# Building and Using CUDA Drivers in Docker Containers

## Goal

In order to run an artificial intelligence based business, we need a
general-purpose computing cluster.  A highly efficient prototype is
described [here](https://github.com/wangkuiyi/k8s-ml), which makes use
of Kubernetes to run jobs in Docker containers.  An ideal platform to
run Kubernetes is CoreOS.  However, CoreOS doesn't include CUDA GPU
driver in its kernel.  In order to use GPUs for accelerated deep
learning, we want to build CUDA GPU driver as kernel modules and to
load them in Docker images together with Tensorflow, Torch and other
programs that relies on CUDA GPU drivers.  At runtime, we load CUDA
driver kernel modules from within Docker containers.

## Solution

https://github.com/emergingstack/es-dev-stack shows that
above idea works.  The problem with the `es-dev-stack` tool is that
the provided Dockerfile builds too big CUDA Docker images.  Actually,
the disk space of an AWS EC2 g2.8xlarge instance doesn't support build
and run such images.

So I use a two-phase approach: build a Docker image which build CUDA
kernel drivers at runtime, and build application images that loads
CUDA drivers and GPU applications.  This repo focuses on the first
phase.

## Build

The primary challenge is that the building process needs CUDA Toolkit
and Linux kernel source code, both take huge amount of disk space.  My
solution is to use the disk space of the host computer (my iMac 5K) as
much as possible.

My iMac doesn't run CoreOS, so I need to run a virtual machine with
CoreOS.  A practical and convenient way to this is to use the standard
Vagrant CoreOS box.  Here is what I do:

1. Run `git clone` to get this repo on the host computer.
1. Run `run.sh`, which
  1. downloads and unpacks CUDA Toolkit into `./cuda` (on host),
  1. executes `vagrant box update` to retrieve the most recent version of CoreOS alpha channel box,
  1. executes `vagrant up` to bring the CoreOS VM up and mounts the current host directory to VM's `/home/core/share`,
  1. executes `vagrant ssh -c "docker build -t cuda /home/core/share"` to build the CUDA builder Docker image on VM,
  1. executes `vagrant ssh -c "docker run -v /home/core/share:/opt/share cuda"` to run the CUDA builder image and builds CUDA modules.

Note that the current directory `./` of the host is mount to the VM at
`/home/core/share`.  As specified in Vagrantfile, this mount is via
NFS, so that any changes of `./` of the host of `/home/core/share` on
the VM is transparent to each other.

`/home/core/share` on the VM is then mapped to `/opt/share` when we
run the builder Docker container.

The builder Docker container checks out the version of Linux kernel
source code that matches the CoreOS kernel running in the VM.  If you
want to use another channels of CoreOS, say stable or beta, please
edit Vagrantfile to use the according Vagrant box.

The checked out Linux kernel source code is put in `/opt/share/linux`.
You will notice `./linux` on the host.

## Pitfalls

To run an application container of GPU-dependent applications, we need
the `--privilege` option with `docker run`.  Otherwise it might causes
confusions as I documented
[here](https://github.com/emergingstack/es-dev-stack/issues/15).
