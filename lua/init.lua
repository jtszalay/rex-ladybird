-- ladybird: Ladybird browser panes for Rex.
--
-- Ladybird draws pages straight into a terminal with the kitty graphics
-- protocol (--headless=terminal), so a browser pane is a plain Rex pane.
-- Panes run lb-pane, which also opens a DevTools port so lb can drive them.
--
--   require("ladybird").setup{
--     key = "shift+cmd+b",   -- open a browser pane; false for no shortcut
--     split = "right",       -- right, left, above, or below
--     ratio = 0.5,           -- the share of the split the browser pane gets
--     home = "about:blank",  -- the page a new pane opens
--     profile = "rex",       -- Ladybird profile shared by all panes
--   }

local M = {}

local SHELL = "com.superlogical.terminal.shell"
local PANE = os.getenv("HOME") .. "/src/rex-ladybird/bin/lb-pane"

local defaults = {
  key = "shift+cmd+b",
  split = "right",
  ratio = 0.5,
  home = "about:blank",
  profile = "rex",
}

local placement = {
  right = { direction = "horizontal", side = "after" },
  left = { direction = "horizontal", side = "before" },
  below = { direction = "vertical", side = "after" },
  above = { direction = "vertical", side = "before" },
}

function M.setup(opts)
  opts = opts or {}
  for k, v in pairs(defaults) do
    if opts[k] == nil then opts[k] = v end
  end
  local where = placement[opts.split]
  if where == nil then
    error("ladybird: split must be right, left, above, or below, not " .. tostring(opts.split), 0)
  end

  local function pane_block(url)
    if url == nil or url == "" then url = opts.home end
    return rex.layout.block{
      flavor = SHELL,
      label = "ladybird",
      options = { command = { "env", "LB_PROFILE=" .. opts.profile, PANE, url } },
    }
  end

  rex.action{
    name = "ladybird_open",
    title = "Open Browser Pane",
    description = "Open a Ladybird browser pane beside this pane.",
    category = "Browser",
    keywords = "browser web ladybird url page preview localhost",
    args = { url = "string?" },
    run = function(ctx, args)
      local split, err = rex.session.new_split{
        anchor_id = ctx.block_id,
        direction = where.direction,
        side = where.side,
        ratio = where.side == "after" and (1 - opts.ratio) or opts.ratio,
        focus = true,
        layout = pane_block(args.url),
      }
      if err ~= nil then error(err, 0) end
      return split
    end,
  }

  rex.action{
    name = "ladybird_open_tab",
    title = "Open Browser Tab",
    description = "Open a Ladybird browser pane in a new tab.",
    category = "Browser",
    keywords = "browser web ladybird url page tab window",
    args = { url = "string?" },
    run = function(ctx, args)
      local w, err = rex.session.new_window{ layout = pane_block(args.url) }
      if err ~= nil then error(err, 0) end
      return w
    end,
  }

  if opts.key then
    rex.bind(opts.key, "ladybird_open")
  end
end

return M
