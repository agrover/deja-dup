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
  public bool show_deprecated {get; construct;}
  public bool read_only {get; construct;}

  public Gtk.Requisition hidden_size()
  {
    Gtk.Requisition pagereq;
    extras.get_preferred_size(null, out pagereq);
    pagereq.width = extras_max_width - pagereq.width + 20;
    pagereq.height = extras_max_height - pagereq.height + 20;
    return pagereq;
  }

  public ConfigLocation(bool show_deprecated, bool read_only, Gtk.SizeGroup? sg = null)
  {
    Object(show_deprecated: show_deprecated, read_only: read_only, label_sizes: sg);
  }

  int num_volumes = 0;

  int extras_max_width = 0;
  int extras_max_height = 0;

  // Keep a settings around for each type, and pass it off to our extra widgets.
  // We want to keep our own so that we can mark them read-only as needed.
  HashTable<string, FilteredSettings> all_settings;

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

    all_settings = new HashTable<string, FilteredSettings>(str_hash, str_equal);
    string[] roots = {"", GOA_ROOT, REMOTE_ROOT, DRIVE_ROOT, LOCAL_ROOT,
                      S3_ROOT, GCS_ROOT, OPENSTACK_ROOT, RACKSPACE_ROOT};
    foreach (string? root in roots) {
      all_settings.insert(root, new FilteredSettings(root, read_only));
    }

    Gtk.TreeIter iter;

    if (label_sizes == null)
      label_sizes = new Gtk.SizeGroup(Gtk.SizeGroupMode.HORIZONTAL);

    extras = new Gtk.EventBox();
    extras.visible_window = false;
    extras.border_width = 0;
    extras.show();

    remake_goa();
    BackendGOA.get_client_sync().account_added.connect(remake_goa);
    BackendGOA.get_client_sync().account_removed.connect(remake_goa);
    add_separator(Group.GOA_SEP);

    insert_clouds();

    add_entry(new ThemedIcon("network-server"),
              _("Network Server"), Group.REMOTE,
              new ConfigLocationCustom(label_sizes, all_settings[REMOTE_ROOT]));
    add_separator(Group.REMOTE_SEP);

    // And a local folder option
    add_entry(new ThemedIcon("folder"), _("Local Folder"),
              Group.LOCAL, new ConfigLocationFile(label_sizes, all_settings[LOCAL_ROOT]));

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
    textrenderer.ellipsize = Pango.EllipsizeMode.END;
    textrenderer.ellipsize_set = true;
    textrenderer.max_width_chars = 10;
    button.pack_start(textrenderer, false);
    button.add_attribute(textrenderer, "markup", Col.TEXT);

    // End of location combo

    mnemonic_widget = button;

    button.set_active(0); // worst case, activate first entry
    set_from_config.begin();

    set_location_widgets();
    button.changed.connect(handle_changed);

    // Watch any key that would cause a row switch
    watch_key(BACKEND_KEY, all_settings[""]);
    watch_key(GOA_ID_KEY, all_settings[GOA_ROOT]);
    watch_key(DRIVE_UUID_KEY, all_settings[DRIVE_ROOT]);
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
    // the quality of the experience. For example, the Google gvfs backend
    // at one point did not support querying filesystem free space. Without
    // that, the user experience would be poor. So we like to vet the service
    // before enabling.
    insert_goa("google");
    insert_goa("owncloud");

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

    var client = DejaDup.BackendGOA.get_client_sync();
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
                  "%s <i>(%s)</i>".printf(BackendGOA.get_provider_name(account),
                                          account.presentation_identity),
                  Group.GOA,
                  new ConfigLocationGoa(label_sizes, all_settings[GOA_ROOT], account),
                  account.id, type);
        found_one = true;
      }
    }

    // Does the user have an old configured type that is now gone?
    if (all_settings[GOA_ROOT].get_string(GOA_TYPE_KEY) == type &&
        client.lookup_by_id(all_settings[GOA_ROOT].get_string(GOA_ID_KEY)) == null)
    {
      found_one = false;
    }

    if (found_one)
      return;

    add_entry(provider.get_provider_icon(null),
              provider.get_provider_name(null),
              Group.GOA,
              new ConfigLocationGoa(label_sizes, all_settings[GOA_ROOT], null),
              "", type);
  }

  void insert_clouds()
  {
    // Note that we are using | not || here, because if show_deprecated is set,
    // we want to insert multiple backends.
    if (insert_cloud("s3", _("Amazon S3"), show_deprecated,
                     new ConfigLocationS3(label_sizes, all_settings[S3_ROOT])) |
        insert_cloud("gcs", _("Google Cloud Storage"), show_deprecated,
                     new ConfigLocationGCS(label_sizes, all_settings[GCS_ROOT])) |
        insert_cloud("u1", _("Ubuntu One"), false, /* u1 is more than deprecated */
                     new ConfigLocationU1(label_sizes)) |
        insert_cloud("rackspace", _("Rackspace Cloud Files"), show_deprecated,
                     new ConfigLocationRackspace(label_sizes, all_settings[RACKSPACE_ROOT])) |
        insert_cloud("openstack", _("OpenStack Swift"), show_deprecated,
                     new ConfigLocationOpenstack(label_sizes, all_settings[OPENSTACK_ROOT])))
      add_separator(Group.CLOUD_SEP);
  }

  bool insert_cloud(string id, string name, bool force_show, Gtk.Widget w)
  {
    // All cloud backends are deprecated in favor of GOA.  So we only show
    // them if they are already configured as the backend (either from older
    // users or they manually set the gsettings value).
    var backend = Backend.get_type_name(all_settings[""]);
    if (force_show || backend == id) {
      add_entry(new ThemedIcon("deja-dup-cloud"), name, Group.CLOUD, w, id);
      return true;
    } else
      return false;
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
      add_volume_full(v.get_uuid(), v.get_name(), v.get_icon());
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
              new ConfigLocationVolume(label_sizes, all_settings[DRIVE_ROOT]), uuid);
  }

  void update_volume(VolumeMonitor monitor, Volume v)
  {
    update_volume_full(v.get_uuid(), v.get_name(), v.get_icon());
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
    remove_volume_full(v.get_uuid());
  }

  void remove_volume_full(string uuid)
  {
    Gtk.TreeIter iter;
    if (!lookup_id(Group.VOLUMES, uuid, out iter))
      return;

    // Make sure it isn't the saved volume; we never want to remove that
    var saved_uuid = all_settings[DRIVE_ROOT].get_string(DRIVE_UUID_KEY);
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
    var uuid = all_settings[DRIVE_ROOT].get_string(DRIVE_UUID_KEY);
    if (uuid != "") {
      Icon vol_icon = null;
      try {
        vol_icon = Icon.new_for_string(all_settings[DRIVE_ROOT].get_string(DRIVE_ICON_KEY));
      }
      catch (Error e) {warning("%s\n", e.message);}

      var vol_name = all_settings[DRIVE_ROOT].get_string(DRIVE_NAME_KEY);

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
    var backend = Backend.get_type_name(all_settings[""]);
    if (backend == "gcs" ||
        backend == "openstack" ||
        backend == "rackspace" ||
        backend == "s3" ||
        backend == "u1") {
      group = Group.CLOUD;
      id = backend;
    }
    else if (backend == "goa") {
      group = Group.GOA;
      id = all_settings[GOA_ROOT].get_string(GOA_ID_KEY);
      goa_type = all_settings[GOA_ROOT].get_string(GOA_TYPE_KEY);

      // Test if the ID is no longer valid, but the type is... we'll fall back
      // to that.
      if (id != "" &&
          !lookup_id(group, id, null, goa_type) &&
          lookup_id(group, "", null, goa_type)) {
        id = "";
      }
    }
    else if (backend == "drive") {
      group = Group.VOLUMES;
      id = all_settings[DRIVE_ROOT].get_string(DRIVE_UUID_KEY);
    }
    else if (backend == "remote") {
      group = Group.REMOTE;
    }
    else if (backend == "local") {
      group = Group.LOCAL;
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
      all_settings[GOA_ROOT].set_string(GOA_ID_KEY, id == null ? "" : id);
      all_settings[GOA_ROOT].set_string(GOA_TYPE_KEY, goa_type);
      all_settings[""].set_string(BACKEND_KEY, "goa");
    }
    else if (group == Group.CLOUD)
      all_settings[""].set_string(BACKEND_KEY, id);
    else if (group == Group.VOLUMES)
      set_volume_info(iter);
    else if (group == Group.REMOTE)
      all_settings[""].set_string(BACKEND_KEY, "remote");
    else if (group == Group.LOCAL)
      all_settings[""].set_string(BACKEND_KEY, "local");
    else {
      warning("Unknown location: group %i, id: %s\n", group, id);
    }

    changed();
  }

  void set_volume_info(Gtk.TreeIter iter)
  {
    // Grab volume from model
    string uuid;
    store.get(iter, Col.ID, out uuid);
    if (uuid == null) {
      warning("Invalid volume location at iter %s\n", store.get_string_from_iter(iter));
      return;
    }

    // First things first, we must remember that we set a volume
    all_settings[""].set_string(BACKEND_KEY, "drive");
    all_settings[DRIVE_ROOT].set_string(DRIVE_UUID_KEY, uuid);

    var vol = VolumeMonitor.get().get_volume_for_uuid(uuid);
    if (vol == null) {
      // Not an error, it's just not plugged in right now
      return;
    }

    BackendDrive.update_volume_info(vol, all_settings[DRIVE_ROOT]);
  }

  public Backend get_backend()
  {
    var type = Backend.get_type_name(all_settings[""]);
    var sub_settings = all_settings[type];
    return Backend.get_for_type(type, sub_settings);
  }
}

}

