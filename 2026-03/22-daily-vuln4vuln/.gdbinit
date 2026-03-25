set disassemble-next-line auto
define hook-stop
  x/gx 0x404018
  x/gx 0x404028
  x/gx 0x404030
  x/48bx &name
end

b main
b *main+58
b *main+83
b *main+108
