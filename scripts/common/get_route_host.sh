#!/usr/bin/env bash

if [ -z "$1" ]; then
    echo "mandatory one argument with route name"
    exit 1
fi

echo $(oc get route $1 -o jsonpath="{.status.ingress[0].host}")