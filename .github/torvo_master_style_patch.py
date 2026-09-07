from pathlib import Path
p=Path('admin.html')
s=p.read_text(encoding='utf-8')
marker='/* TORVO ADMIN MOBILE REFERENCE V22 */'
if marker not in s:
 css='''<style id="torvo-admin-mobile-reference-v22">/* TORVO ADMIN MOBILE REFERENCE V22 */
@media(max-width:640px){
 html,body{background:#f5f7fb!important;overflow-x:hidden!important}
 .app{display:block!important;min-height:100vh!important}
 .left{position:sticky!important;top:0!important;z-index:80!important;width:100%!important;height:64px!important;min-height:64px!important;overflow:hidden!important;padding:7px 10px!important;background:#121e2e!important;border:0!important;display:flex!important;align-items:center!important;gap:8px!important}
 .left .logo{font-size:22px!important;padding:6px 8px!important;white-space:nowrap!important}.left .sub,.left .menuTitle{display:none!important}
 .left .nav{display:none!important}
 .left .nav.active{display:flex!important;align-items:center!important;margin-left:auto!important;width:auto!important;min-height:38px!important;padding:8px 12px!important;background:#ef2636!important;color:#fff!important;border-radius:7px!important;box-shadow:none!important;white-space:nowrap!important}
 .main{padding:0 8px 20px!important;width:100%!important;min-width:0!important}
 .top{position:sticky!important;top:64px!important;z-index:70!important;margin:0 -8px 10px!important;padding:8px!important;min-height:54px!important;display:flex!important;gap:6px!important;background:#fff!important;border-bottom:1px solid #dce4ee!important}
 .top .title,.top .owner,.top .verifyBtn,.top .logout,.top .langBtn{display:none!important}
 .top .search{min-width:0!important;flex:1!important}.top .search input{height:38px!important;min-width:0!important;padding-right:72px!important;font-size:11px!important}
 .topBtn{height:38px!important;padding:0 9px!important}.bell button{height:38px!important;width:38px!important}
 .section.active{max-height:none!important;overflow:visible!important;padding-bottom:30px!important}
 .panel{margin-top:8px!important;padding:10px!important;border-radius:9px!important}
 .cards,.grid,.itemGrid,.reportGrid{grid-template-columns:1fr!important}.toolbar{gap:6px!important}.toolbar>*{max-width:100%!important}
 .field input,.field select,.field textarea{min-height:42px!important}.box{padding:10px!important}
 table{min-width:680px!important}.scroll{overflow-x:auto!important;-webkit-overflow-scrolling:touch!important}
 .torvo-ref-tabs{display:flex!important;overflow-x:auto!important;gap:4px!important;margin-bottom:10px!important}.torvo-ref-tab{flex:0 0 auto!important}
}
@media(min-width:641px){.left{height:100vh!important;position:sticky!important;top:0!important;overflow:auto!important}}
</style>'''
 s=s.replace('</head>',css+'\n</head>',1)
 # Correct visible labels while preserving all original click handlers and IDs.
 for a,b in {
  'ADD ITEM':'PRODUCTS','ITEM MASTER':'SPARE PARTS','SUITABLE SEARCH':'MACHINES',
  'MACHINE DRAWINGS':'ACCESSORIES','MACHINE DRAWING':'ACCESSORIES','MARKET ADD':'DEALERS'
 }.items():
  s=s.replace('>'+a+'<','>'+b+'<')
 # Insert approved Add Spare Part tabs statically. Check actual markup, not CSS text.
 if 'id="spareFormHost"' in s and '<div class="torvo-ref-tabs">' not in s:
  tabs='''<div class="torvo-ref-tabs"><button type="button" class="torvo-ref-tab active">BASIC DETAILS</button><button type="button" class="torvo-ref-tab">MACHINE FITMENT</button><button type="button" class="torvo-ref-tab">SUITABLE FOR</button><button type="button" class="torvo-ref-tab">PRICING & STOCK</button><button type="button" class="torvo-ref-tab">IMAGES & DOCUMENTS</button><button type="button" class="torvo-ref-tab">ADDITIONAL INFO</button></div>'''
  pos=s.find('id="spareFormHost"'); end=s.find('>',pos)
  if end<0: raise SystemExit('SPARE FORM HOST TAG END MISSING')
  s=s[:end+1]+tabs+s[end+1:]
p.write_text(s,encoding='utf-8')
