#!/usr/bin/env python3
import lief
import sys

libpath = sys.argv[1]
lib = lief.parse(libpath)

symbols = ["__bss_end__", "__bss_start", "_end", "_edata", "__bss_start__", "_bss_end__", "__end__"]
for symbol in symbols:
  hidden = lib.get_symbol(symbol)
  if hidden:
    hidden.binding = lief.ELF.SYMBOL_BINDINGS.GLOBAL
    hidden.visibility = lief.ELF.SYMBOL_VISIBILITY.DEFAULT
    hidden = lib.add_dynamic_symbol(hidden)

# HACK: increase .dynsym's sh_info to workaround local symbol warning:
# 'found local symbol in global part of symbol table'
lib.get_section('.dynsym').information = 10

lib.write(libpath)
