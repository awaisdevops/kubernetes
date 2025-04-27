#!/bin/bash
# Exit immediately if a command exits with a non-zero status
set -e

# Add Bitnami Helm chart repository
echo "Adding Bitnami repository..."
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Create Kubernetes namespace for RabbitMQ (ignore error if it already exists)
echo "Creating namespace 'rabbitmq'..."
kubectl create namespace rabbitmq || true

# Install RabbitMQ using Helm with custom values file
echo "Installing RabbitMQ with custom values..."
helm install rabbitmq bitnami/rabbitmq -n rabbitmq -f charts/rabbitmq-values.yaml

# Final success message
echo "RabbitMQ installation initiated successfully!"

