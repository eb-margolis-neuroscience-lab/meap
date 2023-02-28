##########################################
# Makefile for building the MEAP package #
##########################################

# make all commands in a target use the same shell
.ONESHELL:


# expose top-level targets from MEAPR
build_meapr:
	$(MAKE) -C meapr build
	
install_meapr:
	$(MAKE) -C meapr install


# expose top-level targets from MEAPPY
install_meappy:
	$(MAKE) -C meappy install


all: install_meapr

.PHONY: all build_meapr install_meapr