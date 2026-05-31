require("runtime.bootstrap")
require("runtime.loader")

-- Load core modules
require("core")

-- Setup plugin phases
require("runtime.phases").setup()
require("runtime.lazy").setup()

-- Startup profiler / tracker
require("features.ui.dashboard").track(_G.nvimz_start_time)
