-- =============================================================================
-- Hyprland Lua API — EmmyLua type stubs (hl-fwdesk copy)
-- =============================================================================
-- This file is never executed by Hyprland. It exists solely to give
-- lua-language-server type information for the `hl` global that Hyprland
-- injects at runtime (0.55+).
--
-- Coverage is based on the API surface used in conf/*.lua. Extend as needed
-- when new hl.* calls are added.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Shared primitive types
-- ---------------------------------------------------------------------------

---@class hl.ConfigTable
---@class hl.DispatcherValue

-- ---------------------------------------------------------------------------
-- hl.dsp — dispatcher factories
-- ---------------------------------------------------------------------------

---@class hl.dsp.FocusOpts
---@field direction? "left"|"right"|"up"|"down"
---@field workspace?  string|integer
---@field monitor?    string
---@field on_current_monitor? boolean

---@class hl.dsp.MoveOpts
---@field direction?  "left"|"right"|"up"|"down"
---@field workspace?  string
---@field monitor?    "l"|"r"|"u"|"d"|string
---@field follow?     boolean

---@class hl.dsp.FullscreenOpts
---@field mode?   "fullscreen"|"maximize"|"float"
---@field action? "toggle"|"on"|"off"

---@class hl.dsp.FloatOpts
---@field action? "toggle"|"on"|"off"

---@class hl.dsp
local dsp = {}

---Execute a shell command.
---@param cmd string
---@return hl.DispatcherValue
function dsp.exec_cmd(cmd) end

---Invoke a named scrolling-layout dispatcher.
---@param action string
---@return hl.DispatcherValue
function dsp.layout(action) end

---Focus a window or workspace.
---@param opts hl.dsp.FocusOpts
---@return hl.DispatcherValue
function dsp.focus(opts) end

---@class hl.dsp.window
local dsp_window = {}

---Close the focused window.
---@return hl.DispatcherValue
function dsp_window.close() end

---Toggle/set fullscreen on the focused window.
---@param opts? hl.dsp.FullscreenOpts
---@return hl.DispatcherValue
function dsp_window.fullscreen(opts) end

---Toggle/set floating on the focused window.
---@param opts? hl.dsp.FloatOpts
---@return hl.DispatcherValue
function dsp_window.float(opts) end

---Begin an interactive mouse drag (move) on the focused window.
---@return hl.DispatcherValue
function dsp_window.drag() end

---Resize the focused window by a pixel delta.
---@param opts? hl.dsp.ResizeOpts
---@return hl.DispatcherValue
function dsp_window.resize(opts) end

dsp.window = dsp_window

-- ---------------------------------------------------------------------------
-- hl.bind
-- ---------------------------------------------------------------------------

---@class hl.BindOpts
---@field mouse?     boolean
---@field locked?    boolean
---@field repeating? boolean

---@param keys   string
---@param action hl.DispatcherValue | fun()
---@param opts?  hl.BindOpts
function hl.bind(keys, action, opts) end

-- ---------------------------------------------------------------------------
-- hl.config / hl.env / hl.monitor
-- ---------------------------------------------------------------------------

---Apply a hyprlang config table.
---@param cfg hl.ConfigTable
function hl.config(cfg) end

---Set a Wayland/compositor environment variable.
---@param name  string
---@param value string
function hl.env(name, value) end

---@class hl.MonitorOpts
---@field output   string
---@field mode     string
---@field position string
---@field scale    number|string
---@field transform? number

---Configure a monitor/output.
---@param opts hl.MonitorOpts
function hl.monitor(opts) end

-- ---------------------------------------------------------------------------
-- hl.animation
-- ---------------------------------------------------------------------------

---@class hl.AnimationOpts
---@field leaf    string
---@field enabled boolean
---@field speed   number
---@field bezier? string
---@field spring? string
---@field style?  string

---Configure an animation leaf.
---@param opts hl.AnimationOpts
function hl.animation(opts) end

-- ---------------------------------------------------------------------------
-- hl.window_rule
-- ---------------------------------------------------------------------------

---@class hl.WindowRuleMatchOpts
---@field class?      string
---@field title?      string
---@field float?      boolean
---@field fullscreen? boolean
---@field pin?        boolean
---@field xwayland?   boolean
---@field workspace?  string

---@class hl.WindowRuleOpts
---@field name           string
---@field match          hl.WindowRuleMatchOpts
---@field float?         boolean
---@field tile?          boolean
---@field pin?           boolean
---@field opacity?       number
---@field border_size?   number
---@field rounding?      number
---@field move?          string

---Add a window rule.
---@param opts hl.WindowRuleOpts
function hl.window_rule(opts) end

-- ---------------------------------------------------------------------------
-- hl.on / hl.exec_cmd
-- ---------------------------------------------------------------------------

---Register a callback for a Hyprland event.
---@param event    string
---@param callback fun()
function hl.on(event, callback) end

---Execute a shell command immediately (not as a dispatcher).
---@param cmd string
function hl.exec_cmd(cmd) end
