#!/bin/bash
# Copy configmaps from other namespaces
# DST_NS: Destination namespace 

COPY_UTIL=../../utils/copy_cm_func.sh
DST_NS=idbb-onboarder

$COPY_UTIL configmap global default $DST_NS
$COPY_UTIL configmap keycloak-env-vars idbb-keycloak $DST_NS
$COPY_UTIL configmap keycloak-host idbb-keycloak $DST_NS
