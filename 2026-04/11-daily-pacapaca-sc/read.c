#include <fcntl.h>
#include <sys/syscall.h>

#define BUF_SIZE 0x80

int main() {
    char buf[BUF_SIZE];
    char filename[] = "/flag.txt";
    int fd, len;

    asm volatile( // fd = open(filename, O_RDONLY, 0)
        "syscall"
        : "=a"(fd)
        : "a"(SYS_open), "D"(filename), "S"(O_RDONLY), "d"(0)
        : "rcx", "r11", "memory");

    asm volatile( // len = read(fd, buf, BUF_SIZE)
        "syscall"
        : "=a"(len)
        : "a"(SYS_read), "D"(fd), "S"(buf), "d"(BUF_SIZE)
        : "rcx", "r11", "memory");

    asm volatile( // write(1, buf, len)
        "syscall"
        :
        : "a"(SYS_write), "D"(1), "S"(buf), "d"(len)
        : "rcx", "r11", "memory");
}
