import {defineConfig} from 'vite';
import react from '@vitejs/plugin-react';
import {resolve} from 'node:path';

export default defineConfig(()=>{
  const raw=Number(process.env.TORVO_ANDROID_BUILD_NUMBER||process.env.GITHUB_RUN_NUMBER||0);
  const androidBuild=Number.isSafeInteger(raw)&&raw>0?String(raw):'';
  return{
    plugins:[react()],
    define:{'import.meta.env.VITE_ANDROID_BUILD_NUMBER':JSON.stringify(androidBuild)},
    build:{
      outDir:'dist-app',
      emptyOutDir:true,
      rollupOptions:{input:resolve(process.cwd(),'v2.html')}
    }
  };
});
