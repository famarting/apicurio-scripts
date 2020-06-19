#!/usr/bin/env bash
case "$OSTYPE" in
  darwin*)  READLINK=greadlink;;
  *)        READLINK=readlink;;
esac

CURRENT_DIR=`${READLINK} -f \`dirname $0\``
source ${CURRENT_DIR}/../../utils/functions.sh

requiredEnvVar OPERATOR_REPO_DIR $OPERATOR_REPO_DIR
requiredEnvVar NAMESPACE $NAMESPACE
requiredEnvVar OPERATOR_IMAGE $OPERATOR_IMAGE
requiredEnvVar BOOTSTRAP_SERVERS $BOOTSTRAP_SERVERS
requiredEnvVar REGISTRY_IMAGE $REGISTRY_IMAGE
requiredEnvVar REGISTRY_LOG_LEVEL $REGISTRY_LOG_LEVEL

deployRegistryOperator

DEPLOYMENT_FILE=$TEMPLATES_DIR/registry/operator/service-registry-streams.yaml
REPLACED_FILE=$REPLACED_CONTENT_DIR/operator-service-registry.yaml
applyRegistryCR $DEPLOYMENT_FILE $REPLACED_FILE

waitRegistryDeploymentViaOperator "streams"