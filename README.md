# Juris -- AI-Powered Legal Agent for Malaysian Tenants

Juris is an AI-powered mobile application that helps Malaysian tenants understand, audit, and enforce their rights in residential tenancy agreements. Users photograph their tenancy agreement, and Juris extracts the text via Gemini Vision OCR, retrieves relevant Malaysian statutes through Vertex AI Vector Search (RAG), flags illegal or unfair clauses with grounded legal citations, and generates an enforceable Letter of Demand -- all within minutes, at zero cost to the tenant.

---

## Architecture

```
+------------------+       +----------------------------+       +----------------------------+
|                  |       |     Firebase Cloud          |       |    Google Cloud (Vertex AI) |
|  Flutter App     |       |     Functions (Node 20)     |       |                            |
|  (Android/iOS)   |       |     asia-southeast1         |       |                            |
|                  |       |                            |       |                            |
|  1. Capture      +------>+  processDocument            |       |                            |
|     photo        |       |    |                        |       |                            |
|                  |       |    +-> Gemini 1.5 Pro Vision +------>+  OCR extraction            |
|  2. View audit   |       |    |   (multimodal OCR)     |       |                            |
|     results      |       |    |                        |       |                            |
|                  |       |    +-> Vertex AI Embeddings  +------>+  text-embedding-004        |
|  3. Read plain-  |       |    |   (query embedding)    |       |  768-dim vectors           |
|     English      |       |    |                        |       |                            |
|     explanation  |       |    +-> Vector Search Index   +------>+  Tree-AH nearest-neighbor  |
|                  |       |    |   (RAG retrieval)       |       |  ~250 law chunks indexed   |
|  4. Generate     |       |    |                        |       |                            |
|     Letter of    |       |    +-> Gemini 1.5 Pro        +------>+  Compliance analysis       |
|     Demand       |       |    |   (grounded analysis)  |       |  with RAG context          |
|                  |       |    |                        |       |                            |
|  5. Find nearest |       |    +-> Hallucination guard   |       |                            |
|     tribunal     |       |         (citation validator) |       |                            |
|                  |       |                            |       |                            |
+--------+---------+       +-------------+--------------+       +----------------------------+
         |                               |
         |                               |
+--------v---------+       +-------------v--------------+
|                  |       |                            |
|  Firebase Auth   |       |  Cloud Firestore           |
|  (Google, Email) |       |    - documents             |
|                  |       |    - audits                |
+------------------+       |    - letters_of_demand     |
                           |    - law_chunks            |
+------------------+       |                            |
|                  |       +----------------------------+
|  Cloud Storage   |
|  (document imgs) |       +----------------------------+
|                  |       |                            |
+------------------+       |  Google Cloud KMS          |
                           |  (PII encryption at rest)  |
+------------------+       |                            |
|                  |       +----------------------------+
|  Google Maps     |
|  Places API      |       +----------------------------+
|  (tribunal       |       |                            |
|   finder)        |       |  Google Docs API           |
|                  |       |  (LOD export to Google Doc) |
+------------------+       +----------------------------+
```

---

## Tech Stack

| Layer              | Service                                | Purpose                                          |
| ------------------ | -------------------------------------- | ------------------------------------------------ |
| AI / LLM           | Gemini 1.5 Pro (Vision + Text)         | OCR extraction, compliance analysis, LOD drafting |
| RAG Retrieval      | Vertex AI Vector Search                | Nearest-neighbor search over law corpus           |
| Embeddings         | Vertex AI Embeddings (text-embedding-004) | 768-dimension vectors for law chunks and queries |
| Backend            | Firebase Cloud Functions (Node.js 20)  | Serverless compute, event-driven pipeline         |
| Database           | Cloud Firestore                        | Document store for users, audits, law chunks      |
| File Storage       | Firebase Cloud Storage                 | Tenant agreement image uploads                    |
| Authentication     | Firebase Authentication                | Google Sign-In, email/password                    |
| Hosting            | Firebase Hosting                       | Web dashboard (future)                            |
| Encryption         | Google Cloud KMS                       | PII encryption at rest for tenant data            |
| Location Services  | Google Maps Places API                 | Find nearest Tribunal for Consumer Claims         |
| Document Export    | Google Docs API                        | Export Letter of Demand as editable Google Doc     |
| Mobile Client      | Flutter (Dart)                         | Cross-platform Android and iOS application        |

---

## Setup Instructions

### Prerequisites

- Node.js 20 or later
- Firebase CLI (`npm install -g firebase-tools`)
- Google Cloud SDK (`gcloud` CLI)
- Flutter SDK 3.x
- A Firebase project linked to a Google Cloud project

### 1. Clone the repository

```bash
git clone https://github.com/your-org/juris.git
cd juris
```

### 2. Configure Firebase

```bash
firebase login
firebase use juris-kitahack
```

### 3. Install Cloud Functions dependencies

```bash
cd functions
npm install
cp .env.example .env
# Edit .env with your Vertex AI endpoint values
cd ..
```

### 4. Seed the law corpus

Upload the Malaysian law PDFs, then run the seeding script to chunk, embed, and index them:

```bash
cd functions
npm run seed
cd ..
```

### 5. Provision Vertex AI Vector Search

```bash
chmod +x scripts/setup-vertex-ai.sh
./scripts/setup-vertex-ai.sh
```

Copy the output endpoint ID and deployed index ID into `functions/.env`.

### 6. Deploy Firebase resources

```bash
firebase deploy
```

This deploys Firestore rules, Firestore indexes, Storage rules, Cloud Functions, and Hosting in a single command.

### 7. Run the Flutter app

```bash
flutter pub get
flutter run
```

### 8. (Optional) Run with Firebase Emulators

```bash
firebase emulators:start
```

---

## Project Structure

```
juris/
  firebase.json              Firebase project configuration
  firestore.rules            Firestore security rules
  firestore.indexes.json     Composite index definitions
  storage.rules              Cloud Storage security rules
  .firebaserc                Firebase project alias

  functions/
    package.json             Cloud Functions dependencies
    tsconfig.json            TypeScript compiler configuration
    .env.example             Environment variable template
    src/
      index.ts               Main Cloud Functions (processDocument, generateLOD, simplifyClause)
      rag.ts                 Vertex AI Vector Search RAG implementation
      validators.ts          Hallucination grounding, OCR confidence, PII sanitization
      prompts.ts             Gemini system prompts for all pipeline stages
      scripts/
        seed-law-chunks.ts   Law corpus chunking and embedding pipeline

  scripts/
    setup-vertex-ai.sh       Vertex AI Vector Search provisioning script

  lib/                       Flutter application source (Dart)
  android/                   Android platform files
  ios/                       iOS platform files
```

---

## SDG Alignment

### SDG 16: Peace, Justice and Strong Institutions

Juris directly advances **United Nations Sustainable Development Goal 16**, specifically:

- **Target 16.3** -- Promote the rule of law and ensure equal access to justice for all. Juris removes the financial barrier to legal advice for tenants who cannot afford a lawyer by providing AI-grounded legal analysis at zero cost.

- **Target 16.6** -- Develop effective, accountable, and transparent institutions. By grounding every legal citation in verifiable statute text (via RAG) and applying anti-hallucination validation, Juris ensures that the advice it provides is transparent and traceable to its legal source.

- **Target 16.10** -- Ensure public access to information. Juris transforms dense, inaccessible legal language in tenancy agreements into plain English and Bahasa Malaysia explanations, making the law understandable to all Malaysians regardless of education level.

In Malaysia, over 7 million households rent their homes. Many tenants sign agreements containing illegal or unfair clauses -- such as forfeiture of the entire security deposit, waiver of the landlord's repair obligations, or unilateral termination rights -- without understanding their rights under the Contracts Act 1950, the Consumer Protection Act 1999, or the Distress Act 1951. Juris exists to close that justice gap.

---

## Team

| Name | Role | Contact |
| ---- | ---- | ------- |
| TBD  | TBD  | TBD     |

---

## License

This project is licensed under the [MIT License](LICENSE).

```
MIT License

Copyright (c) 2026 Juris

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
