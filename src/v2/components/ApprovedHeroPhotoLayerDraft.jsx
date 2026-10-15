import React from 'react';

/**
 * Staging-only building block for TORVO's owner-approved 1536x864 Hero.
 * NOT mounted in the public website. A clean background plate and verified
 * foreground trim are required before this may replace the flattened image.
 *
 * Positions are approximate and must be visually checked against the
 * original approved artwork before use. No design/text/buttons are rendered.
 */
const REFERENCE_WIDTH = 1536;
const REFERENCE_HEIGHT = 864;
const SLOTS = Object.freeze({
  machinery: {
    box: [91, 372, 245, 130],
    clip: 'polygon(21% 0, 100% 0, 86% 100%, 0 100%)',
  },
  spare_part: {
    box: [317, 372, 247, 130],
    clip: 'polygon(23% 0, 100% 0, 89% 100%, 0 100%)',
  },
  accessori: {
    box: [545, 372, 252, 130],
    clip: 'polygon(25% 0, 100% 0, 87% 100%, 0 100%)',
  },
  feature: {
    box: [790, 170, 678, 516],
    clip: 'polygon(21% 5%, 61% 0, 67% 3%, 100% 51%, 73% 100%, 21% 98%, 0 58%)',
  },
});

const safePhoto = (url) => {
  if (typeof url !== 'string') return '';
  try {
    const parsed = new URL(url);
    return parsed.protocol === 'https:' ? parsed.href : '';
  } catch {
    return '';
  }
};

/**
 * Place this component inside a position:relative, aspect-ratio:16/9
 * wrapper ONLY after approved clean background and foreground assets exist.
 * Its presence alone is not a completed or approved public Hero.
 */
export default function ApprovedHeroPhotoLayerDraft({ photos = {} }) {
  return (
    <div
      aria-hidden="true"
      data-torvo-hero-photo-layer-status="DRAFT_NOT_APPROVED"
      style={{ position: 'absolute', inset: 0, pointerEvents: 'none' }}
    >
      {Object.entries(SLOTS).map(([key, slot]) => {
        const url = safePhoto(photos[key]);
        if (!url) return null;
        const [x, y, width, height] = slot.box;
        return (
          <div
            key={key}
            data-hero-photo-slot={key}
            style={{
              position: 'absolute',
              left: `${(x / REFERENCE_WIDTH) * 100}%`,
              top: `${(y / REFERENCE_HEIGHT) * 100}%`,
              width: `${(width / REFERENCE_WIDTH) * 100}%`,
              height: `${(height / REFERENCE_HEIGHT) * 100}%`,
              clipPath: slot.clip,
              overflow: 'hidden',
            }}
          >
            <img
              src={url}
              alt=""
              loading="lazy"
              decoding="async"
              style={{ display: 'block', width: '100%', height: '100%', objectFit: 'cover' }}
            />
          </div>
        );
      })}
    </div>
  );
}
