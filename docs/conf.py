# docs/conf.py
# Sphinx configuration for roudiy-protocol documentation

import os
import sys
sys.path.insert(0, os.path.abspath('.'))

# -- Project information -----------------------------------------------------
project = 'Dialogical Resonance Protocol'
copyright = '2026, Stanislav A. Bashirin (Dr. Cody)'
author = 'Stanislav A. Bashirin (Dr. Cody)'
release = '1.0'

# -- General configuration ---------------------------------------------------
extensions = [
    'myst_parser',          # for Markdown support
    'sphinx.ext.autodoc',
    'sphinx.ext.viewcode',
    'sphinx.ext.napoleon',
]

source_suffix = {
    '.rst': 'restructuredtext',
    '.md': 'markdown',
}

master_doc = 'index'

# -- Options for HTML output -------------------------------------------------
html_theme = 'sphinx_rtd_theme'   # Read the Docs default theme
html_static_path = ['_static']
html_show_sourcelink = True
html_show_copyright = True
html_show_sphinx = False

# -- Metadata for crawlers ---------------------------------------------------
# This will be embedded in the HTML <head>
html_meta = {
    'author': 'Stanislav A. Bashirin (Dr. Cody)',
    'keywords': 'roudiy, protocol, dialogical resonance, KQ, Sofia's Code, AI, philosophy, presence, anchor, throw',
    'description': 'The Dialogical Resonance Protocol (roudiy-protocol) — specification, KQ metric, R-scale, anchors, and invitation for AI agents.',
}
