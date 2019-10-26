-- Core APIs for OC-OS --

-- print, write, error, panic, len, getColor, setColor, setCursorPos, getCursorPos, log, fs.*, os.*, clearScreen are here

function os.version()
    return _version
end

clearScreen()
setCursorPos(1,1)
log("Booting " .. os.version())

log("Registering path resolver...")
function resolvePath(path)
    local rtn = path
    if rtn:sub(1,1) == "/" then
        rtn = osDir .. rtn
    end
    local rootFiles = fs.list("/")
    while rtn:sub(1,2) == ".." and fs.list(rtn) == rootFiles do
        rtn = rtn:sub(3)
    end

    return rtn
end

log("Registering system-protected folders...")
local protected = {
    osDir .. "sys/",
    osDir .. "sys/core/",
    osDir .. "programs/",
    "/sys/",
    "/sys/core/",
    "/programs/"
}

log("Wrapping fs.open in preparation for multiuser...")

local nativeOpen = fs.open

function fs.open(f, mode)
    local file = resolvePath(f)
    local root = false
    for i=1, #protected, 1 do
        if file:sub(1, len(protected[i])) == protected[i] then
            root = true
        end
    end
    if root then
        if _G.__user__ == "root" and _G.__uid__ == 0 then
            local h = nativeOpen(file, mode)
            return h
        else
            error("Permission denied")
            return nil
        end
    else
        local h = nativeOpen(file, mode)
        return h
    end
end

log("Wrapping fs.exists for sandboxing purposes...")

local nativeExists = fs.exists

function fs.exists(p)
    local path = resolvePath(p)
    if nativeExists(path) then
        return true
    else
        return false
    end
end

log("Initializing run()...")

function run(file)
    if fs.exists(file) then
        os.run(_G, file)
    else
        error("File not found: " .. file)
        return nil
    end
end

log("Initializing networking: check HTTP, set hostname")

_G.net = {}

if not http then
    log("No HTTP")
end

log("Initializing user subsystem...")

_G.__user__ = "root"
_G.__uid__ = 0

_G.users = {}

local root_password = "root" -- Shhhh, don't tell anyone!

function users.login(user, passwd)
    local function x(file)
        local handle = fs.open("/sys/userdata/" .. file)
        if not handle then
            return nil
        end

        local data = {}

        while true do
            local line = handle:readLine()
            if line and line ~= "" then
                table.insert(data,line)
            else
                break
            end
        end
        handle.close()
        return data
    end

    local names = x("names")
    local passwords = x("passwords")

    for i=1, #names, 1 do
        if names[i] == user then
            if passwords[i] == passwd then
                _G.__user__ = user
                _G.__uid__ = i
                return true -- Success! We're logged in.
            else
                return false -- Better luck next time.
            end
        end
    end
    if user == "root" and passwd == root_password then
        __user__ = "root"
        __uid__ = 0
    end
end

function users.logout()
    _G.__user__ = ""
    _G.__uid__ = -1
end

function users.homeDir(user)
    return resolvePath("/users/" .. user .. "/")
end

log("Initializing shell API...")

os.loadAPI("/sys/apis/shell.lua")

if not shell then panic("OC-OS Shell could not be loaded") end

log("Initializing login system...")

run("/programs/login.lua")
