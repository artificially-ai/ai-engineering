#!/bin/sh

echo "Copying known_hosts from 'ekholabs-mlflow-server' to 'ekholabs-jupyterlab'"
docker cp ekholabs-mlflow-server:/root/.ssh/known_hosts .
docker cp known_hosts ekholabs-jupyterlab:/home/jovyan/.ssh/known_hosts
echo "..."
echo "Done!"
