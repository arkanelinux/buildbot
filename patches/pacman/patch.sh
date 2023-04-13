#!/usr/bin/env bash
#
# pacman patch script
#

patch $app_directory/pacman.conf < $patch_path/pacman.conf.patch
patch $app_directory/makepkg.conf < $patch_path/makepkg.conf.patch
patch $app_directory/PKGBUILD < $patch_path/PKGBUILD.patch
