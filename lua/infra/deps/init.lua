local M = {}

--- Dependency orchestration entrypoint.
--- This module provides a unified interface to various dependency management tasks.

function M.sync()
	require("infra.deps.sync").run()
end

function M.update()
	require("infra.deps.update").run()
end

function M.clean()
	require("infra.deps.clean").run()
end

function M.status()
	require("infra.deps.status").run()
end

function M.rollback()
	require("infra.deps.rollback").run()
end

function M.snapshot()
	require("infra.deps.snapshot").run()
end

return M
