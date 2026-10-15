// Isi dua nilai di bawah dari Supabase: Project Settings → API (Project URL dan anon public key).
// Kunci "anon" memang aman ditaruh di sini: data tetap terkunci oleh login dan aturan hak akses di database.
window.KISO_CONFIG = {
  supabaseUrl: "https://hxuoxvznuxjpxfjfphtu.supabase.co",          // contoh: "https://abcdxyz.supabase.co"
  supabaseAnonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh4dW94dnpudXhqcHhmamZwaHR1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTIwNjAxMzQsImV4cCI6MjEwNzYzNjEzNH0.xrny1t_2QV8Z7PsR29aKjieGdtItBQQMUO5x3OTIC1c",   // teks panjang diawali "eyJ..."
  userDomain: "kiso-backoffice.app"         // jangan diubah setelah ada pengguna
};
