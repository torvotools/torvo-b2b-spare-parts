from pathlib import Path
p=Path('admin.html')
s=p.read_text(encoding='utf-8')
# 1) Lock background while Manage Brand popup is open.
old='''function torvoOpenBrandManager(){torvoEnsureBrandUI();E("torvoBrandManager").classList.add("show");E("torvoBrandNew").value="";E("torvoBrandSearch").value="";E("torvoBrandMsg").textContent="";torvoRenderBrands();setTimeout(function(){E("torvoBrandNew").focus()},30)}
function torvoCloseBrandManager(){var x=E("torvoBrandManager");if(x)x.classList.remove("show")}'''
new='''function torvoOpenBrandManager(){torvoEnsureBrandUI();window.torvoBrandScrollY=window.scrollY||0;document.body.classList.add("torvoModalOpen");document.body.style.top="-"+window.torvoBrandScrollY+"px";E("torvoBrandManager").classList.add("show");E("torvoBrandNew").value="";E("torvoBrandSearch").value="";E("torvoBrandMsg").textContent="";torvoRenderBrands();setTimeout(function(){E("torvoBrandNew").focus()},30)}
function torvoCloseBrandManager(){var x=E("torvoBrandManager");if(x)x.classList.remove("show");document.body.classList.remove("torvoModalOpen");document.body.style.top="";window.scrollTo(0,window.torvoBrandScrollY||0)}'''
assert s.count(old)==1, 'Brand popup functions mismatch'
s=s.replace(old,new,1)
# 2) Preserve current Admin section on refresh and make browser Back move one section at a time.
old='''function openSection(id,btn){
 v30UpdateFinderVisibility(id);'''
new='''var torvoNavReady=false;
function torvoNavButton(id){return Array.from(document.querySelectorAll(".nav,.rnav")).find(function(b){return (b.getAttribute("onclick")||"").indexOf("openSection('"+id+"'")>=0})||null}
function openSection(id,btn,navMode){
 if(!E(id))return;
 if(navMode!=="restore"&&navMode!=="pop"){var cur=sessionStorage.getItem("TORVO_ADMIN_SECTION")||"dashboard";if(torvoNavReady&&cur!==id){history.pushState({torvoSection:id},"","#admin-"+id)}else if(!torvoNavReady){history.replaceState({torvoSection:id},"","#admin-"+id)}}
 sessionStorage.setItem("TORVO_ADMIN_SECTION",id);torvoNavReady=true;
 v30UpdateFinderVisibility(id);'''
assert s.count(old)==1, 'openSection start mismatch'
s=s.replace(old,new,1)
anchor='''function goHome(){sndAlert();'''
insert='''window.addEventListener("popstate",function(e){var id=(e.state&&e.state.torvoSection)||String(location.hash||"").replace("#admin-","")||"dashboard";if(E(id))openSection(id,torvoNavButton(id),"pop")});
window.addEventListener("DOMContentLoaded",function(){setTimeout(function(){var id=String(location.hash||"").replace("#admin-","")||sessionStorage.getItem("TORVO_ADMIN_SECTION")||"dashboard";if(!E(id))id="dashboard";openSection(id,torvoNavButton(id),"restore");history.replaceState({torvoSection:id},"","#admin-"+id)},0)});
'''
assert s.count(anchor)==1, 'goHome anchor mismatch'
s=s.replace(anchor,insert+anchor,1)
# CSS for fixed body behind popup.
marker='</style></head>'
css='''.torvoModalOpen{position:fixed!important;left:0;right:0;width:100%;overflow:hidden!important}'''
assert marker in s
s=s.replace(marker,css+marker,1)
p.write_text(s,encoding='utf-8')
