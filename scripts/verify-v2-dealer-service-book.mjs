import fs from'node:fs';
const read=p=>fs.readFileSync(p,'utf8');
const svc=read('src/v2/services/dealerServiceBook.js'),ui=read('src/v2/components/DealerServiceBookWorkspace.jsx'),mount=read('src/v2/components/DealerPortalMounted.jsx'),sql=read('supabase/v2-dealer-service-book.sql'),billSql=read('supabase/v2-dealer-service-book-bill-integrity.sql');
const checks=[
 ['DEVICE-BOUND SERVICE RPC CLIENT',svc.includes('assertDealerSession')&&svc.includes('p_device_id:s.deviceId')&&svc.includes('p_session_token:s.token')],
 ['SERVICE BOOK CREATE + STATUS',svc.includes("rpc('dealer_service_job_create'")&&svc.includes("rpc('dealer_service_job_set_status'")],
 ['SERVICE BOOK PARTS ADD/REMOVE',svc.includes("rpc('dealer_service_job_add_part'")&&svc.includes("rpc('dealer_service_job_remove_part'")],
 ['SERVICE BOOK SERVER BILL READ',svc.includes("rpc('dealer_service_job_bill_read'")],
 ['PRIVATE MEDIA WORKERS',svc.includes('dealer-service-book-media-upload')&&svc.includes('dealer-service-book-media-read')&&svc.includes('dealer-service-book-media-delete')],
 ['SERVICE BOOK UI MOUNTED',mount.includes('DealerServiceBookWorkspace')&&mount.includes("changeMode('service-book')")],
 ['REPAIR REQUESTS REMAIN SEPARATE',mount.includes('DealerRepairWorkspace')&&mount.includes('REPAIR REQUESTS')],
 ['MACHINE IN UI',ui.includes('MACHINE IN')&&ui.includes('SAVE MACHINE IN')&&ui.includes('MACHINE PHOTO')],
 ['CATALOG PART PICKER',ui.includes('loadDealerWorkspaceCatalog')&&ui.includes('ADD TORVO CATALOG SPARE PART')&&ui.includes('SELLING RATE')],
 ['PART EDITS CLOSE BEFORE READY',ui.includes("['in_shop','repairing'].includes")],
 ['WHATSAPP OPERATIONAL NOTICE',ui.includes('serviceBookWhatsAppText')&&ui.includes('WHATSAPP')],
 ['DELIVERY WORKFLOW',ui.includes("move('ready')")&&ui.includes("move('delivered')")],
 ['SERVER SQL DEVICE ASSERTION',sql.includes('dealer_assert_my_device_session')],
 ['SERVER SQL BILL FOUNDATION',billSql.includes('dealer_service_job_bill_read')&&billSql.includes('CLOSED SERVICE JOB IS IMMUTABLE')]
];
const failed=checks.filter(([,ok])=>!ok);for(const[n,ok]of checks)console.log(`${ok?'PASS':'FAIL'} ${n}`);if(failed.length){console.error(`DEALER SERVICE BOOK CONTRACT FAILED: ${failed.length}`);process.exit(1)}console.log(`TORVO V2 DEALER SERVICE BOOK VERIFIED (${checks.length} GATES)`);
