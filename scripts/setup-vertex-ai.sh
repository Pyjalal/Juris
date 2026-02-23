#!/usr/bin/env bash
#
# setup-vertex-ai.sh
#
# Provisions the Vertex AI Vector Search infrastructure for Juris.
# This script creates:
#   1. A GCS bucket to store the embedding JSONL files
#   2. A Vertex AI Vector Search Index (tree-AH algorithm)
#   3. A Vector Search Index Endpoint
#   4. Deploys the index to the endpoint
#
# Prerequisites:
#   - gcloud CLI authenticated with a project-owner or editor role
#   - The embedding JSONL file has already been generated and is available
#     at gs://juris-kitahack-vectors/embeddings/law_chunks.json
#
# Usage:
#   chmod +x scripts/setup-vertex-ai.sh
#   ./scripts/setup-vertex-ai.sh
#
# ----------------------------------------------------------------------

set -euo pipefail

# ---- Configuration ---------------------------------------------------

PROJECT_ID="juris-kitahack"
REGION="asia-southeast1"
BUCKET_NAME="juris-kitahack-vectors"
INDEX_DISPLAY_NAME="juris-law-chunks-index"
ENDPOINT_DISPLAY_NAME="juris-law-chunks-endpoint"
EMBEDDINGS_GCS_URI="gs://${BUCKET_NAME}/embeddings"
EMBEDDING_DIMENSION=768  # text-embedding-004 output dimension

# ---- Colour helpers --------------------------------------------------

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Colour

info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# ---- Pre-flight checks -----------------------------------------------

info "Verifying gcloud CLI is installed and authenticated..."
command -v gcloud >/dev/null 2>&1 || error "gcloud CLI is not installed. See https://cloud.google.com/sdk/docs/install"

ACTIVE_PROJECT=$(gcloud config get-value project 2>/dev/null)
if [[ "${ACTIVE_PROJECT}" != "${PROJECT_ID}" ]]; then
  warn "Active project is '${ACTIVE_PROJECT}', switching to '${PROJECT_ID}'..."
  gcloud config set project "${PROJECT_ID}"
fi

info "Enabling required APIs..."
gcloud services enable aiplatform.googleapis.com \
                        storage.googleapis.com \
                        compute.googleapis.com \
  --project="${PROJECT_ID}" --quiet

# ---- Step 1: Create GCS bucket for vector embeddings ----------------

info "Creating GCS bucket gs://${BUCKET_NAME} (if it does not already exist)..."
if gsutil ls -b "gs://${BUCKET_NAME}" >/dev/null 2>&1; then
  warn "Bucket gs://${BUCKET_NAME} already exists. Skipping creation."
else
  gsutil mb -p "${PROJECT_ID}" -l "${REGION}" -b on "gs://${BUCKET_NAME}"
  info "Bucket gs://${BUCKET_NAME} created."
fi

# Verify the embeddings file exists
info "Checking for embeddings JSONL at ${EMBEDDINGS_GCS_URI}/..."
if ! gsutil ls "${EMBEDDINGS_GCS_URI}/law_chunks.json" >/dev/null 2>&1; then
  warn "Embeddings file not found at ${EMBEDDINGS_GCS_URI}/law_chunks.json"
  warn "Please upload your embeddings JSONL before deploying the index."
  warn "Expected format: one JSON object per line with 'id' and 'embedding' fields."
  warn ""
  warn "  Example:"
  warn '  {"id": "chunk_001", "embedding": [0.012, -0.034, ...]}'
  warn ""
  warn "Upload command:"
  warn "  gsutil cp ./embeddings/law_chunks.json ${EMBEDDINGS_GCS_URI}/law_chunks.json"
  warn ""
  warn "Continuing with infrastructure setup..."
fi

# ---- Step 2: Create Vertex AI Vector Search Index --------------------

info "Creating Vertex AI Vector Search Index: ${INDEX_DISPLAY_NAME}..."

# Check if the index already exists
EXISTING_INDEX=$(gcloud ai indexes list \
  --region="${REGION}" \
  --project="${PROJECT_ID}" \
  --filter="displayName=${INDEX_DISPLAY_NAME}" \
  --format="value(name)" 2>/dev/null || true)

if [[ -n "${EXISTING_INDEX}" ]]; then
  warn "Index '${INDEX_DISPLAY_NAME}' already exists: ${EXISTING_INDEX}"
  INDEX_ID="${EXISTING_INDEX}"
else
  # Create the index metadata configuration
  INDEX_METADATA=$(cat <<EOFMETA
{
  "contentsDeltaUri": "${EMBEDDINGS_GCS_URI}",
  "config": {
    "dimensions": ${EMBEDDING_DIMENSION},
    "approximateNeighborsCount": 20,
    "distanceMeasureType": "DOT_PRODUCT_DISTANCE",
    "algorithmConfig": {
      "treeAhConfig": {
        "leafNodeEmbeddingCount": 500,
        "leafNodesToSearchPercent": 10
      }
    }
  }
}
EOFMETA
)

  # Write metadata to a temporary file
  METADATA_FILE=$(mktemp /tmp/juris-index-metadata.XXXXXX.json)
  echo "${INDEX_METADATA}" > "${METADATA_FILE}"

  INDEX_OPERATION=$(gcloud ai indexes create \
    --region="${REGION}" \
    --project="${PROJECT_ID}" \
    --display-name="${INDEX_DISPLAY_NAME}" \
    --description="Juris Malaysian tenancy law corpus embeddings for RAG retrieval" \
    --metadata-file="${METADATA_FILE}" \
    --format="value(name)" 2>&1)

  rm -f "${METADATA_FILE}"

  info "Index creation initiated. This is a long-running operation (15-30 minutes)."
  info "Operation: ${INDEX_OPERATION}"

  # Extract the operation ID and wait for it
  OPERATION_NAME=$(echo "${INDEX_OPERATION}" | grep -oP 'operations/\K[0-9]+' || echo "")

  if [[ -n "${OPERATION_NAME}" ]]; then
    info "Waiting for index creation to complete (this may take 15-30 minutes)..."
    gcloud ai operations wait "${OPERATION_NAME}" \
      --region="${REGION}" \
      --project="${PROJECT_ID}" 2>/dev/null || true
  fi

  # Retrieve the created index ID
  INDEX_ID=$(gcloud ai indexes list \
    --region="${REGION}" \
    --project="${PROJECT_ID}" \
    --filter="displayName=${INDEX_DISPLAY_NAME}" \
    --format="value(name)" 2>/dev/null)

  if [[ -z "${INDEX_ID}" ]]; then
    error "Failed to retrieve index ID. Check the Cloud Console for status."
  fi

  info "Index created: ${INDEX_ID}"
fi

# Extract the short index ID (numeric portion)
SHORT_INDEX_ID=$(echo "${INDEX_ID}" | grep -oP '[0-9]+$')
info "Short Index ID: ${SHORT_INDEX_ID}"

# ---- Step 3: Create Vertex AI Index Endpoint ------------------------

info "Creating Vertex AI Index Endpoint: ${ENDPOINT_DISPLAY_NAME}..."

EXISTING_ENDPOINT=$(gcloud ai index-endpoints list \
  --region="${REGION}" \
  --project="${PROJECT_ID}" \
  --filter="displayName=${ENDPOINT_DISPLAY_NAME}" \
  --format="value(name)" 2>/dev/null || true)

if [[ -n "${EXISTING_ENDPOINT}" ]]; then
  warn "Endpoint '${ENDPOINT_DISPLAY_NAME}' already exists: ${EXISTING_ENDPOINT}"
  ENDPOINT_ID="${EXISTING_ENDPOINT}"
else
  ENDPOINT_ID=$(gcloud ai index-endpoints create \
    --region="${REGION}" \
    --project="${PROJECT_ID}" \
    --display-name="${ENDPOINT_DISPLAY_NAME}" \
    --description="Juris Vector Search endpoint for Malaysian law RAG" \
    --public-endpoint-enabled \
    --format="value(name)" 2>&1)

  info "Endpoint created: ${ENDPOINT_ID}"
fi

# Extract the short endpoint ID (numeric portion)
SHORT_ENDPOINT_ID=$(echo "${ENDPOINT_ID}" | grep -oP '[0-9]+$')
info "Short Endpoint ID: ${SHORT_ENDPOINT_ID}"

# ---- Step 4: Deploy the index to the endpoint -----------------------

DEPLOYED_INDEX_DISPLAY_NAME="juris-law-chunks-deployed"

info "Deploying index to endpoint..."
info "  Index:    ${INDEX_ID}"
info "  Endpoint: ${ENDPOINT_ID}"

gcloud ai index-endpoints deploy-index "${SHORT_ENDPOINT_ID}" \
  --region="${REGION}" \
  --project="${PROJECT_ID}" \
  --deployed-index-id="${DEPLOYED_INDEX_DISPLAY_NAME}" \
  --index="${SHORT_INDEX_ID}" \
  --display-name="${DEPLOYED_INDEX_DISPLAY_NAME}" \
  --min-replica-count=1 \
  --max-replica-count=2

info "Index deployment initiated. This may take 10-20 minutes."

# ---- Step 5: Output configuration values ----------------------------

echo ""
echo "======================================================================"
echo "  Vertex AI Vector Search Setup Complete"
echo "======================================================================"
echo ""
echo "  Add these values to your functions/.env file:"
echo ""
echo "    GCLOUD_PROJECT=${PROJECT_ID}"
echo "    VECTOR_SEARCH_ENDPOINT=${SHORT_ENDPOINT_ID}"
echo "    DEPLOYED_INDEX_ID=${DEPLOYED_INDEX_DISPLAY_NAME}"
echo ""
echo "  GCS Bucket:         gs://${BUCKET_NAME}"
echo "  Index ID:           ${SHORT_INDEX_ID}"
echo "  Endpoint ID:        ${SHORT_ENDPOINT_ID}"
echo "  Deployed Index ID:  ${DEPLOYED_INDEX_DISPLAY_NAME}"
echo "  Region:             ${REGION}"
echo ""
echo "  Next steps:"
echo "    1. Upload embeddings:  gsutil cp ./embeddings/law_chunks.json ${EMBEDDINGS_GCS_URI}/"
echo "    2. Update the index:   gcloud ai indexes update ${SHORT_INDEX_ID} --region=${REGION} --metadata-file=metadata.json"
echo "    3. Copy .env values:   cp functions/.env.example functions/.env and fill in above values"
echo "    4. Deploy functions:   cd functions && npm run deploy"
echo ""
echo "======================================================================"
