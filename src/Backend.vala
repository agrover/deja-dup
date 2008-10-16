/* -*- Mode: C; indent-tabs-mode: nil; c-basic-offset: 2; tab-width: 2 -*- */
/*
    Déjà Dup
    © 2008 Michael Terry <mike@mterry.name>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

using GLib;

public abstract class Backend : Object
{
  public abstract string? get_location() throws Error;
  public virtual string[]? get_options() throws Error {return null;}
  protected virtual string[]? get_envp() throws Error {return new string[0];}
  
  public static Backend? get_default() throws Error
  {
    var client = GConf.Client.get_default();
    var backend_name = client.get_string(BACKEND_KEY);
    if (backend_name == "s3")
      return new BackendS3();
    else if (backend_name == "file")
      return new BackendFile();
    else
      return null;
  }
}

