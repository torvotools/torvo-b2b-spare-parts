/* TORVO V27 — ISOLATED DASHBOARD POLISH. DOES NOT CHANGE APPROVED HEADER/FILTERS/PROFILE. */
(function(){'use strict';
function boot(){
 var dash=document.querySelector('.dashboard'), date=document.getElementById('torvoDateRow');
 if(!dash||!date)return;
 var style=document.getElementById('torvoDashboardPolishStyle');
 if(!style){style=document.createElement('style');style.id='torvoDashboardPolishStyle';style.textContent=`
 .torvoDateRow{display:grid!important;grid-template-columns:minmax(220px,1fr) auto auto auto!important;align-items:end!important;gap:8px!important}
 .torvoDashTitle{height:50px;min-width:0;border:1px solid #d7dee7;border-left:5px solid #e20b20;border-radius:8px;background:#fff;display:flex;align-items:center;padding:0 18px;font-size:18px;font-weight:950;letter-spacing:.4px;color:#111;box-shadow:0 2px 8px rgba(15,34,56,.05)}
 .dashboard .kpis{display:grid!important;grid-template-columns:repeat(auto-fit,minmax(118px,1fr))!important;gap:10px!important;align-items:stretch!important}
 .dashboard .kpi{width:100%!important;min-width:0!important;min-height:0!important;aspect-ratio:1/1!important;max-height:150px!important;padding:9px 6px!important;border-radius:13px!important;display:flex!important;flex-direction:column!important;align-items:center!important;justify-content:center!important;text-align:center!important;overflow:hidden!important;box-sizing:border-box!important}
 .dashboard .kpi .kicon{width:38px!important;height:38px!important;min-height:38px!important;margin:0 auto 5px!important;border-radius:10px!important;display:grid!important;place-items:center!important;font-size:20px!important}
 .dashboard .kpi span,.dashboard .kpi small{font-size:9px!important;font-weight:900!important;line-height:1.15!important;white-space:normal!important;overflow-wrap:anywhere!important}
 .dashboard .kpi b{font-size:17px!important;line-height:1.05!important;margin:3px 0!important;white-space:nowrap!important}
 .dashboard .kpi:nth-child(5n+1){background:#fff0f0!important}.dashboard .kpi:nth-child(5n+2){background:#effff5!important}.dashboard .kpi:nth-child(5n+3){background:#fff8e5!important}.dashboard .kpi:nth-child(5n+4){background:#eef5ff!important}.dashboard .kpi:nth-child(5n){background:#f6f0ff!important}
 @media(max-width:1100px){.dashboard .kpis{grid-template-columns:repeat(auto-fit,minmax(108px,1fr))!important}.dashboard .kpi{max-height:135px!important}.torvoDashTitle{font-size:16px}}
 @media(max-width:760px){.torvoDateRow{min-width:0!important;grid-template-columns:1fr 1fr!important;padding:7px 9px!important}.torvoDashTitle{grid-column:1/-1!important;height:42px!important;font-size:15px!important}.torvoDateField{width:auto!important;min-width:0!important}.torvoDateSubmit{grid-column:2!important;justify-self:end!important}.dashboard{min-width:0!important}.dashboard .kpis{grid-template-columns:repeat(2,minmax(0,1fr))!important;gap:8px!important}.dashboard .kpi{aspect-ratio:auto!important;min-height:108px!important;max-height:none!important}.dashboard .charts,.dashboard .tables{grid-template-columns:1fr!important}.dashboard .panel{min-width:0!important;overflow:auto!important}}
 @media(min-width:761px) and (max-width:980px){.dashboard .kpis{grid-template-columns:repeat(4,minmax(0,1fr))!important}}
 `;document.head.appendChild(style)}
 if(!date.querySelector('.torvoDashTitle')){var title=document.createElement('div');title.className='torvoDashTitle';title.textContent='DASHBOARD REPORT';date.insertBefore(title,date.firstChild)}
 var kpis=dash.querySelector('.kpis');
 if(kpis&&!kpis.dataset.torvoReports){
   kpis.dataset.torvoReports='1';
   var reports=[['TOTAL ORDERS','0','▣'],['CONFIRMED ORDERS','0','✓'],['PENDING ORDERS','0','⌛'],['TOTAL SALES','₹0','₹'],['TOTAL PROFIT','₹0','↗'],['NEW DEALER INQUIRIES','0','♙'],['APPROVED DEALERS','0','✓'],['NEW MESSAGES','0','✉'],['NON-AVAILABLE REQUESTS','0','!'],['LOW STOCK ITEMS','0','▤'],['ESTIMATES','0','≡'],['SALES ORDERS','0','▦'],['DELIVERY PENDING','0','⇥'],['PAYMENT PENDING','₹0','₹'],['TOTAL PRODUCTS','0','□']];
   kpis.innerHTML=reports.map(function(r){return '<div class="kpi"><div class="kicon">'+r[2]+'</div><span>'+r[0]+'</span><b>'+r[1]+'</b><small>NO DATA</small></div>'}).join('');
 }
}
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',function(){setTimeout(boot,0)});else setTimeout(boot,0);
})();