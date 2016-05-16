# This trial is based on https://github.com/emergingstack/es-dev-stack.

if [[ ! -f ./`basename $0` ]]; then
    echo "Please run this program in the directory where it resides."
    exit
fi

mkdir cuda

if [[ -f cuda/nvidia.ko &&  -f cuda/nvidia-uvm.ko ]]; then
    echo "CUDA kernel modules were built already.  Building a CUDA sample app ..."
    ACTION=use
    (
	cd cuda
	if [[ ! -d cuda-7.5 ]]; then
	    if [[ ! -f cuda-linux64-rel-7.5.18-19867135.run ]]; then
		if [[ ! -f cuda_7.5.18_linux.run ]]; then
		    wget http://developer.download.nvidia.com/compute/cuda/7.5/Prod/local_installers/cuda_7.5.18_linux.run
		fi

		chmod +x cuda_7.5.18_linux.run
		./cuda_7.5.18_linux.run -extract=`pwd`
	    fi

	    chmod +x cuda-linux64-rel-7.5.18-19867135.run
	    ./cuda-linux64-rel-7.5.18-19867135.run -noprompt -prefix=`pwd`/cuda-7.5
	fi
    )
else
    echo "Building CUDA kernel modules ..."
    ACTION=build
    (
	cd cuda
	if [[ ! -d NVIDIA-Linux-x86_64-352.39 ]]; then
	    if [[ ! -f NVIDIA-Linux-x86_64-352.39.run ]]; then
		if [[ ! -f cuda_7.5.18_linux.run ]]; then
		    wget http://developer.download.nvidia.com/compute/cuda/7.5/Prod/local_installers/cuda_7.5.18_linux.run
		fi

		chmod +x cuda_7.5.18_linux.run
		./cuda_7.5.18_linux.run -extract=`pwd`
	    fi

	    chmod +x ./NVIDIA-Linux-x86_64-352.39.run
	    ./NVIDIA-Linux-x86_64-352.39.run -a -x --ui=none
	fi
    )
    rm -rf linux # Re-grab Linux kernel source code anyway.
fi

vagrant box update
vagrant up

if [[ $ACTION == "use" ]]; then
    vagrant ssh -c "docker run --rm -v /home/core/share:/opt/share --privileged gcc:4.9 /bin/bash /opt/share/build-cuda-app.sh"
else 
    vagrant ssh -c "docker run --rm -v /home/core/share:/opt/share --privileged gcc:4.9 /bin/bash /opt/share/build-cuda-driver.sh"
fi
