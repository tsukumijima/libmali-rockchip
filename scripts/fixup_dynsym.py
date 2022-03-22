#!/usr/bin/env python3
import lief
import sys

libpath = sys.argv[1]
lib = lief.parse(libpath)

# HACK: increase .dynsym's sh_info to workaround local symbol warning:
# 'found local symbol in global part of symbol table'
lib.get_section('.dynsym').information = 10

lib.write(libpath)
