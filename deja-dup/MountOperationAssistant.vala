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

/**
 * This class can be used by backends in one of two ways:
 * 1) Traditional way, by having this ask the user for info and then sending
 *    a reply signal.
 * 2) Or by driving the authentication themselves in some secret way.  If so,
 *    they will ask for a button to be shown to start the authentication.
 *    When they are done, they will set the 'go_forward' property to true.
 *    This is used by the U1 backend.
 */

public class MountOperationAssistant : MountOperation
{
  public string label_button {get; set;}
  public string label_help {get; set;}
  public string label_title {get; set; default = _("Connect to Server");}
  public string label_username {get; set; default = _("_Username");}
  public string label_password {get; set; default = _("_Password");}
  public string label_show_password {get; set; default = _("S_how password");}
  public string label_remember_password {get; set; default = _("_Remember password");}
  public bool go_forward {get; set; default = false;} // set by backends if they want to move on

  signal void button_clicked();

  public AssistantOperation assist {get; construct;}
  Gtk.Bin password_page;
  Gtk.Box layout;
  Gtk.Grid table;
  Gtk.RadioButton anonymous_w;
  Gtk.CheckButton remember_w;
  Gtk.Entry username_w;
  Gtk.Entry domain_w;
  Gtk.Entry password_w;
  bool looping = false;

  public MountOperationAssistant(AssistantOperation assist)
  {
    Object(assist: assist);
    assist.prepare.connect(do_prepare);
    assist.backward.connect(do_backward);
    assist.forward.connect(do_forward);
    assist.closing.connect(do_close);
    add_password_page();

    assist.realize();
  }

  construct {
    Signal.connect(this, "notify::go-forward", (Callback)go_forward_changed, this);
  }

  static void go_forward_changed(MountOperationAssistant mop)
  {
    if (mop.go_forward)
      mop.assist.go_forward();      
  }

  public override void aborted()
  {
    assist.show_error(_("Location not available"), null);
  }

  public override void ask_password(string message, string default_user,
                                    string default_domain, AskPasswordFlags flags)
  {
    flesh_out_password_page(message, default_user, default_domain, flags);
    assist.interrupt(password_page);
    looping = true;
    check_valid_inputs();
    assist.set_header_icon(Gtk.Stock.DIALOG_AUTHENTICATION);
    assist.force_visible(false);
    Gtk.main(); // enter new loop so that we don't return until user hits next
  }

  public override void ask_question(string message,
                                    [CCode (array_length = false)] string[] choices)
  {
    // Rather than implement this code right now (not sure if/when it's ever
    // called to mount something), we just outsource to normal GtkMountOp.
    var t = new Gtk.MountOperation(assist);
    t.reply.connect((t, r) => {
      choice = t.choice;
      send_reply(r);
    });
    looping = true;
    t.ask_question(message, choices);
    Gtk.main(); // enter new loop so that we don't return until user hits next
  }

  void add_password_page()
  {
    var page = new Gtk.EventBox();
    assist.append_page(page, Assistant.Type.INTERRUPT);
    password_page = page;
  }

  void flesh_out_password_page(string message, string default_user,
                               string default_domain, AskPasswordFlags flags)
  {
    if (layout != null)
      DejaDup.destroy_widget(layout);

    layout = new Gtk.Box(Gtk.Orientation.VERTICAL, 6);
    layout.set("border-width", 12);

    table = new Gtk.Grid();
    table.set("row-spacing", 6,
              "column-spacing", 6);

    password_page.add(layout);

    int rows = 0;
    int ucol = 0;
    Gtk.Label label;

    // Display user message
    assist.set_page_title(password_page, label_title);

    label = new Gtk.Label(message);
    label.xalign = 0.0f;
    label.wrap = true;
    label.max_width_chars = 25;
    layout.pack_start(label, false, false, 0);

    if (label_help != null) {
      label = new Gtk.Label(label_help);
      label.use_markup = true;
      label.track_visited_links = false;
      label.set("xalign", 0f);
      layout.pack_start(label, false, false, 0);
    }

    // Buffer
    label = new Gtk.Label("");
    layout.pack_start(label, false, false, 0);

    if (label_button != null) {
      var alignment = new Gtk.Alignment(0.5f, 0.5f, 0, 0);
      var button = new Gtk.Button.with_mnemonic(label_button);
      button.clicked.connect(() => {button_clicked();});
      alignment.add(button);
      layout.pack_start(alignment, false, false, 0);
    }

    if ((flags & AskPasswordFlags.ANONYMOUS_SUPPORTED) != 0) {
      anonymous_w = new Gtk.RadioButton.with_mnemonic(null, _("Connect _anonymously"));
      anonymous_w.toggled.connect((b) => {check_valid_inputs();});
      layout.pack_start(anonymous_w, false, false, 0);

      var w = new Gtk.RadioButton.with_mnemonic_from_widget(anonymous_w, _("Connect as u_ser"));
      anonymous_w.toggled.connect((b) => {
        table.sensitive = !b.active;
      });
      table.sensitive = false; // starts inactive
      layout.pack_start(w, false, false, 0);

      var hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
      hbox.pack_start(new Gtk.Label("    "), false, false, 0);
      hbox.pack_start(table, true, true, 0);
      layout.pack_start(hbox, false, false, 0);

      ucol = 1;
    }
    else {
      anonymous_w = null;
      layout.pack_start(table, false, false, 0);
    }

    if ((flags & AskPasswordFlags.NEED_USERNAME) != 0) {
      username_w = new Gtk.Entry();
      username_w.set("activates-default", true,
                     "text", default_user);
      username_w.hexpand = true;
      username_w.changed.connect((e) => {check_valid_inputs();});
      label = new Gtk.Label(label_username);
      label.set("mnemonic-widget", username_w,
                "use-underline", true,
                "xalign", 1.0f);
      table.attach(label, ucol, rows, 1, 1);
      table.attach(username_w, ucol+1, rows, 2-ucol, 1);
      ++rows;
    }
    else
      username_w = null;

    if ((flags & AskPasswordFlags.NEED_DOMAIN) != 0) {
      domain_w = new Gtk.Entry();
      domain_w.set("activates-default", true,
                   "text", default_domain);
      domain_w.hexpand = true;
      domain_w.changed.connect((e) => {check_valid_inputs();});
      // Translators: this is a Windows networking domain
      label = new Gtk.Label(_("_Domain"));
      label.set("mnemonic-widget", domain_w,
                "use-underline", true,
                "xalign", 1.0f);
      table.attach(label, ucol, rows, 1, 1);
      table.attach(domain_w, ucol+1, rows, 2-ucol, 1);
      ++rows;
    }
    else
      domain_w = null;

    if ((flags & AskPasswordFlags.NEED_PASSWORD) != 0) {
      password_w = new Gtk.Entry();
      password_w.set("visibility", false,
                     "activates-default", true);
      password_w.hexpand = true;
      label = new Gtk.Label(label_password);
      label.set("mnemonic-widget", password_w,
                "use-underline", true,
                "xalign", 1.0f);
      table.attach(label, ucol, rows, 1, 1);
      table.attach(password_w, ucol+1, rows, 2-ucol, 1);
      ++rows;

      var w = new Gtk.CheckButton.with_mnemonic(label_show_password);
      ((Gtk.CheckButton)w).toggled.connect((button) => {
        password_w.visibility = button.get_active();
      });
      table.attach(w, ucol+1, rows, 2-ucol, 1);
      ++rows;
    }
    else
      password_w = null;

    if ((flags & AskPasswordFlags.SAVING_SUPPORTED) != 0) {
      remember_w = new Gtk.CheckButton.with_mnemonic(label_remember_password);
      table.attach(remember_w, ucol+1, rows, 2-ucol, 1);
      ++rows;
    }
    else
      remember_w = null;

    password_page.show_all();
  }

  bool is_valid_entry(Gtk.Entry? e)
  {
    return e == null || (e.text != null && e.text != "");
  }

  bool is_anonymous()
  {
    return anonymous_w != null && anonymous_w.active;
  }

  void check_valid_inputs()
  {
    var valid = is_anonymous() ||
                (is_valid_entry(username_w) &&
                 is_valid_entry(domain_w));
    if (label_button != null)
      valid = false; // buttons are used for backend-driven authentication
    assist.allow_forward(valid);
  }

  void send_reply(MountOperationResult result)
  {
    if (looping) {
      Gtk.main_quit();
      looping = false;
      reply(result);
    }
  }

  void do_close(AssistantOperation op, bool success)
  {
    send_reply(MountOperationResult.ABORTED);
  }

  void do_backward(Assistant assist)
  {
    send_reply(MountOperationResult.ABORTED);
  }

  void do_forward(Assistant assist)
  {
  }

  void do_prepare(Assistant assist, Gtk.Widget page)
  {
    if (looping) {
      // This signal happens before a prepare, when going forward
      if (username_w != null) {
        var txt = username_w.get_text();
        username = txt.strip();
      }
      if (domain_w != null) {
        var txt = domain_w.get_text();
        domain = txt.strip();
      }
      if (password_w != null) {
        var txt = password_w.get_text();
        password = txt.strip();
      }
      if (anonymous_w != null)
        anonymous = anonymous_w.get_active();
      if (remember_w != null)
        password_save = remember_w.get_active() ? PasswordSave.PERMANENTLY : PasswordSave.NEVER;
      send_reply(MountOperationResult.HANDLED);
    }
  }
}
