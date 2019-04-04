
NPROC=${shell nproc}

PWD:=${shell pwd}
export WORKSPACE:=$(PWD)/edk2/
export EDK_TOOLS_PATH=$(PWD)/edk2/BaseTools
export CONF_PATH=$(PWD)/edk2/Conf
export GCC5_AARCH64_PREFIX=aarch64-linux-gnu-
export PATH:=$(PWD)/edk2/BaseTools/BinWrappers/PosixLike/:$(PATH)
export TARGET_ARCH=AARCH64
export TARGET=RELEASE

all:
	make prepare
	make build

prepare:
	test -d edk2 || git clone -v \
	https://github.com/tianocore/edk2 edk2
	test -d edk2/BaseTools/Source/C/bin/ || \
	cd edk2 && bash -c '. edk2/edksetup.sh --reconfig'
	cp  target.txt edk2/Conf
	cd edk2/BaseTools/Source/C && make -j $(NPROC)

build:
	cd edk2 && BaseTools/BinWrappers/PosixLike/build -a AARCH64 \
	-p ShellPkg/ShellPkg.dsc || true
	find edk2/Build/ -name '*.efi'

clean:
	rm -rf edk2/Build	
