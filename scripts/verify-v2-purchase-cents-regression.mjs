import fs from 'node:fs';
import vm from 'node:vm';
import assert from 'node:assert/strict';

const source = fs.readFileSync('src/v2/services/purchaseService.js', 'utf8');
const match = source.match(/const purchaseLines=([\s\S]*?);\s*export const purchaseService=/);
assert.ok(match, 'Purchase validator source must be present');
const validate = vm.runInNewContext('(' + match[1] + ')');
const line = rate => [{ item_id: '123e4567-e89b-42d3-a456-426614174000', qty: 1, purchase_rate: rate }];
for (const rate of [0, 0.01, 0.1, 0.29, 1.01, 1.23, 19.99, 99999999.99, 100000000]) {
  assert.equal(validate(line(rate))[0].purchase_rate, rate, 'valid rate rejected: ' + rate);
}
for (const rate of [-0.01, 0.001, 0.009, 1.234, 100000000.01, Infinity, NaN, '', null]) {
  assert.throws(() => validate(line(rate)), 'invalid rate accepted: ' + String(rate));
}
assert.equal(validate([{item_id:'123E4567-E89B-42D3-A456-426614174000',qty:'2',purchase_rate:'19.99'}])[0].qty,2);
assert.throws(() => validate([{item_id:'123e4567-e89b-42d3-a456-426614174000',qty:1,purchase_rate:1},{item_id:'123E4567-E89B-42D3-A456-426614174000',qty:1,purchase_rate:1}]), /DUPLICATE/);
assert.throws(() => validate([]), /AT LEAST ONE/);
assert.throws(() => validate([line(1)[0], line(2)[0]]), /DUPLICATE/);
assert.throws(() => validate([{item_id:'123e4567-e89b-42d3-a456-426614174000',qty:0,purchase_rate:1}]), /QUANTITY/);
assert.throws(() => validate([{item_id:'123e4567-e89b-42d3-a456-426614174000',qty:1,purchase_rate:'abc'}]), /RATE/);
assert.throws(() => validate([{item_id:'123e4567-e89b-42d3-a456-426614174000',qty:1,purchase_rate:'  '}]), /RATE/);
assert.throws(() => validate([{item_id:'123e4567-e89b-42d3-a456-426614174000',qty:1,purchase_rate:false}]), /RATE/);
for (const rate of [[1], {valueOf:()=>1}]) assert.throws(() => validate(line(rate)), /RATE/);

for (const qty of [0, -1, 1.5, 1000000, Infinity, NaN, '', '  ', null, true, false, [1], {valueOf:()=>1}]) {
  assert.throws(() => validate([{item_id:'123e4567-e89b-42d3-a456-426614174000',qty,purchase_rate:1}]), 'invalid qty accepted: ' + String(qty));
}
for (const item_id of ['', ' ', 'NOT-A-UUID', null, 123, true, {}, ['123e4567-e89b-42d3-a456-426614174000']]) {
  assert.throws(() => validate([{item_id,qty:1,purchase_rate:1}]), /ITEM/);
}
assert.throws(() => validate(Array.from({length:501},(_,i)=>({item_id:'123e4567-e89b-42d3-a456-'+String(i).padStart(12,'0'),qty:1,purchase_rate:1}))), /TOO MANY/);

console.log('PASS TORVO V2 purchase cents and validation regression');
