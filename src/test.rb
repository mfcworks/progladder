require './Parser'
require './CodeGen'

#src = "x0 *0 -> y0;\n *0 -> y1"
src = <<EOF



SM400 *0&X1040&!X1041->T200 K2;
*0&!X1040&X1041->T201 K2

# これはコメントです。
# cmnt 2
SM400 *0&X1042&!X1043->T202 K2;
*0&!X1042&X1043->T203 k2
# cmnt 2



# cmnt 2
# cmnt 2



EOF

lexer = Lexer.new(src)
parser = Parser.new(lexer)

il = []
while true
    parsed = parser.parse
    break if parsed == nil
    il += CodeGen.generate_all(parsed)
end

p il.length
il.each do |e|
    p e
end



=begin
lexer = Lexer.new(src)
parser = Parser.new(lexer)
asts = parser.parse
asts.each do |ast|
	CodeGen.generate(ast).each do |e|
        p e
    end
end

#    p ast
    CodeGen.generate(ast).each do |e|
        p e
    end
end

#parser.parse.each do |e|
#    p e
#end
=end
