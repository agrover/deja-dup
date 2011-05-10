/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 2 -*- */
/*
    This file is part of Déjà Dup.
    © 2008,2009,2010,2011 Michael Terry <mike@mterry.name>,
    © 2009 Andrew Fister <temposs@gmail.com>
    © 2011 Canonical Ltd

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
static Pid pid;
static bool op_active = false;
static bool reactive_check;
static bool testing;
static bool first_check = false;

static bool show_version = false;
static const OptionEntry[] options = {
  {"version", 0, 0, OptionArg.NONE, ref show_version, N_("Show version"), null},
  {"testing", 0, OptionFlags.HIDDEN, OptionArg.NONE, ref testing, null, null},
  {null}
};

static Notify.Notification note;

static void op_started(DBusConnection conn, string name, string name_owner)
{
  op_active = true;
}

static void op_ended(DBusConnection conn, string name)
{
  op_active = false;
}

static void network_changed()
{
  reactive_check = true;
  if (DejaDup.Network.get().connected)
    prepare_next_run(); // in case network manager was blocking us
  reactive_check = false;
}

static void volume_added(VolumeMonitor vm, Volume vol)
{
  reactive_check = true;
  prepare_next_run(); // in case missing volume was blocking us
  reactive_check = false;
}

static bool is_ready(out string when)
{
  return DejaDup.Backend.get_default().is_ready(out when);
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

// This is slightly more tortuous than I'd like.  API allows us to convert Date
// to Time.  We can then convert Time to seconds-since-epoch and stuffs that
// into a TimeVal.
static TimeVal date_to_timeval(Date date)
{
  Time time;
  date.to_time(out time);
  
  // to_time says that sub-day values are sensible, but meaningless.  This
  // presumably means 0, but we technically can't rely on that.
  time.hour = 0;
  time.minute = 0;
  time.second = 0;
  
  time_t timet = time.mktime();
  
  TimeVal tval = TimeVal();
  tval.tv_sec = (long)timet;
  tval.tv_usec = 0;
  
  return tval;
}

static long seconds_until(Date date)
{
  TimeVal cur_time = TimeVal();
  cur_time.get_current_time();
  
  TimeVal next_time = date_to_timeval(date);
  
  if (testing)
    return 5;
  else
    return next_time.tv_sec - cur_time.tv_sec;
}

static void close_pid(Pid child_pid, int status)
{
  Process.close_pid(child_pid);
  pid = (Pid)0;
}

static void notify_delay(string header, string reason)
{
  if (note == null) {
    Notify.init(Environment.get_application_name());
    note = new Notify.Notification(header, reason,
                                   "deja-dup");
    note.closed.connect((n) => {note = null;});
  }
  else
    note.update(header, reason, "deja-dup");

  try {
    note.show();
  }
  catch (Error e) {
    warning("%s\n", e.message);
  }
}

static bool kickoff()
{
  long wait_time;
  if (!seconds_until_next_run(out wait_time))
    return false;
  
  if (!testing && wait_time > 0) {
    // Huh?  Shouldn't have been called now.
    prepare_next_run();
    return false;
  }

  if (!reactive_check) {
    // Now we secretly schedule another kickoff tomorrow, in case something
    // goes wrong with this run (or user chooses to ignore for now)
    // If this run is successful, it will change 'last-run' key and this will
    // get rescheduled anyway.
    prepare_tomorrow();
  }

  string when;
  if (!is_ready(out when)) {
    debug("Postponing the backup.");
    if (!reactive_check && when != null)
      notify_delay(_("Scheduled backup delayed"), when);
    return false;
  }

  // Don't run right now if an instance is already running
  if (pid == (Pid)0 && !op_active) {
    try {
      string[] argv = new string[4];
      argv[0] = Path.build_filename(Config.PKG_LIBEXEC_DIR, "deja-dup");
      argv[1] = "--backup";
      argv[2] = "--auto";
      argv[3] = null;
      Process.spawn_async(null, argv, null,
                          SpawnFlags.SEARCH_PATH |
                          SpawnFlags.DO_NOT_REAP_CHILD |
                          SpawnFlags.STDOUT_TO_DEV_NULL |
                          SpawnFlags.STDERR_TO_DEV_NULL,
                          null, out pid);
      ChildWatch.add(pid, close_pid);
    }
    catch (Error e) {
      warning("%s\n", e.message);
    }
  }
  else
    debug("Not rerunning deja-dup, already doing so.");
  
  return false;
}

static bool seconds_until_next_run(out long secs)
{
  var next_date = DejaDup.next_run_date();
  if (!next_date.valid()) {
    debug("Invalid next run date.  Not scheduling a backup.");
    return false;
  }
  
  secs = seconds_until(next_date);
  return true;
}

static void prepare_run(long wait_time)
{
  // Stop previous run timeout
  if (timeout_id != 0)
    Source.remove(timeout_id);
  
  if (wait_time > 0) {
    debug("Waiting %ld seconds until next backup.", wait_time);
    timeout_id = Timeout.add_seconds((uint)wait_time, kickoff);
  }
  else {
    debug("Late by %ld seconds.  Backing up now.", wait_time * -1);
    kickoff();
  }
}

static void prepare_tomorrow()
{
  Date tomorrow = DejaDup.today();
  tomorrow.add_days(1);
  var secs = seconds_until(tomorrow);
  prepare_run(secs);
}

static void prepare_next_run()
{
  if (!first_check) // wait until first official check has happened
    return;

  long wait_time;
  if (!seconds_until_next_run(out wait_time))
    return;
  
  prepare_run(wait_time);
}

static void prepare_if_necessary(string key)
{
  if (key == DejaDup.LAST_RUN_KEY ||
      key == DejaDup.PERIODIC_KEY ||
      key == DejaDup.PERIODIC_PERIOD_KEY)
    prepare_next_run();
}

static void make_first_check()
{
  first_check = true;

  /* We do a little trick here.  BackendAuto -- which is the default
     backend on a fresh install of deja-dup -- will do some work to
     automatically suss out which backend should be used instead of it.
     So we request the current backend then drop it just to get that
     ball rolling in case this is the first time. */
  var unused_backend = DejaDup.Backend.get_default();
  unused_backend = null;

  prepare_next_run();
}

static void watch_settings()
{
  var settings = DejaDup.get_settings();
  settings.changed.connect(prepare_if_necessary);
}

static int main(string[] args)
{
  DejaDup.i18n_setup();

  // Translators: Monitor in this sense means something akin to 'watcher', not
  // a computer screen.  This program acts like a daemon that kicks off
  // backups at scheduled times.
  Environment.set_application_name(_("Déjà Dup Monitor"));
  
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

  DejaDup.initialize();
  DejaDup.Network.get().notify["connected"].connect(network_changed);

  Bus.watch_name(BusType.SESSION, "org.gnome.DejaDup.Operation",
                 BusNameWatcherFlags.NONE, op_started, op_ended);

  var mon = VolumeMonitor.get();
  mon.ref(); // bug 569418; bad things happen when VM goes away
  mon.volume_added.connect(volume_added);

  var loop = new MainLoop(null, false);

  // Delay first check to give the network and desktop environment a chance to start up.
  if (testing)
    make_first_check();
  else
    Timeout.add_seconds(120, () => {make_first_check(); return false;});

  watch_settings();
  loop.run();
  
  return 0;
}

} // End of class Monitor

