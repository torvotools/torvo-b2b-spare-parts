import fs from 'node:fs';
import vm from 'node:vm';
import assert from 'node:assert/strict';

const source = fs.readFileSync('src/v2/services/purchaseService.js', 'utf8');
const match = source.match(/const purchaseLines=([\s\S]*?);\s*export const purchaseService=/);
assert.ok(match, 'Purchase validator source must be present');
const validate = vm.runInNewContext('(' + match[1] + ')');
const line = rate => [{ item_id: 'TEST-ITEM', qty: 1, purchase_rate: rate }];
for (const rate of [0, 0.01, 0.1, 0.29, 1.01, 1.23, 19.99, 99999999.99, 100000000]) {
  assert.equal(validate(line(rate))[0].purchase_rate, rate, 'valid rate rejected: ' + rate);
}
for (const rate of [-0.01, 0.001, 0.009, 1.234, 100000000.01, Infinity, NaN, '', null]) {
  assert.throws(() => validate(line(rate)), 'invalid rate accepted: ' + String(rate));
}
assert.throws(() => validate([]), /AT LEAST ONE/);
assert.throws(() => validate([line(1)[0], line(2)[0]]), /DUPLICATE/);
assert.throws(() => validate([{item_id:'TEST-ITEM',qty:0,purchase_rate:1}]), /QUANTITY/);
assert.throws(() => validate([{item_id:'TEST-ITEM',qty:1,purchase_rate:'abc'}]), /RATE/);
assert.throws(() => validate([{item_id:'TEST-ITEM',qty:1,purchase_rate:'  '}]), /RATE/);
assert.throws(() => validate([{item_id:'TEST-ITEM',qty:1,purchase_rate:false}]), /RATE/);

for (const qty of [0, -1, 1.5, 1000000, Infinity, NaN, '', '  ', null, true, false]) {
  assert.throws(() => validate([{item_id:'TEST-ITEM',qty,purchase_rate:1}]), 'invalid qty accepted: ' + String(qty));
}
for (const item_id of ['', ' ', null, 123, true, {}, ['TEST-ITEM']]) {
  assert.throws(() => validate([{item_id,qty:1,purchase_rate:1}]), /ITEM/);
}
assert.throws(() => validate(Array.from({length:501},(_,i)=>({item_id:'I'+i,qty:1,purchase_rate:1}))), /TOO MANY/);

console.log('PASS TORVO V2 purchase cents and validation regression');
