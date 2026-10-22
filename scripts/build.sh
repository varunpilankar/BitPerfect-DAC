#!/bin/sh
# Build the flashable Magisk module ZIP: dist/BitPerfect-DAC-<version>.zip
set -e
ROOT=$(cd "$(dirname "$0")/.." && pwd)
VER=$(sed -n 's/^version=//p' "$ROOT/module/module.prop")
mkdir -p "$ROOT/dist"
OUT="$ROOT/dist/BitPerfect-DAC-$VER.zip"
rm -f "$OUT"
chmod +x "$ROOT"/module/*.sh "$ROOT"/module/system/bin/* "$ROOT/module/META-INF/com/google/android/update-binary"
( cd "$ROOT/module" && zip -r -X "$OUT" . -x '.*' )
echo "Built $OUT"
( cd "$ROOT/dist" && sha256sum "$(basename "$OUT")" > "$(basename "$OUT").sha256" && cat "$(basename "$OUT").sha256" )
