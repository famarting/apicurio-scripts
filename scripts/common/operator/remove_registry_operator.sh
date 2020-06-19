#!/usr/bin/env bash
case "$OSTYPE" in
  darwin*)  READLINK=greadlink;;
  *)        READLINK=readlink;;
esac

CURRENT_DIR=`${READLINK} -f \`dirname $0\``
source ${CURRENT_DIR}/../../utils/functions.sh

requiredEnvVar OPERATOR_REPO_DIR $OPERATOR_REPO_DIR

REPLACED_FILE=$REPLACED_CONTENT_DIR/operator-service-registry.yaml

oc delete -f $REPLACED_FILE

sleep 5

oc delete -f $OPERATOR_REPO_DIR/deploy/operator.yaml
oc delete -f $OPERATOR_REPO_DIR/deploy/crds/apicur.io_apicurioregistries_crd.yaml
oc delete -f $OPERATOR_REPO_DIR/deploy/cluster_role_binding.yaml
oc delete -f $OPERATOR_REPO_DIR/deploy/cluster_role.yaml
oc delete -f $OPERATOR_REPO_DIR/deploy/role_binding.yaml
oc delete -f $OPERATOR_REPO_DIR/deploy/role.yaml
oc delete -f $OPERATOR_REPO_DIR/deploy/service_account.yaml