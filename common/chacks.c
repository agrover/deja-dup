/* -*- Mode: C; indent-tabs-mode: nil; tab-width: 2 -*- */
/*
    This file is part of Déjà Dup.
    For copyright information, see AUTHORS.

    Déjà Dup is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Déjà Dup is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Déjà Dup.  If not, see <http://www.gnu.org/licenses/>.
*/

#include "chacks.h"

static const GnomeKeyringPasswordSchema PASSPHRASE_SCHEMA_DEF = {
  GNOME_KEYRING_ITEM_GENERIC_SECRET,
  {
    {"owner", GNOME_KEYRING_ATTRIBUTE_TYPE_STRING},
    {"type", GNOME_KEYRING_ATTRIBUTE_TYPE_STRING},
    {NULL, 0}
  }
};

const GnomeKeyringPasswordSchema *PASSPHRASE_SCHEMA = &PASSPHRASE_SCHEMA_DEF;
