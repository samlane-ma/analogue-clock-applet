/*
 *  Analogue Clock Applet for the Budgie Panel
 *
 *  Copyright © 2020 Samuel Lane
 *  http://github.com/samlane-ma/
 *
 *  Thanks to the Ubuntu Budgie Developers for their assistance,
 *  examples, and pieces of code I borrowed to make this work.

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


namespace TimeZoneData {

    const int TIMES[] = {-43200, -39600, -36000, -34200, -32400, -28800, -25200,
                         -21600, -18000, -14400, -12600, -10800,  -7200,  -3600,
                              0,   3600,   7200,  10800,  12600,  14400,  16200,
                          18000,  19800,  20700,  21600,  23400,  25200,  28800,
                          31500,  32400,  34200,  36000,  37800,  39600,  43200,
                          45900, 46800, 50400 };


    string seconds_to_utc(int time) {
        string hour = (time / 3600).to_string("%+03i");
        string minute = (time.abs() % 3600 / 60).to_string("%02i");
        return ("UTC" + hour + ":" + minute);
    }
}