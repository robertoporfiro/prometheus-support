#!/bin/bash

cp *.jsonnet backup
LIB=$HOME/src/github.com/grafana/grafonnet-lib
jsonnet -J $LIB update_dashboard.jsonnet > api.json && \
    curl -XPOST  --dump-header -  --data-binary "@api.json" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${BEARER_TOKEN}" \
    https://grafana.mlab-sandbox.measurementlab.net/api/dashboards/db
