# Juris Cloud Functions - Architecture Diagnosis & Fixes

**Date:** 2026-02-26
**Project:** juris-74a5d
**Region:** asia-southeast1
**Status:** CRITICAL - Document processing failing

---

## Executive Summary

The Juris Cloud Functions are experiencing complete processing failures due to **three critical architectural misconfigurations**:

1. **CRITICAL:** Gemini 1.5 Pro model not accessible via Vertex AI API (404 errors)
2. **CRITICAL:** Multi-region API routing issues (asia-southeast1 ↔ us-central1)
3. **WARNING:** Memory allocation mismatches (256MB vs configured 1GB)

**Impact:** 100% of document uploads are failing after OCR stage.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         JURIS ARCHITECTURE                              │
│                         Firebase Project: juris-74a5d                   │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────┐
│   Flutter App   │
│  (Mobile/Web)   │
└────────┬────────┘
         │
         │ 1. Upload Image
         ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    CLOUD STORAGE (asia-southeast1)                      │
│                    Bucket: juris-74a5d.appspot.com                      │
│                    Path: documents/{uid}/{doc_id}/image.jpg             │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │
                                 │ 2. Storage Trigger
                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│              CLOUD FUNCTION: processDocument                            │
│              Region: asia-southeast1                                    │
│              Runtime: Node.js 20                                        │
│              Memory: 1GB (configured) / 256MB (actual) ❌               │
│              Timeout: 540s                                              │
└────────┬────────────────────────────────────────────────────────────────┘
         │
         │ 3. OCR Request
         ▼
┌─────────────────────────────────────────────────────────────────────────┐
│              VERTEX AI - GEMINI 1.5 PRO (us-central1)                   │
│              ❌ BLOCKED: Model not found via Vertex AI SDK              │
│              Error: Publisher Model not found (404)                     │
│                                                                          │
│              Expected: projects/juris-74a5d/locations/us-central1/      │
│                       publishers/google/models/gemini-1.5-pro           │
│              Status: NOT_FOUND                                          │
└─────────────────────────────────────────────────────────────────────────┘
         │
         │ 4. RAG Retrieval (BLOCKED - never reached)
         ▼
┌─────────────────────────────────────────────────────────────────────────┐
│          VERTEX AI VECTOR SEARCH (asia-southeast1)                      │
│          Index Endpoint: 5253352208304439296                            │
│          Deployed Index: juris_law_chunks_deployed                      │
│          Status: ✅ Deployed and accessible                             │
└─────────────────────────────────────────────────────────────────────────┘
         │
         │ 5. Save Results (BLOCKED - never reached)
         ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    FIRESTORE (asia-southeast1)                          │
│                    Collections: documents, audits                       │
│                    Status: ✅ Accessible                                │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Critical Issues Identified

### Issue #1: Gemini API Access Method (CRITICAL)

**Error Message:**
```
[VertexAI.ClientError]: got status: 404 Not Found
Publisher Model `projects/juris-74a5d/locations/us-central1/publishers/google/models/gemini-1.5-pro` was not found
```

**Root Cause:**
The code is using the **@google-cloud/vertexai** SDK to access Gemini 1.5 Pro, but Gemini models are **NOT** available as "Publisher Models" in Vertex AI. They are available through the **Generative Language API** (generativelanguage.googleapis.com).

**Current Code (WRONG):**
```typescript
// index.ts line 40
const vertexAI = new VertexAI({ project: PROJECT_ID, location: GEMINI_LOCATION });
const model = vertexAI.getGenerativeModel({ model: 'gemini-1.5-pro' });
```

This tries to access:
```
https://us-central1-aiplatform.googleapis.com/v1/projects/juris-74a5d/locations/us-central1/publishers/google/models/gemini-1.5-pro
```

**Diagnosis:**
- ✅ API Enabled: `generativelanguage.googleapis.com` is enabled
- ✅ API Enabled: `aiplatform.googleapis.com` is enabled
- ❌ Wrong SDK: Using Vertex AI SDK for Gemini API access
- ❌ Wrong Endpoint: Gemini models are not "Publisher Models"

**Why This Fails:**
Gemini 1.5 Pro is available through:
1. **Direct Generative Language API** (generativelanguage.googleapis.com) - for API key auth
2. **Vertex AI Gemini API** (requires different endpoint structure)
3. **NOT as Vertex AI Publisher Models**

### Issue #2: Multi-Region Complexity (ARCHITECTURAL)

**Current Setup:**
```
Cloud Function:         asia-southeast1
Vertex AI Vector Search: asia-southeast1  ✅ Works
Gemini API Calls:       us-central1       ❌ Fails
Firestore:              (global)          ✅ Works
Cloud Storage:          asia-southeast1   ✅ Works
```

**Problem:**
The code initializes Vertex AI client with `location: 'us-central1'` but the Cloud Function runs in `asia-southeast1`, causing cross-region authentication and endpoint routing issues.

**Evidence:**
```typescript
// index.ts line 37
const GEMINI_LOCATION = 'us-central1'; // Gemini models available in us-central1
const vertexAI = new VertexAI({ project: PROJECT_ID, location: GEMINI_LOCATION });
```

But Gemini is actually available in multiple regions including asia-southeast1.

### Issue #3: Memory Configuration Mismatch (DEPLOYMENT)

**Configured:**
```typescript
// index.ts line 46
.runWith({ memory: '1GB', timeoutSeconds: 540 })
```

**Actual (from logs):**
```
Memory limit of 256 MiB exceeded with 258 MiB used
```

**Root Cause:**
The Cloud Function is being deployed with default 256MB memory instead of the configured 1GB. This indicates either:
1. Deployment using wrong Firebase CLI version
2. Gen1 vs Gen2 function mismatch
3. Firebase Functions config not being read correctly

**Evidence from Logs:**
```json
{
  "error": "Memory limit of 256 MiB exceeded with 258 MiB used",
  "timestamp": "2026-02-26T11:03:13.329903Z"
}
```

---

## Required API Status

| API | Required | Enabled | Status |
|-----|----------|---------|--------|
| `cloudfunctions.googleapis.com` | ✅ | ✅ | OK |
| `aiplatform.googleapis.com` | ✅ | ✅ | OK |
| `generativelanguage.googleapis.com` | ✅ | ✅ | OK |
| `storage.googleapis.com` | ✅ | ✅ | OK |
| `firestore.googleapis.com` | ✅ | ✅ | OK |
| `cloudresourcemanager.googleapis.com` | ✅ | ✅ | OK |
| `cloudbuild.googleapis.com` | ✅ | ✅ | OK |
| `artifactregistry.googleapis.com` | ✅ | ✅ | OK |

**Conclusion:** All required APIs are enabled. Issue is NOT API enablement.

---

## IAM Permissions Status

**Service Account:** `juris-74a5d@appspot.gserviceaccount.com`
**Current Role:** `roles/editor` ✅

**Required Permissions:**
- ✅ `aiplatform.endpoints.predict` (via roles/editor)
- ✅ `aiplatform.indexes.query` (via roles/editor)
- ✅ `storage.objects.get` (via roles/editor)
- ✅ `storage.objects.create` (via roles/editor)
- ✅ `datastore.entities.create` (via roles/editor)
- ✅ `datastore.entities.update` (via roles/editor)

**Conclusion:** IAM permissions are sufficient. Issue is NOT permissions.

---

## Solutions & Fixes

### Fix #1: Use Correct Gemini API Endpoint (CRITICAL)

**Option A: Use Generative Language API (Recommended for KitaHack)**

Replace Vertex AI SDK with direct Gemini API calls:

```typescript
// Install package
npm install @google-ai/generativelanguage

// Update index.ts
import { GenerativeServiceClient } from '@google-ai/generativelanguage';
import { GoogleAuth } from 'google-auth-library';

const auth = new GoogleAuth({
  scopes: ['https://www.googleapis.com/auth/cloud-platform'],
});

const client = new GenerativeServiceClient({
  auth: auth,
});

// Use gemini-1.5-pro via generativelanguage API
const model = 'models/gemini-1.5-pro';
```

**Option B: Use Vertex AI Gemini Endpoint (Correct Structure)**

Fix the Vertex AI initialization to use the correct Gemini endpoint:

```typescript
// Use @google-cloud/vertexai but with correct model path
const vertexAI = new VertexAI({
  project: PROJECT_ID,
  location: 'asia-southeast1' // Use same region as function
});

// Gemini models in Vertex AI use different naming
const model = vertexAI.preview.getGenerativeModel({
  model: 'gemini-1.5-pro-001', // Use versioned model name
});
```

**Option C: Use REST API with google-auth-library (Most Reliable)**

```typescript
import { GoogleAuth } from 'google-auth-library';

const auth = new GoogleAuth({
  scopes: ['https://www.googleapis.com/auth/cloud-platform'],
});

async function callGemini(prompt: string, base64Image?: string) {
  const client = await auth.getClient();
  const accessToken = await client.getAccessToken();

  const endpoint = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent`;

  const response = await fetch(endpoint, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${accessToken.token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      contents: [{
        parts: [
          { text: prompt },
          ...(base64Image ? [{ inline_data: { mime_type: 'image/jpeg', data: base64Image } }] : [])
        ]
      }],
      generationConfig: {
        temperature: 0.1,
        maxOutputTokens: 8192,
      }
    })
  });

  return response.json();
}
```

### Fix #2: Consolidate to Single Region (RECOMMENDED)

**Change all services to asia-southeast1:**

```typescript
// index.ts
const PROJECT_ID = process.env.GCLOUD_PROJECT || 'juris-74a5d';
const LOCATION = 'asia-southeast1'; // Single region for everything
const GEMINI_LOCATION = 'asia-southeast1'; // Same region

const vertexAI = new VertexAI({ project: PROJECT_ID, location: LOCATION });
```

**Benefits:**
- Reduced latency (all calls in same region)
- No cross-region authentication issues
- Lower costs (no cross-region data transfer)
- Simpler debugging

**Gemini Availability in asia-southeast1:**
Gemini 1.5 Pro IS available in asia-southeast1 region.

### Fix #3: Correct Memory Configuration

**Update firebase.json:**

```json
{
  "functions": {
    "source": "functions",
    "runtime": "nodejs20",
    "region": "asia-southeast1",
    "memory": "1GB",
    "timeout": "540s"
  }
}
```

**Use Gen2 Functions (Recommended):**

```typescript
// index.ts - Update to Gen2 syntax
import { onObjectFinalized } from 'firebase-functions/v2/storage';
import { onCall } from 'firebase-functions/v2/https';

export const processDocument = onObjectFinalized(
  {
    region: 'asia-southeast1',
    memory: '1GiB',
    timeoutSeconds: 540,
    maxInstances: 10,
  },
  async (event) => {
    const filePath = event.data.name;
    // ... rest of code
  }
);
```

**Deploy with explicit flags:**

```bash
firebase deploy --only functions:processDocument --force
```

---

## Recommended Architecture (Fixed)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                      JURIS ARCHITECTURE (FIXED)                         │
│                   All Services: asia-southeast1                         │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────┐
│   Flutter App   │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────────────┐
│              CLOUD STORAGE (asia-southeast1)                            │
│              Trigger: onObjectFinalized                                 │
└────────┬────────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────────────┐
│         CLOUD FUNCTION: processDocument (Gen2)                          │
│         Region: asia-southeast1                                         │
│         Memory: 1GB                                                     │
│         Runtime: Node.js 20                                             │
└────┬────────────────────────────────────────────────────────────────────┘
     │
     ├─── OCR ─────────────────────────────────────────────────────────────┐
     │                                                                      │
     ▼                                                                      ▼
┌─────────────────────────────────────┐  ┌──────────────────────────────────┐
│   GEMINI 1.5 PRO                    │  │  GENERATIVE LANGUAGE API         │
│   Via: generativelanguage API       │  │  Endpoint: generativelanguage    │
│   Region: Global (routed optimally) │  │           .googleapis.com        │
│   Auth: Service Account OAuth       │  │  Auth: OAuth 2.0                 │
└─────────────────────────────────────┘  └──────────────────────────────────┘
     │
     ├─── RAG ─────────────────────────────────────────────────────────────┐
     │                                                                      │
     ▼                                                                      ▼
┌─────────────────────────────────────┐  ┌──────────────────────────────────┐
│   VERTEX AI EMBEDDINGS              │  │  VERTEX AI VECTOR SEARCH         │
│   Model: text-embedding-004         │  │  Index Endpoint: deployed        │
│   Region: asia-southeast1           │  │  Region: asia-southeast1         │
│   Task: RETRIEVAL_QUERY             │  │  Match: findNeighbors            │
└─────────────────────────────────────┘  └──────────────────────────────────┘
     │
     ├─── Compliance ──────────────────────────────────────────────────────┐
     │                                                                      │
     ▼                                                                      ▼
┌─────────────────────────────────────┐  ┌──────────────────────────────────┐
│   GEMINI 1.5 PRO                    │  │  FIRESTORE                       │
│   Compliance Analysis               │  │  Collections:                    │
│   With RAG Context                  │  │  - documents                     │
│   JSON Output                       │  │  - audits                        │
│                                     │  │  - law_chunks                    │
└─────────────────────────────────────┘  └──────────────────────────────────┘
```

---

## Implementation Plan

### Step 1: Fix Gemini API Access (30 mins)

1. Update `functions/src/index.ts`:
   - Replace Vertex AI SDK calls with Generative Language API
   - Use google-auth-library for authentication
   - Test with REST API first for immediate validation

2. Update `functions/package.json`:
   ```json
   "dependencies": {
     "@google-ai/generativelanguage": "^2.3.0",
     "google-auth-library": "^9.0.0",
     // ... rest
   }
   ```

3. Redeploy:
   ```bash
   cd functions
   npm install
   npm run build
   cd ..
   firebase deploy --only functions:processDocument
   ```

### Step 2: Consolidate Region (15 mins)

1. Update all region references to `asia-southeast1`
2. Remove `GEMINI_LOCATION` variable
3. Update embedding API calls to use `asia-southeast1`

### Step 3: Fix Memory Configuration (10 mins)

1. Update to Gen2 functions syntax
2. Add explicit memory configuration
3. Redeploy with `--force` flag

### Step 4: Test Pipeline (30 mins)

1. Upload test tenancy agreement image
2. Monitor Cloud Functions logs
3. Verify OCR → RAG → Compliance flow
4. Check Firestore for audit results

---

## Code Changes Required

### File: `functions/src/index.ts`

**Lines to Change:**

1. **Lines 10-13** - Add new imports:
```typescript
import { GenerativeServiceClient } from '@google-ai/generativelanguage';
import { GoogleAuth } from 'google-auth-library';
```

2. **Lines 35-40** - Fix initialization:
```typescript
const PROJECT_ID = process.env.GCLOUD_PROJECT || 'juris-74a5d';
const LOCATION = 'asia-southeast1'; // Single region

// Initialize auth for Gemini API
const geminiAuth = new GoogleAuth({
  scopes: ['https://www.googleapis.com/auth/cloud-platform'],
});

const geminiClient = new GenerativeServiceClient({
  auth: geminiAuth,
});
```

3. **Lines 44-48** - Update to Gen2:
```typescript
import { onObjectFinalized } from 'firebase-functions/v2/storage';

export const processDocument = onObjectFinalized(
  {
    region: LOCATION,
    memory: '1GiB',
    timeoutSeconds: 540,
  },
  async (event) => {
    const object = event.data;
    // ... rest
  }
);
```

4. **Lines 350-383** - Rewrite performOCR:
```typescript
async function performOCR(
  base64Image: string,
  mimeType: string
): Promise<{ /* same type */ }> {
  const client = await geminiAuth.getClient();
  const token = await client.getAccessToken();

  const response = await fetch(
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent',
    {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token.token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        contents: [{
          parts: [
            {
              inline_data: {
                mime_type: mimeType,
                data: base64Image,
              }
            },
            { text: OCR_USER_PROMPT }
          ]
        }],
        systemInstruction: {
          parts: [{ text: OCR_SYSTEM_PROMPT }]
        },
        generationConfig: {
          response_mime_type: 'application/json',
          temperature: 0.1,
          max_output_tokens: 8192,
        }
      })
    }
  );

  const data = await response.json();
  const responseText = data.candidates?.[0]?.content?.parts?.[0]?.text;

  if (!responseText) {
    throw new Error('OCR returned empty response');
  }

  return JSON.parse(responseText);
}
```

### File: `functions/src/rag.ts`

**Lines to Change:**

1. **Lines 12-19** - Update region:
```typescript
const PROJECT_ID = process.env.GCLOUD_PROJECT || 'juris-74a5d';
const LOCATION = 'asia-southeast1'; // Consolidated region
const INDEX_ENDPOINT_ID = process.env.VECTOR_SEARCH_ENDPOINT || '5253352208304439296';
const DEPLOYED_INDEX_ID = process.env.DEPLOYED_INDEX_ID || 'juris_law_chunks_deployed';
const EMBEDDING_MODEL = 'text-embedding-004';

// Use same region for all Vertex AI calls
const vertexAI = new VertexAI({ project: PROJECT_ID, location: LOCATION });
```

2. **Lines 116-118** - Fix index endpoint path:
```typescript
const [response] = await matchServiceClient.findNeighbors({
  indexEndpoint: INDEX_ENDPOINT_ID, // Already includes full path
  deployedIndexId: DEPLOYED_INDEX_ID,
  // ... rest
});
```

---

## Testing Checklist

- [ ] Deploy updated functions
- [ ] Upload test image via Flutter app
- [ ] Check Cloud Functions logs for errors
- [ ] Verify OCR extraction in Firestore `documents` collection
- [ ] Verify RAG retrieval (check `rag_chunks_used` count)
- [ ] Verify compliance audit in Firestore `audits` collection
- [ ] Test generateLOD function
- [ ] Test simplifyClause function
- [ ] Monitor memory usage (should be under 1GB)
- [ ] Check execution time (should be under 540s)

---

## Monitoring Commands

```bash
# Watch function logs in real-time
gcloud functions logs read processDocument \
  --project=juris-74a5d \
  --region=asia-southeast1 \
  --limit=50

# Check function configuration
gcloud functions describe processDocument \
  --project=juris-74a5d \
  --region=asia-southeast1 \
  --format=yaml

# Monitor specific errors
gcloud logging read \
  'resource.type="cloud_function" AND severity=ERROR' \
  --project=juris-74a5d \
  --limit=10 \
  --format=json
```

---

## Success Metrics

| Metric | Target | Current |
|--------|--------|---------|
| Document Processing Success Rate | >95% | 0% ❌ |
| OCR Accuracy | >80% | N/A (blocked) |
| RAG Retrieval Success | 100% | N/A (blocked) |
| Average Processing Time | <60s | N/A (blocked) |
| Memory Usage | <900MB | 258MB+ crash ❌ |
| API Error Rate | <1% | 100% ❌ |

---

## Conclusion

The Juris architecture is sound, but the implementation has three critical bugs preventing execution:

1. **Gemini API access method** - Using wrong SDK/endpoint
2. **Multi-region routing** - Unnecessary complexity causing auth issues
3. **Memory configuration** - Not being applied during deployment

**Priority:** FIX GEMINI API ACCESS FIRST. The other issues are secondary.

**Estimated Fix Time:** 1-2 hours total
**Testing Time:** 30 minutes
**Total:** 2-3 hours to full recovery

**Next Steps:**
1. Apply Fix #1 (Gemini API)
2. Deploy and test
3. Apply Fix #2 & #3 if needed
4. Monitor logs and validate full pipeline

---

**Document Version:** 1.0
**Author:** Cloud Architect Agent
**Last Updated:** 2026-02-26
