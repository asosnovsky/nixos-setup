---@param s string
---@return string
local function escape_pattern(s)
    return (s:gsub("([%.%-%+%[%]%(%)%$%^%%%?%*])", "%%%1"))
end

---@param url string
---@return fun(w: HL.Window): boolean
local function make_target_validation_for_chromium_apps(url)
    local host = url:match("^https?://([^/:]+)")
    local host_pattern = escape_pattern(host)
    ---@param w HL.Window
    ---@return boolean
    return function(w)
        if not w.class then
            return false
        end
        return w.class:match("^chrome%-" .. host_pattern)
    end
end

---Focus an already-tagged window if one exists.
---@param tag string
---@return HL.Window | nil
local function attempt_to_switch_to_existing(tag)
    local existing = hl.get_windows({ tag = tag })
    if existing and #existing > 0 then
        return existing[1]
    end
    return nil
end

---@param tag string
---@param cmd string
---@param is_target_window fun(w: HL.Window): boolean
---@return fun(): hl.DispatcherValue
local function make_commandable(tag, cmd, is_target_window)
    return function()
        local existing = attempt_to_switch_to_existing(tag)
        if existing ~= nil then
            return hl.dsp.focus({ window = existing })
        end

        ---@type HL.EventSubscription
        local sub
        ---@type hl.TimerHandle
        local timeout

        ---@param w HL.Window
        sub = hl.on("window.open", function(w)
            if not is_target_window(w) then
                return -- not our window, keep listening
            end
            sub:remove()
            timeout:set_enabled(false)
            hl.dispatch(hl.dsp.window.tag({ tag = "+" .. tag, window = w }))
        end)

        timeout = hl.timer(function()
            sub:remove()
        end, { timeout = 5000, type = "oneshot" })

        return hl.dsp.exec_cmd(cmd)
    end
end

---@param name string
---@param url string
---@return fun()
local function web_app(name, url)
    local tag = "skyg-" .. name
    local is_target_window = make_target_validation_for_chromium_apps(url)
    return make_commandable(
        tag,
        string.format("chromium --app=%s --new-window", url),
        is_target_window
    )
end

---@type table<string, fun()>
CarouselApps = CarouselApps or {}

CarouselApps.netflix = web_app("Netflix", "https://www.netflix.com/browse")
CarouselApps.youtube = web_app("YouTube", "https://www.youtube.com")
CarouselApps.jellyfin = web_app("Jellyfin", "http://bigbox1.lab.internal:8096")
CarouselApps.paramountplus = web_app("paramountplus", "https://www.paramountplus.com")
CarouselApps.primevideo = web_app("primevideo", "https://www.primevideo.com")
CarouselApps.chromium = make_commandable("skyg-chromium", "chromium", function(w)
    return w.class == "chromium-browser"
end)
