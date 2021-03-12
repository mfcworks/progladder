# TreeNode ｸﾗｽ

# 木構造のﾉｰﾄﾞの抽象ｸﾗｽ
class TreeNode
	def initialize
		@has_tag = false
	end
	attr_accessor :has_tag
end

# 演算子のﾉｰﾄﾞ
class OperatorNode < TreeNode
	def initialize(left, op, right)
		super()
		@left = left
		@op = op
		@right = right
	end
	attr_reader :left, :op, :right

	def inspect
		"(#{@left.inspect} #{@op.inspect} #{@right.inspect})"
	end
end

# 値のﾉｰﾄﾞ(葉ﾉｰﾄﾞ専用)
class ValueNode < TreeNode
	def initialize(value)
		super()
		@value = value
		@mpp_flag = false # trueならMPP, falseならMRD
	end
	attr_reader :value

	def setmpp
		@mpp_flag = true
	end

	def mpp?
		@mpp_flag
	end

	def inspect
		if @value.class == Array
			"[" + @value.map{|x| x.inspect}.join(" ") + "]"
		elsif @value.tag?
			"#{@value.inspect}(#{@mpp_flag ? "MPP" : "MRD"})"
		else
			@value.inspect
		end
	end
end

# 関数のﾉｰﾄﾞ(INV等)
class FunctionNode < TreeNode
	def initialize(func, body)
		super()
		@func = func
		@body = body
	end
	attr_reader :func, :body

	def inspect
		"(#{@body.inspect} #{@func.inspect})"
	end
end


# ｵﾌﾞｼﾞｪｸﾄがTreeNodeかの判定方法
# puts <obj>.is_a?(TreeNode)
