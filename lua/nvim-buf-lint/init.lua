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

local create_nvim_buf_lint_namespace = function(name)
    local ns_list = vim.api.nvim_get_namespaces()
    local ns_should_create = true
    local ns_nvim_buf_lint_diagnostic

    for active_ns_name, ns in ipairs(ns_list) do
        if active_ns_name == name then
            ns_should_create = false
            ns_nvim_buf_lint_diagnostic = ns
        end
    end

    if ns_should_create then
        ns_nvim_buf_lint_diagnostic = vim.api.nvim_create_namespace(name)
    else
        vim.diagnostic.clear(ns_nvim_buf_lint_diagnostic, 0)
    end

    return ns_nvim_buf_lint_diagnostic
end

-- inject error messages to current buffer
local inject_error_message = function(_, data)
    local diagnostics = parse_json(data)
    local fname = vim.fn.expand("%")

    if diagnostics then
        -- create namespace for this diagnostic if it does not exist
        -- if it exist, simply clear the diagnostics in that namespace
        -- collect all diagnostics
        -- 
        -- Also, the diagnostic framework uses 0 based indexing, so we have to shift everything
        -- by 1
        local d_at_buffer = {}
        for _, diagnostic in ipairs(diagnostics) do
            if fname == diagnostic.path then
                table.insert(d_at_buffer, {
                    lnum = diagnostic.start_line - 1,
                    end_lnum = diagnostic.end_line - 1,
                    col = diagnostic.start_column - 1,
                    end_col = diagnostic.end_column - 1,
                    message = diagnostic.message,
                    source = "nvim-buf-lint",
                })
            end
        end

        -- inject list of diagnostics to current buffer
        local ns = create_nvim_buf_lint_namespace("nvim_buf_lint_ns")
        vim.diagnostic.set(ns, 0, d_at_buffer, nil)
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
-- - exe_path (string) : executable path to buf.build (default 'buf', or in otherwords system wide)
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
