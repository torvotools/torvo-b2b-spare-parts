from pathlib import Path
p=Path('admin.html')
s=p.read_text(encoding='utf-8')
marker='/* TORVO ADD ITEM ACTUAL MASTER ROW V3 */'
if marker not in s:
    css='''
<style id="torvo-add-item-actual-master-row-v3">
/* TORVO ADD ITEM ACTUAL MASTER ROW V3 */
#spareFormHost .masterRow,#accessoryFormHost .masterRow{display:grid!important;grid-template-columns:minmax(0,1fr) 34px 34px 34px!important;gap:5px!important;align-items:center!important}
#spareFormHost .masterRow>input,#accessoryFormHost .masterRow>input{width:100%!important;min-width:0!important;height:36px!important;border:1px solid #cbd5e1!important;border-radius:8px!important;background:#fff!important;padding:0 10px!important;font-weight:700!important}
#spareFormHost .masterRow>.mini,#accessoryFormHost .masterRow>.mini{width:34px!important;min-width:34px!important;height:36px!important;border:0!important;border-radius:8px!important;padding:0!important;font-size:14px!important;font-weight:900!important;box-shadow:0 2px 5px rgba(0,0,0,.08)!important}
#spareFormHost .masterRow>.mini:not(.edit):not(.del),#accessoryFormHost .masterRow>.mini:not(.edit):not(.del){background:#f97316!important;color:#fff!important}
#spareFormHost .masterRow>.mini.edit,#accessoryFormHost .masterRow>.mini.edit{background:#dbeafe!important;color:#075bd8!important}
#spareFormHost .masterRow>.mini.del,#accessoryFormHost .masterRow>.mini.del{background:#fee2e2!important;color:#c81e1e!important}
#spareFormHost .torvoBrandMasterRow,#accessoryFormHost .torvoBrandMasterRow{grid-template-columns:minmax(0,1fr) 34px!important}
#spareFormHost .torvoBrandInputWrap,#accessoryFormHost .torvoBrandInputWrap{min-width:0!important;width:100%!important}
#spareFormHost .torvoBrandAddBtn,#accessoryFormHost .torvoBrandAddBtn{width:34px!important;min-width:34px!important;height:36px!important;border-radius:8px!important;background:#f97316!important;color:#fff!important}
@media(max-width:650px){#spareFormHost .masterRow,#accessoryFormHost .masterRow{grid-template-columns:minmax(0,1fr) 32px 32px 32px!important;gap:4px!important}#spareFormHost .masterRow>.mini,#accessoryFormHost .masterRow>.mini{width:32px!important;min-width:32px!important;height:34px!important}#spareFormHost .masterRow>input,#accessoryFormHost .masterRow>input{height:34px!important}#spareFormHost .torvoBrandMasterRow,#accessoryFormHost .torvoBrandMasterRow{grid-template-columns:minmax(0,1fr) 32px!important}#spareFormHost .torvoBrandAddBtn,#accessoryFormHost .torvoBrandAddBtn{width:32px!important;min-width:32px!important;height:34px!important}}
</style>
'''
    s=s.replace('</head>',css+'</head>',1)
p.write_text(s,encoding='utf-8')
