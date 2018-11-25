# Setting Up Your Computer to Work with EMUs


Programming the ESP8266 is done using [Esplorer](http://esp8266.ru/esplorer-latest/?f=ESPlorer.zip) or [NodeMCU-uploader](https://github.com/kmpm/nodemcu-uploader).  Both work on Windows and OSX.  Esplorer requires [Java](https://www.java.com/en/download/help/download_options.xml) to be installed, and NodeMCU-uploader requires [Python](https://www.python.org/downloads/).

In order to use EMUs with your computer, there are several software aspects to install
1. **Drivers:** The Lolin D1 Mini uses the CH340G USB to serial chipset. In order to connect, you need to install the driver for this
2. **Firmware Flasher:** You need a program to flash a firmware to the D1 Mini: either [nodemcu-pyflasher](https://github.com/marcelstoer/nodemcu-pyflasher) or [esptool](https://github.com/espressif/esptool)
3. **Programming IDE:** You need a program to run code, display output, and download data from the D1 Mini, [ESPlorer](https://esp8266.ru/esplorer/) is the best option and works on Windows, OSX, and Linux
4. **(optional) Commandline Interface:** [nodemcu-uploader](https://github.com/kmpm/nodemcu-uploader) allows you to run, upload, and download files via the commandline. Note that it requires [Python](https://www.python.org/downloads/) and pip (installs with latest Python) to be installed.

## Windows

1. Download and unzip the [Windows CH340G driver](/Drivers/CH340G%20-%20Windows%20-%20v3.4.2014.8.zip). Run Setup.exe and click the Install button. If a prompt appears about an unsigned Windows driver, allow it. A step-by-step guide is [here](http://www.dnatechindia.com/ch340g-drivers-download-installation-guide.html). If the driver is installed correctly, plugging in a D1 mini should result in a device showing up in Devices and Printers with the associated COM port name (e.g., COM7). This is the port you use to connect with.
2. Download [nodemcu-pyflasher](https://github.com/marcelstoer/nodemcu-pyflasher/releases)
Install the Windows CH340G driver.
3. Download [ESPlorer](http://esp8266.ru/esplorer-latest/?f=ESPlorer.zip), and set up (see below). Generally, if java is set up correctly, you can run it by clicking on the ESPlorer.jar or ESPlorer.bat files. Alternatively, in a command prompt, switch to the ESPlorer folder and run `java -jar ESPlorer.jar`. ESPlorer requires [Java SE version 7 or 8](https://www.java.com/en/download/manual.jsp). You may have problems running it with Java version 9 and may need to roll java back. 

## Mac OSX

1. CH340G driver installation for OSX sometimes has problems, and there are now several versions of the driver circulating. We have had good results with [this one that we include here](/Drivers/CH340G%20-%20Mac.zip), but [this website](https://kig.re/2014/12/31/how-to-use-arduino-nano-mini-pro-with-CH340G-on-mac-osx-yosemite.html) maintains a resource dedicated to getting the working for various versions of OSX. You will likely need to go to System Preferences > Security and Privacy and allow apps downloaded from Anywhere to be run. If the driver is installed correctly, plugging in a D1 Mini and running `ls /dev/cu*` from a terminal should list a serial port name starting with `cu.wchusbserial`. This is the port you use to connect with.  If the driver does not work, there is an uninstallation procedure [here](https://sparks.gogo.co.nz/ch340.html).
2. Download [nodemcu-pyflasher](https://github.com/marcelstoer/nodemcu-pyflasher/releases)
3. Download [ESPlorer](http://esp8266.ru/esplorer-latest/?f=ESPlorer.zip), and set up (see below). Generally, if java is set up correctly, you can run it by clicking on the ESPlorer.jar file. Alternatively, in a terminal, switch to the ESPlorer folder and run `java -jar ESPlorer.jar`. ESPlorer requires [Java SE version 7 or 8](https://www.java.com/en/download/manual.jsp). You may have problems running it with Java version 9 and may need to roll java back. 

## Linux

The support for working with EMUs in Linux is not as good as with Windows and OSX and is less well-tested.  We recommend that only experienced Linux users attempt this.  Help on the internet may be difficult to find.

1. In many versions of Linux, no driver installation is required. If that is not the case, there is a Linux driver available [here](https://sparks.gogo.co.nz/ch340.html). If the driver is installed correctly, plugging in a D1 Mini and running `ls /dev/ttyUSB` from a terminal should list a serial port name such as `ttyUSB0`. This is the port you use to connect with. You will also need to have user permissions to access the /dev/ttyUSB0 device. On Linux, you can enable this by adding your user to the dialout group with `sudo adduser <username> dialout`, and rebooting or logging out and in again. Without fixing the permissions issue, ESPlorer will be unable to access the serial port.
2. Install [esptool](https://github.com/espressif/esptool).  Note: this requires [Python](https://www.python.org/downloads/) and pip (installs with latest Python) to be installed.  Often, this is already the case, however.  Alternatively, it should be possible to build [nodemcu-pyflasher](https://github.com/marcelstoer/nodemcu-pyflasher) from source for Linux, though no release currently provided.
3. Download [ESPlorer](http://esp8266.ru/esplorer-latest/?f=ESPlorer.zip), and set up (see below). Generally, if java is set up correctly, you can run it by clicking on the ESPlorer.jar file. Alternatively, in a terminal, switch to the ESPlorer folder and run `java -jar ESPlorer.jar`. ESPlorer requires [Java SE version 7 or 8](https://www.java.com/en/download/manual.jsp). You may have problems running it with Java version 9 and may need to roll java back. 

## Setting up ESPlorer

Open ESPlorer, and click on the Settings tab, where we'll make some changes

* Uncheck AutoSave file to disk before save to ESP
* Uncheck AutoSave file to ESP after save to disk
* Uncheck Autodetect firmware
* Uncheck Command Echo
* Check "Turbo Mode"
* Set Delay after answer to 0 ms
* If there is an option to, uncheck AutoRun file after save to ESP
* At the top, beside the large Open button is a dropdown that is set at 9600 by default.  This is the baud or connection speed.  Set this to 115200, which is the speed that the EMU communicates with by default.
* Click on the Snippets Tab.  Click Edit Snippet0.  Name it Abort, and put abort=1 in the box and click Save

There's also a tutorial for using Esplorer [here](http://www.engineersgarage.com/tutorials/getting-started-esplorer-ide). and an ebook on it [here](http://esp8266.ru/download/esp8266-doc/Getting%20Started%20with%20the%20ESPlorer%20IDE%20-%20Rui%20Santos.pdf).
