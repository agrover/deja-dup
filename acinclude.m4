## -*- Mode: m4; indent-tabs-mode: nil; tab-width: 2 -*-
##
## Copyright (C) 2001 Eazel, Inc.
## Author: Maciej Stachowiak <mjs@noisehavoc.org>
##         Kenneth Christiansen <kenneth@gnu.org>
##         Michael Terry <mike@mterry.name>
##
## Déjà Dup is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or
## (at your option) any later version.
##
## Déjà Dup is distributed in the hope that it will be useful, but
## WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
## General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with Déjà Dup.  If not, see <http://www.gnu.org/licenses/>.

## Parts copied/modified from intltool.m4 by Michael Terry

dnl AC_PROG_VALAC([MINIMUM-VERSION])
AC_DEFUN([AC_PROG_VALAC], [

AC_PATH_PROG([VALAC], [valac], [])

USE_VALAC=true

if test -z "$VALAC"; then
  AC_MSG_WARN([Vala compilation is disabled.])
  USE_VALAC=false
elif test -n "$1"; then
    AC_MSG_CHECKING([valac version >= $1])

    VALAC_REQUIRED_VERSION_AS_INT=`echo $1 | awk -F. '{ print $ 1 * 1000 + $ 2 * 100 + $ 3; }'`
    VALAC_APPLIED_VERSION=`$VALAC --version | head -1 | cut -d" " -f2`
    [VALAC_APPLIED_VERSION_AS_INT=`echo $VALAC_APPLIED_VERSION | awk -F. '{ print $ 1 * 1000 + $ 2 * 100 + $ 3; }'`
    ]
    AC_MSG_RESULT([$VALAC_APPLIED_VERSION found])
    if test "$VALAC_APPLIED_VERSION_AS_INT" -lt "$VALAC_REQUIRED_VERSION_AS_INT"; then
        AC_MSG_WARN([Your valac is too old.  You need valac $1 or later.])
        AC_MSG_WARN([Vala compilation is disabled.])
        USE_VALAC=false
    fi
fi

AM_CONDITIONAL([USE_VALAC], [test x$USE_VALAC = xtrue])

])

