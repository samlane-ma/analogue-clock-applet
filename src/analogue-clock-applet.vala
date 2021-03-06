/*
 *  Analogue Clock Applet for the Budgie Panel
 *
 *  Copyright © 2020 Samuel Lane
 *  http://github.com/samlane-ma/
 *
 *  Thanks to the Ubuntu Budgie Developers for their assistance,
 *  examples, and pieces of code I borrowed to make this work.
 *
 *  Portions of this applet are part of the Budgie Clock Applet
 *  Copyright © 2014-2020 Budgie Desktop Developers
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 *  Icon made by Becris from www.flaticon.com
 */

using Gtk, Gdk, Cairo;
using PanelClockFunctions;

namespace AnalogueClock {

    const int MAX_SIZE = 200;
    const int MIN_SIZE =  22;
    const string CALENDAR_MIME = "text/calendar";

    public class Plugin : Budgie.Plugin, Peas.ExtensionBase {

        public Budgie.Applet get_panel_widget(string uuid){
            return new AnalogueClockApplet(uuid);
        }
    }

    public class AnalogueClockSettings : Gtk.Grid {

        private GLib.Settings app_settings;

        public AnalogueClockSettings(GLib.Settings? settings) {

            app_settings = new GLib.Settings ("com.github.samlane-ma.analogue-clock");

            string[] labels = {"", "Clock Size (px)","Frame Color","Hands Color",
                           "Face Color","Transparent face","","Show hour marks"};

            Gdk.RGBA color;
            string loadcolor;

            for (int i=0; i < 8; i++) {
                Gtk.Label label = new Gtk.Label(labels[i]);
                label.set_halign(Gtk.Align.START);
                label.set_valign(Gtk.Align.CENTER);
                this.attach(label, 0, i, 1, 1);
            }

            Gtk.Adjustment adj = new Gtk.Adjustment(app_settings.get_int("clock-size"),
                                                    MIN_SIZE,MAX_SIZE,1,1,0);
            Gtk.SpinButton spin_clock_size = new Gtk.SpinButton(adj,1.0,0);
            spin_clock_size.set_digits(0);
            this.attach(spin_clock_size, 1, 1, 1, 1);

            loadcolor = app_settings.get_string("clock-outline");
            color = Gdk.RGBA();
            color.parse(loadcolor);
            Gtk.ColorButton buttonframe = new Gtk.ColorButton.with_rgba(color);
            buttonframe.color_set.connect (() => 
                             { on_color_changed(buttonframe,"clock-outline");});
            this.attach(buttonframe, 1, 2, 1, 1);

            loadcolor = app_settings.get_string("clock-hands");
            color = Gdk.RGBA();
            color.parse(loadcolor);
            Gtk.ColorButton buttonhands = new Gtk.ColorButton.with_rgba(color);
            buttonhands.color_set.connect (() => 
                             { on_color_changed(buttonhands,"clock-hands");});
            this.attach(buttonhands, 1, 3, 1, 1);

            loadcolor = app_settings.get_string("clock-face");
            color = Gdk.RGBA();
            if (loadcolor == "none"){
                    color.parse("rgba(0,0,0,0)");
            } 
            else {
                color.parse(loadcolor);
            }
            Gtk.ColorButton buttonface = new Gtk.ColorButton.with_rgba(color);
            buttonface.color_set.connect (() => 
                                 { on_color_changed(buttonface,"clock-face");});
            this.attach(buttonface, 1, 4, 1, 1);

            Gtk.Button button_set_transparent = new Gtk.Button.with_label("Set");
            button_set_transparent.clicked.connect(() => { buttonface.set_alpha(0);
                                    app_settings.set_string("clock-face","none");});
            this.attach(button_set_transparent, 1, 5, 1, 1);
            Gtk.Switch switch_markings = new Gtk.Switch();
            switch_markings.set_halign(Gtk.Align.END);
            this.attach(switch_markings, 1, 7, 1, 1);

            app_settings.bind("clock-size",spin_clock_size,"value",SettingsBindFlags.DEFAULT);
            app_settings.bind("draw-marks",switch_markings,"active",SettingsBindFlags.DEFAULT);

            this.show_all();
        }

        private void on_color_changed(Gtk.ColorButton button, string part) {
            Gdk.RGBA c = button.get_rgba();
            app_settings.set_string(part, c.to_string());
        }
    }

    public class AnalogueClockApplet : Budgie.Applet {

        private GLib.Settings? panel_settings;
        private GLib.Settings? currpanelsubject_settings;
        private GLib.Settings app_settings;
        private ulong panel_signal;
        private ulong? settings_signal;

        private bool keep_running;
        private bool update_needed;

        private Gtk.Box panel_box;
        protected Gtk.EventBox widget;
        private Gtk.Image clock_image;
        private int max_size;
        private int old_minute;
        private PanelClock clock;
        private Gtk.Grid grid_popover;
        private Gtk.Button button_timesettings;
        private Gtk.Button button_calendar;
        private Gtk.Label popover_day;
        private Gtk.Label popover_date;
        private Gtk.Calendar calendar;

        AppInfo? calprov = null;
        Budgie.Popover? popover = null;
        private unowned Budgie.PopoverManager? manager = null;

        public string uuid { public set; public get; }

        public AnalogueClockApplet(string uuid) {

            max_size = MIN_SIZE;
            update_needed = true;
            keep_running = true;
            clock = new PanelClock();

            widget = new Gtk.EventBox();
            panel_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 1);
            widget.add(panel_box);
            add(widget);
            clock_image = new Gtk.Image();
            panel_box.pack_start(clock_image, false, false, 0);

            button_timesettings = new Gtk.Button.with_label("Time and date settings");
            button_timesettings.get_style_context().add_class(Gtk.STYLE_CLASS_FLAT);
            button_calendar = new Gtk.Button.with_label("Open Calendar");
            button_calendar.get_style_context().add_class(Gtk.STYLE_CLASS_FLAT);

            popover_day = new Gtk.Label("");
            popover_day.get_style_context ().add_class ("h1");
            popover_day.halign = Gtk.Align.START;
            popover_day.set_margin_top(10);
            popover_day.set_margin_start(20);

            popover_date = new Gtk.Label("");
            popover_date.get_style_context ().add_class ("h2");
            popover_date.halign = Gtk.Align.START;
            popover_date.set_margin_start(20);
            popover_date.set_margin_top(5);
            popover_date.set_margin_bottom(15);

            calendar = new Gtk.Calendar();

            popover = new Budgie.Popover(widget);
            grid_popover = new Gtk.Grid();
            grid_popover.attach(popover_day,0,0,1,1);
            grid_popover.attach(popover_date,0,1,1,1);
            grid_popover.attach(calendar,0,2,1,1);
            grid_popover.attach(button_calendar,0,3,1,1);
            grid_popover.attach(button_timesettings,0,4,1,1);
            popover.add(grid_popover);

            widget.button_press_event.connect((e)=> {
                if (e.button != 1) {
                    return Gdk.EVENT_PROPAGATE;
                }
                if (popover.get_visible()) {
                    popover.hide();
                } else {
                    DateTime date = new DateTime.now_local();
                    calendar.month = date.get_month () - 1;
                    calendar.year = date.get_year ();
                    calendar.select_day(date.get_day_of_month ());
                    this.manager.show_popover(widget);
                }
                return Gdk.EVENT_STOP;
            });

            calprov = AppInfo.get_default_for_type(CALENDAR_MIME, false);
            var monitor = AppInfoMonitor.get();
            monitor.changed.connect(update_cal);
            update_cal();

            button_timesettings.clicked.connect(on_date_activate);;
            button_calendar.clicked.connect(on_cal_activate);

            popover.get_child().show_all();
            show_all();

            app_settings = new GLib.Settings ("com.github.samlane-ma.analogue-clock");
            settings_signal = app_settings.changed.connect(force_clock_redraw);
            load_settings();
            Idle.add(() => { watch_applet(uuid); 
                             return false;});
            Timeout.add_seconds_full(GLib.Priority.LOW,5,update_clock_time);
        }

        public override void update_popovers(Budgie.PopoverManager? manager) {
            this.manager = manager;
            manager.register_popover(widget, popover);
        }

        private void load_settings(){
            // Load the settings
            clock.size = app_settings.get_int("clock-size");
            if (clock.size > max_size) {
                clock.size = max_size;
            }
            // Don't recursively trigger this if validate_settings fixes things
            if (settings_signal != null) {
                SignalHandler.block((void*)app_settings,settings_signal);
                validate_settings();
                SignalHandler.unblock((void*)app_settings,settings_signal);
            }
            clock.hands_color = app_settings.get_string("clock-hands");
            clock.line_color = app_settings.get_string("clock-outline");
            clock.fill_color = app_settings.get_string("clock-face");
            clock.draw_marks = app_settings.get_boolean("draw-marks");
        }

        private void validate_settings() {
            // Verify the color names are valid, reload defaults if not.
            // Should only happen if invalid dconf settings are manually entered
            string[] setting_name = {"clock-hands", "clock-outline", "clock-face"};
            string[] default_color = {"#000000", "#000000", "#FFFFFF"};
            for (int i = 0; i < 3; i++) {
                Gdk.RGBA testcolor = Gdk.RGBA();
                string colorname = app_settings.get_string(setting_name[i]);
                if (colorname != "none" && !testcolor.parse(colorname)) {
                    app_settings.set_string(setting_name[i],default_color[i]);
                }
            }
        }

        private void force_clock_redraw() {
            // force the redraw after settings / panel change
            update_needed = true;
            load_settings();
            update_clock_time();
        }

        private bool update_clock_time() {
            // Check the time, draw a new clock if necessary
            var current_time = new DateTime.now_local();
            if (current_time.get_minute() != old_minute || update_needed) {
                old_minute = current_time.get_minute();
                clock.hour = current_time.get_hour();
                clock.minute = current_time.get_minute();
                update_needed = false;
                Idle.add(() => { clock_image.set_from_surface(clock.get_clock_surface());
                                 panel_box.set_tooltip_text(current_time.format("%x"));
                                 popover_day.set_text(current_time.format("%A"));
                                 popover_date.set_text(current_time.format("%e %B %Y"));
                                 return false; });
            }
            return keep_running;
        }

        private bool find_applet(string find_uuid, string[] applet_list) {
            // Search panel applets for the given uuid
            for (int i = 0; i < applet_list.length; i++) {
                if (applet_list[i] == find_uuid) {
                    return true;
                }
            }
            return false;
        }

        private void watch_applet(string find_uuid) {
            // Check if the applet is still on the panel and ends cleanly if not
            string[] applets;
            string soluspath = "com.solus-project.budgie-panel";
            panel_settings = new GLib.Settings(soluspath);
            string[] allpanels_list = panel_settings.get_strv("panels");
            foreach (string p in allpanels_list) {
                string panelpath = "/com/solus-project/budgie-panel/panels/".concat("{", p, "}/");
                currpanelsubject_settings = new GLib.Settings.with_path(
                    soluspath + ".panel", panelpath
                );
                applets = currpanelsubject_settings.get_strv("applets");
                if (find_applet(find_uuid, applets)) {
                     panel_signal = currpanelsubject_settings.changed["applets"].connect(() => {
                        applets = currpanelsubject_settings.get_strv("applets");
                        if (!find_applet(find_uuid, applets)) {
                            currpanelsubject_settings.disconnect(panel_signal);
                            app_settings.disconnect(settings_signal);
                            keep_running = false;
                        }
                    });
                }
            }
        }

        public override void panel_size_changed(int p, int i, int s) {
            // Scale the icon if necessary when panel is resized
            max_size = p - 6;
            if (max_size < MIN_SIZE){
                max_size = MIN_SIZE;
            }
            int current_size = app_settings.get_int("clock-size");
            if (current_size > max_size) {
                clock.size = max_size;
            }
            force_clock_redraw();
        }

        public override void panel_position_changed(Budgie.PanelPosition position) {
            // Keep the icon centered in both horizontal and vertical panels
            if ( position == Budgie.PanelPosition.LEFT ||
                 position == Budgie.PanelPosition.RIGHT ) {
                panel_box.set_orientation(Gtk.Orientation.VERTICAL);
            }
            else {
                panel_box.set_orientation(Gtk.Orientation.HORIZONTAL);
            }
            force_clock_redraw();
        }

        public override bool supports_settings() {
            return true;
        }

        public override Gtk.Widget? get_settings_ui() {
            return new AnalogueClockSettings(this.get_applet_settings(uuid));
        }

        private void update_cal() {
            calprov = AppInfo.get_default_for_type(CALENDAR_MIME, false);
            button_calendar.set_sensitive(calprov != null);
        }

        private void on_date_activate() {
            this.popover.hide();
            var app_info = new DesktopAppInfo("gnome-datetime-panel.desktop");
            if (app_info == null) {
                return;
            }
            try {
                app_info.launch(null, null);
            } catch (Error e) {
                message("Unable to launch gnome-datetime-panel.desktop: %s", e.message);
            }
        }

        private void on_cal_activate() {
            this.popover.hide();
            if (calprov == null) {
                return;
            }
            try {
                calprov.launch(null, null);
            } catch (Error e) {
                message("Unable to launch %s: %s", calprov.get_name(), e.message);
            }
        }
    }
}

[ModuleInit]
public void peas_register_types(TypeModule module) {

    // boilerplate - all modules need this
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(AnalogueClock.Plugin));
}
