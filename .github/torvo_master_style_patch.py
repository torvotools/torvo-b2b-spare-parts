from pathlib import Path
p=Path('admin.html')
s=p.read_text(encoding='utf-8')
marker='/* TORVO CATEGORY DROPDOWN V6 */'
if marker not in s:
    old='<div class="field"><label>CATEGORY *</label><div class="masterRow"><input id="pCategory" class="upper" list="catX"><button class="mini" onclick="addMaster(&quot;category&quot;,&quot;pCategory&quot;)">+</button><button class="mini edit" onclick="editMaster(&quot;category&quot;,&quot;pCategory&quot;)">✎</button><button class="mini del" onclick="deleteMaster(&quot;category&quot;,&quot;pCategory&quot;)">🗑</button></div>'
    new='<div class="field torvoCategoryField"><label>CATEGORY *</label><div class="masterRow"><div class="torvoCategoryInputWrap"><input id="pCategory" class="upper" list="catX"><button class="torvoCategoryDropBtn" type="button" onclick="torvoToggleCategoryDropdown()">▼</button></div><button class="mini torvoCategoryAddBtn" type="button" onclick="torvoOpenCategoryManager()">+</button></div><div id="torvoCategoryDropdown" class="torvoCategoryDropdown"></div>'
    if old not in s: raise SystemExit('Category target not found; no change made')
    s=s.replace(old,new,1)
    css='''<style id="torvo-category-dropdown-v6">/* TORVO CATEGORY DROPDOWN V6 */
.torvoCategoryField{position:relative}.torvoCategoryField .masterRow{display:flex!important;gap:6px!important}.torvoCategoryInputWrap{position:relative;flex:1;min-width:0}.torvoCategoryInputWrap input{width:100%!important;padding-right:34px!important}.torvoCategoryDropBtn{position:absolute;right:2px;top:2px;bottom:2px;width:30px;border:0;background:#f1f5f9;border-radius:5px;font-weight:900}.torvoCategoryAddBtn{background:#d71920!important;color:#fff!important;border-color:#d71920!important}.torvoCategoryDropdown{display:none;position:absolute;left:0;right:44px;top:100%;z-index:90;background:#fff;border:1px solid #ced8e3;border-radius:8px;box-shadow:0 8px 24px #0002;max-height:190px;overflow:auto}.torvoCategoryDropdown.show{display:block}.torvoCategoryDropdown button{display:block;width:100%;border:0;border-bottom:1px solid #edf1f5;background:#fff;text-align:left;padding:9px;font-weight:700}
</style>'''
    js='''<script>
function torvoCategoryNames(){return Array.from(new Set([].concat(DB.categories||[],(DB.items||[]).map(function(x){return x.category})).filter(Boolean).map(U))).sort()}
function torvoToggleCategoryDropdown(){var b=E("torvoCategoryDropdown");if(!b)return;var o=b.classList.toggle("show");if(o)b.innerHTML=torvoCategoryNames().map(function(v){return '<button type="button" data-v="'+H(v)+'" onclick="torvoSelectCategory(this)">'+H(v)+'</button>'}).join("")||'<div style="padding:9px">NO CATEGORY ADDED</div>'}
function torvoSelectCategory(x){if(E("pCategory"))E("pCategory").value=x.getAttribute("data-v")||"";var b=E("torvoCategoryDropdown");if(b)b.classList.remove("show")}
function torvoOpenCategoryManager(){var v=U((window.prompt("ADD CATEGORY NAME")||"").trim());if(!v)return;if(torvoCategoryNames().some(function(x){return N(x)===N(v)}))return toast("ALREADY EXISTS — "+v,"error");DB.categories=DB.categories||[];DB.categories.push(v);if(E("pCategory"))E("pCategory").value=v;saveDB();toast("✓ SUCCESSFUL — "+v+" ADDED","success")}
</script>'''
    s=s.replace('</head>',css+'</head>',1)
    s=s.replace('</body>',js+'</body>',1)
p.write_text(s,encoding='utf-8')
