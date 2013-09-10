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

public abstract class ToolJob : Object
{
  // life cycle signals
  public signal void done(bool success, bool cancelled, string? detail);
  public signal void raise_error(string errstr, string? detail);

  // hints to UI
  public signal void action_desc_changed(string action);
  public signal void action_file_changed(File file, bool actual);
  public signal void progress(double percent);
  public signal void is_full(bool first);

  // hints that interaction is needed
  public signal void bad_encryption_password();
  public signal void question(string title, string msg);

  // type-specific signals
  public signal void collection_dates(List<string>? dates); // HISTORY
  public signal void listed_current_files(string date, string file); // LIST

  // life cycle control
  public abstract void start ();
  public abstract void cancel (); // destroy progress so far
  public abstract void stop (); // just abruptly stop
  public abstract void pause (string? reason);
  public abstract void resume ();

  public enum Mode {
    INVALID, BACKUP, RESTORE, STATUS, LIST, HISTORY,
  }
  public Mode mode {get; set; default = Mode.INVALID;}

  public enum Flags {
    NO_PROGRESS,
    NO_CACHE,
  }
  public Flags flags {get; set;}

  public File local {get; set;}
  public Backend backend {get; set;}
  public string encrypt_password {get; set;}

  public List<File> includes; // BACKUP
  public List<File> excludes; // BACKUP

  protected List<File> _restore_files;
  public List<File> restore_files { // RESTORE
    get {
      return this._restore_files;
    }
    set {
      // Deep copy
      foreach (File f in this._restore_files)
        f.unref();
      this._restore_files = value.copy();
      foreach (File f in this._restore_files)
        f.ref();
    }
  }

  public string time {get; set;} // RESTORE
}

public abstract class ToolPlugin : Peas.ExtensionBase, Peas.Activatable
{
  // Peas methods
  public Object object {owned get; construct;}
  public virtual void activate () {}
  public virtual void deactivate () {}
  public virtual void update_state () {}

  // Deja Dup methods
  public string name {get; protected set;}
  public abstract ToolJob create_job () throws Error;
}

} // end namespace

