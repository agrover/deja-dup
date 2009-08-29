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

/**
 * Yes, this is a silly reimplementation of Gtk.Assistant.
 * But Gtk.Assistant has some rediculous map/unmap logic that resets the page
 * history when unmapped and generally doesn't work when unmapped.  Since
 * continuing to work when hidden is important for us, this is a
 * reimplementation of just the bits we use.
 */
public abstract class Assistant : Gtk.Dialog
{
  public signal void canceled();
  public signal void closed();
  public signal void prepare(Gtk.Widget page);
  public signal void forward();
  public signal void backward();

  public enum Type {
    NORMAL, INTERRUPT, SUMMARY, PROGRESS, FINISH
  }

  Gtk.Label header_title;
  protected Gtk.Image header_icon;
  Gtk.Widget back_button;
  Gtk.Widget forward_button;
  Gtk.Widget cancel_button;
  Gtk.Widget close_button;
  Gtk.Widget apply_button;
  protected Gtk.EventBox page_box;

  class PageInfo {
    public Gtk.Widget page;
    public string title;
    public Type type;
  }

  bool interrupted_from_hidden = false;
  weak List<PageInfo> interrupted;

  weak List<PageInfo> current;
  List<PageInfo> infos;

  static const int APPLY = 1;
  static const int BACK = 2;
  static const int FORWARD = 3;
  static const int CANCEL = 4;
  static const int CLOSE = 5;

  construct
  {
    has_separator = false;

    infos = new List<PageInfo>();

    var ebox = new Gtk.EventBox();
    var evbox = new Gtk.VBox(false, 0);
    ebox.add(evbox);

    var ehbox = new Gtk.HBox(false, 0);
    header_title = new Gtk.Label("");
    header_title.xalign = 0f;
    header_icon = new Gtk.Image();
    ehbox.border_width = 6;
    ehbox.pack_start(header_title, true, true, 0);
    ehbox.pack_start(header_icon, false, false, 0);
    evbox.pack_start(ehbox, false, false, 0);

    page_box = new Gtk.EventBox();
    page_box.border_width = 1;
    evbox.pack_start(page_box, true, true, 0);

    vbox.add(ebox);
    vbox.show_all();

    ebox.ensure_style();
    ebox.modify_bg(Gtk.StateType.NORMAL, ebox.style.bg[Gtk.StateType.SELECTED]);
    ebox.modify_fg(Gtk.StateType.NORMAL, ebox.style.fg[Gtk.StateType.SELECTED]);

    response.connect(handle_response);
  }

  public void allow_forward(bool allow)
  {
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
    }
  }

  bool last_op_was_back = false;
  public void skip()
  {
    // During prepare, if a page wants to be skipped, it calls this.
    if (last_op_was_back)
      go_back();
    else
      go_forward();
  }

  public void go_back()
  {
    weak List<PageInfo> next;
    if (interrupted != null)
      next = interrupted.prev;
    else {
      next = current.prev;
      while (next != null && next.data.type == Type.INTERRUPT)
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
        hide();
    }
    else {
      next = current.next;
      while (next != null && next.data.type == Type.INTERRUPT)
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

  public void interrupt(Gtk.Widget page)
  {
    weak List<PageInfo> was = current;
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

      if (page_box.child != null) {
        page_box.child.hide();
        page_box.remove(page_box.child);
      }
      page_box.add(info.page);
      info.page.show();

      reset_size(info.page);

      var w = get_focus();
      if (w != null && w.get_type() == typeof(Gtk.Label))
        ((Gtk.Label)w).select_region(-1, -1);
    }
  }

  void set_buttons()
  {
    return_if_fail(current != null);

    weak PageInfo info = current.data;

    bool show_cancel = false, show_back = false, show_forward = false,
         show_apply = false, show_close = false;
    string forward_text = Gtk.STOCK_GO_FORWARD;

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
      show_forward = true;
      forward_text = _("Co_ntinue");
      break;
    case Type.PROGRESS:
      show_cancel = true;
      show_back = current.prev != null;
      break;
    case Type.FINISH:
      show_close = true;
      break;
    }

    if (cancel_button != null) {
      action_area.remove(cancel_button); cancel_button = null;}
    if (close_button != null) {
      action_area.remove(close_button); close_button = null;}
    if (back_button != null) {
      action_area.remove(back_button); back_button = null;}
    if (forward_button != null) {
      action_area.remove(forward_button); forward_button = null;}
    if (apply_button != null) {
      action_area.remove(apply_button); apply_button = null;}

    if (show_cancel)
      cancel_button = add_button(Gtk.STOCK_CANCEL, CANCEL);
    if (show_close) {
      close_button = add_button(Gtk.STOCK_CLOSE, CLOSE);
      close_button.grab_default();
    }
    if (show_back)
      back_button = add_button(Gtk.STOCK_GO_BACK, BACK);
    if (show_forward) {
      forward_button = add_button(forward_text, FORWARD);
      forward_button.grab_default();
    }
    if (show_apply) {
      apply_button = add_button(Gtk.STOCK_APPLY, APPLY);
      apply_button.grab_default();
    }
  }

  bool set_first_page()
  {
    current = infos;
    page_changed();
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
      page_box.size_request(out page_box_req);

    reset_size(page);

    if (was_empty)
      Idle.add(set_first_page);
  }

  void reset_size(Gtk.Widget page)
  {
    Gtk.Requisition pagereq;
    int boxw, boxh;
    page_box.get_size_request(out boxw, out boxh);
    page.size_request(out pagereq);
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
