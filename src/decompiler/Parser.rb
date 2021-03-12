# 命令ﾘｽﾄのCSVを読み込んでInstructionListｵﾌﾞｼﾞｪｸﾄを生成する

require 'CSV'
require './InstructionList'


class Parser
	def self.parse(csv_file)
		data = CSV.read(csv_file, encoding: "BOM|UTF-16LE", col_sep: "\t")

		#エンコーディング変換
		data.each_with_index do |array, i|
			array.each_with_index do |str, j|
				data[i][j] = str.encode("UTF-8")
			end
		end

		i = 0
		# 開始前
		loop do
			break if data[i][0] == "0"
			i += 1
			if i == data.length
				puts "パースエラー：ステップ番号0が見つかりません"
				return nil
			end
		end

		il = InstructionList.new

		#パース中
		cmd = []
		loop do
			if data[i][1] != ""
				# 行間ステートメントの場合
				if cmd.length != 0
					il.add_command cmd
					cmd = []
				end
				il.add_statement data[i][1]
			elsif data[i][0] == ""
				# 命令の続きの場合(オペランド)
				cmd.push data[i][3]
			else
				# 命令の開始(命令語)
				if cmd.length != 0
					il.add_command cmd
				end
				
				cmd = [data[i][2]]
				if data[i][3] != ""
					cmd.push data[i][3]
				end
			end

			i += 1
			if i == data.length
				if cmd.length != 0
					il.add_command cmd
				end
				break
			end
		end
		il
	end
end
