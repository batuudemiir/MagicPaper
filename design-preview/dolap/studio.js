const $=id=>document.getElementById(id);
const key='magicpaper.studio.human.v2';
let cached;
try{cached=JSON.parse(localStorage.getItem(key))?.look;}catch{}
let savedLook=normalizeLook(cached), draftLook={...savedLook};
let family='Giysiler',slot='sets',zoomed=false,historyStack=[];
const faceSlots=['starter','skin','eye','eyeShape','brow','nose','face','hair','dye','detail','expression','head','glasses'];
const titles={brow:'Kaş biçimleri',nose:'Burun biçimleri',eyeShape:'Göz biçimleri',starter:'Bir başlangıç yüzü seç',sets:'Masal takımları',top:'Üst giysiler',bottom:'Alt giysiler',one:'Tek parça giysiler',shoe:'Ayakkabılar',skin:'Ten tonları',eye:'Göz renkleri',hair:'Saç modelleri',dye:'Saç renkleri',face:'Yüz biçimleri',expression:'Yüz ifadeleri',detail:'Yüz detayları',head:'Şapkalar ve başörtüleri',glasses:'Gözlükler',bag:'Çantalar'};
const startNames=['Çift örgü','Kısa dalga','Kıvırcık çift topuz','Küt kahkül','Uzun dalga','Yüksek topuz','Kısacık','Saçsız'];
const thumbBox={bag:'92 148 75 83',top:'72 142 98 96',bottom:'76 207 88 113',glasses:'80 78 80 43'};
const pictures={top:6,bottom:6,one:6,shoe:6,hair:6,hat:6};
const faceView=s=>faceSlots.includes(s);
const dirty=()=>Object.keys(draftLook).some(k=>draftLook[k]!==savedLook[k]);
function optionsFor(){
 if(slot==='sets')return catalog.outfits;
 if(slot==='starter')return catalog.starters.map((entry,i)=>({id:String(i),name:startNames[i]}));
 return catalog.items[slot];
}
function isSelected(item){
 if(slot==='starter')return identitySlots.every(k=>draftLook[k]===catalog.starters[Number(item.id)][1][k]);
 if(slot==='sets')return Object.entries(item.parts).every(([k,v])=>draftLook[k]===v);
 if(['top','bottom'].includes(slot)&&draftLook.one!=='none')return false;
 return draftLook[slot]===item.id;
}
function thumb(item){
 const span=document.createElement('span');span.className='thumb';
 if(item.hex){const circle=document.createElement('i');circle.className='chip';circle.style.background=item.hex;span.append(circle);return span;}
 if(item.id==='none'){span.textContent='∅';return span;}
 const [prefix,n]=item.id.split('-');
 if(Number(n)<=pictures[prefix]){
  const img=new Image();img.alt='';img.src=heroAsset(item.id);span.append(img);return span;
 }
 let look=selectItem(draftLook,slot,item.id);
 if(slot==='starter'){look.head='none';look.glasses='none';}
 if(['face','expression','detail','brow','nose','eyeShape'].includes(slot)){look.glasses='none';}
 let svg=avatar(look,faceView(slot)?'face':'body');
 if(thumbBox[slot])svg=svg.replace(/viewBox="[^"]+"/,'viewBox="'+thumbBox[slot]+'"');
 span.innerHTML=svg;return span;
}
function updateModel(animate=false){
 const node=$('model');node.innerHTML=avatar(draftLook,zoomed?'face':'body');node.classList.toggle('near',zoomed);
 const text=zoomed?'Tam boy gör':'Yüzü gör';$('zoom').textContent=text;$('zoom').setAttribute('aria-label',text);
 $('undo').disabled=historyStack.length===0;
 if(animate){node.classList.remove('wear');void node.offsetWidth;node.classList.add('wear');}
}
function announce(text){$('msg').textContent=text;}
function renderTiles(focusId){
 const tiles=$('tiles');tiles.replaceChildren();$('title').textContent=titles[slot];
 const covered=['hair','dye'].includes(slot)&&draftLook.head.startsWith('scarf');
 const note=$('hairNote');note.hidden=!covered&&!(slot==='dye'&&draftLook.hair==='bald');
 note.textContent=covered?'Saç seçimin başörtünün altında korunur.':(draftLook.hair==='bald'?'Bu rengi bir saç modeli seçtiğinde göreceksin.':'');
 for(const item of optionsFor()){
  const btn=document.createElement('button');btn.className='tile';btn.setAttribute('aria-pressed',String(isSelected(item)));btn.setAttribute('aria-label',item.name);
  btn.append(thumb(item));const b=document.createElement('b');b.textContent=item.name;btn.append(b);
  btn.onclick=()=>{
   const next=selectItem(draftLook,slot,item.id);
   if(Object.keys(next).some(k=>next[k]!==draftLook[k])){historyStack.push({...draftLook});if(historyStack.length>60)historyStack.shift();draftLook=next;}
   updateModel(true);renderTiles(item.id);announce(item.name+' seçildi.'+(covered?' Saç seçimin başörtünün altında korunur.':''));
  };
  tiles.append(btn);if(item.id===focusId)btn.focus({preventScroll:true});
 }
}
function navButton(title,pressed,select){
 const btn=document.createElement('button');btn.textContent=title;btn.setAttribute('aria-pressed',String(pressed));btn.onclick=select;return btn;
}
function showSlot(next){
 slot=next;zoomed=faceView(slot);drawNav();updateModel();renderTiles();document.querySelector('.rack').scrollTop=0;
}
function drawNav(){
 $('families').replaceChildren(...Object.keys(catalog.groups).map(name=>navButton(name,name===family,()=>{family=name;showSlot(Object.keys(catalog.groups[family])[0]);$('families').querySelector('[aria-pressed=true]').focus({preventScroll:true});})));
 const tabs=Object.entries(catalog.groups[family]).map(([s,label])=>navButton(label,s===slot,()=>{showSlot(s);$('slots').querySelector('[aria-pressed=true]').focus({preventScroll:true});}));
 $('slots').replaceChildren(...tabs);const active=$('slots').querySelector('[aria-pressed=true]');active.scrollIntoView({block:'nearest',inline:'nearest'});
}
$('zoom').onclick=()=>{zoomed=!zoomed;updateModel();};
$('undo').onclick=()=>{if(historyStack.length){draftLook=historyStack.pop();updateModel();renderTiles();announce('Son seçim geri alındı.');}};
const editorNodes=()=>document.querySelectorAll('header,.stage,.panel,footer');
function profile(message){
 $('portrait').innerHTML=avatar(savedLook,'bust');$('feedback').textContent=message;$('profile').hidden=false;
 for(const node of editorNodes())node.inert=true;$('open').focus();
}
$('save').onclick=()=>{
 try{localStorage.setItem(key,JSON.stringify({version:2,look:draftLook}));}
 catch{announce('Bu tarayıcı kayda izin vermiyor.');$('save').textContent='Kaydedilemedi · Tekrar dene';return;}
 savedLook={...draftLook};historyStack=[];profile('Kahramanın kaydedildi.');$('save').textContent='Kahramanımı kaydet';
};
$('back').onclick=()=>{if(dirty())$('leave').showModal();else profile('Dolabına dilediğin zaman dönebilirsin.');};
$('stay').onclick=()=>$('leave').close();
$('discard').onclick=()=>{$('leave').close();draftLook={...savedLook};historyStack=[];profile('Kaydettiğin görünüm burada.');};
$('open').onclick=()=>{for(const node of editorNodes())node.inert=false;$('profile').hidden=true;family='Giysiler';showSlot('sets');$('back').focus();};
drawNav();updateModel();renderTiles();
