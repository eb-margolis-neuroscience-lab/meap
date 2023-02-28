##########################################
# Makefile for building the MEAP package #
##########################################

# make all commands in a target use the same shell
.ONESHELL:

build_meapr:
	$(MAKE) -C meapr build
	
install_meapr:
	$(MAKE) -C meapr install



