#!/bin/bash
# Build FlatBuffers schema for Dart

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/lib/generated"

mkdir -p "$OUTPUT_DIR"

flatc --dart -o "$OUTPUT_DIR" "$SCRIPT_DIR/lib/netwalk_board.fbs"

echo "FlatBuffers generated in $OUTPUT_DIR"
