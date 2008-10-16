#!/bin/sh
set -e -x
autoreconf --force --install
intltoolize --force --copy --automake
