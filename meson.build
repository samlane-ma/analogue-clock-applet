project('analogue-clock-applet',
        ['vala', 'c'],
        version: '0.1.0',
        meson_version: '>=0.40.0',
        license: 'GPL2')

# Global path variable
prefix = get_option('prefix')
libdir = join_paths(prefix, get_option('libdir'))
datadir = join_paths(prefix, get_option('datadir'))
PIXMAPS_DIR = join_paths(datadir, 'pixmaps')
SCHEMA_DIR = join_paths(prefix, 'share', 'glib-2.0', 'schemas')

build_all = get_option('build-all')

for_wayland = get_option('for-wayland')

if for_wayland == false
        budgie_dep = dependency('budgie-1.0')
        peas_dep = dependency('libpeas-1.0')
else
        budgie_dep = [ dependency('budgie-2.0'),
                       dependency('gtk-layer-shell-0') ]
        peas_dep = dependency('libpeas-2')
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
