import React from 'react';

/**
 * DRAFT ONLY: four image regions for the owner's latest 1536x864 hexagon hero
 * (uploaded as 1000960302.png). Not mounted in the website.
 * Bounding polygons were estimated visually and require pixel inspection.
 * The labels, red frames and imagery are flattened into the reference.
 * Do not activate without clean plate, border/label overlays and testing.
 */
const REFERENCE_WIDTH = 1536;
const REFERENCE_HEIGHT = 864;
const SLOTS = Object.freeze({
  machinery: {
    box: [740, 25, 354, 254],
    clip: 'polygon(24% 0, 81% 0, 100% 53%, 81% 100%, 20% 100%, 0 53%)',
  },
  spare_part: {
    box: [688, 279, 356, 235],
    clip: 'polygon(23% 0, 77% 0, 100% 52%, 81% 100%, 19% 100%, 0 52%)',
  },
  accessori: {
    box: [748, 508, 362, 239],
    clip: 'polygon(19% 0, 80% 0, 100% 54%, 77% 100%, 18% 100%, 0 53%)',
  },
  feature: {
    box: [994, 152, 524, 496],
    clip: 'polygon(23% 0, 73% 0, 100% 51%, 72% 100%, 20% 100%, 0 50%)',
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
