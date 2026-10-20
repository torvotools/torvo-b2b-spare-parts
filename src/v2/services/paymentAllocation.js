// Deterministic bill-wise payment allocation preview. Pure calculations only; no ledger writes.
const money = value => {
  const n=Number(value);
  if(!Number.isFinite(n)||n<0||Math.abs(Math.round(n*100)-n*100)>1e-7)throw new Error('INVALID ALLOCATION AMOUNT');
  return Math.round(n*100);
};
export function allocatePaymentsToBills(bills,payments){
  if(!Array.isArray(bills)||!Array.isArray(payments))throw new Error('INVALID ALLOCATION INPUT');
  const balances=new Map();
  for(const bill of bills){
    if(!bill?.id||balances.has(String(bill.id)))throw new Error('DUPLICATE OR MISSING BILL');
    const amount=money(bill.amount),credited=money(bill.allocated_credit??0),paid=money(bill.allocated_payment??0);
    if(credited+paid>amount)throw new Error('EXISTING ALLOCATION EXCEEDS BILL');
    balances.set(String(bill.id),{amount,paid,credited,party_id:bill.party_id==null?null:String(bill.party_id)});
  }
  const seen=new Set(),rows=[];
  const requestKeys=new Set();
  for(const payment of payments){
    if(!payment?.id||seen.has(String(payment.id)))throw new Error('DUPLICATE OR MISSING PAYMENT');
    seen.add(String(payment.id));
    if(payment.request_key!=null){const key=String(payment.request_key).trim();if(!key||requestKeys.has(key))throw new Error('DUPLICATE OR INVALID PAYMENT REQUEST KEY');requestKeys.add(key)}
    if(payment.status!=null&&!['received','cash'].includes(payment.status))throw new Error('PAYMENT NOT RECEIVED');
    if(!payment.bill_id||!balances.has(String(payment.bill_id)))throw new Error('PAYMENT BILL NOT FOUND');
    const amount=money(payment.amount);
    if(amount===0)throw new Error('ZERO PAYMENT ALLOCATION');
    const b=balances.get(String(payment.bill_id));
    if(b.party_id!==null&&(payment.party_id==null||String(payment.party_id)!==b.party_id))throw new Error('PAYMENT PARTY MISMATCH');
    if(b.paid+b.credited+amount>b.amount)throw new Error('PAYMENT EXCEEDS BILL BALANCE');
    b.paid+=amount;
    rows.push({payment_id:payment.id,bill_id:payment.bill_id,allocated:amount/100});
  }
  return {allocations:rows,bills:[...balances].map(([bill_id,b])=>({bill_id,amount:b.amount/100,allocated_payment:b.paid/100,allocated_credit:b.credited/100,outstanding:(b.amount-b.paid-b.credited)/100}))};
}
