---
layout: page
title: Development machine
permalink: /development-machine/
---

The following are the instructions for installing a virtual machine with [Debian](https://www.debian.org/releases/jessie) 8.10 (amd64) and [Vivado Design Suite](https://www.xilinx.com/products/design-tools/vivado) 2018.1 with full SDK.

Creating virtual machine with Debian 8.10 (amd64)
-----

- Download and install [VirtualBox](https://www.virtualbox.org/wiki/Downloads)

- Download [mini.iso](http://ftp.heanet.ie/pub/ftp.debian.org/debian/dists/jessie/main/installer-amd64/current/images/netboot/mini.iso) for Debian 8.10

- Start VirtualBox

- Create at least one host-only interface:

  - From the "File" menu select "Preferences"

  - Select "Network" and then "Host-only Networks"

  - Click the small "+" icon

  - Click "OK"

- Create a new virtual machine:

  - Click the blue "New" icon

  - Pick a name for the machine, then select "Linux" and "Debian (64 bit)"

  - Set the memory size to at least 2048 MB

  - Select "Create a virtual hard drive now"

  - Select "VDI (VirtualBox Disk Image)"

  - Select "Dynamically allocated"

  - Set the image size to at least 129 GB

  - Select the newly created virtual machine and click the yellow "Settings" icon

  - Select "Network" and enable "Adapter 2" attached to "Host-only Adapter"

  - Set "Adapter Type" to "Paravirtualized Network (virtio-net)" for both "Adapter 1" and "Adapter 2"

  - Select "System" and select only "CD/DVD" in the "Boot Order" list

  - Select "Storage" and select "Empty" below the "IDE Controller"

  - Click the small CD/DVD icon next to the "CD/DVD Drive" drop-down list and select the location of the `mini.iso` image

  - Click "OK"

- Select the newly created virtual machine and click the green "Start" icon

- Press TAB when the "Installer boot menu" appears

- Edit the boot parameters at the bottom of the boot screen to make them look like the following:

  (the content of the `goo.gl/eagfri` installation script can be seen at [this link](https://github.com/pavel-demin/red-pitaya-notes/blob/gh-pages/etc/debian.seed))

{% highlight bash %}
linux initrd=initrd.gz url=goo.gl/eagfri auto=true priority=critical interface=auto
{% endhighlight %}

- Press ENTER to start the automatic installation

- After installation is done, stop the virtual machine

- Select the newly created virtual machine and click the yellow "Settings" icon

- Select "System" and select only "Hard Disk" in the "Boot Order" list

- Click "OK"

- The virtual machine is ready to use (the default password for the `root` and `red-pitaya` accounts is `changeme`)

Accessing the virtual machine
-----

The virtual machine can be accessed via SSH. To display applications with graphical user interfaces, a X11 server ([Xming](http://sourceforge.net/projects/xming) for MS Windows or [XQuartz](http://xquartz.macosforge.org) for Mac OS X) should be installed on the host computer. X11 forwarding should be enabled in the SSH client.

Installing Vivado Design Suite
-----

- Download "Vivado HLx 2018.1: All OS installer Single-File Download" from the [Xilinx download page](https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools/2018-1.html) or from [this direct link](https://www.xilinx.com/member/forms/download/xef.html?filename=Xilinx_Vivado_SDK_2018.1_0405_1.tar.gz) (the file name is Xilinx_Vivado_SDK_2018.1_0405_1.tar.gz)

- Create the `/opt/Xilinx` directory, unpack the installer and run it:
{% highlight bash %}
mkdir /opt/Xilinx
cd /opt/Xilinx
tar -zxf Xilinx_Vivado_SDK_2018.1_0405_1.tar.gz
cd Xilinx_Vivado_SDK_2018.1_0405_1
sed -i '/uname -i/s/ -i/ -m/' xsetup
./xsetup
{% endhighlight %}

- Follow the installation wizard and don't forget to select "Software Development Kit" on the installation customization page (for detailed information on installation, see [UG973](https://www.xilinx.com/support/documentation/sw_manuals/xilinx2018_1/ug973-vivado-release-notes-install-license.pdf))

- Xilinx SDK requires `gmake` that is unavailable on Debian. The following command creates a symbolic link called `gmake` and pointing to `make`:
{% highlight bash %}
ln -s make /usr/bin/gmake
{% endhighlight %}