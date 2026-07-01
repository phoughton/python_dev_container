-- ============================================================================
-- Simple Neovim config: Python development and debugging, with a file tree.
--
-- Requirements (install these yourself before first launch):
--   * Neovim 0.11 or later (this uses the native vim.lsp.config / vim.lsp.enable
--     API introduced in 0.11; 0.12 is fine too).
--   * git.
--   * Node.js, because basedpyright is installed by Mason as an npm package.
--   * Python 3 with pip, because Mason installs debugpy into its own venv.
--   * A Nerd Font selected in your terminal, for the file tree icons. If you do
--     not want icons, remove the "nvim-web-devicons" dependency below.
-- No C compiler or tree-sitter CLI is needed, because this config does not use
-- nvim-treesitter. basedpyright provides semantic highlighting on 0.11+.
--
-- Install:
--   1. Back up any existing setup:
--        mv ~/.config/nvim ~/.config/nvim.bak 2>/dev/null || true
--        mv ~/.local/share/nvim ~/.local/share/nvim.bak 2>/dev/null || true
--   2. Save this file as ~/.config/nvim/init.lua
--   3. Launch nvim. lazy.nvim installs the plugins, then Mason downloads
--      basedpyright, ruff and debugpy. Watch progress with :Mason, then quit
--      and reopen nvim once it has finished.
--   4. Run :checkhealth to confirm everything is wired up.
--
-- Python interpreter: basedpyright and the debugger use your project virtualenv
-- when you launch nvim from inside an activated venv, or from a project whose
-- root contains a .venv. That is the reliable way to get the right interpreter
-- and your installed packages during debugging.
--
-- Key maps (leader is the space bar):
--   File tree:   <leader>e or <C-n> toggle
--   LSP:         gd definition, gr references, gi implementation, K hover,
--                <leader>rn rename, <leader>ca code action,
--                [d and ]d move between diagnostics
--   Format:      <leader>f (ruff). Format on save is on by default.
--   Debug:       F5 continue or start, F10 step over, F11 step into,
--                F12 step out, <leader>db toggle breakpoint,
--                <leader>du toggle the debug UI, <leader>dt debug test method
-- ============================================================================

-- Leaders must be set before plugins load.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Disable the built in netrw file explorer, since nvim-tree replaces it.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- A small, sensible set of editor options.
local opt = vim.opt
opt.number = true
opt.relativenumber = true
opt.mouse = "a"
opt.termguicolors = true
opt.signcolumn = "yes"
opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.softtabstop = 4
opt.smartindent = true
opt.ignorecase = true
opt.smartcase = true
opt.updatetime = 250
opt.splitright = true
opt.splitbelow = true
opt.scrolloff = 6

-- ---------------------------------------------------------------------------
-- Bootstrap the lazy.nvim plugin manager.
-- ---------------------------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- ---------------------------------------------------------------------------
-- Plugins.
-- ---------------------------------------------------------------------------
require("lazy").setup({
  -- Colour scheme.
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme("tokyonight-moon")
    end,
  },

  -- File tree on the left.
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "<leader>e", "<cmd>NvimTreeToggle<CR>", desc = "Toggle file tree" },
      { "<C-n>", "<cmd>NvimTreeToggle<CR>", desc = "Toggle file tree" },
    },
    config = function()
      require("nvim-tree").setup({
        view = {
          width = 30, -- narrow. Increase this number for a wider tree.
          side = "left",
        },
        renderer = { group_empty = true },
        filters = { dotfiles = false },
      })

      -- Open the tree automatically on start, keeping the cursor in the file.
      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function(data)
          local is_directory = vim.fn.isdirectory(data.file) == 1
          require("nvim-tree.api").tree.open()
          if not is_directory and data.file ~= "" then
            vim.cmd("wincmd p")
          end
        end,
      })
    end,
  },

  -- Mason installs the language tooling and puts it on Neovim's PATH.
  {
    "mason-org/mason.nvim",
    config = function()
      require("mason").setup()
    end,
  },

  -- Auto install the Python tooling (Mason package names).
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "mason-org/mason.nvim" },
    config = function()
      require("mason-tool-installer").setup({
        ensure_installed = { "basedpyright", "ruff", "debugpy" },
      })
    end,
  },

  -- Completion. Pinned to the 1.x line, since 2.0 has breaking changes.
  {
    "saghen/blink.cmp",
    version = "1.*",
    opts = {
      keymap = { preset = "default" },
      appearance = { nerd_font_variant = "mono" },
      sources = { default = { "lsp", "path", "snippets", "buffer" } },
    },
  },

  -- Language servers, using Neovim's built in LSP client.
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "saghen/blink.cmp",
      "mason-org/mason.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",
    },
    config = function()
      -- Tell servers what the completion plugin can do.
      local capabilities = require("blink.cmp").get_lsp_capabilities()
      vim.lsp.config("*", { capabilities = capabilities })

      -- basedpyright: types, hover, navigation. Let ruff own import sorting.
      vim.lsp.config("basedpyright", {
        settings = {
          basedpyright = {
            disableOrganizeImports = true,
            analysis = {
              typeCheckingMode = "standard",
              diagnosticMode = "openFilesOnly",
              autoImportCompletions = true,
            },
          },
        },
      })

      -- ruff: linting and code actions. It can format too, but conform drives
      -- formatting below, so we simply turn off ruff's hover to avoid a
      -- duplicate hover window alongside basedpyright.
      vim.lsp.config("ruff", {})

      vim.lsp.enable({ "basedpyright", "ruff" })

      vim.diagnostic.config({ virtual_text = true, severity_sort = true })

      -- Buffer local keymaps, set when a server attaches.
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(event)
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client.name == "ruff" then
            client.server_capabilities.hoverProvider = false
          end

          local function map(keys, fn, desc)
            vim.keymap.set("n", keys, fn, { buffer = event.buf, desc = "LSP: " .. desc })
          end
          map("gd", vim.lsp.buf.definition, "Go to definition")
          map("gr", vim.lsp.buf.references, "References")
          map("gi", vim.lsp.buf.implementation, "Implementation")
          map("K", vim.lsp.buf.hover, "Hover documentation")
          map("<leader>rn", vim.lsp.buf.rename, "Rename")
          map("<leader>ca", vim.lsp.buf.code_action, "Code action")
          map("[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, "Previous diagnostic")
          map("]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, "Next diagnostic")
        end,
      })
    end,
  },

  -- Formatting with ruff.
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    keys = {
      {
        "<leader>f",
        function()
          require("conform").format({ async = true, lsp_format = "never" })
        end,
        mode = { "n", "v" },
        desc = "Format buffer",
      },
    },
    opts = {
      formatters_by_ft = {
        python = { "ruff_organize_imports", "ruff_format" },
      },
      format_on_save = {
        timeout_ms = 1000,
        lsp_format = "never",
      },
    },
  },

  -- Debugging with nvim-dap, the visual UI, and the Python adapter.
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
      "mfussenegger/nvim-dap-python",
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")
      dapui.setup()

      -- Use the debugpy that Mason installed. nvim-dap-python still runs your
      -- program with the active virtualenv when one is detected.
      local debugpy_python = vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python"
      require("dap-python").setup(debugpy_python)

      -- Open and close the debug UI automatically.
      dap.listeners.before.attach.dapui_config = function() dapui.open() end
      dap.listeners.before.launch.dapui_config = function() dapui.open() end
      dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
      dap.listeners.before.event_exited.dapui_config = function() dapui.close() end

      -- Debugger keymaps. The function keys follow the usual debugger layout.
      vim.keymap.set("n", "<F5>", dap.continue, { desc = "Debug: continue or start" })
      vim.keymap.set("n", "<F10>", dap.step_over, { desc = "Debug: step over" })
      vim.keymap.set("n", "<F11>", dap.step_into, { desc = "Debug: step into" })
      vim.keymap.set("n", "<F12>", dap.step_out, { desc = "Debug: step out" })
      vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Debug: toggle breakpoint" })
      vim.keymap.set("n", "<leader>dB", function()
        dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
      end, { desc = "Debug: conditional breakpoint" })
      vim.keymap.set("n", "<leader>dr", dap.repl.toggle, { desc = "Debug: toggle REPL" })
      vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "Debug: toggle UI" })
      vim.keymap.set("n", "<leader>dt", function()
        require("dap-python").test_method()
      end, { desc = "Debug: test method" })
    end,
  },
})
