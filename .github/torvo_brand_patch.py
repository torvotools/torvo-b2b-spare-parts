from pathlib import Path
p=Path('admin.html')
s=p.read_text(encoding='utf-8')
old='''function openSection(id,btn,navMode){
 if(!E(id))return;
 if(navMode!=="restore"&&navMode!=="pop"){var cur=sessionStorage.getItem("TORVO_ADMIN_SECTION")||"dashboard";if(torvoNavReady&&cur!==id){history.pushState({torvoSection:id},"","#admin-"+id)}else if(!torvoNavReady){history.replaceState({torvoSection:id},"","#admin-"+id)}}
 sessionStorage.setItem("TORVO_ADMIN_SECTION",id);torvoNavReady=true;'''
new='''function openSection(id,btn,navMode){
 var saved=String(location.hash||"").replace("#admin-","")||sessionStorage.getItem("TORVO_ADMIN_SECTION")||"";
 if(!torvoNavReady&&navMode!=="restore"&&navMode!=="pop"&&id==="dashboard"&&saved&&saved!=="dashboard"&&E(saved)){id=saved;btn=torvoNavButton(id);navMode="restore"}
 if(!E(id))return;
 if(navMode!=="restore"&&navMode!=="pop"){var cur=sessionStorage.getItem("TORVO_ADMIN_SECTION")||"dashboard";if(torvoNavReady&&cur!==id){history.pushState({torvoSection:id},"","#admin-"+id)}else if(!torvoNavReady){history.replaceState({torvoSection:id},"","#admin-"+id)}}
 sessionStorage.setItem("TORVO_ADMIN_SECTION",id);torvoNavReady=true;'''
assert s.count(old)==1, 'current openSection navigation block mismatch'
s=s.replace(old,new,1)
old2='''window.addEventListener("DOMContentLoaded",function(){setTimeout(function(){var id=String(location.hash||"").replace("#admin-","")||sessionStorage.getItem("TORVO_ADMIN_SECTION")||"dashboard";if(!E(id))id="dashboard";openSection(id,torvoNavButton(id),"restore");history.replaceState({torvoSection:id},"","#admin-"+id)},0)});'''
new2='''function torvoRestoreAdminSection(){var id=String(location.hash||"").replace("#admin-","")||sessionStorage.getItem("TORVO_ADMIN_SECTION")||"dashboard";if(!E(id))id="dashboard";openSection(id,torvoNavButton(id),"restore");history.replaceState({torvoSection:id},"","#admin-"+id)}
window.addEventListener("load",function(){setTimeout(torvoRestoreAdminSection,120)});'''
assert s.count(old2)==1, 'current restore handler mismatch'
s=s.replace(old2,new2,1)
p.write_text(s,encoding='utf-8')
