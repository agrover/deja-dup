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

errordomain BackupError {
  INTERNAL
}

public class Backup : Operation
{
  construct
  {
    dup.progress_label = _("Backing up files...");
  }
  
  protected override string[]? make_argv() throws Error
  {
    var target = backend.get_location();
    if (target == null)
      throw new BackupError.INTERNAL(_("Could not connect to backup location"));
    
    var client = GConf.Client.get_default();
    
    var include_list = parse_dir_list(client.get_list(INCLUDE_LIST_KEY,
                                                      GConf.ValueType.STRING));
    var exclude_list = parse_dir_list(client.get_list(EXCLUDE_LIST_KEY,
                                                      GConf.ValueType.STRING));
    var options = backend.get_options();
    
    string[] rv = new string[include_list.length + exclude_list.length + options.length + 6];
    int i = 0;
    rv[i++] = "duplicity";
    
    if (options != null) {
      for (int j = 0; j < options.length; ++j)
        rv[i++] = options[j];
    }
    
    if (!client.get_bool(ENCRYPT_KEY))
      rv[i++] = "--no-encryption";
    foreach (File s in exclude_list)
      rv[i++] = "--exclude=%s".printf(s.get_path());
    foreach (File s in include_list)
      rv[i++] = "--include=%s".printf(s.get_path());
    rv[i++] = "--exclude=**";
    rv[i++] = "/";
    rv[i++] = target;
    rv[i++] = null;
    
    return rv;
  }
}

