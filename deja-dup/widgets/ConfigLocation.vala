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
  enum Col {
    ICON = 0,
    TEXT,
    SORT,
    ID,
    PAGE,
    GROUP,
    GOA_TYPE,
    NUM
  }

  enum Group {
    GOA = 0,
    GOA_SEP,
    CLOUD,
    CLOUD_SEP,
    REMOTE,
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

  bool have_clouds;
  int num_volumes = 0;

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
    store = new Gtk.ListStore(Col.NUM, typeof(Icon), typeof(string), typeof(string),
                              typeof(string), typeof(ConfigLocationTable),
                              typeof(int), typeof(string));
    sort_model = new Gtk.TreeModelSort.with_model(store);
    sort_model.set_sort_column_id(Col.SORT, Gtk.SortType.ASCENDING);
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

    remake_goa();
    BackendGoa.get_client_sync().account_added.connect(remake_goa);
    BackendGoa.get_client_sync().account_removed.connect(remake_goa);

    add_separator(Group.GOA_SEP);

    // Insert cloud providers
    insert_u1();
    insert_s3();
    insert_gcs();
    insert_rackspace();
    insert_openstack();

    add_entry(new ThemedIcon("network-server"),
              _("Network Server"), Group.REMOTE,
              new ConfigLocationCustom(label_sizes));

    add_separator(Group.REMOTE_SEP);

    // And a local folder option
    add_entry(new ThemedIcon("folder"), _("Local Folder"),
              Group.LOCAL, new ConfigLocationFile(label_sizes), "file");

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
    button.add_attribute(pixrenderer, "gicon", Col.ICON);

    var textrenderer = new Gtk.CellRendererText();
    textrenderer.xpad = 6;
    button.pack_start(textrenderer, true);
    button.add_attribute(textrenderer, "markup", Col.TEXT);

    // End of location combo

    mnemonic_widget = button;

    button.set_active(0); // worst case, activate first entry
    set_from_config.begin();

    set_location_widgets();
    button.changed.connect(handle_changed);

    watch_key(BACKEND_KEY);
    watch_key(FILE_PATH_KEY, DejaDup.get_settings(FILE_ROOT));
  }

  void clear_group(int group)
  {
    Gtk.TreeIter iter;
    bool loop = store.get_iter_first(out iter);
    while (loop) {
      int iter_group;
      store.get(iter, Col.GROUP, out iter_group);
      if (iter_group == group)
        loop = store.remove(ref iter);
      else
        loop = store.iter_next(ref iter);
    }
  }

  bool current_iter(out Gtk.TreeIter iter)
  {
    Gtk.TreeIter iter0;
    iter = Gtk.TreeIter();
    if (!button.get_active_iter(out iter0))
      return false;
    sort_model.convert_iter_to_child_iter(out iter, iter0);
    return true;
  }

  void remake_goa()
  {
    int group = -1;
    string id = null;
    string goa_type = null;
    Gtk.TreeIter iter;
    if (current_iter(out iter))
      store.get(iter, Col.GROUP, out group, Col.ID, out id, Col.GOA_TYPE, out goa_type);

    // First, clear any existing GOA accounts (this might be called a second
    // time when accounts are removed or added).
    clear_group(Group.GOA);

    // Insert GNOME Online Account providers. We use a whitelist (rather than
    // adding any that support the Files interface) because we want to control
    // the quality of the experience. For example, the Google gvfs backend,
    // at the time of writing, does not support querying filesystem free space.
    // Without that, the user experience would be poor.
    insert_goa("owncloud");
    // TODO: We can enable Google if we have duplicity >= 0.7.14 and GNOME
    //       bug 785870 is fixed (needs to report FS size) and maybe bug
    //       768594 too (timeout permission issues).
    //insert_goa("google");

    if (group == Group.GOA) {
      // Find place again
      if (id != null && lookup_id(group, id, out iter))
        set_active_iter(iter);
      else if (lookup_id(group, null, out iter, goa_type))
        set_active_iter(iter);
      // above should always work, we make sure to keep one of each type
    }
  }

  void insert_goa(string type)
  {
    /**
     * There are two cases:
     * 1) Some number of existing accounts for this type, in which case we add
     *    all of them.
     * 2) Else if there no existing accounts, we offer a single entry that lets
     *    them add an account of this type.
     */

    var provider = Goa.Provider.get_for_provider_type(type);

    // sanity check
    if (!(Goa.ProviderFeatures.FILES in provider.get_provider_features())) {
      warning("Tried to add GOA provider %s but it doesn't support the Files interface", type);
      return;
    }

    var client = DejaDup.BackendGoa.get_client_sync();
    bool found_one = false;
    foreach (Goa.Object obj in client.get_accounts()) {
      var account = obj.get_account();
      if (account != null &&
          !account.is_temporary &&
          account.provider_type == type)
      {
        Icon icon = null;
        try {
          icon = Icon.new_for_string(account.provider_icon);
        }
        catch (Error e) {warning("%s", e.message);}
        add_entry(icon,
                  "%s <i>(%s)</i>".printf(account.provider_name,
                                          account.presentation_identity),
                  Group.GOA,
                  new ConfigLocationGoa(label_sizes, account),
                  account.id, type);
        found_one = true;
      }
    }

    // Does the user have an old configured type that is now gone?
    var settings = DejaDup.get_settings(GOA_ROOT);
    if (settings.get_string(GOA_TYPE_KEY) == type &&
        BackendGoa.get_object_from_settings() == null)
    {
      found_one = false;
    }

    if (found_one)
      return;

    add_entry(provider.get_provider_icon(null),
              provider.get_provider_name(null),
              Group.GOA,
              new ConfigLocationGoa(label_sizes, null),
              "", type);
  }

  delegate void CloudCallback();

  void insert_s3() {
    insert_cloud_if_available("s3", BackendS3.get_checker(),
                              new ThemedIcon("deja-dup-cloud"),
                              _("Amazon S3"),
                              new ConfigLocationS3(label_sizes),
                              insert_s3);
  }

  void insert_gcs() {
    insert_cloud_if_available("gcs", BackendGCS.get_checker(),
                              new ThemedIcon("deja-dup-cloud"),
                              _("Google Cloud Storage"),
                              new ConfigLocationGCS(label_sizes),
                              insert_gcs);
  }

  void insert_u1() {
    // No longer functional.
    // Only shown if user already had it configured, for migration purposes.
    insert_cloud_if_available("u1", null,
                              new ThemedIcon.from_names({"ubuntuone",
                                                         "ubuntuone-installer",
                                                         "deja-dup-cloud"}),
                              _("Ubuntu One"),
                              new ConfigLocationU1(label_sizes),
                              insert_u1);
  }

  void insert_rackspace() {
    insert_cloud_if_available("rackspace", BackendRackspace.get_checker(),
                              new ThemedIcon("deja-dup-cloud"),
                              _("Rackspace Cloud Files"),
                              new ConfigLocationRackspace(label_sizes),
                              insert_rackspace);
  }

  void insert_openstack() {
    insert_cloud_if_available("openstack", BackendOpenstack.get_checker(),
                              new ThemedIcon("deja-dup-cloud"),
                              _("OpenStack Swift"),
                              new ConfigLocationOpenstack(label_sizes),
                              insert_openstack);
  }

  void insert_cloud_if_available(string id, Checker? checker,
                                 Icon icon, string name,
                                 Gtk.Widget? w,
                                 CloudCallback cb)
  {
    var backend = Backend.get_default_type();
    if (backend == id || (checker != null && checker.complete && checker.available)) {
      add_entry(icon, name, Group.CLOUD, w, id);
      if (!have_clouds) {
        add_separator(Group.CLOUD_SEP);
        have_clouds = true;
      }
    }
    else if (checker != null && !checker.complete) {
      // Call ourselves when we've got enough information.  Also make sure to
      // set from config again, in case in a previous set_from_config, we
      // weren't available in the combo yet.
      checker.notify["complete"].connect(() => {cb(); set_from_config.begin();});
    }
  }

  bool is_allowed_volume(Volume vol)
  {
    // Unfortunately, there is no convenience API to ask, "what type is this
    // GVolume?"  Instead, we ask for the icon and look for standard icon
    // names to determine type.
    // Maybe there is a way to distinguish between optical drives and flash
    // drives?  But I'm not sure what it is right now.

    if (vol.get_drive() == null)
      return false;

    // Don't add internal hard drives
    if (!vol.get_drive().is_removable())
      return false;

    // First, if the icon is emblemed, look past emblems to real icon
    Icon icon_in = vol.get_icon();
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
    model.get_value(iter, Col.TEXT, out text_var);
    weak string text = text_var.get_string();
    return text == null;
  }

  void add_entry(Icon? icon, string label, Group category,
                 Gtk.Widget? page = null, string? id = null,
                 string? goa_type = null)
  {
    var index = store.iter_n_children(null);

    Gtk.TreeIter iter;
    store.insert_with_values(out iter, index, Col.ICON, icon, Col.TEXT, label,
                             Col.SORT, "%d%s".printf((int)category, label),
                             Col.ID, id, Col.PAGE, page, Col.GROUP, category,
                             Col.GOA_TYPE, goa_type);

    if (page != null) {
      Gtk.Requisition pagereq;
      page.show_all();
      page.get_preferred_size(null, out pagereq);
      extras_max_width = int.max(extras_max_width, pagereq.width);
      extras_max_height = int.max(extras_max_height, pagereq.height);
    }
  }

  void add_separator(Group category)
  {
    var index = store.iter_n_children(null);

    Gtk.TreeIter iter;
    store.insert_with_values(out iter, index, Col.SORT, "%d".printf((int)category),
                             Col.TEXT, null, Col.GROUP, category);
  }

  // A null id is a wildcard, will return first valid result
  bool lookup_id(int group, string? id, out Gtk.TreeIter iter_in, string? goa_type = null)
  {
    Gtk.TreeIter iter;
    iter_in = Gtk.TreeIter();
    if (store.get_iter_first(out iter)) {
      do {
        int iter_group;
        string iter_id;
        string iter_goa_type;
        store.get(iter, Col.GROUP, out iter_group, Col.ID, out iter_id, Col.GOA_TYPE, out iter_goa_type);
        if (iter_group == group &&
            (id == null || iter_id == id) &&
            (goa_type == null || iter_goa_type == goa_type))
        {
          iter_in = iter;
          return true;
        }
      } while (store.iter_next(ref iter));
    }

    return false;
  }

  void add_volume(VolumeMonitor monitor, Volume v)
  {
    if (is_allowed_volume(v))
    {
      add_volume_full(v.get_identifier(VolumeIdentifier.UUID),
                      v.get_name(), v.get_icon());
    }
  }

  void add_volume_full(string uuid, string name, Icon icon)
  {
    Gtk.TreeIter iter;
    if (lookup_id(Group.VOLUMES, uuid, out iter)) {
      update_volume_full(uuid, name, icon);
      return;
    }

    if (num_volumes++ == 0)
      add_separator(Group.VOLUMES_SEP);
    add_entry(icon, name, Group.VOLUMES,
              new ConfigLocationVolume(label_sizes), uuid);
  }

  void update_volume(VolumeMonitor monitor, Volume v)
  {
    update_volume_full(v.get_identifier(VolumeIdentifier.UUID),
                       v.get_name(), v.get_icon());
  }

  void update_volume_full(string uuid, string name, Icon icon)
  {
    Gtk.TreeIter iter;
    if (!lookup_id(Group.VOLUMES, uuid, out iter))
      return;

    store.set(iter, Col.ICON, icon, Col.TEXT, name, Col.ID, uuid);
  }

  void remove_volume(VolumeMonitor monitor, Volume v)
  {
    remove_volume_full(v.get_identifier(VolumeIdentifier.UUID));
  }

  void remove_volume_full(string uuid)
  {
    Gtk.TreeIter iter;
    if (!lookup_id(Group.VOLUMES, uuid, out iter))
      return;

    // Make sure it isn't the saved volume; we never want to remove that
    var fsettings = DejaDup.get_settings(FILE_ROOT);
    var saved_uuid = fsettings.get_string(FILE_UUID_KEY);
    if (uuid == saved_uuid)
      return;

    store.remove(ref iter);

    if (--num_volumes == 0) {
      Gtk.TreeIter sep_iter;
      if (lookup_id(Group.VOLUMES_SEP, null, out sep_iter))
        store.remove(ref sep_iter);
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
    int group = -1;
    string id = null;
    string goa_type = null;

    // Check the backend type, then GIO uri if needed
    var backend = Backend.get_default_type();
    if (backend == "gcs" ||
        backend == "openstack" ||
        backend == "rackspace" ||
        backend == "s3" ||
        backend == "u1") {
      group = Group.CLOUD;
      id = backend;
    }
    else if (backend == "goa") {
      var goa_settings = DejaDup.get_settings(GOA_ROOT);
      group = Group.GOA;
      id = goa_settings.get_string(GOA_ID_KEY);
      goa_type = goa_settings.get_string(GOA_TYPE_KEY);

      // Test if the ID is no longer valid, but the type is... we'll fall back
      // to that.
      if (id != "" &&
          !lookup_id(group, id, null, goa_type) &&
          lookup_id(group, "", null, goa_type)) {
        id = "";
      }
    }
    else if (backend == "file") {
      var fsettings = DejaDup.get_settings(FILE_ROOT);

      if (fsettings.get_string(FILE_TYPE_KEY) == "volume") {
        if (update_saved_volume()) {
          group = Group.VOLUMES;
          id = fsettings.get_string(FILE_UUID_KEY);
        }
      }
      else { // normal
        // If we are already on 'custom location', don't switch away from it
        // to another toplevel entry
        Gtk.TreeIter iter;
        if (!current_iter(out iter))
          return;

        int cur_group;
        store.get(iter, Col.GROUP, out cur_group);

        if (cur_group == Group.REMOTE)
          return;

        // OK, we can continue
        var scheme = ConfigURLPart.read_uri_part(fsettings, FILE_PATH_KEY,
                                                 ConfigURLPart.Part.SCHEME);
        switch (scheme) {
        case "file": group = Group.LOCAL;  break;
        default:     group = Group.REMOTE; break;
        }
      }
    }

    if (group >= 0) {
      Gtk.TreeIter saved_iter;
      if (lookup_id(group, id, out saved_iter, goa_type))
        set_active_iter(saved_iter);
    }
  }

  void set_location_widgets()
  {
    var current = extras.get_child();
    if (current != null)
      extras.remove(current);

    Gtk.TreeIter iter;
    Value page_var;
    if (current_iter(out iter)) {
      store.get_value(iter, Col.PAGE, out page_var);
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
    Gtk.TreeIter iter;
    if (!current_iter(out iter))
      return;

    int group;
    string id;
    string goa_type;
    store.get(iter, Col.GROUP, out group, Col.ID, out id, Col.GOA_TYPE, out goa_type);

    if (group == Group.GOA) {
      var goa_settings = DejaDup.get_settings(GOA_ROOT);
      goa_settings.set_string(GOA_ID_KEY, id == null ? "" : id);
      goa_settings.set_string(GOA_TYPE_KEY, goa_type);
      settings.set_string(BACKEND_KEY, "goa");
    }
    else if (group == Group.CLOUD)
      settings.set_string(BACKEND_KEY, id);
    else if (group == Group.VOLUMES)
      yield set_volume_info(iter);
    else if (group == Group.REMOTE || group == Group.LOCAL) {
      yield set_remote_info(id);
    }
    else {
      warning("Unknown location: group %i, id: %s\n", group, id);
    }

    changed();
  }

  async void set_volume_info(Gtk.TreeIter iter)
  {
    // Grab volume from model
    Value vol_var;
    store.get_value(iter, Col.ID, out vol_var);
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
    // Since these changes span two settings roots, we will receive two
    // changed() signals and thus run set_from_config twice.  To prevent
    // dropping the second signal on the floor (as ConfigWidget does if it's
    // in the middle of handling the first), we'll manually trigger the update.
    syncing = true;

    var fsettings = DejaDup.get_settings(FILE_ROOT);
    fsettings.delay();
    fsettings.set_string(FILE_TYPE_KEY, "normal");
    if (scheme != null)
      ConfigURLPart.write_uri_part(fsettings, FILE_PATH_KEY,
                                   ConfigURLPart.Part.SCHEME, scheme);
    fsettings.apply();
    settings.set_string(BACKEND_KEY, "file");

    syncing = false;
    yield set_from_config();
  }
}

}

