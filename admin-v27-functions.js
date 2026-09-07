/* TORVO ADMIN V27 CLEAN CLOUD FUNCTION BRIDGE */
(function(){
'use strict';
var ROUTES={
'DASHBOARD':'dashboard','DEALERS':'market','ADD PRODUCT':'additem','SPARE PARTS':'itemmaster','MACHINES':'machine','ACCESSORIES':'accessories','ORDERS':'orders','QUOTATION':'quotation','SALES ORDER':'salesorder','ESTIMATES':'estimates','REPORTS':'reports','REQUESTS':'requests','MESSAGES':'messages','SCHEMES':'schemes','SETTINGS':'settings','EMPLOYEES':'employeeAccess','BACKUP & LOGS':'recycle','HELP & SUPPORT':'help'};
function legacySection(id){return document.getElementById(id)}
function safeShow(id){
 var el=legacySection(id);
 if(!el)return false;
 if(typeof window.showSection==='function'){window.showSection(id);return true}
 document.querySelectorAll('.section').forEach(function(x){x.classList.remove('active')});
 el.classList.add('active');return true;
}
window.TorvoV27={
 route:function(label){
  label=(label||'').trim().toUpperCase();
  if(label==='BRANDS'){if(typeof window.openBrandMaster==='function'){window.openBrandMaster();return true}return safeShow('brands')}
  if(label==='CATEGORIES'){if(typeof window.openCategoryMaster==='function'){window.openCategoryMaster();return true}return safeShow('categories')}
  if(label==='LOGOUT'){
   if(typeof window.logoutAdmin==='function'){window.logoutAdmin();return true}
   if(typeof window.adminLogout==='function'){window.adminLogout();return true}
   return false;
  }
  return safeShow(ROUTES[label]);
 },
 addSpare:function(){return safeShow('additem')},
 addAccessory:function(){return safeShow('additem')},
 addMachine:function(){return safeShow('machine')},
 dealers:function(){return safeShow('market')},
 orders:function(){return safeShow('orders')},
 reports:function(){return safeShow('reports')}
};
})();
