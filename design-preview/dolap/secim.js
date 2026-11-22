// Tarayıcıdan bağımsız seçim kuralları. iOS uygulamasına aynı sözleşme taşınabilir.
const studioData = typeof module==='undefined'?catalog:require('./katalog.js');
const identitySlots=['skin','eye','brow','nose','eyeShape','hair','dye','face','expression','detail'];
function normalizeLook(raw){
 const look={...studioData.starters[0][1]};
 for(const [slot,options] of Object.entries(studioData.items))
  if(options.some(item=>item.id===raw?.[slot])) look[slot]=raw[slot];
 return look;
}
function selectItem(look,slot,id){
 const result={...look};
 if(slot==='starter'){
  const starter=studioData.starters[Number(id)];
  if(starter)for(const key of identitySlots)result[key]=starter[1][key];
 }else if(slot==='sets'){
  const set=studioData.outfits.find(item=>item.id===id);
  if(set)Object.assign(result,set.parts);
 }else if(studioData.items[slot]?.some(item=>item.id===id)){
  result[slot]=id;
  if(['top','bottom'].includes(slot)) result.one='none';
 }
 return result;
}
if(typeof module!=='undefined')module.exports={normalizeLook,selectItem,identitySlots};
