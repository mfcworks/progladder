# コードジェネレーター

class CodeGen

    def initialize
        @il = []
    end
    attr_reader :il

    # コード生成開始
    def self.generate_all(asts)
        result = []
        asts.each do |ast|
            result += CodeGen.generate(ast)
        end
        result
    end

    def self.generate(ast)
        gen = CodeGen.new()
        gen.traverse ast
        gen.il
    end

    # 構文木の再帰読み込み(トラバース)
    def traverse(ast)
        if ast.is_a?(Token)
            if ast.statement?
                @il.push ast.value
                return
            else
                raise "CodeGenError: invalid token"
            end
        elsif ast.is_a?(ValueNode)
            # 値ノードの場合
            gen_load ast
        elsif ast.is_a?(OperatorNode)
            # 演算子ノードの場合
            # 左辺を解析
            traverse ast.left
            # 右辺が値か、木か
            if ast.right.is_a?(ValueNode)
                # 右辺が値の場合(op=AND/OR/OUT)
                gen_op ast.op, ast.right.value
            else
                # 右辺が木の場合
                traverse ast.right
                if ast.op == Token::AND
                    @il.push ["ANB"]
                elsif ast.op == Token::OR
                    @il.push ["ORB"]
                else
                    raise "CodeGenError : invalid op"
                end
            end
        elsif ast.is_a?(FunctionNode)
            # 結合命令ノードの場合
            # 本体を先にトラバース
            traverse ast.body
            # 結合命令を追加
            @il.push [ast.func.value]
        else
            raise "CodeGenError : invalid tree"
        end
        @il.push ["MPS"] if ast.has_tag
    end

    def lex_device(str)
        md = /(!)?([@%])?([A-Za-z$][A-Za-z0-9$\.\\]*)/.match(str)
        device = md[3]
        inv = (md[1] == "!")
        pls = (md[2] == "@")
        plf = (md[2] == "%")
        device = md[3]
        [inv, pls, plf, device]
    end

    # LD系命令を生成
    def gen_load(ast)
        if ast.value.class != Array
            if ast.value.tag?
                # MRD / MPP
                @il.push (ast.mpp? ? ["MPP"] : ["MRD"])
            else
                # LD LDI LDP LDF LDPI LDFI
                inv, pls, plf, device = lex_device(ast.value.value)
                instcuction = "LD"
                instcuction += "P" if pls
                instcuction += "F" if plf
                instcuction += "I" if inv
                @il.push [instcuction, device]
            end
        else
            cmd = ast.value.dup
            cmd[0] = "LD" + cmd[0]
            @il.push cmd
        end
    end

    # 演算子(AND/OR)系命令を生成
    def gen_op(op, value)
        if op == Token::AND
            if value.class != Array
                # AND ANI ANDP ANDF ANDPI ANDFI
                inv, pls, plf, device = lex_device(value.value)
                instruction = "AND"
                instruction += "P" if pls
                instruction += "F" if plf
                instruction += "I" if inv
                instruction = "ANI" if instruction == "ANDI"
                @il.push [instruction, device]
            else
                cmd = value.map { |e| e.value }
                cmd[0] = "AND" + cmd[0]
                @il.push cmd
            end
        elsif op == Token::OR
            if value.class != Array
                # OR ORI ORP ORF ORPI ORFI
                inv, pls, plf, device = lex_device(value.value)
                instruction = "OR"
                instruction += "P" if pls
                instruction += "F" if plf
                instruction += "I" if inv
                @il.push [instruction, device]
            else
                cmd = value.map { |e| e.value }
                cmd[0] = "OR" + cmd[0]
                @il.push cmd
            end
        elsif op == Token::OUT
            if value.class != Array
                # 出力コイル
                @il.push ["OUT", value.value]
            elsif value[0] == "OUT" || value[0] == "OUTH"
                # タイマ・カウンタ
                @il.push [value[0], value[1].value, value[2].value]
            else
                # 応用命令
                cmd = value.map { |e| e.value }
                @il.push cmd
            end
        else
            raise "CodeGenError : invalid op"
        end
    end


end
