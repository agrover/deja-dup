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

public interface Togglable : Object
{
  public signal void toggled();
  public abstract bool get_active();
}

public class ToggleGroup : Object
{
  public Togglable toggle {get; construct;}
  
  public ToggleGroup(Togglable toggle) {
    Object(toggle: toggle);
  }
  
  List<Gtk.Widget> dependents;
  public void add_dependent(Gtk.Widget w) {
    dependents.append(w);
  }
  
  public void check()
  {
    bool on = toggle.get_active();
    foreach (Gtk.Widget w in dependents)
      w.set_sensitive(on);
  }
  
  construct {
    toggle.toggled.connect((t) => {check();});
  }
}

}

