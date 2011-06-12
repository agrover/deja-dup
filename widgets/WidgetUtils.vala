/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 2 -*- */
/*
    This file is part of Déjà Dup.
    © 2008,2009,2010 Michael Terry <mike@mterry.name>
    © 2011 Canonical Ltd

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
    Gtk.show_uri(screen, link, Gtk.get_current_event_time());
  } catch (Error e) {
    Gtk.MessageDialog dlg = new Gtk.MessageDialog(parent, Gtk.DialogFlags.DESTROY_WITH_PARENT | Gtk.DialogFlags.MODAL, Gtk.MessageType.ERROR, Gtk.ButtonsType.OK, _("Could not display %s"), link);
    dlg.format_secondary_text("%s", e.message);
    dlg.run();
    destroy_widget(dlg);
  }
}

public enum ShellEnv {
  NONE,
  GNOME,
  UNITY,
  LEGACY
}

protected ShellEnv shell = ShellEnv.NONE;
public ShellEnv get_shell()
{
  if (shell == ShellEnv.NONE) {
    // Easiest check is Unity -- it tells us directly
    if (hacks_unity_present())
      shell = ShellEnv.UNITY;
    else {
      // Next check for Shell by notification capabilities
      unowned List<string> caps = Notify.get_server_caps();
      bool persistence = false, actions = false;
      foreach (string cap in caps) {
        if (cap == "persistence")
          persistence = true;
        else if (cap == "actions")
          actions = true;
      }
      if (persistence && actions)
        shell = ShellEnv.GNOME;
      else
        shell = ShellEnv.LEGACY;
    }
  }

  return shell;
}

bool user_focused(Gtk.Widget win, Gdk.EventFocus e)
{
  ((Gtk.Window)win).urgency_hint = false;
  win.focus_in_event.disconnect(user_focused);
  return false;
}

public void show_background_window_for_shell(Gtk.Window win)
{
  win.focus_on_map = false;
  win.urgency_hint = true;
  win.focus_in_event.connect(user_focused);

  if (get_shell() == ShellEnv.UNITY) {
    // Show as a launcher icon instead of a window in the background
    win.iconify();
    win.show();
    win.iconify(); // In case WM didn't respect first iconify
  }

  win.show();
}

public void destroy_widget(Gtk.Widget w)
{
  // We destroy in the idle loop for two reasons:
  // 1) Vala likes to unref local dialogs (like file choosers) after we call
  //    destroy, which is odd.  This avoids issues that arise from that.
  // 2) When running in accessiblity mode (as we do during test suites),
  //    GailButtons tend to do odd things with queued events during idle calls.
  //    This avoids destroying objects before gail is done with them, which led
  //    to crashes.
  w.hide();
  w.ref();
  Idle.add(() => {w.destroy(); return false;});
}

// These need to be namespace-wide to prevent an odd compiler syntax error.
const string[] authors = {"Andrew Fister <temposs@gmail.com>",
                          "Michael Terry <mike@mterry.name>",
                          "Michael Vogt <michael.vogt@ubuntu.com>",
                          "Urban Skudnik <urban.skudnik@gmail.com>",
                          null};

const string[] artists = {"Andreas Nilsson <nisses.mail@home.se>",
                          "Jakub Steiner <jimmac@novell.com>",
                          "Lapo Calamandrei <calamandrei@gmail.com>",
                          "Michael Terry <mike@mterry.name>",
                          null};

const string[] documenters = {"Michael Terry <mike@mterry.name>",
                              null};

public void show_about(Object owner, Gtk.Window? parent)
{
  Gtk.AboutDialog about = (Gtk.AboutDialog)owner.get_data<Gtk.AboutDialog>("about-dlg");
  
  if (about != null)
  {
    about.present_with_time(Gtk.get_current_event_time());
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
  about.license_type = Gtk.License.GPL_3_0;
  about.wrap_license = true;
  
  owner.set_data("about-dlg", about);
  about.set_data("owner", owner);
  
  about.set_transient_for(parent);
  about.set_modal(true);
  about.response.connect((dlg, resp) => {
    Object about_owner = (Object)dlg.get_data<Object>("owner");
    about_owner.set_data("about-dlg", null);
    destroy_widget(dlg);
  });
  
  about.show();
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
    destroy_widget(dlg);
  }

  return rv;
}

} // end namespace
