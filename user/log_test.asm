
user/_log_test:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#define NUM_CHILDREN 4
#define MAKE_HEADER(idx, len) (((idx) << 16) | (len))
int INDICATOR=0;

int main(int argc, char *argv[])
{
   0:	7131                	addi	sp,sp,-192
   2:	fd06                	sd	ra,184(sp)
   4:	f922                	sd	s0,176(sp)
   6:	f526                	sd	s1,168(sp)
   8:	f14a                	sd	s2,160(sp)
   a:	ed4e                	sd	s3,152(sp)
   c:	e952                	sd	s4,144(sp)
   e:	e556                	sd	s5,136(sp)
  10:	e15a                	sd	s6,128(sp)
  12:	fcde                	sd	s7,120(sp)
  14:	f8e2                	sd	s8,112(sp)
  16:	f4e6                	sd	s9,104(sp)
  18:	f0ea                	sd	s10,96(sp)
  1a:	ecee                	sd	s11,88(sp)
  1c:	0180                	addi	s0,sp,192
  char *buf = malloc(PGSIZE);
  1e:	6505                	lui	a0,0x1
  20:	00001097          	auipc	ra,0x1
  24:	964080e7          	jalr	-1692(ra) # 984 <malloc>
  if (!buf) {
  28:	c94d                	beqz	a0,da <main+0xda>
  2a:	8a2a                	mv	s4,a0
    printf("Parent: malloc failed\n");
    exit(1);
  }

  // Zero-initialize the shared buffer
  memset(buf, 0, PGSIZE);
  2c:	6605                	lui	a2,0x1
  2e:	4581                	li	a1,0
  30:	00000097          	auipc	ra,0x0
  34:	312080e7          	jalr	786(ra) # 342 <memset>

  int par_pid = getpid();
  38:	00000097          	auipc	ra,0x0
  3c:	586080e7          	jalr	1414(ra) # 5be <getpid>
  40:	8aaa                	mv	s5,a0
  // Fork childrens
  for (int i = 0; i < NUM_CHILDREN; i++) {
  42:	4981                	li	s3,0
  44:	4491                	li	s1,4
    int pid = fork();
  46:	00000097          	auipc	ra,0x0
  4a:	4f0080e7          	jalr	1264(ra) # 536 <fork>
  4e:	892a                	mv	s2,a0
    if (pid == 0) {
  50:	c155                	beqz	a0,f4 <main+0xf4>
  for (int i = 0; i < NUM_CHILDREN; i++) {
  52:	2985                	addiw	s3,s3,1
  54:	fe9999e3          	bne	s3,s1,46 <main+0x46>
      exit(0);
    }
  }

  // this is the parent
  sleep(20);
  58:	4551                	li	a0,20
  5a:	00000097          	auipc	ra,0x0
  5e:	574080e7          	jalr	1396(ra) # 5ce <sleep>
  printf("Parent: reading messages from shared buffer\n");
  62:	00001517          	auipc	a0,0x1
  66:	a7650513          	addi	a0,a0,-1418 # ad8 <malloc+0x154>
  6a:	00001097          	auipc	ra,0x1
  6e:	85c080e7          	jalr	-1956(ra) # 8c6 <printf>
  
  char *p = buf;
  while (p + 4 <= buf + PGSIZE) {
  72:	004a0593          	addi	a1,s4,4
  76:	6a85                	lui	s5,0x1
  78:	9ad2                	add	s5,s5,s4
    int header = *(int *)p;
    if (header == 0)
      break;

    int child_idx = (header >> 16) & 0xFFFF;
    int length = header & 0xFFFF;
  7a:	69c1                	lui	s3,0x10
  7c:	19fd                	addi	s3,s3,-1

    char msg[MAX_MSG_length];
    memmove(msg, p + 4, length);
    msg[length] = '\0';

    printf("From child %d: %s\n", child_idx, msg);
  7e:	00001b17          	auipc	s6,0x1
  82:	a8ab0b13          	addi	s6,s6,-1398 # b08 <malloc+0x184>
    int header = *(int *)p;
  86:	000a2903          	lw	s2,0(s4)
    if (header == 0)
  8a:	04090363          	beqz	s2,d0 <main+0xd0>
    int length = header & 0xFFFF;
  8e:	013974b3          	and	s1,s2,s3
    memmove(msg, p + 4, length);
  92:	8626                	mv	a2,s1
  94:	f5040513          	addi	a0,s0,-176
  98:	00000097          	auipc	ra,0x0
  9c:	3f4080e7          	jalr	1012(ra) # 48c <memmove>
    msg[length] = '\0';
  a0:	f9040793          	addi	a5,s0,-112
  a4:	97a6                	add	a5,a5,s1
  a6:	fc078023          	sb	zero,-64(a5)
    printf("From child %d: %s\n", child_idx, msg);
  aa:	f5040613          	addi	a2,s0,-176
  ae:	0109559b          	srliw	a1,s2,0x10
  b2:	855a                	mv	a0,s6
  b4:	00001097          	auipc	ra,0x1
  b8:	812080e7          	jalr	-2030(ra) # 8c6 <printf>

    p += 4 + length;
  bc:	0044851b          	addiw	a0,s1,4
  c0:	9552                	add	a0,a0,s4
    p = (char *)(((uint64)p + 3) & ~3);
  c2:	050d                	addi	a0,a0,3
  c4:	ffc57a13          	andi	s4,a0,-4
  while (p + 4 <= buf + PGSIZE) {
  c8:	004a0593          	addi	a1,s4,4
  cc:	fabafde3          	bgeu	s5,a1,86 <main+0x86>
  }

  exit(0);
  d0:	4501                	li	a0,0
  d2:	00000097          	auipc	ra,0x0
  d6:	46c080e7          	jalr	1132(ra) # 53e <exit>
    printf("Parent: malloc failed\n");
  da:	00001517          	auipc	a0,0x1
  de:	99650513          	addi	a0,a0,-1642 # a70 <malloc+0xec>
  e2:	00000097          	auipc	ra,0x0
  e6:	7e4080e7          	jalr	2020(ra) # 8c6 <printf>
    exit(1);
  ea:	4505                	li	a0,1
  ec:	00000097          	auipc	ra,0x0
  f0:	452080e7          	jalr	1106(ra) # 53e <exit>
      uint64 addr = map_shared_pages(par_pid, getpid(), buf, PGSIZE);
  f4:	00000097          	auipc	ra,0x0
  f8:	4ca080e7          	jalr	1226(ra) # 5be <getpid>
  fc:	85aa                	mv	a1,a0
  fe:	6685                	lui	a3,0x1
 100:	8652                	mv	a2,s4
 102:	8556                	mv	a0,s5
 104:	00000097          	auipc	ra,0x0
 108:	4da080e7          	jalr	1242(ra) # 5de <map_shared_pages>
      if (addr == 0) {
 10c:	c105                	beqz	a0,12c <main+0x12c>
        int claimed = __sync_val_compare_and_swap((int *)p, 0, MAKE_HEADER(i, length));
 10e:	01099c9b          	slliw	s9,s3,0x10
      char *p = shared;
 112:	8a2a                	mv	s4,a0
      int num = 1;
 114:	4b85                	li	s7,1
        strcpy(msg, "Hi from child ");
 116:	00001c17          	auipc	s8,0x1
 11a:	99ac0c13          	addi	s8,s8,-1638 # ab0 <malloc+0x12c>
        msg[length] = '0' + i;
 11e:	0309899b          	addiw	s3,s3,48
        if (p + 4 + length > shared + PGSIZE)
 122:	6b05                	lui	s6,0x1
 124:	9b2a                	add	s6,s6,a0
            int prev_length = claimed & 0xFFFF;
 126:	6d41                	lui	s10,0x10
 128:	1d7d                	addi	s10,s10,-1
 12a:	a8a5                	j	1a2 <main+0x1a2>
        printf("Child %d: map_shared_pages failed\n", i);
 12c:	85ce                	mv	a1,s3
 12e:	00001517          	auipc	a0,0x1
 132:	95a50513          	addi	a0,a0,-1702 # a88 <malloc+0x104>
 136:	00000097          	auipc	ra,0x0
 13a:	790080e7          	jalr	1936(ra) # 8c6 <printf>
        exit(1);
 13e:	4505                	li	a0,1
 140:	00000097          	auipc	ra,0x0
 144:	3fe080e7          	jalr	1022(ra) # 53e <exit>
            int available = shared + PGSIZE - p;
 148:	414b0b3b          	subw	s6,s6,s4
            if (available < 4)
 14c:	478d                	li	a5,3
 14e:	0167d963          	bge	a5,s6,160 <main+0x160>
            if (available < 4 + length)
 152:	2711                	addiw	a4,a4,4
 154:	01674463          	blt	a4,s6,15c <main+0x15c>
            write_length = available - 4; 
 158:	ffcb061b          	addiw	a2,s6,-4
            if (write_length <= 0)
 15c:	00c04763          	bgtz	a2,16a <main+0x16a>
      exit(0);
 160:	4501                	li	a0,0
 162:	00000097          	auipc	ra,0x0
 166:	3dc080e7          	jalr	988(ra) # 53e <exit>
            int claimed = __sync_val_compare_and_swap((int *)p, 0, MAKE_HEADER(i, write_length));
 16a:	00ccecb3          	or	s9,s9,a2
 16e:	0f50000f          	fence	iorw,ow
 172:	140a27af          	lr.w.aq	a5,(s4)
 176:	e781                	bnez	a5,17e <main+0x17e>
 178:	1d9a272f          	sc.w.aq	a4,s9,(s4)
 17c:	fb7d                	bnez	a4,172 <main+0x172>
 17e:	2781                	sext.w	a5,a5
            if (claimed == 0)
 180:	f3e5                	bnez	a5,160 <main+0x160>
                memmove(p + 4, msg, write_length);
 182:	f5040593          	addi	a1,s0,-176
 186:	004a0513          	addi	a0,s4,4
 18a:	00000097          	auipc	ra,0x0
 18e:	302080e7          	jalr	770(ra) # 48c <memmove>
 192:	b7f9                	j	160 <main+0x160>
            int prev_length = claimed & 0xFFFF;
 194:	01a7f7b3          	and	a5,a5,s10
            p += 4 + prev_length;
 198:	2791                	addiw	a5,a5,4
 19a:	9a3e                	add	s4,s4,a5
        p = (char *)(((uint64)p + 3) & ~3);  // Align to 4-byte boundary
 19c:	0a0d                	addi	s4,s4,3
 19e:	ffca7a13          	andi	s4,s4,-4
        strcpy(msg, "Hi from child ");
 1a2:	85e2                	mv	a1,s8
 1a4:	f5040513          	addi	a0,s0,-176
 1a8:	00000097          	auipc	ra,0x0
 1ac:	128080e7          	jalr	296(ra) # 2d0 <strcpy>
        int length = strlen(msg);
 1b0:	f5040513          	addi	a0,s0,-176
 1b4:	00000097          	auipc	ra,0x0
 1b8:	164080e7          	jalr	356(ra) # 318 <strlen>
 1bc:	00050d9b          	sext.w	s11,a0
        msg[length] = '0' + i;
 1c0:	f9040793          	addi	a5,s0,-112
 1c4:	97ee                	add	a5,a5,s11
 1c6:	fd378023          	sb	s3,-64(a5)
        int suffix_length = strlen(suffix);
 1ca:	00001517          	auipc	a0,0x1
 1ce:	8f650513          	addi	a0,a0,-1802 # ac0 <malloc+0x13c>
 1d2:	00000097          	auipc	ra,0x0
 1d6:	146080e7          	jalr	326(ra) # 318 <strlen>
        if (length + suffix_length >= MAX_MSG_length)
 1da:	01b50abb          	addw	s5,a0,s11
 1de:	000a849b          	sext.w	s1,s5
 1e2:	03f00793          	li	a5,63
 1e6:	f697cde3          	blt	a5,s1,160 <main+0x160>
        strcpy(msg + length, suffix);
 1ea:	00001597          	auipc	a1,0x1
 1ee:	8d658593          	addi	a1,a1,-1834 # ac0 <malloc+0x13c>
 1f2:	f5040793          	addi	a5,s0,-176
 1f6:	01b78533          	add	a0,a5,s11
 1fa:	00000097          	auipc	ra,0x0
 1fe:	0d6080e7          	jalr	214(ra) # 2d0 <strcpy>
        if (length + 5 >= MAX_MSG_length)
 202:	03a00793          	li	a5,58
 206:	f497cde3          	blt	a5,s1,160 <main+0x160>
 20a:	f4040613          	addi	a2,s0,-192
        int digits = 0;
 20e:	86ca                	mv	a3,s2
        int n = num;
 210:	87de                	mv	a5,s7
            tmp[digits++] = '0' + (n % 10);
 212:	45a9                	li	a1,10
        } while (n > 0);
 214:	4825                	li	a6,9
            tmp[digits++] = '0' + (n % 10);
 216:	8536                	mv	a0,a3
 218:	2685                	addiw	a3,a3,1
 21a:	02b7e73b          	remw	a4,a5,a1
 21e:	0307071b          	addiw	a4,a4,48
 222:	00e60023          	sb	a4,0(a2) # 1000 <INDICATOR>
            n /= 10;
 226:	873e                	mv	a4,a5
 228:	02b7c7bb          	divw	a5,a5,a1
        } while (n > 0);
 22c:	0605                	addi	a2,a2,1
 22e:	fee844e3          	blt	a6,a4,216 <main+0x216>
        for (int j = 0; j < digits; j++)
 232:	02d05563          	blez	a3,25c <main+0x25c>
 236:	f4040793          	addi	a5,s0,-192
 23a:	00d78633          	add	a2,a5,a3
 23e:	f5040793          	addi	a5,s0,-176
 242:	94be                	add	s1,s1,a5
 244:	87b2                	mv	a5,a2
 246:	367d                	addiw	a2,a2,-1
            msg[start + j] = tmp[digits - j - 1];
 248:	fff7c703          	lbu	a4,-1(a5)
 24c:	00e48023          	sb	a4,0(s1)
        for (int j = 0; j < digits; j++)
 250:	17fd                	addi	a5,a5,-1
 252:	0485                	addi	s1,s1,1
 254:	40f6073b          	subw	a4,a2,a5
 258:	fea748e3          	blt	a4,a0,248 <main+0x248>
        length = start + digits;
 25c:	00da8abb          	addw	s5,s5,a3
 260:	000a871b          	sext.w	a4,s5
        msg[length] = '\0';
 264:	f9040793          	addi	a5,s0,-112
 268:	97ba                	add	a5,a5,a4
 26a:	fc078023          	sb	zero,-64(a5)
        length++;
 26e:	001a861b          	addiw	a2,s5,1
        if (p + 4 + length > shared + PGSIZE)
 272:	00460793          	addi	a5,a2,4
 276:	97d2                	add	a5,a5,s4
 278:	ecfb68e3          	bltu	s6,a5,148 <main+0x148>
        int claimed = __sync_val_compare_and_swap((int *)p, 0, MAKE_HEADER(i, length));
 27c:	00cce733          	or	a4,s9,a2
 280:	0f50000f          	fence	iorw,ow
 284:	140a27af          	lr.w.aq	a5,(s4)
 288:	e781                	bnez	a5,290 <main+0x290>
 28a:	1cea26af          	sc.w.aq	a3,a4,(s4)
 28e:	fafd                	bnez	a3,284 <main+0x284>
 290:	2781                	sext.w	a5,a5
        if (claimed == 0) {
 292:	f389                	bnez	a5,194 <main+0x194>
            memmove(p + 4, msg, length);
 294:	f5040593          	addi	a1,s0,-176
 298:	004a0513          	addi	a0,s4,4
 29c:	00000097          	auipc	ra,0x0
 2a0:	1f0080e7          	jalr	496(ra) # 48c <memmove>
            num++; 
 2a4:	2b85                	addiw	s7,s7,1
            p += 4 + length;
 2a6:	2a95                	addiw	s5,s5,5
 2a8:	9a56                	add	s4,s4,s5
            sleep(1); 
 2aa:	4505                	li	a0,1
 2ac:	00000097          	auipc	ra,0x0
 2b0:	322080e7          	jalr	802(ra) # 5ce <sleep>
 2b4:	b5e5                	j	19c <main+0x19c>

00000000000002b6 <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
 2b6:	1141                	addi	sp,sp,-16
 2b8:	e406                	sd	ra,8(sp)
 2ba:	e022                	sd	s0,0(sp)
 2bc:	0800                	addi	s0,sp,16
  extern int main();
  main();
 2be:	00000097          	auipc	ra,0x0
 2c2:	d42080e7          	jalr	-702(ra) # 0 <main>
  exit(0);
 2c6:	4501                	li	a0,0
 2c8:	00000097          	auipc	ra,0x0
 2cc:	276080e7          	jalr	630(ra) # 53e <exit>

00000000000002d0 <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
 2d0:	1141                	addi	sp,sp,-16
 2d2:	e422                	sd	s0,8(sp)
 2d4:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 2d6:	87aa                	mv	a5,a0
 2d8:	0585                	addi	a1,a1,1
 2da:	0785                	addi	a5,a5,1
 2dc:	fff5c703          	lbu	a4,-1(a1)
 2e0:	fee78fa3          	sb	a4,-1(a5)
 2e4:	fb75                	bnez	a4,2d8 <strcpy+0x8>
    ;
  return os;
}
 2e6:	6422                	ld	s0,8(sp)
 2e8:	0141                	addi	sp,sp,16
 2ea:	8082                	ret

00000000000002ec <strcmp>:

int
strcmp(const char *p, const char *q)
{
 2ec:	1141                	addi	sp,sp,-16
 2ee:	e422                	sd	s0,8(sp)
 2f0:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 2f2:	00054783          	lbu	a5,0(a0)
 2f6:	cb91                	beqz	a5,30a <strcmp+0x1e>
 2f8:	0005c703          	lbu	a4,0(a1)
 2fc:	00f71763          	bne	a4,a5,30a <strcmp+0x1e>
    p++, q++;
 300:	0505                	addi	a0,a0,1
 302:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 304:	00054783          	lbu	a5,0(a0)
 308:	fbe5                	bnez	a5,2f8 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 30a:	0005c503          	lbu	a0,0(a1)
}
 30e:	40a7853b          	subw	a0,a5,a0
 312:	6422                	ld	s0,8(sp)
 314:	0141                	addi	sp,sp,16
 316:	8082                	ret

0000000000000318 <strlen>:

uint
strlen(const char *s)
{
 318:	1141                	addi	sp,sp,-16
 31a:	e422                	sd	s0,8(sp)
 31c:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 31e:	00054783          	lbu	a5,0(a0)
 322:	cf91                	beqz	a5,33e <strlen+0x26>
 324:	0505                	addi	a0,a0,1
 326:	87aa                	mv	a5,a0
 328:	4685                	li	a3,1
 32a:	9e89                	subw	a3,a3,a0
 32c:	00f6853b          	addw	a0,a3,a5
 330:	0785                	addi	a5,a5,1
 332:	fff7c703          	lbu	a4,-1(a5)
 336:	fb7d                	bnez	a4,32c <strlen+0x14>
    ;
  return n;
}
 338:	6422                	ld	s0,8(sp)
 33a:	0141                	addi	sp,sp,16
 33c:	8082                	ret
  for(n = 0; s[n]; n++)
 33e:	4501                	li	a0,0
 340:	bfe5                	j	338 <strlen+0x20>

0000000000000342 <memset>:

void*
memset(void *dst, int c, uint n)
{
 342:	1141                	addi	sp,sp,-16
 344:	e422                	sd	s0,8(sp)
 346:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 348:	ca19                	beqz	a2,35e <memset+0x1c>
 34a:	87aa                	mv	a5,a0
 34c:	1602                	slli	a2,a2,0x20
 34e:	9201                	srli	a2,a2,0x20
 350:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 354:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 358:	0785                	addi	a5,a5,1
 35a:	fee79de3          	bne	a5,a4,354 <memset+0x12>
  }
  return dst;
}
 35e:	6422                	ld	s0,8(sp)
 360:	0141                	addi	sp,sp,16
 362:	8082                	ret

0000000000000364 <strchr>:

char*
strchr(const char *s, char c)
{
 364:	1141                	addi	sp,sp,-16
 366:	e422                	sd	s0,8(sp)
 368:	0800                	addi	s0,sp,16
  for(; *s; s++)
 36a:	00054783          	lbu	a5,0(a0)
 36e:	cb99                	beqz	a5,384 <strchr+0x20>
    if(*s == c)
 370:	00f58763          	beq	a1,a5,37e <strchr+0x1a>
  for(; *s; s++)
 374:	0505                	addi	a0,a0,1
 376:	00054783          	lbu	a5,0(a0)
 37a:	fbfd                	bnez	a5,370 <strchr+0xc>
      return (char*)s;
  return 0;
 37c:	4501                	li	a0,0
}
 37e:	6422                	ld	s0,8(sp)
 380:	0141                	addi	sp,sp,16
 382:	8082                	ret
  return 0;
 384:	4501                	li	a0,0
 386:	bfe5                	j	37e <strchr+0x1a>

0000000000000388 <gets>:

char*
gets(char *buf, int max)
{
 388:	711d                	addi	sp,sp,-96
 38a:	ec86                	sd	ra,88(sp)
 38c:	e8a2                	sd	s0,80(sp)
 38e:	e4a6                	sd	s1,72(sp)
 390:	e0ca                	sd	s2,64(sp)
 392:	fc4e                	sd	s3,56(sp)
 394:	f852                	sd	s4,48(sp)
 396:	f456                	sd	s5,40(sp)
 398:	f05a                	sd	s6,32(sp)
 39a:	ec5e                	sd	s7,24(sp)
 39c:	1080                	addi	s0,sp,96
 39e:	8baa                	mv	s7,a0
 3a0:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 3a2:	892a                	mv	s2,a0
 3a4:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 3a6:	4aa9                	li	s5,10
 3a8:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 3aa:	89a6                	mv	s3,s1
 3ac:	2485                	addiw	s1,s1,1
 3ae:	0344d863          	bge	s1,s4,3de <gets+0x56>
    cc = read(0, &c, 1);
 3b2:	4605                	li	a2,1
 3b4:	faf40593          	addi	a1,s0,-81
 3b8:	4501                	li	a0,0
 3ba:	00000097          	auipc	ra,0x0
 3be:	19c080e7          	jalr	412(ra) # 556 <read>
    if(cc < 1)
 3c2:	00a05e63          	blez	a0,3de <gets+0x56>
    buf[i++] = c;
 3c6:	faf44783          	lbu	a5,-81(s0)
 3ca:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 3ce:	01578763          	beq	a5,s5,3dc <gets+0x54>
 3d2:	0905                	addi	s2,s2,1
 3d4:	fd679be3          	bne	a5,s6,3aa <gets+0x22>
  for(i=0; i+1 < max; ){
 3d8:	89a6                	mv	s3,s1
 3da:	a011                	j	3de <gets+0x56>
 3dc:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 3de:	99de                	add	s3,s3,s7
 3e0:	00098023          	sb	zero,0(s3) # 10000 <base+0xeff0>
  return buf;
}
 3e4:	855e                	mv	a0,s7
 3e6:	60e6                	ld	ra,88(sp)
 3e8:	6446                	ld	s0,80(sp)
 3ea:	64a6                	ld	s1,72(sp)
 3ec:	6906                	ld	s2,64(sp)
 3ee:	79e2                	ld	s3,56(sp)
 3f0:	7a42                	ld	s4,48(sp)
 3f2:	7aa2                	ld	s5,40(sp)
 3f4:	7b02                	ld	s6,32(sp)
 3f6:	6be2                	ld	s7,24(sp)
 3f8:	6125                	addi	sp,sp,96
 3fa:	8082                	ret

00000000000003fc <stat>:

int
stat(const char *n, struct stat *st)
{
 3fc:	1101                	addi	sp,sp,-32
 3fe:	ec06                	sd	ra,24(sp)
 400:	e822                	sd	s0,16(sp)
 402:	e426                	sd	s1,8(sp)
 404:	e04a                	sd	s2,0(sp)
 406:	1000                	addi	s0,sp,32
 408:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 40a:	4581                	li	a1,0
 40c:	00000097          	auipc	ra,0x0
 410:	172080e7          	jalr	370(ra) # 57e <open>
  if(fd < 0)
 414:	02054563          	bltz	a0,43e <stat+0x42>
 418:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 41a:	85ca                	mv	a1,s2
 41c:	00000097          	auipc	ra,0x0
 420:	17a080e7          	jalr	378(ra) # 596 <fstat>
 424:	892a                	mv	s2,a0
  close(fd);
 426:	8526                	mv	a0,s1
 428:	00000097          	auipc	ra,0x0
 42c:	13e080e7          	jalr	318(ra) # 566 <close>
  return r;
}
 430:	854a                	mv	a0,s2
 432:	60e2                	ld	ra,24(sp)
 434:	6442                	ld	s0,16(sp)
 436:	64a2                	ld	s1,8(sp)
 438:	6902                	ld	s2,0(sp)
 43a:	6105                	addi	sp,sp,32
 43c:	8082                	ret
    return -1;
 43e:	597d                	li	s2,-1
 440:	bfc5                	j	430 <stat+0x34>

0000000000000442 <atoi>:

int
atoi(const char *s)
{
 442:	1141                	addi	sp,sp,-16
 444:	e422                	sd	s0,8(sp)
 446:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 448:	00054603          	lbu	a2,0(a0)
 44c:	fd06079b          	addiw	a5,a2,-48
 450:	0ff7f793          	andi	a5,a5,255
 454:	4725                	li	a4,9
 456:	02f76963          	bltu	a4,a5,488 <atoi+0x46>
 45a:	86aa                	mv	a3,a0
  n = 0;
 45c:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 45e:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 460:	0685                	addi	a3,a3,1
 462:	0025179b          	slliw	a5,a0,0x2
 466:	9fa9                	addw	a5,a5,a0
 468:	0017979b          	slliw	a5,a5,0x1
 46c:	9fb1                	addw	a5,a5,a2
 46e:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 472:	0006c603          	lbu	a2,0(a3) # 1000 <INDICATOR>
 476:	fd06071b          	addiw	a4,a2,-48
 47a:	0ff77713          	andi	a4,a4,255
 47e:	fee5f1e3          	bgeu	a1,a4,460 <atoi+0x1e>
  return n;
}
 482:	6422                	ld	s0,8(sp)
 484:	0141                	addi	sp,sp,16
 486:	8082                	ret
  n = 0;
 488:	4501                	li	a0,0
 48a:	bfe5                	j	482 <atoi+0x40>

000000000000048c <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 48c:	1141                	addi	sp,sp,-16
 48e:	e422                	sd	s0,8(sp)
 490:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 492:	02b57463          	bgeu	a0,a1,4ba <memmove+0x2e>
    while(n-- > 0)
 496:	00c05f63          	blez	a2,4b4 <memmove+0x28>
 49a:	1602                	slli	a2,a2,0x20
 49c:	9201                	srli	a2,a2,0x20
 49e:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 4a2:	872a                	mv	a4,a0
      *dst++ = *src++;
 4a4:	0585                	addi	a1,a1,1
 4a6:	0705                	addi	a4,a4,1
 4a8:	fff5c683          	lbu	a3,-1(a1)
 4ac:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 4b0:	fee79ae3          	bne	a5,a4,4a4 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 4b4:	6422                	ld	s0,8(sp)
 4b6:	0141                	addi	sp,sp,16
 4b8:	8082                	ret
    dst += n;
 4ba:	00c50733          	add	a4,a0,a2
    src += n;
 4be:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 4c0:	fec05ae3          	blez	a2,4b4 <memmove+0x28>
 4c4:	fff6079b          	addiw	a5,a2,-1
 4c8:	1782                	slli	a5,a5,0x20
 4ca:	9381                	srli	a5,a5,0x20
 4cc:	fff7c793          	not	a5,a5
 4d0:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 4d2:	15fd                	addi	a1,a1,-1
 4d4:	177d                	addi	a4,a4,-1
 4d6:	0005c683          	lbu	a3,0(a1)
 4da:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 4de:	fee79ae3          	bne	a5,a4,4d2 <memmove+0x46>
 4e2:	bfc9                	j	4b4 <memmove+0x28>

00000000000004e4 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 4e4:	1141                	addi	sp,sp,-16
 4e6:	e422                	sd	s0,8(sp)
 4e8:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 4ea:	ca05                	beqz	a2,51a <memcmp+0x36>
 4ec:	fff6069b          	addiw	a3,a2,-1
 4f0:	1682                	slli	a3,a3,0x20
 4f2:	9281                	srli	a3,a3,0x20
 4f4:	0685                	addi	a3,a3,1
 4f6:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 4f8:	00054783          	lbu	a5,0(a0)
 4fc:	0005c703          	lbu	a4,0(a1)
 500:	00e79863          	bne	a5,a4,510 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 504:	0505                	addi	a0,a0,1
    p2++;
 506:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 508:	fed518e3          	bne	a0,a3,4f8 <memcmp+0x14>
  }
  return 0;
 50c:	4501                	li	a0,0
 50e:	a019                	j	514 <memcmp+0x30>
      return *p1 - *p2;
 510:	40e7853b          	subw	a0,a5,a4
}
 514:	6422                	ld	s0,8(sp)
 516:	0141                	addi	sp,sp,16
 518:	8082                	ret
  return 0;
 51a:	4501                	li	a0,0
 51c:	bfe5                	j	514 <memcmp+0x30>

000000000000051e <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 51e:	1141                	addi	sp,sp,-16
 520:	e406                	sd	ra,8(sp)
 522:	e022                	sd	s0,0(sp)
 524:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 526:	00000097          	auipc	ra,0x0
 52a:	f66080e7          	jalr	-154(ra) # 48c <memmove>
}
 52e:	60a2                	ld	ra,8(sp)
 530:	6402                	ld	s0,0(sp)
 532:	0141                	addi	sp,sp,16
 534:	8082                	ret

0000000000000536 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 536:	4885                	li	a7,1
 ecall
 538:	00000073          	ecall
 ret
 53c:	8082                	ret

000000000000053e <exit>:
.global exit
exit:
 li a7, SYS_exit
 53e:	4889                	li	a7,2
 ecall
 540:	00000073          	ecall
 ret
 544:	8082                	ret

0000000000000546 <wait>:
.global wait
wait:
 li a7, SYS_wait
 546:	488d                	li	a7,3
 ecall
 548:	00000073          	ecall
 ret
 54c:	8082                	ret

000000000000054e <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 54e:	4891                	li	a7,4
 ecall
 550:	00000073          	ecall
 ret
 554:	8082                	ret

0000000000000556 <read>:
.global read
read:
 li a7, SYS_read
 556:	4895                	li	a7,5
 ecall
 558:	00000073          	ecall
 ret
 55c:	8082                	ret

000000000000055e <write>:
.global write
write:
 li a7, SYS_write
 55e:	48c1                	li	a7,16
 ecall
 560:	00000073          	ecall
 ret
 564:	8082                	ret

0000000000000566 <close>:
.global close
close:
 li a7, SYS_close
 566:	48d5                	li	a7,21
 ecall
 568:	00000073          	ecall
 ret
 56c:	8082                	ret

000000000000056e <kill>:
.global kill
kill:
 li a7, SYS_kill
 56e:	4899                	li	a7,6
 ecall
 570:	00000073          	ecall
 ret
 574:	8082                	ret

0000000000000576 <exec>:
.global exec
exec:
 li a7, SYS_exec
 576:	489d                	li	a7,7
 ecall
 578:	00000073          	ecall
 ret
 57c:	8082                	ret

000000000000057e <open>:
.global open
open:
 li a7, SYS_open
 57e:	48bd                	li	a7,15
 ecall
 580:	00000073          	ecall
 ret
 584:	8082                	ret

0000000000000586 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 586:	48c5                	li	a7,17
 ecall
 588:	00000073          	ecall
 ret
 58c:	8082                	ret

000000000000058e <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 58e:	48c9                	li	a7,18
 ecall
 590:	00000073          	ecall
 ret
 594:	8082                	ret

0000000000000596 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 596:	48a1                	li	a7,8
 ecall
 598:	00000073          	ecall
 ret
 59c:	8082                	ret

000000000000059e <link>:
.global link
link:
 li a7, SYS_link
 59e:	48cd                	li	a7,19
 ecall
 5a0:	00000073          	ecall
 ret
 5a4:	8082                	ret

00000000000005a6 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 5a6:	48d1                	li	a7,20
 ecall
 5a8:	00000073          	ecall
 ret
 5ac:	8082                	ret

00000000000005ae <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 5ae:	48a5                	li	a7,9
 ecall
 5b0:	00000073          	ecall
 ret
 5b4:	8082                	ret

00000000000005b6 <dup>:
.global dup
dup:
 li a7, SYS_dup
 5b6:	48a9                	li	a7,10
 ecall
 5b8:	00000073          	ecall
 ret
 5bc:	8082                	ret

00000000000005be <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 5be:	48ad                	li	a7,11
 ecall
 5c0:	00000073          	ecall
 ret
 5c4:	8082                	ret

00000000000005c6 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 5c6:	48b1                	li	a7,12
 ecall
 5c8:	00000073          	ecall
 ret
 5cc:	8082                	ret

00000000000005ce <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 5ce:	48b5                	li	a7,13
 ecall
 5d0:	00000073          	ecall
 ret
 5d4:	8082                	ret

00000000000005d6 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 5d6:	48b9                	li	a7,14
 ecall
 5d8:	00000073          	ecall
 ret
 5dc:	8082                	ret

00000000000005de <map_shared_pages>:
.global map_shared_pages
map_shared_pages:
 li a7, SYS_map_shared_pages
 5de:	48d9                	li	a7,22
 ecall
 5e0:	00000073          	ecall
 ret
 5e4:	8082                	ret

00000000000005e6 <unmap_shared_pages>:
.global unmap_shared_pages
unmap_shared_pages:
 li a7, SYS_unmap_shared_pages
 5e6:	48dd                	li	a7,23
 ecall
 5e8:	00000073          	ecall
 ret
 5ec:	8082                	ret

00000000000005ee <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 5ee:	1101                	addi	sp,sp,-32
 5f0:	ec06                	sd	ra,24(sp)
 5f2:	e822                	sd	s0,16(sp)
 5f4:	1000                	addi	s0,sp,32
 5f6:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 5fa:	4605                	li	a2,1
 5fc:	fef40593          	addi	a1,s0,-17
 600:	00000097          	auipc	ra,0x0
 604:	f5e080e7          	jalr	-162(ra) # 55e <write>
}
 608:	60e2                	ld	ra,24(sp)
 60a:	6442                	ld	s0,16(sp)
 60c:	6105                	addi	sp,sp,32
 60e:	8082                	ret

0000000000000610 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 610:	7139                	addi	sp,sp,-64
 612:	fc06                	sd	ra,56(sp)
 614:	f822                	sd	s0,48(sp)
 616:	f426                	sd	s1,40(sp)
 618:	f04a                	sd	s2,32(sp)
 61a:	ec4e                	sd	s3,24(sp)
 61c:	0080                	addi	s0,sp,64
 61e:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 620:	c299                	beqz	a3,626 <printint+0x16>
 622:	0805c863          	bltz	a1,6b2 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 626:	2581                	sext.w	a1,a1
  neg = 0;
 628:	4881                	li	a7,0
 62a:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 62e:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 630:	2601                	sext.w	a2,a2
 632:	00000517          	auipc	a0,0x0
 636:	4f650513          	addi	a0,a0,1270 # b28 <digits>
 63a:	883a                	mv	a6,a4
 63c:	2705                	addiw	a4,a4,1
 63e:	02c5f7bb          	remuw	a5,a1,a2
 642:	1782                	slli	a5,a5,0x20
 644:	9381                	srli	a5,a5,0x20
 646:	97aa                	add	a5,a5,a0
 648:	0007c783          	lbu	a5,0(a5)
 64c:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 650:	0005879b          	sext.w	a5,a1
 654:	02c5d5bb          	divuw	a1,a1,a2
 658:	0685                	addi	a3,a3,1
 65a:	fec7f0e3          	bgeu	a5,a2,63a <printint+0x2a>
  if(neg)
 65e:	00088b63          	beqz	a7,674 <printint+0x64>
    buf[i++] = '-';
 662:	fd040793          	addi	a5,s0,-48
 666:	973e                	add	a4,a4,a5
 668:	02d00793          	li	a5,45
 66c:	fef70823          	sb	a5,-16(a4)
 670:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 674:	02e05863          	blez	a4,6a4 <printint+0x94>
 678:	fc040793          	addi	a5,s0,-64
 67c:	00e78933          	add	s2,a5,a4
 680:	fff78993          	addi	s3,a5,-1
 684:	99ba                	add	s3,s3,a4
 686:	377d                	addiw	a4,a4,-1
 688:	1702                	slli	a4,a4,0x20
 68a:	9301                	srli	a4,a4,0x20
 68c:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 690:	fff94583          	lbu	a1,-1(s2)
 694:	8526                	mv	a0,s1
 696:	00000097          	auipc	ra,0x0
 69a:	f58080e7          	jalr	-168(ra) # 5ee <putc>
  while(--i >= 0)
 69e:	197d                	addi	s2,s2,-1
 6a0:	ff3918e3          	bne	s2,s3,690 <printint+0x80>
}
 6a4:	70e2                	ld	ra,56(sp)
 6a6:	7442                	ld	s0,48(sp)
 6a8:	74a2                	ld	s1,40(sp)
 6aa:	7902                	ld	s2,32(sp)
 6ac:	69e2                	ld	s3,24(sp)
 6ae:	6121                	addi	sp,sp,64
 6b0:	8082                	ret
    x = -xx;
 6b2:	40b005bb          	negw	a1,a1
    neg = 1;
 6b6:	4885                	li	a7,1
    x = -xx;
 6b8:	bf8d                	j	62a <printint+0x1a>

00000000000006ba <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 6ba:	7119                	addi	sp,sp,-128
 6bc:	fc86                	sd	ra,120(sp)
 6be:	f8a2                	sd	s0,112(sp)
 6c0:	f4a6                	sd	s1,104(sp)
 6c2:	f0ca                	sd	s2,96(sp)
 6c4:	ecce                	sd	s3,88(sp)
 6c6:	e8d2                	sd	s4,80(sp)
 6c8:	e4d6                	sd	s5,72(sp)
 6ca:	e0da                	sd	s6,64(sp)
 6cc:	fc5e                	sd	s7,56(sp)
 6ce:	f862                	sd	s8,48(sp)
 6d0:	f466                	sd	s9,40(sp)
 6d2:	f06a                	sd	s10,32(sp)
 6d4:	ec6e                	sd	s11,24(sp)
 6d6:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 6d8:	0005c903          	lbu	s2,0(a1)
 6dc:	18090f63          	beqz	s2,87a <vprintf+0x1c0>
 6e0:	8aaa                	mv	s5,a0
 6e2:	8b32                	mv	s6,a2
 6e4:	00158493          	addi	s1,a1,1
  state = 0;
 6e8:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 6ea:	02500a13          	li	s4,37
      if(c == 'd'){
 6ee:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 6f2:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 6f6:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 6fa:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 6fe:	00000b97          	auipc	s7,0x0
 702:	42ab8b93          	addi	s7,s7,1066 # b28 <digits>
 706:	a839                	j	724 <vprintf+0x6a>
        putc(fd, c);
 708:	85ca                	mv	a1,s2
 70a:	8556                	mv	a0,s5
 70c:	00000097          	auipc	ra,0x0
 710:	ee2080e7          	jalr	-286(ra) # 5ee <putc>
 714:	a019                	j	71a <vprintf+0x60>
    } else if(state == '%'){
 716:	01498f63          	beq	s3,s4,734 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 71a:	0485                	addi	s1,s1,1
 71c:	fff4c903          	lbu	s2,-1(s1)
 720:	14090d63          	beqz	s2,87a <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 724:	0009079b          	sext.w	a5,s2
    if(state == 0){
 728:	fe0997e3          	bnez	s3,716 <vprintf+0x5c>
      if(c == '%'){
 72c:	fd479ee3          	bne	a5,s4,708 <vprintf+0x4e>
        state = '%';
 730:	89be                	mv	s3,a5
 732:	b7e5                	j	71a <vprintf+0x60>
      if(c == 'd'){
 734:	05878063          	beq	a5,s8,774 <vprintf+0xba>
      } else if(c == 'l') {
 738:	05978c63          	beq	a5,s9,790 <vprintf+0xd6>
      } else if(c == 'x') {
 73c:	07a78863          	beq	a5,s10,7ac <vprintf+0xf2>
      } else if(c == 'p') {
 740:	09b78463          	beq	a5,s11,7c8 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 744:	07300713          	li	a4,115
 748:	0ce78663          	beq	a5,a4,814 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 74c:	06300713          	li	a4,99
 750:	0ee78e63          	beq	a5,a4,84c <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 754:	11478863          	beq	a5,s4,864 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 758:	85d2                	mv	a1,s4
 75a:	8556                	mv	a0,s5
 75c:	00000097          	auipc	ra,0x0
 760:	e92080e7          	jalr	-366(ra) # 5ee <putc>
        putc(fd, c);
 764:	85ca                	mv	a1,s2
 766:	8556                	mv	a0,s5
 768:	00000097          	auipc	ra,0x0
 76c:	e86080e7          	jalr	-378(ra) # 5ee <putc>
      }
      state = 0;
 770:	4981                	li	s3,0
 772:	b765                	j	71a <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 774:	008b0913          	addi	s2,s6,8 # 1008 <freep>
 778:	4685                	li	a3,1
 77a:	4629                	li	a2,10
 77c:	000b2583          	lw	a1,0(s6)
 780:	8556                	mv	a0,s5
 782:	00000097          	auipc	ra,0x0
 786:	e8e080e7          	jalr	-370(ra) # 610 <printint>
 78a:	8b4a                	mv	s6,s2
      state = 0;
 78c:	4981                	li	s3,0
 78e:	b771                	j	71a <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 790:	008b0913          	addi	s2,s6,8
 794:	4681                	li	a3,0
 796:	4629                	li	a2,10
 798:	000b2583          	lw	a1,0(s6)
 79c:	8556                	mv	a0,s5
 79e:	00000097          	auipc	ra,0x0
 7a2:	e72080e7          	jalr	-398(ra) # 610 <printint>
 7a6:	8b4a                	mv	s6,s2
      state = 0;
 7a8:	4981                	li	s3,0
 7aa:	bf85                	j	71a <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 7ac:	008b0913          	addi	s2,s6,8
 7b0:	4681                	li	a3,0
 7b2:	4641                	li	a2,16
 7b4:	000b2583          	lw	a1,0(s6)
 7b8:	8556                	mv	a0,s5
 7ba:	00000097          	auipc	ra,0x0
 7be:	e56080e7          	jalr	-426(ra) # 610 <printint>
 7c2:	8b4a                	mv	s6,s2
      state = 0;
 7c4:	4981                	li	s3,0
 7c6:	bf91                	j	71a <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 7c8:	008b0793          	addi	a5,s6,8
 7cc:	f8f43423          	sd	a5,-120(s0)
 7d0:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 7d4:	03000593          	li	a1,48
 7d8:	8556                	mv	a0,s5
 7da:	00000097          	auipc	ra,0x0
 7de:	e14080e7          	jalr	-492(ra) # 5ee <putc>
  putc(fd, 'x');
 7e2:	85ea                	mv	a1,s10
 7e4:	8556                	mv	a0,s5
 7e6:	00000097          	auipc	ra,0x0
 7ea:	e08080e7          	jalr	-504(ra) # 5ee <putc>
 7ee:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 7f0:	03c9d793          	srli	a5,s3,0x3c
 7f4:	97de                	add	a5,a5,s7
 7f6:	0007c583          	lbu	a1,0(a5)
 7fa:	8556                	mv	a0,s5
 7fc:	00000097          	auipc	ra,0x0
 800:	df2080e7          	jalr	-526(ra) # 5ee <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 804:	0992                	slli	s3,s3,0x4
 806:	397d                	addiw	s2,s2,-1
 808:	fe0914e3          	bnez	s2,7f0 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 80c:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 810:	4981                	li	s3,0
 812:	b721                	j	71a <vprintf+0x60>
        s = va_arg(ap, char*);
 814:	008b0993          	addi	s3,s6,8
 818:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 81c:	02090163          	beqz	s2,83e <vprintf+0x184>
        while(*s != 0){
 820:	00094583          	lbu	a1,0(s2)
 824:	c9a1                	beqz	a1,874 <vprintf+0x1ba>
          putc(fd, *s);
 826:	8556                	mv	a0,s5
 828:	00000097          	auipc	ra,0x0
 82c:	dc6080e7          	jalr	-570(ra) # 5ee <putc>
          s++;
 830:	0905                	addi	s2,s2,1
        while(*s != 0){
 832:	00094583          	lbu	a1,0(s2)
 836:	f9e5                	bnez	a1,826 <vprintf+0x16c>
        s = va_arg(ap, char*);
 838:	8b4e                	mv	s6,s3
      state = 0;
 83a:	4981                	li	s3,0
 83c:	bdf9                	j	71a <vprintf+0x60>
          s = "(null)";
 83e:	00000917          	auipc	s2,0x0
 842:	2e290913          	addi	s2,s2,738 # b20 <malloc+0x19c>
        while(*s != 0){
 846:	02800593          	li	a1,40
 84a:	bff1                	j	826 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 84c:	008b0913          	addi	s2,s6,8
 850:	000b4583          	lbu	a1,0(s6)
 854:	8556                	mv	a0,s5
 856:	00000097          	auipc	ra,0x0
 85a:	d98080e7          	jalr	-616(ra) # 5ee <putc>
 85e:	8b4a                	mv	s6,s2
      state = 0;
 860:	4981                	li	s3,0
 862:	bd65                	j	71a <vprintf+0x60>
        putc(fd, c);
 864:	85d2                	mv	a1,s4
 866:	8556                	mv	a0,s5
 868:	00000097          	auipc	ra,0x0
 86c:	d86080e7          	jalr	-634(ra) # 5ee <putc>
      state = 0;
 870:	4981                	li	s3,0
 872:	b565                	j	71a <vprintf+0x60>
        s = va_arg(ap, char*);
 874:	8b4e                	mv	s6,s3
      state = 0;
 876:	4981                	li	s3,0
 878:	b54d                	j	71a <vprintf+0x60>
    }
  }
}
 87a:	70e6                	ld	ra,120(sp)
 87c:	7446                	ld	s0,112(sp)
 87e:	74a6                	ld	s1,104(sp)
 880:	7906                	ld	s2,96(sp)
 882:	69e6                	ld	s3,88(sp)
 884:	6a46                	ld	s4,80(sp)
 886:	6aa6                	ld	s5,72(sp)
 888:	6b06                	ld	s6,64(sp)
 88a:	7be2                	ld	s7,56(sp)
 88c:	7c42                	ld	s8,48(sp)
 88e:	7ca2                	ld	s9,40(sp)
 890:	7d02                	ld	s10,32(sp)
 892:	6de2                	ld	s11,24(sp)
 894:	6109                	addi	sp,sp,128
 896:	8082                	ret

0000000000000898 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 898:	715d                	addi	sp,sp,-80
 89a:	ec06                	sd	ra,24(sp)
 89c:	e822                	sd	s0,16(sp)
 89e:	1000                	addi	s0,sp,32
 8a0:	e010                	sd	a2,0(s0)
 8a2:	e414                	sd	a3,8(s0)
 8a4:	e818                	sd	a4,16(s0)
 8a6:	ec1c                	sd	a5,24(s0)
 8a8:	03043023          	sd	a6,32(s0)
 8ac:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 8b0:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 8b4:	8622                	mv	a2,s0
 8b6:	00000097          	auipc	ra,0x0
 8ba:	e04080e7          	jalr	-508(ra) # 6ba <vprintf>
}
 8be:	60e2                	ld	ra,24(sp)
 8c0:	6442                	ld	s0,16(sp)
 8c2:	6161                	addi	sp,sp,80
 8c4:	8082                	ret

00000000000008c6 <printf>:

void
printf(const char *fmt, ...)
{
 8c6:	711d                	addi	sp,sp,-96
 8c8:	ec06                	sd	ra,24(sp)
 8ca:	e822                	sd	s0,16(sp)
 8cc:	1000                	addi	s0,sp,32
 8ce:	e40c                	sd	a1,8(s0)
 8d0:	e810                	sd	a2,16(s0)
 8d2:	ec14                	sd	a3,24(s0)
 8d4:	f018                	sd	a4,32(s0)
 8d6:	f41c                	sd	a5,40(s0)
 8d8:	03043823          	sd	a6,48(s0)
 8dc:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 8e0:	00840613          	addi	a2,s0,8
 8e4:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 8e8:	85aa                	mv	a1,a0
 8ea:	4505                	li	a0,1
 8ec:	00000097          	auipc	ra,0x0
 8f0:	dce080e7          	jalr	-562(ra) # 6ba <vprintf>
}
 8f4:	60e2                	ld	ra,24(sp)
 8f6:	6442                	ld	s0,16(sp)
 8f8:	6125                	addi	sp,sp,96
 8fa:	8082                	ret

00000000000008fc <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 8fc:	1141                	addi	sp,sp,-16
 8fe:	e422                	sd	s0,8(sp)
 900:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 902:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 906:	00000797          	auipc	a5,0x0
 90a:	7027b783          	ld	a5,1794(a5) # 1008 <freep>
 90e:	a805                	j	93e <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 910:	4618                	lw	a4,8(a2)
 912:	9db9                	addw	a1,a1,a4
 914:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 918:	6398                	ld	a4,0(a5)
 91a:	6318                	ld	a4,0(a4)
 91c:	fee53823          	sd	a4,-16(a0)
 920:	a091                	j	964 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 922:	ff852703          	lw	a4,-8(a0)
 926:	9e39                	addw	a2,a2,a4
 928:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 92a:	ff053703          	ld	a4,-16(a0)
 92e:	e398                	sd	a4,0(a5)
 930:	a099                	j	976 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 932:	6398                	ld	a4,0(a5)
 934:	00e7e463          	bltu	a5,a4,93c <free+0x40>
 938:	00e6ea63          	bltu	a3,a4,94c <free+0x50>
{
 93c:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 93e:	fed7fae3          	bgeu	a5,a3,932 <free+0x36>
 942:	6398                	ld	a4,0(a5)
 944:	00e6e463          	bltu	a3,a4,94c <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 948:	fee7eae3          	bltu	a5,a4,93c <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 94c:	ff852583          	lw	a1,-8(a0)
 950:	6390                	ld	a2,0(a5)
 952:	02059713          	slli	a4,a1,0x20
 956:	9301                	srli	a4,a4,0x20
 958:	0712                	slli	a4,a4,0x4
 95a:	9736                	add	a4,a4,a3
 95c:	fae60ae3          	beq	a2,a4,910 <free+0x14>
    bp->s.ptr = p->s.ptr;
 960:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 964:	4790                	lw	a2,8(a5)
 966:	02061713          	slli	a4,a2,0x20
 96a:	9301                	srli	a4,a4,0x20
 96c:	0712                	slli	a4,a4,0x4
 96e:	973e                	add	a4,a4,a5
 970:	fae689e3          	beq	a3,a4,922 <free+0x26>
  } else
    p->s.ptr = bp;
 974:	e394                	sd	a3,0(a5)
  freep = p;
 976:	00000717          	auipc	a4,0x0
 97a:	68f73923          	sd	a5,1682(a4) # 1008 <freep>
}
 97e:	6422                	ld	s0,8(sp)
 980:	0141                	addi	sp,sp,16
 982:	8082                	ret

0000000000000984 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 984:	7139                	addi	sp,sp,-64
 986:	fc06                	sd	ra,56(sp)
 988:	f822                	sd	s0,48(sp)
 98a:	f426                	sd	s1,40(sp)
 98c:	f04a                	sd	s2,32(sp)
 98e:	ec4e                	sd	s3,24(sp)
 990:	e852                	sd	s4,16(sp)
 992:	e456                	sd	s5,8(sp)
 994:	e05a                	sd	s6,0(sp)
 996:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 998:	02051493          	slli	s1,a0,0x20
 99c:	9081                	srli	s1,s1,0x20
 99e:	04bd                	addi	s1,s1,15
 9a0:	8091                	srli	s1,s1,0x4
 9a2:	0014899b          	addiw	s3,s1,1
 9a6:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 9a8:	00000517          	auipc	a0,0x0
 9ac:	66053503          	ld	a0,1632(a0) # 1008 <freep>
 9b0:	c515                	beqz	a0,9dc <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 9b2:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 9b4:	4798                	lw	a4,8(a5)
 9b6:	02977f63          	bgeu	a4,s1,9f4 <malloc+0x70>
 9ba:	8a4e                	mv	s4,s3
 9bc:	0009871b          	sext.w	a4,s3
 9c0:	6685                	lui	a3,0x1
 9c2:	00d77363          	bgeu	a4,a3,9c8 <malloc+0x44>
 9c6:	6a05                	lui	s4,0x1
 9c8:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 9cc:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 9d0:	00000917          	auipc	s2,0x0
 9d4:	63890913          	addi	s2,s2,1592 # 1008 <freep>
  if(p == (char*)-1)
 9d8:	5afd                	li	s5,-1
 9da:	a88d                	j	a4c <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 9dc:	00000797          	auipc	a5,0x0
 9e0:	63478793          	addi	a5,a5,1588 # 1010 <base>
 9e4:	00000717          	auipc	a4,0x0
 9e8:	62f73223          	sd	a5,1572(a4) # 1008 <freep>
 9ec:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 9ee:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 9f2:	b7e1                	j	9ba <malloc+0x36>
      if(p->s.size == nunits)
 9f4:	02e48b63          	beq	s1,a4,a2a <malloc+0xa6>
        p->s.size -= nunits;
 9f8:	4137073b          	subw	a4,a4,s3
 9fc:	c798                	sw	a4,8(a5)
        p += p->s.size;
 9fe:	1702                	slli	a4,a4,0x20
 a00:	9301                	srli	a4,a4,0x20
 a02:	0712                	slli	a4,a4,0x4
 a04:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 a06:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 a0a:	00000717          	auipc	a4,0x0
 a0e:	5ea73f23          	sd	a0,1534(a4) # 1008 <freep>
      return (void*)(p + 1);
 a12:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 a16:	70e2                	ld	ra,56(sp)
 a18:	7442                	ld	s0,48(sp)
 a1a:	74a2                	ld	s1,40(sp)
 a1c:	7902                	ld	s2,32(sp)
 a1e:	69e2                	ld	s3,24(sp)
 a20:	6a42                	ld	s4,16(sp)
 a22:	6aa2                	ld	s5,8(sp)
 a24:	6b02                	ld	s6,0(sp)
 a26:	6121                	addi	sp,sp,64
 a28:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 a2a:	6398                	ld	a4,0(a5)
 a2c:	e118                	sd	a4,0(a0)
 a2e:	bff1                	j	a0a <malloc+0x86>
  hp->s.size = nu;
 a30:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 a34:	0541                	addi	a0,a0,16
 a36:	00000097          	auipc	ra,0x0
 a3a:	ec6080e7          	jalr	-314(ra) # 8fc <free>
  return freep;
 a3e:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 a42:	d971                	beqz	a0,a16 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 a44:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 a46:	4798                	lw	a4,8(a5)
 a48:	fa9776e3          	bgeu	a4,s1,9f4 <malloc+0x70>
    if(p == freep)
 a4c:	00093703          	ld	a4,0(s2)
 a50:	853e                	mv	a0,a5
 a52:	fef719e3          	bne	a4,a5,a44 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 a56:	8552                	mv	a0,s4
 a58:	00000097          	auipc	ra,0x0
 a5c:	b6e080e7          	jalr	-1170(ra) # 5c6 <sbrk>
  if(p == (char*)-1)
 a60:	fd5518e3          	bne	a0,s5,a30 <malloc+0xac>
        return 0;
 a64:	4501                	li	a0,0
 a66:	bf45                	j	a16 <malloc+0x92>
