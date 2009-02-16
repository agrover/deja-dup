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

namespace DejaDup {

public class OperationStatus : Operation
{
  public signal void collection_dates(List<string>? dates);
  
  public OperationStatus(Gtk.Window? win, uint xid = 0) {
    toplevel = win;
    uppermost_xid = xid;
    mode = Mode.STATUS;
  }
  
  protected override void connect_to_dup()
  {
    dup.collection_dates += (d, dates) => {collection_dates(dates);};
    base.connect_to_dup();
  }
}

} // end namespace

