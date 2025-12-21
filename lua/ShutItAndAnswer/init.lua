local M = {}

M.config = {}

local defaults = {
  preprompt = "Give concise message without any propositions",
  width = 100,
  height = 20,
  provider = "gemini",
  border = "rounded",
}

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

function M.ask()
  local config = vim.tbl_isempty(M.config) and defaults or M.config

  local buf = vim.api.nvim_create_buf(false, true)
  local row = math.ceil((vim.o.lines - config.height) / 2) - 1
  local col = math.ceil((vim.o.columns - config.width) / 2) - 1

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    row = row,
    col = col,
    width = config.width,
    height = config.height,
    style = "minimal",
    border = config.border,
    title = " Shut It and Answer ",
    title_pos = "center",
  })

  vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
  vim.cmd("startinsert")

  vim.keymap.set("n", "<CR>", function()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local question = table.concat(lines, "\n")
    question = config.preprompt .. " " .. question
    -- 1. Identify which provider to use
    local provider_name = M.config.provider or "gemini"
    local provider = require("ShutItAndAnswer.providers." .. provider_name)

    -- 2. Get the specific command and parser
    local job = provider.handle(question)

    vim.api.nvim_buf_set_lines(buf, -1, -1, false, { "", "---", "**" .. provider_name .. ":**", "Thinking..." })

    -- 3. Run the command (works for both curl and local CLI)
    vim.system(job.cmd, { text = true }, function(obj)
      vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(buf) then
          return
        end

        local response_text = (obj.code == 0) and job.parse(obj.stdout)
            or "Error: Command failed with code " .. obj.code

        -- Update the "Thinking..." line with the actual response
        local current_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        for i, line in ipairs(current_lines) do
          if line == "Thinking..." then
            local response_lines = vim.split(response_text, "\n")
            vim.api.nvim_buf_set_lines(buf, i - 1, i, false, response_lines)
            break
          end
        end
      end)
    end)
  end, { buffer = buf })

  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(win, true)
  end, { buffer = buf })
end

return M
