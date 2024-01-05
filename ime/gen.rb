require 'strscan'

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
  # @return [void]
  def insert k, v
    return unless v

    k = k.gsub(/⇧(\w)/) { $1.upcase }

    raise "tried to set table[#{k.inspect}] (currently #{mappings[k].inspect}) to #{v.inspect}" if mappings[k]

    mappings[k] = v
  end

  # @param column [Column]
  # @return [void]
  def add_columns column
    {
      a: [:a, ''],
      d: [:e, ?ん],
      e: [:e, ''],
      i: [:i, ''],
      j: [:u, ?ん],
      k: [:i, ?ん],
      l: [:o, ?ん],
      o: [:o, ''],
      p: [:o, ?っ],
      q: [:a, ?い],
      r: [:e, ?っ],
      s: [:a, ?っ],
      u: [:u, ''],
      z: [:a, ?ん],
      '2': [:a, ?う],
      '3': [:e, ?い],
      '7': [:u, ?う],
      '8': [:u, ?っ],
      '9': [:i, ?っ],
      '0': [:o, ?う],
    }.each do |rime, (original_vowel, suffix)|
      if column.allowed_rimes =~ rime && column.allowed_vowels =~ original_vowel
        insert "#{column.onset}#{rime}", column[original_vowel]&.+(suffix) if original_vowel
      end
    end

    add_columns column.yôon_column if column.yôon_column
  end

  # @return [String]
  def to_tsv
    mappings.map{|k, v| [k, *v.split].join(?\t) + ?\n }.sort.join
  end
end

Column = Data.define :onset, :a, :i, :u, :e, :o, :allowed_vowels, :allowed_rimes, :yôon_key, :yôon_column_properties do
  alias_method :[], :send

  # "あいうえお" という文字列を a: "あ", i: "い", ... という Column に変換する。
  # 大きい文字と小さい文字が連続する場合、ひとまとまりになる。
  # nil は "×" で表す。
  # @param onset [String]
  # @param string [String]
  # @param yôon_key [String, Symbol, nil]
  # @return [Column]
  def self.parse onset, string, **kwargs
    aiueo = []

    scanner = StringScanner.new string

    until scanner.eos?
      scanner.scan %r[
        (?<none> ×)
      | (?<kana>
          [\p{Hiragana}\p{Katakana}]
          (?:
            (?<! [ぁぃぅぇぉヵヶゃゅょゎ]) # 小さい文字同士の連続は、ひとまとまりにしない
            [ぁぃぅぇぉヵヶゃゅょゎ]
          )?+
        )
      ]x
      raise "invalid string: #{scanner.inspect}" unless scanner.matched?

      aiueo << (scanner[:none] ? nil : scanner[:kana])
    end

    aiueo => [a, i, u, e, o]

    Column.new onset:, a:, i:, u:, e:, o:, **kwargs
  end

  def initialize onset:, a:, i:, u:, e:, o:, allowed_vowels: /./, allowed_rimes: /./, yôon_key: nil, yôon_column_properties: {}
    super
  end

  # @return [Column, nil]
  def yôon_column
    if yôon_key
      yôon_prefix =
        case yôon_key
        in String then yôon_key
        in Symbol then self[yôon_key]
        end

      Column.new(
        onset: onset + ?y,
        **'aiueo'.chars.zip('ゃぃゅぇょ'.chars).to_h { |vowel, small| [vowel.to_sym, yôon_prefix + small] },
        **yôon_column_properties,
      )
    end
  end
end

BASIC_COLUMNS = [
  Column.parse('', 'あいうえお', allowed_rimes: /[aiueo]/),
  Column.parse(?⇧, 'ぁぃぅぇぉ', allowed_rimes: /[aiueo]/, yôon_key: '', yôon_column_properties: { allowed_vowels: /[auo]/ }),
  Column.parse(?b, 'ばびぶべぼ', yôon_key: :i),
  Column.parse(?c, 'つぁつぃつつぇつぉ'),
  Column.parse(?d, 'だでぃどぅでど', yôon_key: :e, yôon_column_properties: { allowed_vowels: /[aueo]/ }),
  Column.parse('dc', 'づぁづぃづづぇづぉ'),
  Column.parse('dj', 'ぢゃぢぢゅぢぇぢょ'),
  Column.parse('dw', 'どぁどぃ×どぇどぉ'),
  Column.parse(?f, 'ふぁふぃふふぇふぉ', yôon_key: :u, yôon_column_properties: { allowed_vowels: /[auo]/ }),
  Column.parse(?g, 'がぎぐげご', yôon_key: :i),
  Column.parse('gw', 'ぐゎぐぃぐぅぐぇぐぉ'),
  Column.parse(?h, 'はひ×へほ', yôon_key: :i),
  Column.parse(?j, 'じゃじじゅじぇじょ'),
  Column.parse(?k, 'かきくけこ', yôon_key: :i),
  Column.parse('kw', 'くゎくぃくぅくぇくぉ'),
  Column.parse(?K, 'ヵ××ヶ×'),
  Column.parse(?l, 'あいうえお'),
  Column.parse(?m, 'まみむめも', yôon_key: :i),
  Column.parse(?n, 'なにぬねの', yôon_key: :i, yôon_column_properties: { allowed_rimes: /[^0]/ }),
  Column.parse(?p, 'ぱぴぷぺぽ', yôon_key: :i),
  Column.parse(?q, 'ちゃちちゅちぇちょ'),
  Column.parse(?r, 'らりるれろ', yôon_key: :i),
  Column.parse(?s, 'さすぃすせそ'),
  Column.parse('sw', 'すぁ×すぅすぇすぉ'),
  Column.parse(?t, 'たてぃとぅてと', yôon_key: :e, yôon_column_properties: { allowed_vowels: /[aueo]/ }),
  Column.parse('tw', 'とぁとぃ×とぇとぉ'),
  Column.parse(?v, 'ゔぁゔぃゔゔぇゔぉ', yôon_key: :u, yôon_column_properties: { allowed_vowels: /[auo]/ }),
  Column.parse(?w, 'わうぃ×うぇを'),
  Column.parse(?W, 'ゎ××××'),
  Column.parse('wh', 'うぁ×××うぉ'),
  Column.parse('wy', '×ゑ×ゐ×'),
  Column.parse(?x, 'しゃししゅしぇしょ'),
  Column.parse(?y, 'や×ゆいぇよ'),
  Column.parse(?z, 'ざずぃずぜぞ'),
  Column.parse('zw', 'ずぁ×ずぅずぇずぉ'),
  Column.parse('@l', 'ぁぃぅぇぉ', yôon_key: '', yôon_column_properties: { allowed_vowels: /[auo]/ }),
  Column.parse('@lk', 'ヵ××ヶ×'),
  Column.parse('@lw', 'ゎ××××'),
]

GREEKS = 'αβψδεφγηιξκλμνοπθρστθωςχυζ'

table = Table.from_data

BASIC_COLUMNS.each do |column|
  table.add_columns column
end

GREEKS.chars.zip (?a..?z).to_a do |g, l|
  table.insert "##{l}", g
  table.insert "##{l.upcase}", g.upcase
end

File.write 'romantable.tsv', table.to_tsv

if $DEBUG
  table.mappings.group_by(&:last).sort.each do |value, keys|
    $stderr.puts "#{value.inspect} is associated with multiple romanizations: #{keys.map(&:first)}" if keys.size > 1
  end
end

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
z, ‥
z[ 『
z] 』
z/ ・
