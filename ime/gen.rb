BaseChars = {
  # consonants => [key for 拗音, a, i, u, e, o]
  ?b   => [1,   'ば', 'び', 'ぶ', 'べ', 'ぼ'],
  ?c   => [nil, 'つぁ', 'つぃ', 'つ', 'つぇ', 'つぉ'],
  ?d   => [3,   'だ', 'でぃ', 'どぅ', 'で', 'ど'],
  ?f   => [2,   'ふぁ', 'ふぃ', 'ふ', 'ふぇ', 'ふぉ'],
  ?g   => [1,   'が', 'ぎ', 'ぐ', 'げ', 'ご'],
  ?h   => [1,   'は', 'ひ', nil, 'へ', 'ほ'],
  ?j   => [nil, 'じゃ', 'じ', 'じゅ', 'じぇ', 'じょ'],
  ?k   => [1,   'か', 'き', 'く', 'け', 'こ'],
  ?l   => [nil, 'あ', 'い', 'う', 'え', 'お'],
  ?m   => [1,   'ま', 'み', 'む', 'め', 'も'],
  ?n   => [1,   'な', 'に', 'ぬ', 'ね', 'の'],
  ?p   => [1,   'ぱ', 'ぴ', 'ぷ', 'ぺ', 'ぽ'],
  ?q   => [nil, 'ちゃ', 'ち', 'ちゅ', 'ちぇ', 'ちょ'],
  ?r   => [1,   'ら', 'り', 'る', 'れ', 'ろ'],
  ?s   => ['し', 'さ', 'すぃ', 'す', 'せ', 'そ'],
  ?t   => [3,   'た', 'てぃ', 'とぅ', 'て', 'と'],
  ?v   => [2,   'ゔぁ', 'ゔぃ', 'ゔ', 'ゔぇ', 'ゔぉ'],
  ?w   => [nil, 'わ', 'うぃ', nil, 'うぇ', 'を'],
  ?x   => [nil, 'しゃ', 'し', 'しゅ', 'しぇ', 'しょ'],
  ?y   => [nil, 'や', nil, 'ゆ', 'いぇ', 'よ'],
  ?z   => [nil, 'ざ', 'ずぃ', 'ず', 'ぜ', 'ぞ'],
  '@l' => [nil, 'ぁ', 'ぃ', 'ぅ', 'ぇ', 'ぉ'],
}

$table = DATA.each_line.map{ _1.chomp.split ?\t, 2 }.to_h

def insert k, v
  return unless v
  raise "tried to set $table[#{k.inspect}] (currently #{$table[k].inspect}) to #{v.inspect}" if $table[k]

  $table[k] = v
end

def add_cons cons, kanas
  'aiueo'.chars.zip kanas do |vowel, kana|
    insert cons + vowel, kana
  end

  {
    d: [3, ?ん],
    h: [2, ?っ],
    j: [2, ?ん],
    k: [1, ?ん],
    l: [4, ?ん],
    m: [1, ?っ],
    p: [4, ?っ],
    q: [0, ?い],
    r: [3, ?っ],
    s: [0, ?っ],
    z: [0, ?ん],
    3 => [3, ?い],
    4 => [3, ?い],
    7 => [2, ?う],
    8 => [2, ?う],
    9 => cons != 'ny' && [4, ?う],
    0 => cons != 'ny' && [4, ?う],
  }.each do |vowel, (kana_index, suffix)|
    insert "#{cons}#{vowel}", kanas[kana_index]&.+(suffix) if kana_index
  end
end

BaseChars.each do |cons, (yôon_key, *kanas)|
  add_cons cons, kanas

  yôon_prefix = case yôon_key
    when String  then yôon_key
    when Integer then kanas[yôon_key]
    when nil     then nil
  end

  if yôon_prefix
    yôon_chars = 'ゃぃゅぇょ'.chars.map.with_index do |small, i|
      # if i == kanas.index(yôon_prefix)
      #   nil
      # else
      yôon_prefix + small
      # end
    end

    add_cons cons + ?y, yôon_chars
  end
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
dzu	づ
e	え
gwa	ぐぁ
gwe	ぐぇ
gwi	ぐぃ
gwo	ぐぉ
gwu	ぐぅ
i	い
kwa	くゎ
kwe	くぇ
kwi	くぃ
kwo	くぉ
kwu	くぅ
@lcu	っ
@lka	ヵ
@lke	ヶ
@lwa	ゎ
@lya	ゃ
@lyo	ょ
@lyu	ゅ
n	ん
nn	ん
o	お
sha	しゃ
she	しぇ
shi	し
sho	しょ
shu	しゅ
swa	すぁ
swe	すぇ
swi	すぃ
swo	すぉ
swu	すぅ
twa	とぁ
twe	とぇ
twi	とぃ
two	とぉ
twu	とぅ
u	う
wha	うぁ
whe	うぇ
whi	うぃ
who	うぉ
whu	う
www	w	ww
wye	ゑ
wyi	ゐ
z-	〜
z,	‥
z.	…
z[	『
z]	』
z/	・
zwa	ずぁ
zwe	ずぇ
zwo	ずぉ
