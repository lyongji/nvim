-- ==============================================================
-- 插件花名册
-- ==============================================================
local specs = {
  -- 公共依赖
  "https://github.com/nvim-lua/plenary.nvim", -- lua函数库
  "https://github.com/williamboman/mason.nvim",
  "https://github.com/mason-org/mason-registry",
  "https://github.com/nvim-tree/nvim-web-devicons", -- 图标库
  -- 主题色.lua
  "https://github.com/Mofiqul/dracula.nvim",
  -- 光标特效.lua
  "https://github.com/sphamba/smear-cursor.nvim",
  -- 剪贴板.lua
  "https://github.com/gbprod/yanky.nvim",
  -- 补全.lua 自动补全、代码片段
  "https://github.com/saghen/blink.cmp",
  "https://github.com/rafamadriz/friendly-snippets",
  -- lsp.lua 语言服务器
  "https://github.com/neovim/nvim-lspconfig",
  "https://github.com/williamboman/mason-lspconfig.nvim",
  "https://github.com/MysticalDevil/inlay-hints.nvim", -- 内联提示增强
  -- 内联诊断
  "https://github.com/rachartier/tiny-inline-diagnostic.nvim",
  -- 代码格式化.lua 格式化工具formatter
  "https://github.com/stevearc/conform.nvim",
  -- 彩虹缩进.lua
  "https://github.com/lukas-reineke/indent-blankline.nvim",
  -- 代码折叠.lua 折叠插件
  "https://github.com/kevinhwang91/nvim-ufo",
  "https://github.com/kevinhwang91/promise-async", -- 异步执行
  --  顶部标签栏.lua
  "https://github.com/akinsho/bufferline.nvim",
  -- lualine.lua 底部状态栏
  "https://github.com/nvim-lualine/lualine.nvim",
  -- 代码大纲视图.lua 大纲、函数变量结构
  "https://github.com/hedyhli/outline.nvim",
  -- 弹窗.lua 取代消息、命令行和弹出菜单的 UI
  "https://github.com/folke/noice.nvim",
  "https://github.com/MunifTanjim/nui.nvim",
  -- snacks.lua 图片预览、lazygit、lsp_references模糊查找
  -- "https://github.com/folke/snacks.nvim",
  -- 环绕.lua 各种对字符的surround包裹{} [] ''
  "https://github.com/nvim-mini/mini.surround",
  -- 括号自动配对.lua 对字符自动补全另一半
  "https://github.com/windwp/nvim-autopairs",
  -- tv.lua 模糊查找television
  -- "https://github.com/alexpasmantier/tv.nvim",
  -- peek.lua 预览markdown
  -- 'https://github.com/cap153/peek.nvim',
  -- xmake.lua
  { src = "https://github.com/Mythos-404/xmake.nvim", name = "xmake" },
  -- yazi.lua 文件管理器
  "https://github.com/mikavilpas/yazi.nvim",
  -- 查看可用键位
  "https://github.com/folke/which-key.nvim",
}
-- 禁用插件：不会加载，不会下载(如果是新添加的)，已在硬盘上不会被删除
local disabled = {
  -- { src = 'https://github.com/saghen/blink.cmp', version = 'v1.10.2' }, -- 指定版本，暂时不想用，但想留着源码
}
-- ==============================================================
-- 快捷管理命令
-- ==============================================================

-- 获取所有已安装插件的名称列表（用于命令行 Tab 补全）
local function get_plugin_names(arg_lead)
  local installed = vim.pack.get(nil, { info = false })
  local names = {}
  for _, p in ipairs(installed) do
    local name = p.spec.name
    -- 只添加与用户输入开头匹配的插件名（不区分大小写）
    if name:lower():find(arg_lead:lower(), 1, true) == 1 then
      table.insert(names, name)
    end
  end
  -- 排序让补全列表更整洁
  table.sort(names)
  return names
end

-- :PackUpdate 命令——更新插件
-- 不带参数时更新全部插件，默认显示审查界面（需按 :w 确认）
-- 加 ! 后缀（即 :PackUpdate!）可跳过确认直接强制更新
vim.api.nvim_create_user_command("PackUpdate", function(opts)
  local targets = #opts.fargs > 0 and opts.fargs or nil
  local force = opts.bang -- 如果输入了 PackUpdate! 则 opts.bang 为 true

  if targets then
    vim.notify("正在检查更新: " .. table.concat(targets, ", "), vim.log.levels.INFO)
  else
    vim.notify("正在检查所有插件的更新...", vim.log.levels.INFO)
  end

  vim.pack.update(targets, { force = force })
end, {
  nargs = "*",
  bang = true, -- 声明该命令支持 ! 后缀
  complete = get_plugin_names,
  desc = "更新插件（加 ! 跳过确认）",
})

-- :PackStatus 命令——查看插件当前状态和版本（离线模式，不下载）
vim.api.nvim_create_user_command("PackStatus", function(opts)
  local targets = #opts.fargs > 0 and opts.fargs or nil
  vim.pack.update(targets, { offline = true })
end, {
  nargs = "*",
  complete = get_plugin_names,
  desc = "查看插件状态（不联网下载）",
})

-- ==============================================================
-- 插件管理引擎 (PackUtils)
-- 暴露到全局 _G，供 configs/*.lua 配置文件调用
-- ==============================================================

_G.PackUtils = {
  is_building = {},      -- 记录各插件的构建状态，防止重复构建
  is_initialized = {},   -- 记录具体的配置代码块是否已执行（按调用位置去重）
  plugin_loaded = {},    -- 记录插件是否已挂载到运行时路径（避免重复 packadd）
  disabled_plugins = {}, -- 记录被禁用的插件名单，供 load 函数拦截使用
}

-- [解析插件名]
-- 从插件规格（spec）中提取简短名称
-- 例如 "https://github.com/user/repo.git" → "repo"
function PackUtils.get_name(spec)
  local url = type(spec) == "table" and spec.src or spec
  return type(spec) == "table" and spec.name or url:match("([^\\/]+)$"):gsub("%.git$", "")
end

-- [同步清理]
-- 扫描磁盘上已安装的插件，自动删除不在活跃列表和禁用列表中的"孤儿"插件
-- 同时将禁用列表写入 disabled_plugins 字典
function PackUtils.sync(active_specs, disabled_specs)
  disabled_specs = disabled_specs or {}
  local protected_names = {}

  -- 将活跃插件加入受保护名单
  for _, spec in ipairs(active_specs) do
    protected_names[PackUtils.get_name(spec)] = true
  end

  -- 将禁用插件也加入受保护名单（不删除，只是不加载）
  for _, spec in ipairs(disabled_specs) do
    local name = PackUtils.get_name(spec)
    protected_names[name] = true
    PackUtils.disabled_plugins[name] = true -- 写入禁用字典，供 load 拦截
  end

  -- 扫描磁盘上 pack 目录下所有已安装的插件
  local pack_dir = vim.fn.stdpath("data") .. "/site/pack"
  local installed_plugins = {}
  local packages = vim.fn.expand(pack_dir .. "/*", false, true)
  for _, pkg in ipairs(packages) do
    for _, type_dir in ipairs({ "start", "opt" }) do
      local path = pkg .. "/" .. type_dir
      if vim.fn.isdirectory(path) == 1 then
        local dirs = vim.fn.expand(path .. "/*", false, true)
        for _, dir in ipairs(dirs) do
          local name = dir:match("([^\\/]+)$")
          -- 排除非插件目录（如 README.md、doc）
          if name ~= "README.md" and name ~= "doc" then
            table.insert(installed_plugins, name)
          end
        end
      end
    end
  end

  -- 找出既不在活跃列表也不在禁用列表中的孤儿插件
  local to_delete = {}
  for _, installed in ipairs(installed_plugins) do
    if not protected_names[installed] then
      table.insert(to_delete, installed)
    end
  end

  -- 如果有孤儿插件，异步通知并删除
  if #to_delete > 0 then
    vim.schedule(function()
      vim.notify("🧹 清理孤儿插件: " .. table.concat(to_delete, ", "), vim.log.levels.INFO)
      vim.pack.del(to_delete)
    end)
  end
end

-- [动态路径]
-- 获取插件在磁盘上的根目录路径
function PackUtils.get_root(name)
  name = PackUtils.get_name(name)
  -- 优先从运行时文件列表中查找
  local paths = vim.api.nvim_get_runtime_file("pack/*/*/" .. name, true)
  if #paths > 0 then
    return paths[1]
  end
  -- 备选：通过 globpath 在 packpath 中搜索
  local glob = vim.fn.globpath(vim.o.packpath, "pack/*/*/" .. name, 0, 1)
  return glob[1] or nil
end

-- [构建执行]
-- 执行插件的编译/构建任务
-- 支持三种形式：
--   1. 字符串命令（如 "make install"）
--   2. 表形式命令（如 {"make", "install"}）
--   3. Vim 内部命令（以 ":" 开头，如 ":TSUpdate"）
function PackUtils.run_build(name, build_cmd)
  name = PackUtils.get_name(name)
  -- 禁用的插件不执行构建
  if PackUtils.disabled_plugins[name] then
    return
  end
  -- 没有构建命令或正在构建中，直接返回
  if not build_cmd or PackUtils.is_building[name] then
    return
  end

  local path = PackUtils.get_root(name)
  if not path then
    return
  end

  -- 构建完成标记文件，用于判断是否需要重新构建
  local stamp = path .. "/.build_done"
  PackUtils.is_building[name] = true

  -- 判断是否为 Neovim 内部命令（以 ":" 开头）
  local is_vim_cmd = false
  local vim_cmd_str = ""
  if type(build_cmd) == "string" and build_cmd:sub(1, 1) == ":" then
    is_vim_cmd = true
    vim_cmd_str = build_cmd:sub(2) -- 去掉开头的 ":"
  elseif type(build_cmd) == "table" and type(build_cmd[1]) == "string" and build_cmd[1]:sub(1, 1) == ":" then
    is_vim_cmd = true
    vim_cmd_str = table.concat(build_cmd, " "):sub(2)
  end

  if is_vim_cmd then
    -- Vim 内部命令：在主线程空闲时执行
    vim.schedule(function()
      vim.notify("⚙️ 正在执行 " .. name .. " 的设置命令...", vim.log.levels.INFO)
      -- 确保插件已被加载到当前实例中
      pcall(vim.cmd.packadd, name)
      -- 用 pcall 保护执行，防止命令出错导致编辑器崩溃
      local ok, err = pcall(vim.cmd, vim_cmd_str)
      PackUtils.is_building[name] = false
      if ok then
        -- 写入完成标记文件
        local f = io.open(stamp, "w")
        if f then
          f:close()
        end
        vim.notify("✅ " .. name .. " 设置成功。", vim.log.levels.INFO)
      else
        vim.notify("❌ " .. name .. " 设置失败: " .. tostring(err), vim.log.levels.ERROR)
      end
    end)
  else
    -- 外部 Shell 命令：在后台异步执行
    local final_cmd = {}
    if type(build_cmd) == "string" then
      -- 将字符串按空格拆分为参数列表
      for word in build_cmd:gmatch("%S+") do
        table.insert(final_cmd, word)
      end
    else
      final_cmd = build_cmd
    end

    vim.schedule(function()
      vim.notify("⚙️ 正在后台构建 " .. name .. "...", vim.log.levels.INFO)
    end)

    -- 使用 vim.system 异步执行外部命令
    vim.system(final_cmd, { cwd = path }, function(out)
      PackUtils.is_building[name] = false
      if out.code == 0 then
        -- 构建成功，写入完成标记文件
        local f = io.open(stamp, "w")
        if f then
          f:close()
        end
        vim.schedule(function()
          vim.notify("✅ " .. name .. " 构建成功。", vim.log.levels.INFO)
        end)
      else
        vim.schedule(function()
          vim.notify(
            "❌ " .. name .. " 构建失败: " .. (out.stderr or "未知错误"),
            vim.log.levels.ERROR
          )
        end)
      end
    end)
  end
end

-- [监听器]
-- 注册 PackChanged 自动命令，当插件被安装或更新时自动触发构建
function PackUtils.setup_listener(name, build_cmd)
  name = PackUtils.get_name(name)
  -- 禁用的插件不注册监听
  if PackUtils.disabled_plugins[name] then
    return
  end
  if not build_cmd then
    return
  end

  vim.api.nvim_create_autocmd("PackChanged", {
    pattern = "*",
    callback = function(ev)
      -- 仅在目标插件发生安装或更新时触发
      if ev.data.spec.name == name and (ev.data.kind == "update" or ev.data.kind == "install") then
        local stamp = ev.data.path .. "/.build_done"
        os.remove(stamp) -- 删除构建完成标记，强制重新构建
        PackUtils.run_build(name, build_cmd)
      end
    end,
  })
end

-- [健康检查]
-- 检查插件是否已完成构建，如果缺少 .build_done 标记文件则触发构建
function PackUtils.check_health(name, build_cmd)
  name = PackUtils.get_name(name)
  if PackUtils.disabled_plugins[name] then
    return
  end
  if not build_cmd then
    return
  end

  local path = PackUtils.get_root(name)
  if path then
    local stamp = path .. "/.build_done"
    -- 标记文件不存在，说明从未成功构建过，触发构建
    if vim.fn.filereadable(stamp) == 0 then
      PackUtils.run_build(name, build_cmd)
    end
  end
end

-- [核心加载函数]
-- 全方位防崩加载引擎：负责挂载插件、加载依赖、执行配置
-- P 参数结构：{ name = "插件名", build_cmd = "构建命令"（可选）, deps = {"依赖1", "依赖2"}（可选） }
-- config_fn：配置回调函数，在插件加载后执行（如 require("xxx").setup({...})）
function PackUtils.load(P, config_fn)
  -- 生成调用位置的唯一标识（如 "lua/pack/configs/mini.lua:24"）
  -- 用于精确去重，确保同一行代码不会被重复执行
  local info = debug.getinfo(2, "Sl")
  local call_id = (info.short_src or "unknown") .. ":" .. (info.currentline or 0)

  -- 精准拦截：如果这一行代码已经成功执行过，直接跳过
  if PackUtils.is_initialized[call_id] then
    return
  end

  -- 规范化插件名和依赖名
  P.name = PackUtils.get_name(P.name)
  if P.deps then
    for i, dep in ipairs(P.deps) do
      P.deps[i] = PackUtils.get_name(dep)
    end
  end

  -- 如果插件在禁用名单中，直接返回不加载
  if PackUtils.disabled_plugins[P.name] then
    return
  end

  -- 磁盘中找不到插件目录，说明它正在异步克隆下载中，静默退出
  if not PackUtils.get_root(P.name) then
    return
  end

  -- === 插件级操作：整个生命周期只需做一次的动作 ===
  if not PackUtils.plugin_loaded[P.name] then
    -- 检查是否需要构建
    PackUtils.check_health(P.name, P.build_cmd)
    -- 将插件挂载到 Neovim 运行时路径
    pcall(vim.cmd.packadd, P.name)

    -- 挂载所有依赖插件
    if P.deps then
      for _, dep in ipairs(P.deps) do
        local dep_ok = pcall(vim.cmd.packadd, dep)
        if not dep_ok then
          vim.notify("警告: " .. P.name .. " 的依赖 [" .. dep .. "] 缺失", vim.log.levels.WARN)
        end
      end
    end

    -- 标记该插件已完成挂载
    PackUtils.plugin_loaded[P.name] = true
  end

  -- === 执行用户配置函数 ===
  -- 用 pcall 保护执行，捕获所有错误（如 require 路径拼写错误等）
  if config_fn then
    local setup_ok, err = pcall(config_fn)
    if not setup_ok then
      vim.notify("错误: " .. P.name .. " 配置执行失败: \n" .. tostring(err), vim.log.levels.ERROR)
      return -- 配置失败时不标记为已初始化，允许下次重试
    end
  end

  -- 标记这个具体的代码调用位置已执行完毕
  PackUtils.is_initialized[call_id] = true
end

-- ==============================================================
-- 执行启动流程
-- ==============================================================

-- 第一步：同步清理孤儿插件，并注册禁用名单
PackUtils.sync(specs, disabled)

-- 第二步：正式下载/安装所有活跃插件
vim.pack.add(specs)

-- 第三步：加载 configs/ 目录下所有配置文件
-- 每个文件负责注册对应插件的监听器和配置
local config_path = vim.fn.stdpath("config") .. "/lua/pack/configs"
if vim.fn.isdirectory(config_path) == 1 then
  for name, type in vim.fs.dir(config_path) do
    if type == "file" and name:match("%.lua$") then
      -- 用 pcall 保护加载，单个配置文件出错不影响其他插件
      pcall(require, "pack.configs." .. name:gsub("%.lua$", ""))
    end
  end
end
