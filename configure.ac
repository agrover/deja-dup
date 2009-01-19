# Process this file with autoconf to produce a configure script.

# Sets up autoconf.
AC_INIT([Déjà Dup],[6.0],[mike@mterry.name],[deja-dup])
AC_PREREQ([2.53])
AC_CONFIG_SRCDIR(deja-dup/main.vala)
AC_CONFIG_HEADERS([config.h:config.h.in])
AC_CONFIG_MACRO_DIR([m4])

# Sets up automake.
AM_INIT_AUTOMAKE([1.9 foreign dist-bzip2])

GNOME_DOC_INIT

# Checks for programs.
AC_PROG_CC
AC_PROG_INSTALL
AC_PROG_MAKE_SET
AC_PROG_LIBTOOL

AC_PATH_PROG(GCONFTOOL, gconftool-2)
AM_GCONF_SOURCE_2

# Checks for vala
AC_PROG_VALAC([0.5.4])

# Sets up gettext.
GETTEXT_PACKAGE="$PACKAGE"
AC_SUBST(GETTEXT_PACKAGE)
AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE, "$GETTEXT_PACKAGE", [gettext domain])
AM_GNU_GETTEXT([external])
AM_GNU_GETTEXT_VERSION([0.17])
AC_PROG_INTLTOOL([0.37])

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

# Check dependencies
PKG_CHECK_MODULES(DUP,
                  gtk+-2.0 >= $GTK_REQ_VER
                  gio-2.0
                  gconf-2.0
                  libgnomeui-2.0
                  gnome-keyring-1)
AC_SUBST(DUP_CFLAGS)
AC_SUBST(DUP_LIBS)

PKG_CHECK_MODULES(APPLET,
                  gtk+-2.0 >= $GTK_REQ_VER
                  gio-2.0
                  gconf-2.0
                  libgnomeui-2.0
                  gnome-keyring-1
                  libnotify)
AC_SUBST(APPLET_CFLAGS)
AC_SUBST(APPLET_LIBS)

PKG_CHECK_MODULES(PREF,
                  gtk+-2.0 >= $GTK_REQ_VER
                  gio-2.0
                  gconf-2.0
                  unique-1.0)
AC_SUBST(PREF_CFLAGS)
AC_SUBST(PREF_LIBS)

PKG_CHECK_MODULES(LIBRARY,
                  gtk+-2.0 >= $GTK_REQ_VER
                  gio-2.0
                  gconf-2.0
                  libgnomeui-2.0
                  unique-1.0
                  gnome-keyring-1)
AC_SUBST(LIBRARY_CFLAGS)
AC_SUBST(LIBRARY_LIBS)

PKG_CHECK_MODULES(MONITOR,
                  gconf-2.0)
AC_SUBST(MONITOR_CFLAGS)
AC_SUBST(MONITOR_LIBS)

# Determines if we're debugging.
AC_ARG_ENABLE(debug,
  AC_HELP_STRING([--enable-debug=[no/yes]],[turn on debugging [default=no]]),
  enable_debug="$enableval",
  enable_debug=no)
if test "$enable_debug" = "yes"; then
  DEBUG_CFLAGS="-g -DG_DISABLE_DEPRECATED -DGDK_DISABLE_DEPRECATED -DGDK_PIXBUF_DISABLE_DEPRECATED -DGTK_MULTIHEAD_SAFE"
else
  DEBUG_CFLAGS=""
fi
AC_SUBST(DEBUG_CFLAGS)

# Sets up output files.
AC_CONFIG_FILES([Makefile
                 data/Makefile
                 libdeja-dup/Makefile
                 applet/Makefile
                 monitor/Makefile
                 deja-dup/Makefile
                 help/Makefile
                 help/C/deja-dup.xml
                 po/Makefile.in
                 preferences/Makefile
                 vapi/Makefile])
AC_OUTPUT

