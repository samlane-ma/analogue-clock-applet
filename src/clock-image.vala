/*
 *  ClockImage
 *
 *  Creates and Returns a Cairo Surface With a Clock Image
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
 */

using Math, Cairo;

namespace ClockImage {

    private const double FULL_CIRCLE = 2 * Math.PI;

    // Contains the data to create the Cairo surface
    // Avoids the need to pass tons of arguments
    public struct ClockDrawInfo {
        int hour;
        int minute;
        int size;
        string line_color;
        string hands_color;
        string fill_color;
        bool draw_marks;
    }

    class ClockScalingInfo : Object {
    /* This will create a new object which scales the values used to draw the
     * clock. The size passed (in pixels) will cause data to be adusted so that
     * proportionate values are returned, while keeping some from scaling too
     * low and becoming hard to see at smaller sizes. Lenthy, but keeps the
     * Cairo drawing arguments more obvious.
     */ 
        private const int IMAGE_SIZE   = 200;
        private const int RADIUS       =  92;
        private const int MINHAND_LEN  =  76;
        private const int HOURHAND_LEN =  56;
        private const int MARK_LEN     =  10;
        private const int LINE_WIDTH   =  8; 
        private double scale;
        private double size;

        public ClockScalingInfo(double init_size){
            scale = init_size / IMAGE_SIZE;
            size = init_size;
        }
        public double radius { get {return RADIUS * scale;} }
        public double minhand_len { get {return MINHAND_LEN * scale;} }
        public double hourhand_len { get {return HOURHAND_LEN * scale;} }
        public double offset {set; default = 0;}
        public double mark_len {
            get {
                return (RADIUS - MARK_LEN - _offset) * scale;} 
            }
        public int center { get {return (int)size / 2;} }
        public double line_width {
            get {
                if (LINE_WIDTH * scale < 2){
                    return 2;
                }
                else{
                    return LINE_WIDTH * scale;
                }
            }
        }
        public double hand_width {
            get {
                if (LINE_WIDTH * scale < 2){ return 2;
                }
                else{
                    return LINE_WIDTH * scale;
                }
            }
        }
        public double mark_width{
            get {
                if (LINE_WIDTH * scale * 0.75  < 2){
                    return 2;
                }
                else{
                    return LINE_WIDTH * scale * 0.75;
                }
            }
        }
    }

    public Cairo.ImageSurface get_clock_surface(ClockDrawInfo clock) {
        // Returns a Cairo surface containing the clock image, which will get
        // added into a Gtk.Image

        int hours = clock.hour;
        int mins = clock.minute;

        if (hours > 12) {
            hours -= 12;
        }
        hours = hours * 5 + (mins / 12);
        // Clock looks better when drawn at even values for size / center
        // so lets turn odd values into even ones
        int draw_size = (clock.size % 2 == 0? clock.size : clock.size -1);

        ClockScalingInfo scaled = new ClockScalingInfo(draw_size);
        Cairo.ImageSurface surface = new Cairo.ImageSurface(Cairo.Format.ARGB32, draw_size, draw_size);
        Cairo.Context cr = new Cairo.Context(surface);
        Gdk.RGBA color = new Gdk.RGBA();

        // Clock face
        color.parse(clock.fill_color);
        cr.set_source_rgba(color.red, color.green, color.blue, color.alpha);
        cr.arc(scaled.center, scaled.center, scaled.radius, 0, FULL_CIRCLE);
        cr.fill();

        // draw clock outline
        color.parse(clock.line_color);
        cr.set_source_rgba(color.red, color.green, color.blue, color.alpha);
        cr.set_line_width(scaled.line_width);
        cr.arc(scaled.center, scaled.center, scaled.radius, 0, FULL_CIRCLE);
        cr.stroke();

        // draw clock hour markings
        if (clock.draw_marks) {
            cr.set_line_width(scaled.mark_width);
            for (int i = 0; i < 12; i++) {
                // draw 15 min marks larger than 5 min marks unless clock is small
                scaled.offset = ((i % 3 == 0 || draw_size < 30) ? 5 : 0);
                cr.move_to(get_coord("x", i * 5, scaled.radius, draw_size),
                           get_coord("y", i * 5, scaled.radius, draw_size));
                cr.line_to(get_coord("x", i * 5, scaled.mark_len, draw_size),
                           get_coord("y", i * 5, scaled.mark_len, draw_size));
                cr.stroke();               
            }
        }

        // draw clock hands
        color.parse(clock.hands_color);
        cr.set_source_rgba(color.red, color.green, color.blue, color.alpha);
        cr.set_line_width(scaled.hand_width);
        cr.move_to(scaled.center, scaled.center);
        cr.line_to(get_coord("x",hours, scaled.hourhand_len, draw_size),
                   get_coord("y",hours, scaled.hourhand_len, draw_size));
        cr.stroke();
        cr.move_to(scaled.center,  scaled.center);
        cr.line_to(get_coord("x",mins, scaled.minhand_len, draw_size),
                   get_coord("y",mins, scaled.minhand_len, draw_size));
        cr.stroke();

        // draw a little dot in the center
        cr.arc(scaled.center, scaled.center, scaled.line_width * 0.75, 0, FULL_CIRCLE);
        cr.fill();

        return surface;
    }

    private double get_coord(string c_type, int hand_position, double length, int scale) {
        // Returns the circle coordinates for the given minute/hour 
        // c_type can be either "x" or "y"
        hand_position -= 15;
        if (hand_position < 0) {
            hand_position += 60;
        }
        double radians = (hand_position * (Math.PI * 2) / 60);
        if (c_type == "x") {
            return scale / 2 + length * cos(radians);
        }
        else if (c_type == "y") {
            return scale / 2 + length * sin(radians);
        }
        return 0;
    }
}
