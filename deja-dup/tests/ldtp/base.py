#!/usr/bin/env python
# -*- Mode: Python; indent-tabs-mode: nil; tab-width: 2; coding: utf-8 -*-
#
# This file is part of Déjà Dup.
# For copyright information, see AUTHORS.
#
# Déjà Dup is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# Déjà Dup is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Déjà Dup.  If not, see <http://www.gnu.org/licenses/>.

import os
import sys
import signal
import subprocess
from os import environ
import tempfile
import ldtp
import glob
import re
import traceback
import time

srcdir = "."
temp_dir = None
cleanup_dirs = []
cleanup_mounts = []
cleanup_pids = []
cleanup_envs = []
have_run = False

def create_temp_dir():
  global temp_dir, cleanup_dirs
  if temp_dir is not None:
    return
  if 'DEJA_DUP_TEST_TMP' in environ:
    temp_dir = environ['DEJA_DUP_TEST_TMP']
    os.system('mkdir -p %s' % temp_dir)
    # Don't automatically clean it
  else:
    temp_dir = tempfile.mkdtemp()
    cleanup_dirs += [temp_dir]

def get_temp_name(extra, make=False):
  global temp_dir
  create_temp_dir()
  if make and not os.path.exists(temp_dir + '/' + extra):
    os.makedirs(temp_dir + '/' + extra)
  return temp_dir + '/' + extra

# The current directory is always the 'builddir'.  But 'srcdir' may be different
# if we're running inside a distcheck for example.  So note that we check for
# srcdir and use it if available.  Else, default to current directory.

def setup(root_prompt = False):
  global cleanup_dirs, cleanup_pids, cleanup_envs, ldtp, latest_duplicity, srcdir

  srcdir = environ.get('srcdir')
  if not srcdir:
    srcdir = '.'
  
  builddir = environ.get('builddir')
  if not builddir:
    builddir = '.'
  
  environ['LANG'] = 'C'
  environ['DEJA_DUP_TESTING'] = '1'
  environ['DEJA_DUP_TOOLS_PATH'] = '%s/../../libdeja/tools/duplicity' % (builddir)

  if 'DEJA_DUP_TEST_SYSTEM' in environ and environ['DEJA_DUP_TEST_SYSTEM'] == '1':
    extra_paths = ''
  else:
    extra_paths = ':'.join(['%s/../../%s' % (builddir, x) for x in ['deja-dup', 'preferences', 'monitor']]) + ':'
  extra_pythonpaths = ''

  environ['XDG_CACHE_HOME'] = get_temp_name('cache')
  environ['XDG_CONFIG_HOME'] = get_temp_name('config')
  environ['XDG_DATA_HOME'] = get_temp_name('share')
  environ['XDG_DATA_DIRS'] = "%s:/usr/share/" % environ['XDG_DATA_HOME']
  output = subprocess.Popen(['dbus-launch'], stdout=subprocess.PIPE).communicate()[0]
  lines = output.split('\n')
  for line in lines:
      parts = line.split('=', 1)
      if len(parts) == 2:
          if parts[0] == 'DBUS_SESSION_BUS_PID': # cleanup at end
              cleanup_pids += [int(parts[1])]
          os.environ[parts[0]] = parts[1]

  # Shutdown ldtpd so that it will restart and pick up new dbus environment
  #os.system('pkill -f ldtpd\\.main; sleep 1')
  #ldtp.getwindowlist()/reload(ldtp)

  process = subprocess.Popen(['/usr/lib/dconf/dconf-service'], stdout=subprocess.PIPE)
  cleanup_pids += [process.pid]

  environ['PYTHONPATH'] = extra_pythonpaths + (environ['PYTHONPATH'] if 'PYTHONPATH' in environ else '')
  environ['PATH'] = extra_paths + environ['PATH']
  environ['GNUPGHOME'] = get_temp_name('gnupg', True)
  
  #environ['G_DEBUG'] = 'fatal_warnings'
  
  os.system('mkdir -p %s' % environ['XDG_CONFIG_HOME'])
  os.system('mkdir -p %s/glib-2.0/schemas/' % environ['XDG_DATA_HOME'])

  # Now install default schema into our temporary config dir
  schemas = glob.glob("/usr/share/glib-2.0/schemas/org.gtk.*")
  schemas.append("%s/../../data/org.gnome.DejaDup.gschema.xml" % builddir)
  if os.system('cp %s %s/glib-2.0/schemas/ && glib-compile-schemas %s/glib-2.0/schemas/' % (' '.join(schemas), environ['XDG_DATA_HOME'], environ['XDG_DATA_HOME'])):
    raise Exception('Could not install settings schema')

  # Copy interface files into place as well
  os.system("mkdir -p %s/deja-dup/ui" % environ['XDG_DATA_HOME'])
  os.system("cp %s/../../data/ui/* %s/deja-dup/ui" % (srcdir, environ['XDG_DATA_HOME']))

  set_settings_value("location-mode", "'filename-entry'",
                     root='org.gtk.Settings.FileChooser:/org/gtk/settings/file-chooser/')

  set_settings_value("root-prompt", 'true' if root_prompt else 'false')

def cleanup(success):
  global temp_dir, cleanup_dirs, cleanup_mounts, cleanup_pids, cleanup_envs
  for d in cleanup_mounts:
    os.system('pkexec umount %s' % d)
  for d in cleanup_dirs:
    os.system("rm -rf %s" % d)
  for p in cleanup_pids:
    try:
      os.kill(p, signal.SIGTERM)
    except:
      pass
  for e in cleanup_envs:
    os.environ[e] = ''
  cleanup_mounts = []
  cleanup_dirs = []
  cleanup_pids = []
  cleanup_envs = []
  #os.system('kill %s' % os.environ['GNOME_KEYRING_PID'])
  temp_dir = None
  if success:
    os.system('bash -c "echo -e \'\e[32mPASSED\e[0m\'"')
  else:
    os.system('bash -c "echo -e \'\e[31mFAILED\e[0m\'"')
    sys.exit(1)

def set_settings_value(key, value, schema = None, root = None):
  if root is None:
    root = 'org.gnome.DejaDup'
  if schema:
    fullschema = root + '.' + schema
  else:
    fullschema = root
  cmd = ['gsettings', 'set', fullschema, key, value]
  sp = subprocess.Popen(cmd, stdout=subprocess.PIPE)
  sp.communicate()
  if sp.returncode:
    raise Exception('Could not set key %s to %s' % (key, value))
  # make sure everything is set correctly
  setval = get_settings_value(key, schema=schema, root=root)
  assert setval == value, "%s != %s" % (setval, value)

def get_settings_value(key, schema = None, root = None):
  if root is None:
    root = 'org.gnome.DejaDup'
  if schema:
    fullschema = root + '.' + schema
  else:
    fullschema = root
  cmd = ['gsettings', 'get', fullschema, key]
  sp = subprocess.Popen(cmd, stdout=subprocess.PIPE)
  pout = sp.communicate()[0]
  if sp.returncode:
    raise Exception('Could not get key %s' % (key))
  pout = pout.split('@as ', 1)[-1] # chop off leading @as if any (on empty arrays)
  return pout.strip()

def start_deja_dup(args=[], executable='deja-dup', waitfor='frmBackup', debug=False):
  assert executable != 'deja-dup' or args # must be some argument
  # Rather than running debug, it's sometimes more effective to run
  # "./interactive shell" and then run gdb directly
  cmd = [executable] + args
  if os.environ.get('DEJA_DUP_TEST_VALGRIND') == "1":
    global have_run
    if have_run:
      ldtp.wait(5) # pause between runs for valgrind to finish up
    else:
      have_run = True
    cmd = ['valgrind', '--gen-suppressions=all', '--leak-check=full',
           '--track-origins=yes', '--show-possibly-lost=no',
           '--error-exitcode=1', '--suppressions=valgrind.sup'] + cmd
  if debug:
    cmd = ['gnome-terminal', '-x', 'gdb', '-ex', 'run'] + cmd
  # FIXME gtk3/gail3 seem problematic with always-malloc
  #environ['G_SLICE'] = 'always-malloc,debug-blocks'
  #environ['G_SLICE'] = 'debug-blocks'
  environ['G_DEBUG'] = 'gc-friendly' if not environ.get('G_DEBUG') else environ['G_DEBUG'] + ',gc-friendly'
  subprocess.Popen(cmd)
  if waitfor is not None:
    waitforgui(waitfor)

def quit():
  if ldtp.guiexist('frmBackup'):
    ldtp.closewindow('frmBackup')
  if ldtp.guiexist('frmBackUp'):
    ldtp.closewindow('frmBackUp')

def run(method):
  success = False
  try:
    success = method()
    if success is None:
      success = True # for tests that use exceptions as errors and return nothing
  except:
    traceback.print_exc()
  finally:
    quit()
    cleanup(success)

def get_manifest_date(filename):
  return re.sub('.*\.([0-9TZ]+)\.manifest.*', '\\1', filename)

def list_manifests(dest='local'):
  destdir = get_temp_name(dest)
  files = sorted(glob.glob('%s/*.manifest*' % destdir), key=get_manifest_date)
  files = filter(lambda x: x.count('duplicity-full') == 0 or x.count('.to.') == 0, files) # don't get the in-between manifests
  return (destdir, files)

def num_manifests(mtype=None, dest='local'):
  destdir, files = list_manifests(dest)
  if mtype:
    files = filter(lambda x: manifest_type(x) == mtype, files)
  return len(files)

def manifest_type(fn):
  # fn looks like duplicity-TYPE.DATES.manifest
  return fn.split('.')[0].split('-')[1]

def guiexist(frm, obj, prefix=False):
  if not prefix:
    return obj if ldtp.guiexist(frm, obj) else None
  else:
    objs = ldtp.getobjectlist(frm)
    objs = filter(lambda x: x.startswith(obj), objs)
    return objs[0] if objs else None

def guivisible(frm, obj, prefix=False):
  obj = guiexist(frm, obj, prefix)
  if not obj:
    return False
  states = ldtp.getallstates(frm, obj)
  return ldtp.state.VISIBLE in states

def wait_for_encryption(dlg, encrypt):
  count = 0
  max_count = 10
  while count < max_count:
    if guivisible(dlg, 'txtEncryptionpassword'):
      if encrypt:
        ldtp.settextvalue(dlg, 'txtEncryptionpassword', 'test')
        if guivisible(dlg, 'txtConfirmpassword'):
          ldtp.settextvalue(dlg, 'txtConfirmpassword', 'test')
      else:
        ldtp.click(dlg, 'rbtnAllowrestoringwithoutapassword')
      ldtp.click(dlg, 'btnContinue')
      break
    time.sleep(1)
    count += 1
  assert count < max_count, max_count

def wait_for_finish(dlg, obj, max_count, prefix=False):
  count = 0
  while count < max_count:
    if obj is not None and guivisible(dlg, obj, prefix):
      break
    elif obj is None and not ldtp.guiexist(dlg):
      break
    ldtp.wait(1)
    count += 1
  assert count < max_count, max_count

def waitforgui(frm):
  assert ldtp.waittillguiexist(frm)

def remap(frm):
  ldtp.wait(1) # sometimes (only for newer versions?) ldtp needs a second to catch its breath
  ldtp.remap(frm) # in case this is second time we've run it

def set_file_list(dlg, obj, addObj, removeObj, files):
  # Clear existing items
  while (True):
    try:
      ldtp.selectrowindex(dlg, obj, 0)
      ldtp.click(dlg, removeObj)
    except:
      break

  # FIXME compiz and modal windows tend to not work with ldtp
  set_settings_value('include-list' if obj == 'tblIncludeList' else 'exclude-list',
                     '[%s]' % ', '.join(["'%s'" % os.path.abspath(x) for x in files]))

def wait_for_combo(frm, obj, value):
  count = 0
  while not ldtp.ischildselected(frm, obj, value) and count < 30:
    ldtp.wait(1)
    count = count + 1

def walk_prefs(backend, dest, includes, excludes):
  if backend == 'file':
    ldtp.selecttab('frmBackup', 'ptlCategories', 'Storage')

    if dest is None:
      dest = get_temp_name('local')
      os.system('mkdir -p %s' % dest)
    elif dest[0] != '/' and dest.find(':') == -1:
      dest = os.getcwd()+'/'+dest

    ldtp.comboselect('frmBackup', 'cboLocation', 'Local Folder')
    wait_for_combo('frmBackup', 'cboLocation', 'Local Folder') # this menu acts slowly, because of custom widgets
    remap('frmBackup')
    ldtp.settextvalue('frmBackup', 'txtFileFolder', dest)
    ldtp.wait(1) # without this, sometimes ldtp moves so fast, deja-dup doesn't notice dest

  ldtp.selecttab('frmBackup', 'ptlCategories', 'Folders')
  if includes is not None:
    set_file_list('frmBackup', 'tblIncludeList', 'btnIncludeListAdd', 'btnIncludeListRemove', includes)
  if excludes is not None:
    set_file_list('frmBackup', 'tblExcludeList', 'btnExcludeListAdd', 'btnExcludeListRemove', excludes)

def strip_obj_name(obj):
  return obj.replace("_", "").replace(".", "") if obj is not None else None

def backup_simple(finish=True, error=None, timeout=400, backend = None,
                  encrypt = True, dest = None, includes = None, excludes = None,
                  add_srcdir = True):
  global srcdir
  if add_srcdir:
    if includes is not None:
      includes = [os.path.join(srcdir, f) for f in includes]
    if excludes is not None:
      excludes = [os.path.join(srcdir, f) for f in excludes]

  start_deja_dup(executable='deja-dup-preferences')

  if guivisible('frmBackup', 'btnJustshowmybackupsettings'):
    ldtp.click('frmBackup', 'btnJustshowmybackupsettings')
    remap('frmBackup')

  if backend is not None or includes is not None or excludes is not None:
    walk_prefs(backend=backend, dest=dest, includes=includes,
               excludes=excludes)

  ldtp.selecttab('frmBackup', 'ptlCategories', 'Overview')
  ldtp.click('frmBackup', 'btnBackUpNow')
  waitforgui('frmBackUp')

  if encrypt is not None:
    wait_for_encryption('frmBackUp', encrypt)

  if finish:
    error = strip_obj_name(error)
    wait_for_finish('frmBackUp', error, timeout, prefix=True)

def walk_restore_prefs(dlg, backend, dest):
  if backend == 'file':
    ldtp.comboselect(dlg, 'cboLocation', 'Local Folder')
    wait_for_combo(dlg, 'cboLocation', 'Local Folder') # this menu acts slowly, because of custom widgets
    remap(dlg)
    ldtp.settextvalue(dlg, 'txtFileFolder', dest)
    ldtp.wait(1) # without this, sometimes ldtp moves so fast, deja-dup doesn't notice dest

def restore_simple(path, date=None, backend = None, encrypt=True, dest = None):
  start_deja_dup(executable='deja-dup-preferences')

  if guivisible('frmBackup', 'btnIwanttorestorefilesfromapreviousbackup…'):
    ldtp.click('frmBackup', 'btnIwanttorestorefilesfromapreviousbackup…')
  else:
    ldtp.selecttab('frmBackup', 'ptlCategories', 'Overview')
    ldtp.click('frmBackup', 'btnRestore…')

  waitforgui('frmRestore')

  if backend is not None:
    walk_restore_prefs('frmRestore', backend, dest)  
  ldtp.click('frmRestore', 'btnForward')

  wait_for_finish('frmRestore', 'lblRestoreFromWhen?', 200)
  if date:
    ldtp.comboselect('frmRestore', 'cboDate', date)
  ldtp.click('frmRestore', 'btnForward')

  ldtp.click('frmRestore', 'rbtnRestoretospecificfolder')
  ldtp.comboselect('frmRestore', 'cboRestorefolder', 'Other...')
  waitforgui('dlgChoosedestinationforrestoredfiles')
  # Make sure path ends in '/'
  if path[-1] != '/':
    path += '/'
  ldtp.selectlastrow('dlgChoosedestinationforrestoredfiles', 'tblPlaces') # must switch away from Recent Files view to get txtLocation
  ldtp.wait(1) # give the dlg a second to settle
  ldtp.settextvalue('dlgChoosedestinationforrestoredfiles', 'txtLocation', path)
  ldtp.click('dlgChoosedestinationforrestoredfiles', 'btnOpen')
  ldtp.wait(1) # give the combo a second to settle
  ldtp.click('frmRestore', 'btnForward')
  ldtp.wait(1) # give the dlg a second to settle
  ldtp.click('frmRestore', 'btnRestore')

  if encrypt is not None:
    wait_for_encryption('frmRestore', encrypt)

  wait_for_finish('frmRestore', 'lblYourfilesweresuccessfullyrestored', 400)
  ldtp.click('frmRestore', 'btnClose')
  ldtp.waittillguinotexist('frmRestore')

def restore_missing(files, path):
  args = ['--restore-missing', path]
  start_deja_dup(args=args, waitfor='frmRestore')
  wait_for_finish('frmRestore', 'lblScanningfinished', 200)
  for f in files:
    index = ldtp.gettablerowindex('frmRestore', 'tbl0', f)
    if index != -1:
      ldtp.checkrow('frmRestore', 'tbl0', index)
  ldtp.click('frmRestore', 'btnForward')
  ldtp.click('frmRestore', 'btnRestore')
  wait_for_encryption('frmRestore', True)
  if len(files) == 1:
    lbl = 'lblYourfilewassuccessfullyrestored'
  else:
    lbl = 'lblYourfilesweresuccessfullyrestored'
  wait_for_finish('frmRestore', lbl, 200)
  ldtp.click('frmRestore', 'btnClose')

def file_equals(path, contents):
  f = open(path)
  return f.read() == contents
