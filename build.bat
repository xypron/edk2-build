set WORKSPACE=C:\Users\%USERNAME%\workspace\edk2-build\edk2
set EDK_TOOLS_PATH=C:\Users\%USERNAME%\workspace\edk2-build\edk2\BaseTools
set BASE_TOOLS_PATH=C:\Users\%USERNAME%\workspace\edk2-build\edk2\BaseTools
set EDK_TOOLS_BIN=C:\Users\%USERNAME%\workspace\edk2-build\edk2\BaseTools\Bin\Win32
set CONF_PATH=C:\Users\%USERNAME%\workspace\edk2-build\edk2\Conf
set NASM_PREFIX=C:\Users\%USERNAME%\AppData\Local\bin\NASM

copy target.txt edk2\Conf\target.txt

cd edk2
edksetup.bat
build -p ShellPkg\ShellPkg.dsc -a X64
build -p SctPkg\UEFI\UEFI_SCT.dsc -a X64