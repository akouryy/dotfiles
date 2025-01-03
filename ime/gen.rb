require 'cgi'
require 'strscan'

ROWS = {
  a: [:a, ''],
  A: [:a, ?ー],
  d: [:e, ?ん],
  D: [:e, ?く],
  e: [:e, ''],
  E: [:e, ?ー],
  i: [:i, ''],
  I: [:i, ?ー],
  j: [:u, ?ん],
  J: [:u, ?く],
  k: [:i, ?ん],
  K: [:i, ?く],
  l: [:o, ?ん],
  L: [:o, ?く],
  o: [:o, ''],
  O: [:o, ?ー],
  p: [:o, ?っ],
  P: [:o, ?つ],
  q: [:a, ?い],
  r: [:e, ?っ],
  R: [:e, ?つ],
  s: [:a, ?っ],
  S: [:a, ?つ],
  u: [:u, ''],
  U: [:u, ?ー],
  z: [:a, ?ん],
  Z: [:a, ?く],
  '2': [:a, ?う],
  '3': [:e, ?い],
  '7': [:u, ?う],
  '8': [:u, ?っ],
  '(': [:u, ?つ],
  '9': [:i, ?っ],
  ')': [:i, ?つ],
  '0': [:o, ?う],
}
RIMES_IN_DOCUMENT = %I[#{''} a i u e o z k j d l q 2 7 3 0 A I U E O s 9 8 r p Z K J D L S ) ( R P n]
raise if RIMES_IN_DOCUMENT.to_set != ROWS.keys.to_set + [:'', :n]

KEYBOARD_LAYOUT = [
  { false => %W[1 2 3 4 5 6 7 8 9 0 - ^ \\], true => %W[! " # $ % & ' ( ) #{''} = ~ |] },
  { false => %W[q w e r t y u i o p @ \[], true => %W[Q W E R T Y U I O P ` {] },
  { false => %W[a s d f g h j k l ; : \]], true => %W[A S D F G H J K L + * }] },
  { false => %W[z x c v b n m , . / _], true => %W[Z X C V B N M < > ? _] },
]

Table = Data.define :mappings, :columns do
  # @param data [#each_line]
  # @return [Table]
  def self.from_data data = DATA
    new mappings: data.each_line.map { _1.chomp.split /\s+/, 2 }.to_h
  end

  # @param mappings [Hash<String, String>]
  # @return [void]
  def initialize mappings: {}, columns: []
    super
  end

  # @param k [String]
  # @param v [String, nil]
  # @return [void]
  def insert k, v
    return unless v

    k = Column.normalize_roman k

    raise "tried to set table[#{k.inspect}] (currently #{mappings[k].inspect}) to #{v.inspect}" if mappings[k]

    mappings[k] = v
  end

  # @param column [Column]
  # @return [void]
  def add_columns column
    columns << column

    ROWS.each do |rime, (original_vowel, suffix)|
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

  # @return [String]
  def to_document_tsv
    header = [nil, *RIMES_IN_DOCUMENT]
    body = ONSETS_IN_DOCUMENT.map do |onset|
      [Column.normalize_roman(onset), *RIMES_IN_DOCUMENT.map { |rime| mappings[Column.normalize_roman "#{onset}#{rime}"] }]
    end

    [header, *body].map { |row| row.join(?\t) + ?\n }.join
  end

  # @return [String]
  def to_keyboard_svg
    highlight = '#c93965'
    ordinary = '#000'
    printed = '#ccc'
    special_rows = { ?_ => 'TeX', ?@ =>'特殊', ?# => "ギリ\nシャ" }
    ordinary_rows = { ?/ => '・' }

    <<~SVG
      <?xml version="1.0" encoding="UTF-8"?>
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="-20 -60 2680 920">
        #{[false, true].map { |rime|
          <<~SVG
            <g transform="translate(0, #{rime ? 450 : 0})">
              <text x="-10" y="-10" font-size="30" alignment-baseline="text-after-edge" fill="#000">
                #{rime ? '母音' : '子音'}
              </text>
              <text x="1315" y="-10" font-size="20" alignment-baseline="text-after-edge" fill="#000">
                Shift
              </text>
              #{[false, true].map { |shift|
                <<~SVG
                  <g transform="translate(#{shift ? 1325 : 0}, 0)">
                    <rect x="-10" y="-10" width="1310" height="410" fill="#fff3f3" />
                    #{KEYBOARD_LAYOUT.map.with_index { |row, y|
                      row[shift].map.with_index do |key, x|
                        color, label =
                          if rime
                            row = ROWS[key.to_sym]
                            if row
                              l = row.join
                              [l == key ? ordinary : highlight, l]
                            else
                              [printed, key]
                            end
                          else
                            column = columns.find { Column.normalize_roman(_1.onset) == key }

                            if column&.label
                              [column.label == key ? '#000' : highlight, column.label]
                            elsif special_rows[key]
                              [highlight, special_rows[key]]
                            elsif mappings[key]
                              [ordinary, mappings[key]]
                            elsif ordinary_rows[key]
                              [ordinary, ordinary_rows[key]]
                            else
                              [printed, key]
                            end
                          end

                        <<~SVG
                          <rect x="#{x * 100 + y * 50}" y="#{y * 100}" width="90" height="90" rx="5" ry="5" fill="#fff" stroke="#000" stroke-width="1" />
                          #{label.lines.map.with_index { |line, i|
                            <<~SVG
                              <text
                                x="#{x * 100 + y * 50 + 45}" y="#{y * 100 + 70 + 40 * (i - label.lines.size * 0.5)}"
                                font-size="40" text-anchor="middle" alignment-baseline="middle" fill="#{color}"
                              >
                                #{CGI.escapeHTML line.chomp}
                              </text>
                            SVG
                          }.join}
                        SVG
                      end
                    }.join}
                  </g>
                SVG
              }.join}
            </g>
          SVG
        }.join}
      </svg>
    SVG
  end
end

Column = Data.define :onset, :a, :i, :u, :e, :o, :allowed_vowels, :allowed_rimes, :label, :yôon_key, :yôon_column_properties do
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

  # @param roman [String]
  # @return [String]
  def self.normalize_roman roman
    roman.gsub(/⇧([a-z])/) { $1.upcase }
  end

  def initialize onset:, a:, i:, u:, e:, o:, allowed_vowels: /./, allowed_rimes: /./, label: nil, yôon_key: nil, yôon_column_properties: {}
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
  Column.parse(?⇧, 'ぁぃぅぇぉ', allowed_rimes: /[aiueo]/, yôon_key: '', yôon_column_properties: { allowed_vowels: /[auo]/, label: 'y小' }),
  Column.parse(?b, 'ばびぶべぼ', label: 'b', yôon_key: :i),
  Column.parse(?c, 'つぁつぃつつぇつぉ', label: 'ts'),
  Column.parse(?d, 'だでぃどぅでど', label: 'd', yôon_key: :e, yôon_column_properties: { allowed_vowels: /[aueo]/ }),
  Column.parse('dc', 'づぁづぃづづぇづぉ'),
  Column.parse('dj', 'ぢゃぢぢゅぢぇぢょ'),
  Column.parse('dw', 'どぁどぃ×どぇどぉ'),
  Column.parse(?f, 'ふぁふぃふふぇふぉ', label: 'f', yôon_key: :u, yôon_column_properties: { allowed_vowels: /[auo]/ }),
  Column.parse(?g, 'がぎぐげご', label: 'g', yôon_key: :i),
  Column.parse('gw', 'ぐゎぐぃぐぅぐぇぐぉ'),
  Column.parse(?h, 'はひ×へほ', label: 'h', yôon_key: :i),
  Column.parse(?j, 'じゃじじゅじぇじょ', label: 'j'),
  Column.parse(?k, 'かきくけこ', label: 'k', yôon_key: :i),
  Column.parse('kw', 'くゎくぃくぅくぇくぉ'),
  Column.parse(?K, 'ヵ××ヶ×'),
  Column.parse(?l, 'あいうえお', label: '∅'),
  Column.parse(?L, 'ぁぃぅぇぉ', label: '小', yôon_key: '', yôon_column_properties: { allowed_vowels: /[auo]/ }),
  Column.parse('Lk', 'ヵ××ヶ×'),
  Column.parse('Lw', 'ゎ××××'),
  Column.parse(?m, 'まみむめも', label: 'm', yôon_key: :i),
  Column.parse(?n, 'なにぬねの', label: 'n', yôon_key: :i, yôon_column_properties: { allowed_rimes: /[^0]/ }),
  Column.parse(?p, 'ぱぴぷぺぽ', label: 'p', yôon_key: :i),
  Column.parse(?q, 'ちゃちちゅちぇちょ', label: 'ch'),
  Column.parse(?r, 'らりるれろ', label: 'r', yôon_key: :i),
  Column.parse(?s, 'さすぃすせそ', label: 's'),
  Column.parse('sw', 'すぁ×すぅすぇすぉ'),
  Column.parse(?t, 'たてぃとぅてと', label: 't', yôon_key: :e, yôon_column_properties: { allowed_vowels: /[aueo]/ }),
  Column.parse('tw', 'とぁとぃ×とぇとぉ'),
  Column.parse(?v, 'ゔぁゔぃゔゔぇゔぉ', label: 'v', yôon_key: :u, yôon_column_properties: { allowed_vowels: /[auo]/ }),
  Column.parse(?w, 'わうぃ×うぇを', label: 'w'),
  Column.parse(?W, 'ゎ××××', label: 'w小'),
  Column.parse('wh', 'うぁ×××うぉ'),
  Column.parse('wy', '×ゑ×ゐ×'),
  Column.parse(?x, 'しゃししゅしぇしょ', label: 'sh'),
  Column.parse(?y, 'や×ゆいぇよ', label: 'y'),
  Column.parse(?z, 'ざずぃずぜぞ', label: 'z'),
  Column.parse('zw', 'ずぁ×ずぅずぇずぉ'),
]
ONSETS_IN_DOCUMENT = %W[
  #{''} l ⇧ L k K Lk ky kw g gy gw s sw x z j zw t q c Lc ; ty tw d dj dc dy dw n ny
  h hy f fy b by p py m my y ⇧y Ly r ry w W Lw wh wy v vy
]
begin
  all_onsets = BASIC_COLUMNS.flat_map { |column| [column.onset, column.yôon_column&.onset].compact }.to_set + %w[Lc ;]
  onset_diff = (all_onsets - ONSETS_IN_DOCUMENT.to_set) | (ONSETS_IN_DOCUMENT.to_set - all_onsets)
  raise "onsets mismatch: #{onset_diff.join ?,}" if onset_diff.any?
end

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
File.write 'document.tsv', table.to_document_tsv
File.write 'keyboard.svg', table.to_keyboard_svg

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
@^- ⁻
@^( ⁽
@^) ⁾
@^+ ⁺
@^= ⁼
@^0 ⁰
@^1 ¹
@^2 ²
@^3 ³
@^4 ⁴
@^5 ⁵
@^6 ⁶
@^7 ⁷
@^8 ⁸
@^9 ⁹
@^a ᵃ
@^A ᴬ
@^b ᵇ
@^B ᴮ
@^c ᶜ
@^d ᵈ
@^D ᴰ
@^e ᵉ
@^E ᴱ
@^f ᶠ
@^g ᵍ
@^G ᴳ
@^h ʰ
@^H ᴴ
@^i ⁱ
@^I ᴵ
@^j ʲ
@^J ᴶ
@^k ᵏ
@^K ᴷ
@^l ˡ
@^L ᴸ
@^m ᵐ
@^M ᴹ
@^n ⁿ
@^N ᴺ
@^o ᵒ
@^O ᴼ
@^p ᵖ
@^P ᴾ
@^r ʳ
@^s ˢ
@^t ᵗ
@^T ᵀ
@^u ᵘ
@^U ᵁ
@^v ᵛ
@^V ⱽ
@^x ˣ
@^y ʸ
@^z ᶻ
@a ←
@d →
@s ↓
@w ↑
~ 〜
Lcu っ
n ん
nn ん
www w ww
z, ‥
z[ 『
z] 』
z/ ・
