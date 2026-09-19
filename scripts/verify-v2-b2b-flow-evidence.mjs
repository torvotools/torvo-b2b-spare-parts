import fs from 'node:fs';
const fail=m=>{console.error('FAIL '+m);process.exit(1)};
const [,,p]=process.argv;if(!p||!fs.existsSync(p))fail('usage: node scripts/verify-v2-b2b-flow-evidence.mjs <evidence.json>');
let e;try{e=JSON.parse(fs.readFileSync(p,'utf8'))}catch{fail('invalid evidence JSON')}
for(const k of ['environment_project_id','commit_sha','captured_at_utc','dealer_identity_ref','purchase_order_ref','sales_order_ref','revision_no','estimate_ref','payment_ref','dispatch_ref','delivery_ref'])if(e[k]===undefined||e[k]===null||e[k]==='')fail('missing '+k);
if(e.environment_project_id!=='jvmhhngjlaqrfopfavur')fail('runtime evidence must come from TORVO V2 STAGING');
if(!/^[a-f0-9]{40}$/i.test(e.commit_sha))fail('invalid exact commit SHA');
if(!/^\d{4}-\d{2}-\d{2}T/.test(e.captured_at_utc))fail('captured_at_utc must be ISO timestamp');
if(!Number.isInteger(Number(e.revision_no))||Number(e.revision_no)<1)fail('revision_no must be positive integer');
const required=['dealer_rate_server_derived','dealer_ok_exact_revision','stale_revision_rejected','estimate_created_from_exact_dealer_ok','original_order_locked_after_estimate','payment_idempotency_checked','dispatch_ready_boundary_checked','delivery_exactly_once_checked','dealer_payment_visibility_device_bound','dealer_delivery_visibility_device_bound'];
for(const k of required)if(e[k]!==true)fail(k+' is not true');
if(e.additional_order_tested===true){for(const k of ['additional_order_ref','original_order_unchanged','additional_order_linked','additional_order_replay_rejected'])if(e[k]===undefined||e[k]===null||e[k]===''||((k!=='additional_order_ref')&&e[k]!==true))fail('additional order evidence '+k+' invalid')}
console.log('PASS TORVO V2 B2B FLOW EVIDENCE');
console.log('commit_sha='+e.commit_sha);console.log('sales_order_ref='+e.sales_order_ref);console.log('estimate_ref='+e.estimate_ref);console.log('delivery_ref='+e.delivery_ref);
console.log('NOTE: this validates supplied real staging transaction evidence; it does not create or mutate business records');
