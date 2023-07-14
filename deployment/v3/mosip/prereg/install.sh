#!/bin/bash
# Installs all prereg helm charts
## Usage: ./install.sh [kubeconfig]

if [ $# -ge 1 ] ; then
  export KUBECONFIG=$1
fi

NS=prereg
CHART_VERSION=12.0.1-B2

echo Create $NS namespace
kubectl create ns $NS

function installing_prereg() {
  echo Istio label
  ## TODO: Istio proxy disabled for now as prereui does not come up if
  ## envoy filter container gets installed after prereg container.
  kubectl label ns $NS istio-injection=disabled --overwrite
  helm repo update

  echo Copy configmaps
  sed -i 's/\r$//' copy_cm.sh
  ./copy_cm.sh

  API_HOST=`kubectl get cm global -o jsonpath={.data.mosip-api-host}`
  PREREG_HOST=`kubectl get cm global -o jsonpath={.data.mosip-prereg-host}`

  echo Install prereg-gateway
  helm -n $NS install prereg-gateway mosip/prereg-gateway --set istio.hosts[0]=$PREREG_HOST --version $CHART_VERSION

  echo Installing prereg-captcha
  helm -n $NS install prereg-captcha mosip/prereg-captcha --set image.repository=technogovstack/pre-registration-captcha-service --set image.tag=release-1.2.0.1.1 --version $CHART_VERSION

  echo Installing prereg-application
  helm -n $NS install prereg-application mosip/prereg-application --set image.repository=technogovstack/pre-registration-application-service --set image.tag=release-1.2.0.1 --version $CHART_VERSION

  echo Installing prereg-booking
  helm -n $NS install prereg-booking mosip/prereg-booking --set image.repository=technogovstack/pre-registration-booking-service --set image.tag=release-1.2.0.1 --version $CHART_VERSION

  echo Installing prereg-datasync
  helm -n $NS install prereg-datasync mosip/prereg-datasync --set image.repository=technogovstack/pre-registration-datasync-service --set image.tag=release-1.2.0.1.1 --version $CHART_VERSION

  echo Installing prereg-batchjob
  helm -n $NS install prereg-batchjob mosip/prereg-batchjob --set image.repository=technogovstack/pre-registration-batchjob --set image.tag=release-1.2.0.1.1 --version $CHART_VERSION

  echo Installing prereg-ui
  helm -n $NS install prereg-ui mosip/prereg-ui --set image.repository=technogovstack/pre-registration-ui --set image.tag=release-1.2.0.1.1 --set prereg.apiHost=$PREREG_HOST --version $CHART_VERSION

  echo Installing prereg rate-control Envoyfilter
  kubectl apply -n $NS -f rate-control-envoyfilter.yaml

  kubectl -n $NS  get deploy -o name |  xargs -n1 -t  kubectl -n $NS rollout status

  echo Installed prereg services
  return 0
}

# set commands for error handling.
set -e
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errtrace  # trace ERR through 'time command' and other functions
set -o pipefail  # trace ERR through pipes
installing_prereg   # calling function