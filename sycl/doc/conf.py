# Configuration file for the Sphinx documentation builder.
#
# This file only contains a selection of the most common options. For a full
# list see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Path setup --------------------------------------------------------------

# If extensions (or modules to document with autodoc) are in another directory,
# add these directories to sys.path here. If the directory is relative to the
# documentation root, use os.path.abspath to make it absolute, like shown here.
#
# import os
# import sys
# sys.path.insert(0, os.path.abspath('.'))

import datetime
from docutils import nodes

# -- Project information -----------------------------------------------------

now = datetime.datetime.now()

project = 'oneAPI DPC++ Compiler'
copyright = str(now.year) + ', Intel Corporation'
author = 'Intel Corporation'

# -- General configuration ---------------------------------------------------

master_doc = 'index'

# Add any Sphinx extension module names here, as strings. They can be
# extensions coming with Sphinx (named 'sphinx.ext.*') or your custom
# ones.
extensions = [
    'myst_parser'
]

# Implicit targets for cross reference
myst_heading_anchors = 5

# The name of the Pygments (syntax highlighting) style to use.
pygments_style = 'friendly'

# The theme to use for HTML and HTML Help pages.  See the documentation for
# a list of builtin themes.
html_theme = 'haiku'

# The suffix of source filenames.
source_suffix = ['.rst', '.md']

exclude_patterns = [
    # Extensions are mostly in asciidoc which has poor support in Sphinx.
    'extensions/*',
    'design/opencl-extensions/*',
    'design/spirv-extensions/*',

    # Sphinx complains about syntax errors in these files.
    'design/DeviceLibExtensions.rst',
    'design/SYCLPipesLoweringToSPIRV.rst',
    'design/fpga_io_pipes_design.rst',
    'design/Reduction_status.md'
]

suppress_warnings = [ 'misc.highlighting_failure' ]

def on_missing_reference(app, env, node, contnode):
    # Get the directory that contains the *source* file of the link.  These
    # files are always relative to the directory containing "conf.py"
    # (<top>/sycl/doc).  For example, the file "sycl/doc/design/foo.md" will
    # have a directory "design".
    refdoc_components = node['refdoc'].split('/')
    dirs = '/'.join(refdoc_components[:-1])
    if dirs: dirs += '/'

    # A missing reference usually occurs when the target file of the link is
    # not processed by Sphinx.  Compensate by creating a link that goes to the
    # file's location in the GitHub repo.
    new_target = "https://github.com/intel/llvm/tree/sycl/sycl/doc/" + dirs + \
        node['reftarget']

    newnode = nodes.reference('', '', internal=False, refuri=new_target)
    newnode.append(contnode)
    return newnode

def setup(app):
    app.connect('missing-reference', on_missing_reference)
