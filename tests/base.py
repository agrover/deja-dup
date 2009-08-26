#!/usr/bin/env python
# -*- Mode: Python; indent-tabs-mode: nil; tab-width: 2; coding: utf-8 -*-
#
# This file is part of Déjà Dup.
# © 2008,2009 Michael Terry <mike@mterry.name>
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

from os import environ, path, remove
import tempfile
import sys
import os
import ldtp
import subprocess
import glob
import re
import traceback

latest_duplicity = '0.6.04'

temp_dir = None
gconf_dir = None
cleanup_dirs = []
cleanup_mounts = []

# The current directory is always the 'distdir'.  But 'srcdir' may be different
# if we're running inside a distcheck for example.  So note that we check for
# srcdir and use it if available.  Else, default to current directory.

def setup(backend = None, encrypt = None, start = True, dest = None, sources = [], args=['']):
  global gconf_dir, cleanup_dirs, latest_duplicity
  
  if 'srcdir' in environ:
    srcdir = environ['srcdir']
  else:
    srcdir = '.'
  
  environ['LANG'] = 'C'
  
  extra_paths = '../deja-dup:../preferences:../applet:../monitor:'
  extra_pythonpaths = ''
  
  version = None
  if 'DEJA_DUP_TEST_VERSION' in environ:
    version = environ['DEJA_DUP_TEST_VERSION']
  if version is None:
    version = latest_duplicity
  if version != 'system':
    os.system('%s/build-duplicity %s' % (srcdir, version))
    duproot = './duplicity/duplicity-%s' % (version)
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
  
  environ['PYTHONPATH'] = extra_pythonpaths + (environ['PYTHONPATH'] if 'PYTHONPATH' in environ else '')
  environ['PATH'] = extra_paths + environ['PATH']
  
  environ['XDG_CACHE_HOME'] = get_temp_name('cache')
  
  gconf_dir = get_temp_name('gconf')
  os.system('mkdir -p %s' % gconf_dir)
  environ['GCONF_CONFIG_SOURCE'] = 'xml:readwrite:' + gconf_dir
  
  # Now install default rules into our temporary config dir
  os.system('gconftool-2 --makefile-install-rule %s > /dev/null' % ('%s/../data/deja-dup.schemas.in' % srcdir))
  
  if backend == 'file':
    create_local_config(dest, sources)
  elif backend == 'ssh':
    create_ssh_config(dest, sources);
  
  if encrypt is not None:
    set_gconf_value("encrypt", 'true' if encrypt else 'false', 'bool')
  
  if start:
    start_deja_dup(args)

def cleanup(success):
  global temp_dir, cleanup_dirs, cleanup_mounts
  for d in cleanup_mounts:
    os.system('gksudo "umount %s"' % d)
  for d in cleanup_dirs:
    os.system("rm -rf %s" % d)
  temp_dir = None
  if success:
    os.system('bash -c "echo -e \'\e[32mPASSED\e[0m\'"')
  else:
    os.system('bash -c "echo -e \'\e[31mFAILED\e[0m\'"')
    sys.exit(1)

def set_gconf_value(key, value, key_type = "string", list_type = None):
  cmd = ['gconftool-2', '--config-source=xml:readwrite:%s' % gconf_dir, '-t',
         key_type, '-s', '/apps/deja-dup/%s' % key, value]
  if key_type == "list" and list_type:
    cmd += ["--list-type=%s" % list_type]
  sp = subprocess.Popen(cmd, stdout=subprocess.PIPE)
  sp.communicate()

def get_gconf_value(key):
  cmd = ['gconftool-2', '--config-source=xml:readwrite:%s' % gconf_dir,
         '-g', '/apps/deja-dup/%s' % key]
  sp = subprocess.Popen(cmd, stdout=subprocess.PIPE)
  pout = sp.communicate()[0]
  return pout.strip()

def start_deja_dup(args=[''], waitfor='frmDéjàDup'):
  ldtp.launchapp('deja-dup', arg=args, delay=0)
  ldtp.appundertest('deja-dup')
  if waitfor is not None:
    ldtp.waittillguiexist(waitfor)

def start_deja_dup_prefs():
  ldtp.launchapp('deja-dup-preferences', delay=0)
  ldtp.appundertest('deja-dup-preferences')
  ldtp.waittillguiexist('frmDéjàDupPreferences')

def start_deja_dup_applet():
  ldtp.launchapp('deja-dup', arg=['--backup'], delay=0)
  ldtp.appundertest('deja-dup')

def create_local_config(dest='/', includes=None, excludes=None):
  if dest is None:
    dest = get_temp_name('local')
    os.system('mkdir -p %s' % dest)
  elif dest[0] != '/':
    dest = os.getcwd()+'/'+dest
  set_gconf_value("backend", "file")
  set_gconf_value("file/path", dest)
  includes = includes and [os.getcwd()+'/'+x for x in includes]
  excludes = excludes and [os.getcwd()+'/'+x for x in excludes]
  if includes:
    includes = '[' + ','.join(includes) + ']'
    set_gconf_value("include-list", includes, "list", "string")
  if excludes:
    excludes = '[' + ','.join(excludes) + ']'
    set_gconf_value("exclude-list", excludes, "list", "string")

def create_ssh_config(dest='/', includes=None, excludes=None):
  if dest is None:
    dest = get_temp_name('local')
    os.system('mkdir -p %s' % dest)
  set_gconf_value("backend", "file")
  set_gconf_value("file/path", "ssh://localhost" + dest)
  if includes:
    includes = '[' + ','.join(includes) + ']'
    set_gconf_value("include-list", includes, "list", "string")
  if excludes:
    excludes = '[' + ','.join(excludes) + ']'
    set_gconf_value("exclude-list", excludes, "list", "string")

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

def get_temp_name(extra):
  global temp_dir
  create_temp_dir()
  return temp_dir + '/' + extra

def create_mount(path=None, mtype='ext3', size=20):
  global cleanup_mounts
  if mtype is None: mtype = 'ext3'
  if size is None: size = 20
  if path is None:
    path = get_temp_name('blob')
    if not os.path.exists(path):
      os.system('dd if=/dev/zero of=%s bs=1 count=0 seek=%dM' % (path, size))
      if mtype == 'ext3':
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
    ldtp.selectmenuitem('frmDéjàDup', 'mnuFile;mnuQuit')

def run(method):
  success = False
  try:
    success = method()
  except:
    traceback.print_exc()
  finally:
    quit()
    cleanup(success)

def get_manifest_date(filename):
  return re.sub('.*\.([0-9TZ]+)\.manifest', '\\1', filename)

def list_manifests():
  destdir = get_temp_name('local')
  files = sorted(glob.glob('%s/*.manifest' % destdir), key=get_manifest_date)
  if not files:
    raise Exception("Expected manifest, found none")
  files = filter(lambda x: x.count('duplicity-full') == 0 or x.count('.to.') == 0, files) # don't get the in-between manifests
  return (destdir, files)

def num_manifests(mtype=None):
  destdir, files = list_manifests()
  if mtype:
    files = filter(lambda x: manifest_type(x) == mtype, files)
  return len(files)

def last_manifest():
  '''Returns last backup manifest (directory, filename) pair'''
  destdir, files = list_manifests()
  latest = files[-1]
  return (destdir, latest)

def manifest_type(fn):
  # fn looks like duplicity-TYPE.DATES.manifest
  return fn.split('.')[0].split('-')[1]

def last_type():
  '''Returns last backup type, inc or full'''
  filename = last_manifest()[1]
  return manifest_type(filename)

def last_date_change(to_date):
  '''Changes the most recent set of duplicity files to look like they were
     from to_date's timestamp'''
  destdir, latest = last_manifest()
  olddate = get_manifest_date(latest)
  newdate = subprocess.Popen(['date', '-d', to_date, '+%Y%m%dT%H%M%SZ'], stdout=subprocess.PIPE).communicate()[0].strip()
  cachedir = environ['XDG_CACHE_HOME'] + '/deja-dup/'
  cachedir += os.listdir(cachedir)[0]
  for d in (destdir, cachedir):
    files = glob.glob('%s/*' % d)
    for f in files:
      if f.find(olddate) != -1:
        newname = re.sub(olddate, newdate, f)
        os.rename(f, newname)

def guivisible(frm, obj):
  if obj not in ldtp.getobjectlist(frm):
    return False
  states = ldtp.getallstates(frm, obj)
  return ldtp.state.VISIBLE in states

def backup_simple():
  ldtp.click('frmDéjàDup', 'btnBackup')
  assert ldtp.waittillguiexist('dlgBackup')
  ldtp.remap('dlgBackup') # in case this is second time we've run it
  if guivisible('dlgBackup', 'lblPreferences'):
    ldtp.click('dlgBackup', 'btnForward')
    ldtp.click('dlgBackup', 'btnForward')
  ldtp.click('dlgBackup', 'btnApply')
  assert ldtp.waittillguiexist('dlgBackup', 'lblYourfilesweresuccessfullybackedup.', guiTimeOut=200)
  assert guivisible('dlgBackup', 'lblYourfilesweresuccessfullybackedup.')
  ldtp.click('dlgBackup', 'btnClose')
  ldtp.waittillguinotexist('dlgBackup')

def restore_simple(path, date=None):
  ldtp.click('frmDéjàDup', 'btnRestore')
  assert ldtp.waittillguiexist('dlgRestore')
  ldtp.remap('dlgRestore') # in case this is second time we've run it
  if ldtp.guiexist('dlgRestore', 'lblPreferences'):
    ldtp.click('dlgRestore', 'btnForward')
  assert ldtp.waittillguiexist('dlgRestore', 'lblRestorefromWhen?')
  if date:
    ldtp.comboselect('dlgRestore', 'cboDate', date)
  ldtp.click('dlgRestore', 'btnForward')
  ldtp.click('dlgRestore', 'rbtnRestoretospecificfolder')
  ldtp.comboselect('dlgRestore', 'cboRestorefolder', 'Other...')
  assert ldtp.waittillguiexist('dlgChoosedestinationforrestoredfiles')
  ldtp.settextvalue('dlgChoosedestinationforrestoredfiles', 'txtLocation', path)
  ldtp.click('dlgChoosedestinationforrestoredfiles', 'btnOpen')
  ldtp.click('dlgRestore', 'btnForward')
  ldtp.click('dlgRestore', 'btnApply')
  assert ldtp.waittillguiexist('dlgRestore', 'lblYourfilesweresuccessfullyrestored.')
  assert guivisible('dlgRestore', 'lblYourfilesweresuccessfullyrestored.')
  ldtp.click('dlgRestore', 'btnClose')
  ldtp.waittillguinotexist('dlgRestore')

def restore_specific(path, date=None):
  if ldtp.guiexist('dlgRestore', 'lblPreferences'):
    ldtp.click('dlgRestore', 'btnForward')
  assert ldtp.waittillguiexist('dlgRestore', 'lblRestorefromWhen?')
  if date:
    ldtp.comboselect('dlgRestore', 'cboDate', date)
  ldtp.click('dlgRestore', 'btnForward')
  ldtp.click('dlgRestore', 'btnApply')
  assert ldtp.waittillguiexist('dlgRestore', 'lblYourfilesweresuccessfullyrestored.')
  assert guivisible('dlgRestore', 'lblYourfilesweresuccessfullyrestored.')
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
