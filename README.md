# LLVM-Build-Windows 

This is a helpful batch script to automate building the LLVM toolchain on Windows using Clang itself!

Credits to MSYS project and [Matthew Oliver](https://github.com/Sibras)

## Usage

1. Open a command prompt (cmd.exe) and change directory to the root of where you want the root of your LLVM directory tree.

        >cd C:\llvm-7.0.0

2. Place the build scripts at the root of the LLVM directory tree.
    
        >git clone https://github.com/dude719/LLVM-Build-Windows .
    
3. See here on how to obtain the LLVM source code for building:

    https://llvm.org/docs/GettingStarted.html#getting-started-quickly-a-summary
    
4. Use the `-help` argument for the script for more information:

        >build-llvm.bat -help
        Detected 64 bit system...
        Usage:
            build-llvm.bat [options]

        Options:
            -configure                   Configure the project
            -build                       Build the project
            -static                      Configure and build the project statically
            -debug                       Build project with debug configuration
            -target ARCH                 Set the target architecture
            -directory DIRECTORY         Use specified DIRECTORY for build directory
            -help | --help | -? | /?     Display this help and exit

4. Run the build script for the target of your choice:

x64

    >build-llvm.bat -configure -build -static -target x64 -directory build-release-x64
    
x86

    >build-llvm.bat -configure -build -static -target x86 -directory build-release-x86
