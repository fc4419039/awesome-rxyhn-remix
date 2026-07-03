return {
  {
    "stevearc/conform.nvim",
    event = 'BufWritePre',
    opts = require "configs.conform",
  },

  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "vim", "lua", "vimdoc",
        "html", "css", "javascript", "typescript", "tsx",
        "json", "yaml", "markdown", "bash", "python",
        "go", "rust", "java", "c", "cpp", "sql", "toml", "dockerfile",
      },
    },
  },

  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "mason-org/mason.nvim" },
    opts = {
      ensure_installed = {
        "basedpyright", "ts_ls", "jsonls", "yamlls", "marksman",
        "gopls", "rust_analyzer", "jdtls", "clangd",
        "sqlls", "bashls", "dockerls", "taplo",
        "ruff", "prettier", "stylua",
        "shfmt", "rustfmt", "clang-format",
        "eslint_d",
      },
    },
    config = function(_, opts)
      require("mason-tool-installer").setup(opts)
      vim.cmd("MasonToolsInstall")
    end,
  },

  {
    "folke/trouble.nvim",
    cmd = { "Trouble", "TroubleToggle" },
    opts = {
      focus = true,
      modes = {
        diagnostics = { auto_open = true },
      },
    },
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer diagnostics" },
      { "<leader>xl", "<cmd>Trouble loclist toggle<cr>", desc = "Location list" },
      { "<leader>xq", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix list" },
    },
  },

  {
    "windwp/nvim-ts-autotag",
    event = "VeryLazy",
    opts = {},
  },
}
