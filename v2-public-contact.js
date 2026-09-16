(function (global) {
  'use strict';

  function waHref(phone, text) {
    const digits = String(phone || '').replace(/\D/g, '');
    if (!digits) return '';
    const number = digits.length === 10 ? '91' + digits : digits;
    return 'https://wa.me/' + number + (text ? '?text=' + encodeURIComponent(text) : '');
  }

  function render(root, config) {
    if (!root || !global.TORVO_V2_COMMUNICATION) return;
    const cfg = global.TORVO_V2_COMMUNICATION.publicView(config);
    root.textContent = '';

    const wa = document.createElement('a');
    wa.className = 'torvo-contact-action torvo-contact-whatsapp';
    wa.textContent = 'WHATSAPP';
    wa.href = waHref(cfg.customerCareWhatsApp, 'HELLO TORVO, I HAVE A REQUIREMENT.');
    wa.target = '_blank'; wa.rel = 'noopener noreferrer';
    root.appendChild(wa);

    if (cfg.publicBusinessEmailEnabled && cfg.publicBusinessEmail) {
      const mail = document.createElement('a');
      mail.className = 'torvo-contact-action torvo-contact-email';
      mail.textContent = 'EMAIL REQUIREMENT';
      mail.href = 'mailto:' + cfg.publicBusinessEmail + '?subject=' + encodeURIComponent('TORVO REQUIREMENT');
      root.appendChild(mail);
    }
  }

  global.TORVO_V2_PUBLIC_CONTACT = Object.freeze({ render, waHref });
})(typeof window !== 'undefined' ? window : globalThis);
