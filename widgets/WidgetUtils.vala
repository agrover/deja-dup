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

namespace DejaDup {

public void show_uri(Gtk.Window parent, string link)
{
  try {
    Gdk.Screen screen = parent.get_screen();
    Gtk.show_uri(screen, link, Gdk.CURRENT_TIME);
  } catch (Error e) {
    Gtk.MessageDialog dlg = new Gtk.MessageDialog(parent, Gtk.DialogFlags.DESTROY_WITH_PARENT | Gtk.DialogFlags.MODAL, Gtk.MessageType.ERROR, Gtk.ButtonsType.OK, _("Could not display %s"), link);
    dlg.format_secondary_text("%s", e.message);
    dlg.run();
    dlg.destroy();
  }
}

// These need to be namespace-wide to prevent an odd compiler syntax error.
const string[] authors = {"Andrew Fister <temposs@gmail.com>",
                          "Michael Terry <mike@mterry.name>",
                          "Michael Vogt <michael.vogt@ubuntu.com>",
                          null};

const string[] artists = {"Andreas Nilsson <nisses.mail@home.se>",
                          "Jakub Steiner <jimmac@novell.com>",
                          "Michael Terry <mike@mterry.name>",
                          null};

const string[] documenters = {"Michael Terry <mike@mterry.name>",
                              null};

public void show_about(Object owner, Gtk.Window? parent)
{
  Gtk.AboutDialog about = (Gtk.AboutDialog)owner.get_data<Gtk.AboutDialog>("about-dlg");
  
  if (about != null)
  {
    about.present ();
    return;
  }
  
  about = new Gtk.AboutDialog ();
  about.title = _("About Déjà Dup");
  about.authors = authors;
  about.artists = artists;
  about.documenters = documenters;
  about.translator_credits = _("translator-credits");
  about.logo_icon_name = Config.PACKAGE;
  about.version = Config.VERSION;
  about.website = "https://launchpad.net/deja-dup";
  about.license = "%s\n\n%s\n\n%s".printf (
    _("This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version."),
    _("This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details."),
    _("You should have received a copy of the GNU General Public License along with this program.  If not, see http://www.gnu.org/licenses/."));
  about.wrap_license = true;
  
  owner.set_data("about-dlg", about);
  about.set_data("owner", owner);
  
  about.set_transient_for(parent);
  about.response.connect((dlg, resp) => {
    Object about_owner = (Object)dlg.get_data<Object>("owner");
    about_owner.set_data("about-dlg", null);
    dlg.destroy();
  });
  
  about.show();
}

public Gtk.Window? get_topwindow(Gtk.Widget w)
{
  w = w.get_toplevel();
  if (w != null && w.is_toplevel())
    return (Gtk.Window)w;
  else
    return null;
}

public bool init_duplicity(Gtk.Window? parent)
{
  string header;
  string msg;
  var rv = DejaDup.DuplicityInfo.get_default().check_duplicity_version(out header, out msg);

  if (!rv) {
    Gtk.MessageDialog dlg = new Gtk.MessageDialog (parent,
        Gtk.DialogFlags.DESTROY_WITH_PARENT | Gtk.DialogFlags.MODAL,
        Gtk.MessageType.ERROR,
        Gtk.ButtonsType.OK,
        "%s", header);
    dlg.format_secondary_text("%s", msg);
    dlg.run();
    dlg.destroy();
  }

  return rv;
}

} // end namespace
