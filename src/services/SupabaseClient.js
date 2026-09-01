import { createClient } from '@supabase/supabase-js';

const URL = import.meta.env.VITE_SUPABASE_URL || '';
const KEY = import.meta.env.VITE_SUPABASE_ANON_KEY || '';
const configured = /^https:\/\/[a-z0-9-]+\.supabase\.co\/?$/.test(URL) && KEY.length > 20;

let client = null;

export const SupabaseClient = {
  isConfigured: () => configured,
  getClient() {
    if (!configured) return null;
    if (!client) {
      client = createClient(URL, KEY, {
        auth: { persistSession: true, autoRefreshToken: true },
        global: { headers: { 'x-client-info': 'wave-dash/2.0.0' } }
      });
    }
    return client;
  },
  async getOwnerUid() {
    const c = this.getClient();
    if (!c) return null;
    try {
      const { data } = await c.auth.getSession();
      return data?.session?.user?.id ?? null;
    } catch { return null; }
  }
};
