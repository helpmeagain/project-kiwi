local nk = require("nakama")

local function create_leaderboard(ctx, payload)
    nk.logger_info("Leaderboard creation called.")
    local id = "global_leaderboard"
    local authoritative = false
    local sort = "desc"
    local operator = "set"
    local reset = ""

    nk.leaderboard_create(id, authoritative, sort, operator, reset)
    return nk.json_encode({ 
        success = true, 
        message = "Leaderboard criado: " .. id 
    })
end

nk.register_rpc(create_leaderboard, "create_leaderboard_lua")