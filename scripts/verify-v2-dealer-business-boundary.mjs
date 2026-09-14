import fs from'node:fs';
const read=p=>fs.readFileSync(p,'utf8');
const repo=read('src/v2/services/repository.js'),business=read('src/v2/services/dealerBusiness.js'),proc=read('src/v2/services/dealerProcurement.js'),orders=read('src/v2/services/dealerOrders.js'),machine=read('src/v2/services/dealerMachineSpares.js'),workspace=read('src/v2/services/dealerWorkspace.js');
const proof=x=>x.includes('p_device_id:proof.deviceId')&&x.includes('p_session_token:proof.token');
const checks=[
 ['SECURE BUSINESS FACADE',business.includes('dealerItemRate')&&business.includes('submitDealerPurchaseOrder')&&business.includes('confirmDealerSalesOrder')],
 ['PROCUREMENT PROOF',proof(proc)&&proc.includes('DUPLICATE ITEM IS NOT ALLOWED')],
 ['ORDER PROOF',proof(orders)&&orders.includes('get_dealer_order_history_30d')],
 ['MACHINE SPARES PROOF',proof(machine)&&machine.includes('get_dealer_machine_spares')],
 ['WORKSPACE PROOF',proof(workspace)&&workspace.includes('dealer_workspace_catalog')],
 ['LEGACY MACHINE RPC DETECTED',!repo.includes("rpc('get_dealer_machine_spares',{p_machine:machineId})")],
 ['LEGACY RATE RPC DETECTED',!repo.includes("rpc('dealer_item_rate',{p_item:itemId,p_qty:Number(qty)})")],
 ['LEGACY PO RPC DETECTED',!repo.includes("rpc('submit_purchase_order',{p_lines:clean})")]
];
const failed=checks.filter(([,ok])=>!ok);for(const[n,ok]of checks)console.log(`${ok?'PASS':'FAIL'} ${n}`);if(failed.length){console.error(`DEALER BUSINESS BOUNDARY FAILED: ${failed.length}`);process.exit(1)}console.log('TORVO V2 DEALER BUSINESS BOUNDARY VERIFIED');
