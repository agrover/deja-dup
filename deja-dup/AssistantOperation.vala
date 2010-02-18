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

public abstract class AssistantOperation : Assistant
{
  protected Gtk.Widget confirm_page {get; private set;}
  public signal void closing(bool success);
  
  public bool automatic {get; construct; default = false;}
  StatusIcon status_icon;
  protected bool succeeded = false;

  Gtk.Entry encrypt_entry;
  Gtk.CheckButton encrypt_remember;
  protected Gtk.Widget password_page {get; private set;}

  Gtk.Label question_label;
  protected Gtk.Widget question_page {get; private set;}

  Gtk.Label progress_label;
  Gtk.Label progress_file_label;
  Gtk.Label secondary_label;
  Gtk.ProgressBar progress_bar;
  Gtk.TextView progress_text;
  Gtk.ScrolledWindow progress_scroll;
  Gtk.Expander progress_expander;
  protected Gtk.Widget progress_page {get; private set;}
  
  protected Gtk.Label summary_label;
  Gtk.Widget error_widget;
  Gtk.TextView error_text_view;
  protected Gtk.Widget summary_page {get; private set;}
  
  protected Gdk.Pixbuf op_icon {get; private set;}
  protected DejaDup.Operation op;
  uint timeout_id;
  protected bool error_occurred {get; private set;}
  bool gives_progress;

  bool saved_pos;
  int saved_x;
  int saved_y;

  protected MountOperation mount_op;
  
  construct
  {
    set_op_icon_name();
    op_icon = make_op_icon();
    header_icon.pixbuf = op_icon;

    add_config_pages_if_needed();
    add_setup_pages();
    add_confirm_page();
    add_password_page();
    add_question_page();
    add_progress_page();
    add_summary_page();
    
    canceled.connect(do_cancel);
    closed.connect(do_close);
    prepare.connect(do_prepare);
  }
  
  protected abstract Gtk.Widget? make_confirm_page();
  protected virtual void add_setup_pages() {}
  protected virtual void add_custom_config_pages() {}
  protected abstract DejaDup.Operation create_op();
  protected abstract string get_progress_file_prefix();
  protected virtual void set_op_icon_name() {}

  protected Gdk.Pixbuf? make_op_icon()
  {
    if (this.icon_name == null)
      return null;
    try {
      var theme = Gtk.IconTheme.get_for_screen(get_screen());
      return theme.load_icon(this.icon_name, 48,
                             Gtk.IconLookupFlags.FORCE_SIZE);
    }
    catch (Error e) {
      warning("%s\n", e.message);
      return null;
    }
  }
  
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
    progress_file_label.label = "";
  }
  
  void set_progress_label_file(DejaDup.Operation op, File file, bool actual)
  {
    var parse_name = file.get_parse_name();
    string prefix;
    if (actual) {
      prefix = get_progress_file_prefix();
      progress_label.label = prefix + " ";
      progress_file_label.label = Path.get_basename(parse_name);
    }
    else {
      prefix = _("Scanning:");
      progress_label.label = _("Scanning…");
      progress_file_label.label = "";
    }

    string log_line = prefix + " " + parse_name;

    bool adjustment_at_end = false;
    Gtk.Adjustment adjust = progress_text.vadjustment;
    if (adjust.value >= adjust.upper - adjust.page_size ||
        adjust.page_size == 0 || // means never been set, means not realized
        !progress_expander.expanded)
      adjustment_at_end = true;

    var buffer = progress_text.buffer;
    if (buffer.get_char_count() > 0)
      log_line = "\n" + log_line;
    if (buffer.get_line_count() >= 100 && adjustment_at_end) {
      // If we're watching text scroll by, save memory by only keeping last 100 lines
      Gtk.TextIter start, line100;
      buffer.get_start_iter(out start);
      buffer.get_iter_at_line(out line100, buffer.get_line_count() - 100);
      buffer.delete(start, line100);
    }
    
    Gtk.TextIter iter;
    buffer.get_end_iter(out iter);
    buffer.insert_text(iter, log_line, (int)log_line.size());
    if (adjustment_at_end)
      adjust.value = adjust.upper;
  }
  
  void set_secondary_label(DejaDup.Operation op, string text)
  {
    Gtk.VBox page = (Gtk.VBox)progress_page;
    if (text != null && text != "") {
      secondary_label.label = "<i>" + text + "</i>";
      secondary_label.show();
      page.add(secondary_label);
      page.reorder_child(secondary_label, 1);
      page.child_set(secondary_label, "expand", false);
    }
    else
      page.remove(secondary_label);
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
    
    secondary_label = new Gtk.Label("");
    secondary_label.set("xalign", 0.0f,
                        "wrap", true,
                        "use-markup", true);
    
    progress_text = new Gtk.TextView();
    progress_text.editable = false;
    progress_scroll = new Gtk.ScrolledWindow(null, null);
    progress_scroll.set("child", progress_text,
                        "hscrollbar-policy", Gtk.PolicyType.AUTOMATIC,
                        "vscrollbar-policy", Gtk.PolicyType.AUTOMATIC,
                        "border-width", 0);
    progress_expander = new Gtk.Expander.with_mnemonic(_("_Details"));
    progress_expander.set("child", progress_scroll);
    
    var page = new Gtk.VBox(false, 6);
    page.set("child", progress_hbox,
             "child", progress_bar,
             "child", progress_expander,
             "border-width", 12);
    page.child_set(progress_hbox, "expand", false);
    page.child_set(progress_bar, "expand", false);
    
    return page;
  }
  
  public virtual void show_error(string error, string? detail)
  {
    error_occurred = true;
    
    summary_label.label = error;
    summary_label.wrap = true;
    summary_label.selectable = true;
    
    if (detail != null) {
      page_box.set_size_request(300, 200);
      error_widget.no_show_all = false;
      error_widget.show_all();
      error_text_view.buffer.set_text(detail, -1);
    }
    
    go_to_page(summary_page);
    set_header_icon(Gtk.STOCK_DIALOG_ERROR);
    page_box.queue_resize();
  }

  protected Gtk.Widget make_password_page()
  {
    int rows = 0;
    Gtk.Widget w, label;

    var page = new Gtk.Table(rows, 2, false);
    page.set("row-spacing", 6,
             "column-spacing", 6,
             "border-width", 12);

    w = new Gtk.Entry();
    w.set("visibility", false,
          "activates-default", true);
    label = new Gtk.Label(_("E_ncryption password:"));
    label.set("mnemonic-widget", w,
              "use-underline", true,
              "xalign", 0.0f);
    page.attach(label, 0, 1, rows, rows + 1, Gtk.AttachOptions.FILL, Gtk.AttachOptions.FILL, 0, 0);
    page.attach(w, 1, 2, rows, rows + 1, Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND, Gtk.AttachOptions.FILL, 0, 0);
    ++rows;
    encrypt_entry = (Gtk.Entry)w;

    w = new Gtk.CheckButton.with_mnemonic(_("_Show password"));
    ((Gtk.CheckButton)w).toggled.connect((button) => {
      encrypt_entry.visibility = button.get_active();
    });
    page.attach(w, 0, 2, rows, rows + 1, Gtk.AttachOptions.FILL, Gtk.AttachOptions.FILL, 0, 0);
    ++rows;

    w = new Gtk.CheckButton.with_mnemonic(_("_Remember password"));
    page.attach(w, 0, 2, rows, rows + 1, Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND, Gtk.AttachOptions.FILL, 0, 0);
    ++rows;
    encrypt_remember = (Gtk.CheckButton)w;

    return page;
  }

  protected Gtk.Widget make_question_page()
  {
    int rows = 0;

    var page = new Gtk.Table(rows, 2, false);
    page.set("row-spacing", 6,
             "column-spacing", 6,
             "border-width", 12);

    var label = new Gtk.Label("");
    label.set("use-underline", true,
              "wrap", true,
              "xalign", 0.0f);
    page.attach(label, 0, 1, rows, rows + 1, Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND, Gtk.AttachOptions.FILL, 0, 0);
    ++rows;
    question_label = label;

    return page;
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
  
  void add_config_pages_if_needed()
  {
    var client = DejaDup.get_gconf_client();
    string val;
    try {
      val = client.get_string(DejaDup.LAST_RUN_KEY);
      if (val != null && val != "")
        return;
    }
    catch (Error e) {
      warning("%s\n", e.message);
      return;
    }
    
    add_custom_config_pages();
  }
  
  void add_confirm_page()
  {
    var page = make_confirm_page();
    if (page == null)
      return;
    append_page(page, Type.SUMMARY);
    set_page_title(page, _("Summary"));
    confirm_page = page;
  }

  void add_progress_page()
  {
    var page = make_progress_page();
    append_page(page, Type.PROGRESS);
    progress_page = page;
  }

  void add_password_page()
  {
    var page = make_password_page();
    append_page(page, Type.INTERRUPT);
    set_page_title(page, _("Password needed"));
    password_page = page;
  }

  void add_question_page()
  {
    var page = make_question_page();
    append_page(page, Type.INTERRUPT);
    question_page = page;
  }

  void add_summary_page()
  {
    var page = make_summary_page();
    append_page(page, Type.FINISH);
    summary_page = page;
  }
  
  void apply_finished(DejaDup.Operation op, bool success, bool cancelled)
  {
    status_icon = null;
    this.op = null;

    if (cancelled) {
      if (success) // stop (resume later) vs cancel
        Gtk.main_quit();
      else
        do_close();
    }
    else {
      if (success) {
        succeeded = true;
        go_to_page(summary_page);
      }
      else // show error
        force_visible(false);
    }
  }
  
  void do_apply()
  {
    if (mount_op == null)
      mount_op = new MountOperationAssistant(this);

    op = create_op();
    op.done.connect(apply_finished);
    op.raise_error.connect((o, e, d) => {show_error(e, d);});
    op.passphrase_required.connect(get_passphrase);
    op.action_desc_changed.connect(set_progress_label);
    op.action_file_changed.connect(set_progress_label_file);
    op.progress.connect(show_progress);
    op.question.connect(show_question);
    op.secondary_desc_changed.connect(set_secondary_label);
    op.backend.mount_op = mount_op;
    op.backend.pause_op.connect(pause_op);
    
    status_icon = new StatusIcon(this, op, automatic);
    status_icon.toggle_window.connect((s) => {toggle_window(0, true);});
    status_icon.hide_all.connect((s) => {hide_everything();});

    try {
      op.start();
    }
    catch (Error e) {
      warning("%s\n", e.message);
      show_error(e.message, null); // not really user-friendly text, but ideally this won't happen
      apply_finished(op, false, false);
    }
  }

  protected virtual void do_prepare(Assistant assist, Gtk.Widget page)
  {
    if (timeout_id > 0) {
      Source.remove(timeout_id);
      timeout_id = 0;
    }
    
    if (page == confirm_page) {
      if (op != null) {
        op.done.disconnect(apply_finished);
        op.cancel(); // in case we just went back from progress page
        op = null;
      }
    }
    else if (page == progress_page) {
      progress_bar.fraction = 0;
      timeout_id = Timeout.add(250, pulse);
      if (op != null && op.needs_password) {
        // Operation is waiting for password
        provide_password();
      }
      else if (op == null)
        do_apply();
    }
    else if (page == password_page)
      set_header_icon(Gtk.STOCK_DIALOG_AUTHENTICATION);
  }
  
  public void hide_everything()
  {
    hide();
    status_icon = null; // hide immediately to seem responsive
  }

  void do_cancel()
  {
    hide_everything();
    if (op != null)
      op.cancel(); // do_close will happen in done() callback
    else
      do_close();
  }
  
  protected virtual void do_close()
  {
    if (timeout_id > 0) {
      Source.remove(timeout_id);
      timeout_id = 0;
    }

    closing(succeeded);

    Idle.add(() => {destroy(); return false;});
  }

  public void force_visible(bool user_click)
  {
    if (!visible)
      toggle_window(0, user_click);
    else
      show_to_user(this, 0, user_click);
  }

  bool user_focused(Gtk.Widget win, Gdk.EventFocus e)
  {
    ((Gtk.Window)win).urgency_hint = false;
    win.focus_in_event.disconnect(user_focused);
    return false;
  }

  void show_to_user(Gtk.Window win, uint time, bool user_click)
  {
    win.focus_on_map = user_click;
    if (saved_pos)
      win.move(saved_x, saved_y);
    if (user_click)
      win.present_with_time(time);
    else if (!win.is_active) {
      win.urgency_hint = true;
      win.focus_in_event.connect(user_focused);
      win.show();
    }
  }

  void toggle_window(uint time, bool user_click)
  {
    var will_hide = this.visible;

    if (time == 0)
      time = Gtk.get_current_event_time();

    if (will_hide) {
      saved_pos = true;
      get_position(out saved_x, out saved_y);
      hide();
    }
    else
      show_to_user(this, time, user_click);
  }

  void found_passphrase(GnomeKeyring.Result result, string? str)
  {
    if (str != null)
      op.continue_with_passphrase(str);
    else
      ask_passphrase();
  }

  protected void get_passphrase()
  {
    // First, try user's keyring
    GnomeKeyring.find_password(PASSPHRASE_SCHEMA,
                               found_passphrase,
                               "owner", Config.PACKAGE,
                               "type", "passphrase");
  }

  void save_password_callback(GnomeKeyring.Result result)
  {
  }

  void ask_passphrase()
  {
    interrupt(password_page);
    force_visible(false);
  }

  protected void provide_password()
  {
    var passphrase = encrypt_entry.get_text();
    passphrase = passphrase.strip();
    
    if (passphrase != "") {
      // Save it
      if (encrypt_remember.active) {
        GnomeKeyring.store_password(PASSPHRASE_SCHEMA,
                                    GnomeKeyring.DEFAULT,
                                    _("Déjà Dup backup passphrase"),
                                    passphrase, save_password_callback,
                                    "owner", Config.PACKAGE,
                                    "type", "passphrase");
      }
    }
    
    op.continue_with_passphrase(passphrase);
  }

  void stop_question(Gtk.Dialog dlg, int resp)
  {
    Gtk.main_quit();
    response.disconnect(stop_question);
  }

  void show_question(DejaDup.Operation op, string title, string message)
  {
    set_page_title(question_page, title);
    question_label.label = message;
    interrupt(question_page);
    force_visible(false);
    response.connect(stop_question);
    Gtk.main();
  }

  void pause_op(DejaDup.Backend back, string header, string msg)
  {
    // Basically a question without a response expected
    set_page_title(question_page, header);
    question_label.label = msg;
    interrupt(question_page, false);
    force_visible(false);
  }
}

