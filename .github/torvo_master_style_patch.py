from pathlib import Path
p=Path('admin.html')
s=p.read_text(encoding='utf-8')
marker='/* TORVO SOFTWARE WORKSPACE FIX V16 */'
if marker not in s:
 css='''<style id="torvo-software-workspace-fix-v16">/* TORVO SOFTWARE WORKSPACE FIX V16 */
@media(min-width:761px){
html,body{height:100%!important;overflow:hidden!important}.app{height:100vh!important;overflow:hidden!important}.main{height:100vh!important;overflow:hidden!important;display:flex!important;flex-direction:column!important}.top{flex:0 0 56px!important}.section.active{display:block!important;flex:1 1 auto!important;min-height:0!important;height:calc(100vh - 72px)!important;overflow-y:auto!important;overflow-x:hidden!important;scrollbar-width:thin!important;padding-right:3px!important}.section.active>.panel{display:block!important;height:auto!important;max-height:none!important;min-height:calc(100vh - 86px)!important;overflow:visible!important;margin-bottom:8px!important}.section.active>.panel>.grid,.section.active>.panel>.itemGrid,.section.active>.panel>.verifyList{overflow:visible!important;max-height:none!important}.section.active>.panel>.scroll{max-height:calc(100vh - 190px)!important;overflow:auto!important}.section.active::-webkit-scrollbar{width:7px!important}.section.active::-webkit-scrollbar-thumb{background:#94a3b866!important;border-radius:10px!important}.pTitle,.toolbar{position:relative!important;top:auto!important}.grid{grid-template-columns:repeat(3,minmax(0,1fr))!important}.box{padding:9px!important}.field input,.field select{min-height:35px!important}.field textarea{min-height:60px!important}
}
</style>'''
 if '</head>' not in s: raise SystemExit('Head anchor not found')
 s=s.replace('</head>',css+'\n</head>',1)
p.write_text(s,encoding='utf-8')
