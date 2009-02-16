/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 2 -*- */
/*
    Déjà Dup
    © 2008—2009 Michael Terry <mike@mterry.name>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

using GLib;

public interface Togglable : Object
{
  public signal void toggled();
  public abstract bool get_active();
}

public class ToggleGroup : Object
{
  public Togglable toggle {get; construct;}
  
  public ToggleGroup(Togglable toggle) {
    this.toggle = toggle;
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
    toggle.toggled += (t) => {check();};
  }
}

