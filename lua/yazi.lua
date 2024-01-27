-- local cmd = string.format('yazi --file-chooser --output-file %s %s', output_path, current_directory)

local open_floating_window = require("yazi.window").open_floating_window
local project_root_dir = require("yazi.utils").project_root_dir
local is_yazi_available = require("yazi.utils").is_yazi_available

YAZI_BUFFER = nil
YAZI_LOADED = false
vim.g.yazi_opened = 0
local prev_win = -1
local win = -1
local buffer = -1

local output_path = vim.fn.stdpath("data") .. "\\yazi_filechosen"

local function file_exists(name)
	local f = io.open(name, "r")
	if f ~= nil then
		io.close(f)
		return true
	else
		return false
	end
end

local function on_exit(job_id, code, event)
	if code ~= 0 then
		print("Yazi exited with code: " .. code)
		return
	end

	YAZI_BUFFER = nil
	YAZI_LOADED = false
	vim.g.yazi_opened = 0
	vim.cmd("silent! :checktime")

	if vim.api.nvim_win_is_valid(win) then
		vim.api.nvim_win_close(win, true)

		if code == 0 and file_exists(output_path) then
			local file_lines = vim.fn.readfile(output_path)
			local chosen_file = file_lines and file_lines[1]

			if chosen_file and chosen_file ~= "" then
				vim.cmd(string.format("edit %s", vim.fn.fnameescape(chosen_file)))

				coroutine.wrap(function()
					if vim.api.nvim_buf_is_valid(buffer) and vim.api.nvim_buf_is_loaded(buffer) then
						vim.api.nvim_buf_delete(buffer, { force = true })
					end
				end)()
			else
				print("File chosen is empty or invalid.")
			end
		else
			print("Exit code is not 0 or output file does not exist")
		end

		buffer = -1
		win = -1
	else
		print("Window is not valid at the time of closing.")
	end
end

--- Call yazi
local function exec_yazi_command(cmd)
	-- print(cmd)
	if YAZI_LOADED == false then
		-- ensure that the buffer is closed on exit
		vim.g.yazi_opened = 1
		-- vim.fn.termopen({ on_exit = on_exit })
		-- vim.fn.termopen(cmd, { on_exit = on_exit })
		vim.fn.termopen(cmd, { on_exit = on_exit })
	end
	vim.cmd("startinsert")
end

--- :Yazi entry point
local function yazi(path)
	if is_yazi_available() ~= true then
		print("Please install yazi. Check documentation for more information")
		return
	end

	prev_win = vim.api.nvim_get_current_win()
	path = vim.fn.expand("%:p:h")

	win, buffer = open_floating_window()

	_ = project_root_dir()

	-- if path == nil then
	-- 	if is_symlink() then
	-- 		path = project_root_dir()
	-- 	else
	-- 	end
	-- end

	-- TODO: do this better to not wait io
	os.remove(output_path)
	local cmd = string.format('yazi "%s" --chooser-file "%s"', path, output_path)

	exec_yazi_command(cmd)
end

return {
	yazi = yazi,
}
