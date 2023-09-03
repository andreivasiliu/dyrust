# dyrust

`dyrust` is an experiment to replace Cargo with Nix, in order to replace static
libraries with dynamic libraries.

Although this is already possible with Cargo, Rust's current limitations
(unstable ABI, lack of cargo-aware std) make it so that idiomatic Rust means
statically compiled Rust, which in practice ends up in 10MB-50MB CLI tools.

This is unsuitable for replacing something like GNU's core utils, and so it
makes Rust hard to use as a systems language.

Nix/NixOS are in a unique position to make even an unstable ABI viable, due
to them modelling the exact version of a library as part of the binary
package's hash, which means that changing a library always forces a
recompilation of other libraries or binaries that depend on them.

With Nix's dependency model, multiple versions of Rust's libstd can co-exist,
each library will be linked to the exact version of libstd that it was compiled
against, and the distribution/availability of that version happens
automatically.

# Status

This is currently just a toy package to show how it would work.

It does not support proc macros, build.rs scripts, sys crates, and many other
things.

# Example

After running `nix-shell` inside this project's directory:

```
[nix-shell:~/dyrust]$ sample_bin 
Hello!
And hello again!

[nix-shell:~/dyrust]$ ldd `which sample_bin`
        linux-vdso.so.1 (0x00007ffcae54e000)
        libhello_again.so => /nix/store/y3ackmpghghcg9v923vcr7khhvg1k038-hello_again/lib/libhello_again.so (0x00007f2e9c54e000)
        libhello.so => /nix/store/hq36bfjzamkcfrvfbfgvahn0448knzxd-hello/lib/libhello.so (0x00007f2e9c549000)
        libstd-93484d347580822d.so => /nix/store/933hbwrc6hp8bw01hya4q8k1say6hsyx-libstd-rust/lib/libstd-93484d347580822d.so (0x00007f2e9c380000)
        libgcc_s.so.1 => /nix/store/843dqq10jdkalr2yazaz6drx334visrb-gcc-12.2.0-lib/lib/libgcc_s.so.1 (0x00007f2e9c35f000)
        libc.so.6 => /nix/store/46m4xx889wlhsdj72j38fnlyyvvvvbyb-glibc-2.37-8/lib/libc.so.6 (0x00007f2e9c177000)
        /nix/store/46m4xx889wlhsdj72j38fnlyyvvvvbyb-glibc-2.37-8/lib/ld-linux-x86-64.so.2 => /nix/store/46m4xx889wlhsdj72j38fnlyyvvvvbyb-glibc-2.37-8/lib64/ld-linux-x86-64.so.2 (0x00007f2e9c55a000)
```

This allows the sizes of the binary and its dependencies to be small:

```
[nix-shell:~/dyrust]$ ls -lh `which sample_bin`
-r-xr-xr-x 1 root root 17K Jan  1  1970 /nix/store/jlcad8nlyw99ml2rygl306cx8pkryj6n-sample_bin/bin/sample_bin

[nix-shell:~/dyrust]$ ls -lh /nix/store/hq36bfjzamkcfrvfbfgvahn0448knzxd-hello/lib/libhello.so
-r-xr-xr-x 1 root root 17K Jan  1  1970 /nix/store/hq36bfjzamkcfrvfbfgvahn0448knzxd-hello/lib/libhello.so

[nix-shell:~/dyrust]$ ls -lh /nix/store/y3ackmpghghcg9v923vcr7khhvg1k038-hello_again/lib/libhello_again.so
-r-xr-xr-x 1 root root 18K Jan  1  1970 /nix/store/y3ackmpghghcg9v923vcr7khhvg1k038-hello_again/lib/libhello_again.so
```

With most of the size staying in a common libstd, that can be shared by all binaries on the system.

```
[nix-shell:~/dyrust]$ ls -lh /nix/store/933hbwrc6hp8bw01hya4q8k1say6hsyx-libstd-rust/lib/libstd-93484d347580822d.so
-r--r--r-- 1 root root 6.3M Jan  1  1970 /nix/store/933hbwrc6hp8bw01hya4q8k1say6hsyx-libstd-rust/lib/libstd-93484d347580822d.so
```

This can similarly extend to larger libraries like tokio.

# libstd-rust package

The `rustc` package in nixpkgs does not expose the built standard library as a separate output; as such, the binaries and libraries built with `-C prefer-dynamic` will by default end up linking against a `libstd-*.so` file that only exists in the `rustc` package.

Nix will see this, and will automatically add `rustc` as a runtime dependency.

Unfortunately, `rustc` is a 700MB package, so `dyrust` makes an effort to extract the `libstd-*.so` file into its own, new `libstd-rust` package, and replace the `rustc` dependency with that.

The end result is a runtime dependency closure that is much smaller:

```
$ for pkg in $(nix-store -qR /nix/store/jlcad8nlyw99ml2rygl306cx8pkryj6n-sample_bin); do
>     du -h -d0 $pkg
> done
1.8M    /nix/store/567zfi9026lp2q6v97vwn640rv6i3n4c-libunistring-1.1
612K    /nix/store/4563gldw8ibz76f1a3x69zq3a1vhdpz9-libidn2-2.3.4
152K    /nix/store/jd99cyc0251p0i5y69w8mqjcai8mcq7h-xgcc-12.2.0-libgcc
31M     /nix/store/46m4xx889wlhsdj72j38fnlyyvvvvbyb-glibc-2.37-8
152K    /nix/store/81d13il7plchw65gz8y9ywcxrngq149c-gcc-12.2.0-libgcc
7.7M    /nix/store/843dqq10jdkalr2yazaz6drx334visrb-gcc-12.2.0-lib
6.3M    /nix/store/933hbwrc6hp8bw01hya4q8k1say6hsyx-libstd-rust
12K     /nix/store/dfbrj6pi2f2fnin5vq9ybq6yxvp73ikn-hello
28K     /nix/store/hq36bfjzamkcfrvfbfgvahn0448knzxd-hello
12K     /nix/store/jy07bqfka8w2xbzm6gga6df5yqvlq9g0-hello_again
28K     /nix/store/y3ackmpghghcg9v923vcr7khhvg1k038-hello_again
28K     /nix/store/jlcad8nlyw99ml2rygl306cx8pkryj6n-sample_bin
```

# To do

* port simple package
