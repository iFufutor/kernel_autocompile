#!/bin/bash

DIRECTORY=/opt/kernel
CURRENT_VERSION=$(uname -r)
REVISION=$(date +%Y%m%d)
PROC=$(nproc)
RED="\033[1;31m"
GREEN="\033[1;32m"
DEFCOLOR="\033[0m"

if [[ $EUID -ne 0 ]]
	then
		echo -e "[${RED}FAIL${DEFCOLOR}]  This script must be run as root" 1>&2
		exit 1
fi

if [[ -z $1 ]]
	then
		echo -e "[${RED}FAIL${DEFCOLOR}]  Please specify kernel version as first argument.\n        Ex : ./kernel_compilation 4.9"
		exit 1
	else
		VERSION=$1
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

read -n1 -r -p "New packages will be installed on your system. Press any key to continue..."
echo ""
echo -e "Installing dependencies [...]"
apt-get -qq install -y git fakeroot build-essential ncurses-dev xz-utils libssl-dev bc && apt-get -qq --no-install-recommends install kernel-package
if [ $? -eq 0 ]
	then
		echo -e "        Installing dependencies        [${GREEN}OK${DEFCOLOR}]\n"
	else
		echo -e "        Installing dependencies        [${RED}FAIL${DEFCOLOR}]\n"
		exit 1
fi
mkdir -p $DIRECTORY &&  cd $DIRECTORY
if [ ! -d "linux-${VERSION}" ]
	then
		echo -e "Downloading sources [...]"
		wget -q https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-${VERSION}.tar.xz
		if [ $? -eq 0 ]
			then
				echo -e "        Downloading sources            [${GREEN}OK${DEFCOLOR}]\n"
			else
				echo -e "        Downloading sources            [${RED}FAIL${DEFCOLOR}]\n"
				exit 1
		fi
		echo -e "Uncompressing [...]"
		tar xf linux-${VERSION}.tar.xz > /var/log/kernel_compilation.log 2>&1
		if [ $? -eq 0 ]
			then
				echo -e "        Uncompressing                  [${GREEN}OK${DEFCOLOR}]\n"
			else
				echo -e "        Uncompressing                  [${RED}FAIL${DEFCOLOR}]\n"
				exit 1
		fi
		rm linux-${VERSION}.tar.xz
fi
cd $DIRECTORY/linux-${VERSION}
touch REPORTING-BUGS
echo -e "Do you want to use your default .config or generate a new one ? \n    1 : Use default .config \n    2 : Open menuconfig to generate a new one \n"
while true
do
	read -p "Choice [1-2] : " MENUCONFIG
	case $MENUCONFIG in
		[1] ) 	echo -e "${GREEN}OK ! ${DEFCOLOR}Using your old .config\n"
			cp /boot/config-$CURRENT_VERSION .config
			break;;
   		[2] ) 	echo -e "${GREEN}OK ! ${DEFCOLOR}Opening menuconfig\n"
			make -s menuconfig
			break;;
   		* )     echo -e "${RED}FAIL ! ${DEFCOLOR}Please make a choice between [1-2]"
			;;
  	esac
done
echo -e "Compiling [...] (may take a while...)"
make-kpkg clean >> /var/log/kernel_compilation.log 2>&1
fakeroot make-kpkg --initrd --revision=$REVISION kernel_image kernel_headers --jobs $PROC >> /var/log/kernel_compilation.log 2>&1
if [ $? -eq 0 ]
	then
		echo -e "        Compiling                      [${GREEN}OK${DEFCOLOR}]\n"
	else
		echo -e "        Compiling                      [${RED}FAIL${DEFCOLOR}]\n"
		exit 1
fi
echo -e "Do you want to install your just compiled kernel ?"
while true
do
    read -p "Choice [y-N] : " INSTALL
    case $INSTALL in
            [yY] )  echo -e "${GREEN}OK ! ${DEFCOLOR}Installing your kernel [...]"
                    cd $DIRECTORY
                    echo -e "Installing headers [...]"
                    dpkg -i linux-headers-${VERSION}_${REVISION}_amd64.deb >> /var/log/kernel_compilation.log 2>&1
                    if [ $? -eq 0 ]
						then
							echo -e "        Installing headers             [${GREEN}OK${DEFCOLOR}]\n"
						else
							echo -e "        Installing headers             [${RED}FAIL${DEFCOLOR}]\n"
							exit 1
					fi
					echo -e "Installing image [...]"
                    dpkg -i linux-image-${VERSION}_${REVISION}_amd64.deb >> /var/log/kernel_compilation.log 2>&1
                    if [ $? -eq 0 ]
						then
							echo -e "        Installing image               [${GREEN}OK${DEFCOLOR}]\n"
						else
							echo -e "        Installing image.              [${RED}FAIL${DEFCOLOR}]\n"
							exit 1
					fi
                    echo -e "${GREEN}Successfully installed${DEFCOLOR} your kernel. Please reboot."
                    break;;
            [nN] )  echo -e "Your files are in "$DIRECTORY" and can be installed by yourself."
                    break;;
            * )     echo -e "${RED}FAIL ! ${DEFCOLOR}]Please enter y or N"
                    ;;
    esac
done
