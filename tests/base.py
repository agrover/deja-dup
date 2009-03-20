#!/usr/bin/env python
# -*- Mode: Python; indent-tabs-mode: nil; tab-width: 2; coding: utf-8 -*-

from os import environ, path, remove
import tempfile
import sys
import os
import ldtp

latest_duplicity = '0.5.12'

gconf_dir = None
cleanup_dirs = []
cleanup_mounts = []

def setup(backend, encrypt = True):
  global gconf_dir, cleanup_dirs, latest_duplicity
  
  environ['LANG'] = 'C'
  
  extra_paths = '../deja-dup:../preferences:../applet:../monitor:'
  extra_pythonpaths = ''
  
  version = None
  if 'DEJA_DUP_TEST_VERSION' in environ:
    version = environ['DEJA_DUP_TEST_VERSION']
  if version is None:
    version = latest_duplicity
  if version != 'system':
    os.system('./build-duplicity %s' % version)
    duproot = './duplicity/duplicity-%s' % version
    if not os.path.exists(duproot):
      print 'Could not find duplicity %s' % version
      sys.exit(1)
    
    extra_paths += duproot + '/usr/local/bin:'
    
    # Also add the module path, but we have to find it
    libdir = duproot + '/usr/local/lib/'
    libdir += os.listdir(libdir)[0] # python2.5 or python2.6, etc
    libdir += '/site-packages:'
    extra_pythonpaths += libdir
  
  environ['PYTHONPATH'] = extra_pythonpaths + (environ['PYTHONPATH'] if 'PYTHONPATH' in environ else '')
	print os.environ['PYTHONPATH']
  environ['PATH'] = extra_paths + environ['PATH']
  
  gconf_dir = tempfile.mkdtemp()
  cleanup_dirs += [gconf_dir]
  
  # Now install default rules into our temporary config dir
  os.system('GCONF_CONFIG_SOURCE="xml:readwrite:%s" gconftool-2 --makefile-install-rule %s > /dev/null' % (gconf_dir, '../data/deja-dup.schemas.in'))
  
  if backend == 'file':
    create_local_config()
  
  set_gconf_value("encrypt", 'true' if encrypt else 'false', 'bool')
  
  start_deja_dup()

def cleanup(success):
  global cleanup_dirs, cleanup_mounts
  for d in cleanup_mounts:
    os.system('gksudo "umount %s"' % d)
  for d in cleanup_dirs:
    os.system("rm -rf %s" % d)
  sys.exit(0 if success else 1)

def set_gconf_value(key, value, key_type = "string", list_type = None):
  global gconf_dir
  cmd = "gconftool-2 --config-source=xml:readwrite:%s -t %s -s /apps/deja-dup/%s %s" % (gconf_dir, key_type, key, value)
  if key_type == "list" and list_type:
    cmd += " --list-type=%s" % list_type
  os.system(cmd)

def start_deja_dup():
  global gconf_dir
  ldtp.launchapp('deja-dup', ['--gconf-source=xml:readwrite:%s' % gconf_dir], delay=0)
  ldtp.waittillguiexist('frmDéjàDup')

local_dir = None
def create_local_config():
  global local_dir, cleanup_dirs
  local_dir = tempfile.mkdtemp()
  cleanup_dirs += [local_dir]
  set_gconf_value("backend", "file")
  set_gconf_value("file/path", local_dir)
  set_gconf_value("include-list", '[%s/data/source]' % sys.path[0], "list", "string")

def create_mount(path=None, mtype='ext3', size=20):
  global cleanup_dirs, cleanup_mounts
  mount_dir = tempfile.mkdtemp()
  cleanup_dirs += [mount_dir]
  cleanup_mounts += [mount_dir + '/mount']
  if path is None:
    path = mount_dir + '/blob'
    os.system('dd if=/dev/zero of=%s bs=1 count=0 seek=%dM' % (path, size))
    if mtype == 'ext3':
      args = '-F'
    else:
      args = ''
    os.system('mkfs -t %s %s %s' % (mtype, args, path))
  os.system('mkdir %s/mount' % mount_dir)
  os.system('gksudo "mount -t %s -o loop,sizelimit=%d %s %s/mount"' % (mtype, size*1024*1024, path, mount_dir))
  return mount_dir + '/mount'

def quit():
  ldtp.selectmenuitem('frmDéjàDup', 'mnuFile;mnuQuit')

def run(method):
	success = False
	try:
		method()
		success = True
	except:
	  quit()
	finally:
	  cleanup(success)
