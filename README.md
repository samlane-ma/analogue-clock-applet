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
    meson setup --prefix=/usr
    ninja
    sudo ninja install

To specify the version of the Budgie ABIs to build against:

```
-Dbudgie-version=3.0 (Budgie Desktop 10.10 and later - Wayland)
-Dbudgie-version=2.0 (Budgie Desktop 10.9.4)
-Dbudgie-version=1.0 (Budgie Desktop 10.9.3 and earlier)
``` 
* to install only the applet - use the following option:
```
meson setup --prefix=/usr -Dbuild-all=false -Dbuild-applet=true
```
* to install only the widget
```
meson setup --prefix=/usr -Dbuild-all=false -Dbuild-widget=true
```

This will:
* install applet plugin files to the Budgie Desktop applet plugin folder
* install widget plugin files to the Budgie Desktop widget plugin folder 
* compile the schema
