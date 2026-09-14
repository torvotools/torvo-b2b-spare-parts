import{EXPERIENCE,ROLE_EXPERIENCE}from'../config/modules.js';
import{roleRuntimeAllowed,operationalAppOnlyReason,webBusinessOnlyReason}from'./runtimePlatform.js';
const MOBILE_BREAKPOINT=1024;
export function experienceForAppUser(appUser){if(!appUser||appUser.active!==true)return null;return ROLE_EXPERIENCE[appUser.role]||null}
export function isSecureDesktopRole(appUser){return experienceForAppUser(appUser)===EXPERIENCE.SECURE_DESKTOP}
export function isOperationalAppRole(appUser){return experienceForAppUser(appUser)===EXPERIENCE.OPERATIONAL_APP}
export function desktopViewportAllowed(){return typeof window==='undefined'||window.innerWidth>=MOBILE_BREAKPOINT}
export function isMobileViewport(){return typeof window!=='undefined'&&window.innerWidth<MOBILE_BREAKPOINT}
export function authorizedLanding(appUser){const primary=experienceForAppUser(appUser);if(!primary)return{experience:null,allowed:false,reason:'PRIVATE ACCESS IS NOT AVAILABLE FOR THIS ACCOUNT'};if(!roleRuntimeAllowed(appUser.role)){const appOnly=['dealer','salesman','store_keeper'].includes(appUser.role);return{experience:primary,allowed:false,reason:appOnly?operationalAppOnlyReason(appUser.role):webBusinessOnlyReason(appUser.role)}}if(appUser.role==='admin'&&isMobileViewport())return{experience:EXPERIENCE.ADMIN_MOBILE_APP,allowed:true,reason:''};if(appUser.role==='accountant'&&isMobileViewport())return{experience:primary,allowed:true,reason:''};if(primary===EXPERIENCE.SECURE_DESKTOP&&!desktopViewportAllowed())return{experience:primary,allowed:false,reason:'SECURE DESKTOP ACCESS REQUIRES DESKTOP / LAPTOP'};return{experience:primary,allowed:true,reason:''}}
export function customerPublicExperience(){return EXPERIENCE.CUSTOMER_APP}
