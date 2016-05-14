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

https://github.com/emergingstack/es-dev-stack shows that above idea
works.  The problem with the `es-dev-stack` tool is that it requires
large amount of disk space for building the Docker image, for
downloading full git repo of Linux source code, and for downloading
and unpacking CUDA toolkit.  Actually, even the disk space of an AWS
EC2 g2.8xlarge instance is not enough to build and run such a Docker
image.

A straight-forward solution would be mounting additional external
virtual storage to our EC2 instance.  But a much cheaper alternative
is to build CUDA driver in a virtual machine on my iMac.

My iMac doesn't run CoreOS, so I need to run a virtual machine with
CoreOS.  A practical and convenient way to this is to use the standard
Vagrant CoreOS box.  But this box doesn't have extraordinarily large
disk space.  So I save CUDA toolkit and Linux kernel source code on
host disk and map host directory to the VM.

Other approaches for saving disk space include:

1. checking out only the most recent git commit of Linux kernel source
   code, and
1. avoding building a Docker image for building the CUDA driver as
   https://github.com/emergingstack/es-dev-stack does.

1. Run `git clone` to grab this repo to the host computer.
1. Run `run.sh`, which
  1. downloads and unpacks CUDA Toolkit into `./cuda` (on host),
  1. remove `./linux` if there has been one,
  1. executes `vagrant box update` to retrieve the most recent version of CoreOS alpha channel box,
  1. executes `vagrant up` to bring the CoreOS VM up and mounts the current host directory to VM's `/home/core/share` via NFS,
  1. executes `vagrant ssh -c "docker run --rm -v /home/core/share:/opt/share --privileged ubuntu:14.04 /bin/bash /opt/share/build.sh"` to build CUDA kernel modules.

Note that as specified in Vagrantfile, we mount `./` of the host to
`/home/core/share` on the VM at via NFS.  So that any change to the
directory by either the host or the VM is transparent to each other.

Also, as specified in the above `docker run -v` command, we map
`/home/core/share` on the VM to `/opt/share` in the Docker container.

Please be aware that the Docker container gets the Linux kernel
version using `uname` in `build.sh`, and grabs Linux kernel source
code that matches the CoreOS kernel version running in the VM.  If you
want to use another channel of CoreOS, say stable or beta, please edit
Vagrantfile to use the corresponding Vagrant CoreOS box.

The checked out Linux kernel source code is put in `/opt/share/linux`.
You will notice `./linux` on the host.

## Pitfalls

To run an application container of GPU-dependent applications, we need
the `--privilege` option with `docker run`.  Otherwise it might cause
confusions as I documented
[here](https://github.com/emergingstack/es-dev-stack/issues/15).
