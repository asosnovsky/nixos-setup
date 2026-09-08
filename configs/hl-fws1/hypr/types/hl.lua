-- =============================================================================
-- Hyprland Lua API — EmmyLua type stubs
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
---A free-form table mirroring Hyprland's hyprlang config sections.
---Top-level keys map to sections (general, decoration, input, …).
---Nested tables map to sub-sections. Values are numbers, booleans, or strings.

---@class hl.DispatcherValue
---An opaque value returned by hl.dsp.* factory functions.
---Pass directly to hl.bind() as the `action` argument.

-- ---------------------------------------------------------------------------
-- hl.dsp — dispatcher factories
-- ---------------------------------------------------------------------------

---@class hl.dsp.FocusOpts
---@field direction? "left"|"right"|"up"|"down"   Focus by direction
---@field workspace?  string|integer                e.g. "e-1", "e+1", or a numeric id
---@field monitor?    string                        e.g. "+1", "-1", name
---@field on_current_monitor? boolean               Switch to the workspace on the current monitor

---@class hl.dsp.MoveOpts
---@field direction?  "left"|"right"|"up"|"down"
---@field workspace?  string                        e.g. "r-1", "r+1"
---@field monitor?    "l"|"r"|"u"|"d"|string
---@field follow?     boolean                       Follow the window after move

---@class hl.dsp.FullscreenOpts
---@field mode?   "fullscreen"|"maximize"|"float"
---@field action? "toggle"|"on"|"off"

---@class hl.dsp.FloatOpts
---@field action? "toggle"|"on"|"off"

---@class hl.dsp.ResizeOpts
---@field x        number  Pixel delta (horizontal)
---@field y        number  Pixel delta (vertical)
---@field relative boolean If true, delta is relative to current size

---@class hl.dsp
local dsp = {}

---Focus a window or workspace.
---@param opts hl.dsp.FocusOpts
---@return hl.DispatcherValue
function dsp.focus(opts) end

---Execute a shell command.
---@param cmd string
---@return hl.DispatcherValue
function dsp.exec_cmd(cmd) end

---Invoke a named scrolling-layout dispatcher (colresize, swapcol, etc.).
---@param action string  e.g. "colresize +0.1", "swapcol l", "fit_into_view", "focus current"
---@return hl.DispatcherValue
function dsp.layout(action) end

---@class hl.dsp.window
local dsp_window = {}

---Close the focused window.
---@return hl.DispatcherValue
function dsp_window.close() end

---Cycle focus to the next window.
---@return hl.DispatcherValue
function dsp_window.cycle_next() end

---Swap the focused window with a neighbour.
---@param opts? { direction: "l"|"r"|"u"|"d" }
---@return hl.DispatcherValue
function dsp_window.swap(opts) end

---Move the focused window.
---@param opts hl.dsp.MoveOpts
---@return hl.DispatcherValue
function dsp_window.move(opts) end

---Toggle/set fullscreen on the focused window.
---@param opts? hl.dsp.FullscreenOpts
---@return hl.DispatcherValue
function dsp_window.fullscreen(opts) end

---Toggle/set floating on the focused window.
---@param opts? hl.dsp.FloatOpts
---@return hl.DispatcherValue
function dsp_window.float(opts) end

---Resize the focused window by a pixel delta.
---@param opts? hl.dsp.ResizeOpts
---@return hl.DispatcherValue
function dsp_window.resize(opts) end

---Begin an interactive mouse drag (move) on the focused window.
---@return hl.DispatcherValue
function dsp_window.drag() end

---@class hl.dsp.group
local dsp_group = {}

---Toggle the focused window's group/tab mode.
---@return hl.DispatcherValue
function dsp_group.toggle() end

-- group dispatchers beyond `toggle` (moveintogroup/moveoutofgroup,
-- changegroupactive, lockactivegroup) aren't wrapped by hl.dsp;
-- keybindings.lua reaches them via `hl.exec_cmd("hyprctl dispatch ...")`.

---@class hl.dsp.workspace
local dsp_workspace = {}

---Toggle a special (scratchpad) workspace.
---@param name string
---@return hl.DispatcherValue
function dsp_workspace.toggle_special(name) end

---Focus a window in pseudo-tile mode.
---@return hl.DispatcherValue
function dsp_window.pseudo() end

-- Attach sub-namespaces to dsp
dsp.window = dsp_window
dsp.group = dsp_group
dsp.workspace = dsp_workspace

-- ---------------------------------------------------------------------------
-- hl.bind — keyboard / mouse bindings
-- ---------------------------------------------------------------------------

---@class hl.BindOpts
---@field mouse?     boolean  True for mouse-button bindings (mouse:272, mouse:273 …)
---@field locked?    boolean  Active even on a locked screen (e.g. media keys)
---@field repeating? boolean  Fire repeatedly while held (note: key is `repeating`, not `repeat`)

---Register a keybind. Returns a handle with a `:set_enabled(bool)` method.
---@param keys   string                          Modifier + key string, e.g. "SUPER + T"
---@param action hl.DispatcherValue | fun()      An hl.dsp.* factory result, or a Lua callback
---@param opts?  hl.BindOpts
---@return hl.BindHandle
function hl.bind(keys, action, opts) end

---@class hl.BindHandle
local BindHandle = {}
---Enable or disable this bind at runtime.
---@param enabled boolean
function BindHandle:set_enabled(enabled) end

-- ---------------------------------------------------------------------------
-- hl.config — set hyprlang config values
-- ---------------------------------------------------------------------------

---Apply a hyprlang config table. Sections that are omitted are left unchanged.
---@param cfg hl.ConfigTable
function hl.config(cfg) end

-- ---------------------------------------------------------------------------
-- hl.env — environment variables
-- ---------------------------------------------------------------------------

---Set a Wayland/compositor environment variable.
---@param name  string
---@param value string
function hl.env(name, value) end

-- ---------------------------------------------------------------------------
-- hl.monitor — output / display configuration
-- ---------------------------------------------------------------------------

---@class hl.MonitorOpts
---@field output   string  Connector name ("eDP-1") or desc: string, or "" for fallback
---@field mode     string  Resolution@refresh, e.g. "1920x1080@60", or "preferred"
---@field position string  "XxY" pixel offset, or "auto"
---@field scale    number|string  DPI scale factor, or "auto"
---@field transform? number  0–7 (90° steps + mirror variants)

---Configure a monitor/output.
---@param opts hl.MonitorOpts
function hl.monitor(opts) end

-- ---------------------------------------------------------------------------
-- hl.device — per-device input config
-- ---------------------------------------------------------------------------

---@class hl.DeviceOpts
---@field name        string  Device name as reported by libinput
---@field sensitivity? number  -1.0 to 1.0
---@field kb_layout?  string

---Apply per-device config.
---@param opts hl.DeviceOpts
function hl.device(opts) end

-- ---------------------------------------------------------------------------
-- hl.permission — capability permissions
-- ---------------------------------------------------------------------------

---Grant or deny a permission to a binary (regex path).
---@param binary  string  Regex matched against the process path
---@param capability string  e.g. "screencopy", "plugin"
---@param action  "allow"|"deny"
function hl.permission(binary, capability, action) end

-- ---------------------------------------------------------------------------
-- hl.workspace_rule — workspace rules
-- ---------------------------------------------------------------------------

---@class hl.WorkspaceRuleOpts
---@field workspace  string  Workspace selector, e.g. "w[tv1]", "f[1]"
---@field gaps_in?   number
---@field gaps_out?  number
---@field border_size? number

---Add a workspace rule.
---@param opts hl.WorkspaceRuleOpts
---@return hl.RuleHandle
function hl.workspace_rule(opts) end

-- ---------------------------------------------------------------------------
-- hl.layer_rule — layer-shell rules
-- ---------------------------------------------------------------------------

---@class hl.LayerRuleMatchOpts
---@field namespace? string  Regex matched against the layer namespace

---@class hl.LayerRuleOpts
---@field name     string
---@field match    hl.LayerRuleMatchOpts
---@field no_anim? boolean

---Add a layer-shell rule.
---@param opts hl.LayerRuleOpts
---@return hl.RuleHandle
function hl.layer_rule(opts) end

-- ---------------------------------------------------------------------------
-- hl.gesture — built-in touchpad gesture bindings
-- ---------------------------------------------------------------------------

---@class hl.GestureOpts
---@field fingers   number                                      Number of touch points
---@field direction "horizontal"|"vertical"|"left"|"right"|"up"|"down"
---@field action    string|fun()                                Named action or callback
---@field mods?     string                                      Modifier mask, e.g. "SUPER"

---Register a built-in touchpad gesture.
---@param opts hl.GestureOpts
function hl.gesture(opts) end

-- ---------------------------------------------------------------------------
-- hl.curve — animation bezier / spring curves
-- ---------------------------------------------------------------------------

---@class hl.CurveOpts
---@field type       "bezier"|"spring"
---@field points?    { [1]: number, [2]: number }[]  Control points for bezier (two {x,y} pairs)
---@field mass?      number  Spring mass
---@field stiffness? number  Spring stiffness
---@field dampening? number  Spring dampening

---Define a named animation curve.
---@param name string
---@param opts hl.CurveOpts
function hl.curve(name, opts) end

-- ---------------------------------------------------------------------------
-- hl.animation — animation configuration
-- ---------------------------------------------------------------------------

---@class hl.AnimationOpts
---@field leaf    string   Animation leaf name, e.g. "workspaces", "windows", "fadeIn"
---@field enabled boolean
---@field speed   number   Duration multiplier
---@field bezier? string   Named bezier curve defined via hl.curve()
---@field spring? string   Named spring curve defined via hl.curve()
---@field style?  string   Optional style string, e.g. "slidevert", "slidefade 20%", "popin 87%", "fade"

---Configure an animation leaf.
---@param opts hl.AnimationOpts
function hl.animation(opts) end

-- ---------------------------------------------------------------------------
-- hl.window_rule — window rules
-- ---------------------------------------------------------------------------

---@class hl.WindowRuleMatchOpts
---@field class?      string   Regex matched against window class (app_id)
---@field title?      string   Regex matched against window title
---@field float?      boolean  Match floating windows
---@field fullscreen? boolean  Match fullscreen windows
---@field pin?        boolean  Match pinned windows
---@field xwayland?   boolean  Match XWayland windows
---@field workspace?  string   Match by workspace selector

---@class hl.WindowRuleOpts
---@field name           string                  Identifier for the rule
---@field match          hl.WindowRuleMatchOpts  Match criteria
---@field float?         boolean                 Float the window
---@field tile?          boolean                 Force-tile the window
---@field pin?           boolean                 Pin (always-on-top) the window
---@field opacity?       number                  Override active opacity
---@field no_focus?      boolean                 Prevent focus
---@field border_size?   number                  Override border size
---@field rounding?      number                  Override corner rounding
---@field move?          string                  Position string, e.g. "20 monitor_h-120"
---@field suppress_event? string                 Event name to suppress, e.g. "maximize"

---Add a window rule. Returns a handle with a `:set_enabled(bool)` method.
---@param opts hl.WindowRuleOpts
---@return hl.RuleHandle
function hl.window_rule(opts) end

---@class hl.RuleHandle
local RuleHandle = {}
---Enable or disable this rule at runtime.
---@param enabled boolean
function RuleHandle:set_enabled(enabled) end

-- ---------------------------------------------------------------------------
-- hl.on — event hooks
-- ---------------------------------------------------------------------------

---Register a callback for a Hyprland event.
---@param event    string    e.g. "hyprland.start", "window.open", "monitor.added"
---@param callback fun()
function hl.on(event, callback) end

-- ---------------------------------------------------------------------------
-- hl.exec_cmd — fire-and-forget command (outside a bind)
-- ---------------------------------------------------------------------------

---Execute a shell command immediately (not as a dispatcher).
---@param cmd string
function hl.exec_cmd(cmd) end

-- ---------------------------------------------------------------------------
-- hl.plugin — plugin management
-- ---------------------------------------------------------------------------

---@class hl.plugin
local plugin = {}

---Load a Hyprland plugin from its .so path.
---@param path string  Absolute path to the shared library
function plugin.load(path) end
-- ---------------------------------------------------------------------------
-- hl.get_workspaces — runtime introspection
-- ---------------------------------------------------------------------------

---@class HL.Monitor
---@field id          integer
---@field name        string
---@field description? string
---@field width?      integer
---@field height?     integer
---@field x?          integer
---@field y?          integer
---@field scale?      number
---@field focused?    boolean
---@field active_workspace? HL.Workspace

---@class HL.Workspace
---@field id           integer
---@field name         string
---@field config_name? string   Config-specified name (empty/absent for auto)
---@field windows?     integer  Number of windows on the workspace
---@field special?     boolean  Is a special (scratchpad) workspace
---@field active?      boolean  Is active on its monitor
---@field visible?     boolean
---@field has_urgent?  boolean
---@field is_empty?    boolean
---@field monitor?     HL.Monitor

---All non-inert workspaces.
---@return HL.Workspace[]
function hl.get_workspaces() end

-- ---------------------------------------------------------------------------
-- hl.print — log to the Hyprland log
-- ---------------------------------------------------------------------------

---@param ... any
function hl.print(...) end

-- ---------------------------------------------------------------------------
-- hl.dispatch — execute a dispatcher closure now
-- ---------------------------------------------------------------------------

---Run a dispatcher closure immediately (same as firing a bound key's action).
---@param action hl.DispatcherValue
function hl.dispatch(action) end

-- ---------------------------------------------------------------------------
-- hl.timer — deferred / repeating callbacks
-- ---------------------------------------------------------------------------

---@class hl.TimerOpts
---@field timeout number   Interval / delay in milliseconds
---@field type?   "repeat"|"oneshot"

---@class hl.TimerHandle
local TimerHandle = {}
---Cancel this timer.
function TimerHandle:cancel() end

---Schedule a callback on a repeating or one-shot timer.
---@param callback fun()
---@param opts     hl.TimerOpts
---@return hl.TimerHandle
function hl.timer(callback, opts) end

-- ---------------------------------------------------------------------------
-- Global `hl` declaration
-- ---------------------------------------------------------------------------

---Hyprland Lua API — injected globally by the compositor at startup.
---@class hl
---@field dsp    hl.dsp            Dispatcher factories (actions for binds/gestures)
---@field plugin hl.plugin         Plugin loader and plugin sub-namespaces
hl = {
    dsp = dsp,
    plugin = plugin,
}

-- Ensure the global is visible to LuaLS in all files.
---@type hl
hl = hl
