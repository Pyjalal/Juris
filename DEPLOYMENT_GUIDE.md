# Juris Deployment Guide

> Complete step-by-step guide to deploy Juris for KitaHack 2026
> **Current Status:** Code complete, initial commit done
> **Days Remaining:** 5 days to Feb 28, 2026

---

## Prerequisites Installed ✓

- [x] Flutter SDK 3.38.5 at `C:\tools\flutter\bin`
- [x] Firebase CLI v15.7.0 (npm global)
- [x] Node.js v22.16.0
- [x] Git initialized with initial commit `b1b8363`

---

## Phase 1: Firebase Project Setup

### Step 1.1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **Add project**
3. Enter project name: `juris-kitahack`
4. Disable Google Analytics (not needed for hackathon)
5. Click **Create project**
6. Wait for provisioning to complete

### Step 1.2: Enable Firebase Services

In the Firebase Console for `juris-kitahack`:

**Authentication:**
1. Go to **Build → Authentication**
2. Click **Get started**
3. Enable **Anonymous** sign-in method
4. Click **Save**

**Firestore Database:**
1. Go to **Build → Firestore Database**
2. Click **Create database**
3. Select **Start in production mode**
4. Choose location: **asia-southeast1 (Singapore)**
5. Click **Enable**

**Cloud Storage:**
1. Go to **Build → Storage**
2. Click **Get started**
3. Select **Start in production mode**
4. Choose location: **asia-southeast1**
5. Click **Done**

**Cloud Functions:**
1. Go to **Build → Functions**
2. Click **Get started** (this just enables the service)
3. No action needed yet — we'll deploy functions later

### Step 1.3: Add Firebase to Flutter App

**For Android:**

1. In Firebase Console, click the **Android icon** to add an Android app
2. Enter Android package name: `com.juris.juris_app` (from `AndroidManifest.xml`)
3. Leave app nickname blank
4. Leave Debug signing certificate SHA-1 blank (not needed for dev)
5. Click **Register app**
6. Download `google-services.json`
7. Move it to: `C:\Users\Shahjalal\Documents\kita\juris_app\android\app\google-services.json`
8. Click **Next** through the remaining steps (dependencies already added)
9. Click **Continue to console**

**For iOS (optional for hackathon):**

1. In Firebase Console, click the **iOS icon**
2. Enter iOS bundle ID: `com.juris.jurisApp`
3. Download `GoogleService-Info.plist`
4. Move it to: `C:\Users\Shahjalal\Documents\kita\juris_app\ios\Runner\GoogleService-Info.plist`

**Verify Flutter configuration:**

```bash
cd C:\Users\Shahjalal\Documents\kita\juris_app
export PATH="$PATH:/c/tools/flutter/bin"
flutter pub get
flutterfire configure --project=juris-kitahack
```

This will auto-detect your Firebase project and generate platform-specific config files.

---

## Phase 2: Google Cloud Project Setup

### Step 2.1: Link Firebase to Google Cloud

1. In Firebase Console, click the **gear icon** → **Project settings**
2. Note the **Project ID** (should be `juris-kitahack`)
3. Click **Service accounts** tab
4. Click **Manage service account permissions** (opens Google Cloud Console)
5. You're now in the Google Cloud Console for the same project

### Step 2.2: Enable Required APIs

In [Google Cloud Console](https://console.cloud.google.com/):

1. Ensure project `juris-kitahack` is selected (top navigation bar)
2. Go to **APIs & Services → Library**
3. Search for and enable each of these:
   - **Vertex AI API**
   - **Cloud Functions API** (should already be enabled)
   - **Cloud Storage API** (should already be enabled)
   - **Firestore API** (should already be enabled)
   - **Cloud Build API** (needed for Functions deployment)
   - **Artifact Registry API** (needed for Functions deployment)

### Step 2.3: Set Up Billing (Required)

1. Go to **Billing** in Google Cloud Console
2. Link a billing account (required for Cloud Functions and Vertex AI)
3. If you don't have one, click **Create billing account**
4. Add payment method (Google provides free tier credits)

**Free tier coverage:**
- Firestore: 1 GB storage, 50K reads/day, 20K writes/day
- Cloud Storage: 5 GB, 1 GB/month transfer
- Cloud Functions: 2M invocations/month
- Vertex AI: $300 free credits (usually enough for hackathon testing)

---

## Phase 3: Vertex AI Setup

### Step 3.1: Enable Vertex AI and Create Vector Search Index

Run the provisioning script from the project root:

```bash
cd C:\Users\Shahjalal\Documents\kita
bash scripts/setup-vertex-ai.sh
```

This script will:
1. Validate `gcloud` CLI is installed
2. Set the active project to `juris-kitahack`
3. Enable Vertex AI API
4. Create a GCS bucket: `juris-kitahack-vectors`
5. Create a Vertex AI Vector Search Index (tree-AH, 768 dims, DOT_PRODUCT)
6. Create a public Index Endpoint
7. Deploy the index to the endpoint
8. Output the endpoint ID and deployed index ID

**Expected output:**
```
✓ Vertex AI Vector Search Index deployed successfully

ENDPOINT_ID=projects/123456789/locations/asia-southeast1/indexEndpoints/1234567890123456789
DEPLOYED_INDEX_ID=deployed_index_12345

Copy these values to functions/.env:
VECTOR_SEARCH_ENDPOINT=projects/123456789/locations/asia-southeast1/indexEndpoints/1234567890123456789
DEPLOYED_INDEX_ID=deployed_index_12345
```

### Step 3.2: Configure Cloud Functions Environment Variables

1. Copy `functions/.env.example` to `functions/.env`:
   ```bash
   cp functions/.env.example functions/.env
   ```

2. Edit `functions/.env` and add the values from the script output:
   ```
   GCLOUD_PROJECT=juris-kitahack
   VECTOR_SEARCH_ENDPOINT=projects/123456789/locations/asia-southeast1/indexEndpoints/1234567890123456789
   DEPLOYED_INDEX_ID=deployed_index_12345
   ```

---

## Phase 4: Seed Law Corpus

### Step 4.1: Run the Law Chunks Seeder

This populates Firestore with the 24 pre-chunked Malaysian law sections:

```bash
cd C:\Users\Shahjalal\Documents\kita\functions
npm install
npm run seed-law-chunks
```

**Expected output:**
```
Seeding law chunks to Firestore...
✓ Uploaded 24 law chunks to law_chunks collection
✓ All chunks uploaded successfully
```

### Step 4.2: Verify in Firestore Console

1. Go to Firebase Console → Firestore Database
2. You should see a `law_chunks` collection with 24 documents
3. Each document should have fields: `actName`, `sectionNumber`, `content`, `embedding`, etc.

---

## Phase 5: Deploy Backend

### Step 5.1: Deploy Firestore Rules and Indexes

```bash
cd C:\Users\Shahjalal\Documents\kita
firebase deploy --only firestore:rules,firestore:indexes
```

**Expected output:**
```
✓ Deploy complete!

Firestore Rules:
  Ruleset deployed successfully
Firestore Indexes:
  3 indexes created
```

### Step 5.2: Deploy Storage Rules

```bash
firebase deploy --only storage
```

### Step 5.3: Deploy Cloud Functions

```bash
cd C:\Users\Shahjalal\Documents\kita
firebase deploy --only functions
```

This will deploy 3 functions:
- `processDocument` (Storage trigger)
- `generateLOD` (HTTPS callable)
- `simplifyClause` (HTTPS callable)

**Expected output:**
```
✓ functions[asia-southeast1-processDocument]: Successful create operation.
✓ functions[asia-southeast1-generateLOD]: Successful create operation.
✓ functions[asia-southeast1-simplifyClause]: Successful create operation.

Deploy complete!
```

**Troubleshooting:**
- If deployment fails with "billing not enabled", ensure billing is set up in Step 2.3
- If it fails with "Cloud Build API not enabled", enable it in Step 2.2
- First deployment may take 5-10 minutes

---

## Phase 6: Test the Full Pipeline

### Step 6.1: Build Flutter App

**For Android:**

```bash
cd C:\Users\Shahjalal\Documents\kita\juris_app
export PATH="$PATH:/c/tools/flutter/bin"
flutter build apk --debug
```

The APK will be at: `build/app/outputs/flutter-apk/app-debug.apk`

**For Web (optional):**

```bash
flutter build web
firebase deploy --only hosting
```

### Step 6.2: Run on Emulator or Device

**Android Emulator:**

```bash
flutter run
```

**Physical Android Device:**

1. Enable Developer Options and USB Debugging on your phone
2. Connect via USB
3. Run `flutter devices` to verify detection
4. Run `flutter run`

### Step 6.3: Test End-to-End Flow

1. Open the app
2. Tap **Scan Your Agreement**
3. Take a photo of a sample tenancy agreement (or use a pre-made test image)
4. Wait for processing (30-60 seconds)
5. Verify results screen shows:
   - Risk score gauge
   - Summary chips
   - Flagged clauses (if any)
6. Tap **Generate Letter of Demand**
7. Fill in tenant/landlord details
8. Verify letter generates successfully

**Test Images:**

Create 2-3 sample tenancy agreement images with:
- Clear text (typed, not handwritten)
- Standard A4 format
- Mix of legal and illegal clauses

Example clauses to include:
- Legal: "Rent payable on 1st of each month"
- Illegal: "Tenant forfeits entire deposit for any breach" (violates Contracts Act 1950 Section 75)
- Unfair: "Landlord may terminate with 24 hours notice"

---

## Phase 7: Prepare Demo Materials

### Step 7.1: Record Demo Video

**Requirements:**
- Max 5 minutes
- Must show: problem statement, live demo, architecture, impact
- Upload to YouTube as unlisted
- Record in 1080p minimum

**Script structure:**
1. **Problem (30s):** 80% rental disputes unresolved, RM300/hr lawyer cost
2. **Solution (30s):** Juris workflow overview
3. **Live Demo (2.5 min):**
   - Open app
   - Scan agreement
   - Processing animation
   - Results screen with flagged clauses
   - Generate LOD
4. **Technical Architecture (1 min):** Show architecture diagram, explain RAG pipeline
5. **Impact (30s):** SDG 16.3 alignment, 99.95% cost reduction

**Tools:**
- Screen recording: OBS Studio or Windows Game Bar
- Video editing: DaVinci Resolve (free) or CapCut
- Narration: Record with phone or laptop mic in quiet room

### Step 7.2: Conduct User Feedback Interviews

**Required:** 3+ user interviews (worth 10 points)

**Target interviewees:**
1. University student renting off-campus
2. B40 household member currently renting
3. Foreign worker or someone familiar with rental disputes

**Interview questions:**
1. "Have you ever had a dispute with a landlord? What happened?"
2. "Would you use an app like Juris before signing a lease? Why/why not?"
3. "What features would make you trust the AI analysis?"
4. "Would you pay RM5-10 per scan, or prefer subscription?"
5. "Rate the interface (show them screenshots): 1-5 stars"

**Document:**
- Record verbatim quotes
- Note demographics (age, occupation, rental history)
- Summarize insights in 1-2 paragraphs per interviewee
- Include in submission form

### Step 7.3: Create Screenshots

Take 5-6 high-quality screenshots:
1. Home screen (hero section + recent scans)
2. Processing screen (mid-animation)
3. Results screen (risk gauge + flagged clauses)
4. Clause card expanded (showing explanation)
5. LOD form filled in
6. Generated letter preview

**Capture on Android:**
- Use emulator with Pixel 6 skin (1080x2400)
- Or use physical device screenshots
- Use Figma or Photoshop to add device frame

---

## Phase 8: GitHub Repository

### Step 8.1: Create Remote Repository

1. Go to [GitHub](https://github.com/new)
2. Repository name: `juris-kitahack-2026`
3. Description: "AI-powered legal agent for Malaysian tenants | KitaHack 2026"
4. Public repository
5. **Do NOT** initialize with README (we already have one)
6. Click **Create repository**

### Step 8.2: Push Code

```bash
cd C:\Users\Shahjalal\Documents\kita
git remote add origin https://github.com/YOUR_USERNAME/juris-kitahack-2026.git
git branch -M main
git push -u origin main
```

### Step 8.3: Verify Repository

Check that GitHub shows:
- ✓ 172 files
- ✓ 16,055+ lines of code
- ✓ README.md renders correctly with architecture diagram
- ✓ `docs/` folder with all 4 documentation files
- ✓ `.gitignore` excludes sensitive files

---

## Phase 9: Submission Form

### Step 9.1: Gather Required Information

**Project Details:**
- Project name: Juris
- Tagline: AI-powered legal agent for Malaysian tenants
- GitHub URL: `https://github.com/YOUR_USERNAME/juris-kitahack-2026`
- Demo video URL: `https://youtube.com/watch?v=YOUR_VIDEO_ID`

**Google Technologies Used:**
- Firebase (Auth, Firestore, Storage, Cloud Functions)
- Gemini 1.5 Pro (Vision for OCR, Text for analysis)
- Vertex AI (Vector Search for RAG, Embeddings API)
- Google Cloud (Cloud Storage, Cloud KMS, IAM)
- Google Maps Places API (Tribunal finder)

**SDG Alignment:**
- Primary: SDG 16 Target 16.3 (Equal access to justice)
- Secondary: SDG 11 Target 11.1 (Adequate housing for all)

**Team:**
- [Your Name], Full Stack Developer
- Role: Solo developer (all architecture, frontend, backend, AI integration)

**User Feedback Summary:**
- Paste 3+ interview summaries from Step 7.2
- Include quotes and demographic info

**Success Metrics:**
- Goal: Analyze 500 agreements in first 3 months
- Target accuracy: 85%+ compliance detection rate
- Impact: 100 Letters of Demand generated, RM150,000 saved in legal fees

### Step 9.2: Fill Out KitaHack Submission Form

Go to the official KitaHack 2026 submission portal and enter all information gathered above.

---

## Phase 10: Final Pre-Submission Checklist

### Day Before Deadline

- [ ] GitHub repository is public and accessible
- [ ] README.md includes screenshots and architecture diagram
- [ ] All 4 docs in `docs/` are complete and error-free
- [ ] Demo video is uploaded and unlisted on YouTube
- [ ] Video is under 5 minutes
- [ ] All Firebase/GCP services are deployed and working
- [ ] Conducted 3+ user interviews and documented feedback
- [ ] Tested app end-to-end at least 3 times with different sample agreements
- [ ] APK builds successfully (`flutter build apk --release`)
- [ ] All code committed to GitHub (run `git status` to verify clean working tree)
- [ ] Submission form is completely filled out
- [ ] Submission form has been reviewed for typos/errors

### On Deadline Day (Feb 28, 2026)

- [ ] Submit form **at least 2 hours before deadline** (buffer for technical issues)
- [ ] Take screenshot of submission confirmation
- [ ] Download a local backup of GitHub repo as ZIP
- [ ] Export Firestore data as backup (optional but recommended)

---

## Troubleshooting Common Issues

### "Firebase: No Firebase App '[DEFAULT]' has been created"

**Fix:** Ensure `google-services.json` is at `android/app/google-services.json` and run `flutter clean && flutter pub get`

### "Cloud Function deployment fails with 'permission denied'"

**Fix:**
```bash
gcloud auth login
gcloud config set project juris-kitahack
firebase login --reauth
```

### "Vertex AI Vector Search index creation fails"

**Fix:** Ensure billing is enabled. Vector Search requires a billing account. Check `gcloud billing accounts list` and link it to the project.

### "Flutter build fails with Gradle error"

**Fix:**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk
```

### "OCR confidence is always low in testing"

**Fix:** Use high-quality test images:
- Take photos in bright, even lighting
- Ensure document is flat (no folds/creases)
- Use landscape orientation for A4 documents
- Keep phone parallel to document (not at an angle)

### "generateLOD function times out"

**Fix:** The function has a 120s timeout. If Gemini is slow:
1. Check Gemini API quotas in Google Cloud Console
2. Verify the RAG context isn't too large (should be <10 law sections)
3. Check Cloud Functions logs: `firebase functions:log`

---

## Cost Estimation

### Free Tier (No Cost)

With Google Cloud free tier + Firebase Spark plan:
- **Firestore:** 50K reads/day, 20K writes/day (enough for 100+ users/day)
- **Cloud Functions:** 2M invocations/month (enough for 30K+ analyses)
- **Cloud Storage:** 5 GB (enough for 10,000+ images)

### Vertex AI (Paid)

**Vector Search:**
- Index deployment: ~$0.10/hour = $72/month if kept running 24/7
- **Optimization:** Deploy only during demo, undeploy after submission

**Gemini API:**
- Vision OCR: ~$0.0025/image
- Text analysis: ~$0.005/analysis
- 100 test runs = ~$0.75 total

**Total for hackathon:** <$5 if you undeploy Vector Search index after demo

---

## Timeline (5 Days to Deadline)

### Day 1 (Today): Backend Deployment
- [ ] Complete Firebase project setup (2 hours)
- [ ] Deploy Firestore rules and seed law corpus (1 hour)
- [ ] Set up Vertex AI and deploy Cloud Functions (3 hours)
- [ ] Test one end-to-end flow (1 hour)

### Day 2: Testing & Bug Fixes
- [ ] Test with 5+ sample agreements (3 hours)
- [ ] Fix any bugs found during testing (4 hours)
- [ ] Optimize prompts if compliance detection is weak (1 hour)

### Day 3: Demo Preparation
- [ ] Conduct 3 user interviews (2 hours)
- [ ] Record demo video (3 hours: setup, recording, editing)
- [ ] Take screenshots (1 hour)
- [ ] Prepare submission form answers (1 hour)

### Day 4: Documentation & Polish
- [ ] Review and polish all docs (2 hours)
- [ ] Update README with final screenshots (1 hour)
- [ ] Create GitHub repo and push code (1 hour)
- [ ] Upload demo video to YouTube (1 hour)
- [ ] Practice demo presentation (2 hours)

### Day 5 (Feb 28): Final Submission
- [ ] Complete final checklist (1 hour)
- [ ] Submit form 2+ hours before deadline
- [ ] Take confirmation screenshot

---

## Support Resources

**Documentation:**
- Firebase: https://firebase.google.com/docs
- Flutter: https://docs.flutter.dev
- Vertex AI: https://cloud.google.com/vertex-ai/docs
- Gemini API: https://ai.google.dev/docs

**Community:**
- KitaHack Discord/Slack (if available)
- Firebase Discord: https://discord.gg/firebase
- Flutter Discord: https://discord.gg/flutter

**Emergency Contacts:**
- [Your email/phone for team coordination]

---

**Last Updated:** 2026-02-23
**Document Version:** 1.0
**Status:** Ready for deployment
