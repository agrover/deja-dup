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

public class OperationStatus : Operation
{
  public signal void collection_dates(List<string>? dates);
  
  public OperationStatus() {
    Object(mode: ToolJob.Mode.STATUS);
  }
  
  protected override void connect_to_job()
  {
    job.collection_dates.connect((d, dates) => {collection_dates(dates);});
    base.connect_to_job();
  }
}

} // end namespace

