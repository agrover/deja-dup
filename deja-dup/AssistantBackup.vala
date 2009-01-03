/* -*- Mode: C; indent-tabs-mode: nil; tab-width: 2 -*- */
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

public class AssistantBackup : AssistantOperation
{
  Gtk.Label confirm_backup;
  construct
  {
    title = _("Backup");
  }
  
  protected override void add_setup_pages()
  {
  }
  
  protected override Gtk.Widget make_confirm_page()
  {
    int rows = 0;
    
    var backup_label = new Gtk.Label(_("Backup location:"));
    backup_label.set("xalign", 0.0f);
    confirm_backup = new Gtk.Label("");
    confirm_backup.set("xalign", 0.0f);
    ++rows;
    
    var page = new Gtk.Table(rows, 2, false);
    page.set("row-spacing", 6,
             "column-spacing", 6,
             "border-width", 12);
    
    rows = 0;
    page.attach(backup_label, 0, 1, rows, rows + 1, Gtk.AttachOptions.FILL, 0, 0, 0);
    page.attach(confirm_backup, 1, 2, rows, rows + 1, Gtk.AttachOptions.FILL, 0, 0, 0);
    
    return page;
  }
  
  protected override DejaDup.Operation create_op()
  {
    return new DejaDup.OperationBackup(this);
  }
  
  protected override string get_progress_file_prefix()
  {
    // Translators:  This is the phrase 'Backing up' in the larger phrase
    // "Backing up '%s'".  %s is a filename.
    return _("Backing up");
  }
  
  protected override Gdk.Pixbuf? get_op_icon()
  {
    try {
      var filename = get_backup_icon_filename();
      return new Gdk.Pixbuf.from_file_at_size(filename, 48, 48);
    }
    catch (Error e) {
      warning("%s\n", e.message);
      return null;
    }
  }
  
  protected override void do_prepare(AssistantOperation assist, Gtk.Widget page)
  {
    base.do_prepare(assist, page);
    
    if (page == confirm_page) {
      // Where the backup is
      string backup_loc = null;
      try {
        backup_loc = DejaDup.Backend.get_default(this).get_location_pretty();
      }
      catch (Error e) {
        warning("%s\n", e.message);
      }
      if (backup_loc == null)
        backup_loc = _("Unknown");
      confirm_backup.label = backup_loc;
    }
    else if (page == summary_page) {
      if (error_occurred)
        assist.child_set(page, "title", _("Backup Failed"));
      else {
        assist.child_set(page, "title", _("Backup Finished"));
        summary_label.label = _("Your files were successfully backed up.");
      }
    }
    else if (page == progress_page) {
      assist.child_set(page, "title", _("Backing up..."));
    }
  }
}

