from pathlib import Path
p=Path('admin.html')
s=p.read_text(encoding='utf-8')
marker='/* TORVO FIXED SOFTWARE WORKSPACE V14 */'
if marker not in s:
    css='''<style id="torvo-fixed-software-workspace-v14">/* TORVO FIXED SOFTWARE WORKSPACE V14 */
@media(min-width:761px){
html,body{height:100%!important;overflow:hidden!important}.app{height:100vh!important;max-height:100vh!important;overflow:hidden!important;align-items:stretch!important}.left,.right{height:100vh!important;max-height:100vh!important;overflow-y:auto!important;overscroll-behavior:contain!important;scrollbar-width:thin!important}.main{height:100vh!important;max-height:100vh!important;overflow:hidden!important;display:flex!important;flex-direction:column!important;min-width:0!important}.top{position:relative!important;flex:0 0 auto!important;margin-bottom:0!important;z-index:20!important}.main>.panel{flex:1 1 auto!important;min-height:0!important;max-height:calc(100vh - 82px)!important;overflow-y:auto!important;overflow-x:hidden!important;overscroll-behavior:contain!important;scrollbar-width:thin!important}.main>.panel>.scroll,.main>.panel .scroll{max-height:calc(100vh - 235px)!important;overflow:auto!important;overscroll-behavior:contain!important}.pTitle{position:sticky!important;top:-14px!important;z-index:8!important;background:#fff!important;padding-top:14px!important}.toolbar{position:sticky!important;top:38px!important;z-index:7!important;background:#fff!important;padding-top:5px!important;padding-bottom:7px!important}.left .logo{position:sticky!important;top:0!important;z-index:9!important;background:#111827!important}.left::-webkit-scrollbar,.right::-webkit-scrollbar,.main>.panel::-webkit-scrollbar,.scroll::-webkit-scrollbar{width:7px!important;height:7px!important}.left::-webkit-scrollbar-thumb,.right::-webkit-scrollbar-thumb,.main>.panel::-webkit-scrollbar-thumb,.scroll::-webkit-scrollbar-thumb{background:#94a3b855!important;border-radius:9px!important}
}
@media(max-width:760px){html,body{overflow:auto!important}.app{height:auto!important;max-height:none!important}.main{height:auto!important;max-height:none!important;overflow:visible!important}.main>.panel{max-height:none!important;overflow:visible!important}.main>.panel .scroll{max-height:62vh!important;overflow:auto!important}.pTitle,.toolbar{position:relative!important;top:auto!important}}
</style>'''
    if '</head>' not in s: raise SystemExit('Head anchor not found')
    s=s.replace('</head>',css+'\n</head>',1)
p.write_text(s,encoding='utf-8')
