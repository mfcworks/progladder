$:.unshift File.dirname(__FILE__)

require 'optparse'
require 'Compiler'

# How to use:
#  ruby compile.rb OUTPUT.csv -i INPUT.txt

input_file = ''
output_file = ''

if ARGV.length != 0
    if !ARGV[0].start_with?('-')
        output_file = ARGV[0]
        ARGV.shift
    end
end
args = ARGV.getopts('i:', 'in:')
if args['i'] != nil
    input_file = args['i']
end
if args['in'] != nil
    input_file = args['in']
end

# p input_file
# p output_file

compiler = Compiler.new
if input_file != "" && output_file != ""
    compiler.from_file(input_file).compile.format.save_to_file(output_file)
else
end
