APPLET_ID = 'analogue-clock-applet'
APPLET_INSTALL_DIR = join_paths(prefix, libdir, 'budgie-desktop', 'plugins', APPLET_ID)

subdir('src')
subdir('icons')

install_data('schema/com.github.samlane-ma.analogue-clock.gschema.xml',
    install_dir: SCHEMA_DIR
)
