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

public class Network : Object
{
  public bool connected {get; private set; default = true;}
  public bool metered {get; private set; default = false;}

  public new static Network get() {
    if (singleton == null)
      singleton = new Network();
    return singleton;
  }

  public async bool can_reach(string url)
  {
    var mon = NetworkMonitor.get_default();
    try {
      var socket = NetworkAddress.parse_uri(url, 0);
      return yield mon.can_reach_async(socket);
    }
    catch (Error e) {
      warning("%s", e.message);
      return false;
    }
  }

  construct {
    var mon = NetworkMonitor.get_default();

    update_connected();
    mon.notify["network-available"].connect(update_connected);

    update_metered();
    mon.notify["network-metered"].connect(update_metered);
  }

  void update_connected()
  {
    connected = NetworkMonitor.get_default().network_available;
  }

  void update_metered()
  {
    var mon = NetworkMonitor.get_default();
    var settings = DejaDup.get_settings();
    var allow_metered = settings.get_boolean(DejaDup.ALLOW_METERED_KEY);
    metered = mon.network_metered && !allow_metered;
  }

  static Network singleton;
}

} // end namespace
