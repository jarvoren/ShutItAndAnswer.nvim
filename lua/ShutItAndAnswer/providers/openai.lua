local M = {}

-- Helper to find the key
local function get_api_key()
  local f = io.open(vim.fn.expand("~/.aiApiKey"), "r")
  if f then
    local key = f:read("*all"):gsub("%s+", "")
    f:close()
    return key
  end
  return nil
end

function M.handle(question)
  local api_key = get_api_key()
  if not api_key then
    return { error = "OpenAI API Key not found in ~/.aiApiKey" }
  end

  local data_table = {
    model = "gpt-4o",
    messages = { { role = "user", content = question } },
  }
  local data_json = vim.fn.json_encode(data_table)

  -- DEBUG: Save request JSON
  -- Change this path to your preferred debug location
  local debug_req_path = vim.fn.expand("~/.cache/nvim/shut_it_request.json")
  local debug_file = io.open(debug_req_path, "w")
  if debug_file then
    debug_file:write(data_json)
    debug_file:close()
  end

  return {
    cmd = {
      "curl",
      "-s",
      "https://api.openai.com/v1/chat/completions",
      "-H",
      "Content-Type: application/json",
      "-H",
      "Authorization: Bearer " .. api_key,
      "-d",
      data_json,
    },
    parse = function(stdout)
      -- DEBUG: Save raw response JSON
      local debug_resp_path = vim.fn.expand("~/.cache/nvim/shut_it_response.json")
      local resp_debug = io.open(debug_resp_path, "w")
      if resp_debug then
        resp_debug:write(stdout or "NULL STDOUT")
        resp_debug:close()
      end

      local status, decoded = pcall(vim.fn.json_decode, stdout)
      if status and decoded and decoded.choices then
        return decoded.choices[1].message.content
      elseif decoded and decoded.error then
        return "API Error: " .. (decoded.error.message or "Unknown error")
      end
      return "Error: Could not parse response. Check " .. debug_resp_path
    end,
  }
end

return M
