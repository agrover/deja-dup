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
  DBusProxy nm;

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
    // Set up the DBus connection to network manager
    // FIXME: use async version when I figure out the syntax
    nm = new DBusProxy.for_bus_sync(BusType.SYSTEM, DBusProxyFlags.NONE, null, 
                                    "org.freedesktop.NetworkManager",
                                    "/org/freedesktop/NetworkManager",
                                    "org.freedesktop.NetworkManager", null);

    // Retrieve the network manager connection state.
    Variant state_val = nm.get_cached_property("State");
    if (!state_val.is_of_type(VariantType.UINT32)) {
      // Proxy seems invalid; maybe no NM running?
      return;
    }

    uint32 nm_state = state_val.get_uint32();
    connected = nm_state == NM_STATE_CONNECTED;

    // Dbus signal when the state of the connection is changed.
    nm.g_signal.connect(nm_signal);
  }

  void nm_signal(string sender_name, string signal_name, GLib.Variant parameters)
  {
    if (signal_name == "StateChanged") {
      bool was_connected = connected;

      uint32 nm_state;
      parameters.get("(u)", out nm_state);

      connected = nm_state == NM_STATE_CONNECTED;

      if (was_connected != connected)
        changed(connected);
    }
  }
}

} // end namespace
