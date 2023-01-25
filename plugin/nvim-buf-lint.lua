vim.api.nvim_create_user_command("BufLintCurrentBuffer", require("nvim-buf-lint").lint, {})
