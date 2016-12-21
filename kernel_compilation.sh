#!/bin/bash

DIRECTORY=/opt/kernel
CURRENT_VERSION=$(uname -r)
REVISION=$(date +%Y%m%d)
PROC=$(nproc)
SPIN='-\|/'


if [[ -z $1 ]]
	then
		echo -e "Please specify kernel version as first argument.\nEx : ./kernel_compilation 4.9"
		exit 1
	else
		VERSION=$1
fi

if [[ $EUID -ne 0 ]]
	then
		echo "This script must be run as root" 1>&2
		exit 1
fi
clear
cat << "EOF"
  _  __                    _
 | |/ /___ _ __ _ __   ___| |
 | ' // _ \ '__| '_ \ / _ \ |
 | . \  __/ |  | | | |  __/ |
 |_|\_\___|_|  |_| |_|\___|_|_ _       _   _
  / ___|___  _ __ ___  _ __ (_) | __ _| |_(_) ___  _ __
 | |   / _ \| '_ ` _ \| '_ \| | |/ _` | __| |/ _ \| '_ \
 | |__| (_) | | | | | | |_) | | | (_| | |_| | (_) | | | |
  \____\___/|_| |_| |_| .__/|_|_|\__,_|\__|_|\___/|_| |_|
                      |_|                    by iFufutor.


EOF
echo "Installing dependencies..."
apt-get -qq install -y git fakeroot build-essential ncurses-dev xz-utils libssl-dev bc
apt-get -qq --no-install-recommends install kernel-package
mkdir -p $DIRECTORY &&  cd $DIRECTORY
if [ ! -d "linux-${VERSION}" ]
	then
		echo "Downloading sources..."
		wget -q https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-${VERSION}.tar.xz
		echo "Uncompressing..."
		tar xf linux-${VERSION}.tar.xz 2>/dev/null &
		PID=$!
		i=0
		while kill -0 $PID 2>/dev/null
		do
  			i=$(( (i+1) %4 ))
  			printf "\r${SPIN:$i:1}"
  			sleep .1
		done
		echo -e "\n"
		rm linux-${VERSION}.tar.xz
fi
cd linux-${VERSION}
echo -e "Do you want to use your default .config or generate a new one ? \n    1 : Use default .config \n    2 : Open menuconfig to generate a new one \n    3 : Download an optimized config file"
while true
do
	read -p "Choice [1-2] : " MENUCONFIG
	case $MENUCONFIG in
		[1] ) 	echo "OK ! Using your old .config"
			cp /boot/config-$CURRENT_VERSION .config
			break;;
   		[2] ) 	make -s menuconfig
			break;;
   		* )     echo "Please make a choice between [1-2]"
			;;
  	esac
done
make-kpkg clean
fakeroot make-kpkg --initrd --revision=$REVISION kernel_image kernel_headers --jobs $PROC
echo "Do you want to install your just compiled kernel ?"
while true
do
        read -p "Choice [y-N] : " INSTALL
        case $INSTALL in
                [yY] )  echo "OK ! Installing your kernel"
                        cd $DIRECTORY
                        dpkg -i linux-headers-${VERSION}_${REVISION}_amd64.deb 2>/dev/null &
						PID=$!
						i=0
						while kill -0 $PID 2>/dev/null
						do
  							i=$(( (i+1) %4 ))
  							printf "\r${SPIN:$i:1}"
  							sleep .1
						done
						echo -e "\n"
                        dpkg -i linux-image-${VERSION}_${REVISION}_amd64.deb 2>/dev/null &
						PID=$!
						i=0
						while kill -0 $PID 2>/dev/null
						do
  							i=$(( (i+1) %4 ))
  							printf "\r${SPIN:$i:1}"
  							sleep .1
						done
						echo -e "\n"
                        echo "Successfully installed your kernel. Please reboot."
                        break;;
                [nN] )  echo "Your files are in "$DIRECTORY" and can be installed by yourself."
                        break;;
                * )     echo "Please enter y or N"
                        ;;
        esac
done
