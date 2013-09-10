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

public class ConfigLocation : ConfigWidget
{
  static const int COL_ICON = 0;
  static const int COL_TEXT = 1;
  static const int COL_SORT = 2;
  static const int COL_UUID = 3;
  static const int COL_PAGE = 4;
  static const int COL_INDEX = 5;

  enum Group {
    CLOUD = 0,
    CLOUD_SEP,
    REMOTE,
    REMOTE_CUSTOM,
    REMOTE_SEP,
    VOLUMES,
    VOLUMES_SEP,
    LOCAL
  }

  public Gtk.EventBox extras {get; private set;}
  public Gtk.SizeGroup label_sizes {get; construct;}

  public Gtk.Requisition hidden_size()
  {
    Gtk.Requisition pagereq;
    extras.get_preferred_size(null, out pagereq);
    pagereq.width = extras_max_width - pagereq.width + 20;
    pagereq.height = extras_max_height - pagereq.height + 20;
    return pagereq;
  }

  public ConfigLocation(Gtk.SizeGroup? sg = null)
  {
    Object(label_sizes: sg);
  }

  int index_ftp;
  int index_dav;
  int index_s3 = -2;
  int index_rackspace = -2;
  int index_u1 = -2;
  int index_cloud_sep = -2;
  int index_ssh;
  int index_smb;
  int num_volumes = 0;
  int index_vol_sep = -2;
  int index_custom;
  int index_local;

  int extras_max_width = 0;
  int extras_max_height = 0;

  Gtk.ComboBox button;
  Gtk.ListStore store;
  Gtk.TreeModelSort sort_model;
  construct {
    var vbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 6);
    add(vbox);

    // Here we have a model wrapped inside a sortable model.  This is so we
    // can keep indices around for the inner model while the outer model appears
    // nice and sorted to users.
    store = new Gtk.ListStore(6, typeof(Icon), typeof(string), typeof(string),
                              typeof(string), typeof(ConfigLocationTable),
                              typeof(int));
    sort_model = new Gtk.TreeModelSort.with_model(store);
    sort_model.set_sort_column_id(COL_SORT, Gtk.SortType.ASCENDING);
    button = new Gtk.ComboBox.with_model(sort_model);
    button.set_row_separator_func(is_separator);
    vbox.add(button);

    var accessible = button.get_accessible();
    if (accessible != null) {
      accessible.set_name("Location");
    }

    Gtk.TreeIter iter;

    if (label_sizes == null)
      label_sizes = new Gtk.SizeGroup(Gtk.SizeGroupMode.HORIZONTAL);

    extras = new Gtk.EventBox();
    extras.visible_window = false;
    extras.border_width = 0;
    extras.show();

    // Insert cloud providers
    insert_u1();
    insert_s3();
    insert_rackspace();

    // Now insert remote servers
    index_ssh = add_entry(new ThemedIcon.with_default_fallbacks("folder-remote"),
                          _("SSH"), Group.REMOTE, new ConfigLocationSSH(label_sizes));
    index_smb = add_entry(new ThemedIcon.with_default_fallbacks("folder-remote"),
                          _("Windows Share"), Group.REMOTE, new ConfigLocationSMB(label_sizes));
    index_ftp = add_entry(new ThemedIcon.with_default_fallbacks("folder-remote"),
                          _("FTP"), Group.REMOTE, new ConfigLocationFTP(label_sizes));
    index_dav = add_entry(new ThemedIcon.with_default_fallbacks("folder-remote"),
                          _("WebDAV"), Group.REMOTE, new ConfigLocationDAV(label_sizes));

    index_custom = add_entry(new ThemedIcon.with_default_fallbacks("folder-remote"),
                             _("Custom Location"), Group.REMOTE_CUSTOM,
                             new ConfigLocationCustom(label_sizes));

    add_separator(Group.REMOTE_SEP);

    // And a local folder option
    index_local = add_entry(new ThemedIcon("folder"), _("Local Folder"),
                            Group.LOCAL, new ConfigLocationFile(label_sizes));

    // Now insert removable drives
    var mon = VolumeMonitor.get();
    mon.ref(); // bug 569418; bad things happen when VM goes away
    List<Volume> vols = mon.get_volumes();
    foreach (Volume v in vols) {
      add_volume(mon, v);
    }
    update_saved_volume();

    mon.volume_added.connect(add_volume);
    mon.volume_changed.connect(update_volume);
    mon.volume_removed.connect(remove_volume);

    var pixrenderer = new Gtk.CellRendererPixbuf();
    button.pack_start(pixrenderer, false);
    button.add_attribute(pixrenderer, "gicon", COL_ICON);

    var textrenderer = new Gtk.CellRendererText();
    button.pack_start(textrenderer, true);
    button.add_attribute(textrenderer, "text", COL_TEXT);

    // End of location combo

    mnemonic_widget = button;

    button.set_active(0); // worst case, activate first entry
    set_from_config.begin();

    set_location_widgets();
    button.changed.connect(handle_changed);

    watch_key(BACKEND_KEY);
    watch_key(FILE_PATH_KEY, DejaDup.get_settings(FILE_ROOT));
  }

  delegate void CloudCallback();

  void insert_s3() {
    insert_cloud_if_available("s3", BackendS3.get_checker(),
                              new ThemedIcon("deja-dup-cloud"),
                              _("Amazon S3"),
                              new ConfigLocationS3(label_sizes),
                              ref index_s3, insert_s3);
  }

  void insert_u1() {
    insert_cloud_if_available("u1", BackendU1.get_checker(),
                              new ThemedIcon.from_names({"ubuntuone",
                                                         "ubuntuone-installer",
                                                         "deja-dup-cloud"}),
                              _("Ubuntu One"),
                              new ConfigLocationU1(label_sizes),
                              ref index_u1, insert_u1);
  }

  void insert_rackspace() {
    insert_cloud_if_available("rackspace", BackendRackspace.get_checker(),
                              new ThemedIcon("deja-dup-cloud"),
                              _("Rackspace Cloud Files"),
                              new ConfigLocationRackspace(label_sizes),
                              ref index_rackspace, insert_rackspace);
  }

  void insert_cloud_if_available(string id, Checker checker,
                                 Icon icon, string name,
                                 Gtk.Widget w, ref int index,
                                 CloudCallback cb)
  {
    var backend = Backend.get_default_type();
    if (backend == id || (checker.complete && checker.available)) {
      index = add_entry(icon, name, Group.CLOUD, w);
      if (index_cloud_sep == -2)
        index_cloud_sep = add_separator(Group.CLOUD_SEP);
    }
    else if (!checker.complete) {
      checker.notify["complete"].connect(() => {cb();});
    }
  }

  bool is_allowed_volume(Icon icon_in)
  {
    // Unfortunately, there is no convenience API to ask, "what type is this
    // GVolume?"  Instead, we ask for the icon and look for standard icon
    // names to determine type.
    // Currently, to be on the safe side (and the user always has an 'out' by
    // specifying a custom path), we whitelist the types we allow.

    // First, if the icon is emblemed, look past emblems to real icon
    EmblemedIcon icon_emblemed = icon_in as EmblemedIcon;
    if (icon_emblemed != null)
      icon_in = icon_emblemed.get_icon();

    ThemedIcon icon = icon_in as ThemedIcon;
    if (icon == null)
      return false;

    weak string[] names = icon.get_names();
    foreach (weak string name in names) {
      switch (name) {
      case "drive-harddisk":
      case "drive-removable-media":
      case "media-flash":
      case "media-floppy":
      case "media-tape":
        return true;
      //case "drive-optical":
      //case "media-optical":
      }
    }

    return false;
  }

  bool is_separator(Gtk.TreeModel model, Gtk.TreeIter iter)
  {
    Value text_var;
    model.get_value(iter, COL_TEXT, out text_var);
    weak string text = text_var.get_string();
    return text == null;
  }

  int next_index()
  {
    return store.iter_n_children(null);
  }

  int add_entry(Icon? icon, string label, Group category,
                Gtk.Widget? page = null, string? uuid = null)
  {
    var index = next_index();

    Gtk.TreeIter iter;
    store.insert_with_values(out iter, index, COL_ICON, icon, COL_TEXT, label,
                             COL_SORT, "%d%s".printf((int)category, label),
                             COL_UUID, uuid, COL_PAGE, page, COL_INDEX, index);

    if (page != null) {
      Gtk.Requisition pagereq;
      page.show_all();
      page.get_preferred_size(null, out pagereq);
      extras_max_width = int.max(extras_max_width, pagereq.width);
      extras_max_height = int.max(extras_max_height, pagereq.height);
    }

    return index;
  }

  int add_separator(Group category)
  {
    var index = store.iter_n_children(null);

    Gtk.TreeIter iter;
    store.insert_with_values(out iter, index, COL_SORT, "%d".printf((int)category),
                             COL_TEXT, null, COL_INDEX, index);
    return index;
  }

  bool lookup_uuid(string uuid, out Gtk.TreeIter iter_in)
  {
    Gtk.TreeIter iter;
    iter_in = Gtk.TreeIter();
    if (store.get_iter_first(out iter)) {
      do {
        string iter_uuid;
        store.get(iter, COL_UUID, out iter_uuid);
        if (iter_uuid == uuid) {
          iter_in = iter;
          return true;
        }
      } while (store.iter_next(ref iter));
    }

    return false;
  }

  void add_volume(VolumeMonitor monitor, Volume v)
  {
    add_volume_full(v.get_identifier(VolumeIdentifier.UUID),
                    v.get_name(), v.get_icon());
  }

  void add_volume_full(string uuid, string name, Icon icon)
  {
    Gtk.TreeIter iter;
    if (lookup_uuid(uuid, out iter)) {
      update_volume_full(uuid, name, icon);
      return;
    }

    if (is_allowed_volume(icon)) {
      if (num_volumes++ == 0)
        index_vol_sep = add_separator(Group.VOLUMES_SEP);
      add_entry(icon, name, Group.VOLUMES,
                new ConfigLocationVolume(label_sizes), uuid);
    }
  }

  void update_volume(VolumeMonitor monitor, Volume v)
  {
    update_volume_full(v.get_identifier(VolumeIdentifier.UUID),
                       v.get_name(), v.get_icon());
  }

  void update_volume_full(string uuid, string name, Icon icon)
  {
    Gtk.TreeIter iter;
    if (!lookup_uuid(uuid, out iter))
      return;

    store.set(iter, COL_ICON, icon, COL_TEXT, name, COL_UUID, uuid);
  }

  void remove_volume(VolumeMonitor monitor, Volume v)
  {
    remove_volume_full(v.get_identifier(VolumeIdentifier.UUID));
  }

  void remove_volume_full(string uuid)
  {
    Gtk.TreeIter iter;
    if (!lookup_uuid(uuid, out iter))
      return;

    // Make sure it isn't the saved volume; we never want to remove that
    var fsettings = DejaDup.get_settings(FILE_ROOT);
    var saved_uuid = fsettings.get_string(FILE_UUID_KEY);
    if (uuid == saved_uuid)
      return;

    store.remove(iter);

    if (--num_volumes == 0) {
      Gtk.TreeIter sep_iter;
      if (store.get_iter_from_string(out sep_iter, index_vol_sep.to_string())) {
        store.remove(sep_iter);
        index_vol_sep = -2;
      }
    }
  }

  bool update_saved_volume()
  {
    // And add an entry for any saved volume
    var fsettings = DejaDup.get_settings(FILE_ROOT);
    var uuid = fsettings.get_string(FILE_UUID_KEY);
    if (uuid != "") {
      Icon vol_icon = null;
      try {
        vol_icon = Icon.new_for_string(fsettings.get_string(FILE_ICON_KEY));
      }
      catch (Error e) {warning("%s\n", e.message);}

      var vol_name = fsettings.get_string(FILE_SHORT_NAME_KEY);

      add_volume_full(uuid, vol_name, vol_icon);
      return true;
    }
    else
      return false;
  }

  void set_active_iter(Gtk.TreeIter iter)
  {
    Gtk.TreeIter iter0;
    sort_model.convert_child_iter_to_iter(out iter0, iter);
    button.set_active_iter(iter0);
  }

  protected override async void set_from_config()
  {
    int index = -1;

    // Check the backend type, then GIO uri if needed
    var backend = Backend.get_default_type();
    if (backend == "s3")
      index = index_s3;
    else if (backend == "rackspace")
      index = index_rackspace;
    else if (backend == "u1")
      index = index_u1;
    else if (backend == "file") {
      var fsettings = DejaDup.get_settings(FILE_ROOT);

      if (fsettings.get_string(FILE_TYPE_KEY) == "volume") {
        if (update_saved_volume()) {
          var uuid = fsettings.get_string(FILE_UUID_KEY);
          Gtk.TreeIter saved_iter;
          if (lookup_uuid(uuid, out saved_iter)) {
            set_active_iter(saved_iter);
            return;
          }
        }
      }
      else { // normal
        // If we are already on 'custom location', don't switch away from it
        // to another toplevel entry
        Gtk.TreeIter iter0, inner_iter;
        if (!button.get_active_iter(out iter0))
          return;
        sort_model.convert_iter_to_child_iter(out inner_iter, iter0);

        int cur_index;
        store.get(inner_iter, COL_INDEX, out cur_index);

        if (cur_index == index_custom)
          return;

        // OK, we can continue
        var scheme = ConfigURLPart.read_uri_part(fsettings, FILE_PATH_KEY,
                                                 ConfigURLPart.Part.SCHEME);
        switch (scheme) {
        case "dav":
        case "davs": index = index_dav;    break;
        case "sftp":
        case "ssh":  index = index_ssh;    break;
        case "ftp":  index = index_ftp;    break;
        case "smb":  index = index_smb;    break;
        case "file": index = index_local;  break;
        default:     index = index_custom; break;
        }
      }
    }

    if (index >= 0) {
      Gtk.TreeIter iter;
      if (store.get_iter_from_string(out iter, index.to_string()))
        set_active_iter(iter);
    }
  }

  void set_location_widgets()
  {
    var current = extras.get_child();
    if (current != null)
      extras.remove(current);

    Gtk.TreeIter iter0, iter;
    Value page_var;
    if (button.get_active_iter(out iter0)) {
      sort_model.convert_iter_to_child_iter(out iter, iter0);
      store.get_value(iter, COL_PAGE, out page_var);
      ConfigLocationTable page = page_var.get_object() as ConfigLocationTable;
      if (page != null)
        extras.add(page);
    }
  }

  async void handle_changed()
  {
    yield set_location_info();
    set_location_widgets();
  }

  async void set_location_info()
  {
    Gtk.TreeIter iter0, iter;
    if (!button.get_active_iter(out iter0))
      return;
    sort_model.convert_iter_to_child_iter(out iter, iter0);

    int index;
    string uuid;
    store.get(iter, COL_INDEX, out index, COL_UUID, out uuid);

    if (index == index_s3)
      settings.set_string(BACKEND_KEY, "s3");
    else if (index == index_rackspace)
      settings.set_string(BACKEND_KEY, "rackspace");
    else if (index == index_u1)
      settings.set_string(BACKEND_KEY, "u1");
    else if (index == index_ssh)
      yield set_remote_info("sftp");
    else if (index == index_ftp)
      yield set_remote_info("ftp");
    else if (index == index_dav) {
      // Support not overriding davs with dav by checking current value
      var fsettings = DejaDup.get_settings(FILE_ROOT);
      var scheme = ConfigURLPart.read_uri_part(fsettings, FILE_PATH_KEY,
                                               ConfigURLPart.Part.SCHEME);
      if (scheme != "dav" && scheme != "davs")
        scheme = "dav"; // default to non-https, since we do default to encrypted backups
      yield set_remote_info(scheme);
    }
    else if (index == index_smb)
      yield set_remote_info("smb");
    else if (index == index_local)
      yield set_remote_info("file");
    else if (index == index_custom)
      yield set_remote_info(null);
    else if (uuid != null)
      yield set_volume_info(iter);
    else {
      warning("Unknown location index %i\n", index);
    }

    changed();
  }

  async void set_volume_info(Gtk.TreeIter iter)
  {
    // Grab volume from model
    Value vol_var;
    store.get_value(iter, COL_UUID, out vol_var);
    var uuid = vol_var.get_string();
    if (uuid == null) {
      warning("Invalid volume location at iter %s\n", store.get_string_from_iter(iter));
      return;
    }

    // First things first, we must remember that we set a volume
    var fsettings = DejaDup.get_settings(FILE_ROOT);
    fsettings.set_string(FILE_TYPE_KEY, "volume");
    settings.set_string(BACKEND_KEY, "file");

    var vol = BackendFile.find_volume_by_uuid(uuid);
    if (vol == null) {
      // Not an error, it's just not plugged in right now
      return;
    }

    yield BackendFile.set_volume_info(vol);
  }

  async void set_remote_info(string? scheme)
  {
    var fsettings = DejaDup.get_settings(FILE_ROOT);
    fsettings.delay();
    fsettings.set_string(FILE_TYPE_KEY, "normal");
    if (scheme != null)
      ConfigURLPart.write_uri_part(fsettings, FILE_PATH_KEY,
                                   ConfigURLPart.Part.SCHEME, scheme);
    fsettings.apply();
    settings.set_string(BACKEND_KEY, "file");
  }
}

}

