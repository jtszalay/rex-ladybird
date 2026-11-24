#!/bin/sh
# Installs the devbox side of rcode: the code-server and forward units, and rcode itself.
# Install code-server first, for example:
#   curl -fsSL https://code-server.dev/install.sh | sh -s -- --method standalone
# Settings, as environment variables:
#   RCODE_MAC_HOST  this machine's Rex host label for the Mac (default mac)
#   RCODE_SESSION   Rex session on the Mac (default vscode)
#   RCODE_PORT      port on the Mac (default 18443)
set -eu
here="$(cd "$(dirname "$0")" && pwd -P)"
host="${RCODE_MAC_HOST:-mac}"
session="${RCODE_SESSION:-vscode}"
port="${RCODE_PORT:-18443}"
bindir="${PREFIX:-$HOME/.local}/bin"
units="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"

rex="$(command -v rex)" || { echo "rcode: the rex command is not on PATH" >&2; exit 1; }
[ -x "$HOME/.local/bin/code-server" ] || { echo "rcode: no ~/.local/bin/code-server. Install code-server first (see the top of this script)." >&2; exit 1; }
[ -f "$HOME/.config/code-server/config.yaml" ] ||
  echo "warning: no ~/.config/code-server/config.yaml. See $here/devbox/config.yaml.example" >&2

mkdir -p "$bindir" "$units"
ln -sf "$here/devbox/rcode" "$bindir/rcode"
cp "$here/devbox/code-server.service" "$units/"
sed -e "s|@REX@|$rex|g" -e "s|@HOST@|$host|g" -e "s|@SESSION@|$session|g" -e "s|@PORT@|$port|g" \
  "$here/devbox/code-server-mac-forward.service" > "$units/code-server-mac-forward.service"
systemctl --user daemon-reload
systemctl --user enable --now code-server.service code-server-mac-forward.service
systemctl --user restart code-server-mac-forward.service
echo "installed rcode into $bindir, and started code-server and code-server-mac-forward"
