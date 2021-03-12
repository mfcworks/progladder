require './Parser'
require './InstructionList'


module Helper

	#接点ロード系命令か？
	def self.contact_load?(cmd)
		["LD", "LDI", "LDP", "LDF", "LDPI", "LDFI"].include?(cmd) || cmd.start_with?("LD")
	end
	
	#接点論理積系命令か？
	def self.contact_and?(cmd)
		["AND", "ANI", "ANDP", "ANDF", "ANDPI", "ANDFI"].include?(cmd) || cmd.start_with?("AND")
	end
	
	#接点論理和系命令か？
	def self.contact_or?(cmd)
		["OR", "ORI", "ORP", "ORF", "ORPI", "ORFI"].include?(cmd) || cmd.start_with?("OR")
	end
	
	# Value生成
	def self.make_value(cmd, ary)
		if ["LD", "LDI", "LDP", "LDF", "LDPI", "LDFI"].include?(cmd) ||
			["AND", "ANI", "ANDP", "ANDF", "ANDPI", "ANDFI"].include?(cmd) ||
			["OR", "ORI", "ORP", "ORF", "ORPI", "ORFI"].include?(cmd) then
			device = ary[0]
			return Value.new device, cmd.include?("I"), cmd.include?("P"), cmd.include?("F")
		else
			return Value.new "[" + ary.unshift(cmd).join(" ") + "]"
		end
	end
	
	# 演算子優先順位比較
	# op1 > op2 なら正値、op1 < op2 なら負値を返す。
	def self.opcmp(op1, op2)
		ops = {}
		ops["->"] = 1
		ops["|"] = 2
		ops["&"] = 3
		ops[""] = 100 # 接点のみ

		if ops[op1] > ops[op2]
			return 1
		elsif ops[op1] < ops[op2]
			return -1
		else
			return 0
		end
	end

end

#二分木の末端ﾉｰﾄﾞ
class Value
	def initialize(name, inv=false, pls=false, plf=false)
		@name = name #ﾃﾞﾊﾞｲｽ名
		@inv = inv	#否定か？
		@pls = pls	#立上りか？
		@plf = plf	#立下りか？
		@mps_count = nil
	end
	
	def to_s
		s = @name
		s = "@" + s if @pls
		s = "%" + s if @plf
		s = "!" + s if @inv
		s = s + " *#{@mps_count}" if @mps_count #0も真
		s
	end
	
	def set_mps(count)
		@mps_count = count
	end
	
	def op
		""
	end
end

#二分木
class BinTree
	attr_reader :op
	
	def initialize(left, op, right)
		@left = left	#二分木または単一値
		@right = right	#二分木または単一値
		@op = op		#文字列
		@mps_count = nil
	end
	
	def paren_if(body, flag)
		if flag
			return "(" + body + ")"
		else
			return body
		end
	end
	
	#どうやってｼﾘｱﾙ化する？
	def to_s
		left = paren_if(@left.to_s, Helper.opcmp(@op, @left.op) > 0)
		right = paren_if(@right.to_s, Helper.opcmp(@op, @right.op) > 0)
		mps = ""
		if @mps_count
			mps = " *#{@mps_count}"
		end
		"#{left} #{@op} #{right}" + mps
	end
	
	def set_mps(count)
		@mps_count = count
	end
end




##### パーサの起動
filename = 'TP1_ORIG.csv'

il = InstructionList.new
il.add_command ["LDP", "X0"]
il.add_command ["LDI", "X1"]
il.add_command ["AND", "X2"]
il.add_command ["LD", "X3"]
il.add_command ["ANDFI", "X4"]
il.add_command ["ORB"]
il.add_command ["OR", "X5"]
il.add_command ["ANB"]
il.add_command ["OUT", "Y10"]
il.add_command ["OUT", "Y11"]
il.add_command ["OUT", "Y12"]
il.add_command ["END"]


=begin
il = InstructionList.new
il.add_command ["LD", "X1C"]
il.add_command ["MPS"]
il.add_command ["AND", "M8"]
il.add_command ["OUT", "Y30"]
il.add_command ["MPP"]
il.add_command ["OUT", "Y31"]
il.add_command ["LD", "X1D"]
il.add_command ["MPS"]
il.add_command ["AND", "M9"]
il.add_command ["MPS"]
il.add_command ["AND", "M68"]
il.add_command ["OUT", "Y32"]
il.add_command ["MPP"]
il.add_command ["AND", "T0"]
il.add_command ["OUT", "Y33"]
il.add_command ["MPP"]
il.add_command ["OUT", "Y34"]
il.add_command ["LD", "X1E"]
il.add_command ["AND", "M81"]
il.add_command ["MPS"]
il.add_command ["AND", "M96"]
il.add_command ["OUT", "Y35"]
il.add_command ["MRD"]
il.add_command ["AND", "M97"]
il.add_command ["OUT", "Y36"]
il.add_command ["MRD"]
il.add_command ["AND", "M98"]
il.add_command ["OUT", "Y37"]
il.add_command ["MPP"]
il.add_command ["OUT", "Y38"]
il.add_command ["END"]
=end


il = Parser.parse(filename)

#il.show_all
puts "---"
e = il.to_enum

stack = []
mps_count = -1
loop do
	ary = e.next
	
	# 行間ステートメントならスタックに積むだけ
	if ary.class == String
		stack.push ary
		next
	end
	
	cmd = ary[0] #命令
	if cmd == "ANB"
		right = stack.pop
		left = stack.pop
		stack.push BinTree.new(left, "&", right)
	elsif cmd == "ORB"
		right = stack.pop
		left = stack.pop
		stack.push BinTree.new(left, "|", right)
	elsif Helper.contact_load?(cmd)
		ary.shift
		stack.push Helper.make_value(cmd, ary)
	elsif Helper.contact_and?(cmd)
		ary.shift
		stack.push BinTree.new(stack.pop, "&", Helper.make_value(cmd, ary))
	elsif Helper.contact_or?(cmd)
		ary.shift
		stack.push BinTree.new(stack.pop, "|", Helper.make_value(cmd, ary))
	elsif cmd == "OUT"
		ary.shift
		stack.push BinTree.new(stack.pop, "->", Value.new(ary.join(" ")))
	#elsif 結合命令（INV, MEP, MEF, EGP, EGF）は特殊処理
	elsif cmd == "MPS"
		#メモリ記憶
		mps_count += 1
		stack.last.set_mps(mps_count)
	elsif cmd == "MPP" || cmd == "MRD"
		#メモリ読出し・取出し　LDみたいな感じにする
		stack.push Value.new("*" + mps_count.to_s)
		mps_count -= 1 if cmd == "MPP"
	elsif cmd == "END"
		#全終了
		stack.each do |tree|
			puts tree.to_s
		end
		raise "命令＝" + cmd
	#elsif  MCRなど、応用命令単体で用いられる命令（前の命令の続きで書かれるのを避けるため）
	# mcr, nop?, noplf, page, jmp, di, ei, imask, iret, for,next, ret, com?
	# ix, ixend, ixdev?, chkcir, chkend?,
	else
		#それ以外の応用命令
		ary.shift
		stack.push BinTree.new(stack.pop, "->", Helper.make_value(cmd, ary))
	end
	
end