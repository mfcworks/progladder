class InstructionList
	include Enumerable
	
	def initialize
		# IL = リストのリスト。
		@list = []
	end
	
	# 行間ステートメントを追加する
	def add_statement(statement)
		@list.push statement
	end
	
	# 命令を追加する
	def add_command(array)
		@list.push array.dup
	end
	
	def each
		@list.each do |e|
			yield e
		end
	end
	
	def show_all
		@list.each do |value|
			if value.class == String
				puts "■■■" + value 
			else
				puts value.join(" ")
			end
		end
	end
end
