#!/bin/sh
# Installs Ladybird browser panes for Rex. Asks no questions; safe to run again.
set -eu

here="$(cd "$(dirname "$0")" && pwd -P)"
config_file="${REX_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/rex/init.lua}"
config="$(dirname "$config_file")"
bindir="${PREFIX:-$HOME/.local}/bin"
line='require("ladybird").setup{}'

fail() { echo "rex-ladybird: $*" >&2; exit 1; }

# 1. Requirements.
[ "$(uname -s)" = Darwin ] || fail "needs macOS"
[ -x /Applications/Ladybird.app/Contents/MacOS/Ladybird ] || [ -x "$HOME/Applications/Ladybird.app/Contents/MacOS/Ladybird" ] ||
  fail "Ladybird.app is not in /Applications or ~/Applications. Get it from https://ladybird.org"
command -v rex >/dev/null 2>&1 || fail "the rex command is not on PATH. See https://www.superlogical.com/rex/docs/installation"
/usr/bin/python3 -c '' 2>/dev/null || fail "lb needs /usr/bin/python3. Install the Xcode command line tools: xcode-select --install"
command -v nc >/dev/null 2>&1 || fail "lb-pane needs nc"

# 2. Commands.
mkdir -p "$bindir"
ln -sf "$here/bin/lb" "$bindir/lb"
ln -sf "$here/bin/lb-pane" "$bindir/lb-pane"
echo "linked lb and lb-pane into $bindir"

# 3. The Rex module, with the path of lb-pane filled in.
[ -L "$config/ladybird" ] && rm "$config/ladybird"
mkdir -p "$config/ladybird"
sed "s|@PANE@|$here/bin/lb-pane|" "$here/lua/init.lua" > "$config/ladybird/init.lua"
echo "installed $config/ladybird/init.lua"

# 4. Load it from init.lua. Check the result, and restore the backup if the check fails.
if ! grep -qF "$line" "$config_file" 2>/dev/null; then
  [ -f "$config_file" ] && cp "$config_file" "$config_file.before-ladybird"
  printf '\n%s\n' "$line" >> "$config_file"
  if rex config check "$config_file" >/dev/null 2>&1; then
    echo "added $line to $config_file"
  else
    if [ -f "$config_file.before-ladybird" ]; then cp "$config_file.before-ladybird" "$config_file"; else rm -f "$config_file"; fi
    fail "rex config check failed with the module loaded, so $config_file is unchanged. Run: rex config check"
  fi
fi
grep -q 'require("rexweb").setup' "$config_file" 2>/dev/null &&
  echo "warning: $config_file also loads rexweb. Both use Shift-Cmd-B; remove one, or pass key = false to it." >&2
rex config reload >/dev/null 2>&1 || echo "warning: rex config reload failed. Check $config_file with: rex config check" >&2

case ":$PATH:" in
  *":$bindir:"*) ;;
  *) echo "Add $bindir to your PATH, for example: echo 'export PATH=\"$bindir:\$PATH\"' >> ~/.zshrc" ;;
esac
echo "done. Press Shift-Cmd-B in Rex, or run: lb open example.com"
