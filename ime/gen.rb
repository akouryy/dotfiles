BaseChars = {
  ?b => ['ば', 'び', 'ぶ', 'べ', 'ぼ'],
  ?c => ['ちゃ', 'ち', 'ちゅ', 'ちぇ', 'ちょ'],
  ?d => ['だ', 'でぃ', 'どぅ', 'で', 'ど'],
  ?f => ['ふぁ', 'ふぃ', 'ふ', 'ふぇ', 'ふぉ'],
  ?g => ['が', 'ぎ', 'ぐ', 'げ', 'ご'],
  ?h => ['は', 'ひ', nil, 'へ', 'ほ'],
  ?j => ['じゃ', 'じ', 'じゅ', 'じぇ', 'じょ'],
  ?k => ['か', 'き', 'く', 'け', 'こ'],
  ?l => ['ぁ', 'ぃ', 'ぅ', 'ぇ', 'ぉ'],
  ?m => ['ま', 'み', 'む', 'め', 'も'],
  ?n => ['な', 'に', 'ぬ', 'ね', 'の'],
  ?p => ['ぱ', 'ぴ', 'ぷ', 'ぺ', 'ぽ'],
  ?r => ['ら', 'り', 'る', 'れ', 'ろ'],
  ?s => ['さ', 'すぃ', 'す', 'せ', 'そ'],
  ?t => ['た', 'てぃ', 'とぅ', 'て', 'と'],
  ?v => ['ゔぁ', 'ゔぃ', 'ゔ', 'ゔぇ', 'ゔぉ'],
  ?w => ['わ', 'うぃ', nil, 'うぇ', 'を'],
  ?x => ['しゃ', 'し', 'しゅ', 'しぇ', 'しょ'],
  ?y => ['や', nil, 'ゆ', 'いぇ', 'よ'],
  ?z => ['ざ', 'ずぃ', 'ず', 'ぜ', 'ぞ'],
}

$table = DATA.each_line.map{ _1.chomp.split ?\t, 2 }.to_h

def insert k, v
  return unless v
  raise "tried to set $table[#{k.inspect}] (currently #{$table[k].inspect}) to #{v.inspect}" if $table[k]

  $table[k] = v
end

BaseChars.each do |cons, kanas|
  'aiueo'.chars.zip kanas do |vowel, kana|
    insert cons + vowel, kana
  end

  insert cons + ?d, kanas[3]&.+('ん')
  insert cons + ?j, kanas[2]&.+('ん')
  insert cons + ?k, kanas[1]&.+('ん')
  insert cons + ?l, kanas[4]&.+('ん')
  insert cons + ?q, kanas[0]&.+('い')
  insert cons + ?z, kanas[0]&.+('ん')
  insert cons + ?3, kanas[3]&.+('い')
  insert cons + ?7, kanas[2]&.+('う')
  insert cons + ?9, kanas[4]&.+('う')
end

File.write 'romantable.tsv', $table.map{ _1.join(?\t) + ?\n }.sort.join
puts "Generated #{$table.size} entries."

__END__
-	ー
,	、
;	っ
.	。
[	「
]	」
@@	@
@a	←
@d	→
@s	↓
@w	↑
~	〜
a	あ
bb	っ	b
bya	びゃ
bye	びぇ
byi	びぃ
byo	びょ
byu	びゅ
cc	っ	c
cha	ちゃ
che	ちぇ
chi	ち
cho	ちょ
chu	ちゅ
dja	ぢゃ
dje	ぢぇ
dji	ぢ
djo	ぢょ
dju	ぢゅ
dwa	どぁ
dwe	どぇ
dwi	どぃ
dwo	どぉ
dwu	どぅ
dya	でゃ
dyo	でょ
dyu	でゅ
dzu	づ
e	え
ff	っ	f
fya	ふゃ
fyo	ふょ
fyu	ふゅ
gg	っ	g
gwa	ぐぁ
gwe	ぐぇ
gwi	ぐぃ
gwo	ぐぉ
gwu	ぐぅ
gya	ぎゃ
gye	ぎぇ
gyi	ぎぃ
gyo	ぎょ
gyu	ぎゅ
hh	っ	h
hya	ひゃ
hye	ひぇ
hyi	ひぃ
hyo	ひょ
hyu	ひゅ
i	い
kwa	くゎ
kwe	くぇ
kwi	くぃ
kwo	くぉ
kwu	くぅ
kya	きゃ
kye	きぇ
kyi	きぃ
kyo	きょ
kyu	きゅ
lka	ヵ
lke	ヶ
ltsu	っ
ltu	っ
lwa	ゎ
lya	ゃ
lye	ぇ
lyi	ぃ
lyo	ょ
lyu	ゅ
mm	っ	m
mya	みゃ
mye	みぇ
myi	みぃ
myo	みょ
myu	みゅ
n	ん
nn	ん
nya	にゃ
nye	にぇ
nyi	にぃ
nyo	にょ
nyu	にゅ
o	お
pp	っ	p
pya	ぴゃ
pye	ぴぇ
pyi	ぴぃ
pyo	ぴょ
pyu	ぴゅ
rr	っ	r
rya	りゃ
rye	りぇ
ryi	りぃ
ryo	りょ
ryu	りゅ
sha	しゃ
she	しぇ
shi	し
sho	しょ
shu	しゅ
ss	っ	s
swa	すぁ
swe	すぇ
swi	すぃ
swo	すぉ
swu	すぅ
sya	しゃ
sye	しぇ
syi	しぃ
syo	しょ
syu	しゅ
t;	つ
tsa	つぁ
tse	つぇ
tsi	つぃ
tso	つぉ
tsu	つ
tt	っ	t
twa	とぁ
twe	とぇ
twi	とぃ
two	とぉ
twu	とぅ
tya	てゃ
tyo	てょ
tyu	てゅ
u	う
vv	っ	v
vya	ゔゃ
vyo	ゔょ
vyu	ゔゅ
wha	うぁ
whe	うぇ
whi	うぃ
who	うぉ
whu	う
ww	っ	w
www	w	ww
wye	ゑ
wyi	ゐ
yy	っ	y
z-	〜
z,	‥
z.	…
z[	『
z]	』
z/	・
zwa	ずぁ
zwe	ずぇ
zwo	ずぉ
