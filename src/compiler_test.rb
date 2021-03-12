require './Compiler'

src = <<EOF


SM400 *0&X1040&!X1041->T200 K2;
*0&!X1040&X1041->T201 K2

# これはコメントです。
# cmnt 2
SM400 *0&X1042&!X1043->T202 K2;
*0&!X1042&X1043->T203 k2


EOF

full_path = "C:\\Users\\User\\Dropbox\\ruby_proj\\compiler\\input.txt"

compiler = Compiler.new
compiler.from_file(full_path).compile.format.test
p "---"

#compiler.from_string(src).compile.format.save_to_file(full_path)
