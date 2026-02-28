/**
 * Vertex AI Vector Search RAG Implementation for Juris
 *
 * Full implementation using Vertex AI Vector Search for grounded
 * legal analysis against Malaysian tenancy law corpus.
 */

import { VertexAI } from '@google-cloud/vertexai';
import { v1 } from '@google-cloud/aiplatform';
import * as admin from 'firebase-admin';

const PROJECT_ID = process.env.GCLOUD_PROJECT || 'juris-74a5d';
const LOCATION = 'asia-southeast1'; // Consolidated to single region
const INDEX_ENDPOINT_ID = process.env.VECTOR_SEARCH_ENDPOINT || '5253352208304439296';
const DEPLOYED_INDEX_ID = process.env.DEPLOYED_INDEX_ID || 'juris_law_chunks_deployed';
const EMBEDDING_MODEL = 'text-embedding-004';

// Vertex AI client for embeddings (same region as function)
const vertexAI = new VertexAI({ project: PROJECT_ID, location: LOCATION });

// Firestore reference getter (lazy initialization)
function getDb() {
  return admin.firestore();
}

function getLawChunksRef() {
  return getDb().collection('law_chunks');
}

// === TYPES ===

export interface LawChunk {
  id: string;
  statute_name: string;
  section_number: string;
  section_title: string;
  text: string;
  topic_tags: string[];
  priority: number; // 1=highest (Contracts Act), 5=lowest
  embedding?: number[];
}

interface VectorSearchResult {
  id: string;
  distance: number;
}

// === EMBEDDING GENERATION ===

/**
 * Generate text embeddings using Vertex AI Embeddings API.
 */
export async function generateEmbedding(text: string): Promise<number[]> {
  const model = vertexAI.getGenerativeModel({ model: EMBEDDING_MODEL });

  // Use the Vertex AI Embeddings endpoint directly
  const response = await fetch(
    `https://${LOCATION}-aiplatform.googleapis.com/v1/projects/${PROJECT_ID}/locations/${LOCATION}/publishers/google/models/${EMBEDDING_MODEL}:predict`,
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${await getAccessToken()}`,
      },
      body: JSON.stringify({
        instances: [{ content: text, task_type: 'RETRIEVAL_QUERY' }],
      }),
    }
  );

  const data = await response.json();
  return data.predictions[0].embeddings.values;
}

/**
 * Generate embeddings for document chunks (for indexing).
 */
export async function generateDocumentEmbedding(text: string): Promise<number[]> {
  const response = await fetch(
    `https://${LOCATION}-aiplatform.googleapis.com/v1/projects/${PROJECT_ID}/locations/${LOCATION}/publishers/google/models/${EMBEDDING_MODEL}:predict`,
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${await getAccessToken()}`,
      },
      body: JSON.stringify({
        instances: [{ content: text, task_type: 'RETRIEVAL_DOCUMENT' }],
      }),
    }
  );

  const data = await response.json();
  return data.predictions[0].embeddings.values;
}

// === VERTEX AI VECTOR SEARCH ===

/**
 * Query Vertex AI Vector Search index for relevant law chunks.
 * Returns the top-k most similar law chunks to the query text.
 */
export async function queryVectorSearch(
  queryText: string,
  topK: number = 10,
  minSimilarity: number = 0.65
): Promise<LawChunk[]> {
  // Step 1: Generate query embedding
  const queryEmbedding = await generateEmbedding(queryText);

  // Step 2: Query Vector Search index endpoint
  const matchServiceClient = new v1.MatchServiceClient({
    apiEndpoint: `${LOCATION}-aiplatform.googleapis.com`,
  });

  const [response] = await matchServiceClient.findNeighbors({
    indexEndpoint: `projects/${PROJECT_ID}/locations/${LOCATION}/indexEndpoints/${INDEX_ENDPOINT_ID}`,
    deployedIndexId: DEPLOYED_INDEX_ID,
    queries: [
      {
        datapoint: {
          featureVector: queryEmbedding,
        },
        neighborCount: topK,
      },
    ],
  });

  // Step 3: Filter by similarity threshold and fetch full chunks from Firestore
  const results: VectorSearchResult[] = [];
  if (response.nearestNeighbors && response.nearestNeighbors[0]) {
    for (const neighbor of response.nearestNeighbors[0].neighbors || []) {
      const distance = neighbor.distance || 0;
      // Vector Search returns distance; convert to similarity
      const similarity = 1 - distance;
      if (similarity >= minSimilarity && neighbor.datapoint?.datapointId) {
        results.push({
          id: neighbor.datapoint.datapointId,
          distance,
        });
      }
    }
  }

  // Step 4: Fetch full law chunk metadata from Firestore
  const chunks: LawChunk[] = [];
  for (const result of results) {
    const doc = await getLawChunksRef().doc(result.id).get();
    if (doc.exists) {
      chunks.push({ id: doc.id, ...doc.data() } as LawChunk);
    }
  }

  // Sort by priority (lower = more important) then by distance
  chunks.sort((a, b) => a.priority - b.priority);

  return chunks;
}

/**
 * Build RAG context string from retrieved law chunks.
 * Formats chunks for insertion into the compliance analysis prompt.
 */
export function buildRAGContext(chunks: LawChunk[]): string {
  if (chunks.length === 0) {
    return 'No relevant legal provisions found in the database.';
  }

  return chunks
    .map(
      (chunk, i) =>
        `--- Legal Reference ${i + 1} ---
Statute: ${chunk.statute_name}
Section: ${chunk.section_number}
Title: ${chunk.section_title}
Topics: ${chunk.topic_tags.join(', ')}

${chunk.text}
`
    )
    .join('\n');
}

/**
 * Extract key clause terms for targeted RAG queries.
 * Breaks the OCR text into clause-level queries for better retrieval.
 */
export function extractQueryTerms(ocrText: string): string[] {
  const queries: string[] = [];

  // Full text query for general relevance
  queries.push(ocrText.substring(0, 2000)); // Truncate for embedding limit

  // Extract specific clause topics
  const topicPatterns = [
    /deposit|security deposit|earnest/gi,
    /termination|early termination|terminate/gi,
    /repair|maintenance|structural/gi,
    /entry|access|inspection|premises/gi,
    /penalty|forfeiture|forfeit/gi,
    /rent|rental|increase|increment/gi,
    /subletting|sub-let|assign/gi,
    /quiet enjoyment|peaceful/gi,
    /indemnity|indemnify|liability/gi,
    /insurance|fire|damage/gi,
    /renovation|alteration|modification/gi,
    /notice|vacate|eviction/gi,
  ];

  for (const pattern of topicPatterns) {
    if (pattern.test(ocrText)) {
      // Extract surrounding context (100 chars before and after match)
      const match = ocrText.match(pattern);
      if (match && match.index !== undefined) {
        const start = Math.max(0, match.index - 100);
        const end = Math.min(ocrText.length, match.index + match[0].length + 100);
        queries.push(ocrText.substring(start, end));
      }
    }
  }

  return queries;
}

/**
 * Main RAG retrieval function.
 * Performs multiple queries to get comprehensive legal context.
 */
export async function retrieveLegalContext(
  ocrText: string,
  maxChunks: number = 15
): Promise<{ chunks: LawChunk[]; ragContext: string }> {
  const queryTerms = extractQueryTerms(ocrText);

  // Query vector search with each term and deduplicate results
  const allChunks = new Map<string, LawChunk>();

  for (const query of queryTerms) {
    const chunks = await queryVectorSearch(query, 5, 0.65);
    for (const chunk of chunks) {
      if (!allChunks.has(chunk.id)) {
        allChunks.set(chunk.id, chunk);
      }
    }
  }

  // Take top maxChunks by priority
  const sortedChunks = Array.from(allChunks.values())
    .sort((a, b) => a.priority - b.priority)
    .slice(0, maxChunks);

  const ragContext = buildRAGContext(sortedChunks);

  return { chunks: sortedChunks, ragContext };
}

// === HELPER ===

async function getAccessToken(): Promise<string> {
  const { GoogleAuth } = await import('google-auth-library');
  const auth = new GoogleAuth({
    scopes: ['https://www.googleapis.com/auth/cloud-platform'],
  });
  const client = await auth.getClient();
  const token = await client.getAccessToken();
  return token.token || '';
}
