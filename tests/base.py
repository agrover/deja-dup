#!/usr/bin/env python
# -*- Mode: Python; indent-tabs-mode: nil; tab-width: 2; coding: utf-8 -*-
#
# This file is part of Déjà Dup.
# © 2008,2009,2010,2011 Michael Terry <mike@mterry.name>
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
import atexit
import subprocess
from os import environ, path, remove
import tempfile
import ldtp
import glob
import re
import traceback

latest_duplicity = '0.6.11'

srcdir = "."
temp_dir = None
cleanup_dirs = []
cleanup_mounts = []
cleanup_pids = []
cleanup_envs = []
have_run = False

def skip():
  os.system('bash -c "echo -e \'\e[32mSKIPPED\e[0m\'"')
  sys.exit(0)

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

def setup(start = True, args=[''], root_prompt = False):
  global cleanup_dirs, cleanup_pids, cleanup_envs, ldtp, latest_duplicity, srcdir

  if not os.environ.get('DISPLAY'):
    # Run a Xvfb session to allow running the test suite without a monitor
    proc = subprocess.Popen(['Xvfb', ':5'], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    ldtp.wait(1)
    cleanup_pids.append(proc.pid)
    os.environ['DISPLAY'] = ':5'
    cleanup_envs.append('DISPLAY')

  srcdir = environ.get('srcdir')
  if not srcdir:
    srcdir = '.'
  
  builddir = environ.get('builddir')
  if not builddir:
    builddir = '.'
  
  environ['LANG'] = 'C'
  environ['DEJA_DUP_TESTING'] = '1'

  extra_paths = ':'.join(['%s/../%s' % (builddir, x) for x in ['deja-dup', 'preferences', 'applet', 'monitor']]) + ':'
  extra_pythonpaths = ''
  
  version = None
  if 'DEJA_DUP_TEST_VERSION' in environ:
    version = environ['DEJA_DUP_TEST_VERSION']
  if version is None:
    version = latest_duplicity
  if version != 'system':
    os.system('%s/build-duplicity %s' % (srcdir, version))
    duproot = '%s/duplicity/duplicity-%s' % (srcdir, version)
    if not os.path.exists(duproot):
      print 'Could not find duplicity %s' % version
      sys.exit(1)
    
    extra_paths += duproot + '/usr/local/bin:'
    
    # Also add the module path, but we have to find it
    libdir = duproot + '/usr/local/lib/'
    libdir += os.listdir(libdir)[0] # python2.5 or python2.6, etc
    libdir += '/'
    libdir += os.listdir(libdir)[0] # site-packages or dist-packages
    libdir += ':'
    extra_pythonpaths += libdir
  
  environ['XDG_CACHE_HOME'] = get_temp_name('cache')
  environ['XDG_CONFIG_HOME'] = get_temp_name('config')
  environ['XDG_DATA_HOME'] = get_temp_name('share')
  environ['XDG_DATA_DIRS'] = "%s:%s" % (environ['XDG_DATA_HOME'], environ['XDG_DATA_DIRS'])
  output = subprocess.Popen(['dbus-launch'], stdout=subprocess.PIPE).communicate()[0]
  lines = output.split('\n')
  for line in lines:
      parts = line.split('=', 1)
      if len(parts) == 2:
          if parts[0] == 'DBUS_SESSION_BUS_PID': # cleanup at end
              cleanup_pids += [int(parts[1])]
          os.environ[parts[0]] = parts[1]

  # Shutdown ldtpd so that it will restart and pick up new dbus environment
  os.system('pkill -f ldtpd\\.main; sleep 1')
  ldtp.getwindowlist()

  environ['PYTHONPATH'] = extra_pythonpaths + (environ['PYTHONPATH'] if 'PYTHONPATH' in environ else '')
  environ['PATH'] = extra_paths + environ['PATH']
  environ['GNUPGHOME'] = get_temp_name('gnupg', True)
  
  #environ['G_DEBUG'] = 'fatal_warnings'
  
  os.system('mkdir -p %s' % environ['XDG_CONFIG_HOME'])
  os.system('mkdir -p %s/glib-2.0/schemas/' % environ['XDG_DATA_HOME'])
  
  # Make sure file chooser has txtLocation
  os.system('mkdir -p %s/gtk-2.0' % environ['XDG_CONFIG_HOME'])
  os.system('echo [Filechooser Settings] > "%s/gtk-2.0/gtkfilechooser.ini"' % environ['XDG_CONFIG_HOME'])
  os.system('echo LocationMode=filename-entry >> "%s/gtk-2.0/gtkfilechooser.ini"' % environ['XDG_CONFIG_HOME'])

  # Now install default schema into our temporary config dir
  if os.system('cp %s/../data/org.gnome.DejaDup.gschema.xml %s/glib-2.0/schemas/ && glib-compile-schemas %s/glib-2.0/schemas/' % (builddir, environ['XDG_DATA_HOME'], environ['XDG_DATA_HOME'])):
    raise Exception('Could not install settings schema')

  # Copy interface files into place as well
  os.system("mkdir -p %s/deja-dup/ui" % environ['XDG_DATA_HOME'])
  os.system("cp %s/../data/ui/* %s/deja-dup/ui" % (srcdir, environ['XDG_DATA_HOME']))

  set_settings_value("root-prompt", 'true' if root_prompt else 'false')

  #daemon_env = subprocess.Popen(['gnome-keyring-daemon'], stdout=subprocess.PIPE).communicate()[0].strip()
  #daemon_env = daemon_env.split('\n')
  #for line in daemon_env:
  #  bits = line.split('=')
  #  os.environ[bits[0]] = bits[1]

  if start:
    start_deja_dup(args)

def cleanup(success):
  global temp_dir, cleanup_dirs, cleanup_mounts, cleanup_pids, cleanup_envs
  for d in cleanup_mounts:
    os.system('gksudo "umount %s"' % d)
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

def set_settings_value(key, value, schema = None):
  if schema:
    schema = 'org.gnome.DejaDup.' + schema
  else:
    schema = 'org.gnome.DejaDup'
  cmd = ['gsettings', 'set', schema, key, value]
  sp = subprocess.Popen(cmd, stdout=subprocess.PIPE)
  sp.communicate()
  if sp.returncode:
    raise Exception('Could not set key %s to %s' % (key, value))

def get_settings_value(key, schema = None):
  if schema:
    schema = 'org.gnome.DejaDup.' + schema
  else:
    schema = 'org.gnome.DejaDup'
  cmd = ['gsettings', 'get', schema, key]
  sp = subprocess.Popen(cmd, stdout=subprocess.PIPE)
  pout = sp.communicate()[0]
  return pout.strip()

def start_deja_dup(args=[], executable='deja-dup', waitfor='frmDéjàDup', debug=False):
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
  environ['G_SLICE'] = 'always-malloc,debug-blocks'
  environ['G_DEBUG'] = 'gc-friendly' if not environ.get('G_DEBUG') else environ['G_DEBUG'] + ',gc-friendly'
  subprocess.Popen(cmd)
  if waitfor is not None:
    ldtp.waittillguiexist(waitfor)

def create_vol_config(dest='/'):
  if dest is None:
    raise 'Must specify dest=, using uuid:path syntax'
  uuid, path = dest.split(':', 1)
  set_settings_value("backend", "'file'")
  set_settings_value("type", "'volume'", schema="File")
  set_settings_value("name", "'USB Drive: Test Volume'", schema="File")
  set_settings_value("short-name", "'Test Volume'", schema="File")
  set_settings_value("uuid", "'%s'" % uuid, schema="File")
  set_settings_value("relpath", "'%s'" % path, schema="File")
  set_settings_value("icon", "'drive-removable-media-usb'", schema="File")

def create_mount(path=None, mtype='ext', size=20):
  global cleanup_mounts
  if mtype is None or mtype == 'ext': mtype = 'ext4'
  if size is None: size = 20
  if path is None:
    path = get_temp_name('blob')
    if not os.path.exists(path):
      os.system('dd if=/dev/zero of=%s bs=1 count=0 seek=%dM' % (path, size))
      if mtype.startswith('ext'):
        args = '-F'
      else:
        args = ''
      os.system('mkfs -t %s %s %s' % (mtype, args, path))
  mount_dir = get_temp_name('mount')
  os.system('mkdir -p %s' % mount_dir)
  if mtype == 'vfat':
    args = ',umask=0000'
  else:
    args = ''
  if os.system('gksudo "mount -t %s -o loop,sizelimit=%d%s %s %s"' % (mtype, size*1024*1024, args, path, mount_dir)):
    raise Exception("Couldn't mount")
  cleanup_mounts += [mount_dir]
  return mount_dir

def quit():
  if ldtp.guiexist('frmDéjàDup'):
    ldtp.selectmenuitem('frmDéjàDup', 'mnuBackup;mnuQuit')

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

def dup_meets_version(major, minor, micro):
  # replicates logic in DuplicityInfo a bit
  dupver = subprocess.Popen(['duplicity', '--version'], stdout=subprocess.PIPE).communicate()[0].strip().split()[1]
  if dupver == '999': return True
  dupmajor, dupminor, dupmicro = dupver.split('.')
  dupmajor = int(dupmajor)
  dupminor = int(dupminor)
  dupmicro = int(dupmicro) # sometimes micro has weird characters like 'b' in it...
  if dupmajor > major:  return True
  if dupmajor < major:  return False
  if dupminor > minor:  return True
  if dupminor < minor:  return False
  if dupmicro >= micro: return True
  else:                 return False

def get_manifest_date(filename):
  return re.sub('.*\.([0-9TZ]+)\.manifest.*', '\\1', filename)

def list_manifests(dest='local'):
  destdir = get_temp_name(dest)
  files = sorted(glob.glob('%s/*.manifest*' % destdir), key=get_manifest_date)
  if not files:
    raise Exception("Expected manifest, found none")
  files = filter(lambda x: x.count('duplicity-full') == 0 or x.count('.to.') == 0, files) # don't get the in-between manifests
  return (destdir, files)

def num_manifests(mtype=None, dest='local'):
  destdir, files = list_manifests(dest)
  if mtype:
    files = filter(lambda x: manifest_type(x) == mtype, files)
  return len(files)

def last_manifest(dest='local'):
  '''Returns last backup manifest (directory, filename) pair'''
  destdir, files = list_manifests(dest)
  latest = files[-1]
  return (destdir, latest)

def manifest_type(fn):
  # fn looks like duplicity-TYPE.DATES.manifest
  return fn.split('.')[0].split('-')[1]

def last_type(dest='local'):
  '''Returns last backup type, inc or full'''
  filename = last_manifest(dest)[1]
  return manifest_type(filename)

def last_date_change(to_date, dest='local'):
  '''Changes the most recent set of duplicity files to look like they were
     from to_date's timestamp'''
  destdir, latest = last_manifest(dest)
  olddate = get_manifest_date(latest)
  newdate = subprocess.Popen(['date', '--utc', '-d', to_date, '+%Y%m%dT%H%M%SZ'], stdout=subprocess.PIPE).communicate()[0].strip()
  cachedir = environ['XDG_CACHE_HOME'] + '/deja-dup/'
  cachedir += os.listdir(cachedir)[0]
  for d in (destdir, cachedir):
    files = glob.glob('%s/*' % d)
    for f in files:
      if f.find(olddate) != -1:
        newname = re.sub(olddate, newdate, f)
        os.rename(f, newname)

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

def wait_for_encryption(dlg, obj, max_count, prefix=False):
  count = 0
  while count < max_count:
    if guiexist(dlg, obj, prefix):
      break
    if ldtp.guiexist('dlgAllowaccess'):
      ldtp.click('dlgAllowaccess', 'btnDeny')
    if ldtp.guiexist(dlg, 'txtEncryptionpassword'):
      ldtp.settextvalue(dlg, 'txtEncryptionpassword', 'test')
      if ldtp.guiexist(dlg, 'txtConfirmpassword'):
        ldtp.settextvalue(dlg, 'txtConfirmpassword', 'test')
      ldtp.click(dlg, 'btnContinue')
    ldtp.wait(2)
    remap(dlg)
    count += 1
  assert guivisible(dlg, obj, prefix)

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

  # Add new items
  for f in files:
    ldtp.click(dlg, addObj)
    assert ldtp.waittillguiexist('dlgChoosefolders')
    # Make sure path ends in '/'
    if f[-1] != '/':
      f += '/'
    ldtp.settextvalue('dlgChoosefolders', 'txtLocation', f)
    ldtp.click('dlgChoosefolders', 'btnOpen')
    ldtp.wait(1) # let dialog close

def walk_restore_prefs(dlg, backend = None, encrypt = None, dest = None):
  if backend == 'file':
    if dest is None:
      dest = get_temp_name('local')
      os.system('mkdir -p %s' % dest)
    elif dest[0] != '/' and dest.find(':') == -1:
      dest = os.getcwd()+'/'+dest

    ldtp.comboselect(dlg, 'cboAmazonS3', 'Local Folder')
    remap(dlg)
    ldtp.settextvalue(dlg, 'txt0', dest) # FIXME txt0 is bad name

  if encrypt is not None:
    chklabel = 'chkEncryptbackupfiles'
    if not ldtp.guiexist(dlg, chklabel):
      chklabel = 'chkBackupfilesareencrypted'
    if encrypt:
      ldtp.check(dlg, chklabel)
    else:
      ldtp.uncheck(dlg, chklabel)

  ldtp.click(dlg, 'btnForward')
  remap(dlg)

def walk_backup_prefs(dlg, backend = None, encrypt = None, dest = None, includes = [], excludes = []):
  walk_restore_prefs(dlg, backend, encrypt, dest)
  ldtp.wait(1) # give ldtp a second

  # FIXME: bad names
  set_file_list(dlg, 'tbl1', 'btnAdd1', 'btnRemove1', includes)
  set_file_list(dlg, 'tbl0', 'btnAdd', 'btnRemove', excludes)
  ldtp.click(dlg, 'btnForward')
  remap(dlg)

def backup_simple(finish=True, error=None, timeout=400, backend = None, encrypt = None, dest = None, includes = [], excludes = [], add_srcdir=True):
  global srcdir
  if add_srcdir:
    includes = [os.path.join(srcdir, f) for f in includes]
    excludes = [os.path.join(srcdir, f) for f in excludes]

  ldtp.click('frmDéjàDup', 'btnBackUp…')
  assert ldtp.waittillguiexist('dlgBackUp')
  remap('dlgBackUp')
  if guivisible('dlgBackUp', 'lblPreferences'):
    walk_backup_prefs('dlgBackUp', backend=backend, encrypt=encrypt, dest=dest, includes=includes, excludes=excludes)
  ldtp.click('dlgBackUp', 'btnBackUp')
  remap('dlgBackUp')
  if finish:
    if not error:
      error = 'lblYourfilesweresuccessfullybackedup'
      wait_for_encryption('dlgBackUp', error, timeout)
    else:
      wait_for_encryption('dlgBackUp', error, timeout, prefix=True)
    ldtp.click('dlgBackUp', 'btnClose')
    ldtp.waittillguinotexist('dlgBackUp')

def restore_simple(path, date=None, backend = None, encrypt = None, dest = None):
  ldtp.click('frmDéjàDup', 'btnRestore…')
  assert ldtp.waittillguiexist('dlgRestore')
  remap('dlgRestore')
  if ldtp.guiexist('dlgRestore', 'lblPreferences'):
    walk_restore_prefs('dlgRestore', backend=backend, encrypt=encrypt, dest=dest)
  wait_for_encryption('dlgRestore', 'lblRestorefromWhen?', 200)
  if date:
    ldtp.comboselect('dlgRestore', 'cboDate', date)
  ldtp.click('dlgRestore', 'btnForward')
  ldtp.click('dlgRestore', 'rbtnRestoretospecificfolder')
  ldtp.comboselect('dlgRestore', 'cboRestorefolder', 'Other...')
  assert ldtp.waittillguiexist('dlgChoosedestinationforrestoredfiles')
  # Make sure path ends in '/'
  if path[-1] != '/':
    path += '/'
  ldtp.settextvalue('dlgChoosedestinationforrestoredfiles', 'txtLocation', path)
  ldtp.click('dlgChoosedestinationforrestoredfiles', 'btnOpen')
  ldtp.wait(1) # give the combo a second to settle
  ldtp.click('dlgRestore', 'btnForward')
  ldtp.wait(1) # give the dlg a second to settle
  ldtp.click('dlgRestore', 'btnRestore')
  assert ldtp.waittillguiexist('dlgRestore', 'lblYourfilesweresuccessfullyrestored', 400)
  assert guivisible('dlgRestore', 'lblYourfilesweresuccessfullyrestored')
  ldtp.click('dlgRestore', 'btnClose')
  ldtp.waittillguinotexist('dlgRestore')

def restore_specific(files, path, date=None, backend = None, encrypt = None, dest = None):
  global srcdir
  files = [os.path.join(srcdir, f) for f in files]
  args = ['--restore'] + files
  start_deja_dup(args=args, waitfor='dlgRestore')
  remap('dlgRestore')
  if ldtp.guiexist('dlgRestore', 'lblPreferences'):
    walk_restore_prefs('dlgRestore', backend=backend, encrypt=encrypt, dest=dest)
  wait_for_encryption('dlgRestore', 'lblRestorefromWhen?', 200)
  if date:
    ldtp.comboselect('dlgRestore', 'cboDate', date)
  ldtp.click('dlgRestore', 'btnForward')
  ldtp.click('dlgRestore', 'btnRestore')
  if len(files) == 1:
    lbl = 'lblYourfilewassuccessfullyrestored'
  else:
    lbl = 'lblYourfilesweresuccessfullyrestored'
  assert ldtp.waittillguiexist('dlgRestore', lbl)
  assert guivisible('dlgRestore', lbl)
  ldtp.click('dlgRestore', 'btnClose')

def restore_missing(files, path):
  args = ['--restore-missing', path]
  start_deja_dup(args=args, waitfor='dlgRestore')
  remap('dlgRestore')
  wait_for_encryption('dlgRestore', 'lblScanningfinished', 200)
  for f in files:
    index = ldtp.gettablerowindex('dlgRestore', 'tbl0', f)
    if index != -1:
      ldtp.checkrow('dlgRestore', 'tbl0', index)
  ldtp.click('dlgRestore', 'btnForward')
  ldtp.click('dlgRestore', 'btnRestore')
  if len(files) == 1:
    lbl = 'lblYourfilewassuccessfullyrestored'
  else:
    lbl = 'lblYourfilesweresuccessfullyrestored'
  assert ldtp.waittillguiexist('dlgRestore', lbl)
  assert guivisible('dlgRestore', lbl)
  ldtp.click('dlgRestore', 'btnClose')

def file_equals(path, contents):
  f = open(path)
  return f.read() == contents

def wait_for_quit():
  cmd = ['pgrep', '-n', '-x', 'deja-dup']
  pid = subprocess.Popen(cmd, stdout=subprocess.PIPE).communicate()[0].strip()
  cmd = ['ps', '-p', pid]
  while True:
    sub = subprocess.Popen(cmd, stdout=subprocess.PIPE)
    if sub.wait() == 0 and sub.communicate()[0].count('defunct') == 0:
      ldtp.wait(1)
    else:
      return
