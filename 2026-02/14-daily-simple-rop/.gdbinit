set debuginfod enabled off
set disassemble-next-line auto

cd handout
file chal

b *main+74
b win
