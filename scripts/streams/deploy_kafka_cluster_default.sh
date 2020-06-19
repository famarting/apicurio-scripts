#!/usr/bin/env bash
case "$OSTYPE" in
  darwin*)  READLINK=greadlink;;
  *)        READLINK=readlink;;
esac

CURRENT_DIR=`${READLINK} -f \`dirname $0\``
source ${CURRENT_DIR}/../utils/functions.sh

oc apply -f $TEMPLATES_DIR/kafka/kafka-cluster.yaml
oc apply -f $TEMPLATES_DIR/kafka/registry-topics.yaml