#define _GNU_SOURCE
#include <errno.h>
#include <fcntl.h>
#include <poll.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mount.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

static void reap(void)
{
    int status;
    pid_t pid;
    while ((pid = waitpid(-1, &status, WNOHANG)) > 0)
        printf("reaped pid=%ld status=0x%x\n", (long)pid, status);
}
static void show(const char *path)
{
    char buffer[4096];
    int fd = open(path, O_RDONLY);
    ssize_t n;
    if (fd < 0) { perror(path); return; }
    while ((n = read(fd, buffer, sizeof(buffer))) > 0) {
        ssize_t off = 0;
        while (off < n) {
            ssize_t k = write(1, buffer + off, (size_t)(n - off));
            if (k < 0 && errno == EINTR) continue;
            if (k <= 0) { close(fd); return; }
            off += k;
        }
    }
    if (n < 0) perror("read");
    close(fd);
}
static void child_test(int do_exec)
{
    pid_t pid = fork();
    int status;
    if (pid < 0) { perror("fork"); return; }
    if (pid == 0) {
        printf("child before exec pid=%ld ppid=%ld\n", (long)getpid(), (long)getppid());
        fflush(stdout);
        if (do_exec) {
            execl("/init", "/init", "--exec-child", (char *)NULL);
            perror("execl /init"); _exit(127);
        }
        _exit(7);
    }
    while (waitpid(pid, &status, 0) < 0) {
        if (errno == EINTR) continue;
        perror("waitpid"); return;
    }
    if (WIFEXITED(status))
        printf("parent reaped pid=%ld exit=%d\n", (long)pid, WEXITSTATUS(status));
    else printf("parent reaped pid=%ld status=0x%x\n", (long)pid, status);
}
static void command(char *s)
{
    s[strcspn(s, "\r\n")] = 0;
    if (!strcmp(s, "help")) puts("help | pid | uptime | interrupts | mounts | fork | exec-test");
    else if (!strcmp(s, "pid")) printf("pid=%ld ppid=%ld\n", (long)getpid(), (long)getppid());
    else if (!strcmp(s, "uptime")) show("/proc/uptime");
    else if (!strcmp(s, "interrupts")) show("/proc/interrupts");
    else if (!strcmp(s, "mounts")) show("/proc/mounts");
    else if (!strcmp(s, "fork")) child_test(0);
    else if (!strcmp(s, "exec-test")) child_test(1);
    else if (*s) puts("unknown command; type help");
}
static void make_dir(const char *path)
{
    if (mkdir(path, 0755) < 0 && errno != EEXIST) perror(path);
}
static void mount_one(const char *name, const char *path, const char *type)
{
    if (mount(name, path, type, 0, NULL) < 0 && errno != EBUSY) perror(path);
}
int main(int argc, char **argv)
{
    setvbuf(stdout, NULL, _IONBF, 0);
    if (argc == 2 && !strcmp(argv[1], "--exec-child")) {
        printf("exec child same pid=%ld ppid=%ld\n", (long)getpid(), (long)getppid());
        return 0;
    }
    if (argc == 2 && !strcmp(argv[1], "--selftest")) {
        char cmd[] = "pid";
        command(cmd); child_test(0); return 0;
    }
    if (getpid() != 1) {
        fputs("Run as guest PID 1, or pass --selftest for native smoke check.\n", stderr);
        return 2;
    }
    make_dir("/proc"); make_dir("/sys"); make_dir("/dev"); make_dir("/tmp");
    mount_one("proc", "/proc", "proc");
    mount_one("sysfs", "/sys", "sysfs");
    mount_one("devtmpfs", "/dev", "devtmpfs");
    int fd = open("/dev/console", O_RDWR);
    if (fd < 0) perror("/dev/console");
    else {
        for (int i = 0; i < 3; i++) if (dup2(fd, i) < 0) perror("dup2");
        if (fd > 2) close(fd);
    }
    printf("ARM64 book minit pid=%ld ppid=%ld\n", (long)getpid(), (long)getppid());
    puts("Minimal teaching init; type help. This is not a POSIX shell.");
    char line[256];
    size_t used = 0;
    int input_open = 1;
    fputs("minit> ", stdout);
    for (;;) {
        reap();
        struct pollfd p = { .fd = 0, .events = POLLIN };
        int ready = poll(input_open ? &p : NULL, input_open ? 1 : 0, 1000);
        if (ready < 0) { if (errno != EINTR) perror("poll"); continue; }
        if (ready == 0 || !input_open) continue;
        if (p.revents & (POLLERR | POLLNVAL)) { input_open = 0; continue; }
        if (p.revents & (POLLIN | POLLHUP)) {
            char ch;
            ssize_t n = read(0, &ch, 1);
            if (n < 0) { if (errno != EINTR) perror("stdin"); continue; }
            if (n == 0) { input_open = 0; puts("EOF; PID 1 stays alive."); continue; }
            if (ch == '\n' || ch == '\r') {
                line[used] = 0; command(line); used = 0; fputs("minit> ", stdout);
            } else if (used + 1 < sizeof(line)) line[used++] = ch;
        }
    }
}
