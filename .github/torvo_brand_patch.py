from pathlib import Path
p=Path('admin.html')
s=p.read_text(encoding='utf-8')
# Pre-paint guard: only hide when restoring a non-dashboard Admin page.
if 'torvo-restoring-admin' not in s:
    s=s.replace('<head>','<head><script>(function(){try{var x=localStorage.getItem("TORVO_ADMIN_SECTION");if(x&&x!=="dashboard")document.documentElement.classList.add("torvo-restoring-admin")}catch(e){}})();</script><style>html.torvo-restoring-admin body{visibility:hidden!important}</style>',1)
# Keep existing proven restore logic; simply reveal immediately after it has restored.
needle='history.replaceState({torvoSection:id},"","#admin-"+id);var sub=localStorage.getItem("TORVO_ADMIN_SUBPAGE")||"";'
if needle in s and 'document.documentElement.classList.remove("torvo-restoring-admin")' not in s:
    s=s.replace(needle,needle+'setTimeout(function(){document.documentElement.classList.remove("torvo-restoring-admin")},0);',1)
# Remove the old 120ms wait so Dashboard never gets a visible paint first.
s=s.replace('window.addEventListener("load",function(){setTimeout(torvoRestoreAdminSection,120)});','if(document.readyState==="loading"){document.addEventListener("DOMContentLoaded",torvoRestoreAdminSection,{once:true})}else{torvoRestoreAdminSection()}',1)
if 'torvo-restoring-admin' not in s:
    raise SystemExit('no-flash guard was not installed')
p.write_text(s,encoding='utf-8')
