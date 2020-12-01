FROM ubuntu:xenial-20201030
MAINTAINER Heinrich Schuchardt <xypron.glpk@gmx.de>
LABEL Description="Build UEFI SCT for RISCV64"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update

RUN apt-get install -y \
	bc \
	bison \
	build-essential \
	coccinelle \
    	device-tree-compiler \
	dfu-util \
	efitools \
	flex \
	git \
	gdisk \
	liblz4-tool \
	libguestfs-tools \
	libncurses-dev \
  	libpython3-dev \
	libsdl2-dev \
	libssl-dev \
	linux-image-generic \
	lzma-alone \
	openssl \
	python3 \
  	python3-coverage \
	python3-pyelftools \
	python3-pytest \
	srecord \
	sudo \
	swig \
	u-boot-tools \
	uuid-dev \
	wget

WORKDIR /tmp

RUN wget -O gcc-riscv-9.2.0-2020.02-x86_64_riscv64-unknown-gnu.tar.xz -- \
	https://github.com/riscv/riscv-uefi-edk2-docs/blob/master/gcc-riscv-edk2-ci-toolchain/gcc-riscv-9.2.0-2020.02-x86_64_riscv64-unknown-gnu.tar.xz?raw=true
RUN tar -xjf gcc-riscv-9.2.0-2020.02-x86_64_riscv64-unknown-gnu.tar.xz
RUN cp /tmp/gcc-riscv-9.2.0-2020.02-x86_64_riscv64-unknown-gnu/* /usr/ -r
RUN rm /tmp/* -rf

RUN adduser user --quiet
RUN adduser user sudo
WORKDIR /home/user
USER user

RUN echo v1
RUN git clone https://github.com/xypron/edk2-build.git -b qemu-riscv64

WORKDIR /home/user/edk2-build

RUN export GCC5_RISCV64_PREFIX=riscv64-unknown-elf-
RUN make prepare
RUN GCC5_RISCV64_PREFIX=riscv64-unknown-elf- make build-shell
RUN GCC5_RISCV64_PREFIX=riscv64-unknown-elf- make build-sct

USER root

RUN make sct-image

WORKDIR /home/user

