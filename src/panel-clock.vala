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

namespace PanelClockFunctions {

    private const double FULL_CIRCLE = 2 * Math.PI;

    private class ClockScalingInfo : Object {
    /* This will create a new object which scales the values used to draw the
     * clock. The size passed (in pixels) will cause data to be adusted so that
     * proportionate values are returned, while keeping some from scaling too
     * low and becoming hard to see at smaller sizes. Lenthy, but keeps the
     * Cairo drawing arguments more obvious.
     */
        private const int IMAGE_SIZE   = 200;
        private const int RADIUS       =  92;
        private const int MINHAND_LEN  =  72;
        private const int HOURHAND_LEN =  52;
        private const int MARK_LEN     =  10;
        private const int LINE_WIDTH   =  8;
        private double scale;
        private int size;

        public ClockScalingInfo(int init_size){
            scale = (double)init_size / IMAGE_SIZE;
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
        public double center { get {return (double)size / 2;} }
        public double line_width {
            get {
                if (size < 40 ){
                    return 1;
                }
                else{
                    return LINE_WIDTH * scale;
                }
            }
        }
        public double hand_width {
            get {
                if (size < 40){
                    return 1;
                }
                else{
                    return LINE_WIDTH * scale;
                }
            }
        }
        public double mark_width{
            get {
                if (size < 60){
                    return 1;
                }
                else{
                    return LINE_WIDTH * scale * 0.75;
                }
            }
        }
    }

    public class PanelClock {

        public int hour {get; set;}
        public int minute {get; set;}
        public int size {get; set;}
        public string line_color {get; set;}
        public string hands_color {get; set;}
        public string fill_color {get; set;}
        public bool draw_marks {get; set;}
//      FOR POSSIBLE FUTURE USE TO USE AN EXTERNAL IMAGE FOR THE CLOCK BACKGROUND
//      public bool use_image {get; set; default = false;}
//      public string? image_file {get; set;}

        public Cairo.ImageSurface get_clock_surface() {
            // Returns a Cairo surface containing the clock image, which will get
            // added into a Gtk.Image

            int hour_pos = hour;
            int minute_pos = minute;

            if (hour_pos > 12) {
                hour_pos -= 12;
            }
            hour_pos = hour_pos * 5 + (minute_pos / 12);
            ClockScalingInfo scaled = new ClockScalingInfo(size);
            Cairo.ImageSurface surface = new Cairo.ImageSurface(Cairo.Format.ARGB32, size, size);
            Cairo.Context cr = new Cairo.Context(surface);
            Gdk.RGBA color = new Gdk.RGBA();

            // Clock face
            color.parse(fill_color);
            cr.set_source_rgba(color.red, color.green, color.blue, color.alpha);
            cr.arc(scaled.center, scaled.center, scaled.radius, 0, FULL_CIRCLE);
            cr.fill();

//          FOR POSSIBLE FUTURE USE TO USE AN EXTERNAL IMAGE FOR THE CLOCK BACKGROUND
//          Gdk.Pixbuf image = new Gdk.Pixbuf.from_file_at_scale(image_file,size,size,true);
//          Gdk.cairo_set_source_pixbuf(cr, image, 0, 0);
//          cr.paint();

            // draw clock outline
            color.parse(line_color);
            cr.set_source_rgba(color.red, color.green, color.blue, color.alpha);
            cr.set_line_width(scaled.line_width);
            cr.arc(scaled.center, scaled.center, scaled.radius, 0, FULL_CIRCLE);
            cr.stroke();

            // draw clock hour markings
            if (draw_marks) {
                cr.set_line_cap(Cairo.LineCap.BUTT);
                cr.set_line_width(scaled.mark_width);
                for (int i = 0; i < 12; i++) {
                    // draw 15 min marks larger than 5 min marks unless clock is small
                    scaled.offset = ((i % 3 == 0 || size < 30) ? 5 : 0);
                    cr.move_to(get_coord("x", i * 5, scaled.radius, scaled.center),
                               get_coord("y", i * 5, scaled.radius, scaled.center));
                    cr.line_to(get_coord("x", i * 5, scaled.mark_len, scaled.center),
                               get_coord("y", i * 5, scaled.mark_len, scaled.center));
                    cr.stroke();
                }
            }

            // draw clock hands
            color.parse(hands_color);
            cr.set_source_rgba(color.red, color.green, color.blue, color.alpha);
            cr.set_line_width(scaled.hand_width);
            cr.set_line_cap(Cairo.LineCap.ROUND);
            cr.move_to(scaled.center, scaled.center);
            cr.line_to(get_coord("x", hour_pos, scaled.hourhand_len, scaled.center),
                       get_coord("y", hour_pos, scaled.hourhand_len, scaled.center));
            cr.stroke();
            cr.move_to(scaled.center,  scaled.center);
            cr.line_to(get_coord("x", minute_pos, scaled.minhand_len, scaled.center),
                       get_coord("y", minute_pos, scaled.minhand_len, scaled.center));
            cr.stroke();

            // draw a little dot in the center
            cr.arc(scaled.center, scaled.center, scaled.line_width * 0.75, 0, FULL_CIRCLE);
            cr.fill();

            return surface;
        }

        private double get_coord(string c_type, int hand_position, double length, double center) {
            // Returns the circle coordinates for the given minute/hour
            // c_type can be either "x" or "y"
            hand_position -= 15;
            if (hand_position < 0) {
                hand_position += 60;
            }
            double radians = (hand_position * FULL_CIRCLE / 60);
            if (c_type == "x") {
                return center + length * cos(radians);
            }
            else if (c_type == "y") {
                return center + length * sin(radians);
            }
            return 0;
        }
    }
}
