// TORVO V2 global English business-text normalization.
// Human-entered business/master/catalog/search text is UPPERCASE immediately.
// Never apply to email, username/login where case matters, password/PIN, URLs/websites,
// tokens, IDs, API/provider values or other case-sensitive technical values.
export const normalizeBusinessText=value=>String(value??'').trim().replace(/\s+/g,' ').toUpperCase();
export const normalizeBusinessInput=value=>String(value??'').replace(/\s+/g,' ').toUpperCase();
export const normalizeSearchInput=value=>String(value??'').replace(/\s+/g,' ').toUpperCase();
// Search comparison is case-insensitive internally; the visible user input stays UPPERCASE.
export const normalizeSearchText=value=>String(value??'').trim().replace(/\s+/g,' ').toLowerCase();
export const sameBusinessText=(a,b)=>normalizeBusinessText(a)===normalizeBusinessText(b);
