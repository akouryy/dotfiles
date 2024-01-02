Column = Data.define :yôon_key, :a, :i, :u, :e, :o do
  alias_method :[], :send

  # @return [Column, nil]
  def yôon_column
    if yôon_key
      yôon_prefix =
        case yôon_key
        in String then yôon_key
        in Symbol then self[yôon_key]
        end

      Column.new(nil, *'ゃぃゅぇょ'.chars.map { |small| yôon_prefix + small })
    end
  end
end

BaseChars = {
  ?⇧   => Column.new(nil, 'ぁ', 'ぃ', 'ぅ', 'ぇ', 'ぉ'),
  ?b   => Column.new(:i,  'ば', 'び', 'ぶ', 'べ', 'ぼ'),
  ?c   => Column.new(nil, 'つぁ', 'つぃ', 'つ', 'つぇ', 'つぉ'),
  ?d   => Column.new(:e,  'だ', 'でぃ', 'どぅ', 'で', 'ど'),
  'dc' => Column.new(nil, nil, nil, 'づ', nil, nil),
  'dj' => Column.new(nil, 'ぢゃ', 'ぢ', 'ぢゅ', 'ぢぇ', 'ぢょ'),
  'dw' => Column.new(nil, 'どぁ', 'どぃ', 'どぅ', 'どぇ', 'どぉ'),
  ?f   => Column.new(:u,  'ふぁ', 'ふぃ', 'ふ', 'ふぇ', 'ふぉ'),
  ?g   => Column.new(:i,  'が', 'ぎ', 'ぐ', 'げ', 'ご'),
  'gw' => Column.new(nil, 'ぐゎ', 'ぐぃ', 'ぐぅ', 'ぐぇ', 'ぐぉ'),
  ?h   => Column.new(:i,  'は', 'ひ', nil, 'へ', 'ほ'),
  ?j   => Column.new(nil, 'じゃ', 'じ', 'じゅ', 'じぇ', 'じょ'),
  ?k   => Column.new(:i,  'か', 'き', 'く', 'け', 'こ'),
  'kw' => Column.new(nil, 'くゎ', 'くぃ', 'くぅ', 'くぇ', 'くぉ'),
  ?K   => Column.new(nil, ?ヵ, nil, nil, ?ヶ, nil),
  ?l   => Column.new(nil, 'あ', 'い', 'う', 'え', 'お'),
  ?m   => Column.new(:i,  'ま', 'み', 'む', 'め', 'も'),
  ?n   => Column.new(:i,  'な', 'に', 'ぬ', 'ね', 'の'),
  ?p   => Column.new(:i,  'ぱ', 'ぴ', 'ぷ', 'ぺ', 'ぽ'),
  ?q   => Column.new(nil, 'ちゃ', 'ち', 'ちゅ', 'ちぇ', 'ちょ'),
  ?r   => Column.new(:i,  'ら', 'り', 'る', 'れ', 'ろ'),
  ?s   => Column.new('し', 'さ', 'すぃ', 'す', 'せ', 'そ'),
  'sw' => Column.new(nil, 'すぁ', nil, 'すぅ', 'すぇ', 'すぉ'),
  ?t   => Column.new(:e,  'た', 'てぃ', 'とぅ', 'て', 'と'),
  'tw' => Column.new(nil, 'とぁ', 'とぃ', nil, 'とぇ', 'とぉ'),
  ?v   => Column.new(:u,  'ゔぁ', 'ゔぃ', 'ゔ', 'ゔぇ', 'ゔぉ'),
  ?w   => Column.new(nil, 'わ', 'うぃ', nil, 'うぇ', 'を'),
  ?W   => Column.new(nil, ?ゎ, nil, nil, nil, nil),
  'wh' => Column.new(nil, 'うぁ', nil, nil, nil, 'うぉ'),
  'wy' => Column.new(nil, nil, 'ゑ', nil, 'ゐ', nil),
  ?x   => Column.new(nil, 'しゃ', 'し', 'しゅ', 'しぇ', 'しょ'),
  ?y   => Column.new(nil, 'や', nil, 'ゆ', 'いぇ', 'よ'),
  ?Y   => Column.new(nil, ?ゃ, nil, ?ゅ, nil, ?ょ),
  ?z   => Column.new(nil, 'ざ', 'ずぃ', 'ず', 'ぜ', 'ぞ'),
  'zw' => Column.new(nil, 'ずぁ', nil, 'ずぅ', 'ずぇ', 'ずぉ'),
  '@l' => Column.new(nil, 'ぁ', 'ぃ', 'ぅ', 'ぇ', 'ぉ'),
  '@lk' => Column.new(nil, 'ヵ', nil, nil, 'ヶ', nil),
  '@lw' => Column.new(nil, 'ゎ', nil, nil, nil, nil),
  '@ly' => Column.new(nil, 'ゃ', nil, 'ゅ', nil, 'ょ'),
}

GREEKS = 'αβψδεφγηιξκλμνοπθρστθωςχυζ'

$table = DATA.each_line.map{ _1.chomp.split /\s+/, 2 }.to_h

def insert k, v
  return unless v

  k = k.gsub(/⇧(\w)/) { $1.upcase }

  return if k =~ /^\d/

  raise "tried to set $table[#{k.inspect}] (currently #{$table[k].inspect}) to #{v.inspect}" if $table[k]

  $table[k] = v
end

def add_cons cons, column
  'aiueo'.chars.each do |vowel|
    insert cons + vowel, column[vowel]
  end

  {
    d: cons != '⇧' && [:e, ?ん],
    h: cons != '⇧' && [:u, ?っ],
    j: cons != '⇧' && [:u, ?ん],
    k: cons != '⇧' && [:i, ?ん],
    l: cons != '⇧' && [:o, ?ん],
    m: cons != '⇧' && [:i, ?っ],
    p: cons != '⇧' && [:o, ?っ],
    q: cons != '⇧' && [:a, ?い],
    r: cons != '⇧' && [:e, ?っ],
    s: cons != '⇧' && [:a, ?っ],
    z: cons != '⇧' && [:a, ?ん],
    1 => [:a, ?う],
    2 => [:a, ?う],
    3 => [:e, ?い],
    7 => [:u, ?う],
    8 => [:u, ?う],
    0 => cons != 'ny' && [:o, ?う],
  }.each do |rime, (original_vowel, suffix)|
    insert "#{cons}#{rime}", column[original_vowel]&.+(suffix) if original_vowel
  end
end

BaseChars.each do |cons, column|
  add_cons cons, column
  add_cons cons + ?y, column.yôon_column if column.yôon_column
end

GREEKS.chars.zip (?a..?z).to_a do |g, l|
  insert "##{l}", g
  insert "##{l.upcase}", g.upcase
end

File.write 'romantable.tsv', $table.map{|k, v| [k, *v.split].join(?\t) + ?\n }.sort.join
puts "Generated #{$table.size} entries."

__END__
_approx ≈
_bot ⊥
_cap ∩
_cup ∪
_dashv ⊣
_equiv ≡
_exists ∃
_forall ∀
_in ∈
_infty ∞
_land ∧
_lnot ¬
_lor ∨
_neq ≠
_ni ∋
_notin ∉
_odot ⊙
_ominus ⊖
_oplus ⊕
_oslash ⊘
_otimes ⊗
_pm ±
_prec ≺
_preceq ⪯
_simeq ≃
_subset ⊂
_subseteq ⊆
_subsetneq ⊊
_succ ≻
_succeq ⪰
_supset ⊃
_supseteq ⊇
_supsetneq ⊋
_times ×
_top ⊤
_varnothing ∅
_vdash ⊢
_vDash ⊨
- ー
, 、
; っ
. 。
[ 「
] 」
@.ae ə
@.Ae Ə
@.ng ŋ
@.Ng Ŋ
@@ @
@a ←
@d →
@lcu っ
@s ↓
@w ↑
~ 〜
a あ
e え
i い
n ん
nn ん
o お
u う
www w ww
z- 〜
z, ‥
z. …
z[ 『
z] 』
z/ ・
