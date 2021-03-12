path = "C:\\Users\\Tomoki\\Desktop\\from_text.txt"

f = File.new(path)
while (line = f.gets) != nil
    puts line
end
p "EOF"
