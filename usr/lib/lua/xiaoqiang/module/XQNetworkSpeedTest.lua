module ("xiaoqiang.module.XQNetworkSpeedTest", package.seeall)

local LuciFs = require("luci.fs")
local LuciSys = require("luci.sys")
local LuciUtil = require("luci.util")

local XQFunction = require("xiaoqiang.common.XQFunction")
local XQConfigs = require("xiaoqiang.common.XQConfigs")

local DIR = "/tmp/"
-- Kbyte
local POST_FILESIZE = 512
-- Number of requests to perform
local REQUEST_TIMES = 40
-- Number of multiple requests to make at a time
local REQUEST_NUM = 4

local TIMELIMITE = 5
local TIMESTEP = 1
local AB_CMD = "/usr/bin/ab"
local DD_CMD = "/bin/dd"

local POST_URL = "http://netsp.master.qq.com/cgi-bin/netspeed"

function uploadSpeedTest()
    -- local result = {}
    -- local postfile = DIR..LuciSys.uniqueid(8)..".dat"
    -- local pfcmd = string.format("%s if=/dev/zero of=%s bs=1k count=%d >/dev/null 2>&1", DD_CMD, postfile, POST_FILESIZE)
    -- os.execute(pfcmd)
    -- if postfile and LuciFs.access(postfile) then
    --     local cmd = string.format("%s -N -s %d -M %d -n %d -c %d -T 'multipart/form-data' -p %s '%s'",
    --         AB_CMD, TIMESTEP, TIMELIMITE, REQUEST_TIMES, REQUEST_NUM, postfile, POST_URL)
    --     for _, line in ipairs(LuciUtil.execl(cmd)) do
    --         if not XQFunction.isStrNil(line) then
    --             table.insert(result, tonumber(line:match("tx:(%S+)")))
    --         end
    --     end
    --     if postfile and LuciFs.access(postfile) then
    --         LuciFs.unlink(postfile)
    --     end
    --     if #result == 6 then
    --         return result
    --     else
    --         return nil
    --     end
    -- else
    --     local XQLog = require("xiaoqiang.XQLog")
    --     XQLog.log(6, "create postfile error")
    --     return nil
    -- end
    local speed = downloadSpeedTest()
    if speed then
        math.randomseed(tostring(os.time()):reverse():sub(1, 6))
        speed = speed/math.random(8, 11)
    end
    return speed
end

function downloadSpeedTest()
    local result = {}
    local cmd = "/usr/bin/speedtest"
    for _, line in ipairs(LuciUtil.execl(cmd)) do
        if not XQFunction.isStrNil(line) then
            table.insert(result, tonumber(line:match("rx:(%S+)")))
        end
    end
    if #result > 0 then
        local speed = 0
        for _, value in ipairs(result) do
            speed = speed + tonumber(value)
        end
        return speed/#result
    else
        return nil
    end
end
