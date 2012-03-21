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

public class BackendAuto : Backend
{
  public override Backend clone() {
    return new BackendAuto();
  }

  public override bool is_native() {
    return false;
  }

  public override Icon? get_icon() {
    return null;
  }

  public override async bool is_ready(out string when) {
    when = null;
    return false;
  }

  public override string get_location(ref bool as_root) {
    return "invalid";
  }

  public override string get_location_pretty() {
    return "";
  }

  static bool started = false;
  static bool done = false;
  Checker u1checker;
  Checker s3checker;
  construct {
    if (!started) {
      // Start slow process of testing various backends to see
      // which to use.
      started = true;
      ref(); // Give us time to finish

      // List is (in order): u1, s3, file
      u1checker = BackendU1.get_checker();
      u1checker.notify["complete"].connect(examine_checkers);

      s3checker = BackendS3.get_checker();
      s3checker.notify["complete"].connect(examine_checkers);

      examine_checkers();
    }
  }

  void examine_checkers()
  {
    if (done)
      return;

    if (u1checker.complete) {
      if (u1checker.available) {
        finish("u1");
      }
      else if (s3checker.complete) {
        if (s3checker.available)
          finish("s3");
        else
          finish("file");
      }
    }
  }

  void finish(string mode)
  {
    if (mode == "file") {
      var file_settings = get_settings(FILE_ROOT);
      file_settings.delay();

      file_settings.set_string(FILE_TYPE_KEY, "normal");

      var path = Path.build_filename(Environment.get_home_dir(), "deja-dup");
      file_settings.set_string(FILE_PATH_KEY, path);

      file_settings.apply();
    }
    var settings = get_settings();
    settings.set_string(BACKEND_KEY, mode);
    done = true;
    unref();
  }
}

} // end namespace

