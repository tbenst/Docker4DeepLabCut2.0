FROM nvidia/cuda:9.2-cudnn7-devel-ubuntu18.04
# FROM nvidia/cuda:10.0-cudnn7-devel-ubuntu18.04

# Install Anaconda
# based on https://hub.docker.com/r/continuumio/anaconda3/dockerfile

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV PATH /opt/conda/bin:$PATH

RUN apt-get update --fix-missing && apt-get install -y wget bzip2 ca-certificates \
    libglib2.0-0 libxext6 libsm6 libxrender1 \
    git mercurial subversion

RUN wget --quiet https://repo.anaconda.com/archive/Anaconda3-5.3.0-Linux-x86_64.sh -O ~/anaconda.sh && \
    /bin/bash ~/anaconda.sh -b -p /opt/conda && \
    rm ~/anaconda.sh && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate base" >> ~/.bashrc

RUN apt-get install -y curl grep sed dpkg && \
    TINI_VERSION=`curl https://github.com/krallin/tini/releases/latest | grep -o "/v.*\"" | sed 's:^..\(.*\).$:\1:'` && \
    curl -L "https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini_${TINI_VERSION}.deb" > tini.deb && \
    dpkg -i tini.deb && \
    rm tini.deb && \
    apt-get clean

# Install DeepLabCut
COPY environment.yml /tmp
RUN conda env create -f /tmp/environment.yml
RUN git clone https://github.com/DeepLabCut/DeepLabCut
RUN cd DeepLabCut && /opt/conda/envs/DLC-GPU/bin/python setup.py install

# default to using the dlc conda environment
ENV PATH /opt/conda/envs/DLC-GPU/bin:$PATH

# avoid importing GUI libraries
# in future, these could be supported via X11 (xvfb) or RDP
# see https://github.com/scottyhardy/docker-wine for inspiration
ENV DLClight=True

# workaround for tensorflow bug, needed on certain recent (2xxx RTX) nvidia hardware
# https://github.com/tensorflow/tensorflow/issues/24496#issuecomment-649803728
# uncomment next line if you encounter CUDNN_STATUS_INTERNAL_ERROR'
ENV TF_FORCE_GPU_ALLOW_GROWTH=true

ENTRYPOINT [ "/usr/bin/tini", "--" ]
CMD [ "/bin/bash" ]