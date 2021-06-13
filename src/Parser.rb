require_relative 'Lexer'
require_relative 'TreeNode'


class Parser

    def initialize(token_list)
        @token_list = token_list
    end

    # パーサのメインメソッド
    def parse(sub=false)
        tokens = @token_list

        #パース開始時にトークンがなければnilを返す
        return nil if tokens == nil

        # 行間ステートメントならそれ自体を返す
        if tokens.length == 1 && tokens[0].statement?
            return tokens
        end

        output = [] # 出力キュー
        op_stack = [] # 演算子スタック
        completed = [] # 完成品置き場
        flag_semicolon = false

        # タグを使うオブジェクトを記憶しておく
        tag_list = [[], [], [], [], [], [], [], [], [], [], [], [], [], [], [], []]
        # tag_list = 16.times.map { [] }

        while tokens.length > 0
            token = tokens.shift
            if token.identifier?
                # 値のみ
#                # 値か結合命令
#                if token.association_instruction?
#                    # 結合命令(INV等々)の場合
#                    # ！特異的な処理のため要注意！
#                    # 1) 演算子スタックに AND があったら出力キューに移動する。
#                    # 2) 結合命令を出力キューに追加する。
#                    while op_stack.last == Token::AND
#                        output.push op_stack.pop
#                    end
#                    output.push token
#                else
                    # 値の場合：トークンをValueNodeにして出力キューに突っ込む
                    raise "ParseError : Invalid flag_semicolon" if flag_semicolon
                    output.push ValueNode.new(token)
#                end
            elsif token.tag?
                # *タグ
                # セミコロンの直後のタグかどうか
                if flag_semicolon
                    # 【MRD/MPP位置のタグの場合】
                    flag_semicolon = false

                    node = ValueNode.new(token)
                    # ノードをタグリストに記憶
                    tag_list[token.tag_no].push node

                    output.push node
                else
                    # 【MPS位置のタグの場合】
                    # 演算子スタックの中身をすべて出力キューに追加する。
                    while !(op_stack.empty?)
                        output.push op_stack.pop
                    end
                    # 出力キューの要素から構文木を構築する。
                    elems = []
                    while !(output.empty?)
                        elems.push output.shift
                    end
                    ast = generate_tree(elems)
                    # 構文木のトップノードにタグ有りフラグを追加してoutputに置く。
                    ast.has_tag = true
                    output.push ast
                end

            elsif token == Token::OPENPAREN
            # "("の場合：演算子スタックにプッシュ
                op_stack.push token
            elsif token == Token::CLOSEPAREN
            # ")"の場合：
                while (op_stack.last != Token::OPENPAREN && op_stack.last != nil)
                    output.push op_stack.pop
                end
                if op_stack.last == Token::OPENPAREN
                    op_stack.pop
                elsif op_stack.last == nil
                    raise "ParseError : 対応する左括弧 ( が見つかりません。"
                end
            elsif token == Token::OPENBRACE
            # "[" の場合：トークンリストを配列にしてValueNodeにして出力キューに突っ込む
                ary = []
                loop do
                    t = tokens.shift
                    raise "ParseError : 対応する ] が見つかりません。" if t == nil
                    break if t == Token::CLOSEBRACE
                    ary.push t
                end
                output.push ValueNode.new(ary)
            elsif token == Token::CLOSEBRACE
                raise "ParseError : 対応しない ] が見つかりました。"
            elsif token == Token::OPENBRACKET
                res = []
                loop do
                    res += self.parse(true) # 再帰的にパースを行なう
                    raise "ParseError : 対応する } が見つかりません。" if tokens.length == 0
                    break if tokens[0] == Token::CLOSEBRACKET
                end
                tokens.shift
                output.push BranchNode.new(res)
            elsif token == Token::CLOSEBRACKET
                raise "ParseError : 対応しない } が見つかりました。"
            elsif token == Token::OUT
                # 演算子スタックの中身をすべて出力キューに追加する。
                while !(op_stack.empty?)
                    output.push op_stack.pop
                end
                # 出力キューの要素から構文木を構築する。
                elems = []
                while !(output.empty?)
                    elems.push output.shift
                end
                ast = generate_tree(elems)
                # -> の直後はデバイスか応用命令であるはず。
                # -> の直後が `(` の場合も終わるまで取得する
                t = tokens.shift
                if t == Token::OPENBRACE
                    ary = []
                    loop do
                        t = tokens.shift
                        raise "ParseError : 対応する ] が見つかりません。" if t == nil
                        break if t == Token::CLOSEBRACE
                        ary.push t
                    end
                    output.push OperatorNode.new(ast, token, ValueNode.new(ary))
                elsif t == Token::OPENPAREN
                    ary = []
                    t = tokens[0]
                    if t.identifier? && t.value == "H"
                        tokens.shift
                        ary.push "OUTH"
                    else
                        ary.push "OUT"
                    end
                    loop do
                        t = tokens.shift
                        raise "ParseError : 対応する ) が見つかりません。" if t == nil
                        break if t == Token::CLOSEPAREN
                        ary.push t
                    end
                    output.push OperatorNode.new(ast, token, ValueNode.new(ary))
                else
                    dev = t
                    if dev == nil || !dev.identifier? || dev.association_instruction?
                        raise "ParseError : OUTの直後にデバイスがありません。"
                    end
#                    tc_set = nil
#                    if dev.timer_or_counter?
#                        tc_set = tokens.shift
#                        if tc_set == nil || !tc_set.identifier?
#                            raise "ParseError : タイマ・カウンタの設定値デバイスがありません。"
#                        end
#                    end
#                    if tc_set == nil
                        output.push OperatorNode.new(ast, token, ValueNode.new(dev))
#                    else
#                        # 応用命令との区別のために、TC設定値付きの場合は配列の先頭に"OUT"を入れる
#                        output.push OperatorNode.new(ast, token, ValueNode.new(["OUT", dev, tc_set]))
#                    end
                end
            elsif token == Token::AND
                while (op_stack.last == Token::AND)
                    output.push op_stack.pop
                end
                op_stack.push token
            elsif token == Token::OR
                while (op_stack.last == Token::AND || op_stack.last == Token::OR)
                    output.push op_stack.pop
                end
                op_stack.push token
            elsif token == Token::SEMICOLON
                # 行の終わり
#                raise "デバッグ：セミコロンが見つかりました"
#                flag_semicolon = true # セミコロンフラグを立てておく
                next if output.length == 0 # 空行は無視
                if output.length == 1
                    # 構文木を完成品置き場へ移動
                    completed.push output.pop
                    return completed if sub # 再帰呼び出しの場合はここで return する
                else
                    raise "ParseError : output length(#{output.length}) != 1" if tokens.length != 0
                end
                if tokens.length == 0
                    break
#                    lexed = @lexer.lex_line
#                    if lexed == nil
#                        raise "LexerError : 構文の最後が;で終わっています。"
#                    end
#                    tokens = lexed
                end
            elsif token.statement?
                completed.push token.value
            else
                raise "TokenError : 不適切なトークンです。"
            end
        end # while

        if output.length == 1
            # 行間ステートメントの場合、完成品置き場にStringをそのまま送る
            completed.push output.pop
        else
                # 演算子スタックの中身をすべて出力キューに追加する。
                while !(op_stack.empty?)
                    output.push op_stack.pop
                end
                # 出力キューの要素から構文木を構築する。
                elems = []
                while !(output.empty?)
                    elems.push output.shift
                end
                completed.push generate_tree(elems)

#            raise "ParseError : output length != 1"
        end

        # 最後のMRDをMPPにする
        tag_list.each do |list|
            list.last.setmpp if list.length != 0
        end

        completed
    end

    def generate_tree(elems)
        stack = []
        elems.each do |e|
            if e.is_a?(TreeNode)
                stack.push e
            elsif e == Token::AND || e == Token::OR
                rhs = stack.pop
                raise "ParseError : generating tree" if rhs == nil
                lhs = stack.pop
                raise "ParseError : generating tree" if lhs == nil
                stack.push OperatorNode.new(lhs, e, rhs)
            elsif e.association_instruction?
                body = stack.pop
                raise "ParseError : generating tree" if body == nil
                stack.push FunctionNode.new(e, body)
            else
                # TODO
                raise "ParseError : generating tree"
            end
        end
        raise "ParseError : stack size != 1" if stack.size != 1
        stack[0]
    end
end
