/* TORVO V27 PROTECTED TRANSACTION ENGINE */
(function(){'use strict';
function A(x){return Array.isArray(x)?x:[]}
function N(x){x=Number(x);return isFinite(x)?x:0}
function U(x){return String(x==null?'':x).trim().toUpperCase()}
function clone(x){return JSON.parse(JSON.stringify(x))}
function db(){return window.DB&&typeof window.DB==='object'?window.DB:null}
function save(){if(typeof window.saveDB==='function'){window.saveDB();return true}return false}
function findEstimate(ref){var d=db();if(!d)return null;var list=A(d.estimates);if(typeof ref==='number')return list[ref]||null;return list.find(function(x){return U(x.no||x.estimateNo||x.id)===U(ref)})||null}
function itemNo(line){return U(line&& (line.itemNo||line.no||line.code))}
function itemQty(line){return N(line&& (line.qty||line.quantity||line.pcs))}
function stockKey(item){if(item.stock!=null)return 'stock';if(item.qty!=null)return 'qty';if(item.quantity!=null)return 'quantity';return 'stock'}
function validateDelivery(est){
 if(!est)return {ok:false,message:'ESTIMATE NOT FOUND'};
 if(U(est.paymentStatus||est.payment)!=='RECEIVED')return {ok:false,message:'PAYMENT RECEIVED REQUIRED BEFORE DELIVERY'};
 if(est.stockDeducted||est.deliveryStockDeducted||U(est.deliveryStatus)==='DELIVERED')return {ok:false,message:'DELIVERY / STOCK ALREADY COMPLETED'};
 var d=db();if(!d)return {ok:false,message:'DATABASE NOT AVAILABLE'};
 var lines=A(est.items||est.lines);if(!lines.length)return {ok:false,message:'NO ITEMS IN ESTIMATE'};
 for(var i=0;i<lines.length;i++){
  var no=itemNo(lines[i]),q=itemQty(lines[i]);if(!no||q<=0)return {ok:false,message:'INVALID ITEM OR QUANTITY'};
  var it=A(d.items).find(function(x){return U(x.no||x.itemNo||x.code)===no});if(!it)return {ok:false,message:'ITEM NOT FOUND: '+no};
  if(N(it[stockKey(it)])<q)return {ok:false,message:'INSUFFICIENT STOCK: '+no};
 }
 return {ok:true,message:'READY FOR DELIVERY'};
}
function deliver(ref){
 var d=db(),est=findEstimate(ref),v=validateDelivery(est);if(!v.ok)return v;
 var backup=clone({items:d.items,estimates:d.estimates});
 try{
  A(est.items||est.lines).forEach(function(line){var no=itemNo(line),q=itemQty(line);var it=A(d.items).find(function(x){return U(x.no||x.itemNo||x.code)===no});var k=stockKey(it);it[k]=N(it[k])-q});
  est.paymentStatus='RECEIVED';est.deliveryStatus='DELIVERED';est.status='DELIVERED';est.stockDeducted=true;est.deliveryStockDeducted=true;est.deliveredAt=new Date().toISOString();
  est.history=A(est.history);est.history.push({at:est.deliveredAt,action:'DELIVERY',detail:'PAYMENT RECEIVED - STOCK DEDUCTED ONCE'});
  if(!save())throw new Error('SAVE FUNCTION NOT AVAILABLE');
  return {ok:true,message:'DELIVERY COMPLETED - STOCK DEDUCTED ONCE'};
 }catch(e){d.items=backup.items;d.estimates=backup.estimates;return {ok:false,message:'DELIVERY NOT SAVED: '+e.message}}
}
function markPaymentReceived(ref){var est=findEstimate(ref);if(!est)return {ok:false,message:'ESTIMATE NOT FOUND'};if(U(est.deliveryStatus)==='DELIVERED')return {ok:false,message:'DELIVERED ESTIMATE CANNOT BE CHANGED'};est.paymentStatus='RECEIVED';est.history=A(est.history);est.history.push({at:new Date().toISOString(),action:'PAYMENT RECEIVED'});if(!save())return {ok:false,message:'SAVE FUNCTION NOT AVAILABLE'};return {ok:true,message:'PAYMENT RECEIVED SAVED - STOCK NOT DEDUCTED'} }
window.TorvoV27Txn={validateDelivery:validateDelivery,deliver:deliver,markPaymentReceived:markPaymentReceived};
})();