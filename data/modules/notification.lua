local nk = require("nakama")

local function start_game_notification(context, payload)
    nk.logger_info("Notification send RPC called.")
    local subject = "Start game notification"
    local content = { message = "Start game!" }
    local code = 1
    local persistent = false

    nk.notification_send_all(subject, content, code, persistent)
    return nk.json_encode({ success = true, message = "Notification sent to all users." })
end

nk.register_rpc(start_game_notification, "start_game_notification_lua")
