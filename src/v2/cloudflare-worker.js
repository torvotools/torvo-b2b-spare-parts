const NO_STORE='no-store, no-cache, must-revalidate, max-age=0';
const EVIDENCE=new Set(['/torvo-build-sha.txt','/torvo-build-manifest.json','/torvo-build-manifest.txt']);
export default{
  async fetch(request,env){
    const url=new URL(request.url);
    const response=await env.ASSETS.fetch(request);
    if(!EVIDENCE.has(url.pathname)&&url.pathname!=='/'&&url.pathname!=='/index.html')return response;
    const headers=new Headers(response.headers);
    headers.set('Cache-Control',NO_STORE);
    headers.set('Pragma','no-cache');
    headers.set('Expires','0');
    headers.set('X-Torvo-V2','ACTIVE');
    return new Response(response.body,{status:response.status,statusText:response.statusText,headers});
  }
};
