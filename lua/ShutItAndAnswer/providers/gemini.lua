local M = {}

function M.handle(question)
  -- Replace 'gemini-cli' with the actual command you use in your terminal
  return {
    cmd = { "gemini", "-p", question },
    parse = function(stdout)
      -- If your CLI returns raw text, we just return it.
      -- If it returns JSON, you'd use vim.fn.json_decode here.
      return stdout or "Error: Local Gemini produced no output."
    end,
  }
end

return M
