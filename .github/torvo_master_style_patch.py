from pathlib import Path
p=Path('admin.html')
s=p.read_text(encoding='utf-8')
marker='/* TORVO ADD ITEM SAFE MASTER V4 */'
if marker not in s:
    css='''
<style id="torvo-add-item-safe-master-v4">
/* TORVO ADD ITEM SAFE MASTER V4 */
#spareFormHost .masterRow,#accessoryFormHost .masterRow{grid-template-columns:minmax(0,1fr) 34px!important}
#spareFormHost .masterRow>.mini.edit,#spareFormHost .masterRow>.mini.del,#accessoryFormHost .masterRow>.mini.edit,#accessoryFormHost .masterRow>.mini.del{display:none!important}
#spareFormHost .masterRow>input[list],#accessoryFormHost .masterRow>input[list]{padding-right:24px!important;background-color:#fff!important}
#spareFormHost .torvoBrandMasterRow,#accessoryFormHost .torvoBrandMasterRow{grid-template-columns:minmax(0,1fr) 34px!important}
@media(max-width:650px){#spareFormHost .masterRow,#accessoryFormHost .masterRow{grid-template-columns:minmax(0,1fr) 32px!important}}
</style>
'''
    s=s.replace('</head>',css+'</head>',1)
p.write_text(s,encoding='utf-8')
