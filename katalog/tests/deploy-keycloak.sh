#!/usr/bin/env bats
# Copyright (c) 2021 SIGHUP s.r.l All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.


load ./resources/helper

@test "Deploy KeyCloak" {
    info
    deploy() {
        apply examples/h2-tests
    }
    run deploy
    [ "$status" -eq 0 ]
}

@test "KeyCloak is Running" {
    info
    test() {
        kubectl get pods -l app=keycloak -o json |jq '.items[].status.containerStatuses[].ready' | uniq |grep -q true
    }
    loop_it test 50 5
    status=${loop_it_result}
    [ "$status" -eq 0 ]
}
