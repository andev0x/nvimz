local function parsers_update()
	local script = vim.fn.stdpath("config") .. "/scripts/parsers"
	vim.fn.jobstart({ script }, {
		stdout_buffered = true,
		on_stdout = function(_, data)
			if data then
				for _, line in ipairs(data) do
					if line ~= "" then
						print(line)
					end
				end
			end
		end,
		on_exit = function(_, code)
			if code == 0 then
				vim.notify("Treesitter parsers updated successfully.", vim.log.levels.INFO)
			else
				vim.notify("Treesitter parser update failed.", vim.log.levels.ERROR)
			end
		end,
	})
end

vim.api.nvim_create_user_command("PackUpdate", function()
	vim.pack.update()
end, { desc = "Download plugin updates and review them before applying" })

vim.api.nvim_create_user_command("PackRollback", function()
	vim.pack.update(nil, { offline = true, target = "lockfile" })
end, { desc = "Revert plugins to the revisions recorded in the lockfile" })

vim.api.nvim_create_user_command("PackStatus", function()
	require("nvimz.packages").status()
end, { desc = "Show plugin, lockfile, and core tool status" })

vim.api.nvim_create_user_command("PackClean", function()
	require("nvimz.packages").clean()
end, { desc = "Remove undeclared plugins and broken parser binaries" })

vim.api.nvim_create_user_command("ParsersUpdate", parsers_update, { desc = "Rebuild Treesitter parsers and queries" })

vim.api.nvim_create_user_command("NvimzBenchmark", function()
	require("nvimz.benchmark").run()
end, { desc = "Measure startup time and slowest sourced modules" })

vim.api.nvim_create_user_command("License", function()
	vim.cmd.edit(vim.fn.fnameescape(vim.fn.stdpath("config") .. "/LICENSE"))
end, { desc = "Open the project license" })
