# -*- Mode: m4; indent-tabs-mode: nil; tab-width: 2 -*-
#
# This file is part of Déjà Dup.
# © 2008,2009,2010 Michael Terry <mike@mterry.name>,
# © 2009 Andrew Fister <temposs@gmail.com>
#
# Déjà Dup is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# Déjà Dup is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Déjà Dup.  If not, see <http://www.gnu.org/licenses/>.

# Sets up autoconf.
AC_INIT([Déjà Dup],[14.0.1],[https://bugs.launchpad.net/deja-dup/+filebug],[deja-dup], [https://launchpad.net/deja-dup])
AC_PREREQ(2.64)
AC_CONFIG_SRCDIR(deja-dup/main.vala)
AC_CONFIG_HEADERS([config.h:config.h.in])
AC_CONFIG_MACRO_DIR([m4])

# Sets up automake.
AM_INIT_AUTOMAKE([1.10 foreign dist-bzip2])
m4_ifdef([AM_SILENT_RULES],[AM_SILENT_RULES([yes])])

GNOME_DOC_INIT

# Checks for programs.
AC_PROG_CC
AC_PROG_INSTALL
AC_PROG_MAKE_SET

LT_PREREQ([2.2.6])
LT_INIT

AC_PATH_PROG(GCONFTOOL, gconftool-2)
AM_GCONF_SOURCE_2

AC_PATH_PROG(PO4A, po4a)

# Checks for vala
AC_PROG_VALAC([0.7.10])

# Sets up gettext.
GETTEXT_PACKAGE="$PACKAGE"
AC_SUBST(GETTEXT_PACKAGE)
AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE, "$GETTEXT_PACKAGE", [gettext domain])
AM_GNU_GETTEXT([external])
AM_GNU_GETTEXT_VERSION([0.17])
IT_PROG_INTLTOOL([0.40])

# Sets up a few prefix-relative directories
if test "x${prefix}" = "xNONE"; then
  PREFIX="${ac_default_prefix}"
else
  PREFIX="${prefix}"
fi
AC_DEFINE_UNQUOTED(LOCALE_DIR, "${PREFIX}/${DATADIRNAME}/locale",[Locale directory])
AC_DEFINE_UNQUOTED(THEME_DIR, "${PREFIX}/${DATADIRNAME}/icons",[Icon directory])
AC_DEFINE_UNQUOTED(PKG_DATA_DIR, "${PREFIX}/${DATADIRNAME}/${PACKAGE}",[Package data directory])

GTK_REQ_VER=2.14
GLIB_REQ_VER=2.20
GIO_REQ_VER=$GLIB_REQ_VER

# Check dependencies
PKG_CHECK_MODULES(DUP,
                  gtk+-2.0 >= $GTK_REQ_VER
                  gio-2.0 >= $GIO_REQ_VER
                  gconf-2.0
                  dbus-glib-1
                  gnome-keyring-1)
AC_SUBST(DUP_CFLAGS)
AC_SUBST(DUP_LIBS)

PKG_CHECK_MODULES(PREF,
                  gtk+-2.0 >= $GTK_REQ_VER
                  gio-2.0 >= $GIO_REQ_VER
                  gconf-2.0
                  unique-1.0)
AC_SUBST(PREF_CFLAGS)
AC_SUBST(PREF_LIBS)

PKG_CHECK_MODULES(COMMON,
                  gio-2.0 >= $GIO_REQ_VER
                  gio-unix-2.0 >= $GIO_REQ_VER
                  gconf-2.0
                  dbus-glib-1
                  gnome-keyring-1)
AC_SUBST(COMMON_CFLAGS)
AC_SUBST(COMMON_LIBS)

PKG_CHECK_MODULES(WIDGETS,
                  gtk+-2.0 >= $GTK_REQ_VER
                  gconf-2.0)
AC_SUBST(WIDGETS_CFLAGS)
AC_SUBST(WIDGETS_LIBS)

PKG_CHECK_MODULES(MONITOR,
                  gconf-2.0
                  gio-2.0 >= $GIO_REQ_VER
                  dbus-glib-1
                  libnotify)
AC_SUBST(MONITOR_CFLAGS)
AC_SUBST(MONITOR_LIBS)

AC_ARG_WITH([nautilus],
  [AS_HELP_STRING([--with-nautilus],
    [build nautilus plugin @<:@default=check@:>@])],
  [],
  [with_nautilus=check])
AS_IF([test "x$with_nautilus" != xno],
  [PKG_CHECK_MODULES(NAUTILUS, libnautilus-extension 
                               glib-2.0 >= $GLIB_REQ_VER,
    [AC_SUBST(NAUTILUS_CFLAGS)
     AC_SUBST(NAUTILUS_LIBS)]
     dnl Get nautilus extensions directory
     NAUTILUS_EXTENSION_DIR="${libdir}/nautilus/extensions-2.0"
     AC_SUBST(NAUTILUS_EXTENSION_DIR),
    [if test "x$with_nautilus" != xcheck; then
        AC_MSG_FAILURE(
          [--with-nautilus was given, but test for libnautilus-extension failed])
      fi
    ]
  )]
)
AM_CONDITIONAL([HAVE_NAUTILUS], [test -n "$NAUTILUS_LIBS"])

AH_TEMPLATE([HAVE_APPINDICATOR], [whether libappindicator is available])
AC_ARG_WITH([appindicator],
  [AS_HELP_STRING([--with-appindicator],
    [use libappindicator for notification icons @<:@default=check@:>@])],
  [],
  [with_appindicator=check])
AS_IF([test "x$with_appindicator" != xno],
  [PKG_CHECK_MODULES(APPINDICATOR, appindicator-0.1,
    [AC_DEFINE(HAVE_APPINDICATOR)
     AC_SUBST(APPINDICATOR_CFLAGS)
     AC_SUBST(APPINDICATOR_LIBS)],
    [if test "x$with_appindicator" != xcheck; then
        AC_MSG_FAILURE(
          [--with-appindicator was given, but test for appindicator failed])
      fi
    ]
  )]
)

# Sets up output files.
AC_CONFIG_FILES([Makefile
                 common/Makefile
                 data/Makefile
                 deja-dup/Makefile
                 help/Makefile
                 monitor/Makefile
                 nautilus/Makefile
                 po/Makefile.in
                 preferences/Makefile
                 tests/Makefile
                 vapi/Makefile
                 widgets/Makefile])
AC_OUTPUT
