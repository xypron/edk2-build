# Build EDK2 for MACCHIATObin
.POSIX:

TAG=uefi-2.7-armada-18.09
TAGPREFIX=
REVISION=001

NPROC=${shell nproc}

UID="${shell id -u $(USER)}"
MK_ARCH="${shell uname -m}"
ifeq ("aarch64", $(MK_ARCH))
	undefine CROSS_COMPILE
else
	export CROSS_COMPILE=aarch64-linux-gnu-
endif
undefine MK_ARCH

export DEVICE_TREE=armada-8040-mcbin
export BL33=$(CURDIR)/uefi-marvell/Build/Armada80x0McBin-AARCH64/RELEASE_GCC5/FV/ARMADA_EFI.fd
export SCP_BL2=$(CURDIR)/binaries-marvell/mrvl_scp_bl2_mss_ap_cp1_a8040.img

all:

prepare:
	test -d uefi-marvell || git clone -v \
	https://github.com/MarvellEmbeddedProcessors/uefi-marvell

atf:
	cd patch && (git fetch origin || true)
	cd patch && (git checkout efi-next)
	cd patch && git rebase
	cd binaries-marvell && git fetch
	true
	cd binaries-marvell && git checkout binaries-marvell-armada-18.06
	cd binaries-marvell && \
	git reset --hard origin/binaries-marvell-armada-18.06
	cd mv-ddr && git fetch
	cd mv-ddr && git checkout mv_ddr-armada-18.09
	cd mv-ddr && git reset --hard origin/mv_ddr-armada-18.09
	test ! -f patch/patch-mv_ddr-armada-18.09 || \
	(cd mv-ddr && ../patch/patch-mv_ddr-armada-18.09)
	cd atf-marvell && git fetch
	cd atf-marvell && git checkout atf-v1.5-armada-18.09
	cd atf-marvell && git reset --hard origin/atf-v1.5-armada-18.09
	cd atf-marvell && make USE_COHERENT_MEM=0 LOG_LEVEL=20 \
	MV_DDR_PATH=../mv-ddr PLAT=a80x0_mcbin all fip

clean:

install:
	mkdir -p $(DESTDIR)/usr/lib/u-boot/macchiatobin/
	cp atf-marvell/build/a80x0_mcbin/release/flash-image.bin \
	$(DESTDIR)/usr/lib/u-boot/macchiatobin/
	cp sd_fusing.sh $(DESTDIR)/usr/lib/u-boot/macchiatobin/

uninstall:
