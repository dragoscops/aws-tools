BUCKET1=$1
BUCKET2=$2

echo "Comparing S3 buckets: $BUCKET1 vs $BUCKET2"

for setting in \
    get-bucket-location \
    get-bucket-encryption \
    get-bucket-acl \
    get-bucket-policy \
    get-bucket-versioning \
    get-bucket-accelerate-configuration \
    get-public-access-block \
    get-bucket-logging \
    get-bucket-lifecycle-configuration \
    get-bucket-cors \
    get-bucket-replication
do
    echo "=== $setting ==="
    echo "--- $BUCKET1 ---"
    aws s3api "$setting" --bucket "$BUCKET1" --region "$AWS_REGION" 2>/dev/null | jq '.' || echo "N/A"
    echo "--- $BUCKET2 ---"
    aws s3api "$setting" --bucket "$BUCKET2" --region "$AWS_REGION" 2>/dev/null | jq '.' || echo "N/A"
    echo ""
    read 
done
