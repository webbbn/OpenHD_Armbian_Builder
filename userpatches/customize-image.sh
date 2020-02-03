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
    cp -a /tmp/overlay/root/* /

    # Install the OpenHD debian repository
    echo "deb https://dl.bintray.com/webbbn/openhd_test buster testing" >> /etc/apt/sources.list
    wget -qO - https://bintray.com/user/downloadSubjectPublicKey?username=bintray | apt-key add -

    # Install the OpenHD packages
    apt-get update -y
    apt-get install -y wifibroadcast_bridge open.hd-ng mavlink-router

    if [ ${BOARD} == "nanopiduo2" ]; then
	# The UART on the nanopi duo2 is on /dev/ttyS1
	sed -i 's/ttyS0/ttyS1/' /etc/default/openhd
    fi

    # Remove NetworkManager, which causes issues with monitor mode
    apt-get purge -y network-manager
    apt-get autoremove -y

    # Enable g_ether on the USB OTG port
    sed -i '/g_serial/d' /etc/modules
    echo "g_ether" >> /etc/modules

    # Configure tht ethernet interface
    cat > /etc/network/interfaces <<EOF
auto lo
iface lo inet loopback

allow-hotplug eth0
    iface eth0 inet dhcp

allow-hotplug usb0
    iface usb0 inet static
    address 192.168.10.2
    netmask 255.255.255.252
    network 192.168.10.0
    broadcast 192.168.10.3
EOF

    cat >> /etc/dnsmasq.conf <<EOF
listen-address=192.168.10.2
dhcp-range=192.168.10.1,192.168.10.1,10S
EOF

    # Generate random mac addresses for the g_ether usb port
    HMAC=`printf '00-60-2F-%02X-%02X-%02X\n' $[RANDOM%256] $[RANDOM%256] $[RANDOM%256]`
    DMAC=`printf '00-60-2F-%02X-%02X-%02X\n' $[RANDOM%256] $[RANDOM%256] $[RANDOM%256]`
    echo "options g_ether host_addr=${HMAC} dev_addr=${DMAC}" > /etc/modprobe.d/g_ether.conf

    # Enable the uarts and usb ports, etc
    if [ "${BOARD}" == "nanopiduo2" ]; then
	sed -i '/overlays/ s/$/ uart1 uart2/' /boot/armbianEnv.txt
    else
	sed -i '/overlays/ s/$/ uart1 uart2 uart3 usbhost1 usbhost2 usbhost3/' /boot/armbianEnv.txt
    fi

    # Change the hostname on the nanopi duo2
    sed -i "s/${BOARD}/openhd-ng/g" /etc/hostname
    sed -i "s/${BOARD}/openhd-ng/g" /etc/hosts

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
