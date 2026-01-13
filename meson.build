project('analogue-clock-applet',
        ['vala', 'c'],
        version: '0.1.0',
        meson_version: '>=0.57.0',
        license: 'GPL3')

# Global path variable
prefix = get_option('prefix')
libdir = join_paths(prefix, get_option('libdir'))
datadir = join_paths(prefix, get_option('datadir'))
PIXMAPS_DIR = join_paths(datadir, 'pixmaps')
SCHEMA_DIR = join_paths(prefix, 'share', 'glib-2.0', 'schemas')

build_all = get_option('build-all')
budgie_version = get_option('budgie-version')

for_wayland = get_option('for-wayland')
# for-wayland is only for compatibility with existing Wayland packaging
# It is the same as using budgie-version=3.0, so fail if its used with 
# a different version specified
if for_wayland and budgie_version != '3.0'
        error('"for-wayland" option conflicts with "budgie-version" option')
endif

if budgie_version == '3.0' or for_wayland
        # 10.10.x
        budgie_dep = dependency('budgie-3.0')
        peas_dep = dependency('libpeas-2')
        raven_dep = dependency('budgie-raven-plugin-3.0')
elif budgie_version == '2.0' 
        # 10.9.4
        budgie_dep = dependency('budgie-2.0')
        peas_dep = dependency('libpeas-2')
        raven_dep = dependency('budgie-raven-plugin-2.0')
else
        # 10.9.3 and earlier
        budgie_dep = dependency('budgie-1.0')
        peas_dep = dependency('libpeas-1.0')
        raven_dep = dependency('budgie-raven-plugin-1.0')
endif

build_applet = get_option('build-applet')
if build_all == true or build_applet == true
        subdir('budgie-analogue-clock-applet')
endif

build_widget = get_option('build-widget')
if build_all == true or build_widget == true
        subdir('budgie-analogue-clock-widget')
endif

message('Installing')

meson.add_install_script('meson_post_install')
