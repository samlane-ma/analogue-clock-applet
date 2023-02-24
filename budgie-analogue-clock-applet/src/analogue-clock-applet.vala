/*
 *  Analogue Clock Applet for the Budgie Panel
 *
 *  Copyright © 2020 Samuel Lane
 *  http://github.com/samlane-ma/
 *
 *  Thanks to the Ubuntu Budgie Developers for their assistance,
 *  examples, and pieces of code I borrowed to make this work.
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
using TimeZoneData;

namespace AnalogueClock {

    const int MAX_SIZE = 200;
    const int MIN_SIZE =  22;
    const string[] clock_parts = { "clock-outline", "clock-hands", "clock-face" };

    public class Plugin : Budgie.Plugin, Peas.ExtensionBase {

        public Budgie.Applet get_panel_widget(string uuid){
            return new AnalogueClockApplet(uuid);
        }
    }

    public class AnalogueClockSettings : Gtk.Grid {

        private GLib.Settings settings;
        private Gtk.ComboBoxText combo_tz;

        public AnalogueClockSettings(GLib.Settings? settings) {

            this.settings = settings;

            string[] labels = {"Clock Size (px)", "Frame Color", "Hands Color",
                               "Face Color", "Transparent face", "Show hour marks",
                               "", "Select Timezone", "Time Zone (UTC)","", "Show Clock Name"};

            for (int i=0; i < labels.length; i++) {
                Gtk.Label label = new Gtk.Label(labels[i]);
                label.set_halign(Gtk.Align.START);
                label.set_valign(Gtk.Align.CENTER);
                attach(label, 0, i, 1, 1);
            }

            Gtk.Adjustment adj = new Gtk.Adjustment(settings.get_int("clock-size"), MIN_SIZE, MAX_SIZE, 1, 1, 0);
            Gtk.SpinButton spin_clock_size = new Gtk.SpinButton(adj,1.0,0);
            spin_clock_size.set_digits(0);
            attach(spin_clock_size, 1, 0, 1, 1);

            Gtk.ColorButton buttonframe = new Gtk.ColorButton();
            setup_colorbutton(buttonframe, "clock-outline");
            attach(buttonframe, 1, 1, 1, 1);
            Gtk.ColorButton buttonhands = new Gtk.ColorButton();
            setup_colorbutton(buttonhands,"clock-hands");
            attach(buttonhands, 1, 2, 1, 1);
            Gtk.ColorButton buttonface = new Gtk.ColorButton();
            setup_colorbutton(buttonface, "clock-face");
            attach(buttonface, 1, 3, 1, 1);

            Gtk.Button button_set_transparent = new Gtk.Button.with_label("Set");
            button_set_transparent.clicked.connect(() => {
                Gdk.RGBA transp = Gdk.RGBA();
                transp.parse("rgba(0,0,0,0)");
                buttonface.set_rgba(transp);
                settings.set_string("clock-face","rgba(0,0,0,0)");
            });
            attach(button_set_transparent, 1, 4, 1, 1);

            Gtk.Switch switch_markings = new Gtk.Switch();
            switch_markings.set_halign(Gtk.Align.END);
            attach(switch_markings, 1, 5, 1, 1);

            Gtk.Switch switch_local = new Gtk.Switch();
            switch_local.set_halign(Gtk.Align.END);
            attach(switch_local, 1, 7, 1, 1);
            combo_tz = new Gtk.ComboBoxText();
            combo_tz.set_wrap_width(5);
            for (int i = 0; i < TIMES.length; i++){
                combo_tz.insert_text(i, seconds_to_utc(TIMES[i]));
            }
            switch_local.notify["active"].connect(() => {
                combo_tz.set_sensitive(switch_local.get_active());
            });
            attach(combo_tz, 1, 8, 1, 1);

            Gtk.Switch switch_use_name = new Gtk.Switch();
            switch_use_name.set_halign(Gtk.Align.END);
            attach(switch_use_name, 1, 10, 1, 1);
            Gtk.Box namebox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 5);
            Gtk.Entry entry_name = new Gtk.Entry();
            entry_name.set_max_length(30);
            switch_use_name.notify["active"].connect(() => {
                entry_name.set_sensitive(switch_use_name.get_active());
            });
            namebox.pack_start(new Gtk.Label("Clock name: "), false, false);
            namebox.pack_end(entry_name, true, true);
            attach(namebox, 0, 11, 2, 1);

            settings.bind("clock-size",spin_clock_size,"value",SettingsBindFlags.DEFAULT);
            settings.bind("draw-marks",switch_markings,"active",SettingsBindFlags.DEFAULT);
            settings.bind("show-name", switch_use_name, "active", SettingsBindFlags.DEFAULT);
            settings.bind("use-time-zone", switch_local, "active", SettingsBindFlags.DEFAULT);
            settings.bind("time-zone", combo_tz, "active", SettingsBindFlags.DEFAULT);
            settings.bind("clock-name", entry_name, "text", SettingsBindFlags.DEFAULT);
            combo_tz.set_sensitive(settings.get_boolean("use-time-zone"));
            entry_name.set_sensitive(settings.get_boolean("show-name"));

            this.show_all();
        }

        private void setup_colorbutton(Gtk.ColorButton button, string part) {
            var loadcolor = settings.get_string(part);
            var color = Gdk.RGBA();
            color.parse(loadcolor);
            button.set_rgba(color);
            button.color_set.connect (() => {
                on_color_changed(button, part);
            });
        }

        private void on_color_changed(Gtk.ColorButton button, string part) {
            Gdk.RGBA c = button.get_rgba();
            settings.set_string(part, c.to_string());
        }
    }

    public class AnalogueClockApplet : Budgie.Applet {

        private GLib.Settings settings;
        private ulong panel_signal;
        private ulong settings_signal;

        private bool keep_running;
        private string clock_name = "";
        private int clock_size;
        private int clock_request_size;
        private int max_size = MAX_SIZE;

        protected Gtk.EventBox widget;
        private PanelClockImage.Clock clock;
        private ClockPopover.ClockPopover? popover = null;
        private unowned Budgie.PopoverManager? manager = null;

        public string uuid { public set; public get; }

        public AnalogueClockApplet(string uuid) {
            Object(uuid: uuid);

            /* Get our settings working first */
            this.settings_schema = "com.github.samlane-ma.analogue-clock";
            this.settings_prefix = "/com/solus-project/budgie-panel/instance/analogue-clock";
            this.settings = this.get_applet_settings(uuid);
            clock_size = settings.get_int("clock-size");
            keep_running = true;
            clock = new PanelClockImage.Clock(clock_size);
            widget = new Gtk.EventBox();
            popover = new ClockPopover.ClockPopover(widget);

            widget.add(clock);
            add(widget);

            widget.button_press_event.connect((e)=> {
                if (e.button != 1) {
                    return Gdk.EVENT_PROPAGATE;
                }
                if (popover.get_visible()) {
                    popover.hide();
                } else {
                    popover.select_day(clock.current_time);
                    this.manager.show_popover(widget);
                }
                return Gdk.EVENT_STOP;
            });

            load_settings("all");

            popover.get_child().show_all();
            show_all();

            settings_signal = settings.changed.connect((key) => {
                load_settings(key);
            });

            Idle.add(() => {
                watch_applet(uuid);
                return false;
            });

            Timeout.add(1000, () => {
                update_gui();
                clock.queue_draw();
                return keep_running;
            });
        }

        public override void update_popovers(Budgie.PopoverManager? manager) {
            this.manager = manager;
            manager.register_popover(widget, popover);
        }

        private void load_settings(string key) {
            if (key in "use-time-zone, time-zone, clock-name, show-name, all") {
                update_timedata();
                update_gui();
            }
            if (key in "draw-marks, all") {
                update_drawmarks();
            }
            if (key in "clock-size, all") {
                update_clock_size();
            }
            if (key in clock_parts || key == "all") {
                update_colors();
            }
            clock.queue_draw();
        }

        private void update_timedata() {
            bool use_timezone = settings.get_boolean("use-time-zone");
            int timezone = settings.get_int("time-zone");
            int time_offset = TIMES[timezone];
            clock_name = "Local Time";
            if (settings.get_boolean("use-time-zone")) {
                use_timezone = true;
                clock_name = seconds_to_utc(time_offset);
                clock.set_use_time_offset(time_offset);
            } else {
                clock.set_use_local_time();
            }
            if (settings.get_boolean("show-name")) {
                string load_name = settings.get_string("clock-name").strip();
                if (load_name != "") {
                    clock_name = load_name;
                }
            }
        }

        private void update_drawmarks() {
            clock.set_drawmarks(settings.get_boolean("draw-marks"));
        }

        private void update_clock_size() {
            clock_request_size = settings.get_int("clock-size");
            clock_size = (clock_request_size > max_size) ? max_size : clock_request_size;
            clock.update_size(clock_size);
        }

        private void update_colors() {
            foreach(string part in clock_parts) {
                clock.set_color(part, settings.get_string(part));
            }
        }

        private void update_gui() {
            var ct = clock.current_time;
            widget.set_tooltip_text(clock_name + "\n" + ct.format("%x"));
            popover.update_labels(ct.format("%A"), ct.format("%e %B %Y"), clock_name);
        }

        private bool find_applet(string find_uuid, string[] applet_list) {
            // Search panel applets for the given uuid
            return (find_uuid in applet_list);
        }

        private void watch_applet(string find_uuid) {
            // Check if the applet is still on the panel and ends cleanly if not
            string[] applets;
            string soluspath = "com.solus-project.budgie-panel";
            var panel_settings = new GLib.Settings(soluspath);
            string[] allpanels_list = panel_settings.get_strv("panels");
            foreach (string p in allpanels_list) {
                string panelpath = "/com/solus-project/budgie-panel/panels/".concat("{", p, "}/");
                var currpanelsubject_settings = new GLib.Settings.with_path(soluspath + ".panel", panelpath);
                applets = currpanelsubject_settings.get_strv("applets");
                if (find_applet(find_uuid, applets)) {
                     panel_signal = currpanelsubject_settings.changed["applets"].connect(() => {
                        applets = currpanelsubject_settings.get_strv("applets");
                        if (!find_applet(find_uuid, applets)) {
                            currpanelsubject_settings.disconnect(panel_signal);
                            settings.disconnect(settings_signal);
                            keep_running = false;
                        }
                    });
                }
            }
        }

        public override void panel_size_changed(int p, int i, int s) {
            // Scale the icon if necessary when panel is resized
            max_size = (max_size < MIN_SIZE) ? MIN_SIZE : p;
            clock_size = (clock_request_size > max_size) ? max_size : clock_request_size;
            clock.update_size(clock_size);
        }

        public override bool supports_settings() {
            return true;
        }

        public override Gtk.Widget? get_settings_ui() {
            return new AnalogueClockSettings(this.get_applet_settings(uuid));
        }

    }
}

[ModuleInit]
public void peas_register_types(TypeModule module) {
    // boilerplate - all modules need this
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(AnalogueClock.Plugin));
}
