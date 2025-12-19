local M = {}

M.config = {
  width = 70,
  height = 15,
  border = "double",
}

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

function M.ask()
  local buf = vim.api.nvim_create_buf(false, true)

  local width = M.config.width
  local height = M.config.height
  local row = math.ceil((vim.o.lines - height) / 2) - 1
  local col = math.ceil((vim.o.columns - width) / 2) - 1

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = height,
    style = "minimal",
    border = M.config.border,
    title = " Shut It and Answer ",
    title_pos = "center",
  })

  vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")

  vim.keymap.set("n", "<CR>", function()
    local content = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local question = table.concat(content, "\n")
    print("Asking AI: " .. question:sub(1, 30) .. "...")
    vim.api.nvim_win_close(win, true)
  end, { buffer = buf })

  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(win, true)
  end, { buffer = buf })
end

return M
