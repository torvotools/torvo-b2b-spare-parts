export const WORKSPACE_SHORTCUTS=[
 {key:'F2',action:'focus-search',label:'Search'},
 {key:'F3',action:'new-action',label:'New / Add'},
 {key:'F4',action:'refresh',label:'Refresh'},
 {key:'Escape',action:'close',label:'Close / Back'}
];
export const installWorkspaceShortcuts=handlers=>{if(typeof document==='undefined')return()=>{};const onKey=e=>{const match=WORKSPACE_SHORTCUTS.find(x=>x.key===e.key);if(!match)return;const target=e.target,typing=target&&['INPUT','TEXTAREA','SELECT'].includes(target.tagName);if(typing&&e.key!=='Escape'&&e.key!=='F2')return;const fn=handlers?.[match.action];if(!fn)return;e.preventDefault();fn(e)};document.addEventListener('keydown',onKey);return()=>document.removeEventListener('keydown',onKey)};
