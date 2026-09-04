{
  description = "less as a single self-contained binary";

  nixConfig = {
    extra-substituters = [ "https://unpins.cachix.org" ];
    extra-trusted-public-keys = [ "unpins.cachix.org-1:DDaShjbZ8VvcqxeTcAU3kV9vxZQBlyb7V/uLBHfTynI=" ];
  };

  inputs.unpins-lib.url = "github:unpins/nix-lib";

  outputs = { self, unpins-lib }:
    unpins-lib.lib.mkStandaloneFlake {
      inherit self;
      name = "less";
      smoke = [ "--version" ];
      smokePattern = "^less [0-9]+";

      # Build via the unpin-llvm engine + emit a bitcode multicall module.
      engine = "unpin-llvm";
      multicall = {
        # The `.exe` on the engine too, not the nixpkgs mingw-gcc cross; with
        # three programs that also gives Windows the same dispatcher the other
        # platforms have, instead of three separate binaries.
        windows = true;
        programs = [{ name = "less"; } { name = "lessecho"; } { name = "lesskey"; }];
        # less bakes SYSDIR into the binary and looks for `<sysdir>/.sysless`
        # (the system-wide lesskey) at startup. Autotools resolves SYSDIR to the
        # base derivation's $out/bin, so the shipped binary carried
        # `/nix/store/<base>/bin/.sysless` — a path that exists on no user's
        # machine. Harmless at runtime (the lookup just fails, silently, as it
        # does on any host without one) but it is a store path inside a binary
        # whose whole claim is self-containment, and `nix-store --references`
        # does NOT see it: the check that would catch it is a `strings` scan.
        # Verified present in the released artifact (CI 32491411984, 2026-08-21)
        # before this line.
        removeReferences = [ "less-static" ];
      };
      # less links ncurses(libtinfo) for terminfo-driven screen control. The
      # fallback-terminfo + store-path-leak fix is baked centrally for every
      # engine-Linux ncurses (native-overlay/ncurses.nix), so pkgsStatic.ncurses
      # is already the portable, mega-dedupable .a — no per-package override.
      # (Windows uses Makefile.wng below, no ncurses.)
      build = pkgs:
        let base = pkgs.pkgsStatic.less; in
        base.overrideAttrs (_: {
          # less's suite only runs against a binary built with -DLESSTEST, and
          # upstream's `check` target gets there by `make clean; make LESSTEST=1`
          # (Makefile.in:110). As a checkPhase that would hand installPhase the
          # INSTRUMENTED binary to ship, so it runs after install instead: $out
          # already holds the plain one and the rebuild only dirties a tree
          # about to be discarded. What is exercised is therefore the same
          # source, not the same binary — upstream leaves no other way.
          doInstallCheck =
            base.stdenv.buildPlatform.canExecute base.stdenv.hostPlatform;
          installCheckTarget = "check";
          # lesstest/runtest is `#!/usr/bin/env perl`; the sandbox has no
          # /usr/bin/env, and perl is not otherwise in scope.
          preInstallCheck = "patchShebangs lesstest";
          nativeInstallCheckInputs = [ pkgs.buildPackages.perl ];
        });
      # less on mingw doesn't use ncurses. Upstream ships Makefile.wng which targets
      # the Win32 console API directly (defines.wn + -lshell32). Autotools' configure
      # detects -ltinfo/-lncursesw via AC_CHECK_LIB but every subsequent
      # AC_LINK_IFELSE on tgetent fails, killing the build before any source compiles.
      # Switching to Makefile.wng bypasses configure entirely and produces a much
      # smaller binary (no ncurses pulled into the static link).
      #
      # REGEX_PACKAGE=regcomp-local uses less's bundled Henry Spencer regex (regexp.c),
      # avoiding the mingw libregex dep that's only shipped in MSYS2 environments.
      #
      # Cross from Linux: we have posix grep/sed in PATH, so WINGEN=1 is not needed
      # (the C-based buildgen path is only required when building ON Windows without
      # msys tools).
      windowsBuild = pkgs:
        let cross = unpins-lib.lib.mingwStaticCross pkgs; in
        cross.less.overrideAttrs (old: {
          dontConfigure = true;
          buildInputs = [ ];
          # nixpkgs less declares `outputs = [ "out" "man" ]`, but Makefile.wng installs
          # neither nroff man pages nor a `share/` tree, so drop the man output.
          outputs = [ "out" ];
          # Makefile.wng generates help.c via `perl mkhelp.pl || sh mkhelp.sh`.
          # The .sh fallback isn't shipped in the tarball, so perl is required.
          nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.buildPackages.perl ];
          makeFlags = [
            "-f" "Makefile.wng"
            "SHELL=sh"
            "REGEX_PACKAGE=regcomp-local"
          ];
          # Makefile.wng hard-codes nothing about the compiler, so hand it the
          # stdenv's own — spelled through makeFlagsArray because a `$CC` inside
          # the makeFlags list is not expanded. On the engine that is the clang
          # that emits bitcode; naming a gcc here would quietly build the .exe
          # off the engine and leave the fold with nothing to fold.
          preBuild = (old.preBuild or "") + ''
            makeFlagsArray+=("CC=$CC")
          '';
          installPhase = ''
            runHook preInstall
            mkdir -p $out/bin
            cp less.exe lesskey.exe lessecho.exe $out/bin/
            runHook postInstall
          '';
        });
    };
}
