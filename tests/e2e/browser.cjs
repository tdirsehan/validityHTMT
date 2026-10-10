const {chromium}=require('playwright');
const fs=require('fs');
(async()=>{
 const summary=JSON.parse(fs.readFileSync('artifacts/engine-summary.json'));
 const browser=await chromium.launch({headless:true});
 const context=await browser.newContext({viewport:{width:1600,height:1000}});
 await context.addCookies([{name:'access_key',value:'validityhtmt-ci-local-only',domain:'127.0.0.1',path:'/'}]);
 const page=await context.newPage();
 const errors=[];page.on('pageerror',e=>errors.push(String(e)));
 await page.goto('http://127.0.0.1:41337/'+summary.instance+'/',{waitUntil:'domcontentloaded'});
 let texts=[];
 try {
  await page.waitForFunction(()=>document.readyState==='complete');
  const deadline=Date.now()+90000;
  while(Date.now()<deadline){
   texts=await Promise.all(page.frames().map(f=>f.locator('body').innerText().catch(()=>'')));
   const joined=texts.join('\n');
   if(joined.includes('HTMT+') && /0\.204/.test(joined) && /0\.147/.test(joined))break;
   await page.waitForTimeout(1000);
  }
  const joined=texts.join('\n');
  fs.writeFileSync('artifacts/browser-text.txt',joined);
  await page.screenshot({path:'artifacts/jamovi-results.png',fullPage:true});
  if(!joined.includes('HTMT+') || !/0\.204/.test(joined) || !/0\.147/.test(joined))throw Error('Both Pearson and Spearman results were not rendered in the jamovi UI');
  fs.writeFileSync('artifacts/browser-summary.json',JSON.stringify({status:'PASS',checks:['jamovi UI loaded','Pearson results rendered','Spearman results rendered'],pageErrors:errors},null,2));
  console.log('PASS: jamovi browser renders both analyses');
 } finally {await browser.close();}
})().catch(e=>{console.error(e);process.exit(1)});
