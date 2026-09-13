import { access, copyFile, rm } from 'node:fs/promises'

const source = 'dist/v2-preview.html'
const target = 'dist/index.html'

await access(source)
await copyFile(source, target)
await rm(source)
console.log('TORVO V2 BUILD READY: dist/index.html')
