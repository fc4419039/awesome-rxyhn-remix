require("nvchad.configs.lspconfig").defaults()

local servers = {
  "basedpyright",
  "ts_ls",
  "jsonls",
  "yamlls",
  "marksman",
  "gopls",
  "rust_analyzer",
  "jdtls",
  "clangd",
  "sqlls",
  "bashls",
  "dockerls",
  "taplo",
  "html",
  "cssls",
}
vim.lsp.enable(servers)

vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 4
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "go", "rust" },
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 4
  end,
}) 
