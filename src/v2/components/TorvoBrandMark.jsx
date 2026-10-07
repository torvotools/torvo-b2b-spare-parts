import React from'react';

/**
 * Shared TORVO identity mark for V2 application surfaces.
 * Presentation only: no auth, routing, business or data behavior.
 * Keep the compact mark legible at app-icon/header sizes and expose
 * a stable accessible label instead of duplicating one-off letter marks.
 */
export default function TorvoBrandMark({className='',label='TORVO TOOLS'}){
 return <span className={`torvoBrandMark ${className}`.trim()} role="img" aria-label={label}>
  <span className="torvoBrandMarkT">T</span>
  <span className="torvoBrandMarkV">V</span>
 </span>
}
