# Build EDK2 for MACCHIATObin
.POSIX:

TAG=uefi-2.7-armada-18.09
TAGPREFIX=
REVISION=001

SHELL:=/bin/bash
NPROC=${shell nproc}

UID="${shell id -u $(USER)}"
MK_ARCH="${shell uname -m}"
ifeq ("aarch64", $(MK_ARCH))
	undefine CROSS_COMPILE
else
	export CROSS_COMPILE=aarch64-linux-gnu-
endif
undefine MK_ARCH

export WORKSPACE:=$(CURDIR)
export EDK_TOOLS_PATH=$(CURDIR)/edk2/BaseTools
export CONF_PATH=$(CURDIR)/edk2/Conf
export GCC5_AARCH64_PREFIX=aarch64-linux-gnu-
export PACKAGES_PATH=$(CURDIR)/edk2:$(CURDIR)/edk2-platforms:$(CURDIR)/edk2-non-osi
export PATH:=$(CURDIR)/edk2/BaseTools/BinWrappers/PosixLike/:$(PATH)

export BL33=$(CURDIR)/Build/Armada80x0McBin-AARCH64/RELEASE_GCC5/FV/ARMADA_EFI.fd
export SCP_BL2=$(CURDIR)/binaries-marvell/mrvl_scp_bl2.img

all:
	make prepare
	make build
	make atf

prepare:
	mkdir -p patch
	test -d edk2 || git clone -v \
	https://github.com/tianocore/edk2 edk2
	cd edk2 && git submodule update --init
	test -d edk2-platforms || git clone -v \
	https://github.com/tianocore/edk2-platforms edk2-platforms
	test -d edk2-non-osi || git clone -v \
	https://github.com/tianocore/edk2-non-ose edk2-non-osi
	test -d edk2/BaseTools/Source/C/bin/ || \
	(cd edk2 && pwd && bash -c '. edksetup.sh --reconfig')
	cp target.txt edk2/Conf
	cd edk2/BaseTools/Source/C && make -j $(NPROC)
	test -d binaries-marvell || \
	git clone https://github.com/MarvellEmbeddedProcessors/binaries-marvell
	test -d mv-ddr || git clone \
	https://github.com/MarvellEmbeddedProcessors/mv-ddr-marvell.git mv-ddr
	test -d trusted-firmware-a || \
	git clone https://git.trustedfirmware.org/TF-A/trusted-firmware-a.git
	test -f ~/.gitconfig || \
	  ( git config --global user.email "somebody@example.com"  && \
	  git config --global user.name "somebody" )

build:
	cd edk2-platforms && (git fetch || true)
	cd edk2-platforms && (git am --abort || true)
	cd edk2-platforms && (git reset --hard origin/master)
	test ! -f patch/patch-edk2-platforms || \
	(cd edk2-platforms && ../patch/patch-edk2-platforms)
	cd edk2 && make -C BaseTools -j${NPROC}
	cd edk2 && source edksetup.sh
	cd edk2 && build -a AARCH64 -t GCC5 -b RELEASE \
	-D INCLUDE_TFTP_COMMAND -D X64EMU_ENABLE=TRUE \
	-p edk2-platforms/Platform/SolidRun/Armada80x0McBin/Armada80x0McBin.dsc

atf:
	cd binaries-marvell && git fetch
	true
	cd binaries-marvell && git checkout binaries-marvell-armada-18.12
	cd binaries-marvell && \
	git reset --hard origin/binaries-marvell-armada-18.12
	cd mv-ddr && git fetch
	cd mv-ddr && git checkout mv_ddr-armada-atf-mainline
	cd mv-ddr && git reset --hard origin/mv_ddr-armada-atf-mainline
	test ! -f patch/patch-mv_ddr-armada-atf-mainline || \
	(cd mv-ddr && ../patch/patch-mv_ddr-armada-atf-mainline)
	cd trusted-firmware-a && git fetch
	cd trusted-firmware-a && git checkout v2.2
	cd trusted-firmware-a && git reset --hard v2.2
	cd trusted-firmware-a && make USE_COHERENT_MEM=0 LOG_LEVEL=20 \
	MV_DDR_PATH=../mv-ddr PLAT=a80x0_mcbin all fip

install:
	mkdir -p $(DESTDIR)/usr/lib/u-boot/macchiatobin/
	cp trusted-firmware-a/build/a80x0_mcbin/release/flash-image.bin \
	$(DESTDIR)/usr/lib/u-boot/macchiatobin/
	cp sd_fusing.sh $(DESTDIR)/usr/lib/u-boot/macchiatobin/

clean:

uninstall:
