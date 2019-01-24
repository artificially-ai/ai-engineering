#!/bin/sh

echo "Creating experiments on MLflow Tracking Server..."
echo "..."
echo "Creating experiment using Minio as storage..."
docker exec -it ekholabs-mlflow /bin/sh -c "mlflow experiments create ekholabs-minio-storage --artifact-location s3://ai-models"
echo "..."
echo "Creating experiment using SFTP as storage..."
docker exec -it ekholabs-mlflow /bin/sh -c "mlflow experiments create ekholabs-sftp-storage --artifact-location sftp://ekho@ekholabs-sftp/storage"
echo "..."
echo "Done!"
