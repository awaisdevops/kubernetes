#!/bin/bash
# Exit immediately if a command exits with a non-zero status
set -e

# Upgrade the existing RabbitMQ release using Helm with custom values
echo "Upgrading RabbitMQ..."
helm upgrade rabbitmq bitnami/rabbitmq -n rabbitmq -f charts/rabbitmq-values.yaml

# Final success message
echo "RabbitMQ upgraded successfully!"

