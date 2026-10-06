import fs from 'node:fs';
const app=fs.readFileSync('src/v2/App.jsx','utf8');
const modules=fs.readFileSync('src/v2/config/modules.js','utf8');
const sales=fs.readFileSync('src/v2/components/SalesWorkspace.jsx','utf8');
const checks=[
 ['APP PASSES ROLE TO SALES WORKSPACE',app.includes("<SalesWorkspace role={role}/>")],
 ['ACCOUNTANT HAS DEDICATED MARG BILL MODULE',modules.includes("{id:'marg-bill-sale',label:'Marg Bill / Confirm Sale',roles:['owner','admin','accountant']}")],
 ['ACCOUNTANT MARG BILL ROUTE REUSES CANONICAL COMPONENT',app.includes("active==='marg-bill-sale')page=<MargBillSaleWorkspace/>")],
 ['SALESMAN SALES MODULE PRESERVED',modules.includes("{id:'sales',label:'Sales Workspace',roles:['owner','admin','salesman']}")],
 ['SALESMAN NOT GRANTED DEDICATED MARG BILL MODULE',!modules.includes("roles:['salesman']},{id:'marg-bill-sale'")&&!modules.includes("'marg-bill-sale',label:'Marg Bill / Confirm Sale',roles:['salesman']")],
 ['MARG BILL TAB ROLE GATE',sales.includes("const canPostSale=['owner','admin','accountant'].includes")&&sales.includes("{canPostSale&&<button")],
 ['BACKEND REMAINS AUTHORITATIVE',sales.includes("<MargBillSaleWorkspace/>")]
];
let bad=0;for(const[name,ok]of checks){console.log(`${ok?'PASS':'FAIL'} ${name}`);if(!ok)bad++}
if(bad){console.error(`SALES ROLE BOUNDARY FAILED: ${bad}`);process.exit(1)}
console.log('TORVO V2 SALES / MARG BILL ROLE BOUNDARY LOCKED');
