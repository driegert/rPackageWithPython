# rPackageWithPython

This package serves as a template for how to create an R package that 
incorporates Python functions.

### Acknowledgements

This package was put together in "collaboration" with Claude 3.5 Sonnet, 
Gemini, and Codestral v0.1. In addition, I use Github Copilot integrated 
into RStudio which was also enabled while writing this package.

Much of the base code was provided by these LLMs and then _heavily_ 
modified to correct any errors and / or generate the behaviour I 
was looking for in the package.

## Changes Needed for a New Package:

- Replace all instances of "rPackageWithPython" with the name of your package.
  - The only location at the moment is in the `DESCRIPTION` file and the 
folder name.
  - I have tried to make all other references to the package name dynamic in 
  the `.onLoad` and `setup_python_env` functions.
- Change the `DESCRIPTION` file to reflect the new package.
- Delete, or replace the contents of, `pyfunc.py` and `r_wrapper.R`.
    - The `.onLoad` function will source all `.py` files that have been 
    properly placed in the `[the package name]/inst/python` directory.
- Change the `setup_python_env` function's `packages` argument to properly reflect the 
Python packages that your `.py` files will use.
    - These should also be added to the `DESCRIPTION` file where numpy and pandas are 
currently listed.
- `setup_python_env` should only need to be called once.
    - All `.py` files will be sourced after the Python virtual environment 
    is setup when this function is called.

### Writing Your Own Wrappers

The first line of your R wrapper functions should call the 
`check_python_env_exists` function. This will ensure that the Python 
virtual environment exists and will throw an error with a 
message if it was not along with a reminder to call the `setup_python_env` 
function.

The method I used for calling the user-defined Python functions was: 
`py$my_python_function()`. This requires that `#' @importFrom reticulate py` 
be added in the documentation section for the function. You can also access 
the reticulate functions directly using: `reticulate::py$my_python_function()` 
if you prefer.

**Note:**  
You do _not_ need to write your own Python scripts. You can simply 
wrap existing Python functions as long as you ensure that the appropriate 
Python packages are imported.

_Not tested / checked_:

I believe that you will still need at least one `.py` file that includes the 
import statements. E.g., to use functions in the numpy and pandas packages, 
you should have a `.py` file in the `inst/python` directory that contains 
just the two lines:

```
import numpy as np
import pandas as pd
```

This `.py` file will be sourced with the result that those Python packages will 
be made available to you while using the package.

## `roxygen2`

I find it easiest to use `roxygen2` for documentation. This will also 
automatically create and update the NAMESPACE file. To ensure that new 
functions are being exported correctly, use `#' @export` above your R 
functions and enable the option:

`Tools > Project Options ... > Build Tools > Generate documentation with Roxygen`

Then also check the box next to: "Install and Restart" under "Automatically 
roxygenize ... " in the "Configure" button at the same location.

## Installation

You can install this package using:

```r
devtools::install_github("driegert/rPackageWithPython")
```

Although why you would actually want to install this package doesn't 
make a lot of sense to me. You should copy all of the contents of the 
`rPackageWithPython` directory and make the changes as indicated above!

## Setup

Before using any functions that require Python, you need to set up the Python 
environment using the `setup_python_env` function.  

The arguments (and defaults) are:

- Virtual environment path: `envpath = "~/.[the package name]_env"`
- Packages to install: `packages = c("numpy", "pandas")`
- Version of Python to use: `python_version = NULL`
    - The default version is based on `reticulate::virtualenv_starter`, 
    followed by `python3` (whichever version is pointed to), and finally 
    `python` (whichever version is pointed to).
    - After calling `setup_python_env`, you can check the version of Python 
    using `check_python_env_exists(TRUE)`.

```r
library(rPackageWithPython)

# Use system default Python
setup_python_env()
```

This will create a virtual environment and install the required Python packages 
as set in the `setup_python_env` function's `packages` argument..

### Notes

You can, if you want, start the Python virtual setup process automatically 
if it does not already exist when the package is loaded. You would 
need to modify the `.onLoad` function in the `zzz.R` file. You would 
end up moving much of the contents of the `setup_python_env` function from 
the `setup_python.R` file.

I decided not to do this so that the user is not _forced_ into setting up 
the environment. They can also set an existing environment and use 
the `setup_python_env` function to set the environment as the one to be used 
and install additional Python packages if required.

## Usage

For this particular package, `rPackageWithPython`, the following should work:

```r
library(rPackageWithPython)
result <- py_add_wrapper(2, 3)
print(result)  # Should output 5
```

Note: Make sure to run `setup_python_env()` before using any functions that 
rely on Python.

# ToDo

- Double check that R variables are properly "translated" to Python 
when the Python function is called.
    - I know that there is the `reticulate::r_to_py` function, but did not 
    implement it here.
    - I don't believe that this is necessary.
- Also check that Python variables are properly "translated" to R.
    - I know that there is the `reticulate::py_to_r` function, but did not
    implement it here.
    - I don't believe that this is necessary.

