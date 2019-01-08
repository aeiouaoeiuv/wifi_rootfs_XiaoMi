module ("xiaoqiang.module.XQMessageBox", package.seeall)

local XQFunction = require("xiaoqiang.common.XQFunction")
local XQConfigs = require("xiaoqiang.common.XQConfigs")
local XQCache = require("xiaoqiang.util.XQCacheUtil")

local MESSAGE_EXPIRE_TIME = 86400
local MESSAGE_BOX = "XQMessageBox"

function addMessage(message)
    if not message or not message["type"] or not message["data"] then
        return
    end
    local messages = XQCache.getCache(MESSAGE_BOX)
    message["timestamp"] = os.time()
    if not messages then
        messages = {}
        table.insert(messages, message)
    else
        local exists = false
        for _, item in ipairs(messages) do
            if message["type"] == item["type"] then
                exists = true
                item["data"] = message["data"]
                break
            end
        end
        if not exists then
            table.insert(messages, message)
        end
    end
    XQCache.saveCache(MESSAGE_BOX, messages, MESSAGE_EXPIRE_TIME)
end

function getMessages()
    return XQCache.getCache(MESSAGE_BOX) or {}
end

function removeMessage(mtype)
    if mtype and tonumber(mtype) then
        local messages = XQCache.getCache(MESSAGE_BOX)
        for index, message in ipairs(messages) do
            if message["type"] == tonumber(mtype) then
                table.remove(messages, index)
            end
        end
        XQCache.saveCache(MESSAGE_BOX, messages, MESSAGE_EXPIRE_TIME)
    end
end