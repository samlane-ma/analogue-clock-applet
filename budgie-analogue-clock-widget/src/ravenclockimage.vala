/*
 * Budgie Raven Analog Clock Image
 * Part of Budgie Analog Clock Widget
 * Author: Sam Lane
 * Copyright © 2023 Sam Lane
 * Website=https://github.com/samlane-ma/
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or any later version. This
 * program is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU General Public License for more details. You
 * should have received a copy of the GNU General Public License along with this
 * program.  If not, see <https://www.gnu.org/licenses/>.
 */
namespace RavenClockImage {

struct XYCoords {
    public double x;
    public double y;
}

class ClockInfo : Object {
    /* A lot of math goes into figuring where to draw everything and it gets confusing
       where to make the adjuctments if we need to make small tweaks to the appearance
       (like lengths or widths of clock parts.) In addition, all these values really only
       change when the clock size changes, so if we automatically update them all when
       the size variable is changed, we can avoid re-running these calculations every time
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
    public int small_markwidth { get; private set; }
    public double small_markend { get; private set; }
    public double large_markend { get; private set; }
    public double markstart { get; private set; }
    // Values when drawing the hands
    public int handwidth { get; private set; }
    public int secondhand_width { get; private set; }
    public double minute_handlength { get; private set; }
    public double hourhand_length { get; private set; }
    public double secondhand_length { get; private set; }
    public int center_dotsize { get; private set; }
    // Different offsets for the numbers when minute markings aren't drawn
    public double marked_offset { get; private set; default = 0.75; }
    public double unmarked_offset { get; private set; default = 0.82; }

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
        face_linewidth = _size / 50;
        face_radius = (_size -2 ) / 2 - 1;
        frame_linewidth = result_with_min(1, _size / 50 - 1);
        frame_radius = (_size - _size / 50) / 2;
        large_markwidth = result_with_min(2, _size / 90 + 1);
        small_markwidth = result_with_min(1, _size / 180 + 1);
        large_markend = radius * 0.91;
        small_markend = radius * 0.94;
        markstart = radius * 0.98;
        handwidth = result_with_min(1, _size / 50 - 1);
        secondhand_width = result_with_min(1, _size / 70 - 1);
        minute_handlength = radius * 0.74;
        hourhand_length = radius * 0.53;
        secondhand_length = radius * 0.79;
        center_dotsize = result_with_min(2, _size / 120 + 1);
    }

    private int result_with_min(int min, double math) {
        return math < min ? min : (int) math;
    }
}


public class Clock : Gtk.DrawingArea {

    private const double FULL_CIRCLE = 2 * Math.PI;
    private bool showseconds = true;
    private int time_offset = 0;
    private bool use_timezone = false;
    private bool draw_markings = true;
    private bool use_roman = false;
    private DateTime current_time;
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

    public void set_color(string part, string color) {
        if (part == "hand-color") {
            hand_color.parse(color);
        } else if (part == "face-color") {
            face_color.parse(color);
        } else if (part == "frame-color") {
            frame_color.parse(color);
        } else {
            second_color.parse(color);
        }
        queue_draw();
    }

    public void update_style(bool drawmarks, bool useroman, bool show_seconds) {
        draw_markings = drawmarks;
        use_roman = useroman;
        showseconds = show_seconds;
        queue_draw();
    }

    public void update_size(int size) {
        set_size_request(size, size);
        clockinfo.size = size;
        queue_draw();
    }

    private bool draw_clock(Cairo.Context context) {
        if (!use_timezone) {
            current_time = new DateTime.now_local();
        } else {
             current_time = new DateTime.now_utc().add_seconds(time_offset);
        }
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

        if (draw_markings) {
            context.set_line_cap(Cairo.LineCap.SQUARE);
            for (int i = 0; i < 60; i++) {
                // don't draw minute marks on smaller clocks
                if (i % 5 != 0 && clockinfo.size < 135) continue;
                double end;
                double linewid;
                if (i % 5 == 0) {
                    // draw the larger marks every 5 minutes
                    end = clockinfo.large_markend;
                    linewid = clockinfo.large_markwidth;
                } else {
                    // draw minute marks every minute
                    end = clockinfo.small_markend;
                    linewid = clockinfo.small_markwidth;
                }
                context.set_line_width(linewid);
                var startpos = get_coords(i, clockinfo.markstart, clockinfo.center);
                var endpos = get_coords(i, end, clockinfo.center);
                draw_line(context, startpos, endpos);
            }
        }
        // when not using marks, numbers can be closer to frame
        var number_offset = draw_markings ? clockinfo.marked_offset : clockinfo.unmarked_offset;

        draw_numbers(context, number_offset);
    }

    private void draw_numbers (Cairo.Context context, double offset) {
        string[] roman = {"I", "II", "III", "IV", "V", "VI",
                          "VII", "VIII", "IX", "X", "XI", "XII"};
        string numeral;
        context.set_source_rgba(frame_color.red, frame_color.green, frame_color.blue, frame_color.alpha);
        context.set_font_size(clockinfo.size / 13 - 1);
        context.select_font_face("Sans", Cairo.FontSlant.NORMAL, Cairo.FontWeight.BOLD);
        for (int i=0; i < 12; i++) {
            double radians = i * (FULL_CIRCLE) / 12;
            // shift the numbers so 12 is at the top
            int number = (i > 9) ? i - 9 : i + 3;

            // if using roman numerals, convert to roman
            numeral = use_roman ? roman[number - 1] : number.to_string();

            // text extents calculates how much room the numbers take up
            Cairo.TextExtents extents;
            context.text_extents (numeral, out extents);
            int t_x = (int) (clockinfo.center + (clockinfo.center * offset) * Math.cos(radians));
            int t_y = (int) (clockinfo.center + (clockinfo.center * offset) * Math.sin(radians));
            context.move_to(t_x - extents.width / 2 , t_y + extents.height / 2);
            context.show_text(numeral);
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
