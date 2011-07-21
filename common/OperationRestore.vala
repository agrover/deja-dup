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

public class OperationRestore : Operation
{
  public string dest {get; construct;} // Directory user wants to put files in
  public string time {get; construct;} // Date user wants to restore to
  private List<File> _restore_files;
  public List<File> restore_files {
    get {
      return this._restore_files;
    }
    construct {
      foreach (File f in this._restore_files)
        f.unref();
      this._restore_files = value.copy();
      foreach (File f in this._restore_files)
        f.ref();
    }
  }
  
  public OperationRestore(string dest_in,
                          string? time_in = null,
                          List<File>? files_in = null,
                          uint xid = 0) {
    Object(xid: xid, dest: dest_in, time: time_in, restore_files: files_in,
           mode: Mode.RESTORE);
  }
  
  public async override void start()
  {
    action_desc_changed(_("Restoring files…"));
    base.start();
  }

  protected override void connect_to_dup()
  {
    base.connect_to_dup();
    dup.restore_files = restore_files;
  }

  protected override List<string>? make_argv() throws Error
  {
    List<string> argv = new List<string>();
    if (time != null)
      argv.append("--restore-time=%s".printf(time));
    
    dup.local = File.new_for_path(dest);
    
    return argv;
  }
  
  protected async override void operation_finished(Duplicity dup, bool success, bool cancelled)
  {
    if (success)
      DejaDup.update_last_run_timestamp(DejaDup.TimestampType.RESTORE);

    base.operation_finished(dup, success, cancelled);
  }
}

} // end namespace

