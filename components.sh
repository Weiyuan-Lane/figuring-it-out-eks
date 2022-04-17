#!/bin/sh


# ----- Edit values here if necessary to change -------------------------------
INGRESS_NGINX_CHART_VERSION="4.0.19"        # Version 1.1.3 for Ingress-Nginx
INGRESS_NGINX_RELEASE_NAME="ingress-nginx"
CERT_MANAGER_CHART_VERSION="v1.8.0"         # Version 1.8.0 for Cert Manager
CERT_MANAGER_RELEASE_NAME="cert-manager"
# -----------------------------------------------------------------------------


# ----- Don't edit anything else after this line ------------------------------
bringup() {
  # Bringup metrics server
  kubectl apply -f kubernetes-yaml-configurations/metrics-server/components.yaml

  # Bringup kubernetes Dashboard 
  kubectl apply -f kubernetes-yaml-configurations/kubernetes-dashboard/kubernetes-dashboard.yaml

  # Bringup ingress nginx controller with helm
  helm upgrade -f ./helm-configurations/ingress-nginx/values.yaml $INGRESS_NGINX_RELEASE_NAME ingress-nginx \
    --install \
    --repo https://kubernetes.github.io/ingress-nginx \
    --namespace ingress-nginx \
    --create-namespace \
    --version $INGRESS_NGINX_CHART_VERSION

  # Bringup cert manager with helm
  helm upgrade -f ./helm-configurations/cert-manager/values.yaml $CERT_MANAGER_RELEASE_NAME cert-manager \
    --install \
    --repo https://charts.jetstack.io \
    --namespace cert-manager \
    --create-namespace \
    --version $CERT_MANAGER_CHART_VERSION

  # Bringup cert issuer
  kubectl apply -f kubernetes-yaml-configurations/cert-manager/cert-manager-prod.yaml
}

bringdown() {
  # Uninstall releases before cluster bringdown
  helm uninstall $INGRESS_NGINX_RELEASE_NAME -n ingress-nginx
  helm uninstall $CERT_MANAGER_RELEASE_NAME -n cert-manager
}

_printusage() {
  echo "Usage: \"./components.sh bringup\" OR \"./components.sh bringdown\""
}

while getopts "h" flag; do
  case "${flag}" in
    "h") _printusage; exit 0 ;;
  esac
done

if [ "$#" = "1" ] && [ "$@" = 'bringup' ];then
  bringup
elif [ "$#" = "1" ] && [ "$@" = 'bringdown' ];then
  bringdown
else
  _printusage
fi

