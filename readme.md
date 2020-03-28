# zig-hello-world

### Building zig

#### Setting up my environment

I was using a 19.10 droplet, so I had to setup my environment first.

```
apt-get update && apt-get -y upgrade
apt install -y aptitude
apt install -y vim tmux ripgrep zsh git
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
git clone https://github.com/sgmenda/dotfiles
ln -s dotfiles/dot-vimrc ~/.vimrc
ln -s dotfiles/dot-tmux.conf ~/.tmux.conf
apt install -y lld clang cmake build-essential
```

#### Build LLVM, Clang, and LLD

I stumbled quite a bit with building LLVM. Finally, I got it working using the
instructions in the [zig
Dockerfile](https://github.com/ziglang/docker-zig/blob/master/Dockerfile) and
the instructions on [the
wiki](https://github.com/ziglang/zig/wiki/How-to-build-LLVM,-libclang,-and-liblld-from-source#posix).

For completeness, here are the commands I used.

```
mkdir ~/Projects

cd ~/Projects
wget https://github.com/llvm/llvm-project/releases/download/llvmorg-10.0.0/llvm-10.0.0.src.tar.xz
tar xf llvm-10.0.0.src.tar.xz
cd llvm-10.0.0.src/
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=$HOME/local -DCMAKE_PREFIX_PATH=$HOME/local -DCMAKE_BUILD_TYPE=Release -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD="AVR" -DLLVM_ENABLE_LIBXML2=OFF
make install -j8

cd ~/Projects
wget https://github.com/llvm/llvm-project/releases/download/llvmorg-10.0.0/lld-10.0.0.src.tar.xz
tar xf lld-10.0.0.src.tar.xz
cd lld-10.0.0.src/
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=$HOME/local -DCMAKE_PREFIX_PATH=$HOME/local -DCMAKE_BUILD_TYPE=Release
make install -j8

cd ~/Projects
wget https://github.com/llvm/llvm-project/releases/download/llvmorg-10.0.0/lld-10.0.0.src.tar.xz
tar xf lld-10.0.0.src.tar.xz
cd clang-10.0.0.src/
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=$HOME/local -DCMAKE_PREFIX_PATH=$HOME/local -DCMAKE_BUILD_TYPE=Release
make install -j8
```

#### Build zig

This part was straightforward.

```
git clone https://github.com/ziglang/zig.git
mkdir build
cd build
cmake .. -DCMAKE_PREFIX_PATH=$HOME/local
make
```

### Hello World


