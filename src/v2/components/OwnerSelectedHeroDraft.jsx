import React from 'react';

/**
 * Staging-only implementation for the owner's selected 1536x864 TORVO hero.
 * This does NOT use the older four-slot mask prototype. No image is bundled:
 * pass a verified, owner-approved image URL after it has been uploaded.
 * Do not mount until artwork/logo/text are reviewed and the CTA hit areas
 * have been visually tested on mobile and desktop.
 */
const safeImageUrl = (value) => {
  if (typeof value !== 'string') return '';
  if (value.startsWith('/')) return value.startsWith('//') ? '' : value;
  try {
    const url = new URL(value);
    return url.protocol === 'https:' ? url.href : '';
  } catch {
    return '';
  }
};

const actionStyle = (left, top, width, height) => ({
  position: 'absolute',
  left: `${left}%`,
  top: `${top}%`,
  width: `${width}%`,
  height: `${height}%`,
  display: 'block',
  borderRadius: '4px',
});

export default function OwnerSelectedHeroDraft({ imageUrl, productHref = '#products', dealerHref = '#torvo-dealer' }) {
  const src = safeImageUrl(imageUrl);
  if (!src) return null;
  return (
    <section aria-label="TORVO POWER TOOL SPARE PARTS" data-hero-approval="STAGING_DRAFT">
      <div style={{ position: 'relative', width: '100%', maxWidth: 1920, margin: '0 auto' }}>
        <img
          src={src}
          alt="TORVO MULTI BRAND POWER TOOL SPARE PART AVAILABLE"
          decoding="async"
          loading="eager"
          style={{ display: 'block', width: '100%', height: 'auto' }}
        />
        {/* Hit areas are proportional to the selected 1536x864 artwork.
            Measured against the owner-supplied 1536x864 reference: first button
            x=78..384, y=553..621; second x=408..667, y=553..621.
            Re-measure after any approved artwork revision. */}
        <a href={productHref} aria-label="EXPLORE PRODUCTS" style={actionStyle(5.08, 64.0, 19.92, 7.87)} />
        <a href={dealerHref} aria-label="FIND A DEALER" style={actionStyle(26.56, 64.0, 16.86, 7.87)} />
      </div>
    </section>
  );
}
