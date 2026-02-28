#!/usr/bin/env bash
#
# Monitor Vertex AI index creation and complete setup when ready
#

set -euo pipefail

PROJECT_ID="juris-74a5d"
REGION="asia-southeast1"
INDEX_ID="4174981990107316224"
OPERATION_ID="1910882214720045056"
ENDPOINT_DISPLAY_NAME="juris-law-chunks-endpoint"
DEPLOYED_INDEX_ID="juris-law-chunks-deployed"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WAIT]${NC}  $*"; }

# Prefer Windows .cmd shims in Git Bash
if command -v gcloud.cmd >/dev/null 2>&1; then
  gcloud() { gcloud.cmd "$@"; }
fi

info "Monitoring index creation (ID: ${INDEX_ID})..."
info "Started at: $(date)"
echo ""

# Poll every 2 minutes until index is ready
ELAPSED=0
while true; do
  # Check if index exists and is ready
  INDEX_STATE=$(gcloud ai indexes list \
    --region="${REGION}" \
    --project="${PROJECT_ID}" \
    --filter="name:${INDEX_ID}" \
    --format="value(name)" 2>/dev/null || echo "")

  if [[ -n "${INDEX_STATE}" ]]; then
    info "✓ Index created successfully!"
    break
  fi

  ELAPSED=$((ELAPSED + 2))
  warn "Index still building... (${ELAPSED} minutes elapsed)"
  sleep 120  # Wait 2 minutes
done

info "Index is ready! Proceeding with endpoint creation..."

# Step 2: Create Index Endpoint
info "Creating Vector Search Index Endpoint..."

EXISTING_ENDPOINT=$(gcloud ai index-endpoints list \
  --region="${REGION}" \
  --project="${PROJECT_ID}" \
  --filter="displayName:${ENDPOINT_DISPLAY_NAME}" \
  --format="value(name)" 2>/dev/null || echo "")

if [[ -n "${EXISTING_ENDPOINT}" ]]; then
  warn "Endpoint already exists: ${EXISTING_ENDPOINT}"
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

# Extract short IDs
SHORT_INDEX_ID=$(echo "${INDEX_ID}" | grep -oP '[0-9]+$' || echo "${INDEX_ID}")
SHORT_ENDPOINT_ID=$(echo "${ENDPOINT_ID}" | grep -oP '[0-9]+$' || echo "${ENDPOINT_ID}")

info "Short Index ID: ${SHORT_INDEX_ID}"
info "Short Endpoint ID: ${SHORT_ENDPOINT_ID}"

# Step 3: Deploy index to endpoint
info "Deploying index to endpoint..."

gcloud ai index-endpoints deploy-index "${SHORT_ENDPOINT_ID}" \
  --region="${REGION}" \
  --project="${PROJECT_ID}" \
  --deployed-index-id="${DEPLOYED_INDEX_ID}" \
  --index="${SHORT_INDEX_ID}" \
  --display-name="${DEPLOYED_INDEX_ID}" \
  --min-replica-count=1 \
  --max-replica-count=2

info "Deployment initiated (this takes 10-20 minutes)..."

# Wait for deployment to complete
sleep 30
info "Checking deployment status..."

# Poll for deployment completion
while true; do
  DEPLOYMENT_STATE=$(gcloud ai index-endpoints describe "${SHORT_ENDPOINT_ID}" \
    --region="${REGION}" \
    --project="${PROJECT_ID}" \
    --format="value(deployedIndexes[0].id)" 2>/dev/null || echo "")

  if [[ "${DEPLOYMENT_STATE}" == "${DEPLOYED_INDEX_ID}" ]]; then
    info "✓ Index deployed successfully!"
    break
  fi

  warn "Deployment still in progress..."
  sleep 60
done

# Output final configuration
echo ""
echo "======================================================================"
echo "  ✓ Vertex AI Vector Search Setup Complete!"
echo "======================================================================"
echo ""
echo "Update your functions/.env file with these values:"
echo ""
echo "VECTOR_SEARCH_ENDPOINT=${ENDPOINT_ID}"
echo "DEPLOYED_INDEX_ID=${DEPLOYED_INDEX_ID}"
echo ""
echo "Full details:"
echo "  Project:           ${PROJECT_ID}"
echo "  Region:            ${REGION}"
echo "  Index ID:          ${INDEX_ID}"
echo "  Endpoint ID:       ${ENDPOINT_ID}"
echo "  Deployed Index:    ${DEPLOYED_INDEX_ID}"
echo ""
echo "Completed at: $(date)"
echo "======================================================================"
