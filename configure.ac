# -*- Mode: m4; indent-tabs-mode: nil; tab-width: 2 -*-
#
# This file is part of Déjà Dup.
# © 2008–2010 Michael Terry <mike@mterry.name>,
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
AC_INIT([Déjà Dup],[19.0],[https://bugs.launchpad.net/deja-dup/+filebug],[deja-dup],[https://launchpad.net/deja-dup])
AC_PREREQ(2.64)
AC_CONFIG_SRCDIR(deja-dup/main.vala)
AC_CONFIG_HEADERS([config.h:config.h.in])
AC_CONFIG_MACRO_DIR([m4])

# Sets up automake.
AM_INIT_AUTOMAKE([1.11 foreign tar-pax dist-bzip2 no-dist-gzip])
AM_SILENT_RULES([yes])
AM_MAINTAINER_MODE()

GNOME_DOC_INIT
GLIB_GSETTINGS

# Checks for programs.
AC_PROG_CC
AC_PROG_INSTALL
AC_PROG_MAKE_SET

LT_PREREQ([2.2.6])
LT_INIT

# Checks for valac
if test "x$USE_MAINTAINER_MODE" = "xyes" ; then
  DEJA_PROG_VALAC([0.11.6])
  if test "x$VALAC" = "x" ; then
      AC_MSG_ERROR([Cannot find the "valac" compiler in your PATH])
  fi
  CFLAGS+=" -DG_DISABLE_DEPRECATED -DGDK_DISABLE_DEPRECATED -DGDK_PIXBUF_DISABLE_DEPRECATED -DGTK_DISABLE_DEPRECATED -DGSEAL_ENABLE"
fi

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

GTK_MODULE=gtk+-3.0
GTK_REQ_VER=3.0
GDK_X11_MODULE=gdk-x11-3.0
GLIB_REQ_VER=2.26
GIO_REQ_VER=$GLIB_REQ_VER
NOTIFY_REQ_VER=0.7
APPINDICATOR_MODULE=appindicator3-0.1
DBUSMENU_GTK_MODULE=dbusmenu-gtk3-0.4

AC_SUBST(GTK_MODULE)
AC_SUBST(GDK_X11_MODULE)

# Check dependencies
PKG_CHECK_MODULES(DUP,
                  $GTK_MODULE >= $GTK_REQ_VER
                  gio-2.0 >= $GIO_REQ_VER
                  gnome-keyring-1
                  gmodule-2.0 >= $GLIB_REQ_VER
                  libnotify >= $NOTIFY_REQ_VER)
AC_SUBST(DUP_CFLAGS)
AC_SUBST(DUP_LIBS)

PKG_CHECK_MODULES(PREF,
                  $GTK_MODULE >= $GTK_REQ_VER
                  gio-2.0 >= $GIO_REQ_VER)
AC_SUBST(PREF_CFLAGS)
AC_SUBST(PREF_LIBS)

PKG_CHECK_MODULES(COMMON,
                  gio-2.0 >= $GIO_REQ_VER
                  gio-unix-2.0 >= $GIO_REQ_VER
                  gnome-keyring-1
                  gmodule-2.0 >= $GLIB_REQ_VER)
AC_SUBST(COMMON_CFLAGS)
AC_SUBST(COMMON_LIBS)

PKG_CHECK_MODULES(WIDGETS,
                  gmodule-2.0 >= $GLIB_REQ_VER
                  $GTK_MODULE >= $GTK_REQ_VER)
AC_SUBST(WIDGETS_CFLAGS)
AC_SUBST(WIDGETS_LIBS)

PKG_CHECK_MODULES(MONITOR,
                  gio-2.0 >= $GIO_REQ_VER
                  libnotify >= $NOTIFY_REQ_VER)
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
     NAUTILUS_EXTENSION_DIR=`$PKG_CONFIG --variable=extensiondir libnautilus-extension`
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
  [PKG_CHECK_MODULES(APPINDICATOR, $APPINDICATOR_MODULE,
    [AC_DEFINE(HAVE_APPINDICATOR)
     AC_SUBST(APPINDICATOR_CFLAGS)
     AC_SUBST(APPINDICATOR_LIBS)],
    [if test "x$with_appindicator" != xcheck; then
        AC_MSG_FAILURE(
          [--with-appindicator was given, but test for $APPINDICATOR_MODULE failed])
      fi
    ]
  )]
)

AH_TEMPLATE([HAVE_UNITY], [whether libunity is available])
AC_ARG_WITH([unity],
  [AS_HELP_STRING([--with-unity],
    [support libunity @<:@default=check@:>@])],
  [],
  [with_unity=check])
AS_IF([test "x$with_unity" != xno],
  [PKG_CHECK_MODULES(UNITY, $DBUSMENU_GTK_MODULE >= 0.3.94 unity >= 3.4.2,
    [AC_DEFINE(HAVE_UNITY)
     AC_SUBST(UNITY_CFLAGS)
     AC_SUBST(UNITY_LIBS)],
    [if test "x$with_unity" != xcheck; then
        AC_MSG_FAILURE(
          [--with-unity was given, but test for unity failed])
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
                 man/Makefile
                 monitor/Makefile
                 nautilus/Makefile
                 po/Makefile.in
                 preferences/Makefile
                 tests/Makefile
                 vapi/Makefile
                 widgets/Makefile])
AC_OUTPUT
