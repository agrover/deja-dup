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
public class OperationFiles : Operation {
  public signal void listed_current_files(string date, string file);
  public Time time {get; set;} // Default value is 1900-01-00 00:00:00; since epoch hasn't happened yet, its default %s value is -1
  public File source {get; construct;}
    
  public OperationFiles(Time? time_in,
                        File source) {
    Object(mode: ToolJob.Mode.LIST, source: source);
    if (time_in != null)
        time = time_in;
  }

  protected override void connect_to_job()
  {
    job.listed_current_files.connect((d, date, file) => {listed_current_files(date, file);});
    base.connect_to_job();
  }

  protected override List<string>? make_argv()
  {
    if (time.format("%s") != "-1")
      job.time = time.format("%s");
    else
      job.time = null;
    job.local = source;
    return null;
  }
}
}
