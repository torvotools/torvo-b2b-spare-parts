from pathlib import Path
p=Path('admin.html')
s=p.read_text(encoding='utf-8')
old=''' sessionStorage.setItem("TORVO_ADMIN_SECTION",id);torvoNavReady=true;'''
new=''' sessionStorage.setItem("TORVO_ADMIN_SECTION",id);localStorage.setItem("TORVO_ADMIN_SECTION",id);torvoNavReady=true;'''
assert s.count(old)==1, 'section storage block mismatch'
s=s.replace(old,new,1)
old2='''function torvoRestoreAdminSection(){var id=String(location.hash||"").replace("#admin-","")||sessionStorage.getItem("TORVO_ADMIN_SECTION")||"dashboard";if(!E(id))id="dashboard";openSection(id,torvoNavButton(id),"restore");history.replaceState({torvoSection:id},"","#admin-"+id)}'''
new2='''function torvoRestoreAdminSection(){var id=localStorage.getItem("TORVO_ADMIN_SECTION")||sessionStorage.getItem("TORVO_ADMIN_SECTION")||String(location.hash||"").replace("#admin-","")||"dashboard";if(!E(id))id="dashboard";openSection(id,torvoNavButton(id),"restore");history.replaceState({torvoSection:id},"","#admin-"+id);var sub=localStorage.getItem("TORVO_ADMIN_SUBPAGE")||"";if(sub){setTimeout(function(){var b=document.querySelector('[onclick*="'+sub.replace(/\"/g,'')+'"]');if(b)try{b.click()}catch(e){}},80)}}'''
assert s.count(old2)==1, 'restore function mismatch'
s=s.replace(old2,new2,1)
anchor='''window.addEventListener("load",function(){setTimeout(torvoRestoreAdminSection,120)});'''
insert='''document.addEventListener("click",function(e){var b=e.target.closest&&e.target.closest("button[onclick]");if(!b)return;var oc=b.getAttribute("onclick")||"";var m=oc.match(/^(settingsOpen|v26ItemMasterMode|v26SuitableMode|v26EmployeePanel|v27ReportProductMode|filterV21Orders)\\(([^)]*)\\)/);if(m){localStorage.setItem("TORVO_ADMIN_SUBPAGE",m[1]+"("+m[2]+")")}else if(oc.indexOf("openSection(")===0){localStorage.removeItem("TORVO_ADMIN_SUBPAGE")}},true);
'''
assert s.count(anchor)==1, 'load restore anchor mismatch'
s=s.replace(anchor,insert+anchor,1)
p.write_text(s,encoding='utf-8')
