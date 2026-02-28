#!/usr/bin/env bash
# Quick deployment status checker

if command -v gcloud.cmd >/dev/null 2>&1; then
  gcloud() { gcloud.cmd "$@"; }
fi

ENDPOINT_ID="5253352208304439296"
REGION="asia-southeast1"
PROJECT="juris-74a5d"

echo "Checking deployment status..."
echo "Started: $(date)"
echo ""

MAX_ATTEMPTS=20
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
  DEPLOYED=$(gcloud ai index-endpoints describe $ENDPOINT_ID \
    --region=$REGION \
    --project=$PROJECT \
    --format="value(deployedIndexes[0].id)" 2>/dev/null || echo "")

  if [ -n "$DEPLOYED" ]; then
    echo ""
    echo "✓ DEPLOYMENT COMPLETE!"
    echo "  Deployed Index ID: $DEPLOYED"
    echo "  Completed at: $(date)"
    echo ""
    echo "Your Vertex AI Vector Search is now LIVE!"
    exit 0
  fi

  ATTEMPT=$((ATTEMPT + 1))
  ELAPSED=$((ATTEMPT * 2))
  echo "[$ELAPSED min] Still deploying... (attempt $ATTEMPT/$MAX_ATTEMPTS)"
  sleep 120  # Wait 2 minutes
done

echo ""
echo "Timeout after 40 minutes. Check manually:"
echo "  gcloud ai index-endpoints describe $ENDPOINT_ID --region=$REGION"
exit 1
