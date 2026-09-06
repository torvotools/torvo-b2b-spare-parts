from pathlib import Path
p=Path('admin.html')
s=p.read_text(encoding='utf-8')
marker='/* TORVO MASTER CONTROLS COMPLETE V8 */'
if marker not in s:
    # Item Number + Product Name: add explicit dropdown arrows, keep one red + button.
    old='<div class="field"><label>ITEM NUMBER *</label><div class="masterRow"><input id="pNo" class="upper" list="itemNoMasterList"><button class="mini" onclick="addItemIdentityMaster(&quot;number&quot;)">+</button><button class="mini edit" onclick="editItemIdentityMaster(&quot;number&quot;)">✎</button><button class="mini del" onclick="deleteItemIdentityMaster(&quot;number&quot;)">🗑</button></div><datalist id="itemNoMasterList"></datalist></div>'
    new='<div class="field torvoBrandField"><label>ITEM NUMBER *</label><div class="masterRow torvoBrandMasterRow"><div class="torvoBrandInputWrap"><input id="pNo" class="upper" list="itemNoMasterList"><button class="torvoBrandDropBtn" type="button" onclick="torvoToggleIdentityDropdown(&quot;number&quot;)" title="Select Item Number">▼</button></div><button class="mini torvoBrandAddBtn" type="button" onclick="torvoOpenIdentityManager(&quot;number&quot;)" title="Manage Item Number">+</button></div><div id="torvoNumberDropdown" class="torvoBrandDropdown"></div><datalist id="itemNoMasterList"></datalist></div>'
    if old not in s: raise SystemExit('Item Number target not found; no change made')
    s=s.replace(old,new,1)
    old='<div class="field"><label>PRODUCT NAME *</label><div class="masterRow"><input id="pName" class="upper" list="productNameMasterList" list="productNameMasterList"><button class="mini" onclick="addItemIdentityMaster(&quot;name&quot;)">+</button><button class="mini edit" onclick="editItemIdentityMaster(&quot;name&quot;)">✎</button><button class="mini del" onclick="deleteItemIdentityMaster(&quot;name&quot;)">🗑</button></div><datalist id="productNameMasterList"></datalist></div>'
    new='<div class="field torvoBrandField"><label>PRODUCT NAME *</label><div class="masterRow torvoBrandMasterRow"><div class="torvoBrandInputWrap"><input id="pName" class="upper" list="productNameMasterList"><button class="torvoBrandDropBtn" type="button" onclick="torvoToggleIdentityDropdown(&quot;name&quot;)" title="Select Product Name">▼</button></div><button class="mini torvoBrandAddBtn" type="button" onclick="torvoOpenIdentityManager(&quot;name&quot;)" title="Manage Product Name">+</button></div><div id="torvoNameDropdown" class="torvoBrandDropdown"></div><datalist id="productNameMasterList"></datalist></div>'
    if old not in s: raise SystemExit('Product Name target not found; no change made')
    s=s.replace(old,new,1)

    # Replace Category delete with compact dedicated security popup.
    start='function torvoDeleteCategory(btn){'
    end='function torvoToggleCategoryDropdown()'
    a=s.find(start); b=s.find(end,a)
    if a<0 or b<0: raise SystemExit('Category delete function block not found; no change made')
    # Preserve functions between delete and toggle by replace only exact function using brace scan.
    i=a; depth=0; quote=None; esc=False; j=None
    while i<len(s):
        c=s[i]
        if quote:
            if esc: esc=False
            elif c=='\\': esc=True
            elif c==quote: quote=None
        else:
            if c in "'\"": quote=c
            elif c=='{': depth+=1
            elif c=='}':
                depth-=1
                if depth==0:
                    j=i+1; break
        i+=1
    if not j: raise SystemExit('Category delete parse failed')
    newdel='''function torvoDeleteCategory(btn){var v=U(btn.getAttribute("data-v")||"");if(!v)return;var use=masterUsage("category",v);if(use>0)return torvoCategoryMessage("DELETE BLOCKED — "+v+" IS USED IN "+use+" RECORD(S)",true);torvoOpenDeleteSecurity("CATEGORY",v,function(){DB.categories=(DB.categories||[]).filter(function(x){return N(x)!==N(v)});if(E("pCategory")&&N(E("pCategory").value)===N(v))E("pCategory").value="";logActivity("MASTER DELETED: "+v);saveDB();torvoCategoryMessage("CATEGORY DELETED — "+v,false);torvoRenderCategories()})}'''
    s=s[:a]+newdel+s[j:]

    anchor='function previewPhoto(slot,file)'
    if anchor not in s: raise SystemExit('JS anchor not found; no change made')
    js=r'''/* TORVO MASTER CONTROLS COMPLETE V8 */
function torvoCloseAllMasterDropdowns(except){["torvoBrandDropdown","torvoCategoryDropdown","torvoNumberDropdown","torvoNameDropdown"].forEach(function(id){if(id!==except){var x=E(id);if(x)x.classList.remove("show")}})}
function torvoIdentityValues(type){return Array.from(new Set((DB.items||[]).map(function(x){return U(type==="number"?x.no:x.name)}).filter(Boolean))).sort()}
function torvoToggleIdentityDropdown(type){var id=type==="number"?"torvoNumberDropdown":"torvoNameDropdown",box=E(id);if(!box)return;var was=box.classList.contains("show");torvoCloseAllMasterDropdowns(id);box.classList.toggle("show",!was);if(was)return;box.innerHTML=torvoIdentityValues(type).map(function(v){return '<button type="button" data-v="'+H(v)+'" onclick="torvoSelectIdentity(this,\''+type+'\')">'+H(v)+'</button>'}).join("")||'<div class="torvoBrandEmpty">NO VALUE ADDED</div>'}
function torvoSelectIdentity(btn,type){var x=E(type==="number"?"pNo":"pName");if(x)x.value=btn.getAttribute("data-v")||"";torvoCloseAllMasterDropdowns()}
function torvoEnsureIdentityUI(){if(E("torvoIdentityManager"))return;var d=document.createElement("div");d.id="torvoIdentityManager";d.className="torvoBrandOverlay torvoTopMasterOverlay";d.innerHTML='<div class="torvoBrandCard"><div class="torvoBrandHead"><b id="torvoIdentityTitle">MANAGE</b><button type="button" onclick="torvoCloseIdentityManager()">×</button></div><div class="torvoBrandAdd"><input id="torvoIdentityNew" class="upper"><button type="button" onclick="torvoSaveIdentity()">+ ADD</button></div><div id="torvoIdentityMsg" class="torvoBrandMsg"></div><input id="torvoIdentitySearch" class="torvoBrandSearch upper" oninput="torvoRenderIdentity()"><div id="torvoIdentityRows" class="torvoBrandRows"></div></div>';document.body.appendChild(d)}
function torvoOpenIdentityManager(type){torvoEnsureIdentityUI();torvoCloseAllMasterDropdowns();window.torvoIdentityType=type;var label=type==="number"?"ITEM NUMBER":"PRODUCT NAME";E("torvoIdentityTitle").textContent="MANAGE "+label;E("torvoIdentityNew").placeholder="ADD "+label;E("torvoIdentitySearch").placeholder="SEARCH "+label;E("torvoIdentityNew").value="";E("torvoIdentityNew").removeAttribute("data-edit");E("torvoIdentitySearch").value="";E("torvoIdentityMsg").textContent="";E("torvoIdentityManager").classList.add("show");torvoRenderIdentity()}
function torvoCloseIdentityManager(){var x=E("torvoIdentityManager");if(x)x.classList.remove("show")}
function torvoIdentityMessage(t,bad){var x=E("torvoIdentityMsg");if(x){x.textContent=t;x.className="torvoBrandMsg "+(bad?"bad":"ok")}}
function torvoRenderIdentity(){var type=window.torvoIdentityType||"number",q=N(E("torvoIdentitySearch")?E("torvoIdentitySearch").value:"");var a=torvoIdentityValues(type).filter(function(v){return !q||N(v).includes(q)});E("torvoIdentityRows").innerHTML=a.length?a.map(function(v){return '<div class="torvoBrandRow"><span>'+H(v)+'</span><button type="button" class="torvoBrandEdit" data-v="'+H(v)+'" onclick="torvoEditIdentity(this)" title="Edit">✎</button><button type="button" class="torvoBrandDelete" data-v="'+H(v)+'" onclick="torvoDeleteIdentity(this)" title="Delete">🗑</button></div>'}).join(""):'<div class="torvoBrandEmpty">NO VALUE FOUND</div>'}
function torvoSaveIdentity(){var type=window.torvoIdentityType||"number",n=E("torvoIdentityNew"),v=U((n.value||"").trim()),old=U(n.getAttribute("data-edit")||"");if(!v)return torvoIdentityMessage("ENTER VALUE",true);if(torvoIdentityValues(type).some(function(x){return N(x)===N(v)&&N(x)!==N(old)}))return torvoIdentityMessage("ALREADY EXISTS — "+v,true);if(old){(DB.items||[]).forEach(function(x){if(N(type==="number"?x.no:x.name)===N(old)){if(type==="number")x.no=v;else x.name=v}});n.removeAttribute("data-edit");logActivity("MASTER EDITED: "+old+" → "+v);saveDB();var f=E(type==="number"?"pNo":"pName");if(f&&N(f.value)===N(old))f.value=v;n.value="";torvoIdentityMessage("✓ SUCCESSFUL — "+v+" UPDATED",false);return torvoRenderIdentity()}var f=E(type==="number"?"pNo":"pName");if(f)f.value=v;n.value="";torvoIdentityMessage("✓ "+v+" READY — SAVE ITEM TO ADD",false)}
function torvoEditIdentity(btn){var type=window.torvoIdentityType||"number",v=U(btn.getAttribute("data-v")||"");var n=E("torvoIdentityNew");n.value=v;n.setAttribute("data-edit",v);n.focus();torvoIdentityMessage("EDIT "+v+" ABOVE, THEN PRESS + ADD",false)}
function torvoDeleteIdentity(btn){var type=window.torvoIdentityType||"number",v=U(btn.getAttribute("data-v")||"");var used=(DB.items||[]).filter(function(x){return N(type==="number"?x.no:x.name)===N(v)}).length;if(used>0)return torvoIdentityMessage("DELETE BLOCKED — "+v+" IS USED IN "+used+" ITEM(S)",true);torvoOpenDeleteSecurity(type==="number"?"ITEM NUMBER":"PRODUCT NAME",v,function(){torvoIdentityMessage("DELETED — "+v,false);torvoRenderIdentity()})}
function torvoEnsureDeleteSecurity(){if(E("torvoDeleteSecurity"))return;var d=document.createElement("div");d.id="torvoDeleteSecurity";d.className="torvoDeleteOverlay";d.innerHTML='<div class="torvoDeleteCard"><b>DELETE SECURITY</b><button class="torvoDeleteX" type="button" onclick="torvoCloseDeleteSecurity()">×</button><div class="torvoDeleteWhat" id="torvoDeleteWhat"></div><div class="torvoDeleteWarn">THIS RECORD WILL BE DELETED. ENTER SECURITY CODE TO CONTINUE.</div><input id="torvoDeleteCode" inputmode="numeric" maxlength="4" placeholder="ENTER DELETE CODE"><div id="torvoDeleteError" class="torvoDeleteError"></div><div class="torvoDeleteActions"><button type="button" onclick="torvoCloseDeleteSecurity()">CANCEL</button><button class="danger" type="button" onclick="torvoConfirmDeleteSecurity()">DELETE</button></div></div>';document.body.appendChild(d)}
function torvoOpenDeleteSecurity(type,value,done){torvoEnsureDeleteSecurity();window.torvoDeleteDone=done;E("torvoDeleteWhat").textContent=type+" TO DELETE: "+value;E("torvoDeleteCode").value="";E("torvoDeleteError").textContent="";E("torvoDeleteSecurity").classList.add("show");setTimeout(function(){E("torvoDeleteCode").focus()},20)}
function torvoCloseDeleteSecurity(){var x=E("torvoDeleteSecurity");if(x)x.classList.remove("show");window.torvoDeleteDone=null}
function torvoConfirmDeleteSecurity(){if((E("torvoDeleteCode").value||"").trim()!=="1122"){E("torvoDeleteError").textContent="WRONG DELETE CODE";return}var fn=window.torvoDeleteDone;torvoCloseDeleteSecurity();if(typeof fn==="function")fn()}
'''
    s=s.replace(anchor,js+anchor,1)

    # Make Brand and Category dropdowns mutually exclusive without observers/hover handlers.
    s=s.replace('function torvoToggleBrandDropdown(){var box=E("torvoBrandDropdown");if(!box)return;', 'function torvoToggleBrandDropdown(){torvoCloseAllMasterDropdowns("torvoBrandDropdown");var box=E("torvoBrandDropdown");if(!box)return;',1)
    s=s.replace('function torvoToggleCategoryDropdown(){var box=E("torvoCategoryDropdown");if(!box)return;', 'function torvoToggleCategoryDropdown(){torvoCloseAllMasterDropdowns("torvoCategoryDropdown");var box=E("torvoCategoryDropdown");if(!box)return;',1)

    css='''<style id="torvo-master-controls-complete-v8">.torvoTopMasterOverlay{align-items:flex-start!important;padding-top:12vh!important}.torvoDeleteOverlay{display:none;position:fixed;inset:0;z-index:10050;background:#0007;align-items:flex-start;justify-content:center;padding-top:18vh}.torvoDeleteOverlay.show{display:flex}.torvoDeleteCard{position:relative;width:min(92vw,390px);background:#fff;border-radius:12px;padding:16px;box-shadow:0 18px 50px #0005}.torvoDeleteCard>b{font-size:14px}.torvoDeleteX{position:absolute;right:10px;top:9px;width:32px;height:32px;border:0;border-radius:7px;font-size:18px}.torvoDeleteWhat{margin-top:16px;padding:10px;border-radius:7px;background:#fff1f2;color:#991b1b;font-weight:900}.torvoDeleteWarn{margin:8px 0;color:#d71920;font-size:10px;font-weight:800}.torvoDeleteCard input{width:100%;padding:10px;border:1px solid #ced8e3;border-radius:7px}.torvoDeleteError{min-height:18px;padding-top:5px;color:#d71920;font-weight:900}.torvoDeleteActions{display:flex;justify-content:flex-end;gap:7px;margin-top:7px}.torvoDeleteActions button{border:0;border-radius:7px;padding:8px 13px;font-weight:900}.torvoDeleteActions .danger{background:#d71920;color:#fff}@media(max-width:700px){.torvoTopMasterOverlay{padding-top:9vh!important}.torvoDeleteOverlay{padding-top:14vh}}</style>'''
    if '</head>' not in s: raise SystemExit('Head anchor not found')
    s=s.replace('</head>',css+'\n</head>',1)
p.write_text(s,encoding='utf-8')
