/*
 * Budgie Analog Clock Widget
 * Author: Sam Lane
 * Copyright © 2023 Sam Lane
 * Website=https://github.com/samlane-ma/
 *
 * Copyright Budgie Desktop Developers
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or any later version. This
 * program is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU General Public License for more details. You
 * should have received a copy of the GNU General Public License along with this
 * program.  If not, see <https://www.gnu.org/licenses/>.
 */

public class RavenAnalogClockPlugin : Budgie.RavenPlugin, Peas.ExtensionBase {
    public Budgie.RavenWidget new_widget_instance(string uuid, GLib.Settings? settings) {
        return new RavenAnalogClockWidget(uuid, settings);
    }

    public bool supports_settings() {
        return true;
    }
}

public class RavenAnalogClockWidget : Budgie.RavenWidget {

    private uint timeout_id = 0;
    private RavenClockImage.Clock? clock;
    private Settings? settings;
    private Gtk.Box box;
    private Gtk.Label header_label;
    private Gtk.Image header_icon;
    private int clock_size = 50;
    private int clock_scale = 100;
    private bool use_dropdown;
    private const string[] CLOCKPARTS = {"face-color", "frame-color", "hand-color", "seconds-color"};

    private RavenClockDropDown dropdown;

    public RavenAnalogClockWidget(string uuid, GLib.Settings? settings) {

        this.settings = settings;
        initialize(uuid, settings);

        header_label = new Gtk.Label("Analog Clock");
        header_icon = new Gtk.Image.from_icon_name("raven-analog-clock-symbolic", Gtk.IconSize.MENU);

        dropdown = new RavenClockDropDown(header_label, header_icon);

        clock_scale = settings.get_int("clock-size");
        use_dropdown = settings.get_boolean("use-dropdown");

        size_allocate.connect( () => {
            // Try our best to keep the clock from expanding the Raven panel
            // Need to accomidate a 5px margin on the sides (at 100%, it looks better with margins)
            clock_size = get_allocated_width() - 10;
            Idle.add(() => {
                update_clock_size();
                return false;
            }, GLib.Priority.DEFAULT);
        });

        box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 5);
        box.set_size_request(clock_size, clock_size);
        box.set_halign(Gtk.Align.CENTER);
        box.set_hexpand(true);

        create_clock();
        clock.set_margin_top(5);
        clock.set_margin_bottom(5);
        box.add(clock);

        if (use_dropdown) {
            add(dropdown);
            dropdown.add_content(box);
        } else {
            add(box);
        }

        show_all();

        settings.changed.connect(on_settings_changed);

        // only update the clock when Raven is open
        raven_expanded.connect((expanded) => {
            if (!expanded && timeout_id != 0) {
                Source.remove(timeout_id);
                timeout_id = 0;
            } else if (expanded && timeout_id == 0) {
                timeout_id = Timeout.add(1000, () => {
                    clock.queue_draw();
                    return GLib.Source.CONTINUE;
                });
            }
        });
    }

    private void on_dropdown_toggled(bool show_dropdown) {
        // Switch between adding the clock directly to the panel or using a dropdown
        if (!show_dropdown) {
            dropdown.remove_content(box);
            remove(dropdown);
            add(box);
        } else {
            remove(box);
            dropdown.add_content(box);
            add(dropdown);
        }
        show_all();
    }

    private void create_clock() {
        clock = new RavenClockImage.Clock(clock_size);
        foreach (string part in CLOCKPARTS) {
            clock.set_color(part, settings.get_string(part));
        }
        int style = settings.get_int("clock-style");
        clock.update_style((style % 2 == 0), (style > 1), settings.get_boolean("show-seconds"));
    }

    private void on_settings_changed(Settings settings, string key) {
        if (key in CLOCKPARTS) {
            clock.set_color(key, settings.get_string(key));
            return;
        }
        if (key == "clock-size") {
            clock_scale = settings.get_int("clock-size");
            update_clock_size();
            return;
        }
        if (key == "show-seconds" || key == "clock-style") {
            int style = settings.get_int("clock-style");
            clock.update_style((style % 2 == 0), (style > 1), settings.get_boolean("show-seconds"));
            return;
        }
        if (key == "use-dropdown") {
            use_dropdown = settings.get_boolean("use-dropdown");
            on_dropdown_toggled(use_dropdown);
        }
    }

    private void update_clock_size() {
        int new_size = (int) (clock_scale * clock_size / 100);
        clock.update_size(new_size);
        box.set_size_request(new_size, new_size);
    }

    public override Gtk.Widget build_settings_ui() {
        return new RavenAnalogClockSettings(get_instance_settings());
    }
}

[ModuleInit]
public void peas_register_types(TypeModule module) {
    // boilerplate - all modules need this
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type(typeof(Budgie.RavenPlugin), typeof(RavenAnalogClockPlugin));
}
