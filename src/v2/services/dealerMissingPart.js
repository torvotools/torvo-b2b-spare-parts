import{requireBackend}from'./supabase';

const clean=v=>String(v??'').trim();
const cleanUpper=v=>clean(v).toUpperCase();
const max=(v,n,label)=>{const x=clean(v);if(x.length>n)throw new Error(`${label} IS TOO LONG`);return x};

export async function createDealerMissingPartRequest({machineBrand='',machineModel='',partName='',requestedQty=null,dealerMessage='',photoUrl=null}={}){
  const brand=cleanUpper(max(machineBrand,80,'MACHINE BRAND'));
  const model=cleanUpper(max(machineModel,120,'MACHINE MODEL'));
  const part=cleanUpper(max(partName,160,'PART NAME'));
  const message=max(dealerMessage,1000,'REQUIREMENT DESCRIPTION');
  if(!part&&!message)throw new Error('PART NAME OR REQUIREMENT DESCRIPTION REQUIRED');
  const qty=requestedQty==null||requestedQty===''?null:Number(requestedQty);
  if(qty!=null&&(!Number.isSafeInteger(qty)||qty<=0||qty>9999))throw new Error('QUANTITY MUST BE A WHOLE NUMBER BETWEEN 1 AND 9999');
  if(clean(photoUrl))throw new Error('SECURE PHOTO UPLOAD IS NOT CONNECTED YET');
  const{data,error}=await requireBackend().rpc('dealer_create_missing_part_request',{p_machine_brand:brand||null,p_machine_model:model||null,p_part_name:part||null,p_requested_qty:qty,p_dealer_message:message||null,p_photo_url:null});
  if(error)throw error;
  return data;
}

export async function dealerMissingPartRequests(){
  const{data,error}=await requireBackend().rpc('dealer_my_missing_part_requests');
  if(error)throw error;
  return Array.isArray(data)?data:[];
}
