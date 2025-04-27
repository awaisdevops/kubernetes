#!/bin/bash
# Exit immediately if a command exits with a non-zero status
set -e

# Uninstall the RabbitMQ Helm release
echo "Uninstalling RabbitMQ..."
helm uninstall rabbitmq -n rabbitmq

# Delete the Kubernetes namespace used by RabbitMQ (ignore error if it doesn't exist)
echo "Deleting namespace 'rabbitmq'..."
kubectl delete namespace rabbitmq || true

# Final success message
echo "RabbitMQ uninstalled and cleaned up!"

