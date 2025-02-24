# IDF-WebCamServer
ESP-IDF Version of the WebCamServer

Taken from the espressif arduino example, but converted to work with the esp-idf framework.

### Create sdkconfig
Run idf.py menuconfig to generate sdkconfig. The defaults should work.

### Update main/secrets.h

#define WIFI_SSID "Your_SSID"
#define WIFI_PASS "Your_Password"

