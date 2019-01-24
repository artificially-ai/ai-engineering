#!/bin/sh

echo "Copying known_hosts from 'ekholabs-mlflow-server' to 'ekholabs-jupyterlab'"
docker cp ekholabs-mlflow:/root/.ssh/known_hosts .
docker cp known_hosts ekholabs-jupyterlab:/home/jovyan/.ssh/known_hosts
rm known_hosts
echo "..."
echo "Done!"
