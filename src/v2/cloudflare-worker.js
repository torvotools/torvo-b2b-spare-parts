const NO_STORE='no-store, no-cache, must-revalidate, max-age=0';
const EVIDENCE=new Set(['/torvo-build-sha.txt','/torvo-build-manifest.json','/torvo-build-manifest.txt']);
const HTML=new Set(['/','/index.html']);
export default{
  async fetch(request,env){
    const url=new URL(request.url);
    const response=await env.ASSETS.fetch(request);
    if(!EVIDENCE.has(url.pathname)&&!HTML.has(url.pathname))return response;
    const headers=new Headers(response.headers);
    headers.set('Cache-Control',NO_STORE);
    headers.set('Pragma','no-cache');
    headers.set('Expires','0');
    headers.set('X-Torvo-V2','ACTIVE');
    headers.set('X-Torvo-Cache','BYPASS');
    if(EVIDENCE.has(url.pathname))headers.set('Content-Type',url.pathname.endsWith('.json')?'application/json; charset=utf-8':'text/plain; charset=utf-8');
    return new Response(request.method==='HEAD'?null:response.body,{status:response.status,statusText:response.statusText,headers});
  }
};
