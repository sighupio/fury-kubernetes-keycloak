#!/usr/bin/env bats
# Copyright (c) 2021 SIGHUP s.r.l All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

# shellcheck disable=SC2086,SC2154,SC2034

load ./resources/helper

@test "Applying Monitoring CRDs" {
  info
  kubectl apply --server-side -f https://raw.githubusercontent.com/sighupio/fury-kubernetes-monitoring/v2.1.0/katalog/prometheus-operator/crds/0servicemonitorCustomResourceDefinition.yaml
  kubectl apply --server-side -f https://raw.githubusercontent.com/sighupio/fury-kubernetes-monitoring/v2.1.0/katalog/prometheus-operator/crds/0prometheusruleCustomResourceDefinition.yaml
}

@test "Deploy KeyCloak Operator CRDs" {
    info
    deploy() {
        kapply katalog/keycloak-operator/crds
    }
    loop_it deploy 5 5
    [ "$status" -eq 0 ]
}

@test "Deploy KeyCloak" {
    info
    deploy() {
        apply examples/keycloak-operated-deployment
    }
    loop_it deploy 5 5
    [ "$status" -eq 0 ]
}

@test "KeyCloak is Running" {
    info
    test() {
        kubectl get pods -l app=keycloak -o json -n keycloak |jq '.items[].status.containerStatuses[].ready' | uniq |grep -q true
    }
    loop_it test 50 5
    status=${loop_it_result}
    [ "$status" -eq 0 ]
}
