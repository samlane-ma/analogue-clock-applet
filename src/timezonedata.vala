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

/*void main () {

    for (int i=0; i < TIMES.length; i++) {
        string utc_time = seconds_to_utc(TIMES[i]);
        stdout.printf("%s\n", utc_time);
    }
}
*/

}