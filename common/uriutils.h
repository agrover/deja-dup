/* -*- Mode: C; indent-tabs-mode: nil; tab-width: 2 -*- */
/* 
 * This file is part of Déjà Dup (but originally grabbed from gvfs).
 * Copyright (C) 2006-2007 Red Hat, Inc.
 *
 * Déjà Dup is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.
 *
 * Déjà Dup is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Déjà Dup.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author: Alexander Larsson <alexl@redhat.com>
 */

#ifndef __URI_UTILS_H__
#define __URI_UTILS_H__

#include <glib.h>

G_BEGIN_DECLS

typedef struct {
  char *scheme;
  char *userinfo;
  char *host;
  int port; /* -1 => not in uri */
  char *path;
  char *query;
  char *fragment;
} DejaDupDecodedUri;

char *       deja_dup_decoded_uri_encode_uri       (DejaDupDecodedUri *decoded,
                                                    gboolean     allow_utf8);
void         deja_dup_decoded_uri_free             (DejaDupDecodedUri *decoded);
DejaDupDecodedUri *deja_dup_decoded_uri_decode_uri (const char  *uri);
DejaDupDecodedUri *deja_dup_decoded_uri_new        (void);

G_END_DECLS

#endif /* __URI_UTILS_H__ */
