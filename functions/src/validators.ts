/**
 * Juris - Post-processing validation utilities
 * Hallucination grounding, OCR confidence, PII handling
 */

// === TYPES ===

interface FlaggedClause {
  clause_id: string;
  original_text: string;
  statute_violated: string;
  violation_type: 'illegal' | 'unfair' | 'caution';
  explanation: string;
  suggested_revision: string;
  confidence: number;
}

interface AuditResult {
  risk_score: number;
  flagged_clauses: FlaggedClause[];
  compliant_clauses_count: number;
  total_clauses_count: number;
  actionable_next_step: string;
  analysis_notes: string;
}

interface LawChunk {
  statute_name: string;
  section_number: string;
  text: string;
  topic_tags: string[];
}

interface OCRConfidenceHandler {
  threshold: number;
  action: 'PROCEED' | 'PROCEED_WITH_WARNING' | 'RETRY_SUGGESTED' | 'REJECT';
  userMessage: string;
}

// === HALLUCINATION GROUNDING ===

/**
 * Validates that all statute citations in audit results exist in the RAG corpus.
 * Downgrades unverified citations to "caution" to prevent hallucinated legal references.
 */
export function validateStatuteCitations(
  auditResult: AuditResult,
  ragChunks: LawChunk[]
): AuditResult {
  const validStatutes = new Set(
    ragChunks.map(c => `${c.statute_name}, Section ${c.section_number}`)
  );

  auditResult.flagged_clauses = auditResult.flagged_clauses.map(clause => {
    if (
      clause.statute_violated !== 'N/A' &&
      !validStatutes.has(clause.statute_violated)
    ) {
      // Downgrade to caution if statute not in RAG corpus
      return {
        ...clause,
        violation_type: 'caution' as const,
        statute_violated: 'N/A',
        explanation:
          clause.explanation +
          ' [Note: Original statute reference could not be verified against our database.]',
        confidence: Math.min(clause.confidence, 0.5),
      };
    }
    return clause;
  });

  // Recalculate risk score
  auditResult.risk_score = calculateRiskScore(auditResult.flagged_clauses);
  return auditResult;
}

function calculateRiskScore(clauses: FlaggedClause[]): number {
  let score = 0;
  for (const clause of clauses) {
    if (clause.violation_type === 'illegal') score += 20;
    else if (clause.violation_type === 'unfair') score += 10;
    else if (clause.violation_type === 'caution') score += 5;
  }
  return Math.min(score, 100);
}

// === OCR CONFIDENCE ===

const OCR_CONFIDENCE_TIERS: OCRConfidenceHandler[] = [
  {
    threshold: 0.85,
    action: 'PROCEED',
    userMessage: 'Document scanned successfully.',
  },
  {
    threshold: 0.7,
    action: 'PROCEED_WITH_WARNING',
    userMessage:
      'Some parts of your document were difficult to read. Results may be less accurate. Consider retaking the photo with better lighting.',
  },
  {
    threshold: 0.5,
    action: 'RETRY_SUGGESTED',
    userMessage:
      'The image quality is too low for reliable analysis. Please retake the photo: ensure the document is flat, well-lit, and fills the entire frame.',
  },
  {
    threshold: 0.0,
    action: 'REJECT',
    userMessage:
      'We could not read this document. Please ensure you are photographing a tenancy agreement and try again with better lighting and focus.',
  },
];

export function handleOCRConfidence(confidence: number): OCRConfidenceHandler {
  for (const tier of OCR_CONFIDENCE_TIERS) {
    if (confidence >= tier.threshold) {
      return tier;
    }
  }
  return OCR_CONFIDENCE_TIERS[OCR_CONFIDENCE_TIERS.length - 1];
}

// === PII HANDLING ===

const PII_FIELDS = [
  'tenant_name',
  'tenant_ic',
  'tenant_address',
  'landlord_name',
  'ic_number',
  'phone',
  'email',
];

const IC_PATTERN = /\d{6}-\d{2}-\d{4}/g;
const PHONE_PATTERN = /(\+?6?01[0-9]-?\d{7,8})/g;

/**
 * Strips PII patterns from objects before logging.
 * Redacts known PII field names and regex-matches IC/phone numbers in string values.
 */
export function sanitizeForLogging(
  obj: Record<string, unknown>
): Record<string, unknown> {
  const sanitized = { ...obj };
  for (const key of Object.keys(sanitized)) {
    if (PII_FIELDS.includes(key.toLowerCase())) {
      sanitized[key] = '[REDACTED]';
    } else if (typeof sanitized[key] === 'string') {
      sanitized[key] = (sanitized[key] as string)
        .replace(IC_PATTERN, '[IC_REDACTED]')
        .replace(PHONE_PATTERN, '[PHONE_REDACTED]');
    }
  }
  return sanitized;
}
