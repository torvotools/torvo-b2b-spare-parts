(function (global) {
  'use strict';

  function read(form) {
    if (!form || !global.TORVO_V2_COMMUNICATION) return null;
    return global.TORVO_V2_COMMUNICATION.normalize({
      publicBusinessEmail: form.elements.publicBusinessEmail && form.elements.publicBusinessEmail.value,
      publicBusinessEmailEnabled: form.elements.publicBusinessEmailEnabled && form.elements.publicBusinessEmailEnabled.checked,
      customerCareWhatsApp: form.elements.customerCareWhatsApp && form.elements.customerCareWhatsApp.value,
      socialLinks: {
        facebook: form.elements.facebook && form.elements.facebook.value,
        instagram: form.elements.instagram && form.elements.instagram.value,
        youtube: form.elements.youtube && form.elements.youtube.value
      }
    });
  }

  function bind(form, save) {
    if (!form) return;
    form.addEventListener('submit', async function (event) {
      event.preventDefault();
      const cfg = read(form);
      if (!cfg) return;
      if (typeof save !== 'function') throw new Error('SERVER SAVE HANDLER REQUIRED');
      await save(cfg);
    });
  }

  global.TORVO_V2_ADMIN_COMMUNICATION = Object.freeze({ read, bind });
})(typeof window !== 'undefined' ? window : globalThis);
