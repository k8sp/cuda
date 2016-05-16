#/bin/bash

echo Hello!  We are building an example CUDA app ...

if [[ `gcc --version | head -n 1` != "gcc (GCC) 4.9.3" ]]; then
    echo GCC 4.9 is required for building CUDA driver for CoreOS;
    exit;
fi

cd /opt/share/example
/opt/share/cuda/cuda-7.5/bin/nvcc example.cu -o example
