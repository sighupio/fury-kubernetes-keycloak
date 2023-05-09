#!/usr/bin/env bats
# Copyright (c) 2021 SIGHUP s.r.l All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.


load ./resources/helper

@test "Test KeyCloak - Create User" {
    info
    deploy() {
        kapply katalog/tests/resources/create-user.yml
        kubectl wait --for=condition=complete job create-user --timeout=120s -n keycloak
    }
    run deploy
    [ "$status" -eq 0 ]
}

@test "Test KeyCloak - Get User" {
    info
    deploy() {
        kapply katalog/tests/resources/get-user.yml
        kubectl wait --for=condition=complete job get-user --timeout=120s -n keycloak
    }
    run deploy
    [ "$status" -eq 0 ]
}
