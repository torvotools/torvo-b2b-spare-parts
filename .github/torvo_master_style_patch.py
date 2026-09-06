from pathlib import Path
p=Path('admin.html')
s=p.read_text(encoding='utf-8')
marker='/* TORVO ADD BUTTON RED V5 */'
if marker not in s:
    css='''
<style id="torvo-add-button-red-v5">
/* TORVO ADD BUTTON RED V5 */
#spareFormHost .masterRow>.mini:not(.edit):not(.del),#accessoryFormHost .masterRow>.mini:not(.edit):not(.del),#spareFormHost .torvoBrandAddBtn,#accessoryFormHost .torvoBrandAddBtn{background:#d71920!important;color:#fff!important;border-color:#d71920!important}
</style>
'''
    s=s.replace('</head>',css+'</head>',1)
p.write_text(s,encoding='utf-8')
