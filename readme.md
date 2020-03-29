# zig-hello-world

## Building zig

### Setting up my environment

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

### Build LLVM, Clang, and LLD

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

### Build zig

This part was straightforward.

```
git clone https://github.com/ziglang/zig.git
mkdir build
cd build
cmake .. -DCMAKE_PREFIX_PATH=$HOME/local
make
```

## Hello World

Here is a slightly modified version of hello world from [the
docs](https://ziglang.org/documentation/master/#Hello-World).

```zig
const std = @import("std");

pub fn main() void {
    std.debug.warn("Hello, {}!\n", .{"World"});
}
```

You can compile and run it with
```
zig build-exe hello.zig
./hello
```

You're probably thinking, why have the `"World"` in an argument, why not just

```zig
std.debug.warn("Hello, World!\n");
```

It was my first thought as well, but it turns out that this doesn't compile, it
raises the following helpful error

```
Semantic Analysis [671/880] ./hello.zig:5:19: error: expected 2 arguments, found 1
    std.debug.warn("Hello, World!\n");
    ^
/root/Projects/zig/lib/std/debug.zig:61:5: note: declared here
    pub fn warn(comptime fmt: []const u8, args: var) void {
        ^
```

It turns out that one needs two arguments for the function. So, alternatively,
one could write

```zig
std.debug.warn("Hello, World!\n", .{});
```

and it works as expected. 

So, this is cool, we can now print `Hello, World!` in two ways, but in either
case it produces a large statically linked executable. `hello` was `700KB` on my
computer! Come on man, this is go-level stupid.

But, you can build a better executable using the `--release-fast` flag; from the
`--help` page

```
 --release-fast               build with optimizations on and safety off
```

And indeed the executable generated with `--release-fast` is smaller, it is
`143KB` (but it is still statically linked.) Most people stop here. But what if
you wanted to dynamically link against `libc` (which is already in your memory)?
We can do that with zig!

## C Hello World

Here is the traditional C hello world in zig

```zig
const stdio = @cImport({
    @cInclude("stdio.h");
});

pub fn main() void {
    _ = stdio.printf("Hello, World!\n");
}
```

You can compile it with

```
zig build-exe c_hello.zig -lc --release-fast
```

The `-lc` indicates to the compiler that this code uses `libc`. If you look at
the disassembly using

```
objdump -d c_hello
```

you can see that it calls `glibc`'s `printf` and this executable is the more
palatable `40KB`.

#### Aside: Using musl

If you wanted to statically link against the `musl` libc, you can do that as
follows

```
λ zig build-exe c_hello.zig -lc -target x86_64-linux-musl
λ file c_hello
c_hello: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), statically linked,
with debug_info, not stripped
```

#### Note on Size

Size on its own is not a good indicator of performance (think of loop
unrolling.) Also, statically linked executables might be faster than dynamically
linked executables (you know that your code is hot (because it is running) but
the `libc` routine you're calling might not be hot.)
