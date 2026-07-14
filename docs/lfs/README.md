# LFS Build Notes

Catatan build fase 1 (base system) Incognito OS, mengikuti [Linux From Scratch Book](https://www.linuxfromscratch.org/lfs/view/stable/) versi stable.

## Urutan Build

1. **Persiapan host** — cek dependency (`scripts/build/phase1-lfs-base.sh` -> `check_host_requirements`)
2. **Partisi & mount** — buat partisi khusus build LFS, mount di `$LFS` (default `/mnt/lfs`)
3. **Download source** — semua tarball taruh di `$LFS/sources`, daftar lengkap ada di `packages/base-packages.txt`
4. **User `lfs`** — build toolchain sebagai user non-root demi isolasi dari sistem host
5. **Cross toolchain (pass 1)** — binutils, gcc, linux headers, glibc, libstdc++
6. **Cross toolchain (pass 2)** — rebuild binutils & gcc terhadap glibc target
7. **Temporary tools** — m4, ncurses, bash, coreutils, dll (versi minimal untuk chroot)
8. **Masuk chroot** — lihat output `enter_chroot_prep` di phase1 script untuk command lengkap
9. **Base system final** — build ulang seluruh temporary tools + paket final di dalam chroot (ch. 8 LFS Book)

## Status

- [x] Kerangka script otomatisasi (`phase1-lfs-base.sh`)
- [ ] Daftar package versi + checksum final (isi `packages/base-packages.txt`)
- [ ] Build cross-toolchain pass 1 & 2 (sub-script per paket, taruh di `scripts/tools/lfs-packages/`)
- [ ] Build base system final di dalam chroot

## Referensi

- LFS Book stable: https://www.linuxfromscratch.org/lfs/view/stable/
- Errata (patch fixes): https://www.linuxfromscratch.org/lfs/errata.html
