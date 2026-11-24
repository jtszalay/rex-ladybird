# rex-ladybird

[Ladybird](https://ladybird.org) browser panes for Rex, and `lb`, a command
that scripts them.

Ladybird can draw pages straight into a terminal with the kitty graphics
protocol (`--headless=terminal`). Rex supports that protocol, so a browser pane
is an ordinary Rex pane. There's no overlay window.

## Pieces

| File | |
| --- | --- |
| `bin/lb-pane` | Runs Ladybird in the current pane. It turns on Ladybird's DevTools server on a free local port (6100 and up) and records the port in `~/.lb/panes/<block>`. |
| `bin/lb` | The scripting CLI. Linked to `~/.local/bin/lb`. |
| `lua/init.lua` | The Rex module. `~/.config/rex/ladybird` links here, and `init.lua` loads it with `require("ladybird").setup{}`. |

The module adds **Open Browser Pane** (`Shift-Cmd-B`) and **Open Browser Tab**.
Options: `key`, `split`, `ratio`, `home`, `profile` (default `rex`). All panes
share that Ladybird profile, so sign-ins persist.

In a pane: `ctrl-l` address bar, `ctrl-r` reload, `alt-←/→` history,
`ctrl-q` quit.

## lb

```sh
id=$(lb open --focus=false localhost:3000)   # prints the block ID, waits for the load
lb snapshot -b "$id"                         # numbered controls (e1, e2, ...), then the page text
lb type -b "$id" --submit e1 'Ship it'
lb click -b "$id" e3
lb eval -b "$id" 'document.title'            # prints JSON; await works
lb eval -b "$id" 'const n = 2; return n * 2' # statements need return
lb wait -b "$id" --text Saved
lb nav / back / forward / reload / info / ls / focus / close
```

`-b` takes a block ID, an ID suffix, or part of the page title. Without `-b`,
`lb` works only when exactly one pane is open.

How each command works:

- `eval`, `snapshot`, `click`, `wait`, and `info` run JavaScript through
  Ladybird's DevTools server (the Firefox remote protocol).
- `nav`, `back`, `forward`, and `reload` use the DevTools tab actor. That works
  from Ladybird's error pages too, where scripts can't navigate.
- `type` focuses the field with JavaScript, then types real keys with
  `rex send`. `press` uses `rex send-key`.
- Commands that may navigate wait for a new document to finish loading. A
  failed load exits 1 with Ladybird's error title.

## Limits

- `click` dispatches pointer and mouse events and calls `click()`. It does not
  move a real mouse.
- No `screenshot`. Ladybird sends frames to the terminal, not to DevTools.
- A DevTools server takes one client at a time. Don't run two `lb` commands
  against the same pane at once.
- Ladybird's console never answers a script that has a syntax error. `lb eval`
  gives up after 10 seconds and says to check the syntax.
- The DevTools port listens on 127.0.0.1 without a token. Any local process
  can drive a pane, including its signed-in sessions.
