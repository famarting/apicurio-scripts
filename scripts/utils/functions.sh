#!/usr/bin/env bash

case "$OSTYPE" in
  darwin*)  READLINK=greadlink;;
  *)        READLINK=readlink;;
esac

CURRENT_DIR=`${READLINK} -f \`dirname $0\``
FUNCTIONS_SCRIPT_DIR=`${READLINK} -f \`dirname $BASH_SOURCE\``

set -a

TEMPLATES_DIR=$FUNCTIONS_SCRIPT_DIR/../../templates
REPLACED_CONTENT_DIR=$FUNCTIONS_SCRIPT_DIR/../../replaced

if [ -z "$ENV_VARS_FILE" ]; then
    echo "Setting ENV_VARS_FILE to default .params file"
    ENV_VARS_FILE=$CURRENT_DIR/.params
fi
if [ -f $ENV_VARS_FILE ]; then
    echo "Loading env vars from file $ENV_VARS_FILE"
    source $ENV_VARS_FILE
fi

set +a

mkdir -p $REPLACED_CONTENT_DIR

# set -x

function requiredEnvVar() {
    NAME=$1
    VALUE=$2

    if [ -z "$VALUE" ]; then
        echo "required env var $NAME"
        exit 1
    fi
}

function deploy_kafka_secured() {
    AUTH_TYPE=$1

    sed s#AUTH_TYPE_PLACEHOLDER#$AUTH_TYPE#g $TEMPLATES_DIR/kafka/secured/kafka-cluster-secured.yaml > $REPLACED_CONTENT_DIR/kafka-cluster-secured.yaml
    sed s#AUTH_TYPE_PLACEHOLDER#$AUTH_TYPE#g $TEMPLATES_DIR/kafka/secured/kafka-user-secured.yaml > $REPLACED_CONTENT_DIR/kafka-user-secured.yaml

    oc apply -f $REPLACED_CONTENT_DIR/kafka-cluster-secured.yaml
    oc apply -f $REPLACED_CONTENT_DIR/kafka-user-secured.yaml
    oc apply -f $TEMPLATES_DIR/kafka/registry-topics.yaml
}

function setImagePullSecret() {
    SERVICE_ACCOUNT=$1
    SECRET_NAME=$2
    oc patch sa $SERVICE_ACCOUNT -p '\"imagePullSecrets\": [{\"name\": \"'"$SECRET_NAME"'\" }]'
}

function deployRegistryOperator() {
    echo "Using operator image $OPERATOR_IMAGE"

    cat $OPERATOR_REPO_DIR/deploy/operator.yaml | sed s,{OPERATOR_IMAGE},$OPERATOR_IMAGE,g | oc apply -f -

    oc apply -f $OPERATOR_REPO_DIR/deploy/service_account.yaml
    if [ ! -z "$CUSTOM_PULL_SECRET" ]; then
        setImagePullSecret "apicurio-registry-operator" $CUSTOM_PULL_SECRET
    fi

    oc apply -f $OPERATOR_REPO_DIR/deploy/role.yaml
    oc apply -f $OPERATOR_REPO_DIR/deploy/role_binding.yaml
    oc apply -f $OPERATOR_REPO_DIR/deploy/cluster_role.yaml
    cat $OPERATOR_REPO_DIR/deploy/cluster_role_binding.yaml | sed s/{NAMESPACE}/$NAMESPACE/g | oc apply -f -
    oc apply -f $OPERATOR_REPO_DIR/deploy/crds/apicur.io_apicurioregistries_crd.yaml
    oc apply -f $OPERATOR_REPO_DIR/deploy/operator.yaml
    oc wait deployment/apicurio-registry-operator --for condition=available --timeout=180s
}

function applyRegistryCR() {
    DEPLOYMENT_FILE=$1
    REPLACED_FILE=$2

    sed -e s#IMAGE_PLACEHOLDER#$REGISTRY_IMAGE#g \
        -e s#LOG_LEVEL_PLACEHOLDER#$REGISTRY_LOG_LEVEL#g \
        -e s#ROUTE_PLACEHOLDER#$REGISTRY_ROUTE#g \
        -e s#BOOTSTRAP_SERVERS_PLACEHOLDER#$BOOTSTRAP_SERVERS#g \
        -e s#TRUSTSTORE_SECRET_PLACEHOLDER#$TRUSTSTORE_SECRET#g \
        -e s#KEYSTORE_SECRET_PLACEHOLDER#$KEYSTORE_SECRET#g \
        -e s#USER_PLACEHOLDER#$USER#g \
        -e s#PASSWORD_SECRET_PLACEHOLDER#$PASSWORD_SECRET#g \
        -e s#DATASOURCE_URL_PLACEHOLDER#$DATASOURCE_URL#g \
        $DEPLOYMENT_FILE > $REPLACED_FILE

    oc apply -f $REPLACED_FILE

    sleep 3
}

function waitRegistryDeploymentViaOperator() {
    STORAGE=$1

    oc wait deployment -l app=apicurio-registry-$STORAGE --for condition=available --timeout=180s
    oc get route
}