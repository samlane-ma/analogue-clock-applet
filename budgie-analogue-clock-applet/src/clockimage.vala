/*
 * Author: Sam Lane
 * Copyright © 2023 Ubuntu Budgie Developers
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or any later version. This
 * program is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU General Public License for more details. You
 * should have received a copy of the GNU General Public License along with this
 * program.  If not, see <https://www.gnu.org/licenses/>.
 */

namespace PanelClockImage {

struct XYCoords {
    public double x;
    public double y;
}

class ClockInfo : Object {
    /* A lot of math goes into figuring where to draw everything and it gets confusing
       where to make the adjuctments if we need to make small tweaks to the appearance
       (like lengths or widths of clock parts.) In addition, all these values really only
       changed when the clock size changes, so if we automatically update them all when
       the size variable is changed, we can avoid re- running these calculations every time
       the clock is redrawn.
    */
    private int _size;
    public int center { get; private set; }
    public int radius { get; private set; }
    public int face_linewidth { get; private set; }
    public double face_radius { get; private set; }
    public int frame_linewidth { get; private set; }
    public int frame_radius { get; private set; }
    // Values when drawing the markings on the clock face
    public int large_markwidth { get; private set; }
    public double large_markend { get; private set; }
    public double markstart { get; private set; }
    // Values when drawing the hands
    public int handwidth { get; private set; }
    public int secondhand_width { get; private set; }
    public double minute_handlength { get; private set; }
    public double hourhand_length { get; private set; }
    public double secondhand_length { get; private set; }
    public int center_dotsize { get; private set; }

    public int size {
        get { return _size; }
        set { update_values(value); }
    }

    public ClockInfo(int initial_size) {
        update_values(initial_size);
    }

    private void update_values(int new_size){
        _size = new_size;
        center = _size / 2;
        radius = _size / 2;
        frame_linewidth = minimum_int(1, _size * 0.04);
        frame_radius = (int) (radius * 0.95);
        face_linewidth = _size / 50;
        face_radius = frame_radius;
        large_markwidth = frame_linewidth;
        large_markend = radius * 0.84;
        markstart = radius * 0.92;
        handwidth = minimum_int(1, (_size + 4) * 0.05);
        secondhand_width = minimum_int(1, _size / 70 - 1);
        minute_handlength = radius * 0.74;
        hourhand_length = radius * 0.51;
        secondhand_length = radius * 0.79;
        center_dotsize = minimum_int(1, radius * 0.06);
    }
}

private int minimum_int (int min, double math) {
    int val = (int) math;
    return (val < min ? min : val);
}

public class Clock : Gtk.DrawingArea {

    private const double FULL_CIRCLE = 2 * Math.PI;
    private int clock_number = 0;
    private bool showseconds = false;
    private int time_offset = 0;
    private bool use_timezone = false;
    private bool draw_marks = true;

    public DateTime current_time { get; private set; }
    private ClockInfo clockinfo;

    private Gdk.RGBA face_color = {255, 255, 255, 1}; // white
    private Gdk.RGBA frame_color = {0, 0, 0, 1}; // black
    private Gdk.RGBA hand_color = {0, 0, 0, 1}; // black
    private Gdk.RGBA second_color = {255, 0, 0, 1}; // red

    public Clock(int size) {
        clockinfo = new ClockInfo(size);
        set_halign(Gtk.Align.CENTER);
        set_valign(Gtk.Align.CENTER);
        set_size_request(clockinfo.size, clockinfo.size);
        update_time();
        draw.connect(draw_clock);
    }

    public void set_use_time_offset(int offset) {
        time_offset = offset;
        use_timezone = true;
        queue_draw();
    }

    public void set_use_local_time() {
        time_offset = 0;
        use_timezone = false;
        queue_draw();
    }

    public void set_drawmarks(bool marks) {
        draw_marks = marks;
        queue_draw();
    }

    public void set_color(string part, string color) {
        if (part == "clock-hands") {
            hand_color.parse(color);
        } else if (part == "clock-face") {
            face_color.parse(color);
        } else if (part == "clock-outline") {
            frame_color.parse(color);
        }
        queue_draw();
    }

    public void update_style(int style, bool show_seconds) {
        clock_number = style;
        showseconds = show_seconds;
        queue_draw();
    }

    public void update_size(int size) {
        set_size_request(size, size);
        clockinfo.size = size;
        queue_draw();
    }

    private void update_time() {
        if (!use_timezone) {
            current_time = new DateTime.now_local();
        } else {
            current_time = new DateTime.now_utc().add_seconds(time_offset);
        }
    }

    private bool draw_clock(Cairo.Context context) {
        update_time();
        draw_face(context);
        draw_frame(context);
        draw_hands(context);
        return true;
    }

    private void draw_face(Cairo.Context context) {
        // just a circle
        context.set_source_rgba(face_color.red, face_color.green, face_color.blue, face_color.alpha);
        context.set_line_width (clockinfo.face_linewidth);
        context.arc(clockinfo.center, clockinfo.center, clockinfo.face_radius, 0, FULL_CIRCLE);
        context.fill();
    }

    private void draw_frame (Cairo.Context context) {
        // draw the outside frame circle
        context.set_line_width (clockinfo.frame_linewidth);
        context.set_source_rgba(frame_color.red, frame_color.green, frame_color.blue, frame_color.alpha);
        context.arc(clockinfo.center, clockinfo.center, clockinfo.frame_radius, 0, FULL_CIRCLE);
        context.stroke();
        context.set_line_cap(Cairo.LineCap.SQUARE);
        if (draw_marks) {
            for (int i = 0; i < 12; i++) {
                var end = clockinfo.large_markend;
                var linewid = clockinfo.large_markwidth;
                context.set_line_width(linewid);
                var startpos = get_coords(i * 5, clockinfo.markstart, clockinfo.center);
                var endpos = get_coords(i * 5, end, clockinfo.center);
                draw_line(context, startpos, endpos);
            }
        }
    }

    private void draw_hands(Cairo.Context context) {

        int hour = current_time.get_hour();
        int minute = current_time.get_minute();
        int seconds = (int) current_time.get_seconds();
        context.set_source_rgba(hand_color.red, hand_color.green, hand_color.blue, hand_color.alpha);
        context.set_line_width(clockinfo.handwidth);
        context.set_line_cap(Cairo.LineCap.ROUND);

        // draw the hour hand - hour offset is the additional"ticks" to move the hour hand
        // past the hour (based on the number of minutes) so the hour hand moves smoothly
        int hour_offset = minute / 12;
        var endpos = get_coords(hour * 5 + hour_offset, clockinfo.hourhand_length, clockinfo.center);
        draw_line(context, {clockinfo.center, clockinfo.center}, endpos);

        // draw the minute hands
        endpos = get_coords(minute, clockinfo.minute_handlength, clockinfo.center);
        draw_line(context, {clockinfo.center, clockinfo.center}, endpos);

        // draw the seconds hand
        if (showseconds) {
            context.set_source_rgba(second_color.red, second_color.green, second_color.blue, second_color.alpha);
            context.set_line_width(clockinfo.secondhand_width);
            endpos = get_coords(seconds, clockinfo.secondhand_length, clockinfo.center);
            draw_line(context, {clockinfo.center, clockinfo.center}, endpos);
        }

        // just draw a small dot on the center above the hands
        context.arc(clockinfo.center, clockinfo.center, clockinfo.center_dotsize, 0, FULL_CIRCLE);
        context.fill();
    }

    private void draw_line(Cairo.Context context, XYCoords start, XYCoords end) {
        context.move_to(start.x, start.y);
        context.line_to(end.x, end.y);
        context.stroke();
    }

    private XYCoords get_coords(int hand_position, double length, double center) {
        // Because 0 degrees on a circle is 3:00, we use a cheap trick here
        // to rotate the calculations so 0 degrees would be 12:00
        hand_position -= 15;
        if (hand_position < 0) {
            hand_position += 60;
        }
        // Get the x and y positions based on the time and hand length
        double radians = (hand_position * FULL_CIRCLE / 60);
        double x = length * Math.cos(radians) + center;
        double y = length * Math.sin(radians) + center;
        return { x, y };
    }
}

}
