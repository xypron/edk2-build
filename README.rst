EDK2 II build instructions for VS2019
=====================================

Prerequisites
-------------

* Install Visual Studio Community 2019
* Install NASM using
  https://www.nasm.us/pub/nasm/releasebuilds/2.15.05/win64/nasm-2.15.05-installer-x64.exe
  and set the NASM_PREFIX environment variable to point to the directory (with
  trailing backslash).
* Install GitSCM

Download Tianocore EDK II
-------------------------

.. code-block :: powershell

    cd C:\Users\%USERNAME%\workspace
    git clone https://github.com/tianocore/edk2.git
    cd edk2
    git reset --hard edk2-stable202008
    git submodule init

Adjust the brotli submodules to version v1.0.9

Build EFI Shell
---------------

Open VS2019 shell (from Start menu)

.. code-block :: powershell

    cd C:\Users\%USERNAME%\workspace\edk2-build
    copy target.txt edk2\Conf\ /Y
    cd edk2
    edksetup
    Build -p ShellPkg/ShellPkg.dsc

Build GenBin.exe
----------------

.. code-block :: powershell

    xcopy /S edk2-test\uefi-sct\SctPkg\Tools\Source\GenBin edk2\BaseTools\Source\C\GenBin
    cd edk2
    edksetup
    cd BaseTools\Source\C\GenBin\
    nmake

The generated executable is %EDK_TOOLS_BIN%\\GenBin.exe.

Build SCT
---------

As administrator create a symbolic link in edk2:

.. code-block :: powershell

    cd edk2
    mklink -D SctPkg ..\edk2-test\uefi-sct\SctPkg

As normal user:

.. code-block :: powershell

    cd edk2
    edksetup
    build -p SctPkg/UEFI/UEFI_SCT.dsc