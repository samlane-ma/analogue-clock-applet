# Analogue Clock Applet

## Provides an analogue clock applet for Budgie Panel and a widget for the Raven Panel

## Panel Applet
![Screenshot](images/clock.png?raw=true)

## Raven Widget
![Screenshot](images/analog-clock.png?raw=true)

i.e. for Debian based distros

To install (for Debian/Ubuntu):

    mkdir build
    cd build
    meson setup --prefix=/usr --libdir=/usr/lib
    ninja
    sudo ninja install
    
* to install only the applet - use the following option:
```
meson setup --prefix=/usr --libdir=/usr/lib -Dbuild-all=false -Dbuild-applet=true
```
* to install only the widget
```
meson setup --prefix=/usr --libdir=/usr/lib -Dbuild-all=false -Dbuild-widget=true
```
* for other distros omit libdir or specify the location of the distro library folder

This will:
* install applet plugin files to the Budgie Desktop applet plugin folder
* install widget plugin files to the Budgie Desktop widget plugin folder 
* compile the schema
