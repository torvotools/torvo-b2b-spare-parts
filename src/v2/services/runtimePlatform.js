import{Capacitor}from'@capacitor/core';
export const APP_ONLY_ROLES=Object.freeze(['dealer','salesman','store_keeper']);
export const WEB_BUSINESS_ROLES=Object.freeze(['owner','admin','accountant']);
export function isNativeApp(){try{return Capacitor.isNativePlatform()}catch{return false}}
export function isWebRuntime(){return !isNativeApp()}
export function dealerAppRuntimeAllowed(){return isNativeApp()}
export function operationalAppRuntimeAllowed(){return isNativeApp()}
export function roleRuntimeAllowed(role){const r=String(role||'').toLowerCase();if(APP_ONLY_ROLES.includes(r))return isNativeApp();if(WEB_BUSINESS_ROLES.includes(r))return isWebRuntime();return false}
export function dealerAppOnlyReason(){return 'DEALER ACCESS IS AVAILABLE ONLY IN THE TORVO TOOLS APP.'}
export function operationalAppOnlyReason(role){return `${String(role||'BUSINESS USER').replace('_',' ').toUpperCase()} ACCESS IS AVAILABLE ONLY IN THE TORVO TOOLS APP.`}
export function webBusinessOnlyReason(role){return `${String(role||'BUSINESS USER').replace('_',' ').toUpperCase()} ACCESS IS AVAILABLE THROUGH SECURE BUSINESS USE ON THE WEBSITE.`}
