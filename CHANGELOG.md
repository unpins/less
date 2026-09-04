# Changelog

## [Unreleased]

### Added

- `lesskey` and `lessecho` now work on Windows. They were built and then thrown
  away there; the Windows binary carried `less` alone, while Linux and macOS
  had all three.

### Changed

- The Windows binary is now built by the same compiler as the Linux and macOS
  ones (302 KB to 312 KB — it now carries three programs instead of one).
  Checked on Windows 10: `less --version` matches the previous binary, and
  `lessecho` and `lesskey` do real work.

  It now uses the Universal C Runtime, which is part of Windows 10 and later.
  On Windows 7 or 8.1 that runtime has to be installed first — it comes through
  Windows Update. The previous binary did not need it.
