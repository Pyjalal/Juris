#!/bin/bash

#
# Deploy Juris Cloud Functions with Architecture Fixes
#
# This script deploys the updated Cloud Functions with:
# 1. Fixed Gemini API access via Generative Language API
# 2. Consolidated to single region (asia-southeast1)
# 3. Correct memory configuration (1GB)
#

set -e

PROJECT_ID="juris-74a5d"
REGION="asia-southeast1"

echo "==================================================================="
echo "Deploying Juris Cloud Functions - Architecture Fixes"
echo "==================================================================="
echo ""
echo "Project: $PROJECT_ID"
echo "Region: $REGION"
echo ""

# Check if we're in the correct directory
if [ ! -f "firebase.json" ]; then
  echo "Error: firebase.json not found. Please run this script from the project root."
  exit 1
fi

# Step 1: Install dependencies
echo "Step 1: Installing function dependencies..."
cd functions
npm install
echo "✓ Dependencies installed"
echo ""

# Step 2: Build TypeScript
echo "Step 2: Building TypeScript..."
npm run build
echo "✓ Build complete"
echo ""

# Step 3: Verify build output
if [ ! -f "lib/index.js" ]; then
  echo "Error: Build failed - lib/index.js not found"
  exit 1
fi

if [ ! -f "lib/gemini-client.js" ]; then
  echo "Error: Build failed - lib/gemini-client.js not found"
  exit 1
fi

echo "✓ Build verification passed"
echo ""

cd ..

# Step 4: Deploy functions
echo "Step 3: Deploying Cloud Functions..."
echo ""

# Deploy all functions with explicit region
firebase deploy \
  --only functions \
  --project "$PROJECT_ID" \
  --force

echo ""
echo "==================================================================="
echo "Deployment Complete!"
echo "==================================================================="
echo ""

# Step 5: Verify deployment
echo "Step 4: Verifying deployment..."
echo ""

echo "Checking processDocument configuration..."
gcloud functions describe processDocument \
  --project="$PROJECT_ID" \
  --region="$REGION" \
  --format="table(serviceConfig.availableMemory,serviceConfig.timeoutSeconds)" 2>&1 || echo "Warning: Could not verify processDocument config"

echo ""
echo "Checking generateLOD configuration..."
gcloud functions describe generateLOD \
  --project="$PROJECT_ID" \
  --region="$REGION" \
  --format="table(serviceConfig.availableMemory,serviceConfig.timeoutSeconds)" 2>&1 || echo "Warning: Could not verify generateLOD config"

echo ""
echo "Checking simplifyClause configuration..."
gcloud functions describe simplifyClause \
  --project="$PROJECT_ID" \
  --region="$REGION" \
  --format="table(serviceConfig.availableMemory,serviceConfig.timeoutSeconds)" 2>&1 || echo "Warning: Could not verify simplifyClause config"

echo ""
echo "==================================================================="
echo "Deployment Summary"
echo "==================================================================="
echo ""
echo "Functions deployed:"
echo "  - processDocument (1GB RAM, 540s timeout)"
echo "  - generateLOD (512MB RAM, 300s timeout)"
echo "  - simplifyClause (512MB RAM, 120s timeout)"
echo ""
echo "Key Changes Applied:"
echo "  ✓ Gemini API: Using Generative Language API (REST)"
echo "  ✓ Region: Consolidated to asia-southeast1"
echo "  ✓ Memory: Fixed configuration issues"
echo ""
echo "Next Steps:"
echo "  1. Test document upload via Flutter app"
echo "  2. Monitor logs: gcloud functions logs read processDocument --project=$PROJECT_ID --region=$REGION --limit=50"
echo "  3. Verify OCR extraction in Firestore"
echo "  4. Verify RAG retrieval and compliance analysis"
echo ""
echo "==================================================================="
