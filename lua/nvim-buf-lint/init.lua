local M = {}

local parse_json = function(json_data)
    if not json_data then
        return
    end

    local result = {}
    for _, line in ipairs(json_data) do
        local ok, lint_entry  = pcall(vim.json.decode, line)
        if ok then
            table.insert(result, lint_entry)
        end
    end

    return result
end

-- inject error messages to current buffer
local inject_error_message = function(_, data)
    local diagnostics = parse_json(data)
    local fname = vim.fn.expand("%")

    if diagnostics then
        for _, diagnostic in ipairs(diagnostics) do
            if fname == diagnostic.path then
                print("THis file is problematic!")
            end
        end
    end
end

-- get current diagnostic by running `buf lint`
local lint = function()
    local command = string.format("%s lint --error-format json", M.config.exe_path)
    vim.fn.jobstart(command, {
        stdout_buffered = true,
        on_stdout = inject_error_message,
    })
end

-- init function
-- params:
-- - exe_path: executable path to buf.build (default 'buf', or in otherwords system wide)
M.init = function(config)
    -- defaults
    if not config then
        config = {
            exe_path = "buf",
        }
    end

    -- check if buf exists
    if not (vim.fn.executable(config.exe_path) == 1) then
        print("executable for `buf` does not exist, please install it first by running `go install github.com/bufbuild/buf/cmd/buf@latest`")
        return
    end

    -- initialize the table
    M.lint = lint
    M.config = config
end

return M
