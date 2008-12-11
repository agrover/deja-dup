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

public class ConfigPeriod : ConfigChoice
{
  public ConfigPeriod(string key) {
    this.key = key;
  }
  
  construct {
    var store = new Gtk.ListStore(2, typeof(string), typeof(int));
    
    Gtk.TreeIter iter;
    int i = 0;
    
    store.insert_with_values(out iter, i++, 0, _("Daily"), 1, 1);
    store.insert_with_values(out iter, i++, 0, _("Weekly"), 1, 7);
    // Translators: Biweekly is every two weeks
    store.insert_with_values(out iter, i++, 0, _("Biweekly"), 1, 14);
    store.insert_with_values(out iter, i++, 0, _("Monthly"), 1, 28);
    
    store.set_sort_column_id(1, Gtk.SortType.ASCENDING);
    
    init(store, 1);
  }
  
  protected override void handle_changed()
  {
    Value? val = get_current_value();
    int intval = val == null ? 1 : val.get_int();
    
    try {
        client.set_int(key, intval);
    }
    catch (Error e) {
      printerr("%s\n", e.message);
    }
    
    changed(intval.to_string());
  }
  
  protected override void set_from_config()
  {
    int confval;
    try {
        confval = client.get_int(key);
    }
    catch (Error e) {
      printerr("%s\n", e.message);
      return;
    }
    if (confval < 1)
      confval = 1;
    
    bool valid;
    Gtk.TreeIter iter;
    valid = combo.model.get_iter_first(out iter);
    
    while (valid) {
      Value val;
      combo.model.get_value(iter, gconf_col, out val);
      int intval = val.get_int();
      
      if (intval == confval) {
        combo.set_active_iter(iter);
        break;
      }
      valid = combo.model.iter_next(ref iter);
    }
    
    // If we didn't find the period, user must have set it to something non
    // standard.  Let's add an entry to the combo.
    if (!valid) {
      var store = (Gtk.ListStore)combo.model;
      store.insert_with_values(out iter, 0, 0,
                               ngettext("Every %d day", "Every %d days", confval).printf(confval),
                               1, confval);
      combo.set_active_iter(iter);
    }
  }
}

