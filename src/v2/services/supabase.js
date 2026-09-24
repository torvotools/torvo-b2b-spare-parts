import {createClient} from '@supabase/supabase-js';
const url=import.meta.env.VITE_SUPABASE_URL;
const key=import.meta.env.VITE_SUPABASE_ANON_KEY;
export const backendConfigured=Boolean(url&&key);
const authStorage={getItem:key=>sessionStorage.getItem(key)??localStorage.getItem(key),setItem:(key,value)=>sessionStorage.setItem(key,value),removeItem:key=>{sessionStorage.removeItem(key);localStorage.removeItem(key)}};
export const supabase=backendConfigured?createClient(url,key,{auth:{persistSession:true,autoRefreshToken:true,storage:authStorage}}):null;
export function requireBackend(){if(!supabase)throw new Error('TORVO backend is not configured. Add VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY in deployment secrets.');return supabase;}
