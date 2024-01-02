Table = Data.define :mappings do
  # @param data [#each_line]
  # @return [Table]
  def self.from_data data = DATA
    new mappings: data.each_line.map { _1.chomp.split /\s+/, 2 }.to_h
  end

  # @param mappings [Hash<String, String>]
  # @return [void]
  def initialize mappings: {}
    super
  end

  # @param k [String]
  # @param v [String, nil]
  # @return [String, nil]
  def insert k, v
    return unless v

    k = k.gsub(/⇧(\w)/) { $1.upcase }

    raise "tried to set table[#{k.inspect}] (currently #{mappings[k].inspect}) to #{v.inspect}" if mappings[k]

    mappings[k] = v
  end

  # @param column [Column]
  # @return [void]
  def add_column column
    'aiueo'.chars.each do |vowel|
      insert column.onset + vowel, column[vowel]
    end

    unless ['', '⇧'].include? column.onset
      {
        d: [:e, ?ん],
        h: [:u, ?っ],
        j: [:u, ?ん],
        k: [:i, ?ん],
        l: [:o, ?ん],
        m: [:i, ?っ],
        p: [:o, ?っ],
        q: [:a, ?い],
        r: [:e, ?っ],
        s: [:a, ?っ],
        z: [:a, ?ん],
        1 => [:a, ?う],
        2 => [:a, ?う],
        3 => [:e, ?い],
        7 => [:u, ?う],
        8 => [:u, ?う],
        0 => column.onset != 'ny' && [:o, ?う],
      }.each do |rime, (original_vowel, suffix)|
        insert "#{column.onset}#{rime}", column[original_vowel]&.+(suffix) if original_vowel
      end
    end
  end

  # @return [String]
  def to_tsv
    mappings.map{|k, v| [k, *v.split].join(?\t) + ?\n }.sort.join
  end
end

Column = Data.define :onset, :yôon_key, :a, :i, :u, :e, :o do
  alias_method :[], :send

  # @return [Column, nil]
  def yôon_column
    if yôon_key
      yôon_prefix =
        case yôon_key
        in String then yôon_key
        in Symbol then self[yôon_key]
        end

      Column.new(onset + ?y, nil, *'ゃぃゅぇょ'.chars.map { |small| yôon_prefix + small })
    end
  end
end

BASIC_COLUMNS = [
  Column.new(?⇧,   nil, 'ぁ', 'ぃ', 'ぅ', 'ぇ', 'ぉ'),
  Column.new(?b,   :i,  'ば', 'び', 'ぶ', 'べ', 'ぼ'),
  Column.new(?c,   nil, 'つぁ', 'つぃ', 'つ', 'つぇ', 'つぉ'),
  Column.new(?d,   :e,  'だ', 'でぃ', 'どぅ', 'で', 'ど'),
  Column.new('dc', nil, nil, nil, 'づ', nil, nil),
  Column.new('dj', nil, 'ぢゃ', 'ぢ', 'ぢゅ', 'ぢぇ', 'ぢょ'),
  Column.new('dw', nil, 'どぁ', 'どぃ', 'どぅ', 'どぇ', 'どぉ'),
  Column.new(?f,   :u,  'ふぁ', 'ふぃ', 'ふ', 'ふぇ', 'ふぉ'),
  Column.new(?g,   :i,  'が', 'ぎ', 'ぐ', 'げ', 'ご'),
  Column.new('gw', nil, 'ぐゎ', 'ぐぃ', 'ぐぅ', 'ぐぇ', 'ぐぉ'),
  Column.new(?h,   :i,  'は', 'ひ', nil, 'へ', 'ほ'),
  Column.new(?j,   nil, 'じゃ', 'じ', 'じゅ', 'じぇ', 'じょ'),
  Column.new(?k,   :i,  'か', 'き', 'く', 'け', 'こ'),
  Column.new('kw', nil, 'くゎ', 'くぃ', 'くぅ', 'くぇ', 'くぉ'),
  Column.new(?K,   nil, ?ヵ, nil, nil, ?ヶ, nil),
  Column.new(?l,   nil, 'あ', 'い', 'う', 'え', 'お'),
  Column.new(?m,   :i,  'ま', 'み', 'む', 'め', 'も'),
  Column.new(?n,   :i,  'な', 'に', 'ぬ', 'ね', 'の'),
  Column.new(?p,   :i,  'ぱ', 'ぴ', 'ぷ', 'ぺ', 'ぽ'),
  Column.new(?q,   nil, 'ちゃ', 'ち', 'ちゅ', 'ちぇ', 'ちょ'),
  Column.new(?r,   :i,  'ら', 'り', 'る', 'れ', 'ろ'),
  Column.new(?s,   'し', 'さ', 'すぃ', 'す', 'せ', 'そ'),
  Column.new('sw', nil, 'すぁ', nil, 'すぅ', 'すぇ', 'すぉ'),
  Column.new(?t,   :e,  'た', 'てぃ', 'とぅ', 'て', 'と'),
  Column.new('tw', nil, 'とぁ', 'とぃ', nil, 'とぇ', 'とぉ'),
  Column.new(?v,   :u,  'ゔぁ', 'ゔぃ', 'ゔ', 'ゔぇ', 'ゔぉ'),
  Column.new(?w,   nil, 'わ', 'うぃ', nil, 'うぇ', 'を'),
  Column.new(?W,   nil, ?ゎ, nil, nil, nil, nil),
  Column.new('wh', nil, 'うぁ', nil, nil, nil, 'うぉ'),
  Column.new('wy', nil, nil, 'ゑ', nil, 'ゐ', nil),
  Column.new(?x,   nil, 'しゃ', 'し', 'しゅ', 'しぇ', 'しょ'),
  Column.new(?y,   nil, 'や', nil, 'ゆ', 'いぇ', 'よ'),
  Column.new(?Y,   nil, ?ゃ, nil, ?ゅ, nil, ?ょ),
  Column.new(?z,   nil, 'ざ', 'ずぃ', 'ず', 'ぜ', 'ぞ'),
  Column.new('zw', nil, 'ずぁ', nil, 'ずぅ', 'ずぇ', 'ずぉ'),
  Column.new('@l', nil, 'ぁ', 'ぃ', 'ぅ', 'ぇ', 'ぉ'),
  Column.new('@lk', nil, 'ヵ', nil, nil, 'ヶ', nil),
  Column.new('@lw', nil, 'ゎ', nil, nil, nil, nil),
  Column.new('@ly', nil, 'ゃ', nil, 'ゅ', nil, 'ょ'),
]

GREEKS = 'αβψδεφγηιξκλμνοπθρστθωςχυζ'

table = Table.from_data

BASIC_COLUMNS.each do |column|
  table.add_column column
  table.add_column column.yôon_column if column.yôon_column
end

GREEKS.chars.zip (?a..?z).to_a do |g, l|
  table.insert "##{l}", g
  table.insert "##{l.upcase}", g.upcase
end

File.write 'romantable.tsv', table.to_tsv
$stderr.puts "Generated #{table.mappings.size} entries."

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
n ん
nn ん
www w ww
z- 〜
z, ‥
z. …
z[ 『
z] 』
z/ ・
