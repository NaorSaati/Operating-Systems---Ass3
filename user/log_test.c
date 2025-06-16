#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

#define PGSIZE 4096
#define MAX_MSG_length 64
#define NUM_CHILDREN 4
#define MAKE_HEADER(idx, len) (((idx) << 16) | (len))
int INDICATOR=0;

int main(int argc, char *argv[])
{
  char *buf = malloc(PGSIZE);
  if (!buf) {
    printf("Parent: malloc failed\n");
    exit(1);
  }

  // Zero-initialize the shared buffer
  memset(buf, 0, PGSIZE);

  int par_pid = getpid();
  // Fork childrens
  for (int i = 0; i < NUM_CHILDREN; i++) {
    int pid = fork();
    if (pid == 0) {
      // this the children
      uint64 addr = map_shared_pages(par_pid, getpid(), buf, PGSIZE);
      if (addr == 0) {
        printf("Child %d: map_shared_pages failed\n", i);
        exit(1);
      }

      char *shared = (char *)(uint64)addr;
      char *p = shared;
      int num = 1;

    while (1) {
        // Build message
        char msg[MAX_MSG_length];
        strcpy(msg, "Hi from child ");
        int length = strlen(msg);
        msg[length] = '0' + i;
        
        const char *suffix = " message number: ";
        int suffix_length = strlen(suffix);
        if (length + suffix_length >= MAX_MSG_length)
            break;
        strcpy(msg + length, suffix);
        length += suffix_length;

        // change num to str and concat
        if (length + 5 >= MAX_MSG_length)
            break;
        int start = length;
        int n = num;
        int digits = 0;
        char tmp[12];

        do {
            tmp[digits++] = '0' + (n % 10);
            n /= 10;
        } while (n > 0);

        for (int j = 0; j < digits; j++)
            msg[start + j] = tmp[digits - j - 1];

        length = start + digits;
        msg[length] = '\0';
        length++;
        if (p + 4 + length > shared + PGSIZE)
        {
            int available = shared + PGSIZE - p;
            if (available < 4)
            break;

            int write_length = length;
            if (available < 4 + length)
            write_length = available - 4; 

            if (write_length <= 0)
            break;

            // tring claim header slot
            int claimed = __sync_val_compare_and_swap((int *)p, 0, MAKE_HEADER(i, write_length));
            if (claimed == 0)
                memmove(p + 4, msg, write_length);
            break;
        }
            

        int claimed = __sync_val_compare_and_swap((int *)p, 0, MAKE_HEADER(i, length));
        if (claimed == 0) {
            memmove(p + 4, msg, length);
            num++; 
            p += 4 + length;
            sleep(1); 
        } else {
            int prev_length = claimed & 0xFFFF;
            p += 4 + prev_length;
        }

        p = (char *)(((uint64)p + 3) & ~3);  // Align to 4-byte boundary
        }

      exit(0);
    }
  }

  // this is the parent
  sleep(20);
  printf("Parent: reading messages from shared buffer\n");
  
  char *p = buf;
  while (p + 4 <= buf + PGSIZE) {
    int header = *(int *)p;
    if (header == 0)
      break;

    int child_idx = (header >> 16) & 0xFFFF;
    int length = header & 0xFFFF;

    char msg[MAX_MSG_length];
    memmove(msg, p + 4, length);
    msg[length] = '\0';

    printf("From child %d: %s\n", child_idx, msg);

    p += 4 + length;
    p = (char *)(((uint64)p + 3) & ~3);
  }

  exit(0);
}