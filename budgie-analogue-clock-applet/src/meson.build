install_data('AnalogueClock.plugin', install_dir: APPLET_INSTALL_DIR)

AnalogueClockSources = [
'analogue-clock-applet.vala',
'clockimage.vala',
'timezonedata.vala',
'clock-popover.vala'
]

AnalogueClockDependencies = [
dependency('gtk+-3.0', version: '>=3.18'),
budgie_dep,
peas_dep,
dependency('gdk-3.0'),
meson.get_compiler('c').find_library('m', required: false)
]

AnalogueClockValaArgs = [
'--target-glib=2.38'
]

shared_library('analogue-clock-applet', AnalogueClockSources, dependencies: AnalogueClockDependencies, vala_args: AnalogueClockValaArgs, install: true, install_dir: APPLET_INSTALL_DIR)
