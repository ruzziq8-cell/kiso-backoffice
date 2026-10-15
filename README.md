# KISO Back Office — versi website

Aplikasi back office KISO.ID (stok, penjualan, pembelian, hutang, piutang, bank & kas, iklan, laporan) yang bisa dibuka dari browser mana pun dengan **ID dan password**.

| Bagian | Layanan (gratis) | Fungsi |
|---|---|---|
| Database + login | **Supabase** | Menyimpan semua data dan akun pengguna, menjaga hak akses tiap peran |
| Kode aplikasi | **GitHub** | Tempat file aplikasi; setiap perubahan otomatis terpasang ke website |
| Website | **Cloudflare Pages** | Menayangkan aplikasi di alamat seperti `kiso-backoffice.pages.dev` |

> Kenapa bukan Vercel: paket gratis Vercel (Hobby) hanya untuk pemakaian pribadi non-komersial, sedangkan aplikasi ini dipakai untuk usaha. Cloudflare Pages gratis dan cara pasangnya sama mudahnya.

Tidak ada komputer kantor yang perlu dijadikan server. Data tersimpan di Supabase (cloud).

---

## Langkah 1 — Siapkan database di Supabase (±10 menit)

1. Daftar di **supabase.com** (bisa pakai akun GitHub), lalu **New project**.
   - Name: `kiso-backoffice`
   - Database password: buat yang kuat dan simpan
   - Region: **Southeast Asia (Singapore)**
2. Tunggu proyek selesai dibuat (1–2 menit).
3. Buka menu **SQL Editor** → **New query**. Salin seluruh isi file `supabase/schema.sql`, tempel, lalu klik **Run**. Harus muncul "Success".
4. Buka **Authentication** → **Sign In / Providers** (atau **Providers**) → **Email**:
   - **Enable Email provider**: ON
   - **Confirm email**: **OFF** ← wajib, karena login memakai ID, bukan email sungguhan
   - **Allow new users to sign up**: ON (dipakai CEO saat membuat pengguna dari aplikasi)
   - Simpan.
5. Buka **Project Settings** → **API** (atau **API Keys** → tab *Legacy*). Salin:
   - **Project URL** (contoh `https://abcdxyz.supabase.co`)
   - **anon public** key (teks panjang diawali `eyJ...`)
6. Buka file `config.js`, ganti `ISI_PROJECT_URL` dan `ISI_ANON_PUBLIC_KEY` dengan dua nilai tadi.

## Langkah 2 — Taruh kode di GitHub

1. Daftar/masuk di **github.com** → **New repository** → nama `kiso-backoffice` → **Private** → **Create repository**.
2. Klik **uploading an existing file**, lalu seret semua isi folder ini (`index.html`, `config.js`, `README.md`, `.gitignore`, dan folder `supabase`). Klik **Commit changes**.
3. **Jangan pernah meng-upload file cadangan data (`kiso-backup-*.json`) ke GitHub.** File itu berisi data usaha.

## Langkah 3 — Tayangkan website di Cloudflare Pages

1. Daftar di **dash.cloudflare.com** (gratis).
2. Menu **Workers & Pages** → **Create** → tab **Pages** → **Connect to Git** / **Import an existing Git repository** → hubungkan akun GitHub → pilih repo `kiso-backoffice`.
3. Pengaturan build:
   - Framework preset: **None**
   - Build command: *(kosongkan)*
   - Build output directory: `/`
4. **Save and Deploy**. Setelah selesai, website ada di `https://kiso-backoffice.pages.dev` (nama bisa sedikit berbeda kalau sudah dipakai orang).

Setiap kali file di GitHub diubah, website ikut ter-update otomatis dalam 1–2 menit.

## Langkah 4 — Pakai pertama kali & pindahkan data lama

1. Buka alamat website. Karena belum ada pengguna, muncul layar **Buat akun pertama** → isi Nama, ID, Password → akun ini otomatis menjadi **CEO**.
2. Buka **Pengaturan** → **Cadangan data** → **Pulihkan dari cadangan…** → pilih file `kiso-backup-2026-10-15.json` (data dari aplikasi claude.ai). Tunggu sampai selesai; halaman memuat ulang sendiri.
3. Cek angka di Dashboard dan Stok sama dengan aplikasi lama.
4. Mulai saat itu, **input data hanya di website baru**. Aplikasi lama di claude.ai jangan dipakai lagi supaya data tidak bercabang.

## Langkah 5 — Buat akun untuk tim

Di **Pengaturan → Pengguna & hak akses → Tambah pengguna** (hanya CEO):

| Peran | Yang bisa dilakukan |
|---|---|
| **CEO** | Melihat dan mengubah semua modul, mengatur pengguna, cadangan data |
| **Admin keuangan** | Melihat dan mengubah Dashboard, Penjualan, Pembelian, Hutang, Harga & Margin, Beban & Aset, Bank & Kas, Piutang, Iklan, Laporan |
| **Gudang** | Hanya modul Stok |
| **Pemilik** | Melihat semua modul, tidak bisa mengubah apa pun |

- ID: huruf kecil/angka, contoh `gudang1`, `admin.rina`. Berikan ID + password awal ke orangnya; ia bisa mengganti password sendiri lewat tombol **Ganti password** di kanan atas.
- Lupa password: CEO klik **Ganti password** di baris pengguna itu.
- Orang keluar dari perusahaan: hilangkan centang **Aktif** → **Simpan**. Aksesnya langsung tertutup.

Hak menyimpan dijaga oleh database (bukan hanya tampilan): akun Pemilik tidak bisa mengubah apa pun, akun Gudang hanya bisa mengubah data stok (produksi, penyesuaian, retur, produk, bahan), dan hanya CEO yang bisa mengatur pengguna.

## Perawatan

- **Cadangan rutin:** tiap akhir bulan, CEO klik **Unduh cadangan (.json)** di Pengaturan dan simpan filenya di komputer kantor / Google Drive.
- **Supabase gratis "tertidur"** kalau 7 hari berturut-turut tidak ada yang membuka aplikasi. Kalau website tiba-tiba tidak bisa login setelah libur panjang, masuk ke supabase.com → pilih proyek → **Restore project**. Data tidak hilang.
- Batas paket gratis Supabase (database 500 MB) jauh di atas kebutuhan saat ini.
- Nama domain sendiri (misalnya `kiso.my.id`) bisa disambungkan nanti di Cloudflare Pages → **Custom domains**.
