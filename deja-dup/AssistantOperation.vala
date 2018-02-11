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

public abstract class AssistantOperation : Assistant
{
  /*
   * Abstract class for implementation of various common pages in assistant
   *
   * Abstract class that provides various methods that serve as pages in
   * assistant. Required methods that all classes that inherit from this
   * class must implement are create_op, make_confirm_page and
   * get_progress_file_prefix.
   *
   * Pages are shown in the following order:
   * 1. (Optional) Custom configuration pages
   * 2. Setup pages
   * 3. Confirmation page
   * 4. Password page
   * 5. Question page
   * 6. (Required) Progress page
   * 7. Summary
   */
  protected Gtk.Widget confirm_page {get; private set;}
  public signal void closing(bool success);
  
  public bool automatic {get; construct; default = false;}
  protected StatusIcon status_icon;
  protected bool succeeded = false;

  protected Gtk.Widget backend_install_page {get; private set;}
  Gtk.Label backend_install_desc;
  Gtk.Label backend_install_packages;
  Gtk.ProgressBar backend_install_progress;

  Gtk.Entry nag_entry;
  Gtk.Entry encrypt_entry;
  Gtk.Entry encrypt_confirm_entry;
  Gtk.RadioButton encrypt_enabled;
  Gtk.CheckButton encrypt_remember;
  protected Gtk.Widget password_page {get; private set;}
  protected Gtk.Widget nag_page {get; private set;}
  protected bool nagged;
  List<Gtk.Widget> first_password_widgets;
  MainLoop password_ask_loop;

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
  protected Gtk.Widget detail_widget;
  Gtk.TextView detail_text_view;
  protected Gtk.Widget summary_page {get; private set;}
  
  protected DejaDup.Operation op;
  uint timeout_id;
  protected bool error_occurred {get; private set;}
  bool gives_progress;

  bool searched_for_passphrase = false;

  bool saved_pos;
  int saved_x;
  int saved_y;

  const int LOGS_LINES_TO_KEEP = 10000;
  bool adjustment_at_end = true;

  construct
  {
    add_custom_config_pages();
    add_backend_install_page();
    add_setup_pages();
    add_confirm_page();
    add_password_page();
    add_nag_page();
    add_question_page();
    add_progress_page();
    add_summary_page();
    
    canceled.connect(do_cancel);
    closed.connect(do_close);
    prepare.connect(do_prepare);
    delete_event.connect(do_minimize_to_tray);
  }

  /*
   * Creates confirmation page for particular assistant
   *
   * Creates confirmation page that should create confirm_page widget that
   * is presented for final confirmation.
   */
  protected virtual Gtk.Widget? make_confirm_page() {return null;}
  protected virtual void add_setup_pages() {}
  protected virtual void add_custom_config_pages(){}
  /*
   * Creates and calls appropriate operation
   *
   * Creates and calls appropriate operation (Backup, Restore, Status, Files)
   * that is then used to perform various defined tasks on backend. It is
   * also later connected to various signals.
   */
  protected abstract DejaDup.Operation? create_op();
  protected abstract string get_progress_file_prefix();

  protected abstract string get_apply_text();

  bool pulse()
  {
    if (!gives_progress)
      progress_bar.pulse();
    return true;
  }
  
  void show_progress(DejaDup.Operation op, double percent)
  {
    /*
     * Updates prograss bar
     *
     * Updates progress bar with percet provided.
     */
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
    string prefix;
    if (actual) {
      prefix = get_progress_file_prefix();
      progress_label.label = prefix + " ";
      progress_file_label.label = DejaDup.get_display_name(file);
    }
    else {
      prefix = _("Scanning:");
      progress_label.label = _("Scanning…");
      progress_file_label.label = "";
    }

    string log_line = prefix + " " + file.get_parse_name();

    Gtk.Adjustment adjust = progress_scroll.get_vadjustment();
    if (adjust.value >= adjust.upper - adjust.page_size ||
        adjust.page_size == 0 || // means never been set, means not realized
        !progress_expander.expanded)
      adjustment_at_end = true;

    var buffer = progress_text.buffer;
    if (buffer.get_char_count() > 0)
      log_line = "\n" + log_line;

    Gtk.TextIter iter;
    buffer.get_end_iter(out iter);
    buffer.insert_text(ref iter, log_line, (int)log_line.length);

    if (buffer.get_line_count() >= LOGS_LINES_TO_KEEP && adjustment_at_end) {
      // If we're watching text scroll by, don't keep everything in memory
      Gtk.TextIter start, cutoff;
      buffer.get_start_iter(out start);
      buffer.get_iter_at_line(out cutoff, buffer.get_line_count() - LOGS_LINES_TO_KEEP);
      buffer.delete(ref start, ref cutoff);
    }
  }
  
  protected void set_secondary_label(string text)
  {
    if (text != null && text != "") {
      secondary_label.label = "<i>" + text + "</i>";
      secondary_label.show();
    }
    else
      secondary_label.hide();
  }

  void update_autoscroll()
  {
    if (adjustment_at_end)
    {
        Gtk.Adjustment adjust = progress_scroll.get_vadjustment();
        adjust.value = adjust.upper - adjust.page_size;
    }
  }

  bool stop_autoscroll()
  {
    Gtk.Adjustment adjust = progress_scroll.get_vadjustment();

    if (adjust.value < adjust.upper - adjust.page_size)
      adjustment_at_end = false;

    return false;
  }

  protected virtual Gtk.Widget make_progress_page()
  {
    var page = new Gtk.Grid();
    page.orientation = Gtk.Orientation.VERTICAL;
    page.row_spacing = 6;

    int row = 0;

    progress_label = new Gtk.Label("");
    progress_label.xalign = 0.0f;

    progress_file_label = new Gtk.Label("");
    progress_file_label.xalign = 0.0f;
    progress_file_label.ellipsize = Pango.EllipsizeMode.MIDDLE;
    progress_file_label.hexpand = true;

    page.attach(progress_label, 0, row, 1, 1);
    page.attach(progress_file_label, 1, row, 1, 1);
    ++row;

    secondary_label = new Gtk.Label("");
    secondary_label.xalign = 0.0f;
    secondary_label.wrap = true;
    secondary_label.max_width_chars = 30;
    secondary_label.no_show_all = true;
    secondary_label.use_markup = true;
    page.attach(secondary_label, 0, row, 2, 1);
    ++row;

    progress_bar = new Gtk.ProgressBar();
    page.attach(progress_bar, 0, row, 2, 1);
    ++row;

    progress_text = new Gtk.TextView();
    progress_text.editable = false;
    progress_text.size_allocate.connect(update_autoscroll);
    progress_scroll = new Gtk.ScrolledWindow(null, null);
    progress_scroll.scroll_event.connect(stop_autoscroll);
    ((Gtk.Range)progress_scroll.get_vscrollbar()).change_value.connect(stop_autoscroll);
    progress_scroll.expand = true;
    progress_scroll.child = progress_text;
    progress_scroll.hscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
    progress_scroll.vscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
    progress_scroll.border_width = 0;
    progress_scroll.min_content_height = 200;
    progress_scroll.expand = true;
    progress_expander = new Gtk.Expander.with_mnemonic(_("_Details"));
    progress_expander.child = progress_scroll;
    progress_expander.expand = true;
    page.attach(progress_expander, 0, row, 2, 1);
    ++row;

    page.border_width = 12;

    // Reserve space for details + labels
    page.set_size_request(-1, 200);

    return page;
  }

  void show_detail(string detail)
  {
    page_box.set_size_request(300, 200);
    detail_widget.no_show_all = false;
    detail_widget.show_all();
    detail_text_view.buffer.set_text(detail, -1);
  }

  public virtual void show_error(string error, string? detail)
  {
    error_occurred = true;
    
    summary_label.label = error;
    summary_label.selectable = true;
    
    if (detail != null)
      show_detail(detail);
    
    go_to_page(summary_page);
    set_header_icon("dialog-error");
    page_box.queue_resize();
  }

  protected Gtk.Widget make_backend_install_page()
  {
    int rows = 0;
    Gtk.Label l;

    var page = new Gtk.Grid();
    page.row_spacing = 6;
    page.border_width = 12;

    l = new Gtk.Label(_("In order to continue, the following packages need to be installed:"));
    l.xalign = 0.0f;
    l.max_width_chars = 50;
    l.wrap = true;
    page.attach(l, 0, rows++, 1, 1);
    backend_install_desc = l;

    l = new Gtk.Label("");
    l.halign = Gtk.Align.START;
    l.max_width_chars = 50;
    l.wrap = true;
    l.margin_left = 12;
    l.use_markup = true;
    page.attach(l, 0, rows++, 1, 1);
    backend_install_packages = l;

    backend_install_progress = new Gtk.ProgressBar();
    backend_install_progress.no_show_all = true;
    backend_install_progress.hexpand = true;
    backend_install_progress.hide();
    page.attach(backend_install_progress, 0, rows++, 1, 1);

    return page;
  }

  protected Gtk.Widget make_password_page()
  {
    int rows = 0;
    Gtk.Widget w, label;

    var page = new Gtk.Grid();
    page.set("row-spacing", 6,
             "column-spacing", 6,
             "border-width", 12);

    w = new Gtk.RadioButton.with_mnemonic(null,
                                          _("_Allow restoring without a password"));
    page.attach(w, 0, rows, 3, 1);
    first_password_widgets.append(w);
    ++rows;

    encrypt_enabled = new Gtk.RadioButton.with_mnemonic_from_widget(w as Gtk.RadioButton,
                                                                    _("_Password-protect your backup"));
    encrypt_enabled.active = true; // always default to encrypted
    page.attach(encrypt_enabled, 0, rows, 3, 1);
    first_password_widgets.append(encrypt_enabled);
    encrypt_enabled.toggled.connect(() => {check_password_validity();});
    ++rows;

    w = new Gtk.Label("    "); // indent
    page.attach(w, 0, rows, 1, 1);
    first_password_widgets.append(w);

    w = new Gtk.Label("<i>%s</i>".printf(
      _("You will need your password to restore your files. You might want to write it down.")));
    w.set("xalign", 0.0f,
          "use-markup", true,
          "max-width-chars", 25,
          "wrap", true);
    page.attach(w, 1, rows, 2, 1);
    encrypt_enabled.bind_property("active", w, "sensitive", BindingFlags.SYNC_CREATE);
    first_password_widgets.append(w);
    ++rows;

    w = new Gtk.Entry();
    w.set("input-purpose", Gtk.InputPurpose.PASSWORD,
          "hexpand", true,
          "activates-default", true);
    ((Gtk.Entry)w).changed.connect(() => {check_password_validity();});
    label = new Gtk.Label(_("E_ncryption password"));
    label.set("mnemonic-widget", w,
              "use-underline", true,
              "xalign", 1.0f);
    page.attach(label, 1, rows, 1, 1);
    page.attach(w, 2, rows, 1, 1);
    encrypt_enabled.bind_property("active", w, "sensitive", BindingFlags.SYNC_CREATE);
    encrypt_enabled.bind_property("active", label, "sensitive", BindingFlags.SYNC_CREATE);
    ++rows;
    encrypt_entry = (Gtk.Entry)w;

    // Add a confirmation entry if this is user's first time
    w = new Gtk.Entry();
    w.set("input-purpose", Gtk.InputPurpose.PASSWORD,
          "hexpand", true,
          "activates-default", true);
    ((Gtk.Entry)w).changed.connect(() => {check_password_validity();});
    label = new Gtk.Label(_("Confir_m password"));
    label.set("mnemonic-widget", w,
              "use-underline", true,
              "xalign", 1.0f);
    page.attach(label, 1, rows, 1, 1);
    page.attach(w, 2, rows, 1, 1);
    encrypt_enabled.bind_property("active", w, "sensitive", BindingFlags.SYNC_CREATE);
    encrypt_enabled.bind_property("active", label, "sensitive", BindingFlags.SYNC_CREATE);
    ++rows;
    encrypt_confirm_entry = (Gtk.Entry)w;
    first_password_widgets.append(w);
    first_password_widgets.append(label);

    w = new Gtk.CheckButton.with_mnemonic(_("_Show password"));
    w.bind_property("active", encrypt_entry, "visibility", BindingFlags.SYNC_CREATE);
    w.bind_property("active", encrypt_confirm_entry, "visibility", BindingFlags.SYNC_CREATE);
    page.attach(w, 2, rows, 1, 1);
    encrypt_enabled.bind_property("active", w, "sensitive", BindingFlags.SYNC_CREATE);
    ++rows;

    w = new Gtk.CheckButton.with_mnemonic(_("_Remember password"));
    page.attach(w, 2, rows, 1, 1);
    encrypt_enabled.bind_property("active", w, "sensitive", BindingFlags.SYNC_CREATE);
    ++rows;
    encrypt_remember = (Gtk.CheckButton)w;

    return page;
  }

  protected Gtk.Widget make_nag_page()
  {
    int rows = 0;
    Gtk.Widget w, label;

    var page = new Gtk.Grid();
    page.set("row-spacing", 6,
             "column-spacing", 6,
             "border-width", 12);

    w = new Gtk.Label(_("In order to check that you will be able to retrieve your files in the case of an emergency, please enter your encryption password again to perform a brief restore test."));
    w.set("xalign", 0.0f,
          "max-width-chars", 25,
          "wrap", true);
    page.attach(w, 0, rows, 3, 1);
    w.hide();
    ++rows;

    w = new Gtk.Entry();
    w.set("input-purpose", Gtk.InputPurpose.PASSWORD,
          "hexpand", true,
          "activates-default", true);
    ((Gtk.Entry)w).changed.connect((entry) => {check_nag_validity();});
    label = new Gtk.Label(_("E_ncryption password"));
    label.set("mnemonic-widget", w,
              "use-underline", true,
              "xalign", 1.0f);
    page.attach(label, 1, rows, 1, 1);
    page.attach(w, 2, rows, 1, 1);
    nag_entry = w as Gtk.Entry;
    ++rows;

    w = new Gtk.CheckButton.with_mnemonic(_("_Show password"));
    w.bind_property("active", nag_entry, "visibility", BindingFlags.SYNC_CREATE);
    page.attach(w, 2, rows, 1, 1);
    ++rows;

    w = new Gtk.CheckButton.with_mnemonic(_("Test every two _months"));
    page.attach(w, 0, rows, 3, 1);
    w.hide();
    ((Gtk.CheckButton)w).active = true;
    w.vexpand = true;
    w.valign = Gtk.Align.END;
    ((Gtk.CheckButton)w).toggled.connect((button) => {
      DejaDup.update_nag_time(!button.get_active());
    });
    ++rows;

    return page;
  }

  protected Gtk.Widget make_question_page()
  {
    int rows = 0;

    var page = new Gtk.Grid();
    page.set("row-spacing", 6,
             "column-spacing", 6,
             "border-width", 12);

    var label = new Gtk.Label("");
    label.set("use-underline", true,
              "wrap", true,
              "max-width-chars", 25,
              "hexpand", true,
              "xalign", 0.0f);
    page.attach(label, 0, rows, 1, 1);
    ++rows;
    question_label = label;

    return page;
  }

  protected virtual Gtk.Widget make_summary_page()
  {
    summary_label = new Gtk.Label("");
    summary_label.set("xalign", 0.0f);
    summary_label.wrap = true;
    summary_label.max_width_chars = 25;
    
    detail_text_view = new Gtk.TextView();
    detail_text_view.editable = false;
    detail_text_view.wrap_mode = Gtk.WrapMode.WORD;
    detail_text_view.height_request = 150;

    var scroll = new Gtk.ScrolledWindow(null, null);
    scroll.add(detail_text_view);
    scroll.no_show_all = true; // only will be shown if an error occurs
    detail_widget = scroll;
    
    var page = new Gtk.Box(Gtk.Orientation.VERTICAL, 6);
    page.set("child", summary_label,
             "child", detail_widget,
             "border-width", 12);
    page.child_set(summary_label, "expand", false);
    page.child_set(detail_widget, "expand", true);
    
    return page;
  }

  void add_backend_install_page()
  {
    var page = make_backend_install_page();
    append_page(page, Type.INTERRUPT);
    set_page_title(page, _("Install Packages"));
    backend_install_page = page;
  }

  void add_confirm_page()
  {
    /*
     * Adds confirm page to the sequence of pages
     *
     * Adds confirm_page widget to the sequence of pages in assistant.
     */
    var page = make_confirm_page();
    if (page == null)
      return;
    append_page(page, Type.NORMAL, get_apply_text());
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
    password_page = page;
  }

  void add_nag_page()
  {
    var page = make_nag_page();
    append_page(page, Type.CHECK);
    set_page_title(page, _("Restore Test"));
    nag_page = page;
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
  
  protected virtual void apply_finished(DejaDup.Operation op, bool success, bool cancelled, string? detail)
  {
    if (status_icon != null) {
      status_icon.done(success, cancelled, detail);
      status_icon = null;
    }
    this.op = null;

    if (cancelled) {
      do_close();
    }
    else {
      if (success) {
        succeeded = true;

        if (detail != null) {
          // Expect one paragraph followed by a blank line.  The first paragraph
          // is an explanation before the full detail content.  So split it out
          // into a proper label to look nice.
          var halves = detail.split("\n\n", 2);
          if (halves.length == 1) // no full detail content
            summary_label.label = detail;
          else if (halves.length == 2) {
            summary_label.label = halves[0];
            show_detail(halves[1]);
          }
        }

        go_to_page(summary_page);
      }
      else // show error
        force_visible(false);
    }
  }

  protected void ensure_status_icon(DejaDup.Operation o)
  {
    if (status_icon == null) {
      status_icon = StatusIcon.create(this, o, automatic);
      status_icon.show_window.connect((s, user_click) => {force_visible(user_click);});
    }
  }

  protected async void do_apply()
  {
    /*
     * Applies/starts operation that was configured during assistant process and
     * connect appropriate signals
     *
     * Mounts appropriate backend, creates child operation, connects signals to
     * handler functions and starts operation.
     */
    op = create_op();
    if (op == null) {
      show_error(_("Failed with an unknown error."), null);
      return;
    }

    op.done.connect(apply_finished);
    op.raise_error.connect((o, e, d) => {show_error(e, d);});
    op.passphrase_required.connect(get_passphrase);
    op.action_desc_changed.connect(set_progress_label);
    op.action_file_changed.connect(set_progress_label_file);
    op.progress.connect(show_progress);
    op.question.connect(show_question);
#if HAS_PACKAGEKIT
    op.install.connect(show_install);
#endif
    op.backend.mount_op = new MountOperationAssistant(this);
    op.backend.pause_op.connect(pause_op);

    ensure_status_icon(op);

    op.start.begin();
  }

  protected virtual void do_prepare(Assistant assist, Gtk.Widget page)
  {
    /*
     * Prepare page in assistant
     *
     * Prepares every page in assistant for various operations. For example, if 
     * user returns to confirmation page from progress page, it is necessary
     * to kill running operation. If user advances to progress page, it runs
     * do_apply and runs the needed operation.
     *
     * do_prepare is run when user switches pages and not when pages are built.
     */

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
        provide_password.begin();
      }
      else if (op == null)
        do_apply.begin();
    }
    else if (page == password_page || page == nag_page)
      set_header_icon("dialog-password");
  }

  // Make Deja Dup invisible, used when we are shutting down or some such.
  public void hide_everything()
  {
    hide();
    if (status_icon != null) {
      status_icon.done(false, true, null);
      status_icon = null; // hide immediately to seem responsive
    }
  }

  protected virtual void do_cancel()
  {
    hide_everything();
    if (op != null) {
      op.cancel(); // do_close will happen in done() callback
    }
    else
      do_close();
  }

  bool do_minimize_to_tray(Gdk.EventAny event)
  {
    if (is_interrupted() || op == null)
      do_cancel(); // instead, do the normal cancel operation
    else
      hide_for_now ();

    return true;
  }
  
  protected virtual void do_close()
  {
    if (timeout_id > 0) {
      Source.remove(timeout_id);
      timeout_id = 0;
    }

    closing(succeeded);

    DejaDup.destroy_widget(this);
  }

  public void force_visible(bool user_click)
  {
    show_to_user(this, Gtk.get_current_event_time(), user_click);
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
    else if (!win.is_active || !win.visible) {
      win.urgency_hint = true;
      win.show();
      Idle.add(() => {
        win.focus_in_event.connect(user_focused);
        return false;
      });
    }
  }

  async string? lookup_keyring()
  {
    try {
      return yield Secret.password_lookup(DejaDup.get_passphrase_schema(),
                                          null,
                                          "owner", Config.PACKAGE,
                                          "type", "passphrase");
    }
    catch (Error e) {
      warning("%s\n", e.message);
      return null;
    }
  }

  protected void get_passphrase()
  {
    if (!searched_for_passphrase && !DejaDup.in_testing_mode() &&
        op.use_cached_password) {
      // If we get asked for passphrase again, it is because a
      // saved or entered passphrase didn't work.  So don't bother
      // searching a second time.
      searched_for_passphrase = true;

      string str = null;

      // First, try user's keyring
      var loop = new MainLoop(null);
      lookup_keyring.begin((obj, res) => {
        str = lookup_keyring.end(res);
        loop.quit();
      });
      loop.run();

      // Did we get anything?
      if (str != null) {
        op.set_passphrase(str);
        return;
      }
    }

    ask_passphrase();
  }

  void check_password_validity()
  {
    if (!encrypt_enabled.active) {
      allow_forward(true);
      return;
    }

    var passphrase = encrypt_entry.get_text();
    if (passphrase == "") {
      allow_forward(false);
      return;
    }

    if (encrypt_confirm_entry.visible) {
      var passphrase2 = encrypt_confirm_entry.get_text();
      var valid = (passphrase == passphrase2);
      allow_forward(valid);
    }
    else
      allow_forward(true);
  }

  void configure_password_page(bool first)
  {
    if (first)
      set_page_title(password_page, _("Require Password?"));
    else
      set_page_title(password_page, _("Encryption Password Needed"));

    foreach (Gtk.Widget w in first_password_widgets)
      w.visible = first;

    check_password_validity();
    encrypt_entry.select_region(0, -1);
    encrypt_entry.grab_focus();
  }

  void check_nag_validity()
  {
    var passphrase = nag_entry.get_text();
    if (passphrase == "")
      allow_forward(false);
    else
      allow_forward(true);
  }

  void configure_nag_page()
  {
    check_nag_validity();
    nag_entry.set_text("");
    nag_entry.grab_focus();
  }

  void stop_password_loop(Assistant dlg, int resp)
  {
    Idle.add(() => {
      password_ask_loop.quit();
      password_ask_loop = null;
      return false;
    });
    response.disconnect(stop_password_loop);
  }

  protected void ask_passphrase(bool first = false)
  {
    op.needs_password = true;
    if (op.use_cached_password) {
      interrupt(password_page);
      configure_password_page(first);
    }
    else {
      // interrupt, but stay visible so user can see reassuring message at end
      interrupt(nag_page, true /* can_continue */, true /* stay_visible */);
      configure_nag_page();
      nagged = true;
    }
    force_visible(false);
    // pause until we can provide password by entering new main loop
    password_ask_loop = new MainLoop(null);
    response.connect(stop_password_loop);
    password_ask_loop.run();
  }

  protected async void provide_password()
  {
    var passphrase = "";

    if (op.use_cached_password) {
      if (encrypt_enabled.active) {
        passphrase = encrypt_entry.get_text().strip();
        if (passphrase == "") // all whitespace password?  allow it...
          passphrase = encrypt_entry.get_text();
      }

      if (passphrase != "") {
        // Save it
        if (encrypt_remember.active) {
          try {
            yield Secret.password_store(DejaDup.get_passphrase_schema(),
                                        Secret.COLLECTION_DEFAULT,
                                        _("Backup encryption password"),
                                        passphrase,
                                        null,
                                        "owner", Config.PACKAGE,
                                        "type", "passphrase");
          }
          catch (Error e) {
            warning("%s\n", e.message);
          }
        }
      }
    }
    else {
      passphrase = nag_entry.get_text().strip();
      if (passphrase == "") // all whitespace password?  allow it...
        passphrase = nag_entry.get_text();
    }

    op.set_passphrase(passphrase);
  }

  void stop_question(Assistant dlg, int resp)
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

#if HAS_PACKAGEKIT
  async void start_install(string[] package_ids, MainLoop loop)
  {
    backend_install_desc.hide();
    backend_install_packages.hide();
    backend_install_progress.show();

    try {
      var client = new Pk.Client();
      yield client.install_packages_async(0, package_ids, null, (p, t) => {
        backend_install_progress.fraction = (p.percentage / 100.0).clamp(0, 100);
      });
    }
    catch (Error e) {
      show_error("%s".printf(e.message), null);
      return;
    }

    go_forward();
    loop.quit();
  }

  protected void show_install(DejaDup.Operation op, string[] names, string[] ids)
  {
    var text = "";
    foreach (string s in names) {
      if (text != "")
        text += ", ";
      text += "<b>%s</b>".printf(s);
    }
    backend_install_packages.label = text;

    interrupt(backend_install_page, false);
    set_header_icon("system-software-install");
    var install_button = add_button(C_("verb", "_Install"), CUSTOM_RESPONSE);
    var loop = new MainLoop(null);
    install_button.clicked.connect(() => {start_install.begin(ids, loop);});
    forward_button = install_button;
    force_visible(false);

    loop.run();
  }
#endif

  protected void pause_op(DejaDup.Backend back, string? header, string? msg)
  {
    // Basically a question without a response expected
    if (header == null) // unpause
      go_forward();
    else {
      set_page_title(question_page, header);
      question_label.label = msg;
      interrupt(question_page, false);
      force_visible(false);
    }
  }
}

