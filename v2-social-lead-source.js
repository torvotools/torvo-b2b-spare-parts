(function (global) {
  'use strict';
  const ALLOWED = new Set(['WEBSITE','FACEBOOK','INSTAGRAM','YOUTUBE','WHATSAPP','EMAIL','OTHER']);

  function normalizeSource(value) {
    const source = String(value || '').trim().toUpperCase();
    return ALLOWED.has(source) ? source : '';
  }

  function sourceFromUrl(input) {
    try {
      const url = new URL(input || (global.location && global.location.href) || '', 'https://torvotools.com');
      const explicit = normalizeSource(url.searchParams.get('source') || url.searchParams.get('utm_source'));
      if (explicit) return explicit;
      const ref = String((global.document && global.document.referrer) || '').toLowerCase();
      if (ref.includes('facebook.com') || ref.includes('fb.com')) return 'FACEBOOK';
      if (ref.includes('instagram.com')) return 'INSTAGRAM';
      if (ref.includes('youtube.com') || ref.includes('youtu.be')) return 'YOUTUBE';
      return 'WEBSITE';
    } catch (_) { return ''; }
  }

  function attach(payload, input) {
    const source = normalizeSource(input) || sourceFromUrl();
    return Object.assign({}, payload || {}, source ? { lead_source: source } : {});
  }

  global.TORVO_V2_LEAD_SOURCE = Object.freeze({ normalizeSource, sourceFromUrl, attach });
})(typeof window !== 'undefined' ? window : globalThis);
