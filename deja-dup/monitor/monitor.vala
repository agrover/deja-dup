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

class Monitor : Object {

static uint timeout_id;
static uint netcheck_id;
static bool reactive_check;
static bool first_check = false;
static DejaDup.FilteredSettings settings = null;

static bool testing_delay = true;

static bool show_version = false;
const OptionEntry[] options = {
  {"version", 0, 0, OptionArg.NONE, ref show_version, N_("Show version"), null},
  {null}
};

static bool valid_network()
{
  var network = DejaDup.Network.get();
  return network.connected && !network.metered;
}

static bool network_check()
{
  reactive_check = true;
  if (valid_network())
    prepare_next_run(); // in case network manager was blocking us
  reactive_check = false;
  return false;
}

static void network_changed()
{
  // Wait a bit so that (a) user isn't bombarded by notifications as soon as
  // they connect and (b) if this is a transient connection (or a bug as with
  // LP bug 805140) we don't error out too soon.
  if (netcheck_id > 0)
    Source.remove(netcheck_id);
  netcheck_id = 0;
  if (valid_network())
    netcheck_id = Timeout.add_seconds(120, network_check);
}

static void volume_added(VolumeMonitor vm, Volume vol)
{
  reactive_check = true;
  prepare_next_run(); // in case missing volume was blocking us
  reactive_check = false;
}

static async bool is_ready(out string when)
{
  if (DejaDup.in_testing_mode() && testing_delay) {
    testing_delay = false;
    when = "Testing";
    return false;
  }
  var backend = DejaDup.Backend.get_default();
  var network = DejaDup.Network.get();
  if (!backend.is_native() && !network.connected) {
    when = _("Backup will begin when a network connection becomes available.");
    return false;
  } else if (!backend.is_native() && network.metered) {
    when = _("Backup will begin when an unmetered network connection becomes available.");
    return false;
  }
  return yield backend.is_ready(out when);
}

static bool handle_options(out int status)
{
  status = 0;
  
  if (show_version) {
    print("%s %s\n", "deja-dup-monitor", Config.VERSION);
    return false;
  }
  
  return true;
}

static TimeSpan time_until(DateTime date)
{
  return date.difference(new DateTime.now_local());
}

static async void call_remote(string action, string[] args = {})
{
  var vargs = new VariantBuilder(new VariantType("av"));
  foreach (string arg in args) {
    vargs.add("v", new Variant.string(arg));
  }
  var platform_args = new VariantBuilder(new VariantType("a{sv}"));
  try {
    var deja = yield new DBusProxy.for_bus(BusType.SESSION,
                                           DBusProxyFlags.NONE,
                                           null,
                                           "org.gnome.DejaDup",
                                           "/org/gnome/DejaDup",
                                           "org.freedesktop.Application",
                                           null);
    yield deja.call("ActivateAction",
                    new Variant("(sava{sv})", action, vargs, platform_args),
                    DBusCallFlags.NONE, -1, null);
  }
  catch (Error e) {
    warning("%s", e.message);
  }
}

static async void kickoff()
{
  TimeSpan wait_time;
  if (!time_until_next_run(out wait_time))
    return;
  
  if (wait_time > 0) {
    // Huh?  Shouldn't have been called now.
    prepare_next_run();
    return;
  }

  bool was_reactive = reactive_check;

  if (!was_reactive) {
    // Now we secretly schedule another kickoff tomorrow, in case something
    // goes wrong with this run (or user chooses to ignore for now)
    // If this run is successful, it will change 'last-run' key and this will
    // get rescheduled anyway.
    prepare_tomorrow();
  }

  string when;
  bool ready = yield is_ready(out when);
  if (!ready) {
    debug("Postponing the backup.");
    if (!was_reactive && when != null)
      yield call_remote("delay", {when});
    return;
  }

  debug("Running automatic backup.");

  if (DejaDup.in_testing_mode()) {
    // fake successful and schedule next run
    DejaDup.update_last_run_timestamp(DejaDup.TimestampType.BACKUP);
  }
  else {
    yield call_remote("backup-auto");
  }
}

static bool time_until_next_run(out TimeSpan time)
{
  time = 0;

  var next_date = DejaDup.next_run_date();
  if (next_date == null) {
    debug("Automatic backups disabled.  Not scheduling a backup.");
    return false;
  }
  
  time = time_until(next_date);
  return true;
}

static void prepare_run(TimeSpan wait_time)
{
  // Stop previous run timeout
  if (timeout_id != 0) {
    Source.remove(timeout_id);
    timeout_id = 0;
  }

  TimeSpan secs = wait_time / TimeSpan.SECOND + 1;
  if (wait_time > 0 && secs > 0) {
    debug("Waiting %ld seconds until next backup.", (long)secs);
    timeout_id = Timeout.add_seconds((uint)secs, () => {
      kickoff.begin();
      timeout_id = 0;
      return false;
    });
  }
  else {
    debug("Late by %ld seconds.  Backing up now.", (long)(secs * -1));
    kickoff.begin();
  }
}

static void prepare_tomorrow()
{
  var now = new DateTime.now_local();
  var tomorrow = now.add(DejaDup.get_day());
  var time = time_until(tomorrow);
  prepare_run(time);
}

static void prepare_next_run()
{
  if (!first_check) // wait until first official check has happened
    return;

  TimeSpan wait_time;
  if (!time_until_next_run(out wait_time))
    return;
  
  prepare_run(wait_time);
}

static void prepare_if_necessary(string key)
{
  if (key == DejaDup.LAST_BACKUP_KEY ||
      key == DejaDup.PERIODIC_KEY ||
      key == DejaDup.PERIODIC_PERIOD_KEY)
    prepare_next_run();
}

static void make_first_check()
{
  first_check = true;

  DejaDup.make_prompt_check();
  Timeout.add_seconds(DejaDup.get_prompt_delay(), () => {
    DejaDup.make_prompt_check();
    return true;
  });

  prepare_next_run();
}

static void watch_settings()
{
  settings = DejaDup.get_settings();
  settings.changed.connect(prepare_if_necessary);
}

static void begin_monitoring()
{
  DejaDup.Network.get().notify["connected"].connect(network_changed);
  DejaDup.Network.get().notify["metered"].connect(network_changed);

  var mon = VolumeMonitor.get();
  mon.ref(); // bug 569418; bad things happen when VM goes away
  mon.volume_added.connect(volume_added);

  watch_settings();

  // Delay first check to give the network and desktop environment a chance to start up.
  if (DejaDup.in_testing_mode())
    make_first_check();
  else
    Timeout.add_seconds(120, () => {make_first_check(); return false;});
}

static int main(string[] args)
{
  DejaDup.i18n_setup();

  // Translators: Monitor in this sense means something akin to 'watcher', not
  // a computer screen.  This program acts like a daemon that kicks off
  // backups at scheduled times.
  Environment.set_application_name(_("Backup Monitor"));
  
  OptionContext context = new OptionContext("");
  context.add_main_entries(options, Config.GETTEXT_PACKAGE);
  try {
    context.parse(ref args);
  } catch (Error e) {
    printerr("%s\n\n%s", e.message, context.get_help(true, null));
    return 1;
  }

  int status;
  if (!handle_options(out status))
    return status;

  if (!DejaDup.initialize(null, null))
    return 1;

  var loop = new MainLoop(null, false);
  Idle.add(() => {
    // quit if we can't get the bus name or become disconnected
    Bus.own_name(BusType.SESSION, "org.gnome.DejaDup.Monitor",
                 BusNameOwnerFlags.NONE, ()=>{},
                 ()=>{begin_monitoring();},
                 ()=>{loop.quit();});
    return false;
  });
  loop.run();

  return 0;
}

} // End of class Monitor

