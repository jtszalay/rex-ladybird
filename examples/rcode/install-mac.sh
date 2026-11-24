#!/bin/sh
# Installs the Mac side of rcode. Run ../../install.sh first, for lb.
# Usage: ./install-mac.sh [PASSWORD_FILE]
#   PASSWORD_FILE holds code-server's password; it is copied to ~/.config/rcode/password.
set -eu
here="$(cd "$(dirname "$0")" && pwd -P)"
bindir="${PREFIX:-$HOME/.local}/bin"
cfg="$HOME/.config/rcode"

command -v lb >/dev/null 2>&1 || [ -x "$bindir/lb" ] || { echo "rcode: install lb first: $here/../../install.sh" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "rcode: needs jq: brew install jq" >&2; exit 1; }

mkdir -p "$bindir" "$cfg"
ln -sf "$here/mac/rcode" "$bindir/rcode"
echo "linked rcode into $bindir"

if [ $# -gt 0 ]; then
  (umask 077 && cp "$1" "$cfg/password")
  echo "saved the password in $cfg/password"
elif [ ! -f "$cfg/password" ]; then
  echo "No $cfg/password yet. Create it with code-server's password, mode 600, or code-server will ask in the pane."
fi
[ -f "$cfg/env" ] || echo "Optional: set RCODE_DIR (the folder rcode opens by default), RCODE_PORT, or RCODE_SESSION in $cfg/env"
