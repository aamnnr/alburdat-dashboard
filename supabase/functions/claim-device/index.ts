// @ts-ignore
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
// @ts-ignore
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3"

declare const Deno: {
  env: {
    get(key: string): string | undefined;
  };
};

// Pengaturan CORS agar fungsi bisa dipanggil dari aplikasi Flutter
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req: Request) => {
  // Tangani request preflight CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // 1. Ambil payload dari aplikasi Flutter (device_id yang didapat dari QR/AP ESP32)
    const { device_id, device_name } = await req.json()

    if (!device_id) {
      throw new Error("Device ID tidak disertakan")
    }

    // 2. Inisialisasi Supabase Client menggunakan konteks Auth dari request header
    // Ini memastikan kita tahu persis siapa pengguna yang memanggil fungsi ini
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    )

    // 3. Verifikasi Pengguna
    const { data: { user }, error: authError } = await supabaseClient.auth.getUser()
    if (authError || !user) throw new Error("Akses ditolak. Token tidak valid.")

    // 4. Mendaftarkan Alat ke Database
    // Karena kita sudah memasang RLS sebelumnya, insert ini akan otomatis mengikat owner_id
    const { data, error: insertError } = await supabaseClient
      .from('devices')
      .insert([
        { 
          mac_address: device_id, 
          owner_id: user.id, 
          name: device_name || 'Alat Ferticore Baru',
          status: 'online'
        }
      ])
      .select()

    // Tangani jika alat sudah pernah diklaim (MAC Address Duplicate Key)
    if (insertError) {
      if (insertError.code === '23505') { // Kode unik violation di PostgreSQL
        throw new Error("Alat ini sudah diklaim dan terdaftar di sistem.")
      }
      throw insertError
    }

    // 5. Berikan respons sukses ke Flutter
    return new Response(
      JSON.stringify({ status: "success", message: "Alat berhasil didaftarkan!", data: data }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ status: "error", message: (error as any).message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    )
  }
})