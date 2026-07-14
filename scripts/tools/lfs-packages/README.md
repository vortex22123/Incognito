# scripts/tools/lfs-packages/

Taruh satu sub-script per paket toolchain LFS di sini, dipanggil berurutan oleh
`scripts/build/phase1-lfs-base.sh` (function `build_cross_toolchain`).

Konvensi nama file: `<paket>-pass<N>.sh`, contoh:
- `binutils-pass1.sh`
- `gcc-pass1.sh`
- `linux-headers.sh`
- `glibc.sh`
- `libstdcpp.sh`
- `binutils-pass2.sh`
- `gcc-pass2.sh`

Tiap script dijalankan sebagai user `lfs` (bukan root), dan harus idempotent
(aman dijalankan ulang tanpa merusak build sebelumnya). Isi versi paket ada
di `packages/base-packages.txt`.
