#!/bin/sh
set -e
FLAG=-g
nasm $FLAG main.asm -f elf64 -o emmjit.o
ld $FLAG emmjit.o -o emmjit
rm emmjit.o
