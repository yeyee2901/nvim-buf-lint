-- lint the current project
local lint = function()
    local command = "buf lint --error-format json"

    vim.fn.jobstart(command, {
        stdout_buffered = true,
        on_stdout = function(_, data)
            if not data then
                return
            end

            -- parse the json from stdout
            local result = {}
            for _, line in ipairs(data) do
                local ok, lint_entry  = pcall(vim.json.decode, line)
                if ok then
                    table.insert(result, lint_entry)
                end
            end
        end
    })
end

return {
    lint = lint,
}
