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
        linux-vdso.so.1 (0x00007fff3ea2f000)
        libhello_again.so => /nix/store/h21wym9m4308jkyv2g5lzcpzs8f2w343-hello_again/lib/libhello_again.so (0x00007f5214d44000)
        libhello.so => /nix/store/2bbqrfsj26i6782xlkq613cjph7igpws-hello/lib/libhello.so (0x00007f5214d3f000)
        libstd-93484d347580822d.so => /nix/store/x74cwd4ali3wyww40arw98m69r9nmcdr-rustc-1.69.0/lib/rustlib/x86_64-unknown-linux-gnu/lib/libstd-93484d347580822d.so (0x00007f5214b76000)
        libgcc_s.so.1 => /nix/store/843dqq10jdkalr2yazaz6drx334visrb-gcc-12.2.0-lib/lib/libgcc_s.so.1 (0x00007f5214b55000)
        libc.so.6 => /nix/store/46m4xx889wlhsdj72j38fnlyyvvvvbyb-glibc-2.37-8/lib/libc.so.6 (0x00007f521496d000)
        /nix/store/46m4xx889wlhsdj72j38fnlyyvvvvbyb-glibc-2.37-8/lib/ld-linux-x86-64.so.2 => /nix/store/46m4xx889wlhsdj72j38fnlyyvvvvbyb-glibc-2.37-8/lib64/ld-linux-x86-64.so.2 (0x00007f5214d50000)
```

This allows the sizes of the binary and its dependencies to be small:

```
[nix-shell:~/dyrust]$ ls -lh `which sample_bin`
-r-xr-xr-x 1 root root 17K Jan  1  1970 /nix/store/96yfkqbsg2nlwmfc03b829vcszhcf694-sample_bin/bin/sample_bin

[nix-shell:~/dyrust]$ ls -lh /nix/store/2bbqrfsj26i6782xlkq613cjph7igpws-hello/lib/libhello.so
-r-xr-xr-x 1 root root 18K Jan  1  1970 /nix/store/2bbqrfsj26i6782xlkq613cjph7igpws-hello/lib/libhello.so

[nix-shell:~/dyrust]$ ls -lh /nix/store/h21wym9m4308jkyv2g5lzcpzs8f2w343-hello_again/lib/libhello_again.so
-r-xr-xr-x 1 root root 18K Jan  1  1970 /nix/store/h21wym9m4308jkyv2g5lzcpzs8f2w343-hello_again/lib/libhello_again.so
```

With most of the size staying in a common libstd, that can be shared by all binaries on the system.

```
[nix-shell:~/dyrust]$ ls -lh /nix/store/x74cwd4ali3wyww40arw98m69r9nmcdr-rustc-1.69.0/lib/rustlib/x86_64-unknown-linux-gnu/lib/libstd-93484d347580822d.so
-r-xr-xr-x 1 root root 6.3M Jan  1  1970 /nix/store/x74cwd4ali3wyww40arw98m69r9nmcdr-rustc-1.69.0/lib/rustlib/x86_64-unknown-linux-gnu/lib/libstd-93484d347580822d.so
```

This can similarly extend to larger libraries like tokio.

# To do

* copy libstd to libstd-rust package
* fixup dependency path
* propagate libstd-rust dependency
* port simple package
