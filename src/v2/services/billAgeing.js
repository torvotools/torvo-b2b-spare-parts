// Bill-wise receivable ageing: pure calculations, no ledger postings or database writes.
// Dates are calendar dates, not elapsed 24-hour intervals, so timezone/DST cannot shift ageing.
const day = value => {
  if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(value.slice(0,10))) throw new Error('INVALID ACCOUNTING DATE');
  const date = value.slice(0,10);
  const ms = Date.parse(date + 'T00:00:00Z');
  if (!Number.isFinite(ms) || new Date(ms).toISOString().slice(0,10) !== date) throw new Error('INVALID ACCOUNTING DATE');
  return ms / 86400000;
};
const cents = value => {
  const n = Number(value);
  if (!Number.isFinite(n) || n < 0 || Math.round(n * 100) !== n * 100 && Math.abs(Math.round(n * 100) - n * 100) > 1e-7) throw new Error('INVALID MONEY AMOUNT');
  return Math.round(n * 100);
};
export function calculateBillAgeing(bill, asOfDate) {
  if (!bill || !bill.bill_date) throw new Error('BILL DATE REQUIRED');
  const today = day(asOfDate), issued = day(bill.bill_date);
  if (issued > today) throw new Error('FUTURE BILL DATE');
  const due = bill.due_date ? day(bill.due_date) : issued + (bill.credit_days == null ? 0 : Number(bill.credit_days));
  if (!Number.isInteger(due) || due < issued) throw new Error('INVALID PAYMENT TERMS');
  const total = cents(bill.amount), paid = cents(bill.allocated_payment ?? 0), credited = cents(bill.allocated_credit ?? 0);
  if (paid + credited > total) throw new Error('BILL ALLOCATION EXCEEDS AMOUNT');
  const balanceCents = total - paid - credited;
  const billAgeDays = today - issued, overdueDays = Math.max(0, today - due);
  const bucket = balanceCents === 0 ? 'PAID' : overdueDays === 0 ? 'NOT DUE' : overdueDays <= 30 ? '1-30' : overdueDays <= 60 ? '31-60' : overdueDays <= 90 ? '61-90' : overdueDays <= 180 ? '91-180' : '180+';
  return { bill_id: bill.id, bill_age_days: billAgeDays, overdue_days: overdueDays, outstanding: balanceCents / 100, bucket };
}
export function summarizePartyAgeing(bills, asOfDate) {
  if (!Array.isArray(bills)) throw new Error('BILLS MUST BE AN ARRAY');
  const rows = bills.map(b => calculateBillAgeing(b, asOfDate));
  const bucketCents = { 'NOT DUE':0, '1-30':0, '31-60':0, '61-90':0, '91-180':0, '180+':0 };
  for (const row of rows) if (row.bucket !== 'PAID') bucketCents[row.bucket] += Math.round(row.outstanding * 100);
  return { rows, buckets: Object.fromEntries(Object.entries(bucketCents).map(([k,v])=>[k,v/100])), total_outstanding: Object.values(bucketCents).reduce((a,b)=>a+b,0)/100 };
}
