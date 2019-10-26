-- Login system for OC-OS --

local loginPrompt = {"__HOSTNAME__", " login: "}
local passwordPrompt = {"password: "}

while true do
    while true do
        shell.renderPrompt(loginPrompt)
        local name = read()
        shell.renderPrompt(passwordPrompt)
        local pswd = read("*")
        if users.login(name, pswd) then break end
    end
    run("/programs/oc-shell.lua")
end
