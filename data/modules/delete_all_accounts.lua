local nk = require("nakama")

local function delete_all_accounts(context, payload)
    local query = [[
        SELECT id FROM users
        WHERE id != '00000000-0000-0000-0000-000000000000'
    ]]
    
    local rows, err = nk.sql_query(query)
    
    if err then
        return nk.json_encode({ success = false, error = err })
    end

    for _, row in ipairs(rows) do
        nk.account_delete_id(row.id, false)
    end

    return nk.json_encode({ success = true })
end

nk.register_rpc(delete_all_accounts, "delete_all_accounts_lua")