set debuginfod enabled off
set disassemble-next-line auto

cd handout
file chal

b safe
b *safe+80
b *safe+145

display /wx    $rbp-0x1a4
display /104wx $rbp-0x1a0
display /4gx  $rbp
