/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 2 -*- */
/*
    This file is part of Déjà Dup.
    © 2008–2010 Michael Terry <mike@mterry.name>

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
  DejaDup.ToggleGroup periodic_toggle;
  
  public AssistantBackup(bool automatic)
  {
    Object(automatic: automatic);
  }

  construct
  {
    title = C_("back up is verb", "Back Up");
    apply_text = C_("back up is verb", "_Back Up");
    resume_supported = DejaDup.DuplicityInfo.get_default().can_resume;
    resumed.connect(do_resume);
  }
  
  Gtk.Widget make_backup_location_page()
  {
    int rows = 0;
    Gtk.Widget w, label;
    Gtk.SizeGroup label_sizes = new Gtk.SizeGroup(Gtk.SizeGroupMode.HORIZONTAL);
    
    var vbox = new Gtk.VBox(false, 0);
    vbox.border_width = 12;
    
    var page = new Gtk.Table(rows, 2, false);
    page.set("row-spacing", 6,
             "column-spacing", 6);
    
    var location = new DejaDup.ConfigLocation(label_sizes);
    label = new Gtk.Label.with_mnemonic(_("_Backup location:"));
    label.set("xalign", 0.0f,
              "mnemonic-widget", location);
    label_sizes.add_widget(label);
    page.attach(label, 0, 1, rows, rows + 1, Gtk.AttachOptions.FILL, 0, 0, 0);
    page.attach(location, 1, 2, rows, rows + 1, Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND, 0, 0, 0);
    ++rows;

    page.attach(location.extras, 0, 2, rows, rows + 1, Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND, 0, 0, 0);
    ++rows;
    
    w = new DejaDup.ConfigBool(DejaDup.ENCRYPT_KEY, _("_Encrypt backup files"));
    page.attach(w, 0, 2, rows, rows + 1,
                Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                Gtk.AttachOptions.FILL, 0, 0);
    ++rows;
    
    w = new DejaDup.ConfigLabelPolicy();
    
    vbox.pack_start(page, true, true, 0);
    vbox.pack_end(w, false, false, 0);

    vbox.show_all();

    // Now make sure to reserve the excess space that the hidden bits of
    // ConfigLocation will need.
    Gtk.Requisition req, hidden;
    vbox.size_request(out req);
    hidden = location.hidden_size();
    req.width = req.width + hidden.width;
    req.height = req.height + hidden.height;
    vbox.set_size_request(req.width, req.height);

    return vbox;
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
    w.set_size_request(250, 100);
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
    w.set_size_request(250, 70);
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
    if (automatic)
      return;

    var page = make_backup_location_page();
    append_page(page);
    set_page_title(page, _("Preferences"));
    
    page = make_include_exclude_page();
    append_page(page);
    set_page_title(page, _("Preferences"));
  }
  
  protected override Gtk.Widget? make_confirm_page()
  {
    if (automatic)
      return null;

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
    realize();
    var xid = hacks_window_get_xid(this.get_window());
    var rv = new DejaDup.OperationBackup((uint)xid);
    if (automatic) {
      // If in automatic mode, only use progress if it's a full backup
      rv.use_progress = false;
      rv.is_full.connect((op) => {op.use_progress = true;});
    }
    return rv;
  }
  
  void do_resume()
  {
    hide_everything();
    if (op != null)
      op.stop();
    else {
      succeeded = true; // fake it
      do_close();
    }
  }

  protected override string get_progress_file_prefix()
  {
    // Translators:  This is the phrase 'Backing up' in the larger phrase
    // "Backing up '%s'".  %s is a filename.
    return _("Backing up:");
  }
  
  protected override void set_op_icon_name()
  {
    icon_name = "deja-dup-backup";
  }
  
  void add_periodic_widgets(Gtk.VBox page)
  {
    var check = new DejaDup.ConfigBool(DejaDup.PERIODIC_KEY, _("_Automatically back up on a regular schedule"));
    
    var combo = new DejaDup.ConfigPeriod(DejaDup.PERIODIC_PERIOD_KEY);
    var label = new Gtk.Label("    %s".printf(_("How _often to back up:")));
    label.set("mnemonic-widget", combo,
              "use-underline", true,
              "xalign", 0.0f);
    
    var hbox = new Gtk.HBox(false, 6);
    hbox.set("child", label,
             "child", combo);
    
    page.pack_end(hbox, false, false, 0);
    page.pack_end(check, false, false, 0);
    
    periodic_toggle = new DejaDup.ToggleGroup(check);
    periodic_toggle.add_dependent(label);
    periodic_toggle.add_dependent(combo);
    periodic_toggle.check();
    
    check.show_all();
    hbox.show_all();
  }
  
  protected override void do_prepare(Assistant assist, Gtk.Widget page)
  {
    base.do_prepare(assist, page);
    
    if (page == summary_page) {
      if (error_occurred) {
        set_page_title(page, _("Backup Failed"));
      }
      else {
        set_page_title(page, _("Backup Finished"));
        summary_label.label = _("Your files were successfully backed up.");

        // Summary page is a vbox, let's add some widgets here to allow user to
        // make this backup on a regular basis.  But only show if user isn't
        // already automatically backing up.
        var settings = DejaDup.get_settings();
        bool val = false;
        val = settings.get_boolean(DejaDup.PERIODIC_KEY);
        if (!val)
          add_periodic_widgets((Gtk.VBox)page);

        if (automatic)
          Idle.add(() => {do_close(); return false;});
        else
          Idle.add(() => {force_visible(false); return false;});
      }
    }
    else if (page == progress_page) {
      set_page_title(page, _("Backing Up…"));
    }
  }
}

