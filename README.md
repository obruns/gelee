# gelee - Gigaset Elements LifetimE Extension

On March, 25th, 2024 - with a period for action of just four days -
customers of Gigaset Elements got informed that the cloud service would
be shut down on March 29th due to insolvency of the company.

This project aims to collect as much data as possible while the service
is still active and then - eventually - provide a service that can be
self-hosted on-prem or in the cloud.

## Tools

### download-all-opensource.sh

This script scrapes all archives from the iframe that is embedded at
[gigaset.com/opensource](https://www.gigaset.com/de_de/cms/lp/open-source.html)
that is mentioned in the license agreements that come with Gigaset
products.

You'll need approx. 35GiB for all archives. The script creates three
files named `checksums.sha{1,256,512}` which are also part of this
repository. The more mirrors we create, the more trust anchors there
are. To verify, use

```sh
sha512sum -c checksums.sha512
```

## TODO

* [osmocom](https://osmocom.org/projects/misc-dect-hacks/wiki/Gigaset_Elements_Base) provides a good starting point for the hardware.
  Unfortunately, they do not mention the exact download URL but it appears to be either [bl17](https://cms.gigaset.com/opensource/GigasetElements/gigaset_elements_bl17_opensource.tar.gz) and/or [bl26](https://cms.gigaset.com/opensource/GigasetElements/gigaset_elements_bl26_opensource.tar.gz)
  - Whenever sourcecode/tarball is mentioned, it refers to these
    archives which are from 2013-10-18 and 2013-10-31.
* Comparing the output from the serial console (final snippet on the osmocom page), there are a couple of keywords that I could not find in either of the source tarballs:
  - rxdect452
  - rtxdectstack
  - jbusserver
  - ...
* There is a file `src/init_rootfs/etc/init.d/S60private.sh` which would execute `/mnt/data/private.sh` if it exists
  - a `private.sh`
* conclusion: it is important to create a proper dump of the existing firmware image and/or copy the files before wiping anything
* cr16 is a CPU of the CompactRISC family
  - there does not appear to be a Qemu emulation for that
* see search results for [bflt executable](https://duckduckgo.com/?q=bflt+executable&ia=web)
* use [mitmproxy](https://github.com/mitmproxy/mitmproxy) ([documentation](https://docs.mitmproxy.org/stable/) to
  - sniff the communication between the base station and the cloud service
  - sniff the comminucation between the app and the cloud service (less important because of [gigaset-elements-api](https://github.com/matthsc/gigaset-elements-api))
* Which tarballs are required for
  - button
  - door bell
  - camera
  - climate sensor
  - door/window sensor
* Is the DECT-ULE code part of the open-source tarballs?
  - Kind-of: These are some shell scripts and some bflt binaries.
* Identify versions of the shipped OSS.

### Extract patches and turn them into commits

The changes made to particular files were added as a footer to the file
itself. See e.g. `src/dialog/cr16boot/common/display_options.c`:

```cpp
//
//Changes introduced by Gigaset Elements GmbH:
//Modification date:  2013-10-31 10:54:49.652221564
//@@ -31,22 +31,22 @@
//
// void display_banner(bd_t *bd)
// {
```

This is easily extractable and can be turned into individual commits
grouped by modification date *if* the modification date differs at all.

```sh
rg --files-with-matches '^//Changes introduced by Gigaset Elements GmbH:' | less

rg --files-with-matches '^//Modification date:  2013-10-31 10:5[34]:' | wc -l
```

Conclusion: The timestamp was created as archive creation time. Create
one commit per OSS project.

### CompactRISC CR16C

```sh
# search inside the directory extracted from the source tarball
rg --files-with-matches mcr16c gigaset_elements_bl26_opensource
```

### Basestation API

The client-facing API is visible when watching the activity of
`https://app.gigaset-elements.com/#/events/` through the browsers'
developer tools.

What's more difficult is the API used by the basestation to publish
events. When trying to sniff the network communication with
[mitmproxy](https://mitmproxy.org/), an attempt is made to talk to
`https://api-bs.gigaset-elements.de`. However, that URL is referenced just
once in the image: `src/init_rootfs/usr/bin/simulate_delete.sh`:

```sh
# $1 - sensorId
# $2 - deviceId
echo {"method":"POST", "uri":"https://api-bs.gigaset-elements.de/api/v1/endnode/$2/$1/sink/ev", "payload": {"payload": "deleted"}, "clientId": 138} | sender 127.0.0.1 "CloudTX"
```

This leaves a couple of questions:

* Is this really just guarded by the "deviceId"?
  - see `deviceid=CFE8D287ED60B4B8393398706788C121` in the kernel commandline at [osmocom](https://osmocom.org/projects/misc-dect-hacks/wiki/Gigaset_Elements_Base)
* What is "CloudTX" (also vs. the other topics; see below)?
  - are the topics case-insensitive ("cloudTX" vs "CloudTX")
* The file is called `simulate_delete.sh` - does this mean that `sender`
  (and `receiver`) are just debugging tools left in the image?
  - this does not appear to be the case because there are quite some
    results for "sender" and "receiver" (limited to the relevant dir):

```sh
rg --files-with-matches 'sender|receiver' src/init_rootfs
src/init_rootfs/bin/send2ule
src/init_rootfs/bin/listenall
src/init_rootfs/usr/bin/fw_lib
src/init_rootfs/usr/bin/gotosleep.sh
src/init_rootfs/usr/bin/sensor_version.sh
src/init_rootfs/usr/bin/led_lan.sh
src/init_rootfs/usr/bin/delete_sensor.sh
src/init_rootfs/usr/bin/sirenon.sh
src/init_rootfs/usr/bin/sirenoff.sh
src/init_rootfs/usr/bin/simulate_delete.sh
src/init_rootfs/usr/bin/sensor_update.sh
src/init_rootfs/usr/bin/regoff.sh
src/init_rootfs/usr/bin/fw_prepare.sh
src/init_rootfs/usr/bin/regon.sh
```

I tried `rg --text` and ran `strings` on the binary blobs (`uleapp`,
`receiver`, ...) but the URL was present nowhere else. I also searched
GitHub for `api-bs.gigaset-elements` but also no results

All(?) CA certificates at `./src/opensource/certs/` are expired. I'm
therefore certain that basestations have received updates of various
files in the meantime.

I wasn't successful in using [mitmproxy](https://mitmproxy.org/), yet.
Absent proper tools to use the serial console via UART I can only try to
go via different routes:

* The images `./src/dialog/cr16boot/image452.bin` and `./src/dialog/cr16boot/image452_service.bin`
  contain `bootargs=.*ipaddr=192.168.1.10.*serverip=192.168.1.34`
* This appears to be baked by some files in `src/dialog/cr16boot/` or
  maybe `src/opensource/u-boot-env-tools/fw_env.c`
* The `serverip` is used like in `src/init_rootfs/bin/stauleapp`:

```sh
fw_printenv -n serverip
```

* This may allow us to place arbitrary files and start them, like [dropbear](http://matt.ucc.asn.au/dropbear/dropbear.html)
  or alternative CA certificates.

### DECT-ULE communication

`src/init_rootfs/bin/listenall` contains topics, some of which are not
active:

```sh
TOPICS="ulecontrol uleevent watchdog"
# coma cloud cloudTX cloudRX
```

Some of the files below `src/init_rootfs/usr/bin/` (see previous
section) appear to be dedicated to sensor control based on DECT-ULE.

### System Startup

See `src/init_rootfs/etc/init.d/S40reef.sh` and other scripts.

Inetd has telnet open if `system_locked=false`, see `./src/init_rootfs/etc/inetd.conf`.

`./src/init_rootfs/etc/udhcpc.scr`

### Non-volatile storage?

```sh
src/init_rootfs/usr/bin/nvs_backup.sh

nc -w 30 -p 5600 -l \> backup.file.name
nc -w 2 $1 5600 < /mnt/data/nvs.bin
```

### Bootargs

```sh
xxd ./src/dialog/cr16boot/image452.bin >| /tmp/x_production
xxd ./src/dialog/cr16boot/image452_service.bin >| /tmp/x_service
```

```
# from /tmp/x_service
bootargs=noinitrd root=/dev/ram0 rw init=/linuxrc earlyprintk=serial console=ttyS0.bootcmd=bootm E8000.bootdelay=1.baudrate=115200.ethaddr=02:4e:ef:10:51:10.ipaddr=192.168.1.10.serverip=192.168.1.34.netmask=255.255.255.0.bootfile="vmlinuz".boot_from=flash.board_rev=RevB.1st_boot_pos=E8000.2nd_boot_pos=46F000.rec_boot_pos=20000.boot_from_image_no=1

# from /tmp/x_production
bootargs=noinitrd root=/dev/ram0 rw init=/linuxrc earlyprintk=serial console=ttyS0.bootcmd=bootm E8000.bootdelay=1.baudrate=115200.ethaddr=02:4e:ef:10:51:07.ipaddr=192.168.1.10.serverip=192.168.1.34.netmask=255.255.255.0.bootfile="vmlinuz".boot_from=flash.board_rev=RevB.1st_boot_pos=E8000.2nd_boot_pos=46F000.rec_boot_pos=20000.boot_from_image_no=1
```

### cr16boot bootloader configuration

The build-time configuration of the bootloader is done in the following
headers.

`src/dialog/cr16boot/include/configs/config_sc14452reef.h`
`src/dialog/cr16boot/include/configs/config_sc14452reef_32MB_service.h`

There are a couple noteworthy snippets here:

```cpp
// How to craft this ethernet frame?
// see src/dialog/cr16boot/common/unlock.c
// and src/dialog/cr16boot/net/net.c
#define CONFIG_SYSTEM_LOCK_DEF      "true"          ///< (true|false)default value. When "true", serial console is disabled. Can be unlocked by ethernet frame.

// how can we toggle these?
#define CONFIG_BOOT_FROM_IMAGE_NO       1                       ///< (env) which image should be booted first "1" or "2" or "R" (recovery)

//= feature: longpress button detection
#define CFG_BUTTON_DETECTION            1                       ///< (feat) (0|1) enable button driven behavior
#if (CFG_BUTTON_DETECTION)
/** (export) if defined CONFIG_FACTORY_RESET variable will be exported to linux environment but not stored in u-boot's env settings */
        #define CONFIG_FACTORY_RESET            "factory_reset"
        #define CFG_LONGPRESS_RESET                     (10*10) /// (feat) 10 seconds in 100ms ticks
        #define CFG_LONGPRESS_RECOVERY          (30*10) /// (feat) 30 seconds in 100ms ticks
        #define CFG_LONGPRESS_MAXIMUM_WAIT      (32*10) /// (feat) when button is pressed wait maximum 6 seconds
#endif
```

```sh
vim `rg --files-with-matches -i system_locked`
```

Here is a utility to [craft arbitrary ethernet frames](https://gist.github.com/lethean/5fb0f493a1968939f2f7).
I was not successful unlocking the system with a button press (while
connecting the power plug) and sending the packets in fast succession:

```sh
gcc -Wall -Wextra -Wpedantic -o sendRawEth -O2 sendRawEth.c
for i in seq 1 50 ; do ./sendRawEth; done
```

### Sniffing the traffic while using mitmproxy/mitmdump

I have a couple of pcap-ng dumps from

  * a "normal" boot sequence
  * a boot sequence with the button pressed while connecting the power plug
  * (TODO) a boot sequence while having `sendRawEth` running
  * (TODO) a boot sequence followed by all sensors firing
  * (TODO) with iptables `REDIRECT` to `mitmdump` active

From looking at the packets, I am pleasantly surprised to see the connection
being TLSv1.2-secured. After all, the CR16C isn't the most powerful CPU.
There appear to be client certificates in use, too. My hope is that once
I get my fingers on the client certificate (key pair) I can use
Wireshark to decrypt that TCP session - [see](https://packetpushers.net/blog/using-wireshark-to-decode-ssltls-packets/).

### Creating backups

* `src/init_rootfs/usr/bin/sysdump_create.sh`

### Available tools

* `ifplugd`, `ifup`, `ifdown`
* `inetc`
* `nc` (netcat client and server)
  - see `src/opensource/busybox/include/bbconfigopts.h`
* `sha256sum`
  - see `src/opensource/busybox/include/bbconfigopts.h`
* `telnetd`
* `tftp` (client only)
  - see `src/opensource/busybox/include/bbconfigopts.h`
* `udhcpc`
* `wget`
  - see `src/opensource/busybox/include/bbconfigopts.h`

For the full config see:

```sh
rg -v '^"#' src/opensource/busybox/include/bbconfigopts.h | less
```

### Attacking via recoveryfs

`src/init_recoveryfs/etc/start.sh` attempts to download `recovery.bin`
and `recoveryfs.bin` from `recovery.gigaset-elements.de`.

```sh
# WARNING: based on the example at https://osmocom.org/projects/misc-dect-hacks/wiki/Gigaset_Elements_Base
echo Reef BS version "'bas-001.000.026'" tagged at: "'unknown'" version status: "'NOT REPOSITORY VERSION'" >| /tmp/txt
BAS_TAG=`cat /tmp/txt | grep -w "Reef BS version" | cut -d \' -f 2`
curl --remote-name --get --header "User-Agent: Basestation/${BAS_TAG}" --verbose 'http://recovery.gigaset-elements.de/recoveryfs.bin'
curl --remote-name --get --header "User-Agent: Basestation/${BAS_TAG}" --verbose 'http://recovery.gigaset-elements.de/recovery.bin'
```

The idea here would be to use local DNS spoofing to make the system
download and flash a different recovery filesystem and kernel image that
suites our needs.

## Other projects and references

* [1](https://github.com/matthsc/gigaset-elements-api)
* [2](https://github.com/matthsc/ioBroker.gigaset-elements)
* [3](https://github.com/ycardon/gigaset-elements-proxy)
* [4](https://github.com/dynasticorpheus/gigasetelements-h)
* [5](https://static.digitecgalaxus.ch/Files/7/7/1/3/8/6/0/Gigaset_elements_alarm%20system%20M_1_DE_Datasheet.pdf)
* [6](https://osmocom.org/projects/misc-dect-hacks/wiki/Gigaset_Elements_Base)
* [7](https://community.home-assistant.io/t/gigaset-elements/222444/21)
* [8](https://stadt-bremerhaven.de/elektroschrott-gigaset-smart-home-care-wird-eingestellt/)
* [9](https://old.reddit.com/r/de_EDV/comments/1bnj2ww/gigaset_smart_home_elements_etc_wird_per_294/)
* [10](https://old.reddit.com/r/smarthome/comments/1bngnz1/gigaset_elements_insolvency_any_ideas_to_keep_the/)
* [11](https://raw.githubusercontent.com/bdarmofal/proc_manual/master/ghidra_manuals/prog16c.pdf)
* [bflt-utils](https://code.google.com/archive/p/bflt-utils/source/default/source)
* [GitHub clone of bflt-utils](https://github.com/nihilus/bflt-utils)
* [other auto-exports of bflt-utils from Google Code](https://github.com/search?q=bflt-utils&type=repositories)
* [GCC newer than v12 lacks support for CompactRISC](https://www.phoronix.com/news/GCC-Dropping-CompactRISC-CR16)
* [the patch landed as eb6358247a9386db2828450477d86064f213e0a8](https://gcc.gnu.org/pipermail/gcc-patches/2022-August/600296.html)
* [dropbear](http://matt.ucc.asn.au/dropbear/dropbear.html)
* [GitHub: dropbear](https://github.com/mkj/dropbear)
* [Gigaset Elements WebApp](https://app.gigaset-elements.com/#/unauthorized)
* [craft arbitrary ethernet frames](https://gist.github.com/lethean/5fb0f493a1968939f2f7)
* [alternative](https://gist.github.com/austinmarton/1922600)
* [blog](https://austinmarton.wordpress.com/2011/09/14/sending-raw-ethernet-packets-from-a-specific-interface-in-c-on-linux/)
* [... via](https://old.reddit.com/r/C_Programming/comments/gygbs6/how_to_send_raw_bits_over_an_ethernet_interface/)
* [Using Wireshark to Decode SSL/TLS Packets](https://packetpushers.net/blog/using-wireshark-to-decode-ssltls-packets/)
