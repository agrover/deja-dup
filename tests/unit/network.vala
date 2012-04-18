// -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 2; coding: utf-8 -*-
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

async void check_status()
{
  yield DejaDup.Network.ensure_status();
  var nw = DejaDup.Network.get();
  var can_reach = yield nw.can_reach("https://one.ubuntu.com/");
  var can_reach2 = yield nw.can_reach("http://nowhere.local/");
  print("Connected: %d\n", (int)nw.connected);
  print("Can reach U1: %d\n", (int)can_reach);
  print("Can reach local server: %d\n", (int)can_reach2);
  Gtk.main_quit();
}

int main(string[] args)
{
  Gtk.init(ref args);
  check_status();
  Gtk.main();
  return 0;
}
