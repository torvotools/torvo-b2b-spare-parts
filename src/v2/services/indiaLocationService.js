// TORVO V2 location UI must use the authoritative Supabase location master only.
// Official source of truth for imports/refreshes: Government of India LGD / OGD datasets.
// Do not silently fall back to third-party GitHub/Gist geography because that can mix
// stale or incomplete districts/localities into customer and dealer records.
//
// This compatibility service remains only for callers that have not yet been migrated.
// Fail closed: an unavailable authoritative master must be visible to the UI/admin
// instead of being disguised by guessed geography.
let cache;
export async function loadIndiaLocations(){
  if(cache)return cache;
  cache=Promise.resolve({
    states:[],
    districts:()=>[],
    cities:()=>[],
    sourceStatus:{
      authoritative:false,
      districts:false,
      localities:false,
      reason:'AUTHORITATIVE LOCATION MASTER REQUIRED'
    }
  });
  return cache;
}
