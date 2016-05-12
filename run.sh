# This trial is based on https://github.com/emergingstack/es-dev-stack.

if [[ ! -f ./`basename $0` ]]; then
    echo "Please run this program in the directory where it resides."
    exit
fi

if [[ ! -d coreos-vagrant ]]; then
    git clone -b sync_dir https://github.com/wangkuiyi/coreos-vagrant
fi
cp coreos-vagrant/Vagrantfile .

mkdir cuda
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


# # Start the virtual cluster. 
# vagrant up
# vagrant ssh

