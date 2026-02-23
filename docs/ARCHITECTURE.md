# Juris -- Technical Architecture

> AI-Powered Legal Agent for Malaysian Tenants
> KitaHack 2026 | Built with Google Cloud & Gemini

---

## System Overview

```
                           JURIS ARCHITECTURE
 ============================================================

  FLUTTER APP (Android + Web)
  +---------------------------+
  |  Camera / Gallery Picker  |
  |  +--> Image Upload -------+--> Cloud Storage (GCS)
  |                           |        |
  |  Firebase Auth (Anon)     |        | (Eventarc trigger)
  |  Firestore Listeners      |        v
  +----------+----------------+   Cloud Function:
             |                    processDocument
             |                    +-------------------+
     Real-time updates            | 1. Download image |
             ^                    | 2. Gemini Vision  |
             |                    |    (OCR)          |
             |                    | 3. Vector Search  |
             |                    |    (RAG)          |
             |                    | 4. Gemini Pro     |
             |                    |    (Compliance)   |
             |                    | 5. Validator      |
             |                    | 6. Save to        |
             |                    |    Firestore      |
             |                    +-------------------+
             |                           |
             +------ Firestore <---------+
                     (audits, documents)

  HTTPS Callables:
  +------------------+    +------------------+
  | generateLOD      |    | simplifyClause   |
  | (Letter of       |    | (Plain language   |
  |  Demand)         |    |  explanation)     |
  +------------------+    +------------------+
```

---

## Data Flow Pipeline

```
Step 1: CAPTURE          Step 2: UPLOAD           Step 3: OCR
+----------------+       +----------------+       +------------------+
| Tenant takes   | ----> | Image uploaded | ----> | Gemini 1.5 Pro   |
| photo of       |       | to Cloud       |       | Vision extracts  |
| agreement      |       | Storage        |       | text + clauses   |
+----------------+       +----------------+       +------------------+
                                                          |
Step 6: DISPLAY          Step 5: VALIDATE         Step 4: ANALYZE
+----------------+       +----------------+       +------------------+
| Flutter shows  | <---- | Validator      | <---- | Gemini 1.5 Pro   |
| risk score +   |       | checks statute |       | analyzes clauses |
| flagged clauses|       | citations vs   |       | against RAG law  |
|                |       | RAG corpus     |       | chunks           |
+----------------+       +----------------+       +------------------+
```

---

## Component Descriptions

| Component | Technology | Purpose |
|-----------|-----------|---------|
| Mobile App | Flutter 3.38 | Cross-platform UI (Android + Web) |
| Authentication | Firebase Auth | Anonymous sign-in, zero-friction onboarding |
| Image Storage | Cloud Storage for Firebase | Secure image upload with signed URLs |
| Document Pipeline | Cloud Functions (Node.js 20) | Orchestrates OCR -> RAG -> compliance pipeline |
| OCR Engine | Gemini 1.5 Pro Vision | Multimodal document text extraction |
| Compliance Analyzer | Gemini 1.5 Pro Text | Legal clause analysis with structured JSON output |
| Embedding Generator | text-embedding-004 | 768-dimensional embeddings for semantic search |
| Vector Database | Vertex AI Vector Search | Tree-AH approximate nearest neighbor retrieval |
| Application Database | Cloud Firestore | Real-time document/audit storage and sync |
| LOD Generator | Gemini 1.5 Pro Text | Auto-drafts formal Letters of Demand |
| Clause Simplifier | Gemini 1.5 Pro Text | Translates legal jargon to SPM-level language |

---

## Firestore Schema

### `users/{uid}`

| Field | Type | Description |
|-------|------|-------------|
| `created_at` | timestamp | Account creation time |
| `locale` | string | User preferred language (en/ms) |

### `documents/{doc_id}`

| Field | Type | Description |
|-------|------|-------------|
| `uid` | string | Owner user ID |
| `image_url` | string | GCS path to uploaded image |
| `ocr_text` | string | Full extracted text |
| `ocr_confidence` | number | 0.0-1.0 extraction confidence |
| `ocr_language` | string | Detected language (en/ms/zh/ta/mixed) |
| `ocr_clauses` | array | Extracted clause objects |
| `ocr_warning` | string/null | Warning message for low confidence |
| `status` | string | pending / processing / completed / failed |
| `audit_id` | string | Reference to audit document |
| `error_message` | string | Error description if failed |
| `created_at` | timestamp | Upload time |
| `updated_at` | timestamp | Last status change |

### `audits/{audit_id}`

| Field | Type | Description |
|-------|------|-------------|
| `doc_id` | string | Reference to source document |
| `uid` | string | Owner user ID |
| `risk_score` | number | 0-100 overall risk score |
| `flagged_clauses` | array | Array of flagged clause objects |
| `compliant_clauses_count` | number | Number of compliant clauses |
| `total_clauses_count` | number | Total clauses analyzed |
| `actionable_next_step` | string | Recommended next action |
| `analysis_notes` | string | Caveats about the analysis |
| `rag_chunks_used` | number | Number of law chunks used |
| `created_at` | timestamp | Analysis completion time |

**Flagged Clause Object:**

| Field | Type | Description |
|-------|------|-------------|
| `clause_id` | string | Identifier (c-001, c-002, etc.) |
| `original_text` | string | Exact text from OCR |
| `statute_violated` | string | Statute name + section number |
| `violation_type` | string | illegal / unfair / caution |
| `explanation` | string | Plain English explanation (max 50 words) |
| `suggested_revision` | string | Compliant alternative wording |
| `confidence` | number | 0.0-1.0 analysis confidence |

### `law_chunks/{chunk_id}`

| Field | Type | Description |
|-------|------|-------------|
| `statute_name` | string | Full act name (e.g., "Contracts Act 1950") |
| `section_number` | string | Section identifier (e.g., "Section 75") |
| `section_title` | string | Section title |
| `text` | string | Full section text |
| `topic_tags` | array | Relevant topics (e.g., ["deposit", "penalty"]) |
| `priority` | number | 1-5, lower = more important |
| `embedding` | array | 768-dim float vector |

### `letters_of_demand/{lod_id}`

| Field | Type | Description |
|-------|------|-------------|
| `audit_id` | string | Source audit reference |
| `uid` | string | Owner user ID |
| `letter_content` | string | Full letter in markdown |
| `word_count` | number | Letter word count |
| `clauses_addressed` | number | Number of clauses in letter |
| `escalation_options` | array | Post-LOD legal options |
| `created_at` | timestamp | Generation time |

---

## Security Architecture

### Authentication
- Firebase Auth with anonymous sign-in
- Zero-friction: no email/password required
- Each user gets a unique UID tied to all their documents

### Data Access Control (Firestore Rules)
- Users can only read/write their own documents (`request.auth.uid == resource.data.uid`)
- `law_chunks` collection is publicly readable (legal information)
- Cloud Functions have admin access for pipeline operations
- Default deny on all other paths

### PII Handling
- `sanitizeForLogging()` validator redacts IC numbers and phone numbers before logging
- IC numbers matched via regex: `/\d{6}-\d{2}-\d{4}/g`
- Phone numbers matched via regex: `/(\+?6?01[0-9]-?\d{7,8})/g`
- Raw PII never appears in Cloud Functions logs

### PDPA 2010 Compliance

| PDPA Principle | Implementation |
|----------------|----------------|
| General Principle | Data processed only for tenancy analysis |
| Notice & Choice | Disclaimer shown before upload |
| Disclosure | No data shared with third parties |
| Security | Firebase Auth + Firestore rules + TLS |
| Retention | Users can delete their documents |
| Data Integrity | OCR confidence scoring ensures accuracy |
| Access | Users see all their own data in-app |

---

## Google Technologies Used

| Technology | Service | Justification |
|-----------|---------|---------------|
| Gemini 1.5 Pro | Vertex AI | Best multimodal model for OCR + legal analysis |
| text-embedding-004 | Vertex AI | High-quality 768-dim embeddings for legal text |
| Vector Search | Vertex AI | Sub-second retrieval from law corpus |
| Cloud Functions | Firebase | Serverless pipeline orchestration |
| Firestore | Firebase | Real-time sync between backend and Flutter |
| Cloud Storage | Firebase | Secure image upload with lifecycle rules |
| Firebase Auth | Firebase | Zero-friction anonymous authentication |
| Flutter | Google OSS | Cross-platform mobile + web from single codebase |

---

## Deployment Architecture

- **Region:** `asia-southeast1` (Singapore) -- lowest latency to Malaysia
- **Cloud Functions Runtime:** Node.js 20 with TypeScript
- **Firestore:** Native mode with composite indexes on `uid + created_at`
- **Vector Search:** Tree-AH algorithm, 768 dimensions, DOT_PRODUCT distance
- **Storage:** 10MB upload limit, image-only (JPEG/PNG/WebP/HEIC)

---

*Document version: 1.0 | Last updated: 2026-02-23 | KitaHack 2026*
