/**
 * Juris Cloud Functions
 *
 * Main entry point for all Cloud Functions:
 * 1. processDocument - Triggered on image upload, runs OCR → RAG → compliance pipeline
 * 2. generateLOD - HTTPS callable, generates Letter of Demand from audit
 * 3. simplifyClause - HTTPS callable, simplifies a single clause
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { VertexAI } from '@google-cloud/vertexai';
import { Storage } from '@google-cloud/storage';

import {
  OCR_SYSTEM_PROMPT,
  OCR_USER_PROMPT,
  COMPLIANCE_SYSTEM_PROMPT,
  buildComplianceUserPrompt,
  LOD_SYSTEM_PROMPT,
  SIMPLIFICATION_SYSTEM_PROMPT,
} from './prompts';
import { retrieveLegalContext } from './rag';
import {
  validateStatuteCitations,
  handleOCRConfidence,
  sanitizeForLogging,
} from './validators';

admin.initializeApp();

const db = admin.firestore();
const storage = new Storage();

const PROJECT_ID = process.env.GCLOUD_PROJECT || 'juris-kitahack';
const LOCATION = 'asia-southeast1';

// Initialize Vertex AI
const vertexAI = new VertexAI({ project: PROJECT_ID, location: LOCATION });

// === PROCESS DOCUMENT (Storage Trigger) ===

export const processDocument = functions
  .region(LOCATION)
  .storage.object()
  .onFinalize(async (object) => {
    const filePath = object.name;
    const contentType = object.contentType;

    // Only process images in the documents/ folder
    if (!filePath?.startsWith('documents/') || !contentType?.startsWith('image/')) {
      functions.logger.info('Skipping non-document file', { filePath });
      return;
    }

    // Extract doc_id from path: documents/{uid}/{doc_id}/image.jpg
    const pathParts = filePath.split('/');
    if (pathParts.length < 4) {
      functions.logger.error('Invalid file path structure', { filePath });
      return;
    }
    const uid = pathParts[1];
    const docId = pathParts[2];

    functions.logger.info('Processing document', sanitizeForLogging({ docId, uid }));

    try {
      // Update status to processing
      await db.collection('documents').doc(docId).update({
        status: 'processing',
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });

      // === STEP 1: Download image from GCS ===
      const bucket = storage.bucket(object.bucket);
      const file = bucket.file(filePath);
      const [imageBuffer] = await file.download();
      const base64Image = imageBuffer.toString('base64');
      const mimeType = contentType as string;

      // === STEP 2: OCR via Gemini Vision ===
      const ocrResult = await performOCR(base64Image, mimeType);

      // === STEP 3: Check OCR confidence ===
      const confidenceHandler = handleOCRConfidence(ocrResult.extraction_confidence);

      if (
        confidenceHandler.action === 'REJECT' ||
        confidenceHandler.action === 'RETRY_SUGGESTED'
      ) {
        await db.collection('documents').doc(docId).update({
          status: 'failed',
          error_message: confidenceHandler.userMessage,
          ocr_confidence: ocrResult.extraction_confidence,
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
        });
        functions.logger.warn('OCR confidence too low', {
          docId,
          confidence: ocrResult.extraction_confidence,
          action: confidenceHandler.action,
        });
        return;
      }

      // Save OCR text to document
      await db.collection('documents').doc(docId).update({
        ocr_text: ocrResult.full_text,
        ocr_confidence: ocrResult.extraction_confidence,
        ocr_language: ocrResult.language_detected,
        ocr_clauses: ocrResult.clauses,
        ocr_warning:
          confidenceHandler.action === 'PROCEED_WITH_WARNING'
            ? confidenceHandler.userMessage
            : null,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });

      // === STEP 4: RAG - Retrieve relevant law chunks via Vertex AI Vector Search ===
      const { chunks: ragChunks, ragContext } = await retrieveLegalContext(
        ocrResult.full_text
      );

      functions.logger.info('RAG retrieval complete', {
        docId,
        chunksRetrieved: ragChunks.length,
      });

      // === STEP 5: Compliance analysis via Gemini Pro ===
      const auditResult = await performComplianceAnalysis(
        ocrResult.full_text,
        ragContext
      );

      // === STEP 6: Validate statute citations (anti-hallucination) ===
      const validatedAudit = validateStatuteCitations(auditResult, ragChunks);

      // === STEP 7: Save audit to Firestore ===
      const auditRef = db.collection('audits').doc();
      await auditRef.set({
        doc_id: docId,
        uid,
        risk_score: validatedAudit.risk_score,
        flagged_clauses: validatedAudit.flagged_clauses,
        compliant_clauses_count: validatedAudit.compliant_clauses_count,
        total_clauses_count: validatedAudit.total_clauses_count,
        actionable_next_step: validatedAudit.actionable_next_step,
        analysis_notes: validatedAudit.analysis_notes,
        rag_chunks_used: ragChunks.length,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
      });

      // === STEP 8: Update document status to completed ===
      await db.collection('documents').doc(docId).update({
        status: 'completed',
        audit_id: auditRef.id,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });

      functions.logger.info('Document processing complete', {
        docId,
        auditId: auditRef.id,
        riskScore: validatedAudit.risk_score,
        flaggedClauses: validatedAudit.flagged_clauses.length,
      });
    } catch (error) {
      functions.logger.error('Document processing failed', {
        docId,
        error: error instanceof Error ? error.message : 'Unknown error',
      });

      await db.collection('documents').doc(docId).update({
        status: 'failed',
        error_message: 'An error occurred while processing your document. Please try again.',
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  });

// === GENERATE LETTER OF DEMAND (HTTPS Callable) ===

export const generateLOD = functions
  .region(LOCATION)
  .https.onCall(async (data, context) => {
    // Verify authentication
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Must be logged in to generate a Letter of Demand.'
      );
    }

    const { audit_id, tenant_name, tenant_ic, tenant_address, landlord_name, property_address } =
      data;

    if (!audit_id || !tenant_name || !landlord_name || !property_address) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Missing required fields: audit_id, tenant_name, landlord_name, property_address'
      );
    }

    // Fetch audit data
    const auditDoc = await db.collection('audits').doc(audit_id).get();
    if (!auditDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Audit not found.');
    }

    const auditData = auditDoc.data()!;

    // Verify ownership
    if (auditData.uid !== context.auth.uid) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'You do not have access to this audit.'
      );
    }

    // Generate LOD via Gemini
    const model = vertexAI.getGenerativeModel({
      model: 'gemini-1.5-pro',
      systemInstruction: { role: 'system', parts: [{ text: LOD_SYSTEM_PROMPT }] },
      generationConfig: {
        responseMimeType: 'application/json',
        temperature: 0.3,
        maxOutputTokens: 4096,
      },
    });

    const today = new Date().toLocaleDateString('en-MY', {
      day: 'numeric',
      month: 'long',
      year: 'numeric',
    });

    const prompt = `Generate a Letter of Demand based on the following information:

TENANT DETAILS:
- Name: ${tenant_name}
- IC Number: ${tenant_ic || 'Not provided'}
- Address: ${tenant_address || 'Not provided'}

LANDLORD DETAILS:
- Name: ${landlord_name}
- Property Address: ${property_address}

AUDIT FINDINGS:
${JSON.stringify(auditData.flagged_clauses, null, 2)}

TODAY'S DATE: ${today}

Generate the Letter of Demand following the system instructions exactly. Return only valid JSON.`;

    const result = await model.generateContent(prompt);
    const responseText = result.response.candidates?.[0]?.content?.parts?.[0]?.text;

    if (!responseText) {
      throw new functions.https.HttpsError('internal', 'Failed to generate Letter of Demand.');
    }

    const lodData = JSON.parse(responseText);

    // Save LOD to Firestore
    const lodRef = db.collection('letters_of_demand').doc();
    await lodRef.set({
      audit_id,
      uid: context.auth.uid,
      letter_content: lodData.letter_content,
      word_count: lodData.word_count,
      clauses_addressed: lodData.clauses_addressed,
      escalation_options: lodData.escalation_options,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { lod_id: lodRef.id, ...lodData };
  });

// === SIMPLIFY CLAUSE (HTTPS Callable) ===

export const simplifyClause = functions
  .region(LOCATION)
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Must be logged in.');
    }

    const { clause_text, target_language, violation_type, statute_violated } = data;

    if (!clause_text) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'clause_text is required.'
      );
    }

    const model = vertexAI.getGenerativeModel({
      model: 'gemini-1.5-pro',
      systemInstruction: { role: 'system', parts: [{ text: SIMPLIFICATION_SYSTEM_PROMPT }] },
      generationConfig: {
        responseMimeType: 'application/json',
        temperature: 0.4,
        maxOutputTokens: 1024,
      },
    });

    let prompt = `Simplify the following tenancy agreement clause for a Malaysian tenant:

CLAUSE TEXT:
"${clause_text}"

TARGET LANGUAGE: ${target_language || 'en'}`;

    if (violation_type) {
      prompt += `\n\nNOTE: This clause has been flagged as ${violation_type} because it may violate ${statute_violated || 'Malaysian law'}.`;
    }

    prompt += '\n\nReturn only valid JSON following the system instructions.';

    const result = await model.generateContent(prompt);
    const responseText = result.response.candidates?.[0]?.content?.parts?.[0]?.text;

    if (!responseText) {
      throw new functions.https.HttpsError('internal', 'Failed to simplify clause.');
    }

    return JSON.parse(responseText);
  });

// === HELPER FUNCTIONS ===

async function performOCR(
  base64Image: string,
  mimeType: string
): Promise<{
  extraction_confidence: number;
  language_detected: string;
  total_pages_detected: number;
  document_type: string;
  clauses: Array<{
    clause_number: string;
    clause_title: string | null;
    clause_text: string;
  }>;
  full_text: string;
  notes: string;
}> {
  const model = vertexAI.getGenerativeModel({
    model: 'gemini-1.5-pro',
    systemInstruction: { role: 'system', parts: [{ text: OCR_SYSTEM_PROMPT }] },
    generationConfig: {
      responseMimeType: 'application/json',
      temperature: 0.1,
      maxOutputTokens: 8192,
    },
  });

  const result = await model.generateContent({
    contents: [
      {
        role: 'user',
        parts: [
          {
            inlineData: {
              mimeType,
              data: base64Image,
            },
          },
          { text: OCR_USER_PROMPT },
        ],
      },
    ],
  });

  const responseText = result.response.candidates?.[0]?.content?.parts?.[0]?.text;
  if (!responseText) {
    throw new Error('OCR returned empty response');
  }

  return JSON.parse(responseText);
}

async function performComplianceAnalysis(
  ocrText: string,
  ragContext: string
): Promise<{
  risk_score: number;
  flagged_clauses: Array<{
    clause_id: string;
    original_text: string;
    statute_violated: string;
    violation_type: 'illegal' | 'unfair' | 'caution';
    explanation: string;
    suggested_revision: string;
    confidence: number;
  }>;
  compliant_clauses_count: number;
  total_clauses_count: number;
  actionable_next_step: string;
  analysis_notes: string;
}> {
  const model = vertexAI.getGenerativeModel({
    model: 'gemini-1.5-pro',
    systemInstruction: { role: 'system', parts: [{ text: COMPLIANCE_SYSTEM_PROMPT }] },
    generationConfig: {
      responseMimeType: 'application/json',
      temperature: 0.2,
      maxOutputTokens: 8192,
    },
  });

  const userPrompt = buildComplianceUserPrompt(ragContext, ocrText);
  const result = await model.generateContent(userPrompt);
  const responseText = result.response.candidates?.[0]?.content?.parts?.[0]?.text;

  if (!responseText) {
    throw new Error('Compliance analysis returned empty response');
  }

  return JSON.parse(responseText);
}
