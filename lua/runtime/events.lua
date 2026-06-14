local M = {}

function M.setup()
    -- Existing (currently empty) setup logic can stay.
    -- -------------------------------------------------
    -- NEW: Register :License command
    vim.api.nvim_create_user_command(
        "License",
        function()
            require("infra.license").show()
        end,
        { desc = "Show the project LICENSE" }
    )
    -- -------------------------------------------------
end

return M
