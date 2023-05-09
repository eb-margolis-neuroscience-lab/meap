# meapr: Multi-Electrode Array Pharmacology R package

This is a set of tools for analyzing multi-electrode electrophysiology
recordings The package has been developed by the O'Meara lab at the University
of Michigan and the Margolis Lab at the University of California, San Francisco.

## To install
###Install pre-requisites

   * `rstan`: Follow the instructions for (RStan getting started)[https://github.com/stan-dev/rstan/wiki/RStan-Getting-Started]
   * To fit models using `brms` using this package a C++ compiler is required.
   The program Rtools (available on
   <https://cran.r-project.org/bin/windows/Rtools/>) comes with a C++ compiler
   for Windows. On Mac, you should install Xcode.
    * To load data from the `Phy` format requires calling python through the
      `reticulate` package. If the python version is not automatically detected,
      it can be specified by setting the following environment variable either
      e.g. in the `~/.bash_profile`, or by using `Sys.setenv(...)`
      
      RETICULATE_PYHTHON=path_to_python
      
      
      

Then from within R

    if (!requireNamespace("remotes")) {
        install.packages("remotes")
    }
    remotes::install_github("eb-margolis-neuroscience-lab/meap/meapr")
    
    

The `meapr` package requires a working C++ compiler. If you have issues
installing on windows due to Rtools errors, follow the
instructions here: https://cran.r-project.org/bin/windows/Rtools/

## Usage

...
