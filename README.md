# omlox-rpc-NodeMCU
Example for connecting a temperature sensor to the RPC interface on the omlox hub.

## Setup
Tested with a build containing these modules: adc, bit, bme280, file, gpio, http, i2c, mqtt, net, node, pwm, rtctime, sjson, spi, tmr, uart, websocket, wifi
Probably only bme280, gpio, http, i2c sjson, tmr, wifi are necessary.
You can get a custom firmware build from pages like https://nodemcu-build.com/.
Then you can flash the firmware to your ESP8266 using the esptool. Having done that, you can either use the luatool or the ESPlorer to connect to the ESP8266
and write your scripts to it.

## Usage
To use the example, you have to put in your network configuration at the top of the code. You might also want to change the configuration of the I2C interface. Then you need to upload the file to the ESP8266 and run it, either from the command line inerface or through the init.lua file. 

