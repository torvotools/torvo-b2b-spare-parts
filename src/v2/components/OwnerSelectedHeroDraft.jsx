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
            Re-measure after the final genuine-logo artwork is approved. */}
        <a href={productHref} aria-label="EXPLORE PRODUCTS" style={actionStyle(3.1, 57.6, 17.5, 6.8)} />
        <a href={dealerHref} aria-label="FIND A DEALER" style={actionStyle(21.2, 57.6, 15.7, 6.8)} />
      </div>
    </section>
  );
}
