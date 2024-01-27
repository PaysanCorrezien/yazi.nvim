-- store all git repositories visited in this session
local yazi_visited_git_repos = {}

local fn = vim.fn

-- TODO:check if the repo isa git repo
local function append_git_repo_path(repo_path)
	if repo_path == nil or not fn.isdirectory(repo_path) then
		return
	end

	for _, path in ipairs(yazi_visited_git_repos) do
		if path == repo_path then
			return
		end
	end

	table.insert(yazi_visited_git_repos, tostring(repo_path))
end

--- Strip leading and lagging whitespace
local function trim(str)
	return str:gsub("^%s+", ""):gsub("%s+$", "")
end

local function get_root(cwd)
	local status, job = pcall(require, "plenary.job")
	if not status then
		return fn.system("git rev-parse --show-toplevel")
	end

	local gitroot_job = job:new({
		"git",
		"rev-parse",
		"--show-toplevel",
		cwd = cwd,
	})

	local path, code = gitroot_job:sync()
	if code ~= 0 then
		return nil
	end

	return table.concat(path, "")
end

--- Get project_root_dir for git repository
local function project_root_dir()
	-- Save the current shell
	local oldshell = vim.o.shell

	-- Use bash on Unix based systems, keep the default shell on Windows
	if vim.fn.has("unix") == 1 then
		vim.o.shell = "bash"
	end

	local cwd = vim.loop.cwd()
	local root = get_root(cwd)
	if root == nil then
		vim.o.shell = oldshell -- Revert to old shell
		return nil
	end

	local cmd = string.format(
		'cd "%s" && git rev-parse --show-toplevel',
		fn.fnamemodify(fn.resolve(fn.expand("%:p")), ":h"),
		root
	)
	-- Execute the command
	local gitdir = fn.system(cmd)
	local isgitdir = fn.matchstr(gitdir, "^fatal:.*") == ""

	-- Revert to old shell
	vim.o.shell = oldshell

	if isgitdir then
		append_git_repo_path(gitdir)
		return trim(gitdir)
	end

	local repo_path = fn.getcwd(0, 0)
	append_git_repo_path(repo_path)

	-- Just return the current working directory
	return repo_path
end

--- Check if Yazi is available
local function is_yazi_available()
	return fn.executable("yazi") == 1
end

local function is_symlink()
	local resolved = fn.resolve(fn.expand("%:p"))
	return resolved ~= fn.expand("%:p")
end

return {
	get_root = get_root,
	project_root_dir = project_root_dir,
	yazi_visited_git_repos = yazi_visited_git_repos,
	is_yazi_available = is_yazi_available,
	is_symlink = is_symlink,
}
