#!/usr/bin/env bash

# smallest x86 ELF executable on linux
# tested on kernel 6.1.0-13-amd64, debian 12.2.
#
# this work exploits the permissive implementation of the kernel's parser/loader
# to embed code/data into the unused bytes in the file, and to reduce the file
# size by truncating some unused fields.
#
# smallest you can achieve is 76 bytes with 36 bytes you can modify on systems
# with the common 4KiB page size.
#
# following is the layout of the executable. the non-hexadecimal values are the
# unused bytes you can modify.
#
# hex="\            #
# 7f454c46\         #
# 01\               #
# 01\               #
# 01\               #
# 00\               #
# pppppppppppppppp\ # our entrypoint.
# 0200\             #
# 0300\             #
# 01vvvvvv\         #
# 0800rrrr\         #
# 34000000\         # -=S
# oooooooo\         #
# llllllll\         #
# 3400\             # -=S
# 2000\             #
# 0100\             # | you can remove these 8 bytes because the following 8
# ssss\             # | bytes coincide to satisfy e_phnum=0x0001 and
# 0000\             # | e_shnum=0x0000, adjust other fields by S=remove?8:0.
# iiii\             # |
# 01000000\         #
# 00000000\         #
# 0000rrrr\         # must be a multiple of the page size.
# PPPPPPPP\         #
# 54000000\         # -=S
# mmmmmmmm\         # >= 0x54-S
# 07LLLLLL\         # +W to use p_memsz otherwise SEGVs during zero fill init
# 00100000\         # page size.
# "                 #
#
# interesting remark is that when e_shoff is non-zero despite the absence of
# section headers, objdump, readelf and GDB fails at parsing the executable,
# while the kernel happily parses and loads the executable. they seem to be
# stricter with the file format than the kernel.
#
# reference:
# https://man7.org/linux/man-pages/man5/elf.5.html
# https://github.com/torvalds/linux/blob/master/fs/binfmt_elf.c
#
# some of the hacks in this work are based on:
# https://nathanotterness.com/2021/10/tiny_elf_modernized.html

hex="\
7f454c46\
01\
01\
01\
00\
b93600676143eb10\
0200\
0300\
01676179\
08006761\
2c000000\
b206b004\
cd80eb18\
2c00\
2000\
01000000\
00000000\
00006761\
79736578\
4c000000\
b001cd80\
07736578\
00100000\
"

# convert from hex strings to binary and run.
echo -n $hex | xxd -p -r > a.out && chmod +x a.out && ./a.out
