/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 2 -*- */
/*
    This file is part of Déjà Dup.
    © 2009 Michael Terry <mike@mterry.name>

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

public class MountOperationAssistant : MountOperation
{
  public AssistantOperation assist {get; construct;}
  Gtk.Bin password_page;
  Gtk.VBox layout;
  Gtk.Table table;
  Gtk.RadioButton anonymous_w;
  Gtk.CheckButton remember_w;
  Gtk.Entry username_w;
  Gtk.Entry domain_w;
  Gtk.Entry password_w;
  bool looping = false;

  public MountOperationAssistant(AssistantOperation assist)
  {
    this.assist = assist;
    assist.prepare.connect(do_prepare);
    assist.backward.connect(do_backward);
    assist.forward.connect(do_forward);
    assist.closing.connect(do_close);
    add_password_page();
  }

  construct {
    aborted.connect(do_abort);
    ask_password.connect(do_ask_password);
    ask_question.connect(do_ask_question);
  }

  void do_abort()
  {
    assist.show_error(_("Location not available"), null);
  }

  void do_ask_password(MountOperation op, string message, string default_user,
                       string default_domain, AskPasswordFlags flags)
  {
    flesh_out_password_page(message, default_user, default_domain, flags);
    assist.interrupt(password_page);
    looping = true;
    check_valid_inputs();
    assist.set_header_icon(Gtk.STOCK_DIALOG_AUTHENTICATION);
    assist.force_visible(false);
    Gtk.main(); // enter new loop so that we don't return until user hits next
  }

  void do_ask_question(MountOperation op, string message, string[] choices)
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
      layout.destroy();

    layout = new Gtk.VBox(false, 6);
    layout.set("border-width", 12);

    table = new Gtk.Table(0, 2, false);
    table.set("row-spacing", 6,
              "column-spacing", 6);

    password_page.add(layout);

    int rows = 0;
    int ucol = 0;
    Gtk.Label label;

    // Display user message    
    string[] tokens = message.split("\n", 2);
    assist.set_page_title(password_page, tokens[0]);

    label = new Gtk.Label(_("This backup location requires authentication."));
    label.set("xalign", 0f);
    layout.pack_start(label, false, false, 0);

    if (tokens[1] != null) {
      label = new Gtk.Label(tokens[1]);
      label.set("xalign", 0f);
      layout.pack_start(label, false, false, 0);
    }

    // Buffer
    label = new Gtk.Label("");
    layout.pack_start(label, false, false, 0);

    if ((flags & AskPasswordFlags.ANONYMOUS_SUPPORTED) != 0) {
      anonymous_w = new Gtk.RadioButton.with_mnemonic(null, _("Connect _anonymously"));
      anonymous_w.toggled.connect((b) => {check_valid_inputs();});
      layout.pack_start(anonymous_w, false, false, 0);

      var w = new Gtk.RadioButton.with_mnemonic_from_widget(anonymous_w, _("Connect as u_ser:"));
      anonymous_w.toggled.connect((b) => {
        table.sensitive = !b.active;
      });
      table.sensitive = false; // starts inactive
      layout.pack_start(w, false, false, 0);

      var hbox = new Gtk.HBox(false, 0);
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
      username_w.changed.connect((e) => {check_valid_inputs();});
      label = new Gtk.Label(_("_Username:"));
      label.set("mnemonic-widget", username_w,
                "use-underline", true,
                "xalign", 0.0f);
      table.attach(label, ucol, ucol+1, rows, rows + 1, Gtk.AttachOptions.FILL, Gtk.AttachOptions.FILL, 0, 0);
      table.attach(username_w, ucol+1, 3, rows, rows + 1, Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND, Gtk.AttachOptions.FILL, 0, 0);
      ++rows;
    }
    else
      username_w = null;

    if ((flags & AskPasswordFlags.NEED_DOMAIN) != 0) {
      domain_w = new Gtk.Entry();
      domain_w.set("activates-default", true,
                   "text", default_domain);
      domain_w.changed.connect((e) => {check_valid_inputs();});
      label = new Gtk.Label(_("_Domain:"));
      label.set("mnemonic-widget", domain_w,
                "use-underline", true,
                "xalign", 0.0f);
      table.attach(label, ucol, ucol+1, rows, rows + 1, Gtk.AttachOptions.FILL, Gtk.AttachOptions.FILL, 0, 0);
      table.attach(domain_w, ucol+1, 3, rows, rows + 1, Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND, Gtk.AttachOptions.FILL, 0, 0);
      ++rows;
    }
    else
      domain_w = null;

    if ((flags & AskPasswordFlags.NEED_PASSWORD) != 0) {
      password_w = new Gtk.Entry();
      password_w.set("visibility", false,
                     "activates-default", true);
      label = new Gtk.Label(_("_Password:"));
      label.set("mnemonic-widget", password_w,
                "use-underline", true,
                "xalign", 0.0f);
      table.attach(label, ucol, ucol+1, rows, rows + 1, Gtk.AttachOptions.FILL, Gtk.AttachOptions.FILL, 0, 0);
      table.attach(password_w, ucol+1, 3, rows, rows + 1, Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND, Gtk.AttachOptions.FILL, 0, 0);
      ++rows;
    }
    else
      password_w = null;

    if ((flags & AskPasswordFlags.SAVING_SUPPORTED) != 0) {
      remember_w = new Gtk.CheckButton.with_mnemonic(_("_Remember password"));
      layout.pack_start(remember_w, false, false, 0);
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
      if (username_w != null)
        username = username_w.get_text();
      if (domain_w != null)
        domain = domain_w.get_text();
      if (password_w != null)
        password = password_w.get_text();
      if (anonymous_w != null)
        anonymous = anonymous_w.get_active();
      if (remember_w != null)
        password_save = remember_w.get_active() ? PasswordSave.PERMANENTLY : PasswordSave.NEVER;
      print("sending reply\n");
      send_reply(MountOperationResult.HANDLED);
    }
  }
}
