/* TORVO V27 — HOME SEARCH BAR MATCH */
(function(){'use strict';
function boot(){
 var css=document.createElement('style');
 css.textContent='.searchWrap{overflow:visible!important;padding:0!important}.search{height:52px!important;border:2px solid #d8dbe0!important;border-radius:15px!important;overflow:hidden!important;background:#fff!important;box-shadow:none!important;display:flex!important;align-items:center!important}.search:focus-within{border-color:#b9bec6!important;box-shadow:none!important}.search input{height:48px!important;flex:1!important;min-width:0!important;border:0!important;outline:0!important;background:#fff!important;padding:0 13px!important;font-size:13px!important}.sicon{width:48px!important;height:48px!important;flex:0 0 48px!important;border:0!important;border-left:1px solid #e5e7eb!important;background:#fff!important;padding:0!important;display:grid!important;place-items:center!important}.sicon:hover{background:#f5f5f5!important}.sicon svg{display:block!important;width:23px!important;height:23px!important}.torvoSuggest,.suggest{top:54px!important;left:0!important;right:0!important;border-radius:0 0 15px 15px!important}';
 document.head.appendChild(css);
 var cam=document.querySelector('.sicon.camera'),mic=document.querySelector('.sicon.mic'),sea=document.querySelector('.sicon.glass');
 if(cam)cam.innerHTML='<svg viewBox="0 0 24 24" aria-hidden="true"><path fill="#1689e8" d="M9 4.5 10.2 3h3.6L15 4.5h3.5A2.5 2.5 0 0 1 21 7v10.5a2.5 2.5 0 0 1-2.5 2.5h-13A2.5 2.5 0 0 1 3 17.5V7a2.5 2.5 0 0 1 2.5-2.5H9Zm3 3.2a5.1 5.1 0 1 0 0 10.2 5.1 5.1 0 0 0 0-10.2Zm0 2.1a3 3 0 1 1 0 6 3 3 0 0 1 0-6Z"/><circle cx="18" cy="8" r="1.15" fill="#34a853"/></svg>';
 if(mic)mic.innerHTML='<svg viewBox="0 0 24 24" aria-hidden="true"><path fill="#4285f4" d="M12 2a3 3 0 0 0-3 3v6a3 3 0 0 0 6 0V5a3 3 0 0 0-3-3Z"/><path fill="#34a853" d="M6 10.5h2A4 4 0 0 0 12 15v2a6 6 0 0 1-6-6.5Z"/><path fill="#fbbc05" d="M12 17v2H9v2h6v-2h-3v-2Z"/><path fill="#ea4335" d="M16 10.5h2A6 6 0 0 1 12 17v-2a4 4 0 0 0 4-4.5Z"/></svg>';
 if(sea)sea.innerHTML='<svg viewBox="0 0 24 24" aria-hidden="true"><path fill="#1689e8" d="M10.5 3a7.5 7.5 0 1 0 4.72 13.33l4.22 4.22 1.41-1.41-4.22-4.22A7.5 7.5 0 0 0 10.5 3Zm0 2a5.5 5.5 0 1 1 0 11 5.5 5.5 0 0 1 0-11Z"/></svg>';
 }
 if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',boot);else boot();
})();