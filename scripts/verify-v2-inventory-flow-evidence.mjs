import fs from 'node:fs';
const fail=m=>{console.error('FAIL '+m);process.exit(1)};
const [,,p]=process.argv;if(!p||!fs.existsSync(p))fail('usage: node scripts/verify-v2-inventory-flow-evidence.mjs <evidence.json>');
let e;try{e=JSON.parse(fs.readFileSync(p,'utf8'))}catch{fail('invalid evidence JSON')}
for(const k of ['environment_project_id','commit_sha','captured_at_utc','purchase_ref','estimate_ref','item_id','opening_qty','purchase_received_qty','delivered_qty','closing_qty','movement_net_qty','same_key_purchase_replay_no_extra_movement','different_key_same_purchase_rejected','delivery_replay_no_extra_movement','second_delivery_key_rejected','role_boundary_checked'])if(e[k]===undefined||e[k]===null||e[k]==='')fail('missing '+k);
if(!/^[a-f0-9]{40}$/i.test(e.commit_sha))fail('invalid exact commit SHA');
if(!/^\d{4}-\d{2}-\d{2}T/.test(e.captured_at_utc))fail('captured_at_utc must be ISO timestamp');
const n=x=>Number(x);for(const k of ['opening_qty','purchase_received_qty','delivered_qty','closing_qty','movement_net_qty'])if(!Number.isFinite(n(e[k])))fail(k+' must be numeric');
if(n(e.purchase_received_qty)<=0||n(e.delivered_qty)<=0)fail('real positive purchase and delivery quantities required');
const expected=n(e.opening_qty)+n(e.purchase_received_qty)-n(e.delivered_qty);
if(Math.abs(expected-n(e.closing_qty))>0.000001)fail('closing inventory does not reconcile');
if(Math.abs((n(e.purchase_received_qty)-n(e.delivered_qty))-n(e.movement_net_qty))>0.000001)fail('canonical inventory movement net does not reconcile');
for(const k of ['same_key_purchase_replay_no_extra_movement','different_key_same_purchase_rejected','delivery_replay_no_extra_movement','second_delivery_key_rejected','role_boundary_checked'])if(e[k]!==true)fail(k+' is not true');
console.log('PASS TORVO V2 PURCHASE/DELIVERY INVENTORY EVIDENCE');
console.log('commit_sha='+e.commit_sha);console.log('purchase_ref='+e.purchase_ref);console.log('estimate_ref='+e.estimate_ref);console.log('closing_qty='+e.closing_qty);
console.log('NOTE: this validates supplied real staging evidence; it does not create or mutate staging transactions');
