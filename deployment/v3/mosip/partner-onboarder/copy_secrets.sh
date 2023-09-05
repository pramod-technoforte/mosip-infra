#!/bin/bash
# Copy secrets from other namespaces
# DST_NS: Destination namespace

COPY_UTIL=../../utils/copy_cm_func.sh
DST_NS=idbb-onboarder

$COPY_UTIL secret s3 idbb-s3 $DST_NS
$COPY_UTIL secret keycloak idbb-keycloak $DST_NS
$COPY_UTIL secret keycloak-client-secrets idbb-keycloak $DST_NS
