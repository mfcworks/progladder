require 'Lexer'
require 'Parser'
require 'CodeGen'

class Compiler

    def initialize
        @il = nil
        @src_string = ""
        @compiled_string = ""
    end

    def from_file(source_file)
        @src_string = ""
        f = File.new(source_file)
        while (line = f.gets) != nil
            @src_string += line
        end
        f.close_read
#        puts @src_string

        self
    end

    def from_string(str)
        @src_string = str

        self
    end

    def compile
        lexer = Lexer.new(@src_string)
        parser = Parser.new(lexer)

        @il = []
        while true
            parsed = parser.parse
            break if parsed == nil
            @il += CodeGen.generate_all(parsed)
        end
        # 最後にEND命令を加える。
        @il.push ["END"]

        self
    end

    def save_to_file(csv_file)
        File.open(csv_file, 'wb+:UTF-16LE') do |file|
            file.write "\uFEFF"  # BOMを出力
            file.write @compiled_string.encode('UTF-16LE')
        end
    end

    def format
        buf = "\r\n\r\n\r\n"
        @il.each do |e|
            if e.class == String
                # 行間ステートメント
                buf += "\t\"#{e}\"\r\n"
            else
                # 命令
                if e.length == 1
                    # ex.  INV
                    buf += "\t\t\"#{e[0]}\"\r\n"
                elsif e.length == 2
                    # ex.  LD X0
                    buf += "\t\t\"#{e[0]}\"\t\"#{e[1]}\"\r\n"
                else
                    # ex.  OUT T1 K10
                    buf += "\t\t\"#{e[0]}\"\t\"#{e[1]}\"\r\n"
                    e.shift(2)
                    e.each do |a|
                        buf += "\t\t\t\"#{a}\"\r\n"
                    end
                end
            end
        end
        @compiled_string = buf

        self
    end

    def test
        puts @compiled_string
    end
end
