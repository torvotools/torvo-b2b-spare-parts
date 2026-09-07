from pathlib import Path
p=Path('admin.html')
s=p.read_text(encoding='utf-8')
marker='TORVO ADMIN CLEAN WORKSPACE V24'
if marker not in s:
 css='''<style id="torvo-admin-clean-v24">/* TORVO ADMIN CLEAN WORKSPACE V24 */
/* Dashboard must be software workspace, never the legacy finder screen */
#dashboard .v15SmartFilter,#dashboard .smartFilter,#dashboard .filterPanel,#dashboard .searchFilter,#dashboard .finderPanel{display:none!important}
#dashboard>#v23DashboardShell~*{display:none!important}
#v23DashboardShell{display:block!important;padding:2px 0 20px!important}
@media(min-width:641px){
.app{grid-template-columns:238px minmax(0,1fr)!important}.left{display:block!important;width:auto!important;height:100vh!important;position:sticky!important;top:0!important}.main{padding:0 20px 30px!important}.top{height:62px!important;display:flex!important}.v23PageHead{margin-top:18px!important}.v23Dashboard{grid-template-columns:repeat(4,minmax(150px,1fr))!important}.v23Work{grid-template-columns:2fr 1fr!important}.v23ActionGrid{grid-template-columns:repeat(3,1fr)!important}}
@media(max-width:640px){
body{background:#f4f6fa!important}.app{display:block!important}.left{height:58px!important;min-height:58px!important;position:sticky!important;top:0!important;z-index:90!important;padding:7px 12px!important;border-bottom:0!important}.left .logo{font-size:20px!important}.left .logo:before{content:'T';display:inline-flex;align-items:center;justify-content:center;width:42px;height:42px;margin-right:9px;border-radius:10px;background:#ff1535;color:#fff;font-size:25px;vertical-align:middle}.left .sub{display:inline!important;border:0!important;padding:0!important;margin-left:5px!important;font-size:9px!important}.left .nav.active{font-size:10px!important;padding:10px 13px!important}.main{padding:0 10px 24px!important}.top{position:sticky!important;top:58px!important;z-index:70!important;height:54px!important;margin:0 -10px 12px!important;padding:7px 10px!important;background:#fff!important}.top .search{min-width:0!important;width:100%!important}.top .search input{height:39px!important;font-size:11px!important;padding-right:78px!important}.top .searchBtn{width:44px!important;min-width:44px!important;padding:0!important}.bell button{width:44px!important}.v23PageHead{margin:8px 2px 10px!important}.v23PageHead h1{font-size:18px!important;line-height:1.05!important}.v23PageHead small{font-size:9px!important}.v23Quick .primary{padding:10px!important;font-size:9px!important}.v23Dashboard{grid-template-columns:repeat(2,minmax(0,1fr))!important;gap:8px!important}.v23Kpi{min-height:88px!important;border-radius:10px!important;padding:12px!important}.v23Kpi b{font-size:9px!important}.v23Kpi strong{font-size:25px!important}.v23Work{display:block!important}.v23WorkCard{min-height:0!important;margin-bottom:9px!important;padding:12px!important}.v23ActionGrid{grid-template-columns:repeat(2,minmax(0,1fr))!important;gap:8px!important}.v23ActionGrid button{min-height:62px!important}.section.active{overflow:visible!important}.torvo-ref-tabs{margin:0 0 10px!important}}
</style>'''
 s=s.replace('</head>',css+'\n</head>',1)
 # The legacy finder is before the dashboard shell in current markup; hide every dashboard child except V23 shell.
 css2='''<style id="torvo-dashboard-isolation-v24">#dashboard>*:not(#v23DashboardShell){display:none!important}#dashboard>#v23DashboardShell{display:block!important}</style>'''
 s=s.replace('</head>',css2+'\n</head>',1)
p.write_text(s,encoding='utf-8')
