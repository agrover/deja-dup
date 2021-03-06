/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 2 -*- */
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

/* TODO: libsecret-1.vapi does not have SECRET_SCHEMA_COMPAT_NETWORK yet */
[CCode (cprefix = "Secret", gir_namespace = "Secret", gir_version = "1", lower_case_cprefix = "secret_")]
namespace Secret {
	[CCode (cheader_filename = "libsecret/secret.h", cname = "SECRET_SCHEMA_COMPAT_NETWORK")]
	public Secret.Schema SCHEMA_COMPAT_NETWORK;
}

