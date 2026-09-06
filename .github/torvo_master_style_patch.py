from pathlib import Path
p=Path('admin.html')
s=p.read_text(encoding='utf-8')
marker='/* TORVO MASTER DROPDOWN CLEANUP V9 */'
if marker not in s:
    # Remove native datalist behavior from the four custom-master inputs.
    for field,lst in [('pNo','itemNoMasterList'),('pName','productNameMasterList'),('pBrand','brandList'),('pCategory','catX')]:
        s=s.replace('id="'+field+'" class="upper" list="'+lst+'"','id="'+field+'" class="upper" autocomplete="off"',1)

    # Keep only one custom dropdown open at a time, even when another arrow is clicked.
    s=s.replace('function torvoToggleBrandDropdown(){torvoCloseAllMasterDropdowns("torvoBrandDropdown");var box=E("torvoBrandDropdown");if(!box)return;var open=box.classList.toggle("show");', 'function torvoToggleBrandDropdown(){var box=E("torvoBrandDropdown");if(!box)return;var was=box.classList.contains("show");torvoCloseAllMasterDropdowns();if(was)return;box.classList.add("show");var open=true;',1)
    s=s.replace('function torvoToggleCategoryDropdown(){torvoCloseAllMasterDropdowns("torvoCategoryDropdown");var box=E("torvoCategoryDropdown");if(!box)return;var open=box.classList.toggle("show");', 'function torvoToggleCategoryDropdown(){var box=E("torvoCategoryDropdown");if(!box)return;var was=box.classList.contains("show");torvoCloseAllMasterDropdowns();if(was)return;box.classList.add("show");var open=true;',1)

    # Security dialog must sit visibly above any Manage popup.
    css='''<style id="torvo-master-dropdown-cleanup-v9">/* TORVO MASTER DROPDOWN CLEANUP V9 */
#torvoDeleteSecurity.torvoDeleteOverlay{z-index:2147483647!important;background:rgba(0,0,0,.58)!important;padding-top:8vh!important}
#torvoDeleteSecurity .torvoDeleteCard{z-index:2147483647!important;box-shadow:0 22px 70px rgba(0,0,0,.55)!important;border:2px solid #d71920!important}
.torvoBrandEdit,.torvoBrandDelete{display:inline-flex!important;align-items:center!important;justify-content:center!important;width:30px!important;height:30px!important;padding:0!important;border:0!important;border-radius:6px!important;font-size:14px!important;font-weight:900!important}
.torvoBrandEdit{background:#eef5ff!important;color:#1268d5!important}.torvoBrandDelete{background:#fff0f1!important;color:#d71920!important}
</style>'''
    if '</head>' not in s: raise SystemExit('Head anchor not found; no change made')
    s=s.replace('</head>',css+'\n</head>',1)
p.write_text(s,encoding='utf-8')
