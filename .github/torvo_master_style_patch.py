from pathlib import Path
p=Path('admin.html')
s=p.read_text(encoding='utf-8')
marker='/* TORVO SAFE APP SHELL V12 */'
if marker not in s:
    css='''<style id="torvo-safe-app-shell-v12">/* TORVO SAFE APP SHELL V12 */
:root{--torvo-red:#d71920;--torvo-navy:#111827;--torvo-bg:#f4f6f9;--torvo-line:#e5e7eb}
body{background:var(--torvo-bg)!important}.app{background:var(--torvo-bg)!important}.left{background:linear-gradient(180deg,#111827,#1b2638)!important;border-right:0!important}.left .logo{color:#fff!important}.left .sub{color:#aeb8c8!important;border-color:#334155!important}.left .menuTitle{background:transparent!important;color:#8290a6!important}.left .nav{border-color:transparent!important;background:transparent!important;color:#dce4ef!important;border-radius:9px!important}.left .nav:hover{background:#ffffff12!important;color:#fff!important}.left .nav.active{background:var(--torvo-red)!important;color:#fff!important;border-color:var(--torvo-red)!important}.main{background:var(--torvo-bg)!important}.top,.panel,.card,.dashboardCard,.box,.bizCard,.smartCard,.updateCard,.itemCard{border-color:var(--torvo-line)!important;box-shadow:0 3px 12px #0f172a0b!important}.top,.panel{border-radius:12px!important}.card,.dashboardCard,.box,.bizCard,.smartCard,.updateCard,.itemCard{border-radius:11px!important}.btn,.topBtn,.langBtn,.quickChip,.statusPill{border-radius:8px!important}.field input,.field select,.field textarea,.toolbar input,.toolbar select,.top .search input{border-radius:8px!important;border-color:#d9dee7!important}.right{background:#f8fafc!important;border-left-color:var(--torvo-line)!important}.right .menuTitle{background:transparent!important;color:#6b7280!important}.right .rnav{background:#fff!important;border-color:var(--torvo-line)!important;border-radius:8px!important}.right .rnav.active{background:var(--torvo-navy)!important;color:#fff!important;border-color:var(--torvo-navy)!important}
@media(max-width:760px){.main{padding:8px!important}.panel{border-radius:10px!important}.cards{gap:8px!important}}
</style>'''
    if '</head>' not in s: raise SystemExit('Head anchor not found')
    s=s.replace('</head>',css+'\n</head>',1)
p.write_text(s,encoding='utf-8')
