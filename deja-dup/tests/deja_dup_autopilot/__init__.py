# -*- Mode: Python; indent-tabs-mode: nil; tab-width: 2; coding: utf-8 -*-
#
# This file is part of Déjà Dup.
# For copyright information, see AUTHORS.
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

import os
from functools import wraps

def system_only(fn):
  """A simple decorator that skips test if we are in local mode."""
  @wraps(fn)
  def wrapper(*args, **kwargs):
    if os.environ.get('DEJA_DUP_TEST_SYSTEM') != '1':
      tests_self = args[0]
      tests_self.skip("Skipping system test")
    return fn(*args, **kwargs)
  return wrapper
