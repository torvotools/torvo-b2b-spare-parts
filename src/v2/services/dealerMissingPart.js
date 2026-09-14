import{requireBackend}from'./supabase';

const clean=v=>String(v??'').trim();

export async function createDealerMissingPartRequest({machineBrand='',machineModel='',partName='',requestedQty=null,dealerMessage='',photoUrl=null}={}){
  const part=clean(partName);
  const message=clean(dealerMessage);
  if(!part&&!message)throw new Error('PART NAME OR REQUIREMENT DESCRIPTION REQUIRED');
  const qty=requestedQty==null||requestedQty===''?null:Number(requestedQty);
  if(qty!=null&&(!Number.isFinite(qty)||qty<=0))throw new Error('REQUESTED QUANTITY MUST BE GREATER THAN ZERO');
  const{data,error}=await requireBackend().rpc('dealer_create_missing_part_request',{
    p_machine_brand:clean(machineBrand)||null,
    p_machine_model:clean(machineModel)||null,
    p_part_name:part||null,
    p_requested_qty:qty,
    p_dealer_message:message||null,
    p_photo_url:clean(photoUrl)||null
  });
  if(error)throw error;
  return data;
}
