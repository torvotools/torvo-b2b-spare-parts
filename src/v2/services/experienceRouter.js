import{EXPERIENCE,ROLE_EXPERIENCE}from'../config/modules.js';

const MOBILE_BREAKPOINT=1024;

export function experienceForAppUser(appUser){
 if(!appUser||appUser.active!==true)return null;
 return ROLE_EXPERIENCE[appUser.role]||null;
}

export function isSecureDesktopRole(appUser){return experienceForAppUser(appUser)===EXPERIENCE.SECURE_DESKTOP}
export function isOperationalAppRole(appUser){return experienceForAppUser(appUser)===EXPERIENCE.OPERATIONAL_APP}
export function desktopViewportAllowed(){return typeof window==='undefined'||window.innerWidth>=MOBILE_BREAKPOINT}

export function authorizedLanding(appUser){
 const experience=experienceForAppUser(appUser);
 if(!experience)return{experience:null,allowed:false,reason:'PRIVATE ACCESS IS NOT AVAILABLE FOR THIS ACCOUNT'};
 if(experience===EXPERIENCE.SECURE_DESKTOP&&!desktopViewportAllowed())return{experience,allowed:false,reason:'ADMIN ACCESS REQUIRES DESKTOP / LAPTOP'};
 return{experience,allowed:true,reason:''};
}
