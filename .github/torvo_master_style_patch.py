from pathlib import Path
p=Path('admin.html')
s=p.read_text(encoding='utf-8')
marker='/* TORVO MASTER STYLE STANDARD V1 */'
if marker not in s:
    css='''\n<style id="torvo-master-style-standard-v1">\n/* TORVO MASTER STYLE STANDARD V1 */\n.masterInline{display:grid!important;grid-template-columns:minmax(0,1fr) 42px 42px 42px!important;gap:6px!important;align-items:center!important}\n.masterInline input,.masterInline select{min-width:0!important;width:100%!important;height:42px!important;border:1px solid #cbd5e1!important;border-radius:10px!important;background:#fff!important;padding:0 11px!important;font-weight:700!important}\n.masterInline button{width:42px!important;min-width:42px!important;height:42px!important;border:0!important;border-radius:10px!important;padding:0!important;font-size:17px!important;font-weight:900!important;box-shadow:0 2px 6px rgba(0,0,0,.08)!important}\n.masterInline button:nth-of-type(1){background:#eaf2ff!important;color:#111!important}\n.masterInline button:nth-of-type(2){background:#e3f0ff!important;color:#075bd8!important}\n.masterInline button:nth-of-type(3){background:#ffe5e5!important;color:#c81e1e!important}\n@media(max-width:650px){.masterInline{grid-template-columns:minmax(0,1fr) 40px 40px 40px!important}.masterInline button{width:40px!important;min-width:40px!important;height:40px!important}.masterInline input,.masterInline select{height:40px!important}}\n</style>\n'''
    s=s.replace('</head>',css+'</head>',1)
p.write_text(s,encoding='utf-8')
