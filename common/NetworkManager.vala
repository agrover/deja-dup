/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 2 -*- */
/*
    This file is part of Déjà Dup.
    © 2009 Michael Terry <mike@mterry.name>,
    © 2009 Andrew Fister <temposs@gmail.com>

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

public class NetworkManager : Object
{
  public bool connected {get; set; default = true;}
  public signal void changed(bool connected);

  public new static NetworkManager get() {
    if (singleton == null)
      singleton = new NetworkManager();
    return singleton;
  }

  static NetworkManager singleton;
  static const uint32 NM_STATE_CONNECTED = 3;
  dynamic DBus.Object nm;

  protected NetworkManager() {}

  construct {
    try {
      init_dbus_to_network_manager();
    }
    catch (Error e) {
      warning("%s\n", e.message);
    }
  }

  void init_dbus_to_network_manager() throws Error
  {
    //Set up the DBus connection to network manager
    DBus.Connection conn = DBus.Bus.get(DBus.BusType.SYSTEM);
    nm = conn.get_object("org.freedesktop.NetworkManager",
                         "/org/freedesktop/NetworkManager",
                         "org.freedesktop.NetworkManager");

    //Retrieve the network manager connection state.
    uint32 network_manager_state = nm.State;
    connected = network_manager_state == NM_STATE_CONNECTED;

    //Dbus signal when the state of the connection is changed.
    nm.StateChanged.connect(nm_state_changed);
  }

  protected void nm_state_changed(DBus.Object obj, uint32 new_state)
  {
    bool was_connected = connected;
    connected = new_state == NM_STATE_CONNECTED;

    if (was_connected != connected)
      changed(connected);
  }
}

} // end namespace
