/*
 *  Analogue Clock Applet for the Budgie Panel
 *
 *  Copyright © 2020 Samuel Lane
 *  http://github.com/samlane-ma/
 *
 *  Thanks to the Ubuntu Budgie Developers for both their assistance,
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
 */

using Gtk, Gdk;
using CreateSVG;
using Math;

namespace AnalogueClock {

    const int IMAGE_SIZE   = 200;
    const int MIN_SIZE     =  22;
    const int RADIUS       =  92;
    const int MINHAND_LEN  =  76;
    const int HOURHAND_LEN =  56;
    const int MARK_LEN     =  10;
    const int LINE_WIDTH   =  10; 

    public class Plugin : Budgie.Plugin, Peas.ExtensionBase{

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
                                                    MIN_SIZE,IMAGE_SIZE,1,1,0);
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
            string hex_code =
            "#%02x%02x%02x"
            .printf((uint)(Math.round(c.red*255)),
                    (uint)(Math.round(c.green*255)),
                    (uint)(Math.round(c.blue*255))).up();
            app_settings.set_string(part, hex_code);
        }
    }

    public class AnalogueClockApplet : Budgie.Applet {

        private GLib.Settings? panel_settings;
        private GLib.Settings? currpanelsubject_settings;
        private GLib.Settings app_settings;
        private ulong panel_signal;
        private ulong settings_signal;
        private string soluspath;
        private bool keep_running;

        private Gtk.Box panel_icon;
        private Gtk.Image clock_image;
        private Gdk.Pixbuf pixbuf;
        private string filename;
        private Svgfile clock_svg;
        private bool draw_hour_marks;
        private int max_size;
        private int clock_scale;
        private string hands_color;
        private string line_color;
        private string fill_color;
        private int old_minute;

        public string uuid { public set; public get; }

        public AnalogueClockApplet(string uuid) {

            soluspath = "com.solus-project.budgie-panel";

            string username = Environment.get_user_name();
            filename = "/tmp/".concat(username, "_panel_analogue_clock.svg");

            max_size = MIN_SIZE;
            old_minute = -1;
            keep_running = true;

            panel_icon = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 1);
            add(panel_icon);
            clock_image = new Gtk.Image();
            panel_icon.pack_start(clock_image, false, false, 0);
            show_all();

            app_settings = new GLib.Settings ("com.github.samlane-ma.analogue-clock");
            load_settings();
            settings_signal = app_settings.changed.connect(() => {load_settings();
                                                                  update_clock();} );
            Idle.add(() => {watch_applet(uuid); return false;});
            Timeout.add_seconds(5,update_time);
        }

        private void load_settings(){
            // Load the settings
            clock_scale = app_settings.get_int("clock-size");
            if (clock_scale > max_size) {
                clock_scale = max_size;
            }
            hands_color = app_settings.get_string("clock-hands");
            line_color = app_settings.get_string("clock-outline");
            fill_color = app_settings.get_string("clock-face");
            draw_hour_marks = app_settings.get_boolean("draw-marks");
        }

        private void validate_settings() {
            // Verify the color names are valid, reload defaults if not.
            // Shoudl only happen if invalid dconf settings are manually entered
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

        private void update_clock(){
            // force the redraw & make sure no bad settings were given
            old_minute = -1;
            load_settings();
            validate_settings();
            update_time();
        }
        
        private bool update_time() {
            // Check the time, draw a new clock if necessary
            var current_time = new DateTime.now_local();
            int curr_hour = current_time.get_hour();
            int curr_min = current_time.get_minute();
            if (curr_min != old_minute){
                old_minute = curr_min;
                create_clock_image(curr_hour,curr_min);
                Idle.add(() => { load_new_image();
                                 return false;
                });
            }
            return keep_running;
        }
        
        private void load_new_image () {
           // Load the generated svg into the panel icon
            try {
                pixbuf = new Gdk.Pixbuf.from_file_at_scale(filename,clock_scale,
                                                           clock_scale, true);
                clock_image.set_from_pixbuf(pixbuf);
            }
            catch (Error e) {
                stdout.printf("unable to load image\n");
            }
        }

        private void create_clock_image (int hours, int mins){
            // Write the clock image svg to a temporary file
            if (hours > 12) {
                hours -= 12;
            }
            hours = hours * 5 + (mins / 12);
            clock_svg = new Svgfile(filename, IMAGE_SIZE, IMAGE_SIZE);
            clock_svg.add_circle(IMAGE_SIZE / 2, IMAGE_SIZE / 2, RADIUS,
                                 fill_color, line_color, LINE_WIDTH);
            clock_svg.add_circle(IMAGE_SIZE / 2, IMAGE_SIZE / 2, LINE_WIDTH,
                                 hands_color, hands_color, 1);
            if (draw_hour_marks) {
                for (int i = 0; i < 12; i++) {
                    clock_svg.add_line(get_coord("x", i * 5, RADIUS), get_coord("y",i * 5, RADIUS),
                                       get_coord("x", i * 5, RADIUS - MARK_LEN),
                                       get_coord("y", i * 5, RADIUS -MARK_LEN), line_color, 6);
                }
            }
            clock_svg.add_line(IMAGE_SIZE / 2, IMAGE_SIZE / 2, get_coord("x",hours,HOURHAND_LEN),
                               get_coord("y",hours,HOURHAND_LEN), hands_color, LINE_WIDTH);
            clock_svg.add_line(IMAGE_SIZE / 2, IMAGE_SIZE / 2, get_coord("x",mins,MINHAND_LEN),
                               get_coord("y",mins,MINHAND_LEN), hands_color, LINE_WIDTH);
            clock_svg.write_svg();
        }

        private int get_coord (string c_type, int hand_position, int length) {
            // Returns the circle coordinates for the given minute/hour 
            hand_position -= 15;
            if (hand_position < 0) {
                hand_position += 60;
            }
            double radians = (hand_position * (Math.PI * 2) / 60);
            if (c_type == "x") {
                return (int)Math.round(IMAGE_SIZE / 2 + length * cos(radians));
            }
            else if (c_type == "y") {
                return (int)Math.round(IMAGE_SIZE / 2 + length * sin(radians));
            }
            return 0;
        }

        private bool find_applet (string find_uuid, string[] applet_list) {
            // Search panel applets for the given uuid
            for (int i = 0; i < applet_list.length; i++) {
                if (applet_list[i] == find_uuid) {
                    return true;
                }
            }
            return false;
        }

        private void watch_applet (string find_uuid) {
            // Check if the applet is still on the panel and end cleanly if not
            string[] applets;
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

        public override void panel_size_changed(int p, int i, int s){
            // Scale the icon if necessary when panel is resized
            max_size = p - 6;
            if (max_size < MIN_SIZE){
                max_size = MIN_SIZE;
            }
            int current_size = app_settings.get_int("clock-size");
            if (current_size > max_size) {
                clock_scale = max_size;
            }
            update_clock();
        }

        public override void panel_position_changed(Budgie.PanelPosition position) {
            // Keep the icon centered in both horizontal and vertical panels
            if ( position == Budgie.PanelPosition.LEFT ||
                 position == Budgie.PanelPosition.RIGHT ) {
                panel_icon.set_orientation(Gtk.Orientation.VERTICAL);
            }
            else {
                panel_icon.set_orientation(Gtk.Orientation.HORIZONTAL);
            }
            update_clock();
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
public void peas_register_types(TypeModule module){

    // boilerplate - all modules need this
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(AnalogueClock.Plugin));
}
