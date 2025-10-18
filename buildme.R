# buildme.R

# set working directory to package root
setwd("/cloud/project")

# Unload your package and uninstall it first.
unloadNamespace("solartool"); remove.packages("solartool")
# Auto-document your package, turning roxygen comments into manuals in the `/man` folder
devtools::document(".")
# Load your package temporarily!
devtools::load_all(".")


# Test functions
solartool::finalrun(0.04, 300, "syracuse_hourly.csv", 43, 30, 0,0,"Sample Data & Generation/sampledata1.csv")

unloadNamespace("solartool")

devtools::document("."); # document the package
unloadNamespace("solartool"); # unload the package

# Build the package
devtools::build(pkg = ".", path = getwd(), binary = FALSE, vignettes = FALSE)

# Restart R
rstudioapi::restartSession()

# Install your package from a local build file
# such as 
# install.packages("nameofyourpackagefile.tar.gz", type = "source")
# or in our case:
install.packages("solartool_1.0.tar.gz", type = "source")

# Load your package!
library("solartool")

# When finished, remember to unload the package
unloadNamespace("solartool"); remove.packages("solartool")

# Always a good idea to clear your environment and cache
rm(list = ls()); gc()
