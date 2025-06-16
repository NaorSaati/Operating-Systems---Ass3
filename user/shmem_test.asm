
user/_shmem_test:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:

#define PGSIZE 4096

int
main(int argc, char *argv[])
{
   0:	7179                	addi	sp,sp,-48
   2:	f406                	sd	ra,40(sp)
   4:	f022                	sd	s0,32(sp)
   6:	ec26                	sd	s1,24(sp)
   8:	e84a                	sd	s2,16(sp)
   a:	e44e                	sd	s3,8(sp)
   c:	e052                	sd	s4,0(sp)
   e:	1800                	addi	s0,sp,48
  char *shared;
  int child_Pid;
  int disable_Unmap = 0;

  if (argc > 1 && strcmp(argv[1], "keep") == 0)
  10:	4705                	li	a4,1
  int disable_Unmap = 0;
  12:	4901                	li	s2,0
  if (argc > 1 && strcmp(argv[1], "keep") == 0)
  14:	10a74763          	blt	a4,a0,122 <main+0x122>
    disable_Unmap = 1;

  char *buf = malloc(PGSIZE);
  18:	6505                	lui	a0,0x1
  1a:	00001097          	auipc	ra,0x1
  1e:	8c0080e7          	jalr	-1856(ra) # 8da <malloc>
  22:	84aa                	mv	s1,a0
  if (buf == 0) {
  24:	10050c63          	beqz	a0,13c <main+0x13c>
    printf("Parent: malloc failed\n");
    exit(1);
  }

  void *before_fork_sz = sbrk(0);
  28:	4501                	li	a0,0
  2a:	00000097          	auipc	ra,0x0
  2e:	4f2080e7          	jalr	1266(ra) # 51c <sbrk>
  32:	89aa                	mv	s3,a0
  int parent_pid = getpid();
  34:	00000097          	auipc	ra,0x0
  38:	4e0080e7          	jalr	1248(ra) # 514 <getpid>
  3c:	8a2a                	mv	s4,a0

  child_Pid = fork();
  3e:	00000097          	auipc	ra,0x0
  42:	44e080e7          	jalr	1102(ra) # 48c <fork>
  if (child_Pid < 0) {
  46:	10054863          	bltz	a0,156 <main+0x156>
    printf("fork failed\n");
    exit(1);
  }

  if (child_Pid == 0) {
  4a:	16051f63          	bnez	a0,1c8 <main+0x1c8>
    // The Children
    void *before_map_sz = sbrk(0);
  4e:	4501                	li	a0,0
  50:	00000097          	auipc	ra,0x0
  54:	4cc080e7          	jalr	1228(ra) # 51c <sbrk>
  58:	85aa                	mv	a1,a0
    printf("Child: sz before map: %p\n" ,before_map_sz);
  5a:	00001517          	auipc	a0,0x1
  5e:	99650513          	addi	a0,a0,-1642 # 9f0 <malloc+0x116>
  62:	00000097          	auipc	ra,0x0
  66:	7ba080e7          	jalr	1978(ra) # 81c <printf>

    uint64 addr = map_shared_pages(parent_pid, getpid(), buf, PGSIZE);
  6a:	00000097          	auipc	ra,0x0
  6e:	4aa080e7          	jalr	1194(ra) # 514 <getpid>
  72:	85aa                	mv	a1,a0
  74:	6685                	lui	a3,0x1
  76:	8626                	mv	a2,s1
  78:	8552                	mv	a0,s4
  7a:	00000097          	auipc	ra,0x0
  7e:	4ba080e7          	jalr	1210(ra) # 534 <map_shared_pages>
  82:	84aa                	mv	s1,a0
    if (addr == (uint64)-1) {
  84:	57fd                	li	a5,-1
  86:	0ef50563          	beq	a0,a5,170 <main+0x170>
      printf("Child: map_shared_pages failed\n");
      exit(1);
    }
    shared = (char *)(uint64)addr;

    printf("Child: wrote message to shared memory\n");
  8a:	00001517          	auipc	a0,0x1
  8e:	9a650513          	addi	a0,a0,-1626 # a30 <malloc+0x156>
  92:	00000097          	auipc	ra,0x0
  96:	78a080e7          	jalr	1930(ra) # 81c <printf>
    strcpy(shared, "Hello daddy");
  9a:	00001597          	auipc	a1,0x1
  9e:	9be58593          	addi	a1,a1,-1602 # a58 <malloc+0x17e>
  a2:	8526                	mv	a0,s1
  a4:	00000097          	auipc	ra,0x0
  a8:	182080e7          	jalr	386(ra) # 226 <strcpy>

    void *after_map_sz = sbrk(0);
  ac:	4501                	li	a0,0
  ae:	00000097          	auipc	ra,0x0
  b2:	46e080e7          	jalr	1134(ra) # 51c <sbrk>
  b6:	89aa                	mv	s3,a0
    printf("Child: sz after map: %p\n", after_map_sz);
  b8:	85aa                	mv	a1,a0
  ba:	00001517          	auipc	a0,0x1
  be:	9ae50513          	addi	a0,a0,-1618 # a68 <malloc+0x18e>
  c2:	00000097          	auipc	ra,0x0
  c6:	75a080e7          	jalr	1882(ra) # 81c <printf>

    if (!disable_Unmap) {
  ca:	0c090063          	beqz	s2,18a <main+0x18a>
      } else {
        printf("Child: unmapped shared memory\n");
      }
    }

    printf("Child: sz after unmap: %p\n", disable_Unmap ? after_map_sz : sbrk(0));
  ce:	85ce                	mv	a1,s3
  d0:	00001517          	auipc	a0,0x1
  d4:	a0050513          	addi	a0,a0,-1536 # ad0 <malloc+0x1f6>
  d8:	00000097          	auipc	ra,0x0
  dc:	744080e7          	jalr	1860(ra) # 81c <printf>

    char *test_malloc = malloc(PGSIZE);
  e0:	6505                	lui	a0,0x1
  e2:	00000097          	auipc	ra,0x0
  e6:	7f8080e7          	jalr	2040(ra) # 8da <malloc>
    if (test_malloc)
  ea:	c909                	beqz	a0,fc <main+0xfc>
      strcpy(test_malloc, "Malloc after unmap");
  ec:	00001597          	auipc	a1,0x1
  f0:	a0458593          	addi	a1,a1,-1532 # af0 <malloc+0x216>
  f4:	00000097          	auipc	ra,0x0
  f8:	132080e7          	jalr	306(ra) # 226 <strcpy>

    void *after_malloc_sz = sbrk(0);
  fc:	4501                	li	a0,0
  fe:	00000097          	auipc	ra,0x0
 102:	41e080e7          	jalr	1054(ra) # 51c <sbrk>
 106:	85aa                	mv	a1,a0
    printf("Child: sz after malloc: %p\n", after_malloc_sz);
 108:	00001517          	auipc	a0,0x1
 10c:	a0050513          	addi	a0,a0,-1536 # b08 <malloc+0x22e>
 110:	00000097          	auipc	ra,0x0
 114:	70c080e7          	jalr	1804(ra) # 81c <printf>

    exit(0);
 118:	4501                	li	a0,0
 11a:	00000097          	auipc	ra,0x0
 11e:	37a080e7          	jalr	890(ra) # 494 <exit>
 122:	87ae                	mv	a5,a1
  if (argc > 1 && strcmp(argv[1], "keep") == 0)
 124:	00001597          	auipc	a1,0x1
 128:	89c58593          	addi	a1,a1,-1892 # 9c0 <malloc+0xe6>
 12c:	6788                	ld	a0,8(a5)
 12e:	00000097          	auipc	ra,0x0
 132:	114080e7          	jalr	276(ra) # 242 <strcmp>
  int disable_Unmap = 0;
 136:	00153913          	seqz	s2,a0
 13a:	bdf9                	j	18 <main+0x18>
    printf("Parent: malloc failed\n");
 13c:	00001517          	auipc	a0,0x1
 140:	88c50513          	addi	a0,a0,-1908 # 9c8 <malloc+0xee>
 144:	00000097          	auipc	ra,0x0
 148:	6d8080e7          	jalr	1752(ra) # 81c <printf>
    exit(1);
 14c:	4505                	li	a0,1
 14e:	00000097          	auipc	ra,0x0
 152:	346080e7          	jalr	838(ra) # 494 <exit>
    printf("fork failed\n");
 156:	00001517          	auipc	a0,0x1
 15a:	88a50513          	addi	a0,a0,-1910 # 9e0 <malloc+0x106>
 15e:	00000097          	auipc	ra,0x0
 162:	6be080e7          	jalr	1726(ra) # 81c <printf>
    exit(1);
 166:	4505                	li	a0,1
 168:	00000097          	auipc	ra,0x0
 16c:	32c080e7          	jalr	812(ra) # 494 <exit>
      printf("Child: map_shared_pages failed\n");
 170:	00001517          	auipc	a0,0x1
 174:	8a050513          	addi	a0,a0,-1888 # a10 <malloc+0x136>
 178:	00000097          	auipc	ra,0x0
 17c:	6a4080e7          	jalr	1700(ra) # 81c <printf>
      exit(1);
 180:	4505                	li	a0,1
 182:	00000097          	auipc	ra,0x0
 186:	312080e7          	jalr	786(ra) # 494 <exit>
      if (unmap_shared_pages(shared, PGSIZE) != 0) {
 18a:	6585                	lui	a1,0x1
 18c:	8526                	mv	a0,s1
 18e:	00000097          	auipc	ra,0x0
 192:	3ae080e7          	jalr	942(ra) # 53c <unmap_shared_pages>
 196:	c105                	beqz	a0,1b6 <main+0x1b6>
        printf("Child: unmap_shared_pages failed\n");
 198:	00001517          	auipc	a0,0x1
 19c:	8f050513          	addi	a0,a0,-1808 # a88 <malloc+0x1ae>
 1a0:	00000097          	auipc	ra,0x0
 1a4:	67c080e7          	jalr	1660(ra) # 81c <printf>
    printf("Child: sz after unmap: %p\n", disable_Unmap ? after_map_sz : sbrk(0));
 1a8:	4501                	li	a0,0
 1aa:	00000097          	auipc	ra,0x0
 1ae:	372080e7          	jalr	882(ra) # 51c <sbrk>
 1b2:	89aa                	mv	s3,a0
 1b4:	bf29                	j	ce <main+0xce>
        printf("Child: unmapped shared memory\n");
 1b6:	00001517          	auipc	a0,0x1
 1ba:	8fa50513          	addi	a0,a0,-1798 # ab0 <malloc+0x1d6>
 1be:	00000097          	auipc	ra,0x0
 1c2:	65e080e7          	jalr	1630(ra) # 81c <printf>
 1c6:	b7cd                	j	1a8 <main+0x1a8>
  }

  // The Parrent
  wait(0);
 1c8:	4501                	li	a0,0
 1ca:	00000097          	auipc	ra,0x0
 1ce:	2d2080e7          	jalr	722(ra) # 49c <wait>
  printf("Parent: read from shared buffer: %s\n", buf);
 1d2:	85a6                	mv	a1,s1
 1d4:	00001517          	auipc	a0,0x1
 1d8:	95450513          	addi	a0,a0,-1708 # b28 <malloc+0x24e>
 1dc:	00000097          	auipc	ra,0x0
 1e0:	640080e7          	jalr	1600(ra) # 81c <printf>

  void *after_wait_sz = sbrk(0);
 1e4:	4501                	li	a0,0
 1e6:	00000097          	auipc	ra,0x0
 1ea:	336080e7          	jalr	822(ra) # 51c <sbrk>
 1ee:	862a                	mv	a2,a0
  printf("Parent: sz before: %p, after: %p\n", before_fork_sz, after_wait_sz);
 1f0:	85ce                	mv	a1,s3
 1f2:	00001517          	auipc	a0,0x1
 1f6:	95e50513          	addi	a0,a0,-1698 # b50 <malloc+0x276>
 1fa:	00000097          	auipc	ra,0x0
 1fe:	622080e7          	jalr	1570(ra) # 81c <printf>

  exit(0);
 202:	4501                	li	a0,0
 204:	00000097          	auipc	ra,0x0
 208:	290080e7          	jalr	656(ra) # 494 <exit>

000000000000020c <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
 20c:	1141                	addi	sp,sp,-16
 20e:	e406                	sd	ra,8(sp)
 210:	e022                	sd	s0,0(sp)
 212:	0800                	addi	s0,sp,16
  extern int main();
  main();
 214:	00000097          	auipc	ra,0x0
 218:	dec080e7          	jalr	-532(ra) # 0 <main>
  exit(0);
 21c:	4501                	li	a0,0
 21e:	00000097          	auipc	ra,0x0
 222:	276080e7          	jalr	630(ra) # 494 <exit>

0000000000000226 <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
 226:	1141                	addi	sp,sp,-16
 228:	e422                	sd	s0,8(sp)
 22a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 22c:	87aa                	mv	a5,a0
 22e:	0585                	addi	a1,a1,1
 230:	0785                	addi	a5,a5,1
 232:	fff5c703          	lbu	a4,-1(a1) # fff <digits+0x47f>
 236:	fee78fa3          	sb	a4,-1(a5)
 23a:	fb75                	bnez	a4,22e <strcpy+0x8>
    ;
  return os;
}
 23c:	6422                	ld	s0,8(sp)
 23e:	0141                	addi	sp,sp,16
 240:	8082                	ret

0000000000000242 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 242:	1141                	addi	sp,sp,-16
 244:	e422                	sd	s0,8(sp)
 246:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 248:	00054783          	lbu	a5,0(a0)
 24c:	cb91                	beqz	a5,260 <strcmp+0x1e>
 24e:	0005c703          	lbu	a4,0(a1)
 252:	00f71763          	bne	a4,a5,260 <strcmp+0x1e>
    p++, q++;
 256:	0505                	addi	a0,a0,1
 258:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 25a:	00054783          	lbu	a5,0(a0)
 25e:	fbe5                	bnez	a5,24e <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 260:	0005c503          	lbu	a0,0(a1)
}
 264:	40a7853b          	subw	a0,a5,a0
 268:	6422                	ld	s0,8(sp)
 26a:	0141                	addi	sp,sp,16
 26c:	8082                	ret

000000000000026e <strlen>:

uint
strlen(const char *s)
{
 26e:	1141                	addi	sp,sp,-16
 270:	e422                	sd	s0,8(sp)
 272:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 274:	00054783          	lbu	a5,0(a0)
 278:	cf91                	beqz	a5,294 <strlen+0x26>
 27a:	0505                	addi	a0,a0,1
 27c:	87aa                	mv	a5,a0
 27e:	4685                	li	a3,1
 280:	9e89                	subw	a3,a3,a0
 282:	00f6853b          	addw	a0,a3,a5
 286:	0785                	addi	a5,a5,1
 288:	fff7c703          	lbu	a4,-1(a5)
 28c:	fb7d                	bnez	a4,282 <strlen+0x14>
    ;
  return n;
}
 28e:	6422                	ld	s0,8(sp)
 290:	0141                	addi	sp,sp,16
 292:	8082                	ret
  for(n = 0; s[n]; n++)
 294:	4501                	li	a0,0
 296:	bfe5                	j	28e <strlen+0x20>

0000000000000298 <memset>:

void*
memset(void *dst, int c, uint n)
{
 298:	1141                	addi	sp,sp,-16
 29a:	e422                	sd	s0,8(sp)
 29c:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 29e:	ca19                	beqz	a2,2b4 <memset+0x1c>
 2a0:	87aa                	mv	a5,a0
 2a2:	1602                	slli	a2,a2,0x20
 2a4:	9201                	srli	a2,a2,0x20
 2a6:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 2aa:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 2ae:	0785                	addi	a5,a5,1
 2b0:	fee79de3          	bne	a5,a4,2aa <memset+0x12>
  }
  return dst;
}
 2b4:	6422                	ld	s0,8(sp)
 2b6:	0141                	addi	sp,sp,16
 2b8:	8082                	ret

00000000000002ba <strchr>:

char*
strchr(const char *s, char c)
{
 2ba:	1141                	addi	sp,sp,-16
 2bc:	e422                	sd	s0,8(sp)
 2be:	0800                	addi	s0,sp,16
  for(; *s; s++)
 2c0:	00054783          	lbu	a5,0(a0)
 2c4:	cb99                	beqz	a5,2da <strchr+0x20>
    if(*s == c)
 2c6:	00f58763          	beq	a1,a5,2d4 <strchr+0x1a>
  for(; *s; s++)
 2ca:	0505                	addi	a0,a0,1
 2cc:	00054783          	lbu	a5,0(a0)
 2d0:	fbfd                	bnez	a5,2c6 <strchr+0xc>
      return (char*)s;
  return 0;
 2d2:	4501                	li	a0,0
}
 2d4:	6422                	ld	s0,8(sp)
 2d6:	0141                	addi	sp,sp,16
 2d8:	8082                	ret
  return 0;
 2da:	4501                	li	a0,0
 2dc:	bfe5                	j	2d4 <strchr+0x1a>

00000000000002de <gets>:

char*
gets(char *buf, int max)
{
 2de:	711d                	addi	sp,sp,-96
 2e0:	ec86                	sd	ra,88(sp)
 2e2:	e8a2                	sd	s0,80(sp)
 2e4:	e4a6                	sd	s1,72(sp)
 2e6:	e0ca                	sd	s2,64(sp)
 2e8:	fc4e                	sd	s3,56(sp)
 2ea:	f852                	sd	s4,48(sp)
 2ec:	f456                	sd	s5,40(sp)
 2ee:	f05a                	sd	s6,32(sp)
 2f0:	ec5e                	sd	s7,24(sp)
 2f2:	1080                	addi	s0,sp,96
 2f4:	8baa                	mv	s7,a0
 2f6:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 2f8:	892a                	mv	s2,a0
 2fa:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 2fc:	4aa9                	li	s5,10
 2fe:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 300:	89a6                	mv	s3,s1
 302:	2485                	addiw	s1,s1,1
 304:	0344d863          	bge	s1,s4,334 <gets+0x56>
    cc = read(0, &c, 1);
 308:	4605                	li	a2,1
 30a:	faf40593          	addi	a1,s0,-81
 30e:	4501                	li	a0,0
 310:	00000097          	auipc	ra,0x0
 314:	19c080e7          	jalr	412(ra) # 4ac <read>
    if(cc < 1)
 318:	00a05e63          	blez	a0,334 <gets+0x56>
    buf[i++] = c;
 31c:	faf44783          	lbu	a5,-81(s0)
 320:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 324:	01578763          	beq	a5,s5,332 <gets+0x54>
 328:	0905                	addi	s2,s2,1
 32a:	fd679be3          	bne	a5,s6,300 <gets+0x22>
  for(i=0; i+1 < max; ){
 32e:	89a6                	mv	s3,s1
 330:	a011                	j	334 <gets+0x56>
 332:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 334:	99de                	add	s3,s3,s7
 336:	00098023          	sb	zero,0(s3)
  return buf;
}
 33a:	855e                	mv	a0,s7
 33c:	60e6                	ld	ra,88(sp)
 33e:	6446                	ld	s0,80(sp)
 340:	64a6                	ld	s1,72(sp)
 342:	6906                	ld	s2,64(sp)
 344:	79e2                	ld	s3,56(sp)
 346:	7a42                	ld	s4,48(sp)
 348:	7aa2                	ld	s5,40(sp)
 34a:	7b02                	ld	s6,32(sp)
 34c:	6be2                	ld	s7,24(sp)
 34e:	6125                	addi	sp,sp,96
 350:	8082                	ret

0000000000000352 <stat>:

int
stat(const char *n, struct stat *st)
{
 352:	1101                	addi	sp,sp,-32
 354:	ec06                	sd	ra,24(sp)
 356:	e822                	sd	s0,16(sp)
 358:	e426                	sd	s1,8(sp)
 35a:	e04a                	sd	s2,0(sp)
 35c:	1000                	addi	s0,sp,32
 35e:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 360:	4581                	li	a1,0
 362:	00000097          	auipc	ra,0x0
 366:	172080e7          	jalr	370(ra) # 4d4 <open>
  if(fd < 0)
 36a:	02054563          	bltz	a0,394 <stat+0x42>
 36e:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 370:	85ca                	mv	a1,s2
 372:	00000097          	auipc	ra,0x0
 376:	17a080e7          	jalr	378(ra) # 4ec <fstat>
 37a:	892a                	mv	s2,a0
  close(fd);
 37c:	8526                	mv	a0,s1
 37e:	00000097          	auipc	ra,0x0
 382:	13e080e7          	jalr	318(ra) # 4bc <close>
  return r;
}
 386:	854a                	mv	a0,s2
 388:	60e2                	ld	ra,24(sp)
 38a:	6442                	ld	s0,16(sp)
 38c:	64a2                	ld	s1,8(sp)
 38e:	6902                	ld	s2,0(sp)
 390:	6105                	addi	sp,sp,32
 392:	8082                	ret
    return -1;
 394:	597d                	li	s2,-1
 396:	bfc5                	j	386 <stat+0x34>

0000000000000398 <atoi>:

int
atoi(const char *s)
{
 398:	1141                	addi	sp,sp,-16
 39a:	e422                	sd	s0,8(sp)
 39c:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 39e:	00054603          	lbu	a2,0(a0)
 3a2:	fd06079b          	addiw	a5,a2,-48
 3a6:	0ff7f793          	andi	a5,a5,255
 3aa:	4725                	li	a4,9
 3ac:	02f76963          	bltu	a4,a5,3de <atoi+0x46>
 3b0:	86aa                	mv	a3,a0
  n = 0;
 3b2:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 3b4:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 3b6:	0685                	addi	a3,a3,1
 3b8:	0025179b          	slliw	a5,a0,0x2
 3bc:	9fa9                	addw	a5,a5,a0
 3be:	0017979b          	slliw	a5,a5,0x1
 3c2:	9fb1                	addw	a5,a5,a2
 3c4:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 3c8:	0006c603          	lbu	a2,0(a3) # 1000 <freep>
 3cc:	fd06071b          	addiw	a4,a2,-48
 3d0:	0ff77713          	andi	a4,a4,255
 3d4:	fee5f1e3          	bgeu	a1,a4,3b6 <atoi+0x1e>
  return n;
}
 3d8:	6422                	ld	s0,8(sp)
 3da:	0141                	addi	sp,sp,16
 3dc:	8082                	ret
  n = 0;
 3de:	4501                	li	a0,0
 3e0:	bfe5                	j	3d8 <atoi+0x40>

00000000000003e2 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 3e2:	1141                	addi	sp,sp,-16
 3e4:	e422                	sd	s0,8(sp)
 3e6:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 3e8:	02b57463          	bgeu	a0,a1,410 <memmove+0x2e>
    while(n-- > 0)
 3ec:	00c05f63          	blez	a2,40a <memmove+0x28>
 3f0:	1602                	slli	a2,a2,0x20
 3f2:	9201                	srli	a2,a2,0x20
 3f4:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 3f8:	872a                	mv	a4,a0
      *dst++ = *src++;
 3fa:	0585                	addi	a1,a1,1
 3fc:	0705                	addi	a4,a4,1
 3fe:	fff5c683          	lbu	a3,-1(a1)
 402:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 406:	fee79ae3          	bne	a5,a4,3fa <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 40a:	6422                	ld	s0,8(sp)
 40c:	0141                	addi	sp,sp,16
 40e:	8082                	ret
    dst += n;
 410:	00c50733          	add	a4,a0,a2
    src += n;
 414:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 416:	fec05ae3          	blez	a2,40a <memmove+0x28>
 41a:	fff6079b          	addiw	a5,a2,-1
 41e:	1782                	slli	a5,a5,0x20
 420:	9381                	srli	a5,a5,0x20
 422:	fff7c793          	not	a5,a5
 426:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 428:	15fd                	addi	a1,a1,-1
 42a:	177d                	addi	a4,a4,-1
 42c:	0005c683          	lbu	a3,0(a1)
 430:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 434:	fee79ae3          	bne	a5,a4,428 <memmove+0x46>
 438:	bfc9                	j	40a <memmove+0x28>

000000000000043a <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 43a:	1141                	addi	sp,sp,-16
 43c:	e422                	sd	s0,8(sp)
 43e:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 440:	ca05                	beqz	a2,470 <memcmp+0x36>
 442:	fff6069b          	addiw	a3,a2,-1
 446:	1682                	slli	a3,a3,0x20
 448:	9281                	srli	a3,a3,0x20
 44a:	0685                	addi	a3,a3,1
 44c:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 44e:	00054783          	lbu	a5,0(a0)
 452:	0005c703          	lbu	a4,0(a1)
 456:	00e79863          	bne	a5,a4,466 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 45a:	0505                	addi	a0,a0,1
    p2++;
 45c:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 45e:	fed518e3          	bne	a0,a3,44e <memcmp+0x14>
  }
  return 0;
 462:	4501                	li	a0,0
 464:	a019                	j	46a <memcmp+0x30>
      return *p1 - *p2;
 466:	40e7853b          	subw	a0,a5,a4
}
 46a:	6422                	ld	s0,8(sp)
 46c:	0141                	addi	sp,sp,16
 46e:	8082                	ret
  return 0;
 470:	4501                	li	a0,0
 472:	bfe5                	j	46a <memcmp+0x30>

0000000000000474 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 474:	1141                	addi	sp,sp,-16
 476:	e406                	sd	ra,8(sp)
 478:	e022                	sd	s0,0(sp)
 47a:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 47c:	00000097          	auipc	ra,0x0
 480:	f66080e7          	jalr	-154(ra) # 3e2 <memmove>
}
 484:	60a2                	ld	ra,8(sp)
 486:	6402                	ld	s0,0(sp)
 488:	0141                	addi	sp,sp,16
 48a:	8082                	ret

000000000000048c <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 48c:	4885                	li	a7,1
 ecall
 48e:	00000073          	ecall
 ret
 492:	8082                	ret

0000000000000494 <exit>:
.global exit
exit:
 li a7, SYS_exit
 494:	4889                	li	a7,2
 ecall
 496:	00000073          	ecall
 ret
 49a:	8082                	ret

000000000000049c <wait>:
.global wait
wait:
 li a7, SYS_wait
 49c:	488d                	li	a7,3
 ecall
 49e:	00000073          	ecall
 ret
 4a2:	8082                	ret

00000000000004a4 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 4a4:	4891                	li	a7,4
 ecall
 4a6:	00000073          	ecall
 ret
 4aa:	8082                	ret

00000000000004ac <read>:
.global read
read:
 li a7, SYS_read
 4ac:	4895                	li	a7,5
 ecall
 4ae:	00000073          	ecall
 ret
 4b2:	8082                	ret

00000000000004b4 <write>:
.global write
write:
 li a7, SYS_write
 4b4:	48c1                	li	a7,16
 ecall
 4b6:	00000073          	ecall
 ret
 4ba:	8082                	ret

00000000000004bc <close>:
.global close
close:
 li a7, SYS_close
 4bc:	48d5                	li	a7,21
 ecall
 4be:	00000073          	ecall
 ret
 4c2:	8082                	ret

00000000000004c4 <kill>:
.global kill
kill:
 li a7, SYS_kill
 4c4:	4899                	li	a7,6
 ecall
 4c6:	00000073          	ecall
 ret
 4ca:	8082                	ret

00000000000004cc <exec>:
.global exec
exec:
 li a7, SYS_exec
 4cc:	489d                	li	a7,7
 ecall
 4ce:	00000073          	ecall
 ret
 4d2:	8082                	ret

00000000000004d4 <open>:
.global open
open:
 li a7, SYS_open
 4d4:	48bd                	li	a7,15
 ecall
 4d6:	00000073          	ecall
 ret
 4da:	8082                	ret

00000000000004dc <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 4dc:	48c5                	li	a7,17
 ecall
 4de:	00000073          	ecall
 ret
 4e2:	8082                	ret

00000000000004e4 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 4e4:	48c9                	li	a7,18
 ecall
 4e6:	00000073          	ecall
 ret
 4ea:	8082                	ret

00000000000004ec <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 4ec:	48a1                	li	a7,8
 ecall
 4ee:	00000073          	ecall
 ret
 4f2:	8082                	ret

00000000000004f4 <link>:
.global link
link:
 li a7, SYS_link
 4f4:	48cd                	li	a7,19
 ecall
 4f6:	00000073          	ecall
 ret
 4fa:	8082                	ret

00000000000004fc <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 4fc:	48d1                	li	a7,20
 ecall
 4fe:	00000073          	ecall
 ret
 502:	8082                	ret

0000000000000504 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 504:	48a5                	li	a7,9
 ecall
 506:	00000073          	ecall
 ret
 50a:	8082                	ret

000000000000050c <dup>:
.global dup
dup:
 li a7, SYS_dup
 50c:	48a9                	li	a7,10
 ecall
 50e:	00000073          	ecall
 ret
 512:	8082                	ret

0000000000000514 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 514:	48ad                	li	a7,11
 ecall
 516:	00000073          	ecall
 ret
 51a:	8082                	ret

000000000000051c <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 51c:	48b1                	li	a7,12
 ecall
 51e:	00000073          	ecall
 ret
 522:	8082                	ret

0000000000000524 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 524:	48b5                	li	a7,13
 ecall
 526:	00000073          	ecall
 ret
 52a:	8082                	ret

000000000000052c <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 52c:	48b9                	li	a7,14
 ecall
 52e:	00000073          	ecall
 ret
 532:	8082                	ret

0000000000000534 <map_shared_pages>:
.global map_shared_pages
map_shared_pages:
 li a7, SYS_map_shared_pages
 534:	48d9                	li	a7,22
 ecall
 536:	00000073          	ecall
 ret
 53a:	8082                	ret

000000000000053c <unmap_shared_pages>:
.global unmap_shared_pages
unmap_shared_pages:
 li a7, SYS_unmap_shared_pages
 53c:	48dd                	li	a7,23
 ecall
 53e:	00000073          	ecall
 ret
 542:	8082                	ret

0000000000000544 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 544:	1101                	addi	sp,sp,-32
 546:	ec06                	sd	ra,24(sp)
 548:	e822                	sd	s0,16(sp)
 54a:	1000                	addi	s0,sp,32
 54c:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 550:	4605                	li	a2,1
 552:	fef40593          	addi	a1,s0,-17
 556:	00000097          	auipc	ra,0x0
 55a:	f5e080e7          	jalr	-162(ra) # 4b4 <write>
}
 55e:	60e2                	ld	ra,24(sp)
 560:	6442                	ld	s0,16(sp)
 562:	6105                	addi	sp,sp,32
 564:	8082                	ret

0000000000000566 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 566:	7139                	addi	sp,sp,-64
 568:	fc06                	sd	ra,56(sp)
 56a:	f822                	sd	s0,48(sp)
 56c:	f426                	sd	s1,40(sp)
 56e:	f04a                	sd	s2,32(sp)
 570:	ec4e                	sd	s3,24(sp)
 572:	0080                	addi	s0,sp,64
 574:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 576:	c299                	beqz	a3,57c <printint+0x16>
 578:	0805c863          	bltz	a1,608 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 57c:	2581                	sext.w	a1,a1
  neg = 0;
 57e:	4881                	li	a7,0
 580:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 584:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 586:	2601                	sext.w	a2,a2
 588:	00000517          	auipc	a0,0x0
 58c:	5f850513          	addi	a0,a0,1528 # b80 <digits>
 590:	883a                	mv	a6,a4
 592:	2705                	addiw	a4,a4,1
 594:	02c5f7bb          	remuw	a5,a1,a2
 598:	1782                	slli	a5,a5,0x20
 59a:	9381                	srli	a5,a5,0x20
 59c:	97aa                	add	a5,a5,a0
 59e:	0007c783          	lbu	a5,0(a5)
 5a2:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 5a6:	0005879b          	sext.w	a5,a1
 5aa:	02c5d5bb          	divuw	a1,a1,a2
 5ae:	0685                	addi	a3,a3,1
 5b0:	fec7f0e3          	bgeu	a5,a2,590 <printint+0x2a>
  if(neg)
 5b4:	00088b63          	beqz	a7,5ca <printint+0x64>
    buf[i++] = '-';
 5b8:	fd040793          	addi	a5,s0,-48
 5bc:	973e                	add	a4,a4,a5
 5be:	02d00793          	li	a5,45
 5c2:	fef70823          	sb	a5,-16(a4)
 5c6:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 5ca:	02e05863          	blez	a4,5fa <printint+0x94>
 5ce:	fc040793          	addi	a5,s0,-64
 5d2:	00e78933          	add	s2,a5,a4
 5d6:	fff78993          	addi	s3,a5,-1
 5da:	99ba                	add	s3,s3,a4
 5dc:	377d                	addiw	a4,a4,-1
 5de:	1702                	slli	a4,a4,0x20
 5e0:	9301                	srli	a4,a4,0x20
 5e2:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 5e6:	fff94583          	lbu	a1,-1(s2)
 5ea:	8526                	mv	a0,s1
 5ec:	00000097          	auipc	ra,0x0
 5f0:	f58080e7          	jalr	-168(ra) # 544 <putc>
  while(--i >= 0)
 5f4:	197d                	addi	s2,s2,-1
 5f6:	ff3918e3          	bne	s2,s3,5e6 <printint+0x80>
}
 5fa:	70e2                	ld	ra,56(sp)
 5fc:	7442                	ld	s0,48(sp)
 5fe:	74a2                	ld	s1,40(sp)
 600:	7902                	ld	s2,32(sp)
 602:	69e2                	ld	s3,24(sp)
 604:	6121                	addi	sp,sp,64
 606:	8082                	ret
    x = -xx;
 608:	40b005bb          	negw	a1,a1
    neg = 1;
 60c:	4885                	li	a7,1
    x = -xx;
 60e:	bf8d                	j	580 <printint+0x1a>

0000000000000610 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 610:	7119                	addi	sp,sp,-128
 612:	fc86                	sd	ra,120(sp)
 614:	f8a2                	sd	s0,112(sp)
 616:	f4a6                	sd	s1,104(sp)
 618:	f0ca                	sd	s2,96(sp)
 61a:	ecce                	sd	s3,88(sp)
 61c:	e8d2                	sd	s4,80(sp)
 61e:	e4d6                	sd	s5,72(sp)
 620:	e0da                	sd	s6,64(sp)
 622:	fc5e                	sd	s7,56(sp)
 624:	f862                	sd	s8,48(sp)
 626:	f466                	sd	s9,40(sp)
 628:	f06a                	sd	s10,32(sp)
 62a:	ec6e                	sd	s11,24(sp)
 62c:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 62e:	0005c903          	lbu	s2,0(a1)
 632:	18090f63          	beqz	s2,7d0 <vprintf+0x1c0>
 636:	8aaa                	mv	s5,a0
 638:	8b32                	mv	s6,a2
 63a:	00158493          	addi	s1,a1,1
  state = 0;
 63e:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 640:	02500a13          	li	s4,37
      if(c == 'd'){
 644:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 648:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 64c:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 650:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 654:	00000b97          	auipc	s7,0x0
 658:	52cb8b93          	addi	s7,s7,1324 # b80 <digits>
 65c:	a839                	j	67a <vprintf+0x6a>
        putc(fd, c);
 65e:	85ca                	mv	a1,s2
 660:	8556                	mv	a0,s5
 662:	00000097          	auipc	ra,0x0
 666:	ee2080e7          	jalr	-286(ra) # 544 <putc>
 66a:	a019                	j	670 <vprintf+0x60>
    } else if(state == '%'){
 66c:	01498f63          	beq	s3,s4,68a <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 670:	0485                	addi	s1,s1,1
 672:	fff4c903          	lbu	s2,-1(s1)
 676:	14090d63          	beqz	s2,7d0 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 67a:	0009079b          	sext.w	a5,s2
    if(state == 0){
 67e:	fe0997e3          	bnez	s3,66c <vprintf+0x5c>
      if(c == '%'){
 682:	fd479ee3          	bne	a5,s4,65e <vprintf+0x4e>
        state = '%';
 686:	89be                	mv	s3,a5
 688:	b7e5                	j	670 <vprintf+0x60>
      if(c == 'd'){
 68a:	05878063          	beq	a5,s8,6ca <vprintf+0xba>
      } else if(c == 'l') {
 68e:	05978c63          	beq	a5,s9,6e6 <vprintf+0xd6>
      } else if(c == 'x') {
 692:	07a78863          	beq	a5,s10,702 <vprintf+0xf2>
      } else if(c == 'p') {
 696:	09b78463          	beq	a5,s11,71e <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 69a:	07300713          	li	a4,115
 69e:	0ce78663          	beq	a5,a4,76a <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 6a2:	06300713          	li	a4,99
 6a6:	0ee78e63          	beq	a5,a4,7a2 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 6aa:	11478863          	beq	a5,s4,7ba <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 6ae:	85d2                	mv	a1,s4
 6b0:	8556                	mv	a0,s5
 6b2:	00000097          	auipc	ra,0x0
 6b6:	e92080e7          	jalr	-366(ra) # 544 <putc>
        putc(fd, c);
 6ba:	85ca                	mv	a1,s2
 6bc:	8556                	mv	a0,s5
 6be:	00000097          	auipc	ra,0x0
 6c2:	e86080e7          	jalr	-378(ra) # 544 <putc>
      }
      state = 0;
 6c6:	4981                	li	s3,0
 6c8:	b765                	j	670 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 6ca:	008b0913          	addi	s2,s6,8
 6ce:	4685                	li	a3,1
 6d0:	4629                	li	a2,10
 6d2:	000b2583          	lw	a1,0(s6)
 6d6:	8556                	mv	a0,s5
 6d8:	00000097          	auipc	ra,0x0
 6dc:	e8e080e7          	jalr	-370(ra) # 566 <printint>
 6e0:	8b4a                	mv	s6,s2
      state = 0;
 6e2:	4981                	li	s3,0
 6e4:	b771                	j	670 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 6e6:	008b0913          	addi	s2,s6,8
 6ea:	4681                	li	a3,0
 6ec:	4629                	li	a2,10
 6ee:	000b2583          	lw	a1,0(s6)
 6f2:	8556                	mv	a0,s5
 6f4:	00000097          	auipc	ra,0x0
 6f8:	e72080e7          	jalr	-398(ra) # 566 <printint>
 6fc:	8b4a                	mv	s6,s2
      state = 0;
 6fe:	4981                	li	s3,0
 700:	bf85                	j	670 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 702:	008b0913          	addi	s2,s6,8
 706:	4681                	li	a3,0
 708:	4641                	li	a2,16
 70a:	000b2583          	lw	a1,0(s6)
 70e:	8556                	mv	a0,s5
 710:	00000097          	auipc	ra,0x0
 714:	e56080e7          	jalr	-426(ra) # 566 <printint>
 718:	8b4a                	mv	s6,s2
      state = 0;
 71a:	4981                	li	s3,0
 71c:	bf91                	j	670 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 71e:	008b0793          	addi	a5,s6,8
 722:	f8f43423          	sd	a5,-120(s0)
 726:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 72a:	03000593          	li	a1,48
 72e:	8556                	mv	a0,s5
 730:	00000097          	auipc	ra,0x0
 734:	e14080e7          	jalr	-492(ra) # 544 <putc>
  putc(fd, 'x');
 738:	85ea                	mv	a1,s10
 73a:	8556                	mv	a0,s5
 73c:	00000097          	auipc	ra,0x0
 740:	e08080e7          	jalr	-504(ra) # 544 <putc>
 744:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 746:	03c9d793          	srli	a5,s3,0x3c
 74a:	97de                	add	a5,a5,s7
 74c:	0007c583          	lbu	a1,0(a5)
 750:	8556                	mv	a0,s5
 752:	00000097          	auipc	ra,0x0
 756:	df2080e7          	jalr	-526(ra) # 544 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 75a:	0992                	slli	s3,s3,0x4
 75c:	397d                	addiw	s2,s2,-1
 75e:	fe0914e3          	bnez	s2,746 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 762:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 766:	4981                	li	s3,0
 768:	b721                	j	670 <vprintf+0x60>
        s = va_arg(ap, char*);
 76a:	008b0993          	addi	s3,s6,8
 76e:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 772:	02090163          	beqz	s2,794 <vprintf+0x184>
        while(*s != 0){
 776:	00094583          	lbu	a1,0(s2)
 77a:	c9a1                	beqz	a1,7ca <vprintf+0x1ba>
          putc(fd, *s);
 77c:	8556                	mv	a0,s5
 77e:	00000097          	auipc	ra,0x0
 782:	dc6080e7          	jalr	-570(ra) # 544 <putc>
          s++;
 786:	0905                	addi	s2,s2,1
        while(*s != 0){
 788:	00094583          	lbu	a1,0(s2)
 78c:	f9e5                	bnez	a1,77c <vprintf+0x16c>
        s = va_arg(ap, char*);
 78e:	8b4e                	mv	s6,s3
      state = 0;
 790:	4981                	li	s3,0
 792:	bdf9                	j	670 <vprintf+0x60>
          s = "(null)";
 794:	00000917          	auipc	s2,0x0
 798:	3e490913          	addi	s2,s2,996 # b78 <malloc+0x29e>
        while(*s != 0){
 79c:	02800593          	li	a1,40
 7a0:	bff1                	j	77c <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 7a2:	008b0913          	addi	s2,s6,8
 7a6:	000b4583          	lbu	a1,0(s6)
 7aa:	8556                	mv	a0,s5
 7ac:	00000097          	auipc	ra,0x0
 7b0:	d98080e7          	jalr	-616(ra) # 544 <putc>
 7b4:	8b4a                	mv	s6,s2
      state = 0;
 7b6:	4981                	li	s3,0
 7b8:	bd65                	j	670 <vprintf+0x60>
        putc(fd, c);
 7ba:	85d2                	mv	a1,s4
 7bc:	8556                	mv	a0,s5
 7be:	00000097          	auipc	ra,0x0
 7c2:	d86080e7          	jalr	-634(ra) # 544 <putc>
      state = 0;
 7c6:	4981                	li	s3,0
 7c8:	b565                	j	670 <vprintf+0x60>
        s = va_arg(ap, char*);
 7ca:	8b4e                	mv	s6,s3
      state = 0;
 7cc:	4981                	li	s3,0
 7ce:	b54d                	j	670 <vprintf+0x60>
    }
  }
}
 7d0:	70e6                	ld	ra,120(sp)
 7d2:	7446                	ld	s0,112(sp)
 7d4:	74a6                	ld	s1,104(sp)
 7d6:	7906                	ld	s2,96(sp)
 7d8:	69e6                	ld	s3,88(sp)
 7da:	6a46                	ld	s4,80(sp)
 7dc:	6aa6                	ld	s5,72(sp)
 7de:	6b06                	ld	s6,64(sp)
 7e0:	7be2                	ld	s7,56(sp)
 7e2:	7c42                	ld	s8,48(sp)
 7e4:	7ca2                	ld	s9,40(sp)
 7e6:	7d02                	ld	s10,32(sp)
 7e8:	6de2                	ld	s11,24(sp)
 7ea:	6109                	addi	sp,sp,128
 7ec:	8082                	ret

00000000000007ee <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 7ee:	715d                	addi	sp,sp,-80
 7f0:	ec06                	sd	ra,24(sp)
 7f2:	e822                	sd	s0,16(sp)
 7f4:	1000                	addi	s0,sp,32
 7f6:	e010                	sd	a2,0(s0)
 7f8:	e414                	sd	a3,8(s0)
 7fa:	e818                	sd	a4,16(s0)
 7fc:	ec1c                	sd	a5,24(s0)
 7fe:	03043023          	sd	a6,32(s0)
 802:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 806:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 80a:	8622                	mv	a2,s0
 80c:	00000097          	auipc	ra,0x0
 810:	e04080e7          	jalr	-508(ra) # 610 <vprintf>
}
 814:	60e2                	ld	ra,24(sp)
 816:	6442                	ld	s0,16(sp)
 818:	6161                	addi	sp,sp,80
 81a:	8082                	ret

000000000000081c <printf>:

void
printf(const char *fmt, ...)
{
 81c:	711d                	addi	sp,sp,-96
 81e:	ec06                	sd	ra,24(sp)
 820:	e822                	sd	s0,16(sp)
 822:	1000                	addi	s0,sp,32
 824:	e40c                	sd	a1,8(s0)
 826:	e810                	sd	a2,16(s0)
 828:	ec14                	sd	a3,24(s0)
 82a:	f018                	sd	a4,32(s0)
 82c:	f41c                	sd	a5,40(s0)
 82e:	03043823          	sd	a6,48(s0)
 832:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 836:	00840613          	addi	a2,s0,8
 83a:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 83e:	85aa                	mv	a1,a0
 840:	4505                	li	a0,1
 842:	00000097          	auipc	ra,0x0
 846:	dce080e7          	jalr	-562(ra) # 610 <vprintf>
}
 84a:	60e2                	ld	ra,24(sp)
 84c:	6442                	ld	s0,16(sp)
 84e:	6125                	addi	sp,sp,96
 850:	8082                	ret

0000000000000852 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 852:	1141                	addi	sp,sp,-16
 854:	e422                	sd	s0,8(sp)
 856:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 858:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 85c:	00000797          	auipc	a5,0x0
 860:	7a47b783          	ld	a5,1956(a5) # 1000 <freep>
 864:	a805                	j	894 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 866:	4618                	lw	a4,8(a2)
 868:	9db9                	addw	a1,a1,a4
 86a:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 86e:	6398                	ld	a4,0(a5)
 870:	6318                	ld	a4,0(a4)
 872:	fee53823          	sd	a4,-16(a0)
 876:	a091                	j	8ba <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 878:	ff852703          	lw	a4,-8(a0)
 87c:	9e39                	addw	a2,a2,a4
 87e:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 880:	ff053703          	ld	a4,-16(a0)
 884:	e398                	sd	a4,0(a5)
 886:	a099                	j	8cc <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 888:	6398                	ld	a4,0(a5)
 88a:	00e7e463          	bltu	a5,a4,892 <free+0x40>
 88e:	00e6ea63          	bltu	a3,a4,8a2 <free+0x50>
{
 892:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 894:	fed7fae3          	bgeu	a5,a3,888 <free+0x36>
 898:	6398                	ld	a4,0(a5)
 89a:	00e6e463          	bltu	a3,a4,8a2 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 89e:	fee7eae3          	bltu	a5,a4,892 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 8a2:	ff852583          	lw	a1,-8(a0)
 8a6:	6390                	ld	a2,0(a5)
 8a8:	02059713          	slli	a4,a1,0x20
 8ac:	9301                	srli	a4,a4,0x20
 8ae:	0712                	slli	a4,a4,0x4
 8b0:	9736                	add	a4,a4,a3
 8b2:	fae60ae3          	beq	a2,a4,866 <free+0x14>
    bp->s.ptr = p->s.ptr;
 8b6:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 8ba:	4790                	lw	a2,8(a5)
 8bc:	02061713          	slli	a4,a2,0x20
 8c0:	9301                	srli	a4,a4,0x20
 8c2:	0712                	slli	a4,a4,0x4
 8c4:	973e                	add	a4,a4,a5
 8c6:	fae689e3          	beq	a3,a4,878 <free+0x26>
  } else
    p->s.ptr = bp;
 8ca:	e394                	sd	a3,0(a5)
  freep = p;
 8cc:	00000717          	auipc	a4,0x0
 8d0:	72f73a23          	sd	a5,1844(a4) # 1000 <freep>
}
 8d4:	6422                	ld	s0,8(sp)
 8d6:	0141                	addi	sp,sp,16
 8d8:	8082                	ret

00000000000008da <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 8da:	7139                	addi	sp,sp,-64
 8dc:	fc06                	sd	ra,56(sp)
 8de:	f822                	sd	s0,48(sp)
 8e0:	f426                	sd	s1,40(sp)
 8e2:	f04a                	sd	s2,32(sp)
 8e4:	ec4e                	sd	s3,24(sp)
 8e6:	e852                	sd	s4,16(sp)
 8e8:	e456                	sd	s5,8(sp)
 8ea:	e05a                	sd	s6,0(sp)
 8ec:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 8ee:	02051493          	slli	s1,a0,0x20
 8f2:	9081                	srli	s1,s1,0x20
 8f4:	04bd                	addi	s1,s1,15
 8f6:	8091                	srli	s1,s1,0x4
 8f8:	0014899b          	addiw	s3,s1,1
 8fc:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 8fe:	00000517          	auipc	a0,0x0
 902:	70253503          	ld	a0,1794(a0) # 1000 <freep>
 906:	c515                	beqz	a0,932 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 908:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 90a:	4798                	lw	a4,8(a5)
 90c:	02977f63          	bgeu	a4,s1,94a <malloc+0x70>
 910:	8a4e                	mv	s4,s3
 912:	0009871b          	sext.w	a4,s3
 916:	6685                	lui	a3,0x1
 918:	00d77363          	bgeu	a4,a3,91e <malloc+0x44>
 91c:	6a05                	lui	s4,0x1
 91e:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 922:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 926:	00000917          	auipc	s2,0x0
 92a:	6da90913          	addi	s2,s2,1754 # 1000 <freep>
  if(p == (char*)-1)
 92e:	5afd                	li	s5,-1
 930:	a88d                	j	9a2 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 932:	00000797          	auipc	a5,0x0
 936:	6de78793          	addi	a5,a5,1758 # 1010 <base>
 93a:	00000717          	auipc	a4,0x0
 93e:	6cf73323          	sd	a5,1734(a4) # 1000 <freep>
 942:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 944:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 948:	b7e1                	j	910 <malloc+0x36>
      if(p->s.size == nunits)
 94a:	02e48b63          	beq	s1,a4,980 <malloc+0xa6>
        p->s.size -= nunits;
 94e:	4137073b          	subw	a4,a4,s3
 952:	c798                	sw	a4,8(a5)
        p += p->s.size;
 954:	1702                	slli	a4,a4,0x20
 956:	9301                	srli	a4,a4,0x20
 958:	0712                	slli	a4,a4,0x4
 95a:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 95c:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 960:	00000717          	auipc	a4,0x0
 964:	6aa73023          	sd	a0,1696(a4) # 1000 <freep>
      return (void*)(p + 1);
 968:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 96c:	70e2                	ld	ra,56(sp)
 96e:	7442                	ld	s0,48(sp)
 970:	74a2                	ld	s1,40(sp)
 972:	7902                	ld	s2,32(sp)
 974:	69e2                	ld	s3,24(sp)
 976:	6a42                	ld	s4,16(sp)
 978:	6aa2                	ld	s5,8(sp)
 97a:	6b02                	ld	s6,0(sp)
 97c:	6121                	addi	sp,sp,64
 97e:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 980:	6398                	ld	a4,0(a5)
 982:	e118                	sd	a4,0(a0)
 984:	bff1                	j	960 <malloc+0x86>
  hp->s.size = nu;
 986:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 98a:	0541                	addi	a0,a0,16
 98c:	00000097          	auipc	ra,0x0
 990:	ec6080e7          	jalr	-314(ra) # 852 <free>
  return freep;
 994:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 998:	d971                	beqz	a0,96c <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 99a:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 99c:	4798                	lw	a4,8(a5)
 99e:	fa9776e3          	bgeu	a4,s1,94a <malloc+0x70>
    if(p == freep)
 9a2:	00093703          	ld	a4,0(s2)
 9a6:	853e                	mv	a0,a5
 9a8:	fef719e3          	bne	a4,a5,99a <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 9ac:	8552                	mv	a0,s4
 9ae:	00000097          	auipc	ra,0x0
 9b2:	b6e080e7          	jalr	-1170(ra) # 51c <sbrk>
  if(p == (char*)-1)
 9b6:	fd5518e3          	bne	a0,s5,986 <malloc+0xac>
        return 0;
 9ba:	4501                	li	a0,0
 9bc:	bf45                	j	96c <malloc+0x92>
