import{Capacitor}from'@capacitor/core';
export function isNativeApp(){try{return Capacitor.isNativePlatform()}catch{return false}}
export function isWebRuntime(){return !isNativeApp()}
export function dealerAppRuntimeAllowed(){return isNativeApp()}
export function dealerAppOnlyReason(){return 'DEALER ACCESS IS AVAILABLE ONLY IN THE TORVO TOOLS APP.'}
