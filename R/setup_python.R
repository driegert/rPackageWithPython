#' Set up Python Environment
#'
#' This function sets up a Python virtual environment for the package,
#' installs required packages, and configures reticulate to use this environment.
#'
#' @param envpath Path where the virtual environment should be created
#' @param packages Character vector of Python packages to install
#' @param python_version The Python version to use. If NULL, uses the
#' system's default Python.
#'
#' @export
setup_python_env <- function(envpath = NULL,
                             packages = c("numpy", "pandas"),
                             python_version = NULL) {

  pkgname <- environmentName(environment(setup_python_env))
  if (is.null(envpath)){
    envpath <- file.path("~", paste0(".", pkgname, "_env"))
  }

  # Find the settings directory for the package
  config_dir <- tools::R_user_dir(pkgname, which = "config")
  config_file <- file.path(config_dir, "settings.rds")

  # check if the settings.rds file exists
  if (file.exists(config_file)) {
    message("Loading settings from previous session...")
    settings <- readRDS(config_file)

    # Check if the environment path has changed
    if (settings$envpath != envpath) {
      packageStartupMessage("The environment path has changed from the last session.")
      packageStartupMessage(paste0("Stored path: ", settings$envpath))
      replace_envpath <- readline(
        prompt = paste0("Use the new path (", envpath, ")? [y/n]: ")
      )
    }
    if (exists("replace_envpath") && tolower(replace_envpath) == "n") {
      envpath <- settings$envpath
    }
    # Check if the package list has changed
    if (!(all(packages %in% settings$packages) &
          all(settings$packages %in% packages))){
      packageStartupMessage("The package list has changed from previous setup.")
      packageStartupMessage("New packages will be installed.")
      packages <- union(settings$packages, packages) |> union()
    }
    # Check if the Python version has changed
    if (is.null(python_version)){
      python_version == settings$python_version
    } else if (!is.null(settings$python_version) &&
               python_version != settings$python_version) {
      packageStartupMessage("The Python version has changed from previous setup.")
      replace_python_version <- readline(
        prompt = paste0("Replace existing version (", settings$python_version,
                        ") with new version (", python_version, ")? [y/n]: "))
      if (tolower(replace_python_version) == "n") {
        python_version <- settings$python_version
      }
    }
  }

  if (!fs::dir_exists(envpath)) {
    message("Creating Python virtual environment...")

    # If python_version is NULL, use the system's default Python
    if (is.null(python_version)) {
      python_path <- reticulate::virtualenv_starter(python_version)
      if (python_path == ""){
        python_path <- Sys.which("python3")
      }
      if (python_path == "") {
        python_path <- Sys.which("python")
      }
      if (python_path == "") {
        stop("No Python installation found. Please install Python and try again.")
      }
    } else {
      python_path <- python_version
    }

    tryCatch({
      reticulate::virtualenv_create(envpath, python = python_path)
    }, error = function(e) {
      stop("Failed to create virtual environment. Error: ", e$message)
    })
  }

  reticulate::use_virtualenv(envpath, required = TRUE)

  # Install any required Python packages
  message("Installing required Python packages...")
  reticulate::py_install(packages, envname = envpath)

  # allows setting an option with dynamically generated name
  set_dynamic_option <- function(..., value) {
    option_name <- paste0(...)
    do.call(options, setNames(list(value), option_name))
  }

  # config variables for use during this R session
  set_dynamic_option(pkgname, ".python_env", value = envpath)
  set_dynamic_option(pkgname, ".python_version", value = reticulate::py_version())
  set_dynamic_option(pkgname, ".python_packages", value = packages)

  # Save the settings used to a file; loaded in the .onLoad function
  settings <- list(envpath = envpath, packages = packages,
                   python_version = reticulate::py_version())

  # create the directory if it doesn't exist
  if (!fs::dir_exists(config_dir)) {
    fs::dir_create(config_dir)
  }
  saveRDS(settings, file = config_file)

  # source any Python scripts in the package
  python_script_path <- paste0(system.file(package = pkgname), "/python")
  python_script_files <- fs::dir_ls(python_script_path, glob = "*.py")

  if (length(python_script_path) > 0) {
    sapply(python_script_files, reticulate::source_python)
  } else {
    warning("No .py files found in : ", python_script_path)
  }

  # Print Python configuration for debugging
  message("Python configuration:")
  print(reticulate::py_config())

  message("Python environment setup complete and settings saved.")
}
