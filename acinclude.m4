# -*- Mode: m4; indent-tabs-mode: nil; tab-width: 2 -*-
#
# Copyright (C) 2008, 2009 Free Software Foundation, Inc.
#
# This file is free software; the Free Software Foundation
# gives unlimited permission to copy and/or distribute it,
# with or without modifications, as long as this notice is preserved.

# serial 4

# Check whether the Vala compiler exists in `PATH'. If it is found, the
# variable VALAC is set. Optionally a minimum release number of the
# compiler can be requested.
#
# DEJA_PROG_VALAC([MINIMUM-VERSION])
# --------------------------------
AC_DEFUN([DD_PROG_VALAC],
[AC_PATH_PROGS([VALAC], [$2], [])
 AS_IF([test -z "$VALAC"],
   [AC_MSG_ERROR([No Vala compiler found.])],
   [AS_IF([test -n "$1"],
      [AC_MSG_CHECKING([$VALAC is at least version $1])
       am__vala_version=`$VALAC --version | sed 's/Vala  *//'`
       AS_VERSION_COMPARE([$1], ["$am__vala_version"],
         [AC_MSG_RESULT([yes])],
         [AC_MSG_RESULT([yes])],
         [AC_MSG_RESULT([no])
          AC_MSG_ERROR([Vala $1 not found.])])])])
])
