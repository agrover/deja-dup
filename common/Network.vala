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

abstract class StatusProvider : Object
{
  public enum Status {ONLINE, OFFLINE, UNKNOWN}
  public Status status {get; protected set; default = Status.UNKNOWN;}

  protected DBusProxy proxy {get; private set;}

  construct {
    try {
      proxy = create_proxy();
      proxy.notify["g-name-owner"].connect(owner_changed);
      proxy.g_signal.connect(handle_signal);
      check_owner_status();
    }
    catch (Error e) {
      warning("%s\n", e.message);
    }
  }

  protected void update_status(Status new_status)
  {
    if (status != new_status)
      status = new_status;
  }

  private void owner_changed()
  {
    check_owner_status();
  }

  private async void check_owner_status()
  {
    if (proxy.g_name_owner == null)
      update_status(Status.UNKNOWN);
    else {
      Status status = Status.UNKNOWN;
      try {
        status = yield query_status();
      }
      catch (Error e) {
        warning("%s\n", e.message);
      }
      update_status(status);
    }
  }

  protected abstract DBusProxy create_proxy() throws Error;
  protected abstract async Status query_status() throws Error;
  protected abstract void handle_signal(string sender_name, string signal_name,
                                        GLib.Variant parameters);
}

class StatusNetworkManager : StatusProvider
{
  static const uint32 NM_OLD_STATE_CONNECTED = 3;
  static const uint32 NM_STATE_CONNECTED_LOCAL = 50;
  static const uint32 NM_STATE_CONNECTED_SITE = 60;
  static const uint32 NM_STATE_CONNECTED_GLOBAL = 70;

  protected override DBusProxy create_proxy() throws Error
  {
    // FIXME: use async version when I figure out the syntax
    return new DBusProxy.for_bus_sync(BusType.SYSTEM, DBusProxyFlags.NONE, null, 
                                      "org.freedesktop.NetworkManager",
                                      "/org/freedesktop/NetworkManager",
                                      "org.freedesktop.NetworkManager", null);
  }

  protected override async StatusProvider.Status query_status() throws Error
  {
    Variant state_val = proxy.get_cached_property("State");
    if (state_val == null || !state_val.is_of_type(VariantType.UINT32))
      return Status.UNKNOWN;

    uint32 state = state_val.get_uint32();
    if (state == NM_OLD_STATE_CONNECTED ||
        state == NM_STATE_CONNECTED_LOCAL ||
        state == NM_STATE_CONNECTED_SITE ||
        state == NM_STATE_CONNECTED_GLOBAL)
      return Status.ONLINE;
    else
      return Status.OFFLINE;
  }

  protected override void handle_signal(string sender_name, string signal_name,
                                        GLib.Variant parameters)
  {
    if (signal_name == "StateChanged") {
      uint32 state;
      parameters.get("(u)", out state);

      if (state == NM_OLD_STATE_CONNECTED ||
          state == NM_STATE_CONNECTED_LOCAL ||
          state == NM_STATE_CONNECTED_SITE ||
          state == NM_STATE_CONNECTED_GLOBAL)
        update_status(Status.ONLINE);
      else
        update_status(Status.OFFLINE);
    }
  }  
}

class StatusConnectionManager : StatusProvider
{
  static const string CM_STATE_CONNECTED = "online";

  protected override DBusProxy create_proxy() throws Error
  {
    // FIXME: use async version when I figure out the syntax
    return new DBusProxy.for_bus_sync(BusType.SYSTEM, DBusProxyFlags.NONE, null, 
                                      "org.moblin.connman", "/",
                                      "org.moblin.connman.Manager", null);
  }

  protected override async StatusProvider.Status query_status() throws Error
  {
    Variant state_val = yield proxy.call("GetState", null,
                                         DBusCallFlags.NONE, -1, null);
    if (state_val == null)
      return Status.UNKNOWN;

    string state;
    state_val.get("(s)", out state);
    if (state == CM_STATE_CONNECTED)
      return Status.ONLINE;
    else if (state != null)
      return Status.OFFLINE;
    else
      return Status.UNKNOWN;
  }

  protected override void handle_signal(string sender_name, string signal_name,
                                        GLib.Variant parameters)
  {
    if (signal_name == "StateChanged") {
      string state;
      parameters.get("(s)", out state);
      update_status(state == CM_STATE_CONNECTED ? Status.ONLINE : Status.OFFLINE);
    }
  }
}

public class Network : Object
{
  public bool connected {get; set; default = true;}

  public new static Network get() {
    if (singleton == null)
      singleton = new Network();
    return singleton;
  }

  static Network singleton;
  List<StatusProvider> providers;

  construct {
    providers = new List<StatusProvider>();
    add_provider(new StatusNetworkManager());
    add_provider(new StatusConnectionManager());
    update_status();
  }

  void add_provider(StatusProvider p) {
    providers.prepend(p);
    p.notify["status"].connect(update_status);
  }

  void update_status()
  {
    /* If any of our network status providers is active and running, use it */
    bool offline = false;
    bool online = false;
    foreach (StatusProvider p in providers) {
      if (p.status == StatusProvider.Status.OFFLINE)
        offline = true;
      else if (p.status == StatusProvider.Status.ONLINE)
        online = true;
    }

    bool merged_status;
    if (online)
      merged_status = true;
    else if (offline)
      merged_status = false;
    else
      merged_status = true; // no information, assume online

    if (merged_status != connected)
      connected = merged_status;
  }
}

} // end namespace
