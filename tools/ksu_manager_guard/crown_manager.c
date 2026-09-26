#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <sys/syscall.h>

#define KSU_INSTALL_MAGIC1 0xDEADBEEF
#define CHANGE_MANAGER_UID 10006

int main(int argc, char **argv) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <manager_uid>\n", argv[0]);
        return 1;
    }
    int uid = atoi(argv[1]);
    unsigned long reply = 0;
    long ret = syscall(__NR_reboot, KSU_INSTALL_MAGIC1, CHANGE_MANAGER_UID, uid, &reply);
    if (ret == 0 || errno == 22) {
        printf("[+] Manager UID set to %d\n", uid);
        return 0;
    }
    perror("[-] Failed to set manager UID");
    return 1;
}
