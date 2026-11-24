# rcode: VS Code from a devbox, in a Ladybird pane

`rcode DIR`, run on a remote dev machine, opens `DIR` in VS Code
([code-server](https://github.com/coder/code-server)) in a Ladybird tab of the
Mac's Rex app. It's a worked example of `lb`: it opens the tab, waits for the
page, and fills in code-server's password on the first visit.

```
devbox                                        Mac
──────                                        ───
code-server.service                           Rex session "vscode"
  code-server on 127.0.0.1:8443                 └ forward: localhost:18443 → devbox:8443
code-server-mac-forward.service ────────────▶
  creates the "vscode" session if missing,
  then: rex -S mac forward share ...

rcode [DIR] ──── rex -S mac run ────────────▶ ~/.local/bin/rcode DIR
                                                lb open --tab → Ladybird pane
                                                lb type the password, if asked
                                                show the "vscode" session
```

## Requirements

- A devbox where Rex runs, with a Rex host for the Mac (`rex -S mac` works).
  For example, an SSH `RemoteForward` of the Mac's Rex socket, added as a host
  on the devbox.
- On the Mac: rex-ladybird's `install.sh` (for `lb`), and `jq`.

## Install

On the devbox:

```sh
curl -fsSL https://code-server.dev/install.sh | sh -s -- --method standalone
mkdir -p ~/.config/code-server
cp devbox/config.yaml.example ~/.config/code-server/config.yaml   # then set a password
./install-devbox.sh
```

`install-devbox.sh` links `rcode` into `~/.local/bin`, installs both units with
the path of `rex` filled in, and starts them. Set `RCODE_MAC_HOST` (default
`mac`), `RCODE_SESSION` (default `vscode`), or `RCODE_PORT` (default `18443`)
to change the defaults.

On the Mac:

```sh
./install-mac.sh /path/to/file-with-the-password
```

The script links `rcode` into `~/.local/bin` and saves the password in
`~/.config/rcode/password` (mode 600). Settings go in `~/.config/rcode/env`:
`RCODE_DIR` (the folder `rcode` opens when given none), `RCODE_PORT`, and
`RCODE_SESSION`.

## Use

```sh
rcode            # on the devbox: open the current directory
rcode ~/project  # or any directory
```

You can also run the Mac side directly: `~/.local/bin/rcode /path/on/devbox`.

## Notes

- Keep the Rex session's name as `vscode`, or whatever you set. Both sides find
  the session by name.
- Keep one VS Code tab open at a time. With two, the forward can stop taking
  new connections until one closes.
- code-server's login cookie lives in Ladybird's `rex` profile. After the first
  login, the password form doesn't show again.
