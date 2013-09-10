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

#include "uriutils.h"
#include <string.h>
#include <stdlib.h>

void
deja_dup_decoded_uri_free (DejaDupDecodedUri *decoded)
{
  if (decoded == NULL)
    return;

  g_free (decoded->scheme);
  g_free (decoded->query);
  g_free (decoded->fragment);
  g_free (decoded->userinfo);
  g_free (decoded->host);
  g_free (decoded->path);
  g_free (decoded);
}

DejaDupDecodedUri *
deja_dup_decoded_uri_new (void)
{
  DejaDupDecodedUri *uri;

  uri = g_new0 (DejaDupDecodedUri, 1);
  uri->port = -1;

  return uri;
}

DejaDupDecodedUri *
deja_dup_decoded_uri_decode_uri (const char *uri)
{
  DejaDupDecodedUri *decoded;
  const char *p, *in, *hier_part_start, *hier_part_end, *query_start, *fragment_start;
  char *out;
  char c;

  /* From RFC 3986 Decodes:
   * URI         = scheme ":" hier-part [ "?" query ] [ "#" fragment ]
   */ 

  p = uri;
  
  /* Decode scheme:
     scheme      = ALPHA *( ALPHA / DIGIT / "+" / "-" / "." )
  */

  if (!g_ascii_isalpha (*p))
    return NULL;

  while (1)
    {
      c = *p++;

      if (c == ':')
        break;
      
      if (!(g_ascii_isalnum(c) ||
            c == '+' ||
            c == '-' ||
            c == '.'))
        return NULL;
    }

  decoded = deja_dup_decoded_uri_new ();
  
  decoded->scheme = g_malloc (p - uri);
  out = decoded->scheme;
  for (in = uri; in < p - 1; in++)
    *out++ = g_ascii_tolower (*in);
  *out = 0;

  hier_part_start = p;

  query_start = strchr (p, '?');
  if (query_start)
    {
      hier_part_end = query_start++;
      fragment_start = strchr (query_start, '#');
      if (fragment_start)
        {
          decoded->query = g_strndup (query_start, fragment_start - query_start);
          decoded->fragment = g_strdup (fragment_start+1);
        }
      else
        {
          decoded->query = g_strdup (query_start);
          decoded->fragment = NULL;
        }
    }
  else
    {
      /* No query */
      decoded->query = NULL;
      fragment_start = strchr (p, '#');
      if (fragment_start)
        {
          hier_part_end = fragment_start++;
          decoded->fragment = g_strdup (fragment_start);
        }
      else
        {
          hier_part_end = p + strlen (p);
          decoded->fragment = NULL;
        }
    }

  /*  3:
      hier-part   = "//" authority path-abempty
                  / path-absolute
                  / path-rootless
                  / path-empty

  */

  if (hier_part_start[0] == '/' &&
      hier_part_start[1] == '/')
    {
      const char *authority_start, *authority_end;
      const char *userinfo_start, *userinfo_end;
      const char *host_start, *host_end;
      const char *port_start;
      
      authority_start = hier_part_start + 2;
      /* authority is always followed by / or nothing */
      authority_end = memchr (authority_start, '/', hier_part_end - authority_start);
      if (authority_end == NULL)
        authority_end = hier_part_end;

      /* 3.2:
              authority   = [ userinfo "@" ] host [ ":" port ]
      */

      /* Look for the last so that any multiple @ signs are put in the username part.
       * This is not quite correct, as @ should be escaped here, but this happens
       * in practice, so lets handle it the "nicer" way at least. */
      userinfo_end = g_strrstr_len (authority_start,
                                    authority_end - authority_start, "@");
      if (userinfo_end)
        {
          userinfo_start = authority_start;
          decoded->userinfo = g_uri_unescape_segment (userinfo_start, userinfo_end, NULL);
          if (decoded->userinfo == NULL)
            {
              deja_dup_decoded_uri_free (decoded);
              return NULL;
            }
          host_start = userinfo_end + 1;
        }
      else
        host_start = authority_start;

      /* We should handle hostnames in brackets, as those are used by IPv6 URIs
       * See http://tools.ietf.org/html/rfc2732 */
      if (*host_start == '[')
        {
          char *s;

          port_start = NULL;
          host_end = memchr (host_start, ']', authority_end - host_start);
          if (host_end == NULL)
            {
              deja_dup_decoded_uri_free (decoded);
              return NULL;
            }

          /* Look for the start of the port,
           * And we sure we don't have it start somewhere
           * in the path section */
          s = (char *) host_end;
          while (1)
            {
              if (*s == '/')
                {
                  port_start = NULL;
                  break;
                }
              else if (*s == ':')
                {
                  port_start = s;
                  break;
                }
              else if (*s == '\0')
                {
                  break;
                }

              s++;
            }
        }
      else
        {
          port_start = memchr (host_start, ':', authority_end - host_start);
        }

      if (port_start)
        {
          host_end = port_start++;

          decoded->port = atoi(port_start);
        }
      else
        {
          host_end = authority_end;
          decoded->port = -1;
        }

      decoded->host = g_uri_unescape_segment (host_start, host_end, NULL);

      hier_part_start = authority_end;
    }

  decoded->path = g_uri_unescape_segment (hier_part_start, hier_part_end, "/");

  if (decoded->path == NULL)
    {
      deja_dup_decoded_uri_free (decoded);
      return NULL;
    }
  
  return decoded;
}

char *
deja_dup_decoded_uri_encode_uri (DejaDupDecodedUri *decoded, gboolean allow_utf8)
{
  GString *uri;

  uri = g_string_new (NULL);

  g_string_append (uri, decoded->scheme);
  g_string_append (uri, "://");

  if (decoded->host != NULL)
    {
      if (decoded->userinfo)
        {
          /* userinfo    = *( unreserved / pct-encoded / sub-delims / ":" ) */
          g_string_append_uri_escaped (uri, decoded->userinfo,
                                       G_URI_RESERVED_CHARS_ALLOWED_IN_USERINFO, allow_utf8);
          g_string_append_c (uri, '@');
        }
      
      g_string_append_uri_escaped (uri, decoded->host,
                                   /* Allowed unescaped in hostname / ip address */
                                   G_URI_RESERVED_CHARS_SUBCOMPONENT_DELIMITERS ":[]" ,
                                   allow_utf8);
      
      if (decoded->port != -1)
        {
          g_string_append_c (uri, ':');
          g_string_append_printf (uri, "%d", decoded->port);
        }
    }

  g_string_append_uri_escaped (uri, decoded->path, G_URI_RESERVED_CHARS_ALLOWED_IN_PATH, allow_utf8);
  
  if (decoded->query)
    {
      g_string_append_c (uri, '?');
      g_string_append (uri, decoded->query);
    }
    
  if (decoded->fragment)
    {
      g_string_append_c (uri, '#');
      g_string_append (uri, decoded->fragment);
    }

  return g_string_free (uri, FALSE);
}
