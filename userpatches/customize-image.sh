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

    # Copy the overlay files onto the image
    cp -a /tmp/overlay/etc /tmp/overlay/lib /

    # Install from the PPA
    if [ ${BOARD} == "nanopiduo2" ]; then
	wget -O wfb.zip https://github.com/webbbn/wifibroadcast_bridge/suites/335754305/artifacts/497812
	unzip wfb.zip
	dpkg -i deb-file/*armhf.deb
	rm -rf wfb.zip deb-file
	wget -O openhd.zip https://github.com/webbbn/Open.HD-NG/suites/335768460/artifacts/498042
	unzip openhd.zip
	dpkg -i deb-file/*armhf.deb
	rm -rf openhd.zip deb-file
    fi

    # Enable the services
    systemctl enable wifi_config
    systemctl enable wfb_bridge
    systemctl enable openhd

    # Install the pyric python package
    mkdir -p /usr/local/lib/python3.6/dist-packages
    (
	cd /usr/local/lib/python3.6/dist-packages
	tar xvf /tmp/overlay/pyric.tar.gz
    )

    # Install pymavlink
    pip3 install pymavlink

    # Remove NetworkManager, which causes issues with monitor mode
    apt-get purge -y network-manager
    apt-get autoremove -y

    # Enable g_ether on the Orange Pi Zero Plus2, which doesn't have ethernet
    if [ ${BOARD} == "orangepizeroplus2-h3" ]; then
	cp /tmp/overlay/network_interfaces /etc/network/interfaces
	sed -i 's/g_serial/g_ether/' /etc/modules
	cp /tmp/overlay/resolv.conf /etc
    else
	# Add the ethernet interface configuration
	printf "auto eth0\niface eth0 inet dhcp\n" >> /etc/network/interfaces
    fi

    # Enable the second UART on the nanopi duo2
    if [ ${BOARD} == "nanopiduo2" ]; then
	sed -i '/overlays/ s/$/ uart2/' /boot/armbianEnv.txt
    fi

    # Change the hostname on the nanopi duo2
    if [ ${BOARD} == "nanopiduo2" ]; then
	sed -i 's/nanopiduo2/openhd-ng-air/g' /etc/hostname
	sed -i 's/nanopiduo2/openhd-ng-air/g' /etc/hosts
    fi

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
