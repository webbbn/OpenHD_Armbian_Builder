#!/bin/bash

# arguments: $RELEASE $LINUXFAMILY $BOARD $BUILD_DESKTOP
#
# This is the image customization script

# NOTE: It is copied to /tmp directory inside the image
# and executed there inside chroot environment
# so don't reference any files that are not already installed

# NOTE: If you want to transfer files between chroot and host
# userpatches/overlay directory on host is bind-mounted to /tmp/overlay in chroot

RELEASE=$1
LINUXFAMILY=$2
BOARD=$3
BUILD_DESKTOP=$4

Main() {
    echo "RELEASE=${RELEASE}"

    # Copy the overlay files onto the image
    cp -a /tmp/overlay/etc /tmp/overlay/lib /

    # Install the wifibroadcast_bridge package
    wget -O wfb.zip https://github.com/webbbn/wifibroadcast_bridge/suites/363867671/artifacts/741234
    unzip wfb.zip
    if [ ${BOARD} == "nanopineo4" ]; then
	dpkg -i deb-files/buster-arm64/*.deb
    else
	dpkg -i deb-files/buster-armhf/*.deb
    fi
    rm -rf wfb.zip deb-files

    # Install the Open.HD-NG package
    wget -O openhd.zip https://github.com/webbbn/Open.HD-NG/suites/363868282/artifacts/741238
    unzip openhd.zip
    if [ ${BOARD} == "nanopineo4" ]; then
	dpkg -i deb-files/buster-arm64/*.deb
    else
	dpkg -i deb-files/buster-armhf/*.deb
    fi
    rm -rf openhd.zip deb-files

    if [ ${BOARD} == "nanopiduo2" ]; then
	# The UART on the nanopi duo2 is on /dev/ttyS1
	sed -i 's/ttyS0/ttyS1/' /etc/default/openhd
    fi

    # Enable the services
    systemctl enable wifi_config
    systemctl enable wfb_bridge
    systemctl enable openhd

    # Install pymavlink and pyric
    pip3 install pymavlink
    pip3 install pyric

    # Remove NetworkManager, which causes issues with monitor mode
    apt-get purge -y network-manager
    apt-get autoremove -y

    # Copy the overlay directory to root
    cp -a /tmp/root/* /

    # Enable g_ether on the Orange Pi Zero Plus2, which doesn't have ethernet
    if [ ${BOARD} == "orangepizeroplus2-h3" ]; then
	echo >> /etc/network/interfaces <<EOF
auto lo
iface lo inet loopback

auto usb0
iface usb0 inet static
    address 192.168.137.2
    netmask 255.255.255.0
    network 192.168.137.0
    broadcast 192.168.137.255
    gateway 192.168.137.1
EOF
	sed -i 's/g_serial/g_ether/' /etc/modules
	cat "nameserver 192.168.1.1" > /etc/resolv.conf
    else
	# Add the ethernet interface configuration
	printf "auto eth0\niface eth0 inet dhcp\n" >> /etc/network/interfaces
    fi

    # Enable the second UARTS on the nanopi duo2
    if [ ${BOARD} == "nanopiduo2" ]; then
	sed -i '/overlays/ s/$/ uart1 uart2/' /boot/armbianEnv.txt
    fi

    # Change the hostname on the nanopi duo2
    sed -i 's/${BOARD}/openhd-ng/g' /etc/hostname
    sed -i 's/${BOARD}/openhd-ng/g' /etc/hosts

    # Install the patches to the wifi regulations database
    patch_regdb
    
} # Main


patch_regdb() {
    (
	cd /tmp

	# Download the source tarballs
	wget https://git.kernel.org/pub/scm/linux/kernel/git/sforshee/wireless-regdb.git/snapshot/wireless-regdb-master-2019-06-03.tar.gz
	wget https://git.kernel.org/pub/scm/linux/kernel/git/mcgrof/crda.git/snapshot/crda-4.14.tar.gz

	# Untar them
	tar xfv crda-4.14.tar.gz
	tar xfv wireless-regdb-master-2019-06-03.tar.gz

	# Build the wireless-regdb package
	(
	    cd wireless-regdb-master-2019-06-03
	    cp /tmp/overlay/db.txt .
	    make DISTRO_PRIVKEY=wireless-distro.key.priv.pem DISTRO_PUBKEY=wireless-distro.key.priv.pem REGDB_PRIVKEY=wireless-regdb.key.priv.pem
	    cp regulatory.db regulatory.db.p7s /lib/firmware/
	    cp regulatory.bin /lib/crda/
	    cp *.pub.pem ../crda-4.14/pubkeys
	    cp /lib/crda/pubkeys/*@*pub.pem ../crda-4.14/pubkeys/
	)

	# Build the crda package
	(
	    cd crda-4.14/
	    make REG_BIN=/lib/crda/regulatory.bin 
	    make REG_BIN=/lib/crda/regulatory.bin install
	)
    )
}

Main "$@"
