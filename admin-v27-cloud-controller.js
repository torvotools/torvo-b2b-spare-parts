/* TORVO V27 CLOUD CONTROLLER - NO POLLING / NO OBSERVERS */
(function(){'use strict';
var KEY='TORVO_V27_SECTION';
var map={
'DASHBOARD':'dashboard','DEALERS':'dealers','ADD PRODUCT':'add-spare-part','SPARE PARTS':'products','MACHINES':'machines','ACCESSORIES':'products','BRANDS':'masters','CATEGORIES':'masters','ORDERS':'orders','QUOTATION':'quotation','SALES ORDER':'sales','ESTIMATES':'estimates','REPORTS':'reports','REQUESTS':'requests','MESSAGES':'messages','SCHEMES':'schemes','SETTINGS':'settings','EMPLOYEES':'employees','BACKUP & LOGS':'backup','HELP & SUPPORT':'help'};
function U(s){return String(s||'').trim().toUpperCase()}
function saveSection(s){try{localStorage.setItem(KEY,s)}catch(e){}}
function saved(){try{return localStorage.getItem(KEY)||'dashboard'}catch(e){return 'dashboard'}}
function activeNav(label){document.querySelectorAll('.side .nav').forEach(function(n){n.classList.toggle('active',U(n.textContent)===U(label))})}
function show(id,label){
 var root=document.querySelector('.content');if(!root)return false;
 var target=document.querySelector('[data-v27-screen="'+id+'"]');
 if(target){document.querySelectorAll('[data-v27-screen]').forEach(function(x){x.hidden=true});target.hidden=false;saveSection(id);activeNav(label||id);if(window.TorvoV27Data&&window.TorvoV27Data.dashboard)window.TorvoV27Data.dashboard();return true}
 return false;
}
function nav(label){var u=U(label);if(u==='LOGOUT'){if(window.TorvoV27&&window.TorvoV27.route)return window.TorvoV27.route('LOGOUT');return false}return show(map[u]||'dashboard',u)}
function bindNav(){document.querySelectorAll('.side .nav').forEach(function(n){n.addEventListener('click',function(){nav(n.textContent)})})}
function bindEnter(){document.addEventListener('keydown',function(e){if(e.key!=='Enter'||e.shiftKey||e.ctrlKey||e.altKey)return;var t=e.target;if(!t||!(/^(INPUT|SELECT)$/.test(t.tagName)))return;var scope=t.closest('.v27longform,.v27module,.m')||document;var list=[].slice.call(scope.querySelectorAll('input:not([type="hidden"]):not([disabled]),select:not([disabled]),textarea:not([disabled]),button:not([disabled])')).filter(function(x){return x.offsetParent!==null});var i=list.indexOf(t);if(i>=0&&i<list.length-1){e.preventDefault();list[i+1].focus()}})}
function formatDate(v){if(!v)return '';var d=new Date(v);if(isNaN(d))return String(v);return String(d.getDate()).padStart(2,'0')+'/'+String(d.getMonth()+1).padStart(2,'0')+'/'+d.getFullYear()}
function boot(){bindNav();bindEnter();var id=saved();if(!show(id,id))show('dashboard','DASHBOARD')}
window.TorvoV27Cloud={show:show,nav:nav,saved:saved,formatDate:formatDate};
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',boot);else boot();
})();