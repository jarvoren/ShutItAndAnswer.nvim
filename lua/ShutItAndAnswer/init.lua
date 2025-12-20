local function get_api_key()
  local f = io.open(vim.fn.expand("~/.aiApiKey"), "r")
  if f then
    local key = f:read("*all"):gsub("%s+", "")
    f:close()
    return key
  end
  return nil
end

local M = {}

M.config = {}

local defaults = {
  width = 60,
  height = 10,
  border = "rounded",
}

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

function M.ask()
  local config = vim.tbl_isempty(M.config) and defaults or M.config
  local api_key = get_api_key()

  if not api_key then
    print("Error: Could not find API key file.")
    return
  end

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

    vim.api.nvim_buf_set_lines(buf, -1, -1, false, { "", "---", "**GPT-4o:**", "Thinking..." })

    local data = vim.fn.json_encode({
      model = "gpt-4o",
      messages = { { role = "user", content = question } },
    })

    -- DEBUG: Save request JSON to a file
    local debug_file = io.open(vim.fn.expand("~/projects/ShutItAndAnswer.nvim/debug_request.json"), "w")
    if debug_file then
      debug_file:write(data)
      debug_file:close()
    end

    local cmd = {
      "curl",
      "https://api.openai.com/v1/chat/completions",
      "-H",
      "Content-Type: application/json",
      "-H",
      "Authorization: Bearer " .. api_key,
      "-d",
      data,
    }

    vim.system(cmd, { text = true }, function(obj)
      vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(buf) then
          return
        end

        local response_text = ""

        -- DEBUG: Save raw response to a file
        local resp_debug = io.open(vim.fn.expand("~/projects/ShutItAndAnswer.nvim/debug_response.json"), "w")
        if resp_debug then
          resp_debug:write(obj.stdout or "NULL STDOUT")
          resp_debug:close()
        end

        if obj.code ~= 0 then
          response_text = "Error: Curl failed with code " .. obj.code
        else
          local status, decoded = pcall(vim.fn.json_decode, obj.stdout)
          if status and decoded and decoded.choices then
            response_text = decoded.choices[1].message.content
          elseif decoded and decoded.error then
            -- This captures the actual message from OpenAI (e.g., "Invalid API Key")
            response_text = "API Error: " .. (decoded.error.message or "Unknown error")
          else
            response_text = "Error: Could not parse response. Check debug_response.json"
          end
        end

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
