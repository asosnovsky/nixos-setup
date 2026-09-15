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

---@class Cec
---@field send fun(cmd: string, target: integer)
---@field wake_and_switch fun(target: integer?)
Cec = Cec or {}
Cec.send = cec_send
Cec.wake_and_switch = wake_and_switch
