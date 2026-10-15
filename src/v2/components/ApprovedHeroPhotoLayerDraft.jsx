import React from 'react';

/**
 * Staging-only building block for TORVO's owner-approved 1536x864 Hero.
 * NOT mounted in the public website. A clean background plate and verified
 * foreground trim are required before this may replace the flattened image.
 *
 * Coordinates have been refined by inspection of the 1536x864 original.
 * They remain approximate: the original photo, bevel, and border are
 * flattened together. Do not mount until a clean background and foreground
 * frame have been prepared and visually verified against the
 * original approved artwork before use. No design/text/buttons are rendered.
 */
const REFERENCE_WIDTH = 1536;
const REFERENCE_HEIGHT = 864;
const SLOTS = Object.freeze({
  machinery: {
    box: [83, 370, 246, 135],
    clip: 'polygon(20% 0, 100% 0, 85% 100%, 0 100%)',
  },
  spare_part: {
    box: [317, 370, 248, 135],
    clip: 'polygon(18% 0, 100% 0, 85% 100%, 0 100%)',
  },
  accessori: {
    box: [551, 370, 246, 135],
    clip: 'polygon(20% 0, 100% 0, 85% 100%, 0 100%)',
  },
  feature: {
    box: [787, 174, 675, 505],
    clip: 'polygon(19% 5%, 64% 0, 100% 50%, 79% 100%, 19% 100%, 0 51%)',
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
