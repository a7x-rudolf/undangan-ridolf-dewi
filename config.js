// ISI SETELAH BUAT PROJECT SUPABASE
const SUPABASE_URL = "https://ymkstumlteheublynygl.supabase.co";
const SUPABASE_KEY = "sb_publishable_xplB2HZgy-3pogy9DPNpPQ_AfKmhzqr";
const MAPS_URL = "https://maps.app.goo.gl/VYx9EsycBuDakftm7";
async function rpc(fn, args = {}) {
  const r = await fetch(`${SUPABASE_URL}/rest/v1/rpc/${fn}`, {
    method: "POST",
    headers: { apikey: SUPABASE_KEY, ...(SUPABASE_KEY.startsWith("eyJ") ? { Authorization: `Bearer ${SUPABASE_KEY}` } : {}), "Content-Type": "application/json" },
    body: JSON.stringify(args)
  });
  if (!r.ok) throw new Error(await r.text());
  return r.json();
}
