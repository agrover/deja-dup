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
  public bool connected {get; set; default = true;}

  public new static Network get() {
    if (singleton == null)
      singleton = new Network();
    return singleton;
  }

  public async static void ensure_status()
  {
    var network = Network.get();
    network.update_status();
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
    mon.network_changed.connect(handle_changed);
  }

  void handle_changed(bool available)
  {
    update_status();
  }

  void update_status()
  {
    var mon = NetworkMonitor.get_default();
    if (mon.network_available != connected)
      connected = mon.network_available;
  }

  static Network singleton;
}

} // end namespace
