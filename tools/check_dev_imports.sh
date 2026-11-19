#!/bin/sh
# Spec §1.2: app/lib/dev/는 main_dev.dart와 app/test/에서만 가져온다.
set -eu
cd "$(dirname "$0")/../app"
bad=$(grep -rlE "import '(package:hwaeaek/|\.\./)*dev/" lib --include='*.dart' \
  | grep -v '^lib/dev/' | grep -v '^lib/main_dev.dart$' || true)
if [ -n "$bad" ]; then
  echo "app/lib/dev/를 가져오면 안 되는 파일:" >&2
  echo "$bad" >&2
  exit 1
fi
echo "dev import 검사 통과"
