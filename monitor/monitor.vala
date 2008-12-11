/* -*- Mode: C; indent-tabs-mode: nil; tab-width: 2 -*- */
/*
    Déjà Dup Monitor
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

class Monitor : Object {

static const string GCONF_DIR = "/apps/deja-dup";
static const string LAST_RUN_KEY = "/apps/deja-dup/last-run";
static const string PERIODIC_KEY = "/apps/deja-dup/periodic";
static const string PERIODIC_PERIOD_KEY = "/apps/deja-dup/periodic-period";

static MainLoop loop;
static uint timeout_id;
static Pid pid;

static bool show_version = false;
static const OptionEntry[] options = {
  {"version", 0, 0, OptionArg.NONE, ref show_version, N_("Show version"), null},
  {null}
};

static bool handle_options(out int status)
{
  status = 0;
  
  if (show_version) {
    print("%s %s\n", _("Déjà Dup Monitor"), Config.VERSION);
    return false;
  }
  
  return true;
}

static Date today()
{
  TimeVal cur_time = TimeVal();
  cur_time.get_current_time();
  Date cur_date;
  cur_date.set_time_val(cur_time);
  return cur_date;
}

static Date most_recent_scheduled_date(int period)
{
  // Compare days between epoch and current days.  Mod by period to find
  // scheduled dates.
  
  Date epoch = Date();
  epoch.set_dmy(1, 1, 1970);
  
  Date cur_date = today();
  
  int between = epoch.days_between(cur_date);
  int mod = between % period;
  
  cur_date.subtract_days(mod);
  return cur_date;
}

static Date next_run_date()
{
  var client = GConf.Client.get_default();
  
  bool periodic;
  string last_run_string;
  int period_days;
  
  try {
    periodic = client.get_bool(PERIODIC_KEY);
    last_run_string = client.get_string(LAST_RUN_KEY);
    period_days = client.get_int(PERIODIC_PERIOD_KEY);
  }
  catch (Error e) {
    error("%s", e.message);
    return Date();
  }
  
  if (!periodic)
    return Date();
  if (last_run_string == null)
    return today();
  if (period_days <= 0)
    period_days = 1;
  
  Date last_run = Date();
  TimeVal last_run_tval = TimeVal();
  if (!last_run_tval.from_iso8601(last_run_string))
    return today();
  
  last_run.set_time_val(last_run_tval);
  if (!last_run.valid())
    return today();
  
  Date last_scheduled = most_recent_scheduled_date(period_days);
  
  if (last_scheduled.compare(last_run) <= 0)
    last_scheduled.add_days(period_days);
  
  return last_scheduled;
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
  
  return next_time.tv_sec - cur_time.tv_sec;
}

static void close_pid(Pid child_pid, int status)
{
  Process.close_pid(child_pid);
  pid = (Pid)0;
}

static bool kickoff()
{
  long wait_time;
  if (!seconds_until_next_run(out wait_time))
    return false;
  
  if (wait_time > 0) {
    // Huh?  Shouldn't have been called now.
    prepare_next_run();
    return false;
  }
  
  // Now we secretly schedule another kickoff tomorrow, in case something
  // goes wrong with this run (or user chooses to ignore for now)
  // If this run is successful, it will change 'last-run' key and this will
  // get rescheduled anyway.
  prepare_tomorrow();
  
  // Don't run right now if an applet is already running
  if (pid == (Pid)0) {
    try {
      string[] argv = new string[2];
      argv[0] = "deja-dup-applet";
      argv[1] = null;
      Process.spawn_async(null, argv, null,
                          SpawnFlags.SEARCH_PATH |
                          SpawnFlags.DO_NOT_REAP_CHILD |
                          SpawnFlags.STDOUT_TO_DEV_NULL |
                          SpawnFlags.STDERR_TO_DEV_NULL,
                          null, out pid);
      ChildWatch.add(pid, close_pid);
    }
    catch (Error e) {
      printerr("%s\n", e.message);
    }
  }
  else
    debug("Not rerunning deja-dup-applet, already doing so.");
  
  return false;
}

static bool seconds_until_next_run(out long secs)
{
  var next_date = next_run_date();
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
  Date tomorrow = today();
  tomorrow.add_days(1);
  var secs = seconds_until(tomorrow);
  prepare_run(secs);
}

static void prepare_next_run()
{
  long wait_time;
  if (!seconds_until_next_run(out wait_time))
    return;
  
  prepare_run(wait_time);
}

static void watch_gconf()
{
  var client = GConf.Client.get_default();
  
  try {
    client.add_dir(GCONF_DIR, GConf.ClientPreloadType.NONE);
    client.notify_add(LAST_RUN_KEY, prepare_next_run);
    client.notify_add(PERIODIC_KEY, prepare_next_run);
    client.notify_add(PERIODIC_PERIOD_KEY, prepare_next_run);
  }
  catch (Error e) {
    printerr("%s\n", e.message);
  }
}

static int main(string[] args)
{
  GLib.Intl.textdomain(Config.GETTEXT_PACKAGE);
  GLib.Intl.bindtextdomain(Config.GETTEXT_PACKAGE, Config.LOCALE_DIR);
  GLib.Intl.bind_textdomain_codeset(Config.GETTEXT_PACKAGE, "UTF-8");
  
  // Translators: Monitor in this sense means something akin to 'watcher', not
  // a computer monitor.  This program acts like a daemon that kicks off
  // backups at scheduled times.
  GLib.Environment.set_application_name(_("Déjà Dup Monitor"));
  
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
  
  loop = new MainLoop(null, false);
  
  prepare_next_run();
  watch_gconf();
  loop.run();
  
  return 0;
}

} // End of class Monitor

