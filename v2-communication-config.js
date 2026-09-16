(function (global) {
  'use strict';

  const DEFAULTS = Object.freeze({
    primaryChannel: 'WHATSAPP',
    publicBusinessEmail: '',
    publicBusinessEmailEnabled: false,
    customerCareWhatsApp: '7027751533',
    socialLinks: Object.freeze({ facebook: '', instagram: '', youtube: '' })
  });

  function cleanEmail(value) {
    const email = String(value || '').trim();
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) ? email : '';
  }

  function cleanPhone(value) {
    const digits = String(value || '').replace(/\D/g, '');
    return digits.length >= 10 && digits.length <= 15 ? digits : '';
  }

  function cleanHttpsUrl(value) {
    const raw = String(value || '').trim();
    if (!raw) return '';
    try {
      const url = new URL(raw);
      return url.protocol === 'https:' ? url.toString() : '';
    } catch (_) { return ''; }
  }

  function normalize(input) {
    const cfg = input || {};
    return Object.freeze({
      primaryChannel: 'WHATSAPP',
      publicBusinessEmail: cleanEmail(cfg.publicBusinessEmail),
      publicBusinessEmailEnabled: Boolean(cfg.publicBusinessEmailEnabled && cleanEmail(cfg.publicBusinessEmail)),
      customerCareWhatsApp: cleanPhone(cfg.customerCareWhatsApp) || DEFAULTS.customerCareWhatsApp,
      socialLinks: Object.freeze({
        facebook: cleanHttpsUrl(cfg.socialLinks && cfg.socialLinks.facebook),
        instagram: cleanHttpsUrl(cfg.socialLinks && cfg.socialLinks.instagram),
        youtube: cleanHttpsUrl(cfg.socialLinks && cfg.socialLinks.youtube)
      })
    });
  }

  function publicView(input) {
    const cfg = normalize(input);
    return Object.freeze({
      primaryChannel: cfg.primaryChannel,
      publicBusinessEmail: cfg.publicBusinessEmailEnabled ? cfg.publicBusinessEmail : '',
      publicBusinessEmailEnabled: cfg.publicBusinessEmailEnabled,
      customerCareWhatsApp: cfg.customerCareWhatsApp,
      socialLinks: cfg.socialLinks
    });
  }

  global.TORVO_V2_COMMUNICATION = Object.freeze({ DEFAULTS, normalize, publicView, cleanEmail, cleanPhone, cleanHttpsUrl });
})(typeof window !== 'undefined' ? window : globalThis);
