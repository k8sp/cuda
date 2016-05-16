#/bin/bash

echo Hello!  We are building CUDA driver for your Linux kernel ...

source ./install-gcc49.sh

# clone Linux kernel source code and prepare for kernel module building.
cd /opt/share
git clone -b v`uname -r | sed -e "s/-.*//" | sed -e "s/\.[0]*$//"` --depth 1 git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git linux
(
    cd linux
    git checkout -b stable
    zcat /proc/config.gz > .config
    make modules_prepare
    sed -i -e "s/`uname -r | sed -e "s/-.*//" | sed -e "s/\.[0]*$//"`/`uname -r`/" include/generated/utsrelease.h # In case a '+' was added
)

# patch CUDA driver code.
patch /opt/share/cuda/NVIDIA-Linux-x86_64-352.39/kernel/nv-procfs.c < /opt/share/nvprocfs.patch

# build CUDA kernel module
/opt/share/cuda/NVIDIA-Linux-x86_64-352.39/nvidia-installer -q -a -n -s --kernel-source-path=/opt/share/linux/
cp /opt/share/cuda/NVIDIA-Linux-x86_64-352.39/kernel/uvm/nvidia-uvm.ko /opt/share/cuda/
cp /opt/share/cuda/NVIDIA-Linux-x86_64-352.39/kernel/nvidia.ko /opt/share/cuda/
