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
 * Yes, this is a silly reimplementation of Gtk.Assistant.
 * But Gtk.Assistant has some ridiculous map/unmap logic that resets the page
 * history when unmapped and generally doesn't work when unmapped.  Since
 * continuing to work when hidden is important for us, this is a
 * reimplementation of just the bits we use.
 */
public abstract class Assistant : Gtk.Window
{
  public signal void response(int response);
  public signal void canceled();
  public signal void closed();
  public signal void resumed();
  public signal void prepare(Gtk.Widget page);
  public signal void forward();
  public signal void backward();
  public string apply_text {get; set; default = Gtk.Stock.APPLY;}
  public bool last_op_was_back {get; private set; default = false;}

  public enum Type {
    NORMAL, INTERRUPT, CHECK, SUMMARY, PROGRESS, FINISH
  }

  Gtk.Label header_title;
  protected Gtk.Image header_icon;
  Gtk.ButtonBox button_box;
  Gtk.Widget back_button;
  Gtk.Widget forward_button;
  Gtk.Widget cancel_button;
  Gtk.Widget close_button;
  Gtk.Widget resume_button;
  Gtk.Widget apply_button;
  protected Gtk.EventBox page_box;

  public class PageInfo {
    public Gtk.Widget page;
    public string title;
    public Type type;
  }

  bool interrupt_can_continue = true;
  bool interrupted_from_hidden = false;
  weak List<PageInfo> interrupted;

  public weak List<PageInfo> current;
  List<PageInfo> infos;

  static const int APPLY = 1;
  static const int BACK = 2;
  static const int FORWARD = 3;
  static const int CANCEL = 4;
  static const int CLOSE = 5;
  static const int RESUME = 6;

  construct
  {
    infos = new List<PageInfo>();

    var evbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);

    var ebox = new Gtk.EventBox();
    var ehbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
    header_title = new Gtk.Label("");
    header_title.xalign = 0f;
    header_icon = new Gtk.Image();
    ehbox.border_width = 6;
    ehbox.pack_start(header_title, true, true, 0);
    ehbox.pack_start(header_icon, false, false, 0);
    ebox.add(ehbox);
    evbox.pack_start(ebox, false, false, 0);

    page_box = new Gtk.EventBox();
    evbox.pack_start(page_box, true, true, 0);

    button_box = new Gtk.ButtonBox(Gtk.Orientation.HORIZONTAL);
    button_box.set_layout(Gtk.ButtonBoxStyle.END);
    button_box.border_width = 12;
    button_box.spacing = 12;

    var dlg_vbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 6);
    dlg_vbox.pack_start(evbox, true, true);
    dlg_vbox.pack_end(button_box, false, true);
    dlg_vbox.show_all();
    add(dlg_vbox);

    ebox.ensure_style();
    ebox.modify_bg(Gtk.StateType.NORMAL, ebox.style.bg[Gtk.StateType.SELECTED]);
    ebox.modify_fg(Gtk.StateType.NORMAL, ebox.style.fg[Gtk.StateType.SELECTED]);

    response.connect(handle_response);
  }

  public void allow_forward(bool allow)
  {
    if (current != null && forward_button != null)
      forward_button.sensitive = allow;
  }

  public void set_header_icon(string? name)
  {
    if (name == null)
      name = this.icon_name;

    try {
      var theme = Gtk.IconTheme.get_for_screen(get_screen());
      var pixbuf = theme.load_icon(name, 48,
                                   Gtk.IconLookupFlags.FORCE_SIZE);
      header_icon.pixbuf = pixbuf;
    }
    catch (Error e) {
      // Eh, don't worry about it
    }
  }

  void handle_response(int resp)
  {
    switch (resp) {
    case BACK: go_back(); break;
    case APPLY:
    case FORWARD: go_forward(); break;
    default:
    case CANCEL: canceled(); break;
    case CLOSE: closed(); break;
    case RESUME: resumed(); break;
    }
  }

  public void hide_for_now()
  {
    DejaDup.hide_background_window_for_shell(this);
  }

  public bool is_interrupted()
  {
    return interrupted != null;
  }

  public void skip()
  {
    // During prepare, if a page wants to be skipped, it calls this.
    if (last_op_was_back)
      go_back();
    else
      go_forward();
  }

  static bool is_interrupt_type(Type type)
  {
    return type == Type.INTERRUPT || type == Type.CHECK;
  }

  public void go_back()
  {
    weak List<PageInfo> next;
    if (interrupted != null)
      next = interrupted.prev;
    else {
      next = current.prev;
      while (next != null && is_interrupt_type(next.data.type))
        next = next.prev;
    }

    if (next != null) {
      last_op_was_back = true;
      current = next;
      page_changed();
      backward();
    }
  }

  public void go_forward()
  {
    weak List<PageInfo> next;
    if (interrupted != null) {
      next = interrupted;
      if (interrupted_from_hidden)
        hide_for_now();
    }
    else {
      next = (current == null) ? infos : current.next;
      while (next != null && is_interrupt_type(next.data.type))
        next = next.next;
    }

    if (next != null) {
      last_op_was_back = false;
      current = next;
      page_changed();
      forward();
    }
  }

  public void go_to_page(Gtk.Widget page)
  {
    weak List<PageInfo> i = infos;
    while (i != null) {
      if (i.data.page == page) {
        current = i;
        page_changed();
        break;
      }
      i = i.next;
    }
  }

  public void interrupt(Gtk.Widget page, bool can_continue = true)
  {
    weak List<PageInfo> was = current;
    interrupt_can_continue = can_continue;
    go_to_page(page);
    if (!visible) { // If we are interrupting from a hidden mode
      interrupted_from_hidden = true;
    }
    interrupted = was;
  }

  void use_title(PageInfo info)
  {
    var title = Markup.printf_escaped("<span size=\"xx-large\" weight=\"ultrabold\">%s</span>", info.title);
    header_title.set_markup(title);
  }

  void page_changed()
  {
    return_if_fail(current != null);

    interrupted = null;
    interrupted_from_hidden = false;
    weak PageInfo info = current.data;

    set_header_icon(null); // reset icon

    prepare(info.page);

    // Listeners of prepare may have changed current on us, so only proceed
    // if they haven't.
    if (current.data.page == info.page) {
      use_title(info);
      set_buttons();

      var child = page_box.get_child();
      if (child != null) {
        child.hide();
        page_box.remove(child);
      }
      page_box.add(info.page);
      info.page.show();

      reset_size(info.page);

      var w = get_focus();
      if (w != null && w.get_type() == typeof(Gtk.Label))
        ((Gtk.Label)w).select_region(-1, -1);
    }
  }

  Gtk.Button add_button(string stock, int response_id)
  {
    var btn = new Gtk.Button.from_stock(stock);
    btn.can_default = true;
    btn.clicked.connect(() => {this.response(response_id);});
    btn.show();
    button_box.pack_end(btn, false, true, 0);
    return btn;
  }

  void set_buttons()
  {
    return_if_fail(current != null);

    weak PageInfo info = current.data;

    bool show_cancel = false, show_back = false, show_forward = false,
         show_apply = false, show_close = false, show_resume = false;
    string forward_text = Gtk.Stock.GO_FORWARD;

    switch (info.type) {
    default:
    case Type.NORMAL:
      show_cancel = true;
      show_back = current.prev != null;
      show_forward = true;
      break;
    case Type.SUMMARY:
      show_cancel = true;
      show_back = current.prev != null;
      show_apply = true;
      break;
    case Type.INTERRUPT:
      show_cancel = true;
      if (interrupt_can_continue) {
        show_forward = true;
        forward_text = _("Co_ntinue");
      }
      break;
    case Type.CHECK:
      show_close = true;
      show_forward = true;
      forward_text = C_("verb", "_Test");
      break;
    case Type.PROGRESS:
      show_cancel = true;
      show_resume = true;
      break;
    case Type.FINISH:
      show_close = true;
      break;
    }

    // We call destroy on each so that they are destroyed in the idle loop.
    // GailButton does weird things with queued events during the idle loop,
    // so if we wait until then to destroy them, we avoid colliding with it.
    var area = button_box;
    if (cancel_button != null) {
      area.remove(cancel_button); DejaDup.destroy_widget(cancel_button); cancel_button = null;}
    if (close_button != null) {
      area.remove(close_button); DejaDup.destroy_widget(close_button); close_button = null;}
    if (back_button != null) {
      area.remove(back_button); DejaDup.destroy_widget(back_button); back_button = null;}
    if (resume_button != null) {
      area.remove(resume_button); DejaDup.destroy_widget(resume_button); resume_button = null;}
    if (forward_button != null) {
      area.remove(forward_button); DejaDup.destroy_widget(forward_button); forward_button = null;}
    if (apply_button != null) {
      area.remove(apply_button); DejaDup.destroy_widget(apply_button); apply_button = null;}

    if (show_cancel)
      cancel_button = add_button(Gtk.Stock.CANCEL, CANCEL);
    if (show_close) {
      close_button = add_button(Gtk.Stock.CLOSE, CLOSE);
      close_button.grab_default();
    }
    if (show_back)
      back_button = add_button(Gtk.Stock.GO_BACK, BACK);
    if (show_resume) {
      resume_button = add_button(_("_Resume Later"), RESUME);
      resume_button.grab_default();
    }
    if (show_forward) {
      forward_button = add_button(forward_text, FORWARD);
      forward_button.grab_default();
    }
    if (show_apply) {
      apply_button = add_button(apply_text, APPLY);
      apply_button.grab_default();
    }
  }

  bool set_first_page()
  {
    current = null;
    go_forward();
    return false;
  }

  Gtk.Requisition page_box_req;
  public void append_page(Gtk.Widget page, Type type = Type.NORMAL)
  {
    var was_empty = infos == null;

    var info = new PageInfo();
    info.page = page;
    info.type = type;
    info.title = "";
    infos.append(info);

    page.show_all();

    if (was_empty)
      page_box.get_preferred_size(null, out page_box_req);

    reset_size(page);

    if (was_empty)
      Idle.add(set_first_page);
  }

  void reset_size(Gtk.Widget page)
  {
    Gtk.Requisition pagereq;
    int boxw, boxh;
    page_box.get_size_request(out boxw, out boxh);
    page.get_preferred_size(null, out pagereq);
    page_box.set_size_request(int.max(boxw, pagereq.width+page_box_req.width), int.max(boxh, pagereq.height+page_box_req.height));
  }

  public void set_page_title(Gtk.Widget page, string title)
  {
    foreach (PageInfo info in infos) {
      if (info.page == page) {
        info.title = title;
        if (current != null && current.data.page == page)
          use_title(info);
        break;
      }
    }
  }
}
