=BEGIN
class TreeNode

	def initialize(left, value, right)
		@left = left
		@value = value
		@right = right
	end
	attr_reader :left, :value, :right

	def self.newValue(value)
		TreeNode.new(nil, value, nil)
	end

end
=END
