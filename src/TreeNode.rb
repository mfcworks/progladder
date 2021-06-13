# TreeNode クラス

# 木構造のノードの抽象クラス
class TreeNode
    def initialize
        @has_tag = false
    end
    attr_accessor :has_tag
end

# 演算子のノード
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

# 値のノード(葉ノード専用)
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

# 関数のノード(INV等)
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

# 分枝のノード( { ... } )
class BranchNode < TreeNode
    def initialize(data)
        super()
        @data = data
    end

    def inspect
        @data
    end
end

# オブジェクトがTreeNodeかの判定方法
# puts <obj>.is_a?(TreeNode)
