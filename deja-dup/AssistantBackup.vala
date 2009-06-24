/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 2 -*- */
/*
    This file is part of Déjà Dup.
    © 2008,2009 Michael Terry <mike@mterry.name>

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

public class AssistantBackup : AssistantOperation
{
  construct
  {
    title = _("Backup");
  }
  
  Gtk.Widget make_backup_location_page()
  {
    int rows = 0;
    Gtk.Widget w, label;
    
    var page = new Gtk.Table(rows, 2, false);
    page.set("row-spacing", 6,
             "column-spacing", 6,
             "border-width", 12);
    
    w = new DejaDup.ConfigLocation();
    label = new Gtk.Label.with_mnemonic(_("_Backup location:"));
    label.set("xalign", 0.0f,
              "mnemonic-widget", w);
    page.attach(label, 0, 1, rows, rows + 1, Gtk.AttachOptions.FILL, 0, 0, 0);
    page.attach(w, 1, 2, rows, rows + 1, Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND, 0, 0, 0);
    ++rows;
    
    w = new DejaDup.ConfigBool(DejaDup.ENCRYPT_KEY, _("_Encrypt backup files"));
    page.attach(w, 0, 2, rows, rows + 1,
                Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                Gtk.AttachOptions.FILL, 0, 0);
    ++rows;
    
    return page;
  }
  
  Gtk.Widget make_include_exclude_page()
  {
    int rows = 0;
    Gtk.Widget w, label;
    
    var page = new Gtk.Table(rows, 2, false);
    page.set("row-spacing", 6,
             "column-spacing", 6,
             "border-width", 12);
    
    w = new DejaDup.ConfigList(DejaDup.INCLUDE_LIST_KEY);
    w.set_size_request(250, -1);
    label = new Gtk.Label(_("I_nclude files in folders:"));
    label.set("mnemonic-widget", w,
              "use-underline", true,
              "wrap", true,
              "width-request", 100,
              "xalign", 0.0f,
              "yalign", 0.0f);
    page.attach(label, 0, 1, rows, rows + 1, Gtk.AttachOptions.FILL, Gtk.AttachOptions.FILL, 0, 0);
    page.attach(w, 1, 2, rows, rows + 1, Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND, Gtk.AttachOptions.FILL, 0, 0);
    ++rows;
    
    w = new DejaDup.ConfigList(DejaDup.EXCLUDE_LIST_KEY);
    w.set_size_request(250, -1);
    label = new Gtk.Label(_("E_xcept files in folders:"));
    label.set("mnemonic-widget", w,
              "use-underline", true,
              "wrap", true,
              "width-request", 100,
              "xalign", 0.0f,
              "yalign", 0.0f);
    page.attach(label, 0, 1, rows, rows + 1, Gtk.AttachOptions.FILL, Gtk.AttachOptions.FILL, 0, 0);
    page.attach(w, 1, 2, rows, rows + 1, Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND, Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND, 0, 0);
    ++rows;
    
    return page;
  }
  
  protected override void add_custom_config_pages()
  {
    var page = make_backup_location_page();
    append_page(page);
    child_set(page,
              "title", _("Preferences"),
              "page-type", Gtk.AssistantPageType.CONTENT,
              "complete", true,
              "header-image", op_icon);
    
    page = make_include_exclude_page();
    append_page(page);
    child_set(page,
              "title", _("Preferences"),
              "page-type", Gtk.AssistantPageType.CONTENT,
              "complete", true,
              "header-image", op_icon);
  }
  
  protected override Gtk.Widget make_confirm_page()
  {
    int rows = 0;
    Gtk.Widget label, w;
    
    var page = new Gtk.Table(rows, 2, false);
    page.set("row-spacing", 6,
             "column-spacing", 6,
             "border-width", 12);
    
    label = new Gtk.Label(_("Backup location:"));
    label.set("xalign", 0.0f);
    w = new DejaDup.ConfigLabelLocation();
    page.attach(label, 0, 1, rows, rows + 1, Gtk.AttachOptions.FILL, 0, 0, 0);
    page.attach(w, 1, 2, rows, rows + 1, Gtk.AttachOptions.FILL, 0, 0, 0);
    ++rows;
    
    label = new Gtk.Label(_("Encrypted:"));
    label.set("xalign", 0.0f);
    w = new DejaDup.ConfigLabelBool(DejaDup.ENCRYPT_KEY);
    page.attach(label, 0, 1, rows, rows + 1, Gtk.AttachOptions.FILL, 0, 0, 0);
    page.attach(w, 1, 2, rows, rows + 1, Gtk.AttachOptions.FILL, 0, 0, 0);
    ++rows;
    
    label = new Gtk.Label(_("Include from:"));
    label.set("xalign", 0.0f, "yalign", 0.0f);
    w = new DejaDup.ConfigLabelList(DejaDup.INCLUDE_LIST_KEY);
    w.set("width-request", 250);
    page.attach(label, 0, 1, rows, rows + 1, Gtk.AttachOptions.FILL, Gtk.AttachOptions.FILL, 0, 0);
    page.attach(w, 1, 2, rows, rows + 1, 0, Gtk.AttachOptions.FILL, 0, 0);
    ++rows;
    
    label = new Gtk.Label(_("Except for:"));
    label.set("xalign", 0.0f, "yalign", 0.0f);
    w = new DejaDup.ConfigLabelList(DejaDup.EXCLUDE_LIST_KEY);
    w.set("width-request", 250);
    page.attach(label, 0, 1, rows, rows + 1, Gtk.AttachOptions.FILL, Gtk.AttachOptions.FILL, 0, 0);
    page.attach(w, 1, 2, rows, rows + 1, 0, Gtk.AttachOptions.FILL, 0, 0);
    ++rows;
    
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
  
  protected override Gdk.Pixbuf? make_op_icon()
  {
    try {
      var theme = Gtk.IconTheme.get_for_screen(get_screen());
      return theme.load_icon("deja-dup-backup", 48,
                             Gtk.IconLookupFlags.FORCE_SIZE);
    }
    catch (Error e) {
      warning("%s\n", e.message);
      return null;
    }
  }
  
  protected override void do_prepare(Gtk.Assistant assist, Gtk.Widget page)
  {
    base.do_prepare(assist, page);
    
    if (page == summary_page) {
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

