#!/bin/bash
# Copy configmaps from other namespaces
# DST_NS: Destination (current) namespace 
COPY_UTIL=../../utils/copy_cm_func.sh
DST_NS=idbb-kernel

$COPY_UTIL configmap global default $DST_NS 
$COPY_UTIL configmap artifactory-share idbb-artifactory $DST_NS 
$COPY_UTIL configmap config-server-share idbb-config-server $DST_NS
$COPY_UTIL configmap softhsm-kernel-share idbb-softhsm $DST_NS




