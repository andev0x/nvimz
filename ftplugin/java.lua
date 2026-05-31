vim.cmd("packadd nvim-jdtls")

local ok, jdtls = pcall(require, "jdtls")
if not ok then
  return
end

local root_markers = {
  ".git",
  "mvnw",
  "gradlew",
  "pom.xml",
  "build.gradle",
}

local root_dir = require("jdtls.setup").find_root(root_markers)

if not root_dir then
  return
end

local home = os.getenv("HOME")

local project_name =
  vim.fn.fnamemodify(root_dir, ":p:h:t")

local workspace_dir =
  home .. "/.cache/jdtls/" .. project_name

jdtls.start_or_attach({
  cmd = {
    "jdtls",
    "-data",
    workspace_dir,
  },

  root_dir = root_dir,

  settings = {
    java = {
      eclipse = {
        downloadSources = true,
      },

      configuration = {
        updateBuildConfiguration = "interactive",
      },

      maven = {
        downloadSources = true,
      },

      implementationsCodeLens = {
        enabled = true,
      },

      referencesCodeLens = {
        enabled = true,
      },

      references = {
        includeDecompiledSources = true,
      },

      format = {
        enabled = true,
      },
    },
  },

  init_options = {
    bundles = {},
  },
})
