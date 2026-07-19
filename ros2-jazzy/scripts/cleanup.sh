#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

rm -rf \
    "$WORKSPACE_DIR/build" \
    "$WORKSPACE_DIR/install" \
    "$WORKSPACE_DIR/log" \
    "$WORKSPACE_DIR/.home"
