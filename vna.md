---
layout: page
title: Vector Network Analyzer
permalink: /vna/
---

Interesting links
-----

Some interesting links on network analyzers:

 - [VNA Operating Guide](http://www.wetterlin.org/sam/SA/Operation/VNA_Guide.pdf)

 - [Three-Bead-Balun Reflection Bridge](http://www.wetterlin.org/sam/Reflection/3BeadBalunBridge.pdf)

 - [Ham VNA](http://dxatlas.com/HamVNA)

 - [Introduction to Network Analyzer Measurements](http://download.ni.com/evaluation/rf/Introduction_to_Network_Analyzer_Measurements.pdf)

Hardware
-----

The basic blocks of the system are shown on the following diagram:

![Multichannel Pulse Height Analyzer]({{ "/img/vna.png" | prepend: site.baseurl }})

The [projects/vna](https://github.com/pavel-demin/red-pitaya-notes/tree/master/projects/vna) directory contains one Tcl file [block_design.tcl](https://github.com/pavel-demin/red-pitaya-notes/blob/master/projects/vna/block_design.tcl) that instantiates, configures and interconnects all the needed IP cores.

Software
-----

The [projects/vna/server](https://github.com/pavel-demin/red-pitaya-notes/tree/master/projects/vna/server) directory contains the source code of the TCP server ([vna.c](https://github.com/pavel-demin/red-pitaya-notes/blob/master/projects/vna/server/vna.c)) that receives control commands and transmits the data to the control program running on a remote PC.

The [projects/vna/client](https://github.com/pavel-demin/red-pitaya-notes/tree/master/projects/vna/client) directory contains the source code of the control program ([vna.py](https://github.com/pavel-demin/red-pitaya-notes/blob/master/projects/vna/client/vna.py)).

![vna client]({{ "/img/vna-client.png" | prepend: site.baseurl }})

Getting started with MS Windows (pre-built control program)
-----

 - Download [SD card image zip file]({{ site.release-image }}) (more details about the SD card image can be found at [this link]({{ "/alpine/" | prepend: site.baseurl }})).
 - Copy the content of the SD card image zip file to an SD card.
 - Optionally, to start the application automatically at boot time, copy its `start.sh` file from `apps/vna` to the topmost directory on the SD card.
 - Insert the SD card in Red Pitaya and connect the power.
 - Download and unpack the [control program](https://github.com/pavel-demin/red-pitaya-notes/releases/download/20180305/vna-win32-20180305.zip).
 - Run the `vna.exe` program.
 - Type in the IP address of the Red Pitaya board and press Connect button.
 - Perform calibration and measurements.

Getting started with MS Windows (manual Python installation)
-----

 - Download [SD card image zip file]({{ site.release-image }}) (more details about the SD card image can be found at [this link]({{ "/alpine/" | prepend: site.baseurl }})).
 - Copy the content of the SD card image zip file to an SD card.
 - Optionally, to start the application automatically at boot time, copy its `start.sh` file from `apps/vna` to the topmost directory on the SD card.
 - Insert the SD card in Red Pitaya and connect the power.
 - Download and install [Python 3.4](https://www.python.org/ftp/python/3.4.4/python-3.4.4.msi).
 - Download and install [PyQt 5.5](https://sourceforge.net/projects/pyqt/files/PyQt5/PyQt-5.6/PyQt5-5.6-gpl-Py3.5-Qt5.6.0-x32-2.exe/download).
 - Start a command prompt using the `cmd.exe` program and run the `pip` command to install `matplotlib`:
{% highlight winbatch %}
C:\Python34\python.exe -m pip install --upgrade pip
C:\Python34\Scripts\pip.exe install matplotlib
{% endhighlight %}
 - Download and unpack the [control program](https://github.com/pavel-demin/red-pitaya-notes/releases/download/20180305/vna-python3-20180305.zip).
 - Start a command prompt using the `cmd.exe` program and run the control program:
{% highlight winbatch %}
C:\Python34\pythonw.exe vna.py
{% endhighlight %}
 - Type in the IP address of the Red Pitaya board and press Connect button.
 - Perform calibration and measurements.

Getting started with GNU/Linux
-----

 - Download [SD card image zip file]({{ site.release-image }}) (more details about the SD card image can be found at [this link]({{ "/alpine/" | prepend: site.baseurl }})).
 - Copy the content of the SD card image zip file to an SD card.
 - Optionally, to start the application automatically at boot time, copy its `start.sh` file from `apps/vna` to the topmost directory on the SD card.
 - Insert the SD card in Red Pitaya and connect the power.
 - Install required Python libraries:
{% highlight bash %}
sudo apt-get install python3-dev python3-pip python3-numpy python3-pyqt5 libfreetype6-dev
sudo pip3 install matplotlib
{% endhighlight %}
 - Clone the source code repository:
{% highlight bash %}
git clone https://github.com/pavel-demin/red-pitaya-notes
{% endhighlight %}
 - Run the control program:
{% highlight bash %}
cd red-pitaya-notes/projects/vna/client
python3 vna.py
{% endhighlight %}
 - Type in the IP address of the Red Pitaya board and press Connect button.
 - Perform calibration and measurements.

Building from source
-----

The installation of the development machine is described at [this link]({{ "/development-machine/" | prepend: site.baseurl }}).

The structure of the source code and of the development chain is described at [this link]({{ "/led-blinker/" | prepend: site.baseurl }}).

Setting up the Vivado environment:
{% highlight bash %}
source /opt/Xilinx/Vivado/2018.1/settings64.sh
{% endhighlight %}

Cloning the source code repository:
{% highlight bash %}
git clone https://github.com/pavel-demin/red-pitaya-notes
cd red-pitaya-notes
{% endhighlight %}

Building `vna.bit`:
{% highlight bash %}
make NAME=vna bit
{% endhighlight %}

Building `vna`:
{% highlight bash %}
arm-linux-gnueabihf-gcc -static -O3 -march=armv7-a -mcpu=cortex-a9 -mtune=cortex-a9 -mfpu=neon -mfloat-abi=hard projects/vna/server/vna.c -o vna -lm -lpthread
{% endhighlight %}

Building SD card image zip file:
{% highlight bash %}
source helpers/build-all.sh
{% endhighlight %}