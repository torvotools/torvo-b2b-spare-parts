/* TORVO V27 SEARCH BAR FINAL FIX */
(function(){'use strict';
function boot(){
 var css=document.createElement('style');
 css.textContent='.searchWrap{overflow:visible!important;padding:2px!important}.search{position:relative!important;overflow:visible!important;height:44px!important;border:2px solid #8f99a6!important;border-radius:12px!important;background:#fff!important;box-shadow:0 0 0 1px rgba(20,30,45,.04)!important}.search:focus-within{border-color:#667281!important;box-shadow:0 0 0 2px rgba(102,114,129,.10)!important}.search input{height:40px!important;border:0!important;outline:0!important;background:transparent!important;padding:0 12px!important}.sicon{width:42px!important;height:40px!important;border:0!important;background:transparent!important;padding:0!important;display:grid!important;place-items:center!important}.sicon svg{display:block!important;width:24px!important;height:24px!important}.camera svg{fill:#1689e8!important}.mic svg{fill:#16a765!important}.glass svg{fill:#1689e8!important}.torvoSuggest{top:46px!important;left:0!important;right:0!important}';
 document.head.appendChild(css);
 var cam=document.querySelector('.sicon.camera'),mic=document.querySelector('.sicon.mic'),sea=document.querySelector('.sicon.glass');
 if(cam)cam.innerHTML='<svg viewBox="0 0 24 24" aria-hidden="true"><path fill="#1689e8" d="M9 4.5 10.2 3h3.6L15 4.5h3.5A2.5 2.5 0 0 1 21 7v10.5a2.5 2.5 0 0 1-2.5 2.5h-13A2.5 2.5 0 0 1 3 17.5V7a2.5 2.5 0 0 1 2.5-2.5H9Zm3 3.2a5.1 5.1 0 1 0 0 10.2 5.1 5.1 0 0 0 0-10.2Zm0 2.1a3 3 0 1 1 0 6 3 3 0 0 1 0-6Z"/><circle cx="18" cy="8" r="1.15" fill="#34a853"/></svg>';
 if(mic)mic.innerHTML='<svg viewBox="0 0 24 24" aria-hidden="true"><path fill="#4285f4" d="M12 2a3 3 0 0 0-3 3v6a3 3 0 0 0 6 0V5a3 3 0 0 0-3-3Z"/><path fill="#34a853" d="M6 10.5h2A4 4 0 0 0 12 15v2a6 6 0 0 1-6-6.5Z"/><path fill="#fbbc05" d="M12 17v2H9v2h6v-2h-3v-2Z"/><path fill="#ea4335" d="M16 10.5h2A6 6 0 0 1 12 17v-2a4 4 0 0 0 4-4.5Z"/></svg>';
 if(sea)sea.innerHTML='<svg viewBox="0 0 24 24" aria-hidden="true"><path fill="#4285f4" d="M10.5 3a7.5 7.5 0 1 0 4.72 13.33l4.22 4.22 1.41-1.41-4.22-4.22A7.5 7.5 0 0 0 10.5 3Zm0 2a5.5 5.5 0 1 1 0 11 5.5 5.5 0 0 1 0-11Z"/><path fill="#34a853" d="M15.3 14.9 21 20.6 19.6 22l-5.7-5.7Z"/></svg>';
 }
 if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',boot);else boot();
})();