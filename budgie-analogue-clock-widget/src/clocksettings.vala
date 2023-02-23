/*
 *  Budgie Analog Clock Widget Settings
 *  Part of Budgie Analog Clock Widget
 *  Author: Sam Lane
 *  Copyright © 2023 Sam Lane
 *  Website=https://github.com/samlane-ma/
 *  This program is free software: you can redistribute it and/or modify it under
 *  the terms of the GNU General Public License as published by the Free Software
 *  Foundation, either version 3 of the License, or any later version. This
 *  program is distributed in the hope that it will be useful, but WITHOUT ANY
 *  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 *  A PARTICULAR PURPOSE. See the GNU General Public License for more details. You
 *  should have received a copy of the GNU General Public License along with this
 *  program.  If not, see <https://www.gnu.org/licenses/>.
 */

public class RavenAnalogClockSettings : Gtk.Grid {

    private const string[] labels = {"Size:", "Clock Style:", "Face Color:", "Face Alpha:",
                                     "Frame Color:", "Hand Color:", "Seconds Color:", "Show Seconds:", "Use Dropdown:"};
    private const string[] color_buttons = {"frame-color", "hand-color", "seconds-color"};
    private Gdk.RGBA color;
    private Settings settings;

    public RavenAnalogClockSettings (Settings? app_settings) {

        settings = app_settings;

        set_column_homogeneous(false);
        set_column_spacing(10);

        for (int i = 0; i < 9; i++){
            Gtk.Label label = new Gtk.Label(labels[i]);
            label.set_halign(Gtk.Align.END);
            attach(label, 0, i, 1, 1);
        }

        Gtk.Adjustment size_adj = new Gtk.Adjustment(65, 40, 110, 1, 10, 10);
        Gtk.SpinButton spin_size = new Gtk.SpinButton(size_adj, 1.0, 0);
        spin_size.set_snap_to_ticks(true);
        attach(spin_size, 1, 0, 1, 1);
        spin_size.set_width_chars(5);
        spin_size.output.connect((button) => {
            var adj = button.get_adjustment();
            button.set_text((adj.get_value()).to_string() + "%");
            return true;
        });
        settings.bind("clock-size", spin_size, "value", SettingsBindFlags.DEFAULT);

        Gtk.Adjustment style_adj = new Gtk.Adjustment(0, 0, 4, 1, 1, 1);
        Gtk.SpinButton spin_style = new Gtk.SpinButton(style_adj, 1.0, 0);
        attach(spin_style, 1, 1, 1, 1);
        settings.bind("clock-style", spin_style, "value", SettingsBindFlags.DEFAULT);

        // create the face color button and the transparency slider - these two are connected
        Gtk.Scale face_alpha = new Gtk.Scale.with_range(Gtk.Orientation.HORIZONTAL, 0.0, 1.0, 0.05);
        face_alpha.set_draw_value(false);
        string loadcolor = settings.get_string("face-color");
        color.parse(loadcolor);
        Gtk.ColorButton button_face = new Gtk.ColorButton.with_rgba(color);
        face_alpha.set_value(color.alpha);
        button_face.color_set.connect (() => {
            on_color_changed(button_face,"face-color");
            update_face_alpha(face_alpha.get_value(), button_face);
        });
        face_alpha.value_changed.connect(() => {
            update_face_alpha(face_alpha.get_value(), button_face);
        });
        attach(button_face, 1, 2, 1, 1);
        attach(face_alpha, 1, 3, 1, 1);

        // Create the rest of the color buttons - they are all similar
        int pos = 4;
        foreach (string part in color_buttons) {
            loadcolor = app_settings.get_string(part);
            color.parse(loadcolor);
            Gtk.ColorButton button = new Gtk.ColorButton.with_rgba(color);
            button.color_set.connect (() => {
                on_color_changed(button, part);
            });
            attach(button, 1, pos++, 1, 1);
        }

        Gtk.Switch switch_seconds = new Gtk.Switch();
        switch_seconds.set_hexpand(false);
        switch_seconds.set_halign(Gtk.Align.END);
        settings.bind("show-seconds",switch_seconds,"active",SettingsBindFlags.DEFAULT);
        attach(switch_seconds, 1, 7, 1, 1);

        Gtk.Switch switch_dropdown = new Gtk.Switch();
        switch_dropdown.set_hexpand(false);
        switch_dropdown.set_halign(Gtk.Align.END);
        settings.bind("use-dropdown",switch_dropdown,"active",SettingsBindFlags.DEFAULT);
        attach(switch_dropdown, 1, 8, 1, 1);

        show_all();
    }

    private void update_face_alpha(double value, Gtk.ColorButton button) {
        // when changing the alpha slider, we have to change the color button to reflect it
        Gdk.RGBA color = button.get_rgba();
        color.alpha = value;
        settings.set_string("face-color", color.to_string());
        button.rgba = color;
    }

    private void on_color_changed(Gtk.ColorButton button, string part) {
        Gdk.RGBA c = button.get_rgba();
        settings.set_string(part, c.to_string());
    }
}
