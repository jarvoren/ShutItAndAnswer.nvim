vim.api.nvim_create_user_command("ShutItAndAnswer", function()
  require("ShutItAndAnswer").ask()
end, {})

vim.keymap.set("n", "<leader>a", "<cmd>ShutItAndAnswer<cr>", { desc = "[A]sk AI" })
