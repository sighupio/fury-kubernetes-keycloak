#!/bin/bash -e
# Copyright (c) 2021 SIGHUP s.r.l All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

cd /opt/jboss/keycloak

ENTRYPOINT_DIR=/opt/jboss/startup-scripts

if [[ -d "$ENTRYPOINT_DIR" ]]; then
  # First run cli autoruns
  for f in "$ENTRYPOINT_DIR"/*; do
    if [[ "$f" == *.cli ]]; then
      echo "Executing cli script: $f"
      bin/jboss-cli.sh  --file=$f
    elif [[ -x "$f" ]]; then
      echo "Executing: $f"
      "$f"
    else
      echo "Ignoring file in $ENTRYPOINT_DIR (not *.cli or executable): $f"
    fi
  done
else
      echo "Startup scripts folder not found or is not a directory: $ENTRYPOINT_DIR"	
fi

