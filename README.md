# less

[less](https://www.greenwoodsoftware.com/less/) as a single self-contained binary, built natively for Linux, macOS, and Windows.

[![CI](https://github.com/unpins/less/actions/workflows/less.yml/badge.svg)](https://github.com/unpins/less/actions)
![Linux](https://img.shields.io/badge/Linux-✓-success?logo=linux&logoColor=white)
![macOS](https://img.shields.io/badge/macOS-✓-success?logo=apple&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-✓-success?logo=windows&logoColor=white)

Part of the [unpins](https://unpins.org) catalog; install it with [`unpin`](https://github.com/unpins/unpin): `unpin install less`.

Ships `less` plus its companion programs `lesskey` and `lessecho`. The Windows build uses upstream's `Makefile.wng` (Win32 console API, no ncurses).

## Usage

Run the `less` program with [unpin](https://github.com/unpins/unpin):

```bash
unpin less file.txt
```

To install it onto your PATH:

```bash
unpin install less
```

`unpin install less` also creates the `lesskey` and `lessecho` commands.

## Man pages

`less.1`, `lesskey.1`, and `lessecho.1` are embedded in the `less` binary — read with `unpin man less`.

## Build locally

```bash
nix build github:unpins/less
./result/bin/less
```

Or run directly:

```bash
nix run github:unpins/less
```

The first invocation will offer to add the [unpins.cachix.org](https://unpins.cachix.org) substituter so most pulls come pre-built.

## Manual download

The [Releases](https://github.com/unpins/less/releases) page has standalone binaries for manual download.
