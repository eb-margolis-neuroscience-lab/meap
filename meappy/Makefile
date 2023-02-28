############################################
# Makefile for building the MEAPPY package #
############################################

# make all commands in a target use the same shell
.ONESHELL:


install:
	pip install -e .
	
test:
	pytest .
	
all: install	
	
.PHONY: all install test