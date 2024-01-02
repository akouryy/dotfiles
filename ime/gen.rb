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

  # "あいうえお" という文字列を a: "あ", i: "い", ... という Column に変換する。
  # 大きい文字と小さい文字が連続する場合、ひとまとまりになる。
  # nil は "×" で表す。
  # @param onset [String]
  # @param string [String]
  # @param yôon_key [String, Symbol, nil]
  # @return [Column]
  def self.parse onset, string, yôon_key: nil
    aiueo = []

    scanner = StringScanner.new string

    until scanner.eos?
      scanner.scan %r[
        (?<none> ×)
      | (?<kana>
          [\p{Hiragana}\p{Katakana}]
          (?:
            (?<! [ぁぃぅぇぉヵヶゃゅょゎ])
            [ぁぃぅぇぉヵヶゃゅょゎ]
          )?+
        )
      ]x
      raise "invalid string: #{scanner.inspect}" unless scanner.matched?

      aiueo << (scanner[:none] ? nil : scanner[:kana])
    end

    aiueo => [a, i, u, e, o]

    Column.new(onset:, yôon_key:, a:, i:, u:, e:, o:)
  end

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
  Column.parse('', 'あいうえお'),
  Column.parse(?⇧, 'ぁぃぅぇぉ'),
  Column.parse(?b, 'ばびぶべぼ', yôon_key: :i),
  Column.parse(?c, 'つぁつぃつつぇつぉ'),
  Column.parse(?d, 'だでぃどぅでど', yôon_key: :e),
  Column.parse('dc', '××づ××'),
  Column.parse('dj', 'ぢゃぢぢゅぢぇぢょ'),
  Column.parse('dw', 'どぁどぃどぅどぇどぉ'),
  Column.parse(?f, 'ふぁふぃふふぇふぉ', yôon_key: :u),
  Column.parse(?g, 'がぎぐげご', yôon_key: :i),
  Column.parse('gw', 'ぐゎぐぃぐぅぐぇぐぉ'),
  Column.parse(?h, 'はひ×へほ', yôon_key: :i),
  Column.parse(?j, 'じゃじじゅじぇじょ'),
  Column.parse(?k, 'かきくけこ', yôon_key: :i),
  Column.parse('kw', 'くゎくぃくぅくぇくぉ'),
  Column.parse(?K, 'ヵ××ヶ×'),
  Column.parse(?l, 'あいうえお'),
  Column.parse(?m, 'まみむめも', yôon_key: :i),
  Column.parse(?n, 'なにぬねの', yôon_key: :i),
  Column.parse(?p, 'ぱぴぷぺぽ', yôon_key: :i),
  Column.parse(?q, 'ちゃちちゅちぇちょ'),
  Column.parse(?r, 'らりるれろ', yôon_key: :i),
  Column.parse(?s, 'さすぃすせそ', yôon_key: 'し'),
  Column.parse('sw', 'すぁ×すぅすぇすぉ'),
  Column.parse(?t, 'たてぃとぅてと', yôon_key: :e),
  Column.parse('tw', 'とぁとぃ×とぇとぉ'),
  Column.parse(?v, 'ゔぁゔぃゔゔぇゔぉ', yôon_key: :u),
  Column.parse(?w, 'わうぃ×うぇを'),
  Column.parse(?W, 'ゎ××××'),
  Column.parse('wh', 'うぁ×××うぉ'),
  Column.parse('wy', '×ゑ×ゐ×'),
  Column.parse(?x, 'しゃししゅしぇしょ'),
  Column.parse(?y, 'や×ゆいぇよ'),
  Column.parse(?Y, 'ゃ×ゅ×ょ'),
  Column.parse(?z, 'ざずぃずぜぞ'),
  Column.parse('zw', 'ずぁ×ずぅずぇずぉ'),
  Column.parse('@l', 'ぁぃぅぇぉ'),
  Column.parse('@lk', 'ヵ××ヶ×'),
  Column.parse('@lw', 'ゎ××××'),
  Column.parse('@ly', 'ゃ×ゅ×ょ'),
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
