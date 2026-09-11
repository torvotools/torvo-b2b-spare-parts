// TORVO V2 business text normalization.
// Use for human-entered business/master/catalog text only.
// Never apply to email, password/PIN, URLs, tokens, IDs or other case-sensitive technical values.
export const normalizeBusinessText=value=>String(value??'').trim().replace(/\s+/g,' ').toUpperCase();
export const normalizeBusinessInput=value=>String(value??'').replace(/\s+/g,' ').toUpperCase();
export const normalizeSearchText=value=>String(value??'').trim().replace(/\s+/g,' ').toLowerCase();
export const sameBusinessText=(a,b)=>normalizeBusinessText(a)===normalizeBusinessText(b);
