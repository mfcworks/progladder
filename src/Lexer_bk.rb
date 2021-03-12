#
#	Lexer.rb
#

class Token
	def initialize(value, no_upcase=false)
		@value = no_upcase ? value : value.upcase # ここで全て大文字化しておく
		@type_identifier = false
		@type_tag = false
		@type_statement = false
	end
	attr_accessor :type_identifier, :type_tag, :type_statement
	attr_reader :value

	def self.newSymbol(value)
		Token.new(value)
	end

	def self.newIdenfitier(value)
		token = Token.new(value)
		token.type_identifier = true
		token
	end

	def self.newTag(value)
		token = Token.new(value)
		token.type_tag = true
		token
	end

	# 行間ｽﾃｰﾄﾒﾝﾄ
	def self.newStatement(statement)
		token = Token.new(statement, true)
		token.type_statement = true
		token
	end

	def identifier?
		@type_identifier
	end

	def tag?
		@type_tag
	end

	def statement?
		@type_statement
	end

	def tag_no
		raise "タグではありません。" unless @type_tag
		@value.sub(/\*/, "").to_i
	end

	# 三菱PLCにおける結合命令か？
	def association_instruction?
		["INV", "MEP", "MEF"].include?(@value)
	end

	# デバイスがタイマまたはカウンタであるか？
	def timer_or_counter?
		if !identifier? || association_instruction?
			# 識別子でないか、結合命令であればfalse
			false
		elsif @value.start_with?("T") || @value.start_with?("ST")
			# デバイス名がTから始まれば低速タイマ、STから始まれば高速タイマ
			true
		elsif @value.start_with?("C")
			# デバイス名がCから始まればカウンタ
			true
		end
	end

	# AND, OR, OUT のうち self が other より
	# 優先する場合 true を返す。
	def precede?(other)
		# & > | , | < &
		# & > -> , | > ->
		# -> > & , (-> | 禁止入力)
		if @value == "|" && other.value == "&"
			false
		else
			true
		end
	end


	AND = Token.newSymbol("&")
	OR = Token.newSymbol("|")
	OUT = Token.newSymbol("->")
	OUTH = Token.newSymbol("->H") # 高速タイマ専用
	OPENPAREN = Token.newSymbol("(")
	CLOSEPAREN = Token.newSymbol(")")
	OPENBRACE = Token.newSymbol("[")
	CLOSEBRACE = Token.newSymbol("]")
	SEMICOLON = Token.newSymbol(";")

	def self.get_symbol(str)
		[AND, OR, OUT, OUTH, OPENPAREN, CLOSEPAREN, OPENBRACE, CLOSEBRACE, SEMICOLON].each do |s|
			return s if s.value == str
		end
		raise "TokenError : #{str} is not a symbol"
	end

	def inspect
		if @type_identifier
			@value # + "\tas Identifier"
		elsif @type_tag
			@value # + "\tas Tag"
		else
			@value
		end
	end
end





class Lexer
	# Group 1 : (Only) Identifier; Device or Instruction including string literal
	# Group 2 : Comment starting with '#' -> Ignore.
	# Group 3 : Tag
	# Group 4 : Symbol
	PATTERN = /\s*((#.*)|(\*[0-9]+)|(&|\||->H?|\(|\)|\[|\]|;)|[A-Za-z$]*(?:[<>=]+|[+\-\*\/])[A-Za-z]*|!?[@%]?[A-Za-z$][A-Za-z0-9$\.\\]*|"(\\"|\\|[^"])*")/

	def initialize(source_multiline)
		@source_lines = source_multiline.split("\n")
	end

	def lex
	end

	def lex_line
		loop do
			str = @source_lines.shift
			return nil if str == nil
			tokens = Lexer._lex_line(str)
			return tokens if tokens.length != 0
		end
	end

	def self._lex_line(str)
		pos = 0
		end_pos = str.length
		tokens = []
		while pos < end_pos
			match_data = PATTERN.match(str, pos)
			raise "LexerError : Unmatched." if match_data == nil
			if match_data[2] == nil
				# コメントでないとき
				if match_data[3] != nil
					# タグの場合
					tokens.push Token.newTag(match_data[3])
				elsif match_data[4] != nil
					# 記号(シンボル)の場合
					tokens.push Token.get_symbol(match_data[4])
				else
					# 識別子の場合
					tokens.push Token.newIdenfitier(match_data[1])
				end
			else
				# 行間ｽﾃｰﾄﾒﾝﾄの場合
				tokens.push Token.newStatement(match_data[2])
			end
			pos = match_data.end(0)
		end
		tokens
	end
end

# test
#code = ARGV[0]
#Lexer.lex_line(code).each do |tk|
#	puts tk.inspect
#end
