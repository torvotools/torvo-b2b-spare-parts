import{backendConfigured,requireBackend,supabase}from'./supabase';
export async function currentSession(){if(!backendConfigured)return null;const{data,error}=await supabase.auth.getSession();if(error)throw error;return data.session}
export async function currentAppUser(){const client=requireBackend();const{data:{user},error:uerr}=await client.auth.getUser();if(uerr)throw uerr;if(!user)return null;const{data,error}=await client.from('app_users').select('id,auth_user_id,full_name,mobile,role,active').eq('auth_user_id',user.id).maybeSingle();if(error)throw error;return data}
export function onAuthChange(callback){if(!supabase)return()=>{};const{data}=supabase.auth.onAuthStateChange(()=>callback());return()=>data.subscription.unsubscribe()}
export async function signOut(){if(!supabase)return;const{error}=await supabase.auth.signOut();if(error)throw error}
