import{requireBackend}from'./supabase';

const clean=v=>String(v??'').trim();
const cleanUpper=v=>clean(v).toUpperCase();

export async function createDealerMissingPartRequest({machineBrand='',machineModel='',partName='',requestedQty=null,dealerMessage='',photoUrl=null}={}){
  const part=cleanUpper(partName);
  const message=clean(dealerMessage);
  if(!part&&!message)throw new Error('PART NAME OR REQUIREMENT DESCRIPTION REQUIRED');
  const qty=requestedQty==null||requestedQty===''?null:Number(requestedQty);
  if(qty!=null&&(!Number.isFinite(qty)||qty<=0))throw new Error('REQUESTED QUANTITY MUST BE GREATER THAN ZERO');
  if(clean(photoUrl))throw new Error('SECURE PHOTO UPLOAD IS NOT CONNECTED YET');
  const{data,error}=await requireBackend().rpc('dealer_create_missing_part_request',{
    p_machine_brand:cleanUpper(machineBrand)||null,
    p_machine_model:cleanUpper(machineModel)||null,
    p_part_name:part||null,
    p_requested_qty:qty,
    p_dealer_message:message||null,
    p_photo_url:null
  });
  if(error)throw error;
  return data;
}
