RavenAnalogClockSources = ['ravenanalogclock.vala', 'ravenclockimage.vala', 'clocksettings.vala', 'dropdown.vala']

RavenAnalogClockDependencies = [
    dependency('gtk+-3.0', version: '>=3.18'),
    peas_dep,
    dependency('budgie-raven-plugin-1.0'),
    meson.get_compiler('c').find_library('m', required: false)
]

install_data('RavenAnalogClock.plugin', install_dir: WIDGET_INSTALL_DIR)

shared_library(WIDGET_ID, RavenAnalogClockSources, dependencies: RavenAnalogClockDependencies, install: true, install_dir: WIDGET_INSTALL_DIR)
