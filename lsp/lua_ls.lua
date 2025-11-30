return {
  on_init = function(client)
    if client.workspace_folders then
      local path = client.workspace_folders[1].name
      if path ~= vim.fn.stdpath 'config' and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc')) then
        return
      end
    end

    client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
      runtime = {
        -- 告诉语言服务器你正在使用的 Lua 版本（在 Neovim 的情况下很可能是 LuaJIT）
        version = 'LuaJIT',
        -- 告诉语言服务器如何像 Neovim 一样查找 Lua 模块
        -- （参见 `:h lua-module-load`）
        path = {
          'lua/?.lua',
          'lua/?/init.lua',
        },
      },
      -- 让服务器知道 Neovim 运行时文件
      workspace = {
        checkThirdParty = false,
        library = {
          vim.env.VIMRUNTIME,
          -- 根据使用情况，你可能想在这里添加额外的路径
          -- '${3rd}/luv/library'
          -- '${3rd}/busted/library'
        },
        -- 或者引入所有的 'runtimepath'
        -- 注意：这样会慢很多，并且在处理你自己的配置时可能会导致问题
        -- 参见 https://github.com/neovim/nvim-lspconfig/issues/3189
        -- library = {
        --   vim.api.nvim_get_runtime_file('', true),
        -- }
      },
    })
  end,
  settings = {
    Lua = {
     diagnostics = { globals = { 'vim' } },                                 -- 忽略全局变量 vim 的警告
      workspace = {
        library = vim.api.nvim_get_runtime_file('', true),
        checkThirdParty = false,
      },
      format = { enable = true }, -- 启用格式化
    },
  },
  cmd = { 'lua-language-server' }, -- 启动命令
  filetypes = { 'lua' },
}
