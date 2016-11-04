## ********************************************************************* ##
## Copyright 2016                                                        ##
## David Farmer, Greg Hartman, Alex Jordan, Carly Vollet                 ##
##                                                                       ##
## This file is part of APEX Calculus                                    ##
##                                                                       ##
## ********************************************************************* ##

#######################
# DO NOT EDIT THIS FILE
#######################

#   1) Make a copy of Makefile.paths.original
#      as Makefile.paths, which git will ignore.
#   2) Edit Makefile.paths to provide full paths to the root folders 
#      of your local clones of the project repository and the mathbook
#      repository as described below.
#   3) The files Makefile and Makefile.paths.original
#      are managed by git revision control and any edits you make to 
#      these will conflict. You should only be editing Makefile.paths.

##############
# Introduction
##############

# This is not a "true" makefile, since it does not
# operate on dependencies.  It is more of a shell
# script, sharing common configurations

######################
# System Prerequisites
######################

#   install         (system tool to make directories)
#   xsltproc        (xml/xsl text processor)
#   xmllint         (only to check source against DTD)
#   <helpers>       (PDF viewer, web browser, pager, Sage executable, etc)

#####
# Use
#####

#	A) Navigate to the location of this file
#	B) At command line:  make <some-target-from-the-options-below>

# The included file contains customized versions
# of locations of the principal components of this
# project and names of various helper executables
include Makefile.paths

# These paths are subdirectories of
# the project distribution
PRJSRC    = $(PRJ)/src
OUTPUT    = $(PRJ)/output
STYLE     = $(PRJ)/style

# The project's main hub file
MAINFILE  = $(PRJSRC)/index.mbx

# The project's styling files
CSS       = $(STYLE)/css/apex.css

# These paths are subdirectories of
# the Mathbook XML distribution
# MBUSR is where extension files get copied
# so relative paths work properly
MBXSL = $(MB)/xsl
MBUSR = $(MB)/user
DTD   = $(MB)/schema/dtd

# These paths are subdirectories of
# the scratch directory
PGOUT      = $(OUTPUT)/pg
HTMLOUT    = $(OUTPUT)/html
PDFOUT     = $(OUTPUT)/pdf
IMAGESOUT  = $(OUTPUT)/images

# Some aspects of producing these examples require a WeBWorK server.
# For all but trivial testing or examples, please look into setting
# up your own WeBWorK server, or consult Alex Jordan about the use
# of PCC's server in a nontrivial capacity.    <alex.jordan@pcc.edu>
SERVER = https://webwork.pcc.edu

#  Write out each WW problem as a standalone problem in PGML ready 
#  for use on a WW server.  "def" files and "header" files are 
#  produced. Directories and filenames are derived from titles of 
#  chapters, sections, etc., in addition to the titles of the 
#  problems themselves.
#
#  Results land in the subdirectory:  $(PGOUT)/local
#
pg:
	install -d $(PGOUT)
	cd $(PGOUT); \
	xsltproc -xinclude --stringparam chunk.level 2 $(MBXSL)/mathbook-webwork-archive.xsl $(MAINFILE)

#  HTML output 
#  Output lands in the subdirectory:  $(HTMLOUT)
html:
	install -d $(HTMLOUT)
	-rm $(HTMLOUT)/*.html
	-rm $(HTMLOUT)/knowl/*.html
	cp -a $(IMAGESOUT) $(HTMLOUT)
	cd $(HTMLOUT); \
	xsltproc -xinclude --stringparam webwork.server $(SERVER) --stringparam html.knowl.exercise.inline no --stringparam html.knowl.example no $(MBXSL)/mathbook-html.xsl $(MAINFILE)

# make all the image files in svg format
images:
	install -d $(IMAGESOUT)
	-rm $(IMAGESOUT)/*.svg
	$(MB)/script/mbx -c latex-image -f svg -d $(IMAGESOUT) $(MAINFILE)
#	$(MB)/script/mbx -c asymptote -f svg -d $(IMAGESOUT) $(MAINFILE)

# make all the image files in pdf format
pdfimages:
	install -d $(IMAGESOUT)
	-rm $(IMAGESOUT)/*.pdf
	$(MB)/script/mbx -c latex-image -f pdf -d $(IMAGESOUT) $(MAINFILE)

# for pdf output, a one-time prerequisite for LaTeX conversion of
# problems living on a server, and image construction at server
# our "webwork-tex" is a subdirectory of where the PDF is compiled
# -s specifies an existing WW server to use (ignore security warnings)
webwork-server-tex:
	install -d $(PDFOUT)/webwork-tex
	$(MB)/script/mbx -v -c webwork-tex -s $(SERVER) -d $(PDFOUT)/webwork-tex $(MAINFILE)

# LaTeX for print
# see prerequisite just above
# the "webwork-tex" directory must be given here
# [note trailing slash (subject to change)]
latex:
	install -d $(PDFOUT)
	-rm $(PDFOUT)/*.tex
	cd $(PDFOUT); \
	xsltproc -xinclude --stringparam webwork.server.latex $(PDFOUT)/webwork-tex/ $(MBXSL)/mathbook-latex.xsl $(MAINFILE) \

# PDF for print
# see prerequisite just above
# the "webwork-tex" directory must be given here
# [note trailing slash (subject to change)]
pdf:
	install -d $(PDFOUT)
	-rm $(PDFOUT)/*.tex
	cd $(PDFOUT); \
	xsltproc -xinclude --stringparam webwork.server.latex $(PDFOUT)/webwork-tex/ $(MBXSL)/mathbook-latex.xsl $(MAINFILE); \
	xelatex book-1.tex; \
	xelatex book-1.tex

###########
# Utilities
###########

# Verify Source integrity
#   Leaves "dtderrors.txt" in OUTPUT
#   can then grep on, e.g.
#     "element XXX:"
#     "does not follow"
#     "Element XXXX content does not follow"
#     "No declaration for"
#   Automatically invokes the "less" pager, could configure as $(PAGER)
check:
	install -d $(OUTPUT)
	-rm $(OUTPUT)/dtderrors.*
	-xmllint --xinclude --postvalid --noout --dtdvalid $(DTD)/mathbook.dtd $(MAINFILE) 2> $(OUTPUT)/dtderrors.txt
	less $(OUTPUT)/dtderrors.txt
