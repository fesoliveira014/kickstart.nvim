local myAutoCommands = vim.api.nvim_create_augroup('myAutoCommands', { clear = true })

local function determine_c3_root()
  -- Try project.json
  local pr_json = vim.fs.root(0, 'project.json')
  if pr_json ~= nil then return pr_json end
  -- Try git root
  local git_root = vim.fs.root(0, '.git')
  if git_root ~= nil then return git_root end
  -- Nothing found, assume standalone C3 file
  return vim.fn.getcwd()
end

local function get_c3_std_lib_path()
  -- Query c3c for its installation directory
  local handle = io.popen 'c3c --version 2>&1'
  if not handle then return end

  local result = handle:read '*a'
  local success, _, _ = handle:close()

  if not success then return end

  local c3_dir = result:match 'Installed directory: %s*(.-)\n'
  if not c3_dir then return end

  -- Assume that the standard library lives in same directory
  -- as c3c installation directory
  return c3_dir .. '/lib/'
end

vim.api.nvim_create_autocmd({ 'FileType' }, {
  group = myAutoCommands,
  pattern = { 'c3', 'c3i' },
  callback = function()
    vim.lsp.start {
      name = 'c3_lsp',
      cmd = {
        os.getenv 'HOME' .. '/opt/c3-lsp/server/bin/c3lsp',
        '--stdlib-path',
        get_c3_std_lib_path(),
        '--diagnostics-delay',
        200,
      },
      root_dir = determine_c3_root(),
    }
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'c3',
  callback = function() vim.treesitter.start(0, 'c3') end,
})
