from pathlib import Path
p=Path('admin.html')
s=p.read_text(encoding='utf-8')
marker='/* TORVO EXACT ADMIN REFERENCE V21 */'
if marker not in s:
 css='''<style id="torvo-exact-admin-reference-v21">/* TORVO EXACT ADMIN REFERENCE V21 */
:root{--torvo-navy:#121e2e;--torvo-red:#ef2636;--torvo-blue:#1677ee;--torvo-bg:#f5f7fb;--torvo-line:#dce4ee;--torvo-text:#17243a;--torvo-muted:#75839a}
html,body{background:var(--torvo-bg)!important}.app{grid-template-columns:238px minmax(0,1fr) 0!important;min-height:100vh!important}.left{background:var(--torvo-navy)!important;color:#fff!important;border:0!important;padding:12px 10px!important}.right{display:none!important}.main{background:var(--torvo-bg)!important;padding:0 16px 24px!important;min-width:0!important}.logo{font-size:27px!important;color:#fff!important;font-weight:950!important;padding:10px!important}.sub{color:#94a4b8!important;border-color:#2a394d!important;padding:0 10px 15px!important}.left .menuTitle{background:transparent!important;color:#71839a!important;border:0!important;font-size:9px!important;letter-spacing:1px!important;padding:11px 10px 5px!important}.left .nav{background:transparent!important;color:#d7e0eb!important;border:0!important;border-radius:7px!important;margin:2px 0!important;padding:9px 10px!important;min-height:36px!important;font-weight:850!important}.left .nav.active{background:var(--torvo-red)!important;color:#fff!important;box-shadow:0 6px 14px #ef263633!important}.left .nav:hover{background:#1c2c41!important}.top{margin:0 -16px 14px!important;padding:10px 16px!important;min-height:62px!important;background:#fff!important;border:0!important;border-bottom:1px solid var(--torvo-line)!important;border-radius:0!important;box-shadow:0 2px 8px #20324b0a!important}.top .title{display:none!important}.top .search{flex:1!important}.top .search input{height:40px!important;border:1px solid var(--torvo-line)!important;border-radius:7px!important;background:#f8fafc!important}.panel,.box,.card,.dashboardCard{background:#fff!important;border:1px solid var(--torvo-line)!important;border-radius:9px!important;box-shadow:0 2px 9px #24364f0b!important}.panel{padding:13px!important}.pTitle{border-bottom:1px solid #e8edf3!important;padding-bottom:9px!important}.pTitle b{color:var(--torvo-text)!important}.box{padding:11px!important}.boxTitle{border-left:4px solid var(--torvo-blue)!important;padding-left:8px!important;color:var(--torvo-text)!important}.field input,.field select,.field textarea,.toolbar input,.toolbar select{border:1px solid #d4deea!important;border-radius:6px!important;background:#fff!important;min-height:37px!important}.btn{border-radius:6px!important;font-weight:900!important}.btn.red{background:var(--torvo-red)!important}.btn.blue{background:var(--torvo-blue)!important}table{background:#fff!important;border-collapse:separate!important;border-spacing:0!important}th{background:#f5f7fa!important;color:#40516a!important;font-size:9px!important}td{color:#45566e!important}.modal,.dialog,.popup{border-radius:10px!important}body,.nav,.menuTitle,.pTitle,.boxTitle,.field label,.btn,.mini,th,.tag,.chip,.quickChip,.topBtn,.langBtn{text-transform:uppercase!important}
.torvo-ref-tabs{display:flex;gap:5px;overflow:auto;margin:0 0 12px;padding:3px;background:#fff;border:1px solid var(--torvo-line);border-radius:8px}.torvo-ref-tab{white-space:nowrap;padding:9px 12px;border:0;border-radius:6px;background:#f4f7fb;color:#4a5b73;font-size:9px;font-weight:900}.torvo-ref-tab.active{background:var(--torvo-red);color:#fff}.section.active{overflow:auto!important;max-height:calc(100vh - 82px)!important;padding-bottom:30px!important}
@media(max-width:900px){.app{grid-template-columns:190px minmax(0,1fr) 0!important}.main{padding:0 9px 18px!important}.top{margin:0 -9px 10px!important;padding:8px 9px!important}}
@media(max-width:640px){.app{display:block!important}.left{width:100%!important;position:relative!important}.main{padding:0 7px 16px!important}.top{margin:0 -7px 8px!important}.section.active{max-height:none!important}.grid,.cards{grid-template-columns:1fr!important}}
</style>'''
 if '</head>' not in s: raise SystemExit('HEAD ANCHOR MISSING')
 s=s.replace('</head>',css+'\n</head>',1)
 # Static visible-text upgrades only; preserve existing IDs and event handlers.
 replacements={
  '>ADD ITEM<':'>PRODUCTS<',
  '>ITEM MASTER<':'>SPARE PARTS<',
  '>SUITABLE SEARCH<':'>MACHINES<',
  '>MACHINE DRAWING<':'>ACCESSORIES<',
  '>RECYCLE BIN<':'>BACKUP & LOGS<'
 }
 for a,b in replacements.items(): s=s.replace(a,b)
 # Add reference-style tabs to the existing spare form without runtime JS.
 host='id="spareFormHost"'
 if host in s and 'torvo-ref-tabs' not in s:
  tabs='''<div class="torvo-ref-tabs"><button type="button" class="torvo-ref-tab active">BASIC DETAILS</button><button type="button" class="torvo-ref-tab">MACHINE FITMENT</button><button type="button" class="torvo-ref-tab">SUITABLE FOR</button><button type="button" class="torvo-ref-tab">PRICING & STOCK</button><button type="button" class="torvo-ref-tab">IMAGES & DOCUMENTS</button><button type="button" class="torvo-ref-tab">ADDITIONAL INFO</button></div>'''
  pos=s.find(host); tag=s.rfind('<',0,pos); end=s.find('>',pos)
  if tag>=0 and end>=0: s=s[:end+1]+tabs+s[end+1:]
p.write_text(s,encoding='utf-8')
