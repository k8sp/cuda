# Building and Using CUDA Drivers in Docker Containers

## Goal

In order to run an artificial intelligence based business, we need a
general-purpose computing cluster.  A highly efficient prototype is
described [here](https://github.com/wangkuiyi/k8s-ml), which makes use
of Kubernetes to run jobs in Docker containers.  An ideal platform to
run Kubernetes is CoreOS.  However, CoreOS doesn't include CUDA GPU
driver in its kernel.  In order to use GPUs for accelerated deep
learning, we build CUDA GPU driver as kernel modules, and load them in
Docker images of Tensorflow, Torch and other programs that relies on
CUDA GPU drivers.  At runtime, we load CUDA driver kernel modules from
within Docker containers.

## Solution

Thanks https://github.com/emergingstack/es-dev-stack, which shows that
above idea works.  The problem with the `es-dev-stack` tool is that
the provided Dockerfile builds too big CUDA Docker images.  Actually,
the disk space of an AWS EC2 g2.8xlarge instance doesn't support build
and run such images.  Our solution is a two-phase approach:

1. The `builder` image downloads necessary Linux kernel and CUDA Toolkit
   and build CUDA drivers as kernel modules.  `builder` can run on a
   VirtualBox VM with enough big disk spaces.  The host of the VM
   doesn't need to have CUDA GPU.  `builder` is derived from
   `ubuntu:14.04` image.  `builder` writes two kernel modules files:

 1. `nvidia.ko`
 1. `nvidia-uvm.ko`

1. Some `cuda` images, each based on Tensorflow image or Torch image,
   as well as the two kernel modules.  The Dockerfile runs command
   like `insmod /opt/nvidia.ko && insmod /opt/nvidia-uvm.so` to load
   kernel modules before starting programs that rely on GPU.  These
   `cuda` images are supposed to run on computers with Docker and GPU.


## The `Builder` Image

I followed
[this tutorial](https://gist.github.com/noonat/9fc170ea0c6ddea69c58)
and successfully installed CoreOS into disks of a VirtualBox VM.  The
general idea is that I boot the VM using a CoreOS ISO image, and run a
script `coreos-install` in that image to install CoreOS into the
specified disk, say `/dev/sda`.  The script requires a config file,
which should contain at least a user's SSH public key, so that the
user can ssh to the CoreOS VM later.  I put this config file into my
Github repo, and CoreOS has basic network tools like curl, which can
be used to download the config file for use by `coreos-install`.

I tried to follow https://github.com/emergingstack/es-dev-stack/ to
build a Docker image of CUDA kernel module.  It builds.  But when I
run the built docker image, it complains that the system doesn't have
CUDA GPU. (Yes, it is a VM that doesn't have any GPU).

## CoreOS on AWS EC2

It is true that we can create CoreOS instances as explained in
[this post](http://tleyden.github.io/blog/2014/11/04/coreos-with-nvidia-cuda-gpu-drivers/),
but I cannot find a way to ssh to the instance.  So I resorted to
CloudFoundation to create a CoreOS cluster with at least 3 instances.
CoreOS's tutorial lacks details, reasons, explanations.  Luckily, I
found [this tutorial](https://deis.com/blog/2016/coreos-on-aws/).

### Too Big Docker Image to Build

It is notable that the Dockerfile will run out of disk space on either
`g2.x2large` nodes or `g2.8xlarge` nodes.  So I tried to git clone
only the most recent commit of the wanted branch of Linux kernel code:

1. `git clone git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git linux` gives 1.8GB.
1. Then I removed the `.git` subdirectory. It leaves 715MB.
1. `git clone -b v4.4.8 --depth 1 git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git linux` gives 850MB
1. Then I removed the `.git` subdirectory. It leaves 696MB.

Anyway, I cannot build the Docker image on even `g2.8xlarge`.

So I go back to use VirtualBox VM and installed CoreOS 899.15.0.
After ssh into the VM, `uname -r` shows Linux kernel version 4.3.6 --
exactly as that on AWS!

So I build the Docker image on the VM, tag and push it:

```
docker tag xxxxxx cxwangyi/cuda:v1
docker login --username=cxwangyi --email=yi.wang.2005@gmail.com
docker push cxwangyi/cuda
```

Then on an EC2 CUDA instance, I run:

```
docker run -it --priviledged cxwangyi/cuda:v1
```

### Too Big Docker Image to Pull

However, this complains that the Docker image to be pulled is too big
and runs out of disk space.  The question becomes: how to make Docker
images smaller.  Google told me --
[docker-squash](https://github.com/jwilder/docker-squash).

I downloaded pre-built docker-squash from its Github README.md page,
and scp to my VirtualBox VM, untar there.  Then I followed the
[usage description](http://jasonwilder.com/blog/2014/08/19/squashing-docker-images/)
to remove Linux kernel source code and NVidia packages and
docker-squash.


### Solution

The solution is simply build the Docker image manually, so all changes
get into a single commit.  During this manual procedure, we delete
files that are no longer useful.  This starts from the base image of
ubuntu:14.04:

```
docker run -it --privileged ubuntu:14.04 /bin/bash
```

followed by all steps enlisted
[here](https://github.com/wangkuiyi/es-dev-stack/blob/clone-most-recent-commit-of-linux-kernel/corenvidiadrivers/Dockerfile)
with RUN and the final CMD.  The final step generates
`/opt/nvidia/nvidia_installers/NVIDIA-Linux-x86_64-352.39/kernel/uvm/nvidia-uvm.ko`,
the kernel module we need.  Then all other stuff, Linux kernel source
code and CUDA things can be deleted.  Then we do

```
exit # exit from the running of /bin/bash in ubuntu:14:04 container
docker commit <id>
```

so to make all our work into a single Docker commit.  The `docker
commit` command will print a new Docker commit id, say <new_cid>,
which can be tagged:

```
docker tag cxwangyi/cuda <new_cid>
```

An alternative solution is to combine all RUN directives in Dockerfile
into a single one, so that `docker build` creates a single commit with
all changes.

### Pitfalls

On my VM and AWS EC2 instances, CoreOS mounts `/tmp` to a small
in-memory filesystem which is too small.  The solution is simply `sudo
umount /tmp` so that `/tmp` is on the big disk partition which holds
`/`.

I tried using docker-squash to reduce the image size.  But it is not
as effective as grouping all changes into a single Docker commit.

I once forgot to use the `--privilege` option and causes some
confusions as I documented
[here](https://github.com/emergingstack/es-dev-stack/issues/15).
