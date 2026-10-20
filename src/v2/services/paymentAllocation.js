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
    balances.set(String(bill.id),{amount:money(bill.amount),paid:0,credited:money(bill.allocated_credit??0)});
  }
  const seen=new Set(),rows=[];
  for(const payment of payments){
    if(!payment?.id||seen.has(String(payment.id)))throw new Error('DUPLICATE OR MISSING PAYMENT');
    seen.add(String(payment.id));
    if(!payment.bill_id||!balances.has(String(payment.bill_id)))throw new Error('PAYMENT BILL NOT FOUND');
    const amount=money(payment.amount);
    const b=balances.get(String(payment.bill_id));
    if(b.paid+b.credited+amount>b.amount)throw new Error('PAYMENT EXCEEDS BILL BALANCE');
    b.paid+=amount;
    rows.push({payment_id:payment.id,bill_id:payment.bill_id,allocated:amount/100});
  }
  return {allocations:rows,bills:[...balances].map(([bill_id,b])=>({bill_id,amount:b.amount/100,allocated_payment:b.paid/100,allocated_credit:b.credited/100,outstanding:(b.amount-b.paid-b.credited)/100}))};
}
