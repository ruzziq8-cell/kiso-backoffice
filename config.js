// Isi dua nilai di bawah dari Supabase: Project Settings → API (Project URL dan anon public key).
// Kunci "anon" memang aman ditaruh di sini: data tetap terkunci oleh login dan aturan hak akses di database.
window.KISO_CONFIG = {
  supabaseUrl: "ISI_PROJECT_URL",          // contoh: "https://abcdxyz.supabase.co"
  supabaseAnonKey: "ISI_ANON_PUBLIC_KEY",   // teks panjang diawali "eyJ..."
  userDomain: "kiso-backoffice.app"         // jangan diubah setelah ada pengguna
};
