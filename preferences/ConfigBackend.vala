/* -*- Mode: C; indent-tabs-mode: nil; c-basic-offset: 2; tab-width: 2 -*- */
/*
    Déjà Dup
    © 2008 Michael Terry <mike@mterry.name>

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

public class ConfigBackend : ConfigChoice
{
  public ConfigBackend(string key) {
    this.key = key;
  }
  
  construct {
    var store = new Gtk.ListStore(2, typeof(string), typeof(string));
    
    Gtk.TreeIter iter;
    int i = 0;
    
    store.insert_with_values(out iter, i++, 0, _("Amazon S3"), 1, "s3");
    store.insert_with_values(out iter, i++, 0, _("Local Folder"), 1, "file");
    
    store.set_sort_column_id(0, Gtk.SortType.ASCENDING);
    
    init(store, 1);
  }
}

