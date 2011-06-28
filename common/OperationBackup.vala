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

using GLib;

namespace DejaDup {

public class OperationBackup : Operation
{
  public OperationBackup(uint xid = 0) {
    Object(xid: xid, mode: Mode.BACKUP);
  }
  
  protected async override void operation_finished(Duplicity dup, bool success, bool cancelled)
  {
    /* If successfully completed, update time of last backup and run base operation_finished */
    if (success)
      DejaDup.update_last_run_timestamp(DejaDup.TimestampType.BACKUP);
    
    base.operation_finished(dup, success, cancelled);
  }
  
  protected override List<string>? make_argv() throws Error
  {
    var settings = get_settings();
    
    var include_val = settings.get_value(INCLUDE_LIST_KEY);
    var include_list = parse_dir_list(include_val.get_strv());
    var exclude_val = settings.get_value(EXCLUDE_LIST_KEY);
    var exclude_list = parse_dir_list(exclude_val.get_strv());
    
    List<string> rv = new List<string>();
    
    // Exclude directories no one wants to backup
    var always_excluded = get_always_excluded_dirs();
    foreach (string dir in always_excluded)
      dup.excludes.prepend(File.new_for_path(dir));
    
    foreach (File s in exclude_list)
      dup.excludes.prepend(s);
    foreach (File s in include_list)
      dup.includes.prepend(s);
    
    dup.local = File.new_for_path("/");
    
    return rv;
  }
  
  List<string> get_always_excluded_dirs()
  {
    List<string> rv = new List<string>();
    
    // User doesn't care about cache
    string dir = Environment.get_user_cache_dir();
    if (dir != null) {
      rv.append(dir);
      // We also add our special cache dir because if the user still especially
      // includes the cache dir, we still won't backup our own metadata.
      rv.append(Path.build_filename(dir, Config.PACKAGE));
    }

    // Likewise, user doesn't care about cache-like directories in $HOME.
    // In an ideal world, all of these would be under ~/.cache.  But for
    // historical reasons or for those apps that are both popular enough to
    // warrant special attention, we add some useful exclusions here.
    // When changing this list, remember to update the help documentation too.
    dir = Environment.get_home_dir();
    if (dir != null) {
      rv.append(Path.build_filename(dir, ".adobe/Flash_Player/AssetCache"));
      rv.append(Path.build_filename(dir, ".gvfs"));
      rv.append(Path.build_filename(dir, ".Private")); // encrypted copies of stuff in $HOME
      rv.append(Path.build_filename(dir, ".recent-applications.xbel"));
      rv.append(Path.build_filename(dir, ".recently-used.xbel"));
      rv.append(Path.build_filename(dir, ".thumbnails"));
      rv.append(Path.build_filename(dir, ".xsession-errors"));
    }
    
    // Some problematic directories like /tmp and /proc should be left alone
    dir = Environment.get_tmp_dir();
    if (dir != null)
      rv.append(dir);
    
    rv.append("/proc");
    rv.append("/sys");
    
    return rv;
  }
}

} // end namespace

