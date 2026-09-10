/* TORVO V27 — SIDEBAR APP-STYLE VISUAL ONLY */
(function(){'use strict';
function run(){
 var side=document.querySelector('.side'); if(!side)return;
 var st=document.getElementById('torvoSidebarAppStyle'); if(st)st.remove();
 st=document.createElement('style'); st.id='torvoSidebarAppStyle'; st.textContent=`
 :root{--torvo-side-width:242px}
 .side{width:var(--torvo-side-width)!important;min-width:var(--torvo-side-width)!important;background:#fff!important;color:#111827!important;border-right:1px solid #cbd5e1!important}
 .main,.app,.shell{--sideW:var(--torvo-side-width)}
 .side .nav,.side nav{background:#fff!important}
 .side .nav>button,.side nav>button,.side .nav .navItem,.side nav .navItem{color:#111827!important;background:#fff!important;border-bottom:1px solid #aeb8c5!important;font-size:11px!important;font-weight:700!important;letter-spacing:.05px!important}
 .side .nav>button:hover,.side nav>button:hover,.side .nav .navItem:hover,.side nav .navItem:hover{background:#f8fafc!important}
 .side .nav>button.active,.side nav>button.active,.side .nav .navItem.active,.side nav .navItem.active{background:#e20b20!important;color:#fff!important;border-bottom-color:#c80a1c!important}
 .side .ico,.side .icon,.side [class*="navIcon"]{width:30px!important;height:30px!important;min-width:30px!important;border-radius:8px!important;display:inline-grid!important;place-items:center!important;color:#fff!important;box-shadow:0 1px 2px rgba(15,23,42,.12)!important;font-size:16px!important;font-weight:900!important}
 .side .ico svg,.side .icon svg,.side [class*="navIcon"] svg{width:17px!important;height:17px!important;stroke:#fff!important;fill:none!important;stroke-width:2!important}
 .side .nav>button:nth-child(8n+1) .ico,.side nav>button:nth-child(8n+1) .ico{background:#1485e8!important}
 .side .nav>button:nth-child(8n+2) .ico,.side nav>button:nth-child(8n+2) .ico{background:#6d5ce7!important}
 .side .nav>button:nth-child(8n+3) .ico,.side nav>button:nth-child(8n+3) .ico{background:#ec3971!important}
 .side .nav>button:nth-child(8n+4) .ico,.side nav>button:nth-child(8n+4) .ico{background:#10a7bd!important}
 .side .nav>button:nth-child(8n+5) .ico,.side nav>button:nth-child(8n+5) .ico{background:#f0a51a!important}
 .side .nav>button:nth-child(8n+6) .ico,.side nav>button:nth-child(8n+6) .ico{background:#5669df!important}
 .side .nav>button:nth-child(8n+7) .ico,.side nav>button:nth-child(8n+7) .ico{background:#13a36d!important}
 .side .nav>button:nth-child(8n) .ico,.side nav>button:nth-child(8n) .ico{background:#e20b20!important}
 .side .nav>button.active .ico,.side nav>button.active .ico{background:#1485e8!important}
 `; document.head.appendChild(st);
 var buttons=side.querySelectorAll('button');
 buttons.forEach(function(b){
   var text=(b.textContent||'').trim().toUpperCase();
   if(text==='DASHBOARD'){
     var ic=b.querySelector('.ico,.icon,[class*="navIcon"]');
     if(ic)ic.innerHTML='<svg viewBox="0 0 24 24" aria-hidden="true"><rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/><rect x="14" y="14" width="7" height="7" rx="1.5"/></svg>';
   }
 });
}
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',run);else run();
})();