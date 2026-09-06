from pathlib import Path
p=Path('admin.html')
s=p.read_text(encoding='utf-8')
# Put the pre-paint restore guard immediately after <head>; this file has multiple style blocks.
head='''<head>'''
boot='''<head><script>(function(){try{var x=localStorage.getItem("TORVO_ADMIN_SECTION");if(x&&x!=="dashboard")document.documentElement.classList.add("torvo-restoring-admin")}catch(e){}})();</script><style>html.torvo-restoring-admin body{visibility:hidden!important}</style>'''
assert s.count(head)==1, 'head start marker mismatch'
s=s.replace(head,boot,1)
old='''function torvoRestoreAdminSection(){var id=localStorage.getItem("TORVO_ADMIN_SECTION")||sessionStorage.getItem("TORVO_ADMIN_SECTION")||String(location.hash||"").replace("#admin-","")||"dashboard";if(!E(id))id="dashboard";openSection(id,torvoNavButton(id),"restore");history.replaceState({torvoSection:id},"","#admin-"+id);var sub=localStorage.getItem("TORVO_ADMIN_SUBPAGE")||"";if(sub){setTimeout(function(){var b=document.querySelector('[onclick*="'+sub.replace(/\"/g,'')+'"]');if(b)try{b.click()}catch(e){}},80)}}'''
new='''function torvoRestoreAdminSection(){var id=localStorage.getItem("TORVO_ADMIN_SECTION")||sessionStorage.getItem("TORVO_ADMIN_SECTION")||String(location.hash||"").replace("#admin-","")||"dashboard";if(!E(id))id="dashboard";openSection(id,torvoNavButton(id),"restore");history.replaceState({torvoSection:id},"","#admin-"+id);var sub=localStorage.getItem("TORVO_ADMIN_SUBPAGE")||"";if(sub){var b=document.querySelector('[onclick*="'+sub.replace(/\"/g,'')+'"]');if(b)try{b.click()}catch(e){}}document.documentElement.classList.remove("torvo-restoring-admin")}'''
assert s.count(old)==1, 'current restore function mismatch'
s=s.replace(old,new,1)
old2='''window.addEventListener("load",function(){setTimeout(torvoRestoreAdminSection,120)});'''
new2='''if(document.readyState==="loading"){document.addEventListener("DOMContentLoaded",torvoRestoreAdminSection,{once:true})}else{torvoRestoreAdminSection()}'''
assert s.count(old2)==1, 'delayed restore handler mismatch'
s=s.replace(old2,new2,1)
p.write_text(s,encoding='utf-8')
