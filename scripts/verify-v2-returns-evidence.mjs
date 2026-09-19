import fs from 'node:fs';
const fail=m=>{console.error('FAIL '+m);process.exit(1)};
const [,,p]=process.argv;if(!p||!fs.existsSync(p))fail('usage: node scripts/verify-v2-returns-evidence.mjs <evidence.json>');
let e;try{e=JSON.parse(fs.readFileSync(p,'utf8'))}catch{fail('invalid evidence JSON')}
for(const k of ['environment_project_id','commit_sha','captured_at_utc','sales_return','purchase_return'])if(e[k]===undefined||e[k]===null)fail('missing '+k);
if(!/^[a-f0-9]{40}$/i.test(e.commit_sha))fail('invalid exact commit SHA');
if(!/^\d{4}-\d{2}-\d{2}T/.test(e.captured_at_utc))fail('captured_at_utc must be ISO timestamp');
const check=(name,x,sign)=>{
 for(const k of ['source_ref','approval_ref','return_ref','item_ref','qty','stock_before','stock_after','movement_qty','maker_checker_distinct_or_owner_override','same_request_key_replay_no_extra_effect','over_return_rejected','unauthorized_role_rejected'])if(x[k]===undefined||x[k]===null||x[k]==='')fail(name+' missing '+k);
 const q=Number(x.qty),b=Number(x.stock_before),a=Number(x.stock_after),m=Number(x.movement_qty);
 if(![q,b,a,m].every(Number.isFinite)||q<=0)fail(name+' invalid quantities');
 if(Math.abs(a-(b+sign*q))>0.000001)fail(name+' stock effect does not reconcile');
 if(Math.abs(m-sign*q)>0.000001)fail(name+' inventory movement does not reconcile');
 for(const k of ['maker_checker_distinct_or_owner_override','same_request_key_replay_no_extra_effect','over_return_rejected','unauthorized_role_rejected'])if(x[k]!==true)fail(name+' '+k+' is not true');
};
check('sales_return',e.sales_return,1);check('purchase_return',e.purchase_return,-1);
if(e.purchase_return.insufficient_stock_rejected!==true)fail('purchase_return insufficient_stock_rejected is not true');
console.log('PASS TORVO V2 RETURNS EVIDENCE');console.log('commit_sha='+e.commit_sha);console.log('sales_return_ref='+e.sales_return.return_ref);console.log('purchase_return_ref='+e.purchase_return.return_ref);
console.log('NOTE: this validates supplied real staging return evidence; it does not create or mutate return/inventory records');
