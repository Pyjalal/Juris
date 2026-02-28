/**
 * Simplified Firestore-based RAG Implementation
 *
 * Uses keyword matching instead of vector search for reliable demo.
 * Can be upgraded to Vector Search after hackathon.
 */

import * as admin from 'firebase-admin';

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
}

/**
 * Extract keywords from tenancy agreement text for matching
 */
function extractKeywords(ocrText: string): string[] {
  const text = ocrText.toLowerCase();
  const keywords: string[] = [];

  // Key tenancy topics to search for
  const topicKeywords = {
    deposit: ['deposit', 'security deposit', 'earnest', 'advance payment'],
    termination: ['termination', 'terminate', 'end tenancy', 'cancel', 'evict'],
    repair: ['repair', 'maintenance', 'structural', 'defect', 'damage'],
    entry: ['entry', 'access', 'inspection', 'premises', 'landlord entry'],
    penalty: ['penalty', 'forfeiture', 'forfeit', 'fine', 'charge'],
    rent: ['rent', 'rental', 'payment', 'increase', 'increment'],
    subletting: ['sublet', 'subletting', 'assign', 'transfer'],
    quiet_enjoyment: ['quiet enjoyment', 'peaceful', 'interference', 'harassment'],
    indemnity: ['indemnity', 'indemnify', 'liability', 'responsible'],
    insurance: ['insurance', 'fire', 'flood', 'disaster'],
    renovation: ['renovation', 'alteration', 'modification', 'improvement'],
    notice: ['notice', 'vacate', 'notification', 'inform'],
  };

  // Check which topics are mentioned
  for (const [topic, terms] of Object.entries(topicKeywords)) {
    for (const term of terms) {
      if (text.includes(term)) {
        keywords.push(topic);
        break; // Found this topic, move to next
      }
    }
  }

  // If no specific topics found, return general keywords
  if (keywords.length === 0) {
    keywords.push('tenant', 'landlord', 'tenancy', 'agreement');
  }

  return keywords;
}

/**
 * Query Firestore for relevant law chunks based on keywords
 */
export async function queryFirestoreRAG(
  ocrText: string,
  maxChunks: number = 15
): Promise<LawChunk[]> {
  const keywords = extractKeywords(ocrText);

  // Fetch all law chunks (small dataset - 24 chunks)
  const snapshot = await getLawChunksRef().get();
  const allChunks: LawChunk[] = [];

  snapshot.forEach((doc) => {
    const data = doc.data();
    allChunks.push({
      id: doc.id,
      statute_name: data.statute_name,
      section_number: data.section_number,
      section_title: data.section_title,
      text: data.text,
      topic_tags: data.topic_tags || [],
      priority: data.priority || 5,
    });
  });

  // Score each chunk by keyword relevance
  const scoredChunks = allChunks.map((chunk) => {
    let score = 0;

    // Check if chunk's topic tags match extracted keywords
    for (const keyword of keywords) {
      if (chunk.topic_tags.some((tag) => tag.toLowerCase().includes(keyword))) {
        score += 10;
      }
    }

    // Check if keywords appear in chunk text
    const chunkText = chunk.text.toLowerCase();
    for (const keyword of keywords) {
      if (chunkText.includes(keyword)) {
        score += 5;
      }
    }

    // Boost score for higher priority statutes
    score += (6 - chunk.priority) * 2; // Priority 1 gets +10, priority 5 gets +2

    return { chunk, score };
  });

  // Sort by score descending, then by priority
  scoredChunks.sort((a, b) => {
    if (a.score !== b.score) return b.score - a.score;
    return a.chunk.priority - b.chunk.priority;
  });

  // Return top chunks
  const topChunks = scoredChunks.slice(0, maxChunks).map((sc) => sc.chunk);

  return topChunks;
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
 * Main RAG retrieval function using Firestore keyword search.
 */
export async function retrieveLegalContext(
  ocrText: string,
  maxChunks: number = 15
): Promise<{ chunks: LawChunk[]; ragContext: string }> {
  const chunks = await queryFirestoreRAG(ocrText, maxChunks);
  const ragContext = buildRAGContext(chunks);

  return { chunks, ragContext };
}
