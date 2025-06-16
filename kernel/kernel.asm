
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	a5010113          	addi	sp,sp,-1456 # 80008a50 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	8be70713          	addi	a4,a4,-1858 # 80008910 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	f3c78793          	addi	a5,a5,-196 # 80005fa0 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdca7f>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	dca78793          	addi	a5,a5,-566 # 80000e78 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	644080e7          	jalr	1604(ra) # 80002770 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	780080e7          	jalr	1920(ra) # 800008bc <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	8c650513          	addi	a0,a0,-1850 # 80010a50 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	8b648493          	addi	s1,s1,-1866 # 80010a50 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	94690913          	addi	s2,s2,-1722 # 80010ae8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	aaa080e7          	jalr	-1366(ra) # 80001c6a <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	3f2080e7          	jalr	1010(ra) # 800025ba <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	13c080e7          	jalr	316(ra) # 80002312 <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	508080e7          	jalr	1288(ra) # 8000271a <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	82a50513          	addi	a0,a0,-2006 # 80010a50 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	81450513          	addi	a0,a0,-2028 # 80010a50 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a46080e7          	jalr	-1466(ra) # 80000c8a <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	86f72b23          	sw	a5,-1930(a4) # 80010ae8 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	55e080e7          	jalr	1374(ra) # 800007ea <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54c080e7          	jalr	1356(ra) # 800007ea <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	540080e7          	jalr	1344(ra) # 800007ea <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	536080e7          	jalr	1334(ra) # 800007ea <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00010517          	auipc	a0,0x10
    800002d0:	78450513          	addi	a0,a0,1924 # 80010a50 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	4d4080e7          	jalr	1236(ra) # 800027c6 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	75650513          	addi	a0,a0,1878 # 80010a50 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	73270713          	addi	a4,a4,1842 # 80010a50 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	70878793          	addi	a5,a5,1800 # 80010a50 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00010797          	auipc	a5,0x10
    8000037a:	7727a783          	lw	a5,1906(a5) # 80010ae8 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	6c670713          	addi	a4,a4,1734 # 80010a50 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	6b648493          	addi	s1,s1,1718 # 80010a50 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	67a70713          	addi	a4,a4,1658 # 80010a50 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	70f72223          	sw	a5,1796(a4) # 80010af0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	63e78793          	addi	a5,a5,1598 # 80010a50 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	6ac7ab23          	sw	a2,1718(a5) # 80010aec <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	6aa50513          	addi	a0,a0,1706 # 80010ae8 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	f30080e7          	jalr	-208(ra) # 80002376 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	5f050513          	addi	a0,a0,1520 # 80010a50 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32a080e7          	jalr	810(ra) # 8000079a <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00020797          	auipc	a5,0x20
    8000047c:	77078793          	addi	a5,a5,1904 # 80020be8 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00010797          	auipc	a5,0x10
    8000054e:	5c07a323          	sw	zero,1478(a5) # 80010b10 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00008717          	auipc	a4,0x8
    80000582:	34f72923          	sw	a5,850(a4) # 800088d0 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00010d97          	auipc	s11,0x10
    800005be:	556dad83          	lw	s11,1366(s11) # 80010b10 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	14050f63          	beqz	a0,80000734 <printf+0x1ac>
    800005da:	4981                	li	s3,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b93          	li	s7,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b17          	auipc	s6,0x8
    800005ea:	a5ab0b13          	addi	s6,s6,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00010517          	auipc	a0,0x10
    800005fc:	50050513          	addi	a0,a0,1280 # 80010af8 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5d6080e7          	jalr	1494(ra) # 80000bd6 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2985                	addiw	s3,s3,1
    80000624:	013a07b3          	add	a5,s4,s3
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050463          	beqz	a0,80000734 <printf+0x1ac>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2985                	addiw	s3,s3,1
    80000636:	013a07b3          	add	a5,s4,s3
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000642:	cbed                	beqz	a5,80000734 <printf+0x1ac>
    switch(c){
    80000644:	05778a63          	beq	a5,s7,80000698 <printf+0x110>
    80000648:	02fbf663          	bgeu	s7,a5,80000674 <printf+0xec>
    8000064c:	09978863          	beq	a5,s9,800006dc <printf+0x154>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79563          	bne	a5,a4,8000071e <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	09578f63          	beq	a5,s5,80000712 <printf+0x18a>
    80000678:	0b879363          	bne	a5,s8,8000071e <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c95793          	srli	a5,s2,0x3c
    800006c6:	97da                	add	a5,a5,s6
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0912                	slli	s2,s2,0x4
    800006d6:	34fd                	addiw	s1,s1,-1
    800006d8:	f4ed                	bnez	s1,800006c2 <printf+0x13a>
    800006da:	b7a1                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006dc:	f8843783          	ld	a5,-120(s0)
    800006e0:	00878713          	addi	a4,a5,8
    800006e4:	f8e43423          	sd	a4,-120(s0)
    800006e8:	6384                	ld	s1,0(a5)
    800006ea:	cc89                	beqz	s1,80000704 <printf+0x17c>
      for(; *s; s++)
    800006ec:	0004c503          	lbu	a0,0(s1)
    800006f0:	d90d                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f2:	00000097          	auipc	ra,0x0
    800006f6:	b8a080e7          	jalr	-1142(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fa:	0485                	addi	s1,s1,1
    800006fc:	0004c503          	lbu	a0,0(s1)
    80000700:	f96d                	bnez	a0,800006f2 <printf+0x16a>
    80000702:	b705                	j	80000622 <printf+0x9a>
        s = "(null)";
    80000704:	00008497          	auipc	s1,0x8
    80000708:	91c48493          	addi	s1,s1,-1764 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070c:	02800513          	li	a0,40
    80000710:	b7cd                	j	800006f2 <printf+0x16a>
      consputc('%');
    80000712:	8556                	mv	a0,s5
    80000714:	00000097          	auipc	ra,0x0
    80000718:	b68080e7          	jalr	-1176(ra) # 8000027c <consputc>
      break;
    8000071c:	b719                	j	80000622 <printf+0x9a>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b5c080e7          	jalr	-1188(ra) # 8000027c <consputc>
      consputc(c);
    80000728:	8526                	mv	a0,s1
    8000072a:	00000097          	auipc	ra,0x0
    8000072e:	b52080e7          	jalr	-1198(ra) # 8000027c <consputc>
      break;
    80000732:	bdc5                	j	80000622 <printf+0x9a>
  if(locking)
    80000734:	020d9163          	bnez	s11,80000756 <printf+0x1ce>
}
    80000738:	70e6                	ld	ra,120(sp)
    8000073a:	7446                	ld	s0,112(sp)
    8000073c:	74a6                	ld	s1,104(sp)
    8000073e:	7906                	ld	s2,96(sp)
    80000740:	69e6                	ld	s3,88(sp)
    80000742:	6a46                	ld	s4,80(sp)
    80000744:	6aa6                	ld	s5,72(sp)
    80000746:	6b06                	ld	s6,64(sp)
    80000748:	7be2                	ld	s7,56(sp)
    8000074a:	7c42                	ld	s8,48(sp)
    8000074c:	7ca2                	ld	s9,40(sp)
    8000074e:	7d02                	ld	s10,32(sp)
    80000750:	6de2                	ld	s11,24(sp)
    80000752:	6129                	addi	sp,sp,192
    80000754:	8082                	ret
    release(&pr.lock);
    80000756:	00010517          	auipc	a0,0x10
    8000075a:	3a250513          	addi	a0,a0,930 # 80010af8 <pr>
    8000075e:	00000097          	auipc	ra,0x0
    80000762:	52c080e7          	jalr	1324(ra) # 80000c8a <release>
}
    80000766:	bfc9                	j	80000738 <printf+0x1b0>

0000000080000768 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000768:	1101                	addi	sp,sp,-32
    8000076a:	ec06                	sd	ra,24(sp)
    8000076c:	e822                	sd	s0,16(sp)
    8000076e:	e426                	sd	s1,8(sp)
    80000770:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000772:	00010497          	auipc	s1,0x10
    80000776:	38648493          	addi	s1,s1,902 # 80010af8 <pr>
    8000077a:	00008597          	auipc	a1,0x8
    8000077e:	8be58593          	addi	a1,a1,-1858 # 80008038 <etext+0x38>
    80000782:	8526                	mv	a0,s1
    80000784:	00000097          	auipc	ra,0x0
    80000788:	3c2080e7          	jalr	962(ra) # 80000b46 <initlock>
  pr.locking = 1;
    8000078c:	4785                	li	a5,1
    8000078e:	cc9c                	sw	a5,24(s1)
}
    80000790:	60e2                	ld	ra,24(sp)
    80000792:	6442                	ld	s0,16(sp)
    80000794:	64a2                	ld	s1,8(sp)
    80000796:	6105                	addi	sp,sp,32
    80000798:	8082                	ret

000000008000079a <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079a:	1141                	addi	sp,sp,-16
    8000079c:	e406                	sd	ra,8(sp)
    8000079e:	e022                	sd	s0,0(sp)
    800007a0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a2:	100007b7          	lui	a5,0x10000
    800007a6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007aa:	f8000713          	li	a4,-128
    800007ae:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b2:	470d                	li	a4,3
    800007b4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007bc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c0:	469d                	li	a3,7
    800007c2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c6:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007ca:	00008597          	auipc	a1,0x8
    800007ce:	88e58593          	addi	a1,a1,-1906 # 80008058 <digits+0x18>
    800007d2:	00010517          	auipc	a0,0x10
    800007d6:	34650513          	addi	a0,a0,838 # 80010b18 <uart_tx_lock>
    800007da:	00000097          	auipc	ra,0x0
    800007de:	36c080e7          	jalr	876(ra) # 80000b46 <initlock>
}
    800007e2:	60a2                	ld	ra,8(sp)
    800007e4:	6402                	ld	s0,0(sp)
    800007e6:	0141                	addi	sp,sp,16
    800007e8:	8082                	ret

00000000800007ea <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ea:	1101                	addi	sp,sp,-32
    800007ec:	ec06                	sd	ra,24(sp)
    800007ee:	e822                	sd	s0,16(sp)
    800007f0:	e426                	sd	s1,8(sp)
    800007f2:	1000                	addi	s0,sp,32
    800007f4:	84aa                	mv	s1,a0
  push_off();
    800007f6:	00000097          	auipc	ra,0x0
    800007fa:	394080e7          	jalr	916(ra) # 80000b8a <push_off>

  if(panicked){
    800007fe:	00008797          	auipc	a5,0x8
    80000802:	0d27a783          	lw	a5,210(a5) # 800088d0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000806:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080a:	c391                	beqz	a5,8000080e <uartputc_sync+0x24>
    for(;;)
    8000080c:	a001                	j	8000080c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000812:	0207f793          	andi	a5,a5,32
    80000816:	dfe5                	beqz	a5,8000080e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000818:	0ff4f513          	andi	a0,s1,255
    8000081c:	100007b7          	lui	a5,0x10000
    80000820:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000824:	00000097          	auipc	ra,0x0
    80000828:	406080e7          	jalr	1030(ra) # 80000c2a <pop_off>
}
    8000082c:	60e2                	ld	ra,24(sp)
    8000082e:	6442                	ld	s0,16(sp)
    80000830:	64a2                	ld	s1,8(sp)
    80000832:	6105                	addi	sp,sp,32
    80000834:	8082                	ret

0000000080000836 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000836:	00008797          	auipc	a5,0x8
    8000083a:	0a27b783          	ld	a5,162(a5) # 800088d8 <uart_tx_r>
    8000083e:	00008717          	auipc	a4,0x8
    80000842:	0a273703          	ld	a4,162(a4) # 800088e0 <uart_tx_w>
    80000846:	06f70a63          	beq	a4,a5,800008ba <uartstart+0x84>
{
    8000084a:	7139                	addi	sp,sp,-64
    8000084c:	fc06                	sd	ra,56(sp)
    8000084e:	f822                	sd	s0,48(sp)
    80000850:	f426                	sd	s1,40(sp)
    80000852:	f04a                	sd	s2,32(sp)
    80000854:	ec4e                	sd	s3,24(sp)
    80000856:	e852                	sd	s4,16(sp)
    80000858:	e456                	sd	s5,8(sp)
    8000085a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000860:	00010a17          	auipc	s4,0x10
    80000864:	2b8a0a13          	addi	s4,s4,696 # 80010b18 <uart_tx_lock>
    uart_tx_r += 1;
    80000868:	00008497          	auipc	s1,0x8
    8000086c:	07048493          	addi	s1,s1,112 # 800088d8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000870:	00008997          	auipc	s3,0x8
    80000874:	07098993          	addi	s3,s3,112 # 800088e0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000878:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087c:	02077713          	andi	a4,a4,32
    80000880:	c705                	beqz	a4,800008a8 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000882:	01f7f713          	andi	a4,a5,31
    80000886:	9752                	add	a4,a4,s4
    80000888:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088c:	0785                	addi	a5,a5,1
    8000088e:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000890:	8526                	mv	a0,s1
    80000892:	00002097          	auipc	ra,0x2
    80000896:	ae4080e7          	jalr	-1308(ra) # 80002376 <wakeup>
    
    WriteReg(THR, c);
    8000089a:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089e:	609c                	ld	a5,0(s1)
    800008a0:	0009b703          	ld	a4,0(s3)
    800008a4:	fcf71ae3          	bne	a4,a5,80000878 <uartstart+0x42>
  }
}
    800008a8:	70e2                	ld	ra,56(sp)
    800008aa:	7442                	ld	s0,48(sp)
    800008ac:	74a2                	ld	s1,40(sp)
    800008ae:	7902                	ld	s2,32(sp)
    800008b0:	69e2                	ld	s3,24(sp)
    800008b2:	6a42                	ld	s4,16(sp)
    800008b4:	6aa2                	ld	s5,8(sp)
    800008b6:	6121                	addi	sp,sp,64
    800008b8:	8082                	ret
    800008ba:	8082                	ret

00000000800008bc <uartputc>:
{
    800008bc:	7179                	addi	sp,sp,-48
    800008be:	f406                	sd	ra,40(sp)
    800008c0:	f022                	sd	s0,32(sp)
    800008c2:	ec26                	sd	s1,24(sp)
    800008c4:	e84a                	sd	s2,16(sp)
    800008c6:	e44e                	sd	s3,8(sp)
    800008c8:	e052                	sd	s4,0(sp)
    800008ca:	1800                	addi	s0,sp,48
    800008cc:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ce:	00010517          	auipc	a0,0x10
    800008d2:	24a50513          	addi	a0,a0,586 # 80010b18 <uart_tx_lock>
    800008d6:	00000097          	auipc	ra,0x0
    800008da:	300080e7          	jalr	768(ra) # 80000bd6 <acquire>
  if(panicked){
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	ff27a783          	lw	a5,-14(a5) # 800088d0 <panicked>
    800008e6:	e7c9                	bnez	a5,80000970 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e8:	00008717          	auipc	a4,0x8
    800008ec:	ff873703          	ld	a4,-8(a4) # 800088e0 <uart_tx_w>
    800008f0:	00008797          	auipc	a5,0x8
    800008f4:	fe87b783          	ld	a5,-24(a5) # 800088d8 <uart_tx_r>
    800008f8:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fc:	00010997          	auipc	s3,0x10
    80000900:	21c98993          	addi	s3,s3,540 # 80010b18 <uart_tx_lock>
    80000904:	00008497          	auipc	s1,0x8
    80000908:	fd448493          	addi	s1,s1,-44 # 800088d8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090c:	00008917          	auipc	s2,0x8
    80000910:	fd490913          	addi	s2,s2,-44 # 800088e0 <uart_tx_w>
    80000914:	00e79f63          	bne	a5,a4,80000932 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000918:	85ce                	mv	a1,s3
    8000091a:	8526                	mv	a0,s1
    8000091c:	00002097          	auipc	ra,0x2
    80000920:	9f6080e7          	jalr	-1546(ra) # 80002312 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000924:	00093703          	ld	a4,0(s2)
    80000928:	609c                	ld	a5,0(s1)
    8000092a:	02078793          	addi	a5,a5,32
    8000092e:	fee785e3          	beq	a5,a4,80000918 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000932:	00010497          	auipc	s1,0x10
    80000936:	1e648493          	addi	s1,s1,486 # 80010b18 <uart_tx_lock>
    8000093a:	01f77793          	andi	a5,a4,31
    8000093e:	97a6                	add	a5,a5,s1
    80000940:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000944:	0705                	addi	a4,a4,1
    80000946:	00008797          	auipc	a5,0x8
    8000094a:	f8e7bd23          	sd	a4,-102(a5) # 800088e0 <uart_tx_w>
  uartstart();
    8000094e:	00000097          	auipc	ra,0x0
    80000952:	ee8080e7          	jalr	-280(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    80000956:	8526                	mv	a0,s1
    80000958:	00000097          	auipc	ra,0x0
    8000095c:	332080e7          	jalr	818(ra) # 80000c8a <release>
}
    80000960:	70a2                	ld	ra,40(sp)
    80000962:	7402                	ld	s0,32(sp)
    80000964:	64e2                	ld	s1,24(sp)
    80000966:	6942                	ld	s2,16(sp)
    80000968:	69a2                	ld	s3,8(sp)
    8000096a:	6a02                	ld	s4,0(sp)
    8000096c:	6145                	addi	sp,sp,48
    8000096e:	8082                	ret
    for(;;)
    80000970:	a001                	j	80000970 <uartputc+0xb4>

0000000080000972 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000972:	1141                	addi	sp,sp,-16
    80000974:	e422                	sd	s0,8(sp)
    80000976:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000978:	100007b7          	lui	a5,0x10000
    8000097c:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000980:	8b85                	andi	a5,a5,1
    80000982:	cb91                	beqz	a5,80000996 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000984:	100007b7          	lui	a5,0x10000
    80000988:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000098c:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000990:	6422                	ld	s0,8(sp)
    80000992:	0141                	addi	sp,sp,16
    80000994:	8082                	ret
    return -1;
    80000996:	557d                	li	a0,-1
    80000998:	bfe5                	j	80000990 <uartgetc+0x1e>

000000008000099a <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    8000099a:	1101                	addi	sp,sp,-32
    8000099c:	ec06                	sd	ra,24(sp)
    8000099e:	e822                	sd	s0,16(sp)
    800009a0:	e426                	sd	s1,8(sp)
    800009a2:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a4:	54fd                	li	s1,-1
    800009a6:	a029                	j	800009b0 <uartintr+0x16>
      break;
    consoleintr(c);
    800009a8:	00000097          	auipc	ra,0x0
    800009ac:	916080e7          	jalr	-1770(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009b0:	00000097          	auipc	ra,0x0
    800009b4:	fc2080e7          	jalr	-62(ra) # 80000972 <uartgetc>
    if(c == -1)
    800009b8:	fe9518e3          	bne	a0,s1,800009a8 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009bc:	00010497          	auipc	s1,0x10
    800009c0:	15c48493          	addi	s1,s1,348 # 80010b18 <uart_tx_lock>
    800009c4:	8526                	mv	a0,s1
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	210080e7          	jalr	528(ra) # 80000bd6 <acquire>
  uartstart();
    800009ce:	00000097          	auipc	ra,0x0
    800009d2:	e68080e7          	jalr	-408(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    800009d6:	8526                	mv	a0,s1
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	2b2080e7          	jalr	690(ra) # 80000c8a <release>
}
    800009e0:	60e2                	ld	ra,24(sp)
    800009e2:	6442                	ld	s0,16(sp)
    800009e4:	64a2                	ld	s1,8(sp)
    800009e6:	6105                	addi	sp,sp,32
    800009e8:	8082                	ret

00000000800009ea <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009ea:	1101                	addi	sp,sp,-32
    800009ec:	ec06                	sd	ra,24(sp)
    800009ee:	e822                	sd	s0,16(sp)
    800009f0:	e426                	sd	s1,8(sp)
    800009f2:	e04a                	sd	s2,0(sp)
    800009f4:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f6:	03451793          	slli	a5,a0,0x34
    800009fa:	ebb9                	bnez	a5,80000a50 <kfree+0x66>
    800009fc:	84aa                	mv	s1,a0
    800009fe:	00021797          	auipc	a5,0x21
    80000a02:	38278793          	addi	a5,a5,898 # 80021d80 <end>
    80000a06:	04f56563          	bltu	a0,a5,80000a50 <kfree+0x66>
    80000a0a:	47c5                	li	a5,17
    80000a0c:	07ee                	slli	a5,a5,0x1b
    80000a0e:	04f57163          	bgeu	a0,a5,80000a50 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a12:	6605                	lui	a2,0x1
    80000a14:	4585                	li	a1,1
    80000a16:	00000097          	auipc	ra,0x0
    80000a1a:	2bc080e7          	jalr	700(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1e:	00010917          	auipc	s2,0x10
    80000a22:	13290913          	addi	s2,s2,306 # 80010b50 <kmem>
    80000a26:	854a                	mv	a0,s2
    80000a28:	00000097          	auipc	ra,0x0
    80000a2c:	1ae080e7          	jalr	430(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a30:	01893783          	ld	a5,24(s2)
    80000a34:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a36:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	24e080e7          	jalr	590(ra) # 80000c8a <release>
}
    80000a44:	60e2                	ld	ra,24(sp)
    80000a46:	6442                	ld	s0,16(sp)
    80000a48:	64a2                	ld	s1,8(sp)
    80000a4a:	6902                	ld	s2,0(sp)
    80000a4c:	6105                	addi	sp,sp,32
    80000a4e:	8082                	ret
    panic("kfree");
    80000a50:	00007517          	auipc	a0,0x7
    80000a54:	61050513          	addi	a0,a0,1552 # 80008060 <digits+0x20>
    80000a58:	00000097          	auipc	ra,0x0
    80000a5c:	ae6080e7          	jalr	-1306(ra) # 8000053e <panic>

0000000080000a60 <freerange>:
{
    80000a60:	7179                	addi	sp,sp,-48
    80000a62:	f406                	sd	ra,40(sp)
    80000a64:	f022                	sd	s0,32(sp)
    80000a66:	ec26                	sd	s1,24(sp)
    80000a68:	e84a                	sd	s2,16(sp)
    80000a6a:	e44e                	sd	s3,8(sp)
    80000a6c:	e052                	sd	s4,0(sp)
    80000a6e:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a70:	6785                	lui	a5,0x1
    80000a72:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a76:	94aa                	add	s1,s1,a0
    80000a78:	757d                	lui	a0,0xfffff
    80000a7a:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3a>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5e080e7          	jalr	-162(ra) # 800009ea <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x28>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	09650513          	addi	a0,a0,150 # 80010b50 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00021517          	auipc	a0,0x21
    80000ad2:	2b250513          	addi	a0,a0,690 # 80021d80 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f8a080e7          	jalr	-118(ra) # 80000a60 <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	06048493          	addi	s1,s1,96 # 80010b50 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	04850513          	addi	a0,a0,72 # 80010b50 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	01c50513          	addi	a0,a0,28 # 80010b50 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	0de080e7          	jalr	222(ra) # 80001c4e <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	0ac080e7          	jalr	172(ra) # 80001c4e <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	0a0080e7          	jalr	160(ra) # 80001c4e <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	088080e7          	jalr	136(ra) # 80001c4e <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	048080e7          	jalr	72(ra) # 80001c4e <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	91c080e7          	jalr	-1764(ra) # 8000053e <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	01c080e7          	jalr	28(ra) # 80001c4e <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8cc080e7          	jalr	-1844(ra) # 8000053e <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8bc080e7          	jalr	-1860(ra) # 8000053e <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	874080e7          	jalr	-1932(ra) # 8000053e <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ca19                	beqz	a2,80000cee <memset+0x1c>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	1602                	slli	a2,a2,0x20
    80000cde:	9201                	srli	a2,a2,0x20
    80000ce0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce8:	0785                	addi	a5,a5,1
    80000cea:	fee79de3          	bne	a5,a4,80000ce4 <memset+0x12>
  }
  return dst;
}
    80000cee:	6422                	ld	s0,8(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfa:	ca05                	beqz	a2,80000d2a <memcmp+0x36>
    80000cfc:	fff6069b          	addiw	a3,a2,-1
    80000d00:	1682                	slli	a3,a3,0x20
    80000d02:	9281                	srli	a3,a3,0x20
    80000d04:	0685                	addi	a3,a3,1
    80000d06:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d08:	00054783          	lbu	a5,0(a0)
    80000d0c:	0005c703          	lbu	a4,0(a1)
    80000d10:	00e79863          	bne	a5,a4,80000d20 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d14:	0505                	addi	a0,a0,1
    80000d16:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d18:	fed518e3          	bne	a0,a3,80000d08 <memcmp+0x14>
  }

  return 0;
    80000d1c:	4501                	li	a0,0
    80000d1e:	a019                	j	80000d24 <memcmp+0x30>
      return *s1 - *s2;
    80000d20:	40e7853b          	subw	a0,a5,a4
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  return 0;
    80000d2a:	4501                	li	a0,0
    80000d2c:	bfe5                	j	80000d24 <memcmp+0x30>

0000000080000d2e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d34:	c205                	beqz	a2,80000d54 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d36:	02a5e263          	bltu	a1,a0,80000d5a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d3a:	1602                	slli	a2,a2,0x20
    80000d3c:	9201                	srli	a2,a2,0x20
    80000d3e:	00c587b3          	add	a5,a1,a2
{
    80000d42:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d44:	0585                	addi	a1,a1,1
    80000d46:	0705                	addi	a4,a4,1
    80000d48:	fff5c683          	lbu	a3,-1(a1)
    80000d4c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d50:	fef59ae3          	bne	a1,a5,80000d44 <memmove+0x16>

  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  if(s < d && s + n > d){
    80000d5a:	02061693          	slli	a3,a2,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	00d58733          	add	a4,a1,a3
    80000d64:	fce57be3          	bgeu	a0,a4,80000d3a <memmove+0xc>
    d += n;
    80000d68:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d6a:	fff6079b          	addiw	a5,a2,-1
    80000d6e:	1782                	slli	a5,a5,0x20
    80000d70:	9381                	srli	a5,a5,0x20
    80000d72:	fff7c793          	not	a5,a5
    80000d76:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d78:	177d                	addi	a4,a4,-1
    80000d7a:	16fd                	addi	a3,a3,-1
    80000d7c:	00074603          	lbu	a2,0(a4)
    80000d80:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d84:	fee79ae3          	bne	a5,a4,80000d78 <memmove+0x4a>
    80000d88:	b7f1                	j	80000d54 <memmove+0x26>

0000000080000d8a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e406                	sd	ra,8(sp)
    80000d8e:	e022                	sd	s0,0(sp)
    80000d90:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f9c080e7          	jalr	-100(ra) # 80000d2e <memmove>
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret

0000000080000da2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e422                	sd	s0,8(sp)
    80000da6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da8:	ce11                	beqz	a2,80000dc4 <strncmp+0x22>
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <strncmp+0x26>
    80000db0:	0005c703          	lbu	a4,0(a1)
    80000db4:	00f71a63          	bne	a4,a5,80000dc8 <strncmp+0x26>
    n--, p++, q++;
    80000db8:	367d                	addiw	a2,a2,-1
    80000dba:	0505                	addi	a0,a0,1
    80000dbc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dbe:	f675                	bnez	a2,80000daa <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc0:	4501                	li	a0,0
    80000dc2:	a809                	j	80000dd4 <strncmp+0x32>
    80000dc4:	4501                	li	a0,0
    80000dc6:	a039                	j	80000dd4 <strncmp+0x32>
  if(n == 0)
    80000dc8:	ca09                	beqz	a2,80000dda <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dca:	00054503          	lbu	a0,0(a0)
    80000dce:	0005c783          	lbu	a5,0(a1)
    80000dd2:	9d1d                	subw	a0,a0,a5
}
    80000dd4:	6422                	ld	s0,8(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret
    return 0;
    80000dda:	4501                	li	a0,0
    80000ddc:	bfe5                	j	80000dd4 <strncmp+0x32>

0000000080000dde <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e422                	sd	s0,8(sp)
    80000de2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de4:	872a                	mv	a4,a0
    80000de6:	8832                	mv	a6,a2
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	01005963          	blez	a6,80000dfc <strncpy+0x1e>
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	0005c783          	lbu	a5,0(a1)
    80000df4:	fef70fa3          	sb	a5,-1(a4)
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	f7f5                	bnez	a5,80000de6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dfc:	86ba                	mv	a3,a4
    80000dfe:	00c05c63          	blez	a2,80000e16 <strncpy+0x38>
    *s++ = 0;
    80000e02:	0685                	addi	a3,a3,1
    80000e04:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e08:	fff6c793          	not	a5,a3
    80000e0c:	9fb9                	addw	a5,a5,a4
    80000e0e:	010787bb          	addw	a5,a5,a6
    80000e12:	fef048e3          	bgtz	a5,80000e02 <strncpy+0x24>
  return os;
}
    80000e16:	6422                	ld	s0,8(sp)
    80000e18:	0141                	addi	sp,sp,16
    80000e1a:	8082                	ret

0000000080000e1c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e22:	02c05363          	blez	a2,80000e48 <safestrcpy+0x2c>
    80000e26:	fff6069b          	addiw	a3,a2,-1
    80000e2a:	1682                	slli	a3,a3,0x20
    80000e2c:	9281                	srli	a3,a3,0x20
    80000e2e:	96ae                	add	a3,a3,a1
    80000e30:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e32:	00d58963          	beq	a1,a3,80000e44 <safestrcpy+0x28>
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	0785                	addi	a5,a5,1
    80000e3a:	fff5c703          	lbu	a4,-1(a1)
    80000e3e:	fee78fa3          	sb	a4,-1(a5)
    80000e42:	fb65                	bnez	a4,80000e32 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e44:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <strlen>:

int
strlen(const char *s)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf91                	beqz	a5,80000e74 <strlen+0x26>
    80000e5a:	0505                	addi	a0,a0,1
    80000e5c:	87aa                	mv	a5,a0
    80000e5e:	4685                	li	a3,1
    80000e60:	9e89                	subw	a3,a3,a0
    80000e62:	00f6853b          	addw	a0,a3,a5
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff7c703          	lbu	a4,-1(a5)
    80000e6c:	fb7d                	bnez	a4,80000e62 <strlen+0x14>
    ;
  return n;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e74:	4501                	li	a0,0
    80000e76:	bfe5                	j	80000e6e <strlen+0x20>

0000000080000e78 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e406                	sd	ra,8(sp)
    80000e7c:	e022                	sd	s0,0(sp)
    80000e7e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e80:	00001097          	auipc	ra,0x1
    80000e84:	dbe080e7          	jalr	-578(ra) # 80001c3e <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	a6070713          	addi	a4,a4,-1440 # 800088e8 <started>
  if(cpuid() == 0){
    80000e90:	c139                	beqz	a0,80000ed6 <main+0x5e>
    while(started == 0)
    80000e92:	431c                	lw	a5,0(a4)
    80000e94:	2781                	sext.w	a5,a5
    80000e96:	dff5                	beqz	a5,80000e92 <main+0x1a>
      ;
    __sync_synchronize();
    80000e98:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	da2080e7          	jalr	-606(ra) # 80001c3e <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	21250513          	addi	a0,a0,530 # 800080b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6da080e7          	jalr	1754(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0d8080e7          	jalr	216(ra) # 80000f8e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00002097          	auipc	ra,0x2
    80000ec2:	a62080e7          	jalr	-1438(ra) # 80002920 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	11a080e7          	jalr	282(ra) # 80005fe0 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	292080e7          	jalr	658(ra) # 80002160 <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88a080e7          	jalr	-1910(ra) # 80000768 <printfinit>
    printf("\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	1e250513          	addi	a0,a0,482 # 800080c8 <digits+0x88>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69a080e7          	jalr	1690(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68a080e7          	jalr	1674(ra) # 80000588 <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	1c250513          	addi	a0,a0,450 # 800080c8 <digits+0x88>
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	67a080e7          	jalr	1658(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	b94080e7          	jalr	-1132(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	326080e7          	jalr	806(ra) # 80001244 <kvminit>
    kvminithart();   // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	068080e7          	jalr	104(ra) # 80000f8e <kvminithart>
    procinit();      // process table
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	c5c080e7          	jalr	-932(ra) # 80001b8a <procinit>
    trapinit();      // trap vectors
    80000f36:	00002097          	auipc	ra,0x2
    80000f3a:	9c2080e7          	jalr	-1598(ra) # 800028f8 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	9e2080e7          	jalr	-1566(ra) # 80002920 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	084080e7          	jalr	132(ra) # 80005fca <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	092080e7          	jalr	146(ra) # 80005fe0 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	234080e7          	jalr	564(ra) # 8000318a <binit>
    iinit();         // inode table
    80000f5e:	00003097          	auipc	ra,0x3
    80000f62:	8d8080e7          	jalr	-1832(ra) # 80003836 <iinit>
    fileinit();      // file table
    80000f66:	00004097          	auipc	ra,0x4
    80000f6a:	876080e7          	jalr	-1930(ra) # 800047dc <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	17a080e7          	jalr	378(ra) # 800060e8 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	fcc080e7          	jalr	-52(ra) # 80001f42 <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	96f72223          	sw	a5,-1692(a4) # 800088e8 <started>
    80000f8c:	b789                	j	80000ece <main+0x56>

0000000080000f8e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f8e:	1141                	addi	sp,sp,-16
    80000f90:	e422                	sd	s0,8(sp)
    80000f92:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f94:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f98:	00008797          	auipc	a5,0x8
    80000f9c:	9587b783          	ld	a5,-1704(a5) # 800088f0 <kernel_pagetable>
    80000fa0:	83b1                	srli	a5,a5,0xc
    80000fa2:	577d                	li	a4,-1
    80000fa4:	177e                	slli	a4,a4,0x3f
    80000fa6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fac:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fb0:	6422                	ld	s0,8(sp)
    80000fb2:	0141                	addi	sp,sp,16
    80000fb4:	8082                	ret

0000000080000fb6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb6:	7139                	addi	sp,sp,-64
    80000fb8:	fc06                	sd	ra,56(sp)
    80000fba:	f822                	sd	s0,48(sp)
    80000fbc:	f426                	sd	s1,40(sp)
    80000fbe:	f04a                	sd	s2,32(sp)
    80000fc0:	ec4e                	sd	s3,24(sp)
    80000fc2:	e852                	sd	s4,16(sp)
    80000fc4:	e456                	sd	s5,8(sp)
    80000fc6:	e05a                	sd	s6,0(sp)
    80000fc8:	0080                	addi	s0,sp,64
    80000fca:	84aa                	mv	s1,a0
    80000fcc:	89ae                	mv	s3,a1
    80000fce:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd0:	57fd                	li	a5,-1
    80000fd2:	83e9                	srli	a5,a5,0x1a
    80000fd4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd8:	04b7f263          	bgeu	a5,a1,8000101c <walk+0x66>
    panic("walk");
    80000fdc:	00007517          	auipc	a0,0x7
    80000fe0:	0f450513          	addi	a0,a0,244 # 800080d0 <digits+0x90>
    80000fe4:	fffff097          	auipc	ra,0xfffff
    80000fe8:	55a080e7          	jalr	1370(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fec:	060a8663          	beqz	s5,80001058 <walk+0xa2>
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	af6080e7          	jalr	-1290(ra) # 80000ae6 <kalloc>
    80000ff8:	84aa                	mv	s1,a0
    80000ffa:	c529                	beqz	a0,80001044 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ffc:	6605                	lui	a2,0x1
    80000ffe:	4581                	li	a1,0
    80001000:	00000097          	auipc	ra,0x0
    80001004:	cd2080e7          	jalr	-814(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001008:	00c4d793          	srli	a5,s1,0xc
    8000100c:	07aa                	slli	a5,a5,0xa
    8000100e:	0017e793          	ori	a5,a5,1
    80001012:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001016:	3a5d                	addiw	s4,s4,-9
    80001018:	036a0063          	beq	s4,s6,80001038 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000101c:	0149d933          	srl	s2,s3,s4
    80001020:	1ff97913          	andi	s2,s2,511
    80001024:	090e                	slli	s2,s2,0x3
    80001026:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001028:	00093483          	ld	s1,0(s2)
    8000102c:	0014f793          	andi	a5,s1,1
    80001030:	dfd5                	beqz	a5,80000fec <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001032:	80a9                	srli	s1,s1,0xa
    80001034:	04b2                	slli	s1,s1,0xc
    80001036:	b7c5                	j	80001016 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001038:	00c9d513          	srli	a0,s3,0xc
    8000103c:	1ff57513          	andi	a0,a0,511
    80001040:	050e                	slli	a0,a0,0x3
    80001042:	9526                	add	a0,a0,s1
}
    80001044:	70e2                	ld	ra,56(sp)
    80001046:	7442                	ld	s0,48(sp)
    80001048:	74a2                	ld	s1,40(sp)
    8000104a:	7902                	ld	s2,32(sp)
    8000104c:	69e2                	ld	s3,24(sp)
    8000104e:	6a42                	ld	s4,16(sp)
    80001050:	6aa2                	ld	s5,8(sp)
    80001052:	6b02                	ld	s6,0(sp)
    80001054:	6121                	addi	sp,sp,64
    80001056:	8082                	ret
        return 0;
    80001058:	4501                	li	a0,0
    8000105a:	b7ed                	j	80001044 <walk+0x8e>

000000008000105c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000105c:	57fd                	li	a5,-1
    8000105e:	83e9                	srli	a5,a5,0x1a
    80001060:	00b7f463          	bgeu	a5,a1,80001068 <walkaddr+0xc>
    return 0;
    80001064:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001066:	8082                	ret
{
    80001068:	1141                	addi	sp,sp,-16
    8000106a:	e406                	sd	ra,8(sp)
    8000106c:	e022                	sd	s0,0(sp)
    8000106e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001070:	4601                	li	a2,0
    80001072:	00000097          	auipc	ra,0x0
    80001076:	f44080e7          	jalr	-188(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000107a:	c105                	beqz	a0,8000109a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000107c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000107e:	0117f693          	andi	a3,a5,17
    80001082:	4745                	li	a4,17
    return 0;
    80001084:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001086:	00e68663          	beq	a3,a4,80001092 <walkaddr+0x36>
}
    8000108a:	60a2                	ld	ra,8(sp)
    8000108c:	6402                	ld	s0,0(sp)
    8000108e:	0141                	addi	sp,sp,16
    80001090:	8082                	ret
  pa = PTE2PA(*pte);
    80001092:	00a7d513          	srli	a0,a5,0xa
    80001096:	0532                	slli	a0,a0,0xc
  return pa;
    80001098:	bfcd                	j	8000108a <walkaddr+0x2e>
    return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7fd                	j	8000108a <walkaddr+0x2e>

000000008000109e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000109e:	715d                	addi	sp,sp,-80
    800010a0:	e486                	sd	ra,72(sp)
    800010a2:	e0a2                	sd	s0,64(sp)
    800010a4:	fc26                	sd	s1,56(sp)
    800010a6:	f84a                	sd	s2,48(sp)
    800010a8:	f44e                	sd	s3,40(sp)
    800010aa:	f052                	sd	s4,32(sp)
    800010ac:	ec56                	sd	s5,24(sp)
    800010ae:	e85a                	sd	s6,16(sp)
    800010b0:	e45e                	sd	s7,8(sp)
    800010b2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010b4:	c639                	beqz	a2,80001102 <mappages+0x64>
    800010b6:	8aaa                	mv	s5,a0
    800010b8:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010ba:	77fd                	lui	a5,0xfffff
    800010bc:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010c0:	15fd                	addi	a1,a1,-1
    800010c2:	00c589b3          	add	s3,a1,a2
    800010c6:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010ca:	8952                	mv	s2,s4
    800010cc:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d0:	6b85                	lui	s7,0x1
    800010d2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d6:	4605                	li	a2,1
    800010d8:	85ca                	mv	a1,s2
    800010da:	8556                	mv	a0,s5
    800010dc:	00000097          	auipc	ra,0x0
    800010e0:	eda080e7          	jalr	-294(ra) # 80000fb6 <walk>
    800010e4:	cd1d                	beqz	a0,80001122 <mappages+0x84>
    if(*pte & PTE_V)
    800010e6:	611c                	ld	a5,0(a0)
    800010e8:	8b85                	andi	a5,a5,1
    800010ea:	e785                	bnez	a5,80001112 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010ec:	80b1                	srli	s1,s1,0xc
    800010ee:	04aa                	slli	s1,s1,0xa
    800010f0:	0164e4b3          	or	s1,s1,s6
    800010f4:	0014e493          	ori	s1,s1,1
    800010f8:	e104                	sd	s1,0(a0)
    if(a == last)
    800010fa:	05390063          	beq	s2,s3,8000113a <mappages+0x9c>
    a += PGSIZE;
    800010fe:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001100:	bfc9                	j	800010d2 <mappages+0x34>
    panic("mappages: size");
    80001102:	00007517          	auipc	a0,0x7
    80001106:	fd650513          	addi	a0,a0,-42 # 800080d8 <digits+0x98>
    8000110a:	fffff097          	auipc	ra,0xfffff
    8000110e:	434080e7          	jalr	1076(ra) # 8000053e <panic>
      panic("mappages: remap");
    80001112:	00007517          	auipc	a0,0x7
    80001116:	fd650513          	addi	a0,a0,-42 # 800080e8 <digits+0xa8>
    8000111a:	fffff097          	auipc	ra,0xfffff
    8000111e:	424080e7          	jalr	1060(ra) # 8000053e <panic>
      return -1;
    80001122:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001124:	60a6                	ld	ra,72(sp)
    80001126:	6406                	ld	s0,64(sp)
    80001128:	74e2                	ld	s1,56(sp)
    8000112a:	7942                	ld	s2,48(sp)
    8000112c:	79a2                	ld	s3,40(sp)
    8000112e:	7a02                	ld	s4,32(sp)
    80001130:	6ae2                	ld	s5,24(sp)
    80001132:	6b42                	ld	s6,16(sp)
    80001134:	6ba2                	ld	s7,8(sp)
    80001136:	6161                	addi	sp,sp,80
    80001138:	8082                	ret
  return 0;
    8000113a:	4501                	li	a0,0
    8000113c:	b7e5                	j	80001124 <mappages+0x86>

000000008000113e <kvmmap>:
{
    8000113e:	1141                	addi	sp,sp,-16
    80001140:	e406                	sd	ra,8(sp)
    80001142:	e022                	sd	s0,0(sp)
    80001144:	0800                	addi	s0,sp,16
    80001146:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001148:	86b2                	mv	a3,a2
    8000114a:	863e                	mv	a2,a5
    8000114c:	00000097          	auipc	ra,0x0
    80001150:	f52080e7          	jalr	-174(ra) # 8000109e <mappages>
    80001154:	e509                	bnez	a0,8000115e <kvmmap+0x20>
}
    80001156:	60a2                	ld	ra,8(sp)
    80001158:	6402                	ld	s0,0(sp)
    8000115a:	0141                	addi	sp,sp,16
    8000115c:	8082                	ret
    panic("kvmmap");
    8000115e:	00007517          	auipc	a0,0x7
    80001162:	f9a50513          	addi	a0,a0,-102 # 800080f8 <digits+0xb8>
    80001166:	fffff097          	auipc	ra,0xfffff
    8000116a:	3d8080e7          	jalr	984(ra) # 8000053e <panic>

000000008000116e <kvmmake>:
{
    8000116e:	1101                	addi	sp,sp,-32
    80001170:	ec06                	sd	ra,24(sp)
    80001172:	e822                	sd	s0,16(sp)
    80001174:	e426                	sd	s1,8(sp)
    80001176:	e04a                	sd	s2,0(sp)
    80001178:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	96c080e7          	jalr	-1684(ra) # 80000ae6 <kalloc>
    80001182:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001184:	6605                	lui	a2,0x1
    80001186:	4581                	li	a1,0
    80001188:	00000097          	auipc	ra,0x0
    8000118c:	b4a080e7          	jalr	-1206(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001190:	4719                	li	a4,6
    80001192:	6685                	lui	a3,0x1
    80001194:	10000637          	lui	a2,0x10000
    80001198:	100005b7          	lui	a1,0x10000
    8000119c:	8526                	mv	a0,s1
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	fa0080e7          	jalr	-96(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a6:	4719                	li	a4,6
    800011a8:	6685                	lui	a3,0x1
    800011aa:	10001637          	lui	a2,0x10001
    800011ae:	100015b7          	lui	a1,0x10001
    800011b2:	8526                	mv	a0,s1
    800011b4:	00000097          	auipc	ra,0x0
    800011b8:	f8a080e7          	jalr	-118(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011bc:	4719                	li	a4,6
    800011be:	004006b7          	lui	a3,0x400
    800011c2:	0c000637          	lui	a2,0xc000
    800011c6:	0c0005b7          	lui	a1,0xc000
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f72080e7          	jalr	-142(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011d4:	00007917          	auipc	s2,0x7
    800011d8:	e2c90913          	addi	s2,s2,-468 # 80008000 <etext>
    800011dc:	4729                	li	a4,10
    800011de:	80007697          	auipc	a3,0x80007
    800011e2:	e2268693          	addi	a3,a3,-478 # 8000 <_entry-0x7fff8000>
    800011e6:	4605                	li	a2,1
    800011e8:	067e                	slli	a2,a2,0x1f
    800011ea:	85b2                	mv	a1,a2
    800011ec:	8526                	mv	a0,s1
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	f50080e7          	jalr	-176(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f6:	4719                	li	a4,6
    800011f8:	46c5                	li	a3,17
    800011fa:	06ee                	slli	a3,a3,0x1b
    800011fc:	412686b3          	sub	a3,a3,s2
    80001200:	864a                	mv	a2,s2
    80001202:	85ca                	mv	a1,s2
    80001204:	8526                	mv	a0,s1
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	f38080e7          	jalr	-200(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000120e:	4729                	li	a4,10
    80001210:	6685                	lui	a3,0x1
    80001212:	00006617          	auipc	a2,0x6
    80001216:	dee60613          	addi	a2,a2,-530 # 80007000 <_trampoline>
    8000121a:	040005b7          	lui	a1,0x4000
    8000121e:	15fd                	addi	a1,a1,-1
    80001220:	05b2                	slli	a1,a1,0xc
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f1a080e7          	jalr	-230(ra) # 8000113e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000122c:	8526                	mv	a0,s1
    8000122e:	00001097          	auipc	ra,0x1
    80001232:	8c6080e7          	jalr	-1850(ra) # 80001af4 <proc_mapstacks>
}
    80001236:	8526                	mv	a0,s1
    80001238:	60e2                	ld	ra,24(sp)
    8000123a:	6442                	ld	s0,16(sp)
    8000123c:	64a2                	ld	s1,8(sp)
    8000123e:	6902                	ld	s2,0(sp)
    80001240:	6105                	addi	sp,sp,32
    80001242:	8082                	ret

0000000080001244 <kvminit>:
{
    80001244:	1141                	addi	sp,sp,-16
    80001246:	e406                	sd	ra,8(sp)
    80001248:	e022                	sd	s0,0(sp)
    8000124a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	f22080e7          	jalr	-222(ra) # 8000116e <kvmmake>
    80001254:	00007797          	auipc	a5,0x7
    80001258:	68a7be23          	sd	a0,1692(a5) # 800088f0 <kernel_pagetable>
}
    8000125c:	60a2                	ld	ra,8(sp)
    8000125e:	6402                	ld	s0,0(sp)
    80001260:	0141                	addi	sp,sp,16
    80001262:	8082                	ret

0000000080001264 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001264:	715d                	addi	sp,sp,-80
    80001266:	e486                	sd	ra,72(sp)
    80001268:	e0a2                	sd	s0,64(sp)
    8000126a:	fc26                	sd	s1,56(sp)
    8000126c:	f84a                	sd	s2,48(sp)
    8000126e:	f44e                	sd	s3,40(sp)
    80001270:	f052                	sd	s4,32(sp)
    80001272:	ec56                	sd	s5,24(sp)
    80001274:	e85a                	sd	s6,16(sp)
    80001276:	e45e                	sd	s7,8(sp)
    80001278:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000127a:	03459793          	slli	a5,a1,0x34
    8000127e:	e795                	bnez	a5,800012aa <uvmunmap+0x46>
    80001280:	8a2a                	mv	s4,a0
    80001282:	892e                	mv	s2,a1
    80001284:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001286:	0632                	slli	a2,a2,0xc
    80001288:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000128c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000128e:	6b05                	lui	s6,0x1
    80001290:	0735e963          	bltu	a1,s3,80001302 <uvmunmap+0x9e>
        kfree((void*)pa);
      }
    }
    *pte = 0;
  }
}
    80001294:	60a6                	ld	ra,72(sp)
    80001296:	6406                	ld	s0,64(sp)
    80001298:	74e2                	ld	s1,56(sp)
    8000129a:	7942                	ld	s2,48(sp)
    8000129c:	79a2                	ld	s3,40(sp)
    8000129e:	7a02                	ld	s4,32(sp)
    800012a0:	6ae2                	ld	s5,24(sp)
    800012a2:	6b42                	ld	s6,16(sp)
    800012a4:	6ba2                	ld	s7,8(sp)
    800012a6:	6161                	addi	sp,sp,80
    800012a8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012aa:	00007517          	auipc	a0,0x7
    800012ae:	e5650513          	addi	a0,a0,-426 # 80008100 <digits+0xc0>
    800012b2:	fffff097          	auipc	ra,0xfffff
    800012b6:	28c080e7          	jalr	652(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e5e50513          	addi	a0,a0,-418 # 80008118 <digits+0xd8>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	27c080e7          	jalr	636(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e5e50513          	addi	a0,a0,-418 # 80008128 <digits+0xe8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26c080e7          	jalr	620(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e6650513          	addi	a0,a0,-410 # 80008140 <digits+0x100>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	25c080e7          	jalr	604(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    800012ea:	83a9                	srli	a5,a5,0xa
        kfree((void*)pa);
    800012ec:	00c79513          	slli	a0,a5,0xc
    800012f0:	fffff097          	auipc	ra,0xfffff
    800012f4:	6fa080e7          	jalr	1786(ra) # 800009ea <kfree>
    *pte = 0;
    800012f8:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012fc:	995a                	add	s2,s2,s6
    800012fe:	f9397be3          	bgeu	s2,s3,80001294 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001302:	4601                	li	a2,0
    80001304:	85ca                	mv	a1,s2
    80001306:	8552                	mv	a0,s4
    80001308:	00000097          	auipc	ra,0x0
    8000130c:	cae080e7          	jalr	-850(ra) # 80000fb6 <walk>
    80001310:	84aa                	mv	s1,a0
    80001312:	d545                	beqz	a0,800012ba <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001314:	611c                	ld	a5,0(a0)
    80001316:	0017f713          	andi	a4,a5,1
    8000131a:	db45                	beqz	a4,800012ca <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000131c:	3ff7f713          	andi	a4,a5,1023
    80001320:	fb770de3          	beq	a4,s7,800012da <uvmunmap+0x76>
    if(do_free){
    80001324:	fc0a8ae3          	beqz	s5,800012f8 <uvmunmap+0x94>
      if((*pte & PTE_S) == 0) {
    80001328:	1007f713          	andi	a4,a5,256
    8000132c:	f771                	bnez	a4,800012f8 <uvmunmap+0x94>
    8000132e:	bf75                	j	800012ea <uvmunmap+0x86>

0000000080001330 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001330:	1101                	addi	sp,sp,-32
    80001332:	ec06                	sd	ra,24(sp)
    80001334:	e822                	sd	s0,16(sp)
    80001336:	e426                	sd	s1,8(sp)
    80001338:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000133a:	fffff097          	auipc	ra,0xfffff
    8000133e:	7ac080e7          	jalr	1964(ra) # 80000ae6 <kalloc>
    80001342:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001344:	c519                	beqz	a0,80001352 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001346:	6605                	lui	a2,0x1
    80001348:	4581                	li	a1,0
    8000134a:	00000097          	auipc	ra,0x0
    8000134e:	988080e7          	jalr	-1656(ra) # 80000cd2 <memset>
  return pagetable;
}
    80001352:	8526                	mv	a0,s1
    80001354:	60e2                	ld	ra,24(sp)
    80001356:	6442                	ld	s0,16(sp)
    80001358:	64a2                	ld	s1,8(sp)
    8000135a:	6105                	addi	sp,sp,32
    8000135c:	8082                	ret

000000008000135e <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    8000135e:	7179                	addi	sp,sp,-48
    80001360:	f406                	sd	ra,40(sp)
    80001362:	f022                	sd	s0,32(sp)
    80001364:	ec26                	sd	s1,24(sp)
    80001366:	e84a                	sd	s2,16(sp)
    80001368:	e44e                	sd	s3,8(sp)
    8000136a:	e052                	sd	s4,0(sp)
    8000136c:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000136e:	6785                	lui	a5,0x1
    80001370:	04f67863          	bgeu	a2,a5,800013c0 <uvmfirst+0x62>
    80001374:	8a2a                	mv	s4,a0
    80001376:	89ae                	mv	s3,a1
    80001378:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    8000137a:	fffff097          	auipc	ra,0xfffff
    8000137e:	76c080e7          	jalr	1900(ra) # 80000ae6 <kalloc>
    80001382:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001384:	6605                	lui	a2,0x1
    80001386:	4581                	li	a1,0
    80001388:	00000097          	auipc	ra,0x0
    8000138c:	94a080e7          	jalr	-1718(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001390:	4779                	li	a4,30
    80001392:	86ca                	mv	a3,s2
    80001394:	6605                	lui	a2,0x1
    80001396:	4581                	li	a1,0
    80001398:	8552                	mv	a0,s4
    8000139a:	00000097          	auipc	ra,0x0
    8000139e:	d04080e7          	jalr	-764(ra) # 8000109e <mappages>
  memmove(mem, src, sz);
    800013a2:	8626                	mv	a2,s1
    800013a4:	85ce                	mv	a1,s3
    800013a6:	854a                	mv	a0,s2
    800013a8:	00000097          	auipc	ra,0x0
    800013ac:	986080e7          	jalr	-1658(ra) # 80000d2e <memmove>
}
    800013b0:	70a2                	ld	ra,40(sp)
    800013b2:	7402                	ld	s0,32(sp)
    800013b4:	64e2                	ld	s1,24(sp)
    800013b6:	6942                	ld	s2,16(sp)
    800013b8:	69a2                	ld	s3,8(sp)
    800013ba:	6a02                	ld	s4,0(sp)
    800013bc:	6145                	addi	sp,sp,48
    800013be:	8082                	ret
    panic("uvmfirst: more than a page");
    800013c0:	00007517          	auipc	a0,0x7
    800013c4:	d9850513          	addi	a0,a0,-616 # 80008158 <digits+0x118>
    800013c8:	fffff097          	auipc	ra,0xfffff
    800013cc:	176080e7          	jalr	374(ra) # 8000053e <panic>

00000000800013d0 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013d0:	1101                	addi	sp,sp,-32
    800013d2:	ec06                	sd	ra,24(sp)
    800013d4:	e822                	sd	s0,16(sp)
    800013d6:	e426                	sd	s1,8(sp)
    800013d8:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013da:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013dc:	00b67d63          	bgeu	a2,a1,800013f6 <uvmdealloc+0x26>
    800013e0:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013e2:	6785                	lui	a5,0x1
    800013e4:	17fd                	addi	a5,a5,-1
    800013e6:	00f60733          	add	a4,a2,a5
    800013ea:	767d                	lui	a2,0xfffff
    800013ec:	8f71                	and	a4,a4,a2
    800013ee:	97ae                	add	a5,a5,a1
    800013f0:	8ff1                	and	a5,a5,a2
    800013f2:	00f76863          	bltu	a4,a5,80001402 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013f6:	8526                	mv	a0,s1
    800013f8:	60e2                	ld	ra,24(sp)
    800013fa:	6442                	ld	s0,16(sp)
    800013fc:	64a2                	ld	s1,8(sp)
    800013fe:	6105                	addi	sp,sp,32
    80001400:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001402:	8f99                	sub	a5,a5,a4
    80001404:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001406:	4685                	li	a3,1
    80001408:	0007861b          	sext.w	a2,a5
    8000140c:	85ba                	mv	a1,a4
    8000140e:	00000097          	auipc	ra,0x0
    80001412:	e56080e7          	jalr	-426(ra) # 80001264 <uvmunmap>
    80001416:	b7c5                	j	800013f6 <uvmdealloc+0x26>

0000000080001418 <uvmalloc>:
  if(newsz < oldsz)
    80001418:	0ab66563          	bltu	a2,a1,800014c2 <uvmalloc+0xaa>
{
    8000141c:	7139                	addi	sp,sp,-64
    8000141e:	fc06                	sd	ra,56(sp)
    80001420:	f822                	sd	s0,48(sp)
    80001422:	f426                	sd	s1,40(sp)
    80001424:	f04a                	sd	s2,32(sp)
    80001426:	ec4e                	sd	s3,24(sp)
    80001428:	e852                	sd	s4,16(sp)
    8000142a:	e456                	sd	s5,8(sp)
    8000142c:	e05a                	sd	s6,0(sp)
    8000142e:	0080                	addi	s0,sp,64
    80001430:	8aaa                	mv	s5,a0
    80001432:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001434:	6985                	lui	s3,0x1
    80001436:	19fd                	addi	s3,s3,-1
    80001438:	95ce                	add	a1,a1,s3
    8000143a:	79fd                	lui	s3,0xfffff
    8000143c:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001440:	08c9f363          	bgeu	s3,a2,800014c6 <uvmalloc+0xae>
    80001444:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001446:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    8000144a:	fffff097          	auipc	ra,0xfffff
    8000144e:	69c080e7          	jalr	1692(ra) # 80000ae6 <kalloc>
    80001452:	84aa                	mv	s1,a0
    if(mem == 0){
    80001454:	c51d                	beqz	a0,80001482 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    80001456:	6605                	lui	a2,0x1
    80001458:	4581                	li	a1,0
    8000145a:	00000097          	auipc	ra,0x0
    8000145e:	878080e7          	jalr	-1928(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001462:	875a                	mv	a4,s6
    80001464:	86a6                	mv	a3,s1
    80001466:	6605                	lui	a2,0x1
    80001468:	85ca                	mv	a1,s2
    8000146a:	8556                	mv	a0,s5
    8000146c:	00000097          	auipc	ra,0x0
    80001470:	c32080e7          	jalr	-974(ra) # 8000109e <mappages>
    80001474:	e90d                	bnez	a0,800014a6 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001476:	6785                	lui	a5,0x1
    80001478:	993e                	add	s2,s2,a5
    8000147a:	fd4968e3          	bltu	s2,s4,8000144a <uvmalloc+0x32>
  return newsz;
    8000147e:	8552                	mv	a0,s4
    80001480:	a809                	j	80001492 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    80001482:	864e                	mv	a2,s3
    80001484:	85ca                	mv	a1,s2
    80001486:	8556                	mv	a0,s5
    80001488:	00000097          	auipc	ra,0x0
    8000148c:	f48080e7          	jalr	-184(ra) # 800013d0 <uvmdealloc>
      return 0;
    80001490:	4501                	li	a0,0
}
    80001492:	70e2                	ld	ra,56(sp)
    80001494:	7442                	ld	s0,48(sp)
    80001496:	74a2                	ld	s1,40(sp)
    80001498:	7902                	ld	s2,32(sp)
    8000149a:	69e2                	ld	s3,24(sp)
    8000149c:	6a42                	ld	s4,16(sp)
    8000149e:	6aa2                	ld	s5,8(sp)
    800014a0:	6b02                	ld	s6,0(sp)
    800014a2:	6121                	addi	sp,sp,64
    800014a4:	8082                	ret
      kfree(mem);
    800014a6:	8526                	mv	a0,s1
    800014a8:	fffff097          	auipc	ra,0xfffff
    800014ac:	542080e7          	jalr	1346(ra) # 800009ea <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014b0:	864e                	mv	a2,s3
    800014b2:	85ca                	mv	a1,s2
    800014b4:	8556                	mv	a0,s5
    800014b6:	00000097          	auipc	ra,0x0
    800014ba:	f1a080e7          	jalr	-230(ra) # 800013d0 <uvmdealloc>
      return 0;
    800014be:	4501                	li	a0,0
    800014c0:	bfc9                	j	80001492 <uvmalloc+0x7a>
    return oldsz;
    800014c2:	852e                	mv	a0,a1
}
    800014c4:	8082                	ret
  return newsz;
    800014c6:	8532                	mv	a0,a2
    800014c8:	b7e9                	j	80001492 <uvmalloc+0x7a>

00000000800014ca <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014ca:	7179                	addi	sp,sp,-48
    800014cc:	f406                	sd	ra,40(sp)
    800014ce:	f022                	sd	s0,32(sp)
    800014d0:	ec26                	sd	s1,24(sp)
    800014d2:	e84a                	sd	s2,16(sp)
    800014d4:	e44e                	sd	s3,8(sp)
    800014d6:	e052                	sd	s4,0(sp)
    800014d8:	1800                	addi	s0,sp,48
    800014da:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014dc:	84aa                	mv	s1,a0
    800014de:	6905                	lui	s2,0x1
    800014e0:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e2:	4985                	li	s3,1
    800014e4:	a821                	j	800014fc <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014e6:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014e8:	0532                	slli	a0,a0,0xc
    800014ea:	00000097          	auipc	ra,0x0
    800014ee:	fe0080e7          	jalr	-32(ra) # 800014ca <freewalk>
      pagetable[i] = 0;
    800014f2:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f6:	04a1                	addi	s1,s1,8
    800014f8:	03248163          	beq	s1,s2,8000151a <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014fc:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014fe:	00f57793          	andi	a5,a0,15
    80001502:	ff3782e3          	beq	a5,s3,800014e6 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001506:	8905                	andi	a0,a0,1
    80001508:	d57d                	beqz	a0,800014f6 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000150a:	00007517          	auipc	a0,0x7
    8000150e:	c6e50513          	addi	a0,a0,-914 # 80008178 <digits+0x138>
    80001512:	fffff097          	auipc	ra,0xfffff
    80001516:	02c080e7          	jalr	44(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000151a:	8552                	mv	a0,s4
    8000151c:	fffff097          	auipc	ra,0xfffff
    80001520:	4ce080e7          	jalr	1230(ra) # 800009ea <kfree>
}
    80001524:	70a2                	ld	ra,40(sp)
    80001526:	7402                	ld	s0,32(sp)
    80001528:	64e2                	ld	s1,24(sp)
    8000152a:	6942                	ld	s2,16(sp)
    8000152c:	69a2                	ld	s3,8(sp)
    8000152e:	6a02                	ld	s4,0(sp)
    80001530:	6145                	addi	sp,sp,48
    80001532:	8082                	ret

0000000080001534 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001534:	1101                	addi	sp,sp,-32
    80001536:	ec06                	sd	ra,24(sp)
    80001538:	e822                	sd	s0,16(sp)
    8000153a:	e426                	sd	s1,8(sp)
    8000153c:	1000                	addi	s0,sp,32
    8000153e:	84aa                	mv	s1,a0
  if(sz > 0)
    80001540:	e999                	bnez	a1,80001556 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001542:	8526                	mv	a0,s1
    80001544:	00000097          	auipc	ra,0x0
    80001548:	f86080e7          	jalr	-122(ra) # 800014ca <freewalk>
}
    8000154c:	60e2                	ld	ra,24(sp)
    8000154e:	6442                	ld	s0,16(sp)
    80001550:	64a2                	ld	s1,8(sp)
    80001552:	6105                	addi	sp,sp,32
    80001554:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001556:	6605                	lui	a2,0x1
    80001558:	167d                	addi	a2,a2,-1
    8000155a:	962e                	add	a2,a2,a1
    8000155c:	4685                	li	a3,1
    8000155e:	8231                	srli	a2,a2,0xc
    80001560:	4581                	li	a1,0
    80001562:	00000097          	auipc	ra,0x0
    80001566:	d02080e7          	jalr	-766(ra) # 80001264 <uvmunmap>
    8000156a:	bfe1                	j	80001542 <uvmfree+0xe>

000000008000156c <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000156c:	c679                	beqz	a2,8000163a <uvmcopy+0xce>
{
    8000156e:	715d                	addi	sp,sp,-80
    80001570:	e486                	sd	ra,72(sp)
    80001572:	e0a2                	sd	s0,64(sp)
    80001574:	fc26                	sd	s1,56(sp)
    80001576:	f84a                	sd	s2,48(sp)
    80001578:	f44e                	sd	s3,40(sp)
    8000157a:	f052                	sd	s4,32(sp)
    8000157c:	ec56                	sd	s5,24(sp)
    8000157e:	e85a                	sd	s6,16(sp)
    80001580:	e45e                	sd	s7,8(sp)
    80001582:	0880                	addi	s0,sp,80
    80001584:	8b2a                	mv	s6,a0
    80001586:	8aae                	mv	s5,a1
    80001588:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000158a:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000158c:	4601                	li	a2,0
    8000158e:	85ce                	mv	a1,s3
    80001590:	855a                	mv	a0,s6
    80001592:	00000097          	auipc	ra,0x0
    80001596:	a24080e7          	jalr	-1500(ra) # 80000fb6 <walk>
    8000159a:	c531                	beqz	a0,800015e6 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000159c:	6118                	ld	a4,0(a0)
    8000159e:	00177793          	andi	a5,a4,1
    800015a2:	cbb1                	beqz	a5,800015f6 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a4:	00a75593          	srli	a1,a4,0xa
    800015a8:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015ac:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015b0:	fffff097          	auipc	ra,0xfffff
    800015b4:	536080e7          	jalr	1334(ra) # 80000ae6 <kalloc>
    800015b8:	892a                	mv	s2,a0
    800015ba:	c939                	beqz	a0,80001610 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015bc:	6605                	lui	a2,0x1
    800015be:	85de                	mv	a1,s7
    800015c0:	fffff097          	auipc	ra,0xfffff
    800015c4:	76e080e7          	jalr	1902(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015c8:	8726                	mv	a4,s1
    800015ca:	86ca                	mv	a3,s2
    800015cc:	6605                	lui	a2,0x1
    800015ce:	85ce                	mv	a1,s3
    800015d0:	8556                	mv	a0,s5
    800015d2:	00000097          	auipc	ra,0x0
    800015d6:	acc080e7          	jalr	-1332(ra) # 8000109e <mappages>
    800015da:	e515                	bnez	a0,80001606 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015dc:	6785                	lui	a5,0x1
    800015de:	99be                	add	s3,s3,a5
    800015e0:	fb49e6e3          	bltu	s3,s4,8000158c <uvmcopy+0x20>
    800015e4:	a081                	j	80001624 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e6:	00007517          	auipc	a0,0x7
    800015ea:	ba250513          	addi	a0,a0,-1118 # 80008188 <digits+0x148>
    800015ee:	fffff097          	auipc	ra,0xfffff
    800015f2:	f50080e7          	jalr	-176(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015f6:	00007517          	auipc	a0,0x7
    800015fa:	bb250513          	addi	a0,a0,-1102 # 800081a8 <digits+0x168>
    800015fe:	fffff097          	auipc	ra,0xfffff
    80001602:	f40080e7          	jalr	-192(ra) # 8000053e <panic>
      kfree(mem);
    80001606:	854a                	mv	a0,s2
    80001608:	fffff097          	auipc	ra,0xfffff
    8000160c:	3e2080e7          	jalr	994(ra) # 800009ea <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001610:	4685                	li	a3,1
    80001612:	00c9d613          	srli	a2,s3,0xc
    80001616:	4581                	li	a1,0
    80001618:	8556                	mv	a0,s5
    8000161a:	00000097          	auipc	ra,0x0
    8000161e:	c4a080e7          	jalr	-950(ra) # 80001264 <uvmunmap>
  return -1;
    80001622:	557d                	li	a0,-1
}
    80001624:	60a6                	ld	ra,72(sp)
    80001626:	6406                	ld	s0,64(sp)
    80001628:	74e2                	ld	s1,56(sp)
    8000162a:	7942                	ld	s2,48(sp)
    8000162c:	79a2                	ld	s3,40(sp)
    8000162e:	7a02                	ld	s4,32(sp)
    80001630:	6ae2                	ld	s5,24(sp)
    80001632:	6b42                	ld	s6,16(sp)
    80001634:	6ba2                	ld	s7,8(sp)
    80001636:	6161                	addi	sp,sp,80
    80001638:	8082                	ret
  return 0;
    8000163a:	4501                	li	a0,0
}
    8000163c:	8082                	ret

000000008000163e <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000163e:	1141                	addi	sp,sp,-16
    80001640:	e406                	sd	ra,8(sp)
    80001642:	e022                	sd	s0,0(sp)
    80001644:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001646:	4601                	li	a2,0
    80001648:	00000097          	auipc	ra,0x0
    8000164c:	96e080e7          	jalr	-1682(ra) # 80000fb6 <walk>
  if(pte == 0)
    80001650:	c901                	beqz	a0,80001660 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001652:	611c                	ld	a5,0(a0)
    80001654:	9bbd                	andi	a5,a5,-17
    80001656:	e11c                	sd	a5,0(a0)
}
    80001658:	60a2                	ld	ra,8(sp)
    8000165a:	6402                	ld	s0,0(sp)
    8000165c:	0141                	addi	sp,sp,16
    8000165e:	8082                	ret
    panic("uvmclear");
    80001660:	00007517          	auipc	a0,0x7
    80001664:	b6850513          	addi	a0,a0,-1176 # 800081c8 <digits+0x188>
    80001668:	fffff097          	auipc	ra,0xfffff
    8000166c:	ed6080e7          	jalr	-298(ra) # 8000053e <panic>

0000000080001670 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001670:	c6bd                	beqz	a3,800016de <copyout+0x6e>
{
    80001672:	715d                	addi	sp,sp,-80
    80001674:	e486                	sd	ra,72(sp)
    80001676:	e0a2                	sd	s0,64(sp)
    80001678:	fc26                	sd	s1,56(sp)
    8000167a:	f84a                	sd	s2,48(sp)
    8000167c:	f44e                	sd	s3,40(sp)
    8000167e:	f052                	sd	s4,32(sp)
    80001680:	ec56                	sd	s5,24(sp)
    80001682:	e85a                	sd	s6,16(sp)
    80001684:	e45e                	sd	s7,8(sp)
    80001686:	e062                	sd	s8,0(sp)
    80001688:	0880                	addi	s0,sp,80
    8000168a:	8b2a                	mv	s6,a0
    8000168c:	8c2e                	mv	s8,a1
    8000168e:	8a32                	mv	s4,a2
    80001690:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001692:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001694:	6a85                	lui	s5,0x1
    80001696:	a015                	j	800016ba <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001698:	9562                	add	a0,a0,s8
    8000169a:	0004861b          	sext.w	a2,s1
    8000169e:	85d2                	mv	a1,s4
    800016a0:	41250533          	sub	a0,a0,s2
    800016a4:	fffff097          	auipc	ra,0xfffff
    800016a8:	68a080e7          	jalr	1674(ra) # 80000d2e <memmove>

    len -= n;
    800016ac:	409989b3          	sub	s3,s3,s1
    src += n;
    800016b0:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016b2:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b6:	02098263          	beqz	s3,800016da <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016ba:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016be:	85ca                	mv	a1,s2
    800016c0:	855a                	mv	a0,s6
    800016c2:	00000097          	auipc	ra,0x0
    800016c6:	99a080e7          	jalr	-1638(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800016ca:	cd01                	beqz	a0,800016e2 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016cc:	418904b3          	sub	s1,s2,s8
    800016d0:	94d6                	add	s1,s1,s5
    if(n > len)
    800016d2:	fc99f3e3          	bgeu	s3,s1,80001698 <copyout+0x28>
    800016d6:	84ce                	mv	s1,s3
    800016d8:	b7c1                	j	80001698 <copyout+0x28>
  }
  return 0;
    800016da:	4501                	li	a0,0
    800016dc:	a021                	j	800016e4 <copyout+0x74>
    800016de:	4501                	li	a0,0
}
    800016e0:	8082                	ret
      return -1;
    800016e2:	557d                	li	a0,-1
}
    800016e4:	60a6                	ld	ra,72(sp)
    800016e6:	6406                	ld	s0,64(sp)
    800016e8:	74e2                	ld	s1,56(sp)
    800016ea:	7942                	ld	s2,48(sp)
    800016ec:	79a2                	ld	s3,40(sp)
    800016ee:	7a02                	ld	s4,32(sp)
    800016f0:	6ae2                	ld	s5,24(sp)
    800016f2:	6b42                	ld	s6,16(sp)
    800016f4:	6ba2                	ld	s7,8(sp)
    800016f6:	6c02                	ld	s8,0(sp)
    800016f8:	6161                	addi	sp,sp,80
    800016fa:	8082                	ret

00000000800016fc <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016fc:	caa5                	beqz	a3,8000176c <copyin+0x70>
{
    800016fe:	715d                	addi	sp,sp,-80
    80001700:	e486                	sd	ra,72(sp)
    80001702:	e0a2                	sd	s0,64(sp)
    80001704:	fc26                	sd	s1,56(sp)
    80001706:	f84a                	sd	s2,48(sp)
    80001708:	f44e                	sd	s3,40(sp)
    8000170a:	f052                	sd	s4,32(sp)
    8000170c:	ec56                	sd	s5,24(sp)
    8000170e:	e85a                	sd	s6,16(sp)
    80001710:	e45e                	sd	s7,8(sp)
    80001712:	e062                	sd	s8,0(sp)
    80001714:	0880                	addi	s0,sp,80
    80001716:	8b2a                	mv	s6,a0
    80001718:	8a2e                	mv	s4,a1
    8000171a:	8c32                	mv	s8,a2
    8000171c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000171e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001720:	6a85                	lui	s5,0x1
    80001722:	a01d                	j	80001748 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001724:	018505b3          	add	a1,a0,s8
    80001728:	0004861b          	sext.w	a2,s1
    8000172c:	412585b3          	sub	a1,a1,s2
    80001730:	8552                	mv	a0,s4
    80001732:	fffff097          	auipc	ra,0xfffff
    80001736:	5fc080e7          	jalr	1532(ra) # 80000d2e <memmove>

    len -= n;
    8000173a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001740:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001744:	02098263          	beqz	s3,80001768 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001748:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000174c:	85ca                	mv	a1,s2
    8000174e:	855a                	mv	a0,s6
    80001750:	00000097          	auipc	ra,0x0
    80001754:	90c080e7          	jalr	-1780(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    80001758:	cd01                	beqz	a0,80001770 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    8000175a:	418904b3          	sub	s1,s2,s8
    8000175e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001760:	fc99f2e3          	bgeu	s3,s1,80001724 <copyin+0x28>
    80001764:	84ce                	mv	s1,s3
    80001766:	bf7d                	j	80001724 <copyin+0x28>
  }
  return 0;
    80001768:	4501                	li	a0,0
    8000176a:	a021                	j	80001772 <copyin+0x76>
    8000176c:	4501                	li	a0,0
}
    8000176e:	8082                	ret
      return -1;
    80001770:	557d                	li	a0,-1
}
    80001772:	60a6                	ld	ra,72(sp)
    80001774:	6406                	ld	s0,64(sp)
    80001776:	74e2                	ld	s1,56(sp)
    80001778:	7942                	ld	s2,48(sp)
    8000177a:	79a2                	ld	s3,40(sp)
    8000177c:	7a02                	ld	s4,32(sp)
    8000177e:	6ae2                	ld	s5,24(sp)
    80001780:	6b42                	ld	s6,16(sp)
    80001782:	6ba2                	ld	s7,8(sp)
    80001784:	6c02                	ld	s8,0(sp)
    80001786:	6161                	addi	sp,sp,80
    80001788:	8082                	ret

000000008000178a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000178a:	c6c5                	beqz	a3,80001832 <copyinstr+0xa8>
{
    8000178c:	715d                	addi	sp,sp,-80
    8000178e:	e486                	sd	ra,72(sp)
    80001790:	e0a2                	sd	s0,64(sp)
    80001792:	fc26                	sd	s1,56(sp)
    80001794:	f84a                	sd	s2,48(sp)
    80001796:	f44e                	sd	s3,40(sp)
    80001798:	f052                	sd	s4,32(sp)
    8000179a:	ec56                	sd	s5,24(sp)
    8000179c:	e85a                	sd	s6,16(sp)
    8000179e:	e45e                	sd	s7,8(sp)
    800017a0:	0880                	addi	s0,sp,80
    800017a2:	8a2a                	mv	s4,a0
    800017a4:	8b2e                	mv	s6,a1
    800017a6:	8bb2                	mv	s7,a2
    800017a8:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017aa:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017ac:	6985                	lui	s3,0x1
    800017ae:	a035                	j	800017da <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b6:	0017b793          	seqz	a5,a5
    800017ba:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017be:	60a6                	ld	ra,72(sp)
    800017c0:	6406                	ld	s0,64(sp)
    800017c2:	74e2                	ld	s1,56(sp)
    800017c4:	7942                	ld	s2,48(sp)
    800017c6:	79a2                	ld	s3,40(sp)
    800017c8:	7a02                	ld	s4,32(sp)
    800017ca:	6ae2                	ld	s5,24(sp)
    800017cc:	6b42                	ld	s6,16(sp)
    800017ce:	6ba2                	ld	s7,8(sp)
    800017d0:	6161                	addi	sp,sp,80
    800017d2:	8082                	ret
    srcva = va0 + PGSIZE;
    800017d4:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d8:	c8a9                	beqz	s1,8000182a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017da:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017de:	85ca                	mv	a1,s2
    800017e0:	8552                	mv	a0,s4
    800017e2:	00000097          	auipc	ra,0x0
    800017e6:	87a080e7          	jalr	-1926(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800017ea:	c131                	beqz	a0,8000182e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017ec:	41790833          	sub	a6,s2,s7
    800017f0:	984e                	add	a6,a6,s3
    if(n > max)
    800017f2:	0104f363          	bgeu	s1,a6,800017f8 <copyinstr+0x6e>
    800017f6:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f8:	955e                	add	a0,a0,s7
    800017fa:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017fe:	fc080be3          	beqz	a6,800017d4 <copyinstr+0x4a>
    80001802:	985a                	add	a6,a6,s6
    80001804:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001806:	41650633          	sub	a2,a0,s6
    8000180a:	14fd                	addi	s1,s1,-1
    8000180c:	9b26                	add	s6,s6,s1
    8000180e:	00f60733          	add	a4,a2,a5
    80001812:	00074703          	lbu	a4,0(a4)
    80001816:	df49                	beqz	a4,800017b0 <copyinstr+0x26>
        *dst = *p;
    80001818:	00e78023          	sb	a4,0(a5)
      --max;
    8000181c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001820:	0785                	addi	a5,a5,1
    while(n > 0){
    80001822:	ff0796e3          	bne	a5,a6,8000180e <copyinstr+0x84>
      dst++;
    80001826:	8b42                	mv	s6,a6
    80001828:	b775                	j	800017d4 <copyinstr+0x4a>
    8000182a:	4781                	li	a5,0
    8000182c:	b769                	j	800017b6 <copyinstr+0x2c>
      return -1;
    8000182e:	557d                	li	a0,-1
    80001830:	b779                	j	800017be <copyinstr+0x34>
  int got_null = 0;
    80001832:	4781                	li	a5,0
  if(got_null){
    80001834:	0017b793          	seqz	a5,a5
    80001838:	40f00533          	neg	a0,a5
}
    8000183c:	8082                	ret

000000008000183e <map_shared_pages>:
// task1:

uint64 map_shared_pages(struct proc *src_proc, struct proc *dst_proc,
                        uint64 src_va, uint64 size)
{ // Maps a physical page from one process to another (share)
  if (src_proc == 0 || dst_proc == 0 || size == 0 || src_va >= MAXVA)
    8000183e:	1e050263          	beqz	a0,80001a22 <map_shared_pages+0x1e4>
{ // Maps a physical page from one process to another (share)
    80001842:	7119                	addi	sp,sp,-128
    80001844:	fc86                	sd	ra,120(sp)
    80001846:	f8a2                	sd	s0,112(sp)
    80001848:	f4a6                	sd	s1,104(sp)
    8000184a:	f0ca                	sd	s2,96(sp)
    8000184c:	ecce                	sd	s3,88(sp)
    8000184e:	e8d2                	sd	s4,80(sp)
    80001850:	e4d6                	sd	s5,72(sp)
    80001852:	e0da                	sd	s6,64(sp)
    80001854:	fc5e                	sd	s7,56(sp)
    80001856:	f862                	sd	s8,48(sp)
    80001858:	f466                	sd	s9,40(sp)
    8000185a:	f06a                	sd	s10,32(sp)
    8000185c:	ec6e                	sd	s11,24(sp)
    8000185e:	0100                	addi	s0,sp,128
    80001860:	8b2a                	mv	s6,a0
    80001862:	8aae                	mv	s5,a1
    80001864:	8c32                	mv	s8,a2
  if (src_proc == 0 || dst_proc == 0 || size == 0 || src_va >= MAXVA)
    80001866:	1c058063          	beqz	a1,80001a26 <map_shared_pages+0x1e8>
    return -1;
    8000186a:	557d                	li	a0,-1
  if (src_proc == 0 || dst_proc == 0 || size == 0 || src_va >= MAXVA)
    8000186c:	cee1                	beqz	a3,80001944 <map_shared_pages+0x106>
    8000186e:	57fd                	li	a5,-1
    80001870:	83e9                	srli	a5,a5,0x1a
    80001872:	0cc7e963          	bltu	a5,a2,80001944 <map_shared_pages+0x106>

  pte_t *pte_src;
  uint64 a, last, pa, dst_va, cur_dst_va, offset, org_sz;
  int flags;

  a = PGROUNDDOWN(src_va);
    80001876:	74fd                	lui	s1,0xfffff
    80001878:	00967a33          	and	s4,a2,s1
    8000187c:	f9443023          	sd	s4,-128(s0)
  last = PGROUNDDOWN(src_va + size - 1);
    80001880:	fff60b93          	addi	s7,a2,-1 # fff <_entry-0x7ffff001>
    80001884:	96de                	add	a3,a3,s7
    80001886:	0096fbb3          	and	s7,a3,s1

  acquire(&dst_proc->lock); 
    8000188a:	852e                	mv	a0,a1
    8000188c:	fffff097          	auipc	ra,0xfffff
    80001890:	34a080e7          	jalr	842(ra) # 80000bd6 <acquire>
  acquire(&src_proc->lock);
    80001894:	855a                	mv	a0,s6
    80001896:	fffff097          	auipc	ra,0xfffff
    8000189a:	340080e7          	jalr	832(ra) # 80000bd6 <acquire>

  dst_va = PGROUNDUP(dst_proc->sz);
    8000189e:	048abd83          	ld	s11,72(s5) # fffffffffffff048 <end+0xffffffff7ffdd2c8>
    800018a2:	6505                	lui	a0,0x1
    800018a4:	157d                	addi	a0,a0,-1
    800018a6:	956e                	add	a0,a0,s11
    800018a8:	009577b3          	and	a5,a0,s1
    800018ac:	f8f43423          	sd	a5,-120(s0)
  org_sz = dst_proc->sz;
  cur_dst_va = dst_va;
    800018b0:	893e                	mv	s2,a5
      release(&src_proc->lock);
      release(&dst_proc->lock);
      return -1;
    }

    if (!(*pte_src & PTE_V) || !(*pte_src & PTE_U)) {
    800018b2:	4cc5                	li	s9,17
    }

    pa = PTE2PA(*pte_src);
    flags = PTE_FLAGS(*pte_src) | PTE_S;

    printf("✅ mapping va %p to pa %p with flags 0x%x\n", cur_dst_va, pa, flags);
    800018b4:	00007d17          	auipc	s10,0x7
    800018b8:	924d0d13          	addi	s10,s10,-1756 # 800081d8 <digits+0x198>
    if ((pte_src = walk(src_proc->pagetable, a, 0)) == 0) {
    800018bc:	4601                	li	a2,0
    800018be:	85d2                	mv	a1,s4
    800018c0:	050b3503          	ld	a0,80(s6) # 1050 <_entry-0x7fffefb0>
    800018c4:	fffff097          	auipc	ra,0xfffff
    800018c8:	6f2080e7          	jalr	1778(ra) # 80000fb6 <walk>
    800018cc:	c921                	beqz	a0,8000191c <map_shared_pages+0xde>
    if (!(*pte_src & PTE_V) || !(*pte_src & PTE_U)) {
    800018ce:	6104                	ld	s1,0(a0)
    800018d0:	0114f793          	andi	a5,s1,17
    800018d4:	0b979363          	bne	a5,s9,8000197a <map_shared_pages+0x13c>
    pa = PTE2PA(*pte_src);
    800018d8:	00a4d993          	srli	s3,s1,0xa
    800018dc:	09b2                	slli	s3,s3,0xc
    flags = PTE_FLAGS(*pte_src) | PTE_S;
    800018de:	2ff4f493          	andi	s1,s1,767
    800018e2:	1004e493          	ori	s1,s1,256
    printf("✅ mapping va %p to pa %p with flags 0x%x\n", cur_dst_va, pa, flags);
    800018e6:	86a6                	mv	a3,s1
    800018e8:	864e                	mv	a2,s3
    800018ea:	85ca                	mv	a1,s2
    800018ec:	856a                	mv	a0,s10
    800018ee:	fffff097          	auipc	ra,0xfffff
    800018f2:	c9a080e7          	jalr	-870(ra) # 80000588 <printf>

    if (mappages(dst_proc->pagetable, cur_dst_va, PGSIZE, pa, flags) != 0) {
    800018f6:	8726                	mv	a4,s1
    800018f8:	86ce                	mv	a3,s3
    800018fa:	6605                	lui	a2,0x1
    800018fc:	85ca                	mv	a1,s2
    800018fe:	050ab503          	ld	a0,80(s5)
    80001902:	fffff097          	auipc	ra,0xfffff
    80001906:	79c080e7          	jalr	1948(ra) # 8000109e <mappages>
    8000190a:	e94d                	bnez	a0,800019bc <map_shared_pages+0x17e>
      release(&src_proc->lock);
      release(&dst_proc->lock);
      return -1;
    }

    dst_proc->sz = cur_dst_va + PGSIZE;
    8000190c:	6785                	lui	a5,0x1
    8000190e:	993e                	add	s2,s2,a5
    80001910:	052ab423          	sd	s2,72(s5)

    if (a == last)
    80001914:	0f7a0563          	beq	s4,s7,800019fe <map_shared_pages+0x1c0>
      break;
    a += PGSIZE;
    80001918:	9a3e                	add	s4,s4,a5
    if ((pte_src = walk(src_proc->pagetable, a, 0)) == 0) {
    8000191a:	b74d                	j	800018bc <map_shared_pages+0x7e>
      cleanup(dst_proc, dst_va, ((cur_dst_va - dst_va) / PGSIZE), org_sz);
    8000191c:	f8843783          	ld	a5,-120(s0)
    80001920:	40f90933          	sub	s2,s2,a5
// ------------------------------------------------------------------------------

static void cleanup(struct proc *dst_proc, uint64 dst_va,
                    uint64 pages_mapped, uint64 original_sz)
{
  if (pages_mapped > 0)
    80001924:	6785                	lui	a5,0x1
    80001926:	02f97e63          	bgeu	s2,a5,80001962 <map_shared_pages+0x124>
  {
    uvmunmap(dst_proc->pagetable, dst_va, pages_mapped, 0);
  }
  // Restore the original process size
  dst_proc->sz = original_sz;
    8000192a:	05bab423          	sd	s11,72(s5)
      release(&src_proc->lock);
    8000192e:	855a                	mv	a0,s6
    80001930:	fffff097          	auipc	ra,0xfffff
    80001934:	35a080e7          	jalr	858(ra) # 80000c8a <release>
      release(&dst_proc->lock);
    80001938:	8556                	mv	a0,s5
    8000193a:	fffff097          	auipc	ra,0xfffff
    8000193e:	350080e7          	jalr	848(ra) # 80000c8a <release>
      return -1;
    80001942:	557d                	li	a0,-1
}
    80001944:	70e6                	ld	ra,120(sp)
    80001946:	7446                	ld	s0,112(sp)
    80001948:	74a6                	ld	s1,104(sp)
    8000194a:	7906                	ld	s2,96(sp)
    8000194c:	69e6                	ld	s3,88(sp)
    8000194e:	6a46                	ld	s4,80(sp)
    80001950:	6aa6                	ld	s5,72(sp)
    80001952:	6b06                	ld	s6,64(sp)
    80001954:	7be2                	ld	s7,56(sp)
    80001956:	7c42                	ld	s8,48(sp)
    80001958:	7ca2                	ld	s9,40(sp)
    8000195a:	7d02                	ld	s10,32(sp)
    8000195c:	6de2                	ld	s11,24(sp)
    8000195e:	6109                	addi	sp,sp,128
    80001960:	8082                	ret
    uvmunmap(dst_proc->pagetable, dst_va, pages_mapped, 0);
    80001962:	4681                	li	a3,0
    80001964:	00c95613          	srli	a2,s2,0xc
    80001968:	f8843583          	ld	a1,-120(s0)
    8000196c:	050ab503          	ld	a0,80(s5)
    80001970:	00000097          	auipc	ra,0x0
    80001974:	8f4080e7          	jalr	-1804(ra) # 80001264 <uvmunmap>
    80001978:	bf4d                	j	8000192a <map_shared_pages+0xec>
      cleanup(dst_proc, dst_va, ((cur_dst_va - dst_va) / PGSIZE), org_sz);
    8000197a:	f8843783          	ld	a5,-120(s0)
    8000197e:	40f90933          	sub	s2,s2,a5
  if (pages_mapped > 0)
    80001982:	6785                	lui	a5,0x1
    80001984:	02f97063          	bgeu	s2,a5,800019a4 <map_shared_pages+0x166>
  dst_proc->sz = original_sz;
    80001988:	05bab423          	sd	s11,72(s5)
      release(&src_proc->lock);
    8000198c:	855a                	mv	a0,s6
    8000198e:	fffff097          	auipc	ra,0xfffff
    80001992:	2fc080e7          	jalr	764(ra) # 80000c8a <release>
      release(&dst_proc->lock);
    80001996:	8556                	mv	a0,s5
    80001998:	fffff097          	auipc	ra,0xfffff
    8000199c:	2f2080e7          	jalr	754(ra) # 80000c8a <release>
      return -1;
    800019a0:	557d                	li	a0,-1
    800019a2:	b74d                	j	80001944 <map_shared_pages+0x106>
    uvmunmap(dst_proc->pagetable, dst_va, pages_mapped, 0);
    800019a4:	4681                	li	a3,0
    800019a6:	00c95613          	srli	a2,s2,0xc
    800019aa:	f8843583          	ld	a1,-120(s0)
    800019ae:	050ab503          	ld	a0,80(s5)
    800019b2:	00000097          	auipc	ra,0x0
    800019b6:	8b2080e7          	jalr	-1870(ra) # 80001264 <uvmunmap>
    800019ba:	b7f9                	j	80001988 <map_shared_pages+0x14a>
      cleanup(dst_proc, dst_va, ((cur_dst_va - dst_va) / PGSIZE), org_sz);
    800019bc:	f8843783          	ld	a5,-120(s0)
    800019c0:	40f90933          	sub	s2,s2,a5
  if (pages_mapped > 0)
    800019c4:	6785                	lui	a5,0x1
    800019c6:	02f97063          	bgeu	s2,a5,800019e6 <map_shared_pages+0x1a8>
  dst_proc->sz = original_sz;
    800019ca:	05bab423          	sd	s11,72(s5)
      release(&src_proc->lock);
    800019ce:	855a                	mv	a0,s6
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	2ba080e7          	jalr	698(ra) # 80000c8a <release>
      release(&dst_proc->lock);
    800019d8:	8556                	mv	a0,s5
    800019da:	fffff097          	auipc	ra,0xfffff
    800019de:	2b0080e7          	jalr	688(ra) # 80000c8a <release>
      return -1;
    800019e2:	557d                	li	a0,-1
    800019e4:	b785                	j	80001944 <map_shared_pages+0x106>
    uvmunmap(dst_proc->pagetable, dst_va, pages_mapped, 0);
    800019e6:	4681                	li	a3,0
    800019e8:	00c95613          	srli	a2,s2,0xc
    800019ec:	f8843583          	ld	a1,-120(s0)
    800019f0:	050ab503          	ld	a0,80(s5)
    800019f4:	00000097          	auipc	ra,0x0
    800019f8:	870080e7          	jalr	-1936(ra) # 80001264 <uvmunmap>
    800019fc:	b7f9                	j	800019ca <map_shared_pages+0x18c>
  release(&src_proc->lock);
    800019fe:	855a                	mv	a0,s6
    80001a00:	fffff097          	auipc	ra,0xfffff
    80001a04:	28a080e7          	jalr	650(ra) # 80000c8a <release>
  release(&dst_proc->lock);
    80001a08:	8556                	mv	a0,s5
    80001a0a:	fffff097          	auipc	ra,0xfffff
    80001a0e:	280080e7          	jalr	640(ra) # 80000c8a <release>
  offset = src_va - a;
    80001a12:	f8043783          	ld	a5,-128(s0)
    80001a16:	40fc0533          	sub	a0,s8,a5
  return dst_va + offset;
    80001a1a:	f8843783          	ld	a5,-120(s0)
    80001a1e:	953e                	add	a0,a0,a5
    80001a20:	b715                	j	80001944 <map_shared_pages+0x106>
    return -1;
    80001a22:	557d                	li	a0,-1
}
    80001a24:	8082                	ret
    return -1;
    80001a26:	557d                	li	a0,-1
    80001a28:	bf31                	j	80001944 <map_shared_pages+0x106>

0000000080001a2a <unmap_shared_pages>:
  if (p == 0 || size == 0 || addr >= MAXVA)
    80001a2a:	c179                	beqz	a0,80001af0 <unmap_shared_pages+0xc6>
{ // Removes the mapping from the process that obtained the share.
    80001a2c:	7139                	addi	sp,sp,-64
    80001a2e:	fc06                	sd	ra,56(sp)
    80001a30:	f822                	sd	s0,48(sp)
    80001a32:	f426                	sd	s1,40(sp)
    80001a34:	f04a                	sd	s2,32(sp)
    80001a36:	ec4e                	sd	s3,24(sp)
    80001a38:	e852                	sd	s4,16(sp)
    80001a3a:	e456                	sd	s5,8(sp)
    80001a3c:	e05a                	sd	s6,0(sp)
    80001a3e:	0080                	addi	s0,sp,64
    80001a40:	89aa                	mv	s3,a0
    return -1; // Invalid input
    80001a42:	557d                	li	a0,-1
  if (p == 0 || size == 0 || addr >= MAXVA)
    80001a44:	ca49                	beqz	a2,80001ad6 <unmap_shared_pages+0xac>
    80001a46:	57fd                	li	a5,-1
    80001a48:	83e9                	srli	a5,a5,0x1a
    80001a4a:	08b7e663          	bltu	a5,a1,80001ad6 <unmap_shared_pages+0xac>
  a = PGROUNDDOWN(addr);
    80001a4e:	77fd                	lui	a5,0xfffff
    80001a50:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(addr + size - 1);
    80001a54:	15fd                	addi	a1,a1,-1
    80001a56:	00c58933          	add	s2,a1,a2
    80001a5a:	00f97933          	and	s2,s2,a5
  acquire(&p->lock);
    80001a5e:	854e                	mv	a0,s3
    80001a60:	fffff097          	auipc	ra,0xfffff
    80001a64:	176080e7          	jalr	374(ra) # 80000bd6 <acquire>
  for(uint64 curr = a; curr <= last; curr += PGSIZE){
    80001a68:	03496763          	bltu	s2,s4,80001a96 <unmap_shared_pages+0x6c>
    80001a6c:	84d2                	mv	s1,s4
      if(((pte = walk(p->pagetable, curr, 0)) == 0) || !(*pte & PTE_S) || !(*pte & PTE_V)){
    80001a6e:	10100a93          	li	s5,257
  for(uint64 curr = a; curr <= last; curr += PGSIZE){
    80001a72:	6b05                	lui	s6,0x1
      if(((pte = walk(p->pagetable, curr, 0)) == 0) || !(*pte & PTE_S) || !(*pte & PTE_V)){
    80001a74:	4601                	li	a2,0
    80001a76:	85a6                	mv	a1,s1
    80001a78:	0509b503          	ld	a0,80(s3) # 1050 <_entry-0x7fffefb0>
    80001a7c:	fffff097          	auipc	ra,0xfffff
    80001a80:	53a080e7          	jalr	1338(ra) # 80000fb6 <walk>
    80001a84:	c139                	beqz	a0,80001aca <unmap_shared_pages+0xa0>
    80001a86:	611c                	ld	a5,0(a0)
    80001a88:	1017f793          	andi	a5,a5,257
    80001a8c:	03579f63          	bne	a5,s5,80001aca <unmap_shared_pages+0xa0>
  for(uint64 curr = a; curr <= last; curr += PGSIZE){
    80001a90:	94da                	add	s1,s1,s6
    80001a92:	fe9971e3          	bgeu	s2,s1,80001a74 <unmap_shared_pages+0x4a>
  npages = (last - a)/PGSIZE + 1;
    80001a96:	414904b3          	sub	s1,s2,s4
    80001a9a:	80b1                	srli	s1,s1,0xc
    80001a9c:	0485                	addi	s1,s1,1
  uvmunmap(p->pagetable, a, npages, 0);
    80001a9e:	4681                	li	a3,0
    80001aa0:	8626                	mv	a2,s1
    80001aa2:	85d2                	mv	a1,s4
    80001aa4:	0509b503          	ld	a0,80(s3)
    80001aa8:	fffff097          	auipc	ra,0xfffff
    80001aac:	7bc080e7          	jalr	1980(ra) # 80001264 <uvmunmap>
  if(a + npages*PGSIZE == p->sz)
    80001ab0:	04b2                	slli	s1,s1,0xc
    80001ab2:	94d2                	add	s1,s1,s4
    80001ab4:	0489b783          	ld	a5,72(s3)
    80001ab8:	02f48963          	beq	s1,a5,80001aea <unmap_shared_pages+0xc0>
  release(&p->lock);
    80001abc:	854e                	mv	a0,s3
    80001abe:	fffff097          	auipc	ra,0xfffff
    80001ac2:	1cc080e7          	jalr	460(ra) # 80000c8a <release>
  return 0;
    80001ac6:	4501                	li	a0,0
    80001ac8:	a039                	j	80001ad6 <unmap_shared_pages+0xac>
        release(&p->lock);
    80001aca:	854e                	mv	a0,s3
    80001acc:	fffff097          	auipc	ra,0xfffff
    80001ad0:	1be080e7          	jalr	446(ra) # 80000c8a <release>
        return -1;
    80001ad4:	557d                	li	a0,-1
}
    80001ad6:	70e2                	ld	ra,56(sp)
    80001ad8:	7442                	ld	s0,48(sp)
    80001ada:	74a2                	ld	s1,40(sp)
    80001adc:	7902                	ld	s2,32(sp)
    80001ade:	69e2                	ld	s3,24(sp)
    80001ae0:	6a42                	ld	s4,16(sp)
    80001ae2:	6aa2                	ld	s5,8(sp)
    80001ae4:	6b02                	ld	s6,0(sp)
    80001ae6:	6121                	addi	sp,sp,64
    80001ae8:	8082                	ret
    p->sz = a;
    80001aea:	0549b423          	sd	s4,72(s3)
    80001aee:	b7f9                	j	80001abc <unmap_shared_pages+0x92>
    return -1; // Invalid input
    80001af0:	557d                	li	a0,-1
}
    80001af2:	8082                	ret

0000000080001af4 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001af4:	7139                	addi	sp,sp,-64
    80001af6:	fc06                	sd	ra,56(sp)
    80001af8:	f822                	sd	s0,48(sp)
    80001afa:	f426                	sd	s1,40(sp)
    80001afc:	f04a                	sd	s2,32(sp)
    80001afe:	ec4e                	sd	s3,24(sp)
    80001b00:	e852                	sd	s4,16(sp)
    80001b02:	e456                	sd	s5,8(sp)
    80001b04:	e05a                	sd	s6,0(sp)
    80001b06:	0080                	addi	s0,sp,64
    80001b08:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b0a:	0000f497          	auipc	s1,0xf
    80001b0e:	49648493          	addi	s1,s1,1174 # 80010fa0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001b12:	8b26                	mv	s6,s1
    80001b14:	00006a97          	auipc	s5,0x6
    80001b18:	4eca8a93          	addi	s5,s5,1260 # 80008000 <etext>
    80001b1c:	04000937          	lui	s2,0x4000
    80001b20:	197d                	addi	s2,s2,-1
    80001b22:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b24:	00015a17          	auipc	s4,0x15
    80001b28:	e7ca0a13          	addi	s4,s4,-388 # 800169a0 <tickslock>
    char *pa = kalloc();
    80001b2c:	fffff097          	auipc	ra,0xfffff
    80001b30:	fba080e7          	jalr	-70(ra) # 80000ae6 <kalloc>
    80001b34:	862a                	mv	a2,a0
    if(pa == 0)
    80001b36:	c131                	beqz	a0,80001b7a <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001b38:	416485b3          	sub	a1,s1,s6
    80001b3c:	858d                	srai	a1,a1,0x3
    80001b3e:	000ab783          	ld	a5,0(s5)
    80001b42:	02f585b3          	mul	a1,a1,a5
    80001b46:	2585                	addiw	a1,a1,1
    80001b48:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001b4c:	4719                	li	a4,6
    80001b4e:	6685                	lui	a3,0x1
    80001b50:	40b905b3          	sub	a1,s2,a1
    80001b54:	854e                	mv	a0,s3
    80001b56:	fffff097          	auipc	ra,0xfffff
    80001b5a:	5e8080e7          	jalr	1512(ra) # 8000113e <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b5e:	16848493          	addi	s1,s1,360
    80001b62:	fd4495e3          	bne	s1,s4,80001b2c <proc_mapstacks+0x38>
  }
}
    80001b66:	70e2                	ld	ra,56(sp)
    80001b68:	7442                	ld	s0,48(sp)
    80001b6a:	74a2                	ld	s1,40(sp)
    80001b6c:	7902                	ld	s2,32(sp)
    80001b6e:	69e2                	ld	s3,24(sp)
    80001b70:	6a42                	ld	s4,16(sp)
    80001b72:	6aa2                	ld	s5,8(sp)
    80001b74:	6b02                	ld	s6,0(sp)
    80001b76:	6121                	addi	sp,sp,64
    80001b78:	8082                	ret
      panic("kalloc");
    80001b7a:	00006517          	auipc	a0,0x6
    80001b7e:	68e50513          	addi	a0,a0,1678 # 80008208 <digits+0x1c8>
    80001b82:	fffff097          	auipc	ra,0xfffff
    80001b86:	9bc080e7          	jalr	-1604(ra) # 8000053e <panic>

0000000080001b8a <procinit>:

// initialize the proc table.
void
procinit(void)
{
    80001b8a:	7139                	addi	sp,sp,-64
    80001b8c:	fc06                	sd	ra,56(sp)
    80001b8e:	f822                	sd	s0,48(sp)
    80001b90:	f426                	sd	s1,40(sp)
    80001b92:	f04a                	sd	s2,32(sp)
    80001b94:	ec4e                	sd	s3,24(sp)
    80001b96:	e852                	sd	s4,16(sp)
    80001b98:	e456                	sd	s5,8(sp)
    80001b9a:	e05a                	sd	s6,0(sp)
    80001b9c:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001b9e:	00006597          	auipc	a1,0x6
    80001ba2:	67258593          	addi	a1,a1,1650 # 80008210 <digits+0x1d0>
    80001ba6:	0000f517          	auipc	a0,0xf
    80001baa:	fca50513          	addi	a0,a0,-54 # 80010b70 <pid_lock>
    80001bae:	fffff097          	auipc	ra,0xfffff
    80001bb2:	f98080e7          	jalr	-104(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001bb6:	00006597          	auipc	a1,0x6
    80001bba:	66258593          	addi	a1,a1,1634 # 80008218 <digits+0x1d8>
    80001bbe:	0000f517          	auipc	a0,0xf
    80001bc2:	fca50513          	addi	a0,a0,-54 # 80010b88 <wait_lock>
    80001bc6:	fffff097          	auipc	ra,0xfffff
    80001bca:	f80080e7          	jalr	-128(ra) # 80000b46 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bce:	0000f497          	auipc	s1,0xf
    80001bd2:	3d248493          	addi	s1,s1,978 # 80010fa0 <proc>
      initlock(&p->lock, "proc");
    80001bd6:	00006b17          	auipc	s6,0x6
    80001bda:	652b0b13          	addi	s6,s6,1618 # 80008228 <digits+0x1e8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001bde:	8aa6                	mv	s5,s1
    80001be0:	00006a17          	auipc	s4,0x6
    80001be4:	420a0a13          	addi	s4,s4,1056 # 80008000 <etext>
    80001be8:	04000937          	lui	s2,0x4000
    80001bec:	197d                	addi	s2,s2,-1
    80001bee:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bf0:	00015997          	auipc	s3,0x15
    80001bf4:	db098993          	addi	s3,s3,-592 # 800169a0 <tickslock>
      initlock(&p->lock, "proc");
    80001bf8:	85da                	mv	a1,s6
    80001bfa:	8526                	mv	a0,s1
    80001bfc:	fffff097          	auipc	ra,0xfffff
    80001c00:	f4a080e7          	jalr	-182(ra) # 80000b46 <initlock>
      p->state = UNUSED;
    80001c04:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001c08:	415487b3          	sub	a5,s1,s5
    80001c0c:	878d                	srai	a5,a5,0x3
    80001c0e:	000a3703          	ld	a4,0(s4)
    80001c12:	02e787b3          	mul	a5,a5,a4
    80001c16:	2785                	addiw	a5,a5,1
    80001c18:	00d7979b          	slliw	a5,a5,0xd
    80001c1c:	40f907b3          	sub	a5,s2,a5
    80001c20:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c22:	16848493          	addi	s1,s1,360
    80001c26:	fd3499e3          	bne	s1,s3,80001bf8 <procinit+0x6e>
  }
}
    80001c2a:	70e2                	ld	ra,56(sp)
    80001c2c:	7442                	ld	s0,48(sp)
    80001c2e:	74a2                	ld	s1,40(sp)
    80001c30:	7902                	ld	s2,32(sp)
    80001c32:	69e2                	ld	s3,24(sp)
    80001c34:	6a42                	ld	s4,16(sp)
    80001c36:	6aa2                	ld	s5,8(sp)
    80001c38:	6b02                	ld	s6,0(sp)
    80001c3a:	6121                	addi	sp,sp,64
    80001c3c:	8082                	ret

0000000080001c3e <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001c3e:	1141                	addi	sp,sp,-16
    80001c40:	e422                	sd	s0,8(sp)
    80001c42:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001c44:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001c46:	2501                	sext.w	a0,a0
    80001c48:	6422                	ld	s0,8(sp)
    80001c4a:	0141                	addi	sp,sp,16
    80001c4c:	8082                	ret

0000000080001c4e <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001c4e:	1141                	addi	sp,sp,-16
    80001c50:	e422                	sd	s0,8(sp)
    80001c52:	0800                	addi	s0,sp,16
    80001c54:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001c56:	2781                	sext.w	a5,a5
    80001c58:	079e                	slli	a5,a5,0x7
  return c;
}
    80001c5a:	0000f517          	auipc	a0,0xf
    80001c5e:	f4650513          	addi	a0,a0,-186 # 80010ba0 <cpus>
    80001c62:	953e                	add	a0,a0,a5
    80001c64:	6422                	ld	s0,8(sp)
    80001c66:	0141                	addi	sp,sp,16
    80001c68:	8082                	ret

0000000080001c6a <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    80001c6a:	1101                	addi	sp,sp,-32
    80001c6c:	ec06                	sd	ra,24(sp)
    80001c6e:	e822                	sd	s0,16(sp)
    80001c70:	e426                	sd	s1,8(sp)
    80001c72:	1000                	addi	s0,sp,32
  push_off();
    80001c74:	fffff097          	auipc	ra,0xfffff
    80001c78:	f16080e7          	jalr	-234(ra) # 80000b8a <push_off>
    80001c7c:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001c7e:	2781                	sext.w	a5,a5
    80001c80:	079e                	slli	a5,a5,0x7
    80001c82:	0000f717          	auipc	a4,0xf
    80001c86:	eee70713          	addi	a4,a4,-274 # 80010b70 <pid_lock>
    80001c8a:	97ba                	add	a5,a5,a4
    80001c8c:	7b84                	ld	s1,48(a5)
  pop_off();
    80001c8e:	fffff097          	auipc	ra,0xfffff
    80001c92:	f9c080e7          	jalr	-100(ra) # 80000c2a <pop_off>
  return p;
}
    80001c96:	8526                	mv	a0,s1
    80001c98:	60e2                	ld	ra,24(sp)
    80001c9a:	6442                	ld	s0,16(sp)
    80001c9c:	64a2                	ld	s1,8(sp)
    80001c9e:	6105                	addi	sp,sp,32
    80001ca0:	8082                	ret

0000000080001ca2 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001ca2:	1141                	addi	sp,sp,-16
    80001ca4:	e406                	sd	ra,8(sp)
    80001ca6:	e022                	sd	s0,0(sp)
    80001ca8:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001caa:	00000097          	auipc	ra,0x0
    80001cae:	fc0080e7          	jalr	-64(ra) # 80001c6a <myproc>
    80001cb2:	fffff097          	auipc	ra,0xfffff
    80001cb6:	fd8080e7          	jalr	-40(ra) # 80000c8a <release>

  if (first) {
    80001cba:	00007797          	auipc	a5,0x7
    80001cbe:	bc67a783          	lw	a5,-1082(a5) # 80008880 <first.1>
    80001cc2:	eb89                	bnez	a5,80001cd4 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001cc4:	00001097          	auipc	ra,0x1
    80001cc8:	c74080e7          	jalr	-908(ra) # 80002938 <usertrapret>
}
    80001ccc:	60a2                	ld	ra,8(sp)
    80001cce:	6402                	ld	s0,0(sp)
    80001cd0:	0141                	addi	sp,sp,16
    80001cd2:	8082                	ret
    first = 0;
    80001cd4:	00007797          	auipc	a5,0x7
    80001cd8:	ba07a623          	sw	zero,-1108(a5) # 80008880 <first.1>
    fsinit(ROOTDEV);
    80001cdc:	4505                	li	a0,1
    80001cde:	00002097          	auipc	ra,0x2
    80001ce2:	ad8080e7          	jalr	-1320(ra) # 800037b6 <fsinit>
    80001ce6:	bff9                	j	80001cc4 <forkret+0x22>

0000000080001ce8 <allocpid>:
{
    80001ce8:	1101                	addi	sp,sp,-32
    80001cea:	ec06                	sd	ra,24(sp)
    80001cec:	e822                	sd	s0,16(sp)
    80001cee:	e426                	sd	s1,8(sp)
    80001cf0:	e04a                	sd	s2,0(sp)
    80001cf2:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001cf4:	0000f917          	auipc	s2,0xf
    80001cf8:	e7c90913          	addi	s2,s2,-388 # 80010b70 <pid_lock>
    80001cfc:	854a                	mv	a0,s2
    80001cfe:	fffff097          	auipc	ra,0xfffff
    80001d02:	ed8080e7          	jalr	-296(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001d06:	00007797          	auipc	a5,0x7
    80001d0a:	b7e78793          	addi	a5,a5,-1154 # 80008884 <nextpid>
    80001d0e:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001d10:	0014871b          	addiw	a4,s1,1
    80001d14:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001d16:	854a                	mv	a0,s2
    80001d18:	fffff097          	auipc	ra,0xfffff
    80001d1c:	f72080e7          	jalr	-142(ra) # 80000c8a <release>
}
    80001d20:	8526                	mv	a0,s1
    80001d22:	60e2                	ld	ra,24(sp)
    80001d24:	6442                	ld	s0,16(sp)
    80001d26:	64a2                	ld	s1,8(sp)
    80001d28:	6902                	ld	s2,0(sp)
    80001d2a:	6105                	addi	sp,sp,32
    80001d2c:	8082                	ret

0000000080001d2e <proc_pagetable>:
{
    80001d2e:	1101                	addi	sp,sp,-32
    80001d30:	ec06                	sd	ra,24(sp)
    80001d32:	e822                	sd	s0,16(sp)
    80001d34:	e426                	sd	s1,8(sp)
    80001d36:	e04a                	sd	s2,0(sp)
    80001d38:	1000                	addi	s0,sp,32
    80001d3a:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001d3c:	fffff097          	auipc	ra,0xfffff
    80001d40:	5f4080e7          	jalr	1524(ra) # 80001330 <uvmcreate>
    80001d44:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001d46:	c121                	beqz	a0,80001d86 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001d48:	4729                	li	a4,10
    80001d4a:	00005697          	auipc	a3,0x5
    80001d4e:	2b668693          	addi	a3,a3,694 # 80007000 <_trampoline>
    80001d52:	6605                	lui	a2,0x1
    80001d54:	040005b7          	lui	a1,0x4000
    80001d58:	15fd                	addi	a1,a1,-1
    80001d5a:	05b2                	slli	a1,a1,0xc
    80001d5c:	fffff097          	auipc	ra,0xfffff
    80001d60:	342080e7          	jalr	834(ra) # 8000109e <mappages>
    80001d64:	02054863          	bltz	a0,80001d94 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001d68:	4719                	li	a4,6
    80001d6a:	05893683          	ld	a3,88(s2)
    80001d6e:	6605                	lui	a2,0x1
    80001d70:	020005b7          	lui	a1,0x2000
    80001d74:	15fd                	addi	a1,a1,-1
    80001d76:	05b6                	slli	a1,a1,0xd
    80001d78:	8526                	mv	a0,s1
    80001d7a:	fffff097          	auipc	ra,0xfffff
    80001d7e:	324080e7          	jalr	804(ra) # 8000109e <mappages>
    80001d82:	02054163          	bltz	a0,80001da4 <proc_pagetable+0x76>
}
    80001d86:	8526                	mv	a0,s1
    80001d88:	60e2                	ld	ra,24(sp)
    80001d8a:	6442                	ld	s0,16(sp)
    80001d8c:	64a2                	ld	s1,8(sp)
    80001d8e:	6902                	ld	s2,0(sp)
    80001d90:	6105                	addi	sp,sp,32
    80001d92:	8082                	ret
    uvmfree(pagetable, 0);
    80001d94:	4581                	li	a1,0
    80001d96:	8526                	mv	a0,s1
    80001d98:	fffff097          	auipc	ra,0xfffff
    80001d9c:	79c080e7          	jalr	1948(ra) # 80001534 <uvmfree>
    return 0;
    80001da0:	4481                	li	s1,0
    80001da2:	b7d5                	j	80001d86 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001da4:	4681                	li	a3,0
    80001da6:	4605                	li	a2,1
    80001da8:	040005b7          	lui	a1,0x4000
    80001dac:	15fd                	addi	a1,a1,-1
    80001dae:	05b2                	slli	a1,a1,0xc
    80001db0:	8526                	mv	a0,s1
    80001db2:	fffff097          	auipc	ra,0xfffff
    80001db6:	4b2080e7          	jalr	1202(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, 0);
    80001dba:	4581                	li	a1,0
    80001dbc:	8526                	mv	a0,s1
    80001dbe:	fffff097          	auipc	ra,0xfffff
    80001dc2:	776080e7          	jalr	1910(ra) # 80001534 <uvmfree>
    return 0;
    80001dc6:	4481                	li	s1,0
    80001dc8:	bf7d                	j	80001d86 <proc_pagetable+0x58>

0000000080001dca <proc_freepagetable>:
{
    80001dca:	1101                	addi	sp,sp,-32
    80001dcc:	ec06                	sd	ra,24(sp)
    80001dce:	e822                	sd	s0,16(sp)
    80001dd0:	e426                	sd	s1,8(sp)
    80001dd2:	e04a                	sd	s2,0(sp)
    80001dd4:	1000                	addi	s0,sp,32
    80001dd6:	84aa                	mv	s1,a0
    80001dd8:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001dda:	4681                	li	a3,0
    80001ddc:	4605                	li	a2,1
    80001dde:	040005b7          	lui	a1,0x4000
    80001de2:	15fd                	addi	a1,a1,-1
    80001de4:	05b2                	slli	a1,a1,0xc
    80001de6:	fffff097          	auipc	ra,0xfffff
    80001dea:	47e080e7          	jalr	1150(ra) # 80001264 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001dee:	4681                	li	a3,0
    80001df0:	4605                	li	a2,1
    80001df2:	020005b7          	lui	a1,0x2000
    80001df6:	15fd                	addi	a1,a1,-1
    80001df8:	05b6                	slli	a1,a1,0xd
    80001dfa:	8526                	mv	a0,s1
    80001dfc:	fffff097          	auipc	ra,0xfffff
    80001e00:	468080e7          	jalr	1128(ra) # 80001264 <uvmunmap>
  uvmfree(pagetable, sz);
    80001e04:	85ca                	mv	a1,s2
    80001e06:	8526                	mv	a0,s1
    80001e08:	fffff097          	auipc	ra,0xfffff
    80001e0c:	72c080e7          	jalr	1836(ra) # 80001534 <uvmfree>
}
    80001e10:	60e2                	ld	ra,24(sp)
    80001e12:	6442                	ld	s0,16(sp)
    80001e14:	64a2                	ld	s1,8(sp)
    80001e16:	6902                	ld	s2,0(sp)
    80001e18:	6105                	addi	sp,sp,32
    80001e1a:	8082                	ret

0000000080001e1c <freeproc>:
{
    80001e1c:	1101                	addi	sp,sp,-32
    80001e1e:	ec06                	sd	ra,24(sp)
    80001e20:	e822                	sd	s0,16(sp)
    80001e22:	e426                	sd	s1,8(sp)
    80001e24:	1000                	addi	s0,sp,32
    80001e26:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001e28:	6d28                	ld	a0,88(a0)
    80001e2a:	c509                	beqz	a0,80001e34 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001e2c:	fffff097          	auipc	ra,0xfffff
    80001e30:	bbe080e7          	jalr	-1090(ra) # 800009ea <kfree>
  p->trapframe = 0;
    80001e34:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001e38:	68a8                	ld	a0,80(s1)
    80001e3a:	c511                	beqz	a0,80001e46 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001e3c:	64ac                	ld	a1,72(s1)
    80001e3e:	00000097          	auipc	ra,0x0
    80001e42:	f8c080e7          	jalr	-116(ra) # 80001dca <proc_freepagetable>
  p->pagetable = 0;
    80001e46:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001e4a:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001e4e:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001e52:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001e56:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001e5a:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001e5e:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001e62:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001e66:	0004ac23          	sw	zero,24(s1)
}
    80001e6a:	60e2                	ld	ra,24(sp)
    80001e6c:	6442                	ld	s0,16(sp)
    80001e6e:	64a2                	ld	s1,8(sp)
    80001e70:	6105                	addi	sp,sp,32
    80001e72:	8082                	ret

0000000080001e74 <allocproc>:
{
    80001e74:	1101                	addi	sp,sp,-32
    80001e76:	ec06                	sd	ra,24(sp)
    80001e78:	e822                	sd	s0,16(sp)
    80001e7a:	e426                	sd	s1,8(sp)
    80001e7c:	e04a                	sd	s2,0(sp)
    80001e7e:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e80:	0000f497          	auipc	s1,0xf
    80001e84:	12048493          	addi	s1,s1,288 # 80010fa0 <proc>
    80001e88:	00015917          	auipc	s2,0x15
    80001e8c:	b1890913          	addi	s2,s2,-1256 # 800169a0 <tickslock>
    acquire(&p->lock);
    80001e90:	8526                	mv	a0,s1
    80001e92:	fffff097          	auipc	ra,0xfffff
    80001e96:	d44080e7          	jalr	-700(ra) # 80000bd6 <acquire>
    if(p->state == UNUSED) {
    80001e9a:	4c9c                	lw	a5,24(s1)
    80001e9c:	cf81                	beqz	a5,80001eb4 <allocproc+0x40>
      release(&p->lock);
    80001e9e:	8526                	mv	a0,s1
    80001ea0:	fffff097          	auipc	ra,0xfffff
    80001ea4:	dea080e7          	jalr	-534(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ea8:	16848493          	addi	s1,s1,360
    80001eac:	ff2492e3          	bne	s1,s2,80001e90 <allocproc+0x1c>
  return 0;
    80001eb0:	4481                	li	s1,0
    80001eb2:	a889                	j	80001f04 <allocproc+0x90>
  p->pid = allocpid();
    80001eb4:	00000097          	auipc	ra,0x0
    80001eb8:	e34080e7          	jalr	-460(ra) # 80001ce8 <allocpid>
    80001ebc:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001ebe:	4785                	li	a5,1
    80001ec0:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001ec2:	fffff097          	auipc	ra,0xfffff
    80001ec6:	c24080e7          	jalr	-988(ra) # 80000ae6 <kalloc>
    80001eca:	892a                	mv	s2,a0
    80001ecc:	eca8                	sd	a0,88(s1)
    80001ece:	c131                	beqz	a0,80001f12 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001ed0:	8526                	mv	a0,s1
    80001ed2:	00000097          	auipc	ra,0x0
    80001ed6:	e5c080e7          	jalr	-420(ra) # 80001d2e <proc_pagetable>
    80001eda:	892a                	mv	s2,a0
    80001edc:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001ede:	c531                	beqz	a0,80001f2a <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001ee0:	07000613          	li	a2,112
    80001ee4:	4581                	li	a1,0
    80001ee6:	06048513          	addi	a0,s1,96
    80001eea:	fffff097          	auipc	ra,0xfffff
    80001eee:	de8080e7          	jalr	-536(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001ef2:	00000797          	auipc	a5,0x0
    80001ef6:	db078793          	addi	a5,a5,-592 # 80001ca2 <forkret>
    80001efa:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001efc:	60bc                	ld	a5,64(s1)
    80001efe:	6705                	lui	a4,0x1
    80001f00:	97ba                	add	a5,a5,a4
    80001f02:	f4bc                	sd	a5,104(s1)
}
    80001f04:	8526                	mv	a0,s1
    80001f06:	60e2                	ld	ra,24(sp)
    80001f08:	6442                	ld	s0,16(sp)
    80001f0a:	64a2                	ld	s1,8(sp)
    80001f0c:	6902                	ld	s2,0(sp)
    80001f0e:	6105                	addi	sp,sp,32
    80001f10:	8082                	ret
    freeproc(p);
    80001f12:	8526                	mv	a0,s1
    80001f14:	00000097          	auipc	ra,0x0
    80001f18:	f08080e7          	jalr	-248(ra) # 80001e1c <freeproc>
    release(&p->lock);
    80001f1c:	8526                	mv	a0,s1
    80001f1e:	fffff097          	auipc	ra,0xfffff
    80001f22:	d6c080e7          	jalr	-660(ra) # 80000c8a <release>
    return 0;
    80001f26:	84ca                	mv	s1,s2
    80001f28:	bff1                	j	80001f04 <allocproc+0x90>
    freeproc(p);
    80001f2a:	8526                	mv	a0,s1
    80001f2c:	00000097          	auipc	ra,0x0
    80001f30:	ef0080e7          	jalr	-272(ra) # 80001e1c <freeproc>
    release(&p->lock);
    80001f34:	8526                	mv	a0,s1
    80001f36:	fffff097          	auipc	ra,0xfffff
    80001f3a:	d54080e7          	jalr	-684(ra) # 80000c8a <release>
    return 0;
    80001f3e:	84ca                	mv	s1,s2
    80001f40:	b7d1                	j	80001f04 <allocproc+0x90>

0000000080001f42 <userinit>:
{
    80001f42:	1101                	addi	sp,sp,-32
    80001f44:	ec06                	sd	ra,24(sp)
    80001f46:	e822                	sd	s0,16(sp)
    80001f48:	e426                	sd	s1,8(sp)
    80001f4a:	1000                	addi	s0,sp,32
  p = allocproc();
    80001f4c:	00000097          	auipc	ra,0x0
    80001f50:	f28080e7          	jalr	-216(ra) # 80001e74 <allocproc>
    80001f54:	84aa                	mv	s1,a0
  initproc = p;
    80001f56:	00007797          	auipc	a5,0x7
    80001f5a:	9aa7b123          	sd	a0,-1630(a5) # 800088f8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001f5e:	03400613          	li	a2,52
    80001f62:	00007597          	auipc	a1,0x7
    80001f66:	92e58593          	addi	a1,a1,-1746 # 80008890 <initcode>
    80001f6a:	6928                	ld	a0,80(a0)
    80001f6c:	fffff097          	auipc	ra,0xfffff
    80001f70:	3f2080e7          	jalr	1010(ra) # 8000135e <uvmfirst>
  p->sz = PGSIZE;
    80001f74:	6785                	lui	a5,0x1
    80001f76:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001f78:	6cb8                	ld	a4,88(s1)
    80001f7a:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001f7e:	6cb8                	ld	a4,88(s1)
    80001f80:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001f82:	4641                	li	a2,16
    80001f84:	00006597          	auipc	a1,0x6
    80001f88:	2ac58593          	addi	a1,a1,684 # 80008230 <digits+0x1f0>
    80001f8c:	15848513          	addi	a0,s1,344
    80001f90:	fffff097          	auipc	ra,0xfffff
    80001f94:	e8c080e7          	jalr	-372(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001f98:	00006517          	auipc	a0,0x6
    80001f9c:	2a850513          	addi	a0,a0,680 # 80008240 <digits+0x200>
    80001fa0:	00002097          	auipc	ra,0x2
    80001fa4:	238080e7          	jalr	568(ra) # 800041d8 <namei>
    80001fa8:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001fac:	478d                	li	a5,3
    80001fae:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001fb0:	8526                	mv	a0,s1
    80001fb2:	fffff097          	auipc	ra,0xfffff
    80001fb6:	cd8080e7          	jalr	-808(ra) # 80000c8a <release>
}
    80001fba:	60e2                	ld	ra,24(sp)
    80001fbc:	6442                	ld	s0,16(sp)
    80001fbe:	64a2                	ld	s1,8(sp)
    80001fc0:	6105                	addi	sp,sp,32
    80001fc2:	8082                	ret

0000000080001fc4 <growproc>:
{
    80001fc4:	1101                	addi	sp,sp,-32
    80001fc6:	ec06                	sd	ra,24(sp)
    80001fc8:	e822                	sd	s0,16(sp)
    80001fca:	e426                	sd	s1,8(sp)
    80001fcc:	e04a                	sd	s2,0(sp)
    80001fce:	1000                	addi	s0,sp,32
    80001fd0:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001fd2:	00000097          	auipc	ra,0x0
    80001fd6:	c98080e7          	jalr	-872(ra) # 80001c6a <myproc>
    80001fda:	84aa                	mv	s1,a0
  sz = p->sz;
    80001fdc:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001fde:	01204c63          	bgtz	s2,80001ff6 <growproc+0x32>
  } else if(n < 0){
    80001fe2:	02094663          	bltz	s2,8000200e <growproc+0x4a>
  p->sz = sz;
    80001fe6:	e4ac                	sd	a1,72(s1)
  return 0;
    80001fe8:	4501                	li	a0,0
}
    80001fea:	60e2                	ld	ra,24(sp)
    80001fec:	6442                	ld	s0,16(sp)
    80001fee:	64a2                	ld	s1,8(sp)
    80001ff0:	6902                	ld	s2,0(sp)
    80001ff2:	6105                	addi	sp,sp,32
    80001ff4:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001ff6:	4691                	li	a3,4
    80001ff8:	00b90633          	add	a2,s2,a1
    80001ffc:	6928                	ld	a0,80(a0)
    80001ffe:	fffff097          	auipc	ra,0xfffff
    80002002:	41a080e7          	jalr	1050(ra) # 80001418 <uvmalloc>
    80002006:	85aa                	mv	a1,a0
    80002008:	fd79                	bnez	a0,80001fe6 <growproc+0x22>
      return -1;
    8000200a:	557d                	li	a0,-1
    8000200c:	bff9                	j	80001fea <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    8000200e:	00b90633          	add	a2,s2,a1
    80002012:	6928                	ld	a0,80(a0)
    80002014:	fffff097          	auipc	ra,0xfffff
    80002018:	3bc080e7          	jalr	956(ra) # 800013d0 <uvmdealloc>
    8000201c:	85aa                	mv	a1,a0
    8000201e:	b7e1                	j	80001fe6 <growproc+0x22>

0000000080002020 <fork>:
{
    80002020:	7139                	addi	sp,sp,-64
    80002022:	fc06                	sd	ra,56(sp)
    80002024:	f822                	sd	s0,48(sp)
    80002026:	f426                	sd	s1,40(sp)
    80002028:	f04a                	sd	s2,32(sp)
    8000202a:	ec4e                	sd	s3,24(sp)
    8000202c:	e852                	sd	s4,16(sp)
    8000202e:	e456                	sd	s5,8(sp)
    80002030:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80002032:	00000097          	auipc	ra,0x0
    80002036:	c38080e7          	jalr	-968(ra) # 80001c6a <myproc>
    8000203a:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    8000203c:	00000097          	auipc	ra,0x0
    80002040:	e38080e7          	jalr	-456(ra) # 80001e74 <allocproc>
    80002044:	10050c63          	beqz	a0,8000215c <fork+0x13c>
    80002048:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    8000204a:	048ab603          	ld	a2,72(s5)
    8000204e:	692c                	ld	a1,80(a0)
    80002050:	050ab503          	ld	a0,80(s5)
    80002054:	fffff097          	auipc	ra,0xfffff
    80002058:	518080e7          	jalr	1304(ra) # 8000156c <uvmcopy>
    8000205c:	04054863          	bltz	a0,800020ac <fork+0x8c>
  np->sz = p->sz;
    80002060:	048ab783          	ld	a5,72(s5)
    80002064:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80002068:	058ab683          	ld	a3,88(s5)
    8000206c:	87b6                	mv	a5,a3
    8000206e:	058a3703          	ld	a4,88(s4)
    80002072:	12068693          	addi	a3,a3,288
    80002076:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    8000207a:	6788                	ld	a0,8(a5)
    8000207c:	6b8c                	ld	a1,16(a5)
    8000207e:	6f90                	ld	a2,24(a5)
    80002080:	01073023          	sd	a6,0(a4)
    80002084:	e708                	sd	a0,8(a4)
    80002086:	eb0c                	sd	a1,16(a4)
    80002088:	ef10                	sd	a2,24(a4)
    8000208a:	02078793          	addi	a5,a5,32
    8000208e:	02070713          	addi	a4,a4,32
    80002092:	fed792e3          	bne	a5,a3,80002076 <fork+0x56>
  np->trapframe->a0 = 0;
    80002096:	058a3783          	ld	a5,88(s4)
    8000209a:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    8000209e:	0d0a8493          	addi	s1,s5,208
    800020a2:	0d0a0913          	addi	s2,s4,208
    800020a6:	150a8993          	addi	s3,s5,336
    800020aa:	a00d                	j	800020cc <fork+0xac>
    freeproc(np);
    800020ac:	8552                	mv	a0,s4
    800020ae:	00000097          	auipc	ra,0x0
    800020b2:	d6e080e7          	jalr	-658(ra) # 80001e1c <freeproc>
    release(&np->lock);
    800020b6:	8552                	mv	a0,s4
    800020b8:	fffff097          	auipc	ra,0xfffff
    800020bc:	bd2080e7          	jalr	-1070(ra) # 80000c8a <release>
    return -1;
    800020c0:	597d                	li	s2,-1
    800020c2:	a059                	j	80002148 <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    800020c4:	04a1                	addi	s1,s1,8
    800020c6:	0921                	addi	s2,s2,8
    800020c8:	01348b63          	beq	s1,s3,800020de <fork+0xbe>
    if(p->ofile[i])
    800020cc:	6088                	ld	a0,0(s1)
    800020ce:	d97d                	beqz	a0,800020c4 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    800020d0:	00002097          	auipc	ra,0x2
    800020d4:	79e080e7          	jalr	1950(ra) # 8000486e <filedup>
    800020d8:	00a93023          	sd	a0,0(s2)
    800020dc:	b7e5                	j	800020c4 <fork+0xa4>
  np->cwd = idup(p->cwd);
    800020de:	150ab503          	ld	a0,336(s5)
    800020e2:	00002097          	auipc	ra,0x2
    800020e6:	912080e7          	jalr	-1774(ra) # 800039f4 <idup>
    800020ea:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    800020ee:	4641                	li	a2,16
    800020f0:	158a8593          	addi	a1,s5,344
    800020f4:	158a0513          	addi	a0,s4,344
    800020f8:	fffff097          	auipc	ra,0xfffff
    800020fc:	d24080e7          	jalr	-732(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80002100:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80002104:	8552                	mv	a0,s4
    80002106:	fffff097          	auipc	ra,0xfffff
    8000210a:	b84080e7          	jalr	-1148(ra) # 80000c8a <release>
  acquire(&wait_lock);
    8000210e:	0000f497          	auipc	s1,0xf
    80002112:	a7a48493          	addi	s1,s1,-1414 # 80010b88 <wait_lock>
    80002116:	8526                	mv	a0,s1
    80002118:	fffff097          	auipc	ra,0xfffff
    8000211c:	abe080e7          	jalr	-1346(ra) # 80000bd6 <acquire>
  np->parent = p;
    80002120:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80002124:	8526                	mv	a0,s1
    80002126:	fffff097          	auipc	ra,0xfffff
    8000212a:	b64080e7          	jalr	-1180(ra) # 80000c8a <release>
  acquire(&np->lock);
    8000212e:	8552                	mv	a0,s4
    80002130:	fffff097          	auipc	ra,0xfffff
    80002134:	aa6080e7          	jalr	-1370(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80002138:	478d                	li	a5,3
    8000213a:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    8000213e:	8552                	mv	a0,s4
    80002140:	fffff097          	auipc	ra,0xfffff
    80002144:	b4a080e7          	jalr	-1206(ra) # 80000c8a <release>
}
    80002148:	854a                	mv	a0,s2
    8000214a:	70e2                	ld	ra,56(sp)
    8000214c:	7442                	ld	s0,48(sp)
    8000214e:	74a2                	ld	s1,40(sp)
    80002150:	7902                	ld	s2,32(sp)
    80002152:	69e2                	ld	s3,24(sp)
    80002154:	6a42                	ld	s4,16(sp)
    80002156:	6aa2                	ld	s5,8(sp)
    80002158:	6121                	addi	sp,sp,64
    8000215a:	8082                	ret
    return -1;
    8000215c:	597d                	li	s2,-1
    8000215e:	b7ed                	j	80002148 <fork+0x128>

0000000080002160 <scheduler>:
{
    80002160:	7139                	addi	sp,sp,-64
    80002162:	fc06                	sd	ra,56(sp)
    80002164:	f822                	sd	s0,48(sp)
    80002166:	f426                	sd	s1,40(sp)
    80002168:	f04a                	sd	s2,32(sp)
    8000216a:	ec4e                	sd	s3,24(sp)
    8000216c:	e852                	sd	s4,16(sp)
    8000216e:	e456                	sd	s5,8(sp)
    80002170:	e05a                	sd	s6,0(sp)
    80002172:	0080                	addi	s0,sp,64
    80002174:	8792                	mv	a5,tp
  int id = r_tp();
    80002176:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002178:	00779a93          	slli	s5,a5,0x7
    8000217c:	0000f717          	auipc	a4,0xf
    80002180:	9f470713          	addi	a4,a4,-1548 # 80010b70 <pid_lock>
    80002184:	9756                	add	a4,a4,s5
    80002186:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    8000218a:	0000f717          	auipc	a4,0xf
    8000218e:	a1e70713          	addi	a4,a4,-1506 # 80010ba8 <cpus+0x8>
    80002192:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80002194:	498d                	li	s3,3
        p->state = RUNNING;
    80002196:	4b11                	li	s6,4
        c->proc = p;
    80002198:	079e                	slli	a5,a5,0x7
    8000219a:	0000fa17          	auipc	s4,0xf
    8000219e:	9d6a0a13          	addi	s4,s4,-1578 # 80010b70 <pid_lock>
    800021a2:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    800021a4:	00014917          	auipc	s2,0x14
    800021a8:	7fc90913          	addi	s2,s2,2044 # 800169a0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021ac:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800021b0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800021b4:	10079073          	csrw	sstatus,a5
    800021b8:	0000f497          	auipc	s1,0xf
    800021bc:	de848493          	addi	s1,s1,-536 # 80010fa0 <proc>
    800021c0:	a811                	j	800021d4 <scheduler+0x74>
      release(&p->lock);
    800021c2:	8526                	mv	a0,s1
    800021c4:	fffff097          	auipc	ra,0xfffff
    800021c8:	ac6080e7          	jalr	-1338(ra) # 80000c8a <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    800021cc:	16848493          	addi	s1,s1,360
    800021d0:	fd248ee3          	beq	s1,s2,800021ac <scheduler+0x4c>
      acquire(&p->lock);
    800021d4:	8526                	mv	a0,s1
    800021d6:	fffff097          	auipc	ra,0xfffff
    800021da:	a00080e7          	jalr	-1536(ra) # 80000bd6 <acquire>
      if(p->state == RUNNABLE) {
    800021de:	4c9c                	lw	a5,24(s1)
    800021e0:	ff3791e3          	bne	a5,s3,800021c2 <scheduler+0x62>
        p->state = RUNNING;
    800021e4:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    800021e8:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    800021ec:	06048593          	addi	a1,s1,96
    800021f0:	8556                	mv	a0,s5
    800021f2:	00000097          	auipc	ra,0x0
    800021f6:	69c080e7          	jalr	1692(ra) # 8000288e <swtch>
        c->proc = 0;
    800021fa:	020a3823          	sd	zero,48(s4)
    800021fe:	b7d1                	j	800021c2 <scheduler+0x62>

0000000080002200 <sched>:
{
    80002200:	7179                	addi	sp,sp,-48
    80002202:	f406                	sd	ra,40(sp)
    80002204:	f022                	sd	s0,32(sp)
    80002206:	ec26                	sd	s1,24(sp)
    80002208:	e84a                	sd	s2,16(sp)
    8000220a:	e44e                	sd	s3,8(sp)
    8000220c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000220e:	00000097          	auipc	ra,0x0
    80002212:	a5c080e7          	jalr	-1444(ra) # 80001c6a <myproc>
    80002216:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002218:	fffff097          	auipc	ra,0xfffff
    8000221c:	944080e7          	jalr	-1724(ra) # 80000b5c <holding>
    80002220:	c93d                	beqz	a0,80002296 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002222:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002224:	2781                	sext.w	a5,a5
    80002226:	079e                	slli	a5,a5,0x7
    80002228:	0000f717          	auipc	a4,0xf
    8000222c:	94870713          	addi	a4,a4,-1720 # 80010b70 <pid_lock>
    80002230:	97ba                	add	a5,a5,a4
    80002232:	0a87a703          	lw	a4,168(a5)
    80002236:	4785                	li	a5,1
    80002238:	06f71763          	bne	a4,a5,800022a6 <sched+0xa6>
  if(p->state == RUNNING)
    8000223c:	4c98                	lw	a4,24(s1)
    8000223e:	4791                	li	a5,4
    80002240:	06f70b63          	beq	a4,a5,800022b6 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002244:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002248:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000224a:	efb5                	bnez	a5,800022c6 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000224c:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000224e:	0000f917          	auipc	s2,0xf
    80002252:	92290913          	addi	s2,s2,-1758 # 80010b70 <pid_lock>
    80002256:	2781                	sext.w	a5,a5
    80002258:	079e                	slli	a5,a5,0x7
    8000225a:	97ca                	add	a5,a5,s2
    8000225c:	0ac7a983          	lw	s3,172(a5)
    80002260:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002262:	2781                	sext.w	a5,a5
    80002264:	079e                	slli	a5,a5,0x7
    80002266:	0000f597          	auipc	a1,0xf
    8000226a:	94258593          	addi	a1,a1,-1726 # 80010ba8 <cpus+0x8>
    8000226e:	95be                	add	a1,a1,a5
    80002270:	06048513          	addi	a0,s1,96
    80002274:	00000097          	auipc	ra,0x0
    80002278:	61a080e7          	jalr	1562(ra) # 8000288e <swtch>
    8000227c:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000227e:	2781                	sext.w	a5,a5
    80002280:	079e                	slli	a5,a5,0x7
    80002282:	97ca                	add	a5,a5,s2
    80002284:	0b37a623          	sw	s3,172(a5)
}
    80002288:	70a2                	ld	ra,40(sp)
    8000228a:	7402                	ld	s0,32(sp)
    8000228c:	64e2                	ld	s1,24(sp)
    8000228e:	6942                	ld	s2,16(sp)
    80002290:	69a2                	ld	s3,8(sp)
    80002292:	6145                	addi	sp,sp,48
    80002294:	8082                	ret
    panic("sched p->lock");
    80002296:	00006517          	auipc	a0,0x6
    8000229a:	fb250513          	addi	a0,a0,-78 # 80008248 <digits+0x208>
    8000229e:	ffffe097          	auipc	ra,0xffffe
    800022a2:	2a0080e7          	jalr	672(ra) # 8000053e <panic>
    panic("sched locks");
    800022a6:	00006517          	auipc	a0,0x6
    800022aa:	fb250513          	addi	a0,a0,-78 # 80008258 <digits+0x218>
    800022ae:	ffffe097          	auipc	ra,0xffffe
    800022b2:	290080e7          	jalr	656(ra) # 8000053e <panic>
    panic("sched running");
    800022b6:	00006517          	auipc	a0,0x6
    800022ba:	fb250513          	addi	a0,a0,-78 # 80008268 <digits+0x228>
    800022be:	ffffe097          	auipc	ra,0xffffe
    800022c2:	280080e7          	jalr	640(ra) # 8000053e <panic>
    panic("sched interruptible");
    800022c6:	00006517          	auipc	a0,0x6
    800022ca:	fb250513          	addi	a0,a0,-78 # 80008278 <digits+0x238>
    800022ce:	ffffe097          	auipc	ra,0xffffe
    800022d2:	270080e7          	jalr	624(ra) # 8000053e <panic>

00000000800022d6 <yield>:
{
    800022d6:	1101                	addi	sp,sp,-32
    800022d8:	ec06                	sd	ra,24(sp)
    800022da:	e822                	sd	s0,16(sp)
    800022dc:	e426                	sd	s1,8(sp)
    800022de:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800022e0:	00000097          	auipc	ra,0x0
    800022e4:	98a080e7          	jalr	-1654(ra) # 80001c6a <myproc>
    800022e8:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022ea:	fffff097          	auipc	ra,0xfffff
    800022ee:	8ec080e7          	jalr	-1812(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    800022f2:	478d                	li	a5,3
    800022f4:	cc9c                	sw	a5,24(s1)
  sched();
    800022f6:	00000097          	auipc	ra,0x0
    800022fa:	f0a080e7          	jalr	-246(ra) # 80002200 <sched>
  release(&p->lock);
    800022fe:	8526                	mv	a0,s1
    80002300:	fffff097          	auipc	ra,0xfffff
    80002304:	98a080e7          	jalr	-1654(ra) # 80000c8a <release>
}
    80002308:	60e2                	ld	ra,24(sp)
    8000230a:	6442                	ld	s0,16(sp)
    8000230c:	64a2                	ld	s1,8(sp)
    8000230e:	6105                	addi	sp,sp,32
    80002310:	8082                	ret

0000000080002312 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002312:	7179                	addi	sp,sp,-48
    80002314:	f406                	sd	ra,40(sp)
    80002316:	f022                	sd	s0,32(sp)
    80002318:	ec26                	sd	s1,24(sp)
    8000231a:	e84a                	sd	s2,16(sp)
    8000231c:	e44e                	sd	s3,8(sp)
    8000231e:	1800                	addi	s0,sp,48
    80002320:	89aa                	mv	s3,a0
    80002322:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002324:	00000097          	auipc	ra,0x0
    80002328:	946080e7          	jalr	-1722(ra) # 80001c6a <myproc>
    8000232c:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000232e:	fffff097          	auipc	ra,0xfffff
    80002332:	8a8080e7          	jalr	-1880(ra) # 80000bd6 <acquire>
  release(lk);
    80002336:	854a                	mv	a0,s2
    80002338:	fffff097          	auipc	ra,0xfffff
    8000233c:	952080e7          	jalr	-1710(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    80002340:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002344:	4789                	li	a5,2
    80002346:	cc9c                	sw	a5,24(s1)

  sched();
    80002348:	00000097          	auipc	ra,0x0
    8000234c:	eb8080e7          	jalr	-328(ra) # 80002200 <sched>

  // Tidy up.
  p->chan = 0;
    80002350:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002354:	8526                	mv	a0,s1
    80002356:	fffff097          	auipc	ra,0xfffff
    8000235a:	934080e7          	jalr	-1740(ra) # 80000c8a <release>
  acquire(lk);
    8000235e:	854a                	mv	a0,s2
    80002360:	fffff097          	auipc	ra,0xfffff
    80002364:	876080e7          	jalr	-1930(ra) # 80000bd6 <acquire>
}
    80002368:	70a2                	ld	ra,40(sp)
    8000236a:	7402                	ld	s0,32(sp)
    8000236c:	64e2                	ld	s1,24(sp)
    8000236e:	6942                	ld	s2,16(sp)
    80002370:	69a2                	ld	s3,8(sp)
    80002372:	6145                	addi	sp,sp,48
    80002374:	8082                	ret

0000000080002376 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002376:	7139                	addi	sp,sp,-64
    80002378:	fc06                	sd	ra,56(sp)
    8000237a:	f822                	sd	s0,48(sp)
    8000237c:	f426                	sd	s1,40(sp)
    8000237e:	f04a                	sd	s2,32(sp)
    80002380:	ec4e                	sd	s3,24(sp)
    80002382:	e852                	sd	s4,16(sp)
    80002384:	e456                	sd	s5,8(sp)
    80002386:	0080                	addi	s0,sp,64
    80002388:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000238a:	0000f497          	auipc	s1,0xf
    8000238e:	c1648493          	addi	s1,s1,-1002 # 80010fa0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002392:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002394:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002396:	00014917          	auipc	s2,0x14
    8000239a:	60a90913          	addi	s2,s2,1546 # 800169a0 <tickslock>
    8000239e:	a811                	j	800023b2 <wakeup+0x3c>
      }
      release(&p->lock);
    800023a0:	8526                	mv	a0,s1
    800023a2:	fffff097          	auipc	ra,0xfffff
    800023a6:	8e8080e7          	jalr	-1816(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800023aa:	16848493          	addi	s1,s1,360
    800023ae:	03248663          	beq	s1,s2,800023da <wakeup+0x64>
    if(p != myproc()){
    800023b2:	00000097          	auipc	ra,0x0
    800023b6:	8b8080e7          	jalr	-1864(ra) # 80001c6a <myproc>
    800023ba:	fea488e3          	beq	s1,a0,800023aa <wakeup+0x34>
      acquire(&p->lock);
    800023be:	8526                	mv	a0,s1
    800023c0:	fffff097          	auipc	ra,0xfffff
    800023c4:	816080e7          	jalr	-2026(ra) # 80000bd6 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800023c8:	4c9c                	lw	a5,24(s1)
    800023ca:	fd379be3          	bne	a5,s3,800023a0 <wakeup+0x2a>
    800023ce:	709c                	ld	a5,32(s1)
    800023d0:	fd4798e3          	bne	a5,s4,800023a0 <wakeup+0x2a>
        p->state = RUNNABLE;
    800023d4:	0154ac23          	sw	s5,24(s1)
    800023d8:	b7e1                	j	800023a0 <wakeup+0x2a>
    }
  }
}
    800023da:	70e2                	ld	ra,56(sp)
    800023dc:	7442                	ld	s0,48(sp)
    800023de:	74a2                	ld	s1,40(sp)
    800023e0:	7902                	ld	s2,32(sp)
    800023e2:	69e2                	ld	s3,24(sp)
    800023e4:	6a42                	ld	s4,16(sp)
    800023e6:	6aa2                	ld	s5,8(sp)
    800023e8:	6121                	addi	sp,sp,64
    800023ea:	8082                	ret

00000000800023ec <reparent>:
{
    800023ec:	7179                	addi	sp,sp,-48
    800023ee:	f406                	sd	ra,40(sp)
    800023f0:	f022                	sd	s0,32(sp)
    800023f2:	ec26                	sd	s1,24(sp)
    800023f4:	e84a                	sd	s2,16(sp)
    800023f6:	e44e                	sd	s3,8(sp)
    800023f8:	e052                	sd	s4,0(sp)
    800023fa:	1800                	addi	s0,sp,48
    800023fc:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800023fe:	0000f497          	auipc	s1,0xf
    80002402:	ba248493          	addi	s1,s1,-1118 # 80010fa0 <proc>
      pp->parent = initproc;
    80002406:	00006a17          	auipc	s4,0x6
    8000240a:	4f2a0a13          	addi	s4,s4,1266 # 800088f8 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000240e:	00014997          	auipc	s3,0x14
    80002412:	59298993          	addi	s3,s3,1426 # 800169a0 <tickslock>
    80002416:	a029                	j	80002420 <reparent+0x34>
    80002418:	16848493          	addi	s1,s1,360
    8000241c:	01348d63          	beq	s1,s3,80002436 <reparent+0x4a>
    if(pp->parent == p){
    80002420:	7c9c                	ld	a5,56(s1)
    80002422:	ff279be3          	bne	a5,s2,80002418 <reparent+0x2c>
      pp->parent = initproc;
    80002426:	000a3503          	ld	a0,0(s4)
    8000242a:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000242c:	00000097          	auipc	ra,0x0
    80002430:	f4a080e7          	jalr	-182(ra) # 80002376 <wakeup>
    80002434:	b7d5                	j	80002418 <reparent+0x2c>
}
    80002436:	70a2                	ld	ra,40(sp)
    80002438:	7402                	ld	s0,32(sp)
    8000243a:	64e2                	ld	s1,24(sp)
    8000243c:	6942                	ld	s2,16(sp)
    8000243e:	69a2                	ld	s3,8(sp)
    80002440:	6a02                	ld	s4,0(sp)
    80002442:	6145                	addi	sp,sp,48
    80002444:	8082                	ret

0000000080002446 <exit>:
{
    80002446:	7179                	addi	sp,sp,-48
    80002448:	f406                	sd	ra,40(sp)
    8000244a:	f022                	sd	s0,32(sp)
    8000244c:	ec26                	sd	s1,24(sp)
    8000244e:	e84a                	sd	s2,16(sp)
    80002450:	e44e                	sd	s3,8(sp)
    80002452:	e052                	sd	s4,0(sp)
    80002454:	1800                	addi	s0,sp,48
    80002456:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002458:	00000097          	auipc	ra,0x0
    8000245c:	812080e7          	jalr	-2030(ra) # 80001c6a <myproc>
    80002460:	89aa                	mv	s3,a0
  if(p == initproc)
    80002462:	00006797          	auipc	a5,0x6
    80002466:	4967b783          	ld	a5,1174(a5) # 800088f8 <initproc>
    8000246a:	0d050493          	addi	s1,a0,208
    8000246e:	15050913          	addi	s2,a0,336
    80002472:	02a79363          	bne	a5,a0,80002498 <exit+0x52>
    panic("init exiting");
    80002476:	00006517          	auipc	a0,0x6
    8000247a:	e1a50513          	addi	a0,a0,-486 # 80008290 <digits+0x250>
    8000247e:	ffffe097          	auipc	ra,0xffffe
    80002482:	0c0080e7          	jalr	192(ra) # 8000053e <panic>
      fileclose(f);
    80002486:	00002097          	auipc	ra,0x2
    8000248a:	43a080e7          	jalr	1082(ra) # 800048c0 <fileclose>
      p->ofile[fd] = 0;
    8000248e:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002492:	04a1                	addi	s1,s1,8
    80002494:	01248563          	beq	s1,s2,8000249e <exit+0x58>
    if(p->ofile[fd]){
    80002498:	6088                	ld	a0,0(s1)
    8000249a:	f575                	bnez	a0,80002486 <exit+0x40>
    8000249c:	bfdd                	j	80002492 <exit+0x4c>
  begin_op();
    8000249e:	00002097          	auipc	ra,0x2
    800024a2:	f56080e7          	jalr	-170(ra) # 800043f4 <begin_op>
  iput(p->cwd);
    800024a6:	1509b503          	ld	a0,336(s3)
    800024aa:	00001097          	auipc	ra,0x1
    800024ae:	742080e7          	jalr	1858(ra) # 80003bec <iput>
  end_op();
    800024b2:	00002097          	auipc	ra,0x2
    800024b6:	fc2080e7          	jalr	-62(ra) # 80004474 <end_op>
  p->cwd = 0;
    800024ba:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800024be:	0000e497          	auipc	s1,0xe
    800024c2:	6ca48493          	addi	s1,s1,1738 # 80010b88 <wait_lock>
    800024c6:	8526                	mv	a0,s1
    800024c8:	ffffe097          	auipc	ra,0xffffe
    800024cc:	70e080e7          	jalr	1806(ra) # 80000bd6 <acquire>
  reparent(p);
    800024d0:	854e                	mv	a0,s3
    800024d2:	00000097          	auipc	ra,0x0
    800024d6:	f1a080e7          	jalr	-230(ra) # 800023ec <reparent>
  wakeup(p->parent);
    800024da:	0389b503          	ld	a0,56(s3)
    800024de:	00000097          	auipc	ra,0x0
    800024e2:	e98080e7          	jalr	-360(ra) # 80002376 <wakeup>
  acquire(&p->lock);
    800024e6:	854e                	mv	a0,s3
    800024e8:	ffffe097          	auipc	ra,0xffffe
    800024ec:	6ee080e7          	jalr	1774(ra) # 80000bd6 <acquire>
  p->xstate = status;
    800024f0:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800024f4:	4795                	li	a5,5
    800024f6:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800024fa:	8526                	mv	a0,s1
    800024fc:	ffffe097          	auipc	ra,0xffffe
    80002500:	78e080e7          	jalr	1934(ra) # 80000c8a <release>
  sched();
    80002504:	00000097          	auipc	ra,0x0
    80002508:	cfc080e7          	jalr	-772(ra) # 80002200 <sched>
  panic("zombie exit");
    8000250c:	00006517          	auipc	a0,0x6
    80002510:	d9450513          	addi	a0,a0,-620 # 800082a0 <digits+0x260>
    80002514:	ffffe097          	auipc	ra,0xffffe
    80002518:	02a080e7          	jalr	42(ra) # 8000053e <panic>

000000008000251c <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000251c:	7179                	addi	sp,sp,-48
    8000251e:	f406                	sd	ra,40(sp)
    80002520:	f022                	sd	s0,32(sp)
    80002522:	ec26                	sd	s1,24(sp)
    80002524:	e84a                	sd	s2,16(sp)
    80002526:	e44e                	sd	s3,8(sp)
    80002528:	1800                	addi	s0,sp,48
    8000252a:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000252c:	0000f497          	auipc	s1,0xf
    80002530:	a7448493          	addi	s1,s1,-1420 # 80010fa0 <proc>
    80002534:	00014997          	auipc	s3,0x14
    80002538:	46c98993          	addi	s3,s3,1132 # 800169a0 <tickslock>
    acquire(&p->lock);
    8000253c:	8526                	mv	a0,s1
    8000253e:	ffffe097          	auipc	ra,0xffffe
    80002542:	698080e7          	jalr	1688(ra) # 80000bd6 <acquire>
    if(p->pid == pid){
    80002546:	589c                	lw	a5,48(s1)
    80002548:	01278d63          	beq	a5,s2,80002562 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000254c:	8526                	mv	a0,s1
    8000254e:	ffffe097          	auipc	ra,0xffffe
    80002552:	73c080e7          	jalr	1852(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002556:	16848493          	addi	s1,s1,360
    8000255a:	ff3491e3          	bne	s1,s3,8000253c <kill+0x20>
  }
  return -1;
    8000255e:	557d                	li	a0,-1
    80002560:	a829                	j	8000257a <kill+0x5e>
      p->killed = 1;
    80002562:	4785                	li	a5,1
    80002564:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002566:	4c98                	lw	a4,24(s1)
    80002568:	4789                	li	a5,2
    8000256a:	00f70f63          	beq	a4,a5,80002588 <kill+0x6c>
      release(&p->lock);
    8000256e:	8526                	mv	a0,s1
    80002570:	ffffe097          	auipc	ra,0xffffe
    80002574:	71a080e7          	jalr	1818(ra) # 80000c8a <release>
      return 0;
    80002578:	4501                	li	a0,0
}
    8000257a:	70a2                	ld	ra,40(sp)
    8000257c:	7402                	ld	s0,32(sp)
    8000257e:	64e2                	ld	s1,24(sp)
    80002580:	6942                	ld	s2,16(sp)
    80002582:	69a2                	ld	s3,8(sp)
    80002584:	6145                	addi	sp,sp,48
    80002586:	8082                	ret
        p->state = RUNNABLE;
    80002588:	478d                	li	a5,3
    8000258a:	cc9c                	sw	a5,24(s1)
    8000258c:	b7cd                	j	8000256e <kill+0x52>

000000008000258e <setkilled>:

void
setkilled(struct proc *p)
{
    8000258e:	1101                	addi	sp,sp,-32
    80002590:	ec06                	sd	ra,24(sp)
    80002592:	e822                	sd	s0,16(sp)
    80002594:	e426                	sd	s1,8(sp)
    80002596:	1000                	addi	s0,sp,32
    80002598:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000259a:	ffffe097          	auipc	ra,0xffffe
    8000259e:	63c080e7          	jalr	1596(ra) # 80000bd6 <acquire>
  p->killed = 1;
    800025a2:	4785                	li	a5,1
    800025a4:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800025a6:	8526                	mv	a0,s1
    800025a8:	ffffe097          	auipc	ra,0xffffe
    800025ac:	6e2080e7          	jalr	1762(ra) # 80000c8a <release>
}
    800025b0:	60e2                	ld	ra,24(sp)
    800025b2:	6442                	ld	s0,16(sp)
    800025b4:	64a2                	ld	s1,8(sp)
    800025b6:	6105                	addi	sp,sp,32
    800025b8:	8082                	ret

00000000800025ba <killed>:

int
killed(struct proc *p)
{
    800025ba:	1101                	addi	sp,sp,-32
    800025bc:	ec06                	sd	ra,24(sp)
    800025be:	e822                	sd	s0,16(sp)
    800025c0:	e426                	sd	s1,8(sp)
    800025c2:	e04a                	sd	s2,0(sp)
    800025c4:	1000                	addi	s0,sp,32
    800025c6:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    800025c8:	ffffe097          	auipc	ra,0xffffe
    800025cc:	60e080e7          	jalr	1550(ra) # 80000bd6 <acquire>
  k = p->killed;
    800025d0:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800025d4:	8526                	mv	a0,s1
    800025d6:	ffffe097          	auipc	ra,0xffffe
    800025da:	6b4080e7          	jalr	1716(ra) # 80000c8a <release>
  return k;
}
    800025de:	854a                	mv	a0,s2
    800025e0:	60e2                	ld	ra,24(sp)
    800025e2:	6442                	ld	s0,16(sp)
    800025e4:	64a2                	ld	s1,8(sp)
    800025e6:	6902                	ld	s2,0(sp)
    800025e8:	6105                	addi	sp,sp,32
    800025ea:	8082                	ret

00000000800025ec <wait>:
{
    800025ec:	715d                	addi	sp,sp,-80
    800025ee:	e486                	sd	ra,72(sp)
    800025f0:	e0a2                	sd	s0,64(sp)
    800025f2:	fc26                	sd	s1,56(sp)
    800025f4:	f84a                	sd	s2,48(sp)
    800025f6:	f44e                	sd	s3,40(sp)
    800025f8:	f052                	sd	s4,32(sp)
    800025fa:	ec56                	sd	s5,24(sp)
    800025fc:	e85a                	sd	s6,16(sp)
    800025fe:	e45e                	sd	s7,8(sp)
    80002600:	e062                	sd	s8,0(sp)
    80002602:	0880                	addi	s0,sp,80
    80002604:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002606:	fffff097          	auipc	ra,0xfffff
    8000260a:	664080e7          	jalr	1636(ra) # 80001c6a <myproc>
    8000260e:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002610:	0000e517          	auipc	a0,0xe
    80002614:	57850513          	addi	a0,a0,1400 # 80010b88 <wait_lock>
    80002618:	ffffe097          	auipc	ra,0xffffe
    8000261c:	5be080e7          	jalr	1470(ra) # 80000bd6 <acquire>
    havekids = 0;
    80002620:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    80002622:	4a15                	li	s4,5
        havekids = 1;
    80002624:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002626:	00014997          	auipc	s3,0x14
    8000262a:	37a98993          	addi	s3,s3,890 # 800169a0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000262e:	0000ec17          	auipc	s8,0xe
    80002632:	55ac0c13          	addi	s8,s8,1370 # 80010b88 <wait_lock>
    havekids = 0;
    80002636:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002638:	0000f497          	auipc	s1,0xf
    8000263c:	96848493          	addi	s1,s1,-1688 # 80010fa0 <proc>
    80002640:	a0bd                	j	800026ae <wait+0xc2>
          pid = pp->pid;
    80002642:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002646:	000b0e63          	beqz	s6,80002662 <wait+0x76>
    8000264a:	4691                	li	a3,4
    8000264c:	02c48613          	addi	a2,s1,44
    80002650:	85da                	mv	a1,s6
    80002652:	05093503          	ld	a0,80(s2)
    80002656:	fffff097          	auipc	ra,0xfffff
    8000265a:	01a080e7          	jalr	26(ra) # 80001670 <copyout>
    8000265e:	02054563          	bltz	a0,80002688 <wait+0x9c>
          freeproc(pp);
    80002662:	8526                	mv	a0,s1
    80002664:	fffff097          	auipc	ra,0xfffff
    80002668:	7b8080e7          	jalr	1976(ra) # 80001e1c <freeproc>
          release(&pp->lock);
    8000266c:	8526                	mv	a0,s1
    8000266e:	ffffe097          	auipc	ra,0xffffe
    80002672:	61c080e7          	jalr	1564(ra) # 80000c8a <release>
          release(&wait_lock);
    80002676:	0000e517          	auipc	a0,0xe
    8000267a:	51250513          	addi	a0,a0,1298 # 80010b88 <wait_lock>
    8000267e:	ffffe097          	auipc	ra,0xffffe
    80002682:	60c080e7          	jalr	1548(ra) # 80000c8a <release>
          return pid;
    80002686:	a0b5                	j	800026f2 <wait+0x106>
            release(&pp->lock);
    80002688:	8526                	mv	a0,s1
    8000268a:	ffffe097          	auipc	ra,0xffffe
    8000268e:	600080e7          	jalr	1536(ra) # 80000c8a <release>
            release(&wait_lock);
    80002692:	0000e517          	auipc	a0,0xe
    80002696:	4f650513          	addi	a0,a0,1270 # 80010b88 <wait_lock>
    8000269a:	ffffe097          	auipc	ra,0xffffe
    8000269e:	5f0080e7          	jalr	1520(ra) # 80000c8a <release>
            return -1;
    800026a2:	59fd                	li	s3,-1
    800026a4:	a0b9                	j	800026f2 <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800026a6:	16848493          	addi	s1,s1,360
    800026aa:	03348463          	beq	s1,s3,800026d2 <wait+0xe6>
      if(pp->parent == p){
    800026ae:	7c9c                	ld	a5,56(s1)
    800026b0:	ff279be3          	bne	a5,s2,800026a6 <wait+0xba>
        acquire(&pp->lock);
    800026b4:	8526                	mv	a0,s1
    800026b6:	ffffe097          	auipc	ra,0xffffe
    800026ba:	520080e7          	jalr	1312(ra) # 80000bd6 <acquire>
        if(pp->state == ZOMBIE){
    800026be:	4c9c                	lw	a5,24(s1)
    800026c0:	f94781e3          	beq	a5,s4,80002642 <wait+0x56>
        release(&pp->lock);
    800026c4:	8526                	mv	a0,s1
    800026c6:	ffffe097          	auipc	ra,0xffffe
    800026ca:	5c4080e7          	jalr	1476(ra) # 80000c8a <release>
        havekids = 1;
    800026ce:	8756                	mv	a4,s5
    800026d0:	bfd9                	j	800026a6 <wait+0xba>
    if(!havekids || killed(p)){
    800026d2:	c719                	beqz	a4,800026e0 <wait+0xf4>
    800026d4:	854a                	mv	a0,s2
    800026d6:	00000097          	auipc	ra,0x0
    800026da:	ee4080e7          	jalr	-284(ra) # 800025ba <killed>
    800026de:	c51d                	beqz	a0,8000270c <wait+0x120>
      release(&wait_lock);
    800026e0:	0000e517          	auipc	a0,0xe
    800026e4:	4a850513          	addi	a0,a0,1192 # 80010b88 <wait_lock>
    800026e8:	ffffe097          	auipc	ra,0xffffe
    800026ec:	5a2080e7          	jalr	1442(ra) # 80000c8a <release>
      return -1;
    800026f0:	59fd                	li	s3,-1
}
    800026f2:	854e                	mv	a0,s3
    800026f4:	60a6                	ld	ra,72(sp)
    800026f6:	6406                	ld	s0,64(sp)
    800026f8:	74e2                	ld	s1,56(sp)
    800026fa:	7942                	ld	s2,48(sp)
    800026fc:	79a2                	ld	s3,40(sp)
    800026fe:	7a02                	ld	s4,32(sp)
    80002700:	6ae2                	ld	s5,24(sp)
    80002702:	6b42                	ld	s6,16(sp)
    80002704:	6ba2                	ld	s7,8(sp)
    80002706:	6c02                	ld	s8,0(sp)
    80002708:	6161                	addi	sp,sp,80
    8000270a:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000270c:	85e2                	mv	a1,s8
    8000270e:	854a                	mv	a0,s2
    80002710:	00000097          	auipc	ra,0x0
    80002714:	c02080e7          	jalr	-1022(ra) # 80002312 <sleep>
    havekids = 0;
    80002718:	bf39                	j	80002636 <wait+0x4a>

000000008000271a <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000271a:	7179                	addi	sp,sp,-48
    8000271c:	f406                	sd	ra,40(sp)
    8000271e:	f022                	sd	s0,32(sp)
    80002720:	ec26                	sd	s1,24(sp)
    80002722:	e84a                	sd	s2,16(sp)
    80002724:	e44e                	sd	s3,8(sp)
    80002726:	e052                	sd	s4,0(sp)
    80002728:	1800                	addi	s0,sp,48
    8000272a:	84aa                	mv	s1,a0
    8000272c:	892e                	mv	s2,a1
    8000272e:	89b2                	mv	s3,a2
    80002730:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002732:	fffff097          	auipc	ra,0xfffff
    80002736:	538080e7          	jalr	1336(ra) # 80001c6a <myproc>
  if(user_dst){
    8000273a:	c08d                	beqz	s1,8000275c <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000273c:	86d2                	mv	a3,s4
    8000273e:	864e                	mv	a2,s3
    80002740:	85ca                	mv	a1,s2
    80002742:	6928                	ld	a0,80(a0)
    80002744:	fffff097          	auipc	ra,0xfffff
    80002748:	f2c080e7          	jalr	-212(ra) # 80001670 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000274c:	70a2                	ld	ra,40(sp)
    8000274e:	7402                	ld	s0,32(sp)
    80002750:	64e2                	ld	s1,24(sp)
    80002752:	6942                	ld	s2,16(sp)
    80002754:	69a2                	ld	s3,8(sp)
    80002756:	6a02                	ld	s4,0(sp)
    80002758:	6145                	addi	sp,sp,48
    8000275a:	8082                	ret
    memmove((char *)dst, src, len);
    8000275c:	000a061b          	sext.w	a2,s4
    80002760:	85ce                	mv	a1,s3
    80002762:	854a                	mv	a0,s2
    80002764:	ffffe097          	auipc	ra,0xffffe
    80002768:	5ca080e7          	jalr	1482(ra) # 80000d2e <memmove>
    return 0;
    8000276c:	8526                	mv	a0,s1
    8000276e:	bff9                	j	8000274c <either_copyout+0x32>

0000000080002770 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002770:	7179                	addi	sp,sp,-48
    80002772:	f406                	sd	ra,40(sp)
    80002774:	f022                	sd	s0,32(sp)
    80002776:	ec26                	sd	s1,24(sp)
    80002778:	e84a                	sd	s2,16(sp)
    8000277a:	e44e                	sd	s3,8(sp)
    8000277c:	e052                	sd	s4,0(sp)
    8000277e:	1800                	addi	s0,sp,48
    80002780:	892a                	mv	s2,a0
    80002782:	84ae                	mv	s1,a1
    80002784:	89b2                	mv	s3,a2
    80002786:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002788:	fffff097          	auipc	ra,0xfffff
    8000278c:	4e2080e7          	jalr	1250(ra) # 80001c6a <myproc>
  if(user_src){
    80002790:	c08d                	beqz	s1,800027b2 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002792:	86d2                	mv	a3,s4
    80002794:	864e                	mv	a2,s3
    80002796:	85ca                	mv	a1,s2
    80002798:	6928                	ld	a0,80(a0)
    8000279a:	fffff097          	auipc	ra,0xfffff
    8000279e:	f62080e7          	jalr	-158(ra) # 800016fc <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800027a2:	70a2                	ld	ra,40(sp)
    800027a4:	7402                	ld	s0,32(sp)
    800027a6:	64e2                	ld	s1,24(sp)
    800027a8:	6942                	ld	s2,16(sp)
    800027aa:	69a2                	ld	s3,8(sp)
    800027ac:	6a02                	ld	s4,0(sp)
    800027ae:	6145                	addi	sp,sp,48
    800027b0:	8082                	ret
    memmove(dst, (char*)src, len);
    800027b2:	000a061b          	sext.w	a2,s4
    800027b6:	85ce                	mv	a1,s3
    800027b8:	854a                	mv	a0,s2
    800027ba:	ffffe097          	auipc	ra,0xffffe
    800027be:	574080e7          	jalr	1396(ra) # 80000d2e <memmove>
    return 0;
    800027c2:	8526                	mv	a0,s1
    800027c4:	bff9                	j	800027a2 <either_copyin+0x32>

00000000800027c6 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800027c6:	715d                	addi	sp,sp,-80
    800027c8:	e486                	sd	ra,72(sp)
    800027ca:	e0a2                	sd	s0,64(sp)
    800027cc:	fc26                	sd	s1,56(sp)
    800027ce:	f84a                	sd	s2,48(sp)
    800027d0:	f44e                	sd	s3,40(sp)
    800027d2:	f052                	sd	s4,32(sp)
    800027d4:	ec56                	sd	s5,24(sp)
    800027d6:	e85a                	sd	s6,16(sp)
    800027d8:	e45e                	sd	s7,8(sp)
    800027da:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800027dc:	00006517          	auipc	a0,0x6
    800027e0:	8ec50513          	addi	a0,a0,-1812 # 800080c8 <digits+0x88>
    800027e4:	ffffe097          	auipc	ra,0xffffe
    800027e8:	da4080e7          	jalr	-604(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800027ec:	0000f497          	auipc	s1,0xf
    800027f0:	90c48493          	addi	s1,s1,-1780 # 800110f8 <proc+0x158>
    800027f4:	00014917          	auipc	s2,0x14
    800027f8:	30490913          	addi	s2,s2,772 # 80016af8 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027fc:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800027fe:	00006997          	auipc	s3,0x6
    80002802:	ab298993          	addi	s3,s3,-1358 # 800082b0 <digits+0x270>
    printf("%d %s %s", p->pid, state, p->name);
    80002806:	00006a97          	auipc	s5,0x6
    8000280a:	ab2a8a93          	addi	s5,s5,-1358 # 800082b8 <digits+0x278>
    printf("\n");
    8000280e:	00006a17          	auipc	s4,0x6
    80002812:	8baa0a13          	addi	s4,s4,-1862 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002816:	00006b97          	auipc	s7,0x6
    8000281a:	ae2b8b93          	addi	s7,s7,-1310 # 800082f8 <states.0>
    8000281e:	a00d                	j	80002840 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002820:	ed86a583          	lw	a1,-296(a3)
    80002824:	8556                	mv	a0,s5
    80002826:	ffffe097          	auipc	ra,0xffffe
    8000282a:	d62080e7          	jalr	-670(ra) # 80000588 <printf>
    printf("\n");
    8000282e:	8552                	mv	a0,s4
    80002830:	ffffe097          	auipc	ra,0xffffe
    80002834:	d58080e7          	jalr	-680(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002838:	16848493          	addi	s1,s1,360
    8000283c:	03248163          	beq	s1,s2,8000285e <procdump+0x98>
    if(p->state == UNUSED)
    80002840:	86a6                	mv	a3,s1
    80002842:	ec04a783          	lw	a5,-320(s1)
    80002846:	dbed                	beqz	a5,80002838 <procdump+0x72>
      state = "???";
    80002848:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000284a:	fcfb6be3          	bltu	s6,a5,80002820 <procdump+0x5a>
    8000284e:	1782                	slli	a5,a5,0x20
    80002850:	9381                	srli	a5,a5,0x20
    80002852:	078e                	slli	a5,a5,0x3
    80002854:	97de                	add	a5,a5,s7
    80002856:	6390                	ld	a2,0(a5)
    80002858:	f661                	bnez	a2,80002820 <procdump+0x5a>
      state = "???";
    8000285a:	864e                	mv	a2,s3
    8000285c:	b7d1                	j	80002820 <procdump+0x5a>
  }
}
    8000285e:	60a6                	ld	ra,72(sp)
    80002860:	6406                	ld	s0,64(sp)
    80002862:	74e2                	ld	s1,56(sp)
    80002864:	7942                	ld	s2,48(sp)
    80002866:	79a2                	ld	s3,40(sp)
    80002868:	7a02                	ld	s4,32(sp)
    8000286a:	6ae2                	ld	s5,24(sp)
    8000286c:	6b42                	ld	s6,16(sp)
    8000286e:	6ba2                	ld	s7,8(sp)
    80002870:	6161                	addi	sp,sp,80
    80002872:	8082                	ret

0000000080002874 <sys_get_sz>:

// task1:
int sys_get_sz(void) {
    80002874:	1141                	addi	sp,sp,-16
    80002876:	e406                	sd	ra,8(sp)
    80002878:	e022                	sd	s0,0(sp)
    8000287a:	0800                	addi	s0,sp,16
  return myproc()->sz;
    8000287c:	fffff097          	auipc	ra,0xfffff
    80002880:	3ee080e7          	jalr	1006(ra) # 80001c6a <myproc>
    80002884:	4528                	lw	a0,72(a0)
    80002886:	60a2                	ld	ra,8(sp)
    80002888:	6402                	ld	s0,0(sp)
    8000288a:	0141                	addi	sp,sp,16
    8000288c:	8082                	ret

000000008000288e <swtch>:
    8000288e:	00153023          	sd	ra,0(a0)
    80002892:	00253423          	sd	sp,8(a0)
    80002896:	e900                	sd	s0,16(a0)
    80002898:	ed04                	sd	s1,24(a0)
    8000289a:	03253023          	sd	s2,32(a0)
    8000289e:	03353423          	sd	s3,40(a0)
    800028a2:	03453823          	sd	s4,48(a0)
    800028a6:	03553c23          	sd	s5,56(a0)
    800028aa:	05653023          	sd	s6,64(a0)
    800028ae:	05753423          	sd	s7,72(a0)
    800028b2:	05853823          	sd	s8,80(a0)
    800028b6:	05953c23          	sd	s9,88(a0)
    800028ba:	07a53023          	sd	s10,96(a0)
    800028be:	07b53423          	sd	s11,104(a0)
    800028c2:	0005b083          	ld	ra,0(a1)
    800028c6:	0085b103          	ld	sp,8(a1)
    800028ca:	6980                	ld	s0,16(a1)
    800028cc:	6d84                	ld	s1,24(a1)
    800028ce:	0205b903          	ld	s2,32(a1)
    800028d2:	0285b983          	ld	s3,40(a1)
    800028d6:	0305ba03          	ld	s4,48(a1)
    800028da:	0385ba83          	ld	s5,56(a1)
    800028de:	0405bb03          	ld	s6,64(a1)
    800028e2:	0485bb83          	ld	s7,72(a1)
    800028e6:	0505bc03          	ld	s8,80(a1)
    800028ea:	0585bc83          	ld	s9,88(a1)
    800028ee:	0605bd03          	ld	s10,96(a1)
    800028f2:	0685bd83          	ld	s11,104(a1)
    800028f6:	8082                	ret

00000000800028f8 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800028f8:	1141                	addi	sp,sp,-16
    800028fa:	e406                	sd	ra,8(sp)
    800028fc:	e022                	sd	s0,0(sp)
    800028fe:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002900:	00006597          	auipc	a1,0x6
    80002904:	a2858593          	addi	a1,a1,-1496 # 80008328 <states.0+0x30>
    80002908:	00014517          	auipc	a0,0x14
    8000290c:	09850513          	addi	a0,a0,152 # 800169a0 <tickslock>
    80002910:	ffffe097          	auipc	ra,0xffffe
    80002914:	236080e7          	jalr	566(ra) # 80000b46 <initlock>
}
    80002918:	60a2                	ld	ra,8(sp)
    8000291a:	6402                	ld	s0,0(sp)
    8000291c:	0141                	addi	sp,sp,16
    8000291e:	8082                	ret

0000000080002920 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002920:	1141                	addi	sp,sp,-16
    80002922:	e422                	sd	s0,8(sp)
    80002924:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002926:	00003797          	auipc	a5,0x3
    8000292a:	5ea78793          	addi	a5,a5,1514 # 80005f10 <kernelvec>
    8000292e:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002932:	6422                	ld	s0,8(sp)
    80002934:	0141                	addi	sp,sp,16
    80002936:	8082                	ret

0000000080002938 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002938:	1141                	addi	sp,sp,-16
    8000293a:	e406                	sd	ra,8(sp)
    8000293c:	e022                	sd	s0,0(sp)
    8000293e:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002940:	fffff097          	auipc	ra,0xfffff
    80002944:	32a080e7          	jalr	810(ra) # 80001c6a <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002948:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000294c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000294e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002952:	00004617          	auipc	a2,0x4
    80002956:	6ae60613          	addi	a2,a2,1710 # 80007000 <_trampoline>
    8000295a:	00004697          	auipc	a3,0x4
    8000295e:	6a668693          	addi	a3,a3,1702 # 80007000 <_trampoline>
    80002962:	8e91                	sub	a3,a3,a2
    80002964:	040007b7          	lui	a5,0x4000
    80002968:	17fd                	addi	a5,a5,-1
    8000296a:	07b2                	slli	a5,a5,0xc
    8000296c:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000296e:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002972:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002974:	180026f3          	csrr	a3,satp
    80002978:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000297a:	6d38                	ld	a4,88(a0)
    8000297c:	6134                	ld	a3,64(a0)
    8000297e:	6585                	lui	a1,0x1
    80002980:	96ae                	add	a3,a3,a1
    80002982:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002984:	6d38                	ld	a4,88(a0)
    80002986:	00000697          	auipc	a3,0x0
    8000298a:	13068693          	addi	a3,a3,304 # 80002ab6 <usertrap>
    8000298e:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002990:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002992:	8692                	mv	a3,tp
    80002994:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002996:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000299a:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000299e:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029a2:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800029a6:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029a8:	6f18                	ld	a4,24(a4)
    800029aa:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800029ae:	6928                	ld	a0,80(a0)
    800029b0:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800029b2:	00004717          	auipc	a4,0x4
    800029b6:	6ea70713          	addi	a4,a4,1770 # 8000709c <userret>
    800029ba:	8f11                	sub	a4,a4,a2
    800029bc:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800029be:	577d                	li	a4,-1
    800029c0:	177e                	slli	a4,a4,0x3f
    800029c2:	8d59                	or	a0,a0,a4
    800029c4:	9782                	jalr	a5
}
    800029c6:	60a2                	ld	ra,8(sp)
    800029c8:	6402                	ld	s0,0(sp)
    800029ca:	0141                	addi	sp,sp,16
    800029cc:	8082                	ret

00000000800029ce <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800029ce:	1101                	addi	sp,sp,-32
    800029d0:	ec06                	sd	ra,24(sp)
    800029d2:	e822                	sd	s0,16(sp)
    800029d4:	e426                	sd	s1,8(sp)
    800029d6:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800029d8:	00014497          	auipc	s1,0x14
    800029dc:	fc848493          	addi	s1,s1,-56 # 800169a0 <tickslock>
    800029e0:	8526                	mv	a0,s1
    800029e2:	ffffe097          	auipc	ra,0xffffe
    800029e6:	1f4080e7          	jalr	500(ra) # 80000bd6 <acquire>
  ticks++;
    800029ea:	00006517          	auipc	a0,0x6
    800029ee:	f1650513          	addi	a0,a0,-234 # 80008900 <ticks>
    800029f2:	411c                	lw	a5,0(a0)
    800029f4:	2785                	addiw	a5,a5,1
    800029f6:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800029f8:	00000097          	auipc	ra,0x0
    800029fc:	97e080e7          	jalr	-1666(ra) # 80002376 <wakeup>
  release(&tickslock);
    80002a00:	8526                	mv	a0,s1
    80002a02:	ffffe097          	auipc	ra,0xffffe
    80002a06:	288080e7          	jalr	648(ra) # 80000c8a <release>
}
    80002a0a:	60e2                	ld	ra,24(sp)
    80002a0c:	6442                	ld	s0,16(sp)
    80002a0e:	64a2                	ld	s1,8(sp)
    80002a10:	6105                	addi	sp,sp,32
    80002a12:	8082                	ret

0000000080002a14 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002a14:	1101                	addi	sp,sp,-32
    80002a16:	ec06                	sd	ra,24(sp)
    80002a18:	e822                	sd	s0,16(sp)
    80002a1a:	e426                	sd	s1,8(sp)
    80002a1c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a1e:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002a22:	00074d63          	bltz	a4,80002a3c <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002a26:	57fd                	li	a5,-1
    80002a28:	17fe                	slli	a5,a5,0x3f
    80002a2a:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002a2c:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002a2e:	06f70363          	beq	a4,a5,80002a94 <devintr+0x80>
  }
}
    80002a32:	60e2                	ld	ra,24(sp)
    80002a34:	6442                	ld	s0,16(sp)
    80002a36:	64a2                	ld	s1,8(sp)
    80002a38:	6105                	addi	sp,sp,32
    80002a3a:	8082                	ret
     (scause & 0xff) == 9){
    80002a3c:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002a40:	46a5                	li	a3,9
    80002a42:	fed792e3          	bne	a5,a3,80002a26 <devintr+0x12>
    int irq = plic_claim();
    80002a46:	00003097          	auipc	ra,0x3
    80002a4a:	5d2080e7          	jalr	1490(ra) # 80006018 <plic_claim>
    80002a4e:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002a50:	47a9                	li	a5,10
    80002a52:	02f50763          	beq	a0,a5,80002a80 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002a56:	4785                	li	a5,1
    80002a58:	02f50963          	beq	a0,a5,80002a8a <devintr+0x76>
    return 1;
    80002a5c:	4505                	li	a0,1
    } else if(irq){
    80002a5e:	d8f1                	beqz	s1,80002a32 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002a60:	85a6                	mv	a1,s1
    80002a62:	00006517          	auipc	a0,0x6
    80002a66:	8ce50513          	addi	a0,a0,-1842 # 80008330 <states.0+0x38>
    80002a6a:	ffffe097          	auipc	ra,0xffffe
    80002a6e:	b1e080e7          	jalr	-1250(ra) # 80000588 <printf>
      plic_complete(irq);
    80002a72:	8526                	mv	a0,s1
    80002a74:	00003097          	auipc	ra,0x3
    80002a78:	5c8080e7          	jalr	1480(ra) # 8000603c <plic_complete>
    return 1;
    80002a7c:	4505                	li	a0,1
    80002a7e:	bf55                	j	80002a32 <devintr+0x1e>
      uartintr();
    80002a80:	ffffe097          	auipc	ra,0xffffe
    80002a84:	f1a080e7          	jalr	-230(ra) # 8000099a <uartintr>
    80002a88:	b7ed                	j	80002a72 <devintr+0x5e>
      virtio_disk_intr();
    80002a8a:	00004097          	auipc	ra,0x4
    80002a8e:	a7e080e7          	jalr	-1410(ra) # 80006508 <virtio_disk_intr>
    80002a92:	b7c5                	j	80002a72 <devintr+0x5e>
    if(cpuid() == 0){
    80002a94:	fffff097          	auipc	ra,0xfffff
    80002a98:	1aa080e7          	jalr	426(ra) # 80001c3e <cpuid>
    80002a9c:	c901                	beqz	a0,80002aac <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002a9e:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002aa2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002aa4:	14479073          	csrw	sip,a5
    return 2;
    80002aa8:	4509                	li	a0,2
    80002aaa:	b761                	j	80002a32 <devintr+0x1e>
      clockintr();
    80002aac:	00000097          	auipc	ra,0x0
    80002ab0:	f22080e7          	jalr	-222(ra) # 800029ce <clockintr>
    80002ab4:	b7ed                	j	80002a9e <devintr+0x8a>

0000000080002ab6 <usertrap>:
{
    80002ab6:	1101                	addi	sp,sp,-32
    80002ab8:	ec06                	sd	ra,24(sp)
    80002aba:	e822                	sd	s0,16(sp)
    80002abc:	e426                	sd	s1,8(sp)
    80002abe:	e04a                	sd	s2,0(sp)
    80002ac0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ac2:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002ac6:	1007f793          	andi	a5,a5,256
    80002aca:	e3b1                	bnez	a5,80002b0e <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002acc:	00003797          	auipc	a5,0x3
    80002ad0:	44478793          	addi	a5,a5,1092 # 80005f10 <kernelvec>
    80002ad4:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002ad8:	fffff097          	auipc	ra,0xfffff
    80002adc:	192080e7          	jalr	402(ra) # 80001c6a <myproc>
    80002ae0:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002ae2:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ae4:	14102773          	csrr	a4,sepc
    80002ae8:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002aea:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002aee:	47a1                	li	a5,8
    80002af0:	02f70763          	beq	a4,a5,80002b1e <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    80002af4:	00000097          	auipc	ra,0x0
    80002af8:	f20080e7          	jalr	-224(ra) # 80002a14 <devintr>
    80002afc:	892a                	mv	s2,a0
    80002afe:	c151                	beqz	a0,80002b82 <usertrap+0xcc>
  if(killed(p))
    80002b00:	8526                	mv	a0,s1
    80002b02:	00000097          	auipc	ra,0x0
    80002b06:	ab8080e7          	jalr	-1352(ra) # 800025ba <killed>
    80002b0a:	c929                	beqz	a0,80002b5c <usertrap+0xa6>
    80002b0c:	a099                	j	80002b52 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002b0e:	00006517          	auipc	a0,0x6
    80002b12:	84250513          	addi	a0,a0,-1982 # 80008350 <states.0+0x58>
    80002b16:	ffffe097          	auipc	ra,0xffffe
    80002b1a:	a28080e7          	jalr	-1496(ra) # 8000053e <panic>
    if(killed(p))
    80002b1e:	00000097          	auipc	ra,0x0
    80002b22:	a9c080e7          	jalr	-1380(ra) # 800025ba <killed>
    80002b26:	e921                	bnez	a0,80002b76 <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002b28:	6cb8                	ld	a4,88(s1)
    80002b2a:	6f1c                	ld	a5,24(a4)
    80002b2c:	0791                	addi	a5,a5,4
    80002b2e:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b30:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b34:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b38:	10079073          	csrw	sstatus,a5
    syscall();
    80002b3c:	00000097          	auipc	ra,0x0
    80002b40:	2d4080e7          	jalr	724(ra) # 80002e10 <syscall>
  if(killed(p))
    80002b44:	8526                	mv	a0,s1
    80002b46:	00000097          	auipc	ra,0x0
    80002b4a:	a74080e7          	jalr	-1420(ra) # 800025ba <killed>
    80002b4e:	c911                	beqz	a0,80002b62 <usertrap+0xac>
    80002b50:	4901                	li	s2,0
    exit(-1);
    80002b52:	557d                	li	a0,-1
    80002b54:	00000097          	auipc	ra,0x0
    80002b58:	8f2080e7          	jalr	-1806(ra) # 80002446 <exit>
  if(which_dev == 2)
    80002b5c:	4789                	li	a5,2
    80002b5e:	04f90f63          	beq	s2,a5,80002bbc <usertrap+0x106>
  usertrapret();
    80002b62:	00000097          	auipc	ra,0x0
    80002b66:	dd6080e7          	jalr	-554(ra) # 80002938 <usertrapret>
}
    80002b6a:	60e2                	ld	ra,24(sp)
    80002b6c:	6442                	ld	s0,16(sp)
    80002b6e:	64a2                	ld	s1,8(sp)
    80002b70:	6902                	ld	s2,0(sp)
    80002b72:	6105                	addi	sp,sp,32
    80002b74:	8082                	ret
      exit(-1);
    80002b76:	557d                	li	a0,-1
    80002b78:	00000097          	auipc	ra,0x0
    80002b7c:	8ce080e7          	jalr	-1842(ra) # 80002446 <exit>
    80002b80:	b765                	j	80002b28 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b82:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002b86:	5890                	lw	a2,48(s1)
    80002b88:	00005517          	auipc	a0,0x5
    80002b8c:	7e850513          	addi	a0,a0,2024 # 80008370 <states.0+0x78>
    80002b90:	ffffe097          	auipc	ra,0xffffe
    80002b94:	9f8080e7          	jalr	-1544(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b98:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b9c:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ba0:	00006517          	auipc	a0,0x6
    80002ba4:	80050513          	addi	a0,a0,-2048 # 800083a0 <states.0+0xa8>
    80002ba8:	ffffe097          	auipc	ra,0xffffe
    80002bac:	9e0080e7          	jalr	-1568(ra) # 80000588 <printf>
    setkilled(p);
    80002bb0:	8526                	mv	a0,s1
    80002bb2:	00000097          	auipc	ra,0x0
    80002bb6:	9dc080e7          	jalr	-1572(ra) # 8000258e <setkilled>
    80002bba:	b769                	j	80002b44 <usertrap+0x8e>
    yield();
    80002bbc:	fffff097          	auipc	ra,0xfffff
    80002bc0:	71a080e7          	jalr	1818(ra) # 800022d6 <yield>
    80002bc4:	bf79                	j	80002b62 <usertrap+0xac>

0000000080002bc6 <kerneltrap>:
{
    80002bc6:	7179                	addi	sp,sp,-48
    80002bc8:	f406                	sd	ra,40(sp)
    80002bca:	f022                	sd	s0,32(sp)
    80002bcc:	ec26                	sd	s1,24(sp)
    80002bce:	e84a                	sd	s2,16(sp)
    80002bd0:	e44e                	sd	s3,8(sp)
    80002bd2:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bd4:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bd8:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bdc:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002be0:	1004f793          	andi	a5,s1,256
    80002be4:	cb85                	beqz	a5,80002c14 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002be6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002bea:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002bec:	ef85                	bnez	a5,80002c24 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002bee:	00000097          	auipc	ra,0x0
    80002bf2:	e26080e7          	jalr	-474(ra) # 80002a14 <devintr>
    80002bf6:	cd1d                	beqz	a0,80002c34 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002bf8:	4789                	li	a5,2
    80002bfa:	06f50a63          	beq	a0,a5,80002c6e <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002bfe:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c02:	10049073          	csrw	sstatus,s1
}
    80002c06:	70a2                	ld	ra,40(sp)
    80002c08:	7402                	ld	s0,32(sp)
    80002c0a:	64e2                	ld	s1,24(sp)
    80002c0c:	6942                	ld	s2,16(sp)
    80002c0e:	69a2                	ld	s3,8(sp)
    80002c10:	6145                	addi	sp,sp,48
    80002c12:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c14:	00005517          	auipc	a0,0x5
    80002c18:	7ac50513          	addi	a0,a0,1964 # 800083c0 <states.0+0xc8>
    80002c1c:	ffffe097          	auipc	ra,0xffffe
    80002c20:	922080e7          	jalr	-1758(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002c24:	00005517          	auipc	a0,0x5
    80002c28:	7c450513          	addi	a0,a0,1988 # 800083e8 <states.0+0xf0>
    80002c2c:	ffffe097          	auipc	ra,0xffffe
    80002c30:	912080e7          	jalr	-1774(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002c34:	85ce                	mv	a1,s3
    80002c36:	00005517          	auipc	a0,0x5
    80002c3a:	7d250513          	addi	a0,a0,2002 # 80008408 <states.0+0x110>
    80002c3e:	ffffe097          	auipc	ra,0xffffe
    80002c42:	94a080e7          	jalr	-1718(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c46:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c4a:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c4e:	00005517          	auipc	a0,0x5
    80002c52:	7ca50513          	addi	a0,a0,1994 # 80008418 <states.0+0x120>
    80002c56:	ffffe097          	auipc	ra,0xffffe
    80002c5a:	932080e7          	jalr	-1742(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002c5e:	00005517          	auipc	a0,0x5
    80002c62:	7d250513          	addi	a0,a0,2002 # 80008430 <states.0+0x138>
    80002c66:	ffffe097          	auipc	ra,0xffffe
    80002c6a:	8d8080e7          	jalr	-1832(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c6e:	fffff097          	auipc	ra,0xfffff
    80002c72:	ffc080e7          	jalr	-4(ra) # 80001c6a <myproc>
    80002c76:	d541                	beqz	a0,80002bfe <kerneltrap+0x38>
    80002c78:	fffff097          	auipc	ra,0xfffff
    80002c7c:	ff2080e7          	jalr	-14(ra) # 80001c6a <myproc>
    80002c80:	4d18                	lw	a4,24(a0)
    80002c82:	4791                	li	a5,4
    80002c84:	f6f71de3          	bne	a4,a5,80002bfe <kerneltrap+0x38>
    yield();
    80002c88:	fffff097          	auipc	ra,0xfffff
    80002c8c:	64e080e7          	jalr	1614(ra) # 800022d6 <yield>
    80002c90:	b7bd                	j	80002bfe <kerneltrap+0x38>

0000000080002c92 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002c92:	1101                	addi	sp,sp,-32
    80002c94:	ec06                	sd	ra,24(sp)
    80002c96:	e822                	sd	s0,16(sp)
    80002c98:	e426                	sd	s1,8(sp)
    80002c9a:	1000                	addi	s0,sp,32
    80002c9c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002c9e:	fffff097          	auipc	ra,0xfffff
    80002ca2:	fcc080e7          	jalr	-52(ra) # 80001c6a <myproc>
  switch (n) {
    80002ca6:	4795                	li	a5,5
    80002ca8:	0497e163          	bltu	a5,s1,80002cea <argraw+0x58>
    80002cac:	048a                	slli	s1,s1,0x2
    80002cae:	00005717          	auipc	a4,0x5
    80002cb2:	7ba70713          	addi	a4,a4,1978 # 80008468 <states.0+0x170>
    80002cb6:	94ba                	add	s1,s1,a4
    80002cb8:	409c                	lw	a5,0(s1)
    80002cba:	97ba                	add	a5,a5,a4
    80002cbc:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002cbe:	6d3c                	ld	a5,88(a0)
    80002cc0:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002cc2:	60e2                	ld	ra,24(sp)
    80002cc4:	6442                	ld	s0,16(sp)
    80002cc6:	64a2                	ld	s1,8(sp)
    80002cc8:	6105                	addi	sp,sp,32
    80002cca:	8082                	ret
    return p->trapframe->a1;
    80002ccc:	6d3c                	ld	a5,88(a0)
    80002cce:	7fa8                	ld	a0,120(a5)
    80002cd0:	bfcd                	j	80002cc2 <argraw+0x30>
    return p->trapframe->a2;
    80002cd2:	6d3c                	ld	a5,88(a0)
    80002cd4:	63c8                	ld	a0,128(a5)
    80002cd6:	b7f5                	j	80002cc2 <argraw+0x30>
    return p->trapframe->a3;
    80002cd8:	6d3c                	ld	a5,88(a0)
    80002cda:	67c8                	ld	a0,136(a5)
    80002cdc:	b7dd                	j	80002cc2 <argraw+0x30>
    return p->trapframe->a4;
    80002cde:	6d3c                	ld	a5,88(a0)
    80002ce0:	6bc8                	ld	a0,144(a5)
    80002ce2:	b7c5                	j	80002cc2 <argraw+0x30>
    return p->trapframe->a5;
    80002ce4:	6d3c                	ld	a5,88(a0)
    80002ce6:	6fc8                	ld	a0,152(a5)
    80002ce8:	bfe9                	j	80002cc2 <argraw+0x30>
  panic("argraw");
    80002cea:	00005517          	auipc	a0,0x5
    80002cee:	75650513          	addi	a0,a0,1878 # 80008440 <states.0+0x148>
    80002cf2:	ffffe097          	auipc	ra,0xffffe
    80002cf6:	84c080e7          	jalr	-1972(ra) # 8000053e <panic>

0000000080002cfa <fetchaddr>:
{
    80002cfa:	1101                	addi	sp,sp,-32
    80002cfc:	ec06                	sd	ra,24(sp)
    80002cfe:	e822                	sd	s0,16(sp)
    80002d00:	e426                	sd	s1,8(sp)
    80002d02:	e04a                	sd	s2,0(sp)
    80002d04:	1000                	addi	s0,sp,32
    80002d06:	84aa                	mv	s1,a0
    80002d08:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d0a:	fffff097          	auipc	ra,0xfffff
    80002d0e:	f60080e7          	jalr	-160(ra) # 80001c6a <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002d12:	653c                	ld	a5,72(a0)
    80002d14:	02f4f863          	bgeu	s1,a5,80002d44 <fetchaddr+0x4a>
    80002d18:	00848713          	addi	a4,s1,8
    80002d1c:	02e7e663          	bltu	a5,a4,80002d48 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d20:	46a1                	li	a3,8
    80002d22:	8626                	mv	a2,s1
    80002d24:	85ca                	mv	a1,s2
    80002d26:	6928                	ld	a0,80(a0)
    80002d28:	fffff097          	auipc	ra,0xfffff
    80002d2c:	9d4080e7          	jalr	-1580(ra) # 800016fc <copyin>
    80002d30:	00a03533          	snez	a0,a0
    80002d34:	40a00533          	neg	a0,a0
}
    80002d38:	60e2                	ld	ra,24(sp)
    80002d3a:	6442                	ld	s0,16(sp)
    80002d3c:	64a2                	ld	s1,8(sp)
    80002d3e:	6902                	ld	s2,0(sp)
    80002d40:	6105                	addi	sp,sp,32
    80002d42:	8082                	ret
    return -1;
    80002d44:	557d                	li	a0,-1
    80002d46:	bfcd                	j	80002d38 <fetchaddr+0x3e>
    80002d48:	557d                	li	a0,-1
    80002d4a:	b7fd                	j	80002d38 <fetchaddr+0x3e>

0000000080002d4c <fetchstr>:
{
    80002d4c:	7179                	addi	sp,sp,-48
    80002d4e:	f406                	sd	ra,40(sp)
    80002d50:	f022                	sd	s0,32(sp)
    80002d52:	ec26                	sd	s1,24(sp)
    80002d54:	e84a                	sd	s2,16(sp)
    80002d56:	e44e                	sd	s3,8(sp)
    80002d58:	1800                	addi	s0,sp,48
    80002d5a:	892a                	mv	s2,a0
    80002d5c:	84ae                	mv	s1,a1
    80002d5e:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002d60:	fffff097          	auipc	ra,0xfffff
    80002d64:	f0a080e7          	jalr	-246(ra) # 80001c6a <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002d68:	86ce                	mv	a3,s3
    80002d6a:	864a                	mv	a2,s2
    80002d6c:	85a6                	mv	a1,s1
    80002d6e:	6928                	ld	a0,80(a0)
    80002d70:	fffff097          	auipc	ra,0xfffff
    80002d74:	a1a080e7          	jalr	-1510(ra) # 8000178a <copyinstr>
    80002d78:	00054e63          	bltz	a0,80002d94 <fetchstr+0x48>
  return strlen(buf);
    80002d7c:	8526                	mv	a0,s1
    80002d7e:	ffffe097          	auipc	ra,0xffffe
    80002d82:	0d0080e7          	jalr	208(ra) # 80000e4e <strlen>
}
    80002d86:	70a2                	ld	ra,40(sp)
    80002d88:	7402                	ld	s0,32(sp)
    80002d8a:	64e2                	ld	s1,24(sp)
    80002d8c:	6942                	ld	s2,16(sp)
    80002d8e:	69a2                	ld	s3,8(sp)
    80002d90:	6145                	addi	sp,sp,48
    80002d92:	8082                	ret
    return -1;
    80002d94:	557d                	li	a0,-1
    80002d96:	bfc5                	j	80002d86 <fetchstr+0x3a>

0000000080002d98 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002d98:	1101                	addi	sp,sp,-32
    80002d9a:	ec06                	sd	ra,24(sp)
    80002d9c:	e822                	sd	s0,16(sp)
    80002d9e:	e426                	sd	s1,8(sp)
    80002da0:	1000                	addi	s0,sp,32
    80002da2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002da4:	00000097          	auipc	ra,0x0
    80002da8:	eee080e7          	jalr	-274(ra) # 80002c92 <argraw>
    80002dac:	c088                	sw	a0,0(s1)
}
    80002dae:	60e2                	ld	ra,24(sp)
    80002db0:	6442                	ld	s0,16(sp)
    80002db2:	64a2                	ld	s1,8(sp)
    80002db4:	6105                	addi	sp,sp,32
    80002db6:	8082                	ret

0000000080002db8 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002db8:	1101                	addi	sp,sp,-32
    80002dba:	ec06                	sd	ra,24(sp)
    80002dbc:	e822                	sd	s0,16(sp)
    80002dbe:	e426                	sd	s1,8(sp)
    80002dc0:	1000                	addi	s0,sp,32
    80002dc2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002dc4:	00000097          	auipc	ra,0x0
    80002dc8:	ece080e7          	jalr	-306(ra) # 80002c92 <argraw>
    80002dcc:	e088                	sd	a0,0(s1)
}
    80002dce:	60e2                	ld	ra,24(sp)
    80002dd0:	6442                	ld	s0,16(sp)
    80002dd2:	64a2                	ld	s1,8(sp)
    80002dd4:	6105                	addi	sp,sp,32
    80002dd6:	8082                	ret

0000000080002dd8 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002dd8:	7179                	addi	sp,sp,-48
    80002dda:	f406                	sd	ra,40(sp)
    80002ddc:	f022                	sd	s0,32(sp)
    80002dde:	ec26                	sd	s1,24(sp)
    80002de0:	e84a                	sd	s2,16(sp)
    80002de2:	1800                	addi	s0,sp,48
    80002de4:	84ae                	mv	s1,a1
    80002de6:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002de8:	fd840593          	addi	a1,s0,-40
    80002dec:	00000097          	auipc	ra,0x0
    80002df0:	fcc080e7          	jalr	-52(ra) # 80002db8 <argaddr>
  return fetchstr(addr, buf, max);
    80002df4:	864a                	mv	a2,s2
    80002df6:	85a6                	mv	a1,s1
    80002df8:	fd843503          	ld	a0,-40(s0)
    80002dfc:	00000097          	auipc	ra,0x0
    80002e00:	f50080e7          	jalr	-176(ra) # 80002d4c <fetchstr>
}
    80002e04:	70a2                	ld	ra,40(sp)
    80002e06:	7402                	ld	s0,32(sp)
    80002e08:	64e2                	ld	s1,24(sp)
    80002e0a:	6942                	ld	s2,16(sp)
    80002e0c:	6145                	addi	sp,sp,48
    80002e0e:	8082                	ret

0000000080002e10 <syscall>:
[SYS_unmap_shared_pages]  sys_unmap_shared_pages,
};

void
syscall(void)
{
    80002e10:	1101                	addi	sp,sp,-32
    80002e12:	ec06                	sd	ra,24(sp)
    80002e14:	e822                	sd	s0,16(sp)
    80002e16:	e426                	sd	s1,8(sp)
    80002e18:	e04a                	sd	s2,0(sp)
    80002e1a:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002e1c:	fffff097          	auipc	ra,0xfffff
    80002e20:	e4e080e7          	jalr	-434(ra) # 80001c6a <myproc>
    80002e24:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002e26:	05853903          	ld	s2,88(a0)
    80002e2a:	0a893783          	ld	a5,168(s2)
    80002e2e:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002e32:	37fd                	addiw	a5,a5,-1
    80002e34:	4759                	li	a4,22
    80002e36:	00f76f63          	bltu	a4,a5,80002e54 <syscall+0x44>
    80002e3a:	00369713          	slli	a4,a3,0x3
    80002e3e:	00005797          	auipc	a5,0x5
    80002e42:	64278793          	addi	a5,a5,1602 # 80008480 <syscalls>
    80002e46:	97ba                	add	a5,a5,a4
    80002e48:	639c                	ld	a5,0(a5)
    80002e4a:	c789                	beqz	a5,80002e54 <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002e4c:	9782                	jalr	a5
    80002e4e:	06a93823          	sd	a0,112(s2)
    80002e52:	a839                	j	80002e70 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002e54:	15848613          	addi	a2,s1,344
    80002e58:	588c                	lw	a1,48(s1)
    80002e5a:	00005517          	auipc	a0,0x5
    80002e5e:	5ee50513          	addi	a0,a0,1518 # 80008448 <states.0+0x150>
    80002e62:	ffffd097          	auipc	ra,0xffffd
    80002e66:	726080e7          	jalr	1830(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002e6a:	6cbc                	ld	a5,88(s1)
    80002e6c:	577d                	li	a4,-1
    80002e6e:	fbb8                	sd	a4,112(a5)
  }
}
    80002e70:	60e2                	ld	ra,24(sp)
    80002e72:	6442                	ld	s0,16(sp)
    80002e74:	64a2                	ld	s1,8(sp)
    80002e76:	6902                	ld	s2,0(sp)
    80002e78:	6105                	addi	sp,sp,32
    80002e7a:	8082                	ret

0000000080002e7c <sys_exit>:
extern uint64 unmap_shared_pages(struct proc*, uint64, uint64);
extern struct proc proc[NPROC];

uint64
sys_exit(void)
{
    80002e7c:	1101                	addi	sp,sp,-32
    80002e7e:	ec06                	sd	ra,24(sp)
    80002e80:	e822                	sd	s0,16(sp)
    80002e82:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002e84:	fec40593          	addi	a1,s0,-20
    80002e88:	4501                	li	a0,0
    80002e8a:	00000097          	auipc	ra,0x0
    80002e8e:	f0e080e7          	jalr	-242(ra) # 80002d98 <argint>
  exit(n);
    80002e92:	fec42503          	lw	a0,-20(s0)
    80002e96:	fffff097          	auipc	ra,0xfffff
    80002e9a:	5b0080e7          	jalr	1456(ra) # 80002446 <exit>
  return 0;  // not reached
}
    80002e9e:	4501                	li	a0,0
    80002ea0:	60e2                	ld	ra,24(sp)
    80002ea2:	6442                	ld	s0,16(sp)
    80002ea4:	6105                	addi	sp,sp,32
    80002ea6:	8082                	ret

0000000080002ea8 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002ea8:	1141                	addi	sp,sp,-16
    80002eaa:	e406                	sd	ra,8(sp)
    80002eac:	e022                	sd	s0,0(sp)
    80002eae:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002eb0:	fffff097          	auipc	ra,0xfffff
    80002eb4:	dba080e7          	jalr	-582(ra) # 80001c6a <myproc>
}
    80002eb8:	5908                	lw	a0,48(a0)
    80002eba:	60a2                	ld	ra,8(sp)
    80002ebc:	6402                	ld	s0,0(sp)
    80002ebe:	0141                	addi	sp,sp,16
    80002ec0:	8082                	ret

0000000080002ec2 <sys_fork>:

uint64
sys_fork(void)
{
    80002ec2:	1141                	addi	sp,sp,-16
    80002ec4:	e406                	sd	ra,8(sp)
    80002ec6:	e022                	sd	s0,0(sp)
    80002ec8:	0800                	addi	s0,sp,16
  return fork();
    80002eca:	fffff097          	auipc	ra,0xfffff
    80002ece:	156080e7          	jalr	342(ra) # 80002020 <fork>
}
    80002ed2:	60a2                	ld	ra,8(sp)
    80002ed4:	6402                	ld	s0,0(sp)
    80002ed6:	0141                	addi	sp,sp,16
    80002ed8:	8082                	ret

0000000080002eda <sys_wait>:

uint64
sys_wait(void)
{
    80002eda:	1101                	addi	sp,sp,-32
    80002edc:	ec06                	sd	ra,24(sp)
    80002ede:	e822                	sd	s0,16(sp)
    80002ee0:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002ee2:	fe840593          	addi	a1,s0,-24
    80002ee6:	4501                	li	a0,0
    80002ee8:	00000097          	auipc	ra,0x0
    80002eec:	ed0080e7          	jalr	-304(ra) # 80002db8 <argaddr>
  return wait(p);
    80002ef0:	fe843503          	ld	a0,-24(s0)
    80002ef4:	fffff097          	auipc	ra,0xfffff
    80002ef8:	6f8080e7          	jalr	1784(ra) # 800025ec <wait>
}
    80002efc:	60e2                	ld	ra,24(sp)
    80002efe:	6442                	ld	s0,16(sp)
    80002f00:	6105                	addi	sp,sp,32
    80002f02:	8082                	ret

0000000080002f04 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f04:	7179                	addi	sp,sp,-48
    80002f06:	f406                	sd	ra,40(sp)
    80002f08:	f022                	sd	s0,32(sp)
    80002f0a:	ec26                	sd	s1,24(sp)
    80002f0c:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002f0e:	fdc40593          	addi	a1,s0,-36
    80002f12:	4501                	li	a0,0
    80002f14:	00000097          	auipc	ra,0x0
    80002f18:	e84080e7          	jalr	-380(ra) # 80002d98 <argint>
  addr = myproc()->sz;
    80002f1c:	fffff097          	auipc	ra,0xfffff
    80002f20:	d4e080e7          	jalr	-690(ra) # 80001c6a <myproc>
    80002f24:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002f26:	fdc42503          	lw	a0,-36(s0)
    80002f2a:	fffff097          	auipc	ra,0xfffff
    80002f2e:	09a080e7          	jalr	154(ra) # 80001fc4 <growproc>
    80002f32:	00054863          	bltz	a0,80002f42 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002f36:	8526                	mv	a0,s1
    80002f38:	70a2                	ld	ra,40(sp)
    80002f3a:	7402                	ld	s0,32(sp)
    80002f3c:	64e2                	ld	s1,24(sp)
    80002f3e:	6145                	addi	sp,sp,48
    80002f40:	8082                	ret
    return -1;
    80002f42:	54fd                	li	s1,-1
    80002f44:	bfcd                	j	80002f36 <sys_sbrk+0x32>

0000000080002f46 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002f46:	7139                	addi	sp,sp,-64
    80002f48:	fc06                	sd	ra,56(sp)
    80002f4a:	f822                	sd	s0,48(sp)
    80002f4c:	f426                	sd	s1,40(sp)
    80002f4e:	f04a                	sd	s2,32(sp)
    80002f50:	ec4e                	sd	s3,24(sp)
    80002f52:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002f54:	fcc40593          	addi	a1,s0,-52
    80002f58:	4501                	li	a0,0
    80002f5a:	00000097          	auipc	ra,0x0
    80002f5e:	e3e080e7          	jalr	-450(ra) # 80002d98 <argint>
  acquire(&tickslock);
    80002f62:	00014517          	auipc	a0,0x14
    80002f66:	a3e50513          	addi	a0,a0,-1474 # 800169a0 <tickslock>
    80002f6a:	ffffe097          	auipc	ra,0xffffe
    80002f6e:	c6c080e7          	jalr	-916(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002f72:	00006917          	auipc	s2,0x6
    80002f76:	98e92903          	lw	s2,-1650(s2) # 80008900 <ticks>
  while(ticks - ticks0 < n){
    80002f7a:	fcc42783          	lw	a5,-52(s0)
    80002f7e:	cf9d                	beqz	a5,80002fbc <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002f80:	00014997          	auipc	s3,0x14
    80002f84:	a2098993          	addi	s3,s3,-1504 # 800169a0 <tickslock>
    80002f88:	00006497          	auipc	s1,0x6
    80002f8c:	97848493          	addi	s1,s1,-1672 # 80008900 <ticks>
    if(killed(myproc())){
    80002f90:	fffff097          	auipc	ra,0xfffff
    80002f94:	cda080e7          	jalr	-806(ra) # 80001c6a <myproc>
    80002f98:	fffff097          	auipc	ra,0xfffff
    80002f9c:	622080e7          	jalr	1570(ra) # 800025ba <killed>
    80002fa0:	ed15                	bnez	a0,80002fdc <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002fa2:	85ce                	mv	a1,s3
    80002fa4:	8526                	mv	a0,s1
    80002fa6:	fffff097          	auipc	ra,0xfffff
    80002faa:	36c080e7          	jalr	876(ra) # 80002312 <sleep>
  while(ticks - ticks0 < n){
    80002fae:	409c                	lw	a5,0(s1)
    80002fb0:	412787bb          	subw	a5,a5,s2
    80002fb4:	fcc42703          	lw	a4,-52(s0)
    80002fb8:	fce7ece3          	bltu	a5,a4,80002f90 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002fbc:	00014517          	auipc	a0,0x14
    80002fc0:	9e450513          	addi	a0,a0,-1564 # 800169a0 <tickslock>
    80002fc4:	ffffe097          	auipc	ra,0xffffe
    80002fc8:	cc6080e7          	jalr	-826(ra) # 80000c8a <release>
  return 0;
    80002fcc:	4501                	li	a0,0
}
    80002fce:	70e2                	ld	ra,56(sp)
    80002fd0:	7442                	ld	s0,48(sp)
    80002fd2:	74a2                	ld	s1,40(sp)
    80002fd4:	7902                	ld	s2,32(sp)
    80002fd6:	69e2                	ld	s3,24(sp)
    80002fd8:	6121                	addi	sp,sp,64
    80002fda:	8082                	ret
      release(&tickslock);
    80002fdc:	00014517          	auipc	a0,0x14
    80002fe0:	9c450513          	addi	a0,a0,-1596 # 800169a0 <tickslock>
    80002fe4:	ffffe097          	auipc	ra,0xffffe
    80002fe8:	ca6080e7          	jalr	-858(ra) # 80000c8a <release>
      return -1;
    80002fec:	557d                	li	a0,-1
    80002fee:	b7c5                	j	80002fce <sys_sleep+0x88>

0000000080002ff0 <sys_kill>:

uint64
sys_kill(void)
{
    80002ff0:	1101                	addi	sp,sp,-32
    80002ff2:	ec06                	sd	ra,24(sp)
    80002ff4:	e822                	sd	s0,16(sp)
    80002ff6:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002ff8:	fec40593          	addi	a1,s0,-20
    80002ffc:	4501                	li	a0,0
    80002ffe:	00000097          	auipc	ra,0x0
    80003002:	d9a080e7          	jalr	-614(ra) # 80002d98 <argint>
  return kill(pid);
    80003006:	fec42503          	lw	a0,-20(s0)
    8000300a:	fffff097          	auipc	ra,0xfffff
    8000300e:	512080e7          	jalr	1298(ra) # 8000251c <kill>
}
    80003012:	60e2                	ld	ra,24(sp)
    80003014:	6442                	ld	s0,16(sp)
    80003016:	6105                	addi	sp,sp,32
    80003018:	8082                	ret

000000008000301a <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000301a:	1101                	addi	sp,sp,-32
    8000301c:	ec06                	sd	ra,24(sp)
    8000301e:	e822                	sd	s0,16(sp)
    80003020:	e426                	sd	s1,8(sp)
    80003022:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003024:	00014517          	auipc	a0,0x14
    80003028:	97c50513          	addi	a0,a0,-1668 # 800169a0 <tickslock>
    8000302c:	ffffe097          	auipc	ra,0xffffe
    80003030:	baa080e7          	jalr	-1110(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80003034:	00006497          	auipc	s1,0x6
    80003038:	8cc4a483          	lw	s1,-1844(s1) # 80008900 <ticks>
  release(&tickslock);
    8000303c:	00014517          	auipc	a0,0x14
    80003040:	96450513          	addi	a0,a0,-1692 # 800169a0 <tickslock>
    80003044:	ffffe097          	auipc	ra,0xffffe
    80003048:	c46080e7          	jalr	-954(ra) # 80000c8a <release>
  return xticks;
}
    8000304c:	02049513          	slli	a0,s1,0x20
    80003050:	9101                	srli	a0,a0,0x20
    80003052:	60e2                	ld	ra,24(sp)
    80003054:	6442                	ld	s0,16(sp)
    80003056:	64a2                	ld	s1,8(sp)
    80003058:	6105                	addi	sp,sp,32
    8000305a:	8082                	ret

000000008000305c <sys_map_shared_pages>:
// ----------------------------------------------------------------------
// task1:
uint64
sys_map_shared_pages(void)
{
    8000305c:	715d                	addi	sp,sp,-80
    8000305e:	e486                	sd	ra,72(sp)
    80003060:	e0a2                	sd	s0,64(sp)
    80003062:	fc26                	sd	s1,56(sp)
    80003064:	f84a                	sd	s2,48(sp)
    80003066:	f44e                	sd	s3,40(sp)
    80003068:	f052                	sd	s4,32(sp)
    8000306a:	0880                	addi	s0,sp,80
    int src_pid, dst_pid;
    uint64 src_va, size;
    struct proc *src_proc, *dst_proc;
    
    // Extract arguments from user space
    argint(0, &src_pid);
    8000306c:	fcc40593          	addi	a1,s0,-52
    80003070:	4501                	li	a0,0
    80003072:	00000097          	auipc	ra,0x0
    80003076:	d26080e7          	jalr	-730(ra) # 80002d98 <argint>
    argint(1, &dst_pid);
    8000307a:	fc840593          	addi	a1,s0,-56
    8000307e:	4505                	li	a0,1
    80003080:	00000097          	auipc	ra,0x0
    80003084:	d18080e7          	jalr	-744(ra) # 80002d98 <argint>
    argaddr(2, &src_va);
    80003088:	fc040593          	addi	a1,s0,-64
    8000308c:	4509                	li	a0,2
    8000308e:	00000097          	auipc	ra,0x0
    80003092:	d2a080e7          	jalr	-726(ra) # 80002db8 <argaddr>
    argaddr(3, &size);
    80003096:	fb840593          	addi	a1,s0,-72
    8000309a:	450d                	li	a0,3
    8000309c:	00000097          	auipc	ra,0x0
    800030a0:	d1c080e7          	jalr	-740(ra) # 80002db8 <argaddr>
    
    // Find source process by PID
    src_proc = 0; 
    dst_proc = 0;
    for(struct proc *p = proc; p < &proc[NPROC]; p++) {
    800030a4:	0000e497          	auipc	s1,0xe
    800030a8:	efc48493          	addi	s1,s1,-260 # 80010fa0 <proc>
    dst_proc = 0;
    800030ac:	4a01                	li	s4,0
    src_proc = 0; 
    800030ae:	4901                	li	s2,0
    for(struct proc *p = proc; p < &proc[NPROC]; p++) {
    800030b0:	00014997          	auipc	s3,0x14
    800030b4:	8f098993          	addi	s3,s3,-1808 # 800169a0 <tickslock>
    800030b8:	a005                	j	800030d8 <sys_map_shared_pages+0x7c>
      acquire(&p->lock);
      if(p->state != UNUSED) {
          if(p->pid == src_pid)
    800030ba:	8926                	mv	s2,s1
    800030bc:	a815                	j	800030f0 <sys_map_shared_pages+0x94>
              src_proc = p;
          if(p->pid == dst_pid)
              dst_proc = p;
      }
      release(&p->lock);
    800030be:	8526                	mv	a0,s1
    800030c0:	ffffe097          	auipc	ra,0xffffe
    800030c4:	bca080e7          	jalr	-1078(ra) # 80000c8a <release>

      if(src_proc && dst_proc)
    800030c8:	00090463          	beqz	s2,800030d0 <sys_map_shared_pages+0x74>
    800030cc:	060a1763          	bnez	s4,8000313a <sys_map_shared_pages+0xde>
    for(struct proc *p = proc; p < &proc[NPROC]; p++) {
    800030d0:	16848493          	addi	s1,s1,360
    800030d4:	03348b63          	beq	s1,s3,8000310a <sys_map_shared_pages+0xae>
      acquire(&p->lock);
    800030d8:	8526                	mv	a0,s1
    800030da:	ffffe097          	auipc	ra,0xffffe
    800030de:	afc080e7          	jalr	-1284(ra) # 80000bd6 <acquire>
      if(p->state != UNUSED) {
    800030e2:	4c9c                	lw	a5,24(s1)
    800030e4:	dfe9                	beqz	a5,800030be <sys_map_shared_pages+0x62>
          if(p->pid == src_pid)
    800030e6:	589c                	lw	a5,48(s1)
    800030e8:	fcc42703          	lw	a4,-52(s0)
    800030ec:	fcf707e3          	beq	a4,a5,800030ba <sys_map_shared_pages+0x5e>
          if(p->pid == dst_pid)
    800030f0:	fc842703          	lw	a4,-56(s0)
    800030f4:	fcf715e3          	bne	a4,a5,800030be <sys_map_shared_pages+0x62>
      release(&p->lock);
    800030f8:	8526                	mv	a0,s1
    800030fa:	ffffe097          	auipc	ra,0xffffe
    800030fe:	b90080e7          	jalr	-1136(ra) # 80000c8a <release>
      if(src_proc && dst_proc)
    80003102:	00091a63          	bnez	s2,80003116 <sys_map_shared_pages+0xba>
    80003106:	8a26                	mv	s4,s1
    80003108:	b7e1                	j	800030d0 <sys_map_shared_pages+0x74>
          break;
    }

    
    if(src_proc == 0 || dst_proc == 0) {
        return -1; // Source process not found
    8000310a:	557d                	li	a0,-1
    if(src_proc == 0 || dst_proc == 0) {
    8000310c:	00090f63          	beqz	s2,8000312a <sys_map_shared_pages+0xce>
    80003110:	000a0d63          	beqz	s4,8000312a <sys_map_shared_pages+0xce>
    80003114:	84d2                	mv	s1,s4
    }
    
    return map_shared_pages(src_proc, dst_proc, src_va, size);
    80003116:	fb843683          	ld	a3,-72(s0)
    8000311a:	fc043603          	ld	a2,-64(s0)
    8000311e:	85a6                	mv	a1,s1
    80003120:	854a                	mv	a0,s2
    80003122:	ffffe097          	auipc	ra,0xffffe
    80003126:	71c080e7          	jalr	1820(ra) # 8000183e <map_shared_pages>
}
    8000312a:	60a6                	ld	ra,72(sp)
    8000312c:	6406                	ld	s0,64(sp)
    8000312e:	74e2                	ld	s1,56(sp)
    80003130:	7942                	ld	s2,48(sp)
    80003132:	79a2                	ld	s3,40(sp)
    80003134:	7a02                	ld	s4,32(sp)
    80003136:	6161                	addi	sp,sp,80
    80003138:	8082                	ret
    8000313a:	84d2                	mv	s1,s4
    if(src_proc == 0 || dst_proc == 0) {
    8000313c:	bfe9                	j	80003116 <sys_map_shared_pages+0xba>

000000008000313e <sys_unmap_shared_pages>:

// ----------------------------------------------------------------------
uint64
sys_unmap_shared_pages(void)
{
    8000313e:	7179                	addi	sp,sp,-48
    80003140:	f406                	sd	ra,40(sp)
    80003142:	f022                	sd	s0,32(sp)
    80003144:	ec26                	sd	s1,24(sp)
    80003146:	1800                	addi	s0,sp,48
  struct proc *curproc = myproc();
    80003148:	fffff097          	auipc	ra,0xfffff
    8000314c:	b22080e7          	jalr	-1246(ra) # 80001c6a <myproc>
    80003150:	84aa                	mv	s1,a0
  uint64 addr;
  int size;

  argaddr(0, &addr);
    80003152:	fd840593          	addi	a1,s0,-40
    80003156:	4501                	li	a0,0
    80003158:	00000097          	auipc	ra,0x0
    8000315c:	c60080e7          	jalr	-928(ra) # 80002db8 <argaddr>
  argint(1, &size);
    80003160:	fd440593          	addi	a1,s0,-44
    80003164:	4505                	li	a0,1
    80003166:	00000097          	auipc	ra,0x0
    8000316a:	c32080e7          	jalr	-974(ra) # 80002d98 <argint>

  return unmap_shared_pages(curproc, addr, size);
    8000316e:	fd442603          	lw	a2,-44(s0)
    80003172:	fd843583          	ld	a1,-40(s0)
    80003176:	8526                	mv	a0,s1
    80003178:	fffff097          	auipc	ra,0xfffff
    8000317c:	8b2080e7          	jalr	-1870(ra) # 80001a2a <unmap_shared_pages>
}
    80003180:	70a2                	ld	ra,40(sp)
    80003182:	7402                	ld	s0,32(sp)
    80003184:	64e2                	ld	s1,24(sp)
    80003186:	6145                	addi	sp,sp,48
    80003188:	8082                	ret

000000008000318a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000318a:	7179                	addi	sp,sp,-48
    8000318c:	f406                	sd	ra,40(sp)
    8000318e:	f022                	sd	s0,32(sp)
    80003190:	ec26                	sd	s1,24(sp)
    80003192:	e84a                	sd	s2,16(sp)
    80003194:	e44e                	sd	s3,8(sp)
    80003196:	e052                	sd	s4,0(sp)
    80003198:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000319a:	00005597          	auipc	a1,0x5
    8000319e:	3a658593          	addi	a1,a1,934 # 80008540 <syscalls+0xc0>
    800031a2:	00014517          	auipc	a0,0x14
    800031a6:	81650513          	addi	a0,a0,-2026 # 800169b8 <bcache>
    800031aa:	ffffe097          	auipc	ra,0xffffe
    800031ae:	99c080e7          	jalr	-1636(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800031b2:	0001c797          	auipc	a5,0x1c
    800031b6:	80678793          	addi	a5,a5,-2042 # 8001e9b8 <bcache+0x8000>
    800031ba:	0001c717          	auipc	a4,0x1c
    800031be:	a6670713          	addi	a4,a4,-1434 # 8001ec20 <bcache+0x8268>
    800031c2:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800031c6:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800031ca:	00014497          	auipc	s1,0x14
    800031ce:	80648493          	addi	s1,s1,-2042 # 800169d0 <bcache+0x18>
    b->next = bcache.head.next;
    800031d2:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800031d4:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800031d6:	00005a17          	auipc	s4,0x5
    800031da:	372a0a13          	addi	s4,s4,882 # 80008548 <syscalls+0xc8>
    b->next = bcache.head.next;
    800031de:	2b893783          	ld	a5,696(s2)
    800031e2:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800031e4:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800031e8:	85d2                	mv	a1,s4
    800031ea:	01048513          	addi	a0,s1,16
    800031ee:	00001097          	auipc	ra,0x1
    800031f2:	4c4080e7          	jalr	1220(ra) # 800046b2 <initsleeplock>
    bcache.head.next->prev = b;
    800031f6:	2b893783          	ld	a5,696(s2)
    800031fa:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800031fc:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003200:	45848493          	addi	s1,s1,1112
    80003204:	fd349de3          	bne	s1,s3,800031de <binit+0x54>
  }
}
    80003208:	70a2                	ld	ra,40(sp)
    8000320a:	7402                	ld	s0,32(sp)
    8000320c:	64e2                	ld	s1,24(sp)
    8000320e:	6942                	ld	s2,16(sp)
    80003210:	69a2                	ld	s3,8(sp)
    80003212:	6a02                	ld	s4,0(sp)
    80003214:	6145                	addi	sp,sp,48
    80003216:	8082                	ret

0000000080003218 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003218:	7179                	addi	sp,sp,-48
    8000321a:	f406                	sd	ra,40(sp)
    8000321c:	f022                	sd	s0,32(sp)
    8000321e:	ec26                	sd	s1,24(sp)
    80003220:	e84a                	sd	s2,16(sp)
    80003222:	e44e                	sd	s3,8(sp)
    80003224:	1800                	addi	s0,sp,48
    80003226:	892a                	mv	s2,a0
    80003228:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000322a:	00013517          	auipc	a0,0x13
    8000322e:	78e50513          	addi	a0,a0,1934 # 800169b8 <bcache>
    80003232:	ffffe097          	auipc	ra,0xffffe
    80003236:	9a4080e7          	jalr	-1628(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000323a:	0001c497          	auipc	s1,0x1c
    8000323e:	a364b483          	ld	s1,-1482(s1) # 8001ec70 <bcache+0x82b8>
    80003242:	0001c797          	auipc	a5,0x1c
    80003246:	9de78793          	addi	a5,a5,-1570 # 8001ec20 <bcache+0x8268>
    8000324a:	02f48f63          	beq	s1,a5,80003288 <bread+0x70>
    8000324e:	873e                	mv	a4,a5
    80003250:	a021                	j	80003258 <bread+0x40>
    80003252:	68a4                	ld	s1,80(s1)
    80003254:	02e48a63          	beq	s1,a4,80003288 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003258:	449c                	lw	a5,8(s1)
    8000325a:	ff279ce3          	bne	a5,s2,80003252 <bread+0x3a>
    8000325e:	44dc                	lw	a5,12(s1)
    80003260:	ff3799e3          	bne	a5,s3,80003252 <bread+0x3a>
      b->refcnt++;
    80003264:	40bc                	lw	a5,64(s1)
    80003266:	2785                	addiw	a5,a5,1
    80003268:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000326a:	00013517          	auipc	a0,0x13
    8000326e:	74e50513          	addi	a0,a0,1870 # 800169b8 <bcache>
    80003272:	ffffe097          	auipc	ra,0xffffe
    80003276:	a18080e7          	jalr	-1512(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    8000327a:	01048513          	addi	a0,s1,16
    8000327e:	00001097          	auipc	ra,0x1
    80003282:	46e080e7          	jalr	1134(ra) # 800046ec <acquiresleep>
      return b;
    80003286:	a8b9                	j	800032e4 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003288:	0001c497          	auipc	s1,0x1c
    8000328c:	9e04b483          	ld	s1,-1568(s1) # 8001ec68 <bcache+0x82b0>
    80003290:	0001c797          	auipc	a5,0x1c
    80003294:	99078793          	addi	a5,a5,-1648 # 8001ec20 <bcache+0x8268>
    80003298:	00f48863          	beq	s1,a5,800032a8 <bread+0x90>
    8000329c:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000329e:	40bc                	lw	a5,64(s1)
    800032a0:	cf81                	beqz	a5,800032b8 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800032a2:	64a4                	ld	s1,72(s1)
    800032a4:	fee49de3          	bne	s1,a4,8000329e <bread+0x86>
  panic("bget: no buffers");
    800032a8:	00005517          	auipc	a0,0x5
    800032ac:	2a850513          	addi	a0,a0,680 # 80008550 <syscalls+0xd0>
    800032b0:	ffffd097          	auipc	ra,0xffffd
    800032b4:	28e080e7          	jalr	654(ra) # 8000053e <panic>
      b->dev = dev;
    800032b8:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800032bc:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800032c0:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800032c4:	4785                	li	a5,1
    800032c6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800032c8:	00013517          	auipc	a0,0x13
    800032cc:	6f050513          	addi	a0,a0,1776 # 800169b8 <bcache>
    800032d0:	ffffe097          	auipc	ra,0xffffe
    800032d4:	9ba080e7          	jalr	-1606(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    800032d8:	01048513          	addi	a0,s1,16
    800032dc:	00001097          	auipc	ra,0x1
    800032e0:	410080e7          	jalr	1040(ra) # 800046ec <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800032e4:	409c                	lw	a5,0(s1)
    800032e6:	cb89                	beqz	a5,800032f8 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800032e8:	8526                	mv	a0,s1
    800032ea:	70a2                	ld	ra,40(sp)
    800032ec:	7402                	ld	s0,32(sp)
    800032ee:	64e2                	ld	s1,24(sp)
    800032f0:	6942                	ld	s2,16(sp)
    800032f2:	69a2                	ld	s3,8(sp)
    800032f4:	6145                	addi	sp,sp,48
    800032f6:	8082                	ret
    virtio_disk_rw(b, 0);
    800032f8:	4581                	li	a1,0
    800032fa:	8526                	mv	a0,s1
    800032fc:	00003097          	auipc	ra,0x3
    80003300:	fd8080e7          	jalr	-40(ra) # 800062d4 <virtio_disk_rw>
    b->valid = 1;
    80003304:	4785                	li	a5,1
    80003306:	c09c                	sw	a5,0(s1)
  return b;
    80003308:	b7c5                	j	800032e8 <bread+0xd0>

000000008000330a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000330a:	1101                	addi	sp,sp,-32
    8000330c:	ec06                	sd	ra,24(sp)
    8000330e:	e822                	sd	s0,16(sp)
    80003310:	e426                	sd	s1,8(sp)
    80003312:	1000                	addi	s0,sp,32
    80003314:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003316:	0541                	addi	a0,a0,16
    80003318:	00001097          	auipc	ra,0x1
    8000331c:	46e080e7          	jalr	1134(ra) # 80004786 <holdingsleep>
    80003320:	cd01                	beqz	a0,80003338 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003322:	4585                	li	a1,1
    80003324:	8526                	mv	a0,s1
    80003326:	00003097          	auipc	ra,0x3
    8000332a:	fae080e7          	jalr	-82(ra) # 800062d4 <virtio_disk_rw>
}
    8000332e:	60e2                	ld	ra,24(sp)
    80003330:	6442                	ld	s0,16(sp)
    80003332:	64a2                	ld	s1,8(sp)
    80003334:	6105                	addi	sp,sp,32
    80003336:	8082                	ret
    panic("bwrite");
    80003338:	00005517          	auipc	a0,0x5
    8000333c:	23050513          	addi	a0,a0,560 # 80008568 <syscalls+0xe8>
    80003340:	ffffd097          	auipc	ra,0xffffd
    80003344:	1fe080e7          	jalr	510(ra) # 8000053e <panic>

0000000080003348 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003348:	1101                	addi	sp,sp,-32
    8000334a:	ec06                	sd	ra,24(sp)
    8000334c:	e822                	sd	s0,16(sp)
    8000334e:	e426                	sd	s1,8(sp)
    80003350:	e04a                	sd	s2,0(sp)
    80003352:	1000                	addi	s0,sp,32
    80003354:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003356:	01050913          	addi	s2,a0,16
    8000335a:	854a                	mv	a0,s2
    8000335c:	00001097          	auipc	ra,0x1
    80003360:	42a080e7          	jalr	1066(ra) # 80004786 <holdingsleep>
    80003364:	c92d                	beqz	a0,800033d6 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003366:	854a                	mv	a0,s2
    80003368:	00001097          	auipc	ra,0x1
    8000336c:	3da080e7          	jalr	986(ra) # 80004742 <releasesleep>

  acquire(&bcache.lock);
    80003370:	00013517          	auipc	a0,0x13
    80003374:	64850513          	addi	a0,a0,1608 # 800169b8 <bcache>
    80003378:	ffffe097          	auipc	ra,0xffffe
    8000337c:	85e080e7          	jalr	-1954(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003380:	40bc                	lw	a5,64(s1)
    80003382:	37fd                	addiw	a5,a5,-1
    80003384:	0007871b          	sext.w	a4,a5
    80003388:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000338a:	eb05                	bnez	a4,800033ba <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000338c:	68bc                	ld	a5,80(s1)
    8000338e:	64b8                	ld	a4,72(s1)
    80003390:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003392:	64bc                	ld	a5,72(s1)
    80003394:	68b8                	ld	a4,80(s1)
    80003396:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003398:	0001b797          	auipc	a5,0x1b
    8000339c:	62078793          	addi	a5,a5,1568 # 8001e9b8 <bcache+0x8000>
    800033a0:	2b87b703          	ld	a4,696(a5)
    800033a4:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800033a6:	0001c717          	auipc	a4,0x1c
    800033aa:	87a70713          	addi	a4,a4,-1926 # 8001ec20 <bcache+0x8268>
    800033ae:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800033b0:	2b87b703          	ld	a4,696(a5)
    800033b4:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800033b6:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800033ba:	00013517          	auipc	a0,0x13
    800033be:	5fe50513          	addi	a0,a0,1534 # 800169b8 <bcache>
    800033c2:	ffffe097          	auipc	ra,0xffffe
    800033c6:	8c8080e7          	jalr	-1848(ra) # 80000c8a <release>
}
    800033ca:	60e2                	ld	ra,24(sp)
    800033cc:	6442                	ld	s0,16(sp)
    800033ce:	64a2                	ld	s1,8(sp)
    800033d0:	6902                	ld	s2,0(sp)
    800033d2:	6105                	addi	sp,sp,32
    800033d4:	8082                	ret
    panic("brelse");
    800033d6:	00005517          	auipc	a0,0x5
    800033da:	19a50513          	addi	a0,a0,410 # 80008570 <syscalls+0xf0>
    800033de:	ffffd097          	auipc	ra,0xffffd
    800033e2:	160080e7          	jalr	352(ra) # 8000053e <panic>

00000000800033e6 <bpin>:

void
bpin(struct buf *b) {
    800033e6:	1101                	addi	sp,sp,-32
    800033e8:	ec06                	sd	ra,24(sp)
    800033ea:	e822                	sd	s0,16(sp)
    800033ec:	e426                	sd	s1,8(sp)
    800033ee:	1000                	addi	s0,sp,32
    800033f0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800033f2:	00013517          	auipc	a0,0x13
    800033f6:	5c650513          	addi	a0,a0,1478 # 800169b8 <bcache>
    800033fa:	ffffd097          	auipc	ra,0xffffd
    800033fe:	7dc080e7          	jalr	2012(ra) # 80000bd6 <acquire>
  b->refcnt++;
    80003402:	40bc                	lw	a5,64(s1)
    80003404:	2785                	addiw	a5,a5,1
    80003406:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003408:	00013517          	auipc	a0,0x13
    8000340c:	5b050513          	addi	a0,a0,1456 # 800169b8 <bcache>
    80003410:	ffffe097          	auipc	ra,0xffffe
    80003414:	87a080e7          	jalr	-1926(ra) # 80000c8a <release>
}
    80003418:	60e2                	ld	ra,24(sp)
    8000341a:	6442                	ld	s0,16(sp)
    8000341c:	64a2                	ld	s1,8(sp)
    8000341e:	6105                	addi	sp,sp,32
    80003420:	8082                	ret

0000000080003422 <bunpin>:

void
bunpin(struct buf *b) {
    80003422:	1101                	addi	sp,sp,-32
    80003424:	ec06                	sd	ra,24(sp)
    80003426:	e822                	sd	s0,16(sp)
    80003428:	e426                	sd	s1,8(sp)
    8000342a:	1000                	addi	s0,sp,32
    8000342c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000342e:	00013517          	auipc	a0,0x13
    80003432:	58a50513          	addi	a0,a0,1418 # 800169b8 <bcache>
    80003436:	ffffd097          	auipc	ra,0xffffd
    8000343a:	7a0080e7          	jalr	1952(ra) # 80000bd6 <acquire>
  b->refcnt--;
    8000343e:	40bc                	lw	a5,64(s1)
    80003440:	37fd                	addiw	a5,a5,-1
    80003442:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003444:	00013517          	auipc	a0,0x13
    80003448:	57450513          	addi	a0,a0,1396 # 800169b8 <bcache>
    8000344c:	ffffe097          	auipc	ra,0xffffe
    80003450:	83e080e7          	jalr	-1986(ra) # 80000c8a <release>
}
    80003454:	60e2                	ld	ra,24(sp)
    80003456:	6442                	ld	s0,16(sp)
    80003458:	64a2                	ld	s1,8(sp)
    8000345a:	6105                	addi	sp,sp,32
    8000345c:	8082                	ret

000000008000345e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000345e:	1101                	addi	sp,sp,-32
    80003460:	ec06                	sd	ra,24(sp)
    80003462:	e822                	sd	s0,16(sp)
    80003464:	e426                	sd	s1,8(sp)
    80003466:	e04a                	sd	s2,0(sp)
    80003468:	1000                	addi	s0,sp,32
    8000346a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000346c:	00d5d59b          	srliw	a1,a1,0xd
    80003470:	0001c797          	auipc	a5,0x1c
    80003474:	c247a783          	lw	a5,-988(a5) # 8001f094 <sb+0x1c>
    80003478:	9dbd                	addw	a1,a1,a5
    8000347a:	00000097          	auipc	ra,0x0
    8000347e:	d9e080e7          	jalr	-610(ra) # 80003218 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003482:	0074f713          	andi	a4,s1,7
    80003486:	4785                	li	a5,1
    80003488:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000348c:	14ce                	slli	s1,s1,0x33
    8000348e:	90d9                	srli	s1,s1,0x36
    80003490:	00950733          	add	a4,a0,s1
    80003494:	05874703          	lbu	a4,88(a4)
    80003498:	00e7f6b3          	and	a3,a5,a4
    8000349c:	c69d                	beqz	a3,800034ca <bfree+0x6c>
    8000349e:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800034a0:	94aa                	add	s1,s1,a0
    800034a2:	fff7c793          	not	a5,a5
    800034a6:	8ff9                	and	a5,a5,a4
    800034a8:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800034ac:	00001097          	auipc	ra,0x1
    800034b0:	120080e7          	jalr	288(ra) # 800045cc <log_write>
  brelse(bp);
    800034b4:	854a                	mv	a0,s2
    800034b6:	00000097          	auipc	ra,0x0
    800034ba:	e92080e7          	jalr	-366(ra) # 80003348 <brelse>
}
    800034be:	60e2                	ld	ra,24(sp)
    800034c0:	6442                	ld	s0,16(sp)
    800034c2:	64a2                	ld	s1,8(sp)
    800034c4:	6902                	ld	s2,0(sp)
    800034c6:	6105                	addi	sp,sp,32
    800034c8:	8082                	ret
    panic("freeing free block");
    800034ca:	00005517          	auipc	a0,0x5
    800034ce:	0ae50513          	addi	a0,a0,174 # 80008578 <syscalls+0xf8>
    800034d2:	ffffd097          	auipc	ra,0xffffd
    800034d6:	06c080e7          	jalr	108(ra) # 8000053e <panic>

00000000800034da <balloc>:
{
    800034da:	711d                	addi	sp,sp,-96
    800034dc:	ec86                	sd	ra,88(sp)
    800034de:	e8a2                	sd	s0,80(sp)
    800034e0:	e4a6                	sd	s1,72(sp)
    800034e2:	e0ca                	sd	s2,64(sp)
    800034e4:	fc4e                	sd	s3,56(sp)
    800034e6:	f852                	sd	s4,48(sp)
    800034e8:	f456                	sd	s5,40(sp)
    800034ea:	f05a                	sd	s6,32(sp)
    800034ec:	ec5e                	sd	s7,24(sp)
    800034ee:	e862                	sd	s8,16(sp)
    800034f0:	e466                	sd	s9,8(sp)
    800034f2:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800034f4:	0001c797          	auipc	a5,0x1c
    800034f8:	b887a783          	lw	a5,-1144(a5) # 8001f07c <sb+0x4>
    800034fc:	10078163          	beqz	a5,800035fe <balloc+0x124>
    80003500:	8baa                	mv	s7,a0
    80003502:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003504:	0001cb17          	auipc	s6,0x1c
    80003508:	b74b0b13          	addi	s6,s6,-1164 # 8001f078 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000350c:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000350e:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003510:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003512:	6c89                	lui	s9,0x2
    80003514:	a061                	j	8000359c <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003516:	974a                	add	a4,a4,s2
    80003518:	8fd5                	or	a5,a5,a3
    8000351a:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000351e:	854a                	mv	a0,s2
    80003520:	00001097          	auipc	ra,0x1
    80003524:	0ac080e7          	jalr	172(ra) # 800045cc <log_write>
        brelse(bp);
    80003528:	854a                	mv	a0,s2
    8000352a:	00000097          	auipc	ra,0x0
    8000352e:	e1e080e7          	jalr	-482(ra) # 80003348 <brelse>
  bp = bread(dev, bno);
    80003532:	85a6                	mv	a1,s1
    80003534:	855e                	mv	a0,s7
    80003536:	00000097          	auipc	ra,0x0
    8000353a:	ce2080e7          	jalr	-798(ra) # 80003218 <bread>
    8000353e:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003540:	40000613          	li	a2,1024
    80003544:	4581                	li	a1,0
    80003546:	05850513          	addi	a0,a0,88
    8000354a:	ffffd097          	auipc	ra,0xffffd
    8000354e:	788080e7          	jalr	1928(ra) # 80000cd2 <memset>
  log_write(bp);
    80003552:	854a                	mv	a0,s2
    80003554:	00001097          	auipc	ra,0x1
    80003558:	078080e7          	jalr	120(ra) # 800045cc <log_write>
  brelse(bp);
    8000355c:	854a                	mv	a0,s2
    8000355e:	00000097          	auipc	ra,0x0
    80003562:	dea080e7          	jalr	-534(ra) # 80003348 <brelse>
}
    80003566:	8526                	mv	a0,s1
    80003568:	60e6                	ld	ra,88(sp)
    8000356a:	6446                	ld	s0,80(sp)
    8000356c:	64a6                	ld	s1,72(sp)
    8000356e:	6906                	ld	s2,64(sp)
    80003570:	79e2                	ld	s3,56(sp)
    80003572:	7a42                	ld	s4,48(sp)
    80003574:	7aa2                	ld	s5,40(sp)
    80003576:	7b02                	ld	s6,32(sp)
    80003578:	6be2                	ld	s7,24(sp)
    8000357a:	6c42                	ld	s8,16(sp)
    8000357c:	6ca2                	ld	s9,8(sp)
    8000357e:	6125                	addi	sp,sp,96
    80003580:	8082                	ret
    brelse(bp);
    80003582:	854a                	mv	a0,s2
    80003584:	00000097          	auipc	ra,0x0
    80003588:	dc4080e7          	jalr	-572(ra) # 80003348 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000358c:	015c87bb          	addw	a5,s9,s5
    80003590:	00078a9b          	sext.w	s5,a5
    80003594:	004b2703          	lw	a4,4(s6)
    80003598:	06eaf363          	bgeu	s5,a4,800035fe <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    8000359c:	41fad79b          	sraiw	a5,s5,0x1f
    800035a0:	0137d79b          	srliw	a5,a5,0x13
    800035a4:	015787bb          	addw	a5,a5,s5
    800035a8:	40d7d79b          	sraiw	a5,a5,0xd
    800035ac:	01cb2583          	lw	a1,28(s6)
    800035b0:	9dbd                	addw	a1,a1,a5
    800035b2:	855e                	mv	a0,s7
    800035b4:	00000097          	auipc	ra,0x0
    800035b8:	c64080e7          	jalr	-924(ra) # 80003218 <bread>
    800035bc:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035be:	004b2503          	lw	a0,4(s6)
    800035c2:	000a849b          	sext.w	s1,s5
    800035c6:	8662                	mv	a2,s8
    800035c8:	faa4fde3          	bgeu	s1,a0,80003582 <balloc+0xa8>
      m = 1 << (bi % 8);
    800035cc:	41f6579b          	sraiw	a5,a2,0x1f
    800035d0:	01d7d69b          	srliw	a3,a5,0x1d
    800035d4:	00c6873b          	addw	a4,a3,a2
    800035d8:	00777793          	andi	a5,a4,7
    800035dc:	9f95                	subw	a5,a5,a3
    800035de:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800035e2:	4037571b          	sraiw	a4,a4,0x3
    800035e6:	00e906b3          	add	a3,s2,a4
    800035ea:	0586c683          	lbu	a3,88(a3)
    800035ee:	00d7f5b3          	and	a1,a5,a3
    800035f2:	d195                	beqz	a1,80003516 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035f4:	2605                	addiw	a2,a2,1
    800035f6:	2485                	addiw	s1,s1,1
    800035f8:	fd4618e3          	bne	a2,s4,800035c8 <balloc+0xee>
    800035fc:	b759                	j	80003582 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    800035fe:	00005517          	auipc	a0,0x5
    80003602:	f9250513          	addi	a0,a0,-110 # 80008590 <syscalls+0x110>
    80003606:	ffffd097          	auipc	ra,0xffffd
    8000360a:	f82080e7          	jalr	-126(ra) # 80000588 <printf>
  return 0;
    8000360e:	4481                	li	s1,0
    80003610:	bf99                	j	80003566 <balloc+0x8c>

0000000080003612 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003612:	7179                	addi	sp,sp,-48
    80003614:	f406                	sd	ra,40(sp)
    80003616:	f022                	sd	s0,32(sp)
    80003618:	ec26                	sd	s1,24(sp)
    8000361a:	e84a                	sd	s2,16(sp)
    8000361c:	e44e                	sd	s3,8(sp)
    8000361e:	e052                	sd	s4,0(sp)
    80003620:	1800                	addi	s0,sp,48
    80003622:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003624:	47ad                	li	a5,11
    80003626:	02b7e763          	bltu	a5,a1,80003654 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    8000362a:	02059493          	slli	s1,a1,0x20
    8000362e:	9081                	srli	s1,s1,0x20
    80003630:	048a                	slli	s1,s1,0x2
    80003632:	94aa                	add	s1,s1,a0
    80003634:	0504a903          	lw	s2,80(s1)
    80003638:	06091e63          	bnez	s2,800036b4 <bmap+0xa2>
      addr = balloc(ip->dev);
    8000363c:	4108                	lw	a0,0(a0)
    8000363e:	00000097          	auipc	ra,0x0
    80003642:	e9c080e7          	jalr	-356(ra) # 800034da <balloc>
    80003646:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000364a:	06090563          	beqz	s2,800036b4 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    8000364e:	0524a823          	sw	s2,80(s1)
    80003652:	a08d                	j	800036b4 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003654:	ff45849b          	addiw	s1,a1,-12
    80003658:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000365c:	0ff00793          	li	a5,255
    80003660:	08e7e563          	bltu	a5,a4,800036ea <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003664:	08052903          	lw	s2,128(a0)
    80003668:	00091d63          	bnez	s2,80003682 <bmap+0x70>
      addr = balloc(ip->dev);
    8000366c:	4108                	lw	a0,0(a0)
    8000366e:	00000097          	auipc	ra,0x0
    80003672:	e6c080e7          	jalr	-404(ra) # 800034da <balloc>
    80003676:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000367a:	02090d63          	beqz	s2,800036b4 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    8000367e:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003682:	85ca                	mv	a1,s2
    80003684:	0009a503          	lw	a0,0(s3)
    80003688:	00000097          	auipc	ra,0x0
    8000368c:	b90080e7          	jalr	-1136(ra) # 80003218 <bread>
    80003690:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003692:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003696:	02049593          	slli	a1,s1,0x20
    8000369a:	9181                	srli	a1,a1,0x20
    8000369c:	058a                	slli	a1,a1,0x2
    8000369e:	00b784b3          	add	s1,a5,a1
    800036a2:	0004a903          	lw	s2,0(s1)
    800036a6:	02090063          	beqz	s2,800036c6 <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800036aa:	8552                	mv	a0,s4
    800036ac:	00000097          	auipc	ra,0x0
    800036b0:	c9c080e7          	jalr	-868(ra) # 80003348 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800036b4:	854a                	mv	a0,s2
    800036b6:	70a2                	ld	ra,40(sp)
    800036b8:	7402                	ld	s0,32(sp)
    800036ba:	64e2                	ld	s1,24(sp)
    800036bc:	6942                	ld	s2,16(sp)
    800036be:	69a2                	ld	s3,8(sp)
    800036c0:	6a02                	ld	s4,0(sp)
    800036c2:	6145                	addi	sp,sp,48
    800036c4:	8082                	ret
      addr = balloc(ip->dev);
    800036c6:	0009a503          	lw	a0,0(s3)
    800036ca:	00000097          	auipc	ra,0x0
    800036ce:	e10080e7          	jalr	-496(ra) # 800034da <balloc>
    800036d2:	0005091b          	sext.w	s2,a0
      if(addr){
    800036d6:	fc090ae3          	beqz	s2,800036aa <bmap+0x98>
        a[bn] = addr;
    800036da:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800036de:	8552                	mv	a0,s4
    800036e0:	00001097          	auipc	ra,0x1
    800036e4:	eec080e7          	jalr	-276(ra) # 800045cc <log_write>
    800036e8:	b7c9                	j	800036aa <bmap+0x98>
  panic("bmap: out of range");
    800036ea:	00005517          	auipc	a0,0x5
    800036ee:	ebe50513          	addi	a0,a0,-322 # 800085a8 <syscalls+0x128>
    800036f2:	ffffd097          	auipc	ra,0xffffd
    800036f6:	e4c080e7          	jalr	-436(ra) # 8000053e <panic>

00000000800036fa <iget>:
{
    800036fa:	7179                	addi	sp,sp,-48
    800036fc:	f406                	sd	ra,40(sp)
    800036fe:	f022                	sd	s0,32(sp)
    80003700:	ec26                	sd	s1,24(sp)
    80003702:	e84a                	sd	s2,16(sp)
    80003704:	e44e                	sd	s3,8(sp)
    80003706:	e052                	sd	s4,0(sp)
    80003708:	1800                	addi	s0,sp,48
    8000370a:	89aa                	mv	s3,a0
    8000370c:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000370e:	0001c517          	auipc	a0,0x1c
    80003712:	98a50513          	addi	a0,a0,-1654 # 8001f098 <itable>
    80003716:	ffffd097          	auipc	ra,0xffffd
    8000371a:	4c0080e7          	jalr	1216(ra) # 80000bd6 <acquire>
  empty = 0;
    8000371e:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003720:	0001c497          	auipc	s1,0x1c
    80003724:	99048493          	addi	s1,s1,-1648 # 8001f0b0 <itable+0x18>
    80003728:	0001d697          	auipc	a3,0x1d
    8000372c:	41868693          	addi	a3,a3,1048 # 80020b40 <log>
    80003730:	a039                	j	8000373e <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003732:	02090b63          	beqz	s2,80003768 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003736:	08848493          	addi	s1,s1,136
    8000373a:	02d48a63          	beq	s1,a3,8000376e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000373e:	449c                	lw	a5,8(s1)
    80003740:	fef059e3          	blez	a5,80003732 <iget+0x38>
    80003744:	4098                	lw	a4,0(s1)
    80003746:	ff3716e3          	bne	a4,s3,80003732 <iget+0x38>
    8000374a:	40d8                	lw	a4,4(s1)
    8000374c:	ff4713e3          	bne	a4,s4,80003732 <iget+0x38>
      ip->ref++;
    80003750:	2785                	addiw	a5,a5,1
    80003752:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003754:	0001c517          	auipc	a0,0x1c
    80003758:	94450513          	addi	a0,a0,-1724 # 8001f098 <itable>
    8000375c:	ffffd097          	auipc	ra,0xffffd
    80003760:	52e080e7          	jalr	1326(ra) # 80000c8a <release>
      return ip;
    80003764:	8926                	mv	s2,s1
    80003766:	a03d                	j	80003794 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003768:	f7f9                	bnez	a5,80003736 <iget+0x3c>
    8000376a:	8926                	mv	s2,s1
    8000376c:	b7e9                	j	80003736 <iget+0x3c>
  if(empty == 0)
    8000376e:	02090c63          	beqz	s2,800037a6 <iget+0xac>
  ip->dev = dev;
    80003772:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003776:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000377a:	4785                	li	a5,1
    8000377c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003780:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003784:	0001c517          	auipc	a0,0x1c
    80003788:	91450513          	addi	a0,a0,-1772 # 8001f098 <itable>
    8000378c:	ffffd097          	auipc	ra,0xffffd
    80003790:	4fe080e7          	jalr	1278(ra) # 80000c8a <release>
}
    80003794:	854a                	mv	a0,s2
    80003796:	70a2                	ld	ra,40(sp)
    80003798:	7402                	ld	s0,32(sp)
    8000379a:	64e2                	ld	s1,24(sp)
    8000379c:	6942                	ld	s2,16(sp)
    8000379e:	69a2                	ld	s3,8(sp)
    800037a0:	6a02                	ld	s4,0(sp)
    800037a2:	6145                	addi	sp,sp,48
    800037a4:	8082                	ret
    panic("iget: no inodes");
    800037a6:	00005517          	auipc	a0,0x5
    800037aa:	e1a50513          	addi	a0,a0,-486 # 800085c0 <syscalls+0x140>
    800037ae:	ffffd097          	auipc	ra,0xffffd
    800037b2:	d90080e7          	jalr	-624(ra) # 8000053e <panic>

00000000800037b6 <fsinit>:
fsinit(int dev) {
    800037b6:	7179                	addi	sp,sp,-48
    800037b8:	f406                	sd	ra,40(sp)
    800037ba:	f022                	sd	s0,32(sp)
    800037bc:	ec26                	sd	s1,24(sp)
    800037be:	e84a                	sd	s2,16(sp)
    800037c0:	e44e                	sd	s3,8(sp)
    800037c2:	1800                	addi	s0,sp,48
    800037c4:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800037c6:	4585                	li	a1,1
    800037c8:	00000097          	auipc	ra,0x0
    800037cc:	a50080e7          	jalr	-1456(ra) # 80003218 <bread>
    800037d0:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800037d2:	0001c997          	auipc	s3,0x1c
    800037d6:	8a698993          	addi	s3,s3,-1882 # 8001f078 <sb>
    800037da:	02000613          	li	a2,32
    800037de:	05850593          	addi	a1,a0,88
    800037e2:	854e                	mv	a0,s3
    800037e4:	ffffd097          	auipc	ra,0xffffd
    800037e8:	54a080e7          	jalr	1354(ra) # 80000d2e <memmove>
  brelse(bp);
    800037ec:	8526                	mv	a0,s1
    800037ee:	00000097          	auipc	ra,0x0
    800037f2:	b5a080e7          	jalr	-1190(ra) # 80003348 <brelse>
  if(sb.magic != FSMAGIC)
    800037f6:	0009a703          	lw	a4,0(s3)
    800037fa:	102037b7          	lui	a5,0x10203
    800037fe:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003802:	02f71263          	bne	a4,a5,80003826 <fsinit+0x70>
  initlog(dev, &sb);
    80003806:	0001c597          	auipc	a1,0x1c
    8000380a:	87258593          	addi	a1,a1,-1934 # 8001f078 <sb>
    8000380e:	854a                	mv	a0,s2
    80003810:	00001097          	auipc	ra,0x1
    80003814:	b40080e7          	jalr	-1216(ra) # 80004350 <initlog>
}
    80003818:	70a2                	ld	ra,40(sp)
    8000381a:	7402                	ld	s0,32(sp)
    8000381c:	64e2                	ld	s1,24(sp)
    8000381e:	6942                	ld	s2,16(sp)
    80003820:	69a2                	ld	s3,8(sp)
    80003822:	6145                	addi	sp,sp,48
    80003824:	8082                	ret
    panic("invalid file system");
    80003826:	00005517          	auipc	a0,0x5
    8000382a:	daa50513          	addi	a0,a0,-598 # 800085d0 <syscalls+0x150>
    8000382e:	ffffd097          	auipc	ra,0xffffd
    80003832:	d10080e7          	jalr	-752(ra) # 8000053e <panic>

0000000080003836 <iinit>:
{
    80003836:	7179                	addi	sp,sp,-48
    80003838:	f406                	sd	ra,40(sp)
    8000383a:	f022                	sd	s0,32(sp)
    8000383c:	ec26                	sd	s1,24(sp)
    8000383e:	e84a                	sd	s2,16(sp)
    80003840:	e44e                	sd	s3,8(sp)
    80003842:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003844:	00005597          	auipc	a1,0x5
    80003848:	da458593          	addi	a1,a1,-604 # 800085e8 <syscalls+0x168>
    8000384c:	0001c517          	auipc	a0,0x1c
    80003850:	84c50513          	addi	a0,a0,-1972 # 8001f098 <itable>
    80003854:	ffffd097          	auipc	ra,0xffffd
    80003858:	2f2080e7          	jalr	754(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000385c:	0001c497          	auipc	s1,0x1c
    80003860:	86448493          	addi	s1,s1,-1948 # 8001f0c0 <itable+0x28>
    80003864:	0001d997          	auipc	s3,0x1d
    80003868:	2ec98993          	addi	s3,s3,748 # 80020b50 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000386c:	00005917          	auipc	s2,0x5
    80003870:	d8490913          	addi	s2,s2,-636 # 800085f0 <syscalls+0x170>
    80003874:	85ca                	mv	a1,s2
    80003876:	8526                	mv	a0,s1
    80003878:	00001097          	auipc	ra,0x1
    8000387c:	e3a080e7          	jalr	-454(ra) # 800046b2 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003880:	08848493          	addi	s1,s1,136
    80003884:	ff3498e3          	bne	s1,s3,80003874 <iinit+0x3e>
}
    80003888:	70a2                	ld	ra,40(sp)
    8000388a:	7402                	ld	s0,32(sp)
    8000388c:	64e2                	ld	s1,24(sp)
    8000388e:	6942                	ld	s2,16(sp)
    80003890:	69a2                	ld	s3,8(sp)
    80003892:	6145                	addi	sp,sp,48
    80003894:	8082                	ret

0000000080003896 <ialloc>:
{
    80003896:	715d                	addi	sp,sp,-80
    80003898:	e486                	sd	ra,72(sp)
    8000389a:	e0a2                	sd	s0,64(sp)
    8000389c:	fc26                	sd	s1,56(sp)
    8000389e:	f84a                	sd	s2,48(sp)
    800038a0:	f44e                	sd	s3,40(sp)
    800038a2:	f052                	sd	s4,32(sp)
    800038a4:	ec56                	sd	s5,24(sp)
    800038a6:	e85a                	sd	s6,16(sp)
    800038a8:	e45e                	sd	s7,8(sp)
    800038aa:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800038ac:	0001b717          	auipc	a4,0x1b
    800038b0:	7d872703          	lw	a4,2008(a4) # 8001f084 <sb+0xc>
    800038b4:	4785                	li	a5,1
    800038b6:	04e7fa63          	bgeu	a5,a4,8000390a <ialloc+0x74>
    800038ba:	8aaa                	mv	s5,a0
    800038bc:	8bae                	mv	s7,a1
    800038be:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800038c0:	0001ba17          	auipc	s4,0x1b
    800038c4:	7b8a0a13          	addi	s4,s4,1976 # 8001f078 <sb>
    800038c8:	00048b1b          	sext.w	s6,s1
    800038cc:	0044d793          	srli	a5,s1,0x4
    800038d0:	018a2583          	lw	a1,24(s4)
    800038d4:	9dbd                	addw	a1,a1,a5
    800038d6:	8556                	mv	a0,s5
    800038d8:	00000097          	auipc	ra,0x0
    800038dc:	940080e7          	jalr	-1728(ra) # 80003218 <bread>
    800038e0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800038e2:	05850993          	addi	s3,a0,88
    800038e6:	00f4f793          	andi	a5,s1,15
    800038ea:	079a                	slli	a5,a5,0x6
    800038ec:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800038ee:	00099783          	lh	a5,0(s3)
    800038f2:	c3a1                	beqz	a5,80003932 <ialloc+0x9c>
    brelse(bp);
    800038f4:	00000097          	auipc	ra,0x0
    800038f8:	a54080e7          	jalr	-1452(ra) # 80003348 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800038fc:	0485                	addi	s1,s1,1
    800038fe:	00ca2703          	lw	a4,12(s4)
    80003902:	0004879b          	sext.w	a5,s1
    80003906:	fce7e1e3          	bltu	a5,a4,800038c8 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    8000390a:	00005517          	auipc	a0,0x5
    8000390e:	cee50513          	addi	a0,a0,-786 # 800085f8 <syscalls+0x178>
    80003912:	ffffd097          	auipc	ra,0xffffd
    80003916:	c76080e7          	jalr	-906(ra) # 80000588 <printf>
  return 0;
    8000391a:	4501                	li	a0,0
}
    8000391c:	60a6                	ld	ra,72(sp)
    8000391e:	6406                	ld	s0,64(sp)
    80003920:	74e2                	ld	s1,56(sp)
    80003922:	7942                	ld	s2,48(sp)
    80003924:	79a2                	ld	s3,40(sp)
    80003926:	7a02                	ld	s4,32(sp)
    80003928:	6ae2                	ld	s5,24(sp)
    8000392a:	6b42                	ld	s6,16(sp)
    8000392c:	6ba2                	ld	s7,8(sp)
    8000392e:	6161                	addi	sp,sp,80
    80003930:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003932:	04000613          	li	a2,64
    80003936:	4581                	li	a1,0
    80003938:	854e                	mv	a0,s3
    8000393a:	ffffd097          	auipc	ra,0xffffd
    8000393e:	398080e7          	jalr	920(ra) # 80000cd2 <memset>
      dip->type = type;
    80003942:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003946:	854a                	mv	a0,s2
    80003948:	00001097          	auipc	ra,0x1
    8000394c:	c84080e7          	jalr	-892(ra) # 800045cc <log_write>
      brelse(bp);
    80003950:	854a                	mv	a0,s2
    80003952:	00000097          	auipc	ra,0x0
    80003956:	9f6080e7          	jalr	-1546(ra) # 80003348 <brelse>
      return iget(dev, inum);
    8000395a:	85da                	mv	a1,s6
    8000395c:	8556                	mv	a0,s5
    8000395e:	00000097          	auipc	ra,0x0
    80003962:	d9c080e7          	jalr	-612(ra) # 800036fa <iget>
    80003966:	bf5d                	j	8000391c <ialloc+0x86>

0000000080003968 <iupdate>:
{
    80003968:	1101                	addi	sp,sp,-32
    8000396a:	ec06                	sd	ra,24(sp)
    8000396c:	e822                	sd	s0,16(sp)
    8000396e:	e426                	sd	s1,8(sp)
    80003970:	e04a                	sd	s2,0(sp)
    80003972:	1000                	addi	s0,sp,32
    80003974:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003976:	415c                	lw	a5,4(a0)
    80003978:	0047d79b          	srliw	a5,a5,0x4
    8000397c:	0001b597          	auipc	a1,0x1b
    80003980:	7145a583          	lw	a1,1812(a1) # 8001f090 <sb+0x18>
    80003984:	9dbd                	addw	a1,a1,a5
    80003986:	4108                	lw	a0,0(a0)
    80003988:	00000097          	auipc	ra,0x0
    8000398c:	890080e7          	jalr	-1904(ra) # 80003218 <bread>
    80003990:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003992:	05850793          	addi	a5,a0,88
    80003996:	40c8                	lw	a0,4(s1)
    80003998:	893d                	andi	a0,a0,15
    8000399a:	051a                	slli	a0,a0,0x6
    8000399c:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000399e:	04449703          	lh	a4,68(s1)
    800039a2:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800039a6:	04649703          	lh	a4,70(s1)
    800039aa:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800039ae:	04849703          	lh	a4,72(s1)
    800039b2:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800039b6:	04a49703          	lh	a4,74(s1)
    800039ba:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800039be:	44f8                	lw	a4,76(s1)
    800039c0:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800039c2:	03400613          	li	a2,52
    800039c6:	05048593          	addi	a1,s1,80
    800039ca:	0531                	addi	a0,a0,12
    800039cc:	ffffd097          	auipc	ra,0xffffd
    800039d0:	362080e7          	jalr	866(ra) # 80000d2e <memmove>
  log_write(bp);
    800039d4:	854a                	mv	a0,s2
    800039d6:	00001097          	auipc	ra,0x1
    800039da:	bf6080e7          	jalr	-1034(ra) # 800045cc <log_write>
  brelse(bp);
    800039de:	854a                	mv	a0,s2
    800039e0:	00000097          	auipc	ra,0x0
    800039e4:	968080e7          	jalr	-1688(ra) # 80003348 <brelse>
}
    800039e8:	60e2                	ld	ra,24(sp)
    800039ea:	6442                	ld	s0,16(sp)
    800039ec:	64a2                	ld	s1,8(sp)
    800039ee:	6902                	ld	s2,0(sp)
    800039f0:	6105                	addi	sp,sp,32
    800039f2:	8082                	ret

00000000800039f4 <idup>:
{
    800039f4:	1101                	addi	sp,sp,-32
    800039f6:	ec06                	sd	ra,24(sp)
    800039f8:	e822                	sd	s0,16(sp)
    800039fa:	e426                	sd	s1,8(sp)
    800039fc:	1000                	addi	s0,sp,32
    800039fe:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a00:	0001b517          	auipc	a0,0x1b
    80003a04:	69850513          	addi	a0,a0,1688 # 8001f098 <itable>
    80003a08:	ffffd097          	auipc	ra,0xffffd
    80003a0c:	1ce080e7          	jalr	462(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003a10:	449c                	lw	a5,8(s1)
    80003a12:	2785                	addiw	a5,a5,1
    80003a14:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a16:	0001b517          	auipc	a0,0x1b
    80003a1a:	68250513          	addi	a0,a0,1666 # 8001f098 <itable>
    80003a1e:	ffffd097          	auipc	ra,0xffffd
    80003a22:	26c080e7          	jalr	620(ra) # 80000c8a <release>
}
    80003a26:	8526                	mv	a0,s1
    80003a28:	60e2                	ld	ra,24(sp)
    80003a2a:	6442                	ld	s0,16(sp)
    80003a2c:	64a2                	ld	s1,8(sp)
    80003a2e:	6105                	addi	sp,sp,32
    80003a30:	8082                	ret

0000000080003a32 <ilock>:
{
    80003a32:	1101                	addi	sp,sp,-32
    80003a34:	ec06                	sd	ra,24(sp)
    80003a36:	e822                	sd	s0,16(sp)
    80003a38:	e426                	sd	s1,8(sp)
    80003a3a:	e04a                	sd	s2,0(sp)
    80003a3c:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003a3e:	c115                	beqz	a0,80003a62 <ilock+0x30>
    80003a40:	84aa                	mv	s1,a0
    80003a42:	451c                	lw	a5,8(a0)
    80003a44:	00f05f63          	blez	a5,80003a62 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003a48:	0541                	addi	a0,a0,16
    80003a4a:	00001097          	auipc	ra,0x1
    80003a4e:	ca2080e7          	jalr	-862(ra) # 800046ec <acquiresleep>
  if(ip->valid == 0){
    80003a52:	40bc                	lw	a5,64(s1)
    80003a54:	cf99                	beqz	a5,80003a72 <ilock+0x40>
}
    80003a56:	60e2                	ld	ra,24(sp)
    80003a58:	6442                	ld	s0,16(sp)
    80003a5a:	64a2                	ld	s1,8(sp)
    80003a5c:	6902                	ld	s2,0(sp)
    80003a5e:	6105                	addi	sp,sp,32
    80003a60:	8082                	ret
    panic("ilock");
    80003a62:	00005517          	auipc	a0,0x5
    80003a66:	bae50513          	addi	a0,a0,-1106 # 80008610 <syscalls+0x190>
    80003a6a:	ffffd097          	auipc	ra,0xffffd
    80003a6e:	ad4080e7          	jalr	-1324(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a72:	40dc                	lw	a5,4(s1)
    80003a74:	0047d79b          	srliw	a5,a5,0x4
    80003a78:	0001b597          	auipc	a1,0x1b
    80003a7c:	6185a583          	lw	a1,1560(a1) # 8001f090 <sb+0x18>
    80003a80:	9dbd                	addw	a1,a1,a5
    80003a82:	4088                	lw	a0,0(s1)
    80003a84:	fffff097          	auipc	ra,0xfffff
    80003a88:	794080e7          	jalr	1940(ra) # 80003218 <bread>
    80003a8c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a8e:	05850593          	addi	a1,a0,88
    80003a92:	40dc                	lw	a5,4(s1)
    80003a94:	8bbd                	andi	a5,a5,15
    80003a96:	079a                	slli	a5,a5,0x6
    80003a98:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003a9a:	00059783          	lh	a5,0(a1)
    80003a9e:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003aa2:	00259783          	lh	a5,2(a1)
    80003aa6:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003aaa:	00459783          	lh	a5,4(a1)
    80003aae:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003ab2:	00659783          	lh	a5,6(a1)
    80003ab6:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003aba:	459c                	lw	a5,8(a1)
    80003abc:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003abe:	03400613          	li	a2,52
    80003ac2:	05b1                	addi	a1,a1,12
    80003ac4:	05048513          	addi	a0,s1,80
    80003ac8:	ffffd097          	auipc	ra,0xffffd
    80003acc:	266080e7          	jalr	614(ra) # 80000d2e <memmove>
    brelse(bp);
    80003ad0:	854a                	mv	a0,s2
    80003ad2:	00000097          	auipc	ra,0x0
    80003ad6:	876080e7          	jalr	-1930(ra) # 80003348 <brelse>
    ip->valid = 1;
    80003ada:	4785                	li	a5,1
    80003adc:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003ade:	04449783          	lh	a5,68(s1)
    80003ae2:	fbb5                	bnez	a5,80003a56 <ilock+0x24>
      panic("ilock: no type");
    80003ae4:	00005517          	auipc	a0,0x5
    80003ae8:	b3450513          	addi	a0,a0,-1228 # 80008618 <syscalls+0x198>
    80003aec:	ffffd097          	auipc	ra,0xffffd
    80003af0:	a52080e7          	jalr	-1454(ra) # 8000053e <panic>

0000000080003af4 <iunlock>:
{
    80003af4:	1101                	addi	sp,sp,-32
    80003af6:	ec06                	sd	ra,24(sp)
    80003af8:	e822                	sd	s0,16(sp)
    80003afa:	e426                	sd	s1,8(sp)
    80003afc:	e04a                	sd	s2,0(sp)
    80003afe:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003b00:	c905                	beqz	a0,80003b30 <iunlock+0x3c>
    80003b02:	84aa                	mv	s1,a0
    80003b04:	01050913          	addi	s2,a0,16
    80003b08:	854a                	mv	a0,s2
    80003b0a:	00001097          	auipc	ra,0x1
    80003b0e:	c7c080e7          	jalr	-900(ra) # 80004786 <holdingsleep>
    80003b12:	cd19                	beqz	a0,80003b30 <iunlock+0x3c>
    80003b14:	449c                	lw	a5,8(s1)
    80003b16:	00f05d63          	blez	a5,80003b30 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003b1a:	854a                	mv	a0,s2
    80003b1c:	00001097          	auipc	ra,0x1
    80003b20:	c26080e7          	jalr	-986(ra) # 80004742 <releasesleep>
}
    80003b24:	60e2                	ld	ra,24(sp)
    80003b26:	6442                	ld	s0,16(sp)
    80003b28:	64a2                	ld	s1,8(sp)
    80003b2a:	6902                	ld	s2,0(sp)
    80003b2c:	6105                	addi	sp,sp,32
    80003b2e:	8082                	ret
    panic("iunlock");
    80003b30:	00005517          	auipc	a0,0x5
    80003b34:	af850513          	addi	a0,a0,-1288 # 80008628 <syscalls+0x1a8>
    80003b38:	ffffd097          	auipc	ra,0xffffd
    80003b3c:	a06080e7          	jalr	-1530(ra) # 8000053e <panic>

0000000080003b40 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003b40:	7179                	addi	sp,sp,-48
    80003b42:	f406                	sd	ra,40(sp)
    80003b44:	f022                	sd	s0,32(sp)
    80003b46:	ec26                	sd	s1,24(sp)
    80003b48:	e84a                	sd	s2,16(sp)
    80003b4a:	e44e                	sd	s3,8(sp)
    80003b4c:	e052                	sd	s4,0(sp)
    80003b4e:	1800                	addi	s0,sp,48
    80003b50:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003b52:	05050493          	addi	s1,a0,80
    80003b56:	08050913          	addi	s2,a0,128
    80003b5a:	a021                	j	80003b62 <itrunc+0x22>
    80003b5c:	0491                	addi	s1,s1,4
    80003b5e:	01248d63          	beq	s1,s2,80003b78 <itrunc+0x38>
    if(ip->addrs[i]){
    80003b62:	408c                	lw	a1,0(s1)
    80003b64:	dde5                	beqz	a1,80003b5c <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003b66:	0009a503          	lw	a0,0(s3)
    80003b6a:	00000097          	auipc	ra,0x0
    80003b6e:	8f4080e7          	jalr	-1804(ra) # 8000345e <bfree>
      ip->addrs[i] = 0;
    80003b72:	0004a023          	sw	zero,0(s1)
    80003b76:	b7dd                	j	80003b5c <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003b78:	0809a583          	lw	a1,128(s3)
    80003b7c:	e185                	bnez	a1,80003b9c <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003b7e:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003b82:	854e                	mv	a0,s3
    80003b84:	00000097          	auipc	ra,0x0
    80003b88:	de4080e7          	jalr	-540(ra) # 80003968 <iupdate>
}
    80003b8c:	70a2                	ld	ra,40(sp)
    80003b8e:	7402                	ld	s0,32(sp)
    80003b90:	64e2                	ld	s1,24(sp)
    80003b92:	6942                	ld	s2,16(sp)
    80003b94:	69a2                	ld	s3,8(sp)
    80003b96:	6a02                	ld	s4,0(sp)
    80003b98:	6145                	addi	sp,sp,48
    80003b9a:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003b9c:	0009a503          	lw	a0,0(s3)
    80003ba0:	fffff097          	auipc	ra,0xfffff
    80003ba4:	678080e7          	jalr	1656(ra) # 80003218 <bread>
    80003ba8:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003baa:	05850493          	addi	s1,a0,88
    80003bae:	45850913          	addi	s2,a0,1112
    80003bb2:	a021                	j	80003bba <itrunc+0x7a>
    80003bb4:	0491                	addi	s1,s1,4
    80003bb6:	01248b63          	beq	s1,s2,80003bcc <itrunc+0x8c>
      if(a[j])
    80003bba:	408c                	lw	a1,0(s1)
    80003bbc:	dde5                	beqz	a1,80003bb4 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003bbe:	0009a503          	lw	a0,0(s3)
    80003bc2:	00000097          	auipc	ra,0x0
    80003bc6:	89c080e7          	jalr	-1892(ra) # 8000345e <bfree>
    80003bca:	b7ed                	j	80003bb4 <itrunc+0x74>
    brelse(bp);
    80003bcc:	8552                	mv	a0,s4
    80003bce:	fffff097          	auipc	ra,0xfffff
    80003bd2:	77a080e7          	jalr	1914(ra) # 80003348 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003bd6:	0809a583          	lw	a1,128(s3)
    80003bda:	0009a503          	lw	a0,0(s3)
    80003bde:	00000097          	auipc	ra,0x0
    80003be2:	880080e7          	jalr	-1920(ra) # 8000345e <bfree>
    ip->addrs[NDIRECT] = 0;
    80003be6:	0809a023          	sw	zero,128(s3)
    80003bea:	bf51                	j	80003b7e <itrunc+0x3e>

0000000080003bec <iput>:
{
    80003bec:	1101                	addi	sp,sp,-32
    80003bee:	ec06                	sd	ra,24(sp)
    80003bf0:	e822                	sd	s0,16(sp)
    80003bf2:	e426                	sd	s1,8(sp)
    80003bf4:	e04a                	sd	s2,0(sp)
    80003bf6:	1000                	addi	s0,sp,32
    80003bf8:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003bfa:	0001b517          	auipc	a0,0x1b
    80003bfe:	49e50513          	addi	a0,a0,1182 # 8001f098 <itable>
    80003c02:	ffffd097          	auipc	ra,0xffffd
    80003c06:	fd4080e7          	jalr	-44(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003c0a:	4498                	lw	a4,8(s1)
    80003c0c:	4785                	li	a5,1
    80003c0e:	02f70363          	beq	a4,a5,80003c34 <iput+0x48>
  ip->ref--;
    80003c12:	449c                	lw	a5,8(s1)
    80003c14:	37fd                	addiw	a5,a5,-1
    80003c16:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003c18:	0001b517          	auipc	a0,0x1b
    80003c1c:	48050513          	addi	a0,a0,1152 # 8001f098 <itable>
    80003c20:	ffffd097          	auipc	ra,0xffffd
    80003c24:	06a080e7          	jalr	106(ra) # 80000c8a <release>
}
    80003c28:	60e2                	ld	ra,24(sp)
    80003c2a:	6442                	ld	s0,16(sp)
    80003c2c:	64a2                	ld	s1,8(sp)
    80003c2e:	6902                	ld	s2,0(sp)
    80003c30:	6105                	addi	sp,sp,32
    80003c32:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003c34:	40bc                	lw	a5,64(s1)
    80003c36:	dff1                	beqz	a5,80003c12 <iput+0x26>
    80003c38:	04a49783          	lh	a5,74(s1)
    80003c3c:	fbf9                	bnez	a5,80003c12 <iput+0x26>
    acquiresleep(&ip->lock);
    80003c3e:	01048913          	addi	s2,s1,16
    80003c42:	854a                	mv	a0,s2
    80003c44:	00001097          	auipc	ra,0x1
    80003c48:	aa8080e7          	jalr	-1368(ra) # 800046ec <acquiresleep>
    release(&itable.lock);
    80003c4c:	0001b517          	auipc	a0,0x1b
    80003c50:	44c50513          	addi	a0,a0,1100 # 8001f098 <itable>
    80003c54:	ffffd097          	auipc	ra,0xffffd
    80003c58:	036080e7          	jalr	54(ra) # 80000c8a <release>
    itrunc(ip);
    80003c5c:	8526                	mv	a0,s1
    80003c5e:	00000097          	auipc	ra,0x0
    80003c62:	ee2080e7          	jalr	-286(ra) # 80003b40 <itrunc>
    ip->type = 0;
    80003c66:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003c6a:	8526                	mv	a0,s1
    80003c6c:	00000097          	auipc	ra,0x0
    80003c70:	cfc080e7          	jalr	-772(ra) # 80003968 <iupdate>
    ip->valid = 0;
    80003c74:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003c78:	854a                	mv	a0,s2
    80003c7a:	00001097          	auipc	ra,0x1
    80003c7e:	ac8080e7          	jalr	-1336(ra) # 80004742 <releasesleep>
    acquire(&itable.lock);
    80003c82:	0001b517          	auipc	a0,0x1b
    80003c86:	41650513          	addi	a0,a0,1046 # 8001f098 <itable>
    80003c8a:	ffffd097          	auipc	ra,0xffffd
    80003c8e:	f4c080e7          	jalr	-180(ra) # 80000bd6 <acquire>
    80003c92:	b741                	j	80003c12 <iput+0x26>

0000000080003c94 <iunlockput>:
{
    80003c94:	1101                	addi	sp,sp,-32
    80003c96:	ec06                	sd	ra,24(sp)
    80003c98:	e822                	sd	s0,16(sp)
    80003c9a:	e426                	sd	s1,8(sp)
    80003c9c:	1000                	addi	s0,sp,32
    80003c9e:	84aa                	mv	s1,a0
  iunlock(ip);
    80003ca0:	00000097          	auipc	ra,0x0
    80003ca4:	e54080e7          	jalr	-428(ra) # 80003af4 <iunlock>
  iput(ip);
    80003ca8:	8526                	mv	a0,s1
    80003caa:	00000097          	auipc	ra,0x0
    80003cae:	f42080e7          	jalr	-190(ra) # 80003bec <iput>
}
    80003cb2:	60e2                	ld	ra,24(sp)
    80003cb4:	6442                	ld	s0,16(sp)
    80003cb6:	64a2                	ld	s1,8(sp)
    80003cb8:	6105                	addi	sp,sp,32
    80003cba:	8082                	ret

0000000080003cbc <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003cbc:	1141                	addi	sp,sp,-16
    80003cbe:	e422                	sd	s0,8(sp)
    80003cc0:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003cc2:	411c                	lw	a5,0(a0)
    80003cc4:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003cc6:	415c                	lw	a5,4(a0)
    80003cc8:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003cca:	04451783          	lh	a5,68(a0)
    80003cce:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003cd2:	04a51783          	lh	a5,74(a0)
    80003cd6:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003cda:	04c56783          	lwu	a5,76(a0)
    80003cde:	e99c                	sd	a5,16(a1)
}
    80003ce0:	6422                	ld	s0,8(sp)
    80003ce2:	0141                	addi	sp,sp,16
    80003ce4:	8082                	ret

0000000080003ce6 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ce6:	457c                	lw	a5,76(a0)
    80003ce8:	0ed7e963          	bltu	a5,a3,80003dda <readi+0xf4>
{
    80003cec:	7159                	addi	sp,sp,-112
    80003cee:	f486                	sd	ra,104(sp)
    80003cf0:	f0a2                	sd	s0,96(sp)
    80003cf2:	eca6                	sd	s1,88(sp)
    80003cf4:	e8ca                	sd	s2,80(sp)
    80003cf6:	e4ce                	sd	s3,72(sp)
    80003cf8:	e0d2                	sd	s4,64(sp)
    80003cfa:	fc56                	sd	s5,56(sp)
    80003cfc:	f85a                	sd	s6,48(sp)
    80003cfe:	f45e                	sd	s7,40(sp)
    80003d00:	f062                	sd	s8,32(sp)
    80003d02:	ec66                	sd	s9,24(sp)
    80003d04:	e86a                	sd	s10,16(sp)
    80003d06:	e46e                	sd	s11,8(sp)
    80003d08:	1880                	addi	s0,sp,112
    80003d0a:	8b2a                	mv	s6,a0
    80003d0c:	8bae                	mv	s7,a1
    80003d0e:	8a32                	mv	s4,a2
    80003d10:	84b6                	mv	s1,a3
    80003d12:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003d14:	9f35                	addw	a4,a4,a3
    return 0;
    80003d16:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003d18:	0ad76063          	bltu	a4,a3,80003db8 <readi+0xd2>
  if(off + n > ip->size)
    80003d1c:	00e7f463          	bgeu	a5,a4,80003d24 <readi+0x3e>
    n = ip->size - off;
    80003d20:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d24:	0a0a8963          	beqz	s5,80003dd6 <readi+0xf0>
    80003d28:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d2a:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003d2e:	5c7d                	li	s8,-1
    80003d30:	a82d                	j	80003d6a <readi+0x84>
    80003d32:	020d1d93          	slli	s11,s10,0x20
    80003d36:	020ddd93          	srli	s11,s11,0x20
    80003d3a:	05890793          	addi	a5,s2,88
    80003d3e:	86ee                	mv	a3,s11
    80003d40:	963e                	add	a2,a2,a5
    80003d42:	85d2                	mv	a1,s4
    80003d44:	855e                	mv	a0,s7
    80003d46:	fffff097          	auipc	ra,0xfffff
    80003d4a:	9d4080e7          	jalr	-1580(ra) # 8000271a <either_copyout>
    80003d4e:	05850d63          	beq	a0,s8,80003da8 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003d52:	854a                	mv	a0,s2
    80003d54:	fffff097          	auipc	ra,0xfffff
    80003d58:	5f4080e7          	jalr	1524(ra) # 80003348 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d5c:	013d09bb          	addw	s3,s10,s3
    80003d60:	009d04bb          	addw	s1,s10,s1
    80003d64:	9a6e                	add	s4,s4,s11
    80003d66:	0559f763          	bgeu	s3,s5,80003db4 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003d6a:	00a4d59b          	srliw	a1,s1,0xa
    80003d6e:	855a                	mv	a0,s6
    80003d70:	00000097          	auipc	ra,0x0
    80003d74:	8a2080e7          	jalr	-1886(ra) # 80003612 <bmap>
    80003d78:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003d7c:	cd85                	beqz	a1,80003db4 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003d7e:	000b2503          	lw	a0,0(s6)
    80003d82:	fffff097          	auipc	ra,0xfffff
    80003d86:	496080e7          	jalr	1174(ra) # 80003218 <bread>
    80003d8a:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d8c:	3ff4f613          	andi	a2,s1,1023
    80003d90:	40cc87bb          	subw	a5,s9,a2
    80003d94:	413a873b          	subw	a4,s5,s3
    80003d98:	8d3e                	mv	s10,a5
    80003d9a:	2781                	sext.w	a5,a5
    80003d9c:	0007069b          	sext.w	a3,a4
    80003da0:	f8f6f9e3          	bgeu	a3,a5,80003d32 <readi+0x4c>
    80003da4:	8d3a                	mv	s10,a4
    80003da6:	b771                	j	80003d32 <readi+0x4c>
      brelse(bp);
    80003da8:	854a                	mv	a0,s2
    80003daa:	fffff097          	auipc	ra,0xfffff
    80003dae:	59e080e7          	jalr	1438(ra) # 80003348 <brelse>
      tot = -1;
    80003db2:	59fd                	li	s3,-1
  }
  return tot;
    80003db4:	0009851b          	sext.w	a0,s3
}
    80003db8:	70a6                	ld	ra,104(sp)
    80003dba:	7406                	ld	s0,96(sp)
    80003dbc:	64e6                	ld	s1,88(sp)
    80003dbe:	6946                	ld	s2,80(sp)
    80003dc0:	69a6                	ld	s3,72(sp)
    80003dc2:	6a06                	ld	s4,64(sp)
    80003dc4:	7ae2                	ld	s5,56(sp)
    80003dc6:	7b42                	ld	s6,48(sp)
    80003dc8:	7ba2                	ld	s7,40(sp)
    80003dca:	7c02                	ld	s8,32(sp)
    80003dcc:	6ce2                	ld	s9,24(sp)
    80003dce:	6d42                	ld	s10,16(sp)
    80003dd0:	6da2                	ld	s11,8(sp)
    80003dd2:	6165                	addi	sp,sp,112
    80003dd4:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003dd6:	89d6                	mv	s3,s5
    80003dd8:	bff1                	j	80003db4 <readi+0xce>
    return 0;
    80003dda:	4501                	li	a0,0
}
    80003ddc:	8082                	ret

0000000080003dde <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003dde:	457c                	lw	a5,76(a0)
    80003de0:	10d7e863          	bltu	a5,a3,80003ef0 <writei+0x112>
{
    80003de4:	7159                	addi	sp,sp,-112
    80003de6:	f486                	sd	ra,104(sp)
    80003de8:	f0a2                	sd	s0,96(sp)
    80003dea:	eca6                	sd	s1,88(sp)
    80003dec:	e8ca                	sd	s2,80(sp)
    80003dee:	e4ce                	sd	s3,72(sp)
    80003df0:	e0d2                	sd	s4,64(sp)
    80003df2:	fc56                	sd	s5,56(sp)
    80003df4:	f85a                	sd	s6,48(sp)
    80003df6:	f45e                	sd	s7,40(sp)
    80003df8:	f062                	sd	s8,32(sp)
    80003dfa:	ec66                	sd	s9,24(sp)
    80003dfc:	e86a                	sd	s10,16(sp)
    80003dfe:	e46e                	sd	s11,8(sp)
    80003e00:	1880                	addi	s0,sp,112
    80003e02:	8aaa                	mv	s5,a0
    80003e04:	8bae                	mv	s7,a1
    80003e06:	8a32                	mv	s4,a2
    80003e08:	8936                	mv	s2,a3
    80003e0a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003e0c:	00e687bb          	addw	a5,a3,a4
    80003e10:	0ed7e263          	bltu	a5,a3,80003ef4 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003e14:	00043737          	lui	a4,0x43
    80003e18:	0ef76063          	bltu	a4,a5,80003ef8 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e1c:	0c0b0863          	beqz	s6,80003eec <writei+0x10e>
    80003e20:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e22:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003e26:	5c7d                	li	s8,-1
    80003e28:	a091                	j	80003e6c <writei+0x8e>
    80003e2a:	020d1d93          	slli	s11,s10,0x20
    80003e2e:	020ddd93          	srli	s11,s11,0x20
    80003e32:	05848793          	addi	a5,s1,88
    80003e36:	86ee                	mv	a3,s11
    80003e38:	8652                	mv	a2,s4
    80003e3a:	85de                	mv	a1,s7
    80003e3c:	953e                	add	a0,a0,a5
    80003e3e:	fffff097          	auipc	ra,0xfffff
    80003e42:	932080e7          	jalr	-1742(ra) # 80002770 <either_copyin>
    80003e46:	07850263          	beq	a0,s8,80003eaa <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003e4a:	8526                	mv	a0,s1
    80003e4c:	00000097          	auipc	ra,0x0
    80003e50:	780080e7          	jalr	1920(ra) # 800045cc <log_write>
    brelse(bp);
    80003e54:	8526                	mv	a0,s1
    80003e56:	fffff097          	auipc	ra,0xfffff
    80003e5a:	4f2080e7          	jalr	1266(ra) # 80003348 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e5e:	013d09bb          	addw	s3,s10,s3
    80003e62:	012d093b          	addw	s2,s10,s2
    80003e66:	9a6e                	add	s4,s4,s11
    80003e68:	0569f663          	bgeu	s3,s6,80003eb4 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003e6c:	00a9559b          	srliw	a1,s2,0xa
    80003e70:	8556                	mv	a0,s5
    80003e72:	fffff097          	auipc	ra,0xfffff
    80003e76:	7a0080e7          	jalr	1952(ra) # 80003612 <bmap>
    80003e7a:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003e7e:	c99d                	beqz	a1,80003eb4 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003e80:	000aa503          	lw	a0,0(s5)
    80003e84:	fffff097          	auipc	ra,0xfffff
    80003e88:	394080e7          	jalr	916(ra) # 80003218 <bread>
    80003e8c:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e8e:	3ff97513          	andi	a0,s2,1023
    80003e92:	40ac87bb          	subw	a5,s9,a0
    80003e96:	413b073b          	subw	a4,s6,s3
    80003e9a:	8d3e                	mv	s10,a5
    80003e9c:	2781                	sext.w	a5,a5
    80003e9e:	0007069b          	sext.w	a3,a4
    80003ea2:	f8f6f4e3          	bgeu	a3,a5,80003e2a <writei+0x4c>
    80003ea6:	8d3a                	mv	s10,a4
    80003ea8:	b749                	j	80003e2a <writei+0x4c>
      brelse(bp);
    80003eaa:	8526                	mv	a0,s1
    80003eac:	fffff097          	auipc	ra,0xfffff
    80003eb0:	49c080e7          	jalr	1180(ra) # 80003348 <brelse>
  }

  if(off > ip->size)
    80003eb4:	04caa783          	lw	a5,76(s5)
    80003eb8:	0127f463          	bgeu	a5,s2,80003ec0 <writei+0xe2>
    ip->size = off;
    80003ebc:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003ec0:	8556                	mv	a0,s5
    80003ec2:	00000097          	auipc	ra,0x0
    80003ec6:	aa6080e7          	jalr	-1370(ra) # 80003968 <iupdate>

  return tot;
    80003eca:	0009851b          	sext.w	a0,s3
}
    80003ece:	70a6                	ld	ra,104(sp)
    80003ed0:	7406                	ld	s0,96(sp)
    80003ed2:	64e6                	ld	s1,88(sp)
    80003ed4:	6946                	ld	s2,80(sp)
    80003ed6:	69a6                	ld	s3,72(sp)
    80003ed8:	6a06                	ld	s4,64(sp)
    80003eda:	7ae2                	ld	s5,56(sp)
    80003edc:	7b42                	ld	s6,48(sp)
    80003ede:	7ba2                	ld	s7,40(sp)
    80003ee0:	7c02                	ld	s8,32(sp)
    80003ee2:	6ce2                	ld	s9,24(sp)
    80003ee4:	6d42                	ld	s10,16(sp)
    80003ee6:	6da2                	ld	s11,8(sp)
    80003ee8:	6165                	addi	sp,sp,112
    80003eea:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003eec:	89da                	mv	s3,s6
    80003eee:	bfc9                	j	80003ec0 <writei+0xe2>
    return -1;
    80003ef0:	557d                	li	a0,-1
}
    80003ef2:	8082                	ret
    return -1;
    80003ef4:	557d                	li	a0,-1
    80003ef6:	bfe1                	j	80003ece <writei+0xf0>
    return -1;
    80003ef8:	557d                	li	a0,-1
    80003efa:	bfd1                	j	80003ece <writei+0xf0>

0000000080003efc <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003efc:	1141                	addi	sp,sp,-16
    80003efe:	e406                	sd	ra,8(sp)
    80003f00:	e022                	sd	s0,0(sp)
    80003f02:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003f04:	4639                	li	a2,14
    80003f06:	ffffd097          	auipc	ra,0xffffd
    80003f0a:	e9c080e7          	jalr	-356(ra) # 80000da2 <strncmp>
}
    80003f0e:	60a2                	ld	ra,8(sp)
    80003f10:	6402                	ld	s0,0(sp)
    80003f12:	0141                	addi	sp,sp,16
    80003f14:	8082                	ret

0000000080003f16 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003f16:	7139                	addi	sp,sp,-64
    80003f18:	fc06                	sd	ra,56(sp)
    80003f1a:	f822                	sd	s0,48(sp)
    80003f1c:	f426                	sd	s1,40(sp)
    80003f1e:	f04a                	sd	s2,32(sp)
    80003f20:	ec4e                	sd	s3,24(sp)
    80003f22:	e852                	sd	s4,16(sp)
    80003f24:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003f26:	04451703          	lh	a4,68(a0)
    80003f2a:	4785                	li	a5,1
    80003f2c:	00f71a63          	bne	a4,a5,80003f40 <dirlookup+0x2a>
    80003f30:	892a                	mv	s2,a0
    80003f32:	89ae                	mv	s3,a1
    80003f34:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f36:	457c                	lw	a5,76(a0)
    80003f38:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003f3a:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f3c:	e79d                	bnez	a5,80003f6a <dirlookup+0x54>
    80003f3e:	a8a5                	j	80003fb6 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003f40:	00004517          	auipc	a0,0x4
    80003f44:	6f050513          	addi	a0,a0,1776 # 80008630 <syscalls+0x1b0>
    80003f48:	ffffc097          	auipc	ra,0xffffc
    80003f4c:	5f6080e7          	jalr	1526(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003f50:	00004517          	auipc	a0,0x4
    80003f54:	6f850513          	addi	a0,a0,1784 # 80008648 <syscalls+0x1c8>
    80003f58:	ffffc097          	auipc	ra,0xffffc
    80003f5c:	5e6080e7          	jalr	1510(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f60:	24c1                	addiw	s1,s1,16
    80003f62:	04c92783          	lw	a5,76(s2)
    80003f66:	04f4f763          	bgeu	s1,a5,80003fb4 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f6a:	4741                	li	a4,16
    80003f6c:	86a6                	mv	a3,s1
    80003f6e:	fc040613          	addi	a2,s0,-64
    80003f72:	4581                	li	a1,0
    80003f74:	854a                	mv	a0,s2
    80003f76:	00000097          	auipc	ra,0x0
    80003f7a:	d70080e7          	jalr	-656(ra) # 80003ce6 <readi>
    80003f7e:	47c1                	li	a5,16
    80003f80:	fcf518e3          	bne	a0,a5,80003f50 <dirlookup+0x3a>
    if(de.inum == 0)
    80003f84:	fc045783          	lhu	a5,-64(s0)
    80003f88:	dfe1                	beqz	a5,80003f60 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003f8a:	fc240593          	addi	a1,s0,-62
    80003f8e:	854e                	mv	a0,s3
    80003f90:	00000097          	auipc	ra,0x0
    80003f94:	f6c080e7          	jalr	-148(ra) # 80003efc <namecmp>
    80003f98:	f561                	bnez	a0,80003f60 <dirlookup+0x4a>
      if(poff)
    80003f9a:	000a0463          	beqz	s4,80003fa2 <dirlookup+0x8c>
        *poff = off;
    80003f9e:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003fa2:	fc045583          	lhu	a1,-64(s0)
    80003fa6:	00092503          	lw	a0,0(s2)
    80003faa:	fffff097          	auipc	ra,0xfffff
    80003fae:	750080e7          	jalr	1872(ra) # 800036fa <iget>
    80003fb2:	a011                	j	80003fb6 <dirlookup+0xa0>
  return 0;
    80003fb4:	4501                	li	a0,0
}
    80003fb6:	70e2                	ld	ra,56(sp)
    80003fb8:	7442                	ld	s0,48(sp)
    80003fba:	74a2                	ld	s1,40(sp)
    80003fbc:	7902                	ld	s2,32(sp)
    80003fbe:	69e2                	ld	s3,24(sp)
    80003fc0:	6a42                	ld	s4,16(sp)
    80003fc2:	6121                	addi	sp,sp,64
    80003fc4:	8082                	ret

0000000080003fc6 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003fc6:	711d                	addi	sp,sp,-96
    80003fc8:	ec86                	sd	ra,88(sp)
    80003fca:	e8a2                	sd	s0,80(sp)
    80003fcc:	e4a6                	sd	s1,72(sp)
    80003fce:	e0ca                	sd	s2,64(sp)
    80003fd0:	fc4e                	sd	s3,56(sp)
    80003fd2:	f852                	sd	s4,48(sp)
    80003fd4:	f456                	sd	s5,40(sp)
    80003fd6:	f05a                	sd	s6,32(sp)
    80003fd8:	ec5e                	sd	s7,24(sp)
    80003fda:	e862                	sd	s8,16(sp)
    80003fdc:	e466                	sd	s9,8(sp)
    80003fde:	1080                	addi	s0,sp,96
    80003fe0:	84aa                	mv	s1,a0
    80003fe2:	8aae                	mv	s5,a1
    80003fe4:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003fe6:	00054703          	lbu	a4,0(a0)
    80003fea:	02f00793          	li	a5,47
    80003fee:	02f70363          	beq	a4,a5,80004014 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003ff2:	ffffe097          	auipc	ra,0xffffe
    80003ff6:	c78080e7          	jalr	-904(ra) # 80001c6a <myproc>
    80003ffa:	15053503          	ld	a0,336(a0)
    80003ffe:	00000097          	auipc	ra,0x0
    80004002:	9f6080e7          	jalr	-1546(ra) # 800039f4 <idup>
    80004006:	89aa                	mv	s3,a0
  while(*path == '/')
    80004008:	02f00913          	li	s2,47
  len = path - s;
    8000400c:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    8000400e:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004010:	4b85                	li	s7,1
    80004012:	a865                	j	800040ca <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004014:	4585                	li	a1,1
    80004016:	4505                	li	a0,1
    80004018:	fffff097          	auipc	ra,0xfffff
    8000401c:	6e2080e7          	jalr	1762(ra) # 800036fa <iget>
    80004020:	89aa                	mv	s3,a0
    80004022:	b7dd                	j	80004008 <namex+0x42>
      iunlockput(ip);
    80004024:	854e                	mv	a0,s3
    80004026:	00000097          	auipc	ra,0x0
    8000402a:	c6e080e7          	jalr	-914(ra) # 80003c94 <iunlockput>
      return 0;
    8000402e:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004030:	854e                	mv	a0,s3
    80004032:	60e6                	ld	ra,88(sp)
    80004034:	6446                	ld	s0,80(sp)
    80004036:	64a6                	ld	s1,72(sp)
    80004038:	6906                	ld	s2,64(sp)
    8000403a:	79e2                	ld	s3,56(sp)
    8000403c:	7a42                	ld	s4,48(sp)
    8000403e:	7aa2                	ld	s5,40(sp)
    80004040:	7b02                	ld	s6,32(sp)
    80004042:	6be2                	ld	s7,24(sp)
    80004044:	6c42                	ld	s8,16(sp)
    80004046:	6ca2                	ld	s9,8(sp)
    80004048:	6125                	addi	sp,sp,96
    8000404a:	8082                	ret
      iunlock(ip);
    8000404c:	854e                	mv	a0,s3
    8000404e:	00000097          	auipc	ra,0x0
    80004052:	aa6080e7          	jalr	-1370(ra) # 80003af4 <iunlock>
      return ip;
    80004056:	bfe9                	j	80004030 <namex+0x6a>
      iunlockput(ip);
    80004058:	854e                	mv	a0,s3
    8000405a:	00000097          	auipc	ra,0x0
    8000405e:	c3a080e7          	jalr	-966(ra) # 80003c94 <iunlockput>
      return 0;
    80004062:	89e6                	mv	s3,s9
    80004064:	b7f1                	j	80004030 <namex+0x6a>
  len = path - s;
    80004066:	40b48633          	sub	a2,s1,a1
    8000406a:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    8000406e:	099c5463          	bge	s8,s9,800040f6 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004072:	4639                	li	a2,14
    80004074:	8552                	mv	a0,s4
    80004076:	ffffd097          	auipc	ra,0xffffd
    8000407a:	cb8080e7          	jalr	-840(ra) # 80000d2e <memmove>
  while(*path == '/')
    8000407e:	0004c783          	lbu	a5,0(s1)
    80004082:	01279763          	bne	a5,s2,80004090 <namex+0xca>
    path++;
    80004086:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004088:	0004c783          	lbu	a5,0(s1)
    8000408c:	ff278de3          	beq	a5,s2,80004086 <namex+0xc0>
    ilock(ip);
    80004090:	854e                	mv	a0,s3
    80004092:	00000097          	auipc	ra,0x0
    80004096:	9a0080e7          	jalr	-1632(ra) # 80003a32 <ilock>
    if(ip->type != T_DIR){
    8000409a:	04499783          	lh	a5,68(s3)
    8000409e:	f97793e3          	bne	a5,s7,80004024 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800040a2:	000a8563          	beqz	s5,800040ac <namex+0xe6>
    800040a6:	0004c783          	lbu	a5,0(s1)
    800040aa:	d3cd                	beqz	a5,8000404c <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800040ac:	865a                	mv	a2,s6
    800040ae:	85d2                	mv	a1,s4
    800040b0:	854e                	mv	a0,s3
    800040b2:	00000097          	auipc	ra,0x0
    800040b6:	e64080e7          	jalr	-412(ra) # 80003f16 <dirlookup>
    800040ba:	8caa                	mv	s9,a0
    800040bc:	dd51                	beqz	a0,80004058 <namex+0x92>
    iunlockput(ip);
    800040be:	854e                	mv	a0,s3
    800040c0:	00000097          	auipc	ra,0x0
    800040c4:	bd4080e7          	jalr	-1068(ra) # 80003c94 <iunlockput>
    ip = next;
    800040c8:	89e6                	mv	s3,s9
  while(*path == '/')
    800040ca:	0004c783          	lbu	a5,0(s1)
    800040ce:	05279763          	bne	a5,s2,8000411c <namex+0x156>
    path++;
    800040d2:	0485                	addi	s1,s1,1
  while(*path == '/')
    800040d4:	0004c783          	lbu	a5,0(s1)
    800040d8:	ff278de3          	beq	a5,s2,800040d2 <namex+0x10c>
  if(*path == 0)
    800040dc:	c79d                	beqz	a5,8000410a <namex+0x144>
    path++;
    800040de:	85a6                	mv	a1,s1
  len = path - s;
    800040e0:	8cda                	mv	s9,s6
    800040e2:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    800040e4:	01278963          	beq	a5,s2,800040f6 <namex+0x130>
    800040e8:	dfbd                	beqz	a5,80004066 <namex+0xa0>
    path++;
    800040ea:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800040ec:	0004c783          	lbu	a5,0(s1)
    800040f0:	ff279ce3          	bne	a5,s2,800040e8 <namex+0x122>
    800040f4:	bf8d                	j	80004066 <namex+0xa0>
    memmove(name, s, len);
    800040f6:	2601                	sext.w	a2,a2
    800040f8:	8552                	mv	a0,s4
    800040fa:	ffffd097          	auipc	ra,0xffffd
    800040fe:	c34080e7          	jalr	-972(ra) # 80000d2e <memmove>
    name[len] = 0;
    80004102:	9cd2                	add	s9,s9,s4
    80004104:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004108:	bf9d                	j	8000407e <namex+0xb8>
  if(nameiparent){
    8000410a:	f20a83e3          	beqz	s5,80004030 <namex+0x6a>
    iput(ip);
    8000410e:	854e                	mv	a0,s3
    80004110:	00000097          	auipc	ra,0x0
    80004114:	adc080e7          	jalr	-1316(ra) # 80003bec <iput>
    return 0;
    80004118:	4981                	li	s3,0
    8000411a:	bf19                	j	80004030 <namex+0x6a>
  if(*path == 0)
    8000411c:	d7fd                	beqz	a5,8000410a <namex+0x144>
  while(*path != '/' && *path != 0)
    8000411e:	0004c783          	lbu	a5,0(s1)
    80004122:	85a6                	mv	a1,s1
    80004124:	b7d1                	j	800040e8 <namex+0x122>

0000000080004126 <dirlink>:
{
    80004126:	7139                	addi	sp,sp,-64
    80004128:	fc06                	sd	ra,56(sp)
    8000412a:	f822                	sd	s0,48(sp)
    8000412c:	f426                	sd	s1,40(sp)
    8000412e:	f04a                	sd	s2,32(sp)
    80004130:	ec4e                	sd	s3,24(sp)
    80004132:	e852                	sd	s4,16(sp)
    80004134:	0080                	addi	s0,sp,64
    80004136:	892a                	mv	s2,a0
    80004138:	8a2e                	mv	s4,a1
    8000413a:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000413c:	4601                	li	a2,0
    8000413e:	00000097          	auipc	ra,0x0
    80004142:	dd8080e7          	jalr	-552(ra) # 80003f16 <dirlookup>
    80004146:	e93d                	bnez	a0,800041bc <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004148:	04c92483          	lw	s1,76(s2)
    8000414c:	c49d                	beqz	s1,8000417a <dirlink+0x54>
    8000414e:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004150:	4741                	li	a4,16
    80004152:	86a6                	mv	a3,s1
    80004154:	fc040613          	addi	a2,s0,-64
    80004158:	4581                	li	a1,0
    8000415a:	854a                	mv	a0,s2
    8000415c:	00000097          	auipc	ra,0x0
    80004160:	b8a080e7          	jalr	-1142(ra) # 80003ce6 <readi>
    80004164:	47c1                	li	a5,16
    80004166:	06f51163          	bne	a0,a5,800041c8 <dirlink+0xa2>
    if(de.inum == 0)
    8000416a:	fc045783          	lhu	a5,-64(s0)
    8000416e:	c791                	beqz	a5,8000417a <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004170:	24c1                	addiw	s1,s1,16
    80004172:	04c92783          	lw	a5,76(s2)
    80004176:	fcf4ede3          	bltu	s1,a5,80004150 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000417a:	4639                	li	a2,14
    8000417c:	85d2                	mv	a1,s4
    8000417e:	fc240513          	addi	a0,s0,-62
    80004182:	ffffd097          	auipc	ra,0xffffd
    80004186:	c5c080e7          	jalr	-932(ra) # 80000dde <strncpy>
  de.inum = inum;
    8000418a:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000418e:	4741                	li	a4,16
    80004190:	86a6                	mv	a3,s1
    80004192:	fc040613          	addi	a2,s0,-64
    80004196:	4581                	li	a1,0
    80004198:	854a                	mv	a0,s2
    8000419a:	00000097          	auipc	ra,0x0
    8000419e:	c44080e7          	jalr	-956(ra) # 80003dde <writei>
    800041a2:	1541                	addi	a0,a0,-16
    800041a4:	00a03533          	snez	a0,a0
    800041a8:	40a00533          	neg	a0,a0
}
    800041ac:	70e2                	ld	ra,56(sp)
    800041ae:	7442                	ld	s0,48(sp)
    800041b0:	74a2                	ld	s1,40(sp)
    800041b2:	7902                	ld	s2,32(sp)
    800041b4:	69e2                	ld	s3,24(sp)
    800041b6:	6a42                	ld	s4,16(sp)
    800041b8:	6121                	addi	sp,sp,64
    800041ba:	8082                	ret
    iput(ip);
    800041bc:	00000097          	auipc	ra,0x0
    800041c0:	a30080e7          	jalr	-1488(ra) # 80003bec <iput>
    return -1;
    800041c4:	557d                	li	a0,-1
    800041c6:	b7dd                	j	800041ac <dirlink+0x86>
      panic("dirlink read");
    800041c8:	00004517          	auipc	a0,0x4
    800041cc:	49050513          	addi	a0,a0,1168 # 80008658 <syscalls+0x1d8>
    800041d0:	ffffc097          	auipc	ra,0xffffc
    800041d4:	36e080e7          	jalr	878(ra) # 8000053e <panic>

00000000800041d8 <namei>:

struct inode*
namei(char *path)
{
    800041d8:	1101                	addi	sp,sp,-32
    800041da:	ec06                	sd	ra,24(sp)
    800041dc:	e822                	sd	s0,16(sp)
    800041de:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800041e0:	fe040613          	addi	a2,s0,-32
    800041e4:	4581                	li	a1,0
    800041e6:	00000097          	auipc	ra,0x0
    800041ea:	de0080e7          	jalr	-544(ra) # 80003fc6 <namex>
}
    800041ee:	60e2                	ld	ra,24(sp)
    800041f0:	6442                	ld	s0,16(sp)
    800041f2:	6105                	addi	sp,sp,32
    800041f4:	8082                	ret

00000000800041f6 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800041f6:	1141                	addi	sp,sp,-16
    800041f8:	e406                	sd	ra,8(sp)
    800041fa:	e022                	sd	s0,0(sp)
    800041fc:	0800                	addi	s0,sp,16
    800041fe:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004200:	4585                	li	a1,1
    80004202:	00000097          	auipc	ra,0x0
    80004206:	dc4080e7          	jalr	-572(ra) # 80003fc6 <namex>
}
    8000420a:	60a2                	ld	ra,8(sp)
    8000420c:	6402                	ld	s0,0(sp)
    8000420e:	0141                	addi	sp,sp,16
    80004210:	8082                	ret

0000000080004212 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004212:	1101                	addi	sp,sp,-32
    80004214:	ec06                	sd	ra,24(sp)
    80004216:	e822                	sd	s0,16(sp)
    80004218:	e426                	sd	s1,8(sp)
    8000421a:	e04a                	sd	s2,0(sp)
    8000421c:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000421e:	0001d917          	auipc	s2,0x1d
    80004222:	92290913          	addi	s2,s2,-1758 # 80020b40 <log>
    80004226:	01892583          	lw	a1,24(s2)
    8000422a:	02892503          	lw	a0,40(s2)
    8000422e:	fffff097          	auipc	ra,0xfffff
    80004232:	fea080e7          	jalr	-22(ra) # 80003218 <bread>
    80004236:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004238:	02c92683          	lw	a3,44(s2)
    8000423c:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000423e:	02d05763          	blez	a3,8000426c <write_head+0x5a>
    80004242:	0001d797          	auipc	a5,0x1d
    80004246:	92e78793          	addi	a5,a5,-1746 # 80020b70 <log+0x30>
    8000424a:	05c50713          	addi	a4,a0,92
    8000424e:	36fd                	addiw	a3,a3,-1
    80004250:	1682                	slli	a3,a3,0x20
    80004252:	9281                	srli	a3,a3,0x20
    80004254:	068a                	slli	a3,a3,0x2
    80004256:	0001d617          	auipc	a2,0x1d
    8000425a:	91e60613          	addi	a2,a2,-1762 # 80020b74 <log+0x34>
    8000425e:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004260:	4390                	lw	a2,0(a5)
    80004262:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004264:	0791                	addi	a5,a5,4
    80004266:	0711                	addi	a4,a4,4
    80004268:	fed79ce3          	bne	a5,a3,80004260 <write_head+0x4e>
  }
  bwrite(buf);
    8000426c:	8526                	mv	a0,s1
    8000426e:	fffff097          	auipc	ra,0xfffff
    80004272:	09c080e7          	jalr	156(ra) # 8000330a <bwrite>
  brelse(buf);
    80004276:	8526                	mv	a0,s1
    80004278:	fffff097          	auipc	ra,0xfffff
    8000427c:	0d0080e7          	jalr	208(ra) # 80003348 <brelse>
}
    80004280:	60e2                	ld	ra,24(sp)
    80004282:	6442                	ld	s0,16(sp)
    80004284:	64a2                	ld	s1,8(sp)
    80004286:	6902                	ld	s2,0(sp)
    80004288:	6105                	addi	sp,sp,32
    8000428a:	8082                	ret

000000008000428c <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000428c:	0001d797          	auipc	a5,0x1d
    80004290:	8e07a783          	lw	a5,-1824(a5) # 80020b6c <log+0x2c>
    80004294:	0af05d63          	blez	a5,8000434e <install_trans+0xc2>
{
    80004298:	7139                	addi	sp,sp,-64
    8000429a:	fc06                	sd	ra,56(sp)
    8000429c:	f822                	sd	s0,48(sp)
    8000429e:	f426                	sd	s1,40(sp)
    800042a0:	f04a                	sd	s2,32(sp)
    800042a2:	ec4e                	sd	s3,24(sp)
    800042a4:	e852                	sd	s4,16(sp)
    800042a6:	e456                	sd	s5,8(sp)
    800042a8:	e05a                	sd	s6,0(sp)
    800042aa:	0080                	addi	s0,sp,64
    800042ac:	8b2a                	mv	s6,a0
    800042ae:	0001da97          	auipc	s5,0x1d
    800042b2:	8c2a8a93          	addi	s5,s5,-1854 # 80020b70 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042b6:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800042b8:	0001d997          	auipc	s3,0x1d
    800042bc:	88898993          	addi	s3,s3,-1912 # 80020b40 <log>
    800042c0:	a00d                	j	800042e2 <install_trans+0x56>
    brelse(lbuf);
    800042c2:	854a                	mv	a0,s2
    800042c4:	fffff097          	auipc	ra,0xfffff
    800042c8:	084080e7          	jalr	132(ra) # 80003348 <brelse>
    brelse(dbuf);
    800042cc:	8526                	mv	a0,s1
    800042ce:	fffff097          	auipc	ra,0xfffff
    800042d2:	07a080e7          	jalr	122(ra) # 80003348 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042d6:	2a05                	addiw	s4,s4,1
    800042d8:	0a91                	addi	s5,s5,4
    800042da:	02c9a783          	lw	a5,44(s3)
    800042de:	04fa5e63          	bge	s4,a5,8000433a <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800042e2:	0189a583          	lw	a1,24(s3)
    800042e6:	014585bb          	addw	a1,a1,s4
    800042ea:	2585                	addiw	a1,a1,1
    800042ec:	0289a503          	lw	a0,40(s3)
    800042f0:	fffff097          	auipc	ra,0xfffff
    800042f4:	f28080e7          	jalr	-216(ra) # 80003218 <bread>
    800042f8:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800042fa:	000aa583          	lw	a1,0(s5)
    800042fe:	0289a503          	lw	a0,40(s3)
    80004302:	fffff097          	auipc	ra,0xfffff
    80004306:	f16080e7          	jalr	-234(ra) # 80003218 <bread>
    8000430a:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000430c:	40000613          	li	a2,1024
    80004310:	05890593          	addi	a1,s2,88
    80004314:	05850513          	addi	a0,a0,88
    80004318:	ffffd097          	auipc	ra,0xffffd
    8000431c:	a16080e7          	jalr	-1514(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    80004320:	8526                	mv	a0,s1
    80004322:	fffff097          	auipc	ra,0xfffff
    80004326:	fe8080e7          	jalr	-24(ra) # 8000330a <bwrite>
    if(recovering == 0)
    8000432a:	f80b1ce3          	bnez	s6,800042c2 <install_trans+0x36>
      bunpin(dbuf);
    8000432e:	8526                	mv	a0,s1
    80004330:	fffff097          	auipc	ra,0xfffff
    80004334:	0f2080e7          	jalr	242(ra) # 80003422 <bunpin>
    80004338:	b769                	j	800042c2 <install_trans+0x36>
}
    8000433a:	70e2                	ld	ra,56(sp)
    8000433c:	7442                	ld	s0,48(sp)
    8000433e:	74a2                	ld	s1,40(sp)
    80004340:	7902                	ld	s2,32(sp)
    80004342:	69e2                	ld	s3,24(sp)
    80004344:	6a42                	ld	s4,16(sp)
    80004346:	6aa2                	ld	s5,8(sp)
    80004348:	6b02                	ld	s6,0(sp)
    8000434a:	6121                	addi	sp,sp,64
    8000434c:	8082                	ret
    8000434e:	8082                	ret

0000000080004350 <initlog>:
{
    80004350:	7179                	addi	sp,sp,-48
    80004352:	f406                	sd	ra,40(sp)
    80004354:	f022                	sd	s0,32(sp)
    80004356:	ec26                	sd	s1,24(sp)
    80004358:	e84a                	sd	s2,16(sp)
    8000435a:	e44e                	sd	s3,8(sp)
    8000435c:	1800                	addi	s0,sp,48
    8000435e:	892a                	mv	s2,a0
    80004360:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004362:	0001c497          	auipc	s1,0x1c
    80004366:	7de48493          	addi	s1,s1,2014 # 80020b40 <log>
    8000436a:	00004597          	auipc	a1,0x4
    8000436e:	2fe58593          	addi	a1,a1,766 # 80008668 <syscalls+0x1e8>
    80004372:	8526                	mv	a0,s1
    80004374:	ffffc097          	auipc	ra,0xffffc
    80004378:	7d2080e7          	jalr	2002(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    8000437c:	0149a583          	lw	a1,20(s3)
    80004380:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004382:	0109a783          	lw	a5,16(s3)
    80004386:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004388:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000438c:	854a                	mv	a0,s2
    8000438e:	fffff097          	auipc	ra,0xfffff
    80004392:	e8a080e7          	jalr	-374(ra) # 80003218 <bread>
  log.lh.n = lh->n;
    80004396:	4d34                	lw	a3,88(a0)
    80004398:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000439a:	02d05563          	blez	a3,800043c4 <initlog+0x74>
    8000439e:	05c50793          	addi	a5,a0,92
    800043a2:	0001c717          	auipc	a4,0x1c
    800043a6:	7ce70713          	addi	a4,a4,1998 # 80020b70 <log+0x30>
    800043aa:	36fd                	addiw	a3,a3,-1
    800043ac:	1682                	slli	a3,a3,0x20
    800043ae:	9281                	srli	a3,a3,0x20
    800043b0:	068a                	slli	a3,a3,0x2
    800043b2:	06050613          	addi	a2,a0,96
    800043b6:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800043b8:	4390                	lw	a2,0(a5)
    800043ba:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800043bc:	0791                	addi	a5,a5,4
    800043be:	0711                	addi	a4,a4,4
    800043c0:	fed79ce3          	bne	a5,a3,800043b8 <initlog+0x68>
  brelse(buf);
    800043c4:	fffff097          	auipc	ra,0xfffff
    800043c8:	f84080e7          	jalr	-124(ra) # 80003348 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800043cc:	4505                	li	a0,1
    800043ce:	00000097          	auipc	ra,0x0
    800043d2:	ebe080e7          	jalr	-322(ra) # 8000428c <install_trans>
  log.lh.n = 0;
    800043d6:	0001c797          	auipc	a5,0x1c
    800043da:	7807ab23          	sw	zero,1942(a5) # 80020b6c <log+0x2c>
  write_head(); // clear the log
    800043de:	00000097          	auipc	ra,0x0
    800043e2:	e34080e7          	jalr	-460(ra) # 80004212 <write_head>
}
    800043e6:	70a2                	ld	ra,40(sp)
    800043e8:	7402                	ld	s0,32(sp)
    800043ea:	64e2                	ld	s1,24(sp)
    800043ec:	6942                	ld	s2,16(sp)
    800043ee:	69a2                	ld	s3,8(sp)
    800043f0:	6145                	addi	sp,sp,48
    800043f2:	8082                	ret

00000000800043f4 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800043f4:	1101                	addi	sp,sp,-32
    800043f6:	ec06                	sd	ra,24(sp)
    800043f8:	e822                	sd	s0,16(sp)
    800043fa:	e426                	sd	s1,8(sp)
    800043fc:	e04a                	sd	s2,0(sp)
    800043fe:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004400:	0001c517          	auipc	a0,0x1c
    80004404:	74050513          	addi	a0,a0,1856 # 80020b40 <log>
    80004408:	ffffc097          	auipc	ra,0xffffc
    8000440c:	7ce080e7          	jalr	1998(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    80004410:	0001c497          	auipc	s1,0x1c
    80004414:	73048493          	addi	s1,s1,1840 # 80020b40 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004418:	4979                	li	s2,30
    8000441a:	a039                	j	80004428 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000441c:	85a6                	mv	a1,s1
    8000441e:	8526                	mv	a0,s1
    80004420:	ffffe097          	auipc	ra,0xffffe
    80004424:	ef2080e7          	jalr	-270(ra) # 80002312 <sleep>
    if(log.committing){
    80004428:	50dc                	lw	a5,36(s1)
    8000442a:	fbed                	bnez	a5,8000441c <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000442c:	509c                	lw	a5,32(s1)
    8000442e:	0017871b          	addiw	a4,a5,1
    80004432:	0007069b          	sext.w	a3,a4
    80004436:	0027179b          	slliw	a5,a4,0x2
    8000443a:	9fb9                	addw	a5,a5,a4
    8000443c:	0017979b          	slliw	a5,a5,0x1
    80004440:	54d8                	lw	a4,44(s1)
    80004442:	9fb9                	addw	a5,a5,a4
    80004444:	00f95963          	bge	s2,a5,80004456 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004448:	85a6                	mv	a1,s1
    8000444a:	8526                	mv	a0,s1
    8000444c:	ffffe097          	auipc	ra,0xffffe
    80004450:	ec6080e7          	jalr	-314(ra) # 80002312 <sleep>
    80004454:	bfd1                	j	80004428 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004456:	0001c517          	auipc	a0,0x1c
    8000445a:	6ea50513          	addi	a0,a0,1770 # 80020b40 <log>
    8000445e:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004460:	ffffd097          	auipc	ra,0xffffd
    80004464:	82a080e7          	jalr	-2006(ra) # 80000c8a <release>
      break;
    }
  }
}
    80004468:	60e2                	ld	ra,24(sp)
    8000446a:	6442                	ld	s0,16(sp)
    8000446c:	64a2                	ld	s1,8(sp)
    8000446e:	6902                	ld	s2,0(sp)
    80004470:	6105                	addi	sp,sp,32
    80004472:	8082                	ret

0000000080004474 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004474:	7139                	addi	sp,sp,-64
    80004476:	fc06                	sd	ra,56(sp)
    80004478:	f822                	sd	s0,48(sp)
    8000447a:	f426                	sd	s1,40(sp)
    8000447c:	f04a                	sd	s2,32(sp)
    8000447e:	ec4e                	sd	s3,24(sp)
    80004480:	e852                	sd	s4,16(sp)
    80004482:	e456                	sd	s5,8(sp)
    80004484:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004486:	0001c497          	auipc	s1,0x1c
    8000448a:	6ba48493          	addi	s1,s1,1722 # 80020b40 <log>
    8000448e:	8526                	mv	a0,s1
    80004490:	ffffc097          	auipc	ra,0xffffc
    80004494:	746080e7          	jalr	1862(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    80004498:	509c                	lw	a5,32(s1)
    8000449a:	37fd                	addiw	a5,a5,-1
    8000449c:	0007891b          	sext.w	s2,a5
    800044a0:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800044a2:	50dc                	lw	a5,36(s1)
    800044a4:	e7b9                	bnez	a5,800044f2 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800044a6:	04091e63          	bnez	s2,80004502 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800044aa:	0001c497          	auipc	s1,0x1c
    800044ae:	69648493          	addi	s1,s1,1686 # 80020b40 <log>
    800044b2:	4785                	li	a5,1
    800044b4:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800044b6:	8526                	mv	a0,s1
    800044b8:	ffffc097          	auipc	ra,0xffffc
    800044bc:	7d2080e7          	jalr	2002(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800044c0:	54dc                	lw	a5,44(s1)
    800044c2:	06f04763          	bgtz	a5,80004530 <end_op+0xbc>
    acquire(&log.lock);
    800044c6:	0001c497          	auipc	s1,0x1c
    800044ca:	67a48493          	addi	s1,s1,1658 # 80020b40 <log>
    800044ce:	8526                	mv	a0,s1
    800044d0:	ffffc097          	auipc	ra,0xffffc
    800044d4:	706080e7          	jalr	1798(ra) # 80000bd6 <acquire>
    log.committing = 0;
    800044d8:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800044dc:	8526                	mv	a0,s1
    800044de:	ffffe097          	auipc	ra,0xffffe
    800044e2:	e98080e7          	jalr	-360(ra) # 80002376 <wakeup>
    release(&log.lock);
    800044e6:	8526                	mv	a0,s1
    800044e8:	ffffc097          	auipc	ra,0xffffc
    800044ec:	7a2080e7          	jalr	1954(ra) # 80000c8a <release>
}
    800044f0:	a03d                	j	8000451e <end_op+0xaa>
    panic("log.committing");
    800044f2:	00004517          	auipc	a0,0x4
    800044f6:	17e50513          	addi	a0,a0,382 # 80008670 <syscalls+0x1f0>
    800044fa:	ffffc097          	auipc	ra,0xffffc
    800044fe:	044080e7          	jalr	68(ra) # 8000053e <panic>
    wakeup(&log);
    80004502:	0001c497          	auipc	s1,0x1c
    80004506:	63e48493          	addi	s1,s1,1598 # 80020b40 <log>
    8000450a:	8526                	mv	a0,s1
    8000450c:	ffffe097          	auipc	ra,0xffffe
    80004510:	e6a080e7          	jalr	-406(ra) # 80002376 <wakeup>
  release(&log.lock);
    80004514:	8526                	mv	a0,s1
    80004516:	ffffc097          	auipc	ra,0xffffc
    8000451a:	774080e7          	jalr	1908(ra) # 80000c8a <release>
}
    8000451e:	70e2                	ld	ra,56(sp)
    80004520:	7442                	ld	s0,48(sp)
    80004522:	74a2                	ld	s1,40(sp)
    80004524:	7902                	ld	s2,32(sp)
    80004526:	69e2                	ld	s3,24(sp)
    80004528:	6a42                	ld	s4,16(sp)
    8000452a:	6aa2                	ld	s5,8(sp)
    8000452c:	6121                	addi	sp,sp,64
    8000452e:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004530:	0001ca97          	auipc	s5,0x1c
    80004534:	640a8a93          	addi	s5,s5,1600 # 80020b70 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004538:	0001ca17          	auipc	s4,0x1c
    8000453c:	608a0a13          	addi	s4,s4,1544 # 80020b40 <log>
    80004540:	018a2583          	lw	a1,24(s4)
    80004544:	012585bb          	addw	a1,a1,s2
    80004548:	2585                	addiw	a1,a1,1
    8000454a:	028a2503          	lw	a0,40(s4)
    8000454e:	fffff097          	auipc	ra,0xfffff
    80004552:	cca080e7          	jalr	-822(ra) # 80003218 <bread>
    80004556:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004558:	000aa583          	lw	a1,0(s5)
    8000455c:	028a2503          	lw	a0,40(s4)
    80004560:	fffff097          	auipc	ra,0xfffff
    80004564:	cb8080e7          	jalr	-840(ra) # 80003218 <bread>
    80004568:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000456a:	40000613          	li	a2,1024
    8000456e:	05850593          	addi	a1,a0,88
    80004572:	05848513          	addi	a0,s1,88
    80004576:	ffffc097          	auipc	ra,0xffffc
    8000457a:	7b8080e7          	jalr	1976(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    8000457e:	8526                	mv	a0,s1
    80004580:	fffff097          	auipc	ra,0xfffff
    80004584:	d8a080e7          	jalr	-630(ra) # 8000330a <bwrite>
    brelse(from);
    80004588:	854e                	mv	a0,s3
    8000458a:	fffff097          	auipc	ra,0xfffff
    8000458e:	dbe080e7          	jalr	-578(ra) # 80003348 <brelse>
    brelse(to);
    80004592:	8526                	mv	a0,s1
    80004594:	fffff097          	auipc	ra,0xfffff
    80004598:	db4080e7          	jalr	-588(ra) # 80003348 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000459c:	2905                	addiw	s2,s2,1
    8000459e:	0a91                	addi	s5,s5,4
    800045a0:	02ca2783          	lw	a5,44(s4)
    800045a4:	f8f94ee3          	blt	s2,a5,80004540 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800045a8:	00000097          	auipc	ra,0x0
    800045ac:	c6a080e7          	jalr	-918(ra) # 80004212 <write_head>
    install_trans(0); // Now install writes to home locations
    800045b0:	4501                	li	a0,0
    800045b2:	00000097          	auipc	ra,0x0
    800045b6:	cda080e7          	jalr	-806(ra) # 8000428c <install_trans>
    log.lh.n = 0;
    800045ba:	0001c797          	auipc	a5,0x1c
    800045be:	5a07a923          	sw	zero,1458(a5) # 80020b6c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800045c2:	00000097          	auipc	ra,0x0
    800045c6:	c50080e7          	jalr	-944(ra) # 80004212 <write_head>
    800045ca:	bdf5                	j	800044c6 <end_op+0x52>

00000000800045cc <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800045cc:	1101                	addi	sp,sp,-32
    800045ce:	ec06                	sd	ra,24(sp)
    800045d0:	e822                	sd	s0,16(sp)
    800045d2:	e426                	sd	s1,8(sp)
    800045d4:	e04a                	sd	s2,0(sp)
    800045d6:	1000                	addi	s0,sp,32
    800045d8:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800045da:	0001c917          	auipc	s2,0x1c
    800045de:	56690913          	addi	s2,s2,1382 # 80020b40 <log>
    800045e2:	854a                	mv	a0,s2
    800045e4:	ffffc097          	auipc	ra,0xffffc
    800045e8:	5f2080e7          	jalr	1522(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800045ec:	02c92603          	lw	a2,44(s2)
    800045f0:	47f5                	li	a5,29
    800045f2:	06c7c563          	blt	a5,a2,8000465c <log_write+0x90>
    800045f6:	0001c797          	auipc	a5,0x1c
    800045fa:	5667a783          	lw	a5,1382(a5) # 80020b5c <log+0x1c>
    800045fe:	37fd                	addiw	a5,a5,-1
    80004600:	04f65e63          	bge	a2,a5,8000465c <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004604:	0001c797          	auipc	a5,0x1c
    80004608:	55c7a783          	lw	a5,1372(a5) # 80020b60 <log+0x20>
    8000460c:	06f05063          	blez	a5,8000466c <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004610:	4781                	li	a5,0
    80004612:	06c05563          	blez	a2,8000467c <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004616:	44cc                	lw	a1,12(s1)
    80004618:	0001c717          	auipc	a4,0x1c
    8000461c:	55870713          	addi	a4,a4,1368 # 80020b70 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004620:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004622:	4314                	lw	a3,0(a4)
    80004624:	04b68c63          	beq	a3,a1,8000467c <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004628:	2785                	addiw	a5,a5,1
    8000462a:	0711                	addi	a4,a4,4
    8000462c:	fef61be3          	bne	a2,a5,80004622 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004630:	0621                	addi	a2,a2,8
    80004632:	060a                	slli	a2,a2,0x2
    80004634:	0001c797          	auipc	a5,0x1c
    80004638:	50c78793          	addi	a5,a5,1292 # 80020b40 <log>
    8000463c:	963e                	add	a2,a2,a5
    8000463e:	44dc                	lw	a5,12(s1)
    80004640:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004642:	8526                	mv	a0,s1
    80004644:	fffff097          	auipc	ra,0xfffff
    80004648:	da2080e7          	jalr	-606(ra) # 800033e6 <bpin>
    log.lh.n++;
    8000464c:	0001c717          	auipc	a4,0x1c
    80004650:	4f470713          	addi	a4,a4,1268 # 80020b40 <log>
    80004654:	575c                	lw	a5,44(a4)
    80004656:	2785                	addiw	a5,a5,1
    80004658:	d75c                	sw	a5,44(a4)
    8000465a:	a835                	j	80004696 <log_write+0xca>
    panic("too big a transaction");
    8000465c:	00004517          	auipc	a0,0x4
    80004660:	02450513          	addi	a0,a0,36 # 80008680 <syscalls+0x200>
    80004664:	ffffc097          	auipc	ra,0xffffc
    80004668:	eda080e7          	jalr	-294(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    8000466c:	00004517          	auipc	a0,0x4
    80004670:	02c50513          	addi	a0,a0,44 # 80008698 <syscalls+0x218>
    80004674:	ffffc097          	auipc	ra,0xffffc
    80004678:	eca080e7          	jalr	-310(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    8000467c:	00878713          	addi	a4,a5,8
    80004680:	00271693          	slli	a3,a4,0x2
    80004684:	0001c717          	auipc	a4,0x1c
    80004688:	4bc70713          	addi	a4,a4,1212 # 80020b40 <log>
    8000468c:	9736                	add	a4,a4,a3
    8000468e:	44d4                	lw	a3,12(s1)
    80004690:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004692:	faf608e3          	beq	a2,a5,80004642 <log_write+0x76>
  }
  release(&log.lock);
    80004696:	0001c517          	auipc	a0,0x1c
    8000469a:	4aa50513          	addi	a0,a0,1194 # 80020b40 <log>
    8000469e:	ffffc097          	auipc	ra,0xffffc
    800046a2:	5ec080e7          	jalr	1516(ra) # 80000c8a <release>
}
    800046a6:	60e2                	ld	ra,24(sp)
    800046a8:	6442                	ld	s0,16(sp)
    800046aa:	64a2                	ld	s1,8(sp)
    800046ac:	6902                	ld	s2,0(sp)
    800046ae:	6105                	addi	sp,sp,32
    800046b0:	8082                	ret

00000000800046b2 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800046b2:	1101                	addi	sp,sp,-32
    800046b4:	ec06                	sd	ra,24(sp)
    800046b6:	e822                	sd	s0,16(sp)
    800046b8:	e426                	sd	s1,8(sp)
    800046ba:	e04a                	sd	s2,0(sp)
    800046bc:	1000                	addi	s0,sp,32
    800046be:	84aa                	mv	s1,a0
    800046c0:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800046c2:	00004597          	auipc	a1,0x4
    800046c6:	ff658593          	addi	a1,a1,-10 # 800086b8 <syscalls+0x238>
    800046ca:	0521                	addi	a0,a0,8
    800046cc:	ffffc097          	auipc	ra,0xffffc
    800046d0:	47a080e7          	jalr	1146(ra) # 80000b46 <initlock>
  lk->name = name;
    800046d4:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800046d8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800046dc:	0204a423          	sw	zero,40(s1)
}
    800046e0:	60e2                	ld	ra,24(sp)
    800046e2:	6442                	ld	s0,16(sp)
    800046e4:	64a2                	ld	s1,8(sp)
    800046e6:	6902                	ld	s2,0(sp)
    800046e8:	6105                	addi	sp,sp,32
    800046ea:	8082                	ret

00000000800046ec <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800046ec:	1101                	addi	sp,sp,-32
    800046ee:	ec06                	sd	ra,24(sp)
    800046f0:	e822                	sd	s0,16(sp)
    800046f2:	e426                	sd	s1,8(sp)
    800046f4:	e04a                	sd	s2,0(sp)
    800046f6:	1000                	addi	s0,sp,32
    800046f8:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800046fa:	00850913          	addi	s2,a0,8
    800046fe:	854a                	mv	a0,s2
    80004700:	ffffc097          	auipc	ra,0xffffc
    80004704:	4d6080e7          	jalr	1238(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    80004708:	409c                	lw	a5,0(s1)
    8000470a:	cb89                	beqz	a5,8000471c <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000470c:	85ca                	mv	a1,s2
    8000470e:	8526                	mv	a0,s1
    80004710:	ffffe097          	auipc	ra,0xffffe
    80004714:	c02080e7          	jalr	-1022(ra) # 80002312 <sleep>
  while (lk->locked) {
    80004718:	409c                	lw	a5,0(s1)
    8000471a:	fbed                	bnez	a5,8000470c <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000471c:	4785                	li	a5,1
    8000471e:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004720:	ffffd097          	auipc	ra,0xffffd
    80004724:	54a080e7          	jalr	1354(ra) # 80001c6a <myproc>
    80004728:	591c                	lw	a5,48(a0)
    8000472a:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000472c:	854a                	mv	a0,s2
    8000472e:	ffffc097          	auipc	ra,0xffffc
    80004732:	55c080e7          	jalr	1372(ra) # 80000c8a <release>
}
    80004736:	60e2                	ld	ra,24(sp)
    80004738:	6442                	ld	s0,16(sp)
    8000473a:	64a2                	ld	s1,8(sp)
    8000473c:	6902                	ld	s2,0(sp)
    8000473e:	6105                	addi	sp,sp,32
    80004740:	8082                	ret

0000000080004742 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004742:	1101                	addi	sp,sp,-32
    80004744:	ec06                	sd	ra,24(sp)
    80004746:	e822                	sd	s0,16(sp)
    80004748:	e426                	sd	s1,8(sp)
    8000474a:	e04a                	sd	s2,0(sp)
    8000474c:	1000                	addi	s0,sp,32
    8000474e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004750:	00850913          	addi	s2,a0,8
    80004754:	854a                	mv	a0,s2
    80004756:	ffffc097          	auipc	ra,0xffffc
    8000475a:	480080e7          	jalr	1152(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    8000475e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004762:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004766:	8526                	mv	a0,s1
    80004768:	ffffe097          	auipc	ra,0xffffe
    8000476c:	c0e080e7          	jalr	-1010(ra) # 80002376 <wakeup>
  release(&lk->lk);
    80004770:	854a                	mv	a0,s2
    80004772:	ffffc097          	auipc	ra,0xffffc
    80004776:	518080e7          	jalr	1304(ra) # 80000c8a <release>
}
    8000477a:	60e2                	ld	ra,24(sp)
    8000477c:	6442                	ld	s0,16(sp)
    8000477e:	64a2                	ld	s1,8(sp)
    80004780:	6902                	ld	s2,0(sp)
    80004782:	6105                	addi	sp,sp,32
    80004784:	8082                	ret

0000000080004786 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004786:	7179                	addi	sp,sp,-48
    80004788:	f406                	sd	ra,40(sp)
    8000478a:	f022                	sd	s0,32(sp)
    8000478c:	ec26                	sd	s1,24(sp)
    8000478e:	e84a                	sd	s2,16(sp)
    80004790:	e44e                	sd	s3,8(sp)
    80004792:	1800                	addi	s0,sp,48
    80004794:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004796:	00850913          	addi	s2,a0,8
    8000479a:	854a                	mv	a0,s2
    8000479c:	ffffc097          	auipc	ra,0xffffc
    800047a0:	43a080e7          	jalr	1082(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800047a4:	409c                	lw	a5,0(s1)
    800047a6:	ef99                	bnez	a5,800047c4 <holdingsleep+0x3e>
    800047a8:	4481                	li	s1,0
  release(&lk->lk);
    800047aa:	854a                	mv	a0,s2
    800047ac:	ffffc097          	auipc	ra,0xffffc
    800047b0:	4de080e7          	jalr	1246(ra) # 80000c8a <release>
  return r;
}
    800047b4:	8526                	mv	a0,s1
    800047b6:	70a2                	ld	ra,40(sp)
    800047b8:	7402                	ld	s0,32(sp)
    800047ba:	64e2                	ld	s1,24(sp)
    800047bc:	6942                	ld	s2,16(sp)
    800047be:	69a2                	ld	s3,8(sp)
    800047c0:	6145                	addi	sp,sp,48
    800047c2:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800047c4:	0284a983          	lw	s3,40(s1)
    800047c8:	ffffd097          	auipc	ra,0xffffd
    800047cc:	4a2080e7          	jalr	1186(ra) # 80001c6a <myproc>
    800047d0:	5904                	lw	s1,48(a0)
    800047d2:	413484b3          	sub	s1,s1,s3
    800047d6:	0014b493          	seqz	s1,s1
    800047da:	bfc1                	j	800047aa <holdingsleep+0x24>

00000000800047dc <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800047dc:	1141                	addi	sp,sp,-16
    800047de:	e406                	sd	ra,8(sp)
    800047e0:	e022                	sd	s0,0(sp)
    800047e2:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800047e4:	00004597          	auipc	a1,0x4
    800047e8:	ee458593          	addi	a1,a1,-284 # 800086c8 <syscalls+0x248>
    800047ec:	0001c517          	auipc	a0,0x1c
    800047f0:	49c50513          	addi	a0,a0,1180 # 80020c88 <ftable>
    800047f4:	ffffc097          	auipc	ra,0xffffc
    800047f8:	352080e7          	jalr	850(ra) # 80000b46 <initlock>
}
    800047fc:	60a2                	ld	ra,8(sp)
    800047fe:	6402                	ld	s0,0(sp)
    80004800:	0141                	addi	sp,sp,16
    80004802:	8082                	ret

0000000080004804 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004804:	1101                	addi	sp,sp,-32
    80004806:	ec06                	sd	ra,24(sp)
    80004808:	e822                	sd	s0,16(sp)
    8000480a:	e426                	sd	s1,8(sp)
    8000480c:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000480e:	0001c517          	auipc	a0,0x1c
    80004812:	47a50513          	addi	a0,a0,1146 # 80020c88 <ftable>
    80004816:	ffffc097          	auipc	ra,0xffffc
    8000481a:	3c0080e7          	jalr	960(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000481e:	0001c497          	auipc	s1,0x1c
    80004822:	48248493          	addi	s1,s1,1154 # 80020ca0 <ftable+0x18>
    80004826:	0001d717          	auipc	a4,0x1d
    8000482a:	41a70713          	addi	a4,a4,1050 # 80021c40 <disk>
    if(f->ref == 0){
    8000482e:	40dc                	lw	a5,4(s1)
    80004830:	cf99                	beqz	a5,8000484e <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004832:	02848493          	addi	s1,s1,40
    80004836:	fee49ce3          	bne	s1,a4,8000482e <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000483a:	0001c517          	auipc	a0,0x1c
    8000483e:	44e50513          	addi	a0,a0,1102 # 80020c88 <ftable>
    80004842:	ffffc097          	auipc	ra,0xffffc
    80004846:	448080e7          	jalr	1096(ra) # 80000c8a <release>
  return 0;
    8000484a:	4481                	li	s1,0
    8000484c:	a819                	j	80004862 <filealloc+0x5e>
      f->ref = 1;
    8000484e:	4785                	li	a5,1
    80004850:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004852:	0001c517          	auipc	a0,0x1c
    80004856:	43650513          	addi	a0,a0,1078 # 80020c88 <ftable>
    8000485a:	ffffc097          	auipc	ra,0xffffc
    8000485e:	430080e7          	jalr	1072(ra) # 80000c8a <release>
}
    80004862:	8526                	mv	a0,s1
    80004864:	60e2                	ld	ra,24(sp)
    80004866:	6442                	ld	s0,16(sp)
    80004868:	64a2                	ld	s1,8(sp)
    8000486a:	6105                	addi	sp,sp,32
    8000486c:	8082                	ret

000000008000486e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000486e:	1101                	addi	sp,sp,-32
    80004870:	ec06                	sd	ra,24(sp)
    80004872:	e822                	sd	s0,16(sp)
    80004874:	e426                	sd	s1,8(sp)
    80004876:	1000                	addi	s0,sp,32
    80004878:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000487a:	0001c517          	auipc	a0,0x1c
    8000487e:	40e50513          	addi	a0,a0,1038 # 80020c88 <ftable>
    80004882:	ffffc097          	auipc	ra,0xffffc
    80004886:	354080e7          	jalr	852(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    8000488a:	40dc                	lw	a5,4(s1)
    8000488c:	02f05263          	blez	a5,800048b0 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004890:	2785                	addiw	a5,a5,1
    80004892:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004894:	0001c517          	auipc	a0,0x1c
    80004898:	3f450513          	addi	a0,a0,1012 # 80020c88 <ftable>
    8000489c:	ffffc097          	auipc	ra,0xffffc
    800048a0:	3ee080e7          	jalr	1006(ra) # 80000c8a <release>
  return f;
}
    800048a4:	8526                	mv	a0,s1
    800048a6:	60e2                	ld	ra,24(sp)
    800048a8:	6442                	ld	s0,16(sp)
    800048aa:	64a2                	ld	s1,8(sp)
    800048ac:	6105                	addi	sp,sp,32
    800048ae:	8082                	ret
    panic("filedup");
    800048b0:	00004517          	auipc	a0,0x4
    800048b4:	e2050513          	addi	a0,a0,-480 # 800086d0 <syscalls+0x250>
    800048b8:	ffffc097          	auipc	ra,0xffffc
    800048bc:	c86080e7          	jalr	-890(ra) # 8000053e <panic>

00000000800048c0 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800048c0:	7139                	addi	sp,sp,-64
    800048c2:	fc06                	sd	ra,56(sp)
    800048c4:	f822                	sd	s0,48(sp)
    800048c6:	f426                	sd	s1,40(sp)
    800048c8:	f04a                	sd	s2,32(sp)
    800048ca:	ec4e                	sd	s3,24(sp)
    800048cc:	e852                	sd	s4,16(sp)
    800048ce:	e456                	sd	s5,8(sp)
    800048d0:	0080                	addi	s0,sp,64
    800048d2:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800048d4:	0001c517          	auipc	a0,0x1c
    800048d8:	3b450513          	addi	a0,a0,948 # 80020c88 <ftable>
    800048dc:	ffffc097          	auipc	ra,0xffffc
    800048e0:	2fa080e7          	jalr	762(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    800048e4:	40dc                	lw	a5,4(s1)
    800048e6:	06f05163          	blez	a5,80004948 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800048ea:	37fd                	addiw	a5,a5,-1
    800048ec:	0007871b          	sext.w	a4,a5
    800048f0:	c0dc                	sw	a5,4(s1)
    800048f2:	06e04363          	bgtz	a4,80004958 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800048f6:	0004a903          	lw	s2,0(s1)
    800048fa:	0094ca83          	lbu	s5,9(s1)
    800048fe:	0104ba03          	ld	s4,16(s1)
    80004902:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004906:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000490a:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000490e:	0001c517          	auipc	a0,0x1c
    80004912:	37a50513          	addi	a0,a0,890 # 80020c88 <ftable>
    80004916:	ffffc097          	auipc	ra,0xffffc
    8000491a:	374080e7          	jalr	884(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    8000491e:	4785                	li	a5,1
    80004920:	04f90d63          	beq	s2,a5,8000497a <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004924:	3979                	addiw	s2,s2,-2
    80004926:	4785                	li	a5,1
    80004928:	0527e063          	bltu	a5,s2,80004968 <fileclose+0xa8>
    begin_op();
    8000492c:	00000097          	auipc	ra,0x0
    80004930:	ac8080e7          	jalr	-1336(ra) # 800043f4 <begin_op>
    iput(ff.ip);
    80004934:	854e                	mv	a0,s3
    80004936:	fffff097          	auipc	ra,0xfffff
    8000493a:	2b6080e7          	jalr	694(ra) # 80003bec <iput>
    end_op();
    8000493e:	00000097          	auipc	ra,0x0
    80004942:	b36080e7          	jalr	-1226(ra) # 80004474 <end_op>
    80004946:	a00d                	j	80004968 <fileclose+0xa8>
    panic("fileclose");
    80004948:	00004517          	auipc	a0,0x4
    8000494c:	d9050513          	addi	a0,a0,-624 # 800086d8 <syscalls+0x258>
    80004950:	ffffc097          	auipc	ra,0xffffc
    80004954:	bee080e7          	jalr	-1042(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004958:	0001c517          	auipc	a0,0x1c
    8000495c:	33050513          	addi	a0,a0,816 # 80020c88 <ftable>
    80004960:	ffffc097          	auipc	ra,0xffffc
    80004964:	32a080e7          	jalr	810(ra) # 80000c8a <release>
  }
}
    80004968:	70e2                	ld	ra,56(sp)
    8000496a:	7442                	ld	s0,48(sp)
    8000496c:	74a2                	ld	s1,40(sp)
    8000496e:	7902                	ld	s2,32(sp)
    80004970:	69e2                	ld	s3,24(sp)
    80004972:	6a42                	ld	s4,16(sp)
    80004974:	6aa2                	ld	s5,8(sp)
    80004976:	6121                	addi	sp,sp,64
    80004978:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000497a:	85d6                	mv	a1,s5
    8000497c:	8552                	mv	a0,s4
    8000497e:	00000097          	auipc	ra,0x0
    80004982:	34c080e7          	jalr	844(ra) # 80004cca <pipeclose>
    80004986:	b7cd                	j	80004968 <fileclose+0xa8>

0000000080004988 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004988:	715d                	addi	sp,sp,-80
    8000498a:	e486                	sd	ra,72(sp)
    8000498c:	e0a2                	sd	s0,64(sp)
    8000498e:	fc26                	sd	s1,56(sp)
    80004990:	f84a                	sd	s2,48(sp)
    80004992:	f44e                	sd	s3,40(sp)
    80004994:	0880                	addi	s0,sp,80
    80004996:	84aa                	mv	s1,a0
    80004998:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000499a:	ffffd097          	auipc	ra,0xffffd
    8000499e:	2d0080e7          	jalr	720(ra) # 80001c6a <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800049a2:	409c                	lw	a5,0(s1)
    800049a4:	37f9                	addiw	a5,a5,-2
    800049a6:	4705                	li	a4,1
    800049a8:	04f76763          	bltu	a4,a5,800049f6 <filestat+0x6e>
    800049ac:	892a                	mv	s2,a0
    ilock(f->ip);
    800049ae:	6c88                	ld	a0,24(s1)
    800049b0:	fffff097          	auipc	ra,0xfffff
    800049b4:	082080e7          	jalr	130(ra) # 80003a32 <ilock>
    stati(f->ip, &st);
    800049b8:	fb840593          	addi	a1,s0,-72
    800049bc:	6c88                	ld	a0,24(s1)
    800049be:	fffff097          	auipc	ra,0xfffff
    800049c2:	2fe080e7          	jalr	766(ra) # 80003cbc <stati>
    iunlock(f->ip);
    800049c6:	6c88                	ld	a0,24(s1)
    800049c8:	fffff097          	auipc	ra,0xfffff
    800049cc:	12c080e7          	jalr	300(ra) # 80003af4 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800049d0:	46e1                	li	a3,24
    800049d2:	fb840613          	addi	a2,s0,-72
    800049d6:	85ce                	mv	a1,s3
    800049d8:	05093503          	ld	a0,80(s2)
    800049dc:	ffffd097          	auipc	ra,0xffffd
    800049e0:	c94080e7          	jalr	-876(ra) # 80001670 <copyout>
    800049e4:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800049e8:	60a6                	ld	ra,72(sp)
    800049ea:	6406                	ld	s0,64(sp)
    800049ec:	74e2                	ld	s1,56(sp)
    800049ee:	7942                	ld	s2,48(sp)
    800049f0:	79a2                	ld	s3,40(sp)
    800049f2:	6161                	addi	sp,sp,80
    800049f4:	8082                	ret
  return -1;
    800049f6:	557d                	li	a0,-1
    800049f8:	bfc5                	j	800049e8 <filestat+0x60>

00000000800049fa <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800049fa:	7179                	addi	sp,sp,-48
    800049fc:	f406                	sd	ra,40(sp)
    800049fe:	f022                	sd	s0,32(sp)
    80004a00:	ec26                	sd	s1,24(sp)
    80004a02:	e84a                	sd	s2,16(sp)
    80004a04:	e44e                	sd	s3,8(sp)
    80004a06:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004a08:	00854783          	lbu	a5,8(a0)
    80004a0c:	c3d5                	beqz	a5,80004ab0 <fileread+0xb6>
    80004a0e:	84aa                	mv	s1,a0
    80004a10:	89ae                	mv	s3,a1
    80004a12:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a14:	411c                	lw	a5,0(a0)
    80004a16:	4705                	li	a4,1
    80004a18:	04e78963          	beq	a5,a4,80004a6a <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a1c:	470d                	li	a4,3
    80004a1e:	04e78d63          	beq	a5,a4,80004a78 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a22:	4709                	li	a4,2
    80004a24:	06e79e63          	bne	a5,a4,80004aa0 <fileread+0xa6>
    ilock(f->ip);
    80004a28:	6d08                	ld	a0,24(a0)
    80004a2a:	fffff097          	auipc	ra,0xfffff
    80004a2e:	008080e7          	jalr	8(ra) # 80003a32 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004a32:	874a                	mv	a4,s2
    80004a34:	5094                	lw	a3,32(s1)
    80004a36:	864e                	mv	a2,s3
    80004a38:	4585                	li	a1,1
    80004a3a:	6c88                	ld	a0,24(s1)
    80004a3c:	fffff097          	auipc	ra,0xfffff
    80004a40:	2aa080e7          	jalr	682(ra) # 80003ce6 <readi>
    80004a44:	892a                	mv	s2,a0
    80004a46:	00a05563          	blez	a0,80004a50 <fileread+0x56>
      f->off += r;
    80004a4a:	509c                	lw	a5,32(s1)
    80004a4c:	9fa9                	addw	a5,a5,a0
    80004a4e:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004a50:	6c88                	ld	a0,24(s1)
    80004a52:	fffff097          	auipc	ra,0xfffff
    80004a56:	0a2080e7          	jalr	162(ra) # 80003af4 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004a5a:	854a                	mv	a0,s2
    80004a5c:	70a2                	ld	ra,40(sp)
    80004a5e:	7402                	ld	s0,32(sp)
    80004a60:	64e2                	ld	s1,24(sp)
    80004a62:	6942                	ld	s2,16(sp)
    80004a64:	69a2                	ld	s3,8(sp)
    80004a66:	6145                	addi	sp,sp,48
    80004a68:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004a6a:	6908                	ld	a0,16(a0)
    80004a6c:	00000097          	auipc	ra,0x0
    80004a70:	3c6080e7          	jalr	966(ra) # 80004e32 <piperead>
    80004a74:	892a                	mv	s2,a0
    80004a76:	b7d5                	j	80004a5a <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004a78:	02451783          	lh	a5,36(a0)
    80004a7c:	03079693          	slli	a3,a5,0x30
    80004a80:	92c1                	srli	a3,a3,0x30
    80004a82:	4725                	li	a4,9
    80004a84:	02d76863          	bltu	a4,a3,80004ab4 <fileread+0xba>
    80004a88:	0792                	slli	a5,a5,0x4
    80004a8a:	0001c717          	auipc	a4,0x1c
    80004a8e:	15e70713          	addi	a4,a4,350 # 80020be8 <devsw>
    80004a92:	97ba                	add	a5,a5,a4
    80004a94:	639c                	ld	a5,0(a5)
    80004a96:	c38d                	beqz	a5,80004ab8 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004a98:	4505                	li	a0,1
    80004a9a:	9782                	jalr	a5
    80004a9c:	892a                	mv	s2,a0
    80004a9e:	bf75                	j	80004a5a <fileread+0x60>
    panic("fileread");
    80004aa0:	00004517          	auipc	a0,0x4
    80004aa4:	c4850513          	addi	a0,a0,-952 # 800086e8 <syscalls+0x268>
    80004aa8:	ffffc097          	auipc	ra,0xffffc
    80004aac:	a96080e7          	jalr	-1386(ra) # 8000053e <panic>
    return -1;
    80004ab0:	597d                	li	s2,-1
    80004ab2:	b765                	j	80004a5a <fileread+0x60>
      return -1;
    80004ab4:	597d                	li	s2,-1
    80004ab6:	b755                	j	80004a5a <fileread+0x60>
    80004ab8:	597d                	li	s2,-1
    80004aba:	b745                	j	80004a5a <fileread+0x60>

0000000080004abc <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004abc:	715d                	addi	sp,sp,-80
    80004abe:	e486                	sd	ra,72(sp)
    80004ac0:	e0a2                	sd	s0,64(sp)
    80004ac2:	fc26                	sd	s1,56(sp)
    80004ac4:	f84a                	sd	s2,48(sp)
    80004ac6:	f44e                	sd	s3,40(sp)
    80004ac8:	f052                	sd	s4,32(sp)
    80004aca:	ec56                	sd	s5,24(sp)
    80004acc:	e85a                	sd	s6,16(sp)
    80004ace:	e45e                	sd	s7,8(sp)
    80004ad0:	e062                	sd	s8,0(sp)
    80004ad2:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004ad4:	00954783          	lbu	a5,9(a0)
    80004ad8:	10078663          	beqz	a5,80004be4 <filewrite+0x128>
    80004adc:	892a                	mv	s2,a0
    80004ade:	8aae                	mv	s5,a1
    80004ae0:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004ae2:	411c                	lw	a5,0(a0)
    80004ae4:	4705                	li	a4,1
    80004ae6:	02e78263          	beq	a5,a4,80004b0a <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004aea:	470d                	li	a4,3
    80004aec:	02e78663          	beq	a5,a4,80004b18 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004af0:	4709                	li	a4,2
    80004af2:	0ee79163          	bne	a5,a4,80004bd4 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004af6:	0ac05d63          	blez	a2,80004bb0 <filewrite+0xf4>
    int i = 0;
    80004afa:	4981                	li	s3,0
    80004afc:	6b05                	lui	s6,0x1
    80004afe:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004b02:	6b85                	lui	s7,0x1
    80004b04:	c00b8b9b          	addiw	s7,s7,-1024
    80004b08:	a861                	j	80004ba0 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004b0a:	6908                	ld	a0,16(a0)
    80004b0c:	00000097          	auipc	ra,0x0
    80004b10:	22e080e7          	jalr	558(ra) # 80004d3a <pipewrite>
    80004b14:	8a2a                	mv	s4,a0
    80004b16:	a045                	j	80004bb6 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004b18:	02451783          	lh	a5,36(a0)
    80004b1c:	03079693          	slli	a3,a5,0x30
    80004b20:	92c1                	srli	a3,a3,0x30
    80004b22:	4725                	li	a4,9
    80004b24:	0cd76263          	bltu	a4,a3,80004be8 <filewrite+0x12c>
    80004b28:	0792                	slli	a5,a5,0x4
    80004b2a:	0001c717          	auipc	a4,0x1c
    80004b2e:	0be70713          	addi	a4,a4,190 # 80020be8 <devsw>
    80004b32:	97ba                	add	a5,a5,a4
    80004b34:	679c                	ld	a5,8(a5)
    80004b36:	cbdd                	beqz	a5,80004bec <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004b38:	4505                	li	a0,1
    80004b3a:	9782                	jalr	a5
    80004b3c:	8a2a                	mv	s4,a0
    80004b3e:	a8a5                	j	80004bb6 <filewrite+0xfa>
    80004b40:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004b44:	00000097          	auipc	ra,0x0
    80004b48:	8b0080e7          	jalr	-1872(ra) # 800043f4 <begin_op>
      ilock(f->ip);
    80004b4c:	01893503          	ld	a0,24(s2)
    80004b50:	fffff097          	auipc	ra,0xfffff
    80004b54:	ee2080e7          	jalr	-286(ra) # 80003a32 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004b58:	8762                	mv	a4,s8
    80004b5a:	02092683          	lw	a3,32(s2)
    80004b5e:	01598633          	add	a2,s3,s5
    80004b62:	4585                	li	a1,1
    80004b64:	01893503          	ld	a0,24(s2)
    80004b68:	fffff097          	auipc	ra,0xfffff
    80004b6c:	276080e7          	jalr	630(ra) # 80003dde <writei>
    80004b70:	84aa                	mv	s1,a0
    80004b72:	00a05763          	blez	a0,80004b80 <filewrite+0xc4>
        f->off += r;
    80004b76:	02092783          	lw	a5,32(s2)
    80004b7a:	9fa9                	addw	a5,a5,a0
    80004b7c:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004b80:	01893503          	ld	a0,24(s2)
    80004b84:	fffff097          	auipc	ra,0xfffff
    80004b88:	f70080e7          	jalr	-144(ra) # 80003af4 <iunlock>
      end_op();
    80004b8c:	00000097          	auipc	ra,0x0
    80004b90:	8e8080e7          	jalr	-1816(ra) # 80004474 <end_op>

      if(r != n1){
    80004b94:	009c1f63          	bne	s8,s1,80004bb2 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004b98:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004b9c:	0149db63          	bge	s3,s4,80004bb2 <filewrite+0xf6>
      int n1 = n - i;
    80004ba0:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004ba4:	84be                	mv	s1,a5
    80004ba6:	2781                	sext.w	a5,a5
    80004ba8:	f8fb5ce3          	bge	s6,a5,80004b40 <filewrite+0x84>
    80004bac:	84de                	mv	s1,s7
    80004bae:	bf49                	j	80004b40 <filewrite+0x84>
    int i = 0;
    80004bb0:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004bb2:	013a1f63          	bne	s4,s3,80004bd0 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004bb6:	8552                	mv	a0,s4
    80004bb8:	60a6                	ld	ra,72(sp)
    80004bba:	6406                	ld	s0,64(sp)
    80004bbc:	74e2                	ld	s1,56(sp)
    80004bbe:	7942                	ld	s2,48(sp)
    80004bc0:	79a2                	ld	s3,40(sp)
    80004bc2:	7a02                	ld	s4,32(sp)
    80004bc4:	6ae2                	ld	s5,24(sp)
    80004bc6:	6b42                	ld	s6,16(sp)
    80004bc8:	6ba2                	ld	s7,8(sp)
    80004bca:	6c02                	ld	s8,0(sp)
    80004bcc:	6161                	addi	sp,sp,80
    80004bce:	8082                	ret
    ret = (i == n ? n : -1);
    80004bd0:	5a7d                	li	s4,-1
    80004bd2:	b7d5                	j	80004bb6 <filewrite+0xfa>
    panic("filewrite");
    80004bd4:	00004517          	auipc	a0,0x4
    80004bd8:	b2450513          	addi	a0,a0,-1244 # 800086f8 <syscalls+0x278>
    80004bdc:	ffffc097          	auipc	ra,0xffffc
    80004be0:	962080e7          	jalr	-1694(ra) # 8000053e <panic>
    return -1;
    80004be4:	5a7d                	li	s4,-1
    80004be6:	bfc1                	j	80004bb6 <filewrite+0xfa>
      return -1;
    80004be8:	5a7d                	li	s4,-1
    80004bea:	b7f1                	j	80004bb6 <filewrite+0xfa>
    80004bec:	5a7d                	li	s4,-1
    80004bee:	b7e1                	j	80004bb6 <filewrite+0xfa>

0000000080004bf0 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004bf0:	7179                	addi	sp,sp,-48
    80004bf2:	f406                	sd	ra,40(sp)
    80004bf4:	f022                	sd	s0,32(sp)
    80004bf6:	ec26                	sd	s1,24(sp)
    80004bf8:	e84a                	sd	s2,16(sp)
    80004bfa:	e44e                	sd	s3,8(sp)
    80004bfc:	e052                	sd	s4,0(sp)
    80004bfe:	1800                	addi	s0,sp,48
    80004c00:	84aa                	mv	s1,a0
    80004c02:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004c04:	0005b023          	sd	zero,0(a1)
    80004c08:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004c0c:	00000097          	auipc	ra,0x0
    80004c10:	bf8080e7          	jalr	-1032(ra) # 80004804 <filealloc>
    80004c14:	e088                	sd	a0,0(s1)
    80004c16:	c551                	beqz	a0,80004ca2 <pipealloc+0xb2>
    80004c18:	00000097          	auipc	ra,0x0
    80004c1c:	bec080e7          	jalr	-1044(ra) # 80004804 <filealloc>
    80004c20:	00aa3023          	sd	a0,0(s4)
    80004c24:	c92d                	beqz	a0,80004c96 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004c26:	ffffc097          	auipc	ra,0xffffc
    80004c2a:	ec0080e7          	jalr	-320(ra) # 80000ae6 <kalloc>
    80004c2e:	892a                	mv	s2,a0
    80004c30:	c125                	beqz	a0,80004c90 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004c32:	4985                	li	s3,1
    80004c34:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004c38:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004c3c:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004c40:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004c44:	00004597          	auipc	a1,0x4
    80004c48:	ac458593          	addi	a1,a1,-1340 # 80008708 <syscalls+0x288>
    80004c4c:	ffffc097          	auipc	ra,0xffffc
    80004c50:	efa080e7          	jalr	-262(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004c54:	609c                	ld	a5,0(s1)
    80004c56:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004c5a:	609c                	ld	a5,0(s1)
    80004c5c:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004c60:	609c                	ld	a5,0(s1)
    80004c62:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004c66:	609c                	ld	a5,0(s1)
    80004c68:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004c6c:	000a3783          	ld	a5,0(s4)
    80004c70:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004c74:	000a3783          	ld	a5,0(s4)
    80004c78:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004c7c:	000a3783          	ld	a5,0(s4)
    80004c80:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004c84:	000a3783          	ld	a5,0(s4)
    80004c88:	0127b823          	sd	s2,16(a5)
  return 0;
    80004c8c:	4501                	li	a0,0
    80004c8e:	a025                	j	80004cb6 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004c90:	6088                	ld	a0,0(s1)
    80004c92:	e501                	bnez	a0,80004c9a <pipealloc+0xaa>
    80004c94:	a039                	j	80004ca2 <pipealloc+0xb2>
    80004c96:	6088                	ld	a0,0(s1)
    80004c98:	c51d                	beqz	a0,80004cc6 <pipealloc+0xd6>
    fileclose(*f0);
    80004c9a:	00000097          	auipc	ra,0x0
    80004c9e:	c26080e7          	jalr	-986(ra) # 800048c0 <fileclose>
  if(*f1)
    80004ca2:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004ca6:	557d                	li	a0,-1
  if(*f1)
    80004ca8:	c799                	beqz	a5,80004cb6 <pipealloc+0xc6>
    fileclose(*f1);
    80004caa:	853e                	mv	a0,a5
    80004cac:	00000097          	auipc	ra,0x0
    80004cb0:	c14080e7          	jalr	-1004(ra) # 800048c0 <fileclose>
  return -1;
    80004cb4:	557d                	li	a0,-1
}
    80004cb6:	70a2                	ld	ra,40(sp)
    80004cb8:	7402                	ld	s0,32(sp)
    80004cba:	64e2                	ld	s1,24(sp)
    80004cbc:	6942                	ld	s2,16(sp)
    80004cbe:	69a2                	ld	s3,8(sp)
    80004cc0:	6a02                	ld	s4,0(sp)
    80004cc2:	6145                	addi	sp,sp,48
    80004cc4:	8082                	ret
  return -1;
    80004cc6:	557d                	li	a0,-1
    80004cc8:	b7fd                	j	80004cb6 <pipealloc+0xc6>

0000000080004cca <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004cca:	1101                	addi	sp,sp,-32
    80004ccc:	ec06                	sd	ra,24(sp)
    80004cce:	e822                	sd	s0,16(sp)
    80004cd0:	e426                	sd	s1,8(sp)
    80004cd2:	e04a                	sd	s2,0(sp)
    80004cd4:	1000                	addi	s0,sp,32
    80004cd6:	84aa                	mv	s1,a0
    80004cd8:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004cda:	ffffc097          	auipc	ra,0xffffc
    80004cde:	efc080e7          	jalr	-260(ra) # 80000bd6 <acquire>
  if(writable){
    80004ce2:	02090d63          	beqz	s2,80004d1c <pipeclose+0x52>
    pi->writeopen = 0;
    80004ce6:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004cea:	21848513          	addi	a0,s1,536
    80004cee:	ffffd097          	auipc	ra,0xffffd
    80004cf2:	688080e7          	jalr	1672(ra) # 80002376 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004cf6:	2204b783          	ld	a5,544(s1)
    80004cfa:	eb95                	bnez	a5,80004d2e <pipeclose+0x64>
    release(&pi->lock);
    80004cfc:	8526                	mv	a0,s1
    80004cfe:	ffffc097          	auipc	ra,0xffffc
    80004d02:	f8c080e7          	jalr	-116(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004d06:	8526                	mv	a0,s1
    80004d08:	ffffc097          	auipc	ra,0xffffc
    80004d0c:	ce2080e7          	jalr	-798(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    80004d10:	60e2                	ld	ra,24(sp)
    80004d12:	6442                	ld	s0,16(sp)
    80004d14:	64a2                	ld	s1,8(sp)
    80004d16:	6902                	ld	s2,0(sp)
    80004d18:	6105                	addi	sp,sp,32
    80004d1a:	8082                	ret
    pi->readopen = 0;
    80004d1c:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004d20:	21c48513          	addi	a0,s1,540
    80004d24:	ffffd097          	auipc	ra,0xffffd
    80004d28:	652080e7          	jalr	1618(ra) # 80002376 <wakeup>
    80004d2c:	b7e9                	j	80004cf6 <pipeclose+0x2c>
    release(&pi->lock);
    80004d2e:	8526                	mv	a0,s1
    80004d30:	ffffc097          	auipc	ra,0xffffc
    80004d34:	f5a080e7          	jalr	-166(ra) # 80000c8a <release>
}
    80004d38:	bfe1                	j	80004d10 <pipeclose+0x46>

0000000080004d3a <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004d3a:	711d                	addi	sp,sp,-96
    80004d3c:	ec86                	sd	ra,88(sp)
    80004d3e:	e8a2                	sd	s0,80(sp)
    80004d40:	e4a6                	sd	s1,72(sp)
    80004d42:	e0ca                	sd	s2,64(sp)
    80004d44:	fc4e                	sd	s3,56(sp)
    80004d46:	f852                	sd	s4,48(sp)
    80004d48:	f456                	sd	s5,40(sp)
    80004d4a:	f05a                	sd	s6,32(sp)
    80004d4c:	ec5e                	sd	s7,24(sp)
    80004d4e:	e862                	sd	s8,16(sp)
    80004d50:	1080                	addi	s0,sp,96
    80004d52:	84aa                	mv	s1,a0
    80004d54:	8aae                	mv	s5,a1
    80004d56:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004d58:	ffffd097          	auipc	ra,0xffffd
    80004d5c:	f12080e7          	jalr	-238(ra) # 80001c6a <myproc>
    80004d60:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004d62:	8526                	mv	a0,s1
    80004d64:	ffffc097          	auipc	ra,0xffffc
    80004d68:	e72080e7          	jalr	-398(ra) # 80000bd6 <acquire>
  while(i < n){
    80004d6c:	0b405663          	blez	s4,80004e18 <pipewrite+0xde>
  int i = 0;
    80004d70:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d72:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004d74:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004d78:	21c48b93          	addi	s7,s1,540
    80004d7c:	a089                	j	80004dbe <pipewrite+0x84>
      release(&pi->lock);
    80004d7e:	8526                	mv	a0,s1
    80004d80:	ffffc097          	auipc	ra,0xffffc
    80004d84:	f0a080e7          	jalr	-246(ra) # 80000c8a <release>
      return -1;
    80004d88:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004d8a:	854a                	mv	a0,s2
    80004d8c:	60e6                	ld	ra,88(sp)
    80004d8e:	6446                	ld	s0,80(sp)
    80004d90:	64a6                	ld	s1,72(sp)
    80004d92:	6906                	ld	s2,64(sp)
    80004d94:	79e2                	ld	s3,56(sp)
    80004d96:	7a42                	ld	s4,48(sp)
    80004d98:	7aa2                	ld	s5,40(sp)
    80004d9a:	7b02                	ld	s6,32(sp)
    80004d9c:	6be2                	ld	s7,24(sp)
    80004d9e:	6c42                	ld	s8,16(sp)
    80004da0:	6125                	addi	sp,sp,96
    80004da2:	8082                	ret
      wakeup(&pi->nread);
    80004da4:	8562                	mv	a0,s8
    80004da6:	ffffd097          	auipc	ra,0xffffd
    80004daa:	5d0080e7          	jalr	1488(ra) # 80002376 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004dae:	85a6                	mv	a1,s1
    80004db0:	855e                	mv	a0,s7
    80004db2:	ffffd097          	auipc	ra,0xffffd
    80004db6:	560080e7          	jalr	1376(ra) # 80002312 <sleep>
  while(i < n){
    80004dba:	07495063          	bge	s2,s4,80004e1a <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004dbe:	2204a783          	lw	a5,544(s1)
    80004dc2:	dfd5                	beqz	a5,80004d7e <pipewrite+0x44>
    80004dc4:	854e                	mv	a0,s3
    80004dc6:	ffffd097          	auipc	ra,0xffffd
    80004dca:	7f4080e7          	jalr	2036(ra) # 800025ba <killed>
    80004dce:	f945                	bnez	a0,80004d7e <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004dd0:	2184a783          	lw	a5,536(s1)
    80004dd4:	21c4a703          	lw	a4,540(s1)
    80004dd8:	2007879b          	addiw	a5,a5,512
    80004ddc:	fcf704e3          	beq	a4,a5,80004da4 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004de0:	4685                	li	a3,1
    80004de2:	01590633          	add	a2,s2,s5
    80004de6:	faf40593          	addi	a1,s0,-81
    80004dea:	0509b503          	ld	a0,80(s3)
    80004dee:	ffffd097          	auipc	ra,0xffffd
    80004df2:	90e080e7          	jalr	-1778(ra) # 800016fc <copyin>
    80004df6:	03650263          	beq	a0,s6,80004e1a <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004dfa:	21c4a783          	lw	a5,540(s1)
    80004dfe:	0017871b          	addiw	a4,a5,1
    80004e02:	20e4ae23          	sw	a4,540(s1)
    80004e06:	1ff7f793          	andi	a5,a5,511
    80004e0a:	97a6                	add	a5,a5,s1
    80004e0c:	faf44703          	lbu	a4,-81(s0)
    80004e10:	00e78c23          	sb	a4,24(a5)
      i++;
    80004e14:	2905                	addiw	s2,s2,1
    80004e16:	b755                	j	80004dba <pipewrite+0x80>
  int i = 0;
    80004e18:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004e1a:	21848513          	addi	a0,s1,536
    80004e1e:	ffffd097          	auipc	ra,0xffffd
    80004e22:	558080e7          	jalr	1368(ra) # 80002376 <wakeup>
  release(&pi->lock);
    80004e26:	8526                	mv	a0,s1
    80004e28:	ffffc097          	auipc	ra,0xffffc
    80004e2c:	e62080e7          	jalr	-414(ra) # 80000c8a <release>
  return i;
    80004e30:	bfa9                	j	80004d8a <pipewrite+0x50>

0000000080004e32 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004e32:	715d                	addi	sp,sp,-80
    80004e34:	e486                	sd	ra,72(sp)
    80004e36:	e0a2                	sd	s0,64(sp)
    80004e38:	fc26                	sd	s1,56(sp)
    80004e3a:	f84a                	sd	s2,48(sp)
    80004e3c:	f44e                	sd	s3,40(sp)
    80004e3e:	f052                	sd	s4,32(sp)
    80004e40:	ec56                	sd	s5,24(sp)
    80004e42:	e85a                	sd	s6,16(sp)
    80004e44:	0880                	addi	s0,sp,80
    80004e46:	84aa                	mv	s1,a0
    80004e48:	892e                	mv	s2,a1
    80004e4a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004e4c:	ffffd097          	auipc	ra,0xffffd
    80004e50:	e1e080e7          	jalr	-482(ra) # 80001c6a <myproc>
    80004e54:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004e56:	8526                	mv	a0,s1
    80004e58:	ffffc097          	auipc	ra,0xffffc
    80004e5c:	d7e080e7          	jalr	-642(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e60:	2184a703          	lw	a4,536(s1)
    80004e64:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e68:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e6c:	02f71763          	bne	a4,a5,80004e9a <piperead+0x68>
    80004e70:	2244a783          	lw	a5,548(s1)
    80004e74:	c39d                	beqz	a5,80004e9a <piperead+0x68>
    if(killed(pr)){
    80004e76:	8552                	mv	a0,s4
    80004e78:	ffffd097          	auipc	ra,0xffffd
    80004e7c:	742080e7          	jalr	1858(ra) # 800025ba <killed>
    80004e80:	e941                	bnez	a0,80004f10 <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e82:	85a6                	mv	a1,s1
    80004e84:	854e                	mv	a0,s3
    80004e86:	ffffd097          	auipc	ra,0xffffd
    80004e8a:	48c080e7          	jalr	1164(ra) # 80002312 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e8e:	2184a703          	lw	a4,536(s1)
    80004e92:	21c4a783          	lw	a5,540(s1)
    80004e96:	fcf70de3          	beq	a4,a5,80004e70 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e9a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e9c:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e9e:	05505363          	blez	s5,80004ee4 <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    80004ea2:	2184a783          	lw	a5,536(s1)
    80004ea6:	21c4a703          	lw	a4,540(s1)
    80004eaa:	02f70d63          	beq	a4,a5,80004ee4 <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004eae:	0017871b          	addiw	a4,a5,1
    80004eb2:	20e4ac23          	sw	a4,536(s1)
    80004eb6:	1ff7f793          	andi	a5,a5,511
    80004eba:	97a6                	add	a5,a5,s1
    80004ebc:	0187c783          	lbu	a5,24(a5)
    80004ec0:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ec4:	4685                	li	a3,1
    80004ec6:	fbf40613          	addi	a2,s0,-65
    80004eca:	85ca                	mv	a1,s2
    80004ecc:	050a3503          	ld	a0,80(s4)
    80004ed0:	ffffc097          	auipc	ra,0xffffc
    80004ed4:	7a0080e7          	jalr	1952(ra) # 80001670 <copyout>
    80004ed8:	01650663          	beq	a0,s6,80004ee4 <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004edc:	2985                	addiw	s3,s3,1
    80004ede:	0905                	addi	s2,s2,1
    80004ee0:	fd3a91e3          	bne	s5,s3,80004ea2 <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004ee4:	21c48513          	addi	a0,s1,540
    80004ee8:	ffffd097          	auipc	ra,0xffffd
    80004eec:	48e080e7          	jalr	1166(ra) # 80002376 <wakeup>
  release(&pi->lock);
    80004ef0:	8526                	mv	a0,s1
    80004ef2:	ffffc097          	auipc	ra,0xffffc
    80004ef6:	d98080e7          	jalr	-616(ra) # 80000c8a <release>
  return i;
}
    80004efa:	854e                	mv	a0,s3
    80004efc:	60a6                	ld	ra,72(sp)
    80004efe:	6406                	ld	s0,64(sp)
    80004f00:	74e2                	ld	s1,56(sp)
    80004f02:	7942                	ld	s2,48(sp)
    80004f04:	79a2                	ld	s3,40(sp)
    80004f06:	7a02                	ld	s4,32(sp)
    80004f08:	6ae2                	ld	s5,24(sp)
    80004f0a:	6b42                	ld	s6,16(sp)
    80004f0c:	6161                	addi	sp,sp,80
    80004f0e:	8082                	ret
      release(&pi->lock);
    80004f10:	8526                	mv	a0,s1
    80004f12:	ffffc097          	auipc	ra,0xffffc
    80004f16:	d78080e7          	jalr	-648(ra) # 80000c8a <release>
      return -1;
    80004f1a:	59fd                	li	s3,-1
    80004f1c:	bff9                	j	80004efa <piperead+0xc8>

0000000080004f1e <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004f1e:	1141                	addi	sp,sp,-16
    80004f20:	e422                	sd	s0,8(sp)
    80004f22:	0800                	addi	s0,sp,16
    80004f24:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004f26:	8905                	andi	a0,a0,1
    80004f28:	c111                	beqz	a0,80004f2c <flags2perm+0xe>
      perm = PTE_X;
    80004f2a:	4521                	li	a0,8
    if(flags & 0x2)
    80004f2c:	8b89                	andi	a5,a5,2
    80004f2e:	c399                	beqz	a5,80004f34 <flags2perm+0x16>
      perm |= PTE_W;
    80004f30:	00456513          	ori	a0,a0,4
    return perm;
}
    80004f34:	6422                	ld	s0,8(sp)
    80004f36:	0141                	addi	sp,sp,16
    80004f38:	8082                	ret

0000000080004f3a <exec>:

int
exec(char *path, char **argv)
{
    80004f3a:	de010113          	addi	sp,sp,-544
    80004f3e:	20113c23          	sd	ra,536(sp)
    80004f42:	20813823          	sd	s0,528(sp)
    80004f46:	20913423          	sd	s1,520(sp)
    80004f4a:	21213023          	sd	s2,512(sp)
    80004f4e:	ffce                	sd	s3,504(sp)
    80004f50:	fbd2                	sd	s4,496(sp)
    80004f52:	f7d6                	sd	s5,488(sp)
    80004f54:	f3da                	sd	s6,480(sp)
    80004f56:	efde                	sd	s7,472(sp)
    80004f58:	ebe2                	sd	s8,464(sp)
    80004f5a:	e7e6                	sd	s9,456(sp)
    80004f5c:	e3ea                	sd	s10,448(sp)
    80004f5e:	ff6e                	sd	s11,440(sp)
    80004f60:	1400                	addi	s0,sp,544
    80004f62:	892a                	mv	s2,a0
    80004f64:	dea43423          	sd	a0,-536(s0)
    80004f68:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004f6c:	ffffd097          	auipc	ra,0xffffd
    80004f70:	cfe080e7          	jalr	-770(ra) # 80001c6a <myproc>
    80004f74:	84aa                	mv	s1,a0

  begin_op();
    80004f76:	fffff097          	auipc	ra,0xfffff
    80004f7a:	47e080e7          	jalr	1150(ra) # 800043f4 <begin_op>

  if((ip = namei(path)) == 0){
    80004f7e:	854a                	mv	a0,s2
    80004f80:	fffff097          	auipc	ra,0xfffff
    80004f84:	258080e7          	jalr	600(ra) # 800041d8 <namei>
    80004f88:	c93d                	beqz	a0,80004ffe <exec+0xc4>
    80004f8a:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004f8c:	fffff097          	auipc	ra,0xfffff
    80004f90:	aa6080e7          	jalr	-1370(ra) # 80003a32 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004f94:	04000713          	li	a4,64
    80004f98:	4681                	li	a3,0
    80004f9a:	e5040613          	addi	a2,s0,-432
    80004f9e:	4581                	li	a1,0
    80004fa0:	8556                	mv	a0,s5
    80004fa2:	fffff097          	auipc	ra,0xfffff
    80004fa6:	d44080e7          	jalr	-700(ra) # 80003ce6 <readi>
    80004faa:	04000793          	li	a5,64
    80004fae:	00f51a63          	bne	a0,a5,80004fc2 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004fb2:	e5042703          	lw	a4,-432(s0)
    80004fb6:	464c47b7          	lui	a5,0x464c4
    80004fba:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004fbe:	04f70663          	beq	a4,a5,8000500a <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004fc2:	8556                	mv	a0,s5
    80004fc4:	fffff097          	auipc	ra,0xfffff
    80004fc8:	cd0080e7          	jalr	-816(ra) # 80003c94 <iunlockput>
    end_op();
    80004fcc:	fffff097          	auipc	ra,0xfffff
    80004fd0:	4a8080e7          	jalr	1192(ra) # 80004474 <end_op>
  }
  return -1;
    80004fd4:	557d                	li	a0,-1
}
    80004fd6:	21813083          	ld	ra,536(sp)
    80004fda:	21013403          	ld	s0,528(sp)
    80004fde:	20813483          	ld	s1,520(sp)
    80004fe2:	20013903          	ld	s2,512(sp)
    80004fe6:	79fe                	ld	s3,504(sp)
    80004fe8:	7a5e                	ld	s4,496(sp)
    80004fea:	7abe                	ld	s5,488(sp)
    80004fec:	7b1e                	ld	s6,480(sp)
    80004fee:	6bfe                	ld	s7,472(sp)
    80004ff0:	6c5e                	ld	s8,464(sp)
    80004ff2:	6cbe                	ld	s9,456(sp)
    80004ff4:	6d1e                	ld	s10,448(sp)
    80004ff6:	7dfa                	ld	s11,440(sp)
    80004ff8:	22010113          	addi	sp,sp,544
    80004ffc:	8082                	ret
    end_op();
    80004ffe:	fffff097          	auipc	ra,0xfffff
    80005002:	476080e7          	jalr	1142(ra) # 80004474 <end_op>
    return -1;
    80005006:	557d                	li	a0,-1
    80005008:	b7f9                	j	80004fd6 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    8000500a:	8526                	mv	a0,s1
    8000500c:	ffffd097          	auipc	ra,0xffffd
    80005010:	d22080e7          	jalr	-734(ra) # 80001d2e <proc_pagetable>
    80005014:	8b2a                	mv	s6,a0
    80005016:	d555                	beqz	a0,80004fc2 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005018:	e7042783          	lw	a5,-400(s0)
    8000501c:	e8845703          	lhu	a4,-376(s0)
    80005020:	c735                	beqz	a4,8000508c <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005022:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005024:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80005028:	6a05                	lui	s4,0x1
    8000502a:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    8000502e:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80005032:	6d85                	lui	s11,0x1
    80005034:	7d7d                	lui	s10,0xfffff
    80005036:	a481                	j	80005276 <exec+0x33c>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005038:	00003517          	auipc	a0,0x3
    8000503c:	6d850513          	addi	a0,a0,1752 # 80008710 <syscalls+0x290>
    80005040:	ffffb097          	auipc	ra,0xffffb
    80005044:	4fe080e7          	jalr	1278(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005048:	874a                	mv	a4,s2
    8000504a:	009c86bb          	addw	a3,s9,s1
    8000504e:	4581                	li	a1,0
    80005050:	8556                	mv	a0,s5
    80005052:	fffff097          	auipc	ra,0xfffff
    80005056:	c94080e7          	jalr	-876(ra) # 80003ce6 <readi>
    8000505a:	2501                	sext.w	a0,a0
    8000505c:	1aa91a63          	bne	s2,a0,80005210 <exec+0x2d6>
  for(i = 0; i < sz; i += PGSIZE){
    80005060:	009d84bb          	addw	s1,s11,s1
    80005064:	013d09bb          	addw	s3,s10,s3
    80005068:	1f74f763          	bgeu	s1,s7,80005256 <exec+0x31c>
    pa = walkaddr(pagetable, va + i);
    8000506c:	02049593          	slli	a1,s1,0x20
    80005070:	9181                	srli	a1,a1,0x20
    80005072:	95e2                	add	a1,a1,s8
    80005074:	855a                	mv	a0,s6
    80005076:	ffffc097          	auipc	ra,0xffffc
    8000507a:	fe6080e7          	jalr	-26(ra) # 8000105c <walkaddr>
    8000507e:	862a                	mv	a2,a0
    if(pa == 0)
    80005080:	dd45                	beqz	a0,80005038 <exec+0xfe>
      n = PGSIZE;
    80005082:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005084:	fd49f2e3          	bgeu	s3,s4,80005048 <exec+0x10e>
      n = sz - i;
    80005088:	894e                	mv	s2,s3
    8000508a:	bf7d                	j	80005048 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000508c:	4901                	li	s2,0
  iunlockput(ip);
    8000508e:	8556                	mv	a0,s5
    80005090:	fffff097          	auipc	ra,0xfffff
    80005094:	c04080e7          	jalr	-1020(ra) # 80003c94 <iunlockput>
  end_op();
    80005098:	fffff097          	auipc	ra,0xfffff
    8000509c:	3dc080e7          	jalr	988(ra) # 80004474 <end_op>
  p = myproc();
    800050a0:	ffffd097          	auipc	ra,0xffffd
    800050a4:	bca080e7          	jalr	-1078(ra) # 80001c6a <myproc>
    800050a8:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    800050aa:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    800050ae:	6785                	lui	a5,0x1
    800050b0:	17fd                	addi	a5,a5,-1
    800050b2:	993e                	add	s2,s2,a5
    800050b4:	77fd                	lui	a5,0xfffff
    800050b6:	00f977b3          	and	a5,s2,a5
    800050ba:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800050be:	4691                	li	a3,4
    800050c0:	6609                	lui	a2,0x2
    800050c2:	963e                	add	a2,a2,a5
    800050c4:	85be                	mv	a1,a5
    800050c6:	855a                	mv	a0,s6
    800050c8:	ffffc097          	auipc	ra,0xffffc
    800050cc:	350080e7          	jalr	848(ra) # 80001418 <uvmalloc>
    800050d0:	8c2a                	mv	s8,a0
  ip = 0;
    800050d2:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800050d4:	12050e63          	beqz	a0,80005210 <exec+0x2d6>
  uvmclear(pagetable, sz-2*PGSIZE);
    800050d8:	75f9                	lui	a1,0xffffe
    800050da:	95aa                	add	a1,a1,a0
    800050dc:	855a                	mv	a0,s6
    800050de:	ffffc097          	auipc	ra,0xffffc
    800050e2:	560080e7          	jalr	1376(ra) # 8000163e <uvmclear>
  stackbase = sp - PGSIZE;
    800050e6:	7afd                	lui	s5,0xfffff
    800050e8:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    800050ea:	df043783          	ld	a5,-528(s0)
    800050ee:	6388                	ld	a0,0(a5)
    800050f0:	c925                	beqz	a0,80005160 <exec+0x226>
    800050f2:	e9040993          	addi	s3,s0,-368
    800050f6:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800050fa:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800050fc:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800050fe:	ffffc097          	auipc	ra,0xffffc
    80005102:	d50080e7          	jalr	-688(ra) # 80000e4e <strlen>
    80005106:	0015079b          	addiw	a5,a0,1
    8000510a:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000510e:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005112:	13596663          	bltu	s2,s5,8000523e <exec+0x304>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005116:	df043d83          	ld	s11,-528(s0)
    8000511a:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    8000511e:	8552                	mv	a0,s4
    80005120:	ffffc097          	auipc	ra,0xffffc
    80005124:	d2e080e7          	jalr	-722(ra) # 80000e4e <strlen>
    80005128:	0015069b          	addiw	a3,a0,1
    8000512c:	8652                	mv	a2,s4
    8000512e:	85ca                	mv	a1,s2
    80005130:	855a                	mv	a0,s6
    80005132:	ffffc097          	auipc	ra,0xffffc
    80005136:	53e080e7          	jalr	1342(ra) # 80001670 <copyout>
    8000513a:	10054663          	bltz	a0,80005246 <exec+0x30c>
    ustack[argc] = sp;
    8000513e:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005142:	0485                	addi	s1,s1,1
    80005144:	008d8793          	addi	a5,s11,8
    80005148:	def43823          	sd	a5,-528(s0)
    8000514c:	008db503          	ld	a0,8(s11)
    80005150:	c911                	beqz	a0,80005164 <exec+0x22a>
    if(argc >= MAXARG)
    80005152:	09a1                	addi	s3,s3,8
    80005154:	fb3c95e3          	bne	s9,s3,800050fe <exec+0x1c4>
  sz = sz1;
    80005158:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000515c:	4a81                	li	s5,0
    8000515e:	a84d                	j	80005210 <exec+0x2d6>
  sp = sz;
    80005160:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005162:	4481                	li	s1,0
  ustack[argc] = 0;
    80005164:	00349793          	slli	a5,s1,0x3
    80005168:	f9040713          	addi	a4,s0,-112
    8000516c:	97ba                	add	a5,a5,a4
    8000516e:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffdd180>
  sp -= (argc+1) * sizeof(uint64);
    80005172:	00148693          	addi	a3,s1,1
    80005176:	068e                	slli	a3,a3,0x3
    80005178:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000517c:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005180:	01597663          	bgeu	s2,s5,8000518c <exec+0x252>
  sz = sz1;
    80005184:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005188:	4a81                	li	s5,0
    8000518a:	a059                	j	80005210 <exec+0x2d6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000518c:	e9040613          	addi	a2,s0,-368
    80005190:	85ca                	mv	a1,s2
    80005192:	855a                	mv	a0,s6
    80005194:	ffffc097          	auipc	ra,0xffffc
    80005198:	4dc080e7          	jalr	1244(ra) # 80001670 <copyout>
    8000519c:	0a054963          	bltz	a0,8000524e <exec+0x314>
  p->trapframe->a1 = sp;
    800051a0:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    800051a4:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800051a8:	de843783          	ld	a5,-536(s0)
    800051ac:	0007c703          	lbu	a4,0(a5)
    800051b0:	cf11                	beqz	a4,800051cc <exec+0x292>
    800051b2:	0785                	addi	a5,a5,1
    if(*s == '/')
    800051b4:	02f00693          	li	a3,47
    800051b8:	a039                	j	800051c6 <exec+0x28c>
      last = s+1;
    800051ba:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    800051be:	0785                	addi	a5,a5,1
    800051c0:	fff7c703          	lbu	a4,-1(a5)
    800051c4:	c701                	beqz	a4,800051cc <exec+0x292>
    if(*s == '/')
    800051c6:	fed71ce3          	bne	a4,a3,800051be <exec+0x284>
    800051ca:	bfc5                	j	800051ba <exec+0x280>
  safestrcpy(p->name, last, sizeof(p->name));
    800051cc:	4641                	li	a2,16
    800051ce:	de843583          	ld	a1,-536(s0)
    800051d2:	158b8513          	addi	a0,s7,344
    800051d6:	ffffc097          	auipc	ra,0xffffc
    800051da:	c46080e7          	jalr	-954(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    800051de:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    800051e2:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    800051e6:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800051ea:	058bb783          	ld	a5,88(s7)
    800051ee:	e6843703          	ld	a4,-408(s0)
    800051f2:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800051f4:	058bb783          	ld	a5,88(s7)
    800051f8:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800051fc:	85ea                	mv	a1,s10
    800051fe:	ffffd097          	auipc	ra,0xffffd
    80005202:	bcc080e7          	jalr	-1076(ra) # 80001dca <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005206:	0004851b          	sext.w	a0,s1
    8000520a:	b3f1                	j	80004fd6 <exec+0x9c>
    8000520c:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005210:	df843583          	ld	a1,-520(s0)
    80005214:	855a                	mv	a0,s6
    80005216:	ffffd097          	auipc	ra,0xffffd
    8000521a:	bb4080e7          	jalr	-1100(ra) # 80001dca <proc_freepagetable>
  if(ip){
    8000521e:	da0a92e3          	bnez	s5,80004fc2 <exec+0x88>
  return -1;
    80005222:	557d                	li	a0,-1
    80005224:	bb4d                	j	80004fd6 <exec+0x9c>
    80005226:	df243c23          	sd	s2,-520(s0)
    8000522a:	b7dd                	j	80005210 <exec+0x2d6>
    8000522c:	df243c23          	sd	s2,-520(s0)
    80005230:	b7c5                	j	80005210 <exec+0x2d6>
    80005232:	df243c23          	sd	s2,-520(s0)
    80005236:	bfe9                	j	80005210 <exec+0x2d6>
    80005238:	df243c23          	sd	s2,-520(s0)
    8000523c:	bfd1                	j	80005210 <exec+0x2d6>
  sz = sz1;
    8000523e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005242:	4a81                	li	s5,0
    80005244:	b7f1                	j	80005210 <exec+0x2d6>
  sz = sz1;
    80005246:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000524a:	4a81                	li	s5,0
    8000524c:	b7d1                	j	80005210 <exec+0x2d6>
  sz = sz1;
    8000524e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005252:	4a81                	li	s5,0
    80005254:	bf75                	j	80005210 <exec+0x2d6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005256:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000525a:	e0843783          	ld	a5,-504(s0)
    8000525e:	0017869b          	addiw	a3,a5,1
    80005262:	e0d43423          	sd	a3,-504(s0)
    80005266:	e0043783          	ld	a5,-512(s0)
    8000526a:	0387879b          	addiw	a5,a5,56
    8000526e:	e8845703          	lhu	a4,-376(s0)
    80005272:	e0e6dee3          	bge	a3,a4,8000508e <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005276:	2781                	sext.w	a5,a5
    80005278:	e0f43023          	sd	a5,-512(s0)
    8000527c:	03800713          	li	a4,56
    80005280:	86be                	mv	a3,a5
    80005282:	e1840613          	addi	a2,s0,-488
    80005286:	4581                	li	a1,0
    80005288:	8556                	mv	a0,s5
    8000528a:	fffff097          	auipc	ra,0xfffff
    8000528e:	a5c080e7          	jalr	-1444(ra) # 80003ce6 <readi>
    80005292:	03800793          	li	a5,56
    80005296:	f6f51be3          	bne	a0,a5,8000520c <exec+0x2d2>
    if(ph.type != ELF_PROG_LOAD)
    8000529a:	e1842783          	lw	a5,-488(s0)
    8000529e:	4705                	li	a4,1
    800052a0:	fae79de3          	bne	a5,a4,8000525a <exec+0x320>
    if(ph.memsz < ph.filesz)
    800052a4:	e4043483          	ld	s1,-448(s0)
    800052a8:	e3843783          	ld	a5,-456(s0)
    800052ac:	f6f4ede3          	bltu	s1,a5,80005226 <exec+0x2ec>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800052b0:	e2843783          	ld	a5,-472(s0)
    800052b4:	94be                	add	s1,s1,a5
    800052b6:	f6f4ebe3          	bltu	s1,a5,8000522c <exec+0x2f2>
    if(ph.vaddr % PGSIZE != 0)
    800052ba:	de043703          	ld	a4,-544(s0)
    800052be:	8ff9                	and	a5,a5,a4
    800052c0:	fbad                	bnez	a5,80005232 <exec+0x2f8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800052c2:	e1c42503          	lw	a0,-484(s0)
    800052c6:	00000097          	auipc	ra,0x0
    800052ca:	c58080e7          	jalr	-936(ra) # 80004f1e <flags2perm>
    800052ce:	86aa                	mv	a3,a0
    800052d0:	8626                	mv	a2,s1
    800052d2:	85ca                	mv	a1,s2
    800052d4:	855a                	mv	a0,s6
    800052d6:	ffffc097          	auipc	ra,0xffffc
    800052da:	142080e7          	jalr	322(ra) # 80001418 <uvmalloc>
    800052de:	dea43c23          	sd	a0,-520(s0)
    800052e2:	d939                	beqz	a0,80005238 <exec+0x2fe>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800052e4:	e2843c03          	ld	s8,-472(s0)
    800052e8:	e2042c83          	lw	s9,-480(s0)
    800052ec:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800052f0:	f60b83e3          	beqz	s7,80005256 <exec+0x31c>
    800052f4:	89de                	mv	s3,s7
    800052f6:	4481                	li	s1,0
    800052f8:	bb95                	j	8000506c <exec+0x132>

00000000800052fa <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800052fa:	7179                	addi	sp,sp,-48
    800052fc:	f406                	sd	ra,40(sp)
    800052fe:	f022                	sd	s0,32(sp)
    80005300:	ec26                	sd	s1,24(sp)
    80005302:	e84a                	sd	s2,16(sp)
    80005304:	1800                	addi	s0,sp,48
    80005306:	892e                	mv	s2,a1
    80005308:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    8000530a:	fdc40593          	addi	a1,s0,-36
    8000530e:	ffffe097          	auipc	ra,0xffffe
    80005312:	a8a080e7          	jalr	-1398(ra) # 80002d98 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005316:	fdc42703          	lw	a4,-36(s0)
    8000531a:	47bd                	li	a5,15
    8000531c:	02e7eb63          	bltu	a5,a4,80005352 <argfd+0x58>
    80005320:	ffffd097          	auipc	ra,0xffffd
    80005324:	94a080e7          	jalr	-1718(ra) # 80001c6a <myproc>
    80005328:	fdc42703          	lw	a4,-36(s0)
    8000532c:	01a70793          	addi	a5,a4,26
    80005330:	078e                	slli	a5,a5,0x3
    80005332:	953e                	add	a0,a0,a5
    80005334:	611c                	ld	a5,0(a0)
    80005336:	c385                	beqz	a5,80005356 <argfd+0x5c>
    return -1;
  if(pfd)
    80005338:	00090463          	beqz	s2,80005340 <argfd+0x46>
    *pfd = fd;
    8000533c:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005340:	4501                	li	a0,0
  if(pf)
    80005342:	c091                	beqz	s1,80005346 <argfd+0x4c>
    *pf = f;
    80005344:	e09c                	sd	a5,0(s1)
}
    80005346:	70a2                	ld	ra,40(sp)
    80005348:	7402                	ld	s0,32(sp)
    8000534a:	64e2                	ld	s1,24(sp)
    8000534c:	6942                	ld	s2,16(sp)
    8000534e:	6145                	addi	sp,sp,48
    80005350:	8082                	ret
    return -1;
    80005352:	557d                	li	a0,-1
    80005354:	bfcd                	j	80005346 <argfd+0x4c>
    80005356:	557d                	li	a0,-1
    80005358:	b7fd                	j	80005346 <argfd+0x4c>

000000008000535a <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000535a:	1101                	addi	sp,sp,-32
    8000535c:	ec06                	sd	ra,24(sp)
    8000535e:	e822                	sd	s0,16(sp)
    80005360:	e426                	sd	s1,8(sp)
    80005362:	1000                	addi	s0,sp,32
    80005364:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005366:	ffffd097          	auipc	ra,0xffffd
    8000536a:	904080e7          	jalr	-1788(ra) # 80001c6a <myproc>
    8000536e:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005370:	0d050793          	addi	a5,a0,208
    80005374:	4501                	li	a0,0
    80005376:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005378:	6398                	ld	a4,0(a5)
    8000537a:	cb19                	beqz	a4,80005390 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000537c:	2505                	addiw	a0,a0,1
    8000537e:	07a1                	addi	a5,a5,8
    80005380:	fed51ce3          	bne	a0,a3,80005378 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005384:	557d                	li	a0,-1
}
    80005386:	60e2                	ld	ra,24(sp)
    80005388:	6442                	ld	s0,16(sp)
    8000538a:	64a2                	ld	s1,8(sp)
    8000538c:	6105                	addi	sp,sp,32
    8000538e:	8082                	ret
      p->ofile[fd] = f;
    80005390:	01a50793          	addi	a5,a0,26
    80005394:	078e                	slli	a5,a5,0x3
    80005396:	963e                	add	a2,a2,a5
    80005398:	e204                	sd	s1,0(a2)
      return fd;
    8000539a:	b7f5                	j	80005386 <fdalloc+0x2c>

000000008000539c <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000539c:	715d                	addi	sp,sp,-80
    8000539e:	e486                	sd	ra,72(sp)
    800053a0:	e0a2                	sd	s0,64(sp)
    800053a2:	fc26                	sd	s1,56(sp)
    800053a4:	f84a                	sd	s2,48(sp)
    800053a6:	f44e                	sd	s3,40(sp)
    800053a8:	f052                	sd	s4,32(sp)
    800053aa:	ec56                	sd	s5,24(sp)
    800053ac:	e85a                	sd	s6,16(sp)
    800053ae:	0880                	addi	s0,sp,80
    800053b0:	8b2e                	mv	s6,a1
    800053b2:	89b2                	mv	s3,a2
    800053b4:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800053b6:	fb040593          	addi	a1,s0,-80
    800053ba:	fffff097          	auipc	ra,0xfffff
    800053be:	e3c080e7          	jalr	-452(ra) # 800041f6 <nameiparent>
    800053c2:	84aa                	mv	s1,a0
    800053c4:	14050f63          	beqz	a0,80005522 <create+0x186>
    return 0;

  ilock(dp);
    800053c8:	ffffe097          	auipc	ra,0xffffe
    800053cc:	66a080e7          	jalr	1642(ra) # 80003a32 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800053d0:	4601                	li	a2,0
    800053d2:	fb040593          	addi	a1,s0,-80
    800053d6:	8526                	mv	a0,s1
    800053d8:	fffff097          	auipc	ra,0xfffff
    800053dc:	b3e080e7          	jalr	-1218(ra) # 80003f16 <dirlookup>
    800053e0:	8aaa                	mv	s5,a0
    800053e2:	c931                	beqz	a0,80005436 <create+0x9a>
    iunlockput(dp);
    800053e4:	8526                	mv	a0,s1
    800053e6:	fffff097          	auipc	ra,0xfffff
    800053ea:	8ae080e7          	jalr	-1874(ra) # 80003c94 <iunlockput>
    ilock(ip);
    800053ee:	8556                	mv	a0,s5
    800053f0:	ffffe097          	auipc	ra,0xffffe
    800053f4:	642080e7          	jalr	1602(ra) # 80003a32 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800053f8:	000b059b          	sext.w	a1,s6
    800053fc:	4789                	li	a5,2
    800053fe:	02f59563          	bne	a1,a5,80005428 <create+0x8c>
    80005402:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdd2c4>
    80005406:	37f9                	addiw	a5,a5,-2
    80005408:	17c2                	slli	a5,a5,0x30
    8000540a:	93c1                	srli	a5,a5,0x30
    8000540c:	4705                	li	a4,1
    8000540e:	00f76d63          	bltu	a4,a5,80005428 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005412:	8556                	mv	a0,s5
    80005414:	60a6                	ld	ra,72(sp)
    80005416:	6406                	ld	s0,64(sp)
    80005418:	74e2                	ld	s1,56(sp)
    8000541a:	7942                	ld	s2,48(sp)
    8000541c:	79a2                	ld	s3,40(sp)
    8000541e:	7a02                	ld	s4,32(sp)
    80005420:	6ae2                	ld	s5,24(sp)
    80005422:	6b42                	ld	s6,16(sp)
    80005424:	6161                	addi	sp,sp,80
    80005426:	8082                	ret
    iunlockput(ip);
    80005428:	8556                	mv	a0,s5
    8000542a:	fffff097          	auipc	ra,0xfffff
    8000542e:	86a080e7          	jalr	-1942(ra) # 80003c94 <iunlockput>
    return 0;
    80005432:	4a81                	li	s5,0
    80005434:	bff9                	j	80005412 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005436:	85da                	mv	a1,s6
    80005438:	4088                	lw	a0,0(s1)
    8000543a:	ffffe097          	auipc	ra,0xffffe
    8000543e:	45c080e7          	jalr	1116(ra) # 80003896 <ialloc>
    80005442:	8a2a                	mv	s4,a0
    80005444:	c539                	beqz	a0,80005492 <create+0xf6>
  ilock(ip);
    80005446:	ffffe097          	auipc	ra,0xffffe
    8000544a:	5ec080e7          	jalr	1516(ra) # 80003a32 <ilock>
  ip->major = major;
    8000544e:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005452:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005456:	4905                	li	s2,1
    80005458:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    8000545c:	8552                	mv	a0,s4
    8000545e:	ffffe097          	auipc	ra,0xffffe
    80005462:	50a080e7          	jalr	1290(ra) # 80003968 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005466:	000b059b          	sext.w	a1,s6
    8000546a:	03258b63          	beq	a1,s2,800054a0 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    8000546e:	004a2603          	lw	a2,4(s4)
    80005472:	fb040593          	addi	a1,s0,-80
    80005476:	8526                	mv	a0,s1
    80005478:	fffff097          	auipc	ra,0xfffff
    8000547c:	cae080e7          	jalr	-850(ra) # 80004126 <dirlink>
    80005480:	06054f63          	bltz	a0,800054fe <create+0x162>
  iunlockput(dp);
    80005484:	8526                	mv	a0,s1
    80005486:	fffff097          	auipc	ra,0xfffff
    8000548a:	80e080e7          	jalr	-2034(ra) # 80003c94 <iunlockput>
  return ip;
    8000548e:	8ad2                	mv	s5,s4
    80005490:	b749                	j	80005412 <create+0x76>
    iunlockput(dp);
    80005492:	8526                	mv	a0,s1
    80005494:	fffff097          	auipc	ra,0xfffff
    80005498:	800080e7          	jalr	-2048(ra) # 80003c94 <iunlockput>
    return 0;
    8000549c:	8ad2                	mv	s5,s4
    8000549e:	bf95                	j	80005412 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800054a0:	004a2603          	lw	a2,4(s4)
    800054a4:	00003597          	auipc	a1,0x3
    800054a8:	28c58593          	addi	a1,a1,652 # 80008730 <syscalls+0x2b0>
    800054ac:	8552                	mv	a0,s4
    800054ae:	fffff097          	auipc	ra,0xfffff
    800054b2:	c78080e7          	jalr	-904(ra) # 80004126 <dirlink>
    800054b6:	04054463          	bltz	a0,800054fe <create+0x162>
    800054ba:	40d0                	lw	a2,4(s1)
    800054bc:	00003597          	auipc	a1,0x3
    800054c0:	27c58593          	addi	a1,a1,636 # 80008738 <syscalls+0x2b8>
    800054c4:	8552                	mv	a0,s4
    800054c6:	fffff097          	auipc	ra,0xfffff
    800054ca:	c60080e7          	jalr	-928(ra) # 80004126 <dirlink>
    800054ce:	02054863          	bltz	a0,800054fe <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    800054d2:	004a2603          	lw	a2,4(s4)
    800054d6:	fb040593          	addi	a1,s0,-80
    800054da:	8526                	mv	a0,s1
    800054dc:	fffff097          	auipc	ra,0xfffff
    800054e0:	c4a080e7          	jalr	-950(ra) # 80004126 <dirlink>
    800054e4:	00054d63          	bltz	a0,800054fe <create+0x162>
    dp->nlink++;  // for ".."
    800054e8:	04a4d783          	lhu	a5,74(s1)
    800054ec:	2785                	addiw	a5,a5,1
    800054ee:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800054f2:	8526                	mv	a0,s1
    800054f4:	ffffe097          	auipc	ra,0xffffe
    800054f8:	474080e7          	jalr	1140(ra) # 80003968 <iupdate>
    800054fc:	b761                	j	80005484 <create+0xe8>
  ip->nlink = 0;
    800054fe:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005502:	8552                	mv	a0,s4
    80005504:	ffffe097          	auipc	ra,0xffffe
    80005508:	464080e7          	jalr	1124(ra) # 80003968 <iupdate>
  iunlockput(ip);
    8000550c:	8552                	mv	a0,s4
    8000550e:	ffffe097          	auipc	ra,0xffffe
    80005512:	786080e7          	jalr	1926(ra) # 80003c94 <iunlockput>
  iunlockput(dp);
    80005516:	8526                	mv	a0,s1
    80005518:	ffffe097          	auipc	ra,0xffffe
    8000551c:	77c080e7          	jalr	1916(ra) # 80003c94 <iunlockput>
  return 0;
    80005520:	bdcd                	j	80005412 <create+0x76>
    return 0;
    80005522:	8aaa                	mv	s5,a0
    80005524:	b5fd                	j	80005412 <create+0x76>

0000000080005526 <sys_dup>:
{
    80005526:	7179                	addi	sp,sp,-48
    80005528:	f406                	sd	ra,40(sp)
    8000552a:	f022                	sd	s0,32(sp)
    8000552c:	ec26                	sd	s1,24(sp)
    8000552e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005530:	fd840613          	addi	a2,s0,-40
    80005534:	4581                	li	a1,0
    80005536:	4501                	li	a0,0
    80005538:	00000097          	auipc	ra,0x0
    8000553c:	dc2080e7          	jalr	-574(ra) # 800052fa <argfd>
    return -1;
    80005540:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005542:	02054363          	bltz	a0,80005568 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005546:	fd843503          	ld	a0,-40(s0)
    8000554a:	00000097          	auipc	ra,0x0
    8000554e:	e10080e7          	jalr	-496(ra) # 8000535a <fdalloc>
    80005552:	84aa                	mv	s1,a0
    return -1;
    80005554:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005556:	00054963          	bltz	a0,80005568 <sys_dup+0x42>
  filedup(f);
    8000555a:	fd843503          	ld	a0,-40(s0)
    8000555e:	fffff097          	auipc	ra,0xfffff
    80005562:	310080e7          	jalr	784(ra) # 8000486e <filedup>
  return fd;
    80005566:	87a6                	mv	a5,s1
}
    80005568:	853e                	mv	a0,a5
    8000556a:	70a2                	ld	ra,40(sp)
    8000556c:	7402                	ld	s0,32(sp)
    8000556e:	64e2                	ld	s1,24(sp)
    80005570:	6145                	addi	sp,sp,48
    80005572:	8082                	ret

0000000080005574 <sys_read>:
{
    80005574:	7179                	addi	sp,sp,-48
    80005576:	f406                	sd	ra,40(sp)
    80005578:	f022                	sd	s0,32(sp)
    8000557a:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000557c:	fd840593          	addi	a1,s0,-40
    80005580:	4505                	li	a0,1
    80005582:	ffffe097          	auipc	ra,0xffffe
    80005586:	836080e7          	jalr	-1994(ra) # 80002db8 <argaddr>
  argint(2, &n);
    8000558a:	fe440593          	addi	a1,s0,-28
    8000558e:	4509                	li	a0,2
    80005590:	ffffe097          	auipc	ra,0xffffe
    80005594:	808080e7          	jalr	-2040(ra) # 80002d98 <argint>
  if(argfd(0, 0, &f) < 0)
    80005598:	fe840613          	addi	a2,s0,-24
    8000559c:	4581                	li	a1,0
    8000559e:	4501                	li	a0,0
    800055a0:	00000097          	auipc	ra,0x0
    800055a4:	d5a080e7          	jalr	-678(ra) # 800052fa <argfd>
    800055a8:	87aa                	mv	a5,a0
    return -1;
    800055aa:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800055ac:	0007cc63          	bltz	a5,800055c4 <sys_read+0x50>
  return fileread(f, p, n);
    800055b0:	fe442603          	lw	a2,-28(s0)
    800055b4:	fd843583          	ld	a1,-40(s0)
    800055b8:	fe843503          	ld	a0,-24(s0)
    800055bc:	fffff097          	auipc	ra,0xfffff
    800055c0:	43e080e7          	jalr	1086(ra) # 800049fa <fileread>
}
    800055c4:	70a2                	ld	ra,40(sp)
    800055c6:	7402                	ld	s0,32(sp)
    800055c8:	6145                	addi	sp,sp,48
    800055ca:	8082                	ret

00000000800055cc <sys_write>:
{
    800055cc:	7179                	addi	sp,sp,-48
    800055ce:	f406                	sd	ra,40(sp)
    800055d0:	f022                	sd	s0,32(sp)
    800055d2:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800055d4:	fd840593          	addi	a1,s0,-40
    800055d8:	4505                	li	a0,1
    800055da:	ffffd097          	auipc	ra,0xffffd
    800055de:	7de080e7          	jalr	2014(ra) # 80002db8 <argaddr>
  argint(2, &n);
    800055e2:	fe440593          	addi	a1,s0,-28
    800055e6:	4509                	li	a0,2
    800055e8:	ffffd097          	auipc	ra,0xffffd
    800055ec:	7b0080e7          	jalr	1968(ra) # 80002d98 <argint>
  if(argfd(0, 0, &f) < 0)
    800055f0:	fe840613          	addi	a2,s0,-24
    800055f4:	4581                	li	a1,0
    800055f6:	4501                	li	a0,0
    800055f8:	00000097          	auipc	ra,0x0
    800055fc:	d02080e7          	jalr	-766(ra) # 800052fa <argfd>
    80005600:	87aa                	mv	a5,a0
    return -1;
    80005602:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005604:	0007cc63          	bltz	a5,8000561c <sys_write+0x50>
  return filewrite(f, p, n);
    80005608:	fe442603          	lw	a2,-28(s0)
    8000560c:	fd843583          	ld	a1,-40(s0)
    80005610:	fe843503          	ld	a0,-24(s0)
    80005614:	fffff097          	auipc	ra,0xfffff
    80005618:	4a8080e7          	jalr	1192(ra) # 80004abc <filewrite>
}
    8000561c:	70a2                	ld	ra,40(sp)
    8000561e:	7402                	ld	s0,32(sp)
    80005620:	6145                	addi	sp,sp,48
    80005622:	8082                	ret

0000000080005624 <sys_close>:
{
    80005624:	1101                	addi	sp,sp,-32
    80005626:	ec06                	sd	ra,24(sp)
    80005628:	e822                	sd	s0,16(sp)
    8000562a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000562c:	fe040613          	addi	a2,s0,-32
    80005630:	fec40593          	addi	a1,s0,-20
    80005634:	4501                	li	a0,0
    80005636:	00000097          	auipc	ra,0x0
    8000563a:	cc4080e7          	jalr	-828(ra) # 800052fa <argfd>
    return -1;
    8000563e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005640:	02054463          	bltz	a0,80005668 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005644:	ffffc097          	auipc	ra,0xffffc
    80005648:	626080e7          	jalr	1574(ra) # 80001c6a <myproc>
    8000564c:	fec42783          	lw	a5,-20(s0)
    80005650:	07e9                	addi	a5,a5,26
    80005652:	078e                	slli	a5,a5,0x3
    80005654:	97aa                	add	a5,a5,a0
    80005656:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000565a:	fe043503          	ld	a0,-32(s0)
    8000565e:	fffff097          	auipc	ra,0xfffff
    80005662:	262080e7          	jalr	610(ra) # 800048c0 <fileclose>
  return 0;
    80005666:	4781                	li	a5,0
}
    80005668:	853e                	mv	a0,a5
    8000566a:	60e2                	ld	ra,24(sp)
    8000566c:	6442                	ld	s0,16(sp)
    8000566e:	6105                	addi	sp,sp,32
    80005670:	8082                	ret

0000000080005672 <sys_fstat>:
{
    80005672:	1101                	addi	sp,sp,-32
    80005674:	ec06                	sd	ra,24(sp)
    80005676:	e822                	sd	s0,16(sp)
    80005678:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    8000567a:	fe040593          	addi	a1,s0,-32
    8000567e:	4505                	li	a0,1
    80005680:	ffffd097          	auipc	ra,0xffffd
    80005684:	738080e7          	jalr	1848(ra) # 80002db8 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005688:	fe840613          	addi	a2,s0,-24
    8000568c:	4581                	li	a1,0
    8000568e:	4501                	li	a0,0
    80005690:	00000097          	auipc	ra,0x0
    80005694:	c6a080e7          	jalr	-918(ra) # 800052fa <argfd>
    80005698:	87aa                	mv	a5,a0
    return -1;
    8000569a:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000569c:	0007ca63          	bltz	a5,800056b0 <sys_fstat+0x3e>
  return filestat(f, st);
    800056a0:	fe043583          	ld	a1,-32(s0)
    800056a4:	fe843503          	ld	a0,-24(s0)
    800056a8:	fffff097          	auipc	ra,0xfffff
    800056ac:	2e0080e7          	jalr	736(ra) # 80004988 <filestat>
}
    800056b0:	60e2                	ld	ra,24(sp)
    800056b2:	6442                	ld	s0,16(sp)
    800056b4:	6105                	addi	sp,sp,32
    800056b6:	8082                	ret

00000000800056b8 <sys_link>:
{
    800056b8:	7169                	addi	sp,sp,-304
    800056ba:	f606                	sd	ra,296(sp)
    800056bc:	f222                	sd	s0,288(sp)
    800056be:	ee26                	sd	s1,280(sp)
    800056c0:	ea4a                	sd	s2,272(sp)
    800056c2:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056c4:	08000613          	li	a2,128
    800056c8:	ed040593          	addi	a1,s0,-304
    800056cc:	4501                	li	a0,0
    800056ce:	ffffd097          	auipc	ra,0xffffd
    800056d2:	70a080e7          	jalr	1802(ra) # 80002dd8 <argstr>
    return -1;
    800056d6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056d8:	10054e63          	bltz	a0,800057f4 <sys_link+0x13c>
    800056dc:	08000613          	li	a2,128
    800056e0:	f5040593          	addi	a1,s0,-176
    800056e4:	4505                	li	a0,1
    800056e6:	ffffd097          	auipc	ra,0xffffd
    800056ea:	6f2080e7          	jalr	1778(ra) # 80002dd8 <argstr>
    return -1;
    800056ee:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056f0:	10054263          	bltz	a0,800057f4 <sys_link+0x13c>
  begin_op();
    800056f4:	fffff097          	auipc	ra,0xfffff
    800056f8:	d00080e7          	jalr	-768(ra) # 800043f4 <begin_op>
  if((ip = namei(old)) == 0){
    800056fc:	ed040513          	addi	a0,s0,-304
    80005700:	fffff097          	auipc	ra,0xfffff
    80005704:	ad8080e7          	jalr	-1320(ra) # 800041d8 <namei>
    80005708:	84aa                	mv	s1,a0
    8000570a:	c551                	beqz	a0,80005796 <sys_link+0xde>
  ilock(ip);
    8000570c:	ffffe097          	auipc	ra,0xffffe
    80005710:	326080e7          	jalr	806(ra) # 80003a32 <ilock>
  if(ip->type == T_DIR){
    80005714:	04449703          	lh	a4,68(s1)
    80005718:	4785                	li	a5,1
    8000571a:	08f70463          	beq	a4,a5,800057a2 <sys_link+0xea>
  ip->nlink++;
    8000571e:	04a4d783          	lhu	a5,74(s1)
    80005722:	2785                	addiw	a5,a5,1
    80005724:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005728:	8526                	mv	a0,s1
    8000572a:	ffffe097          	auipc	ra,0xffffe
    8000572e:	23e080e7          	jalr	574(ra) # 80003968 <iupdate>
  iunlock(ip);
    80005732:	8526                	mv	a0,s1
    80005734:	ffffe097          	auipc	ra,0xffffe
    80005738:	3c0080e7          	jalr	960(ra) # 80003af4 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000573c:	fd040593          	addi	a1,s0,-48
    80005740:	f5040513          	addi	a0,s0,-176
    80005744:	fffff097          	auipc	ra,0xfffff
    80005748:	ab2080e7          	jalr	-1358(ra) # 800041f6 <nameiparent>
    8000574c:	892a                	mv	s2,a0
    8000574e:	c935                	beqz	a0,800057c2 <sys_link+0x10a>
  ilock(dp);
    80005750:	ffffe097          	auipc	ra,0xffffe
    80005754:	2e2080e7          	jalr	738(ra) # 80003a32 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005758:	00092703          	lw	a4,0(s2)
    8000575c:	409c                	lw	a5,0(s1)
    8000575e:	04f71d63          	bne	a4,a5,800057b8 <sys_link+0x100>
    80005762:	40d0                	lw	a2,4(s1)
    80005764:	fd040593          	addi	a1,s0,-48
    80005768:	854a                	mv	a0,s2
    8000576a:	fffff097          	auipc	ra,0xfffff
    8000576e:	9bc080e7          	jalr	-1604(ra) # 80004126 <dirlink>
    80005772:	04054363          	bltz	a0,800057b8 <sys_link+0x100>
  iunlockput(dp);
    80005776:	854a                	mv	a0,s2
    80005778:	ffffe097          	auipc	ra,0xffffe
    8000577c:	51c080e7          	jalr	1308(ra) # 80003c94 <iunlockput>
  iput(ip);
    80005780:	8526                	mv	a0,s1
    80005782:	ffffe097          	auipc	ra,0xffffe
    80005786:	46a080e7          	jalr	1130(ra) # 80003bec <iput>
  end_op();
    8000578a:	fffff097          	auipc	ra,0xfffff
    8000578e:	cea080e7          	jalr	-790(ra) # 80004474 <end_op>
  return 0;
    80005792:	4781                	li	a5,0
    80005794:	a085                	j	800057f4 <sys_link+0x13c>
    end_op();
    80005796:	fffff097          	auipc	ra,0xfffff
    8000579a:	cde080e7          	jalr	-802(ra) # 80004474 <end_op>
    return -1;
    8000579e:	57fd                	li	a5,-1
    800057a0:	a891                	j	800057f4 <sys_link+0x13c>
    iunlockput(ip);
    800057a2:	8526                	mv	a0,s1
    800057a4:	ffffe097          	auipc	ra,0xffffe
    800057a8:	4f0080e7          	jalr	1264(ra) # 80003c94 <iunlockput>
    end_op();
    800057ac:	fffff097          	auipc	ra,0xfffff
    800057b0:	cc8080e7          	jalr	-824(ra) # 80004474 <end_op>
    return -1;
    800057b4:	57fd                	li	a5,-1
    800057b6:	a83d                	j	800057f4 <sys_link+0x13c>
    iunlockput(dp);
    800057b8:	854a                	mv	a0,s2
    800057ba:	ffffe097          	auipc	ra,0xffffe
    800057be:	4da080e7          	jalr	1242(ra) # 80003c94 <iunlockput>
  ilock(ip);
    800057c2:	8526                	mv	a0,s1
    800057c4:	ffffe097          	auipc	ra,0xffffe
    800057c8:	26e080e7          	jalr	622(ra) # 80003a32 <ilock>
  ip->nlink--;
    800057cc:	04a4d783          	lhu	a5,74(s1)
    800057d0:	37fd                	addiw	a5,a5,-1
    800057d2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800057d6:	8526                	mv	a0,s1
    800057d8:	ffffe097          	auipc	ra,0xffffe
    800057dc:	190080e7          	jalr	400(ra) # 80003968 <iupdate>
  iunlockput(ip);
    800057e0:	8526                	mv	a0,s1
    800057e2:	ffffe097          	auipc	ra,0xffffe
    800057e6:	4b2080e7          	jalr	1202(ra) # 80003c94 <iunlockput>
  end_op();
    800057ea:	fffff097          	auipc	ra,0xfffff
    800057ee:	c8a080e7          	jalr	-886(ra) # 80004474 <end_op>
  return -1;
    800057f2:	57fd                	li	a5,-1
}
    800057f4:	853e                	mv	a0,a5
    800057f6:	70b2                	ld	ra,296(sp)
    800057f8:	7412                	ld	s0,288(sp)
    800057fa:	64f2                	ld	s1,280(sp)
    800057fc:	6952                	ld	s2,272(sp)
    800057fe:	6155                	addi	sp,sp,304
    80005800:	8082                	ret

0000000080005802 <sys_unlink>:
{
    80005802:	7151                	addi	sp,sp,-240
    80005804:	f586                	sd	ra,232(sp)
    80005806:	f1a2                	sd	s0,224(sp)
    80005808:	eda6                	sd	s1,216(sp)
    8000580a:	e9ca                	sd	s2,208(sp)
    8000580c:	e5ce                	sd	s3,200(sp)
    8000580e:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005810:	08000613          	li	a2,128
    80005814:	f3040593          	addi	a1,s0,-208
    80005818:	4501                	li	a0,0
    8000581a:	ffffd097          	auipc	ra,0xffffd
    8000581e:	5be080e7          	jalr	1470(ra) # 80002dd8 <argstr>
    80005822:	18054163          	bltz	a0,800059a4 <sys_unlink+0x1a2>
  begin_op();
    80005826:	fffff097          	auipc	ra,0xfffff
    8000582a:	bce080e7          	jalr	-1074(ra) # 800043f4 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000582e:	fb040593          	addi	a1,s0,-80
    80005832:	f3040513          	addi	a0,s0,-208
    80005836:	fffff097          	auipc	ra,0xfffff
    8000583a:	9c0080e7          	jalr	-1600(ra) # 800041f6 <nameiparent>
    8000583e:	84aa                	mv	s1,a0
    80005840:	c979                	beqz	a0,80005916 <sys_unlink+0x114>
  ilock(dp);
    80005842:	ffffe097          	auipc	ra,0xffffe
    80005846:	1f0080e7          	jalr	496(ra) # 80003a32 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000584a:	00003597          	auipc	a1,0x3
    8000584e:	ee658593          	addi	a1,a1,-282 # 80008730 <syscalls+0x2b0>
    80005852:	fb040513          	addi	a0,s0,-80
    80005856:	ffffe097          	auipc	ra,0xffffe
    8000585a:	6a6080e7          	jalr	1702(ra) # 80003efc <namecmp>
    8000585e:	14050a63          	beqz	a0,800059b2 <sys_unlink+0x1b0>
    80005862:	00003597          	auipc	a1,0x3
    80005866:	ed658593          	addi	a1,a1,-298 # 80008738 <syscalls+0x2b8>
    8000586a:	fb040513          	addi	a0,s0,-80
    8000586e:	ffffe097          	auipc	ra,0xffffe
    80005872:	68e080e7          	jalr	1678(ra) # 80003efc <namecmp>
    80005876:	12050e63          	beqz	a0,800059b2 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000587a:	f2c40613          	addi	a2,s0,-212
    8000587e:	fb040593          	addi	a1,s0,-80
    80005882:	8526                	mv	a0,s1
    80005884:	ffffe097          	auipc	ra,0xffffe
    80005888:	692080e7          	jalr	1682(ra) # 80003f16 <dirlookup>
    8000588c:	892a                	mv	s2,a0
    8000588e:	12050263          	beqz	a0,800059b2 <sys_unlink+0x1b0>
  ilock(ip);
    80005892:	ffffe097          	auipc	ra,0xffffe
    80005896:	1a0080e7          	jalr	416(ra) # 80003a32 <ilock>
  if(ip->nlink < 1)
    8000589a:	04a91783          	lh	a5,74(s2)
    8000589e:	08f05263          	blez	a5,80005922 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800058a2:	04491703          	lh	a4,68(s2)
    800058a6:	4785                	li	a5,1
    800058a8:	08f70563          	beq	a4,a5,80005932 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800058ac:	4641                	li	a2,16
    800058ae:	4581                	li	a1,0
    800058b0:	fc040513          	addi	a0,s0,-64
    800058b4:	ffffb097          	auipc	ra,0xffffb
    800058b8:	41e080e7          	jalr	1054(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800058bc:	4741                	li	a4,16
    800058be:	f2c42683          	lw	a3,-212(s0)
    800058c2:	fc040613          	addi	a2,s0,-64
    800058c6:	4581                	li	a1,0
    800058c8:	8526                	mv	a0,s1
    800058ca:	ffffe097          	auipc	ra,0xffffe
    800058ce:	514080e7          	jalr	1300(ra) # 80003dde <writei>
    800058d2:	47c1                	li	a5,16
    800058d4:	0af51563          	bne	a0,a5,8000597e <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800058d8:	04491703          	lh	a4,68(s2)
    800058dc:	4785                	li	a5,1
    800058de:	0af70863          	beq	a4,a5,8000598e <sys_unlink+0x18c>
  iunlockput(dp);
    800058e2:	8526                	mv	a0,s1
    800058e4:	ffffe097          	auipc	ra,0xffffe
    800058e8:	3b0080e7          	jalr	944(ra) # 80003c94 <iunlockput>
  ip->nlink--;
    800058ec:	04a95783          	lhu	a5,74(s2)
    800058f0:	37fd                	addiw	a5,a5,-1
    800058f2:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800058f6:	854a                	mv	a0,s2
    800058f8:	ffffe097          	auipc	ra,0xffffe
    800058fc:	070080e7          	jalr	112(ra) # 80003968 <iupdate>
  iunlockput(ip);
    80005900:	854a                	mv	a0,s2
    80005902:	ffffe097          	auipc	ra,0xffffe
    80005906:	392080e7          	jalr	914(ra) # 80003c94 <iunlockput>
  end_op();
    8000590a:	fffff097          	auipc	ra,0xfffff
    8000590e:	b6a080e7          	jalr	-1174(ra) # 80004474 <end_op>
  return 0;
    80005912:	4501                	li	a0,0
    80005914:	a84d                	j	800059c6 <sys_unlink+0x1c4>
    end_op();
    80005916:	fffff097          	auipc	ra,0xfffff
    8000591a:	b5e080e7          	jalr	-1186(ra) # 80004474 <end_op>
    return -1;
    8000591e:	557d                	li	a0,-1
    80005920:	a05d                	j	800059c6 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005922:	00003517          	auipc	a0,0x3
    80005926:	e1e50513          	addi	a0,a0,-482 # 80008740 <syscalls+0x2c0>
    8000592a:	ffffb097          	auipc	ra,0xffffb
    8000592e:	c14080e7          	jalr	-1004(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005932:	04c92703          	lw	a4,76(s2)
    80005936:	02000793          	li	a5,32
    8000593a:	f6e7f9e3          	bgeu	a5,a4,800058ac <sys_unlink+0xaa>
    8000593e:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005942:	4741                	li	a4,16
    80005944:	86ce                	mv	a3,s3
    80005946:	f1840613          	addi	a2,s0,-232
    8000594a:	4581                	li	a1,0
    8000594c:	854a                	mv	a0,s2
    8000594e:	ffffe097          	auipc	ra,0xffffe
    80005952:	398080e7          	jalr	920(ra) # 80003ce6 <readi>
    80005956:	47c1                	li	a5,16
    80005958:	00f51b63          	bne	a0,a5,8000596e <sys_unlink+0x16c>
    if(de.inum != 0)
    8000595c:	f1845783          	lhu	a5,-232(s0)
    80005960:	e7a1                	bnez	a5,800059a8 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005962:	29c1                	addiw	s3,s3,16
    80005964:	04c92783          	lw	a5,76(s2)
    80005968:	fcf9ede3          	bltu	s3,a5,80005942 <sys_unlink+0x140>
    8000596c:	b781                	j	800058ac <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000596e:	00003517          	auipc	a0,0x3
    80005972:	dea50513          	addi	a0,a0,-534 # 80008758 <syscalls+0x2d8>
    80005976:	ffffb097          	auipc	ra,0xffffb
    8000597a:	bc8080e7          	jalr	-1080(ra) # 8000053e <panic>
    panic("unlink: writei");
    8000597e:	00003517          	auipc	a0,0x3
    80005982:	df250513          	addi	a0,a0,-526 # 80008770 <syscalls+0x2f0>
    80005986:	ffffb097          	auipc	ra,0xffffb
    8000598a:	bb8080e7          	jalr	-1096(ra) # 8000053e <panic>
    dp->nlink--;
    8000598e:	04a4d783          	lhu	a5,74(s1)
    80005992:	37fd                	addiw	a5,a5,-1
    80005994:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005998:	8526                	mv	a0,s1
    8000599a:	ffffe097          	auipc	ra,0xffffe
    8000599e:	fce080e7          	jalr	-50(ra) # 80003968 <iupdate>
    800059a2:	b781                	j	800058e2 <sys_unlink+0xe0>
    return -1;
    800059a4:	557d                	li	a0,-1
    800059a6:	a005                	j	800059c6 <sys_unlink+0x1c4>
    iunlockput(ip);
    800059a8:	854a                	mv	a0,s2
    800059aa:	ffffe097          	auipc	ra,0xffffe
    800059ae:	2ea080e7          	jalr	746(ra) # 80003c94 <iunlockput>
  iunlockput(dp);
    800059b2:	8526                	mv	a0,s1
    800059b4:	ffffe097          	auipc	ra,0xffffe
    800059b8:	2e0080e7          	jalr	736(ra) # 80003c94 <iunlockput>
  end_op();
    800059bc:	fffff097          	auipc	ra,0xfffff
    800059c0:	ab8080e7          	jalr	-1352(ra) # 80004474 <end_op>
  return -1;
    800059c4:	557d                	li	a0,-1
}
    800059c6:	70ae                	ld	ra,232(sp)
    800059c8:	740e                	ld	s0,224(sp)
    800059ca:	64ee                	ld	s1,216(sp)
    800059cc:	694e                	ld	s2,208(sp)
    800059ce:	69ae                	ld	s3,200(sp)
    800059d0:	616d                	addi	sp,sp,240
    800059d2:	8082                	ret

00000000800059d4 <sys_open>:

uint64
sys_open(void)
{
    800059d4:	7131                	addi	sp,sp,-192
    800059d6:	fd06                	sd	ra,184(sp)
    800059d8:	f922                	sd	s0,176(sp)
    800059da:	f526                	sd	s1,168(sp)
    800059dc:	f14a                	sd	s2,160(sp)
    800059de:	ed4e                	sd	s3,152(sp)
    800059e0:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    800059e2:	f4c40593          	addi	a1,s0,-180
    800059e6:	4505                	li	a0,1
    800059e8:	ffffd097          	auipc	ra,0xffffd
    800059ec:	3b0080e7          	jalr	944(ra) # 80002d98 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    800059f0:	08000613          	li	a2,128
    800059f4:	f5040593          	addi	a1,s0,-176
    800059f8:	4501                	li	a0,0
    800059fa:	ffffd097          	auipc	ra,0xffffd
    800059fe:	3de080e7          	jalr	990(ra) # 80002dd8 <argstr>
    80005a02:	87aa                	mv	a5,a0
    return -1;
    80005a04:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005a06:	0a07c963          	bltz	a5,80005ab8 <sys_open+0xe4>

  begin_op();
    80005a0a:	fffff097          	auipc	ra,0xfffff
    80005a0e:	9ea080e7          	jalr	-1558(ra) # 800043f4 <begin_op>

  if(omode & O_CREATE){
    80005a12:	f4c42783          	lw	a5,-180(s0)
    80005a16:	2007f793          	andi	a5,a5,512
    80005a1a:	cfc5                	beqz	a5,80005ad2 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005a1c:	4681                	li	a3,0
    80005a1e:	4601                	li	a2,0
    80005a20:	4589                	li	a1,2
    80005a22:	f5040513          	addi	a0,s0,-176
    80005a26:	00000097          	auipc	ra,0x0
    80005a2a:	976080e7          	jalr	-1674(ra) # 8000539c <create>
    80005a2e:	84aa                	mv	s1,a0
    if(ip == 0){
    80005a30:	c959                	beqz	a0,80005ac6 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005a32:	04449703          	lh	a4,68(s1)
    80005a36:	478d                	li	a5,3
    80005a38:	00f71763          	bne	a4,a5,80005a46 <sys_open+0x72>
    80005a3c:	0464d703          	lhu	a4,70(s1)
    80005a40:	47a5                	li	a5,9
    80005a42:	0ce7ed63          	bltu	a5,a4,80005b1c <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005a46:	fffff097          	auipc	ra,0xfffff
    80005a4a:	dbe080e7          	jalr	-578(ra) # 80004804 <filealloc>
    80005a4e:	89aa                	mv	s3,a0
    80005a50:	10050363          	beqz	a0,80005b56 <sys_open+0x182>
    80005a54:	00000097          	auipc	ra,0x0
    80005a58:	906080e7          	jalr	-1786(ra) # 8000535a <fdalloc>
    80005a5c:	892a                	mv	s2,a0
    80005a5e:	0e054763          	bltz	a0,80005b4c <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005a62:	04449703          	lh	a4,68(s1)
    80005a66:	478d                	li	a5,3
    80005a68:	0cf70563          	beq	a4,a5,80005b32 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005a6c:	4789                	li	a5,2
    80005a6e:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005a72:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005a76:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005a7a:	f4c42783          	lw	a5,-180(s0)
    80005a7e:	0017c713          	xori	a4,a5,1
    80005a82:	8b05                	andi	a4,a4,1
    80005a84:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005a88:	0037f713          	andi	a4,a5,3
    80005a8c:	00e03733          	snez	a4,a4
    80005a90:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005a94:	4007f793          	andi	a5,a5,1024
    80005a98:	c791                	beqz	a5,80005aa4 <sys_open+0xd0>
    80005a9a:	04449703          	lh	a4,68(s1)
    80005a9e:	4789                	li	a5,2
    80005aa0:	0af70063          	beq	a4,a5,80005b40 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005aa4:	8526                	mv	a0,s1
    80005aa6:	ffffe097          	auipc	ra,0xffffe
    80005aaa:	04e080e7          	jalr	78(ra) # 80003af4 <iunlock>
  end_op();
    80005aae:	fffff097          	auipc	ra,0xfffff
    80005ab2:	9c6080e7          	jalr	-1594(ra) # 80004474 <end_op>

  return fd;
    80005ab6:	854a                	mv	a0,s2
}
    80005ab8:	70ea                	ld	ra,184(sp)
    80005aba:	744a                	ld	s0,176(sp)
    80005abc:	74aa                	ld	s1,168(sp)
    80005abe:	790a                	ld	s2,160(sp)
    80005ac0:	69ea                	ld	s3,152(sp)
    80005ac2:	6129                	addi	sp,sp,192
    80005ac4:	8082                	ret
      end_op();
    80005ac6:	fffff097          	auipc	ra,0xfffff
    80005aca:	9ae080e7          	jalr	-1618(ra) # 80004474 <end_op>
      return -1;
    80005ace:	557d                	li	a0,-1
    80005ad0:	b7e5                	j	80005ab8 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005ad2:	f5040513          	addi	a0,s0,-176
    80005ad6:	ffffe097          	auipc	ra,0xffffe
    80005ada:	702080e7          	jalr	1794(ra) # 800041d8 <namei>
    80005ade:	84aa                	mv	s1,a0
    80005ae0:	c905                	beqz	a0,80005b10 <sys_open+0x13c>
    ilock(ip);
    80005ae2:	ffffe097          	auipc	ra,0xffffe
    80005ae6:	f50080e7          	jalr	-176(ra) # 80003a32 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005aea:	04449703          	lh	a4,68(s1)
    80005aee:	4785                	li	a5,1
    80005af0:	f4f711e3          	bne	a4,a5,80005a32 <sys_open+0x5e>
    80005af4:	f4c42783          	lw	a5,-180(s0)
    80005af8:	d7b9                	beqz	a5,80005a46 <sys_open+0x72>
      iunlockput(ip);
    80005afa:	8526                	mv	a0,s1
    80005afc:	ffffe097          	auipc	ra,0xffffe
    80005b00:	198080e7          	jalr	408(ra) # 80003c94 <iunlockput>
      end_op();
    80005b04:	fffff097          	auipc	ra,0xfffff
    80005b08:	970080e7          	jalr	-1680(ra) # 80004474 <end_op>
      return -1;
    80005b0c:	557d                	li	a0,-1
    80005b0e:	b76d                	j	80005ab8 <sys_open+0xe4>
      end_op();
    80005b10:	fffff097          	auipc	ra,0xfffff
    80005b14:	964080e7          	jalr	-1692(ra) # 80004474 <end_op>
      return -1;
    80005b18:	557d                	li	a0,-1
    80005b1a:	bf79                	j	80005ab8 <sys_open+0xe4>
    iunlockput(ip);
    80005b1c:	8526                	mv	a0,s1
    80005b1e:	ffffe097          	auipc	ra,0xffffe
    80005b22:	176080e7          	jalr	374(ra) # 80003c94 <iunlockput>
    end_op();
    80005b26:	fffff097          	auipc	ra,0xfffff
    80005b2a:	94e080e7          	jalr	-1714(ra) # 80004474 <end_op>
    return -1;
    80005b2e:	557d                	li	a0,-1
    80005b30:	b761                	j	80005ab8 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005b32:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005b36:	04649783          	lh	a5,70(s1)
    80005b3a:	02f99223          	sh	a5,36(s3)
    80005b3e:	bf25                	j	80005a76 <sys_open+0xa2>
    itrunc(ip);
    80005b40:	8526                	mv	a0,s1
    80005b42:	ffffe097          	auipc	ra,0xffffe
    80005b46:	ffe080e7          	jalr	-2(ra) # 80003b40 <itrunc>
    80005b4a:	bfa9                	j	80005aa4 <sys_open+0xd0>
      fileclose(f);
    80005b4c:	854e                	mv	a0,s3
    80005b4e:	fffff097          	auipc	ra,0xfffff
    80005b52:	d72080e7          	jalr	-654(ra) # 800048c0 <fileclose>
    iunlockput(ip);
    80005b56:	8526                	mv	a0,s1
    80005b58:	ffffe097          	auipc	ra,0xffffe
    80005b5c:	13c080e7          	jalr	316(ra) # 80003c94 <iunlockput>
    end_op();
    80005b60:	fffff097          	auipc	ra,0xfffff
    80005b64:	914080e7          	jalr	-1772(ra) # 80004474 <end_op>
    return -1;
    80005b68:	557d                	li	a0,-1
    80005b6a:	b7b9                	j	80005ab8 <sys_open+0xe4>

0000000080005b6c <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005b6c:	7175                	addi	sp,sp,-144
    80005b6e:	e506                	sd	ra,136(sp)
    80005b70:	e122                	sd	s0,128(sp)
    80005b72:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005b74:	fffff097          	auipc	ra,0xfffff
    80005b78:	880080e7          	jalr	-1920(ra) # 800043f4 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005b7c:	08000613          	li	a2,128
    80005b80:	f7040593          	addi	a1,s0,-144
    80005b84:	4501                	li	a0,0
    80005b86:	ffffd097          	auipc	ra,0xffffd
    80005b8a:	252080e7          	jalr	594(ra) # 80002dd8 <argstr>
    80005b8e:	02054963          	bltz	a0,80005bc0 <sys_mkdir+0x54>
    80005b92:	4681                	li	a3,0
    80005b94:	4601                	li	a2,0
    80005b96:	4585                	li	a1,1
    80005b98:	f7040513          	addi	a0,s0,-144
    80005b9c:	00000097          	auipc	ra,0x0
    80005ba0:	800080e7          	jalr	-2048(ra) # 8000539c <create>
    80005ba4:	cd11                	beqz	a0,80005bc0 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005ba6:	ffffe097          	auipc	ra,0xffffe
    80005baa:	0ee080e7          	jalr	238(ra) # 80003c94 <iunlockput>
  end_op();
    80005bae:	fffff097          	auipc	ra,0xfffff
    80005bb2:	8c6080e7          	jalr	-1850(ra) # 80004474 <end_op>
  return 0;
    80005bb6:	4501                	li	a0,0
}
    80005bb8:	60aa                	ld	ra,136(sp)
    80005bba:	640a                	ld	s0,128(sp)
    80005bbc:	6149                	addi	sp,sp,144
    80005bbe:	8082                	ret
    end_op();
    80005bc0:	fffff097          	auipc	ra,0xfffff
    80005bc4:	8b4080e7          	jalr	-1868(ra) # 80004474 <end_op>
    return -1;
    80005bc8:	557d                	li	a0,-1
    80005bca:	b7fd                	j	80005bb8 <sys_mkdir+0x4c>

0000000080005bcc <sys_mknod>:

uint64
sys_mknod(void)
{
    80005bcc:	7135                	addi	sp,sp,-160
    80005bce:	ed06                	sd	ra,152(sp)
    80005bd0:	e922                	sd	s0,144(sp)
    80005bd2:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005bd4:	fffff097          	auipc	ra,0xfffff
    80005bd8:	820080e7          	jalr	-2016(ra) # 800043f4 <begin_op>
  argint(1, &major);
    80005bdc:	f6c40593          	addi	a1,s0,-148
    80005be0:	4505                	li	a0,1
    80005be2:	ffffd097          	auipc	ra,0xffffd
    80005be6:	1b6080e7          	jalr	438(ra) # 80002d98 <argint>
  argint(2, &minor);
    80005bea:	f6840593          	addi	a1,s0,-152
    80005bee:	4509                	li	a0,2
    80005bf0:	ffffd097          	auipc	ra,0xffffd
    80005bf4:	1a8080e7          	jalr	424(ra) # 80002d98 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005bf8:	08000613          	li	a2,128
    80005bfc:	f7040593          	addi	a1,s0,-144
    80005c00:	4501                	li	a0,0
    80005c02:	ffffd097          	auipc	ra,0xffffd
    80005c06:	1d6080e7          	jalr	470(ra) # 80002dd8 <argstr>
    80005c0a:	02054b63          	bltz	a0,80005c40 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005c0e:	f6841683          	lh	a3,-152(s0)
    80005c12:	f6c41603          	lh	a2,-148(s0)
    80005c16:	458d                	li	a1,3
    80005c18:	f7040513          	addi	a0,s0,-144
    80005c1c:	fffff097          	auipc	ra,0xfffff
    80005c20:	780080e7          	jalr	1920(ra) # 8000539c <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005c24:	cd11                	beqz	a0,80005c40 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005c26:	ffffe097          	auipc	ra,0xffffe
    80005c2a:	06e080e7          	jalr	110(ra) # 80003c94 <iunlockput>
  end_op();
    80005c2e:	fffff097          	auipc	ra,0xfffff
    80005c32:	846080e7          	jalr	-1978(ra) # 80004474 <end_op>
  return 0;
    80005c36:	4501                	li	a0,0
}
    80005c38:	60ea                	ld	ra,152(sp)
    80005c3a:	644a                	ld	s0,144(sp)
    80005c3c:	610d                	addi	sp,sp,160
    80005c3e:	8082                	ret
    end_op();
    80005c40:	fffff097          	auipc	ra,0xfffff
    80005c44:	834080e7          	jalr	-1996(ra) # 80004474 <end_op>
    return -1;
    80005c48:	557d                	li	a0,-1
    80005c4a:	b7fd                	j	80005c38 <sys_mknod+0x6c>

0000000080005c4c <sys_chdir>:

uint64
sys_chdir(void)
{
    80005c4c:	7135                	addi	sp,sp,-160
    80005c4e:	ed06                	sd	ra,152(sp)
    80005c50:	e922                	sd	s0,144(sp)
    80005c52:	e526                	sd	s1,136(sp)
    80005c54:	e14a                	sd	s2,128(sp)
    80005c56:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005c58:	ffffc097          	auipc	ra,0xffffc
    80005c5c:	012080e7          	jalr	18(ra) # 80001c6a <myproc>
    80005c60:	892a                	mv	s2,a0
  
  begin_op();
    80005c62:	ffffe097          	auipc	ra,0xffffe
    80005c66:	792080e7          	jalr	1938(ra) # 800043f4 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005c6a:	08000613          	li	a2,128
    80005c6e:	f6040593          	addi	a1,s0,-160
    80005c72:	4501                	li	a0,0
    80005c74:	ffffd097          	auipc	ra,0xffffd
    80005c78:	164080e7          	jalr	356(ra) # 80002dd8 <argstr>
    80005c7c:	04054b63          	bltz	a0,80005cd2 <sys_chdir+0x86>
    80005c80:	f6040513          	addi	a0,s0,-160
    80005c84:	ffffe097          	auipc	ra,0xffffe
    80005c88:	554080e7          	jalr	1364(ra) # 800041d8 <namei>
    80005c8c:	84aa                	mv	s1,a0
    80005c8e:	c131                	beqz	a0,80005cd2 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005c90:	ffffe097          	auipc	ra,0xffffe
    80005c94:	da2080e7          	jalr	-606(ra) # 80003a32 <ilock>
  if(ip->type != T_DIR){
    80005c98:	04449703          	lh	a4,68(s1)
    80005c9c:	4785                	li	a5,1
    80005c9e:	04f71063          	bne	a4,a5,80005cde <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005ca2:	8526                	mv	a0,s1
    80005ca4:	ffffe097          	auipc	ra,0xffffe
    80005ca8:	e50080e7          	jalr	-432(ra) # 80003af4 <iunlock>
  iput(p->cwd);
    80005cac:	15093503          	ld	a0,336(s2)
    80005cb0:	ffffe097          	auipc	ra,0xffffe
    80005cb4:	f3c080e7          	jalr	-196(ra) # 80003bec <iput>
  end_op();
    80005cb8:	ffffe097          	auipc	ra,0xffffe
    80005cbc:	7bc080e7          	jalr	1980(ra) # 80004474 <end_op>
  p->cwd = ip;
    80005cc0:	14993823          	sd	s1,336(s2)
  return 0;
    80005cc4:	4501                	li	a0,0
}
    80005cc6:	60ea                	ld	ra,152(sp)
    80005cc8:	644a                	ld	s0,144(sp)
    80005cca:	64aa                	ld	s1,136(sp)
    80005ccc:	690a                	ld	s2,128(sp)
    80005cce:	610d                	addi	sp,sp,160
    80005cd0:	8082                	ret
    end_op();
    80005cd2:	ffffe097          	auipc	ra,0xffffe
    80005cd6:	7a2080e7          	jalr	1954(ra) # 80004474 <end_op>
    return -1;
    80005cda:	557d                	li	a0,-1
    80005cdc:	b7ed                	j	80005cc6 <sys_chdir+0x7a>
    iunlockput(ip);
    80005cde:	8526                	mv	a0,s1
    80005ce0:	ffffe097          	auipc	ra,0xffffe
    80005ce4:	fb4080e7          	jalr	-76(ra) # 80003c94 <iunlockput>
    end_op();
    80005ce8:	ffffe097          	auipc	ra,0xffffe
    80005cec:	78c080e7          	jalr	1932(ra) # 80004474 <end_op>
    return -1;
    80005cf0:	557d                	li	a0,-1
    80005cf2:	bfd1                	j	80005cc6 <sys_chdir+0x7a>

0000000080005cf4 <sys_exec>:

uint64
sys_exec(void)
{
    80005cf4:	7145                	addi	sp,sp,-464
    80005cf6:	e786                	sd	ra,456(sp)
    80005cf8:	e3a2                	sd	s0,448(sp)
    80005cfa:	ff26                	sd	s1,440(sp)
    80005cfc:	fb4a                	sd	s2,432(sp)
    80005cfe:	f74e                	sd	s3,424(sp)
    80005d00:	f352                	sd	s4,416(sp)
    80005d02:	ef56                	sd	s5,408(sp)
    80005d04:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005d06:	e3840593          	addi	a1,s0,-456
    80005d0a:	4505                	li	a0,1
    80005d0c:	ffffd097          	auipc	ra,0xffffd
    80005d10:	0ac080e7          	jalr	172(ra) # 80002db8 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005d14:	08000613          	li	a2,128
    80005d18:	f4040593          	addi	a1,s0,-192
    80005d1c:	4501                	li	a0,0
    80005d1e:	ffffd097          	auipc	ra,0xffffd
    80005d22:	0ba080e7          	jalr	186(ra) # 80002dd8 <argstr>
    80005d26:	87aa                	mv	a5,a0
    return -1;
    80005d28:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005d2a:	0c07c263          	bltz	a5,80005dee <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005d2e:	10000613          	li	a2,256
    80005d32:	4581                	li	a1,0
    80005d34:	e4040513          	addi	a0,s0,-448
    80005d38:	ffffb097          	auipc	ra,0xffffb
    80005d3c:	f9a080e7          	jalr	-102(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005d40:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005d44:	89a6                	mv	s3,s1
    80005d46:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005d48:	02000a13          	li	s4,32
    80005d4c:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005d50:	00391793          	slli	a5,s2,0x3
    80005d54:	e3040593          	addi	a1,s0,-464
    80005d58:	e3843503          	ld	a0,-456(s0)
    80005d5c:	953e                	add	a0,a0,a5
    80005d5e:	ffffd097          	auipc	ra,0xffffd
    80005d62:	f9c080e7          	jalr	-100(ra) # 80002cfa <fetchaddr>
    80005d66:	02054a63          	bltz	a0,80005d9a <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005d6a:	e3043783          	ld	a5,-464(s0)
    80005d6e:	c3b9                	beqz	a5,80005db4 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005d70:	ffffb097          	auipc	ra,0xffffb
    80005d74:	d76080e7          	jalr	-650(ra) # 80000ae6 <kalloc>
    80005d78:	85aa                	mv	a1,a0
    80005d7a:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005d7e:	cd11                	beqz	a0,80005d9a <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005d80:	6605                	lui	a2,0x1
    80005d82:	e3043503          	ld	a0,-464(s0)
    80005d86:	ffffd097          	auipc	ra,0xffffd
    80005d8a:	fc6080e7          	jalr	-58(ra) # 80002d4c <fetchstr>
    80005d8e:	00054663          	bltz	a0,80005d9a <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005d92:	0905                	addi	s2,s2,1
    80005d94:	09a1                	addi	s3,s3,8
    80005d96:	fb491be3          	bne	s2,s4,80005d4c <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d9a:	10048913          	addi	s2,s1,256
    80005d9e:	6088                	ld	a0,0(s1)
    80005da0:	c531                	beqz	a0,80005dec <sys_exec+0xf8>
    kfree(argv[i]);
    80005da2:	ffffb097          	auipc	ra,0xffffb
    80005da6:	c48080e7          	jalr	-952(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005daa:	04a1                	addi	s1,s1,8
    80005dac:	ff2499e3          	bne	s1,s2,80005d9e <sys_exec+0xaa>
  return -1;
    80005db0:	557d                	li	a0,-1
    80005db2:	a835                	j	80005dee <sys_exec+0xfa>
      argv[i] = 0;
    80005db4:	0a8e                	slli	s5,s5,0x3
    80005db6:	fc040793          	addi	a5,s0,-64
    80005dba:	9abe                	add	s5,s5,a5
    80005dbc:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005dc0:	e4040593          	addi	a1,s0,-448
    80005dc4:	f4040513          	addi	a0,s0,-192
    80005dc8:	fffff097          	auipc	ra,0xfffff
    80005dcc:	172080e7          	jalr	370(ra) # 80004f3a <exec>
    80005dd0:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005dd2:	10048993          	addi	s3,s1,256
    80005dd6:	6088                	ld	a0,0(s1)
    80005dd8:	c901                	beqz	a0,80005de8 <sys_exec+0xf4>
    kfree(argv[i]);
    80005dda:	ffffb097          	auipc	ra,0xffffb
    80005dde:	c10080e7          	jalr	-1008(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005de2:	04a1                	addi	s1,s1,8
    80005de4:	ff3499e3          	bne	s1,s3,80005dd6 <sys_exec+0xe2>
  return ret;
    80005de8:	854a                	mv	a0,s2
    80005dea:	a011                	j	80005dee <sys_exec+0xfa>
  return -1;
    80005dec:	557d                	li	a0,-1
}
    80005dee:	60be                	ld	ra,456(sp)
    80005df0:	641e                	ld	s0,448(sp)
    80005df2:	74fa                	ld	s1,440(sp)
    80005df4:	795a                	ld	s2,432(sp)
    80005df6:	79ba                	ld	s3,424(sp)
    80005df8:	7a1a                	ld	s4,416(sp)
    80005dfa:	6afa                	ld	s5,408(sp)
    80005dfc:	6179                	addi	sp,sp,464
    80005dfe:	8082                	ret

0000000080005e00 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005e00:	7139                	addi	sp,sp,-64
    80005e02:	fc06                	sd	ra,56(sp)
    80005e04:	f822                	sd	s0,48(sp)
    80005e06:	f426                	sd	s1,40(sp)
    80005e08:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005e0a:	ffffc097          	auipc	ra,0xffffc
    80005e0e:	e60080e7          	jalr	-416(ra) # 80001c6a <myproc>
    80005e12:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005e14:	fd840593          	addi	a1,s0,-40
    80005e18:	4501                	li	a0,0
    80005e1a:	ffffd097          	auipc	ra,0xffffd
    80005e1e:	f9e080e7          	jalr	-98(ra) # 80002db8 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005e22:	fc840593          	addi	a1,s0,-56
    80005e26:	fd040513          	addi	a0,s0,-48
    80005e2a:	fffff097          	auipc	ra,0xfffff
    80005e2e:	dc6080e7          	jalr	-570(ra) # 80004bf0 <pipealloc>
    return -1;
    80005e32:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005e34:	0c054463          	bltz	a0,80005efc <sys_pipe+0xfc>
  fd0 = -1;
    80005e38:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005e3c:	fd043503          	ld	a0,-48(s0)
    80005e40:	fffff097          	auipc	ra,0xfffff
    80005e44:	51a080e7          	jalr	1306(ra) # 8000535a <fdalloc>
    80005e48:	fca42223          	sw	a0,-60(s0)
    80005e4c:	08054b63          	bltz	a0,80005ee2 <sys_pipe+0xe2>
    80005e50:	fc843503          	ld	a0,-56(s0)
    80005e54:	fffff097          	auipc	ra,0xfffff
    80005e58:	506080e7          	jalr	1286(ra) # 8000535a <fdalloc>
    80005e5c:	fca42023          	sw	a0,-64(s0)
    80005e60:	06054863          	bltz	a0,80005ed0 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e64:	4691                	li	a3,4
    80005e66:	fc440613          	addi	a2,s0,-60
    80005e6a:	fd843583          	ld	a1,-40(s0)
    80005e6e:	68a8                	ld	a0,80(s1)
    80005e70:	ffffc097          	auipc	ra,0xffffc
    80005e74:	800080e7          	jalr	-2048(ra) # 80001670 <copyout>
    80005e78:	02054063          	bltz	a0,80005e98 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005e7c:	4691                	li	a3,4
    80005e7e:	fc040613          	addi	a2,s0,-64
    80005e82:	fd843583          	ld	a1,-40(s0)
    80005e86:	0591                	addi	a1,a1,4
    80005e88:	68a8                	ld	a0,80(s1)
    80005e8a:	ffffb097          	auipc	ra,0xffffb
    80005e8e:	7e6080e7          	jalr	2022(ra) # 80001670 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005e92:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e94:	06055463          	bgez	a0,80005efc <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005e98:	fc442783          	lw	a5,-60(s0)
    80005e9c:	07e9                	addi	a5,a5,26
    80005e9e:	078e                	slli	a5,a5,0x3
    80005ea0:	97a6                	add	a5,a5,s1
    80005ea2:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005ea6:	fc042503          	lw	a0,-64(s0)
    80005eaa:	0569                	addi	a0,a0,26
    80005eac:	050e                	slli	a0,a0,0x3
    80005eae:	94aa                	add	s1,s1,a0
    80005eb0:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005eb4:	fd043503          	ld	a0,-48(s0)
    80005eb8:	fffff097          	auipc	ra,0xfffff
    80005ebc:	a08080e7          	jalr	-1528(ra) # 800048c0 <fileclose>
    fileclose(wf);
    80005ec0:	fc843503          	ld	a0,-56(s0)
    80005ec4:	fffff097          	auipc	ra,0xfffff
    80005ec8:	9fc080e7          	jalr	-1540(ra) # 800048c0 <fileclose>
    return -1;
    80005ecc:	57fd                	li	a5,-1
    80005ece:	a03d                	j	80005efc <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005ed0:	fc442783          	lw	a5,-60(s0)
    80005ed4:	0007c763          	bltz	a5,80005ee2 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005ed8:	07e9                	addi	a5,a5,26
    80005eda:	078e                	slli	a5,a5,0x3
    80005edc:	94be                	add	s1,s1,a5
    80005ede:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005ee2:	fd043503          	ld	a0,-48(s0)
    80005ee6:	fffff097          	auipc	ra,0xfffff
    80005eea:	9da080e7          	jalr	-1574(ra) # 800048c0 <fileclose>
    fileclose(wf);
    80005eee:	fc843503          	ld	a0,-56(s0)
    80005ef2:	fffff097          	auipc	ra,0xfffff
    80005ef6:	9ce080e7          	jalr	-1586(ra) # 800048c0 <fileclose>
    return -1;
    80005efa:	57fd                	li	a5,-1
}
    80005efc:	853e                	mv	a0,a5
    80005efe:	70e2                	ld	ra,56(sp)
    80005f00:	7442                	ld	s0,48(sp)
    80005f02:	74a2                	ld	s1,40(sp)
    80005f04:	6121                	addi	sp,sp,64
    80005f06:	8082                	ret
	...

0000000080005f10 <kernelvec>:
    80005f10:	7111                	addi	sp,sp,-256
    80005f12:	e006                	sd	ra,0(sp)
    80005f14:	e40a                	sd	sp,8(sp)
    80005f16:	e80e                	sd	gp,16(sp)
    80005f18:	ec12                	sd	tp,24(sp)
    80005f1a:	f016                	sd	t0,32(sp)
    80005f1c:	f41a                	sd	t1,40(sp)
    80005f1e:	f81e                	sd	t2,48(sp)
    80005f20:	fc22                	sd	s0,56(sp)
    80005f22:	e0a6                	sd	s1,64(sp)
    80005f24:	e4aa                	sd	a0,72(sp)
    80005f26:	e8ae                	sd	a1,80(sp)
    80005f28:	ecb2                	sd	a2,88(sp)
    80005f2a:	f0b6                	sd	a3,96(sp)
    80005f2c:	f4ba                	sd	a4,104(sp)
    80005f2e:	f8be                	sd	a5,112(sp)
    80005f30:	fcc2                	sd	a6,120(sp)
    80005f32:	e146                	sd	a7,128(sp)
    80005f34:	e54a                	sd	s2,136(sp)
    80005f36:	e94e                	sd	s3,144(sp)
    80005f38:	ed52                	sd	s4,152(sp)
    80005f3a:	f156                	sd	s5,160(sp)
    80005f3c:	f55a                	sd	s6,168(sp)
    80005f3e:	f95e                	sd	s7,176(sp)
    80005f40:	fd62                	sd	s8,184(sp)
    80005f42:	e1e6                	sd	s9,192(sp)
    80005f44:	e5ea                	sd	s10,200(sp)
    80005f46:	e9ee                	sd	s11,208(sp)
    80005f48:	edf2                	sd	t3,216(sp)
    80005f4a:	f1f6                	sd	t4,224(sp)
    80005f4c:	f5fa                	sd	t5,232(sp)
    80005f4e:	f9fe                	sd	t6,240(sp)
    80005f50:	c77fc0ef          	jal	ra,80002bc6 <kerneltrap>
    80005f54:	6082                	ld	ra,0(sp)
    80005f56:	6122                	ld	sp,8(sp)
    80005f58:	61c2                	ld	gp,16(sp)
    80005f5a:	7282                	ld	t0,32(sp)
    80005f5c:	7322                	ld	t1,40(sp)
    80005f5e:	73c2                	ld	t2,48(sp)
    80005f60:	7462                	ld	s0,56(sp)
    80005f62:	6486                	ld	s1,64(sp)
    80005f64:	6526                	ld	a0,72(sp)
    80005f66:	65c6                	ld	a1,80(sp)
    80005f68:	6666                	ld	a2,88(sp)
    80005f6a:	7686                	ld	a3,96(sp)
    80005f6c:	7726                	ld	a4,104(sp)
    80005f6e:	77c6                	ld	a5,112(sp)
    80005f70:	7866                	ld	a6,120(sp)
    80005f72:	688a                	ld	a7,128(sp)
    80005f74:	692a                	ld	s2,136(sp)
    80005f76:	69ca                	ld	s3,144(sp)
    80005f78:	6a6a                	ld	s4,152(sp)
    80005f7a:	7a8a                	ld	s5,160(sp)
    80005f7c:	7b2a                	ld	s6,168(sp)
    80005f7e:	7bca                	ld	s7,176(sp)
    80005f80:	7c6a                	ld	s8,184(sp)
    80005f82:	6c8e                	ld	s9,192(sp)
    80005f84:	6d2e                	ld	s10,200(sp)
    80005f86:	6dce                	ld	s11,208(sp)
    80005f88:	6e6e                	ld	t3,216(sp)
    80005f8a:	7e8e                	ld	t4,224(sp)
    80005f8c:	7f2e                	ld	t5,232(sp)
    80005f8e:	7fce                	ld	t6,240(sp)
    80005f90:	6111                	addi	sp,sp,256
    80005f92:	10200073          	sret
    80005f96:	00000013          	nop
    80005f9a:	00000013          	nop
    80005f9e:	0001                	nop

0000000080005fa0 <timervec>:
    80005fa0:	34051573          	csrrw	a0,mscratch,a0
    80005fa4:	e10c                	sd	a1,0(a0)
    80005fa6:	e510                	sd	a2,8(a0)
    80005fa8:	e914                	sd	a3,16(a0)
    80005faa:	6d0c                	ld	a1,24(a0)
    80005fac:	7110                	ld	a2,32(a0)
    80005fae:	6194                	ld	a3,0(a1)
    80005fb0:	96b2                	add	a3,a3,a2
    80005fb2:	e194                	sd	a3,0(a1)
    80005fb4:	4589                	li	a1,2
    80005fb6:	14459073          	csrw	sip,a1
    80005fba:	6914                	ld	a3,16(a0)
    80005fbc:	6510                	ld	a2,8(a0)
    80005fbe:	610c                	ld	a1,0(a0)
    80005fc0:	34051573          	csrrw	a0,mscratch,a0
    80005fc4:	30200073          	mret
	...

0000000080005fca <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005fca:	1141                	addi	sp,sp,-16
    80005fcc:	e422                	sd	s0,8(sp)
    80005fce:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005fd0:	0c0007b7          	lui	a5,0xc000
    80005fd4:	4705                	li	a4,1
    80005fd6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005fd8:	c3d8                	sw	a4,4(a5)
}
    80005fda:	6422                	ld	s0,8(sp)
    80005fdc:	0141                	addi	sp,sp,16
    80005fde:	8082                	ret

0000000080005fe0 <plicinithart>:

void
plicinithart(void)
{
    80005fe0:	1141                	addi	sp,sp,-16
    80005fe2:	e406                	sd	ra,8(sp)
    80005fe4:	e022                	sd	s0,0(sp)
    80005fe6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005fe8:	ffffc097          	auipc	ra,0xffffc
    80005fec:	c56080e7          	jalr	-938(ra) # 80001c3e <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005ff0:	0085171b          	slliw	a4,a0,0x8
    80005ff4:	0c0027b7          	lui	a5,0xc002
    80005ff8:	97ba                	add	a5,a5,a4
    80005ffa:	40200713          	li	a4,1026
    80005ffe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006002:	00d5151b          	slliw	a0,a0,0xd
    80006006:	0c2017b7          	lui	a5,0xc201
    8000600a:	953e                	add	a0,a0,a5
    8000600c:	00052023          	sw	zero,0(a0)
}
    80006010:	60a2                	ld	ra,8(sp)
    80006012:	6402                	ld	s0,0(sp)
    80006014:	0141                	addi	sp,sp,16
    80006016:	8082                	ret

0000000080006018 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006018:	1141                	addi	sp,sp,-16
    8000601a:	e406                	sd	ra,8(sp)
    8000601c:	e022                	sd	s0,0(sp)
    8000601e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006020:	ffffc097          	auipc	ra,0xffffc
    80006024:	c1e080e7          	jalr	-994(ra) # 80001c3e <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006028:	00d5179b          	slliw	a5,a0,0xd
    8000602c:	0c201537          	lui	a0,0xc201
    80006030:	953e                	add	a0,a0,a5
  return irq;
}
    80006032:	4148                	lw	a0,4(a0)
    80006034:	60a2                	ld	ra,8(sp)
    80006036:	6402                	ld	s0,0(sp)
    80006038:	0141                	addi	sp,sp,16
    8000603a:	8082                	ret

000000008000603c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000603c:	1101                	addi	sp,sp,-32
    8000603e:	ec06                	sd	ra,24(sp)
    80006040:	e822                	sd	s0,16(sp)
    80006042:	e426                	sd	s1,8(sp)
    80006044:	1000                	addi	s0,sp,32
    80006046:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006048:	ffffc097          	auipc	ra,0xffffc
    8000604c:	bf6080e7          	jalr	-1034(ra) # 80001c3e <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006050:	00d5151b          	slliw	a0,a0,0xd
    80006054:	0c2017b7          	lui	a5,0xc201
    80006058:	97aa                	add	a5,a5,a0
    8000605a:	c3c4                	sw	s1,4(a5)
}
    8000605c:	60e2                	ld	ra,24(sp)
    8000605e:	6442                	ld	s0,16(sp)
    80006060:	64a2                	ld	s1,8(sp)
    80006062:	6105                	addi	sp,sp,32
    80006064:	8082                	ret

0000000080006066 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006066:	1141                	addi	sp,sp,-16
    80006068:	e406                	sd	ra,8(sp)
    8000606a:	e022                	sd	s0,0(sp)
    8000606c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000606e:	479d                	li	a5,7
    80006070:	04a7cc63          	blt	a5,a0,800060c8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006074:	0001c797          	auipc	a5,0x1c
    80006078:	bcc78793          	addi	a5,a5,-1076 # 80021c40 <disk>
    8000607c:	97aa                	add	a5,a5,a0
    8000607e:	0187c783          	lbu	a5,24(a5)
    80006082:	ebb9                	bnez	a5,800060d8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006084:	00451613          	slli	a2,a0,0x4
    80006088:	0001c797          	auipc	a5,0x1c
    8000608c:	bb878793          	addi	a5,a5,-1096 # 80021c40 <disk>
    80006090:	6394                	ld	a3,0(a5)
    80006092:	96b2                	add	a3,a3,a2
    80006094:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80006098:	6398                	ld	a4,0(a5)
    8000609a:	9732                	add	a4,a4,a2
    8000609c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800060a0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800060a4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800060a8:	953e                	add	a0,a0,a5
    800060aa:	4785                	li	a5,1
    800060ac:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    800060b0:	0001c517          	auipc	a0,0x1c
    800060b4:	ba850513          	addi	a0,a0,-1112 # 80021c58 <disk+0x18>
    800060b8:	ffffc097          	auipc	ra,0xffffc
    800060bc:	2be080e7          	jalr	702(ra) # 80002376 <wakeup>
}
    800060c0:	60a2                	ld	ra,8(sp)
    800060c2:	6402                	ld	s0,0(sp)
    800060c4:	0141                	addi	sp,sp,16
    800060c6:	8082                	ret
    panic("free_desc 1");
    800060c8:	00002517          	auipc	a0,0x2
    800060cc:	6b850513          	addi	a0,a0,1720 # 80008780 <syscalls+0x300>
    800060d0:	ffffa097          	auipc	ra,0xffffa
    800060d4:	46e080e7          	jalr	1134(ra) # 8000053e <panic>
    panic("free_desc 2");
    800060d8:	00002517          	auipc	a0,0x2
    800060dc:	6b850513          	addi	a0,a0,1720 # 80008790 <syscalls+0x310>
    800060e0:	ffffa097          	auipc	ra,0xffffa
    800060e4:	45e080e7          	jalr	1118(ra) # 8000053e <panic>

00000000800060e8 <virtio_disk_init>:
{
    800060e8:	1101                	addi	sp,sp,-32
    800060ea:	ec06                	sd	ra,24(sp)
    800060ec:	e822                	sd	s0,16(sp)
    800060ee:	e426                	sd	s1,8(sp)
    800060f0:	e04a                	sd	s2,0(sp)
    800060f2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800060f4:	00002597          	auipc	a1,0x2
    800060f8:	6ac58593          	addi	a1,a1,1708 # 800087a0 <syscalls+0x320>
    800060fc:	0001c517          	auipc	a0,0x1c
    80006100:	c6c50513          	addi	a0,a0,-916 # 80021d68 <disk+0x128>
    80006104:	ffffb097          	auipc	ra,0xffffb
    80006108:	a42080e7          	jalr	-1470(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000610c:	100017b7          	lui	a5,0x10001
    80006110:	4398                	lw	a4,0(a5)
    80006112:	2701                	sext.w	a4,a4
    80006114:	747277b7          	lui	a5,0x74727
    80006118:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000611c:	14f71c63          	bne	a4,a5,80006274 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006120:	100017b7          	lui	a5,0x10001
    80006124:	43dc                	lw	a5,4(a5)
    80006126:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006128:	4709                	li	a4,2
    8000612a:	14e79563          	bne	a5,a4,80006274 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000612e:	100017b7          	lui	a5,0x10001
    80006132:	479c                	lw	a5,8(a5)
    80006134:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006136:	12e79f63          	bne	a5,a4,80006274 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000613a:	100017b7          	lui	a5,0x10001
    8000613e:	47d8                	lw	a4,12(a5)
    80006140:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006142:	554d47b7          	lui	a5,0x554d4
    80006146:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000614a:	12f71563          	bne	a4,a5,80006274 <virtio_disk_init+0x18c>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000614e:	100017b7          	lui	a5,0x10001
    80006152:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006156:	4705                	li	a4,1
    80006158:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000615a:	470d                	li	a4,3
    8000615c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000615e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006160:	c7ffe737          	lui	a4,0xc7ffe
    80006164:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc9df>
    80006168:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000616a:	2701                	sext.w	a4,a4
    8000616c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000616e:	472d                	li	a4,11
    80006170:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006172:	5bbc                	lw	a5,112(a5)
    80006174:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006178:	8ba1                	andi	a5,a5,8
    8000617a:	10078563          	beqz	a5,80006284 <virtio_disk_init+0x19c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000617e:	100017b7          	lui	a5,0x10001
    80006182:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006186:	43fc                	lw	a5,68(a5)
    80006188:	2781                	sext.w	a5,a5
    8000618a:	10079563          	bnez	a5,80006294 <virtio_disk_init+0x1ac>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000618e:	100017b7          	lui	a5,0x10001
    80006192:	5bdc                	lw	a5,52(a5)
    80006194:	2781                	sext.w	a5,a5
  if(max == 0)
    80006196:	10078763          	beqz	a5,800062a4 <virtio_disk_init+0x1bc>
  if(max < NUM)
    8000619a:	471d                	li	a4,7
    8000619c:	10f77c63          	bgeu	a4,a5,800062b4 <virtio_disk_init+0x1cc>
  disk.desc = kalloc();
    800061a0:	ffffb097          	auipc	ra,0xffffb
    800061a4:	946080e7          	jalr	-1722(ra) # 80000ae6 <kalloc>
    800061a8:	0001c497          	auipc	s1,0x1c
    800061ac:	a9848493          	addi	s1,s1,-1384 # 80021c40 <disk>
    800061b0:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800061b2:	ffffb097          	auipc	ra,0xffffb
    800061b6:	934080e7          	jalr	-1740(ra) # 80000ae6 <kalloc>
    800061ba:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800061bc:	ffffb097          	auipc	ra,0xffffb
    800061c0:	92a080e7          	jalr	-1750(ra) # 80000ae6 <kalloc>
    800061c4:	87aa                	mv	a5,a0
    800061c6:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800061c8:	6088                	ld	a0,0(s1)
    800061ca:	cd6d                	beqz	a0,800062c4 <virtio_disk_init+0x1dc>
    800061cc:	0001c717          	auipc	a4,0x1c
    800061d0:	a7c73703          	ld	a4,-1412(a4) # 80021c48 <disk+0x8>
    800061d4:	cb65                	beqz	a4,800062c4 <virtio_disk_init+0x1dc>
    800061d6:	c7fd                	beqz	a5,800062c4 <virtio_disk_init+0x1dc>
  memset(disk.desc, 0, PGSIZE);
    800061d8:	6605                	lui	a2,0x1
    800061da:	4581                	li	a1,0
    800061dc:	ffffb097          	auipc	ra,0xffffb
    800061e0:	af6080e7          	jalr	-1290(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    800061e4:	0001c497          	auipc	s1,0x1c
    800061e8:	a5c48493          	addi	s1,s1,-1444 # 80021c40 <disk>
    800061ec:	6605                	lui	a2,0x1
    800061ee:	4581                	li	a1,0
    800061f0:	6488                	ld	a0,8(s1)
    800061f2:	ffffb097          	auipc	ra,0xffffb
    800061f6:	ae0080e7          	jalr	-1312(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    800061fa:	6605                	lui	a2,0x1
    800061fc:	4581                	li	a1,0
    800061fe:	6888                	ld	a0,16(s1)
    80006200:	ffffb097          	auipc	ra,0xffffb
    80006204:	ad2080e7          	jalr	-1326(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006208:	100017b7          	lui	a5,0x10001
    8000620c:	4721                	li	a4,8
    8000620e:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006210:	4098                	lw	a4,0(s1)
    80006212:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006216:	40d8                	lw	a4,4(s1)
    80006218:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000621c:	6498                	ld	a4,8(s1)
    8000621e:	0007069b          	sext.w	a3,a4
    80006222:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006226:	9701                	srai	a4,a4,0x20
    80006228:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000622c:	6898                	ld	a4,16(s1)
    8000622e:	0007069b          	sext.w	a3,a4
    80006232:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006236:	9701                	srai	a4,a4,0x20
    80006238:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000623c:	4705                	li	a4,1
    8000623e:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80006240:	00e48c23          	sb	a4,24(s1)
    80006244:	00e48ca3          	sb	a4,25(s1)
    80006248:	00e48d23          	sb	a4,26(s1)
    8000624c:	00e48da3          	sb	a4,27(s1)
    80006250:	00e48e23          	sb	a4,28(s1)
    80006254:	00e48ea3          	sb	a4,29(s1)
    80006258:	00e48f23          	sb	a4,30(s1)
    8000625c:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006260:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006264:	0727a823          	sw	s2,112(a5)
}
    80006268:	60e2                	ld	ra,24(sp)
    8000626a:	6442                	ld	s0,16(sp)
    8000626c:	64a2                	ld	s1,8(sp)
    8000626e:	6902                	ld	s2,0(sp)
    80006270:	6105                	addi	sp,sp,32
    80006272:	8082                	ret
    panic("could not find virtio disk");
    80006274:	00002517          	auipc	a0,0x2
    80006278:	53c50513          	addi	a0,a0,1340 # 800087b0 <syscalls+0x330>
    8000627c:	ffffa097          	auipc	ra,0xffffa
    80006280:	2c2080e7          	jalr	706(ra) # 8000053e <panic>
    panic("virtio disk FEATURES_OK unset");
    80006284:	00002517          	auipc	a0,0x2
    80006288:	54c50513          	addi	a0,a0,1356 # 800087d0 <syscalls+0x350>
    8000628c:	ffffa097          	auipc	ra,0xffffa
    80006290:	2b2080e7          	jalr	690(ra) # 8000053e <panic>
    panic("virtio disk should not be ready");
    80006294:	00002517          	auipc	a0,0x2
    80006298:	55c50513          	addi	a0,a0,1372 # 800087f0 <syscalls+0x370>
    8000629c:	ffffa097          	auipc	ra,0xffffa
    800062a0:	2a2080e7          	jalr	674(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800062a4:	00002517          	auipc	a0,0x2
    800062a8:	56c50513          	addi	a0,a0,1388 # 80008810 <syscalls+0x390>
    800062ac:	ffffa097          	auipc	ra,0xffffa
    800062b0:	292080e7          	jalr	658(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800062b4:	00002517          	auipc	a0,0x2
    800062b8:	57c50513          	addi	a0,a0,1404 # 80008830 <syscalls+0x3b0>
    800062bc:	ffffa097          	auipc	ra,0xffffa
    800062c0:	282080e7          	jalr	642(ra) # 8000053e <panic>
    panic("virtio disk kalloc");
    800062c4:	00002517          	auipc	a0,0x2
    800062c8:	58c50513          	addi	a0,a0,1420 # 80008850 <syscalls+0x3d0>
    800062cc:	ffffa097          	auipc	ra,0xffffa
    800062d0:	272080e7          	jalr	626(ra) # 8000053e <panic>

00000000800062d4 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800062d4:	7119                	addi	sp,sp,-128
    800062d6:	fc86                	sd	ra,120(sp)
    800062d8:	f8a2                	sd	s0,112(sp)
    800062da:	f4a6                	sd	s1,104(sp)
    800062dc:	f0ca                	sd	s2,96(sp)
    800062de:	ecce                	sd	s3,88(sp)
    800062e0:	e8d2                	sd	s4,80(sp)
    800062e2:	e4d6                	sd	s5,72(sp)
    800062e4:	e0da                	sd	s6,64(sp)
    800062e6:	fc5e                	sd	s7,56(sp)
    800062e8:	f862                	sd	s8,48(sp)
    800062ea:	f466                	sd	s9,40(sp)
    800062ec:	f06a                	sd	s10,32(sp)
    800062ee:	ec6e                	sd	s11,24(sp)
    800062f0:	0100                	addi	s0,sp,128
    800062f2:	8aaa                	mv	s5,a0
    800062f4:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800062f6:	00c52d03          	lw	s10,12(a0)
    800062fa:	001d1d1b          	slliw	s10,s10,0x1
    800062fe:	1d02                	slli	s10,s10,0x20
    80006300:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006304:	0001c517          	auipc	a0,0x1c
    80006308:	a6450513          	addi	a0,a0,-1436 # 80021d68 <disk+0x128>
    8000630c:	ffffb097          	auipc	ra,0xffffb
    80006310:	8ca080e7          	jalr	-1846(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80006314:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006316:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006318:	0001cb97          	auipc	s7,0x1c
    8000631c:	928b8b93          	addi	s7,s7,-1752 # 80021c40 <disk>
  for(int i = 0; i < 3; i++){
    80006320:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006322:	0001cc97          	auipc	s9,0x1c
    80006326:	a46c8c93          	addi	s9,s9,-1466 # 80021d68 <disk+0x128>
    8000632a:	a08d                	j	8000638c <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000632c:	00fb8733          	add	a4,s7,a5
    80006330:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006334:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006336:	0207c563          	bltz	a5,80006360 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    8000633a:	2905                	addiw	s2,s2,1
    8000633c:	0611                	addi	a2,a2,4
    8000633e:	05690c63          	beq	s2,s6,80006396 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006342:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006344:	0001c717          	auipc	a4,0x1c
    80006348:	8fc70713          	addi	a4,a4,-1796 # 80021c40 <disk>
    8000634c:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000634e:	01874683          	lbu	a3,24(a4)
    80006352:	fee9                	bnez	a3,8000632c <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006354:	2785                	addiw	a5,a5,1
    80006356:	0705                	addi	a4,a4,1
    80006358:	fe979be3          	bne	a5,s1,8000634e <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000635c:	57fd                	li	a5,-1
    8000635e:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006360:	01205d63          	blez	s2,8000637a <virtio_disk_rw+0xa6>
    80006364:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006366:	000a2503          	lw	a0,0(s4)
    8000636a:	00000097          	auipc	ra,0x0
    8000636e:	cfc080e7          	jalr	-772(ra) # 80006066 <free_desc>
      for(int j = 0; j < i; j++)
    80006372:	2d85                	addiw	s11,s11,1
    80006374:	0a11                	addi	s4,s4,4
    80006376:	ffb918e3          	bne	s2,s11,80006366 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000637a:	85e6                	mv	a1,s9
    8000637c:	0001c517          	auipc	a0,0x1c
    80006380:	8dc50513          	addi	a0,a0,-1828 # 80021c58 <disk+0x18>
    80006384:	ffffc097          	auipc	ra,0xffffc
    80006388:	f8e080e7          	jalr	-114(ra) # 80002312 <sleep>
  for(int i = 0; i < 3; i++){
    8000638c:	f8040a13          	addi	s4,s0,-128
{
    80006390:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006392:	894e                	mv	s2,s3
    80006394:	b77d                	j	80006342 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006396:	f8042583          	lw	a1,-128(s0)
    8000639a:	00a58793          	addi	a5,a1,10
    8000639e:	0792                	slli	a5,a5,0x4

  if(write)
    800063a0:	0001c617          	auipc	a2,0x1c
    800063a4:	8a060613          	addi	a2,a2,-1888 # 80021c40 <disk>
    800063a8:	00f60733          	add	a4,a2,a5
    800063ac:	018036b3          	snez	a3,s8
    800063b0:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800063b2:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    800063b6:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800063ba:	f6078693          	addi	a3,a5,-160
    800063be:	6218                	ld	a4,0(a2)
    800063c0:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800063c2:	00878513          	addi	a0,a5,8
    800063c6:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    800063c8:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800063ca:	6208                	ld	a0,0(a2)
    800063cc:	96aa                	add	a3,a3,a0
    800063ce:	4741                	li	a4,16
    800063d0:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800063d2:	4705                	li	a4,1
    800063d4:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    800063d8:	f8442703          	lw	a4,-124(s0)
    800063dc:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800063e0:	0712                	slli	a4,a4,0x4
    800063e2:	953a                	add	a0,a0,a4
    800063e4:	058a8693          	addi	a3,s5,88
    800063e8:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    800063ea:	6208                	ld	a0,0(a2)
    800063ec:	972a                	add	a4,a4,a0
    800063ee:	40000693          	li	a3,1024
    800063f2:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800063f4:	001c3c13          	seqz	s8,s8
    800063f8:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800063fa:	001c6c13          	ori	s8,s8,1
    800063fe:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    80006402:	f8842603          	lw	a2,-120(s0)
    80006406:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    8000640a:	0001c697          	auipc	a3,0x1c
    8000640e:	83668693          	addi	a3,a3,-1994 # 80021c40 <disk>
    80006412:	00258713          	addi	a4,a1,2
    80006416:	0712                	slli	a4,a4,0x4
    80006418:	9736                	add	a4,a4,a3
    8000641a:	587d                	li	a6,-1
    8000641c:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006420:	0612                	slli	a2,a2,0x4
    80006422:	9532                	add	a0,a0,a2
    80006424:	f9078793          	addi	a5,a5,-112
    80006428:	97b6                	add	a5,a5,a3
    8000642a:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    8000642c:	629c                	ld	a5,0(a3)
    8000642e:	97b2                	add	a5,a5,a2
    80006430:	4605                	li	a2,1
    80006432:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006434:	4509                	li	a0,2
    80006436:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    8000643a:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000643e:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006442:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006446:	6698                	ld	a4,8(a3)
    80006448:	00275783          	lhu	a5,2(a4)
    8000644c:	8b9d                	andi	a5,a5,7
    8000644e:	0786                	slli	a5,a5,0x1
    80006450:	97ba                	add	a5,a5,a4
    80006452:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006456:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000645a:	6698                	ld	a4,8(a3)
    8000645c:	00275783          	lhu	a5,2(a4)
    80006460:	2785                	addiw	a5,a5,1
    80006462:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006466:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000646a:	100017b7          	lui	a5,0x10001
    8000646e:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006472:	004aa783          	lw	a5,4(s5)
    80006476:	02c79163          	bne	a5,a2,80006498 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    8000647a:	0001c917          	auipc	s2,0x1c
    8000647e:	8ee90913          	addi	s2,s2,-1810 # 80021d68 <disk+0x128>
  while(b->disk == 1) {
    80006482:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006484:	85ca                	mv	a1,s2
    80006486:	8556                	mv	a0,s5
    80006488:	ffffc097          	auipc	ra,0xffffc
    8000648c:	e8a080e7          	jalr	-374(ra) # 80002312 <sleep>
  while(b->disk == 1) {
    80006490:	004aa783          	lw	a5,4(s5)
    80006494:	fe9788e3          	beq	a5,s1,80006484 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006498:	f8042903          	lw	s2,-128(s0)
    8000649c:	00290793          	addi	a5,s2,2
    800064a0:	00479713          	slli	a4,a5,0x4
    800064a4:	0001b797          	auipc	a5,0x1b
    800064a8:	79c78793          	addi	a5,a5,1948 # 80021c40 <disk>
    800064ac:	97ba                	add	a5,a5,a4
    800064ae:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800064b2:	0001b997          	auipc	s3,0x1b
    800064b6:	78e98993          	addi	s3,s3,1934 # 80021c40 <disk>
    800064ba:	00491713          	slli	a4,s2,0x4
    800064be:	0009b783          	ld	a5,0(s3)
    800064c2:	97ba                	add	a5,a5,a4
    800064c4:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800064c8:	854a                	mv	a0,s2
    800064ca:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800064ce:	00000097          	auipc	ra,0x0
    800064d2:	b98080e7          	jalr	-1128(ra) # 80006066 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800064d6:	8885                	andi	s1,s1,1
    800064d8:	f0ed                	bnez	s1,800064ba <virtio_disk_rw+0x1e6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800064da:	0001c517          	auipc	a0,0x1c
    800064de:	88e50513          	addi	a0,a0,-1906 # 80021d68 <disk+0x128>
    800064e2:	ffffa097          	auipc	ra,0xffffa
    800064e6:	7a8080e7          	jalr	1960(ra) # 80000c8a <release>
}
    800064ea:	70e6                	ld	ra,120(sp)
    800064ec:	7446                	ld	s0,112(sp)
    800064ee:	74a6                	ld	s1,104(sp)
    800064f0:	7906                	ld	s2,96(sp)
    800064f2:	69e6                	ld	s3,88(sp)
    800064f4:	6a46                	ld	s4,80(sp)
    800064f6:	6aa6                	ld	s5,72(sp)
    800064f8:	6b06                	ld	s6,64(sp)
    800064fa:	7be2                	ld	s7,56(sp)
    800064fc:	7c42                	ld	s8,48(sp)
    800064fe:	7ca2                	ld	s9,40(sp)
    80006500:	7d02                	ld	s10,32(sp)
    80006502:	6de2                	ld	s11,24(sp)
    80006504:	6109                	addi	sp,sp,128
    80006506:	8082                	ret

0000000080006508 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006508:	1101                	addi	sp,sp,-32
    8000650a:	ec06                	sd	ra,24(sp)
    8000650c:	e822                	sd	s0,16(sp)
    8000650e:	e426                	sd	s1,8(sp)
    80006510:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006512:	0001b497          	auipc	s1,0x1b
    80006516:	72e48493          	addi	s1,s1,1838 # 80021c40 <disk>
    8000651a:	0001c517          	auipc	a0,0x1c
    8000651e:	84e50513          	addi	a0,a0,-1970 # 80021d68 <disk+0x128>
    80006522:	ffffa097          	auipc	ra,0xffffa
    80006526:	6b4080e7          	jalr	1716(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000652a:	10001737          	lui	a4,0x10001
    8000652e:	533c                	lw	a5,96(a4)
    80006530:	8b8d                	andi	a5,a5,3
    80006532:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006534:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006538:	689c                	ld	a5,16(s1)
    8000653a:	0204d703          	lhu	a4,32(s1)
    8000653e:	0027d783          	lhu	a5,2(a5)
    80006542:	04f70863          	beq	a4,a5,80006592 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006546:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000654a:	6898                	ld	a4,16(s1)
    8000654c:	0204d783          	lhu	a5,32(s1)
    80006550:	8b9d                	andi	a5,a5,7
    80006552:	078e                	slli	a5,a5,0x3
    80006554:	97ba                	add	a5,a5,a4
    80006556:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006558:	00278713          	addi	a4,a5,2
    8000655c:	0712                	slli	a4,a4,0x4
    8000655e:	9726                	add	a4,a4,s1
    80006560:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006564:	e721                	bnez	a4,800065ac <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006566:	0789                	addi	a5,a5,2
    80006568:	0792                	slli	a5,a5,0x4
    8000656a:	97a6                	add	a5,a5,s1
    8000656c:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000656e:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006572:	ffffc097          	auipc	ra,0xffffc
    80006576:	e04080e7          	jalr	-508(ra) # 80002376 <wakeup>

    disk.used_idx += 1;
    8000657a:	0204d783          	lhu	a5,32(s1)
    8000657e:	2785                	addiw	a5,a5,1
    80006580:	17c2                	slli	a5,a5,0x30
    80006582:	93c1                	srli	a5,a5,0x30
    80006584:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006588:	6898                	ld	a4,16(s1)
    8000658a:	00275703          	lhu	a4,2(a4)
    8000658e:	faf71ce3          	bne	a4,a5,80006546 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006592:	0001b517          	auipc	a0,0x1b
    80006596:	7d650513          	addi	a0,a0,2006 # 80021d68 <disk+0x128>
    8000659a:	ffffa097          	auipc	ra,0xffffa
    8000659e:	6f0080e7          	jalr	1776(ra) # 80000c8a <release>
}
    800065a2:	60e2                	ld	ra,24(sp)
    800065a4:	6442                	ld	s0,16(sp)
    800065a6:	64a2                	ld	s1,8(sp)
    800065a8:	6105                	addi	sp,sp,32
    800065aa:	8082                	ret
      panic("virtio_disk_intr status");
    800065ac:	00002517          	auipc	a0,0x2
    800065b0:	2bc50513          	addi	a0,a0,700 # 80008868 <syscalls+0x3e8>
    800065b4:	ffffa097          	auipc	ra,0xffffa
    800065b8:	f8a080e7          	jalr	-118(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
