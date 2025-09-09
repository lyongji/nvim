return {
  {
    "Kurama622/llm.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim" },
    cmd = { "LLMSessionToggle", "LLMSelectedTextHandler", "LLMAppHandler" },
    config = function()
      require("llm").setup({
        name = "SiliconFlow",
        url = "https://api.siliconflow.cn/v1/chat/completions",
        -- model = "THUDM/glm-4-9b-chat",
        api_type = "openai",
        -- max_tokens = 4096,
        -- model = "01-ai/Yi-1.5-9B-Chat-16K",
        -- model = "google/gemma-2-9b-it",
        -- model = "meta-llama/Meta-Llama-3.1-8B-Instruct",
        -- model = "Qwen/Qwen2.5-7B-Instruct",
        model = "THUDM/GLM-4.1V-9B-Thinking",
        -- model = "Qwen/Qwen3-8B", -- think
        -- model = "Qwen/Qwen2.5-Coder-7B-Instruct",
        -- model = "internlm/internlm2_5-7b-chat",
        fetch_key = vim.env.SILICONFLOW_TOKEN,
        temperature = 0.3,
        top_p = 0.7,
        enable_thinking = true,
      })
    end,
    keys = {
      { "<leader>ac", mode = "n", "<cmd>LLMSessionToggle<cr>" },
    },
  },
}
