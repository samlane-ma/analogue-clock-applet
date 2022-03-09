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
using TimeZoneData;

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

        private GLib.Settings settings;
        private Gtk.ComboBoxText combo_tz;

        public AnalogueClockSettings(GLib.Settings? settings) {

            this.settings = settings;

            string[] labels = {"Clock Size (px)", "Frame Color", "Hands Color",
                               "Face Color", "Transparent face", "Show hour marks",
                               "", "Select Timezone", "Time Zone (UTC)","", "Show Clock Name"};
            Gdk.RGBA color;
            string loadcolor;

            for (int i=0; i < labels.length; i++) {
                Gtk.Label label = new Gtk.Label(labels[i]);
                label.set_halign(Gtk.Align.START);
                label.set_valign(Gtk.Align.CENTER);
                this.attach(label, 0, i, 1, 1);
            }

            Gtk.Adjustment adj = new Gtk.Adjustment(settings.get_int("clock-size"),
                                                    MIN_SIZE,MAX_SIZE,1,1,0);
            Gtk.SpinButton spin_clock_size = new Gtk.SpinButton(adj,1.0,0);
            spin_clock_size.set_digits(0);
            this.attach(spin_clock_size, 1, 0, 1, 1);

            loadcolor = settings.get_string("clock-outline");
            color = Gdk.RGBA();
            color.parse(loadcolor);
            Gtk.ColorButton buttonframe = new Gtk.ColorButton.with_rgba(color);
            buttonframe.color_set.connect (() =>
                             { on_color_changed(buttonframe,"clock-outline");});
            this.attach(buttonframe, 1, 1, 1, 1);

            loadcolor = settings.get_string("clock-hands");
            color = Gdk.RGBA();
            color.parse(loadcolor);
            Gtk.ColorButton buttonhands = new Gtk.ColorButton.with_rgba(color);
            buttonhands.color_set.connect (() =>
                             { on_color_changed(buttonhands,"clock-hands");});
            this.attach(buttonhands, 1, 2, 1, 1);

            loadcolor = settings.get_string("clock-face");
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
            this.attach(buttonface, 1, 3, 1, 1);

            Gtk.Button button_set_transparent = new Gtk.Button.with_label("Set");
            button_set_transparent.clicked.connect(() => {
                                    Gdk.RGBA transp = Gdk.RGBA();
                                    transp.parse("rgba(0,0,0,0)");
                                    buttonface.set_rgba(transp);
                                    settings.set_string("clock-face","none");});
            this.attach(button_set_transparent, 1, 4, 1, 1);
            Gtk.Switch switch_markings = new Gtk.Switch();
            switch_markings.set_halign(Gtk.Align.END);
            this.attach(switch_markings, 1, 5, 1, 1);

            Gtk.Switch switch_local = new Gtk.Switch();
            switch_local.set_halign(Gtk.Align.END);
            this.attach(switch_local, 1, 7, 1, 1);
            combo_tz = new Gtk.ComboBoxText();
            combo_tz.set_wrap_width(5);
            for (int i = 0; i < TIMES.length; i++){
                combo_tz.insert_text(i, seconds_to_utc(TIMES[i]));
            }
            switch_local.notify["active"].connect(() => {
                                          combo_tz.set_sensitive(switch_local.get_active()); } );
            this.attach(combo_tz, 1, 8, 1, 1);

            Gtk.Switch switch_use_name = new Gtk.Switch();
            switch_use_name.set_halign(Gtk.Align.END);
            this.attach(switch_use_name, 1, 10, 1, 1);
            Gtk.Box namebox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 5);
            Gtk.Entry entry_name = new Gtk.Entry();
            entry_name.set_max_length(30);
            switch_use_name.notify["active"].connect(() => {
                                          entry_name.set_sensitive(switch_use_name.get_active()); } );
            namebox.pack_start(new Gtk.Label("Clock name: "), false, false);
            namebox.pack_end(entry_name, true, true);
            this.attach(namebox, 0, 11, 2, 1);

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

        private void on_color_changed(Gtk.ColorButton button, string part) {
            Gdk.RGBA c = button.get_rgba();
            settings.set_string(part, c.to_string());
        }
    }

    public class AnalogueClockApplet : Budgie.Applet {

        private GLib.Settings? panel_settings;
        private GLib.Settings? currpanelsubject_settings;
        private GLib.Settings settings;
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
        private DateTime current_time;

        private int time_offset = 0;
        private bool use_timezone = false;
        private string clock_name = "";

        ClockPopover.ClockPopover? popover = null;
        private unowned Budgie.PopoverManager? manager = null;

        public string uuid { public set; public get; }

        public AnalogueClockApplet(string uuid) {
            Object(uuid: uuid);

		    /* Get our settings working first */
		    this.settings_schema = "com.github.samlane-ma.analogue-clock";
		    this.settings_prefix = "/com/solus-project/budgie-panel/instance/analogue-clock";
		    this.settings = this.get_applet_settings(uuid);

            max_size = MIN_SIZE;
            update_needed = true;
            keep_running = true;
            clock = new PanelClock();

            widget = new Gtk.EventBox();
            popover = new ClockPopover.ClockPopover(widget);

            panel_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 1);
            widget.add(panel_box);
            add(widget);
            clock_image = new Gtk.Image();
            panel_box.pack_start(clock_image, false, false, 0);

            widget.button_press_event.connect((e)=> {
                if (e.button != 1) {
                    return Gdk.EVENT_PROPAGATE;
                }
                if (popover.get_visible()) {
                    popover.hide();
                } else {
                    DateTime date;
                    if (!use_timezone) {
                        date = new DateTime.now_local();
                    }
                    else {
                        date = new DateTime.now_utc().add_seconds(time_offset);
                    }
                    popover.select_day(date);
                    this.manager.show_popover(widget);
                }
                return Gdk.EVENT_STOP;
            });

            popover.get_child().show_all();
            show_all();

            settings_signal = settings.changed.connect(force_clock_redraw);
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
            use_timezone = settings.get_boolean("use-time-zone");
            int timezone = settings.get_int("time-zone");
            time_offset = TIMES[timezone];
            clock_name = "Local Time";
            if (settings.get_boolean("use-time-zone")) {
                use_timezone = true;
                clock_name = seconds_to_utc(time_offset);
            }
            if (settings.get_boolean("show-name")) {
                string load_name = settings.get_string("clock-name").strip();
                if (load_name != "") {
                    clock_name = load_name;
                }
            }
            clock.size = settings.get_int("clock-size");
            if (clock.size > max_size) {
                clock.size = max_size;
            }
            // Don't recursively trigger this if validate_settings fixes things
            if (settings_signal != null) {
                SignalHandler.block((void*)settings,settings_signal);
                validate_settings();
                SignalHandler.unblock((void*)settings,settings_signal);
            }
            clock.hands_color = settings.get_string("clock-hands");
            clock.line_color = settings.get_string("clock-outline");
            clock.fill_color = settings.get_string("clock-face");
            clock.draw_marks = settings.get_boolean("draw-marks");
        }

        private void validate_settings() {
            // Verify the color names are valid, reload defaults if not.
            // Should only happen if invalid dconf settings are manually entered
            string[] setting_name = {"clock-hands", "clock-outline", "clock-face"};
            string[] default_color = {"#000000", "#000000", "#FFFFFF"};
            for (int i = 0; i < 3; i++) {
                Gdk.RGBA testcolor = Gdk.RGBA();
                string colorname = settings.get_string(setting_name[i]);
                if (colorname != "none" && !testcolor.parse(colorname)) {
                    settings.set_string(setting_name[i],default_color[i]);
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
            if (use_timezone) {
                current_time = new DateTime.now_utc().add_seconds(time_offset);
            }
            else {
                current_time = new DateTime.now_local();
            }
            if (current_time.get_minute() != old_minute || update_needed) {
                old_minute = current_time.get_minute();
                clock.hour = current_time.get_hour();
                clock.minute = current_time.get_minute();
                update_needed = false;
                Idle.add(() => { clock_image.set_from_surface(clock.get_clock_surface());
                                 panel_box.set_tooltip_text(clock_name + "\n" + current_time.format("%x"));
                                 popover.update_labels(current_time.format("%A"),
                                                       current_time.format("%e %B %Y"),
                                                       clock_name);
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
                            settings.disconnect(settings_signal);
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
            int current_size = settings.get_int("clock-size");
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

    }
}

[ModuleInit]
public void peas_register_types(TypeModule module) {

    // boilerplate - all modules need this
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(AnalogueClock.Plugin));
}
