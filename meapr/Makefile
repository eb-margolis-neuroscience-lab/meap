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
  
all: install


.PHONY: all build install