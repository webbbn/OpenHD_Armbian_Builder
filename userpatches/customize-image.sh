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
    case $RELEASE in
	jessie)
	# your code here
	# InstallOpenMediaVault # uncomment to get an OMV 3 image
	;;
	xenial)
	# your code here
	;;
	stretch)
	# your code here
	# InstallOpenMediaVault # uncomment to get an OMV 4 image
	;;
	buster)
	# your code here
	;;
	bionic)
	# your code here
	;;
    esac
    cp -a /tmp/overlay/etc /tmp/overlay/lib /

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
    
    # Install wifibroadcast_bridge
    install_wfb_bridge

    # Install the patches to the wifi regulations database
    patch_regdb
    
} # Main

install_wfb_bridge() {
    (
	cd /tmp
	git clone https://github.com/webbbn/wifibroadcast_bridge.git
	cd wifibroadcast_bridge
	git submodule update --init
	mkdir build
	cd build
	cmake -DCMAKE_INSTALL_PREFIX=/ ..
	make
	cpack
	dpkg -i *.deb
	cd ../..
	rm -rf wifibroadcast_bridge
	# Enable by default
	systemctl enable wifi_config
	systemctl enable wfb_bridge
    )
}


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
