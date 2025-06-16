#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

#define PGSIZE 4096

int
main(int argc, char *argv[])
{
  char *shared;
  int child_Pid;
  int disable_Unmap = 0;

  if (argc > 1 && strcmp(argv[1], "keep") == 0)
    disable_Unmap = 1;

  char *buf = malloc(PGSIZE);
  if (buf == 0) {
    printf("Parent: malloc failed\n");
    exit(1);
  }

  void *before_fork_sz = sbrk(0);
  int parent_pid = getpid();

  child_Pid = fork();
  if (child_Pid < 0) {
    printf("fork failed\n");
    exit(1);
  }

  if (child_Pid == 0) {
    // The Children
    void *before_map_sz = sbrk(0);
    printf("Child: sz before map: %p\n" ,before_map_sz);

    uint64 addr = map_shared_pages(parent_pid, getpid(), buf, PGSIZE);
    if (addr == (uint64)-1) {
      printf("Child: map_shared_pages failed\n");
      exit(1);
    }
    shared = (char *)(uint64)addr;

    printf("Child: wrote message to shared memory\n");
    strcpy(shared, "Hello daddy");

    void *after_map_sz = sbrk(0);
    printf("Child: sz after map: %p\n", after_map_sz);

    if (!disable_Unmap) {
      if (unmap_shared_pages(shared, PGSIZE) != 0) {
        printf("Child: unmap_shared_pages failed\n");
      } else {
        printf("Child: unmapped shared memory\n");
      }
    }

    printf("Child: sz after unmap: %p\n", disable_Unmap ? after_map_sz : sbrk(0));

    char *test_malloc = malloc(PGSIZE);
    if (test_malloc)
      strcpy(test_malloc, "Malloc after unmap");

    void *after_malloc_sz = sbrk(0);
    printf("Child: sz after malloc: %p\n", after_malloc_sz);

    exit(0);
  }

  // The Parrent
  wait(0);
  printf("Parent: read from shared buffer: %s\n", buf);

  void *after_wait_sz = sbrk(0);
  printf("Parent: sz before: %p, after: %p\n", before_fork_sz, after_wait_sz);

  exit(0);
}