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

public abstract class AssistantOperation : Gtk.Assistant
{
  protected Gtk.Widget confirm_page {get; private set;}
  
  Gtk.Label progress_label;
  Gtk.Label progress_file_label;
  Gtk.ProgressBar progress_bar;
  protected Gtk.Widget progress_page {get; private set;}
  
  protected Gtk.Label summary_label;
  Gtk.Widget error_widget;
  Gtk.TextView error_text_view;
  protected Gtk.Widget summary_page {get; private set;}
  
  protected Gdk.Pixbuf icon {get; private set;}
  DejaDup.Operation op;
  uint timeout_id;
  protected bool error_occurred {get; private set;}
  bool gives_progress;
  
  construct
  {
    icon = get_op_icon();
    
    add_setup_pages();
    add_confirm_page();
    add_progress_page();
    add_summary_page();
    
    apply += do_apply;
    cancel += do_cancel;
    close += do_close;
    prepare += do_prepare;
  }
  
  protected abstract Gtk.Widget make_confirm_page();
  protected abstract void add_setup_pages();
  protected abstract DejaDup.Operation create_op();
  protected abstract string get_progress_file_prefix();
  protected abstract Gdk.Pixbuf? get_op_icon();
  
  bool pulse()
  {
    if (!gives_progress)
      progress_bar.pulse();
    return true;
  }
  
  void show_progress(DejaDup.Operation op, double percent)
  {
    progress_bar.fraction = percent;
    gives_progress = true;
  }
  
  void set_progress_label(DejaDup.Operation op, string label)
  {
    progress_label.label = label;
  }
  
  void set_progress_label_file(DejaDup.Operation op, File file)
  {
    var parse_name = file.get_parse_name();
    var basename = Path.get_basename(parse_name);
    progress_label.label = get_progress_file_prefix() + " ";
    progress_file_label.label = "'%s'".printf(basename);
  }
  
  protected virtual Gtk.Widget make_progress_page()
  {
    progress_label = new Gtk.Label("");
    progress_label.set("xalign", 0.0f);
    
    progress_file_label = new Gtk.Label("");
    progress_file_label.set("xalign", 0.0f,
                            "ellipsize", Pango.EllipsizeMode.MIDDLE);
    
    var progress_hbox = new Gtk.HBox(false, 0);
    progress_hbox.set("child", progress_label,
                      "child", progress_file_label);
    progress_hbox.child_set(progress_label, "expand", false);
    
    progress_bar = new Gtk.ProgressBar();
    
    var page = new Gtk.VBox(false, 6);
    page.set("child", progress_hbox,
             "child", progress_bar,
             "border-width", 12);
    page.child_set(progress_hbox, "expand", false);
    page.child_set(progress_bar, "expand", false);
    
    return page;
  }
  
  protected virtual void show_error(DejaDup.Operation op, string error, string? detail)
  {
    error_occurred = true;
    
    // Try to show nice error icon
    try {
      var pixbuf = Gtk.IconTheme.get_default().load_icon(
                     Gtk.STOCK_DIALOG_ERROR, 48, 
                     Gtk.IconLookupFlags.FORCE_SIZE);
      child_set(summary_page,
                "header-image", pixbuf);
    }
    catch (Error e) {
      // Eh, don't worry about it
    }
    
    summary_label.label = error;
    summary_label.wrap = true;
    summary_label.selectable = true;
    
    if (detail != null) {
      error_widget.no_show_all = false;
      error_widget.show_all();
      error_text_view.buffer.set_text(detail, -1);
    }
    
    set_current_page(get_n_pages() - 1); // last, summary page
  }
  
  protected virtual Gtk.Widget make_summary_page()
  {
    summary_label = new Gtk.Label("");
    summary_label.set("xalign", 0.0f);
    
    error_text_view = new Gtk.TextView();
    error_text_view.editable = false;
    error_text_view.wrap_mode = Gtk.WrapMode.WORD;
    error_text_view.height_request = 150;

    var scroll = new Gtk.ScrolledWindow(null, null);
    scroll.add(error_text_view);
    scroll.no_show_all = true; // only will be shown if an error occurs
    error_widget = scroll;
    
    var page = new Gtk.VBox(false, 6);
    page.set("child", summary_label,
             "child", error_widget,
             "border-width", 12);
    page.child_set(summary_label, "expand", false);
    
    return page;
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
    confirm_page = page;
  }

  void add_progress_page()
  {
    var page = make_progress_page();
    append_page(page);
    // We don't actually use a PROGRESS type for this page, because that
    // doesn't allow for cancelling.
    child_set(page,
              "page-type", Gtk.AssistantPageType.CONTENT,
              "header-image", icon);
    progress_page = page;
  }
  
  void add_summary_page()
  {
    var page = make_summary_page();
    append_page(page);
    child_set(page,
              "page-type", Gtk.AssistantPageType.SUMMARY,
              "complete", true,
              "header-image", icon);
    summary_page = page;
  }
  
  void apply_finished(DejaDup.Operation op, bool success)
  {
    this.op = null;
    
    if (success) {
      set_current_page(get_n_pages() - 1); // last, summary page
    }
    else if (!error_occurred) {
      // was cancelled...  Close dialog
      do_cancel();
    }
  }
  
  void do_apply()
  {
    op = create_op();
    op.done += apply_finished;
    op.raise_error += show_error;
    op.action_desc_changed += set_progress_label;
    op.action_file_changed += set_progress_label_file;
    op.progress += show_progress;
    
    try {
      op.start();
    }
    catch (Error e) {
      warning("%s\n", e.message);
      show_error(op, e.message, null); // not really user-friendly text, but ideally this won't happen
      apply_finished(op, false);
    }
  }
  
  protected virtual void do_prepare(AssistantOperation assist, Gtk.Widget page)
  {
    if (timeout_id > 0) {
      Source.remove(timeout_id);
      timeout_id = 0;
    }
    
    if (page == confirm_page) {
      if (op != null) {
        op.done -= apply_finished;
        op.cancel(); // in case we just went back from progress page
      }
    }
    else if (page == progress_page) {
      progress_bar.fraction = 0;
      timeout_id = Timeout.add(250, pulse);
    }
  }
  
  void do_cancel()
  {
    if (op != null)
      op.cancel();
    do_close();
  }
  
  void do_close()
  {
    if (timeout_id > 0) {
      Source.remove(timeout_id);
      timeout_id = 0;
    }
    
    destroy();
  }
}
