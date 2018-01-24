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
  File metadir;

  public OperationBackup(Backend backend) {
    Object(mode: ToolJob.Mode.BACKUP, backend: backend);
  }
  
  internal async override void operation_finished(bool success, bool cancelled, string? detail)
  {
    /* If successfully completed, update time of last backup and run base operation_finished */
    if (success)
      DejaDup.update_last_run_timestamp(DejaDup.TimestampType.BACKUP);

    if (metadir != null)
      new RecursiveDelete(metadir).start();

    if (success && !cancelled)
      yield chain_op(new OperationVerify(backend), _("Verifying backup…"), detail);
    else
      yield base.operation_finished(success, cancelled, detail);
  }

  protected override void send_action_file_changed(File file, bool actual)
  {
    // Intercept action_file_changed signals and ignore them if they are
    // metadata file, the user doesn't need to see them.
    if (!file.has_prefix(metadir))
      base.send_action_file_changed(file, actual);
  }

  protected override List<string>? make_argv()
  {
    var settings = get_settings();
    var include_list = settings.get_file_list(INCLUDE_LIST_KEY);
    var exclude_list = settings.get_file_list(EXCLUDE_LIST_KEY);
    
    // Exclude directories no one wants to backup
    add_always_excluded_dirs(ref job.excludes, ref job.exclude_regexps);

    foreach (File s in exclude_list)
      job.excludes.prepend(s);
    foreach (File s in include_list)
      job.includes.prepend(s);

    // Insert deja-dup meta info directory
    string cachedir = Environment.get_user_cache_dir();
    try {
      metadir = File.new_for_path(Path.build_filename(cachedir, Config.PACKAGE, "metadata"));
      fill_metadir();
      job.includes.prepend(metadir);
    }
    catch (Error e) {
      warning("%s\n", e.message);
    }
    
    job.local = File.new_for_path("/");

    return null;
  }
  
  void add_always_excluded_dirs(ref List<File> files, ref List<string> regexps)
  {
    // User doesn't care about cache
    string dir = Environment.get_user_cache_dir();
    if (dir != null) {
      files.prepend(File.new_for_path(dir));
      // We also add our special cache dir because if the user still especially
      // includes the cache dir, we still won't backup our own metadata.
      files.prepend(File.new_for_path(Path.build_filename(dir, Config.PACKAGE)));
    }

    // Likewise, user doesn't care about cache-like directories in $HOME.
    // In an ideal world, all of these would be under ~/.cache.  But for
    // historical reasons or for those apps that are both popular enough to
    // warrant special attention, we add some useful exclusions here.
    // When changing this list, remember to update the help documentation too.
    dir = Environment.get_home_dir();
    if (dir != null) {
      files.prepend(File.new_for_path(Path.build_filename(dir, ".adobe/Flash_Player/AssetCache")));
      files.prepend(File.new_for_path(Path.build_filename(dir, ".ccache")));
      files.prepend(File.new_for_path(Path.build_filename(dir, ".gvfs")));
      files.prepend(File.new_for_path(Path.build_filename(dir, ".Private"))); // encrypted copies of stuff in $HOME
      files.prepend(File.new_for_path(Path.build_filename(dir, ".recent-applications.xbel")));
      files.prepend(File.new_for_path(Path.build_filename(dir, ".recently-used.xbel")));
      files.prepend(File.new_for_path(Path.build_filename(dir, ".steam/root")));
      files.prepend(File.new_for_path(Path.build_filename(dir, ".thumbnails")));
      files.prepend(File.new_for_path(Path.build_filename(dir, ".xsession-errors")));
      regexps.prepend(Path.build_filename(dir, "snap/*/*/.cache"));
    }
    
    // Skip all of our temporary directories
    foreach (var tempdir in DejaDup.get_tempdirs())
      files.prepend(File.new_for_path(tempdir));

    // Skip transient directories
    files.prepend(File.new_for_path("/proc"));
    files.prepend(File.new_for_path("/run"));
    files.prepend(File.new_for_path("/sys"));
  }

  void fill_metadir() throws Error
  {
    if (metadir == null)
      return;

    // Delete old dir, if any, and replace it
    new RecursiveDelete(metadir).start();
    metadir.make_directory_with_parents(null);

    // Put a file in there that is one part always constant, and one part
    // always different, for basic sanity checking.  This way, it will be
    // included in every backup, but we can still check its contents for
    // corruption.  We'll stuff seconds-since-epoch in it.
    var now = new DateTime.now_utc();
    var msg = "This folder can be safely deleted.\n%s".printf(now.format("%s"));
    FileUtils.set_contents(Path.build_filename(metadir.get_path(), "README"), msg);
  }
}

} // end namespace

