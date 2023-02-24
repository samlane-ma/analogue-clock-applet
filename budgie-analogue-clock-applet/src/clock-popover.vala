/*
 *  ClockPopover
 *
 *  Popover used by the Analogue Clock Applet to display a calendar and
 *  options to open a Calendar application and system time settings
 *
 *  Copyright © 2020 Samuel Lane
 *  http://github.com/samlane-ma/
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

using Gtk, Gdk;

namespace ClockPopover {

    public class ClockPopover : Budgie.Popover {

        public string clock_name {get; set;}
        private Gtk.Button button_timesettings;
        private Gtk.Button button_calendar;
        private Gtk.Label popover_day;
        private Gtk.Label popover_date;
        private Gtk.Label popover_name;
        private Gtk.Calendar calendar;
        private Gtk.Grid grid_popover;
        private AppInfo calprov;

        private const string CALENDAR_MIME = "text/calendar";

        public ClockPopover(Gtk.Widget relative_parent) {
            Object(relative_to: relative_parent);

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

            popover_name = new Gtk.Label("");
            popover_name.set_halign(Gtk.Align.CENTER);
            popover_name.set_margin_end(20);

            calendar = new Gtk.Calendar();
            calprov = AppInfo.get_default_for_type(CALENDAR_MIME, false);
            var monitor = AppInfoMonitor.get();
            monitor.changed.connect(update_cal);
            update_cal();

            button_timesettings.clicked.connect(on_date_activate);;
            button_calendar.clicked.connect(on_cal_activate);

            grid_popover = new Gtk.Grid();
            grid_popover.attach(popover_name,0,0,2,1);
            grid_popover.attach(popover_day,0,1,2,1);
            grid_popover.attach(popover_date,0,2,2,1);
            grid_popover.attach(calendar,0,3,2,1);
            grid_popover.attach(button_calendar,0,4,2,1);
            grid_popover.attach(button_timesettings,0,5,2,1);
            this.add(grid_popover);
        }

        public void update_labels (string day, string date, string name) {
            popover_day.set_text(day);
            popover_date.set_text(date);
            popover_name.set_text(name);
        }

        public void select_day(DateTime date) {
            calendar.month = date.get_month () - 1;
            calendar.year = date.get_year ();
            calendar.select_day(date.get_day_of_month ());
        }

        private void update_cal() {
            calprov = AppInfo.get_default_for_type(CALENDAR_MIME, false);
            button_calendar.set_sensitive(calprov != null);
        }

        private void on_date_activate() {
            this.hide();
            string desktop_file = "gnome-datetime-panel.desktop";
            if (Environment.find_program_in_path("budgie-control-center") != null) {
                desktop_file = "budgie-datetime-panel.desktop";
            }
            var app_info = new DesktopAppInfo(desktop_file);
            if (app_info == null) {
                return;
            }
            try {
                app_info.launch(null, null);
            } catch (Error e) {
                message("Unable to launch %s: %s", desktop_file, e.message);
            }
        }

        private void on_cal_activate() {
            this.hide();
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