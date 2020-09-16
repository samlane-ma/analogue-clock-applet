# Analogue Clock Applet

![Screenshot](images/clock.png?raw=true)

## Add an analogue clock to the Budgie Panel

### This is a Vala based rewrite of python Budgie Analog Clock.
### It is for the most part identical in form and function to the python version.

This applet will add a simple analogue clock on the Budgie panel. 

The applet currently allows you to:
* Change the clock size through the applet settings
* Change the color of the frame, face, and hands
* Enable or disable the hour markings on the face

The applet will respect the panel settings, and not draw a clock larger than
the Budgie Panel.  However, if the panel is resized, the clock will change size
as well, up to the clock size specified in the applet setting


i.e. for Debian based distros

To install (for Debian/Ubuntu):

    mkdir build
    cd build
    meson --prefix=/usr --libdir=/usr/lib
    ninja -v
    sudo ninja install

* for other distros omit libdir or specify the location of the distro library folder

This will:
* install plugin files to the Budgie Desktop plugins folder
* compile the schema
