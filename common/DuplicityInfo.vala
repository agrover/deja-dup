/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 2 -*- */
/*
    This file is part of Déjà Dup.
    © 2008–2010 Michael Terry <mike@mterry.name>

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

public class DuplicityInfo : Object
{
  public static const int REQUIRED_MAJOR = 0;
  public static const int REQUIRED_MINOR = 5;
  public static const int REQUIRED_MICRO = 3;

  public bool has_broken_cleanup {get; private set; default = false; }
  public bool has_backup_progress {get; private set; default = false; }
  public bool has_restore_progress {get; private set; default = false; }
  public bool has_collection_status {get; private set; default = false; }
  public bool new_time_format {get; private set; default = false; }
  public bool can_read_short_filenames {get; private set; default = false; }
  public bool has_native_gio {get; private set; default = false; }
  public bool can_resume {get; private set; default = false; }
  public bool has_rename_arg {get; private set; default = false; }
  public bool has_fixed_log_file {get; private set; default = false; }
  public bool use_empty_gpg_options {get; private set; default = false; }
  public bool guarantees_error_codes {get; private set; default = false; }
  public bool has_u1 {get; private set; default = false;}
  
  static DuplicityInfo info = null;
  public static DuplicityInfo get_default() {
    if (info == null)
      info = new DuplicityInfo();
    return info;
  }
  
  // Returns true if everything is OK.  If false, program will close.  A dialog
  // will already have been thrown up.
  public bool check_duplicity_version(out string header, out string msg) {
    string output;
    
    try {
      Process.spawn_command_line_sync("duplicity --version", out output, null, null);
    }
    catch (Error e) {
      set_missing_duplicity_error(out header, out msg, e.message);
      return false;
    }
    
    var tokens = output.split(" ", 2);
    if (tokens == null || tokens[0] == null || tokens[1] == null) {
      set_missing_duplicity_error(out header, out msg, null);
      return false;
    }
    
    // First token is 'duplicity' and is ignorable.  Second looks like '0.5.03'
    version_string = tokens[1].strip();
    var ver_tokens = version_string.split(".");
    if (ver_tokens == null || ver_tokens[0] == null) {
      set_missing_duplicity_error(out header, out msg, null);
      return false;
    }
    major = int.parse(ver_tokens[0]);
    // Don't error out if no minor or micro.  Duplicity might not have them?
    if (ver_tokens[1] != null) {
      minor = int.parse(ver_tokens[1]);
      if (ver_tokens[2] != null)
        micro = int.parse(ver_tokens[2]);
    }
    
    var good_enough = meets_requirements();
    if (!good_enough) {
      set_bad_version_error(out header, out msg);
      return false;
    }
    
    if (meets_version(0, 5, 4)) {
      has_backup_progress = true;
      has_collection_status = true;
      guarantees_error_codes = true;
    }
    if (equals_version(0, 5, 4) || equals_version(0, 5, 5))
      has_broken_cleanup = true;
    if (meets_version(0, 5, 6))
      has_restore_progress = true;
    if (meets_version(0, 5, 10))
      new_time_format = true;
    if (meets_version(0, 5, 16))
      can_read_short_filenames = true;
    if (meets_version(0, 6, 5)) {
      has_native_gio = true; // had it since 0.6.1, but didn't work on restore
    }
    if (meets_version(0, 6, 7)) {
      has_rename_arg = true;
      has_fixed_log_file = true; // had it since 0.5.3, but was buggy
    }
    if (equals_version(0, 6, 8))
      use_empty_gpg_options = true; // workaround a duplicity bug
    if (equals_version(0, 6, 13))
      can_resume = true; // had it since 0.6.0, but had data corruption bugs

    return true;
  }
  
  string version_string = null;
  int major = 0;
  int minor = 0;
  int micro = 0;
  
  bool meets_version(int vmaj, int vmin, int vmic) {
    return (major > vmaj) ||
           (major == vmaj && minor > vmin) ||
           (major == vmaj && minor == vmin && micro >= vmic);
  }
  
  bool equals_version(int vmaj, int vmin, int vmic) {
    return major == vmaj && minor == vmin && micro == vmic;
  }
  
  // Doesn't yet handle a blacklist of versions.  We'll cross that bridge when we come to it
  bool meets_requirements() {
    return meets_version(REQUIRED_MAJOR, REQUIRED_MINOR, REQUIRED_MICRO);
  }
  
  void set_missing_duplicity_error(out string header, out string msg, string? msg_in) {
    header = _("Could not run duplicity");
    msg = msg_in;
    if (msg != null)
      msg = msg.chomp() + "\n\n";
    else if (version_string == null)
        msg = _("Could not understand duplicity version.\n\n");
    else
        msg = _("Could not understand duplicity version ‘%s’.\n\n").printf(version_string);

    msg += _("Without duplicity, Déjà Dup cannot function.  It will close now.");
  }
  
  void set_bad_version_error(out string header, out string msg) {
    header = _("Duplicity’s version is too old");
    msg = _("Déjà Dup requires at least version %d.%d.%.2d of duplicity, but only found version %d.%d.%.2d").printf(REQUIRED_MAJOR, REQUIRED_MINOR, REQUIRED_MICRO, major, minor, micro);
  }
}

} // end namespace

