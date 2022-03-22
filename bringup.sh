#!/bin/sh

# Metrics server
kubectl apply -f metrics-server/components.yaml

# Kubernetes Dashboard 
kubectl apply -f kubernetes-dashboard/kubernetes-dashboard.yaml
