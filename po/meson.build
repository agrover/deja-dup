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

linguas = [
    'ar',
    'ast',
    'az',
    'be',
    'bg',
    'bn',
    'bo',
    'bs',
    'ca',
    'ca@valencia',
    'ce',
    'cs',
    'cy',
    'da',
    'de',
    'el',
    'en_AU',
    'en_CA',
    'en_GB',
    'eo',
    'es',
    'et',
    'eu',
    'fa',
    'fi',
    'fo',
    'fr_CA',
    'fr',
    'fy',
    'gd',
    'gl',
    'he',
    'hi',
    'hr',
    'hu',
    'hy',
    'ia',
    'id',
    'io',
    'it',
    'ja',
    'kk',
    'km',
    'ko',
    'ku',
    'lt',
    'lv',
    'mhr',
    'ml',
    'mr',
    'ms',
    'my',
    'nb',
    'ne',
    'nl',
    'nn',
    'oc',
    'pa',
    'pl',
    'ps',
    'pt_BR',
    'pt',
    'ro',
    'ru',
    'se',
    'shn',
    'si',
    'sk',
    'sl',
    'sq',
    'sr',
    'sv',
    'ta',
    'te',
    'th',
    'tr',
    'ug',
    'uk',
    'uz',
    'vi',
    'zh_CN',
    'zh_HK',
    'zh_TW']

i18n.gettext(meson.project_name(), preset: 'glib', languages: linguas)

validate_po_linguas = find_program('./validate-linguas')
test('po-linguas', validate_po_linguas,
    env: ['LINGUAS=' + ' '.join(linguas)])
