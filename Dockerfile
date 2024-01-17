FROM debian:latest

ARG IMG_VER
ENV IMG_VER=${IMG_VER:-v1.1.0}


RUN apt-get update && apt-get upgrade --yes
RUN apt-get install software-properties-common apt-utils gnupg lsb-release\
    curl wget \
    git \
    tree  nano \
    build-essential gdb \
    man-db \
    sudo \
    --yes

RUN mkdir ~/Temp && cd ~/Temp

ARG NODE_VER=20.10.0
RUN wget https://nodejs.org/dist/v${NODE_VER}/node-v${NODE_VER}-linux-x64.tar.xz
RUN tar -xf node-v${NODE_VER}-linux-x64.tar.xz
RUN mv node-v${NODE_VER}-linux-x64 /opt
ENV PATH=/opt/node-v${NODE_VER}-linux-x64/bin:${PATH}


ARG NVIM_VER=0.9.4
RUN curl --silent -LO https://github.com/neovim/neovim/releases/download/v${NVIM_VER}/nvim.appimage
RUN chmod +x nvim.appimage
RUN ./nvim.appimage --appimage-extract 1>/dev/null
RUN mkdir -p /opt && mv squashfs-root /opt
RUN ln -s /opt/squashfs-root/AppRun /usr/local/bin/nvim
RUN npm install -g neovim
RUN sudo apt install python3 python3-pip python3-pynvim python3-venv -y

ARG RIPGREP_VER=13.0.0
RUN curl -LO https://github.com/BurntSushi/ripgrep/releases/download/${RIPGREP_VER}/ripgrep_${RIPGREP_VER}_amd64.deb
RUN dpkg -i ripgrep_${RIPGREP_VER}_amd64.deb

ARG FDFIND_VER=8.7.1
RUN curl -LO https://github.com/sharkdp/fd/releases/download/v${FDFIND_VER}/fd_${FDFIND_VER}_amd64.deb
RUN dpkg -i fd_${FDFIND_VER}_amd64.deb

ARG LUA_VER=5.4.6
RUN apt-get install libreadline-dev --yes
RUN wget https://www.lua.org/ftp/lua-${LUA_VER}.tar.gz
RUN tar -zxf lua-${LUA_VER}.tar.gz
RUN cd lua-${LUA_VER} && make linux-readline && make install
RUN cd ..

ARG LUAROCKS_VER=3.9.2
RUN apt-get install zip --yes
RUN wget https://luarocks.github.io/luarocks/releases/luarocks-${LUAROCKS_VER}.tar.gz
RUN tar -zxf luarocks-${LUAROCKS_VER}.tar.gz 
RUN cd luarocks-${LUAROCKS_VER} && ./configure --with-lua-include=/usr/local/include && make && make install
RUN cd ..

ARG BAT_VER=0.24.0
RUN wget https://github.com/sharkdp/bat/releases/download/v${BAT_VER}/bat_${BAT_VER}_amd64.deb
RUN dpkg -i bat_${BAT_VER}_amd64.deb

ARG DELTA_VER=0.16.5
RUN wget https://github.com/dandavison/delta/releases/download/${DELTA_VER}/git-delta_${DELTA_VER}_amd64.deb
RUN dpkg -i git-delta_${DELTA_VER}_amd64.deb

ARG LAZYGIT_VER=0.40.2
RUN wget https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VER}/lazygit_${LAZYGIT_VER}_Linux_x86_64.tar.gz
RUN mkdir /opt/lazygit_${LAZYGIT_VER}_Linux_x86_64
RUN tar -zxf lazygit_${LAZYGIT_VER}_Linux_x86_64.tar.gz -C /opt/lazygit_${LAZYGIT_VER}_Linux_x86_64
ENV PATH=/opt/lazygit_${LAZYGIT_VER}_Linux_x86_64:${PATH}

ARG BAZELISK_VER=1.19.0
RUN wget https://github.com/bazelbuild/bazelisk/releases/download/v${BAZELISK_VER}/bazelisk-linux-amd64 -O /usr/local/bin/bazel
RUN chmod +x /usr/local/bin/bazel

ARG BAZEL_VER=7.0.0
RUN wget https://raw.githubusercontent.com/bazelbuild/bazel/${BAZEL_VER}/scripts/bazel-complete-template.bash -O /etc/bash_completion.d/bazel-complete-template.bash
RUN wget https://raw.githubusercontent.com/bazelbuild/bazel/${BAZEL_VER}/scripts/bazel-complete-header.bash -O /etc/bash_completion.d/bazel-complete-header.bash
RUN wget https://raw.githubusercontent.com/bazelbuild/bazel/${BAZEL_VER}/scripts/generate_bash_completion.sh -O /usr/local/bin/generate_bash_completion.sh
RUN chmod +x /usr/local/bin/generate_bash_completion.sh

RUN cd ~ && rm -rf ~/Temp

RUN apt-get autoremove -y

RUN useradd -ms /bin/bash developer
RUN usermod -aG sudo developer
RUN echo "developer     ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER developer
WORKDIR /home/developer

RUN git clone  https://github.com/Ahmed-Zamouche/LazyVim.git  ~/.config/nvim
RUN cd ~/.config/nvim && git checkout personal && git submodule update --init --recursive
RUN nvim +PluginUpdate +qall

RUN git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
RUN ~/.fzf/install --all

RUN wget -P ~ https://git.io/.gdbinit
RUN sudo apt install python3-pygments

RUN wget https://gist.githubusercontent.com/Ahmed-Zamouche/6235fdf5ac584290ba94926f62acb441/raw/a42385fa087c059c2b2360345bac5245bfd4bda4/.bash_functions
RUN wget https://gist.githubusercontent.com/Ahmed-Zamouche/e75c71c1856f04b3c458cbe1f722ce61/raw/c53a8f49b8fd581699ad791e2bfdabc0588ee08a/.fzfrc
RUN wget https://gist.githubusercontent.com/Ahmed-Zamouche/dafe2b33458166c61530ea9569e99aab/raw/221ce4db592524ffc3be7ba4a502e2820eed6254/.bash_aliases
RUN wget https://gist.githubusercontent.com/Ahmed-Zamouche/df69ebe0e48702d5cbe65104103f5e00/raw/e0600a59808f85697aa2bfa082af1a49ddaa4e72/.git-prompt.sh
RUN wget https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -O ~/.git-completion.bash

COPY bashrc.patch /tmp/bashrc.patch
RUN patch -u -b ~/.bashrc -i /tmp/bashrc.patch
RUN sudo rm /tmp/bashrc.patch

RUN echo "export OPEN_WEATHER_API_KEY=${OPEN_WEATHER_API_KEY}" >> ~/.profile
ENV OPEN_WEATHER_API_KEY=${OPEN_WEATHER_API_KEY}
ENV SHELL=bash
ENV LANG=C.UTF-8

