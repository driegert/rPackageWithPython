.onLoad <- function(libname, pkgname) {
  # Source the python file
  tryCatch({
    config_dir <- tools::R_user_dir(pkgname, which = "config")
    config_file <- file.path(config_dir, "settings.rds")

    # check if the settings.rds file exists
    if (file.exists(config_file)) {
      message("Loading settings from previous session...")
      settings <- readRDS(config_file)

      envpath <- settings$envpath
      python_version <- settings$python_version
      packages <- settings$packages
    } else {
      envpath <- NULL
      python_version <- NULL
      packages <- NULL
    }

    if (is.null(envpath) || !fs::dir_exists(envpath)) {
      message("Python environment not found. Please run setup_python_env() to set it up.")
      return(invisible(NULL))
    }

    reticulate::use_virtualenv(envpath, required = TRUE)
    ## Not needed if using use_virtualenv (I think, anyway... )
    # reticulate::use_python(Sys.which("python3"), required = TRUE)

    python_version <- reticulate::py_config()$version
    packageStartupMessage("Using Python version: ", python_version)

    python_script_path <- paste0(system.file(package = pkgname), "/python")
    python_script_files <- fs::dir_ls(python_script_path, glob = "*.py")

    if (length(python_script_path) > 0) {
      sapply(python_script_files, reticulate::source_python)
    } else {
      warning("No .py files found in : ", python_script_path)
    }
  }, error = function(e) {
    packageStartupMessage("Error sourcing Python script: ", e$message)
    packageStartupMessage("Python config: ", reticulate::py_config())
    print(reticulate::py_config())
    stop(e)
  })

  # Save the virtual environment path and Python version as options
  # allows setting an option with dynamically generated name
  set_dynamic_option <- function(..., value) {
    option_name <- paste0(...)
    do.call(options, setNames(list(value), option_name))
  }

  # config variables for use during this R session
  set_dynamic_option(pkgname, ".python_env", value = envpath)
  set_dynamic_option(pkgname, ".python_version",
                     value = reticulate::py_config()$version)
  set_dynamic_option(pkgname, ".python_packages", value = packages)
  set_dynamic_option(pkgname, ".python_script_path", value = python_script_path)
}

#' Check if Python environment exists
#'
#' This function checks if the Python environment has been set up for the package.
#'
#' @param print_pkgname Logical. If TRUE, print the package name and
#' Python environment path. This can be used as a diagnostic to ensure that
#' the correct package name is being used.
#'
#' @export
check_python_env_exists <- function(print_pkgname = FALSE){
  pkgname <- environmentName(environment(check_python_env_exists))
  envpath <- getOption(paste0(pkgname, ".python_env"))

  if (print_pkgname) {
    message("Package name: ", pkgname)
    message("Python environment path: ", envpath)
  }

  if (is.null(envpath) || !fs::dir_exists(envpath)) {
    stop("Python environment not set up. Please run setup_python_env() first.")
  }
}
