#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/riscv.h"

void shmem_test(int disable_unmapping)
{
    char *buffer = malloc(PGSIZE);
    if (buffer == 0) {
        printf("❌ Failed to allocate buffer\n");
        exit(1);
    }

    strcpy(buffer, "Hello daddy 👋");

    int p[2];
    pipe(p);  // p[0] = read end, p[1] = write end

    int pid = fork();
    if (pid < 0) {
        printf("❌ Fork failed\n");
        free(buffer);
        exit(1);
    }

    if (pid == 0) {
        // 👶 ילד
        close(p[1]);  // סגור צד כתיבה
        uint64 mapped_addr;
        read(p[0], &mapped_addr, sizeof(mapped_addr));
        close(p[0]);

        sleep(5);  // תן להורה להשלים מיפוי
        printf("[Child] sbrk before: %d\n", sbrk(0));
        printf("[Child] shared buffer contains: %s\n", (char *)mapped_addr);

        if (!disable_unmapping) {
            if (unmap_shared_pages((void *)mapped_addr, PGSIZE) < 0)
                printf("[Child] ❌ unmap failed\n");
            else
                printf("[Child] ✅ unmapped successfully\n");
            printf("[Child] sbrk after unmap: %d\n", sbrk(0));
        }

        char *new_buf = malloc(PGSIZE);
        if (new_buf == 0) {
            printf("[Child] ❌ malloc after unmap failed\n");
            exit(1);
        }

        strcpy(new_buf, "malloc after unmap works!");
        printf("[Child] new malloc: %s\n", new_buf);
        printf("[Child] sbrk after malloc: %d\n", sbrk(0));
        free(new_buf);
        exit(0);
    } else {
        // 👨 אבא
        close(p[0]);  // סגור צד קריאה

        uint64 mapped = map_shared_pages(getpid(), pid, buffer, PGSIZE);
        if (mapped == (uint64)-1) {
            printf("❌ mapping failed\n");
            free(buffer);
            wait(0);
            return;
        } else {
            write(p[1], &mapped, sizeof(mapped));
            close(p[1]);
            printf("✅ mapping succeeded\n");
        }

        wait(0);
        printf("[Parent] read from buffer: %s\n", buffer);
        free(buffer);
    }
}

int main(int argc, char *argv[])
{
    printf("\n=== Test with unmap ===\n");
    shmem_test(0);

    printf("\n=== Test without unmap ===\n");
    shmem_test(1);

    exit(0);
}
