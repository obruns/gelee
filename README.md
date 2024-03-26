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
