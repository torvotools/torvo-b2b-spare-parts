/* TORVO V27 SAFE DATA ADAPTER - READ FIRST, NO STOCK MUTATION */
(function(){'use strict';
function arr(x){return Array.isArray(x)?x:[]}
function num(x){x=Number(x);return isFinite(x)?x:0}
function readLegacy(){
 var candidates=['TORVO_DB','torvoDB','DB','TORVO_ADMIN_DB'];
 for(var i=0;i<candidates.length;i++){
  try{var raw=localStorage.getItem(candidates[i]);if(raw){var d=JSON.parse(raw);if(d&&typeof d==='object')return d}}catch(e){}
 }
 if(window.DB&&typeof window.DB==='object')return window.DB;
 return {};
}
function data(){var d=readLegacy();return {
 raw:d,
 items:arr(d.items),machines:arr(d.machines),dealers:arr(d.dealers||d.customers),orders:arr(d.orders),estimates:arr(d.estimates),requests:arr(d.requests||d.dealerRequests),messages:arr(d.messages),employees:arr(d.employees)
}}
function status(x){return String((x&&x.status)||'').toUpperCase()}
function saleValue(e){return num(e&&((e.total!=null&&e.total)||(e.amount!=null&&e.amount)||(e.grandTotal!=null&&e.grandTotal))) }
function stockOf(x){return num(x&&((x.stock!=null&&x.stock)||(x.qty!=null&&x.qty)||(x.quantity!=null&&x.quantity))) }
function esc(s){return String(s==null?'':s).replace(/[&<>"']/g,function(c){return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]})}
function setText(sel,v){var e=document.querySelector(sel);if(e)e.textContent=v}
function money(v){try{return '₹'+num(v).toLocaleString('en-IN')}catch(e){return '₹'+num(v)}}
function dashboard(){var d=data();var sales=d.estimates.filter(function(x){var s=status(x);return s.indexOf('DELIVER')>=0||s.indexOf('FINAL')>=0||s.indexOf('PAID')>=0}).reduce(function(a,x){return a+saleValue(x)},0);
 setText('[data-kpi="dealers"]',d.dealers.length);setText('[data-kpi="products"]',d.items.length);setText('[data-kpi="orders"]',d.orders.length);setText('[data-kpi="estimates"]',d.estimates.length);setText('[data-kpi="sales"]',money(sales));
 return {dealers:d.dealers.length,products:d.items.length,orders:d.orders.length,estimates:d.estimates.length,sales:sales};}
function rows(kind){var d=data(),a=[];
 if(kind==='products')a=d.items.map(function(x){return [x.no||x.itemNo,x.name||x.productName,x.brand,x.category,x.originalFor||'',x.suitableFor||'',stockOf(x),x.status||'ACTIVE']});
 if(kind==='machines')a=d.machines.map(function(x){return [x.brand,x.type||x.machineType,x.work||x.workType,x.model,x.originalParts||'',x.suitableParts||'',x.status||'ACTIVE']});
 if(kind==='dealers')a=d.dealers.map(function(x){return [x.code||x.dealerCode,x.shopName||x.name,x.mobile||x.phone,x.city,x.rateGroup||x.rate,x.status]});
 if(kind==='orders')a=d.orders.map(function(x){return [x.no||x.orderNo,x.date,x.dealerName||x.dealer,x.items?arr(x.items).length:'',saleValue(x),x.status]});
 if(kind==='estimates')a=d.estimates.map(function(x){return [x.no||x.estimateNo,x.dealerName||x.dealer,saleValue(x),x.paymentStatus||x.payment,x.deliveryStatus||x.delivery,x.status]});
 return a;
}
function renderTable(tbody,kind,cols){var e=typeof tbody==='string'?document.querySelector(tbody):tbody;if(!e)return;var a=rows(kind);if(!a.length){e.innerHTML='<tr><td colspan="'+cols+'">NO DATA</td></tr>';return}e.innerHTML=a.map(function(r){return '<tr>'+r.map(function(v){return '<td>'+esc(v)+'</td>'}).join('')+'</tr>'}).join('')}
function canDeliverEstimate(e){if(!e)return false;var p=String(e.paymentStatus||e.payment||'').toUpperCase();var delivered=!!(e.stockDeducted||e.deliveryStockDeducted)||String(e.deliveryStatus||'').toUpperCase()==='DELIVERED';return p==='RECEIVED'&&!delivered}
window.TorvoV27Data={read:data,dashboard:dashboard,rows:rows,renderTable:renderTable,canDeliverEstimate:canDeliverEstimate,stockOf:stockOf};
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',dashboard);else dashboard();
})();