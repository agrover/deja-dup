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

namespace DejaDup {

public interface Togglable : Object
{
  public signal void toggled(Togglable t, bool user);
  public abstract bool get_active();
}

public class ToggleGroup : Object
{
  // One or the other of these is non-null
  public Togglable toggle {get; construct;}
  public Gtk.ToggleButton toggle_button {get; construct;}

  public ToggleGroup(Togglable toggle) {
    Object(toggle: toggle);
  }

  public ToggleGroup.with_button(Gtk.ToggleButton toggle_button) {
    Object(toggle_button: toggle_button);
  }

  List<Gtk.Widget> dependents;
  public void add_dependent(Gtk.Widget w) {
    dependents.append(w);
    w.set_sensitive(get_active());
  }

  public void check()
  {
    bool on = get_active();
    foreach (Gtk.Widget w in dependents)
      w.set_sensitive(on);
  }

  bool get_active()
  {
    if (toggle != null)
      return toggle.get_active();
    else
      return toggle_button.get_active();
  }

  construct {
    if (toggle != null)
      toggle.toggled.connect(() => {check();});
    else
      toggle_button.toggled.connect(() => {check();});
  }
}

}

