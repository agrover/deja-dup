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

void testing_mode()
{
  Environment.unset_variable("DEJA_DUP_TESTING");
  assert(!DejaDup.in_testing_mode());
  Environment.set_variable("DEJA_DUP_TESTING", "0", true);
  assert(!DejaDup.in_testing_mode());
  Environment.set_variable("DEJA_DUP_TESTING", "1", true);
  assert(DejaDup.in_testing_mode());
  Environment.unset_variable("DEJA_DUP_TESTING");
}

void get_day()
{
  Environment.unset_variable("DEJA_DUP_TESTING");
  assert(DejaDup.get_day() == TimeSpan.DAY);
  Environment.set_variable("DEJA_DUP_TESTING", "1", true);
  assert(DejaDup.get_day() == TimeSpan.SECOND * (TimeSpan)10);
  Environment.unset_variable("DEJA_DUP_TESTING");
}

void parse_dir()
{
  assert(DejaDup.parse_dir("$HOME").equal(
         File.new_for_path(Environment.get_home_dir())));
  assert(DejaDup.parse_dir("$TRASH").equal(
         File.new_for_path(Path.build_filename(Environment.get_user_data_dir(), "Trash"))));
  assert(DejaDup.parse_dir("$DESKTOP").equal(
         File.new_for_path(Environment.get_user_special_dir(UserDirectory.DESKTOP))));
  assert(DejaDup.parse_dir("$DOCUMENTS").equal(
         File.new_for_path(Environment.get_user_special_dir(UserDirectory.DOCUMENTS))));
  assert(DejaDup.parse_dir("$DOWNLOAD").equal(
         File.new_for_path(Environment.get_user_special_dir(UserDirectory.DOWNLOAD))));
  assert(DejaDup.parse_dir("$MUSIC").equal(
         File.new_for_path(Environment.get_user_special_dir(UserDirectory.MUSIC))));
  assert(DejaDup.parse_dir("$PICTURES").equal(
         File.new_for_path(Environment.get_user_special_dir(UserDirectory.PICTURES))));
  assert(DejaDup.parse_dir("$PUBLIC_SHARE").equal(
         File.new_for_path(Environment.get_user_special_dir(UserDirectory.PUBLIC_SHARE))));
  assert(DejaDup.parse_dir("$TEMPLATES").equal(
         File.new_for_path(Environment.get_user_special_dir(UserDirectory.TEMPLATES))));
  assert(DejaDup.parse_dir("$VIDEOS").equal(
         File.new_for_path(Environment.get_user_special_dir(UserDirectory.VIDEOS))));
  assert(DejaDup.parse_dir("VIDEOS").equal(
         File.new_for_path(Path.build_filename(Environment.get_home_dir(), "VIDEOS"))));
  assert(DejaDup.parse_dir("/VIDEOS").equal(
         File.new_for_path("/VIDEOS")));
  assert(DejaDup.parse_dir("file:VIDEOS").equal(
         File.parse_name("file:VIDEOS")));
  assert(DejaDup.parse_dir("file:///VIDEOS").equal(
         File.new_for_path("/VIDEOS")));
  assert(DejaDup.parse_dir("").equal(
         File.new_for_path(Environment.get_home_dir())));
}

void parse_dir_list()
{
  
}

int main(string[] args)
{
  Test.init(ref args);
  Test.add_func("/common/utils/testing_mode", testing_mode);
  Test.add_func("/common/utils/get_day", get_day);
  Test.add_func("/common/utils/parse_dir", parse_dir);
  Test.add_func("/common/utils/parse_dir_list", parse_dir_list);
  return Test.run();
}
