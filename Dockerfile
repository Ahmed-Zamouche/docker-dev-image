FROM debian:bullseye

ARG IMG_VER
ENV IMG_VER=${IMG_VER:-v1.0.0}


RUN apt-get update && apt-get upgrade --quiet --yes
RUN apt-get install software-properties-common apt-utils gnupg lsb-release\
    curl wget \
    git \
    asciidoctor \
    tree  nano \
    build-essential gdb \
    fontconfig xfonts-utils xclip xterm firefox-esr \
    plantuml pandoc pandoc-plantuml-filter python3-pip \
    man-db \
    sudo \
    --quiet --yes

ARG NVIM_VER=0.5.1
RUN curl --silent -LO https://github.com/neovim/neovim/releases/download/v${NVIM_VER}/nvim.appimage
RUN chmod +x nvim.appimage
RUN ./nvim.appimage --appimage-extract 1>/dev/null
RUN rm nvim.appimage
RUN mkdir -p /opt && mv squashfs-root /opt
RUN ln -s /opt/squashfs-root/AppRun /usr/local/bin/nvim

RUN bash -c "$(wget -O - https://apt.llvm.org/llvm.sh --quiet)"
# Fingerprint: 6084 F3CF 814B 57C1 CF12 EFD5 15CF 4D18 AF4F 7421
RUN wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key --quiet | apt-key add -
RUN apt-get update && apt-get install clang-format clang-tidy clang-tools \
    clang clangd libc++-dev libc++1 libc++abi-dev libc++abi1 libclang-dev \
    libclang1 liblldb-dev libllvm-ocaml-dev libomp-dev libomp5 lld lldb \
    llvm-dev llvm-runtime llvm python-clang --quiet --yes

ARG CMAKE_VER=3.22.0
RUN wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VER}/cmake-${CMAKE_VER}-linux-x86_64.sh --quiet
RUN chmod +x cmake-${CMAKE_VER}-linux-x86_64.sh
RUN ./cmake-${CMAKE_VER}-linux-x86_64.sh --prefix=/usr/local --skip-license
RUN rm cmake-${CMAKE_VER}-linux-x86_64.sh

ARG CCACHE_VER=4.5.1
RUN wget https://github.com/ccache/ccache/releases/download/v${CCACHE_VER}/ccache-${CCACHE_VER}.tar.gz --quiet
RUN tar -xf ccache-${CCACHE_VER}.tar.gz
RUN cd ccache-${CCACHE_VER} && mkdir build && cd build && \
    CC=/usr/bin/clang CXX=/usr/bin/clang++ LD=/usr/bin/lld \
    cmake .. -DZSTD_FROM_INTERNET=ON \
    -DHIREDIS_FROM_INTERNET=ON \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DCMAKE_INSTALL_SYSCONFDIR=/etc \
    -DCMAKE_BUILD_TYPE=Release && \
    make  -j$(nproc --all) && make install
RUN ln -s ccache /usr/local/bin/gcc
RUN ln -s ccache /usr/local/bin/g++
RUN ln -s ccache /usr/local/bin/cc
RUN ln -s ccache /usr/local/bin/c++
RUN ln -s ccache /usr/local/bin/clang
RUN ln -s ccache /usr/local/bin/clang++
RUN rm -r ccache-${CCACHE_VER}.tar.gz ccache-${CCACHE_VER}

ARG GTEST_VER=1.11.0
RUN wget https://github.com/google/googletest/archive/refs/tags/release-${GTEST_VER}.tar.gz --quiet
RUN tar -xf release-${GTEST_VER}.tar.gz
RUN cd googletest-release-${GTEST_VER} && mkdir build && cd build && pwd && \
    cmake .. -DGTEST_HAS_PTHREAD=1 \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    && make && make install
RUN rm -r release-${GTEST_VER}.tar.gz googletest-release-${GTEST_VER}

ARG CPPCHECK_VER=2.6
RUN wget https://github.com/danmar/cppcheck/archive/${CPPCHECK_VER}.tar.gz --quiet
RUN tar -xf ${CPPCHECK_VER}.tar.gz
RUN apt-get install libpcre3 libpcre3-dev -y
RUN cd cppcheck-${CPPCHECK_VER} && mkdir build && cd build && \
    CC=/usr/bin/clang CXX=/usr/bin/clang++ LD=/usr/bin/lld \
    cmake .. -DBUILD_GUI=OFF \
    -DHAVE_RULES=ON \
    -DUSE_MATCHCOMPILER=ON \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DCMAKE_INSTALL_SYSCONFDIR=/etc \
    -DCMAKE_BUILD_TYPE=Release && \
    make  -j$(nproc --all) && make install

RUN rm -r ${CPPCHECK_VER}.tar.gz cppcheck-${CPPCHECK_VER}

RUN apt-get autoremove -y

RUN echo "source /home/developer/workspace/setup.sh" >> /etc/skel/.bashrc
RUN useradd -ms /bin/bash developer
RUN usermod -aG sudo developer
RUN echo "developer     ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER developer
WORKDIR /home/developer

ARG DISPLAY
ENV DISPLAY=${DISPLAY:-:0.0}

RUN curl -sLf https://spacevim.org/install.sh | bash
RUN python3 -m pip install --user --upgrade pynvim

USER root

#ARG CTAGS_VER=1.11.0
#RUN wget https://sourceforge.net/projects/ctags/files/ctags/5.8/ctags-5.8.tar.gz
RUN apt-get install exuberant-ctags -y

USER developer

