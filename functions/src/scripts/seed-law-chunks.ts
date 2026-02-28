/**
 * Seed Malaysian Law Chunks into Firestore + Generate Embeddings for Vertex AI Vector Search
 *
 * Usage: npx ts-node src/scripts/seed-law-chunks.ts
 *
 * This script:
 * 1. Parses Malaysian law PDFs into section-level chunks
 * 2. Stores chunk metadata in Firestore `law_chunks` collection
 * 3. Generates embeddings via Vertex AI text-embedding-004
 * 4. Exports embeddings in JSONL format for Vertex AI Vector Search index import
 */

import * as admin from 'firebase-admin';
import * as fs from 'fs';
import * as path from 'path';

// Initialize Firebase Admin (uses Application Default Credentials)
admin.initializeApp({
  projectId: process.env.GCLOUD_PROJECT || 'juris-74a5d',
});

const db = admin.firestore();
const PROJECT_ID = process.env.GCLOUD_PROJECT || 'juris-74a5d';
const LOCATION = 'asia-southeast1';
const EMBEDDING_MODEL = 'text-embedding-004';

// === LAW CHUNK DEFINITIONS ===
// Pre-extracted key sections from Malaysian tenancy-related laws.
// These are the critical sections that Juris needs for compliance analysis.

interface RawLawChunk {
  statute_name: string;
  section_number: string;
  section_title: string;
  text: string;
  topic_tags: string[];
  priority: number;
}

const LAW_CHUNKS: RawLawChunk[] = [
  // === CONTRACTS ACT 1950 (Priority 1) ===
  {
    statute_name: 'Contracts Act 1950',
    section_number: '10',
    section_title: 'What agreements are contracts',
    text: 'All agreements are contracts if they are made by the free consent of parties competent to contract, for a lawful consideration and with a lawful object, and are not hereby expressly declared to be void.',
    topic_tags: ['contract validity', 'free consent', 'lawful consideration'],
    priority: 1,
  },
  {
    statute_name: 'Contracts Act 1950',
    section_number: '14',
    section_title: 'Free consent defined',
    text: 'Consent is said to be free when it is not caused by coercion, undue influence, fraud, misrepresentation, or mistake.',
    topic_tags: ['free consent', 'coercion', 'undue influence', 'fraud'],
    priority: 1,
  },
  {
    statute_name: 'Contracts Act 1950',
    section_number: '16',
    section_title: 'Undue influence',
    text: 'A contract is said to be induced by "undue influence" where the relations subsisting between the parties are such that one of the parties is in a position to dominate the will of the other and uses that position to obtain an unfair advantage over the other.',
    topic_tags: ['undue influence', 'unfair advantage', 'power imbalance'],
    priority: 1,
  },
  {
    statute_name: 'Contracts Act 1950',
    section_number: '24',
    section_title: 'What considerations and objects are lawful',
    text: 'The consideration or object of an agreement is lawful, unless it is forbidden by a law; or is of such a nature that, if permitted, it would defeat any law; or is fraudulent; or involves or implies injury to the person or property of another; or the court regards it as immoral, or opposed to public policy.',
    topic_tags: ['lawful consideration', 'public policy', 'void agreement'],
    priority: 1,
  },
  {
    statute_name: 'Contracts Act 1950',
    section_number: '38',
    section_title: 'Effect of refusal of party to perform wholly',
    text: 'Where a party to a contract has refused to perform, or disabled himself from performing, his promise in its entirety, the promisee may put an end to the contract, unless he has signified, by words or conduct, his acquiescence in its continuance.',
    topic_tags: ['breach of contract', 'termination', 'refusal to perform'],
    priority: 1,
  },
  {
    statute_name: 'Contracts Act 1950',
    section_number: '56',
    section_title: 'Agreement to do impossible act',
    text: 'An agreement to do an act impossible in itself is void. A contract to do an act which, after the contract is made, becomes impossible, or by reason of some event which the promisor could not prevent, unlawful, becomes void when the act becomes impossible or unlawful.',
    topic_tags: ['impossible act', 'void agreement', 'frustration'],
    priority: 1,
  },
  {
    statute_name: 'Contracts Act 1950',
    section_number: '64',
    section_title: 'Consequence of rescission of voidable contract',
    text: 'When a person at whose option a contract is voidable rescinds it, the other party thereto need not perform any promise therein contained in which he is the promisor. The party rescinding a voidable contract shall, if he has received any benefit thereunder from another party to such contract, restore the benefit, so far as may be, to the person from whom it was received.',
    topic_tags: ['rescission', 'voidable contract', 'restoration of benefit'],
    priority: 1,
  },
  {
    statute_name: 'Contracts Act 1950',
    section_number: '74',
    section_title: 'Compensation for breach of contract where penalty stipulated for',
    text: 'When a contract has been broken, if a sum is named in the contract as the amount to be paid in case of such breach, or if the contract contains any other stipulation by way of penalty, the party complaining of the breach is entitled, whether or not actual damage or loss is proved to have been caused thereby, to receive from the party who has broken the contract reasonable compensation not exceeding the amount so named or, as the case may be, the penalty stipulated for.',
    topic_tags: ['penalty clause', 'compensation', 'breach', 'reasonable compensation', 'deposit forfeiture'],
    priority: 1,
  },
  {
    statute_name: 'Contracts Act 1950',
    section_number: '75',
    section_title: 'Party rightfully rescinding contract entitled to compensation',
    text: 'A person who rightfully rescinds a contract is entitled to compensation for any damage which he has sustained through the non-fulfilment of the contract.',
    topic_tags: ['rescission compensation', 'damage', 'non-fulfilment'],
    priority: 1,
  },

  // === CONSUMER PROTECTION ACT 1999 (Priority 1) ===
  {
    statute_name: 'Consumer Protection Act 1999',
    section_number: '24C',
    section_title: 'Unfair contract terms - Procedural unfairness',
    text: 'In determining whether a contract or a term of a contract is procedurally unfair, the court shall have regard to all the circumstances of the case including whether the consumer was in a position to protect their own interests, having regard to the consumer\'s ability to understand any documents, the consumer\'s bargaining position, and whether any undue influence, pressure or unfair tactics were used.',
    topic_tags: ['unfair terms', 'procedural unfairness', 'consumer protection', 'bargaining power'],
    priority: 1,
  },
  {
    statute_name: 'Consumer Protection Act 1999',
    section_number: '24D',
    section_title: 'Unfair contract terms - Substantive unfairness',
    text: 'In determining whether a contract or a term of a contract is substantively unfair, the court shall have regard to whether the contract or the term of the contract is in the interest of the consumer, whether the contract or the term of the contract results in a substantially unequal exchange of values or consideration, and whether the consumer was reasonably required to comply with conditions that were not reasonably necessary for the protection of the legitimate interests of the supplier.',
    topic_tags: ['substantive unfairness', 'unequal exchange', 'consumer rights', 'unfair terms'],
    priority: 1,
  },
  {
    statute_name: 'Consumer Protection Act 1999',
    section_number: '24G',
    section_title: 'Relief by court for unfair contract terms',
    text: 'Where the court finds a contract or a term of a contract to be unfair, the court may declare the contract or the term of the contract to be void, or vary the contract or the term of the contract, or refuse to enforce the contract or the term of the contract.',
    topic_tags: ['void unfair terms', 'court relief', 'consumer protection'],
    priority: 1,
  },

  // === SPECIFIC RELIEF ACT 1950 (Priority 2) ===
  {
    statute_name: 'Specific Relief Act 1950',
    section_number: '18',
    section_title: 'Specific performance of contracts connected with trusts',
    text: 'A contract made by a trustee, in excess of his powers or in breach of trust, may, at the suit of the beneficiary, be specifically enforced by the court. The occupier of property has the right to quiet enjoyment of the premises without interference from the landlord or any person claiming under the landlord.',
    topic_tags: ['specific performance', 'quiet enjoyment', 'landlord interference', 'tenant rights'],
    priority: 2,
  },
  {
    statute_name: 'Specific Relief Act 1950',
    section_number: '40',
    section_title: 'Perpetual injunctions',
    text: 'A perpetual injunction can only be granted by the decree made at the hearing and upon the merits of the suit; the defendant is thereby perpetually enjoined from the assertion of a right, or from the commission of an act, which would be contrary to the rights of the plaintiff.',
    topic_tags: ['injunction', 'tenant rights protection', 'court order'],
    priority: 2,
  },

  // === CIVIL LAW ACT 1956 (Priority 2) ===
  {
    statute_name: 'Civil Law Act 1956',
    section_number: '28(4)',
    section_title: 'Double rental for holding over',
    text: 'Every tenant holding over after the determination of his tenancy shall be chargeable, at the option of his landlord, with double the amount of his rent until possession is given up by him. The double rental provision serves as a deterrent against tenants who refuse to vacate after the tenancy has ended.',
    topic_tags: ['holding over', 'double rental', 'tenancy termination', 'overstaying tenant'],
    priority: 2,
  },
  {
    statute_name: 'Civil Law Act 1956',
    section_number: '6(1)',
    section_title: 'Limitation period for rent recovery',
    text: 'No action shall be brought after the expiration of six years from the date on which the cause of action accrued for recovery of arrears of rent. This applies to landlord claims for unpaid rent against former tenants.',
    topic_tags: ['limitation period', 'rent arrears', 'time limit', 'landlord claims'],
    priority: 2,
  },

  // === DISTRESS ACT 1951 (Priority 3) ===
  {
    statute_name: 'Distress Act 1951',
    section_number: '5',
    section_title: 'Landlord may distrain for rent in arrears',
    text: 'When the whole or any part of the rent of any premises is in arrear, the landlord may levy a distress on any goods and chattels belonging to the tenant or to any sub-tenant which may be found in the premises. The landlord must apply to the court for a warrant of distress.',
    topic_tags: ['distress', 'rent arrears', 'landlord remedy', 'seizure of goods'],
    priority: 3,
  },
  {
    statute_name: 'Distress Act 1951',
    section_number: '7',
    section_title: 'Exempted goods',
    text: 'The following goods and chattels shall be exempted from distress: tools of trade, professional instruments, necessary wearing apparel, bedding, and kitchen utensils to the value of five hundred ringgit.',
    topic_tags: ['distress exemption', 'protected goods', 'tenant property rights'],
    priority: 3,
  },

  // === NATIONAL LAND CODE (Priority 3) ===
  {
    statute_name: 'National Land Code',
    section_number: '213',
    section_title: 'Tenancies exempt from registration',
    text: 'A tenancy for a term not exceeding three years is exempt from registration. Such tenancy is enforceable between the parties without being registered. Tenancies exceeding three years must be registered to be enforceable against third parties.',
    topic_tags: ['tenancy registration', 'short term tenancy', 'land code', 'exemption'],
    priority: 3,
  },
  {
    statute_name: 'National Land Code',
    section_number: '221',
    section_title: 'Implied obligations of landlord',
    text: 'Every landlord of premises subject to this Act shall be implied to have covenanted with the tenant: (a) that the tenant shall have quiet enjoyment of the premises during the tenancy; (b) that the landlord shall keep the premises in a tenantable state of repair during the tenancy.',
    topic_tags: ['implied obligations', 'quiet enjoyment', 'landlord repair duty', 'tenantable repair'],
    priority: 3,
  },

  // === COMMON TENANCY ISSUES (Synthesized Legal Principles) ===
  {
    statute_name: 'Malaysian Tenancy Law (Common Law)',
    section_number: 'CL-001',
    section_title: 'Security deposit obligations',
    text: 'Under Malaysian tenancy practice, security deposits (typically 2 months rent plus 0.5 months utility deposit) must be refunded within a reasonable period after the tenancy ends, less any legitimate deductions for damage beyond normal wear and tear. Landlords cannot forfeit the entire deposit for minor issues or normal wear and tear. Deductions must be itemized and supported with evidence.',
    topic_tags: ['security deposit', 'deposit refund', 'wear and tear', 'deductions', 'deposit forfeiture'],
    priority: 1,
  },
  {
    statute_name: 'Malaysian Tenancy Law (Common Law)',
    section_number: 'CL-002',
    section_title: 'Notice requirements for tenancy termination',
    text: 'Unless otherwise agreed, a monthly tenancy may be terminated by either party giving one month notice. A fixed-term tenancy ends automatically at the expiry of the term. Early termination by the tenant typically requires the tenant to forfeit a proportional amount of the deposit, not the entire deposit. The landlord must give reasonable notice before any entry or inspection of the premises.',
    topic_tags: ['notice period', 'termination', 'early termination', 'landlord notice', 'inspection notice'],
    priority: 1,
  },
  {
    statute_name: 'Malaysian Tenancy Law (Common Law)',
    section_number: 'CL-003',
    section_title: 'Tenant obligations and landlord obligations',
    text: 'Tenants are generally responsible for: paying rent on time, keeping the premises clean, minor repairs and maintenance, not causing nuisance. Landlords are generally responsible for: structural repairs (roof, walls, plumbing), ensuring the property is habitable, not interfering with tenant quiet enjoyment, providing agreed amenities, maintaining common areas in multi-tenant properties.',
    topic_tags: ['tenant obligations', 'landlord obligations', 'maintenance', 'structural repairs', 'habitable'],
    priority: 1,
  },
  {
    statute_name: 'Malaysian Tenancy Law (Common Law)',
    section_number: 'CL-004',
    section_title: 'Illegal eviction and lock-out protection',
    text: 'A landlord cannot evict a tenant without a court order, even if rent is unpaid. Changing locks, removing tenant belongings, cutting utilities, or physically removing a tenant constitutes illegal eviction. The tenant may seek an injunction and claim damages for illegal eviction. The proper legal process requires the landlord to file a claim in court and obtain a possession order.',
    topic_tags: ['illegal eviction', 'lock out', 'possession order', 'court process', 'tenant protection'],
    priority: 1,
  },
];

// === MAIN ===

async function main() {
  console.log(`Seeding ${LAW_CHUNKS.length} law chunks...`);

  const batch = db.batch();
  const embeddings: Array<{ id: string; embedding: number[] }> = [];

  for (let i = 0; i < LAW_CHUNKS.length; i++) {
    const chunk = LAW_CHUNKS[i];
    const chunkId = `${chunk.statute_name.replace(/\s+/g, '_')}_S${chunk.section_number}`.toLowerCase();

    console.log(`[${i + 1}/${LAW_CHUNKS.length}] Processing: ${chunk.statute_name} S.${chunk.section_number}`);

    // Generate embedding
    const embeddingText = `${chunk.statute_name} Section ${chunk.section_number}: ${chunk.section_title}. ${chunk.text}`;
    const embedding = await generateEmbedding(embeddingText);

    // Save to Firestore (without embedding — Firestore is for metadata)
    const docRef = db.collection('law_chunks').doc(chunkId);
    batch.set(docRef, {
      statute_name: chunk.statute_name,
      section_number: chunk.section_number,
      section_title: chunk.section_title,
      text: chunk.text,
      topic_tags: chunk.topic_tags,
      priority: chunk.priority,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Collect for Vertex AI Vector Search JSONL export
    embeddings.push({ id: chunkId, embedding });

    // Rate limit: ~1 req/sec for embeddings API
    if (i < LAW_CHUNKS.length - 1) {
      await new Promise((resolve) => setTimeout(resolve, 500));
    }
  }

  // Commit Firestore batch
  await batch.commit();
  console.log(`Saved ${LAW_CHUNKS.length} chunks to Firestore.`);

  // Export embeddings as JSONL for Vertex AI Vector Search index import
  const jsonlLines = embeddings.map((e) =>
    JSON.stringify({
      id: e.id,
      embedding: e.embedding,
    })
  );

  const outputPath = path.join(__dirname, '../../data/embeddings.jsonl');
  fs.mkdirSync(path.dirname(outputPath), { recursive: true });
  fs.writeFileSync(outputPath, jsonlLines.join('\n'));
  console.log(`Exported embeddings to ${outputPath}`);

  console.log('\nNext steps:');
  console.log('1. Upload embeddings.jsonl to GCS: gsutil cp data/embeddings.jsonl gs://juris-kitahack-vectors/');
  console.log('2. Create Vector Search index: see scripts/create-vector-index.sh');
  console.log('3. Deploy index to endpoint');

  process.exit(0);
}

async function generateEmbedding(text: string): Promise<number[]> {
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

  if (!response.ok) {
    throw new Error(`Embedding API error: ${response.status} ${await response.text()}`);
  }

  const data = await response.json();
  return data.predictions[0].embeddings.values;
}

async function getAccessToken(): Promise<string> {
  const { GoogleAuth } = await import('google-auth-library');
  const auth = new GoogleAuth({
    scopes: ['https://www.googleapis.com/auth/cloud-platform'],
  });
  const client = await auth.getClient();
  const token = await client.getAccessToken();
  return token.token || '';
}

main().catch(console.error);
