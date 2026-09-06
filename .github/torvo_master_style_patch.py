from pathlib import Path
p=Path('admin.html')
s=p.read_text(encoding='utf-8')
marker='/* TORVO BRAND MATCH CATEGORY V10 */'
if marker not in s:
    old='''function torvoRenderBrands(){var q=N(E("torvoBrandSearch")?E("torvoBrandSearch").value:"");var a=torvoBrandNames().filter(function(v){return !q||N(v).includes(q)});E("torvoBrandRows").innerHTML=a.length?a.map(function(v){return '<div class="torvoBrandRow"><span>'+H(v)+'</span><div><button type="button" class="edit torvoBrandIconBtn" title="Edit" aria-label="Edit" data-brand="'+H(v)+'" onclick="torvoEditBrand(this)">✎</button><button type="button" class="del torvoBrandIconBtn" title="Delete" aria-label="Delete" data-brand="'+H(v)+'" onclick="torvoDeleteBrand(this)">🗑</button></div></div>'}).join(""):'<div class="torvoBrandEmpty">NO BRAND FOUND</div>'}'''
    new='''function torvoRenderBrands(){var q=N(E("torvoBrandSearch")?E("torvoBrandSearch").value:"");var a=torvoBrandNames().filter(function(v){return !q||N(v).includes(q)});E("torvoBrandRows").innerHTML=a.length?a.map(function(v){return '<div class="torvoBrandRow"><span>'+H(v)+'</span><button type="button" class="torvoBrandEdit" title="Edit" aria-label="Edit" data-brand="'+H(v)+'" onclick="torvoEditBrand(this)">✎</button><button type="button" class="torvoBrandDelete" title="Delete" aria-label="Delete" data-brand="'+H(v)+'" onclick="torvoDeleteBrand(this)">🗑</button></div>'}).join(""):'<div class="torvoBrandEmpty">NO BRAND FOUND</div>'}'''
    if old not in s: raise SystemExit('Brand renderer target not found; no change made')
    s=s.replace(old,new,1)
    old='''function torvoEditBrand(btn){var old=btn.getAttribute("data-brand"),use=masterUsage("brand",old);if(use>0)return torvoBrandMessage("VALUE USED IN "+use+" RECORD(S). CHANGE LINKED RECORD FIRST",true);var v=U((prompt("EDIT BRAND",old)||"").trim());if(!v)return;if(torvoBrandNames().some(function(x){return N(x)===N(v)&&N(x)!==N(old)}))return torvoBrandMessage("NEW VALUE ALREADY EXISTS",true);DB.brands=DB.brands.map(function(x){return N(x)===N(old)?v:x});if(E("pBrand")&&N(E("pBrand").value)===N(old))E("pBrand").value=v;logActivity("MASTER EDITED: "+old+" → "+v);saveDB();torvoBrandMessage("✓ SUCCESSFUL — BRAND UPDATED",false);torvoRenderBrands()}'''
    new='''function torvoEditBrand(btn){var old=U(btn.getAttribute("data-brand")||""),use=masterUsage("brand",old);if(use>0)return torvoBrandMessage("VALUE USED IN "+use+" RECORD(S). CHANGE LINKED RECORD FIRST",true);var n=E("torvoBrandNew");n.value=old;n.setAttribute("data-edit",old);n.focus();torvoBrandMessage("EDIT "+old+" ABOVE, THEN PRESS + ADD",false)}'''
    if old not in s: raise SystemExit('Brand edit target not found; no change made')
    s=s.replace(old,new,1)
    old='''function torvoAddBrand(){var v=U((E("torvoBrandNew").value||"").trim());if(!v)return torvoBrandMessage("ENTER BRAND NAME",true);if(torvoBrandNames().some(function(x){return N(x)===N(v)}))return torvoBrandMessage("BRAND ALREADY EXISTS",true);DB.brands.push(v);if(E("pBrand"))E("pBrand").value=v;logActivity("MASTER ADDED: "+v);saveDB();E("torvoBrandNew").value="";torvoBrandMessage("✓ SUCCESSFUL — "+v+" ADDED",false);torvoRenderBrands()}'''
    new='''function torvoAddBrand(){var n=E("torvoBrandNew"),v=U((n.value||"").trim()),old=U(n.getAttribute("data-edit")||"");if(!v)return torvoBrandMessage("ENTER BRAND NAME",true);if(old){if(torvoBrandNames().some(function(x){return N(x)===N(v)&&N(x)!==N(old)}))return torvoBrandMessage("BRAND ALREADY EXISTS",true);DB.brands=(DB.brands||[]).map(function(x){return N(x)===N(old)?v:x});n.removeAttribute("data-edit");if(E("pBrand")&&N(E("pBrand").value)===N(old))E("pBrand").value=v;logActivity("MASTER EDITED: "+old+" → "+v);saveDB();n.value="";torvoBrandMessage("✓ SUCCESSFUL — "+v+" UPDATED",false);return torvoRenderBrands()}if(torvoBrandNames().some(function(x){return N(x)===N(v)}))return torvoBrandMessage("BRAND ALREADY EXISTS",true);DB.brands=DB.brands||[];DB.brands.push(v);if(E("pBrand"))E("pBrand").value=v;logActivity("MASTER ADDED: "+v);saveDB();n.value="";torvoBrandMessage("✓ SUCCESSFUL — "+v+" ADDED",false);torvoRenderBrands()}'''
    if old not in s: raise SystemExit('Brand add target not found; no change made')
    s=s.replace(old,new,1)
    start=s.find('function torvoDeleteBrand(btn){')
    end=s.find('function torvoConfirmBrandDelete(btn){',start)
    if start<0 or end<0: raise SystemExit('Brand delete target not found; no change made')
    # replace old delete function only
    i=start; depth=0; quote=None; esc=False; j=None
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
                if depth==0: j=i+1; break
        i+=1
    if not j: raise SystemExit('Brand delete parse failed')
    newdel='''function torvoDeleteBrand(btn){var v=U(btn.getAttribute("data-brand")||""),use=masterUsage("brand",v);if(use>0)return torvoBrandMessage("DELETE BLOCKED — "+v+" IS USED IN "+use+" RECORD(S)",true);torvoOpenDeleteSecurity("BRAND",v,function(){DB.brands=(DB.brands||[]).filter(function(x){return N(x)!==N(v)});if(E("pBrand")&&N(E("pBrand").value)===N(v))E("pBrand").value="";logActivity("MASTER DELETED: "+v);saveDB();sndDelete();torvoBrandMessage("✓ SUCCESSFUL — "+v+" DELETED",false);torvoRenderBrands()})}'''
    s=s[:start]+newdel+s[j:]
    # Remove obsolete inline-confirm function so old CODE 1122 UI cannot be used.
    start=s.find('function torvoConfirmBrandDelete(btn){')
    if start>=0:
        i=start; depth=0; quote=None; esc=False; j=None
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
                    if depth==0: j=i+1; break
            i+=1
        if j: s=s[:start]+s[j:]
    css='''<style id="torvo-brand-match-category-v10">/* TORVO BRAND MATCH CATEGORY V10 */
#torvoBrandManager .torvoBrandRow{display:grid!important;grid-template-columns:minmax(0,1fr) 34px 34px!important;align-items:center!important}
#torvoBrandManager .torvoBrandEdit,#torvoBrandManager .torvoBrandDelete{display:inline-flex!important;align-items:center!important;justify-content:center!important;width:30px!important;height:30px!important;padding:0!important;border:0!important;border-radius:6px!important;font-size:14px!important;font-weight:900!important}
#torvoBrandManager .torvoBrandEdit{background:#eef5ff!important;color:#1268d5!important}#torvoBrandManager .torvoBrandDelete{background:#fff0f1!important;color:#d71920!important}
</style>'''
    if '</head>' not in s: raise SystemExit('Head anchor not found')
    s=s.replace('</head>',css+'\n</head>',1)
p.write_text(s,encoding='utf-8')
