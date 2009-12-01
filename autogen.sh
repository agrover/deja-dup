#!/bin/sh
# Run this to generate all the initial makefiles, etc.

srcdir=`dirname $0`
test -z "$srcdir" && srcdir=.

PKG_NAME="deja-dup"
REQUIRED_AUTOCONF_VERSION=2.53
REQUIRED_AUTOMAKE_VERSION=1.9
REQUIRED_GETTEXT_VERSION=0.17
REQUIRED_INTLTOOL_VERSION=0.37

(test -f $srcdir/configure.ac \
  && test -d $srcdir/deja-dup) || {
    echo -n "**Error**: Directory "\`$srcdir\'" does not look like the"
    echo " top-level $PKG_NAME directory"
    exit 1
}

which gnome-autogen.sh || {
    echo "You need to install gnome-common"
    exit 1
}

USE_GNOME2_MACROS=1 . gnome-autogen.sh
