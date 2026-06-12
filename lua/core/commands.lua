local M = {}

-- Create helper commands
function M.setup()
	if vim.g.pack_commands_created then
		return
	end

	vim.g.pack_commands_created = true

	vim.schedule(function()
		vim.api.nvim_create_user_command("PackSync", function()
			require("infra.deps").sync()
		end, { desc = "Fetch and check plugin updates" })

		vim.api.nvim_create_user_command("PackUpdate", function()
			require("infra.deps").update()
		end, { desc = "Apply plugin updates, relock, validate, and report" })

		vim.api.nvim_create_user_command("PackValidate", function()
			require("infra.health").run()
		end, { desc = "Validate runtime integrity and config health" })

		vim.api.nvim_create_user_command("ToolDoctor", function()
			require("infra.health").run_doctor()
		end, { desc = "Show environment tooling health" })

		vim.api.nvim_create_user_command("PackDoctor", function()
			require("infra.report.doctor").run()
		end, { desc = "Run health diagnostics" })

		vim.api.nvim_create_user_command("PackBenchmark", function()
			require("infra.report.benchmark").run()
		end, { desc = "Measure startup and module performance" })

		vim.api.nvim_create_user_command("PackRollback", function()
			require("infra.deps").rollback()
		end, { desc = "Restore plugins from lockfile state" })

		vim.api.nvim_create_user_command("PackStatus", function()
			require("infra.deps").status()
		end, { desc = "Quick overview of package status" })

		vim.api.nvim_create_user_command("PackClean", function()
			require("infra.deps").clean()
		end, { desc = "Remove inactive plugins, stale cache, and old snapshots" })

		vim.api.nvim_create_user_command("PackSnapshot", function()
			require("infra.deps").snapshot()
		end, { desc = "Generate system and state snapshot" })

		vim.api.nvim_create_user_command("PackReport", function()
			require("infra.report.maintenance").run()
		end, { desc = "Regenerate maintenance report" })

		vim.api.nvim_create_user_command("ParsersUpdate", function()
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
						vim.notify("Treesitter parsers updated successfully!", vim.log.levels.INFO)
					else
						vim.notify("Treesitter parser update failed!", vim.log.levels.ERROR)
					end
				end,
			})
		end, {
			desc = "Update Treesitter parsers",
		})
	end)
end

return M
