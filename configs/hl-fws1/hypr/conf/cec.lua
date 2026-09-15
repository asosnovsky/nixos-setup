-- =========================
-- CEC (HDMI-CEC control, e.g. waking/switching the TV)
-- =========================

---@param cmd string  raw cec-client command, e.g. "on" or "as"
---@param target integer  CEC logical address (0 = TV)
local function cec_send(cmd, target)
    hl.exec_cmd(
        string.format("bash -c \"echo '%s %d' | cec-client -s -d 1 -o SkygBox -t p\"", cmd, target)
    )
end

---Wake a CEC device and make this box its active source.
---@param target integer?  CEC logical address, defaults to 0 (TV)
local function wake_and_switch(target)
    target = target or 0
    cec_send("on", target)
    cec_send("as", target)
end

---Send a CEC "User Control Pressed" + "Released" key press to a device.
---cec-client's built-in volup/voldown/mute shortcuts hardcode the CEC
---"Audio System" address (5), which is a no-op when there's no amp/soundbar
---on the bus — so volume keys go through raw tx frames addressed at the
---TV instead, the same address `wake_and_switch` already proves works.
---@param target integer  CEC logical address (0 = TV)
---@param ui_cmd string  UI command hex byte, e.g. "41" Volume Up, "42" Volume Down, "43" Mute
local function cec_key(target, ui_cmd)
    local src = 1
    local press = string.format("tx %x%x:44:%s", src, target, ui_cmd)
    local release = string.format("tx %x%x:45", src, target)
    hl.exec_cmd(
        string.format(
            "bash -c \"printf '%%s\\n%%s\\n' '%s' '%s' | cec-client -s -d 1 -o SkygBox -t p\"",
            press,
            release
        )
    )
end

---@param target integer?  defaults to 0 (TV)
local function volume_up(target)
    cec_key(target or 0, "41")
end

---@param target integer?  defaults to 0 (TV)
local function volume_down(target)
    cec_key(target or 0, "42")
end

---@param target integer?  defaults to 0 (TV)
local function mute(target)
    cec_key(target or 0, "43")
end

---@class Cec
---@field send fun(cmd: string, target: integer)
---@field wake_and_switch fun(target: integer?)
---@field volume_up fun(target: integer?)
---@field volume_down fun(target: integer?)
---@field mute fun(target: integer?)
Cec = Cec or {}
Cec.send = cec_send
Cec.wake_and_switch = wake_and_switch
Cec.volume_up = volume_up
Cec.volume_down = volume_down
Cec.mute = mute
