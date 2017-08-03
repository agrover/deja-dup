# -*- Mode: Meson; indent-tabs-mode: nil; tab-width: 4 -*-
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

help_linguas = [
    'ar',
    'bg',
    'bs',
    'ca',
    'cs',
    'da',
    'de',
    'el',
    'en_AU',
    'en_GB',
    'eo',
    'es',
    'eu',
    'fi',
    'fr',
    'gl',
    'he',
    'hr',
    'hu',
    'id',
    'it',
    'ja',
    'ko',
    'ku',
    'lt',
    'my',
    'nb',
    'nl',
    'oc',
    'pa',
    'pl',
    'ps',
    'pt_BR',
    'ru',
    'sk',
    'sl',
    'sr',
    'sv',
    'th',
    'tr',
    'vi',
    'zh_CN',
    'zh_TW']

gnome.yelp('org.gnome.DejaDup',
    sources: ['backup-auto.page',
              'backup-first.page',
              'contribute.page',
              'credits.page',
              'index.page',
              'license.page',
              'prefs.page',
              'restore-full.page',
              'restore-lost.page',
              'restore-revert.page',
              'restore-worst-case.page',
              'support.page'],
    media: ['figures/deja-dup-icon.png'],
    languages: help_linguas,
    symlink_media: true)

validate_help_linguas = find_program('./validate-linguas')
test('help-linguas', validate_help_linguas,
    env: ['LC_ALL=C.UTF-8',
          'LINGUAS=' + ' '.join(help_linguas)],
    workdir: meson.current_source_dir())
