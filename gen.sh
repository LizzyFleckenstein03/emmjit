#!/bin/sh
set -e
lua gen.lua
cc const.c -o const
./const > const.asm
rm const
