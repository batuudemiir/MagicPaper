// Ortak katalog. Seçim değerleri dizinlerden bağımsız, kalıcı kimliklerdir.
const options = (prefix, names) => names.split('|').map((name,i)=>({id:prefix+'-'+(i+1),name}));
const colors = text => text.split('|').map(row=>{const [id,name,hex]=row.split('/');return {id,name,hex:'#'+hex}});
const off={id:'none',name:'Çıkar'};
const items = {
 skin:colors('pearl/Porselen/F8DBCA|apricot/Açık şeftali/F3C6A6|sand/Kum/E7B38B|honey/Bal/DB9D71|amber/Amber/C48859|hazel/Fındık/AD7352|cocoa/Kakao/895737|walnut/Ceviz/724531|earth/Toprak/5F392E|espresso/Koyu kahve/482C27'),
 eye:colors('brown/Kahverengi/754633|dark/Koyu kahve/503529|hazel/Ela/89804A|green/Yaprak yeşili/618159|blue/Gök mavisi/6092AE|gray/Gri mavi/758896|amber/Kehribar/B58343|sea/Deniz yeşili/498882'),
 hair:[...options('hair','Kısa dalga|Küt kahkül|Çift örgü|Kıvırcık çift topuz|Uzun dalga|Yüksek topuz'),{id:'crop',name:'Kısacık'},{id:'bald',name:'Saçsız'}],
 dye:colors('chestnut/Kestane/76442F|black/Yumuşak siyah/272330|darkbrown/Koyu kahve/473029|honey/Bal sarısı/CE985A|copper/Bakır/B85F39|ash/Küllü kumral/957F6C|silver/Gümüş/B7B0AE|violet/Mürdüm/79506E'),
 brow:options('brow','Yumuşak yay|Düz|Dolgun|Kısa yay'),
 eyeShape:options('eyes','Yuvarlak|Badem|Yumuşak oval'),
 nose:options('nose','Küçük|Yuvarlak|Yumuşak kavis'),
 face:options('face','Yuvarlak|Oval|Yumuşak köşeli|Kalp'),
 expression:options('smile','Hafif gülümseme|Neşeli|Meraklı'),
 detail:[{id:'none',name:'Sade'},...options('mark','Çiller|Gamze|Küçük ben|Çil ve ben')],
 top:options('top','Kirazlı bluz|Doğa yeleği|Ay desenli pijama|Denizci bluzu|Ressam gömleği|Çiçekli süveter|Çizgili tişört|Lavanta kapüşonlu|Sarı yağmurluk|Nane hırka|Yıldızlı kazak|Mercan tunik'),
 bottom:options('bottom','Kadife pantolon|Kirazlı etek|Keşif şortu|Çiçekli uzun etek|Ay desenli pijama|Bol paça kot|Lavanta tayt|Pileli etek|Spor pantolon|Keten kısa etek'),
 one:[{id:'none',name:'Üst ve alta dön'},...options('one','Kiraz elbise|Denim salopet|Yıldız cübbesi|Papatya jile|Orman pelerini|Astronot tulumu')],
 shoe:options('shoe','Bağcıklı bot|Deniz spor ayakkabısı|Çapraz bantlı babet|Yağmur çizmesi|Ay terliği|Kiraz tokalı ayakkabı'),
 head:[off,...options('hat','Ahududu bere|Lavanta bere|Gezgin şapkası|Yaprak kep|Yağmur şapkası|Papatya şapka'),...options('scarf','Lavanta başörtüsü|Gül başörtüsü|Adaçayı başörtüsü|Krem başörtüsü')],
 glasses:[off,...options('glass','Yuvarlak mor|Turkuaz köşeli|Bal rengi oval|Mercan kedi gözü|Lacivert yuvarlak|Yeşil altıgen')],
 bag:[off,...options('bag','Bal rengi heybe|Yaprak çanta|Kiraz kese|Mavi postacı çantası')]
};
const look=(skin,eye,hair,dye,top,bottom,shoe,one='none',head='none',glasses='none',bag='none',face='face-1',detail='none',expression='smile-1')=>({skin,eye,hair,dye,face,brow:'brow-1',eyeShape:'eyes-1',nose:'nose-1',detail,expression,top,bottom,shoe,one,head,glasses,bag});
const starters=[
 ['Kiraz bahçesi',look('honey','hazel','hair-3','chestnut','top-1','bottom-2','shoe-6','none','none','none','none','face-1','mark-1')],
 ['Göl gezgini',look('walnut','brown','hair-1','black','top-2','bottom-3','shoe-1','none','none','glass-3','bag-1','face-3')],
 ['Çiçek bahçesi',look('cocoa','dark','hair-4','darkbrown','top-6','bottom-6','shoe-2','one-4','none','none','none','face-1','mark-3','smile-2')],
 ['Ay yolcusu',look('sand','blue','hair-2','copper','top-3','bottom-5','shoe-5','one-6','none','none','none','face-2')],
 ['Göl kenarı',look('amber','green','hair-5','chestnut','top-4','bottom-4','shoe-3','none','scarf-3','glass-1','none','face-2','mark-2')],
 ['Küçük ressam',look('apricot','sea','hair-6','honey','top-5','bottom-6','shoe-2','none','none','glass-2','none','face-4','mark-1')],
 ['Orman okuru',look('espresso','amber','crop','black','top-11','bottom-9','shoe-1','one-5','none','none','none','face-3','none','smile-3')],
 ['Yıldız avcısı',look('pearl','gray','bald','ash','top-8','bottom-7','shoe-3','one-3','none','glass-6','none','face-4','mark-4')]
];
// Başlangıç yüzleri bağımsız olarak düzenlenebilir.
starters.forEach(([,s],i)=>{s.brow='brow-'+(i%4+1);s.eyeShape='eyes-'+(i%3+1);s.nose='nose-'+((i+1)%3+1);});
const outfits=[
 ['Kiraz bahçesi',1,2,6,0],['Gezgin',2,3,1,0],['Uyku zamanı',3,5,5,0],['Denizci',4,6,2,0],['Küçük ressam',5,1,2,0],['Örgü günü',6,4,3,0],
 ['Kiraz elbise',1,2,6,1],['Salopet',7,6,2,2],['Yıldız büyüsü',11,7,3,3],['Papatya',6,2,6,4],['Orman',2,3,1,5],['Uzay gezisi',7,9,1,6],
 ['Yağmurlu gün',9,6,4,0],['Parkta oyun',8,9,2,0],['Yaz gezisi',12,10,3,0],['Çizgili gün',7,8,6,0]
].map(([name,t,b,s,o],i)=>({name,id:'set-'+(i+1),parts:{top:'top-'+t,bottom:'bottom-'+b,shoe:'shoe-'+s,one:o?'one-'+o:'none'}}));
const groups={ 'Kahramanım':{starter:'Başlangıçlar',skin:'Ten',face:'Yüz',eye:'Göz rengi',eyeShape:'Göz biçimi',brow:'Kaş',nose:'Burun',hair:'Saç',dye:'Saç rengi',expression:'İfade',detail:'Yüz detayı'}, 'Giysiler':{sets:'Takımlar',top:'Üst',bottom:'Alt',one:'Tek parça',shoe:'Ayakkabı'}, 'Aksesuarlar':{head:'Başlık ve örtü',glasses:'Gözlük',bag:'Çanta'} };
const catalog={items,starters,outfits,groups};
if(typeof module!=='undefined') module.exports=catalog;
