/*
 * CreateSVG for Budgie Analogue Clock
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

namespace CreateSVG {

    private string file_name;
    private int size_x;
    private int size_y;
    private List<string> svgitems;

    class Svgfile : Object {

        public Svgfile(string filename, int x, int y){
            file_name = filename;
            size_x = x;
            size_y = y;
            string svgheader = "<?xml version=\"1.0\" encoding=\"utf-8\" ?>";
            string svgsize = "<svg height=\"" + y.to_string() + "\" width=\"" + 
                             x.to_string() + "\">";
            svgitems = new List<string>();
            svgitems.append(svgheader);
            svgitems.append(svgsize);
        }

        public void write_svg(){
            svgitems.append("</svg>");
            try {
                var file = File.new_for_path (file_name);
                if (file.query_exists ()) {
                   file.delete ();
                }
                var dos = new DataOutputStream (file.create (FileCreateFlags.REPLACE_DESTINATION));
                foreach (string entry in svgitems) {
                    dos.put_string(entry);
                }
            } catch (Error e) {
                stderr.printf("unable to write file: %s\n",e.message);
            }
        }

        public void add_circle(int cx, int cy, int r, string fill, string stroke, int stroke_width){
            string svgline = "<circle cx=\"" + cx.to_string() + "\" cy=\"" + cy.to_string() + "\"" +
                             " fill=\"" + fill + "\" r=\"" + r.to_string() + "\" stroke=\"" +
                             stroke +"\" stroke-width=\"" + stroke_width.to_string() + "\"/>";
            svgitems.append(svgline);
        }

        public void add_line(int x_start, int y_start, int x_end, int y_end, string stroke, int stroke_width){
            string svgline = "<line stroke=\"" + stroke + "\" stroke-width=\"" + stroke_width.to_string() +
                             "\" x1=\"" + x_start.to_string() + "\" x2=\"" + x_end.to_string() + "\" y1=\"" +
                             y_start.to_string() + "\" y2=\"" + y_end.to_string() + "\"/>";
            svgitems.append(svgline);
        }
    }
}
