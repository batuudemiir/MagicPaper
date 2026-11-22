// Prototip (22 Kasım 2026): parçalar uygulamanın asset kataloğundan okunur, depoda tek kopya.
const heroAsset=id=>"../../MagicPaper/Assets.xcassets/HeroFigure/"+id+".imageset/"+id+".png";
if(typeof globalThis!=="undefined")globalThis.heroAsset=heroAsset;
// Bütün görseller 240 × 360 ortak sahnesinde dizilir. Önizleme ve portre aynı veriyi kullanır.
const wardrobe = typeof module==='undefined' ? catalog : require('./katalog.js');
const {items: palette} = wardrobe;
const getColor=(slot,id)=>palette[slot].find(v=>v.id===id).hex;
const nth=id=>Number(id.split('-').pop());
const curve=(d,fill,extra='')=>'<path d="'+d+'" fill="'+fill+'" '+extra+'/>';
const dot=(x,y,rx,ry,fill,extra='')=>'<ellipse cx="'+x+'" cy="'+y+'" rx="'+rx+'" ry="'+ry+'" fill="'+fill+'" '+extra+'/>';
const line=(d,color,width=1.5)=>curve(d,'none','stroke="'+color+'" stroke-width="'+width+'" stroke-linecap="round" stroke-linejoin="round"');
const tint=(color,target,weight)=>{
 const ch=(v,i)=>parseInt(v.slice(1+i*2,3+i*2),16);
 return '#'+[0,1,2].map(i=>Math.round(ch(color,i)*(1-weight)+ch(target,i)*weight).toString(16).padStart(2,'0')).join('');
};
const at=(id,x,y,w,h,extra='')=>'<image href="'+heroAsset(id)+'" xlink:href="'+heroAsset(id)+'" x="'+x+'" y="'+y+'" width="'+w+'" height="'+h+'" preserveAspectRatio="none" '+extra+'/>';
function drawGlasses(id){
 if(id==='none')return '';
 const i=nth(id),c=['#775481','#447e82','#b88142','#aa5062','#34485e','#698268'][i-1];
 function lens(x){
  if(i===6)return 'M'+(x-10)+' 97l5 -6h11l5 6 -3 11 -11 2 -7 -5z';
  if(i===2)return 'M'+(x-11)+' 94q11 -3 22 0l-2 11q-9 7 -18 0z';
  if(i===4)return 'M'+(x-12)+' 91q13 2 23 4l-2 9q-11 12 -19 0z';
  return 'M'+(x-11)+' 99a11 '+(i===3?8:10)+' 0 1 0 22 0a11 '+(i===3?8:10)+' 0 1 0 -22 0';
 }
 return line(lens(105)+' '+lens(135),c,2.3)+line('M116 98Q120 94 124 98M93 97l-7 -3M147 97l7 -3',c,2.1);
}
function drawnTop(i){
 const colors=['#efe2bc','#997bbd','#e6b650','#76a893','#574d83','#cf7e70'],c=colors[i-7];
 const shape='M108 148Q120 159 132 148L147 154Q153 159 160 187L148 192L151 227Q120 235 89 227L92 192L80 187Q86 161 94 154Z';
 let detail=line('M110 150Q120 160 130 150',tint(c,'#513850',.35),2)+line('M93 224q26 5 54 0',tint(c,'#513850',.22));
 if(i===7)for(const y of [172,181,190,199,208,217])detail+=line('M92 '+y+'q26 4 56 0','#679097',3);
 if(i===8)detail+=curve('M101 152Q117 137 137 152L130 165L120 159L112 166Z','#796294')+line('M110 205q10 3 20 0l5 9q-16 4 -30 0z','#766092');
 if(i===9||i===10)detail+=line('M120 155v72',tint(c,'#473349',.35),2)+[174,187,200,213].map(y=>dot(123,y,1.6,1.6,'#f8e8bb')).join('')+line('M95 204q6 3 13 0M132 204q6 3 13 0','#f9eac8',3);
 if(i===11)detail+=curve('M120 173l3 8 9 1 -7 6 2 9 -7 -5 -8 5 2 -9 -6 -6 8 -1z','#ebc469');
 if(i===12)detail+=curve('M106 152q3 16 14 6 11 10 15 -6l-15 5z','#fad4bd')+line('M95 218q25 5 50 0','#eead8d',2.6);
 return curve(shape,c)+detail;
}
function drawnBottom(i){
 const c=['#967da7','#779d91','#6a879d','#ca9c75'][i-7];
 if(i===8||i===10)return curve('M98 215Q118 221 142 215L157 266Q120 277 83 266Z',c)+[98,112,126,140].map((x,j)=>line('M'+x+' 225l'+((j-1.5)*4)+' 39',tint(c,'#4b3b54',.25))).join('');
 return curve('M96 214H144L144 314Q136 318 126 314L119 251L113 314Q103 317 95 313Z',c)+line('M99 221h39M139 230l1 78',tint(c,'#f6e8dc',.35),2);
}
function bagArt(id){
 if(id==='none')return '';
 const i=nth(id),c=['#c59960','#819761','#c77179','#7394a0'][i-1];
 return line('M101 152Q120 187 145 207','#634f45',4)+curve('M135 198q10 -2 20 1l1 22q-9 5 -22 0z',c)+curve('M134 198q11 -4 22 1l-2 8q-9 5 -20 -2z',tint(c,'#fff2cd',.22))+dot(146,207,1.6,1.6,'#f4d68e');
}
let serial=0;
function avatar(state,view='body'){
 const s=state,k='v'+(++serial),ref=id=>'url(#'+k+id+')',skin=getColor('skin',s.skin),iris=getColor('eye',s.eye),hair=getColor('dye',s.dye);
 const shade=tint(skin,'#713f32',.27),lip=tint(skin,'#722d36',.65),brow=tint(hair,'#442d31',.30);
 const grad=(name,stops)=>'<linearGradient id="'+k+name+'" x2=".85" y2="1">'+stops.map(([off,col])=>'<stop offset="'+off+'" stop-color="'+col+'"/>').join('')+'</linearGradient>';
 const glow='<radialGradient id="'+k+'blush"><stop stop-color="'+tint(skin,'#d66d72',.55)+'" stop-opacity=".82"/><stop offset="1" stop-color="'+skin+'" stop-opacity="0"/></radialGradient>';
 const colors=[tint(hair,'#221a23',.75),tint(hair,'#30202a',.25),tint(hair,'#efe2ce',.35),tint(hair,'#fff6da',.7)];
 const filter='<filter id="'+k+'dye" color-interpolation-filters="sRGB"><feColorMatrix type="saturate" values="0"/><feComponentTransfer>'+['R','G','B'].map((channel,j)=>'<feFunc'+channel+' type="table" tableValues="'+colors.map(c=>(parseInt(c.slice(1+j*2,3+j*2),16)/255).toFixed(3)).join(' ')+'"/>').join('')+'</feComponentTransfer></filter>';
 const defs='<defs>'+grad('skin',[['0%',tint(skin,'#fff1d4',.13)],['55%',skin],['100%',shade]])+glow+filter+'<clipPath id="'+k+'cap"><rect x="0" y="78" width="240" height="280"/></clipPath></defs>';
 const flesh=ref('skin'),hijab=s.head.startsWith('scarf'),hat=s.head.startsWith('hat');
 const body=curve('M110 128Q115 144 110 150Q120 164 130 150Q125 142 130 128Z',shade)+curve('M99 208Q115 210 116 225L111 320Q105 327 98 320L99 268Q94 235 99 208Z',flesh)+curve('M124 213Q133 207 143 214Q149 245 141 272L141 320Q135 328 128 320L125 264Z',flesh)+curve('M99 155Q92 154 86 170L76 211Q72 219 76 223Q80 228 84 222L85 216Q86 220 88 216L88 209L101 174Z',flesh)+curve('M141 155Q148 154 154 170L164 211Q168 219 164 223Q160 228 156 222L155 216Q154 220 152 216L152 209L139 174Z',flesh);
 const so=nth(s.shoe), shoeH=[31,22,17,38,18,19][so-1];
 const shoes=at(s.shoe,94,338-shoeH,53,shoeH);
 const bod=nth(s.bottom), top=nth(s.top);
 let clothes;
 if(s.one==='none'){
  const bounds=[[93,213,54,101],[81,212,79,55],[91,213,58,44],[80,212,80,83],[94,213,53,102],[89,213,62,99]];
  clothes=(bod<=6?at(s.bottom,...bounds[bod-1]):drawnBottom(bod))+(top<=6?at(s.top,79,147,82,81):drawnTop(top));
 }else{
  const coords=[[77,148,86,119],[80,148,80,112],[76,148,88,139],[78,148,84,124],[75,148,90,132],[72,147,96,172]];
  clothes=at(s.one,...coords[nth(s.one)-1]);
  if(s.one==='one-6')clothes=line('M100 158Q86 163 78 214M140 158Q154 163 162 214','#51647f',10)+clothes+dot(79,229,3.8,5,flesh)+dot(161,229,3.8,5,flesh);
 }
 const heads=[
  'M82 92Q80 55 120 54Q160 55 158 92Q159 122 140 135Q120 149 99 136Q81 124 82 92Z',
  'M85 90Q82 54 120 52Q158 54 155 90Q156 123 139 137Q120 152 101 137Q84 121 85 90Z',
  'M82 90Q83 55 120 54Q157 55 158 90L155 120Q151 138 129 141Q105 146 91 132Q82 122 82 90Z',
  'M80 89Q80 54 120 53Q158 54 160 89Q161 110 143 128Q128 145 120 146Q110 143 96 130Q78 113 80 89Z'];
 const facebase=dot(82,102,6.5,9,flesh)+dot(158,102,6.5,9,flesh)+curve(heads[nth(s.face)-1],flesh)+dot(95,113,12,7,ref('blush'))+dot(145,113,12,7,ref('blush'));
 function eye(x,mirror){
  const dir=mirror?-1:1; const sy=[1,.72,.85][nth(s.eyeShape)-1],sx=[1,1.16,1.04][nth(s.eyeShape)-1];
  return '<g transform="translate('+x+' 100) scale('+(dir*sx)+' '+sy+')">'+curve('M-8 1Q-7 -8 0 -8Q8 -8 8 1Q6 7 0 7Q-6 7 -8 1Z','#fff7e9')+dot(.3,0,5.8,7,iris)+dot(.4,.2,3.1,4.4,'#332931')+dot(-1.2,-2.4,1.6,1.7,'#fff9ed')+line('M-8 0Q-5 -10 3 -8Q7 -7 8 -3',brow,1.8)+'</g>';
 }
 const exp=nth(s.expression),detail=s.detail;
 const browIndex=nth(s.brow),stroke=[2.5,2.4,3.7,2.5][browIndex-1];
 const left=['M97 88q7 -5 14 -2','M97 87l14 -1','M96 88q7 -6 16 -2','M99 88q5 -5 10 -3'][browIndex-1];
 const noseLine=['M119 105q-3 7 2 7','M117 110q-2 6 5 4q3 -1 2 -3','M120 104q0 6 -3 9q3 2 6 0'][nth(s.nose)-1];
 let features=eye(105,false)+eye(135,true)+line(left,brow,stroke)+'<g transform="translate(240 '+(exp===3?-2:0)+') scale(-1 1)">'+line(left,brow,stroke)+'</g>'+line(noseLine,shade,1.9);
 features+=exp===2?curve('M110 121q11 4 21 -1q-2 12 -12 10q-7 -1 -9 -9z',lip)+curve('M113 122q9 2 16 0q-5 4 -15 3z','#fff6e9'):line(exp===3?'M115 124q5 -3 11 -1':'M110 122q10 9 21 -1',lip,2);
 if(['mark-1','mark-4'].includes(detail))for(const [x,y] of [[95,111],[100,113],[105,111],[136,111],[142,113],[147,110],[97,115],[140,116]])features+=dot(x,y,.9,.8,brow,'opacity=".55"');
 if(detail==='mark-2')features+=line('M107 124q0 3 3 3M133 124q0 3 -2 3',shade,1.3);
 if(['mark-3','mark-4'].includes(detail))features+=dot(143,120,1.35,1.3,brow);
 const hairFit=[[73,44,94,79],[68,41,104,88],[73,50,94,130],[53,45,134,85],[60,48,120,110],[74,23,92,94]];
 let hairLayer='';
 if(s.hair==='crop')hairLayer=curve('M81 93Q76 53 119 51Q161 52 159 94Q149 76 136 78Q113 69 97 79Q89 80 81 93Z',hair);
 else if(s.hair!=='bald')hairLayer=at(s.hair,...hairFit[nth(s.hair)-1],s.dye==='chestnut'?'':'filter="'+ref('dye')+'"');
 if(s.hair==='hair-4')hairLayer=curve('M82 92Q77 51 119 50Q162 50 158 94Q151 79 140 79Q122 70 104 80Q90 78 82 92Z',hair)+hairLayer;
 let covering='';
 if(hijab){
  const c=['#a78ac0','#c1838e','#879d88','#dcc7aa'][nth(s.head)-1];
  covering=curve('M74 101Q71 49 119 45Q167 45 166 99Q163 128 173 158Q155 173 135 168L105 159L83 166Q66 158 70 145Q76 124 74 101ZM86 99Q88 78 119 66Q150 76 154 99Q153 125 135 136Q120 146 106 137Q88 125 86 99Z',c,'fill-rule="evenodd"')+line('M75 139q9 18 31 19M134 162q18 -9 23 -28',tint(c,'#60495d',.25),2);
 }else if(hat){
  const fits=[[67,28,104,51],[72,21,96,62],[56,24,128,60],[70,27,100,57],[61,24,118,60],[64,24,112,61]];
  covering=at(s.head,...fits[nth(s.head)-1]);
 }
 if(hat)hairLayer='<g clip-path="'+ref('cap')+'">'+hairLayer+'</g>';
 const vb=view==='face'?'53 15 134 147':view==='bust'?'51 15 138 169':'47 4 146 343';
 return '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="'+vb+'" aria-hidden="true" overflow="hidden">'+defs+body+shoes+clothes+bagArt(s.bag)+facebase+features+(hijab?'':hairLayer)+covering+drawGlasses(s.glasses)+'</svg>';
}
if(typeof module!=='undefined')module.exports={avatar};
