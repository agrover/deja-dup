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

/* This is meant to be used right after a successful OperationBackup to
   verify the results. */

public class OperationVerify : Operation
{
  File metadir;
  File destdir;

  public OperationVerify() {
    Object(mode: ToolJob.Mode.RESTORE);
  }

  public async override void start(bool try_claim_bus = true)
  {
    action_desc_changed(_("Verifying backup…"));
    yield base.start(try_claim_bus);
  }

  protected override void connect_to_job()
  {
    string cachedir = Environment.get_user_cache_dir();
    metadir = File.new_for_path(Path.build_filename(cachedir, Config.PACKAGE, "metadata"));
    job.restore_files.append(metadir);

    destdir = File.new_for_path("/");
    job.local = destdir;

    base.connect_to_job();
  }

  internal async override void operation_finished(ToolJob job, bool success, bool cancelled, string? detail)
  {
    // Verify results
    if (success) {
      var verified = true;
      string contents;
      try {
        FileUtils.get_contents(Path.build_filename(metadir.get_path(), "README"), out contents);
      }
      catch (Error e) {
        verified = false;
      }

      if (verified) {
        var lines = contents.split("\n");
        verified = (lines[0] == "This folder can be safely deleted.");
      }

      if (!verified) {
        raise_error(_("Your backup appears to be corrupted.  You should delete the backup and try again."), null);
        success = false;
      }
    }

    new RecursiveDelete(metadir).start();

    yield base.operation_finished(job, success, cancelled, detail);
  }
}

} // end namespace

