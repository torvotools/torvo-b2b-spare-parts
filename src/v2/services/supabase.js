import {createClient} from '@supabase/supabase-js';
const url=import.meta.env.VITE_SUPABASE_URL;
const key=import.meta.env.VITE_SUPABASE_ANON_KEY;
export const backendConfigured=Boolean(url&&key);
export const supabase=backendConfigured?createClient(url,key,{auth:{persistSession:true,autoRefreshToken:true}}):null;
export function requireBackend(){if(!supabase)throw new Error('TORVO backend is not configured. Add VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY in deployment secrets.');return supabase;}
