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

public class RestoreAssistant : Gtk.Assistant
{
  public string restore_location {get; protected set; default = "/";}
  
  Gtk.HBox cust_box;
  Gtk.FileChooserButton cust_button;
  Gtk.Label progress_label;
  Gtk.ProgressBar progress_bar;
  Gtk.Widget progress_page;
  Gtk.Label summary_label;
  Gtk.Widget summary_page;
  Gdk.Pixbuf icon;
  DejaDup.OperationRestore op;
  uint timeout_id;
  construct
  {
    title = _("Restore");
    
    try {
      var filename = get_restore_icon_filename();
      icon = new Gdk.Pixbuf.from_file_at_size(filename, 48, 48);
    }
    catch (Error e) {
      warning("%s\n", e.message);
    }
    
    add_restore_dest_page();
    add_confirm_page();
    add_progress_page();
    add_summary_page();
    
    apply += do_apply;
    cancel += do_cancel;
    close += do_close;
    prepare += do_prepare;
  }
  
  Gtk.Widget make_restore_dest_page()
  {
    var orig_radio = new Gtk.RadioButton(null);
    orig_radio.set("label", _("Restore files to _original locations"),
                   "use-underline", true);
    orig_radio.toggled += (r) => {if (r.active) restore_location = "/";};
    
    var cust_radio = new Gtk.RadioButton(null);
    cust_radio.set("label", _("Restore to _specific folder"),
                   "use-underline", true,
                   "group", orig_radio);
    cust_radio.toggled += (r) => {
      if (r.active)
        restore_location = cust_button.get_filename();
      cust_box.sensitive = r.active;
    };
    
    cust_button =
      new Gtk.FileChooserButton(_("Choose destination for restored files"),
                                Gtk.FileChooserAction.SELECT_FOLDER);
    
    var cust_label = new Gtk.Label("    " + _("Restore _folder:"));
    cust_label.set("mnemonic-widget", cust_button,
                   "use-underline", true,
                   "xalign", 0.0f);
    
    cust_box = new Gtk.HBox(false, 6);
    cust_box.set("child", cust_label,
                 "child", cust_button,
                 "sensitive", false);
    
    var page = new Gtk.VBox(false, 6);
    page.set("child", orig_radio,
             "child", cust_radio,
             "child", cust_box,
             "border-width", 12);
    page.child_set(orig_radio, "expand", false);
    page.child_set(cust_radio, "expand", false);
    page.child_set(cust_box, "expand", false);
    
    return page;
  }
  
  Gtk.Widget make_confirm_page()
  {
    int rows = 0;
    
    var location_label = new Gtk.Label(_("Restore folder:"));
    location_label.set("xalign", 0.0f);
    
    var location = new Gtk.Label(restore_location);
    if (restore_location == "/")
      location.label = _("Original location");
    
    var page = new Gtk.Table(rows, 2, false);
    page.set("row-spacing", 6,
             "column-spacing", 6,
             "border-width", 12);
    page.attach(location_label, 0, 1, 0, 1, 0, 0, 0, 0);
    page.attach(location, 1, 2, 0, 1, 0, 0, 0, 0);
    
    return page;
  }
  
  bool pulse()
  {
    progress_bar.pulse();
    return true;
  }
  
  void set_progress_label(DejaDup.OperationRestore restore, string label)
  {
    progress_label.label = label;
  }
  
  Gtk.Widget make_progress_page()
  {
    progress_label = new Gtk.Label("");
    progress_label.set("xalign", 0.0f);
    
    progress_bar = new Gtk.ProgressBar();
    
    var page = new Gtk.VBox(false, 6);
    page.set("child", progress_label,
             "child", progress_bar,
             "border-width", 12);
    page.child_set(progress_label, "expand", false);
    page.child_set(progress_bar, "expand", false);
    
    return page;
  }
  
  void show_error(DejaDup.OperationRestore restore, string error, string? detail)
  {
    child_set(summary_page,
              "title", _("Restore Failed"));
    summary_label.label = error;
  }
  
  Gtk.Widget make_summary_page()
  {
    summary_label = new Gtk.Label("");
    summary_label.set("xalign", 0.0f);
    
    var page = new Gtk.VBox(false, 6);
    page.set("child", summary_label,
             "border-width", 12);
    page.child_set(summary_label, "expand", false);
    
    return page;
  }
  
  void add_restore_dest_page()
  {
    var page = make_restore_dest_page();
    append_page(page);
    child_set(page,
              "title", _("Restore to Where?"),
              "complete", true,
              "header-image", icon);
  }
  
  void add_confirm_page()
  {
    var page = make_confirm_page();
    append_page(page);
    child_set(page,
              "title", _("Summary"),
              "page-type", Gtk.AssistantPageType.CONFIRM,
              "complete", true,
              "header-image", icon);
  }

  void add_progress_page()
  {
    var page = make_progress_page();
    append_page(page);
    child_set(page,
              "title", _("Restoring"),
              "page-type", Gtk.AssistantPageType.PROGRESS,
              "header-image", icon);
    progress_page = page;
  }
  
  void add_summary_page()
  {
    var page = make_summary_page();
    append_page(page);
    child_set(page,
              "title", _("Restore Finished"),
              "page-type", Gtk.AssistantPageType.SUMMARY,
              "complete", true,
              "header-image", icon);
    summary_page = page;
  }
  
  void apply_finished(DejaDup.OperationRestore restore, bool success)
  {
    if (success)
      summary_label.label = _("Your files were successfully restored.");
    // else show_error set label
    
    set_current_page(get_n_pages() - 1); // last, summary page
    
    if (timeout_id > 0) {
      Source.remove(timeout_id);
      timeout_id = 0;
    }
    
    op = null;
  }
  
  void do_apply()
  {
    op = new DejaDup.OperationRestore(this, restore_location);
    op.done += apply_finished;
    op.raise_error += show_error;
    op.action_desc_changed += set_progress_label;
    
    try {
      op.start();
    }
    catch (Error e) {
      warning("%s\n", e.message);
      show_error(op, e.message, null); // not really user-friendly text, but ideally this won't happen
      apply_finished(op, false);
    }
  }
  
  void do_prepare(RestoreAssistant assist, Gtk.Widget page)
  {
    if (page == progress_page)
      timeout_id = Timeout.add(200, pulse);
  }
  
  void do_cancel()
  {
    if (op != null)
      op.cancel();
    destroy();
  }
  
  void do_close()
  {
    destroy();
  }
}

