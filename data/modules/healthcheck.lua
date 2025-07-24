local nk = require("nakama")

local function healthcheck_rpc(context, payload)
    nk.logger_info("Healthcheck RPC called.")
    return nk.json_encode({ ["success"] = true })
end

nk.register_rpc(healthcheck_rpc, "healthcheck_lua")