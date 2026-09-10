/* TORVO V27 — APPROVED SIDEBAR ONLY: WHITE + BLACK TEXT + APP ICONS */
(function(){'use strict';
function applySidebar(){
  var side=document.querySelector('.side'); if(!side)return;
  var old=document.getElementById('torvoSidebarOnlyStyle'); if(old)old.remove();
  var st=document.createElement('style'); st.id='torvoSidebarOnlyStyle'; st.textContent=`
  .side{background:#fff!important;color:#111827!important;border-right:1px solid #dfe6ee!important}
  .side .brandName,.side .brandSub{color:#111827!important}
  .side .nav{color:#111827!important;font-weight:850!important;background:#fff!important;border-bottom:1px solid #edf1f5!important}
  .side .nav:hover{background:#f7f9fc!important}
  .side .nav.active{background:#e20b20!important;color:#fff!important;border-bottom-color:#e20b20!important}
  .side .nav .arrow{color:inherit!important}
  .side .ni{width:28px!important;height:28px!important;min-width:28px!important;border-radius:7px!important;display:grid!important;place-items:center!important;color:#fff!important;font-size:16px!important;line-height:1!important;font-weight:900!important}
  .side .nav:nth-of-type(1) .ni{background:#ef233c!important}.side .nav:nth-of-type(2) .ni{background:#1687f8!important}.side .nav:nth-of-type(3) .ni{background:#7c3aed!important}.side .nav:nth-of-type(4) .ni{background:#ef476f!important}.side .nav:nth-of-type(5) .ni{background:#1687f8!important}.side .nav:nth-of-type(6) .ni{background:#12a594!important}.side .nav:nth-of-type(7) .ni{background:#ff8a00!important}.side .nav:nth-of-type(8) .ni{background:#8b5cf6!important}.side .nav:nth-of-type(9) .ni{background:#00a86b!important}.side .nav:nth-of-type(10) .ni{background:#f43f5e!important}.side .nav:nth-of-type(11) .ni{background:#1687f8!important}.side .nav:nth-of-type(12) .ni{background:#f59e0b!important}.side .nav:nth-of-type(13) .ni{background:#ec4899!important}.side .nav:nth-of-type(14) .ni{background:#8b5cf6!important}.side .nav:nth-of-type(15) .ni{background:#0ea5e9!important}.side .nav:nth-of-type(16) .ni{background:#64748b!important}
  .side .subnav .nav{background:#fff!important;color:#111827!important;border-bottom:1px solid #f1f4f7!important}.side .subnav .nav:hover{background:#f7f9fc!important}
  `; document.head.appendChild(st);
  var map={
    dashboard:'⌂',dealers:'♟','add-spare-part':'＋','spare-parts':'⚙',machines:'⚒',accessories:'🔧',brands:'◆',categories:'▦',orders:'▤','sales-order':'🛒',estimates:'▥',reports:'▥',requests:'?',messages:'✉',schemes:'🎁',employees:'♟',backup:'☁',settings:'⚙',logout:'↪'
  };
  side.querySelectorAll('.nav').forEach(function(n){var i=n.querySelector('.ni');if(!i)return;var key=n.dataset.go||'';if(n.id==='productMaster')key='products';var icons={products:'◆'};i.textContent=map[key]||icons[key]||i.textContent});
}
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',applySidebar);else applySidebar();
})();