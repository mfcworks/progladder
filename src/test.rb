require_relative 'Lexer'
require_relative 'Parser'

src = <<EOF
a & {
    b -> c
    d -> e
    f -> g
}
EOF

lexer = Lexer.new(src)
tokens = lexer.lex
parser = Parser.new(tokens)
p parser.parse
