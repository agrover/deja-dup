#!/usr/bin/env python
# -*- Mode: Python; indent-tabs-mode: nil; tab-width: 2; coding: utf-8 -*-

from os import environ, path, remove
import tempfile
import sys
import os
import ldtp

gconf_dir = None
cleanup_dirs = []

def setup(backend, encrypt = True):
  global gconf_dir, cleanup_dirs
  
  environ['LANG'] = 'en_US.UTF-8'
  environ['PATH'] = '../deja-dup:../preferences:../applet:../monitor' + environ['PATH']
  
  gconf_dir = tempfile.mkdtemp()
  cleanup_dirs += [gconf_dir]
  
  # Now install default rules into our temporary config dir
  os.system('GCONF_CONFIG_SOURCE="xml:readwrite:%s" gconftool-2 --makefile-install-rule %s' % (gconf_dir, '../data/deja-dup.schemas.in'))
  
  if backend == 'file':
    create_local_config()
  
  set_gconf_value("encrypt", 'true' if encrypt else 'false', 'bool')
  
  start_deja_dup()

def cleanup(success):
  global cleanup_dirs
  for d in cleanup_dirs:
    os.system("rm -r %s" % d)
  sys.exit(0 if success else 1)

def set_gconf_value(key, value, key_type = "string", list_type = None):
  global gconf_dir
  cmd = "gconftool-2 --config-source=xml:readwrite:%s -t %s -s /apps/deja-dup/%s %s" % (gconf_dir, key_type, key, value)
  if key_type == "list" and list_type:
    cmd += " --list-type=%s" % list_type
  os.system(cmd)

def start_deja_dup():
  global gconf_dir
  ldtp.launchapp('deja-dup', ['--gconf-source=xml:readwrite:%s' % gconf_dir], env=1)
  ldtp.waittillguiexist('frmDéjàDup')

local_dir = None
def create_local_config():
  global local_dir, cleanup_dirs
  local_dir = tempfile.mkdtemp()
  cleanup_dirs += [local_dir]
  set_gconf_value("backend", "file")
  set_gconf_value("file/path", local_dir)
  set_gconf_value("include-list", '[%s/data/source]' % sys.path[0], "list", "string")

def quit():
  ldtp.selectmenuitem('frmDéjàDup', 'mnuFile;mnuQuit')

