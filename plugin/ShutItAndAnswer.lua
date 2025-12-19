vim.api.nvim_create_user_command("ShutItAndAnswer", function()
  require("ShutItAndAnswer").ask()
end, {})
