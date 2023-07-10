###########################################
# Makefile for building the MEAPR package #
###########################################

# make all commands in a target use the same shell
.ONESHELL:

build:
	Rscript -e "devtools::document()"
  Rscript -e "devtools::build()"

install:
	Rscript -e "devtools::install_local('.', force = TRUE)"


test_more:
	Rscript -e "devtools::check()"
	Rscript -e "covr::covr()"
	Rscript -e "lintr::lint_package()"
	Rscript -e "urlchecker::url_check()"
	Rscript -e "docreview::package_review()"
	Rscript -e "spelling::spell_check_package()"

all: install


.PHONY: all build install test_more