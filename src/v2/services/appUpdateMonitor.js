import{loadPublicAndroidUpdate,publicAndroidUpdateState,currentAndroidBuild}from'./appRelease';
const EVENT='torvo:app-update-state';let timer=null;
export async function checkTorvoAppUpdate(){const release=await loadPublicAndroidUpdate(),state=publicAndroidUpdateState(release,currentAndroidBuild());if(typeof window!=='undefined')window.dispatchEvent(new CustomEvent(EVENT,{detail:state}));return state}
export function startTorvoAppUpdateMonitor({intervalMs=6*60*60*1000}={}){if(typeof window==='undefined')return()=>{};stopTorvoAppUpdateMonitor();const run=()=>checkTorvoAppUpdate().catch(()=>null);run();const onFocus=()=>run(),onVisible=()=>{if(document.visibilityState==='visible')run()};window.addEventListener('focus',onFocus);document.addEventListener('visibilitychange',onVisible);timer=window.setInterval(run,Math.max(Number(intervalMs)||0,60*60*1000));return()=>{window.removeEventListener('focus',onFocus);document.removeEventListener('visibilitychange',onVisible);stopTorvoAppUpdateMonitor()}}
export function stopTorvoAppUpdateMonitor(){if(timer&&typeof window!=='undefined')window.clearInterval(timer);timer=null}
export const TORVO_APP_UPDATE_EVENT=EVENT;
