configurationData = configuration_data()
configurationData.set('PACKAGE_NAME', meson.project_name())
configurationData.set('LOCALE_DIR', LOCALE_DIR)
configure_file(input: 'config.h.in', output: 'config.h', configuration: configurationData)

install_data('AnalogueClock.plugin', install_dir: LIB_INSTALL_DIR)

AnalogueClockSources = [
'analogue-clock-applet.vala',
'clockimage.vala',
'timezonedata.vala',
'clock-popover.vala'
]

AnalogueClockDependencies = [
dependency('gtk+-3.0', version: '>=3.18'), 
dependency('budgie-1.0', version: '>=2'),
dependency('gdk-3.0'),
dependency('libpeas-gtk-1.0'),
meson.get_compiler('c').find_library('m', required: false)
]

AnalogueClockValaArgs = [
'--pkg=config', 
'--vapidir=' + VAPI_DIR, 
'--target-glib=2.38'
]

AnalogueClockCArgs = [
'-include', 
'config.h'
]

shared_library('analogue-clock-applet', AnalogueClockSources, dependencies: AnalogueClockDependencies, vala_args: AnalogueClockValaArgs, c_args: AnalogueClockCArgs, install: true, install_dir: LIB_INSTALL_DIR)
