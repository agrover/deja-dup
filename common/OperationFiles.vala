/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 2 -*- */
/*
    This file is part of Déjà Dup.
    © 2010 Urban Skudnik <urban.skudnik@gmail.com>

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
  public Time time {get; set;}
  public File source {get; construct;}
    
  public OperationFiles(uint xid = 0,
                        Time? time_in,
                        File source)
  {
    Object(xid: xid, mode: Mode.LIST, source: source);
    time = time_in;
  }

  protected override void connect_to_dup()
  {
    dup.listed_current_files.connect((d, date, file) => {listed_current_files(date, file);});
    base.connect_to_dup();
  }

  protected override List<string>? make_argv() throws Error
  {
    List<string> argv = new List<string>();
    //if (time != null) //- no need, we don't allow null anyway
    argv.append("--time=%s".printf(time.format("%s")));

    dup.local = source;
      
      return argv;
  }
}
}
