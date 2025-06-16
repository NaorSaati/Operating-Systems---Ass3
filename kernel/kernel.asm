
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	ac010113          	addi	sp,sp,-1344 # 80008ac0 <stack0>
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
    80000056:	92e70713          	addi	a4,a4,-1746 # 80008980 <timer_scratch>
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
    80000068:	f6c78793          	addi	a5,a5,-148 # 80005fd0 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdca0f>
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
    80000130:	67a080e7          	jalr	1658(ra) # 800027a6 <either_copyin>
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
    8000018e:	93650513          	addi	a0,a0,-1738 # 80010ac0 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	92648493          	addi	s1,s1,-1754 # 80010ac0 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	9b690913          	addi	s2,s2,-1610 # 80010b58 <cons+0x98>
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
    800001c4:	ae0080e7          	jalr	-1312(ra) # 80001ca0 <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	428080e7          	jalr	1064(ra) # 800025f0 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	172080e7          	jalr	370(ra) # 80002348 <sleep>
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
    80000216:	53e080e7          	jalr	1342(ra) # 80002750 <either_copyout>
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
    8000022a:	89a50513          	addi	a0,a0,-1894 # 80010ac0 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	88450513          	addi	a0,a0,-1916 # 80010ac0 <cons>
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
    80000276:	8ef72323          	sw	a5,-1818(a4) # 80010b58 <cons+0x98>
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
    800002d0:	7f450513          	addi	a0,a0,2036 # 80010ac0 <cons>
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
    800002f6:	50a080e7          	jalr	1290(ra) # 800027fc <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	7c650513          	addi	a0,a0,1990 # 80010ac0 <cons>
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
    80000322:	7a270713          	addi	a4,a4,1954 # 80010ac0 <cons>
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
    8000034c:	77878793          	addi	a5,a5,1912 # 80010ac0 <cons>
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
    8000037a:	7e27a783          	lw	a5,2018(a5) # 80010b58 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	73670713          	addi	a4,a4,1846 # 80010ac0 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	72648493          	addi	s1,s1,1830 # 80010ac0 <cons>
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
    800003da:	6ea70713          	addi	a4,a4,1770 # 80010ac0 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	76f72a23          	sw	a5,1908(a4) # 80010b60 <cons+0xa0>
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
    80000416:	6ae78793          	addi	a5,a5,1710 # 80010ac0 <cons>
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
    8000043a:	72c7a323          	sw	a2,1830(a5) # 80010b5c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	71a50513          	addi	a0,a0,1818 # 80010b58 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	f66080e7          	jalr	-154(ra) # 800023ac <wakeup>
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
    80000464:	66050513          	addi	a0,a0,1632 # 80010ac0 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32a080e7          	jalr	810(ra) # 8000079a <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00020797          	auipc	a5,0x20
    8000047c:	7e078793          	addi	a5,a5,2016 # 80020c58 <devsw>
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
    8000054e:	6207ab23          	sw	zero,1590(a5) # 80010b80 <pr+0x18>
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
    80000582:	3cf72123          	sw	a5,962(a4) # 80008940 <panicked>
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
    800005be:	5c6dad83          	lw	s11,1478(s11) # 80010b80 <pr+0x18>
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
    800005fc:	57050513          	addi	a0,a0,1392 # 80010b68 <pr>
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
    8000075a:	41250513          	addi	a0,a0,1042 # 80010b68 <pr>
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
    80000776:	3f648493          	addi	s1,s1,1014 # 80010b68 <pr>
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
    800007d6:	3b650513          	addi	a0,a0,950 # 80010b88 <uart_tx_lock>
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
    80000802:	1427a783          	lw	a5,322(a5) # 80008940 <panicked>
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
    8000083a:	1127b783          	ld	a5,274(a5) # 80008948 <uart_tx_r>
    8000083e:	00008717          	auipc	a4,0x8
    80000842:	11273703          	ld	a4,274(a4) # 80008950 <uart_tx_w>
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
    80000864:	328a0a13          	addi	s4,s4,808 # 80010b88 <uart_tx_lock>
    uart_tx_r += 1;
    80000868:	00008497          	auipc	s1,0x8
    8000086c:	0e048493          	addi	s1,s1,224 # 80008948 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000870:	00008997          	auipc	s3,0x8
    80000874:	0e098993          	addi	s3,s3,224 # 80008950 <uart_tx_w>
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
    80000896:	b1a080e7          	jalr	-1254(ra) # 800023ac <wakeup>
    
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
    800008d2:	2ba50513          	addi	a0,a0,698 # 80010b88 <uart_tx_lock>
    800008d6:	00000097          	auipc	ra,0x0
    800008da:	300080e7          	jalr	768(ra) # 80000bd6 <acquire>
  if(panicked){
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	0627a783          	lw	a5,98(a5) # 80008940 <panicked>
    800008e6:	e7c9                	bnez	a5,80000970 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e8:	00008717          	auipc	a4,0x8
    800008ec:	06873703          	ld	a4,104(a4) # 80008950 <uart_tx_w>
    800008f0:	00008797          	auipc	a5,0x8
    800008f4:	0587b783          	ld	a5,88(a5) # 80008948 <uart_tx_r>
    800008f8:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fc:	00010997          	auipc	s3,0x10
    80000900:	28c98993          	addi	s3,s3,652 # 80010b88 <uart_tx_lock>
    80000904:	00008497          	auipc	s1,0x8
    80000908:	04448493          	addi	s1,s1,68 # 80008948 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090c:	00008917          	auipc	s2,0x8
    80000910:	04490913          	addi	s2,s2,68 # 80008950 <uart_tx_w>
    80000914:	00e79f63          	bne	a5,a4,80000932 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000918:	85ce                	mv	a1,s3
    8000091a:	8526                	mv	a0,s1
    8000091c:	00002097          	auipc	ra,0x2
    80000920:	a2c080e7          	jalr	-1492(ra) # 80002348 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000924:	00093703          	ld	a4,0(s2)
    80000928:	609c                	ld	a5,0(s1)
    8000092a:	02078793          	addi	a5,a5,32
    8000092e:	fee785e3          	beq	a5,a4,80000918 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000932:	00010497          	auipc	s1,0x10
    80000936:	25648493          	addi	s1,s1,598 # 80010b88 <uart_tx_lock>
    8000093a:	01f77793          	andi	a5,a4,31
    8000093e:	97a6                	add	a5,a5,s1
    80000940:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000944:	0705                	addi	a4,a4,1
    80000946:	00008797          	auipc	a5,0x8
    8000094a:	00e7b523          	sd	a4,10(a5) # 80008950 <uart_tx_w>
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
    800009c0:	1cc48493          	addi	s1,s1,460 # 80010b88 <uart_tx_lock>
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
    80000a02:	3f278793          	addi	a5,a5,1010 # 80021df0 <end>
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
    80000a22:	1a290913          	addi	s2,s2,418 # 80010bc0 <kmem>
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
    80000abe:	10650513          	addi	a0,a0,262 # 80010bc0 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00021517          	auipc	a0,0x21
    80000ad2:	32250513          	addi	a0,a0,802 # 80021df0 <end>
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
    80000af4:	0d048493          	addi	s1,s1,208 # 80010bc0 <kmem>
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
    80000b0c:	0b850513          	addi	a0,a0,184 # 80010bc0 <kmem>
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
    80000b38:	08c50513          	addi	a0,a0,140 # 80010bc0 <kmem>
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
    80000b74:	114080e7          	jalr	276(ra) # 80001c84 <mycpu>
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
    80000ba6:	0e2080e7          	jalr	226(ra) # 80001c84 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	0d6080e7          	jalr	214(ra) # 80001c84 <mycpu>
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
    80000bca:	0be080e7          	jalr	190(ra) # 80001c84 <mycpu>
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
    80000c0a:	07e080e7          	jalr	126(ra) # 80001c84 <mycpu>
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
    80000c36:	052080e7          	jalr	82(ra) # 80001c84 <mycpu>
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
    80000e84:	df4080e7          	jalr	-524(ra) # 80001c74 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	ad070713          	addi	a4,a4,-1328 # 80008958 <started>
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
    80000ea0:	dd8080e7          	jalr	-552(ra) # 80001c74 <cpuid>
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
    80000ec2:	a98080e7          	jalr	-1384(ra) # 80002956 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	14a080e7          	jalr	330(ra) # 80006010 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	2c8080e7          	jalr	712(ra) # 80002196 <scheduler>
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
    80000f32:	c92080e7          	jalr	-878(ra) # 80001bc0 <procinit>
    trapinit();      // trap vectors
    80000f36:	00002097          	auipc	ra,0x2
    80000f3a:	9f8080e7          	jalr	-1544(ra) # 8000292e <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	a18080e7          	jalr	-1512(ra) # 80002956 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	0b4080e7          	jalr	180(ra) # 80005ffa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	0c2080e7          	jalr	194(ra) # 80006010 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	26a080e7          	jalr	618(ra) # 800031c0 <binit>
    iinit();         // inode table
    80000f5e:	00003097          	auipc	ra,0x3
    80000f62:	90e080e7          	jalr	-1778(ra) # 8000386c <iinit>
    fileinit();      // file table
    80000f66:	00004097          	auipc	ra,0x4
    80000f6a:	8ac080e7          	jalr	-1876(ra) # 80004812 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	1aa080e7          	jalr	426(ra) # 80006118 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	002080e7          	jalr	2(ra) # 80001f78 <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	9cf72a23          	sw	a5,-1580(a4) # 80008958 <started>
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
    80000f9c:	9c87b783          	ld	a5,-1592(a5) # 80008960 <kernel_pagetable>
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
    80001232:	8fc080e7          	jalr	-1796(ra) # 80001b2a <proc_mapstacks>
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
    80001258:	70a7b623          	sd	a0,1804(a5) # 80008960 <kernel_pagetable>
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
{
  if (src_proc == 0 || dst_proc == 0 || size == 0 || src_va >= MAXVA)
    8000183e:	20050d63          	beqz	a0,80001a58 <map_shared_pages+0x21a>
{
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
    80001866:	1e058b63          	beqz	a1,80001a5c <map_shared_pages+0x21e>
    return -1;
    8000186a:	557d                	li	a0,-1
  if (src_proc == 0 || dst_proc == 0 || size == 0 || src_va >= MAXVA)
    8000186c:	c6ed                	beqz	a3,80001956 <map_shared_pages+0x118>
    8000186e:	57fd                	li	a5,-1
    80001870:	83e9                	srli	a5,a5,0x1a
    80001872:	0ec7e263          	bltu	a5,a2,80001956 <map_shared_pages+0x118>

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
    8000189e:	048abd83          	ld	s11,72(s5) # fffffffffffff048 <end+0xffffffff7ffdd258>
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
    800018b8:	96cd0d13          	addi	s10,s10,-1684 # 80008220 <digits+0x1e0>
    if ((pte_src = walk(src_proc->pagetable, a, 0)) == 0) {
    800018bc:	4601                	li	a2,0
    800018be:	85d2                	mv	a1,s4
    800018c0:	050b3503          	ld	a0,80(s6) # 1050 <_entry-0x7fffefb0>
    800018c4:	fffff097          	auipc	ra,0xfffff
    800018c8:	6f2080e7          	jalr	1778(ra) # 80000fb6 <walk>
    800018cc:	c921                	beqz	a0,8000191c <map_shared_pages+0xde>
    if (!(*pte_src & PTE_V) || !(*pte_src & PTE_U)) {
    800018ce:	6110                	ld	a2,0(a0)
    800018d0:	01167793          	andi	a5,a2,17
    800018d4:	0b979c63          	bne	a5,s9,8000198c <map_shared_pages+0x14e>
    pa = PTE2PA(*pte_src);
    800018d8:	00a65993          	srli	s3,a2,0xa
    800018dc:	09b2                	slli	s3,s3,0xc
    flags = PTE_FLAGS(*pte_src) | PTE_S;
    800018de:	2ff67613          	andi	a2,a2,767
    800018e2:	10066493          	ori	s1,a2,256
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
    8000190a:	e979                	bnez	a0,800019e0 <map_shared_pages+0x1a2>
      release(&src_proc->lock);
      release(&dst_proc->lock);
      return -1;
    }

    dst_proc->sz = cur_dst_va + PGSIZE;
    8000190c:	6785                	lui	a5,0x1
    8000190e:	993e                	add	s2,s2,a5
    80001910:	052ab423          	sd	s2,72(s5)

    if (a == last)
    80001914:	137a0063          	beq	s4,s7,80001a34 <map_shared_pages+0x1f6>
      break;
    a += PGSIZE;
    80001918:	9a3e                	add	s4,s4,a5
    if ((pte_src = walk(src_proc->pagetable, a, 0)) == 0) {
    8000191a:	b74d                	j	800018bc <map_shared_pages+0x7e>
      printf("❌ walk failed at va %p\n", a);
    8000191c:	85d2                	mv	a1,s4
    8000191e:	00007517          	auipc	a0,0x7
    80001922:	8ba50513          	addi	a0,a0,-1862 # 800081d8 <digits+0x198>
    80001926:	fffff097          	auipc	ra,0xfffff
    8000192a:	c62080e7          	jalr	-926(ra) # 80000588 <printf>
      cleanup(dst_proc, dst_va, ((cur_dst_va - dst_va) / PGSIZE), org_sz);
    8000192e:	f8843783          	ld	a5,-120(s0)
    80001932:	40f90933          	sub	s2,s2,a5
// ------------------------------------------------------------------------------

static void cleanup(struct proc *dst_proc, uint64 dst_va,
                    uint64 pages_mapped, uint64 original_sz)
{
  if (pages_mapped > 0)
    80001936:	6785                	lui	a5,0x1
    80001938:	02f97e63          	bgeu	s2,a5,80001974 <map_shared_pages+0x136>
  {
    uvmunmap(dst_proc->pagetable, dst_va, pages_mapped, 0);
  }
  // Restore the original process size
  dst_proc->sz = original_sz;
    8000193c:	05bab423          	sd	s11,72(s5)
      release(&src_proc->lock);
    80001940:	855a                	mv	a0,s6
    80001942:	fffff097          	auipc	ra,0xfffff
    80001946:	348080e7          	jalr	840(ra) # 80000c8a <release>
      release(&dst_proc->lock);
    8000194a:	8556                	mv	a0,s5
    8000194c:	fffff097          	auipc	ra,0xfffff
    80001950:	33e080e7          	jalr	830(ra) # 80000c8a <release>
      return -1;
    80001954:	557d                	li	a0,-1
}
    80001956:	70e6                	ld	ra,120(sp)
    80001958:	7446                	ld	s0,112(sp)
    8000195a:	74a6                	ld	s1,104(sp)
    8000195c:	7906                	ld	s2,96(sp)
    8000195e:	69e6                	ld	s3,88(sp)
    80001960:	6a46                	ld	s4,80(sp)
    80001962:	6aa6                	ld	s5,72(sp)
    80001964:	6b06                	ld	s6,64(sp)
    80001966:	7be2                	ld	s7,56(sp)
    80001968:	7c42                	ld	s8,48(sp)
    8000196a:	7ca2                	ld	s9,40(sp)
    8000196c:	7d02                	ld	s10,32(sp)
    8000196e:	6de2                	ld	s11,24(sp)
    80001970:	6109                	addi	sp,sp,128
    80001972:	8082                	ret
    uvmunmap(dst_proc->pagetable, dst_va, pages_mapped, 0);
    80001974:	4681                	li	a3,0
    80001976:	00c95613          	srli	a2,s2,0xc
    8000197a:	f8843583          	ld	a1,-120(s0)
    8000197e:	050ab503          	ld	a0,80(s5)
    80001982:	00000097          	auipc	ra,0x0
    80001986:	8e2080e7          	jalr	-1822(ra) # 80001264 <uvmunmap>
    8000198a:	bf4d                	j	8000193c <map_shared_pages+0xfe>
      printf("❌ invalid PTE at va %p: flags = 0x%x\n", a, *pte_src);
    8000198c:	85d2                	mv	a1,s4
    8000198e:	00007517          	auipc	a0,0x7
    80001992:	86a50513          	addi	a0,a0,-1942 # 800081f8 <digits+0x1b8>
    80001996:	fffff097          	auipc	ra,0xfffff
    8000199a:	bf2080e7          	jalr	-1038(ra) # 80000588 <printf>
      cleanup(dst_proc, dst_va, ((cur_dst_va - dst_va) / PGSIZE), org_sz);
    8000199e:	f8843783          	ld	a5,-120(s0)
    800019a2:	40f90933          	sub	s2,s2,a5
  if (pages_mapped > 0)
    800019a6:	6785                	lui	a5,0x1
    800019a8:	02f97063          	bgeu	s2,a5,800019c8 <map_shared_pages+0x18a>
  dst_proc->sz = original_sz;
    800019ac:	05bab423          	sd	s11,72(s5)
      release(&src_proc->lock);
    800019b0:	855a                	mv	a0,s6
    800019b2:	fffff097          	auipc	ra,0xfffff
    800019b6:	2d8080e7          	jalr	728(ra) # 80000c8a <release>
      release(&dst_proc->lock);
    800019ba:	8556                	mv	a0,s5
    800019bc:	fffff097          	auipc	ra,0xfffff
    800019c0:	2ce080e7          	jalr	718(ra) # 80000c8a <release>
      return -1;
    800019c4:	557d                	li	a0,-1
    800019c6:	bf41                	j	80001956 <map_shared_pages+0x118>
    uvmunmap(dst_proc->pagetable, dst_va, pages_mapped, 0);
    800019c8:	4681                	li	a3,0
    800019ca:	00c95613          	srli	a2,s2,0xc
    800019ce:	f8843583          	ld	a1,-120(s0)
    800019d2:	050ab503          	ld	a0,80(s5)
    800019d6:	00000097          	auipc	ra,0x0
    800019da:	88e080e7          	jalr	-1906(ra) # 80001264 <uvmunmap>
    800019de:	b7f9                	j	800019ac <map_shared_pages+0x16e>
      printf("❌ mappages failed at dst_va %p\n", cur_dst_va);
    800019e0:	85ca                	mv	a1,s2
    800019e2:	00007517          	auipc	a0,0x7
    800019e6:	86e50513          	addi	a0,a0,-1938 # 80008250 <digits+0x210>
    800019ea:	fffff097          	auipc	ra,0xfffff
    800019ee:	b9e080e7          	jalr	-1122(ra) # 80000588 <printf>
      cleanup(dst_proc, dst_va, ((cur_dst_va - dst_va) / PGSIZE), org_sz);
    800019f2:	f8843783          	ld	a5,-120(s0)
    800019f6:	40f90933          	sub	s2,s2,a5
  if (pages_mapped > 0)
    800019fa:	6785                	lui	a5,0x1
    800019fc:	02f97063          	bgeu	s2,a5,80001a1c <map_shared_pages+0x1de>
  dst_proc->sz = original_sz;
    80001a00:	05bab423          	sd	s11,72(s5)
      release(&src_proc->lock);
    80001a04:	855a                	mv	a0,s6
    80001a06:	fffff097          	auipc	ra,0xfffff
    80001a0a:	284080e7          	jalr	644(ra) # 80000c8a <release>
      release(&dst_proc->lock);
    80001a0e:	8556                	mv	a0,s5
    80001a10:	fffff097          	auipc	ra,0xfffff
    80001a14:	27a080e7          	jalr	634(ra) # 80000c8a <release>
      return -1;
    80001a18:	557d                	li	a0,-1
    80001a1a:	bf35                	j	80001956 <map_shared_pages+0x118>
    uvmunmap(dst_proc->pagetable, dst_va, pages_mapped, 0);
    80001a1c:	4681                	li	a3,0
    80001a1e:	00c95613          	srli	a2,s2,0xc
    80001a22:	f8843583          	ld	a1,-120(s0)
    80001a26:	050ab503          	ld	a0,80(s5)
    80001a2a:	00000097          	auipc	ra,0x0
    80001a2e:	83a080e7          	jalr	-1990(ra) # 80001264 <uvmunmap>
    80001a32:	b7f9                	j	80001a00 <map_shared_pages+0x1c2>
  release(&src_proc->lock);
    80001a34:	855a                	mv	a0,s6
    80001a36:	fffff097          	auipc	ra,0xfffff
    80001a3a:	254080e7          	jalr	596(ra) # 80000c8a <release>
  release(&dst_proc->lock);
    80001a3e:	8556                	mv	a0,s5
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	24a080e7          	jalr	586(ra) # 80000c8a <release>
  offset = src_va - a;
    80001a48:	f8043783          	ld	a5,-128(s0)
    80001a4c:	40fc0533          	sub	a0,s8,a5
  return dst_va + offset;
    80001a50:	f8843783          	ld	a5,-120(s0)
    80001a54:	953e                	add	a0,a0,a5
    80001a56:	b701                	j	80001956 <map_shared_pages+0x118>
    return -1;
    80001a58:	557d                	li	a0,-1
}
    80001a5a:	8082                	ret
    return -1;
    80001a5c:	557d                	li	a0,-1
    80001a5e:	bde5                	j	80001956 <map_shared_pages+0x118>

0000000080001a60 <unmap_shared_pages>:
  if (p == 0 || size == 0 || addr >= MAXVA)
    80001a60:	c179                	beqz	a0,80001b26 <unmap_shared_pages+0xc6>
{
    80001a62:	7139                	addi	sp,sp,-64
    80001a64:	fc06                	sd	ra,56(sp)
    80001a66:	f822                	sd	s0,48(sp)
    80001a68:	f426                	sd	s1,40(sp)
    80001a6a:	f04a                	sd	s2,32(sp)
    80001a6c:	ec4e                	sd	s3,24(sp)
    80001a6e:	e852                	sd	s4,16(sp)
    80001a70:	e456                	sd	s5,8(sp)
    80001a72:	e05a                	sd	s6,0(sp)
    80001a74:	0080                	addi	s0,sp,64
    80001a76:	89aa                	mv	s3,a0
    return -1; // Invalid input
    80001a78:	557d                	li	a0,-1
  if (p == 0 || size == 0 || addr >= MAXVA)
    80001a7a:	ca49                	beqz	a2,80001b0c <unmap_shared_pages+0xac>
    80001a7c:	57fd                	li	a5,-1
    80001a7e:	83e9                	srli	a5,a5,0x1a
    80001a80:	08b7e663          	bltu	a5,a1,80001b0c <unmap_shared_pages+0xac>
  a = PGROUNDDOWN(addr);
    80001a84:	77fd                	lui	a5,0xfffff
    80001a86:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(addr + size - 1);
    80001a8a:	15fd                	addi	a1,a1,-1
    80001a8c:	00c58933          	add	s2,a1,a2
    80001a90:	00f97933          	and	s2,s2,a5
  acquire(&p->lock);
    80001a94:	854e                	mv	a0,s3
    80001a96:	fffff097          	auipc	ra,0xfffff
    80001a9a:	140080e7          	jalr	320(ra) # 80000bd6 <acquire>
  for(uint64 curr = a; curr <= last; curr += PGSIZE){
    80001a9e:	03496763          	bltu	s2,s4,80001acc <unmap_shared_pages+0x6c>
    80001aa2:	84d2                	mv	s1,s4
      if(((pte = walk(p->pagetable, curr, 0)) == 0) || !(*pte & PTE_S) || !(*pte & PTE_V)){
    80001aa4:	10100a93          	li	s5,257
  for(uint64 curr = a; curr <= last; curr += PGSIZE){
    80001aa8:	6b05                	lui	s6,0x1
      if(((pte = walk(p->pagetable, curr, 0)) == 0) || !(*pte & PTE_S) || !(*pte & PTE_V)){
    80001aaa:	4601                	li	a2,0
    80001aac:	85a6                	mv	a1,s1
    80001aae:	0509b503          	ld	a0,80(s3) # 1050 <_entry-0x7fffefb0>
    80001ab2:	fffff097          	auipc	ra,0xfffff
    80001ab6:	504080e7          	jalr	1284(ra) # 80000fb6 <walk>
    80001aba:	c139                	beqz	a0,80001b00 <unmap_shared_pages+0xa0>
    80001abc:	611c                	ld	a5,0(a0)
    80001abe:	1017f793          	andi	a5,a5,257
    80001ac2:	03579f63          	bne	a5,s5,80001b00 <unmap_shared_pages+0xa0>
  for(uint64 curr = a; curr <= last; curr += PGSIZE){
    80001ac6:	94da                	add	s1,s1,s6
    80001ac8:	fe9971e3          	bgeu	s2,s1,80001aaa <unmap_shared_pages+0x4a>
  npages = (last - a)/PGSIZE + 1;
    80001acc:	414904b3          	sub	s1,s2,s4
    80001ad0:	80b1                	srli	s1,s1,0xc
    80001ad2:	0485                	addi	s1,s1,1
  uvmunmap(p->pagetable, a, npages, 0);
    80001ad4:	4681                	li	a3,0
    80001ad6:	8626                	mv	a2,s1
    80001ad8:	85d2                	mv	a1,s4
    80001ada:	0509b503          	ld	a0,80(s3)
    80001ade:	fffff097          	auipc	ra,0xfffff
    80001ae2:	786080e7          	jalr	1926(ra) # 80001264 <uvmunmap>
  if(a + npages*PGSIZE == p->sz)
    80001ae6:	04b2                	slli	s1,s1,0xc
    80001ae8:	94d2                	add	s1,s1,s4
    80001aea:	0489b783          	ld	a5,72(s3)
    80001aee:	02f48963          	beq	s1,a5,80001b20 <unmap_shared_pages+0xc0>
  release(&p->lock);
    80001af2:	854e                	mv	a0,s3
    80001af4:	fffff097          	auipc	ra,0xfffff
    80001af8:	196080e7          	jalr	406(ra) # 80000c8a <release>
  return 0;
    80001afc:	4501                	li	a0,0
    80001afe:	a039                	j	80001b0c <unmap_shared_pages+0xac>
        release(&p->lock);
    80001b00:	854e                	mv	a0,s3
    80001b02:	fffff097          	auipc	ra,0xfffff
    80001b06:	188080e7          	jalr	392(ra) # 80000c8a <release>
        return -1;
    80001b0a:	557d                	li	a0,-1
}
    80001b0c:	70e2                	ld	ra,56(sp)
    80001b0e:	7442                	ld	s0,48(sp)
    80001b10:	74a2                	ld	s1,40(sp)
    80001b12:	7902                	ld	s2,32(sp)
    80001b14:	69e2                	ld	s3,24(sp)
    80001b16:	6a42                	ld	s4,16(sp)
    80001b18:	6aa2                	ld	s5,8(sp)
    80001b1a:	6b02                	ld	s6,0(sp)
    80001b1c:	6121                	addi	sp,sp,64
    80001b1e:	8082                	ret
    p->sz = a;
    80001b20:	0549b423          	sd	s4,72(s3)
    80001b24:	b7f9                	j	80001af2 <unmap_shared_pages+0x92>
    return -1; // Invalid input
    80001b26:	557d                	li	a0,-1
}
    80001b28:	8082                	ret

0000000080001b2a <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001b2a:	7139                	addi	sp,sp,-64
    80001b2c:	fc06                	sd	ra,56(sp)
    80001b2e:	f822                	sd	s0,48(sp)
    80001b30:	f426                	sd	s1,40(sp)
    80001b32:	f04a                	sd	s2,32(sp)
    80001b34:	ec4e                	sd	s3,24(sp)
    80001b36:	e852                	sd	s4,16(sp)
    80001b38:	e456                	sd	s5,8(sp)
    80001b3a:	e05a                	sd	s6,0(sp)
    80001b3c:	0080                	addi	s0,sp,64
    80001b3e:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b40:	0000f497          	auipc	s1,0xf
    80001b44:	4d048493          	addi	s1,s1,1232 # 80011010 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001b48:	8b26                	mv	s6,s1
    80001b4a:	00006a97          	auipc	s5,0x6
    80001b4e:	4b6a8a93          	addi	s5,s5,1206 # 80008000 <etext>
    80001b52:	04000937          	lui	s2,0x4000
    80001b56:	197d                	addi	s2,s2,-1
    80001b58:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b5a:	00015a17          	auipc	s4,0x15
    80001b5e:	eb6a0a13          	addi	s4,s4,-330 # 80016a10 <tickslock>
    char *pa = kalloc();
    80001b62:	fffff097          	auipc	ra,0xfffff
    80001b66:	f84080e7          	jalr	-124(ra) # 80000ae6 <kalloc>
    80001b6a:	862a                	mv	a2,a0
    if(pa == 0)
    80001b6c:	c131                	beqz	a0,80001bb0 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001b6e:	416485b3          	sub	a1,s1,s6
    80001b72:	858d                	srai	a1,a1,0x3
    80001b74:	000ab783          	ld	a5,0(s5)
    80001b78:	02f585b3          	mul	a1,a1,a5
    80001b7c:	2585                	addiw	a1,a1,1
    80001b7e:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001b82:	4719                	li	a4,6
    80001b84:	6685                	lui	a3,0x1
    80001b86:	40b905b3          	sub	a1,s2,a1
    80001b8a:	854e                	mv	a0,s3
    80001b8c:	fffff097          	auipc	ra,0xfffff
    80001b90:	5b2080e7          	jalr	1458(ra) # 8000113e <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b94:	16848493          	addi	s1,s1,360
    80001b98:	fd4495e3          	bne	s1,s4,80001b62 <proc_mapstacks+0x38>
  }
}
    80001b9c:	70e2                	ld	ra,56(sp)
    80001b9e:	7442                	ld	s0,48(sp)
    80001ba0:	74a2                	ld	s1,40(sp)
    80001ba2:	7902                	ld	s2,32(sp)
    80001ba4:	69e2                	ld	s3,24(sp)
    80001ba6:	6a42                	ld	s4,16(sp)
    80001ba8:	6aa2                	ld	s5,8(sp)
    80001baa:	6b02                	ld	s6,0(sp)
    80001bac:	6121                	addi	sp,sp,64
    80001bae:	8082                	ret
      panic("kalloc");
    80001bb0:	00006517          	auipc	a0,0x6
    80001bb4:	6c850513          	addi	a0,a0,1736 # 80008278 <digits+0x238>
    80001bb8:	fffff097          	auipc	ra,0xfffff
    80001bbc:	986080e7          	jalr	-1658(ra) # 8000053e <panic>

0000000080001bc0 <procinit>:

// initialize the proc table.
void
procinit(void)
{
    80001bc0:	7139                	addi	sp,sp,-64
    80001bc2:	fc06                	sd	ra,56(sp)
    80001bc4:	f822                	sd	s0,48(sp)
    80001bc6:	f426                	sd	s1,40(sp)
    80001bc8:	f04a                	sd	s2,32(sp)
    80001bca:	ec4e                	sd	s3,24(sp)
    80001bcc:	e852                	sd	s4,16(sp)
    80001bce:	e456                	sd	s5,8(sp)
    80001bd0:	e05a                	sd	s6,0(sp)
    80001bd2:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001bd4:	00006597          	auipc	a1,0x6
    80001bd8:	6ac58593          	addi	a1,a1,1708 # 80008280 <digits+0x240>
    80001bdc:	0000f517          	auipc	a0,0xf
    80001be0:	00450513          	addi	a0,a0,4 # 80010be0 <pid_lock>
    80001be4:	fffff097          	auipc	ra,0xfffff
    80001be8:	f62080e7          	jalr	-158(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001bec:	00006597          	auipc	a1,0x6
    80001bf0:	69c58593          	addi	a1,a1,1692 # 80008288 <digits+0x248>
    80001bf4:	0000f517          	auipc	a0,0xf
    80001bf8:	00450513          	addi	a0,a0,4 # 80010bf8 <wait_lock>
    80001bfc:	fffff097          	auipc	ra,0xfffff
    80001c00:	f4a080e7          	jalr	-182(ra) # 80000b46 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c04:	0000f497          	auipc	s1,0xf
    80001c08:	40c48493          	addi	s1,s1,1036 # 80011010 <proc>
      initlock(&p->lock, "proc");
    80001c0c:	00006b17          	auipc	s6,0x6
    80001c10:	68cb0b13          	addi	s6,s6,1676 # 80008298 <digits+0x258>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001c14:	8aa6                	mv	s5,s1
    80001c16:	00006a17          	auipc	s4,0x6
    80001c1a:	3eaa0a13          	addi	s4,s4,1002 # 80008000 <etext>
    80001c1e:	04000937          	lui	s2,0x4000
    80001c22:	197d                	addi	s2,s2,-1
    80001c24:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c26:	00015997          	auipc	s3,0x15
    80001c2a:	dea98993          	addi	s3,s3,-534 # 80016a10 <tickslock>
      initlock(&p->lock, "proc");
    80001c2e:	85da                	mv	a1,s6
    80001c30:	8526                	mv	a0,s1
    80001c32:	fffff097          	auipc	ra,0xfffff
    80001c36:	f14080e7          	jalr	-236(ra) # 80000b46 <initlock>
      p->state = UNUSED;
    80001c3a:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001c3e:	415487b3          	sub	a5,s1,s5
    80001c42:	878d                	srai	a5,a5,0x3
    80001c44:	000a3703          	ld	a4,0(s4)
    80001c48:	02e787b3          	mul	a5,a5,a4
    80001c4c:	2785                	addiw	a5,a5,1
    80001c4e:	00d7979b          	slliw	a5,a5,0xd
    80001c52:	40f907b3          	sub	a5,s2,a5
    80001c56:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c58:	16848493          	addi	s1,s1,360
    80001c5c:	fd3499e3          	bne	s1,s3,80001c2e <procinit+0x6e>
  }
}
    80001c60:	70e2                	ld	ra,56(sp)
    80001c62:	7442                	ld	s0,48(sp)
    80001c64:	74a2                	ld	s1,40(sp)
    80001c66:	7902                	ld	s2,32(sp)
    80001c68:	69e2                	ld	s3,24(sp)
    80001c6a:	6a42                	ld	s4,16(sp)
    80001c6c:	6aa2                	ld	s5,8(sp)
    80001c6e:	6b02                	ld	s6,0(sp)
    80001c70:	6121                	addi	sp,sp,64
    80001c72:	8082                	ret

0000000080001c74 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001c74:	1141                	addi	sp,sp,-16
    80001c76:	e422                	sd	s0,8(sp)
    80001c78:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001c7a:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001c7c:	2501                	sext.w	a0,a0
    80001c7e:	6422                	ld	s0,8(sp)
    80001c80:	0141                	addi	sp,sp,16
    80001c82:	8082                	ret

0000000080001c84 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001c84:	1141                	addi	sp,sp,-16
    80001c86:	e422                	sd	s0,8(sp)
    80001c88:	0800                	addi	s0,sp,16
    80001c8a:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001c8c:	2781                	sext.w	a5,a5
    80001c8e:	079e                	slli	a5,a5,0x7
  return c;
}
    80001c90:	0000f517          	auipc	a0,0xf
    80001c94:	f8050513          	addi	a0,a0,-128 # 80010c10 <cpus>
    80001c98:	953e                	add	a0,a0,a5
    80001c9a:	6422                	ld	s0,8(sp)
    80001c9c:	0141                	addi	sp,sp,16
    80001c9e:	8082                	ret

0000000080001ca0 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    80001ca0:	1101                	addi	sp,sp,-32
    80001ca2:	ec06                	sd	ra,24(sp)
    80001ca4:	e822                	sd	s0,16(sp)
    80001ca6:	e426                	sd	s1,8(sp)
    80001ca8:	1000                	addi	s0,sp,32
  push_off();
    80001caa:	fffff097          	auipc	ra,0xfffff
    80001cae:	ee0080e7          	jalr	-288(ra) # 80000b8a <push_off>
    80001cb2:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001cb4:	2781                	sext.w	a5,a5
    80001cb6:	079e                	slli	a5,a5,0x7
    80001cb8:	0000f717          	auipc	a4,0xf
    80001cbc:	f2870713          	addi	a4,a4,-216 # 80010be0 <pid_lock>
    80001cc0:	97ba                	add	a5,a5,a4
    80001cc2:	7b84                	ld	s1,48(a5)
  pop_off();
    80001cc4:	fffff097          	auipc	ra,0xfffff
    80001cc8:	f66080e7          	jalr	-154(ra) # 80000c2a <pop_off>
  return p;
}
    80001ccc:	8526                	mv	a0,s1
    80001cce:	60e2                	ld	ra,24(sp)
    80001cd0:	6442                	ld	s0,16(sp)
    80001cd2:	64a2                	ld	s1,8(sp)
    80001cd4:	6105                	addi	sp,sp,32
    80001cd6:	8082                	ret

0000000080001cd8 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001cd8:	1141                	addi	sp,sp,-16
    80001cda:	e406                	sd	ra,8(sp)
    80001cdc:	e022                	sd	s0,0(sp)
    80001cde:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001ce0:	00000097          	auipc	ra,0x0
    80001ce4:	fc0080e7          	jalr	-64(ra) # 80001ca0 <myproc>
    80001ce8:	fffff097          	auipc	ra,0xfffff
    80001cec:	fa2080e7          	jalr	-94(ra) # 80000c8a <release>

  if (first) {
    80001cf0:	00007797          	auipc	a5,0x7
    80001cf4:	c007a783          	lw	a5,-1024(a5) # 800088f0 <first.1>
    80001cf8:	eb89                	bnez	a5,80001d0a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001cfa:	00001097          	auipc	ra,0x1
    80001cfe:	c74080e7          	jalr	-908(ra) # 8000296e <usertrapret>
}
    80001d02:	60a2                	ld	ra,8(sp)
    80001d04:	6402                	ld	s0,0(sp)
    80001d06:	0141                	addi	sp,sp,16
    80001d08:	8082                	ret
    first = 0;
    80001d0a:	00007797          	auipc	a5,0x7
    80001d0e:	be07a323          	sw	zero,-1050(a5) # 800088f0 <first.1>
    fsinit(ROOTDEV);
    80001d12:	4505                	li	a0,1
    80001d14:	00002097          	auipc	ra,0x2
    80001d18:	ad8080e7          	jalr	-1320(ra) # 800037ec <fsinit>
    80001d1c:	bff9                	j	80001cfa <forkret+0x22>

0000000080001d1e <allocpid>:
{
    80001d1e:	1101                	addi	sp,sp,-32
    80001d20:	ec06                	sd	ra,24(sp)
    80001d22:	e822                	sd	s0,16(sp)
    80001d24:	e426                	sd	s1,8(sp)
    80001d26:	e04a                	sd	s2,0(sp)
    80001d28:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001d2a:	0000f917          	auipc	s2,0xf
    80001d2e:	eb690913          	addi	s2,s2,-330 # 80010be0 <pid_lock>
    80001d32:	854a                	mv	a0,s2
    80001d34:	fffff097          	auipc	ra,0xfffff
    80001d38:	ea2080e7          	jalr	-350(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001d3c:	00007797          	auipc	a5,0x7
    80001d40:	bb878793          	addi	a5,a5,-1096 # 800088f4 <nextpid>
    80001d44:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001d46:	0014871b          	addiw	a4,s1,1
    80001d4a:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001d4c:	854a                	mv	a0,s2
    80001d4e:	fffff097          	auipc	ra,0xfffff
    80001d52:	f3c080e7          	jalr	-196(ra) # 80000c8a <release>
}
    80001d56:	8526                	mv	a0,s1
    80001d58:	60e2                	ld	ra,24(sp)
    80001d5a:	6442                	ld	s0,16(sp)
    80001d5c:	64a2                	ld	s1,8(sp)
    80001d5e:	6902                	ld	s2,0(sp)
    80001d60:	6105                	addi	sp,sp,32
    80001d62:	8082                	ret

0000000080001d64 <proc_pagetable>:
{
    80001d64:	1101                	addi	sp,sp,-32
    80001d66:	ec06                	sd	ra,24(sp)
    80001d68:	e822                	sd	s0,16(sp)
    80001d6a:	e426                	sd	s1,8(sp)
    80001d6c:	e04a                	sd	s2,0(sp)
    80001d6e:	1000                	addi	s0,sp,32
    80001d70:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001d72:	fffff097          	auipc	ra,0xfffff
    80001d76:	5be080e7          	jalr	1470(ra) # 80001330 <uvmcreate>
    80001d7a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001d7c:	c121                	beqz	a0,80001dbc <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001d7e:	4729                	li	a4,10
    80001d80:	00005697          	auipc	a3,0x5
    80001d84:	28068693          	addi	a3,a3,640 # 80007000 <_trampoline>
    80001d88:	6605                	lui	a2,0x1
    80001d8a:	040005b7          	lui	a1,0x4000
    80001d8e:	15fd                	addi	a1,a1,-1
    80001d90:	05b2                	slli	a1,a1,0xc
    80001d92:	fffff097          	auipc	ra,0xfffff
    80001d96:	30c080e7          	jalr	780(ra) # 8000109e <mappages>
    80001d9a:	02054863          	bltz	a0,80001dca <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001d9e:	4719                	li	a4,6
    80001da0:	05893683          	ld	a3,88(s2)
    80001da4:	6605                	lui	a2,0x1
    80001da6:	020005b7          	lui	a1,0x2000
    80001daa:	15fd                	addi	a1,a1,-1
    80001dac:	05b6                	slli	a1,a1,0xd
    80001dae:	8526                	mv	a0,s1
    80001db0:	fffff097          	auipc	ra,0xfffff
    80001db4:	2ee080e7          	jalr	750(ra) # 8000109e <mappages>
    80001db8:	02054163          	bltz	a0,80001dda <proc_pagetable+0x76>
}
    80001dbc:	8526                	mv	a0,s1
    80001dbe:	60e2                	ld	ra,24(sp)
    80001dc0:	6442                	ld	s0,16(sp)
    80001dc2:	64a2                	ld	s1,8(sp)
    80001dc4:	6902                	ld	s2,0(sp)
    80001dc6:	6105                	addi	sp,sp,32
    80001dc8:	8082                	ret
    uvmfree(pagetable, 0);
    80001dca:	4581                	li	a1,0
    80001dcc:	8526                	mv	a0,s1
    80001dce:	fffff097          	auipc	ra,0xfffff
    80001dd2:	766080e7          	jalr	1894(ra) # 80001534 <uvmfree>
    return 0;
    80001dd6:	4481                	li	s1,0
    80001dd8:	b7d5                	j	80001dbc <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001dda:	4681                	li	a3,0
    80001ddc:	4605                	li	a2,1
    80001dde:	040005b7          	lui	a1,0x4000
    80001de2:	15fd                	addi	a1,a1,-1
    80001de4:	05b2                	slli	a1,a1,0xc
    80001de6:	8526                	mv	a0,s1
    80001de8:	fffff097          	auipc	ra,0xfffff
    80001dec:	47c080e7          	jalr	1148(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, 0);
    80001df0:	4581                	li	a1,0
    80001df2:	8526                	mv	a0,s1
    80001df4:	fffff097          	auipc	ra,0xfffff
    80001df8:	740080e7          	jalr	1856(ra) # 80001534 <uvmfree>
    return 0;
    80001dfc:	4481                	li	s1,0
    80001dfe:	bf7d                	j	80001dbc <proc_pagetable+0x58>

0000000080001e00 <proc_freepagetable>:
{
    80001e00:	1101                	addi	sp,sp,-32
    80001e02:	ec06                	sd	ra,24(sp)
    80001e04:	e822                	sd	s0,16(sp)
    80001e06:	e426                	sd	s1,8(sp)
    80001e08:	e04a                	sd	s2,0(sp)
    80001e0a:	1000                	addi	s0,sp,32
    80001e0c:	84aa                	mv	s1,a0
    80001e0e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001e10:	4681                	li	a3,0
    80001e12:	4605                	li	a2,1
    80001e14:	040005b7          	lui	a1,0x4000
    80001e18:	15fd                	addi	a1,a1,-1
    80001e1a:	05b2                	slli	a1,a1,0xc
    80001e1c:	fffff097          	auipc	ra,0xfffff
    80001e20:	448080e7          	jalr	1096(ra) # 80001264 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001e24:	4681                	li	a3,0
    80001e26:	4605                	li	a2,1
    80001e28:	020005b7          	lui	a1,0x2000
    80001e2c:	15fd                	addi	a1,a1,-1
    80001e2e:	05b6                	slli	a1,a1,0xd
    80001e30:	8526                	mv	a0,s1
    80001e32:	fffff097          	auipc	ra,0xfffff
    80001e36:	432080e7          	jalr	1074(ra) # 80001264 <uvmunmap>
  uvmfree(pagetable, sz);
    80001e3a:	85ca                	mv	a1,s2
    80001e3c:	8526                	mv	a0,s1
    80001e3e:	fffff097          	auipc	ra,0xfffff
    80001e42:	6f6080e7          	jalr	1782(ra) # 80001534 <uvmfree>
}
    80001e46:	60e2                	ld	ra,24(sp)
    80001e48:	6442                	ld	s0,16(sp)
    80001e4a:	64a2                	ld	s1,8(sp)
    80001e4c:	6902                	ld	s2,0(sp)
    80001e4e:	6105                	addi	sp,sp,32
    80001e50:	8082                	ret

0000000080001e52 <freeproc>:
{
    80001e52:	1101                	addi	sp,sp,-32
    80001e54:	ec06                	sd	ra,24(sp)
    80001e56:	e822                	sd	s0,16(sp)
    80001e58:	e426                	sd	s1,8(sp)
    80001e5a:	1000                	addi	s0,sp,32
    80001e5c:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001e5e:	6d28                	ld	a0,88(a0)
    80001e60:	c509                	beqz	a0,80001e6a <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001e62:	fffff097          	auipc	ra,0xfffff
    80001e66:	b88080e7          	jalr	-1144(ra) # 800009ea <kfree>
  p->trapframe = 0;
    80001e6a:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001e6e:	68a8                	ld	a0,80(s1)
    80001e70:	c511                	beqz	a0,80001e7c <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001e72:	64ac                	ld	a1,72(s1)
    80001e74:	00000097          	auipc	ra,0x0
    80001e78:	f8c080e7          	jalr	-116(ra) # 80001e00 <proc_freepagetable>
  p->pagetable = 0;
    80001e7c:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001e80:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001e84:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001e88:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001e8c:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001e90:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001e94:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001e98:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001e9c:	0004ac23          	sw	zero,24(s1)
}
    80001ea0:	60e2                	ld	ra,24(sp)
    80001ea2:	6442                	ld	s0,16(sp)
    80001ea4:	64a2                	ld	s1,8(sp)
    80001ea6:	6105                	addi	sp,sp,32
    80001ea8:	8082                	ret

0000000080001eaa <allocproc>:
{
    80001eaa:	1101                	addi	sp,sp,-32
    80001eac:	ec06                	sd	ra,24(sp)
    80001eae:	e822                	sd	s0,16(sp)
    80001eb0:	e426                	sd	s1,8(sp)
    80001eb2:	e04a                	sd	s2,0(sp)
    80001eb4:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001eb6:	0000f497          	auipc	s1,0xf
    80001eba:	15a48493          	addi	s1,s1,346 # 80011010 <proc>
    80001ebe:	00015917          	auipc	s2,0x15
    80001ec2:	b5290913          	addi	s2,s2,-1198 # 80016a10 <tickslock>
    acquire(&p->lock);
    80001ec6:	8526                	mv	a0,s1
    80001ec8:	fffff097          	auipc	ra,0xfffff
    80001ecc:	d0e080e7          	jalr	-754(ra) # 80000bd6 <acquire>
    if(p->state == UNUSED) {
    80001ed0:	4c9c                	lw	a5,24(s1)
    80001ed2:	cf81                	beqz	a5,80001eea <allocproc+0x40>
      release(&p->lock);
    80001ed4:	8526                	mv	a0,s1
    80001ed6:	fffff097          	auipc	ra,0xfffff
    80001eda:	db4080e7          	jalr	-588(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ede:	16848493          	addi	s1,s1,360
    80001ee2:	ff2492e3          	bne	s1,s2,80001ec6 <allocproc+0x1c>
  return 0;
    80001ee6:	4481                	li	s1,0
    80001ee8:	a889                	j	80001f3a <allocproc+0x90>
  p->pid = allocpid();
    80001eea:	00000097          	auipc	ra,0x0
    80001eee:	e34080e7          	jalr	-460(ra) # 80001d1e <allocpid>
    80001ef2:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001ef4:	4785                	li	a5,1
    80001ef6:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001ef8:	fffff097          	auipc	ra,0xfffff
    80001efc:	bee080e7          	jalr	-1042(ra) # 80000ae6 <kalloc>
    80001f00:	892a                	mv	s2,a0
    80001f02:	eca8                	sd	a0,88(s1)
    80001f04:	c131                	beqz	a0,80001f48 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001f06:	8526                	mv	a0,s1
    80001f08:	00000097          	auipc	ra,0x0
    80001f0c:	e5c080e7          	jalr	-420(ra) # 80001d64 <proc_pagetable>
    80001f10:	892a                	mv	s2,a0
    80001f12:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001f14:	c531                	beqz	a0,80001f60 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001f16:	07000613          	li	a2,112
    80001f1a:	4581                	li	a1,0
    80001f1c:	06048513          	addi	a0,s1,96
    80001f20:	fffff097          	auipc	ra,0xfffff
    80001f24:	db2080e7          	jalr	-590(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001f28:	00000797          	auipc	a5,0x0
    80001f2c:	db078793          	addi	a5,a5,-592 # 80001cd8 <forkret>
    80001f30:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001f32:	60bc                	ld	a5,64(s1)
    80001f34:	6705                	lui	a4,0x1
    80001f36:	97ba                	add	a5,a5,a4
    80001f38:	f4bc                	sd	a5,104(s1)
}
    80001f3a:	8526                	mv	a0,s1
    80001f3c:	60e2                	ld	ra,24(sp)
    80001f3e:	6442                	ld	s0,16(sp)
    80001f40:	64a2                	ld	s1,8(sp)
    80001f42:	6902                	ld	s2,0(sp)
    80001f44:	6105                	addi	sp,sp,32
    80001f46:	8082                	ret
    freeproc(p);
    80001f48:	8526                	mv	a0,s1
    80001f4a:	00000097          	auipc	ra,0x0
    80001f4e:	f08080e7          	jalr	-248(ra) # 80001e52 <freeproc>
    release(&p->lock);
    80001f52:	8526                	mv	a0,s1
    80001f54:	fffff097          	auipc	ra,0xfffff
    80001f58:	d36080e7          	jalr	-714(ra) # 80000c8a <release>
    return 0;
    80001f5c:	84ca                	mv	s1,s2
    80001f5e:	bff1                	j	80001f3a <allocproc+0x90>
    freeproc(p);
    80001f60:	8526                	mv	a0,s1
    80001f62:	00000097          	auipc	ra,0x0
    80001f66:	ef0080e7          	jalr	-272(ra) # 80001e52 <freeproc>
    release(&p->lock);
    80001f6a:	8526                	mv	a0,s1
    80001f6c:	fffff097          	auipc	ra,0xfffff
    80001f70:	d1e080e7          	jalr	-738(ra) # 80000c8a <release>
    return 0;
    80001f74:	84ca                	mv	s1,s2
    80001f76:	b7d1                	j	80001f3a <allocproc+0x90>

0000000080001f78 <userinit>:
{
    80001f78:	1101                	addi	sp,sp,-32
    80001f7a:	ec06                	sd	ra,24(sp)
    80001f7c:	e822                	sd	s0,16(sp)
    80001f7e:	e426                	sd	s1,8(sp)
    80001f80:	1000                	addi	s0,sp,32
  p = allocproc();
    80001f82:	00000097          	auipc	ra,0x0
    80001f86:	f28080e7          	jalr	-216(ra) # 80001eaa <allocproc>
    80001f8a:	84aa                	mv	s1,a0
  initproc = p;
    80001f8c:	00007797          	auipc	a5,0x7
    80001f90:	9ca7be23          	sd	a0,-1572(a5) # 80008968 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001f94:	03400613          	li	a2,52
    80001f98:	00007597          	auipc	a1,0x7
    80001f9c:	96858593          	addi	a1,a1,-1688 # 80008900 <initcode>
    80001fa0:	6928                	ld	a0,80(a0)
    80001fa2:	fffff097          	auipc	ra,0xfffff
    80001fa6:	3bc080e7          	jalr	956(ra) # 8000135e <uvmfirst>
  p->sz = PGSIZE;
    80001faa:	6785                	lui	a5,0x1
    80001fac:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001fae:	6cb8                	ld	a4,88(s1)
    80001fb0:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001fb4:	6cb8                	ld	a4,88(s1)
    80001fb6:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001fb8:	4641                	li	a2,16
    80001fba:	00006597          	auipc	a1,0x6
    80001fbe:	2e658593          	addi	a1,a1,742 # 800082a0 <digits+0x260>
    80001fc2:	15848513          	addi	a0,s1,344
    80001fc6:	fffff097          	auipc	ra,0xfffff
    80001fca:	e56080e7          	jalr	-426(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001fce:	00006517          	auipc	a0,0x6
    80001fd2:	2e250513          	addi	a0,a0,738 # 800082b0 <digits+0x270>
    80001fd6:	00002097          	auipc	ra,0x2
    80001fda:	238080e7          	jalr	568(ra) # 8000420e <namei>
    80001fde:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001fe2:	478d                	li	a5,3
    80001fe4:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001fe6:	8526                	mv	a0,s1
    80001fe8:	fffff097          	auipc	ra,0xfffff
    80001fec:	ca2080e7          	jalr	-862(ra) # 80000c8a <release>
}
    80001ff0:	60e2                	ld	ra,24(sp)
    80001ff2:	6442                	ld	s0,16(sp)
    80001ff4:	64a2                	ld	s1,8(sp)
    80001ff6:	6105                	addi	sp,sp,32
    80001ff8:	8082                	ret

0000000080001ffa <growproc>:
{
    80001ffa:	1101                	addi	sp,sp,-32
    80001ffc:	ec06                	sd	ra,24(sp)
    80001ffe:	e822                	sd	s0,16(sp)
    80002000:	e426                	sd	s1,8(sp)
    80002002:	e04a                	sd	s2,0(sp)
    80002004:	1000                	addi	s0,sp,32
    80002006:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80002008:	00000097          	auipc	ra,0x0
    8000200c:	c98080e7          	jalr	-872(ra) # 80001ca0 <myproc>
    80002010:	84aa                	mv	s1,a0
  sz = p->sz;
    80002012:	652c                	ld	a1,72(a0)
  if(n > 0){
    80002014:	01204c63          	bgtz	s2,8000202c <growproc+0x32>
  } else if(n < 0){
    80002018:	02094663          	bltz	s2,80002044 <growproc+0x4a>
  p->sz = sz;
    8000201c:	e4ac                	sd	a1,72(s1)
  return 0;
    8000201e:	4501                	li	a0,0
}
    80002020:	60e2                	ld	ra,24(sp)
    80002022:	6442                	ld	s0,16(sp)
    80002024:	64a2                	ld	s1,8(sp)
    80002026:	6902                	ld	s2,0(sp)
    80002028:	6105                	addi	sp,sp,32
    8000202a:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    8000202c:	4691                	li	a3,4
    8000202e:	00b90633          	add	a2,s2,a1
    80002032:	6928                	ld	a0,80(a0)
    80002034:	fffff097          	auipc	ra,0xfffff
    80002038:	3e4080e7          	jalr	996(ra) # 80001418 <uvmalloc>
    8000203c:	85aa                	mv	a1,a0
    8000203e:	fd79                	bnez	a0,8000201c <growproc+0x22>
      return -1;
    80002040:	557d                	li	a0,-1
    80002042:	bff9                	j	80002020 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80002044:	00b90633          	add	a2,s2,a1
    80002048:	6928                	ld	a0,80(a0)
    8000204a:	fffff097          	auipc	ra,0xfffff
    8000204e:	386080e7          	jalr	902(ra) # 800013d0 <uvmdealloc>
    80002052:	85aa                	mv	a1,a0
    80002054:	b7e1                	j	8000201c <growproc+0x22>

0000000080002056 <fork>:
{
    80002056:	7139                	addi	sp,sp,-64
    80002058:	fc06                	sd	ra,56(sp)
    8000205a:	f822                	sd	s0,48(sp)
    8000205c:	f426                	sd	s1,40(sp)
    8000205e:	f04a                	sd	s2,32(sp)
    80002060:	ec4e                	sd	s3,24(sp)
    80002062:	e852                	sd	s4,16(sp)
    80002064:	e456                	sd	s5,8(sp)
    80002066:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80002068:	00000097          	auipc	ra,0x0
    8000206c:	c38080e7          	jalr	-968(ra) # 80001ca0 <myproc>
    80002070:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80002072:	00000097          	auipc	ra,0x0
    80002076:	e38080e7          	jalr	-456(ra) # 80001eaa <allocproc>
    8000207a:	10050c63          	beqz	a0,80002192 <fork+0x13c>
    8000207e:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002080:	048ab603          	ld	a2,72(s5)
    80002084:	692c                	ld	a1,80(a0)
    80002086:	050ab503          	ld	a0,80(s5)
    8000208a:	fffff097          	auipc	ra,0xfffff
    8000208e:	4e2080e7          	jalr	1250(ra) # 8000156c <uvmcopy>
    80002092:	04054863          	bltz	a0,800020e2 <fork+0x8c>
  np->sz = p->sz;
    80002096:	048ab783          	ld	a5,72(s5)
    8000209a:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    8000209e:	058ab683          	ld	a3,88(s5)
    800020a2:	87b6                	mv	a5,a3
    800020a4:	058a3703          	ld	a4,88(s4)
    800020a8:	12068693          	addi	a3,a3,288
    800020ac:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    800020b0:	6788                	ld	a0,8(a5)
    800020b2:	6b8c                	ld	a1,16(a5)
    800020b4:	6f90                	ld	a2,24(a5)
    800020b6:	01073023          	sd	a6,0(a4)
    800020ba:	e708                	sd	a0,8(a4)
    800020bc:	eb0c                	sd	a1,16(a4)
    800020be:	ef10                	sd	a2,24(a4)
    800020c0:	02078793          	addi	a5,a5,32
    800020c4:	02070713          	addi	a4,a4,32
    800020c8:	fed792e3          	bne	a5,a3,800020ac <fork+0x56>
  np->trapframe->a0 = 0;
    800020cc:	058a3783          	ld	a5,88(s4)
    800020d0:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    800020d4:	0d0a8493          	addi	s1,s5,208
    800020d8:	0d0a0913          	addi	s2,s4,208
    800020dc:	150a8993          	addi	s3,s5,336
    800020e0:	a00d                	j	80002102 <fork+0xac>
    freeproc(np);
    800020e2:	8552                	mv	a0,s4
    800020e4:	00000097          	auipc	ra,0x0
    800020e8:	d6e080e7          	jalr	-658(ra) # 80001e52 <freeproc>
    release(&np->lock);
    800020ec:	8552                	mv	a0,s4
    800020ee:	fffff097          	auipc	ra,0xfffff
    800020f2:	b9c080e7          	jalr	-1124(ra) # 80000c8a <release>
    return -1;
    800020f6:	597d                	li	s2,-1
    800020f8:	a059                	j	8000217e <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    800020fa:	04a1                	addi	s1,s1,8
    800020fc:	0921                	addi	s2,s2,8
    800020fe:	01348b63          	beq	s1,s3,80002114 <fork+0xbe>
    if(p->ofile[i])
    80002102:	6088                	ld	a0,0(s1)
    80002104:	d97d                	beqz	a0,800020fa <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80002106:	00002097          	auipc	ra,0x2
    8000210a:	79e080e7          	jalr	1950(ra) # 800048a4 <filedup>
    8000210e:	00a93023          	sd	a0,0(s2)
    80002112:	b7e5                	j	800020fa <fork+0xa4>
  np->cwd = idup(p->cwd);
    80002114:	150ab503          	ld	a0,336(s5)
    80002118:	00002097          	auipc	ra,0x2
    8000211c:	912080e7          	jalr	-1774(ra) # 80003a2a <idup>
    80002120:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002124:	4641                	li	a2,16
    80002126:	158a8593          	addi	a1,s5,344
    8000212a:	158a0513          	addi	a0,s4,344
    8000212e:	fffff097          	auipc	ra,0xfffff
    80002132:	cee080e7          	jalr	-786(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80002136:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    8000213a:	8552                	mv	a0,s4
    8000213c:	fffff097          	auipc	ra,0xfffff
    80002140:	b4e080e7          	jalr	-1202(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80002144:	0000f497          	auipc	s1,0xf
    80002148:	ab448493          	addi	s1,s1,-1356 # 80010bf8 <wait_lock>
    8000214c:	8526                	mv	a0,s1
    8000214e:	fffff097          	auipc	ra,0xfffff
    80002152:	a88080e7          	jalr	-1400(ra) # 80000bd6 <acquire>
  np->parent = p;
    80002156:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    8000215a:	8526                	mv	a0,s1
    8000215c:	fffff097          	auipc	ra,0xfffff
    80002160:	b2e080e7          	jalr	-1234(ra) # 80000c8a <release>
  acquire(&np->lock);
    80002164:	8552                	mv	a0,s4
    80002166:	fffff097          	auipc	ra,0xfffff
    8000216a:	a70080e7          	jalr	-1424(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    8000216e:	478d                	li	a5,3
    80002170:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80002174:	8552                	mv	a0,s4
    80002176:	fffff097          	auipc	ra,0xfffff
    8000217a:	b14080e7          	jalr	-1260(ra) # 80000c8a <release>
}
    8000217e:	854a                	mv	a0,s2
    80002180:	70e2                	ld	ra,56(sp)
    80002182:	7442                	ld	s0,48(sp)
    80002184:	74a2                	ld	s1,40(sp)
    80002186:	7902                	ld	s2,32(sp)
    80002188:	69e2                	ld	s3,24(sp)
    8000218a:	6a42                	ld	s4,16(sp)
    8000218c:	6aa2                	ld	s5,8(sp)
    8000218e:	6121                	addi	sp,sp,64
    80002190:	8082                	ret
    return -1;
    80002192:	597d                	li	s2,-1
    80002194:	b7ed                	j	8000217e <fork+0x128>

0000000080002196 <scheduler>:
{
    80002196:	7139                	addi	sp,sp,-64
    80002198:	fc06                	sd	ra,56(sp)
    8000219a:	f822                	sd	s0,48(sp)
    8000219c:	f426                	sd	s1,40(sp)
    8000219e:	f04a                	sd	s2,32(sp)
    800021a0:	ec4e                	sd	s3,24(sp)
    800021a2:	e852                	sd	s4,16(sp)
    800021a4:	e456                	sd	s5,8(sp)
    800021a6:	e05a                	sd	s6,0(sp)
    800021a8:	0080                	addi	s0,sp,64
    800021aa:	8792                	mv	a5,tp
  int id = r_tp();
    800021ac:	2781                	sext.w	a5,a5
  c->proc = 0;
    800021ae:	00779a93          	slli	s5,a5,0x7
    800021b2:	0000f717          	auipc	a4,0xf
    800021b6:	a2e70713          	addi	a4,a4,-1490 # 80010be0 <pid_lock>
    800021ba:	9756                	add	a4,a4,s5
    800021bc:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    800021c0:	0000f717          	auipc	a4,0xf
    800021c4:	a5870713          	addi	a4,a4,-1448 # 80010c18 <cpus+0x8>
    800021c8:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    800021ca:	498d                	li	s3,3
        p->state = RUNNING;
    800021cc:	4b11                	li	s6,4
        c->proc = p;
    800021ce:	079e                	slli	a5,a5,0x7
    800021d0:	0000fa17          	auipc	s4,0xf
    800021d4:	a10a0a13          	addi	s4,s4,-1520 # 80010be0 <pid_lock>
    800021d8:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    800021da:	00015917          	auipc	s2,0x15
    800021de:	83690913          	addi	s2,s2,-1994 # 80016a10 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021e2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800021e6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800021ea:	10079073          	csrw	sstatus,a5
    800021ee:	0000f497          	auipc	s1,0xf
    800021f2:	e2248493          	addi	s1,s1,-478 # 80011010 <proc>
    800021f6:	a811                	j	8000220a <scheduler+0x74>
      release(&p->lock);
    800021f8:	8526                	mv	a0,s1
    800021fa:	fffff097          	auipc	ra,0xfffff
    800021fe:	a90080e7          	jalr	-1392(ra) # 80000c8a <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002202:	16848493          	addi	s1,s1,360
    80002206:	fd248ee3          	beq	s1,s2,800021e2 <scheduler+0x4c>
      acquire(&p->lock);
    8000220a:	8526                	mv	a0,s1
    8000220c:	fffff097          	auipc	ra,0xfffff
    80002210:	9ca080e7          	jalr	-1590(ra) # 80000bd6 <acquire>
      if(p->state == RUNNABLE) {
    80002214:	4c9c                	lw	a5,24(s1)
    80002216:	ff3791e3          	bne	a5,s3,800021f8 <scheduler+0x62>
        p->state = RUNNING;
    8000221a:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    8000221e:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80002222:	06048593          	addi	a1,s1,96
    80002226:	8556                	mv	a0,s5
    80002228:	00000097          	auipc	ra,0x0
    8000222c:	69c080e7          	jalr	1692(ra) # 800028c4 <swtch>
        c->proc = 0;
    80002230:	020a3823          	sd	zero,48(s4)
    80002234:	b7d1                	j	800021f8 <scheduler+0x62>

0000000080002236 <sched>:
{
    80002236:	7179                	addi	sp,sp,-48
    80002238:	f406                	sd	ra,40(sp)
    8000223a:	f022                	sd	s0,32(sp)
    8000223c:	ec26                	sd	s1,24(sp)
    8000223e:	e84a                	sd	s2,16(sp)
    80002240:	e44e                	sd	s3,8(sp)
    80002242:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002244:	00000097          	auipc	ra,0x0
    80002248:	a5c080e7          	jalr	-1444(ra) # 80001ca0 <myproc>
    8000224c:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000224e:	fffff097          	auipc	ra,0xfffff
    80002252:	90e080e7          	jalr	-1778(ra) # 80000b5c <holding>
    80002256:	c93d                	beqz	a0,800022cc <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002258:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000225a:	2781                	sext.w	a5,a5
    8000225c:	079e                	slli	a5,a5,0x7
    8000225e:	0000f717          	auipc	a4,0xf
    80002262:	98270713          	addi	a4,a4,-1662 # 80010be0 <pid_lock>
    80002266:	97ba                	add	a5,a5,a4
    80002268:	0a87a703          	lw	a4,168(a5)
    8000226c:	4785                	li	a5,1
    8000226e:	06f71763          	bne	a4,a5,800022dc <sched+0xa6>
  if(p->state == RUNNING)
    80002272:	4c98                	lw	a4,24(s1)
    80002274:	4791                	li	a5,4
    80002276:	06f70b63          	beq	a4,a5,800022ec <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000227a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000227e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002280:	efb5                	bnez	a5,800022fc <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002282:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002284:	0000f917          	auipc	s2,0xf
    80002288:	95c90913          	addi	s2,s2,-1700 # 80010be0 <pid_lock>
    8000228c:	2781                	sext.w	a5,a5
    8000228e:	079e                	slli	a5,a5,0x7
    80002290:	97ca                	add	a5,a5,s2
    80002292:	0ac7a983          	lw	s3,172(a5)
    80002296:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002298:	2781                	sext.w	a5,a5
    8000229a:	079e                	slli	a5,a5,0x7
    8000229c:	0000f597          	auipc	a1,0xf
    800022a0:	97c58593          	addi	a1,a1,-1668 # 80010c18 <cpus+0x8>
    800022a4:	95be                	add	a1,a1,a5
    800022a6:	06048513          	addi	a0,s1,96
    800022aa:	00000097          	auipc	ra,0x0
    800022ae:	61a080e7          	jalr	1562(ra) # 800028c4 <swtch>
    800022b2:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800022b4:	2781                	sext.w	a5,a5
    800022b6:	079e                	slli	a5,a5,0x7
    800022b8:	97ca                	add	a5,a5,s2
    800022ba:	0b37a623          	sw	s3,172(a5)
}
    800022be:	70a2                	ld	ra,40(sp)
    800022c0:	7402                	ld	s0,32(sp)
    800022c2:	64e2                	ld	s1,24(sp)
    800022c4:	6942                	ld	s2,16(sp)
    800022c6:	69a2                	ld	s3,8(sp)
    800022c8:	6145                	addi	sp,sp,48
    800022ca:	8082                	ret
    panic("sched p->lock");
    800022cc:	00006517          	auipc	a0,0x6
    800022d0:	fec50513          	addi	a0,a0,-20 # 800082b8 <digits+0x278>
    800022d4:	ffffe097          	auipc	ra,0xffffe
    800022d8:	26a080e7          	jalr	618(ra) # 8000053e <panic>
    panic("sched locks");
    800022dc:	00006517          	auipc	a0,0x6
    800022e0:	fec50513          	addi	a0,a0,-20 # 800082c8 <digits+0x288>
    800022e4:	ffffe097          	auipc	ra,0xffffe
    800022e8:	25a080e7          	jalr	602(ra) # 8000053e <panic>
    panic("sched running");
    800022ec:	00006517          	auipc	a0,0x6
    800022f0:	fec50513          	addi	a0,a0,-20 # 800082d8 <digits+0x298>
    800022f4:	ffffe097          	auipc	ra,0xffffe
    800022f8:	24a080e7          	jalr	586(ra) # 8000053e <panic>
    panic("sched interruptible");
    800022fc:	00006517          	auipc	a0,0x6
    80002300:	fec50513          	addi	a0,a0,-20 # 800082e8 <digits+0x2a8>
    80002304:	ffffe097          	auipc	ra,0xffffe
    80002308:	23a080e7          	jalr	570(ra) # 8000053e <panic>

000000008000230c <yield>:
{
    8000230c:	1101                	addi	sp,sp,-32
    8000230e:	ec06                	sd	ra,24(sp)
    80002310:	e822                	sd	s0,16(sp)
    80002312:	e426                	sd	s1,8(sp)
    80002314:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002316:	00000097          	auipc	ra,0x0
    8000231a:	98a080e7          	jalr	-1654(ra) # 80001ca0 <myproc>
    8000231e:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002320:	fffff097          	auipc	ra,0xfffff
    80002324:	8b6080e7          	jalr	-1866(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    80002328:	478d                	li	a5,3
    8000232a:	cc9c                	sw	a5,24(s1)
  sched();
    8000232c:	00000097          	auipc	ra,0x0
    80002330:	f0a080e7          	jalr	-246(ra) # 80002236 <sched>
  release(&p->lock);
    80002334:	8526                	mv	a0,s1
    80002336:	fffff097          	auipc	ra,0xfffff
    8000233a:	954080e7          	jalr	-1708(ra) # 80000c8a <release>
}
    8000233e:	60e2                	ld	ra,24(sp)
    80002340:	6442                	ld	s0,16(sp)
    80002342:	64a2                	ld	s1,8(sp)
    80002344:	6105                	addi	sp,sp,32
    80002346:	8082                	ret

0000000080002348 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002348:	7179                	addi	sp,sp,-48
    8000234a:	f406                	sd	ra,40(sp)
    8000234c:	f022                	sd	s0,32(sp)
    8000234e:	ec26                	sd	s1,24(sp)
    80002350:	e84a                	sd	s2,16(sp)
    80002352:	e44e                	sd	s3,8(sp)
    80002354:	1800                	addi	s0,sp,48
    80002356:	89aa                	mv	s3,a0
    80002358:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000235a:	00000097          	auipc	ra,0x0
    8000235e:	946080e7          	jalr	-1722(ra) # 80001ca0 <myproc>
    80002362:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002364:	fffff097          	auipc	ra,0xfffff
    80002368:	872080e7          	jalr	-1934(ra) # 80000bd6 <acquire>
  release(lk);
    8000236c:	854a                	mv	a0,s2
    8000236e:	fffff097          	auipc	ra,0xfffff
    80002372:	91c080e7          	jalr	-1764(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    80002376:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000237a:	4789                	li	a5,2
    8000237c:	cc9c                	sw	a5,24(s1)

  sched();
    8000237e:	00000097          	auipc	ra,0x0
    80002382:	eb8080e7          	jalr	-328(ra) # 80002236 <sched>

  // Tidy up.
  p->chan = 0;
    80002386:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000238a:	8526                	mv	a0,s1
    8000238c:	fffff097          	auipc	ra,0xfffff
    80002390:	8fe080e7          	jalr	-1794(ra) # 80000c8a <release>
  acquire(lk);
    80002394:	854a                	mv	a0,s2
    80002396:	fffff097          	auipc	ra,0xfffff
    8000239a:	840080e7          	jalr	-1984(ra) # 80000bd6 <acquire>
}
    8000239e:	70a2                	ld	ra,40(sp)
    800023a0:	7402                	ld	s0,32(sp)
    800023a2:	64e2                	ld	s1,24(sp)
    800023a4:	6942                	ld	s2,16(sp)
    800023a6:	69a2                	ld	s3,8(sp)
    800023a8:	6145                	addi	sp,sp,48
    800023aa:	8082                	ret

00000000800023ac <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800023ac:	7139                	addi	sp,sp,-64
    800023ae:	fc06                	sd	ra,56(sp)
    800023b0:	f822                	sd	s0,48(sp)
    800023b2:	f426                	sd	s1,40(sp)
    800023b4:	f04a                	sd	s2,32(sp)
    800023b6:	ec4e                	sd	s3,24(sp)
    800023b8:	e852                	sd	s4,16(sp)
    800023ba:	e456                	sd	s5,8(sp)
    800023bc:	0080                	addi	s0,sp,64
    800023be:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800023c0:	0000f497          	auipc	s1,0xf
    800023c4:	c5048493          	addi	s1,s1,-944 # 80011010 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800023c8:	4989                	li	s3,2
        p->state = RUNNABLE;
    800023ca:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800023cc:	00014917          	auipc	s2,0x14
    800023d0:	64490913          	addi	s2,s2,1604 # 80016a10 <tickslock>
    800023d4:	a811                	j	800023e8 <wakeup+0x3c>
      }
      release(&p->lock);
    800023d6:	8526                	mv	a0,s1
    800023d8:	fffff097          	auipc	ra,0xfffff
    800023dc:	8b2080e7          	jalr	-1870(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800023e0:	16848493          	addi	s1,s1,360
    800023e4:	03248663          	beq	s1,s2,80002410 <wakeup+0x64>
    if(p != myproc()){
    800023e8:	00000097          	auipc	ra,0x0
    800023ec:	8b8080e7          	jalr	-1864(ra) # 80001ca0 <myproc>
    800023f0:	fea488e3          	beq	s1,a0,800023e0 <wakeup+0x34>
      acquire(&p->lock);
    800023f4:	8526                	mv	a0,s1
    800023f6:	ffffe097          	auipc	ra,0xffffe
    800023fa:	7e0080e7          	jalr	2016(ra) # 80000bd6 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800023fe:	4c9c                	lw	a5,24(s1)
    80002400:	fd379be3          	bne	a5,s3,800023d6 <wakeup+0x2a>
    80002404:	709c                	ld	a5,32(s1)
    80002406:	fd4798e3          	bne	a5,s4,800023d6 <wakeup+0x2a>
        p->state = RUNNABLE;
    8000240a:	0154ac23          	sw	s5,24(s1)
    8000240e:	b7e1                	j	800023d6 <wakeup+0x2a>
    }
  }
}
    80002410:	70e2                	ld	ra,56(sp)
    80002412:	7442                	ld	s0,48(sp)
    80002414:	74a2                	ld	s1,40(sp)
    80002416:	7902                	ld	s2,32(sp)
    80002418:	69e2                	ld	s3,24(sp)
    8000241a:	6a42                	ld	s4,16(sp)
    8000241c:	6aa2                	ld	s5,8(sp)
    8000241e:	6121                	addi	sp,sp,64
    80002420:	8082                	ret

0000000080002422 <reparent>:
{
    80002422:	7179                	addi	sp,sp,-48
    80002424:	f406                	sd	ra,40(sp)
    80002426:	f022                	sd	s0,32(sp)
    80002428:	ec26                	sd	s1,24(sp)
    8000242a:	e84a                	sd	s2,16(sp)
    8000242c:	e44e                	sd	s3,8(sp)
    8000242e:	e052                	sd	s4,0(sp)
    80002430:	1800                	addi	s0,sp,48
    80002432:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002434:	0000f497          	auipc	s1,0xf
    80002438:	bdc48493          	addi	s1,s1,-1060 # 80011010 <proc>
      pp->parent = initproc;
    8000243c:	00006a17          	auipc	s4,0x6
    80002440:	52ca0a13          	addi	s4,s4,1324 # 80008968 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002444:	00014997          	auipc	s3,0x14
    80002448:	5cc98993          	addi	s3,s3,1484 # 80016a10 <tickslock>
    8000244c:	a029                	j	80002456 <reparent+0x34>
    8000244e:	16848493          	addi	s1,s1,360
    80002452:	01348d63          	beq	s1,s3,8000246c <reparent+0x4a>
    if(pp->parent == p){
    80002456:	7c9c                	ld	a5,56(s1)
    80002458:	ff279be3          	bne	a5,s2,8000244e <reparent+0x2c>
      pp->parent = initproc;
    8000245c:	000a3503          	ld	a0,0(s4)
    80002460:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002462:	00000097          	auipc	ra,0x0
    80002466:	f4a080e7          	jalr	-182(ra) # 800023ac <wakeup>
    8000246a:	b7d5                	j	8000244e <reparent+0x2c>
}
    8000246c:	70a2                	ld	ra,40(sp)
    8000246e:	7402                	ld	s0,32(sp)
    80002470:	64e2                	ld	s1,24(sp)
    80002472:	6942                	ld	s2,16(sp)
    80002474:	69a2                	ld	s3,8(sp)
    80002476:	6a02                	ld	s4,0(sp)
    80002478:	6145                	addi	sp,sp,48
    8000247a:	8082                	ret

000000008000247c <exit>:
{
    8000247c:	7179                	addi	sp,sp,-48
    8000247e:	f406                	sd	ra,40(sp)
    80002480:	f022                	sd	s0,32(sp)
    80002482:	ec26                	sd	s1,24(sp)
    80002484:	e84a                	sd	s2,16(sp)
    80002486:	e44e                	sd	s3,8(sp)
    80002488:	e052                	sd	s4,0(sp)
    8000248a:	1800                	addi	s0,sp,48
    8000248c:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000248e:	00000097          	auipc	ra,0x0
    80002492:	812080e7          	jalr	-2030(ra) # 80001ca0 <myproc>
    80002496:	89aa                	mv	s3,a0
  if(p == initproc)
    80002498:	00006797          	auipc	a5,0x6
    8000249c:	4d07b783          	ld	a5,1232(a5) # 80008968 <initproc>
    800024a0:	0d050493          	addi	s1,a0,208
    800024a4:	15050913          	addi	s2,a0,336
    800024a8:	02a79363          	bne	a5,a0,800024ce <exit+0x52>
    panic("init exiting");
    800024ac:	00006517          	auipc	a0,0x6
    800024b0:	e5450513          	addi	a0,a0,-428 # 80008300 <digits+0x2c0>
    800024b4:	ffffe097          	auipc	ra,0xffffe
    800024b8:	08a080e7          	jalr	138(ra) # 8000053e <panic>
      fileclose(f);
    800024bc:	00002097          	auipc	ra,0x2
    800024c0:	43a080e7          	jalr	1082(ra) # 800048f6 <fileclose>
      p->ofile[fd] = 0;
    800024c4:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800024c8:	04a1                	addi	s1,s1,8
    800024ca:	01248563          	beq	s1,s2,800024d4 <exit+0x58>
    if(p->ofile[fd]){
    800024ce:	6088                	ld	a0,0(s1)
    800024d0:	f575                	bnez	a0,800024bc <exit+0x40>
    800024d2:	bfdd                	j	800024c8 <exit+0x4c>
  begin_op();
    800024d4:	00002097          	auipc	ra,0x2
    800024d8:	f56080e7          	jalr	-170(ra) # 8000442a <begin_op>
  iput(p->cwd);
    800024dc:	1509b503          	ld	a0,336(s3)
    800024e0:	00001097          	auipc	ra,0x1
    800024e4:	742080e7          	jalr	1858(ra) # 80003c22 <iput>
  end_op();
    800024e8:	00002097          	auipc	ra,0x2
    800024ec:	fc2080e7          	jalr	-62(ra) # 800044aa <end_op>
  p->cwd = 0;
    800024f0:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800024f4:	0000e497          	auipc	s1,0xe
    800024f8:	70448493          	addi	s1,s1,1796 # 80010bf8 <wait_lock>
    800024fc:	8526                	mv	a0,s1
    800024fe:	ffffe097          	auipc	ra,0xffffe
    80002502:	6d8080e7          	jalr	1752(ra) # 80000bd6 <acquire>
  reparent(p);
    80002506:	854e                	mv	a0,s3
    80002508:	00000097          	auipc	ra,0x0
    8000250c:	f1a080e7          	jalr	-230(ra) # 80002422 <reparent>
  wakeup(p->parent);
    80002510:	0389b503          	ld	a0,56(s3)
    80002514:	00000097          	auipc	ra,0x0
    80002518:	e98080e7          	jalr	-360(ra) # 800023ac <wakeup>
  acquire(&p->lock);
    8000251c:	854e                	mv	a0,s3
    8000251e:	ffffe097          	auipc	ra,0xffffe
    80002522:	6b8080e7          	jalr	1720(ra) # 80000bd6 <acquire>
  p->xstate = status;
    80002526:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000252a:	4795                	li	a5,5
    8000252c:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002530:	8526                	mv	a0,s1
    80002532:	ffffe097          	auipc	ra,0xffffe
    80002536:	758080e7          	jalr	1880(ra) # 80000c8a <release>
  sched();
    8000253a:	00000097          	auipc	ra,0x0
    8000253e:	cfc080e7          	jalr	-772(ra) # 80002236 <sched>
  panic("zombie exit");
    80002542:	00006517          	auipc	a0,0x6
    80002546:	dce50513          	addi	a0,a0,-562 # 80008310 <digits+0x2d0>
    8000254a:	ffffe097          	auipc	ra,0xffffe
    8000254e:	ff4080e7          	jalr	-12(ra) # 8000053e <panic>

0000000080002552 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002552:	7179                	addi	sp,sp,-48
    80002554:	f406                	sd	ra,40(sp)
    80002556:	f022                	sd	s0,32(sp)
    80002558:	ec26                	sd	s1,24(sp)
    8000255a:	e84a                	sd	s2,16(sp)
    8000255c:	e44e                	sd	s3,8(sp)
    8000255e:	1800                	addi	s0,sp,48
    80002560:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002562:	0000f497          	auipc	s1,0xf
    80002566:	aae48493          	addi	s1,s1,-1362 # 80011010 <proc>
    8000256a:	00014997          	auipc	s3,0x14
    8000256e:	4a698993          	addi	s3,s3,1190 # 80016a10 <tickslock>
    acquire(&p->lock);
    80002572:	8526                	mv	a0,s1
    80002574:	ffffe097          	auipc	ra,0xffffe
    80002578:	662080e7          	jalr	1634(ra) # 80000bd6 <acquire>
    if(p->pid == pid){
    8000257c:	589c                	lw	a5,48(s1)
    8000257e:	01278d63          	beq	a5,s2,80002598 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002582:	8526                	mv	a0,s1
    80002584:	ffffe097          	auipc	ra,0xffffe
    80002588:	706080e7          	jalr	1798(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000258c:	16848493          	addi	s1,s1,360
    80002590:	ff3491e3          	bne	s1,s3,80002572 <kill+0x20>
  }
  return -1;
    80002594:	557d                	li	a0,-1
    80002596:	a829                	j	800025b0 <kill+0x5e>
      p->killed = 1;
    80002598:	4785                	li	a5,1
    8000259a:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000259c:	4c98                	lw	a4,24(s1)
    8000259e:	4789                	li	a5,2
    800025a0:	00f70f63          	beq	a4,a5,800025be <kill+0x6c>
      release(&p->lock);
    800025a4:	8526                	mv	a0,s1
    800025a6:	ffffe097          	auipc	ra,0xffffe
    800025aa:	6e4080e7          	jalr	1764(ra) # 80000c8a <release>
      return 0;
    800025ae:	4501                	li	a0,0
}
    800025b0:	70a2                	ld	ra,40(sp)
    800025b2:	7402                	ld	s0,32(sp)
    800025b4:	64e2                	ld	s1,24(sp)
    800025b6:	6942                	ld	s2,16(sp)
    800025b8:	69a2                	ld	s3,8(sp)
    800025ba:	6145                	addi	sp,sp,48
    800025bc:	8082                	ret
        p->state = RUNNABLE;
    800025be:	478d                	li	a5,3
    800025c0:	cc9c                	sw	a5,24(s1)
    800025c2:	b7cd                	j	800025a4 <kill+0x52>

00000000800025c4 <setkilled>:

void
setkilled(struct proc *p)
{
    800025c4:	1101                	addi	sp,sp,-32
    800025c6:	ec06                	sd	ra,24(sp)
    800025c8:	e822                	sd	s0,16(sp)
    800025ca:	e426                	sd	s1,8(sp)
    800025cc:	1000                	addi	s0,sp,32
    800025ce:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800025d0:	ffffe097          	auipc	ra,0xffffe
    800025d4:	606080e7          	jalr	1542(ra) # 80000bd6 <acquire>
  p->killed = 1;
    800025d8:	4785                	li	a5,1
    800025da:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800025dc:	8526                	mv	a0,s1
    800025de:	ffffe097          	auipc	ra,0xffffe
    800025e2:	6ac080e7          	jalr	1708(ra) # 80000c8a <release>
}
    800025e6:	60e2                	ld	ra,24(sp)
    800025e8:	6442                	ld	s0,16(sp)
    800025ea:	64a2                	ld	s1,8(sp)
    800025ec:	6105                	addi	sp,sp,32
    800025ee:	8082                	ret

00000000800025f0 <killed>:

int
killed(struct proc *p)
{
    800025f0:	1101                	addi	sp,sp,-32
    800025f2:	ec06                	sd	ra,24(sp)
    800025f4:	e822                	sd	s0,16(sp)
    800025f6:	e426                	sd	s1,8(sp)
    800025f8:	e04a                	sd	s2,0(sp)
    800025fa:	1000                	addi	s0,sp,32
    800025fc:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    800025fe:	ffffe097          	auipc	ra,0xffffe
    80002602:	5d8080e7          	jalr	1496(ra) # 80000bd6 <acquire>
  k = p->killed;
    80002606:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    8000260a:	8526                	mv	a0,s1
    8000260c:	ffffe097          	auipc	ra,0xffffe
    80002610:	67e080e7          	jalr	1662(ra) # 80000c8a <release>
  return k;
}
    80002614:	854a                	mv	a0,s2
    80002616:	60e2                	ld	ra,24(sp)
    80002618:	6442                	ld	s0,16(sp)
    8000261a:	64a2                	ld	s1,8(sp)
    8000261c:	6902                	ld	s2,0(sp)
    8000261e:	6105                	addi	sp,sp,32
    80002620:	8082                	ret

0000000080002622 <wait>:
{
    80002622:	715d                	addi	sp,sp,-80
    80002624:	e486                	sd	ra,72(sp)
    80002626:	e0a2                	sd	s0,64(sp)
    80002628:	fc26                	sd	s1,56(sp)
    8000262a:	f84a                	sd	s2,48(sp)
    8000262c:	f44e                	sd	s3,40(sp)
    8000262e:	f052                	sd	s4,32(sp)
    80002630:	ec56                	sd	s5,24(sp)
    80002632:	e85a                	sd	s6,16(sp)
    80002634:	e45e                	sd	s7,8(sp)
    80002636:	e062                	sd	s8,0(sp)
    80002638:	0880                	addi	s0,sp,80
    8000263a:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000263c:	fffff097          	auipc	ra,0xfffff
    80002640:	664080e7          	jalr	1636(ra) # 80001ca0 <myproc>
    80002644:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002646:	0000e517          	auipc	a0,0xe
    8000264a:	5b250513          	addi	a0,a0,1458 # 80010bf8 <wait_lock>
    8000264e:	ffffe097          	auipc	ra,0xffffe
    80002652:	588080e7          	jalr	1416(ra) # 80000bd6 <acquire>
    havekids = 0;
    80002656:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    80002658:	4a15                	li	s4,5
        havekids = 1;
    8000265a:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000265c:	00014997          	auipc	s3,0x14
    80002660:	3b498993          	addi	s3,s3,948 # 80016a10 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002664:	0000ec17          	auipc	s8,0xe
    80002668:	594c0c13          	addi	s8,s8,1428 # 80010bf8 <wait_lock>
    havekids = 0;
    8000266c:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000266e:	0000f497          	auipc	s1,0xf
    80002672:	9a248493          	addi	s1,s1,-1630 # 80011010 <proc>
    80002676:	a0bd                	j	800026e4 <wait+0xc2>
          pid = pp->pid;
    80002678:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    8000267c:	000b0e63          	beqz	s6,80002698 <wait+0x76>
    80002680:	4691                	li	a3,4
    80002682:	02c48613          	addi	a2,s1,44
    80002686:	85da                	mv	a1,s6
    80002688:	05093503          	ld	a0,80(s2)
    8000268c:	fffff097          	auipc	ra,0xfffff
    80002690:	fe4080e7          	jalr	-28(ra) # 80001670 <copyout>
    80002694:	02054563          	bltz	a0,800026be <wait+0x9c>
          freeproc(pp);
    80002698:	8526                	mv	a0,s1
    8000269a:	fffff097          	auipc	ra,0xfffff
    8000269e:	7b8080e7          	jalr	1976(ra) # 80001e52 <freeproc>
          release(&pp->lock);
    800026a2:	8526                	mv	a0,s1
    800026a4:	ffffe097          	auipc	ra,0xffffe
    800026a8:	5e6080e7          	jalr	1510(ra) # 80000c8a <release>
          release(&wait_lock);
    800026ac:	0000e517          	auipc	a0,0xe
    800026b0:	54c50513          	addi	a0,a0,1356 # 80010bf8 <wait_lock>
    800026b4:	ffffe097          	auipc	ra,0xffffe
    800026b8:	5d6080e7          	jalr	1494(ra) # 80000c8a <release>
          return pid;
    800026bc:	a0b5                	j	80002728 <wait+0x106>
            release(&pp->lock);
    800026be:	8526                	mv	a0,s1
    800026c0:	ffffe097          	auipc	ra,0xffffe
    800026c4:	5ca080e7          	jalr	1482(ra) # 80000c8a <release>
            release(&wait_lock);
    800026c8:	0000e517          	auipc	a0,0xe
    800026cc:	53050513          	addi	a0,a0,1328 # 80010bf8 <wait_lock>
    800026d0:	ffffe097          	auipc	ra,0xffffe
    800026d4:	5ba080e7          	jalr	1466(ra) # 80000c8a <release>
            return -1;
    800026d8:	59fd                	li	s3,-1
    800026da:	a0b9                	j	80002728 <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800026dc:	16848493          	addi	s1,s1,360
    800026e0:	03348463          	beq	s1,s3,80002708 <wait+0xe6>
      if(pp->parent == p){
    800026e4:	7c9c                	ld	a5,56(s1)
    800026e6:	ff279be3          	bne	a5,s2,800026dc <wait+0xba>
        acquire(&pp->lock);
    800026ea:	8526                	mv	a0,s1
    800026ec:	ffffe097          	auipc	ra,0xffffe
    800026f0:	4ea080e7          	jalr	1258(ra) # 80000bd6 <acquire>
        if(pp->state == ZOMBIE){
    800026f4:	4c9c                	lw	a5,24(s1)
    800026f6:	f94781e3          	beq	a5,s4,80002678 <wait+0x56>
        release(&pp->lock);
    800026fa:	8526                	mv	a0,s1
    800026fc:	ffffe097          	auipc	ra,0xffffe
    80002700:	58e080e7          	jalr	1422(ra) # 80000c8a <release>
        havekids = 1;
    80002704:	8756                	mv	a4,s5
    80002706:	bfd9                	j	800026dc <wait+0xba>
    if(!havekids || killed(p)){
    80002708:	c719                	beqz	a4,80002716 <wait+0xf4>
    8000270a:	854a                	mv	a0,s2
    8000270c:	00000097          	auipc	ra,0x0
    80002710:	ee4080e7          	jalr	-284(ra) # 800025f0 <killed>
    80002714:	c51d                	beqz	a0,80002742 <wait+0x120>
      release(&wait_lock);
    80002716:	0000e517          	auipc	a0,0xe
    8000271a:	4e250513          	addi	a0,a0,1250 # 80010bf8 <wait_lock>
    8000271e:	ffffe097          	auipc	ra,0xffffe
    80002722:	56c080e7          	jalr	1388(ra) # 80000c8a <release>
      return -1;
    80002726:	59fd                	li	s3,-1
}
    80002728:	854e                	mv	a0,s3
    8000272a:	60a6                	ld	ra,72(sp)
    8000272c:	6406                	ld	s0,64(sp)
    8000272e:	74e2                	ld	s1,56(sp)
    80002730:	7942                	ld	s2,48(sp)
    80002732:	79a2                	ld	s3,40(sp)
    80002734:	7a02                	ld	s4,32(sp)
    80002736:	6ae2                	ld	s5,24(sp)
    80002738:	6b42                	ld	s6,16(sp)
    8000273a:	6ba2                	ld	s7,8(sp)
    8000273c:	6c02                	ld	s8,0(sp)
    8000273e:	6161                	addi	sp,sp,80
    80002740:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002742:	85e2                	mv	a1,s8
    80002744:	854a                	mv	a0,s2
    80002746:	00000097          	auipc	ra,0x0
    8000274a:	c02080e7          	jalr	-1022(ra) # 80002348 <sleep>
    havekids = 0;
    8000274e:	bf39                	j	8000266c <wait+0x4a>

0000000080002750 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002750:	7179                	addi	sp,sp,-48
    80002752:	f406                	sd	ra,40(sp)
    80002754:	f022                	sd	s0,32(sp)
    80002756:	ec26                	sd	s1,24(sp)
    80002758:	e84a                	sd	s2,16(sp)
    8000275a:	e44e                	sd	s3,8(sp)
    8000275c:	e052                	sd	s4,0(sp)
    8000275e:	1800                	addi	s0,sp,48
    80002760:	84aa                	mv	s1,a0
    80002762:	892e                	mv	s2,a1
    80002764:	89b2                	mv	s3,a2
    80002766:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002768:	fffff097          	auipc	ra,0xfffff
    8000276c:	538080e7          	jalr	1336(ra) # 80001ca0 <myproc>
  if(user_dst){
    80002770:	c08d                	beqz	s1,80002792 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002772:	86d2                	mv	a3,s4
    80002774:	864e                	mv	a2,s3
    80002776:	85ca                	mv	a1,s2
    80002778:	6928                	ld	a0,80(a0)
    8000277a:	fffff097          	auipc	ra,0xfffff
    8000277e:	ef6080e7          	jalr	-266(ra) # 80001670 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002782:	70a2                	ld	ra,40(sp)
    80002784:	7402                	ld	s0,32(sp)
    80002786:	64e2                	ld	s1,24(sp)
    80002788:	6942                	ld	s2,16(sp)
    8000278a:	69a2                	ld	s3,8(sp)
    8000278c:	6a02                	ld	s4,0(sp)
    8000278e:	6145                	addi	sp,sp,48
    80002790:	8082                	ret
    memmove((char *)dst, src, len);
    80002792:	000a061b          	sext.w	a2,s4
    80002796:	85ce                	mv	a1,s3
    80002798:	854a                	mv	a0,s2
    8000279a:	ffffe097          	auipc	ra,0xffffe
    8000279e:	594080e7          	jalr	1428(ra) # 80000d2e <memmove>
    return 0;
    800027a2:	8526                	mv	a0,s1
    800027a4:	bff9                	j	80002782 <either_copyout+0x32>

00000000800027a6 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800027a6:	7179                	addi	sp,sp,-48
    800027a8:	f406                	sd	ra,40(sp)
    800027aa:	f022                	sd	s0,32(sp)
    800027ac:	ec26                	sd	s1,24(sp)
    800027ae:	e84a                	sd	s2,16(sp)
    800027b0:	e44e                	sd	s3,8(sp)
    800027b2:	e052                	sd	s4,0(sp)
    800027b4:	1800                	addi	s0,sp,48
    800027b6:	892a                	mv	s2,a0
    800027b8:	84ae                	mv	s1,a1
    800027ba:	89b2                	mv	s3,a2
    800027bc:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800027be:	fffff097          	auipc	ra,0xfffff
    800027c2:	4e2080e7          	jalr	1250(ra) # 80001ca0 <myproc>
  if(user_src){
    800027c6:	c08d                	beqz	s1,800027e8 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800027c8:	86d2                	mv	a3,s4
    800027ca:	864e                	mv	a2,s3
    800027cc:	85ca                	mv	a1,s2
    800027ce:	6928                	ld	a0,80(a0)
    800027d0:	fffff097          	auipc	ra,0xfffff
    800027d4:	f2c080e7          	jalr	-212(ra) # 800016fc <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800027d8:	70a2                	ld	ra,40(sp)
    800027da:	7402                	ld	s0,32(sp)
    800027dc:	64e2                	ld	s1,24(sp)
    800027de:	6942                	ld	s2,16(sp)
    800027e0:	69a2                	ld	s3,8(sp)
    800027e2:	6a02                	ld	s4,0(sp)
    800027e4:	6145                	addi	sp,sp,48
    800027e6:	8082                	ret
    memmove(dst, (char*)src, len);
    800027e8:	000a061b          	sext.w	a2,s4
    800027ec:	85ce                	mv	a1,s3
    800027ee:	854a                	mv	a0,s2
    800027f0:	ffffe097          	auipc	ra,0xffffe
    800027f4:	53e080e7          	jalr	1342(ra) # 80000d2e <memmove>
    return 0;
    800027f8:	8526                	mv	a0,s1
    800027fa:	bff9                	j	800027d8 <either_copyin+0x32>

00000000800027fc <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800027fc:	715d                	addi	sp,sp,-80
    800027fe:	e486                	sd	ra,72(sp)
    80002800:	e0a2                	sd	s0,64(sp)
    80002802:	fc26                	sd	s1,56(sp)
    80002804:	f84a                	sd	s2,48(sp)
    80002806:	f44e                	sd	s3,40(sp)
    80002808:	f052                	sd	s4,32(sp)
    8000280a:	ec56                	sd	s5,24(sp)
    8000280c:	e85a                	sd	s6,16(sp)
    8000280e:	e45e                	sd	s7,8(sp)
    80002810:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002812:	00006517          	auipc	a0,0x6
    80002816:	8b650513          	addi	a0,a0,-1866 # 800080c8 <digits+0x88>
    8000281a:	ffffe097          	auipc	ra,0xffffe
    8000281e:	d6e080e7          	jalr	-658(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002822:	0000f497          	auipc	s1,0xf
    80002826:	94648493          	addi	s1,s1,-1722 # 80011168 <proc+0x158>
    8000282a:	00014917          	auipc	s2,0x14
    8000282e:	33e90913          	addi	s2,s2,830 # 80016b68 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002832:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002834:	00006997          	auipc	s3,0x6
    80002838:	aec98993          	addi	s3,s3,-1300 # 80008320 <digits+0x2e0>
    printf("%d %s %s", p->pid, state, p->name);
    8000283c:	00006a97          	auipc	s5,0x6
    80002840:	aeca8a93          	addi	s5,s5,-1300 # 80008328 <digits+0x2e8>
    printf("\n");
    80002844:	00006a17          	auipc	s4,0x6
    80002848:	884a0a13          	addi	s4,s4,-1916 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000284c:	00006b97          	auipc	s7,0x6
    80002850:	b1cb8b93          	addi	s7,s7,-1252 # 80008368 <states.0>
    80002854:	a00d                	j	80002876 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002856:	ed86a583          	lw	a1,-296(a3)
    8000285a:	8556                	mv	a0,s5
    8000285c:	ffffe097          	auipc	ra,0xffffe
    80002860:	d2c080e7          	jalr	-724(ra) # 80000588 <printf>
    printf("\n");
    80002864:	8552                	mv	a0,s4
    80002866:	ffffe097          	auipc	ra,0xffffe
    8000286a:	d22080e7          	jalr	-734(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000286e:	16848493          	addi	s1,s1,360
    80002872:	03248163          	beq	s1,s2,80002894 <procdump+0x98>
    if(p->state == UNUSED)
    80002876:	86a6                	mv	a3,s1
    80002878:	ec04a783          	lw	a5,-320(s1)
    8000287c:	dbed                	beqz	a5,8000286e <procdump+0x72>
      state = "???";
    8000287e:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002880:	fcfb6be3          	bltu	s6,a5,80002856 <procdump+0x5a>
    80002884:	1782                	slli	a5,a5,0x20
    80002886:	9381                	srli	a5,a5,0x20
    80002888:	078e                	slli	a5,a5,0x3
    8000288a:	97de                	add	a5,a5,s7
    8000288c:	6390                	ld	a2,0(a5)
    8000288e:	f661                	bnez	a2,80002856 <procdump+0x5a>
      state = "???";
    80002890:	864e                	mv	a2,s3
    80002892:	b7d1                	j	80002856 <procdump+0x5a>
  }
}
    80002894:	60a6                	ld	ra,72(sp)
    80002896:	6406                	ld	s0,64(sp)
    80002898:	74e2                	ld	s1,56(sp)
    8000289a:	7942                	ld	s2,48(sp)
    8000289c:	79a2                	ld	s3,40(sp)
    8000289e:	7a02                	ld	s4,32(sp)
    800028a0:	6ae2                	ld	s5,24(sp)
    800028a2:	6b42                	ld	s6,16(sp)
    800028a4:	6ba2                	ld	s7,8(sp)
    800028a6:	6161                	addi	sp,sp,80
    800028a8:	8082                	ret

00000000800028aa <sys_get_sz>:

// task1:
int sys_get_sz(void) {
    800028aa:	1141                	addi	sp,sp,-16
    800028ac:	e406                	sd	ra,8(sp)
    800028ae:	e022                	sd	s0,0(sp)
    800028b0:	0800                	addi	s0,sp,16
  return myproc()->sz;
    800028b2:	fffff097          	auipc	ra,0xfffff
    800028b6:	3ee080e7          	jalr	1006(ra) # 80001ca0 <myproc>
    800028ba:	4528                	lw	a0,72(a0)
    800028bc:	60a2                	ld	ra,8(sp)
    800028be:	6402                	ld	s0,0(sp)
    800028c0:	0141                	addi	sp,sp,16
    800028c2:	8082                	ret

00000000800028c4 <swtch>:
    800028c4:	00153023          	sd	ra,0(a0)
    800028c8:	00253423          	sd	sp,8(a0)
    800028cc:	e900                	sd	s0,16(a0)
    800028ce:	ed04                	sd	s1,24(a0)
    800028d0:	03253023          	sd	s2,32(a0)
    800028d4:	03353423          	sd	s3,40(a0)
    800028d8:	03453823          	sd	s4,48(a0)
    800028dc:	03553c23          	sd	s5,56(a0)
    800028e0:	05653023          	sd	s6,64(a0)
    800028e4:	05753423          	sd	s7,72(a0)
    800028e8:	05853823          	sd	s8,80(a0)
    800028ec:	05953c23          	sd	s9,88(a0)
    800028f0:	07a53023          	sd	s10,96(a0)
    800028f4:	07b53423          	sd	s11,104(a0)
    800028f8:	0005b083          	ld	ra,0(a1)
    800028fc:	0085b103          	ld	sp,8(a1)
    80002900:	6980                	ld	s0,16(a1)
    80002902:	6d84                	ld	s1,24(a1)
    80002904:	0205b903          	ld	s2,32(a1)
    80002908:	0285b983          	ld	s3,40(a1)
    8000290c:	0305ba03          	ld	s4,48(a1)
    80002910:	0385ba83          	ld	s5,56(a1)
    80002914:	0405bb03          	ld	s6,64(a1)
    80002918:	0485bb83          	ld	s7,72(a1)
    8000291c:	0505bc03          	ld	s8,80(a1)
    80002920:	0585bc83          	ld	s9,88(a1)
    80002924:	0605bd03          	ld	s10,96(a1)
    80002928:	0685bd83          	ld	s11,104(a1)
    8000292c:	8082                	ret

000000008000292e <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000292e:	1141                	addi	sp,sp,-16
    80002930:	e406                	sd	ra,8(sp)
    80002932:	e022                	sd	s0,0(sp)
    80002934:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002936:	00006597          	auipc	a1,0x6
    8000293a:	a6258593          	addi	a1,a1,-1438 # 80008398 <states.0+0x30>
    8000293e:	00014517          	auipc	a0,0x14
    80002942:	0d250513          	addi	a0,a0,210 # 80016a10 <tickslock>
    80002946:	ffffe097          	auipc	ra,0xffffe
    8000294a:	200080e7          	jalr	512(ra) # 80000b46 <initlock>
}
    8000294e:	60a2                	ld	ra,8(sp)
    80002950:	6402                	ld	s0,0(sp)
    80002952:	0141                	addi	sp,sp,16
    80002954:	8082                	ret

0000000080002956 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002956:	1141                	addi	sp,sp,-16
    80002958:	e422                	sd	s0,8(sp)
    8000295a:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000295c:	00003797          	auipc	a5,0x3
    80002960:	5e478793          	addi	a5,a5,1508 # 80005f40 <kernelvec>
    80002964:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002968:	6422                	ld	s0,8(sp)
    8000296a:	0141                	addi	sp,sp,16
    8000296c:	8082                	ret

000000008000296e <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000296e:	1141                	addi	sp,sp,-16
    80002970:	e406                	sd	ra,8(sp)
    80002972:	e022                	sd	s0,0(sp)
    80002974:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002976:	fffff097          	auipc	ra,0xfffff
    8000297a:	32a080e7          	jalr	810(ra) # 80001ca0 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000297e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002982:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002984:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002988:	00004617          	auipc	a2,0x4
    8000298c:	67860613          	addi	a2,a2,1656 # 80007000 <_trampoline>
    80002990:	00004697          	auipc	a3,0x4
    80002994:	67068693          	addi	a3,a3,1648 # 80007000 <_trampoline>
    80002998:	8e91                	sub	a3,a3,a2
    8000299a:	040007b7          	lui	a5,0x4000
    8000299e:	17fd                	addi	a5,a5,-1
    800029a0:	07b2                	slli	a5,a5,0xc
    800029a2:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029a4:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800029a8:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800029aa:	180026f3          	csrr	a3,satp
    800029ae:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800029b0:	6d38                	ld	a4,88(a0)
    800029b2:	6134                	ld	a3,64(a0)
    800029b4:	6585                	lui	a1,0x1
    800029b6:	96ae                	add	a3,a3,a1
    800029b8:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800029ba:	6d38                	ld	a4,88(a0)
    800029bc:	00000697          	auipc	a3,0x0
    800029c0:	13068693          	addi	a3,a3,304 # 80002aec <usertrap>
    800029c4:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800029c6:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800029c8:	8692                	mv	a3,tp
    800029ca:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029cc:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800029d0:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800029d4:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029d8:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800029dc:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029de:	6f18                	ld	a4,24(a4)
    800029e0:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800029e4:	6928                	ld	a0,80(a0)
    800029e6:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800029e8:	00004717          	auipc	a4,0x4
    800029ec:	6b470713          	addi	a4,a4,1716 # 8000709c <userret>
    800029f0:	8f11                	sub	a4,a4,a2
    800029f2:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800029f4:	577d                	li	a4,-1
    800029f6:	177e                	slli	a4,a4,0x3f
    800029f8:	8d59                	or	a0,a0,a4
    800029fa:	9782                	jalr	a5
}
    800029fc:	60a2                	ld	ra,8(sp)
    800029fe:	6402                	ld	s0,0(sp)
    80002a00:	0141                	addi	sp,sp,16
    80002a02:	8082                	ret

0000000080002a04 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002a04:	1101                	addi	sp,sp,-32
    80002a06:	ec06                	sd	ra,24(sp)
    80002a08:	e822                	sd	s0,16(sp)
    80002a0a:	e426                	sd	s1,8(sp)
    80002a0c:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002a0e:	00014497          	auipc	s1,0x14
    80002a12:	00248493          	addi	s1,s1,2 # 80016a10 <tickslock>
    80002a16:	8526                	mv	a0,s1
    80002a18:	ffffe097          	auipc	ra,0xffffe
    80002a1c:	1be080e7          	jalr	446(ra) # 80000bd6 <acquire>
  ticks++;
    80002a20:	00006517          	auipc	a0,0x6
    80002a24:	f5050513          	addi	a0,a0,-176 # 80008970 <ticks>
    80002a28:	411c                	lw	a5,0(a0)
    80002a2a:	2785                	addiw	a5,a5,1
    80002a2c:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002a2e:	00000097          	auipc	ra,0x0
    80002a32:	97e080e7          	jalr	-1666(ra) # 800023ac <wakeup>
  release(&tickslock);
    80002a36:	8526                	mv	a0,s1
    80002a38:	ffffe097          	auipc	ra,0xffffe
    80002a3c:	252080e7          	jalr	594(ra) # 80000c8a <release>
}
    80002a40:	60e2                	ld	ra,24(sp)
    80002a42:	6442                	ld	s0,16(sp)
    80002a44:	64a2                	ld	s1,8(sp)
    80002a46:	6105                	addi	sp,sp,32
    80002a48:	8082                	ret

0000000080002a4a <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002a4a:	1101                	addi	sp,sp,-32
    80002a4c:	ec06                	sd	ra,24(sp)
    80002a4e:	e822                	sd	s0,16(sp)
    80002a50:	e426                	sd	s1,8(sp)
    80002a52:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a54:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002a58:	00074d63          	bltz	a4,80002a72 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002a5c:	57fd                	li	a5,-1
    80002a5e:	17fe                	slli	a5,a5,0x3f
    80002a60:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002a62:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002a64:	06f70363          	beq	a4,a5,80002aca <devintr+0x80>
  }
}
    80002a68:	60e2                	ld	ra,24(sp)
    80002a6a:	6442                	ld	s0,16(sp)
    80002a6c:	64a2                	ld	s1,8(sp)
    80002a6e:	6105                	addi	sp,sp,32
    80002a70:	8082                	ret
     (scause & 0xff) == 9){
    80002a72:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002a76:	46a5                	li	a3,9
    80002a78:	fed792e3          	bne	a5,a3,80002a5c <devintr+0x12>
    int irq = plic_claim();
    80002a7c:	00003097          	auipc	ra,0x3
    80002a80:	5cc080e7          	jalr	1484(ra) # 80006048 <plic_claim>
    80002a84:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002a86:	47a9                	li	a5,10
    80002a88:	02f50763          	beq	a0,a5,80002ab6 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002a8c:	4785                	li	a5,1
    80002a8e:	02f50963          	beq	a0,a5,80002ac0 <devintr+0x76>
    return 1;
    80002a92:	4505                	li	a0,1
    } else if(irq){
    80002a94:	d8f1                	beqz	s1,80002a68 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002a96:	85a6                	mv	a1,s1
    80002a98:	00006517          	auipc	a0,0x6
    80002a9c:	90850513          	addi	a0,a0,-1784 # 800083a0 <states.0+0x38>
    80002aa0:	ffffe097          	auipc	ra,0xffffe
    80002aa4:	ae8080e7          	jalr	-1304(ra) # 80000588 <printf>
      plic_complete(irq);
    80002aa8:	8526                	mv	a0,s1
    80002aaa:	00003097          	auipc	ra,0x3
    80002aae:	5c2080e7          	jalr	1474(ra) # 8000606c <plic_complete>
    return 1;
    80002ab2:	4505                	li	a0,1
    80002ab4:	bf55                	j	80002a68 <devintr+0x1e>
      uartintr();
    80002ab6:	ffffe097          	auipc	ra,0xffffe
    80002aba:	ee4080e7          	jalr	-284(ra) # 8000099a <uartintr>
    80002abe:	b7ed                	j	80002aa8 <devintr+0x5e>
      virtio_disk_intr();
    80002ac0:	00004097          	auipc	ra,0x4
    80002ac4:	a78080e7          	jalr	-1416(ra) # 80006538 <virtio_disk_intr>
    80002ac8:	b7c5                	j	80002aa8 <devintr+0x5e>
    if(cpuid() == 0){
    80002aca:	fffff097          	auipc	ra,0xfffff
    80002ace:	1aa080e7          	jalr	426(ra) # 80001c74 <cpuid>
    80002ad2:	c901                	beqz	a0,80002ae2 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002ad4:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002ad8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002ada:	14479073          	csrw	sip,a5
    return 2;
    80002ade:	4509                	li	a0,2
    80002ae0:	b761                	j	80002a68 <devintr+0x1e>
      clockintr();
    80002ae2:	00000097          	auipc	ra,0x0
    80002ae6:	f22080e7          	jalr	-222(ra) # 80002a04 <clockintr>
    80002aea:	b7ed                	j	80002ad4 <devintr+0x8a>

0000000080002aec <usertrap>:
{
    80002aec:	1101                	addi	sp,sp,-32
    80002aee:	ec06                	sd	ra,24(sp)
    80002af0:	e822                	sd	s0,16(sp)
    80002af2:	e426                	sd	s1,8(sp)
    80002af4:	e04a                	sd	s2,0(sp)
    80002af6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002af8:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002afc:	1007f793          	andi	a5,a5,256
    80002b00:	e3b1                	bnez	a5,80002b44 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b02:	00003797          	auipc	a5,0x3
    80002b06:	43e78793          	addi	a5,a5,1086 # 80005f40 <kernelvec>
    80002b0a:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002b0e:	fffff097          	auipc	ra,0xfffff
    80002b12:	192080e7          	jalr	402(ra) # 80001ca0 <myproc>
    80002b16:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b18:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b1a:	14102773          	csrr	a4,sepc
    80002b1e:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b20:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002b24:	47a1                	li	a5,8
    80002b26:	02f70763          	beq	a4,a5,80002b54 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    80002b2a:	00000097          	auipc	ra,0x0
    80002b2e:	f20080e7          	jalr	-224(ra) # 80002a4a <devintr>
    80002b32:	892a                	mv	s2,a0
    80002b34:	c151                	beqz	a0,80002bb8 <usertrap+0xcc>
  if(killed(p))
    80002b36:	8526                	mv	a0,s1
    80002b38:	00000097          	auipc	ra,0x0
    80002b3c:	ab8080e7          	jalr	-1352(ra) # 800025f0 <killed>
    80002b40:	c929                	beqz	a0,80002b92 <usertrap+0xa6>
    80002b42:	a099                	j	80002b88 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002b44:	00006517          	auipc	a0,0x6
    80002b48:	87c50513          	addi	a0,a0,-1924 # 800083c0 <states.0+0x58>
    80002b4c:	ffffe097          	auipc	ra,0xffffe
    80002b50:	9f2080e7          	jalr	-1550(ra) # 8000053e <panic>
    if(killed(p))
    80002b54:	00000097          	auipc	ra,0x0
    80002b58:	a9c080e7          	jalr	-1380(ra) # 800025f0 <killed>
    80002b5c:	e921                	bnez	a0,80002bac <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002b5e:	6cb8                	ld	a4,88(s1)
    80002b60:	6f1c                	ld	a5,24(a4)
    80002b62:	0791                	addi	a5,a5,4
    80002b64:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b66:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b6a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b6e:	10079073          	csrw	sstatus,a5
    syscall();
    80002b72:	00000097          	auipc	ra,0x0
    80002b76:	2d4080e7          	jalr	724(ra) # 80002e46 <syscall>
  if(killed(p))
    80002b7a:	8526                	mv	a0,s1
    80002b7c:	00000097          	auipc	ra,0x0
    80002b80:	a74080e7          	jalr	-1420(ra) # 800025f0 <killed>
    80002b84:	c911                	beqz	a0,80002b98 <usertrap+0xac>
    80002b86:	4901                	li	s2,0
    exit(-1);
    80002b88:	557d                	li	a0,-1
    80002b8a:	00000097          	auipc	ra,0x0
    80002b8e:	8f2080e7          	jalr	-1806(ra) # 8000247c <exit>
  if(which_dev == 2)
    80002b92:	4789                	li	a5,2
    80002b94:	04f90f63          	beq	s2,a5,80002bf2 <usertrap+0x106>
  usertrapret();
    80002b98:	00000097          	auipc	ra,0x0
    80002b9c:	dd6080e7          	jalr	-554(ra) # 8000296e <usertrapret>
}
    80002ba0:	60e2                	ld	ra,24(sp)
    80002ba2:	6442                	ld	s0,16(sp)
    80002ba4:	64a2                	ld	s1,8(sp)
    80002ba6:	6902                	ld	s2,0(sp)
    80002ba8:	6105                	addi	sp,sp,32
    80002baa:	8082                	ret
      exit(-1);
    80002bac:	557d                	li	a0,-1
    80002bae:	00000097          	auipc	ra,0x0
    80002bb2:	8ce080e7          	jalr	-1842(ra) # 8000247c <exit>
    80002bb6:	b765                	j	80002b5e <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bb8:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002bbc:	5890                	lw	a2,48(s1)
    80002bbe:	00006517          	auipc	a0,0x6
    80002bc2:	82250513          	addi	a0,a0,-2014 # 800083e0 <states.0+0x78>
    80002bc6:	ffffe097          	auipc	ra,0xffffe
    80002bca:	9c2080e7          	jalr	-1598(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bce:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bd2:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bd6:	00006517          	auipc	a0,0x6
    80002bda:	83a50513          	addi	a0,a0,-1990 # 80008410 <states.0+0xa8>
    80002bde:	ffffe097          	auipc	ra,0xffffe
    80002be2:	9aa080e7          	jalr	-1622(ra) # 80000588 <printf>
    setkilled(p);
    80002be6:	8526                	mv	a0,s1
    80002be8:	00000097          	auipc	ra,0x0
    80002bec:	9dc080e7          	jalr	-1572(ra) # 800025c4 <setkilled>
    80002bf0:	b769                	j	80002b7a <usertrap+0x8e>
    yield();
    80002bf2:	fffff097          	auipc	ra,0xfffff
    80002bf6:	71a080e7          	jalr	1818(ra) # 8000230c <yield>
    80002bfa:	bf79                	j	80002b98 <usertrap+0xac>

0000000080002bfc <kerneltrap>:
{
    80002bfc:	7179                	addi	sp,sp,-48
    80002bfe:	f406                	sd	ra,40(sp)
    80002c00:	f022                	sd	s0,32(sp)
    80002c02:	ec26                	sd	s1,24(sp)
    80002c04:	e84a                	sd	s2,16(sp)
    80002c06:	e44e                	sd	s3,8(sp)
    80002c08:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c0a:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c0e:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c12:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002c16:	1004f793          	andi	a5,s1,256
    80002c1a:	cb85                	beqz	a5,80002c4a <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c1c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c20:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002c22:	ef85                	bnez	a5,80002c5a <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002c24:	00000097          	auipc	ra,0x0
    80002c28:	e26080e7          	jalr	-474(ra) # 80002a4a <devintr>
    80002c2c:	cd1d                	beqz	a0,80002c6a <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c2e:	4789                	li	a5,2
    80002c30:	06f50a63          	beq	a0,a5,80002ca4 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c34:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c38:	10049073          	csrw	sstatus,s1
}
    80002c3c:	70a2                	ld	ra,40(sp)
    80002c3e:	7402                	ld	s0,32(sp)
    80002c40:	64e2                	ld	s1,24(sp)
    80002c42:	6942                	ld	s2,16(sp)
    80002c44:	69a2                	ld	s3,8(sp)
    80002c46:	6145                	addi	sp,sp,48
    80002c48:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c4a:	00005517          	auipc	a0,0x5
    80002c4e:	7e650513          	addi	a0,a0,2022 # 80008430 <states.0+0xc8>
    80002c52:	ffffe097          	auipc	ra,0xffffe
    80002c56:	8ec080e7          	jalr	-1812(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002c5a:	00005517          	auipc	a0,0x5
    80002c5e:	7fe50513          	addi	a0,a0,2046 # 80008458 <states.0+0xf0>
    80002c62:	ffffe097          	auipc	ra,0xffffe
    80002c66:	8dc080e7          	jalr	-1828(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002c6a:	85ce                	mv	a1,s3
    80002c6c:	00006517          	auipc	a0,0x6
    80002c70:	80c50513          	addi	a0,a0,-2036 # 80008478 <states.0+0x110>
    80002c74:	ffffe097          	auipc	ra,0xffffe
    80002c78:	914080e7          	jalr	-1772(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c7c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c80:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c84:	00006517          	auipc	a0,0x6
    80002c88:	80450513          	addi	a0,a0,-2044 # 80008488 <states.0+0x120>
    80002c8c:	ffffe097          	auipc	ra,0xffffe
    80002c90:	8fc080e7          	jalr	-1796(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002c94:	00006517          	auipc	a0,0x6
    80002c98:	80c50513          	addi	a0,a0,-2036 # 800084a0 <states.0+0x138>
    80002c9c:	ffffe097          	auipc	ra,0xffffe
    80002ca0:	8a2080e7          	jalr	-1886(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ca4:	fffff097          	auipc	ra,0xfffff
    80002ca8:	ffc080e7          	jalr	-4(ra) # 80001ca0 <myproc>
    80002cac:	d541                	beqz	a0,80002c34 <kerneltrap+0x38>
    80002cae:	fffff097          	auipc	ra,0xfffff
    80002cb2:	ff2080e7          	jalr	-14(ra) # 80001ca0 <myproc>
    80002cb6:	4d18                	lw	a4,24(a0)
    80002cb8:	4791                	li	a5,4
    80002cba:	f6f71de3          	bne	a4,a5,80002c34 <kerneltrap+0x38>
    yield();
    80002cbe:	fffff097          	auipc	ra,0xfffff
    80002cc2:	64e080e7          	jalr	1614(ra) # 8000230c <yield>
    80002cc6:	b7bd                	j	80002c34 <kerneltrap+0x38>

0000000080002cc8 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002cc8:	1101                	addi	sp,sp,-32
    80002cca:	ec06                	sd	ra,24(sp)
    80002ccc:	e822                	sd	s0,16(sp)
    80002cce:	e426                	sd	s1,8(sp)
    80002cd0:	1000                	addi	s0,sp,32
    80002cd2:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002cd4:	fffff097          	auipc	ra,0xfffff
    80002cd8:	fcc080e7          	jalr	-52(ra) # 80001ca0 <myproc>
  switch (n) {
    80002cdc:	4795                	li	a5,5
    80002cde:	0497e163          	bltu	a5,s1,80002d20 <argraw+0x58>
    80002ce2:	048a                	slli	s1,s1,0x2
    80002ce4:	00005717          	auipc	a4,0x5
    80002ce8:	7f470713          	addi	a4,a4,2036 # 800084d8 <states.0+0x170>
    80002cec:	94ba                	add	s1,s1,a4
    80002cee:	409c                	lw	a5,0(s1)
    80002cf0:	97ba                	add	a5,a5,a4
    80002cf2:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002cf4:	6d3c                	ld	a5,88(a0)
    80002cf6:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002cf8:	60e2                	ld	ra,24(sp)
    80002cfa:	6442                	ld	s0,16(sp)
    80002cfc:	64a2                	ld	s1,8(sp)
    80002cfe:	6105                	addi	sp,sp,32
    80002d00:	8082                	ret
    return p->trapframe->a1;
    80002d02:	6d3c                	ld	a5,88(a0)
    80002d04:	7fa8                	ld	a0,120(a5)
    80002d06:	bfcd                	j	80002cf8 <argraw+0x30>
    return p->trapframe->a2;
    80002d08:	6d3c                	ld	a5,88(a0)
    80002d0a:	63c8                	ld	a0,128(a5)
    80002d0c:	b7f5                	j	80002cf8 <argraw+0x30>
    return p->trapframe->a3;
    80002d0e:	6d3c                	ld	a5,88(a0)
    80002d10:	67c8                	ld	a0,136(a5)
    80002d12:	b7dd                	j	80002cf8 <argraw+0x30>
    return p->trapframe->a4;
    80002d14:	6d3c                	ld	a5,88(a0)
    80002d16:	6bc8                	ld	a0,144(a5)
    80002d18:	b7c5                	j	80002cf8 <argraw+0x30>
    return p->trapframe->a5;
    80002d1a:	6d3c                	ld	a5,88(a0)
    80002d1c:	6fc8                	ld	a0,152(a5)
    80002d1e:	bfe9                	j	80002cf8 <argraw+0x30>
  panic("argraw");
    80002d20:	00005517          	auipc	a0,0x5
    80002d24:	79050513          	addi	a0,a0,1936 # 800084b0 <states.0+0x148>
    80002d28:	ffffe097          	auipc	ra,0xffffe
    80002d2c:	816080e7          	jalr	-2026(ra) # 8000053e <panic>

0000000080002d30 <fetchaddr>:
{
    80002d30:	1101                	addi	sp,sp,-32
    80002d32:	ec06                	sd	ra,24(sp)
    80002d34:	e822                	sd	s0,16(sp)
    80002d36:	e426                	sd	s1,8(sp)
    80002d38:	e04a                	sd	s2,0(sp)
    80002d3a:	1000                	addi	s0,sp,32
    80002d3c:	84aa                	mv	s1,a0
    80002d3e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d40:	fffff097          	auipc	ra,0xfffff
    80002d44:	f60080e7          	jalr	-160(ra) # 80001ca0 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002d48:	653c                	ld	a5,72(a0)
    80002d4a:	02f4f863          	bgeu	s1,a5,80002d7a <fetchaddr+0x4a>
    80002d4e:	00848713          	addi	a4,s1,8
    80002d52:	02e7e663          	bltu	a5,a4,80002d7e <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d56:	46a1                	li	a3,8
    80002d58:	8626                	mv	a2,s1
    80002d5a:	85ca                	mv	a1,s2
    80002d5c:	6928                	ld	a0,80(a0)
    80002d5e:	fffff097          	auipc	ra,0xfffff
    80002d62:	99e080e7          	jalr	-1634(ra) # 800016fc <copyin>
    80002d66:	00a03533          	snez	a0,a0
    80002d6a:	40a00533          	neg	a0,a0
}
    80002d6e:	60e2                	ld	ra,24(sp)
    80002d70:	6442                	ld	s0,16(sp)
    80002d72:	64a2                	ld	s1,8(sp)
    80002d74:	6902                	ld	s2,0(sp)
    80002d76:	6105                	addi	sp,sp,32
    80002d78:	8082                	ret
    return -1;
    80002d7a:	557d                	li	a0,-1
    80002d7c:	bfcd                	j	80002d6e <fetchaddr+0x3e>
    80002d7e:	557d                	li	a0,-1
    80002d80:	b7fd                	j	80002d6e <fetchaddr+0x3e>

0000000080002d82 <fetchstr>:
{
    80002d82:	7179                	addi	sp,sp,-48
    80002d84:	f406                	sd	ra,40(sp)
    80002d86:	f022                	sd	s0,32(sp)
    80002d88:	ec26                	sd	s1,24(sp)
    80002d8a:	e84a                	sd	s2,16(sp)
    80002d8c:	e44e                	sd	s3,8(sp)
    80002d8e:	1800                	addi	s0,sp,48
    80002d90:	892a                	mv	s2,a0
    80002d92:	84ae                	mv	s1,a1
    80002d94:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002d96:	fffff097          	auipc	ra,0xfffff
    80002d9a:	f0a080e7          	jalr	-246(ra) # 80001ca0 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002d9e:	86ce                	mv	a3,s3
    80002da0:	864a                	mv	a2,s2
    80002da2:	85a6                	mv	a1,s1
    80002da4:	6928                	ld	a0,80(a0)
    80002da6:	fffff097          	auipc	ra,0xfffff
    80002daa:	9e4080e7          	jalr	-1564(ra) # 8000178a <copyinstr>
    80002dae:	00054e63          	bltz	a0,80002dca <fetchstr+0x48>
  return strlen(buf);
    80002db2:	8526                	mv	a0,s1
    80002db4:	ffffe097          	auipc	ra,0xffffe
    80002db8:	09a080e7          	jalr	154(ra) # 80000e4e <strlen>
}
    80002dbc:	70a2                	ld	ra,40(sp)
    80002dbe:	7402                	ld	s0,32(sp)
    80002dc0:	64e2                	ld	s1,24(sp)
    80002dc2:	6942                	ld	s2,16(sp)
    80002dc4:	69a2                	ld	s3,8(sp)
    80002dc6:	6145                	addi	sp,sp,48
    80002dc8:	8082                	ret
    return -1;
    80002dca:	557d                	li	a0,-1
    80002dcc:	bfc5                	j	80002dbc <fetchstr+0x3a>

0000000080002dce <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002dce:	1101                	addi	sp,sp,-32
    80002dd0:	ec06                	sd	ra,24(sp)
    80002dd2:	e822                	sd	s0,16(sp)
    80002dd4:	e426                	sd	s1,8(sp)
    80002dd6:	1000                	addi	s0,sp,32
    80002dd8:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002dda:	00000097          	auipc	ra,0x0
    80002dde:	eee080e7          	jalr	-274(ra) # 80002cc8 <argraw>
    80002de2:	c088                	sw	a0,0(s1)
}
    80002de4:	60e2                	ld	ra,24(sp)
    80002de6:	6442                	ld	s0,16(sp)
    80002de8:	64a2                	ld	s1,8(sp)
    80002dea:	6105                	addi	sp,sp,32
    80002dec:	8082                	ret

0000000080002dee <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002dee:	1101                	addi	sp,sp,-32
    80002df0:	ec06                	sd	ra,24(sp)
    80002df2:	e822                	sd	s0,16(sp)
    80002df4:	e426                	sd	s1,8(sp)
    80002df6:	1000                	addi	s0,sp,32
    80002df8:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002dfa:	00000097          	auipc	ra,0x0
    80002dfe:	ece080e7          	jalr	-306(ra) # 80002cc8 <argraw>
    80002e02:	e088                	sd	a0,0(s1)
}
    80002e04:	60e2                	ld	ra,24(sp)
    80002e06:	6442                	ld	s0,16(sp)
    80002e08:	64a2                	ld	s1,8(sp)
    80002e0a:	6105                	addi	sp,sp,32
    80002e0c:	8082                	ret

0000000080002e0e <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002e0e:	7179                	addi	sp,sp,-48
    80002e10:	f406                	sd	ra,40(sp)
    80002e12:	f022                	sd	s0,32(sp)
    80002e14:	ec26                	sd	s1,24(sp)
    80002e16:	e84a                	sd	s2,16(sp)
    80002e18:	1800                	addi	s0,sp,48
    80002e1a:	84ae                	mv	s1,a1
    80002e1c:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002e1e:	fd840593          	addi	a1,s0,-40
    80002e22:	00000097          	auipc	ra,0x0
    80002e26:	fcc080e7          	jalr	-52(ra) # 80002dee <argaddr>
  return fetchstr(addr, buf, max);
    80002e2a:	864a                	mv	a2,s2
    80002e2c:	85a6                	mv	a1,s1
    80002e2e:	fd843503          	ld	a0,-40(s0)
    80002e32:	00000097          	auipc	ra,0x0
    80002e36:	f50080e7          	jalr	-176(ra) # 80002d82 <fetchstr>
}
    80002e3a:	70a2                	ld	ra,40(sp)
    80002e3c:	7402                	ld	s0,32(sp)
    80002e3e:	64e2                	ld	s1,24(sp)
    80002e40:	6942                	ld	s2,16(sp)
    80002e42:	6145                	addi	sp,sp,48
    80002e44:	8082                	ret

0000000080002e46 <syscall>:
[SYS_unmap_shared_pages]  sys_unmap_shared_pages,
};

void
syscall(void)
{
    80002e46:	1101                	addi	sp,sp,-32
    80002e48:	ec06                	sd	ra,24(sp)
    80002e4a:	e822                	sd	s0,16(sp)
    80002e4c:	e426                	sd	s1,8(sp)
    80002e4e:	e04a                	sd	s2,0(sp)
    80002e50:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002e52:	fffff097          	auipc	ra,0xfffff
    80002e56:	e4e080e7          	jalr	-434(ra) # 80001ca0 <myproc>
    80002e5a:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002e5c:	05853903          	ld	s2,88(a0)
    80002e60:	0a893783          	ld	a5,168(s2)
    80002e64:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002e68:	37fd                	addiw	a5,a5,-1
    80002e6a:	4759                	li	a4,22
    80002e6c:	00f76f63          	bltu	a4,a5,80002e8a <syscall+0x44>
    80002e70:	00369713          	slli	a4,a3,0x3
    80002e74:	00005797          	auipc	a5,0x5
    80002e78:	67c78793          	addi	a5,a5,1660 # 800084f0 <syscalls>
    80002e7c:	97ba                	add	a5,a5,a4
    80002e7e:	639c                	ld	a5,0(a5)
    80002e80:	c789                	beqz	a5,80002e8a <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002e82:	9782                	jalr	a5
    80002e84:	06a93823          	sd	a0,112(s2)
    80002e88:	a839                	j	80002ea6 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002e8a:	15848613          	addi	a2,s1,344
    80002e8e:	588c                	lw	a1,48(s1)
    80002e90:	00005517          	auipc	a0,0x5
    80002e94:	62850513          	addi	a0,a0,1576 # 800084b8 <states.0+0x150>
    80002e98:	ffffd097          	auipc	ra,0xffffd
    80002e9c:	6f0080e7          	jalr	1776(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002ea0:	6cbc                	ld	a5,88(s1)
    80002ea2:	577d                	li	a4,-1
    80002ea4:	fbb8                	sd	a4,112(a5)
  }
}
    80002ea6:	60e2                	ld	ra,24(sp)
    80002ea8:	6442                	ld	s0,16(sp)
    80002eaa:	64a2                	ld	s1,8(sp)
    80002eac:	6902                	ld	s2,0(sp)
    80002eae:	6105                	addi	sp,sp,32
    80002eb0:	8082                	ret

0000000080002eb2 <sys_exit>:
extern uint64 unmap_shared_pages(struct proc*, uint64, uint64);
extern struct proc proc[NPROC];

uint64
sys_exit(void)
{
    80002eb2:	1101                	addi	sp,sp,-32
    80002eb4:	ec06                	sd	ra,24(sp)
    80002eb6:	e822                	sd	s0,16(sp)
    80002eb8:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002eba:	fec40593          	addi	a1,s0,-20
    80002ebe:	4501                	li	a0,0
    80002ec0:	00000097          	auipc	ra,0x0
    80002ec4:	f0e080e7          	jalr	-242(ra) # 80002dce <argint>
  exit(n);
    80002ec8:	fec42503          	lw	a0,-20(s0)
    80002ecc:	fffff097          	auipc	ra,0xfffff
    80002ed0:	5b0080e7          	jalr	1456(ra) # 8000247c <exit>
  return 0;  // not reached
}
    80002ed4:	4501                	li	a0,0
    80002ed6:	60e2                	ld	ra,24(sp)
    80002ed8:	6442                	ld	s0,16(sp)
    80002eda:	6105                	addi	sp,sp,32
    80002edc:	8082                	ret

0000000080002ede <sys_getpid>:

uint64
sys_getpid(void)
{
    80002ede:	1141                	addi	sp,sp,-16
    80002ee0:	e406                	sd	ra,8(sp)
    80002ee2:	e022                	sd	s0,0(sp)
    80002ee4:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002ee6:	fffff097          	auipc	ra,0xfffff
    80002eea:	dba080e7          	jalr	-582(ra) # 80001ca0 <myproc>
}
    80002eee:	5908                	lw	a0,48(a0)
    80002ef0:	60a2                	ld	ra,8(sp)
    80002ef2:	6402                	ld	s0,0(sp)
    80002ef4:	0141                	addi	sp,sp,16
    80002ef6:	8082                	ret

0000000080002ef8 <sys_fork>:

uint64
sys_fork(void)
{
    80002ef8:	1141                	addi	sp,sp,-16
    80002efa:	e406                	sd	ra,8(sp)
    80002efc:	e022                	sd	s0,0(sp)
    80002efe:	0800                	addi	s0,sp,16
  return fork();
    80002f00:	fffff097          	auipc	ra,0xfffff
    80002f04:	156080e7          	jalr	342(ra) # 80002056 <fork>
}
    80002f08:	60a2                	ld	ra,8(sp)
    80002f0a:	6402                	ld	s0,0(sp)
    80002f0c:	0141                	addi	sp,sp,16
    80002f0e:	8082                	ret

0000000080002f10 <sys_wait>:

uint64
sys_wait(void)
{
    80002f10:	1101                	addi	sp,sp,-32
    80002f12:	ec06                	sd	ra,24(sp)
    80002f14:	e822                	sd	s0,16(sp)
    80002f16:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002f18:	fe840593          	addi	a1,s0,-24
    80002f1c:	4501                	li	a0,0
    80002f1e:	00000097          	auipc	ra,0x0
    80002f22:	ed0080e7          	jalr	-304(ra) # 80002dee <argaddr>
  return wait(p);
    80002f26:	fe843503          	ld	a0,-24(s0)
    80002f2a:	fffff097          	auipc	ra,0xfffff
    80002f2e:	6f8080e7          	jalr	1784(ra) # 80002622 <wait>
}
    80002f32:	60e2                	ld	ra,24(sp)
    80002f34:	6442                	ld	s0,16(sp)
    80002f36:	6105                	addi	sp,sp,32
    80002f38:	8082                	ret

0000000080002f3a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f3a:	7179                	addi	sp,sp,-48
    80002f3c:	f406                	sd	ra,40(sp)
    80002f3e:	f022                	sd	s0,32(sp)
    80002f40:	ec26                	sd	s1,24(sp)
    80002f42:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002f44:	fdc40593          	addi	a1,s0,-36
    80002f48:	4501                	li	a0,0
    80002f4a:	00000097          	auipc	ra,0x0
    80002f4e:	e84080e7          	jalr	-380(ra) # 80002dce <argint>
  addr = myproc()->sz;
    80002f52:	fffff097          	auipc	ra,0xfffff
    80002f56:	d4e080e7          	jalr	-690(ra) # 80001ca0 <myproc>
    80002f5a:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002f5c:	fdc42503          	lw	a0,-36(s0)
    80002f60:	fffff097          	auipc	ra,0xfffff
    80002f64:	09a080e7          	jalr	154(ra) # 80001ffa <growproc>
    80002f68:	00054863          	bltz	a0,80002f78 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002f6c:	8526                	mv	a0,s1
    80002f6e:	70a2                	ld	ra,40(sp)
    80002f70:	7402                	ld	s0,32(sp)
    80002f72:	64e2                	ld	s1,24(sp)
    80002f74:	6145                	addi	sp,sp,48
    80002f76:	8082                	ret
    return -1;
    80002f78:	54fd                	li	s1,-1
    80002f7a:	bfcd                	j	80002f6c <sys_sbrk+0x32>

0000000080002f7c <sys_sleep>:

uint64
sys_sleep(void)
{
    80002f7c:	7139                	addi	sp,sp,-64
    80002f7e:	fc06                	sd	ra,56(sp)
    80002f80:	f822                	sd	s0,48(sp)
    80002f82:	f426                	sd	s1,40(sp)
    80002f84:	f04a                	sd	s2,32(sp)
    80002f86:	ec4e                	sd	s3,24(sp)
    80002f88:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002f8a:	fcc40593          	addi	a1,s0,-52
    80002f8e:	4501                	li	a0,0
    80002f90:	00000097          	auipc	ra,0x0
    80002f94:	e3e080e7          	jalr	-450(ra) # 80002dce <argint>
  acquire(&tickslock);
    80002f98:	00014517          	auipc	a0,0x14
    80002f9c:	a7850513          	addi	a0,a0,-1416 # 80016a10 <tickslock>
    80002fa0:	ffffe097          	auipc	ra,0xffffe
    80002fa4:	c36080e7          	jalr	-970(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002fa8:	00006917          	auipc	s2,0x6
    80002fac:	9c892903          	lw	s2,-1592(s2) # 80008970 <ticks>
  while(ticks - ticks0 < n){
    80002fb0:	fcc42783          	lw	a5,-52(s0)
    80002fb4:	cf9d                	beqz	a5,80002ff2 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002fb6:	00014997          	auipc	s3,0x14
    80002fba:	a5a98993          	addi	s3,s3,-1446 # 80016a10 <tickslock>
    80002fbe:	00006497          	auipc	s1,0x6
    80002fc2:	9b248493          	addi	s1,s1,-1614 # 80008970 <ticks>
    if(killed(myproc())){
    80002fc6:	fffff097          	auipc	ra,0xfffff
    80002fca:	cda080e7          	jalr	-806(ra) # 80001ca0 <myproc>
    80002fce:	fffff097          	auipc	ra,0xfffff
    80002fd2:	622080e7          	jalr	1570(ra) # 800025f0 <killed>
    80002fd6:	ed15                	bnez	a0,80003012 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002fd8:	85ce                	mv	a1,s3
    80002fda:	8526                	mv	a0,s1
    80002fdc:	fffff097          	auipc	ra,0xfffff
    80002fe0:	36c080e7          	jalr	876(ra) # 80002348 <sleep>
  while(ticks - ticks0 < n){
    80002fe4:	409c                	lw	a5,0(s1)
    80002fe6:	412787bb          	subw	a5,a5,s2
    80002fea:	fcc42703          	lw	a4,-52(s0)
    80002fee:	fce7ece3          	bltu	a5,a4,80002fc6 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002ff2:	00014517          	auipc	a0,0x14
    80002ff6:	a1e50513          	addi	a0,a0,-1506 # 80016a10 <tickslock>
    80002ffa:	ffffe097          	auipc	ra,0xffffe
    80002ffe:	c90080e7          	jalr	-880(ra) # 80000c8a <release>
  return 0;
    80003002:	4501                	li	a0,0
}
    80003004:	70e2                	ld	ra,56(sp)
    80003006:	7442                	ld	s0,48(sp)
    80003008:	74a2                	ld	s1,40(sp)
    8000300a:	7902                	ld	s2,32(sp)
    8000300c:	69e2                	ld	s3,24(sp)
    8000300e:	6121                	addi	sp,sp,64
    80003010:	8082                	ret
      release(&tickslock);
    80003012:	00014517          	auipc	a0,0x14
    80003016:	9fe50513          	addi	a0,a0,-1538 # 80016a10 <tickslock>
    8000301a:	ffffe097          	auipc	ra,0xffffe
    8000301e:	c70080e7          	jalr	-912(ra) # 80000c8a <release>
      return -1;
    80003022:	557d                	li	a0,-1
    80003024:	b7c5                	j	80003004 <sys_sleep+0x88>

0000000080003026 <sys_kill>:

uint64
sys_kill(void)
{
    80003026:	1101                	addi	sp,sp,-32
    80003028:	ec06                	sd	ra,24(sp)
    8000302a:	e822                	sd	s0,16(sp)
    8000302c:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    8000302e:	fec40593          	addi	a1,s0,-20
    80003032:	4501                	li	a0,0
    80003034:	00000097          	auipc	ra,0x0
    80003038:	d9a080e7          	jalr	-614(ra) # 80002dce <argint>
  return kill(pid);
    8000303c:	fec42503          	lw	a0,-20(s0)
    80003040:	fffff097          	auipc	ra,0xfffff
    80003044:	512080e7          	jalr	1298(ra) # 80002552 <kill>
}
    80003048:	60e2                	ld	ra,24(sp)
    8000304a:	6442                	ld	s0,16(sp)
    8000304c:	6105                	addi	sp,sp,32
    8000304e:	8082                	ret

0000000080003050 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003050:	1101                	addi	sp,sp,-32
    80003052:	ec06                	sd	ra,24(sp)
    80003054:	e822                	sd	s0,16(sp)
    80003056:	e426                	sd	s1,8(sp)
    80003058:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000305a:	00014517          	auipc	a0,0x14
    8000305e:	9b650513          	addi	a0,a0,-1610 # 80016a10 <tickslock>
    80003062:	ffffe097          	auipc	ra,0xffffe
    80003066:	b74080e7          	jalr	-1164(ra) # 80000bd6 <acquire>
  xticks = ticks;
    8000306a:	00006497          	auipc	s1,0x6
    8000306e:	9064a483          	lw	s1,-1786(s1) # 80008970 <ticks>
  release(&tickslock);
    80003072:	00014517          	auipc	a0,0x14
    80003076:	99e50513          	addi	a0,a0,-1634 # 80016a10 <tickslock>
    8000307a:	ffffe097          	auipc	ra,0xffffe
    8000307e:	c10080e7          	jalr	-1008(ra) # 80000c8a <release>
  return xticks;
}
    80003082:	02049513          	slli	a0,s1,0x20
    80003086:	9101                	srli	a0,a0,0x20
    80003088:	60e2                	ld	ra,24(sp)
    8000308a:	6442                	ld	s0,16(sp)
    8000308c:	64a2                	ld	s1,8(sp)
    8000308e:	6105                	addi	sp,sp,32
    80003090:	8082                	ret

0000000080003092 <sys_map_shared_pages>:
// ----------------------------------------------------------------------
// task1:
uint64
sys_map_shared_pages(void)
{
    80003092:	715d                	addi	sp,sp,-80
    80003094:	e486                	sd	ra,72(sp)
    80003096:	e0a2                	sd	s0,64(sp)
    80003098:	fc26                	sd	s1,56(sp)
    8000309a:	f84a                	sd	s2,48(sp)
    8000309c:	f44e                	sd	s3,40(sp)
    8000309e:	f052                	sd	s4,32(sp)
    800030a0:	0880                	addi	s0,sp,80
    int src_pid, dst_pid;
    uint64 src_va, size;
    struct proc *src_proc, *dst_proc;
    
    // Extract arguments from user space
    argint(0, &src_pid);
    800030a2:	fcc40593          	addi	a1,s0,-52
    800030a6:	4501                	li	a0,0
    800030a8:	00000097          	auipc	ra,0x0
    800030ac:	d26080e7          	jalr	-730(ra) # 80002dce <argint>
    argint(1, &dst_pid);
    800030b0:	fc840593          	addi	a1,s0,-56
    800030b4:	4505                	li	a0,1
    800030b6:	00000097          	auipc	ra,0x0
    800030ba:	d18080e7          	jalr	-744(ra) # 80002dce <argint>
    argaddr(2, &src_va);
    800030be:	fc040593          	addi	a1,s0,-64
    800030c2:	4509                	li	a0,2
    800030c4:	00000097          	auipc	ra,0x0
    800030c8:	d2a080e7          	jalr	-726(ra) # 80002dee <argaddr>
    argaddr(3, &size);
    800030cc:	fb840593          	addi	a1,s0,-72
    800030d0:	450d                	li	a0,3
    800030d2:	00000097          	auipc	ra,0x0
    800030d6:	d1c080e7          	jalr	-740(ra) # 80002dee <argaddr>
    
    // Find source process by PID
    src_proc = 0; 
    dst_proc = 0;
    for(struct proc *p = proc; p < &proc[NPROC]; p++) {
    800030da:	0000e497          	auipc	s1,0xe
    800030de:	f3648493          	addi	s1,s1,-202 # 80011010 <proc>
    dst_proc = 0;
    800030e2:	4a01                	li	s4,0
    src_proc = 0; 
    800030e4:	4901                	li	s2,0
    for(struct proc *p = proc; p < &proc[NPROC]; p++) {
    800030e6:	00014997          	auipc	s3,0x14
    800030ea:	92a98993          	addi	s3,s3,-1750 # 80016a10 <tickslock>
    800030ee:	a005                	j	8000310e <sys_map_shared_pages+0x7c>
      acquire(&p->lock);
      if(p->state != UNUSED) {
          if(p->pid == src_pid)
    800030f0:	8926                	mv	s2,s1
    800030f2:	a815                	j	80003126 <sys_map_shared_pages+0x94>
              src_proc = p;
          if(p->pid == dst_pid)
              dst_proc = p;
      }
      release(&p->lock);
    800030f4:	8526                	mv	a0,s1
    800030f6:	ffffe097          	auipc	ra,0xffffe
    800030fa:	b94080e7          	jalr	-1132(ra) # 80000c8a <release>

      if(src_proc && dst_proc)
    800030fe:	00090463          	beqz	s2,80003106 <sys_map_shared_pages+0x74>
    80003102:	060a1763          	bnez	s4,80003170 <sys_map_shared_pages+0xde>
    for(struct proc *p = proc; p < &proc[NPROC]; p++) {
    80003106:	16848493          	addi	s1,s1,360
    8000310a:	03348b63          	beq	s1,s3,80003140 <sys_map_shared_pages+0xae>
      acquire(&p->lock);
    8000310e:	8526                	mv	a0,s1
    80003110:	ffffe097          	auipc	ra,0xffffe
    80003114:	ac6080e7          	jalr	-1338(ra) # 80000bd6 <acquire>
      if(p->state != UNUSED) {
    80003118:	4c9c                	lw	a5,24(s1)
    8000311a:	dfe9                	beqz	a5,800030f4 <sys_map_shared_pages+0x62>
          if(p->pid == src_pid)
    8000311c:	589c                	lw	a5,48(s1)
    8000311e:	fcc42703          	lw	a4,-52(s0)
    80003122:	fcf707e3          	beq	a4,a5,800030f0 <sys_map_shared_pages+0x5e>
          if(p->pid == dst_pid)
    80003126:	fc842703          	lw	a4,-56(s0)
    8000312a:	fcf715e3          	bne	a4,a5,800030f4 <sys_map_shared_pages+0x62>
      release(&p->lock);
    8000312e:	8526                	mv	a0,s1
    80003130:	ffffe097          	auipc	ra,0xffffe
    80003134:	b5a080e7          	jalr	-1190(ra) # 80000c8a <release>
      if(src_proc && dst_proc)
    80003138:	00091a63          	bnez	s2,8000314c <sys_map_shared_pages+0xba>
    8000313c:	8a26                	mv	s4,s1
    8000313e:	b7e1                	j	80003106 <sys_map_shared_pages+0x74>
          break;
    }

    
    if(src_proc == 0 || dst_proc == 0) {
        return -1; // Source process not found
    80003140:	557d                	li	a0,-1
    if(src_proc == 0 || dst_proc == 0) {
    80003142:	00090f63          	beqz	s2,80003160 <sys_map_shared_pages+0xce>
    80003146:	000a0d63          	beqz	s4,80003160 <sys_map_shared_pages+0xce>
    8000314a:	84d2                	mv	s1,s4
    }
    
    return map_shared_pages(src_proc, dst_proc, src_va, size);
    8000314c:	fb843683          	ld	a3,-72(s0)
    80003150:	fc043603          	ld	a2,-64(s0)
    80003154:	85a6                	mv	a1,s1
    80003156:	854a                	mv	a0,s2
    80003158:	ffffe097          	auipc	ra,0xffffe
    8000315c:	6e6080e7          	jalr	1766(ra) # 8000183e <map_shared_pages>
}
    80003160:	60a6                	ld	ra,72(sp)
    80003162:	6406                	ld	s0,64(sp)
    80003164:	74e2                	ld	s1,56(sp)
    80003166:	7942                	ld	s2,48(sp)
    80003168:	79a2                	ld	s3,40(sp)
    8000316a:	7a02                	ld	s4,32(sp)
    8000316c:	6161                	addi	sp,sp,80
    8000316e:	8082                	ret
    80003170:	84d2                	mv	s1,s4
    if(src_proc == 0 || dst_proc == 0) {
    80003172:	bfe9                	j	8000314c <sys_map_shared_pages+0xba>

0000000080003174 <sys_unmap_shared_pages>:

// ----------------------------------------------------------------------
uint64
sys_unmap_shared_pages(void)
{
    80003174:	7179                	addi	sp,sp,-48
    80003176:	f406                	sd	ra,40(sp)
    80003178:	f022                	sd	s0,32(sp)
    8000317a:	ec26                	sd	s1,24(sp)
    8000317c:	1800                	addi	s0,sp,48
  struct proc *curproc = myproc();
    8000317e:	fffff097          	auipc	ra,0xfffff
    80003182:	b22080e7          	jalr	-1246(ra) # 80001ca0 <myproc>
    80003186:	84aa                	mv	s1,a0
  uint64 addr;
  int size;

  argaddr(0, &addr);
    80003188:	fd840593          	addi	a1,s0,-40
    8000318c:	4501                	li	a0,0
    8000318e:	00000097          	auipc	ra,0x0
    80003192:	c60080e7          	jalr	-928(ra) # 80002dee <argaddr>
  argint(1, &size);
    80003196:	fd440593          	addi	a1,s0,-44
    8000319a:	4505                	li	a0,1
    8000319c:	00000097          	auipc	ra,0x0
    800031a0:	c32080e7          	jalr	-974(ra) # 80002dce <argint>

  return unmap_shared_pages(curproc, addr, size);
    800031a4:	fd442603          	lw	a2,-44(s0)
    800031a8:	fd843583          	ld	a1,-40(s0)
    800031ac:	8526                	mv	a0,s1
    800031ae:	fffff097          	auipc	ra,0xfffff
    800031b2:	8b2080e7          	jalr	-1870(ra) # 80001a60 <unmap_shared_pages>
}
    800031b6:	70a2                	ld	ra,40(sp)
    800031b8:	7402                	ld	s0,32(sp)
    800031ba:	64e2                	ld	s1,24(sp)
    800031bc:	6145                	addi	sp,sp,48
    800031be:	8082                	ret

00000000800031c0 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800031c0:	7179                	addi	sp,sp,-48
    800031c2:	f406                	sd	ra,40(sp)
    800031c4:	f022                	sd	s0,32(sp)
    800031c6:	ec26                	sd	s1,24(sp)
    800031c8:	e84a                	sd	s2,16(sp)
    800031ca:	e44e                	sd	s3,8(sp)
    800031cc:	e052                	sd	s4,0(sp)
    800031ce:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800031d0:	00005597          	auipc	a1,0x5
    800031d4:	3e058593          	addi	a1,a1,992 # 800085b0 <syscalls+0xc0>
    800031d8:	00014517          	auipc	a0,0x14
    800031dc:	85050513          	addi	a0,a0,-1968 # 80016a28 <bcache>
    800031e0:	ffffe097          	auipc	ra,0xffffe
    800031e4:	966080e7          	jalr	-1690(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800031e8:	0001c797          	auipc	a5,0x1c
    800031ec:	84078793          	addi	a5,a5,-1984 # 8001ea28 <bcache+0x8000>
    800031f0:	0001c717          	auipc	a4,0x1c
    800031f4:	aa070713          	addi	a4,a4,-1376 # 8001ec90 <bcache+0x8268>
    800031f8:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800031fc:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003200:	00014497          	auipc	s1,0x14
    80003204:	84048493          	addi	s1,s1,-1984 # 80016a40 <bcache+0x18>
    b->next = bcache.head.next;
    80003208:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000320a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000320c:	00005a17          	auipc	s4,0x5
    80003210:	3aca0a13          	addi	s4,s4,940 # 800085b8 <syscalls+0xc8>
    b->next = bcache.head.next;
    80003214:	2b893783          	ld	a5,696(s2)
    80003218:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000321a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000321e:	85d2                	mv	a1,s4
    80003220:	01048513          	addi	a0,s1,16
    80003224:	00001097          	auipc	ra,0x1
    80003228:	4c4080e7          	jalr	1220(ra) # 800046e8 <initsleeplock>
    bcache.head.next->prev = b;
    8000322c:	2b893783          	ld	a5,696(s2)
    80003230:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003232:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003236:	45848493          	addi	s1,s1,1112
    8000323a:	fd349de3          	bne	s1,s3,80003214 <binit+0x54>
  }
}
    8000323e:	70a2                	ld	ra,40(sp)
    80003240:	7402                	ld	s0,32(sp)
    80003242:	64e2                	ld	s1,24(sp)
    80003244:	6942                	ld	s2,16(sp)
    80003246:	69a2                	ld	s3,8(sp)
    80003248:	6a02                	ld	s4,0(sp)
    8000324a:	6145                	addi	sp,sp,48
    8000324c:	8082                	ret

000000008000324e <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000324e:	7179                	addi	sp,sp,-48
    80003250:	f406                	sd	ra,40(sp)
    80003252:	f022                	sd	s0,32(sp)
    80003254:	ec26                	sd	s1,24(sp)
    80003256:	e84a                	sd	s2,16(sp)
    80003258:	e44e                	sd	s3,8(sp)
    8000325a:	1800                	addi	s0,sp,48
    8000325c:	892a                	mv	s2,a0
    8000325e:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003260:	00013517          	auipc	a0,0x13
    80003264:	7c850513          	addi	a0,a0,1992 # 80016a28 <bcache>
    80003268:	ffffe097          	auipc	ra,0xffffe
    8000326c:	96e080e7          	jalr	-1682(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003270:	0001c497          	auipc	s1,0x1c
    80003274:	a704b483          	ld	s1,-1424(s1) # 8001ece0 <bcache+0x82b8>
    80003278:	0001c797          	auipc	a5,0x1c
    8000327c:	a1878793          	addi	a5,a5,-1512 # 8001ec90 <bcache+0x8268>
    80003280:	02f48f63          	beq	s1,a5,800032be <bread+0x70>
    80003284:	873e                	mv	a4,a5
    80003286:	a021                	j	8000328e <bread+0x40>
    80003288:	68a4                	ld	s1,80(s1)
    8000328a:	02e48a63          	beq	s1,a4,800032be <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000328e:	449c                	lw	a5,8(s1)
    80003290:	ff279ce3          	bne	a5,s2,80003288 <bread+0x3a>
    80003294:	44dc                	lw	a5,12(s1)
    80003296:	ff3799e3          	bne	a5,s3,80003288 <bread+0x3a>
      b->refcnt++;
    8000329a:	40bc                	lw	a5,64(s1)
    8000329c:	2785                	addiw	a5,a5,1
    8000329e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800032a0:	00013517          	auipc	a0,0x13
    800032a4:	78850513          	addi	a0,a0,1928 # 80016a28 <bcache>
    800032a8:	ffffe097          	auipc	ra,0xffffe
    800032ac:	9e2080e7          	jalr	-1566(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    800032b0:	01048513          	addi	a0,s1,16
    800032b4:	00001097          	auipc	ra,0x1
    800032b8:	46e080e7          	jalr	1134(ra) # 80004722 <acquiresleep>
      return b;
    800032bc:	a8b9                	j	8000331a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800032be:	0001c497          	auipc	s1,0x1c
    800032c2:	a1a4b483          	ld	s1,-1510(s1) # 8001ecd8 <bcache+0x82b0>
    800032c6:	0001c797          	auipc	a5,0x1c
    800032ca:	9ca78793          	addi	a5,a5,-1590 # 8001ec90 <bcache+0x8268>
    800032ce:	00f48863          	beq	s1,a5,800032de <bread+0x90>
    800032d2:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800032d4:	40bc                	lw	a5,64(s1)
    800032d6:	cf81                	beqz	a5,800032ee <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800032d8:	64a4                	ld	s1,72(s1)
    800032da:	fee49de3          	bne	s1,a4,800032d4 <bread+0x86>
  panic("bget: no buffers");
    800032de:	00005517          	auipc	a0,0x5
    800032e2:	2e250513          	addi	a0,a0,738 # 800085c0 <syscalls+0xd0>
    800032e6:	ffffd097          	auipc	ra,0xffffd
    800032ea:	258080e7          	jalr	600(ra) # 8000053e <panic>
      b->dev = dev;
    800032ee:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800032f2:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800032f6:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800032fa:	4785                	li	a5,1
    800032fc:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800032fe:	00013517          	auipc	a0,0x13
    80003302:	72a50513          	addi	a0,a0,1834 # 80016a28 <bcache>
    80003306:	ffffe097          	auipc	ra,0xffffe
    8000330a:	984080e7          	jalr	-1660(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    8000330e:	01048513          	addi	a0,s1,16
    80003312:	00001097          	auipc	ra,0x1
    80003316:	410080e7          	jalr	1040(ra) # 80004722 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000331a:	409c                	lw	a5,0(s1)
    8000331c:	cb89                	beqz	a5,8000332e <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000331e:	8526                	mv	a0,s1
    80003320:	70a2                	ld	ra,40(sp)
    80003322:	7402                	ld	s0,32(sp)
    80003324:	64e2                	ld	s1,24(sp)
    80003326:	6942                	ld	s2,16(sp)
    80003328:	69a2                	ld	s3,8(sp)
    8000332a:	6145                	addi	sp,sp,48
    8000332c:	8082                	ret
    virtio_disk_rw(b, 0);
    8000332e:	4581                	li	a1,0
    80003330:	8526                	mv	a0,s1
    80003332:	00003097          	auipc	ra,0x3
    80003336:	fd2080e7          	jalr	-46(ra) # 80006304 <virtio_disk_rw>
    b->valid = 1;
    8000333a:	4785                	li	a5,1
    8000333c:	c09c                	sw	a5,0(s1)
  return b;
    8000333e:	b7c5                	j	8000331e <bread+0xd0>

0000000080003340 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003340:	1101                	addi	sp,sp,-32
    80003342:	ec06                	sd	ra,24(sp)
    80003344:	e822                	sd	s0,16(sp)
    80003346:	e426                	sd	s1,8(sp)
    80003348:	1000                	addi	s0,sp,32
    8000334a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000334c:	0541                	addi	a0,a0,16
    8000334e:	00001097          	auipc	ra,0x1
    80003352:	46e080e7          	jalr	1134(ra) # 800047bc <holdingsleep>
    80003356:	cd01                	beqz	a0,8000336e <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003358:	4585                	li	a1,1
    8000335a:	8526                	mv	a0,s1
    8000335c:	00003097          	auipc	ra,0x3
    80003360:	fa8080e7          	jalr	-88(ra) # 80006304 <virtio_disk_rw>
}
    80003364:	60e2                	ld	ra,24(sp)
    80003366:	6442                	ld	s0,16(sp)
    80003368:	64a2                	ld	s1,8(sp)
    8000336a:	6105                	addi	sp,sp,32
    8000336c:	8082                	ret
    panic("bwrite");
    8000336e:	00005517          	auipc	a0,0x5
    80003372:	26a50513          	addi	a0,a0,618 # 800085d8 <syscalls+0xe8>
    80003376:	ffffd097          	auipc	ra,0xffffd
    8000337a:	1c8080e7          	jalr	456(ra) # 8000053e <panic>

000000008000337e <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000337e:	1101                	addi	sp,sp,-32
    80003380:	ec06                	sd	ra,24(sp)
    80003382:	e822                	sd	s0,16(sp)
    80003384:	e426                	sd	s1,8(sp)
    80003386:	e04a                	sd	s2,0(sp)
    80003388:	1000                	addi	s0,sp,32
    8000338a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000338c:	01050913          	addi	s2,a0,16
    80003390:	854a                	mv	a0,s2
    80003392:	00001097          	auipc	ra,0x1
    80003396:	42a080e7          	jalr	1066(ra) # 800047bc <holdingsleep>
    8000339a:	c92d                	beqz	a0,8000340c <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000339c:	854a                	mv	a0,s2
    8000339e:	00001097          	auipc	ra,0x1
    800033a2:	3da080e7          	jalr	986(ra) # 80004778 <releasesleep>

  acquire(&bcache.lock);
    800033a6:	00013517          	auipc	a0,0x13
    800033aa:	68250513          	addi	a0,a0,1666 # 80016a28 <bcache>
    800033ae:	ffffe097          	auipc	ra,0xffffe
    800033b2:	828080e7          	jalr	-2008(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800033b6:	40bc                	lw	a5,64(s1)
    800033b8:	37fd                	addiw	a5,a5,-1
    800033ba:	0007871b          	sext.w	a4,a5
    800033be:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800033c0:	eb05                	bnez	a4,800033f0 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800033c2:	68bc                	ld	a5,80(s1)
    800033c4:	64b8                	ld	a4,72(s1)
    800033c6:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800033c8:	64bc                	ld	a5,72(s1)
    800033ca:	68b8                	ld	a4,80(s1)
    800033cc:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800033ce:	0001b797          	auipc	a5,0x1b
    800033d2:	65a78793          	addi	a5,a5,1626 # 8001ea28 <bcache+0x8000>
    800033d6:	2b87b703          	ld	a4,696(a5)
    800033da:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800033dc:	0001c717          	auipc	a4,0x1c
    800033e0:	8b470713          	addi	a4,a4,-1868 # 8001ec90 <bcache+0x8268>
    800033e4:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800033e6:	2b87b703          	ld	a4,696(a5)
    800033ea:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800033ec:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800033f0:	00013517          	auipc	a0,0x13
    800033f4:	63850513          	addi	a0,a0,1592 # 80016a28 <bcache>
    800033f8:	ffffe097          	auipc	ra,0xffffe
    800033fc:	892080e7          	jalr	-1902(ra) # 80000c8a <release>
}
    80003400:	60e2                	ld	ra,24(sp)
    80003402:	6442                	ld	s0,16(sp)
    80003404:	64a2                	ld	s1,8(sp)
    80003406:	6902                	ld	s2,0(sp)
    80003408:	6105                	addi	sp,sp,32
    8000340a:	8082                	ret
    panic("brelse");
    8000340c:	00005517          	auipc	a0,0x5
    80003410:	1d450513          	addi	a0,a0,468 # 800085e0 <syscalls+0xf0>
    80003414:	ffffd097          	auipc	ra,0xffffd
    80003418:	12a080e7          	jalr	298(ra) # 8000053e <panic>

000000008000341c <bpin>:

void
bpin(struct buf *b) {
    8000341c:	1101                	addi	sp,sp,-32
    8000341e:	ec06                	sd	ra,24(sp)
    80003420:	e822                	sd	s0,16(sp)
    80003422:	e426                	sd	s1,8(sp)
    80003424:	1000                	addi	s0,sp,32
    80003426:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003428:	00013517          	auipc	a0,0x13
    8000342c:	60050513          	addi	a0,a0,1536 # 80016a28 <bcache>
    80003430:	ffffd097          	auipc	ra,0xffffd
    80003434:	7a6080e7          	jalr	1958(ra) # 80000bd6 <acquire>
  b->refcnt++;
    80003438:	40bc                	lw	a5,64(s1)
    8000343a:	2785                	addiw	a5,a5,1
    8000343c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000343e:	00013517          	auipc	a0,0x13
    80003442:	5ea50513          	addi	a0,a0,1514 # 80016a28 <bcache>
    80003446:	ffffe097          	auipc	ra,0xffffe
    8000344a:	844080e7          	jalr	-1980(ra) # 80000c8a <release>
}
    8000344e:	60e2                	ld	ra,24(sp)
    80003450:	6442                	ld	s0,16(sp)
    80003452:	64a2                	ld	s1,8(sp)
    80003454:	6105                	addi	sp,sp,32
    80003456:	8082                	ret

0000000080003458 <bunpin>:

void
bunpin(struct buf *b) {
    80003458:	1101                	addi	sp,sp,-32
    8000345a:	ec06                	sd	ra,24(sp)
    8000345c:	e822                	sd	s0,16(sp)
    8000345e:	e426                	sd	s1,8(sp)
    80003460:	1000                	addi	s0,sp,32
    80003462:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003464:	00013517          	auipc	a0,0x13
    80003468:	5c450513          	addi	a0,a0,1476 # 80016a28 <bcache>
    8000346c:	ffffd097          	auipc	ra,0xffffd
    80003470:	76a080e7          	jalr	1898(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003474:	40bc                	lw	a5,64(s1)
    80003476:	37fd                	addiw	a5,a5,-1
    80003478:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000347a:	00013517          	auipc	a0,0x13
    8000347e:	5ae50513          	addi	a0,a0,1454 # 80016a28 <bcache>
    80003482:	ffffe097          	auipc	ra,0xffffe
    80003486:	808080e7          	jalr	-2040(ra) # 80000c8a <release>
}
    8000348a:	60e2                	ld	ra,24(sp)
    8000348c:	6442                	ld	s0,16(sp)
    8000348e:	64a2                	ld	s1,8(sp)
    80003490:	6105                	addi	sp,sp,32
    80003492:	8082                	ret

0000000080003494 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003494:	1101                	addi	sp,sp,-32
    80003496:	ec06                	sd	ra,24(sp)
    80003498:	e822                	sd	s0,16(sp)
    8000349a:	e426                	sd	s1,8(sp)
    8000349c:	e04a                	sd	s2,0(sp)
    8000349e:	1000                	addi	s0,sp,32
    800034a0:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800034a2:	00d5d59b          	srliw	a1,a1,0xd
    800034a6:	0001c797          	auipc	a5,0x1c
    800034aa:	c5e7a783          	lw	a5,-930(a5) # 8001f104 <sb+0x1c>
    800034ae:	9dbd                	addw	a1,a1,a5
    800034b0:	00000097          	auipc	ra,0x0
    800034b4:	d9e080e7          	jalr	-610(ra) # 8000324e <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800034b8:	0074f713          	andi	a4,s1,7
    800034bc:	4785                	li	a5,1
    800034be:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800034c2:	14ce                	slli	s1,s1,0x33
    800034c4:	90d9                	srli	s1,s1,0x36
    800034c6:	00950733          	add	a4,a0,s1
    800034ca:	05874703          	lbu	a4,88(a4)
    800034ce:	00e7f6b3          	and	a3,a5,a4
    800034d2:	c69d                	beqz	a3,80003500 <bfree+0x6c>
    800034d4:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800034d6:	94aa                	add	s1,s1,a0
    800034d8:	fff7c793          	not	a5,a5
    800034dc:	8ff9                	and	a5,a5,a4
    800034de:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800034e2:	00001097          	auipc	ra,0x1
    800034e6:	120080e7          	jalr	288(ra) # 80004602 <log_write>
  brelse(bp);
    800034ea:	854a                	mv	a0,s2
    800034ec:	00000097          	auipc	ra,0x0
    800034f0:	e92080e7          	jalr	-366(ra) # 8000337e <brelse>
}
    800034f4:	60e2                	ld	ra,24(sp)
    800034f6:	6442                	ld	s0,16(sp)
    800034f8:	64a2                	ld	s1,8(sp)
    800034fa:	6902                	ld	s2,0(sp)
    800034fc:	6105                	addi	sp,sp,32
    800034fe:	8082                	ret
    panic("freeing free block");
    80003500:	00005517          	auipc	a0,0x5
    80003504:	0e850513          	addi	a0,a0,232 # 800085e8 <syscalls+0xf8>
    80003508:	ffffd097          	auipc	ra,0xffffd
    8000350c:	036080e7          	jalr	54(ra) # 8000053e <panic>

0000000080003510 <balloc>:
{
    80003510:	711d                	addi	sp,sp,-96
    80003512:	ec86                	sd	ra,88(sp)
    80003514:	e8a2                	sd	s0,80(sp)
    80003516:	e4a6                	sd	s1,72(sp)
    80003518:	e0ca                	sd	s2,64(sp)
    8000351a:	fc4e                	sd	s3,56(sp)
    8000351c:	f852                	sd	s4,48(sp)
    8000351e:	f456                	sd	s5,40(sp)
    80003520:	f05a                	sd	s6,32(sp)
    80003522:	ec5e                	sd	s7,24(sp)
    80003524:	e862                	sd	s8,16(sp)
    80003526:	e466                	sd	s9,8(sp)
    80003528:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000352a:	0001c797          	auipc	a5,0x1c
    8000352e:	bc27a783          	lw	a5,-1086(a5) # 8001f0ec <sb+0x4>
    80003532:	10078163          	beqz	a5,80003634 <balloc+0x124>
    80003536:	8baa                	mv	s7,a0
    80003538:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000353a:	0001cb17          	auipc	s6,0x1c
    8000353e:	baeb0b13          	addi	s6,s6,-1106 # 8001f0e8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003542:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003544:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003546:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003548:	6c89                	lui	s9,0x2
    8000354a:	a061                	j	800035d2 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000354c:	974a                	add	a4,a4,s2
    8000354e:	8fd5                	or	a5,a5,a3
    80003550:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003554:	854a                	mv	a0,s2
    80003556:	00001097          	auipc	ra,0x1
    8000355a:	0ac080e7          	jalr	172(ra) # 80004602 <log_write>
        brelse(bp);
    8000355e:	854a                	mv	a0,s2
    80003560:	00000097          	auipc	ra,0x0
    80003564:	e1e080e7          	jalr	-482(ra) # 8000337e <brelse>
  bp = bread(dev, bno);
    80003568:	85a6                	mv	a1,s1
    8000356a:	855e                	mv	a0,s7
    8000356c:	00000097          	auipc	ra,0x0
    80003570:	ce2080e7          	jalr	-798(ra) # 8000324e <bread>
    80003574:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003576:	40000613          	li	a2,1024
    8000357a:	4581                	li	a1,0
    8000357c:	05850513          	addi	a0,a0,88
    80003580:	ffffd097          	auipc	ra,0xffffd
    80003584:	752080e7          	jalr	1874(ra) # 80000cd2 <memset>
  log_write(bp);
    80003588:	854a                	mv	a0,s2
    8000358a:	00001097          	auipc	ra,0x1
    8000358e:	078080e7          	jalr	120(ra) # 80004602 <log_write>
  brelse(bp);
    80003592:	854a                	mv	a0,s2
    80003594:	00000097          	auipc	ra,0x0
    80003598:	dea080e7          	jalr	-534(ra) # 8000337e <brelse>
}
    8000359c:	8526                	mv	a0,s1
    8000359e:	60e6                	ld	ra,88(sp)
    800035a0:	6446                	ld	s0,80(sp)
    800035a2:	64a6                	ld	s1,72(sp)
    800035a4:	6906                	ld	s2,64(sp)
    800035a6:	79e2                	ld	s3,56(sp)
    800035a8:	7a42                	ld	s4,48(sp)
    800035aa:	7aa2                	ld	s5,40(sp)
    800035ac:	7b02                	ld	s6,32(sp)
    800035ae:	6be2                	ld	s7,24(sp)
    800035b0:	6c42                	ld	s8,16(sp)
    800035b2:	6ca2                	ld	s9,8(sp)
    800035b4:	6125                	addi	sp,sp,96
    800035b6:	8082                	ret
    brelse(bp);
    800035b8:	854a                	mv	a0,s2
    800035ba:	00000097          	auipc	ra,0x0
    800035be:	dc4080e7          	jalr	-572(ra) # 8000337e <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800035c2:	015c87bb          	addw	a5,s9,s5
    800035c6:	00078a9b          	sext.w	s5,a5
    800035ca:	004b2703          	lw	a4,4(s6)
    800035ce:	06eaf363          	bgeu	s5,a4,80003634 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    800035d2:	41fad79b          	sraiw	a5,s5,0x1f
    800035d6:	0137d79b          	srliw	a5,a5,0x13
    800035da:	015787bb          	addw	a5,a5,s5
    800035de:	40d7d79b          	sraiw	a5,a5,0xd
    800035e2:	01cb2583          	lw	a1,28(s6)
    800035e6:	9dbd                	addw	a1,a1,a5
    800035e8:	855e                	mv	a0,s7
    800035ea:	00000097          	auipc	ra,0x0
    800035ee:	c64080e7          	jalr	-924(ra) # 8000324e <bread>
    800035f2:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035f4:	004b2503          	lw	a0,4(s6)
    800035f8:	000a849b          	sext.w	s1,s5
    800035fc:	8662                	mv	a2,s8
    800035fe:	faa4fde3          	bgeu	s1,a0,800035b8 <balloc+0xa8>
      m = 1 << (bi % 8);
    80003602:	41f6579b          	sraiw	a5,a2,0x1f
    80003606:	01d7d69b          	srliw	a3,a5,0x1d
    8000360a:	00c6873b          	addw	a4,a3,a2
    8000360e:	00777793          	andi	a5,a4,7
    80003612:	9f95                	subw	a5,a5,a3
    80003614:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003618:	4037571b          	sraiw	a4,a4,0x3
    8000361c:	00e906b3          	add	a3,s2,a4
    80003620:	0586c683          	lbu	a3,88(a3)
    80003624:	00d7f5b3          	and	a1,a5,a3
    80003628:	d195                	beqz	a1,8000354c <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000362a:	2605                	addiw	a2,a2,1
    8000362c:	2485                	addiw	s1,s1,1
    8000362e:	fd4618e3          	bne	a2,s4,800035fe <balloc+0xee>
    80003632:	b759                	j	800035b8 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    80003634:	00005517          	auipc	a0,0x5
    80003638:	fcc50513          	addi	a0,a0,-52 # 80008600 <syscalls+0x110>
    8000363c:	ffffd097          	auipc	ra,0xffffd
    80003640:	f4c080e7          	jalr	-180(ra) # 80000588 <printf>
  return 0;
    80003644:	4481                	li	s1,0
    80003646:	bf99                	j	8000359c <balloc+0x8c>

0000000080003648 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003648:	7179                	addi	sp,sp,-48
    8000364a:	f406                	sd	ra,40(sp)
    8000364c:	f022                	sd	s0,32(sp)
    8000364e:	ec26                	sd	s1,24(sp)
    80003650:	e84a                	sd	s2,16(sp)
    80003652:	e44e                	sd	s3,8(sp)
    80003654:	e052                	sd	s4,0(sp)
    80003656:	1800                	addi	s0,sp,48
    80003658:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000365a:	47ad                	li	a5,11
    8000365c:	02b7e763          	bltu	a5,a1,8000368a <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    80003660:	02059493          	slli	s1,a1,0x20
    80003664:	9081                	srli	s1,s1,0x20
    80003666:	048a                	slli	s1,s1,0x2
    80003668:	94aa                	add	s1,s1,a0
    8000366a:	0504a903          	lw	s2,80(s1)
    8000366e:	06091e63          	bnez	s2,800036ea <bmap+0xa2>
      addr = balloc(ip->dev);
    80003672:	4108                	lw	a0,0(a0)
    80003674:	00000097          	auipc	ra,0x0
    80003678:	e9c080e7          	jalr	-356(ra) # 80003510 <balloc>
    8000367c:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003680:	06090563          	beqz	s2,800036ea <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    80003684:	0524a823          	sw	s2,80(s1)
    80003688:	a08d                	j	800036ea <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    8000368a:	ff45849b          	addiw	s1,a1,-12
    8000368e:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003692:	0ff00793          	li	a5,255
    80003696:	08e7e563          	bltu	a5,a4,80003720 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    8000369a:	08052903          	lw	s2,128(a0)
    8000369e:	00091d63          	bnez	s2,800036b8 <bmap+0x70>
      addr = balloc(ip->dev);
    800036a2:	4108                	lw	a0,0(a0)
    800036a4:	00000097          	auipc	ra,0x0
    800036a8:	e6c080e7          	jalr	-404(ra) # 80003510 <balloc>
    800036ac:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800036b0:	02090d63          	beqz	s2,800036ea <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800036b4:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800036b8:	85ca                	mv	a1,s2
    800036ba:	0009a503          	lw	a0,0(s3)
    800036be:	00000097          	auipc	ra,0x0
    800036c2:	b90080e7          	jalr	-1136(ra) # 8000324e <bread>
    800036c6:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800036c8:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800036cc:	02049593          	slli	a1,s1,0x20
    800036d0:	9181                	srli	a1,a1,0x20
    800036d2:	058a                	slli	a1,a1,0x2
    800036d4:	00b784b3          	add	s1,a5,a1
    800036d8:	0004a903          	lw	s2,0(s1)
    800036dc:	02090063          	beqz	s2,800036fc <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800036e0:	8552                	mv	a0,s4
    800036e2:	00000097          	auipc	ra,0x0
    800036e6:	c9c080e7          	jalr	-868(ra) # 8000337e <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800036ea:	854a                	mv	a0,s2
    800036ec:	70a2                	ld	ra,40(sp)
    800036ee:	7402                	ld	s0,32(sp)
    800036f0:	64e2                	ld	s1,24(sp)
    800036f2:	6942                	ld	s2,16(sp)
    800036f4:	69a2                	ld	s3,8(sp)
    800036f6:	6a02                	ld	s4,0(sp)
    800036f8:	6145                	addi	sp,sp,48
    800036fa:	8082                	ret
      addr = balloc(ip->dev);
    800036fc:	0009a503          	lw	a0,0(s3)
    80003700:	00000097          	auipc	ra,0x0
    80003704:	e10080e7          	jalr	-496(ra) # 80003510 <balloc>
    80003708:	0005091b          	sext.w	s2,a0
      if(addr){
    8000370c:	fc090ae3          	beqz	s2,800036e0 <bmap+0x98>
        a[bn] = addr;
    80003710:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003714:	8552                	mv	a0,s4
    80003716:	00001097          	auipc	ra,0x1
    8000371a:	eec080e7          	jalr	-276(ra) # 80004602 <log_write>
    8000371e:	b7c9                	j	800036e0 <bmap+0x98>
  panic("bmap: out of range");
    80003720:	00005517          	auipc	a0,0x5
    80003724:	ef850513          	addi	a0,a0,-264 # 80008618 <syscalls+0x128>
    80003728:	ffffd097          	auipc	ra,0xffffd
    8000372c:	e16080e7          	jalr	-490(ra) # 8000053e <panic>

0000000080003730 <iget>:
{
    80003730:	7179                	addi	sp,sp,-48
    80003732:	f406                	sd	ra,40(sp)
    80003734:	f022                	sd	s0,32(sp)
    80003736:	ec26                	sd	s1,24(sp)
    80003738:	e84a                	sd	s2,16(sp)
    8000373a:	e44e                	sd	s3,8(sp)
    8000373c:	e052                	sd	s4,0(sp)
    8000373e:	1800                	addi	s0,sp,48
    80003740:	89aa                	mv	s3,a0
    80003742:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003744:	0001c517          	auipc	a0,0x1c
    80003748:	9c450513          	addi	a0,a0,-1596 # 8001f108 <itable>
    8000374c:	ffffd097          	auipc	ra,0xffffd
    80003750:	48a080e7          	jalr	1162(ra) # 80000bd6 <acquire>
  empty = 0;
    80003754:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003756:	0001c497          	auipc	s1,0x1c
    8000375a:	9ca48493          	addi	s1,s1,-1590 # 8001f120 <itable+0x18>
    8000375e:	0001d697          	auipc	a3,0x1d
    80003762:	45268693          	addi	a3,a3,1106 # 80020bb0 <log>
    80003766:	a039                	j	80003774 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003768:	02090b63          	beqz	s2,8000379e <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000376c:	08848493          	addi	s1,s1,136
    80003770:	02d48a63          	beq	s1,a3,800037a4 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003774:	449c                	lw	a5,8(s1)
    80003776:	fef059e3          	blez	a5,80003768 <iget+0x38>
    8000377a:	4098                	lw	a4,0(s1)
    8000377c:	ff3716e3          	bne	a4,s3,80003768 <iget+0x38>
    80003780:	40d8                	lw	a4,4(s1)
    80003782:	ff4713e3          	bne	a4,s4,80003768 <iget+0x38>
      ip->ref++;
    80003786:	2785                	addiw	a5,a5,1
    80003788:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000378a:	0001c517          	auipc	a0,0x1c
    8000378e:	97e50513          	addi	a0,a0,-1666 # 8001f108 <itable>
    80003792:	ffffd097          	auipc	ra,0xffffd
    80003796:	4f8080e7          	jalr	1272(ra) # 80000c8a <release>
      return ip;
    8000379a:	8926                	mv	s2,s1
    8000379c:	a03d                	j	800037ca <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000379e:	f7f9                	bnez	a5,8000376c <iget+0x3c>
    800037a0:	8926                	mv	s2,s1
    800037a2:	b7e9                	j	8000376c <iget+0x3c>
  if(empty == 0)
    800037a4:	02090c63          	beqz	s2,800037dc <iget+0xac>
  ip->dev = dev;
    800037a8:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800037ac:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800037b0:	4785                	li	a5,1
    800037b2:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800037b6:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800037ba:	0001c517          	auipc	a0,0x1c
    800037be:	94e50513          	addi	a0,a0,-1714 # 8001f108 <itable>
    800037c2:	ffffd097          	auipc	ra,0xffffd
    800037c6:	4c8080e7          	jalr	1224(ra) # 80000c8a <release>
}
    800037ca:	854a                	mv	a0,s2
    800037cc:	70a2                	ld	ra,40(sp)
    800037ce:	7402                	ld	s0,32(sp)
    800037d0:	64e2                	ld	s1,24(sp)
    800037d2:	6942                	ld	s2,16(sp)
    800037d4:	69a2                	ld	s3,8(sp)
    800037d6:	6a02                	ld	s4,0(sp)
    800037d8:	6145                	addi	sp,sp,48
    800037da:	8082                	ret
    panic("iget: no inodes");
    800037dc:	00005517          	auipc	a0,0x5
    800037e0:	e5450513          	addi	a0,a0,-428 # 80008630 <syscalls+0x140>
    800037e4:	ffffd097          	auipc	ra,0xffffd
    800037e8:	d5a080e7          	jalr	-678(ra) # 8000053e <panic>

00000000800037ec <fsinit>:
fsinit(int dev) {
    800037ec:	7179                	addi	sp,sp,-48
    800037ee:	f406                	sd	ra,40(sp)
    800037f0:	f022                	sd	s0,32(sp)
    800037f2:	ec26                	sd	s1,24(sp)
    800037f4:	e84a                	sd	s2,16(sp)
    800037f6:	e44e                	sd	s3,8(sp)
    800037f8:	1800                	addi	s0,sp,48
    800037fa:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800037fc:	4585                	li	a1,1
    800037fe:	00000097          	auipc	ra,0x0
    80003802:	a50080e7          	jalr	-1456(ra) # 8000324e <bread>
    80003806:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003808:	0001c997          	auipc	s3,0x1c
    8000380c:	8e098993          	addi	s3,s3,-1824 # 8001f0e8 <sb>
    80003810:	02000613          	li	a2,32
    80003814:	05850593          	addi	a1,a0,88
    80003818:	854e                	mv	a0,s3
    8000381a:	ffffd097          	auipc	ra,0xffffd
    8000381e:	514080e7          	jalr	1300(ra) # 80000d2e <memmove>
  brelse(bp);
    80003822:	8526                	mv	a0,s1
    80003824:	00000097          	auipc	ra,0x0
    80003828:	b5a080e7          	jalr	-1190(ra) # 8000337e <brelse>
  if(sb.magic != FSMAGIC)
    8000382c:	0009a703          	lw	a4,0(s3)
    80003830:	102037b7          	lui	a5,0x10203
    80003834:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003838:	02f71263          	bne	a4,a5,8000385c <fsinit+0x70>
  initlog(dev, &sb);
    8000383c:	0001c597          	auipc	a1,0x1c
    80003840:	8ac58593          	addi	a1,a1,-1876 # 8001f0e8 <sb>
    80003844:	854a                	mv	a0,s2
    80003846:	00001097          	auipc	ra,0x1
    8000384a:	b40080e7          	jalr	-1216(ra) # 80004386 <initlog>
}
    8000384e:	70a2                	ld	ra,40(sp)
    80003850:	7402                	ld	s0,32(sp)
    80003852:	64e2                	ld	s1,24(sp)
    80003854:	6942                	ld	s2,16(sp)
    80003856:	69a2                	ld	s3,8(sp)
    80003858:	6145                	addi	sp,sp,48
    8000385a:	8082                	ret
    panic("invalid file system");
    8000385c:	00005517          	auipc	a0,0x5
    80003860:	de450513          	addi	a0,a0,-540 # 80008640 <syscalls+0x150>
    80003864:	ffffd097          	auipc	ra,0xffffd
    80003868:	cda080e7          	jalr	-806(ra) # 8000053e <panic>

000000008000386c <iinit>:
{
    8000386c:	7179                	addi	sp,sp,-48
    8000386e:	f406                	sd	ra,40(sp)
    80003870:	f022                	sd	s0,32(sp)
    80003872:	ec26                	sd	s1,24(sp)
    80003874:	e84a                	sd	s2,16(sp)
    80003876:	e44e                	sd	s3,8(sp)
    80003878:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000387a:	00005597          	auipc	a1,0x5
    8000387e:	dde58593          	addi	a1,a1,-546 # 80008658 <syscalls+0x168>
    80003882:	0001c517          	auipc	a0,0x1c
    80003886:	88650513          	addi	a0,a0,-1914 # 8001f108 <itable>
    8000388a:	ffffd097          	auipc	ra,0xffffd
    8000388e:	2bc080e7          	jalr	700(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003892:	0001c497          	auipc	s1,0x1c
    80003896:	89e48493          	addi	s1,s1,-1890 # 8001f130 <itable+0x28>
    8000389a:	0001d997          	auipc	s3,0x1d
    8000389e:	32698993          	addi	s3,s3,806 # 80020bc0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800038a2:	00005917          	auipc	s2,0x5
    800038a6:	dbe90913          	addi	s2,s2,-578 # 80008660 <syscalls+0x170>
    800038aa:	85ca                	mv	a1,s2
    800038ac:	8526                	mv	a0,s1
    800038ae:	00001097          	auipc	ra,0x1
    800038b2:	e3a080e7          	jalr	-454(ra) # 800046e8 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800038b6:	08848493          	addi	s1,s1,136
    800038ba:	ff3498e3          	bne	s1,s3,800038aa <iinit+0x3e>
}
    800038be:	70a2                	ld	ra,40(sp)
    800038c0:	7402                	ld	s0,32(sp)
    800038c2:	64e2                	ld	s1,24(sp)
    800038c4:	6942                	ld	s2,16(sp)
    800038c6:	69a2                	ld	s3,8(sp)
    800038c8:	6145                	addi	sp,sp,48
    800038ca:	8082                	ret

00000000800038cc <ialloc>:
{
    800038cc:	715d                	addi	sp,sp,-80
    800038ce:	e486                	sd	ra,72(sp)
    800038d0:	e0a2                	sd	s0,64(sp)
    800038d2:	fc26                	sd	s1,56(sp)
    800038d4:	f84a                	sd	s2,48(sp)
    800038d6:	f44e                	sd	s3,40(sp)
    800038d8:	f052                	sd	s4,32(sp)
    800038da:	ec56                	sd	s5,24(sp)
    800038dc:	e85a                	sd	s6,16(sp)
    800038de:	e45e                	sd	s7,8(sp)
    800038e0:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800038e2:	0001c717          	auipc	a4,0x1c
    800038e6:	81272703          	lw	a4,-2030(a4) # 8001f0f4 <sb+0xc>
    800038ea:	4785                	li	a5,1
    800038ec:	04e7fa63          	bgeu	a5,a4,80003940 <ialloc+0x74>
    800038f0:	8aaa                	mv	s5,a0
    800038f2:	8bae                	mv	s7,a1
    800038f4:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800038f6:	0001ba17          	auipc	s4,0x1b
    800038fa:	7f2a0a13          	addi	s4,s4,2034 # 8001f0e8 <sb>
    800038fe:	00048b1b          	sext.w	s6,s1
    80003902:	0044d793          	srli	a5,s1,0x4
    80003906:	018a2583          	lw	a1,24(s4)
    8000390a:	9dbd                	addw	a1,a1,a5
    8000390c:	8556                	mv	a0,s5
    8000390e:	00000097          	auipc	ra,0x0
    80003912:	940080e7          	jalr	-1728(ra) # 8000324e <bread>
    80003916:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003918:	05850993          	addi	s3,a0,88
    8000391c:	00f4f793          	andi	a5,s1,15
    80003920:	079a                	slli	a5,a5,0x6
    80003922:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003924:	00099783          	lh	a5,0(s3)
    80003928:	c3a1                	beqz	a5,80003968 <ialloc+0x9c>
    brelse(bp);
    8000392a:	00000097          	auipc	ra,0x0
    8000392e:	a54080e7          	jalr	-1452(ra) # 8000337e <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003932:	0485                	addi	s1,s1,1
    80003934:	00ca2703          	lw	a4,12(s4)
    80003938:	0004879b          	sext.w	a5,s1
    8000393c:	fce7e1e3          	bltu	a5,a4,800038fe <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003940:	00005517          	auipc	a0,0x5
    80003944:	d2850513          	addi	a0,a0,-728 # 80008668 <syscalls+0x178>
    80003948:	ffffd097          	auipc	ra,0xffffd
    8000394c:	c40080e7          	jalr	-960(ra) # 80000588 <printf>
  return 0;
    80003950:	4501                	li	a0,0
}
    80003952:	60a6                	ld	ra,72(sp)
    80003954:	6406                	ld	s0,64(sp)
    80003956:	74e2                	ld	s1,56(sp)
    80003958:	7942                	ld	s2,48(sp)
    8000395a:	79a2                	ld	s3,40(sp)
    8000395c:	7a02                	ld	s4,32(sp)
    8000395e:	6ae2                	ld	s5,24(sp)
    80003960:	6b42                	ld	s6,16(sp)
    80003962:	6ba2                	ld	s7,8(sp)
    80003964:	6161                	addi	sp,sp,80
    80003966:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003968:	04000613          	li	a2,64
    8000396c:	4581                	li	a1,0
    8000396e:	854e                	mv	a0,s3
    80003970:	ffffd097          	auipc	ra,0xffffd
    80003974:	362080e7          	jalr	866(ra) # 80000cd2 <memset>
      dip->type = type;
    80003978:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000397c:	854a                	mv	a0,s2
    8000397e:	00001097          	auipc	ra,0x1
    80003982:	c84080e7          	jalr	-892(ra) # 80004602 <log_write>
      brelse(bp);
    80003986:	854a                	mv	a0,s2
    80003988:	00000097          	auipc	ra,0x0
    8000398c:	9f6080e7          	jalr	-1546(ra) # 8000337e <brelse>
      return iget(dev, inum);
    80003990:	85da                	mv	a1,s6
    80003992:	8556                	mv	a0,s5
    80003994:	00000097          	auipc	ra,0x0
    80003998:	d9c080e7          	jalr	-612(ra) # 80003730 <iget>
    8000399c:	bf5d                	j	80003952 <ialloc+0x86>

000000008000399e <iupdate>:
{
    8000399e:	1101                	addi	sp,sp,-32
    800039a0:	ec06                	sd	ra,24(sp)
    800039a2:	e822                	sd	s0,16(sp)
    800039a4:	e426                	sd	s1,8(sp)
    800039a6:	e04a                	sd	s2,0(sp)
    800039a8:	1000                	addi	s0,sp,32
    800039aa:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800039ac:	415c                	lw	a5,4(a0)
    800039ae:	0047d79b          	srliw	a5,a5,0x4
    800039b2:	0001b597          	auipc	a1,0x1b
    800039b6:	74e5a583          	lw	a1,1870(a1) # 8001f100 <sb+0x18>
    800039ba:	9dbd                	addw	a1,a1,a5
    800039bc:	4108                	lw	a0,0(a0)
    800039be:	00000097          	auipc	ra,0x0
    800039c2:	890080e7          	jalr	-1904(ra) # 8000324e <bread>
    800039c6:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800039c8:	05850793          	addi	a5,a0,88
    800039cc:	40c8                	lw	a0,4(s1)
    800039ce:	893d                	andi	a0,a0,15
    800039d0:	051a                	slli	a0,a0,0x6
    800039d2:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800039d4:	04449703          	lh	a4,68(s1)
    800039d8:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800039dc:	04649703          	lh	a4,70(s1)
    800039e0:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800039e4:	04849703          	lh	a4,72(s1)
    800039e8:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800039ec:	04a49703          	lh	a4,74(s1)
    800039f0:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800039f4:	44f8                	lw	a4,76(s1)
    800039f6:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800039f8:	03400613          	li	a2,52
    800039fc:	05048593          	addi	a1,s1,80
    80003a00:	0531                	addi	a0,a0,12
    80003a02:	ffffd097          	auipc	ra,0xffffd
    80003a06:	32c080e7          	jalr	812(ra) # 80000d2e <memmove>
  log_write(bp);
    80003a0a:	854a                	mv	a0,s2
    80003a0c:	00001097          	auipc	ra,0x1
    80003a10:	bf6080e7          	jalr	-1034(ra) # 80004602 <log_write>
  brelse(bp);
    80003a14:	854a                	mv	a0,s2
    80003a16:	00000097          	auipc	ra,0x0
    80003a1a:	968080e7          	jalr	-1688(ra) # 8000337e <brelse>
}
    80003a1e:	60e2                	ld	ra,24(sp)
    80003a20:	6442                	ld	s0,16(sp)
    80003a22:	64a2                	ld	s1,8(sp)
    80003a24:	6902                	ld	s2,0(sp)
    80003a26:	6105                	addi	sp,sp,32
    80003a28:	8082                	ret

0000000080003a2a <idup>:
{
    80003a2a:	1101                	addi	sp,sp,-32
    80003a2c:	ec06                	sd	ra,24(sp)
    80003a2e:	e822                	sd	s0,16(sp)
    80003a30:	e426                	sd	s1,8(sp)
    80003a32:	1000                	addi	s0,sp,32
    80003a34:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a36:	0001b517          	auipc	a0,0x1b
    80003a3a:	6d250513          	addi	a0,a0,1746 # 8001f108 <itable>
    80003a3e:	ffffd097          	auipc	ra,0xffffd
    80003a42:	198080e7          	jalr	408(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003a46:	449c                	lw	a5,8(s1)
    80003a48:	2785                	addiw	a5,a5,1
    80003a4a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a4c:	0001b517          	auipc	a0,0x1b
    80003a50:	6bc50513          	addi	a0,a0,1724 # 8001f108 <itable>
    80003a54:	ffffd097          	auipc	ra,0xffffd
    80003a58:	236080e7          	jalr	566(ra) # 80000c8a <release>
}
    80003a5c:	8526                	mv	a0,s1
    80003a5e:	60e2                	ld	ra,24(sp)
    80003a60:	6442                	ld	s0,16(sp)
    80003a62:	64a2                	ld	s1,8(sp)
    80003a64:	6105                	addi	sp,sp,32
    80003a66:	8082                	ret

0000000080003a68 <ilock>:
{
    80003a68:	1101                	addi	sp,sp,-32
    80003a6a:	ec06                	sd	ra,24(sp)
    80003a6c:	e822                	sd	s0,16(sp)
    80003a6e:	e426                	sd	s1,8(sp)
    80003a70:	e04a                	sd	s2,0(sp)
    80003a72:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003a74:	c115                	beqz	a0,80003a98 <ilock+0x30>
    80003a76:	84aa                	mv	s1,a0
    80003a78:	451c                	lw	a5,8(a0)
    80003a7a:	00f05f63          	blez	a5,80003a98 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003a7e:	0541                	addi	a0,a0,16
    80003a80:	00001097          	auipc	ra,0x1
    80003a84:	ca2080e7          	jalr	-862(ra) # 80004722 <acquiresleep>
  if(ip->valid == 0){
    80003a88:	40bc                	lw	a5,64(s1)
    80003a8a:	cf99                	beqz	a5,80003aa8 <ilock+0x40>
}
    80003a8c:	60e2                	ld	ra,24(sp)
    80003a8e:	6442                	ld	s0,16(sp)
    80003a90:	64a2                	ld	s1,8(sp)
    80003a92:	6902                	ld	s2,0(sp)
    80003a94:	6105                	addi	sp,sp,32
    80003a96:	8082                	ret
    panic("ilock");
    80003a98:	00005517          	auipc	a0,0x5
    80003a9c:	be850513          	addi	a0,a0,-1048 # 80008680 <syscalls+0x190>
    80003aa0:	ffffd097          	auipc	ra,0xffffd
    80003aa4:	a9e080e7          	jalr	-1378(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003aa8:	40dc                	lw	a5,4(s1)
    80003aaa:	0047d79b          	srliw	a5,a5,0x4
    80003aae:	0001b597          	auipc	a1,0x1b
    80003ab2:	6525a583          	lw	a1,1618(a1) # 8001f100 <sb+0x18>
    80003ab6:	9dbd                	addw	a1,a1,a5
    80003ab8:	4088                	lw	a0,0(s1)
    80003aba:	fffff097          	auipc	ra,0xfffff
    80003abe:	794080e7          	jalr	1940(ra) # 8000324e <bread>
    80003ac2:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003ac4:	05850593          	addi	a1,a0,88
    80003ac8:	40dc                	lw	a5,4(s1)
    80003aca:	8bbd                	andi	a5,a5,15
    80003acc:	079a                	slli	a5,a5,0x6
    80003ace:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003ad0:	00059783          	lh	a5,0(a1)
    80003ad4:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003ad8:	00259783          	lh	a5,2(a1)
    80003adc:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003ae0:	00459783          	lh	a5,4(a1)
    80003ae4:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003ae8:	00659783          	lh	a5,6(a1)
    80003aec:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003af0:	459c                	lw	a5,8(a1)
    80003af2:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003af4:	03400613          	li	a2,52
    80003af8:	05b1                	addi	a1,a1,12
    80003afa:	05048513          	addi	a0,s1,80
    80003afe:	ffffd097          	auipc	ra,0xffffd
    80003b02:	230080e7          	jalr	560(ra) # 80000d2e <memmove>
    brelse(bp);
    80003b06:	854a                	mv	a0,s2
    80003b08:	00000097          	auipc	ra,0x0
    80003b0c:	876080e7          	jalr	-1930(ra) # 8000337e <brelse>
    ip->valid = 1;
    80003b10:	4785                	li	a5,1
    80003b12:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003b14:	04449783          	lh	a5,68(s1)
    80003b18:	fbb5                	bnez	a5,80003a8c <ilock+0x24>
      panic("ilock: no type");
    80003b1a:	00005517          	auipc	a0,0x5
    80003b1e:	b6e50513          	addi	a0,a0,-1170 # 80008688 <syscalls+0x198>
    80003b22:	ffffd097          	auipc	ra,0xffffd
    80003b26:	a1c080e7          	jalr	-1508(ra) # 8000053e <panic>

0000000080003b2a <iunlock>:
{
    80003b2a:	1101                	addi	sp,sp,-32
    80003b2c:	ec06                	sd	ra,24(sp)
    80003b2e:	e822                	sd	s0,16(sp)
    80003b30:	e426                	sd	s1,8(sp)
    80003b32:	e04a                	sd	s2,0(sp)
    80003b34:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003b36:	c905                	beqz	a0,80003b66 <iunlock+0x3c>
    80003b38:	84aa                	mv	s1,a0
    80003b3a:	01050913          	addi	s2,a0,16
    80003b3e:	854a                	mv	a0,s2
    80003b40:	00001097          	auipc	ra,0x1
    80003b44:	c7c080e7          	jalr	-900(ra) # 800047bc <holdingsleep>
    80003b48:	cd19                	beqz	a0,80003b66 <iunlock+0x3c>
    80003b4a:	449c                	lw	a5,8(s1)
    80003b4c:	00f05d63          	blez	a5,80003b66 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003b50:	854a                	mv	a0,s2
    80003b52:	00001097          	auipc	ra,0x1
    80003b56:	c26080e7          	jalr	-986(ra) # 80004778 <releasesleep>
}
    80003b5a:	60e2                	ld	ra,24(sp)
    80003b5c:	6442                	ld	s0,16(sp)
    80003b5e:	64a2                	ld	s1,8(sp)
    80003b60:	6902                	ld	s2,0(sp)
    80003b62:	6105                	addi	sp,sp,32
    80003b64:	8082                	ret
    panic("iunlock");
    80003b66:	00005517          	auipc	a0,0x5
    80003b6a:	b3250513          	addi	a0,a0,-1230 # 80008698 <syscalls+0x1a8>
    80003b6e:	ffffd097          	auipc	ra,0xffffd
    80003b72:	9d0080e7          	jalr	-1584(ra) # 8000053e <panic>

0000000080003b76 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003b76:	7179                	addi	sp,sp,-48
    80003b78:	f406                	sd	ra,40(sp)
    80003b7a:	f022                	sd	s0,32(sp)
    80003b7c:	ec26                	sd	s1,24(sp)
    80003b7e:	e84a                	sd	s2,16(sp)
    80003b80:	e44e                	sd	s3,8(sp)
    80003b82:	e052                	sd	s4,0(sp)
    80003b84:	1800                	addi	s0,sp,48
    80003b86:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003b88:	05050493          	addi	s1,a0,80
    80003b8c:	08050913          	addi	s2,a0,128
    80003b90:	a021                	j	80003b98 <itrunc+0x22>
    80003b92:	0491                	addi	s1,s1,4
    80003b94:	01248d63          	beq	s1,s2,80003bae <itrunc+0x38>
    if(ip->addrs[i]){
    80003b98:	408c                	lw	a1,0(s1)
    80003b9a:	dde5                	beqz	a1,80003b92 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003b9c:	0009a503          	lw	a0,0(s3)
    80003ba0:	00000097          	auipc	ra,0x0
    80003ba4:	8f4080e7          	jalr	-1804(ra) # 80003494 <bfree>
      ip->addrs[i] = 0;
    80003ba8:	0004a023          	sw	zero,0(s1)
    80003bac:	b7dd                	j	80003b92 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003bae:	0809a583          	lw	a1,128(s3)
    80003bb2:	e185                	bnez	a1,80003bd2 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003bb4:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003bb8:	854e                	mv	a0,s3
    80003bba:	00000097          	auipc	ra,0x0
    80003bbe:	de4080e7          	jalr	-540(ra) # 8000399e <iupdate>
}
    80003bc2:	70a2                	ld	ra,40(sp)
    80003bc4:	7402                	ld	s0,32(sp)
    80003bc6:	64e2                	ld	s1,24(sp)
    80003bc8:	6942                	ld	s2,16(sp)
    80003bca:	69a2                	ld	s3,8(sp)
    80003bcc:	6a02                	ld	s4,0(sp)
    80003bce:	6145                	addi	sp,sp,48
    80003bd0:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003bd2:	0009a503          	lw	a0,0(s3)
    80003bd6:	fffff097          	auipc	ra,0xfffff
    80003bda:	678080e7          	jalr	1656(ra) # 8000324e <bread>
    80003bde:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003be0:	05850493          	addi	s1,a0,88
    80003be4:	45850913          	addi	s2,a0,1112
    80003be8:	a021                	j	80003bf0 <itrunc+0x7a>
    80003bea:	0491                	addi	s1,s1,4
    80003bec:	01248b63          	beq	s1,s2,80003c02 <itrunc+0x8c>
      if(a[j])
    80003bf0:	408c                	lw	a1,0(s1)
    80003bf2:	dde5                	beqz	a1,80003bea <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003bf4:	0009a503          	lw	a0,0(s3)
    80003bf8:	00000097          	auipc	ra,0x0
    80003bfc:	89c080e7          	jalr	-1892(ra) # 80003494 <bfree>
    80003c00:	b7ed                	j	80003bea <itrunc+0x74>
    brelse(bp);
    80003c02:	8552                	mv	a0,s4
    80003c04:	fffff097          	auipc	ra,0xfffff
    80003c08:	77a080e7          	jalr	1914(ra) # 8000337e <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003c0c:	0809a583          	lw	a1,128(s3)
    80003c10:	0009a503          	lw	a0,0(s3)
    80003c14:	00000097          	auipc	ra,0x0
    80003c18:	880080e7          	jalr	-1920(ra) # 80003494 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003c1c:	0809a023          	sw	zero,128(s3)
    80003c20:	bf51                	j	80003bb4 <itrunc+0x3e>

0000000080003c22 <iput>:
{
    80003c22:	1101                	addi	sp,sp,-32
    80003c24:	ec06                	sd	ra,24(sp)
    80003c26:	e822                	sd	s0,16(sp)
    80003c28:	e426                	sd	s1,8(sp)
    80003c2a:	e04a                	sd	s2,0(sp)
    80003c2c:	1000                	addi	s0,sp,32
    80003c2e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003c30:	0001b517          	auipc	a0,0x1b
    80003c34:	4d850513          	addi	a0,a0,1240 # 8001f108 <itable>
    80003c38:	ffffd097          	auipc	ra,0xffffd
    80003c3c:	f9e080e7          	jalr	-98(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003c40:	4498                	lw	a4,8(s1)
    80003c42:	4785                	li	a5,1
    80003c44:	02f70363          	beq	a4,a5,80003c6a <iput+0x48>
  ip->ref--;
    80003c48:	449c                	lw	a5,8(s1)
    80003c4a:	37fd                	addiw	a5,a5,-1
    80003c4c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003c4e:	0001b517          	auipc	a0,0x1b
    80003c52:	4ba50513          	addi	a0,a0,1210 # 8001f108 <itable>
    80003c56:	ffffd097          	auipc	ra,0xffffd
    80003c5a:	034080e7          	jalr	52(ra) # 80000c8a <release>
}
    80003c5e:	60e2                	ld	ra,24(sp)
    80003c60:	6442                	ld	s0,16(sp)
    80003c62:	64a2                	ld	s1,8(sp)
    80003c64:	6902                	ld	s2,0(sp)
    80003c66:	6105                	addi	sp,sp,32
    80003c68:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003c6a:	40bc                	lw	a5,64(s1)
    80003c6c:	dff1                	beqz	a5,80003c48 <iput+0x26>
    80003c6e:	04a49783          	lh	a5,74(s1)
    80003c72:	fbf9                	bnez	a5,80003c48 <iput+0x26>
    acquiresleep(&ip->lock);
    80003c74:	01048913          	addi	s2,s1,16
    80003c78:	854a                	mv	a0,s2
    80003c7a:	00001097          	auipc	ra,0x1
    80003c7e:	aa8080e7          	jalr	-1368(ra) # 80004722 <acquiresleep>
    release(&itable.lock);
    80003c82:	0001b517          	auipc	a0,0x1b
    80003c86:	48650513          	addi	a0,a0,1158 # 8001f108 <itable>
    80003c8a:	ffffd097          	auipc	ra,0xffffd
    80003c8e:	000080e7          	jalr	ra # 80000c8a <release>
    itrunc(ip);
    80003c92:	8526                	mv	a0,s1
    80003c94:	00000097          	auipc	ra,0x0
    80003c98:	ee2080e7          	jalr	-286(ra) # 80003b76 <itrunc>
    ip->type = 0;
    80003c9c:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003ca0:	8526                	mv	a0,s1
    80003ca2:	00000097          	auipc	ra,0x0
    80003ca6:	cfc080e7          	jalr	-772(ra) # 8000399e <iupdate>
    ip->valid = 0;
    80003caa:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003cae:	854a                	mv	a0,s2
    80003cb0:	00001097          	auipc	ra,0x1
    80003cb4:	ac8080e7          	jalr	-1336(ra) # 80004778 <releasesleep>
    acquire(&itable.lock);
    80003cb8:	0001b517          	auipc	a0,0x1b
    80003cbc:	45050513          	addi	a0,a0,1104 # 8001f108 <itable>
    80003cc0:	ffffd097          	auipc	ra,0xffffd
    80003cc4:	f16080e7          	jalr	-234(ra) # 80000bd6 <acquire>
    80003cc8:	b741                	j	80003c48 <iput+0x26>

0000000080003cca <iunlockput>:
{
    80003cca:	1101                	addi	sp,sp,-32
    80003ccc:	ec06                	sd	ra,24(sp)
    80003cce:	e822                	sd	s0,16(sp)
    80003cd0:	e426                	sd	s1,8(sp)
    80003cd2:	1000                	addi	s0,sp,32
    80003cd4:	84aa                	mv	s1,a0
  iunlock(ip);
    80003cd6:	00000097          	auipc	ra,0x0
    80003cda:	e54080e7          	jalr	-428(ra) # 80003b2a <iunlock>
  iput(ip);
    80003cde:	8526                	mv	a0,s1
    80003ce0:	00000097          	auipc	ra,0x0
    80003ce4:	f42080e7          	jalr	-190(ra) # 80003c22 <iput>
}
    80003ce8:	60e2                	ld	ra,24(sp)
    80003cea:	6442                	ld	s0,16(sp)
    80003cec:	64a2                	ld	s1,8(sp)
    80003cee:	6105                	addi	sp,sp,32
    80003cf0:	8082                	ret

0000000080003cf2 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003cf2:	1141                	addi	sp,sp,-16
    80003cf4:	e422                	sd	s0,8(sp)
    80003cf6:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003cf8:	411c                	lw	a5,0(a0)
    80003cfa:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003cfc:	415c                	lw	a5,4(a0)
    80003cfe:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003d00:	04451783          	lh	a5,68(a0)
    80003d04:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003d08:	04a51783          	lh	a5,74(a0)
    80003d0c:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003d10:	04c56783          	lwu	a5,76(a0)
    80003d14:	e99c                	sd	a5,16(a1)
}
    80003d16:	6422                	ld	s0,8(sp)
    80003d18:	0141                	addi	sp,sp,16
    80003d1a:	8082                	ret

0000000080003d1c <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d1c:	457c                	lw	a5,76(a0)
    80003d1e:	0ed7e963          	bltu	a5,a3,80003e10 <readi+0xf4>
{
    80003d22:	7159                	addi	sp,sp,-112
    80003d24:	f486                	sd	ra,104(sp)
    80003d26:	f0a2                	sd	s0,96(sp)
    80003d28:	eca6                	sd	s1,88(sp)
    80003d2a:	e8ca                	sd	s2,80(sp)
    80003d2c:	e4ce                	sd	s3,72(sp)
    80003d2e:	e0d2                	sd	s4,64(sp)
    80003d30:	fc56                	sd	s5,56(sp)
    80003d32:	f85a                	sd	s6,48(sp)
    80003d34:	f45e                	sd	s7,40(sp)
    80003d36:	f062                	sd	s8,32(sp)
    80003d38:	ec66                	sd	s9,24(sp)
    80003d3a:	e86a                	sd	s10,16(sp)
    80003d3c:	e46e                	sd	s11,8(sp)
    80003d3e:	1880                	addi	s0,sp,112
    80003d40:	8b2a                	mv	s6,a0
    80003d42:	8bae                	mv	s7,a1
    80003d44:	8a32                	mv	s4,a2
    80003d46:	84b6                	mv	s1,a3
    80003d48:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003d4a:	9f35                	addw	a4,a4,a3
    return 0;
    80003d4c:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003d4e:	0ad76063          	bltu	a4,a3,80003dee <readi+0xd2>
  if(off + n > ip->size)
    80003d52:	00e7f463          	bgeu	a5,a4,80003d5a <readi+0x3e>
    n = ip->size - off;
    80003d56:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d5a:	0a0a8963          	beqz	s5,80003e0c <readi+0xf0>
    80003d5e:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d60:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003d64:	5c7d                	li	s8,-1
    80003d66:	a82d                	j	80003da0 <readi+0x84>
    80003d68:	020d1d93          	slli	s11,s10,0x20
    80003d6c:	020ddd93          	srli	s11,s11,0x20
    80003d70:	05890793          	addi	a5,s2,88
    80003d74:	86ee                	mv	a3,s11
    80003d76:	963e                	add	a2,a2,a5
    80003d78:	85d2                	mv	a1,s4
    80003d7a:	855e                	mv	a0,s7
    80003d7c:	fffff097          	auipc	ra,0xfffff
    80003d80:	9d4080e7          	jalr	-1580(ra) # 80002750 <either_copyout>
    80003d84:	05850d63          	beq	a0,s8,80003dde <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003d88:	854a                	mv	a0,s2
    80003d8a:	fffff097          	auipc	ra,0xfffff
    80003d8e:	5f4080e7          	jalr	1524(ra) # 8000337e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d92:	013d09bb          	addw	s3,s10,s3
    80003d96:	009d04bb          	addw	s1,s10,s1
    80003d9a:	9a6e                	add	s4,s4,s11
    80003d9c:	0559f763          	bgeu	s3,s5,80003dea <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003da0:	00a4d59b          	srliw	a1,s1,0xa
    80003da4:	855a                	mv	a0,s6
    80003da6:	00000097          	auipc	ra,0x0
    80003daa:	8a2080e7          	jalr	-1886(ra) # 80003648 <bmap>
    80003dae:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003db2:	cd85                	beqz	a1,80003dea <readi+0xce>
    bp = bread(ip->dev, addr);
    80003db4:	000b2503          	lw	a0,0(s6)
    80003db8:	fffff097          	auipc	ra,0xfffff
    80003dbc:	496080e7          	jalr	1174(ra) # 8000324e <bread>
    80003dc0:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003dc2:	3ff4f613          	andi	a2,s1,1023
    80003dc6:	40cc87bb          	subw	a5,s9,a2
    80003dca:	413a873b          	subw	a4,s5,s3
    80003dce:	8d3e                	mv	s10,a5
    80003dd0:	2781                	sext.w	a5,a5
    80003dd2:	0007069b          	sext.w	a3,a4
    80003dd6:	f8f6f9e3          	bgeu	a3,a5,80003d68 <readi+0x4c>
    80003dda:	8d3a                	mv	s10,a4
    80003ddc:	b771                	j	80003d68 <readi+0x4c>
      brelse(bp);
    80003dde:	854a                	mv	a0,s2
    80003de0:	fffff097          	auipc	ra,0xfffff
    80003de4:	59e080e7          	jalr	1438(ra) # 8000337e <brelse>
      tot = -1;
    80003de8:	59fd                	li	s3,-1
  }
  return tot;
    80003dea:	0009851b          	sext.w	a0,s3
}
    80003dee:	70a6                	ld	ra,104(sp)
    80003df0:	7406                	ld	s0,96(sp)
    80003df2:	64e6                	ld	s1,88(sp)
    80003df4:	6946                	ld	s2,80(sp)
    80003df6:	69a6                	ld	s3,72(sp)
    80003df8:	6a06                	ld	s4,64(sp)
    80003dfa:	7ae2                	ld	s5,56(sp)
    80003dfc:	7b42                	ld	s6,48(sp)
    80003dfe:	7ba2                	ld	s7,40(sp)
    80003e00:	7c02                	ld	s8,32(sp)
    80003e02:	6ce2                	ld	s9,24(sp)
    80003e04:	6d42                	ld	s10,16(sp)
    80003e06:	6da2                	ld	s11,8(sp)
    80003e08:	6165                	addi	sp,sp,112
    80003e0a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e0c:	89d6                	mv	s3,s5
    80003e0e:	bff1                	j	80003dea <readi+0xce>
    return 0;
    80003e10:	4501                	li	a0,0
}
    80003e12:	8082                	ret

0000000080003e14 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003e14:	457c                	lw	a5,76(a0)
    80003e16:	10d7e863          	bltu	a5,a3,80003f26 <writei+0x112>
{
    80003e1a:	7159                	addi	sp,sp,-112
    80003e1c:	f486                	sd	ra,104(sp)
    80003e1e:	f0a2                	sd	s0,96(sp)
    80003e20:	eca6                	sd	s1,88(sp)
    80003e22:	e8ca                	sd	s2,80(sp)
    80003e24:	e4ce                	sd	s3,72(sp)
    80003e26:	e0d2                	sd	s4,64(sp)
    80003e28:	fc56                	sd	s5,56(sp)
    80003e2a:	f85a                	sd	s6,48(sp)
    80003e2c:	f45e                	sd	s7,40(sp)
    80003e2e:	f062                	sd	s8,32(sp)
    80003e30:	ec66                	sd	s9,24(sp)
    80003e32:	e86a                	sd	s10,16(sp)
    80003e34:	e46e                	sd	s11,8(sp)
    80003e36:	1880                	addi	s0,sp,112
    80003e38:	8aaa                	mv	s5,a0
    80003e3a:	8bae                	mv	s7,a1
    80003e3c:	8a32                	mv	s4,a2
    80003e3e:	8936                	mv	s2,a3
    80003e40:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003e42:	00e687bb          	addw	a5,a3,a4
    80003e46:	0ed7e263          	bltu	a5,a3,80003f2a <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003e4a:	00043737          	lui	a4,0x43
    80003e4e:	0ef76063          	bltu	a4,a5,80003f2e <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e52:	0c0b0863          	beqz	s6,80003f22 <writei+0x10e>
    80003e56:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e58:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003e5c:	5c7d                	li	s8,-1
    80003e5e:	a091                	j	80003ea2 <writei+0x8e>
    80003e60:	020d1d93          	slli	s11,s10,0x20
    80003e64:	020ddd93          	srli	s11,s11,0x20
    80003e68:	05848793          	addi	a5,s1,88
    80003e6c:	86ee                	mv	a3,s11
    80003e6e:	8652                	mv	a2,s4
    80003e70:	85de                	mv	a1,s7
    80003e72:	953e                	add	a0,a0,a5
    80003e74:	fffff097          	auipc	ra,0xfffff
    80003e78:	932080e7          	jalr	-1742(ra) # 800027a6 <either_copyin>
    80003e7c:	07850263          	beq	a0,s8,80003ee0 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003e80:	8526                	mv	a0,s1
    80003e82:	00000097          	auipc	ra,0x0
    80003e86:	780080e7          	jalr	1920(ra) # 80004602 <log_write>
    brelse(bp);
    80003e8a:	8526                	mv	a0,s1
    80003e8c:	fffff097          	auipc	ra,0xfffff
    80003e90:	4f2080e7          	jalr	1266(ra) # 8000337e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e94:	013d09bb          	addw	s3,s10,s3
    80003e98:	012d093b          	addw	s2,s10,s2
    80003e9c:	9a6e                	add	s4,s4,s11
    80003e9e:	0569f663          	bgeu	s3,s6,80003eea <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003ea2:	00a9559b          	srliw	a1,s2,0xa
    80003ea6:	8556                	mv	a0,s5
    80003ea8:	fffff097          	auipc	ra,0xfffff
    80003eac:	7a0080e7          	jalr	1952(ra) # 80003648 <bmap>
    80003eb0:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003eb4:	c99d                	beqz	a1,80003eea <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003eb6:	000aa503          	lw	a0,0(s5)
    80003eba:	fffff097          	auipc	ra,0xfffff
    80003ebe:	394080e7          	jalr	916(ra) # 8000324e <bread>
    80003ec2:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ec4:	3ff97513          	andi	a0,s2,1023
    80003ec8:	40ac87bb          	subw	a5,s9,a0
    80003ecc:	413b073b          	subw	a4,s6,s3
    80003ed0:	8d3e                	mv	s10,a5
    80003ed2:	2781                	sext.w	a5,a5
    80003ed4:	0007069b          	sext.w	a3,a4
    80003ed8:	f8f6f4e3          	bgeu	a3,a5,80003e60 <writei+0x4c>
    80003edc:	8d3a                	mv	s10,a4
    80003ede:	b749                	j	80003e60 <writei+0x4c>
      brelse(bp);
    80003ee0:	8526                	mv	a0,s1
    80003ee2:	fffff097          	auipc	ra,0xfffff
    80003ee6:	49c080e7          	jalr	1180(ra) # 8000337e <brelse>
  }

  if(off > ip->size)
    80003eea:	04caa783          	lw	a5,76(s5)
    80003eee:	0127f463          	bgeu	a5,s2,80003ef6 <writei+0xe2>
    ip->size = off;
    80003ef2:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003ef6:	8556                	mv	a0,s5
    80003ef8:	00000097          	auipc	ra,0x0
    80003efc:	aa6080e7          	jalr	-1370(ra) # 8000399e <iupdate>

  return tot;
    80003f00:	0009851b          	sext.w	a0,s3
}
    80003f04:	70a6                	ld	ra,104(sp)
    80003f06:	7406                	ld	s0,96(sp)
    80003f08:	64e6                	ld	s1,88(sp)
    80003f0a:	6946                	ld	s2,80(sp)
    80003f0c:	69a6                	ld	s3,72(sp)
    80003f0e:	6a06                	ld	s4,64(sp)
    80003f10:	7ae2                	ld	s5,56(sp)
    80003f12:	7b42                	ld	s6,48(sp)
    80003f14:	7ba2                	ld	s7,40(sp)
    80003f16:	7c02                	ld	s8,32(sp)
    80003f18:	6ce2                	ld	s9,24(sp)
    80003f1a:	6d42                	ld	s10,16(sp)
    80003f1c:	6da2                	ld	s11,8(sp)
    80003f1e:	6165                	addi	sp,sp,112
    80003f20:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f22:	89da                	mv	s3,s6
    80003f24:	bfc9                	j	80003ef6 <writei+0xe2>
    return -1;
    80003f26:	557d                	li	a0,-1
}
    80003f28:	8082                	ret
    return -1;
    80003f2a:	557d                	li	a0,-1
    80003f2c:	bfe1                	j	80003f04 <writei+0xf0>
    return -1;
    80003f2e:	557d                	li	a0,-1
    80003f30:	bfd1                	j	80003f04 <writei+0xf0>

0000000080003f32 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003f32:	1141                	addi	sp,sp,-16
    80003f34:	e406                	sd	ra,8(sp)
    80003f36:	e022                	sd	s0,0(sp)
    80003f38:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003f3a:	4639                	li	a2,14
    80003f3c:	ffffd097          	auipc	ra,0xffffd
    80003f40:	e66080e7          	jalr	-410(ra) # 80000da2 <strncmp>
}
    80003f44:	60a2                	ld	ra,8(sp)
    80003f46:	6402                	ld	s0,0(sp)
    80003f48:	0141                	addi	sp,sp,16
    80003f4a:	8082                	ret

0000000080003f4c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003f4c:	7139                	addi	sp,sp,-64
    80003f4e:	fc06                	sd	ra,56(sp)
    80003f50:	f822                	sd	s0,48(sp)
    80003f52:	f426                	sd	s1,40(sp)
    80003f54:	f04a                	sd	s2,32(sp)
    80003f56:	ec4e                	sd	s3,24(sp)
    80003f58:	e852                	sd	s4,16(sp)
    80003f5a:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003f5c:	04451703          	lh	a4,68(a0)
    80003f60:	4785                	li	a5,1
    80003f62:	00f71a63          	bne	a4,a5,80003f76 <dirlookup+0x2a>
    80003f66:	892a                	mv	s2,a0
    80003f68:	89ae                	mv	s3,a1
    80003f6a:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f6c:	457c                	lw	a5,76(a0)
    80003f6e:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003f70:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f72:	e79d                	bnez	a5,80003fa0 <dirlookup+0x54>
    80003f74:	a8a5                	j	80003fec <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003f76:	00004517          	auipc	a0,0x4
    80003f7a:	72a50513          	addi	a0,a0,1834 # 800086a0 <syscalls+0x1b0>
    80003f7e:	ffffc097          	auipc	ra,0xffffc
    80003f82:	5c0080e7          	jalr	1472(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003f86:	00004517          	auipc	a0,0x4
    80003f8a:	73250513          	addi	a0,a0,1842 # 800086b8 <syscalls+0x1c8>
    80003f8e:	ffffc097          	auipc	ra,0xffffc
    80003f92:	5b0080e7          	jalr	1456(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f96:	24c1                	addiw	s1,s1,16
    80003f98:	04c92783          	lw	a5,76(s2)
    80003f9c:	04f4f763          	bgeu	s1,a5,80003fea <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fa0:	4741                	li	a4,16
    80003fa2:	86a6                	mv	a3,s1
    80003fa4:	fc040613          	addi	a2,s0,-64
    80003fa8:	4581                	li	a1,0
    80003faa:	854a                	mv	a0,s2
    80003fac:	00000097          	auipc	ra,0x0
    80003fb0:	d70080e7          	jalr	-656(ra) # 80003d1c <readi>
    80003fb4:	47c1                	li	a5,16
    80003fb6:	fcf518e3          	bne	a0,a5,80003f86 <dirlookup+0x3a>
    if(de.inum == 0)
    80003fba:	fc045783          	lhu	a5,-64(s0)
    80003fbe:	dfe1                	beqz	a5,80003f96 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003fc0:	fc240593          	addi	a1,s0,-62
    80003fc4:	854e                	mv	a0,s3
    80003fc6:	00000097          	auipc	ra,0x0
    80003fca:	f6c080e7          	jalr	-148(ra) # 80003f32 <namecmp>
    80003fce:	f561                	bnez	a0,80003f96 <dirlookup+0x4a>
      if(poff)
    80003fd0:	000a0463          	beqz	s4,80003fd8 <dirlookup+0x8c>
        *poff = off;
    80003fd4:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003fd8:	fc045583          	lhu	a1,-64(s0)
    80003fdc:	00092503          	lw	a0,0(s2)
    80003fe0:	fffff097          	auipc	ra,0xfffff
    80003fe4:	750080e7          	jalr	1872(ra) # 80003730 <iget>
    80003fe8:	a011                	j	80003fec <dirlookup+0xa0>
  return 0;
    80003fea:	4501                	li	a0,0
}
    80003fec:	70e2                	ld	ra,56(sp)
    80003fee:	7442                	ld	s0,48(sp)
    80003ff0:	74a2                	ld	s1,40(sp)
    80003ff2:	7902                	ld	s2,32(sp)
    80003ff4:	69e2                	ld	s3,24(sp)
    80003ff6:	6a42                	ld	s4,16(sp)
    80003ff8:	6121                	addi	sp,sp,64
    80003ffa:	8082                	ret

0000000080003ffc <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003ffc:	711d                	addi	sp,sp,-96
    80003ffe:	ec86                	sd	ra,88(sp)
    80004000:	e8a2                	sd	s0,80(sp)
    80004002:	e4a6                	sd	s1,72(sp)
    80004004:	e0ca                	sd	s2,64(sp)
    80004006:	fc4e                	sd	s3,56(sp)
    80004008:	f852                	sd	s4,48(sp)
    8000400a:	f456                	sd	s5,40(sp)
    8000400c:	f05a                	sd	s6,32(sp)
    8000400e:	ec5e                	sd	s7,24(sp)
    80004010:	e862                	sd	s8,16(sp)
    80004012:	e466                	sd	s9,8(sp)
    80004014:	1080                	addi	s0,sp,96
    80004016:	84aa                	mv	s1,a0
    80004018:	8aae                	mv	s5,a1
    8000401a:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000401c:	00054703          	lbu	a4,0(a0)
    80004020:	02f00793          	li	a5,47
    80004024:	02f70363          	beq	a4,a5,8000404a <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004028:	ffffe097          	auipc	ra,0xffffe
    8000402c:	c78080e7          	jalr	-904(ra) # 80001ca0 <myproc>
    80004030:	15053503          	ld	a0,336(a0)
    80004034:	00000097          	auipc	ra,0x0
    80004038:	9f6080e7          	jalr	-1546(ra) # 80003a2a <idup>
    8000403c:	89aa                	mv	s3,a0
  while(*path == '/')
    8000403e:	02f00913          	li	s2,47
  len = path - s;
    80004042:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80004044:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004046:	4b85                	li	s7,1
    80004048:	a865                	j	80004100 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    8000404a:	4585                	li	a1,1
    8000404c:	4505                	li	a0,1
    8000404e:	fffff097          	auipc	ra,0xfffff
    80004052:	6e2080e7          	jalr	1762(ra) # 80003730 <iget>
    80004056:	89aa                	mv	s3,a0
    80004058:	b7dd                	j	8000403e <namex+0x42>
      iunlockput(ip);
    8000405a:	854e                	mv	a0,s3
    8000405c:	00000097          	auipc	ra,0x0
    80004060:	c6e080e7          	jalr	-914(ra) # 80003cca <iunlockput>
      return 0;
    80004064:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004066:	854e                	mv	a0,s3
    80004068:	60e6                	ld	ra,88(sp)
    8000406a:	6446                	ld	s0,80(sp)
    8000406c:	64a6                	ld	s1,72(sp)
    8000406e:	6906                	ld	s2,64(sp)
    80004070:	79e2                	ld	s3,56(sp)
    80004072:	7a42                	ld	s4,48(sp)
    80004074:	7aa2                	ld	s5,40(sp)
    80004076:	7b02                	ld	s6,32(sp)
    80004078:	6be2                	ld	s7,24(sp)
    8000407a:	6c42                	ld	s8,16(sp)
    8000407c:	6ca2                	ld	s9,8(sp)
    8000407e:	6125                	addi	sp,sp,96
    80004080:	8082                	ret
      iunlock(ip);
    80004082:	854e                	mv	a0,s3
    80004084:	00000097          	auipc	ra,0x0
    80004088:	aa6080e7          	jalr	-1370(ra) # 80003b2a <iunlock>
      return ip;
    8000408c:	bfe9                	j	80004066 <namex+0x6a>
      iunlockput(ip);
    8000408e:	854e                	mv	a0,s3
    80004090:	00000097          	auipc	ra,0x0
    80004094:	c3a080e7          	jalr	-966(ra) # 80003cca <iunlockput>
      return 0;
    80004098:	89e6                	mv	s3,s9
    8000409a:	b7f1                	j	80004066 <namex+0x6a>
  len = path - s;
    8000409c:	40b48633          	sub	a2,s1,a1
    800040a0:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    800040a4:	099c5463          	bge	s8,s9,8000412c <namex+0x130>
    memmove(name, s, DIRSIZ);
    800040a8:	4639                	li	a2,14
    800040aa:	8552                	mv	a0,s4
    800040ac:	ffffd097          	auipc	ra,0xffffd
    800040b0:	c82080e7          	jalr	-894(ra) # 80000d2e <memmove>
  while(*path == '/')
    800040b4:	0004c783          	lbu	a5,0(s1)
    800040b8:	01279763          	bne	a5,s2,800040c6 <namex+0xca>
    path++;
    800040bc:	0485                	addi	s1,s1,1
  while(*path == '/')
    800040be:	0004c783          	lbu	a5,0(s1)
    800040c2:	ff278de3          	beq	a5,s2,800040bc <namex+0xc0>
    ilock(ip);
    800040c6:	854e                	mv	a0,s3
    800040c8:	00000097          	auipc	ra,0x0
    800040cc:	9a0080e7          	jalr	-1632(ra) # 80003a68 <ilock>
    if(ip->type != T_DIR){
    800040d0:	04499783          	lh	a5,68(s3)
    800040d4:	f97793e3          	bne	a5,s7,8000405a <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800040d8:	000a8563          	beqz	s5,800040e2 <namex+0xe6>
    800040dc:	0004c783          	lbu	a5,0(s1)
    800040e0:	d3cd                	beqz	a5,80004082 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800040e2:	865a                	mv	a2,s6
    800040e4:	85d2                	mv	a1,s4
    800040e6:	854e                	mv	a0,s3
    800040e8:	00000097          	auipc	ra,0x0
    800040ec:	e64080e7          	jalr	-412(ra) # 80003f4c <dirlookup>
    800040f0:	8caa                	mv	s9,a0
    800040f2:	dd51                	beqz	a0,8000408e <namex+0x92>
    iunlockput(ip);
    800040f4:	854e                	mv	a0,s3
    800040f6:	00000097          	auipc	ra,0x0
    800040fa:	bd4080e7          	jalr	-1068(ra) # 80003cca <iunlockput>
    ip = next;
    800040fe:	89e6                	mv	s3,s9
  while(*path == '/')
    80004100:	0004c783          	lbu	a5,0(s1)
    80004104:	05279763          	bne	a5,s2,80004152 <namex+0x156>
    path++;
    80004108:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000410a:	0004c783          	lbu	a5,0(s1)
    8000410e:	ff278de3          	beq	a5,s2,80004108 <namex+0x10c>
  if(*path == 0)
    80004112:	c79d                	beqz	a5,80004140 <namex+0x144>
    path++;
    80004114:	85a6                	mv	a1,s1
  len = path - s;
    80004116:	8cda                	mv	s9,s6
    80004118:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    8000411a:	01278963          	beq	a5,s2,8000412c <namex+0x130>
    8000411e:	dfbd                	beqz	a5,8000409c <namex+0xa0>
    path++;
    80004120:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004122:	0004c783          	lbu	a5,0(s1)
    80004126:	ff279ce3          	bne	a5,s2,8000411e <namex+0x122>
    8000412a:	bf8d                	j	8000409c <namex+0xa0>
    memmove(name, s, len);
    8000412c:	2601                	sext.w	a2,a2
    8000412e:	8552                	mv	a0,s4
    80004130:	ffffd097          	auipc	ra,0xffffd
    80004134:	bfe080e7          	jalr	-1026(ra) # 80000d2e <memmove>
    name[len] = 0;
    80004138:	9cd2                	add	s9,s9,s4
    8000413a:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    8000413e:	bf9d                	j	800040b4 <namex+0xb8>
  if(nameiparent){
    80004140:	f20a83e3          	beqz	s5,80004066 <namex+0x6a>
    iput(ip);
    80004144:	854e                	mv	a0,s3
    80004146:	00000097          	auipc	ra,0x0
    8000414a:	adc080e7          	jalr	-1316(ra) # 80003c22 <iput>
    return 0;
    8000414e:	4981                	li	s3,0
    80004150:	bf19                	j	80004066 <namex+0x6a>
  if(*path == 0)
    80004152:	d7fd                	beqz	a5,80004140 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004154:	0004c783          	lbu	a5,0(s1)
    80004158:	85a6                	mv	a1,s1
    8000415a:	b7d1                	j	8000411e <namex+0x122>

000000008000415c <dirlink>:
{
    8000415c:	7139                	addi	sp,sp,-64
    8000415e:	fc06                	sd	ra,56(sp)
    80004160:	f822                	sd	s0,48(sp)
    80004162:	f426                	sd	s1,40(sp)
    80004164:	f04a                	sd	s2,32(sp)
    80004166:	ec4e                	sd	s3,24(sp)
    80004168:	e852                	sd	s4,16(sp)
    8000416a:	0080                	addi	s0,sp,64
    8000416c:	892a                	mv	s2,a0
    8000416e:	8a2e                	mv	s4,a1
    80004170:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004172:	4601                	li	a2,0
    80004174:	00000097          	auipc	ra,0x0
    80004178:	dd8080e7          	jalr	-552(ra) # 80003f4c <dirlookup>
    8000417c:	e93d                	bnez	a0,800041f2 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000417e:	04c92483          	lw	s1,76(s2)
    80004182:	c49d                	beqz	s1,800041b0 <dirlink+0x54>
    80004184:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004186:	4741                	li	a4,16
    80004188:	86a6                	mv	a3,s1
    8000418a:	fc040613          	addi	a2,s0,-64
    8000418e:	4581                	li	a1,0
    80004190:	854a                	mv	a0,s2
    80004192:	00000097          	auipc	ra,0x0
    80004196:	b8a080e7          	jalr	-1142(ra) # 80003d1c <readi>
    8000419a:	47c1                	li	a5,16
    8000419c:	06f51163          	bne	a0,a5,800041fe <dirlink+0xa2>
    if(de.inum == 0)
    800041a0:	fc045783          	lhu	a5,-64(s0)
    800041a4:	c791                	beqz	a5,800041b0 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800041a6:	24c1                	addiw	s1,s1,16
    800041a8:	04c92783          	lw	a5,76(s2)
    800041ac:	fcf4ede3          	bltu	s1,a5,80004186 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800041b0:	4639                	li	a2,14
    800041b2:	85d2                	mv	a1,s4
    800041b4:	fc240513          	addi	a0,s0,-62
    800041b8:	ffffd097          	auipc	ra,0xffffd
    800041bc:	c26080e7          	jalr	-986(ra) # 80000dde <strncpy>
  de.inum = inum;
    800041c0:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800041c4:	4741                	li	a4,16
    800041c6:	86a6                	mv	a3,s1
    800041c8:	fc040613          	addi	a2,s0,-64
    800041cc:	4581                	li	a1,0
    800041ce:	854a                	mv	a0,s2
    800041d0:	00000097          	auipc	ra,0x0
    800041d4:	c44080e7          	jalr	-956(ra) # 80003e14 <writei>
    800041d8:	1541                	addi	a0,a0,-16
    800041da:	00a03533          	snez	a0,a0
    800041de:	40a00533          	neg	a0,a0
}
    800041e2:	70e2                	ld	ra,56(sp)
    800041e4:	7442                	ld	s0,48(sp)
    800041e6:	74a2                	ld	s1,40(sp)
    800041e8:	7902                	ld	s2,32(sp)
    800041ea:	69e2                	ld	s3,24(sp)
    800041ec:	6a42                	ld	s4,16(sp)
    800041ee:	6121                	addi	sp,sp,64
    800041f0:	8082                	ret
    iput(ip);
    800041f2:	00000097          	auipc	ra,0x0
    800041f6:	a30080e7          	jalr	-1488(ra) # 80003c22 <iput>
    return -1;
    800041fa:	557d                	li	a0,-1
    800041fc:	b7dd                	j	800041e2 <dirlink+0x86>
      panic("dirlink read");
    800041fe:	00004517          	auipc	a0,0x4
    80004202:	4ca50513          	addi	a0,a0,1226 # 800086c8 <syscalls+0x1d8>
    80004206:	ffffc097          	auipc	ra,0xffffc
    8000420a:	338080e7          	jalr	824(ra) # 8000053e <panic>

000000008000420e <namei>:

struct inode*
namei(char *path)
{
    8000420e:	1101                	addi	sp,sp,-32
    80004210:	ec06                	sd	ra,24(sp)
    80004212:	e822                	sd	s0,16(sp)
    80004214:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004216:	fe040613          	addi	a2,s0,-32
    8000421a:	4581                	li	a1,0
    8000421c:	00000097          	auipc	ra,0x0
    80004220:	de0080e7          	jalr	-544(ra) # 80003ffc <namex>
}
    80004224:	60e2                	ld	ra,24(sp)
    80004226:	6442                	ld	s0,16(sp)
    80004228:	6105                	addi	sp,sp,32
    8000422a:	8082                	ret

000000008000422c <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000422c:	1141                	addi	sp,sp,-16
    8000422e:	e406                	sd	ra,8(sp)
    80004230:	e022                	sd	s0,0(sp)
    80004232:	0800                	addi	s0,sp,16
    80004234:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004236:	4585                	li	a1,1
    80004238:	00000097          	auipc	ra,0x0
    8000423c:	dc4080e7          	jalr	-572(ra) # 80003ffc <namex>
}
    80004240:	60a2                	ld	ra,8(sp)
    80004242:	6402                	ld	s0,0(sp)
    80004244:	0141                	addi	sp,sp,16
    80004246:	8082                	ret

0000000080004248 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004248:	1101                	addi	sp,sp,-32
    8000424a:	ec06                	sd	ra,24(sp)
    8000424c:	e822                	sd	s0,16(sp)
    8000424e:	e426                	sd	s1,8(sp)
    80004250:	e04a                	sd	s2,0(sp)
    80004252:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004254:	0001d917          	auipc	s2,0x1d
    80004258:	95c90913          	addi	s2,s2,-1700 # 80020bb0 <log>
    8000425c:	01892583          	lw	a1,24(s2)
    80004260:	02892503          	lw	a0,40(s2)
    80004264:	fffff097          	auipc	ra,0xfffff
    80004268:	fea080e7          	jalr	-22(ra) # 8000324e <bread>
    8000426c:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000426e:	02c92683          	lw	a3,44(s2)
    80004272:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004274:	02d05763          	blez	a3,800042a2 <write_head+0x5a>
    80004278:	0001d797          	auipc	a5,0x1d
    8000427c:	96878793          	addi	a5,a5,-1688 # 80020be0 <log+0x30>
    80004280:	05c50713          	addi	a4,a0,92
    80004284:	36fd                	addiw	a3,a3,-1
    80004286:	1682                	slli	a3,a3,0x20
    80004288:	9281                	srli	a3,a3,0x20
    8000428a:	068a                	slli	a3,a3,0x2
    8000428c:	0001d617          	auipc	a2,0x1d
    80004290:	95860613          	addi	a2,a2,-1704 # 80020be4 <log+0x34>
    80004294:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004296:	4390                	lw	a2,0(a5)
    80004298:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000429a:	0791                	addi	a5,a5,4
    8000429c:	0711                	addi	a4,a4,4
    8000429e:	fed79ce3          	bne	a5,a3,80004296 <write_head+0x4e>
  }
  bwrite(buf);
    800042a2:	8526                	mv	a0,s1
    800042a4:	fffff097          	auipc	ra,0xfffff
    800042a8:	09c080e7          	jalr	156(ra) # 80003340 <bwrite>
  brelse(buf);
    800042ac:	8526                	mv	a0,s1
    800042ae:	fffff097          	auipc	ra,0xfffff
    800042b2:	0d0080e7          	jalr	208(ra) # 8000337e <brelse>
}
    800042b6:	60e2                	ld	ra,24(sp)
    800042b8:	6442                	ld	s0,16(sp)
    800042ba:	64a2                	ld	s1,8(sp)
    800042bc:	6902                	ld	s2,0(sp)
    800042be:	6105                	addi	sp,sp,32
    800042c0:	8082                	ret

00000000800042c2 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800042c2:	0001d797          	auipc	a5,0x1d
    800042c6:	91a7a783          	lw	a5,-1766(a5) # 80020bdc <log+0x2c>
    800042ca:	0af05d63          	blez	a5,80004384 <install_trans+0xc2>
{
    800042ce:	7139                	addi	sp,sp,-64
    800042d0:	fc06                	sd	ra,56(sp)
    800042d2:	f822                	sd	s0,48(sp)
    800042d4:	f426                	sd	s1,40(sp)
    800042d6:	f04a                	sd	s2,32(sp)
    800042d8:	ec4e                	sd	s3,24(sp)
    800042da:	e852                	sd	s4,16(sp)
    800042dc:	e456                	sd	s5,8(sp)
    800042de:	e05a                	sd	s6,0(sp)
    800042e0:	0080                	addi	s0,sp,64
    800042e2:	8b2a                	mv	s6,a0
    800042e4:	0001da97          	auipc	s5,0x1d
    800042e8:	8fca8a93          	addi	s5,s5,-1796 # 80020be0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042ec:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800042ee:	0001d997          	auipc	s3,0x1d
    800042f2:	8c298993          	addi	s3,s3,-1854 # 80020bb0 <log>
    800042f6:	a00d                	j	80004318 <install_trans+0x56>
    brelse(lbuf);
    800042f8:	854a                	mv	a0,s2
    800042fa:	fffff097          	auipc	ra,0xfffff
    800042fe:	084080e7          	jalr	132(ra) # 8000337e <brelse>
    brelse(dbuf);
    80004302:	8526                	mv	a0,s1
    80004304:	fffff097          	auipc	ra,0xfffff
    80004308:	07a080e7          	jalr	122(ra) # 8000337e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000430c:	2a05                	addiw	s4,s4,1
    8000430e:	0a91                	addi	s5,s5,4
    80004310:	02c9a783          	lw	a5,44(s3)
    80004314:	04fa5e63          	bge	s4,a5,80004370 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004318:	0189a583          	lw	a1,24(s3)
    8000431c:	014585bb          	addw	a1,a1,s4
    80004320:	2585                	addiw	a1,a1,1
    80004322:	0289a503          	lw	a0,40(s3)
    80004326:	fffff097          	auipc	ra,0xfffff
    8000432a:	f28080e7          	jalr	-216(ra) # 8000324e <bread>
    8000432e:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004330:	000aa583          	lw	a1,0(s5)
    80004334:	0289a503          	lw	a0,40(s3)
    80004338:	fffff097          	auipc	ra,0xfffff
    8000433c:	f16080e7          	jalr	-234(ra) # 8000324e <bread>
    80004340:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004342:	40000613          	li	a2,1024
    80004346:	05890593          	addi	a1,s2,88
    8000434a:	05850513          	addi	a0,a0,88
    8000434e:	ffffd097          	auipc	ra,0xffffd
    80004352:	9e0080e7          	jalr	-1568(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    80004356:	8526                	mv	a0,s1
    80004358:	fffff097          	auipc	ra,0xfffff
    8000435c:	fe8080e7          	jalr	-24(ra) # 80003340 <bwrite>
    if(recovering == 0)
    80004360:	f80b1ce3          	bnez	s6,800042f8 <install_trans+0x36>
      bunpin(dbuf);
    80004364:	8526                	mv	a0,s1
    80004366:	fffff097          	auipc	ra,0xfffff
    8000436a:	0f2080e7          	jalr	242(ra) # 80003458 <bunpin>
    8000436e:	b769                	j	800042f8 <install_trans+0x36>
}
    80004370:	70e2                	ld	ra,56(sp)
    80004372:	7442                	ld	s0,48(sp)
    80004374:	74a2                	ld	s1,40(sp)
    80004376:	7902                	ld	s2,32(sp)
    80004378:	69e2                	ld	s3,24(sp)
    8000437a:	6a42                	ld	s4,16(sp)
    8000437c:	6aa2                	ld	s5,8(sp)
    8000437e:	6b02                	ld	s6,0(sp)
    80004380:	6121                	addi	sp,sp,64
    80004382:	8082                	ret
    80004384:	8082                	ret

0000000080004386 <initlog>:
{
    80004386:	7179                	addi	sp,sp,-48
    80004388:	f406                	sd	ra,40(sp)
    8000438a:	f022                	sd	s0,32(sp)
    8000438c:	ec26                	sd	s1,24(sp)
    8000438e:	e84a                	sd	s2,16(sp)
    80004390:	e44e                	sd	s3,8(sp)
    80004392:	1800                	addi	s0,sp,48
    80004394:	892a                	mv	s2,a0
    80004396:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004398:	0001d497          	auipc	s1,0x1d
    8000439c:	81848493          	addi	s1,s1,-2024 # 80020bb0 <log>
    800043a0:	00004597          	auipc	a1,0x4
    800043a4:	33858593          	addi	a1,a1,824 # 800086d8 <syscalls+0x1e8>
    800043a8:	8526                	mv	a0,s1
    800043aa:	ffffc097          	auipc	ra,0xffffc
    800043ae:	79c080e7          	jalr	1948(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    800043b2:	0149a583          	lw	a1,20(s3)
    800043b6:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800043b8:	0109a783          	lw	a5,16(s3)
    800043bc:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800043be:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800043c2:	854a                	mv	a0,s2
    800043c4:	fffff097          	auipc	ra,0xfffff
    800043c8:	e8a080e7          	jalr	-374(ra) # 8000324e <bread>
  log.lh.n = lh->n;
    800043cc:	4d34                	lw	a3,88(a0)
    800043ce:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800043d0:	02d05563          	blez	a3,800043fa <initlog+0x74>
    800043d4:	05c50793          	addi	a5,a0,92
    800043d8:	0001d717          	auipc	a4,0x1d
    800043dc:	80870713          	addi	a4,a4,-2040 # 80020be0 <log+0x30>
    800043e0:	36fd                	addiw	a3,a3,-1
    800043e2:	1682                	slli	a3,a3,0x20
    800043e4:	9281                	srli	a3,a3,0x20
    800043e6:	068a                	slli	a3,a3,0x2
    800043e8:	06050613          	addi	a2,a0,96
    800043ec:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800043ee:	4390                	lw	a2,0(a5)
    800043f0:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800043f2:	0791                	addi	a5,a5,4
    800043f4:	0711                	addi	a4,a4,4
    800043f6:	fed79ce3          	bne	a5,a3,800043ee <initlog+0x68>
  brelse(buf);
    800043fa:	fffff097          	auipc	ra,0xfffff
    800043fe:	f84080e7          	jalr	-124(ra) # 8000337e <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004402:	4505                	li	a0,1
    80004404:	00000097          	auipc	ra,0x0
    80004408:	ebe080e7          	jalr	-322(ra) # 800042c2 <install_trans>
  log.lh.n = 0;
    8000440c:	0001c797          	auipc	a5,0x1c
    80004410:	7c07a823          	sw	zero,2000(a5) # 80020bdc <log+0x2c>
  write_head(); // clear the log
    80004414:	00000097          	auipc	ra,0x0
    80004418:	e34080e7          	jalr	-460(ra) # 80004248 <write_head>
}
    8000441c:	70a2                	ld	ra,40(sp)
    8000441e:	7402                	ld	s0,32(sp)
    80004420:	64e2                	ld	s1,24(sp)
    80004422:	6942                	ld	s2,16(sp)
    80004424:	69a2                	ld	s3,8(sp)
    80004426:	6145                	addi	sp,sp,48
    80004428:	8082                	ret

000000008000442a <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000442a:	1101                	addi	sp,sp,-32
    8000442c:	ec06                	sd	ra,24(sp)
    8000442e:	e822                	sd	s0,16(sp)
    80004430:	e426                	sd	s1,8(sp)
    80004432:	e04a                	sd	s2,0(sp)
    80004434:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004436:	0001c517          	auipc	a0,0x1c
    8000443a:	77a50513          	addi	a0,a0,1914 # 80020bb0 <log>
    8000443e:	ffffc097          	auipc	ra,0xffffc
    80004442:	798080e7          	jalr	1944(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    80004446:	0001c497          	auipc	s1,0x1c
    8000444a:	76a48493          	addi	s1,s1,1898 # 80020bb0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000444e:	4979                	li	s2,30
    80004450:	a039                	j	8000445e <begin_op+0x34>
      sleep(&log, &log.lock);
    80004452:	85a6                	mv	a1,s1
    80004454:	8526                	mv	a0,s1
    80004456:	ffffe097          	auipc	ra,0xffffe
    8000445a:	ef2080e7          	jalr	-270(ra) # 80002348 <sleep>
    if(log.committing){
    8000445e:	50dc                	lw	a5,36(s1)
    80004460:	fbed                	bnez	a5,80004452 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004462:	509c                	lw	a5,32(s1)
    80004464:	0017871b          	addiw	a4,a5,1
    80004468:	0007069b          	sext.w	a3,a4
    8000446c:	0027179b          	slliw	a5,a4,0x2
    80004470:	9fb9                	addw	a5,a5,a4
    80004472:	0017979b          	slliw	a5,a5,0x1
    80004476:	54d8                	lw	a4,44(s1)
    80004478:	9fb9                	addw	a5,a5,a4
    8000447a:	00f95963          	bge	s2,a5,8000448c <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000447e:	85a6                	mv	a1,s1
    80004480:	8526                	mv	a0,s1
    80004482:	ffffe097          	auipc	ra,0xffffe
    80004486:	ec6080e7          	jalr	-314(ra) # 80002348 <sleep>
    8000448a:	bfd1                	j	8000445e <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000448c:	0001c517          	auipc	a0,0x1c
    80004490:	72450513          	addi	a0,a0,1828 # 80020bb0 <log>
    80004494:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004496:	ffffc097          	auipc	ra,0xffffc
    8000449a:	7f4080e7          	jalr	2036(ra) # 80000c8a <release>
      break;
    }
  }
}
    8000449e:	60e2                	ld	ra,24(sp)
    800044a0:	6442                	ld	s0,16(sp)
    800044a2:	64a2                	ld	s1,8(sp)
    800044a4:	6902                	ld	s2,0(sp)
    800044a6:	6105                	addi	sp,sp,32
    800044a8:	8082                	ret

00000000800044aa <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800044aa:	7139                	addi	sp,sp,-64
    800044ac:	fc06                	sd	ra,56(sp)
    800044ae:	f822                	sd	s0,48(sp)
    800044b0:	f426                	sd	s1,40(sp)
    800044b2:	f04a                	sd	s2,32(sp)
    800044b4:	ec4e                	sd	s3,24(sp)
    800044b6:	e852                	sd	s4,16(sp)
    800044b8:	e456                	sd	s5,8(sp)
    800044ba:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800044bc:	0001c497          	auipc	s1,0x1c
    800044c0:	6f448493          	addi	s1,s1,1780 # 80020bb0 <log>
    800044c4:	8526                	mv	a0,s1
    800044c6:	ffffc097          	auipc	ra,0xffffc
    800044ca:	710080e7          	jalr	1808(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    800044ce:	509c                	lw	a5,32(s1)
    800044d0:	37fd                	addiw	a5,a5,-1
    800044d2:	0007891b          	sext.w	s2,a5
    800044d6:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800044d8:	50dc                	lw	a5,36(s1)
    800044da:	e7b9                	bnez	a5,80004528 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800044dc:	04091e63          	bnez	s2,80004538 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800044e0:	0001c497          	auipc	s1,0x1c
    800044e4:	6d048493          	addi	s1,s1,1744 # 80020bb0 <log>
    800044e8:	4785                	li	a5,1
    800044ea:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800044ec:	8526                	mv	a0,s1
    800044ee:	ffffc097          	auipc	ra,0xffffc
    800044f2:	79c080e7          	jalr	1948(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800044f6:	54dc                	lw	a5,44(s1)
    800044f8:	06f04763          	bgtz	a5,80004566 <end_op+0xbc>
    acquire(&log.lock);
    800044fc:	0001c497          	auipc	s1,0x1c
    80004500:	6b448493          	addi	s1,s1,1716 # 80020bb0 <log>
    80004504:	8526                	mv	a0,s1
    80004506:	ffffc097          	auipc	ra,0xffffc
    8000450a:	6d0080e7          	jalr	1744(ra) # 80000bd6 <acquire>
    log.committing = 0;
    8000450e:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004512:	8526                	mv	a0,s1
    80004514:	ffffe097          	auipc	ra,0xffffe
    80004518:	e98080e7          	jalr	-360(ra) # 800023ac <wakeup>
    release(&log.lock);
    8000451c:	8526                	mv	a0,s1
    8000451e:	ffffc097          	auipc	ra,0xffffc
    80004522:	76c080e7          	jalr	1900(ra) # 80000c8a <release>
}
    80004526:	a03d                	j	80004554 <end_op+0xaa>
    panic("log.committing");
    80004528:	00004517          	auipc	a0,0x4
    8000452c:	1b850513          	addi	a0,a0,440 # 800086e0 <syscalls+0x1f0>
    80004530:	ffffc097          	auipc	ra,0xffffc
    80004534:	00e080e7          	jalr	14(ra) # 8000053e <panic>
    wakeup(&log);
    80004538:	0001c497          	auipc	s1,0x1c
    8000453c:	67848493          	addi	s1,s1,1656 # 80020bb0 <log>
    80004540:	8526                	mv	a0,s1
    80004542:	ffffe097          	auipc	ra,0xffffe
    80004546:	e6a080e7          	jalr	-406(ra) # 800023ac <wakeup>
  release(&log.lock);
    8000454a:	8526                	mv	a0,s1
    8000454c:	ffffc097          	auipc	ra,0xffffc
    80004550:	73e080e7          	jalr	1854(ra) # 80000c8a <release>
}
    80004554:	70e2                	ld	ra,56(sp)
    80004556:	7442                	ld	s0,48(sp)
    80004558:	74a2                	ld	s1,40(sp)
    8000455a:	7902                	ld	s2,32(sp)
    8000455c:	69e2                	ld	s3,24(sp)
    8000455e:	6a42                	ld	s4,16(sp)
    80004560:	6aa2                	ld	s5,8(sp)
    80004562:	6121                	addi	sp,sp,64
    80004564:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004566:	0001ca97          	auipc	s5,0x1c
    8000456a:	67aa8a93          	addi	s5,s5,1658 # 80020be0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000456e:	0001ca17          	auipc	s4,0x1c
    80004572:	642a0a13          	addi	s4,s4,1602 # 80020bb0 <log>
    80004576:	018a2583          	lw	a1,24(s4)
    8000457a:	012585bb          	addw	a1,a1,s2
    8000457e:	2585                	addiw	a1,a1,1
    80004580:	028a2503          	lw	a0,40(s4)
    80004584:	fffff097          	auipc	ra,0xfffff
    80004588:	cca080e7          	jalr	-822(ra) # 8000324e <bread>
    8000458c:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000458e:	000aa583          	lw	a1,0(s5)
    80004592:	028a2503          	lw	a0,40(s4)
    80004596:	fffff097          	auipc	ra,0xfffff
    8000459a:	cb8080e7          	jalr	-840(ra) # 8000324e <bread>
    8000459e:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800045a0:	40000613          	li	a2,1024
    800045a4:	05850593          	addi	a1,a0,88
    800045a8:	05848513          	addi	a0,s1,88
    800045ac:	ffffc097          	auipc	ra,0xffffc
    800045b0:	782080e7          	jalr	1922(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    800045b4:	8526                	mv	a0,s1
    800045b6:	fffff097          	auipc	ra,0xfffff
    800045ba:	d8a080e7          	jalr	-630(ra) # 80003340 <bwrite>
    brelse(from);
    800045be:	854e                	mv	a0,s3
    800045c0:	fffff097          	auipc	ra,0xfffff
    800045c4:	dbe080e7          	jalr	-578(ra) # 8000337e <brelse>
    brelse(to);
    800045c8:	8526                	mv	a0,s1
    800045ca:	fffff097          	auipc	ra,0xfffff
    800045ce:	db4080e7          	jalr	-588(ra) # 8000337e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045d2:	2905                	addiw	s2,s2,1
    800045d4:	0a91                	addi	s5,s5,4
    800045d6:	02ca2783          	lw	a5,44(s4)
    800045da:	f8f94ee3          	blt	s2,a5,80004576 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800045de:	00000097          	auipc	ra,0x0
    800045e2:	c6a080e7          	jalr	-918(ra) # 80004248 <write_head>
    install_trans(0); // Now install writes to home locations
    800045e6:	4501                	li	a0,0
    800045e8:	00000097          	auipc	ra,0x0
    800045ec:	cda080e7          	jalr	-806(ra) # 800042c2 <install_trans>
    log.lh.n = 0;
    800045f0:	0001c797          	auipc	a5,0x1c
    800045f4:	5e07a623          	sw	zero,1516(a5) # 80020bdc <log+0x2c>
    write_head();    // Erase the transaction from the log
    800045f8:	00000097          	auipc	ra,0x0
    800045fc:	c50080e7          	jalr	-944(ra) # 80004248 <write_head>
    80004600:	bdf5                	j	800044fc <end_op+0x52>

0000000080004602 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004602:	1101                	addi	sp,sp,-32
    80004604:	ec06                	sd	ra,24(sp)
    80004606:	e822                	sd	s0,16(sp)
    80004608:	e426                	sd	s1,8(sp)
    8000460a:	e04a                	sd	s2,0(sp)
    8000460c:	1000                	addi	s0,sp,32
    8000460e:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004610:	0001c917          	auipc	s2,0x1c
    80004614:	5a090913          	addi	s2,s2,1440 # 80020bb0 <log>
    80004618:	854a                	mv	a0,s2
    8000461a:	ffffc097          	auipc	ra,0xffffc
    8000461e:	5bc080e7          	jalr	1468(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004622:	02c92603          	lw	a2,44(s2)
    80004626:	47f5                	li	a5,29
    80004628:	06c7c563          	blt	a5,a2,80004692 <log_write+0x90>
    8000462c:	0001c797          	auipc	a5,0x1c
    80004630:	5a07a783          	lw	a5,1440(a5) # 80020bcc <log+0x1c>
    80004634:	37fd                	addiw	a5,a5,-1
    80004636:	04f65e63          	bge	a2,a5,80004692 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000463a:	0001c797          	auipc	a5,0x1c
    8000463e:	5967a783          	lw	a5,1430(a5) # 80020bd0 <log+0x20>
    80004642:	06f05063          	blez	a5,800046a2 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004646:	4781                	li	a5,0
    80004648:	06c05563          	blez	a2,800046b2 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000464c:	44cc                	lw	a1,12(s1)
    8000464e:	0001c717          	auipc	a4,0x1c
    80004652:	59270713          	addi	a4,a4,1426 # 80020be0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004656:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004658:	4314                	lw	a3,0(a4)
    8000465a:	04b68c63          	beq	a3,a1,800046b2 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000465e:	2785                	addiw	a5,a5,1
    80004660:	0711                	addi	a4,a4,4
    80004662:	fef61be3          	bne	a2,a5,80004658 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004666:	0621                	addi	a2,a2,8
    80004668:	060a                	slli	a2,a2,0x2
    8000466a:	0001c797          	auipc	a5,0x1c
    8000466e:	54678793          	addi	a5,a5,1350 # 80020bb0 <log>
    80004672:	963e                	add	a2,a2,a5
    80004674:	44dc                	lw	a5,12(s1)
    80004676:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004678:	8526                	mv	a0,s1
    8000467a:	fffff097          	auipc	ra,0xfffff
    8000467e:	da2080e7          	jalr	-606(ra) # 8000341c <bpin>
    log.lh.n++;
    80004682:	0001c717          	auipc	a4,0x1c
    80004686:	52e70713          	addi	a4,a4,1326 # 80020bb0 <log>
    8000468a:	575c                	lw	a5,44(a4)
    8000468c:	2785                	addiw	a5,a5,1
    8000468e:	d75c                	sw	a5,44(a4)
    80004690:	a835                	j	800046cc <log_write+0xca>
    panic("too big a transaction");
    80004692:	00004517          	auipc	a0,0x4
    80004696:	05e50513          	addi	a0,a0,94 # 800086f0 <syscalls+0x200>
    8000469a:	ffffc097          	auipc	ra,0xffffc
    8000469e:	ea4080e7          	jalr	-348(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800046a2:	00004517          	auipc	a0,0x4
    800046a6:	06650513          	addi	a0,a0,102 # 80008708 <syscalls+0x218>
    800046aa:	ffffc097          	auipc	ra,0xffffc
    800046ae:	e94080e7          	jalr	-364(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800046b2:	00878713          	addi	a4,a5,8
    800046b6:	00271693          	slli	a3,a4,0x2
    800046ba:	0001c717          	auipc	a4,0x1c
    800046be:	4f670713          	addi	a4,a4,1270 # 80020bb0 <log>
    800046c2:	9736                	add	a4,a4,a3
    800046c4:	44d4                	lw	a3,12(s1)
    800046c6:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800046c8:	faf608e3          	beq	a2,a5,80004678 <log_write+0x76>
  }
  release(&log.lock);
    800046cc:	0001c517          	auipc	a0,0x1c
    800046d0:	4e450513          	addi	a0,a0,1252 # 80020bb0 <log>
    800046d4:	ffffc097          	auipc	ra,0xffffc
    800046d8:	5b6080e7          	jalr	1462(ra) # 80000c8a <release>
}
    800046dc:	60e2                	ld	ra,24(sp)
    800046de:	6442                	ld	s0,16(sp)
    800046e0:	64a2                	ld	s1,8(sp)
    800046e2:	6902                	ld	s2,0(sp)
    800046e4:	6105                	addi	sp,sp,32
    800046e6:	8082                	ret

00000000800046e8 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800046e8:	1101                	addi	sp,sp,-32
    800046ea:	ec06                	sd	ra,24(sp)
    800046ec:	e822                	sd	s0,16(sp)
    800046ee:	e426                	sd	s1,8(sp)
    800046f0:	e04a                	sd	s2,0(sp)
    800046f2:	1000                	addi	s0,sp,32
    800046f4:	84aa                	mv	s1,a0
    800046f6:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800046f8:	00004597          	auipc	a1,0x4
    800046fc:	03058593          	addi	a1,a1,48 # 80008728 <syscalls+0x238>
    80004700:	0521                	addi	a0,a0,8
    80004702:	ffffc097          	auipc	ra,0xffffc
    80004706:	444080e7          	jalr	1092(ra) # 80000b46 <initlock>
  lk->name = name;
    8000470a:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000470e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004712:	0204a423          	sw	zero,40(s1)
}
    80004716:	60e2                	ld	ra,24(sp)
    80004718:	6442                	ld	s0,16(sp)
    8000471a:	64a2                	ld	s1,8(sp)
    8000471c:	6902                	ld	s2,0(sp)
    8000471e:	6105                	addi	sp,sp,32
    80004720:	8082                	ret

0000000080004722 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004722:	1101                	addi	sp,sp,-32
    80004724:	ec06                	sd	ra,24(sp)
    80004726:	e822                	sd	s0,16(sp)
    80004728:	e426                	sd	s1,8(sp)
    8000472a:	e04a                	sd	s2,0(sp)
    8000472c:	1000                	addi	s0,sp,32
    8000472e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004730:	00850913          	addi	s2,a0,8
    80004734:	854a                	mv	a0,s2
    80004736:	ffffc097          	auipc	ra,0xffffc
    8000473a:	4a0080e7          	jalr	1184(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    8000473e:	409c                	lw	a5,0(s1)
    80004740:	cb89                	beqz	a5,80004752 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004742:	85ca                	mv	a1,s2
    80004744:	8526                	mv	a0,s1
    80004746:	ffffe097          	auipc	ra,0xffffe
    8000474a:	c02080e7          	jalr	-1022(ra) # 80002348 <sleep>
  while (lk->locked) {
    8000474e:	409c                	lw	a5,0(s1)
    80004750:	fbed                	bnez	a5,80004742 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004752:	4785                	li	a5,1
    80004754:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004756:	ffffd097          	auipc	ra,0xffffd
    8000475a:	54a080e7          	jalr	1354(ra) # 80001ca0 <myproc>
    8000475e:	591c                	lw	a5,48(a0)
    80004760:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004762:	854a                	mv	a0,s2
    80004764:	ffffc097          	auipc	ra,0xffffc
    80004768:	526080e7          	jalr	1318(ra) # 80000c8a <release>
}
    8000476c:	60e2                	ld	ra,24(sp)
    8000476e:	6442                	ld	s0,16(sp)
    80004770:	64a2                	ld	s1,8(sp)
    80004772:	6902                	ld	s2,0(sp)
    80004774:	6105                	addi	sp,sp,32
    80004776:	8082                	ret

0000000080004778 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004778:	1101                	addi	sp,sp,-32
    8000477a:	ec06                	sd	ra,24(sp)
    8000477c:	e822                	sd	s0,16(sp)
    8000477e:	e426                	sd	s1,8(sp)
    80004780:	e04a                	sd	s2,0(sp)
    80004782:	1000                	addi	s0,sp,32
    80004784:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004786:	00850913          	addi	s2,a0,8
    8000478a:	854a                	mv	a0,s2
    8000478c:	ffffc097          	auipc	ra,0xffffc
    80004790:	44a080e7          	jalr	1098(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    80004794:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004798:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000479c:	8526                	mv	a0,s1
    8000479e:	ffffe097          	auipc	ra,0xffffe
    800047a2:	c0e080e7          	jalr	-1010(ra) # 800023ac <wakeup>
  release(&lk->lk);
    800047a6:	854a                	mv	a0,s2
    800047a8:	ffffc097          	auipc	ra,0xffffc
    800047ac:	4e2080e7          	jalr	1250(ra) # 80000c8a <release>
}
    800047b0:	60e2                	ld	ra,24(sp)
    800047b2:	6442                	ld	s0,16(sp)
    800047b4:	64a2                	ld	s1,8(sp)
    800047b6:	6902                	ld	s2,0(sp)
    800047b8:	6105                	addi	sp,sp,32
    800047ba:	8082                	ret

00000000800047bc <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800047bc:	7179                	addi	sp,sp,-48
    800047be:	f406                	sd	ra,40(sp)
    800047c0:	f022                	sd	s0,32(sp)
    800047c2:	ec26                	sd	s1,24(sp)
    800047c4:	e84a                	sd	s2,16(sp)
    800047c6:	e44e                	sd	s3,8(sp)
    800047c8:	1800                	addi	s0,sp,48
    800047ca:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800047cc:	00850913          	addi	s2,a0,8
    800047d0:	854a                	mv	a0,s2
    800047d2:	ffffc097          	auipc	ra,0xffffc
    800047d6:	404080e7          	jalr	1028(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800047da:	409c                	lw	a5,0(s1)
    800047dc:	ef99                	bnez	a5,800047fa <holdingsleep+0x3e>
    800047de:	4481                	li	s1,0
  release(&lk->lk);
    800047e0:	854a                	mv	a0,s2
    800047e2:	ffffc097          	auipc	ra,0xffffc
    800047e6:	4a8080e7          	jalr	1192(ra) # 80000c8a <release>
  return r;
}
    800047ea:	8526                	mv	a0,s1
    800047ec:	70a2                	ld	ra,40(sp)
    800047ee:	7402                	ld	s0,32(sp)
    800047f0:	64e2                	ld	s1,24(sp)
    800047f2:	6942                	ld	s2,16(sp)
    800047f4:	69a2                	ld	s3,8(sp)
    800047f6:	6145                	addi	sp,sp,48
    800047f8:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800047fa:	0284a983          	lw	s3,40(s1)
    800047fe:	ffffd097          	auipc	ra,0xffffd
    80004802:	4a2080e7          	jalr	1186(ra) # 80001ca0 <myproc>
    80004806:	5904                	lw	s1,48(a0)
    80004808:	413484b3          	sub	s1,s1,s3
    8000480c:	0014b493          	seqz	s1,s1
    80004810:	bfc1                	j	800047e0 <holdingsleep+0x24>

0000000080004812 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004812:	1141                	addi	sp,sp,-16
    80004814:	e406                	sd	ra,8(sp)
    80004816:	e022                	sd	s0,0(sp)
    80004818:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000481a:	00004597          	auipc	a1,0x4
    8000481e:	f1e58593          	addi	a1,a1,-226 # 80008738 <syscalls+0x248>
    80004822:	0001c517          	auipc	a0,0x1c
    80004826:	4d650513          	addi	a0,a0,1238 # 80020cf8 <ftable>
    8000482a:	ffffc097          	auipc	ra,0xffffc
    8000482e:	31c080e7          	jalr	796(ra) # 80000b46 <initlock>
}
    80004832:	60a2                	ld	ra,8(sp)
    80004834:	6402                	ld	s0,0(sp)
    80004836:	0141                	addi	sp,sp,16
    80004838:	8082                	ret

000000008000483a <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000483a:	1101                	addi	sp,sp,-32
    8000483c:	ec06                	sd	ra,24(sp)
    8000483e:	e822                	sd	s0,16(sp)
    80004840:	e426                	sd	s1,8(sp)
    80004842:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004844:	0001c517          	auipc	a0,0x1c
    80004848:	4b450513          	addi	a0,a0,1204 # 80020cf8 <ftable>
    8000484c:	ffffc097          	auipc	ra,0xffffc
    80004850:	38a080e7          	jalr	906(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004854:	0001c497          	auipc	s1,0x1c
    80004858:	4bc48493          	addi	s1,s1,1212 # 80020d10 <ftable+0x18>
    8000485c:	0001d717          	auipc	a4,0x1d
    80004860:	45470713          	addi	a4,a4,1108 # 80021cb0 <disk>
    if(f->ref == 0){
    80004864:	40dc                	lw	a5,4(s1)
    80004866:	cf99                	beqz	a5,80004884 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004868:	02848493          	addi	s1,s1,40
    8000486c:	fee49ce3          	bne	s1,a4,80004864 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004870:	0001c517          	auipc	a0,0x1c
    80004874:	48850513          	addi	a0,a0,1160 # 80020cf8 <ftable>
    80004878:	ffffc097          	auipc	ra,0xffffc
    8000487c:	412080e7          	jalr	1042(ra) # 80000c8a <release>
  return 0;
    80004880:	4481                	li	s1,0
    80004882:	a819                	j	80004898 <filealloc+0x5e>
      f->ref = 1;
    80004884:	4785                	li	a5,1
    80004886:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004888:	0001c517          	auipc	a0,0x1c
    8000488c:	47050513          	addi	a0,a0,1136 # 80020cf8 <ftable>
    80004890:	ffffc097          	auipc	ra,0xffffc
    80004894:	3fa080e7          	jalr	1018(ra) # 80000c8a <release>
}
    80004898:	8526                	mv	a0,s1
    8000489a:	60e2                	ld	ra,24(sp)
    8000489c:	6442                	ld	s0,16(sp)
    8000489e:	64a2                	ld	s1,8(sp)
    800048a0:	6105                	addi	sp,sp,32
    800048a2:	8082                	ret

00000000800048a4 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800048a4:	1101                	addi	sp,sp,-32
    800048a6:	ec06                	sd	ra,24(sp)
    800048a8:	e822                	sd	s0,16(sp)
    800048aa:	e426                	sd	s1,8(sp)
    800048ac:	1000                	addi	s0,sp,32
    800048ae:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800048b0:	0001c517          	auipc	a0,0x1c
    800048b4:	44850513          	addi	a0,a0,1096 # 80020cf8 <ftable>
    800048b8:	ffffc097          	auipc	ra,0xffffc
    800048bc:	31e080e7          	jalr	798(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    800048c0:	40dc                	lw	a5,4(s1)
    800048c2:	02f05263          	blez	a5,800048e6 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800048c6:	2785                	addiw	a5,a5,1
    800048c8:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800048ca:	0001c517          	auipc	a0,0x1c
    800048ce:	42e50513          	addi	a0,a0,1070 # 80020cf8 <ftable>
    800048d2:	ffffc097          	auipc	ra,0xffffc
    800048d6:	3b8080e7          	jalr	952(ra) # 80000c8a <release>
  return f;
}
    800048da:	8526                	mv	a0,s1
    800048dc:	60e2                	ld	ra,24(sp)
    800048de:	6442                	ld	s0,16(sp)
    800048e0:	64a2                	ld	s1,8(sp)
    800048e2:	6105                	addi	sp,sp,32
    800048e4:	8082                	ret
    panic("filedup");
    800048e6:	00004517          	auipc	a0,0x4
    800048ea:	e5a50513          	addi	a0,a0,-422 # 80008740 <syscalls+0x250>
    800048ee:	ffffc097          	auipc	ra,0xffffc
    800048f2:	c50080e7          	jalr	-944(ra) # 8000053e <panic>

00000000800048f6 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800048f6:	7139                	addi	sp,sp,-64
    800048f8:	fc06                	sd	ra,56(sp)
    800048fa:	f822                	sd	s0,48(sp)
    800048fc:	f426                	sd	s1,40(sp)
    800048fe:	f04a                	sd	s2,32(sp)
    80004900:	ec4e                	sd	s3,24(sp)
    80004902:	e852                	sd	s4,16(sp)
    80004904:	e456                	sd	s5,8(sp)
    80004906:	0080                	addi	s0,sp,64
    80004908:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000490a:	0001c517          	auipc	a0,0x1c
    8000490e:	3ee50513          	addi	a0,a0,1006 # 80020cf8 <ftable>
    80004912:	ffffc097          	auipc	ra,0xffffc
    80004916:	2c4080e7          	jalr	708(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    8000491a:	40dc                	lw	a5,4(s1)
    8000491c:	06f05163          	blez	a5,8000497e <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004920:	37fd                	addiw	a5,a5,-1
    80004922:	0007871b          	sext.w	a4,a5
    80004926:	c0dc                	sw	a5,4(s1)
    80004928:	06e04363          	bgtz	a4,8000498e <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000492c:	0004a903          	lw	s2,0(s1)
    80004930:	0094ca83          	lbu	s5,9(s1)
    80004934:	0104ba03          	ld	s4,16(s1)
    80004938:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000493c:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004940:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004944:	0001c517          	auipc	a0,0x1c
    80004948:	3b450513          	addi	a0,a0,948 # 80020cf8 <ftable>
    8000494c:	ffffc097          	auipc	ra,0xffffc
    80004950:	33e080e7          	jalr	830(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    80004954:	4785                	li	a5,1
    80004956:	04f90d63          	beq	s2,a5,800049b0 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000495a:	3979                	addiw	s2,s2,-2
    8000495c:	4785                	li	a5,1
    8000495e:	0527e063          	bltu	a5,s2,8000499e <fileclose+0xa8>
    begin_op();
    80004962:	00000097          	auipc	ra,0x0
    80004966:	ac8080e7          	jalr	-1336(ra) # 8000442a <begin_op>
    iput(ff.ip);
    8000496a:	854e                	mv	a0,s3
    8000496c:	fffff097          	auipc	ra,0xfffff
    80004970:	2b6080e7          	jalr	694(ra) # 80003c22 <iput>
    end_op();
    80004974:	00000097          	auipc	ra,0x0
    80004978:	b36080e7          	jalr	-1226(ra) # 800044aa <end_op>
    8000497c:	a00d                	j	8000499e <fileclose+0xa8>
    panic("fileclose");
    8000497e:	00004517          	auipc	a0,0x4
    80004982:	dca50513          	addi	a0,a0,-566 # 80008748 <syscalls+0x258>
    80004986:	ffffc097          	auipc	ra,0xffffc
    8000498a:	bb8080e7          	jalr	-1096(ra) # 8000053e <panic>
    release(&ftable.lock);
    8000498e:	0001c517          	auipc	a0,0x1c
    80004992:	36a50513          	addi	a0,a0,874 # 80020cf8 <ftable>
    80004996:	ffffc097          	auipc	ra,0xffffc
    8000499a:	2f4080e7          	jalr	756(ra) # 80000c8a <release>
  }
}
    8000499e:	70e2                	ld	ra,56(sp)
    800049a0:	7442                	ld	s0,48(sp)
    800049a2:	74a2                	ld	s1,40(sp)
    800049a4:	7902                	ld	s2,32(sp)
    800049a6:	69e2                	ld	s3,24(sp)
    800049a8:	6a42                	ld	s4,16(sp)
    800049aa:	6aa2                	ld	s5,8(sp)
    800049ac:	6121                	addi	sp,sp,64
    800049ae:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800049b0:	85d6                	mv	a1,s5
    800049b2:	8552                	mv	a0,s4
    800049b4:	00000097          	auipc	ra,0x0
    800049b8:	34c080e7          	jalr	844(ra) # 80004d00 <pipeclose>
    800049bc:	b7cd                	j	8000499e <fileclose+0xa8>

00000000800049be <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800049be:	715d                	addi	sp,sp,-80
    800049c0:	e486                	sd	ra,72(sp)
    800049c2:	e0a2                	sd	s0,64(sp)
    800049c4:	fc26                	sd	s1,56(sp)
    800049c6:	f84a                	sd	s2,48(sp)
    800049c8:	f44e                	sd	s3,40(sp)
    800049ca:	0880                	addi	s0,sp,80
    800049cc:	84aa                	mv	s1,a0
    800049ce:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800049d0:	ffffd097          	auipc	ra,0xffffd
    800049d4:	2d0080e7          	jalr	720(ra) # 80001ca0 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800049d8:	409c                	lw	a5,0(s1)
    800049da:	37f9                	addiw	a5,a5,-2
    800049dc:	4705                	li	a4,1
    800049de:	04f76763          	bltu	a4,a5,80004a2c <filestat+0x6e>
    800049e2:	892a                	mv	s2,a0
    ilock(f->ip);
    800049e4:	6c88                	ld	a0,24(s1)
    800049e6:	fffff097          	auipc	ra,0xfffff
    800049ea:	082080e7          	jalr	130(ra) # 80003a68 <ilock>
    stati(f->ip, &st);
    800049ee:	fb840593          	addi	a1,s0,-72
    800049f2:	6c88                	ld	a0,24(s1)
    800049f4:	fffff097          	auipc	ra,0xfffff
    800049f8:	2fe080e7          	jalr	766(ra) # 80003cf2 <stati>
    iunlock(f->ip);
    800049fc:	6c88                	ld	a0,24(s1)
    800049fe:	fffff097          	auipc	ra,0xfffff
    80004a02:	12c080e7          	jalr	300(ra) # 80003b2a <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004a06:	46e1                	li	a3,24
    80004a08:	fb840613          	addi	a2,s0,-72
    80004a0c:	85ce                	mv	a1,s3
    80004a0e:	05093503          	ld	a0,80(s2)
    80004a12:	ffffd097          	auipc	ra,0xffffd
    80004a16:	c5e080e7          	jalr	-930(ra) # 80001670 <copyout>
    80004a1a:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004a1e:	60a6                	ld	ra,72(sp)
    80004a20:	6406                	ld	s0,64(sp)
    80004a22:	74e2                	ld	s1,56(sp)
    80004a24:	7942                	ld	s2,48(sp)
    80004a26:	79a2                	ld	s3,40(sp)
    80004a28:	6161                	addi	sp,sp,80
    80004a2a:	8082                	ret
  return -1;
    80004a2c:	557d                	li	a0,-1
    80004a2e:	bfc5                	j	80004a1e <filestat+0x60>

0000000080004a30 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004a30:	7179                	addi	sp,sp,-48
    80004a32:	f406                	sd	ra,40(sp)
    80004a34:	f022                	sd	s0,32(sp)
    80004a36:	ec26                	sd	s1,24(sp)
    80004a38:	e84a                	sd	s2,16(sp)
    80004a3a:	e44e                	sd	s3,8(sp)
    80004a3c:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004a3e:	00854783          	lbu	a5,8(a0)
    80004a42:	c3d5                	beqz	a5,80004ae6 <fileread+0xb6>
    80004a44:	84aa                	mv	s1,a0
    80004a46:	89ae                	mv	s3,a1
    80004a48:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a4a:	411c                	lw	a5,0(a0)
    80004a4c:	4705                	li	a4,1
    80004a4e:	04e78963          	beq	a5,a4,80004aa0 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a52:	470d                	li	a4,3
    80004a54:	04e78d63          	beq	a5,a4,80004aae <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a58:	4709                	li	a4,2
    80004a5a:	06e79e63          	bne	a5,a4,80004ad6 <fileread+0xa6>
    ilock(f->ip);
    80004a5e:	6d08                	ld	a0,24(a0)
    80004a60:	fffff097          	auipc	ra,0xfffff
    80004a64:	008080e7          	jalr	8(ra) # 80003a68 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004a68:	874a                	mv	a4,s2
    80004a6a:	5094                	lw	a3,32(s1)
    80004a6c:	864e                	mv	a2,s3
    80004a6e:	4585                	li	a1,1
    80004a70:	6c88                	ld	a0,24(s1)
    80004a72:	fffff097          	auipc	ra,0xfffff
    80004a76:	2aa080e7          	jalr	682(ra) # 80003d1c <readi>
    80004a7a:	892a                	mv	s2,a0
    80004a7c:	00a05563          	blez	a0,80004a86 <fileread+0x56>
      f->off += r;
    80004a80:	509c                	lw	a5,32(s1)
    80004a82:	9fa9                	addw	a5,a5,a0
    80004a84:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004a86:	6c88                	ld	a0,24(s1)
    80004a88:	fffff097          	auipc	ra,0xfffff
    80004a8c:	0a2080e7          	jalr	162(ra) # 80003b2a <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004a90:	854a                	mv	a0,s2
    80004a92:	70a2                	ld	ra,40(sp)
    80004a94:	7402                	ld	s0,32(sp)
    80004a96:	64e2                	ld	s1,24(sp)
    80004a98:	6942                	ld	s2,16(sp)
    80004a9a:	69a2                	ld	s3,8(sp)
    80004a9c:	6145                	addi	sp,sp,48
    80004a9e:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004aa0:	6908                	ld	a0,16(a0)
    80004aa2:	00000097          	auipc	ra,0x0
    80004aa6:	3c6080e7          	jalr	966(ra) # 80004e68 <piperead>
    80004aaa:	892a                	mv	s2,a0
    80004aac:	b7d5                	j	80004a90 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004aae:	02451783          	lh	a5,36(a0)
    80004ab2:	03079693          	slli	a3,a5,0x30
    80004ab6:	92c1                	srli	a3,a3,0x30
    80004ab8:	4725                	li	a4,9
    80004aba:	02d76863          	bltu	a4,a3,80004aea <fileread+0xba>
    80004abe:	0792                	slli	a5,a5,0x4
    80004ac0:	0001c717          	auipc	a4,0x1c
    80004ac4:	19870713          	addi	a4,a4,408 # 80020c58 <devsw>
    80004ac8:	97ba                	add	a5,a5,a4
    80004aca:	639c                	ld	a5,0(a5)
    80004acc:	c38d                	beqz	a5,80004aee <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004ace:	4505                	li	a0,1
    80004ad0:	9782                	jalr	a5
    80004ad2:	892a                	mv	s2,a0
    80004ad4:	bf75                	j	80004a90 <fileread+0x60>
    panic("fileread");
    80004ad6:	00004517          	auipc	a0,0x4
    80004ada:	c8250513          	addi	a0,a0,-894 # 80008758 <syscalls+0x268>
    80004ade:	ffffc097          	auipc	ra,0xffffc
    80004ae2:	a60080e7          	jalr	-1440(ra) # 8000053e <panic>
    return -1;
    80004ae6:	597d                	li	s2,-1
    80004ae8:	b765                	j	80004a90 <fileread+0x60>
      return -1;
    80004aea:	597d                	li	s2,-1
    80004aec:	b755                	j	80004a90 <fileread+0x60>
    80004aee:	597d                	li	s2,-1
    80004af0:	b745                	j	80004a90 <fileread+0x60>

0000000080004af2 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004af2:	715d                	addi	sp,sp,-80
    80004af4:	e486                	sd	ra,72(sp)
    80004af6:	e0a2                	sd	s0,64(sp)
    80004af8:	fc26                	sd	s1,56(sp)
    80004afa:	f84a                	sd	s2,48(sp)
    80004afc:	f44e                	sd	s3,40(sp)
    80004afe:	f052                	sd	s4,32(sp)
    80004b00:	ec56                	sd	s5,24(sp)
    80004b02:	e85a                	sd	s6,16(sp)
    80004b04:	e45e                	sd	s7,8(sp)
    80004b06:	e062                	sd	s8,0(sp)
    80004b08:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004b0a:	00954783          	lbu	a5,9(a0)
    80004b0e:	10078663          	beqz	a5,80004c1a <filewrite+0x128>
    80004b12:	892a                	mv	s2,a0
    80004b14:	8aae                	mv	s5,a1
    80004b16:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b18:	411c                	lw	a5,0(a0)
    80004b1a:	4705                	li	a4,1
    80004b1c:	02e78263          	beq	a5,a4,80004b40 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b20:	470d                	li	a4,3
    80004b22:	02e78663          	beq	a5,a4,80004b4e <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b26:	4709                	li	a4,2
    80004b28:	0ee79163          	bne	a5,a4,80004c0a <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004b2c:	0ac05d63          	blez	a2,80004be6 <filewrite+0xf4>
    int i = 0;
    80004b30:	4981                	li	s3,0
    80004b32:	6b05                	lui	s6,0x1
    80004b34:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004b38:	6b85                	lui	s7,0x1
    80004b3a:	c00b8b9b          	addiw	s7,s7,-1024
    80004b3e:	a861                	j	80004bd6 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004b40:	6908                	ld	a0,16(a0)
    80004b42:	00000097          	auipc	ra,0x0
    80004b46:	22e080e7          	jalr	558(ra) # 80004d70 <pipewrite>
    80004b4a:	8a2a                	mv	s4,a0
    80004b4c:	a045                	j	80004bec <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004b4e:	02451783          	lh	a5,36(a0)
    80004b52:	03079693          	slli	a3,a5,0x30
    80004b56:	92c1                	srli	a3,a3,0x30
    80004b58:	4725                	li	a4,9
    80004b5a:	0cd76263          	bltu	a4,a3,80004c1e <filewrite+0x12c>
    80004b5e:	0792                	slli	a5,a5,0x4
    80004b60:	0001c717          	auipc	a4,0x1c
    80004b64:	0f870713          	addi	a4,a4,248 # 80020c58 <devsw>
    80004b68:	97ba                	add	a5,a5,a4
    80004b6a:	679c                	ld	a5,8(a5)
    80004b6c:	cbdd                	beqz	a5,80004c22 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004b6e:	4505                	li	a0,1
    80004b70:	9782                	jalr	a5
    80004b72:	8a2a                	mv	s4,a0
    80004b74:	a8a5                	j	80004bec <filewrite+0xfa>
    80004b76:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004b7a:	00000097          	auipc	ra,0x0
    80004b7e:	8b0080e7          	jalr	-1872(ra) # 8000442a <begin_op>
      ilock(f->ip);
    80004b82:	01893503          	ld	a0,24(s2)
    80004b86:	fffff097          	auipc	ra,0xfffff
    80004b8a:	ee2080e7          	jalr	-286(ra) # 80003a68 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004b8e:	8762                	mv	a4,s8
    80004b90:	02092683          	lw	a3,32(s2)
    80004b94:	01598633          	add	a2,s3,s5
    80004b98:	4585                	li	a1,1
    80004b9a:	01893503          	ld	a0,24(s2)
    80004b9e:	fffff097          	auipc	ra,0xfffff
    80004ba2:	276080e7          	jalr	630(ra) # 80003e14 <writei>
    80004ba6:	84aa                	mv	s1,a0
    80004ba8:	00a05763          	blez	a0,80004bb6 <filewrite+0xc4>
        f->off += r;
    80004bac:	02092783          	lw	a5,32(s2)
    80004bb0:	9fa9                	addw	a5,a5,a0
    80004bb2:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004bb6:	01893503          	ld	a0,24(s2)
    80004bba:	fffff097          	auipc	ra,0xfffff
    80004bbe:	f70080e7          	jalr	-144(ra) # 80003b2a <iunlock>
      end_op();
    80004bc2:	00000097          	auipc	ra,0x0
    80004bc6:	8e8080e7          	jalr	-1816(ra) # 800044aa <end_op>

      if(r != n1){
    80004bca:	009c1f63          	bne	s8,s1,80004be8 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004bce:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004bd2:	0149db63          	bge	s3,s4,80004be8 <filewrite+0xf6>
      int n1 = n - i;
    80004bd6:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004bda:	84be                	mv	s1,a5
    80004bdc:	2781                	sext.w	a5,a5
    80004bde:	f8fb5ce3          	bge	s6,a5,80004b76 <filewrite+0x84>
    80004be2:	84de                	mv	s1,s7
    80004be4:	bf49                	j	80004b76 <filewrite+0x84>
    int i = 0;
    80004be6:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004be8:	013a1f63          	bne	s4,s3,80004c06 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004bec:	8552                	mv	a0,s4
    80004bee:	60a6                	ld	ra,72(sp)
    80004bf0:	6406                	ld	s0,64(sp)
    80004bf2:	74e2                	ld	s1,56(sp)
    80004bf4:	7942                	ld	s2,48(sp)
    80004bf6:	79a2                	ld	s3,40(sp)
    80004bf8:	7a02                	ld	s4,32(sp)
    80004bfa:	6ae2                	ld	s5,24(sp)
    80004bfc:	6b42                	ld	s6,16(sp)
    80004bfe:	6ba2                	ld	s7,8(sp)
    80004c00:	6c02                	ld	s8,0(sp)
    80004c02:	6161                	addi	sp,sp,80
    80004c04:	8082                	ret
    ret = (i == n ? n : -1);
    80004c06:	5a7d                	li	s4,-1
    80004c08:	b7d5                	j	80004bec <filewrite+0xfa>
    panic("filewrite");
    80004c0a:	00004517          	auipc	a0,0x4
    80004c0e:	b5e50513          	addi	a0,a0,-1186 # 80008768 <syscalls+0x278>
    80004c12:	ffffc097          	auipc	ra,0xffffc
    80004c16:	92c080e7          	jalr	-1748(ra) # 8000053e <panic>
    return -1;
    80004c1a:	5a7d                	li	s4,-1
    80004c1c:	bfc1                	j	80004bec <filewrite+0xfa>
      return -1;
    80004c1e:	5a7d                	li	s4,-1
    80004c20:	b7f1                	j	80004bec <filewrite+0xfa>
    80004c22:	5a7d                	li	s4,-1
    80004c24:	b7e1                	j	80004bec <filewrite+0xfa>

0000000080004c26 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004c26:	7179                	addi	sp,sp,-48
    80004c28:	f406                	sd	ra,40(sp)
    80004c2a:	f022                	sd	s0,32(sp)
    80004c2c:	ec26                	sd	s1,24(sp)
    80004c2e:	e84a                	sd	s2,16(sp)
    80004c30:	e44e                	sd	s3,8(sp)
    80004c32:	e052                	sd	s4,0(sp)
    80004c34:	1800                	addi	s0,sp,48
    80004c36:	84aa                	mv	s1,a0
    80004c38:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004c3a:	0005b023          	sd	zero,0(a1)
    80004c3e:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004c42:	00000097          	auipc	ra,0x0
    80004c46:	bf8080e7          	jalr	-1032(ra) # 8000483a <filealloc>
    80004c4a:	e088                	sd	a0,0(s1)
    80004c4c:	c551                	beqz	a0,80004cd8 <pipealloc+0xb2>
    80004c4e:	00000097          	auipc	ra,0x0
    80004c52:	bec080e7          	jalr	-1044(ra) # 8000483a <filealloc>
    80004c56:	00aa3023          	sd	a0,0(s4)
    80004c5a:	c92d                	beqz	a0,80004ccc <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004c5c:	ffffc097          	auipc	ra,0xffffc
    80004c60:	e8a080e7          	jalr	-374(ra) # 80000ae6 <kalloc>
    80004c64:	892a                	mv	s2,a0
    80004c66:	c125                	beqz	a0,80004cc6 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004c68:	4985                	li	s3,1
    80004c6a:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004c6e:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004c72:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004c76:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004c7a:	00004597          	auipc	a1,0x4
    80004c7e:	afe58593          	addi	a1,a1,-1282 # 80008778 <syscalls+0x288>
    80004c82:	ffffc097          	auipc	ra,0xffffc
    80004c86:	ec4080e7          	jalr	-316(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004c8a:	609c                	ld	a5,0(s1)
    80004c8c:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004c90:	609c                	ld	a5,0(s1)
    80004c92:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004c96:	609c                	ld	a5,0(s1)
    80004c98:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004c9c:	609c                	ld	a5,0(s1)
    80004c9e:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004ca2:	000a3783          	ld	a5,0(s4)
    80004ca6:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004caa:	000a3783          	ld	a5,0(s4)
    80004cae:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004cb2:	000a3783          	ld	a5,0(s4)
    80004cb6:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004cba:	000a3783          	ld	a5,0(s4)
    80004cbe:	0127b823          	sd	s2,16(a5)
  return 0;
    80004cc2:	4501                	li	a0,0
    80004cc4:	a025                	j	80004cec <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004cc6:	6088                	ld	a0,0(s1)
    80004cc8:	e501                	bnez	a0,80004cd0 <pipealloc+0xaa>
    80004cca:	a039                	j	80004cd8 <pipealloc+0xb2>
    80004ccc:	6088                	ld	a0,0(s1)
    80004cce:	c51d                	beqz	a0,80004cfc <pipealloc+0xd6>
    fileclose(*f0);
    80004cd0:	00000097          	auipc	ra,0x0
    80004cd4:	c26080e7          	jalr	-986(ra) # 800048f6 <fileclose>
  if(*f1)
    80004cd8:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004cdc:	557d                	li	a0,-1
  if(*f1)
    80004cde:	c799                	beqz	a5,80004cec <pipealloc+0xc6>
    fileclose(*f1);
    80004ce0:	853e                	mv	a0,a5
    80004ce2:	00000097          	auipc	ra,0x0
    80004ce6:	c14080e7          	jalr	-1004(ra) # 800048f6 <fileclose>
  return -1;
    80004cea:	557d                	li	a0,-1
}
    80004cec:	70a2                	ld	ra,40(sp)
    80004cee:	7402                	ld	s0,32(sp)
    80004cf0:	64e2                	ld	s1,24(sp)
    80004cf2:	6942                	ld	s2,16(sp)
    80004cf4:	69a2                	ld	s3,8(sp)
    80004cf6:	6a02                	ld	s4,0(sp)
    80004cf8:	6145                	addi	sp,sp,48
    80004cfa:	8082                	ret
  return -1;
    80004cfc:	557d                	li	a0,-1
    80004cfe:	b7fd                	j	80004cec <pipealloc+0xc6>

0000000080004d00 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004d00:	1101                	addi	sp,sp,-32
    80004d02:	ec06                	sd	ra,24(sp)
    80004d04:	e822                	sd	s0,16(sp)
    80004d06:	e426                	sd	s1,8(sp)
    80004d08:	e04a                	sd	s2,0(sp)
    80004d0a:	1000                	addi	s0,sp,32
    80004d0c:	84aa                	mv	s1,a0
    80004d0e:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004d10:	ffffc097          	auipc	ra,0xffffc
    80004d14:	ec6080e7          	jalr	-314(ra) # 80000bd6 <acquire>
  if(writable){
    80004d18:	02090d63          	beqz	s2,80004d52 <pipeclose+0x52>
    pi->writeopen = 0;
    80004d1c:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004d20:	21848513          	addi	a0,s1,536
    80004d24:	ffffd097          	auipc	ra,0xffffd
    80004d28:	688080e7          	jalr	1672(ra) # 800023ac <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004d2c:	2204b783          	ld	a5,544(s1)
    80004d30:	eb95                	bnez	a5,80004d64 <pipeclose+0x64>
    release(&pi->lock);
    80004d32:	8526                	mv	a0,s1
    80004d34:	ffffc097          	auipc	ra,0xffffc
    80004d38:	f56080e7          	jalr	-170(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004d3c:	8526                	mv	a0,s1
    80004d3e:	ffffc097          	auipc	ra,0xffffc
    80004d42:	cac080e7          	jalr	-852(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    80004d46:	60e2                	ld	ra,24(sp)
    80004d48:	6442                	ld	s0,16(sp)
    80004d4a:	64a2                	ld	s1,8(sp)
    80004d4c:	6902                	ld	s2,0(sp)
    80004d4e:	6105                	addi	sp,sp,32
    80004d50:	8082                	ret
    pi->readopen = 0;
    80004d52:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004d56:	21c48513          	addi	a0,s1,540
    80004d5a:	ffffd097          	auipc	ra,0xffffd
    80004d5e:	652080e7          	jalr	1618(ra) # 800023ac <wakeup>
    80004d62:	b7e9                	j	80004d2c <pipeclose+0x2c>
    release(&pi->lock);
    80004d64:	8526                	mv	a0,s1
    80004d66:	ffffc097          	auipc	ra,0xffffc
    80004d6a:	f24080e7          	jalr	-220(ra) # 80000c8a <release>
}
    80004d6e:	bfe1                	j	80004d46 <pipeclose+0x46>

0000000080004d70 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004d70:	711d                	addi	sp,sp,-96
    80004d72:	ec86                	sd	ra,88(sp)
    80004d74:	e8a2                	sd	s0,80(sp)
    80004d76:	e4a6                	sd	s1,72(sp)
    80004d78:	e0ca                	sd	s2,64(sp)
    80004d7a:	fc4e                	sd	s3,56(sp)
    80004d7c:	f852                	sd	s4,48(sp)
    80004d7e:	f456                	sd	s5,40(sp)
    80004d80:	f05a                	sd	s6,32(sp)
    80004d82:	ec5e                	sd	s7,24(sp)
    80004d84:	e862                	sd	s8,16(sp)
    80004d86:	1080                	addi	s0,sp,96
    80004d88:	84aa                	mv	s1,a0
    80004d8a:	8aae                	mv	s5,a1
    80004d8c:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004d8e:	ffffd097          	auipc	ra,0xffffd
    80004d92:	f12080e7          	jalr	-238(ra) # 80001ca0 <myproc>
    80004d96:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004d98:	8526                	mv	a0,s1
    80004d9a:	ffffc097          	auipc	ra,0xffffc
    80004d9e:	e3c080e7          	jalr	-452(ra) # 80000bd6 <acquire>
  while(i < n){
    80004da2:	0b405663          	blez	s4,80004e4e <pipewrite+0xde>
  int i = 0;
    80004da6:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004da8:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004daa:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004dae:	21c48b93          	addi	s7,s1,540
    80004db2:	a089                	j	80004df4 <pipewrite+0x84>
      release(&pi->lock);
    80004db4:	8526                	mv	a0,s1
    80004db6:	ffffc097          	auipc	ra,0xffffc
    80004dba:	ed4080e7          	jalr	-300(ra) # 80000c8a <release>
      return -1;
    80004dbe:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004dc0:	854a                	mv	a0,s2
    80004dc2:	60e6                	ld	ra,88(sp)
    80004dc4:	6446                	ld	s0,80(sp)
    80004dc6:	64a6                	ld	s1,72(sp)
    80004dc8:	6906                	ld	s2,64(sp)
    80004dca:	79e2                	ld	s3,56(sp)
    80004dcc:	7a42                	ld	s4,48(sp)
    80004dce:	7aa2                	ld	s5,40(sp)
    80004dd0:	7b02                	ld	s6,32(sp)
    80004dd2:	6be2                	ld	s7,24(sp)
    80004dd4:	6c42                	ld	s8,16(sp)
    80004dd6:	6125                	addi	sp,sp,96
    80004dd8:	8082                	ret
      wakeup(&pi->nread);
    80004dda:	8562                	mv	a0,s8
    80004ddc:	ffffd097          	auipc	ra,0xffffd
    80004de0:	5d0080e7          	jalr	1488(ra) # 800023ac <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004de4:	85a6                	mv	a1,s1
    80004de6:	855e                	mv	a0,s7
    80004de8:	ffffd097          	auipc	ra,0xffffd
    80004dec:	560080e7          	jalr	1376(ra) # 80002348 <sleep>
  while(i < n){
    80004df0:	07495063          	bge	s2,s4,80004e50 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004df4:	2204a783          	lw	a5,544(s1)
    80004df8:	dfd5                	beqz	a5,80004db4 <pipewrite+0x44>
    80004dfa:	854e                	mv	a0,s3
    80004dfc:	ffffd097          	auipc	ra,0xffffd
    80004e00:	7f4080e7          	jalr	2036(ra) # 800025f0 <killed>
    80004e04:	f945                	bnez	a0,80004db4 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004e06:	2184a783          	lw	a5,536(s1)
    80004e0a:	21c4a703          	lw	a4,540(s1)
    80004e0e:	2007879b          	addiw	a5,a5,512
    80004e12:	fcf704e3          	beq	a4,a5,80004dda <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004e16:	4685                	li	a3,1
    80004e18:	01590633          	add	a2,s2,s5
    80004e1c:	faf40593          	addi	a1,s0,-81
    80004e20:	0509b503          	ld	a0,80(s3)
    80004e24:	ffffd097          	auipc	ra,0xffffd
    80004e28:	8d8080e7          	jalr	-1832(ra) # 800016fc <copyin>
    80004e2c:	03650263          	beq	a0,s6,80004e50 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004e30:	21c4a783          	lw	a5,540(s1)
    80004e34:	0017871b          	addiw	a4,a5,1
    80004e38:	20e4ae23          	sw	a4,540(s1)
    80004e3c:	1ff7f793          	andi	a5,a5,511
    80004e40:	97a6                	add	a5,a5,s1
    80004e42:	faf44703          	lbu	a4,-81(s0)
    80004e46:	00e78c23          	sb	a4,24(a5)
      i++;
    80004e4a:	2905                	addiw	s2,s2,1
    80004e4c:	b755                	j	80004df0 <pipewrite+0x80>
  int i = 0;
    80004e4e:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004e50:	21848513          	addi	a0,s1,536
    80004e54:	ffffd097          	auipc	ra,0xffffd
    80004e58:	558080e7          	jalr	1368(ra) # 800023ac <wakeup>
  release(&pi->lock);
    80004e5c:	8526                	mv	a0,s1
    80004e5e:	ffffc097          	auipc	ra,0xffffc
    80004e62:	e2c080e7          	jalr	-468(ra) # 80000c8a <release>
  return i;
    80004e66:	bfa9                	j	80004dc0 <pipewrite+0x50>

0000000080004e68 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004e68:	715d                	addi	sp,sp,-80
    80004e6a:	e486                	sd	ra,72(sp)
    80004e6c:	e0a2                	sd	s0,64(sp)
    80004e6e:	fc26                	sd	s1,56(sp)
    80004e70:	f84a                	sd	s2,48(sp)
    80004e72:	f44e                	sd	s3,40(sp)
    80004e74:	f052                	sd	s4,32(sp)
    80004e76:	ec56                	sd	s5,24(sp)
    80004e78:	e85a                	sd	s6,16(sp)
    80004e7a:	0880                	addi	s0,sp,80
    80004e7c:	84aa                	mv	s1,a0
    80004e7e:	892e                	mv	s2,a1
    80004e80:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004e82:	ffffd097          	auipc	ra,0xffffd
    80004e86:	e1e080e7          	jalr	-482(ra) # 80001ca0 <myproc>
    80004e8a:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004e8c:	8526                	mv	a0,s1
    80004e8e:	ffffc097          	auipc	ra,0xffffc
    80004e92:	d48080e7          	jalr	-696(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e96:	2184a703          	lw	a4,536(s1)
    80004e9a:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e9e:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ea2:	02f71763          	bne	a4,a5,80004ed0 <piperead+0x68>
    80004ea6:	2244a783          	lw	a5,548(s1)
    80004eaa:	c39d                	beqz	a5,80004ed0 <piperead+0x68>
    if(killed(pr)){
    80004eac:	8552                	mv	a0,s4
    80004eae:	ffffd097          	auipc	ra,0xffffd
    80004eb2:	742080e7          	jalr	1858(ra) # 800025f0 <killed>
    80004eb6:	e941                	bnez	a0,80004f46 <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004eb8:	85a6                	mv	a1,s1
    80004eba:	854e                	mv	a0,s3
    80004ebc:	ffffd097          	auipc	ra,0xffffd
    80004ec0:	48c080e7          	jalr	1164(ra) # 80002348 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ec4:	2184a703          	lw	a4,536(s1)
    80004ec8:	21c4a783          	lw	a5,540(s1)
    80004ecc:	fcf70de3          	beq	a4,a5,80004ea6 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ed0:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ed2:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ed4:	05505363          	blez	s5,80004f1a <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    80004ed8:	2184a783          	lw	a5,536(s1)
    80004edc:	21c4a703          	lw	a4,540(s1)
    80004ee0:	02f70d63          	beq	a4,a5,80004f1a <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004ee4:	0017871b          	addiw	a4,a5,1
    80004ee8:	20e4ac23          	sw	a4,536(s1)
    80004eec:	1ff7f793          	andi	a5,a5,511
    80004ef0:	97a6                	add	a5,a5,s1
    80004ef2:	0187c783          	lbu	a5,24(a5)
    80004ef6:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004efa:	4685                	li	a3,1
    80004efc:	fbf40613          	addi	a2,s0,-65
    80004f00:	85ca                	mv	a1,s2
    80004f02:	050a3503          	ld	a0,80(s4)
    80004f06:	ffffc097          	auipc	ra,0xffffc
    80004f0a:	76a080e7          	jalr	1898(ra) # 80001670 <copyout>
    80004f0e:	01650663          	beq	a0,s6,80004f1a <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f12:	2985                	addiw	s3,s3,1
    80004f14:	0905                	addi	s2,s2,1
    80004f16:	fd3a91e3          	bne	s5,s3,80004ed8 <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004f1a:	21c48513          	addi	a0,s1,540
    80004f1e:	ffffd097          	auipc	ra,0xffffd
    80004f22:	48e080e7          	jalr	1166(ra) # 800023ac <wakeup>
  release(&pi->lock);
    80004f26:	8526                	mv	a0,s1
    80004f28:	ffffc097          	auipc	ra,0xffffc
    80004f2c:	d62080e7          	jalr	-670(ra) # 80000c8a <release>
  return i;
}
    80004f30:	854e                	mv	a0,s3
    80004f32:	60a6                	ld	ra,72(sp)
    80004f34:	6406                	ld	s0,64(sp)
    80004f36:	74e2                	ld	s1,56(sp)
    80004f38:	7942                	ld	s2,48(sp)
    80004f3a:	79a2                	ld	s3,40(sp)
    80004f3c:	7a02                	ld	s4,32(sp)
    80004f3e:	6ae2                	ld	s5,24(sp)
    80004f40:	6b42                	ld	s6,16(sp)
    80004f42:	6161                	addi	sp,sp,80
    80004f44:	8082                	ret
      release(&pi->lock);
    80004f46:	8526                	mv	a0,s1
    80004f48:	ffffc097          	auipc	ra,0xffffc
    80004f4c:	d42080e7          	jalr	-702(ra) # 80000c8a <release>
      return -1;
    80004f50:	59fd                	li	s3,-1
    80004f52:	bff9                	j	80004f30 <piperead+0xc8>

0000000080004f54 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004f54:	1141                	addi	sp,sp,-16
    80004f56:	e422                	sd	s0,8(sp)
    80004f58:	0800                	addi	s0,sp,16
    80004f5a:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004f5c:	8905                	andi	a0,a0,1
    80004f5e:	c111                	beqz	a0,80004f62 <flags2perm+0xe>
      perm = PTE_X;
    80004f60:	4521                	li	a0,8
    if(flags & 0x2)
    80004f62:	8b89                	andi	a5,a5,2
    80004f64:	c399                	beqz	a5,80004f6a <flags2perm+0x16>
      perm |= PTE_W;
    80004f66:	00456513          	ori	a0,a0,4
    return perm;
}
    80004f6a:	6422                	ld	s0,8(sp)
    80004f6c:	0141                	addi	sp,sp,16
    80004f6e:	8082                	ret

0000000080004f70 <exec>:

int
exec(char *path, char **argv)
{
    80004f70:	de010113          	addi	sp,sp,-544
    80004f74:	20113c23          	sd	ra,536(sp)
    80004f78:	20813823          	sd	s0,528(sp)
    80004f7c:	20913423          	sd	s1,520(sp)
    80004f80:	21213023          	sd	s2,512(sp)
    80004f84:	ffce                	sd	s3,504(sp)
    80004f86:	fbd2                	sd	s4,496(sp)
    80004f88:	f7d6                	sd	s5,488(sp)
    80004f8a:	f3da                	sd	s6,480(sp)
    80004f8c:	efde                	sd	s7,472(sp)
    80004f8e:	ebe2                	sd	s8,464(sp)
    80004f90:	e7e6                	sd	s9,456(sp)
    80004f92:	e3ea                	sd	s10,448(sp)
    80004f94:	ff6e                	sd	s11,440(sp)
    80004f96:	1400                	addi	s0,sp,544
    80004f98:	892a                	mv	s2,a0
    80004f9a:	dea43423          	sd	a0,-536(s0)
    80004f9e:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004fa2:	ffffd097          	auipc	ra,0xffffd
    80004fa6:	cfe080e7          	jalr	-770(ra) # 80001ca0 <myproc>
    80004faa:	84aa                	mv	s1,a0

  begin_op();
    80004fac:	fffff097          	auipc	ra,0xfffff
    80004fb0:	47e080e7          	jalr	1150(ra) # 8000442a <begin_op>

  if((ip = namei(path)) == 0){
    80004fb4:	854a                	mv	a0,s2
    80004fb6:	fffff097          	auipc	ra,0xfffff
    80004fba:	258080e7          	jalr	600(ra) # 8000420e <namei>
    80004fbe:	c93d                	beqz	a0,80005034 <exec+0xc4>
    80004fc0:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004fc2:	fffff097          	auipc	ra,0xfffff
    80004fc6:	aa6080e7          	jalr	-1370(ra) # 80003a68 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004fca:	04000713          	li	a4,64
    80004fce:	4681                	li	a3,0
    80004fd0:	e5040613          	addi	a2,s0,-432
    80004fd4:	4581                	li	a1,0
    80004fd6:	8556                	mv	a0,s5
    80004fd8:	fffff097          	auipc	ra,0xfffff
    80004fdc:	d44080e7          	jalr	-700(ra) # 80003d1c <readi>
    80004fe0:	04000793          	li	a5,64
    80004fe4:	00f51a63          	bne	a0,a5,80004ff8 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004fe8:	e5042703          	lw	a4,-432(s0)
    80004fec:	464c47b7          	lui	a5,0x464c4
    80004ff0:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004ff4:	04f70663          	beq	a4,a5,80005040 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004ff8:	8556                	mv	a0,s5
    80004ffa:	fffff097          	auipc	ra,0xfffff
    80004ffe:	cd0080e7          	jalr	-816(ra) # 80003cca <iunlockput>
    end_op();
    80005002:	fffff097          	auipc	ra,0xfffff
    80005006:	4a8080e7          	jalr	1192(ra) # 800044aa <end_op>
  }
  return -1;
    8000500a:	557d                	li	a0,-1
}
    8000500c:	21813083          	ld	ra,536(sp)
    80005010:	21013403          	ld	s0,528(sp)
    80005014:	20813483          	ld	s1,520(sp)
    80005018:	20013903          	ld	s2,512(sp)
    8000501c:	79fe                	ld	s3,504(sp)
    8000501e:	7a5e                	ld	s4,496(sp)
    80005020:	7abe                	ld	s5,488(sp)
    80005022:	7b1e                	ld	s6,480(sp)
    80005024:	6bfe                	ld	s7,472(sp)
    80005026:	6c5e                	ld	s8,464(sp)
    80005028:	6cbe                	ld	s9,456(sp)
    8000502a:	6d1e                	ld	s10,448(sp)
    8000502c:	7dfa                	ld	s11,440(sp)
    8000502e:	22010113          	addi	sp,sp,544
    80005032:	8082                	ret
    end_op();
    80005034:	fffff097          	auipc	ra,0xfffff
    80005038:	476080e7          	jalr	1142(ra) # 800044aa <end_op>
    return -1;
    8000503c:	557d                	li	a0,-1
    8000503e:	b7f9                	j	8000500c <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80005040:	8526                	mv	a0,s1
    80005042:	ffffd097          	auipc	ra,0xffffd
    80005046:	d22080e7          	jalr	-734(ra) # 80001d64 <proc_pagetable>
    8000504a:	8b2a                	mv	s6,a0
    8000504c:	d555                	beqz	a0,80004ff8 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000504e:	e7042783          	lw	a5,-400(s0)
    80005052:	e8845703          	lhu	a4,-376(s0)
    80005056:	c735                	beqz	a4,800050c2 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005058:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000505a:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    8000505e:	6a05                	lui	s4,0x1
    80005060:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80005064:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80005068:	6d85                	lui	s11,0x1
    8000506a:	7d7d                	lui	s10,0xfffff
    8000506c:	a481                	j	800052ac <exec+0x33c>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    8000506e:	00003517          	auipc	a0,0x3
    80005072:	71250513          	addi	a0,a0,1810 # 80008780 <syscalls+0x290>
    80005076:	ffffb097          	auipc	ra,0xffffb
    8000507a:	4c8080e7          	jalr	1224(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000507e:	874a                	mv	a4,s2
    80005080:	009c86bb          	addw	a3,s9,s1
    80005084:	4581                	li	a1,0
    80005086:	8556                	mv	a0,s5
    80005088:	fffff097          	auipc	ra,0xfffff
    8000508c:	c94080e7          	jalr	-876(ra) # 80003d1c <readi>
    80005090:	2501                	sext.w	a0,a0
    80005092:	1aa91a63          	bne	s2,a0,80005246 <exec+0x2d6>
  for(i = 0; i < sz; i += PGSIZE){
    80005096:	009d84bb          	addw	s1,s11,s1
    8000509a:	013d09bb          	addw	s3,s10,s3
    8000509e:	1f74f763          	bgeu	s1,s7,8000528c <exec+0x31c>
    pa = walkaddr(pagetable, va + i);
    800050a2:	02049593          	slli	a1,s1,0x20
    800050a6:	9181                	srli	a1,a1,0x20
    800050a8:	95e2                	add	a1,a1,s8
    800050aa:	855a                	mv	a0,s6
    800050ac:	ffffc097          	auipc	ra,0xffffc
    800050b0:	fb0080e7          	jalr	-80(ra) # 8000105c <walkaddr>
    800050b4:	862a                	mv	a2,a0
    if(pa == 0)
    800050b6:	dd45                	beqz	a0,8000506e <exec+0xfe>
      n = PGSIZE;
    800050b8:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    800050ba:	fd49f2e3          	bgeu	s3,s4,8000507e <exec+0x10e>
      n = sz - i;
    800050be:	894e                	mv	s2,s3
    800050c0:	bf7d                	j	8000507e <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800050c2:	4901                	li	s2,0
  iunlockput(ip);
    800050c4:	8556                	mv	a0,s5
    800050c6:	fffff097          	auipc	ra,0xfffff
    800050ca:	c04080e7          	jalr	-1020(ra) # 80003cca <iunlockput>
  end_op();
    800050ce:	fffff097          	auipc	ra,0xfffff
    800050d2:	3dc080e7          	jalr	988(ra) # 800044aa <end_op>
  p = myproc();
    800050d6:	ffffd097          	auipc	ra,0xffffd
    800050da:	bca080e7          	jalr	-1078(ra) # 80001ca0 <myproc>
    800050de:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    800050e0:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    800050e4:	6785                	lui	a5,0x1
    800050e6:	17fd                	addi	a5,a5,-1
    800050e8:	993e                	add	s2,s2,a5
    800050ea:	77fd                	lui	a5,0xfffff
    800050ec:	00f977b3          	and	a5,s2,a5
    800050f0:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800050f4:	4691                	li	a3,4
    800050f6:	6609                	lui	a2,0x2
    800050f8:	963e                	add	a2,a2,a5
    800050fa:	85be                	mv	a1,a5
    800050fc:	855a                	mv	a0,s6
    800050fe:	ffffc097          	auipc	ra,0xffffc
    80005102:	31a080e7          	jalr	794(ra) # 80001418 <uvmalloc>
    80005106:	8c2a                	mv	s8,a0
  ip = 0;
    80005108:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    8000510a:	12050e63          	beqz	a0,80005246 <exec+0x2d6>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000510e:	75f9                	lui	a1,0xffffe
    80005110:	95aa                	add	a1,a1,a0
    80005112:	855a                	mv	a0,s6
    80005114:	ffffc097          	auipc	ra,0xffffc
    80005118:	52a080e7          	jalr	1322(ra) # 8000163e <uvmclear>
  stackbase = sp - PGSIZE;
    8000511c:	7afd                	lui	s5,0xfffff
    8000511e:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80005120:	df043783          	ld	a5,-528(s0)
    80005124:	6388                	ld	a0,0(a5)
    80005126:	c925                	beqz	a0,80005196 <exec+0x226>
    80005128:	e9040993          	addi	s3,s0,-368
    8000512c:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005130:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005132:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005134:	ffffc097          	auipc	ra,0xffffc
    80005138:	d1a080e7          	jalr	-742(ra) # 80000e4e <strlen>
    8000513c:	0015079b          	addiw	a5,a0,1
    80005140:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005144:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005148:	13596663          	bltu	s2,s5,80005274 <exec+0x304>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000514c:	df043d83          	ld	s11,-528(s0)
    80005150:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80005154:	8552                	mv	a0,s4
    80005156:	ffffc097          	auipc	ra,0xffffc
    8000515a:	cf8080e7          	jalr	-776(ra) # 80000e4e <strlen>
    8000515e:	0015069b          	addiw	a3,a0,1
    80005162:	8652                	mv	a2,s4
    80005164:	85ca                	mv	a1,s2
    80005166:	855a                	mv	a0,s6
    80005168:	ffffc097          	auipc	ra,0xffffc
    8000516c:	508080e7          	jalr	1288(ra) # 80001670 <copyout>
    80005170:	10054663          	bltz	a0,8000527c <exec+0x30c>
    ustack[argc] = sp;
    80005174:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005178:	0485                	addi	s1,s1,1
    8000517a:	008d8793          	addi	a5,s11,8
    8000517e:	def43823          	sd	a5,-528(s0)
    80005182:	008db503          	ld	a0,8(s11)
    80005186:	c911                	beqz	a0,8000519a <exec+0x22a>
    if(argc >= MAXARG)
    80005188:	09a1                	addi	s3,s3,8
    8000518a:	fb3c95e3          	bne	s9,s3,80005134 <exec+0x1c4>
  sz = sz1;
    8000518e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005192:	4a81                	li	s5,0
    80005194:	a84d                	j	80005246 <exec+0x2d6>
  sp = sz;
    80005196:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005198:	4481                	li	s1,0
  ustack[argc] = 0;
    8000519a:	00349793          	slli	a5,s1,0x3
    8000519e:	f9040713          	addi	a4,s0,-112
    800051a2:	97ba                	add	a5,a5,a4
    800051a4:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffdd110>
  sp -= (argc+1) * sizeof(uint64);
    800051a8:	00148693          	addi	a3,s1,1
    800051ac:	068e                	slli	a3,a3,0x3
    800051ae:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800051b2:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800051b6:	01597663          	bgeu	s2,s5,800051c2 <exec+0x252>
  sz = sz1;
    800051ba:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800051be:	4a81                	li	s5,0
    800051c0:	a059                	j	80005246 <exec+0x2d6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800051c2:	e9040613          	addi	a2,s0,-368
    800051c6:	85ca                	mv	a1,s2
    800051c8:	855a                	mv	a0,s6
    800051ca:	ffffc097          	auipc	ra,0xffffc
    800051ce:	4a6080e7          	jalr	1190(ra) # 80001670 <copyout>
    800051d2:	0a054963          	bltz	a0,80005284 <exec+0x314>
  p->trapframe->a1 = sp;
    800051d6:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    800051da:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800051de:	de843783          	ld	a5,-536(s0)
    800051e2:	0007c703          	lbu	a4,0(a5)
    800051e6:	cf11                	beqz	a4,80005202 <exec+0x292>
    800051e8:	0785                	addi	a5,a5,1
    if(*s == '/')
    800051ea:	02f00693          	li	a3,47
    800051ee:	a039                	j	800051fc <exec+0x28c>
      last = s+1;
    800051f0:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    800051f4:	0785                	addi	a5,a5,1
    800051f6:	fff7c703          	lbu	a4,-1(a5)
    800051fa:	c701                	beqz	a4,80005202 <exec+0x292>
    if(*s == '/')
    800051fc:	fed71ce3          	bne	a4,a3,800051f4 <exec+0x284>
    80005200:	bfc5                	j	800051f0 <exec+0x280>
  safestrcpy(p->name, last, sizeof(p->name));
    80005202:	4641                	li	a2,16
    80005204:	de843583          	ld	a1,-536(s0)
    80005208:	158b8513          	addi	a0,s7,344
    8000520c:	ffffc097          	auipc	ra,0xffffc
    80005210:	c10080e7          	jalr	-1008(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    80005214:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80005218:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    8000521c:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005220:	058bb783          	ld	a5,88(s7)
    80005224:	e6843703          	ld	a4,-408(s0)
    80005228:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000522a:	058bb783          	ld	a5,88(s7)
    8000522e:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005232:	85ea                	mv	a1,s10
    80005234:	ffffd097          	auipc	ra,0xffffd
    80005238:	bcc080e7          	jalr	-1076(ra) # 80001e00 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000523c:	0004851b          	sext.w	a0,s1
    80005240:	b3f1                	j	8000500c <exec+0x9c>
    80005242:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005246:	df843583          	ld	a1,-520(s0)
    8000524a:	855a                	mv	a0,s6
    8000524c:	ffffd097          	auipc	ra,0xffffd
    80005250:	bb4080e7          	jalr	-1100(ra) # 80001e00 <proc_freepagetable>
  if(ip){
    80005254:	da0a92e3          	bnez	s5,80004ff8 <exec+0x88>
  return -1;
    80005258:	557d                	li	a0,-1
    8000525a:	bb4d                	j	8000500c <exec+0x9c>
    8000525c:	df243c23          	sd	s2,-520(s0)
    80005260:	b7dd                	j	80005246 <exec+0x2d6>
    80005262:	df243c23          	sd	s2,-520(s0)
    80005266:	b7c5                	j	80005246 <exec+0x2d6>
    80005268:	df243c23          	sd	s2,-520(s0)
    8000526c:	bfe9                	j	80005246 <exec+0x2d6>
    8000526e:	df243c23          	sd	s2,-520(s0)
    80005272:	bfd1                	j	80005246 <exec+0x2d6>
  sz = sz1;
    80005274:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005278:	4a81                	li	s5,0
    8000527a:	b7f1                	j	80005246 <exec+0x2d6>
  sz = sz1;
    8000527c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005280:	4a81                	li	s5,0
    80005282:	b7d1                	j	80005246 <exec+0x2d6>
  sz = sz1;
    80005284:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005288:	4a81                	li	s5,0
    8000528a:	bf75                	j	80005246 <exec+0x2d6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000528c:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005290:	e0843783          	ld	a5,-504(s0)
    80005294:	0017869b          	addiw	a3,a5,1
    80005298:	e0d43423          	sd	a3,-504(s0)
    8000529c:	e0043783          	ld	a5,-512(s0)
    800052a0:	0387879b          	addiw	a5,a5,56
    800052a4:	e8845703          	lhu	a4,-376(s0)
    800052a8:	e0e6dee3          	bge	a3,a4,800050c4 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800052ac:	2781                	sext.w	a5,a5
    800052ae:	e0f43023          	sd	a5,-512(s0)
    800052b2:	03800713          	li	a4,56
    800052b6:	86be                	mv	a3,a5
    800052b8:	e1840613          	addi	a2,s0,-488
    800052bc:	4581                	li	a1,0
    800052be:	8556                	mv	a0,s5
    800052c0:	fffff097          	auipc	ra,0xfffff
    800052c4:	a5c080e7          	jalr	-1444(ra) # 80003d1c <readi>
    800052c8:	03800793          	li	a5,56
    800052cc:	f6f51be3          	bne	a0,a5,80005242 <exec+0x2d2>
    if(ph.type != ELF_PROG_LOAD)
    800052d0:	e1842783          	lw	a5,-488(s0)
    800052d4:	4705                	li	a4,1
    800052d6:	fae79de3          	bne	a5,a4,80005290 <exec+0x320>
    if(ph.memsz < ph.filesz)
    800052da:	e4043483          	ld	s1,-448(s0)
    800052de:	e3843783          	ld	a5,-456(s0)
    800052e2:	f6f4ede3          	bltu	s1,a5,8000525c <exec+0x2ec>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800052e6:	e2843783          	ld	a5,-472(s0)
    800052ea:	94be                	add	s1,s1,a5
    800052ec:	f6f4ebe3          	bltu	s1,a5,80005262 <exec+0x2f2>
    if(ph.vaddr % PGSIZE != 0)
    800052f0:	de043703          	ld	a4,-544(s0)
    800052f4:	8ff9                	and	a5,a5,a4
    800052f6:	fbad                	bnez	a5,80005268 <exec+0x2f8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800052f8:	e1c42503          	lw	a0,-484(s0)
    800052fc:	00000097          	auipc	ra,0x0
    80005300:	c58080e7          	jalr	-936(ra) # 80004f54 <flags2perm>
    80005304:	86aa                	mv	a3,a0
    80005306:	8626                	mv	a2,s1
    80005308:	85ca                	mv	a1,s2
    8000530a:	855a                	mv	a0,s6
    8000530c:	ffffc097          	auipc	ra,0xffffc
    80005310:	10c080e7          	jalr	268(ra) # 80001418 <uvmalloc>
    80005314:	dea43c23          	sd	a0,-520(s0)
    80005318:	d939                	beqz	a0,8000526e <exec+0x2fe>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000531a:	e2843c03          	ld	s8,-472(s0)
    8000531e:	e2042c83          	lw	s9,-480(s0)
    80005322:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005326:	f60b83e3          	beqz	s7,8000528c <exec+0x31c>
    8000532a:	89de                	mv	s3,s7
    8000532c:	4481                	li	s1,0
    8000532e:	bb95                	j	800050a2 <exec+0x132>

0000000080005330 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005330:	7179                	addi	sp,sp,-48
    80005332:	f406                	sd	ra,40(sp)
    80005334:	f022                	sd	s0,32(sp)
    80005336:	ec26                	sd	s1,24(sp)
    80005338:	e84a                	sd	s2,16(sp)
    8000533a:	1800                	addi	s0,sp,48
    8000533c:	892e                	mv	s2,a1
    8000533e:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005340:	fdc40593          	addi	a1,s0,-36
    80005344:	ffffe097          	auipc	ra,0xffffe
    80005348:	a8a080e7          	jalr	-1398(ra) # 80002dce <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000534c:	fdc42703          	lw	a4,-36(s0)
    80005350:	47bd                	li	a5,15
    80005352:	02e7eb63          	bltu	a5,a4,80005388 <argfd+0x58>
    80005356:	ffffd097          	auipc	ra,0xffffd
    8000535a:	94a080e7          	jalr	-1718(ra) # 80001ca0 <myproc>
    8000535e:	fdc42703          	lw	a4,-36(s0)
    80005362:	01a70793          	addi	a5,a4,26
    80005366:	078e                	slli	a5,a5,0x3
    80005368:	953e                	add	a0,a0,a5
    8000536a:	611c                	ld	a5,0(a0)
    8000536c:	c385                	beqz	a5,8000538c <argfd+0x5c>
    return -1;
  if(pfd)
    8000536e:	00090463          	beqz	s2,80005376 <argfd+0x46>
    *pfd = fd;
    80005372:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005376:	4501                	li	a0,0
  if(pf)
    80005378:	c091                	beqz	s1,8000537c <argfd+0x4c>
    *pf = f;
    8000537a:	e09c                	sd	a5,0(s1)
}
    8000537c:	70a2                	ld	ra,40(sp)
    8000537e:	7402                	ld	s0,32(sp)
    80005380:	64e2                	ld	s1,24(sp)
    80005382:	6942                	ld	s2,16(sp)
    80005384:	6145                	addi	sp,sp,48
    80005386:	8082                	ret
    return -1;
    80005388:	557d                	li	a0,-1
    8000538a:	bfcd                	j	8000537c <argfd+0x4c>
    8000538c:	557d                	li	a0,-1
    8000538e:	b7fd                	j	8000537c <argfd+0x4c>

0000000080005390 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005390:	1101                	addi	sp,sp,-32
    80005392:	ec06                	sd	ra,24(sp)
    80005394:	e822                	sd	s0,16(sp)
    80005396:	e426                	sd	s1,8(sp)
    80005398:	1000                	addi	s0,sp,32
    8000539a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000539c:	ffffd097          	auipc	ra,0xffffd
    800053a0:	904080e7          	jalr	-1788(ra) # 80001ca0 <myproc>
    800053a4:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800053a6:	0d050793          	addi	a5,a0,208
    800053aa:	4501                	li	a0,0
    800053ac:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800053ae:	6398                	ld	a4,0(a5)
    800053b0:	cb19                	beqz	a4,800053c6 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800053b2:	2505                	addiw	a0,a0,1
    800053b4:	07a1                	addi	a5,a5,8
    800053b6:	fed51ce3          	bne	a0,a3,800053ae <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800053ba:	557d                	li	a0,-1
}
    800053bc:	60e2                	ld	ra,24(sp)
    800053be:	6442                	ld	s0,16(sp)
    800053c0:	64a2                	ld	s1,8(sp)
    800053c2:	6105                	addi	sp,sp,32
    800053c4:	8082                	ret
      p->ofile[fd] = f;
    800053c6:	01a50793          	addi	a5,a0,26
    800053ca:	078e                	slli	a5,a5,0x3
    800053cc:	963e                	add	a2,a2,a5
    800053ce:	e204                	sd	s1,0(a2)
      return fd;
    800053d0:	b7f5                	j	800053bc <fdalloc+0x2c>

00000000800053d2 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800053d2:	715d                	addi	sp,sp,-80
    800053d4:	e486                	sd	ra,72(sp)
    800053d6:	e0a2                	sd	s0,64(sp)
    800053d8:	fc26                	sd	s1,56(sp)
    800053da:	f84a                	sd	s2,48(sp)
    800053dc:	f44e                	sd	s3,40(sp)
    800053de:	f052                	sd	s4,32(sp)
    800053e0:	ec56                	sd	s5,24(sp)
    800053e2:	e85a                	sd	s6,16(sp)
    800053e4:	0880                	addi	s0,sp,80
    800053e6:	8b2e                	mv	s6,a1
    800053e8:	89b2                	mv	s3,a2
    800053ea:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800053ec:	fb040593          	addi	a1,s0,-80
    800053f0:	fffff097          	auipc	ra,0xfffff
    800053f4:	e3c080e7          	jalr	-452(ra) # 8000422c <nameiparent>
    800053f8:	84aa                	mv	s1,a0
    800053fa:	14050f63          	beqz	a0,80005558 <create+0x186>
    return 0;

  ilock(dp);
    800053fe:	ffffe097          	auipc	ra,0xffffe
    80005402:	66a080e7          	jalr	1642(ra) # 80003a68 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005406:	4601                	li	a2,0
    80005408:	fb040593          	addi	a1,s0,-80
    8000540c:	8526                	mv	a0,s1
    8000540e:	fffff097          	auipc	ra,0xfffff
    80005412:	b3e080e7          	jalr	-1218(ra) # 80003f4c <dirlookup>
    80005416:	8aaa                	mv	s5,a0
    80005418:	c931                	beqz	a0,8000546c <create+0x9a>
    iunlockput(dp);
    8000541a:	8526                	mv	a0,s1
    8000541c:	fffff097          	auipc	ra,0xfffff
    80005420:	8ae080e7          	jalr	-1874(ra) # 80003cca <iunlockput>
    ilock(ip);
    80005424:	8556                	mv	a0,s5
    80005426:	ffffe097          	auipc	ra,0xffffe
    8000542a:	642080e7          	jalr	1602(ra) # 80003a68 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000542e:	000b059b          	sext.w	a1,s6
    80005432:	4789                	li	a5,2
    80005434:	02f59563          	bne	a1,a5,8000545e <create+0x8c>
    80005438:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdd254>
    8000543c:	37f9                	addiw	a5,a5,-2
    8000543e:	17c2                	slli	a5,a5,0x30
    80005440:	93c1                	srli	a5,a5,0x30
    80005442:	4705                	li	a4,1
    80005444:	00f76d63          	bltu	a4,a5,8000545e <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005448:	8556                	mv	a0,s5
    8000544a:	60a6                	ld	ra,72(sp)
    8000544c:	6406                	ld	s0,64(sp)
    8000544e:	74e2                	ld	s1,56(sp)
    80005450:	7942                	ld	s2,48(sp)
    80005452:	79a2                	ld	s3,40(sp)
    80005454:	7a02                	ld	s4,32(sp)
    80005456:	6ae2                	ld	s5,24(sp)
    80005458:	6b42                	ld	s6,16(sp)
    8000545a:	6161                	addi	sp,sp,80
    8000545c:	8082                	ret
    iunlockput(ip);
    8000545e:	8556                	mv	a0,s5
    80005460:	fffff097          	auipc	ra,0xfffff
    80005464:	86a080e7          	jalr	-1942(ra) # 80003cca <iunlockput>
    return 0;
    80005468:	4a81                	li	s5,0
    8000546a:	bff9                	j	80005448 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    8000546c:	85da                	mv	a1,s6
    8000546e:	4088                	lw	a0,0(s1)
    80005470:	ffffe097          	auipc	ra,0xffffe
    80005474:	45c080e7          	jalr	1116(ra) # 800038cc <ialloc>
    80005478:	8a2a                	mv	s4,a0
    8000547a:	c539                	beqz	a0,800054c8 <create+0xf6>
  ilock(ip);
    8000547c:	ffffe097          	auipc	ra,0xffffe
    80005480:	5ec080e7          	jalr	1516(ra) # 80003a68 <ilock>
  ip->major = major;
    80005484:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005488:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    8000548c:	4905                	li	s2,1
    8000548e:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005492:	8552                	mv	a0,s4
    80005494:	ffffe097          	auipc	ra,0xffffe
    80005498:	50a080e7          	jalr	1290(ra) # 8000399e <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000549c:	000b059b          	sext.w	a1,s6
    800054a0:	03258b63          	beq	a1,s2,800054d6 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    800054a4:	004a2603          	lw	a2,4(s4)
    800054a8:	fb040593          	addi	a1,s0,-80
    800054ac:	8526                	mv	a0,s1
    800054ae:	fffff097          	auipc	ra,0xfffff
    800054b2:	cae080e7          	jalr	-850(ra) # 8000415c <dirlink>
    800054b6:	06054f63          	bltz	a0,80005534 <create+0x162>
  iunlockput(dp);
    800054ba:	8526                	mv	a0,s1
    800054bc:	fffff097          	auipc	ra,0xfffff
    800054c0:	80e080e7          	jalr	-2034(ra) # 80003cca <iunlockput>
  return ip;
    800054c4:	8ad2                	mv	s5,s4
    800054c6:	b749                	j	80005448 <create+0x76>
    iunlockput(dp);
    800054c8:	8526                	mv	a0,s1
    800054ca:	fffff097          	auipc	ra,0xfffff
    800054ce:	800080e7          	jalr	-2048(ra) # 80003cca <iunlockput>
    return 0;
    800054d2:	8ad2                	mv	s5,s4
    800054d4:	bf95                	j	80005448 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800054d6:	004a2603          	lw	a2,4(s4)
    800054da:	00003597          	auipc	a1,0x3
    800054de:	2c658593          	addi	a1,a1,710 # 800087a0 <syscalls+0x2b0>
    800054e2:	8552                	mv	a0,s4
    800054e4:	fffff097          	auipc	ra,0xfffff
    800054e8:	c78080e7          	jalr	-904(ra) # 8000415c <dirlink>
    800054ec:	04054463          	bltz	a0,80005534 <create+0x162>
    800054f0:	40d0                	lw	a2,4(s1)
    800054f2:	00003597          	auipc	a1,0x3
    800054f6:	2b658593          	addi	a1,a1,694 # 800087a8 <syscalls+0x2b8>
    800054fa:	8552                	mv	a0,s4
    800054fc:	fffff097          	auipc	ra,0xfffff
    80005500:	c60080e7          	jalr	-928(ra) # 8000415c <dirlink>
    80005504:	02054863          	bltz	a0,80005534 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    80005508:	004a2603          	lw	a2,4(s4)
    8000550c:	fb040593          	addi	a1,s0,-80
    80005510:	8526                	mv	a0,s1
    80005512:	fffff097          	auipc	ra,0xfffff
    80005516:	c4a080e7          	jalr	-950(ra) # 8000415c <dirlink>
    8000551a:	00054d63          	bltz	a0,80005534 <create+0x162>
    dp->nlink++;  // for ".."
    8000551e:	04a4d783          	lhu	a5,74(s1)
    80005522:	2785                	addiw	a5,a5,1
    80005524:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005528:	8526                	mv	a0,s1
    8000552a:	ffffe097          	auipc	ra,0xffffe
    8000552e:	474080e7          	jalr	1140(ra) # 8000399e <iupdate>
    80005532:	b761                	j	800054ba <create+0xe8>
  ip->nlink = 0;
    80005534:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005538:	8552                	mv	a0,s4
    8000553a:	ffffe097          	auipc	ra,0xffffe
    8000553e:	464080e7          	jalr	1124(ra) # 8000399e <iupdate>
  iunlockput(ip);
    80005542:	8552                	mv	a0,s4
    80005544:	ffffe097          	auipc	ra,0xffffe
    80005548:	786080e7          	jalr	1926(ra) # 80003cca <iunlockput>
  iunlockput(dp);
    8000554c:	8526                	mv	a0,s1
    8000554e:	ffffe097          	auipc	ra,0xffffe
    80005552:	77c080e7          	jalr	1916(ra) # 80003cca <iunlockput>
  return 0;
    80005556:	bdcd                	j	80005448 <create+0x76>
    return 0;
    80005558:	8aaa                	mv	s5,a0
    8000555a:	b5fd                	j	80005448 <create+0x76>

000000008000555c <sys_dup>:
{
    8000555c:	7179                	addi	sp,sp,-48
    8000555e:	f406                	sd	ra,40(sp)
    80005560:	f022                	sd	s0,32(sp)
    80005562:	ec26                	sd	s1,24(sp)
    80005564:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005566:	fd840613          	addi	a2,s0,-40
    8000556a:	4581                	li	a1,0
    8000556c:	4501                	li	a0,0
    8000556e:	00000097          	auipc	ra,0x0
    80005572:	dc2080e7          	jalr	-574(ra) # 80005330 <argfd>
    return -1;
    80005576:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005578:	02054363          	bltz	a0,8000559e <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000557c:	fd843503          	ld	a0,-40(s0)
    80005580:	00000097          	auipc	ra,0x0
    80005584:	e10080e7          	jalr	-496(ra) # 80005390 <fdalloc>
    80005588:	84aa                	mv	s1,a0
    return -1;
    8000558a:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000558c:	00054963          	bltz	a0,8000559e <sys_dup+0x42>
  filedup(f);
    80005590:	fd843503          	ld	a0,-40(s0)
    80005594:	fffff097          	auipc	ra,0xfffff
    80005598:	310080e7          	jalr	784(ra) # 800048a4 <filedup>
  return fd;
    8000559c:	87a6                	mv	a5,s1
}
    8000559e:	853e                	mv	a0,a5
    800055a0:	70a2                	ld	ra,40(sp)
    800055a2:	7402                	ld	s0,32(sp)
    800055a4:	64e2                	ld	s1,24(sp)
    800055a6:	6145                	addi	sp,sp,48
    800055a8:	8082                	ret

00000000800055aa <sys_read>:
{
    800055aa:	7179                	addi	sp,sp,-48
    800055ac:	f406                	sd	ra,40(sp)
    800055ae:	f022                	sd	s0,32(sp)
    800055b0:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800055b2:	fd840593          	addi	a1,s0,-40
    800055b6:	4505                	li	a0,1
    800055b8:	ffffe097          	auipc	ra,0xffffe
    800055bc:	836080e7          	jalr	-1994(ra) # 80002dee <argaddr>
  argint(2, &n);
    800055c0:	fe440593          	addi	a1,s0,-28
    800055c4:	4509                	li	a0,2
    800055c6:	ffffe097          	auipc	ra,0xffffe
    800055ca:	808080e7          	jalr	-2040(ra) # 80002dce <argint>
  if(argfd(0, 0, &f) < 0)
    800055ce:	fe840613          	addi	a2,s0,-24
    800055d2:	4581                	li	a1,0
    800055d4:	4501                	li	a0,0
    800055d6:	00000097          	auipc	ra,0x0
    800055da:	d5a080e7          	jalr	-678(ra) # 80005330 <argfd>
    800055de:	87aa                	mv	a5,a0
    return -1;
    800055e0:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800055e2:	0007cc63          	bltz	a5,800055fa <sys_read+0x50>
  return fileread(f, p, n);
    800055e6:	fe442603          	lw	a2,-28(s0)
    800055ea:	fd843583          	ld	a1,-40(s0)
    800055ee:	fe843503          	ld	a0,-24(s0)
    800055f2:	fffff097          	auipc	ra,0xfffff
    800055f6:	43e080e7          	jalr	1086(ra) # 80004a30 <fileread>
}
    800055fa:	70a2                	ld	ra,40(sp)
    800055fc:	7402                	ld	s0,32(sp)
    800055fe:	6145                	addi	sp,sp,48
    80005600:	8082                	ret

0000000080005602 <sys_write>:
{
    80005602:	7179                	addi	sp,sp,-48
    80005604:	f406                	sd	ra,40(sp)
    80005606:	f022                	sd	s0,32(sp)
    80005608:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000560a:	fd840593          	addi	a1,s0,-40
    8000560e:	4505                	li	a0,1
    80005610:	ffffd097          	auipc	ra,0xffffd
    80005614:	7de080e7          	jalr	2014(ra) # 80002dee <argaddr>
  argint(2, &n);
    80005618:	fe440593          	addi	a1,s0,-28
    8000561c:	4509                	li	a0,2
    8000561e:	ffffd097          	auipc	ra,0xffffd
    80005622:	7b0080e7          	jalr	1968(ra) # 80002dce <argint>
  if(argfd(0, 0, &f) < 0)
    80005626:	fe840613          	addi	a2,s0,-24
    8000562a:	4581                	li	a1,0
    8000562c:	4501                	li	a0,0
    8000562e:	00000097          	auipc	ra,0x0
    80005632:	d02080e7          	jalr	-766(ra) # 80005330 <argfd>
    80005636:	87aa                	mv	a5,a0
    return -1;
    80005638:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000563a:	0007cc63          	bltz	a5,80005652 <sys_write+0x50>
  return filewrite(f, p, n);
    8000563e:	fe442603          	lw	a2,-28(s0)
    80005642:	fd843583          	ld	a1,-40(s0)
    80005646:	fe843503          	ld	a0,-24(s0)
    8000564a:	fffff097          	auipc	ra,0xfffff
    8000564e:	4a8080e7          	jalr	1192(ra) # 80004af2 <filewrite>
}
    80005652:	70a2                	ld	ra,40(sp)
    80005654:	7402                	ld	s0,32(sp)
    80005656:	6145                	addi	sp,sp,48
    80005658:	8082                	ret

000000008000565a <sys_close>:
{
    8000565a:	1101                	addi	sp,sp,-32
    8000565c:	ec06                	sd	ra,24(sp)
    8000565e:	e822                	sd	s0,16(sp)
    80005660:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005662:	fe040613          	addi	a2,s0,-32
    80005666:	fec40593          	addi	a1,s0,-20
    8000566a:	4501                	li	a0,0
    8000566c:	00000097          	auipc	ra,0x0
    80005670:	cc4080e7          	jalr	-828(ra) # 80005330 <argfd>
    return -1;
    80005674:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005676:	02054463          	bltz	a0,8000569e <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000567a:	ffffc097          	auipc	ra,0xffffc
    8000567e:	626080e7          	jalr	1574(ra) # 80001ca0 <myproc>
    80005682:	fec42783          	lw	a5,-20(s0)
    80005686:	07e9                	addi	a5,a5,26
    80005688:	078e                	slli	a5,a5,0x3
    8000568a:	97aa                	add	a5,a5,a0
    8000568c:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005690:	fe043503          	ld	a0,-32(s0)
    80005694:	fffff097          	auipc	ra,0xfffff
    80005698:	262080e7          	jalr	610(ra) # 800048f6 <fileclose>
  return 0;
    8000569c:	4781                	li	a5,0
}
    8000569e:	853e                	mv	a0,a5
    800056a0:	60e2                	ld	ra,24(sp)
    800056a2:	6442                	ld	s0,16(sp)
    800056a4:	6105                	addi	sp,sp,32
    800056a6:	8082                	ret

00000000800056a8 <sys_fstat>:
{
    800056a8:	1101                	addi	sp,sp,-32
    800056aa:	ec06                	sd	ra,24(sp)
    800056ac:	e822                	sd	s0,16(sp)
    800056ae:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800056b0:	fe040593          	addi	a1,s0,-32
    800056b4:	4505                	li	a0,1
    800056b6:	ffffd097          	auipc	ra,0xffffd
    800056ba:	738080e7          	jalr	1848(ra) # 80002dee <argaddr>
  if(argfd(0, 0, &f) < 0)
    800056be:	fe840613          	addi	a2,s0,-24
    800056c2:	4581                	li	a1,0
    800056c4:	4501                	li	a0,0
    800056c6:	00000097          	auipc	ra,0x0
    800056ca:	c6a080e7          	jalr	-918(ra) # 80005330 <argfd>
    800056ce:	87aa                	mv	a5,a0
    return -1;
    800056d0:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800056d2:	0007ca63          	bltz	a5,800056e6 <sys_fstat+0x3e>
  return filestat(f, st);
    800056d6:	fe043583          	ld	a1,-32(s0)
    800056da:	fe843503          	ld	a0,-24(s0)
    800056de:	fffff097          	auipc	ra,0xfffff
    800056e2:	2e0080e7          	jalr	736(ra) # 800049be <filestat>
}
    800056e6:	60e2                	ld	ra,24(sp)
    800056e8:	6442                	ld	s0,16(sp)
    800056ea:	6105                	addi	sp,sp,32
    800056ec:	8082                	ret

00000000800056ee <sys_link>:
{
    800056ee:	7169                	addi	sp,sp,-304
    800056f0:	f606                	sd	ra,296(sp)
    800056f2:	f222                	sd	s0,288(sp)
    800056f4:	ee26                	sd	s1,280(sp)
    800056f6:	ea4a                	sd	s2,272(sp)
    800056f8:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056fa:	08000613          	li	a2,128
    800056fe:	ed040593          	addi	a1,s0,-304
    80005702:	4501                	li	a0,0
    80005704:	ffffd097          	auipc	ra,0xffffd
    80005708:	70a080e7          	jalr	1802(ra) # 80002e0e <argstr>
    return -1;
    8000570c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000570e:	10054e63          	bltz	a0,8000582a <sys_link+0x13c>
    80005712:	08000613          	li	a2,128
    80005716:	f5040593          	addi	a1,s0,-176
    8000571a:	4505                	li	a0,1
    8000571c:	ffffd097          	auipc	ra,0xffffd
    80005720:	6f2080e7          	jalr	1778(ra) # 80002e0e <argstr>
    return -1;
    80005724:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005726:	10054263          	bltz	a0,8000582a <sys_link+0x13c>
  begin_op();
    8000572a:	fffff097          	auipc	ra,0xfffff
    8000572e:	d00080e7          	jalr	-768(ra) # 8000442a <begin_op>
  if((ip = namei(old)) == 0){
    80005732:	ed040513          	addi	a0,s0,-304
    80005736:	fffff097          	auipc	ra,0xfffff
    8000573a:	ad8080e7          	jalr	-1320(ra) # 8000420e <namei>
    8000573e:	84aa                	mv	s1,a0
    80005740:	c551                	beqz	a0,800057cc <sys_link+0xde>
  ilock(ip);
    80005742:	ffffe097          	auipc	ra,0xffffe
    80005746:	326080e7          	jalr	806(ra) # 80003a68 <ilock>
  if(ip->type == T_DIR){
    8000574a:	04449703          	lh	a4,68(s1)
    8000574e:	4785                	li	a5,1
    80005750:	08f70463          	beq	a4,a5,800057d8 <sys_link+0xea>
  ip->nlink++;
    80005754:	04a4d783          	lhu	a5,74(s1)
    80005758:	2785                	addiw	a5,a5,1
    8000575a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000575e:	8526                	mv	a0,s1
    80005760:	ffffe097          	auipc	ra,0xffffe
    80005764:	23e080e7          	jalr	574(ra) # 8000399e <iupdate>
  iunlock(ip);
    80005768:	8526                	mv	a0,s1
    8000576a:	ffffe097          	auipc	ra,0xffffe
    8000576e:	3c0080e7          	jalr	960(ra) # 80003b2a <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005772:	fd040593          	addi	a1,s0,-48
    80005776:	f5040513          	addi	a0,s0,-176
    8000577a:	fffff097          	auipc	ra,0xfffff
    8000577e:	ab2080e7          	jalr	-1358(ra) # 8000422c <nameiparent>
    80005782:	892a                	mv	s2,a0
    80005784:	c935                	beqz	a0,800057f8 <sys_link+0x10a>
  ilock(dp);
    80005786:	ffffe097          	auipc	ra,0xffffe
    8000578a:	2e2080e7          	jalr	738(ra) # 80003a68 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000578e:	00092703          	lw	a4,0(s2)
    80005792:	409c                	lw	a5,0(s1)
    80005794:	04f71d63          	bne	a4,a5,800057ee <sys_link+0x100>
    80005798:	40d0                	lw	a2,4(s1)
    8000579a:	fd040593          	addi	a1,s0,-48
    8000579e:	854a                	mv	a0,s2
    800057a0:	fffff097          	auipc	ra,0xfffff
    800057a4:	9bc080e7          	jalr	-1604(ra) # 8000415c <dirlink>
    800057a8:	04054363          	bltz	a0,800057ee <sys_link+0x100>
  iunlockput(dp);
    800057ac:	854a                	mv	a0,s2
    800057ae:	ffffe097          	auipc	ra,0xffffe
    800057b2:	51c080e7          	jalr	1308(ra) # 80003cca <iunlockput>
  iput(ip);
    800057b6:	8526                	mv	a0,s1
    800057b8:	ffffe097          	auipc	ra,0xffffe
    800057bc:	46a080e7          	jalr	1130(ra) # 80003c22 <iput>
  end_op();
    800057c0:	fffff097          	auipc	ra,0xfffff
    800057c4:	cea080e7          	jalr	-790(ra) # 800044aa <end_op>
  return 0;
    800057c8:	4781                	li	a5,0
    800057ca:	a085                	j	8000582a <sys_link+0x13c>
    end_op();
    800057cc:	fffff097          	auipc	ra,0xfffff
    800057d0:	cde080e7          	jalr	-802(ra) # 800044aa <end_op>
    return -1;
    800057d4:	57fd                	li	a5,-1
    800057d6:	a891                	j	8000582a <sys_link+0x13c>
    iunlockput(ip);
    800057d8:	8526                	mv	a0,s1
    800057da:	ffffe097          	auipc	ra,0xffffe
    800057de:	4f0080e7          	jalr	1264(ra) # 80003cca <iunlockput>
    end_op();
    800057e2:	fffff097          	auipc	ra,0xfffff
    800057e6:	cc8080e7          	jalr	-824(ra) # 800044aa <end_op>
    return -1;
    800057ea:	57fd                	li	a5,-1
    800057ec:	a83d                	j	8000582a <sys_link+0x13c>
    iunlockput(dp);
    800057ee:	854a                	mv	a0,s2
    800057f0:	ffffe097          	auipc	ra,0xffffe
    800057f4:	4da080e7          	jalr	1242(ra) # 80003cca <iunlockput>
  ilock(ip);
    800057f8:	8526                	mv	a0,s1
    800057fa:	ffffe097          	auipc	ra,0xffffe
    800057fe:	26e080e7          	jalr	622(ra) # 80003a68 <ilock>
  ip->nlink--;
    80005802:	04a4d783          	lhu	a5,74(s1)
    80005806:	37fd                	addiw	a5,a5,-1
    80005808:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000580c:	8526                	mv	a0,s1
    8000580e:	ffffe097          	auipc	ra,0xffffe
    80005812:	190080e7          	jalr	400(ra) # 8000399e <iupdate>
  iunlockput(ip);
    80005816:	8526                	mv	a0,s1
    80005818:	ffffe097          	auipc	ra,0xffffe
    8000581c:	4b2080e7          	jalr	1202(ra) # 80003cca <iunlockput>
  end_op();
    80005820:	fffff097          	auipc	ra,0xfffff
    80005824:	c8a080e7          	jalr	-886(ra) # 800044aa <end_op>
  return -1;
    80005828:	57fd                	li	a5,-1
}
    8000582a:	853e                	mv	a0,a5
    8000582c:	70b2                	ld	ra,296(sp)
    8000582e:	7412                	ld	s0,288(sp)
    80005830:	64f2                	ld	s1,280(sp)
    80005832:	6952                	ld	s2,272(sp)
    80005834:	6155                	addi	sp,sp,304
    80005836:	8082                	ret

0000000080005838 <sys_unlink>:
{
    80005838:	7151                	addi	sp,sp,-240
    8000583a:	f586                	sd	ra,232(sp)
    8000583c:	f1a2                	sd	s0,224(sp)
    8000583e:	eda6                	sd	s1,216(sp)
    80005840:	e9ca                	sd	s2,208(sp)
    80005842:	e5ce                	sd	s3,200(sp)
    80005844:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005846:	08000613          	li	a2,128
    8000584a:	f3040593          	addi	a1,s0,-208
    8000584e:	4501                	li	a0,0
    80005850:	ffffd097          	auipc	ra,0xffffd
    80005854:	5be080e7          	jalr	1470(ra) # 80002e0e <argstr>
    80005858:	18054163          	bltz	a0,800059da <sys_unlink+0x1a2>
  begin_op();
    8000585c:	fffff097          	auipc	ra,0xfffff
    80005860:	bce080e7          	jalr	-1074(ra) # 8000442a <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005864:	fb040593          	addi	a1,s0,-80
    80005868:	f3040513          	addi	a0,s0,-208
    8000586c:	fffff097          	auipc	ra,0xfffff
    80005870:	9c0080e7          	jalr	-1600(ra) # 8000422c <nameiparent>
    80005874:	84aa                	mv	s1,a0
    80005876:	c979                	beqz	a0,8000594c <sys_unlink+0x114>
  ilock(dp);
    80005878:	ffffe097          	auipc	ra,0xffffe
    8000587c:	1f0080e7          	jalr	496(ra) # 80003a68 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005880:	00003597          	auipc	a1,0x3
    80005884:	f2058593          	addi	a1,a1,-224 # 800087a0 <syscalls+0x2b0>
    80005888:	fb040513          	addi	a0,s0,-80
    8000588c:	ffffe097          	auipc	ra,0xffffe
    80005890:	6a6080e7          	jalr	1702(ra) # 80003f32 <namecmp>
    80005894:	14050a63          	beqz	a0,800059e8 <sys_unlink+0x1b0>
    80005898:	00003597          	auipc	a1,0x3
    8000589c:	f1058593          	addi	a1,a1,-240 # 800087a8 <syscalls+0x2b8>
    800058a0:	fb040513          	addi	a0,s0,-80
    800058a4:	ffffe097          	auipc	ra,0xffffe
    800058a8:	68e080e7          	jalr	1678(ra) # 80003f32 <namecmp>
    800058ac:	12050e63          	beqz	a0,800059e8 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800058b0:	f2c40613          	addi	a2,s0,-212
    800058b4:	fb040593          	addi	a1,s0,-80
    800058b8:	8526                	mv	a0,s1
    800058ba:	ffffe097          	auipc	ra,0xffffe
    800058be:	692080e7          	jalr	1682(ra) # 80003f4c <dirlookup>
    800058c2:	892a                	mv	s2,a0
    800058c4:	12050263          	beqz	a0,800059e8 <sys_unlink+0x1b0>
  ilock(ip);
    800058c8:	ffffe097          	auipc	ra,0xffffe
    800058cc:	1a0080e7          	jalr	416(ra) # 80003a68 <ilock>
  if(ip->nlink < 1)
    800058d0:	04a91783          	lh	a5,74(s2)
    800058d4:	08f05263          	blez	a5,80005958 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800058d8:	04491703          	lh	a4,68(s2)
    800058dc:	4785                	li	a5,1
    800058de:	08f70563          	beq	a4,a5,80005968 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800058e2:	4641                	li	a2,16
    800058e4:	4581                	li	a1,0
    800058e6:	fc040513          	addi	a0,s0,-64
    800058ea:	ffffb097          	auipc	ra,0xffffb
    800058ee:	3e8080e7          	jalr	1000(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800058f2:	4741                	li	a4,16
    800058f4:	f2c42683          	lw	a3,-212(s0)
    800058f8:	fc040613          	addi	a2,s0,-64
    800058fc:	4581                	li	a1,0
    800058fe:	8526                	mv	a0,s1
    80005900:	ffffe097          	auipc	ra,0xffffe
    80005904:	514080e7          	jalr	1300(ra) # 80003e14 <writei>
    80005908:	47c1                	li	a5,16
    8000590a:	0af51563          	bne	a0,a5,800059b4 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000590e:	04491703          	lh	a4,68(s2)
    80005912:	4785                	li	a5,1
    80005914:	0af70863          	beq	a4,a5,800059c4 <sys_unlink+0x18c>
  iunlockput(dp);
    80005918:	8526                	mv	a0,s1
    8000591a:	ffffe097          	auipc	ra,0xffffe
    8000591e:	3b0080e7          	jalr	944(ra) # 80003cca <iunlockput>
  ip->nlink--;
    80005922:	04a95783          	lhu	a5,74(s2)
    80005926:	37fd                	addiw	a5,a5,-1
    80005928:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000592c:	854a                	mv	a0,s2
    8000592e:	ffffe097          	auipc	ra,0xffffe
    80005932:	070080e7          	jalr	112(ra) # 8000399e <iupdate>
  iunlockput(ip);
    80005936:	854a                	mv	a0,s2
    80005938:	ffffe097          	auipc	ra,0xffffe
    8000593c:	392080e7          	jalr	914(ra) # 80003cca <iunlockput>
  end_op();
    80005940:	fffff097          	auipc	ra,0xfffff
    80005944:	b6a080e7          	jalr	-1174(ra) # 800044aa <end_op>
  return 0;
    80005948:	4501                	li	a0,0
    8000594a:	a84d                	j	800059fc <sys_unlink+0x1c4>
    end_op();
    8000594c:	fffff097          	auipc	ra,0xfffff
    80005950:	b5e080e7          	jalr	-1186(ra) # 800044aa <end_op>
    return -1;
    80005954:	557d                	li	a0,-1
    80005956:	a05d                	j	800059fc <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005958:	00003517          	auipc	a0,0x3
    8000595c:	e5850513          	addi	a0,a0,-424 # 800087b0 <syscalls+0x2c0>
    80005960:	ffffb097          	auipc	ra,0xffffb
    80005964:	bde080e7          	jalr	-1058(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005968:	04c92703          	lw	a4,76(s2)
    8000596c:	02000793          	li	a5,32
    80005970:	f6e7f9e3          	bgeu	a5,a4,800058e2 <sys_unlink+0xaa>
    80005974:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005978:	4741                	li	a4,16
    8000597a:	86ce                	mv	a3,s3
    8000597c:	f1840613          	addi	a2,s0,-232
    80005980:	4581                	li	a1,0
    80005982:	854a                	mv	a0,s2
    80005984:	ffffe097          	auipc	ra,0xffffe
    80005988:	398080e7          	jalr	920(ra) # 80003d1c <readi>
    8000598c:	47c1                	li	a5,16
    8000598e:	00f51b63          	bne	a0,a5,800059a4 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005992:	f1845783          	lhu	a5,-232(s0)
    80005996:	e7a1                	bnez	a5,800059de <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005998:	29c1                	addiw	s3,s3,16
    8000599a:	04c92783          	lw	a5,76(s2)
    8000599e:	fcf9ede3          	bltu	s3,a5,80005978 <sys_unlink+0x140>
    800059a2:	b781                	j	800058e2 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800059a4:	00003517          	auipc	a0,0x3
    800059a8:	e2450513          	addi	a0,a0,-476 # 800087c8 <syscalls+0x2d8>
    800059ac:	ffffb097          	auipc	ra,0xffffb
    800059b0:	b92080e7          	jalr	-1134(ra) # 8000053e <panic>
    panic("unlink: writei");
    800059b4:	00003517          	auipc	a0,0x3
    800059b8:	e2c50513          	addi	a0,a0,-468 # 800087e0 <syscalls+0x2f0>
    800059bc:	ffffb097          	auipc	ra,0xffffb
    800059c0:	b82080e7          	jalr	-1150(ra) # 8000053e <panic>
    dp->nlink--;
    800059c4:	04a4d783          	lhu	a5,74(s1)
    800059c8:	37fd                	addiw	a5,a5,-1
    800059ca:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800059ce:	8526                	mv	a0,s1
    800059d0:	ffffe097          	auipc	ra,0xffffe
    800059d4:	fce080e7          	jalr	-50(ra) # 8000399e <iupdate>
    800059d8:	b781                	j	80005918 <sys_unlink+0xe0>
    return -1;
    800059da:	557d                	li	a0,-1
    800059dc:	a005                	j	800059fc <sys_unlink+0x1c4>
    iunlockput(ip);
    800059de:	854a                	mv	a0,s2
    800059e0:	ffffe097          	auipc	ra,0xffffe
    800059e4:	2ea080e7          	jalr	746(ra) # 80003cca <iunlockput>
  iunlockput(dp);
    800059e8:	8526                	mv	a0,s1
    800059ea:	ffffe097          	auipc	ra,0xffffe
    800059ee:	2e0080e7          	jalr	736(ra) # 80003cca <iunlockput>
  end_op();
    800059f2:	fffff097          	auipc	ra,0xfffff
    800059f6:	ab8080e7          	jalr	-1352(ra) # 800044aa <end_op>
  return -1;
    800059fa:	557d                	li	a0,-1
}
    800059fc:	70ae                	ld	ra,232(sp)
    800059fe:	740e                	ld	s0,224(sp)
    80005a00:	64ee                	ld	s1,216(sp)
    80005a02:	694e                	ld	s2,208(sp)
    80005a04:	69ae                	ld	s3,200(sp)
    80005a06:	616d                	addi	sp,sp,240
    80005a08:	8082                	ret

0000000080005a0a <sys_open>:

uint64
sys_open(void)
{
    80005a0a:	7131                	addi	sp,sp,-192
    80005a0c:	fd06                	sd	ra,184(sp)
    80005a0e:	f922                	sd	s0,176(sp)
    80005a10:	f526                	sd	s1,168(sp)
    80005a12:	f14a                	sd	s2,160(sp)
    80005a14:	ed4e                	sd	s3,152(sp)
    80005a16:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005a18:	f4c40593          	addi	a1,s0,-180
    80005a1c:	4505                	li	a0,1
    80005a1e:	ffffd097          	auipc	ra,0xffffd
    80005a22:	3b0080e7          	jalr	944(ra) # 80002dce <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005a26:	08000613          	li	a2,128
    80005a2a:	f5040593          	addi	a1,s0,-176
    80005a2e:	4501                	li	a0,0
    80005a30:	ffffd097          	auipc	ra,0xffffd
    80005a34:	3de080e7          	jalr	990(ra) # 80002e0e <argstr>
    80005a38:	87aa                	mv	a5,a0
    return -1;
    80005a3a:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005a3c:	0a07c963          	bltz	a5,80005aee <sys_open+0xe4>

  begin_op();
    80005a40:	fffff097          	auipc	ra,0xfffff
    80005a44:	9ea080e7          	jalr	-1558(ra) # 8000442a <begin_op>

  if(omode & O_CREATE){
    80005a48:	f4c42783          	lw	a5,-180(s0)
    80005a4c:	2007f793          	andi	a5,a5,512
    80005a50:	cfc5                	beqz	a5,80005b08 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005a52:	4681                	li	a3,0
    80005a54:	4601                	li	a2,0
    80005a56:	4589                	li	a1,2
    80005a58:	f5040513          	addi	a0,s0,-176
    80005a5c:	00000097          	auipc	ra,0x0
    80005a60:	976080e7          	jalr	-1674(ra) # 800053d2 <create>
    80005a64:	84aa                	mv	s1,a0
    if(ip == 0){
    80005a66:	c959                	beqz	a0,80005afc <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005a68:	04449703          	lh	a4,68(s1)
    80005a6c:	478d                	li	a5,3
    80005a6e:	00f71763          	bne	a4,a5,80005a7c <sys_open+0x72>
    80005a72:	0464d703          	lhu	a4,70(s1)
    80005a76:	47a5                	li	a5,9
    80005a78:	0ce7ed63          	bltu	a5,a4,80005b52 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005a7c:	fffff097          	auipc	ra,0xfffff
    80005a80:	dbe080e7          	jalr	-578(ra) # 8000483a <filealloc>
    80005a84:	89aa                	mv	s3,a0
    80005a86:	10050363          	beqz	a0,80005b8c <sys_open+0x182>
    80005a8a:	00000097          	auipc	ra,0x0
    80005a8e:	906080e7          	jalr	-1786(ra) # 80005390 <fdalloc>
    80005a92:	892a                	mv	s2,a0
    80005a94:	0e054763          	bltz	a0,80005b82 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005a98:	04449703          	lh	a4,68(s1)
    80005a9c:	478d                	li	a5,3
    80005a9e:	0cf70563          	beq	a4,a5,80005b68 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005aa2:	4789                	li	a5,2
    80005aa4:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005aa8:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005aac:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005ab0:	f4c42783          	lw	a5,-180(s0)
    80005ab4:	0017c713          	xori	a4,a5,1
    80005ab8:	8b05                	andi	a4,a4,1
    80005aba:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005abe:	0037f713          	andi	a4,a5,3
    80005ac2:	00e03733          	snez	a4,a4
    80005ac6:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005aca:	4007f793          	andi	a5,a5,1024
    80005ace:	c791                	beqz	a5,80005ada <sys_open+0xd0>
    80005ad0:	04449703          	lh	a4,68(s1)
    80005ad4:	4789                	li	a5,2
    80005ad6:	0af70063          	beq	a4,a5,80005b76 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005ada:	8526                	mv	a0,s1
    80005adc:	ffffe097          	auipc	ra,0xffffe
    80005ae0:	04e080e7          	jalr	78(ra) # 80003b2a <iunlock>
  end_op();
    80005ae4:	fffff097          	auipc	ra,0xfffff
    80005ae8:	9c6080e7          	jalr	-1594(ra) # 800044aa <end_op>

  return fd;
    80005aec:	854a                	mv	a0,s2
}
    80005aee:	70ea                	ld	ra,184(sp)
    80005af0:	744a                	ld	s0,176(sp)
    80005af2:	74aa                	ld	s1,168(sp)
    80005af4:	790a                	ld	s2,160(sp)
    80005af6:	69ea                	ld	s3,152(sp)
    80005af8:	6129                	addi	sp,sp,192
    80005afa:	8082                	ret
      end_op();
    80005afc:	fffff097          	auipc	ra,0xfffff
    80005b00:	9ae080e7          	jalr	-1618(ra) # 800044aa <end_op>
      return -1;
    80005b04:	557d                	li	a0,-1
    80005b06:	b7e5                	j	80005aee <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005b08:	f5040513          	addi	a0,s0,-176
    80005b0c:	ffffe097          	auipc	ra,0xffffe
    80005b10:	702080e7          	jalr	1794(ra) # 8000420e <namei>
    80005b14:	84aa                	mv	s1,a0
    80005b16:	c905                	beqz	a0,80005b46 <sys_open+0x13c>
    ilock(ip);
    80005b18:	ffffe097          	auipc	ra,0xffffe
    80005b1c:	f50080e7          	jalr	-176(ra) # 80003a68 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005b20:	04449703          	lh	a4,68(s1)
    80005b24:	4785                	li	a5,1
    80005b26:	f4f711e3          	bne	a4,a5,80005a68 <sys_open+0x5e>
    80005b2a:	f4c42783          	lw	a5,-180(s0)
    80005b2e:	d7b9                	beqz	a5,80005a7c <sys_open+0x72>
      iunlockput(ip);
    80005b30:	8526                	mv	a0,s1
    80005b32:	ffffe097          	auipc	ra,0xffffe
    80005b36:	198080e7          	jalr	408(ra) # 80003cca <iunlockput>
      end_op();
    80005b3a:	fffff097          	auipc	ra,0xfffff
    80005b3e:	970080e7          	jalr	-1680(ra) # 800044aa <end_op>
      return -1;
    80005b42:	557d                	li	a0,-1
    80005b44:	b76d                	j	80005aee <sys_open+0xe4>
      end_op();
    80005b46:	fffff097          	auipc	ra,0xfffff
    80005b4a:	964080e7          	jalr	-1692(ra) # 800044aa <end_op>
      return -1;
    80005b4e:	557d                	li	a0,-1
    80005b50:	bf79                	j	80005aee <sys_open+0xe4>
    iunlockput(ip);
    80005b52:	8526                	mv	a0,s1
    80005b54:	ffffe097          	auipc	ra,0xffffe
    80005b58:	176080e7          	jalr	374(ra) # 80003cca <iunlockput>
    end_op();
    80005b5c:	fffff097          	auipc	ra,0xfffff
    80005b60:	94e080e7          	jalr	-1714(ra) # 800044aa <end_op>
    return -1;
    80005b64:	557d                	li	a0,-1
    80005b66:	b761                	j	80005aee <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005b68:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005b6c:	04649783          	lh	a5,70(s1)
    80005b70:	02f99223          	sh	a5,36(s3)
    80005b74:	bf25                	j	80005aac <sys_open+0xa2>
    itrunc(ip);
    80005b76:	8526                	mv	a0,s1
    80005b78:	ffffe097          	auipc	ra,0xffffe
    80005b7c:	ffe080e7          	jalr	-2(ra) # 80003b76 <itrunc>
    80005b80:	bfa9                	j	80005ada <sys_open+0xd0>
      fileclose(f);
    80005b82:	854e                	mv	a0,s3
    80005b84:	fffff097          	auipc	ra,0xfffff
    80005b88:	d72080e7          	jalr	-654(ra) # 800048f6 <fileclose>
    iunlockput(ip);
    80005b8c:	8526                	mv	a0,s1
    80005b8e:	ffffe097          	auipc	ra,0xffffe
    80005b92:	13c080e7          	jalr	316(ra) # 80003cca <iunlockput>
    end_op();
    80005b96:	fffff097          	auipc	ra,0xfffff
    80005b9a:	914080e7          	jalr	-1772(ra) # 800044aa <end_op>
    return -1;
    80005b9e:	557d                	li	a0,-1
    80005ba0:	b7b9                	j	80005aee <sys_open+0xe4>

0000000080005ba2 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005ba2:	7175                	addi	sp,sp,-144
    80005ba4:	e506                	sd	ra,136(sp)
    80005ba6:	e122                	sd	s0,128(sp)
    80005ba8:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005baa:	fffff097          	auipc	ra,0xfffff
    80005bae:	880080e7          	jalr	-1920(ra) # 8000442a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005bb2:	08000613          	li	a2,128
    80005bb6:	f7040593          	addi	a1,s0,-144
    80005bba:	4501                	li	a0,0
    80005bbc:	ffffd097          	auipc	ra,0xffffd
    80005bc0:	252080e7          	jalr	594(ra) # 80002e0e <argstr>
    80005bc4:	02054963          	bltz	a0,80005bf6 <sys_mkdir+0x54>
    80005bc8:	4681                	li	a3,0
    80005bca:	4601                	li	a2,0
    80005bcc:	4585                	li	a1,1
    80005bce:	f7040513          	addi	a0,s0,-144
    80005bd2:	00000097          	auipc	ra,0x0
    80005bd6:	800080e7          	jalr	-2048(ra) # 800053d2 <create>
    80005bda:	cd11                	beqz	a0,80005bf6 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005bdc:	ffffe097          	auipc	ra,0xffffe
    80005be0:	0ee080e7          	jalr	238(ra) # 80003cca <iunlockput>
  end_op();
    80005be4:	fffff097          	auipc	ra,0xfffff
    80005be8:	8c6080e7          	jalr	-1850(ra) # 800044aa <end_op>
  return 0;
    80005bec:	4501                	li	a0,0
}
    80005bee:	60aa                	ld	ra,136(sp)
    80005bf0:	640a                	ld	s0,128(sp)
    80005bf2:	6149                	addi	sp,sp,144
    80005bf4:	8082                	ret
    end_op();
    80005bf6:	fffff097          	auipc	ra,0xfffff
    80005bfa:	8b4080e7          	jalr	-1868(ra) # 800044aa <end_op>
    return -1;
    80005bfe:	557d                	li	a0,-1
    80005c00:	b7fd                	j	80005bee <sys_mkdir+0x4c>

0000000080005c02 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005c02:	7135                	addi	sp,sp,-160
    80005c04:	ed06                	sd	ra,152(sp)
    80005c06:	e922                	sd	s0,144(sp)
    80005c08:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005c0a:	fffff097          	auipc	ra,0xfffff
    80005c0e:	820080e7          	jalr	-2016(ra) # 8000442a <begin_op>
  argint(1, &major);
    80005c12:	f6c40593          	addi	a1,s0,-148
    80005c16:	4505                	li	a0,1
    80005c18:	ffffd097          	auipc	ra,0xffffd
    80005c1c:	1b6080e7          	jalr	438(ra) # 80002dce <argint>
  argint(2, &minor);
    80005c20:	f6840593          	addi	a1,s0,-152
    80005c24:	4509                	li	a0,2
    80005c26:	ffffd097          	auipc	ra,0xffffd
    80005c2a:	1a8080e7          	jalr	424(ra) # 80002dce <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005c2e:	08000613          	li	a2,128
    80005c32:	f7040593          	addi	a1,s0,-144
    80005c36:	4501                	li	a0,0
    80005c38:	ffffd097          	auipc	ra,0xffffd
    80005c3c:	1d6080e7          	jalr	470(ra) # 80002e0e <argstr>
    80005c40:	02054b63          	bltz	a0,80005c76 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005c44:	f6841683          	lh	a3,-152(s0)
    80005c48:	f6c41603          	lh	a2,-148(s0)
    80005c4c:	458d                	li	a1,3
    80005c4e:	f7040513          	addi	a0,s0,-144
    80005c52:	fffff097          	auipc	ra,0xfffff
    80005c56:	780080e7          	jalr	1920(ra) # 800053d2 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005c5a:	cd11                	beqz	a0,80005c76 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005c5c:	ffffe097          	auipc	ra,0xffffe
    80005c60:	06e080e7          	jalr	110(ra) # 80003cca <iunlockput>
  end_op();
    80005c64:	fffff097          	auipc	ra,0xfffff
    80005c68:	846080e7          	jalr	-1978(ra) # 800044aa <end_op>
  return 0;
    80005c6c:	4501                	li	a0,0
}
    80005c6e:	60ea                	ld	ra,152(sp)
    80005c70:	644a                	ld	s0,144(sp)
    80005c72:	610d                	addi	sp,sp,160
    80005c74:	8082                	ret
    end_op();
    80005c76:	fffff097          	auipc	ra,0xfffff
    80005c7a:	834080e7          	jalr	-1996(ra) # 800044aa <end_op>
    return -1;
    80005c7e:	557d                	li	a0,-1
    80005c80:	b7fd                	j	80005c6e <sys_mknod+0x6c>

0000000080005c82 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005c82:	7135                	addi	sp,sp,-160
    80005c84:	ed06                	sd	ra,152(sp)
    80005c86:	e922                	sd	s0,144(sp)
    80005c88:	e526                	sd	s1,136(sp)
    80005c8a:	e14a                	sd	s2,128(sp)
    80005c8c:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005c8e:	ffffc097          	auipc	ra,0xffffc
    80005c92:	012080e7          	jalr	18(ra) # 80001ca0 <myproc>
    80005c96:	892a                	mv	s2,a0
  
  begin_op();
    80005c98:	ffffe097          	auipc	ra,0xffffe
    80005c9c:	792080e7          	jalr	1938(ra) # 8000442a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005ca0:	08000613          	li	a2,128
    80005ca4:	f6040593          	addi	a1,s0,-160
    80005ca8:	4501                	li	a0,0
    80005caa:	ffffd097          	auipc	ra,0xffffd
    80005cae:	164080e7          	jalr	356(ra) # 80002e0e <argstr>
    80005cb2:	04054b63          	bltz	a0,80005d08 <sys_chdir+0x86>
    80005cb6:	f6040513          	addi	a0,s0,-160
    80005cba:	ffffe097          	auipc	ra,0xffffe
    80005cbe:	554080e7          	jalr	1364(ra) # 8000420e <namei>
    80005cc2:	84aa                	mv	s1,a0
    80005cc4:	c131                	beqz	a0,80005d08 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005cc6:	ffffe097          	auipc	ra,0xffffe
    80005cca:	da2080e7          	jalr	-606(ra) # 80003a68 <ilock>
  if(ip->type != T_DIR){
    80005cce:	04449703          	lh	a4,68(s1)
    80005cd2:	4785                	li	a5,1
    80005cd4:	04f71063          	bne	a4,a5,80005d14 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005cd8:	8526                	mv	a0,s1
    80005cda:	ffffe097          	auipc	ra,0xffffe
    80005cde:	e50080e7          	jalr	-432(ra) # 80003b2a <iunlock>
  iput(p->cwd);
    80005ce2:	15093503          	ld	a0,336(s2)
    80005ce6:	ffffe097          	auipc	ra,0xffffe
    80005cea:	f3c080e7          	jalr	-196(ra) # 80003c22 <iput>
  end_op();
    80005cee:	ffffe097          	auipc	ra,0xffffe
    80005cf2:	7bc080e7          	jalr	1980(ra) # 800044aa <end_op>
  p->cwd = ip;
    80005cf6:	14993823          	sd	s1,336(s2)
  return 0;
    80005cfa:	4501                	li	a0,0
}
    80005cfc:	60ea                	ld	ra,152(sp)
    80005cfe:	644a                	ld	s0,144(sp)
    80005d00:	64aa                	ld	s1,136(sp)
    80005d02:	690a                	ld	s2,128(sp)
    80005d04:	610d                	addi	sp,sp,160
    80005d06:	8082                	ret
    end_op();
    80005d08:	ffffe097          	auipc	ra,0xffffe
    80005d0c:	7a2080e7          	jalr	1954(ra) # 800044aa <end_op>
    return -1;
    80005d10:	557d                	li	a0,-1
    80005d12:	b7ed                	j	80005cfc <sys_chdir+0x7a>
    iunlockput(ip);
    80005d14:	8526                	mv	a0,s1
    80005d16:	ffffe097          	auipc	ra,0xffffe
    80005d1a:	fb4080e7          	jalr	-76(ra) # 80003cca <iunlockput>
    end_op();
    80005d1e:	ffffe097          	auipc	ra,0xffffe
    80005d22:	78c080e7          	jalr	1932(ra) # 800044aa <end_op>
    return -1;
    80005d26:	557d                	li	a0,-1
    80005d28:	bfd1                	j	80005cfc <sys_chdir+0x7a>

0000000080005d2a <sys_exec>:

uint64
sys_exec(void)
{
    80005d2a:	7145                	addi	sp,sp,-464
    80005d2c:	e786                	sd	ra,456(sp)
    80005d2e:	e3a2                	sd	s0,448(sp)
    80005d30:	ff26                	sd	s1,440(sp)
    80005d32:	fb4a                	sd	s2,432(sp)
    80005d34:	f74e                	sd	s3,424(sp)
    80005d36:	f352                	sd	s4,416(sp)
    80005d38:	ef56                	sd	s5,408(sp)
    80005d3a:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005d3c:	e3840593          	addi	a1,s0,-456
    80005d40:	4505                	li	a0,1
    80005d42:	ffffd097          	auipc	ra,0xffffd
    80005d46:	0ac080e7          	jalr	172(ra) # 80002dee <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005d4a:	08000613          	li	a2,128
    80005d4e:	f4040593          	addi	a1,s0,-192
    80005d52:	4501                	li	a0,0
    80005d54:	ffffd097          	auipc	ra,0xffffd
    80005d58:	0ba080e7          	jalr	186(ra) # 80002e0e <argstr>
    80005d5c:	87aa                	mv	a5,a0
    return -1;
    80005d5e:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005d60:	0c07c263          	bltz	a5,80005e24 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005d64:	10000613          	li	a2,256
    80005d68:	4581                	li	a1,0
    80005d6a:	e4040513          	addi	a0,s0,-448
    80005d6e:	ffffb097          	auipc	ra,0xffffb
    80005d72:	f64080e7          	jalr	-156(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005d76:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005d7a:	89a6                	mv	s3,s1
    80005d7c:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005d7e:	02000a13          	li	s4,32
    80005d82:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005d86:	00391793          	slli	a5,s2,0x3
    80005d8a:	e3040593          	addi	a1,s0,-464
    80005d8e:	e3843503          	ld	a0,-456(s0)
    80005d92:	953e                	add	a0,a0,a5
    80005d94:	ffffd097          	auipc	ra,0xffffd
    80005d98:	f9c080e7          	jalr	-100(ra) # 80002d30 <fetchaddr>
    80005d9c:	02054a63          	bltz	a0,80005dd0 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005da0:	e3043783          	ld	a5,-464(s0)
    80005da4:	c3b9                	beqz	a5,80005dea <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005da6:	ffffb097          	auipc	ra,0xffffb
    80005daa:	d40080e7          	jalr	-704(ra) # 80000ae6 <kalloc>
    80005dae:	85aa                	mv	a1,a0
    80005db0:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005db4:	cd11                	beqz	a0,80005dd0 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005db6:	6605                	lui	a2,0x1
    80005db8:	e3043503          	ld	a0,-464(s0)
    80005dbc:	ffffd097          	auipc	ra,0xffffd
    80005dc0:	fc6080e7          	jalr	-58(ra) # 80002d82 <fetchstr>
    80005dc4:	00054663          	bltz	a0,80005dd0 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005dc8:	0905                	addi	s2,s2,1
    80005dca:	09a1                	addi	s3,s3,8
    80005dcc:	fb491be3          	bne	s2,s4,80005d82 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005dd0:	10048913          	addi	s2,s1,256
    80005dd4:	6088                	ld	a0,0(s1)
    80005dd6:	c531                	beqz	a0,80005e22 <sys_exec+0xf8>
    kfree(argv[i]);
    80005dd8:	ffffb097          	auipc	ra,0xffffb
    80005ddc:	c12080e7          	jalr	-1006(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005de0:	04a1                	addi	s1,s1,8
    80005de2:	ff2499e3          	bne	s1,s2,80005dd4 <sys_exec+0xaa>
  return -1;
    80005de6:	557d                	li	a0,-1
    80005de8:	a835                	j	80005e24 <sys_exec+0xfa>
      argv[i] = 0;
    80005dea:	0a8e                	slli	s5,s5,0x3
    80005dec:	fc040793          	addi	a5,s0,-64
    80005df0:	9abe                	add	s5,s5,a5
    80005df2:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005df6:	e4040593          	addi	a1,s0,-448
    80005dfa:	f4040513          	addi	a0,s0,-192
    80005dfe:	fffff097          	auipc	ra,0xfffff
    80005e02:	172080e7          	jalr	370(ra) # 80004f70 <exec>
    80005e06:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e08:	10048993          	addi	s3,s1,256
    80005e0c:	6088                	ld	a0,0(s1)
    80005e0e:	c901                	beqz	a0,80005e1e <sys_exec+0xf4>
    kfree(argv[i]);
    80005e10:	ffffb097          	auipc	ra,0xffffb
    80005e14:	bda080e7          	jalr	-1062(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e18:	04a1                	addi	s1,s1,8
    80005e1a:	ff3499e3          	bne	s1,s3,80005e0c <sys_exec+0xe2>
  return ret;
    80005e1e:	854a                	mv	a0,s2
    80005e20:	a011                	j	80005e24 <sys_exec+0xfa>
  return -1;
    80005e22:	557d                	li	a0,-1
}
    80005e24:	60be                	ld	ra,456(sp)
    80005e26:	641e                	ld	s0,448(sp)
    80005e28:	74fa                	ld	s1,440(sp)
    80005e2a:	795a                	ld	s2,432(sp)
    80005e2c:	79ba                	ld	s3,424(sp)
    80005e2e:	7a1a                	ld	s4,416(sp)
    80005e30:	6afa                	ld	s5,408(sp)
    80005e32:	6179                	addi	sp,sp,464
    80005e34:	8082                	ret

0000000080005e36 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005e36:	7139                	addi	sp,sp,-64
    80005e38:	fc06                	sd	ra,56(sp)
    80005e3a:	f822                	sd	s0,48(sp)
    80005e3c:	f426                	sd	s1,40(sp)
    80005e3e:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005e40:	ffffc097          	auipc	ra,0xffffc
    80005e44:	e60080e7          	jalr	-416(ra) # 80001ca0 <myproc>
    80005e48:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005e4a:	fd840593          	addi	a1,s0,-40
    80005e4e:	4501                	li	a0,0
    80005e50:	ffffd097          	auipc	ra,0xffffd
    80005e54:	f9e080e7          	jalr	-98(ra) # 80002dee <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005e58:	fc840593          	addi	a1,s0,-56
    80005e5c:	fd040513          	addi	a0,s0,-48
    80005e60:	fffff097          	auipc	ra,0xfffff
    80005e64:	dc6080e7          	jalr	-570(ra) # 80004c26 <pipealloc>
    return -1;
    80005e68:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005e6a:	0c054463          	bltz	a0,80005f32 <sys_pipe+0xfc>
  fd0 = -1;
    80005e6e:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005e72:	fd043503          	ld	a0,-48(s0)
    80005e76:	fffff097          	auipc	ra,0xfffff
    80005e7a:	51a080e7          	jalr	1306(ra) # 80005390 <fdalloc>
    80005e7e:	fca42223          	sw	a0,-60(s0)
    80005e82:	08054b63          	bltz	a0,80005f18 <sys_pipe+0xe2>
    80005e86:	fc843503          	ld	a0,-56(s0)
    80005e8a:	fffff097          	auipc	ra,0xfffff
    80005e8e:	506080e7          	jalr	1286(ra) # 80005390 <fdalloc>
    80005e92:	fca42023          	sw	a0,-64(s0)
    80005e96:	06054863          	bltz	a0,80005f06 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e9a:	4691                	li	a3,4
    80005e9c:	fc440613          	addi	a2,s0,-60
    80005ea0:	fd843583          	ld	a1,-40(s0)
    80005ea4:	68a8                	ld	a0,80(s1)
    80005ea6:	ffffb097          	auipc	ra,0xffffb
    80005eaa:	7ca080e7          	jalr	1994(ra) # 80001670 <copyout>
    80005eae:	02054063          	bltz	a0,80005ece <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005eb2:	4691                	li	a3,4
    80005eb4:	fc040613          	addi	a2,s0,-64
    80005eb8:	fd843583          	ld	a1,-40(s0)
    80005ebc:	0591                	addi	a1,a1,4
    80005ebe:	68a8                	ld	a0,80(s1)
    80005ec0:	ffffb097          	auipc	ra,0xffffb
    80005ec4:	7b0080e7          	jalr	1968(ra) # 80001670 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005ec8:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005eca:	06055463          	bgez	a0,80005f32 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005ece:	fc442783          	lw	a5,-60(s0)
    80005ed2:	07e9                	addi	a5,a5,26
    80005ed4:	078e                	slli	a5,a5,0x3
    80005ed6:	97a6                	add	a5,a5,s1
    80005ed8:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005edc:	fc042503          	lw	a0,-64(s0)
    80005ee0:	0569                	addi	a0,a0,26
    80005ee2:	050e                	slli	a0,a0,0x3
    80005ee4:	94aa                	add	s1,s1,a0
    80005ee6:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005eea:	fd043503          	ld	a0,-48(s0)
    80005eee:	fffff097          	auipc	ra,0xfffff
    80005ef2:	a08080e7          	jalr	-1528(ra) # 800048f6 <fileclose>
    fileclose(wf);
    80005ef6:	fc843503          	ld	a0,-56(s0)
    80005efa:	fffff097          	auipc	ra,0xfffff
    80005efe:	9fc080e7          	jalr	-1540(ra) # 800048f6 <fileclose>
    return -1;
    80005f02:	57fd                	li	a5,-1
    80005f04:	a03d                	j	80005f32 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005f06:	fc442783          	lw	a5,-60(s0)
    80005f0a:	0007c763          	bltz	a5,80005f18 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005f0e:	07e9                	addi	a5,a5,26
    80005f10:	078e                	slli	a5,a5,0x3
    80005f12:	94be                	add	s1,s1,a5
    80005f14:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005f18:	fd043503          	ld	a0,-48(s0)
    80005f1c:	fffff097          	auipc	ra,0xfffff
    80005f20:	9da080e7          	jalr	-1574(ra) # 800048f6 <fileclose>
    fileclose(wf);
    80005f24:	fc843503          	ld	a0,-56(s0)
    80005f28:	fffff097          	auipc	ra,0xfffff
    80005f2c:	9ce080e7          	jalr	-1586(ra) # 800048f6 <fileclose>
    return -1;
    80005f30:	57fd                	li	a5,-1
}
    80005f32:	853e                	mv	a0,a5
    80005f34:	70e2                	ld	ra,56(sp)
    80005f36:	7442                	ld	s0,48(sp)
    80005f38:	74a2                	ld	s1,40(sp)
    80005f3a:	6121                	addi	sp,sp,64
    80005f3c:	8082                	ret
	...

0000000080005f40 <kernelvec>:
    80005f40:	7111                	addi	sp,sp,-256
    80005f42:	e006                	sd	ra,0(sp)
    80005f44:	e40a                	sd	sp,8(sp)
    80005f46:	e80e                	sd	gp,16(sp)
    80005f48:	ec12                	sd	tp,24(sp)
    80005f4a:	f016                	sd	t0,32(sp)
    80005f4c:	f41a                	sd	t1,40(sp)
    80005f4e:	f81e                	sd	t2,48(sp)
    80005f50:	fc22                	sd	s0,56(sp)
    80005f52:	e0a6                	sd	s1,64(sp)
    80005f54:	e4aa                	sd	a0,72(sp)
    80005f56:	e8ae                	sd	a1,80(sp)
    80005f58:	ecb2                	sd	a2,88(sp)
    80005f5a:	f0b6                	sd	a3,96(sp)
    80005f5c:	f4ba                	sd	a4,104(sp)
    80005f5e:	f8be                	sd	a5,112(sp)
    80005f60:	fcc2                	sd	a6,120(sp)
    80005f62:	e146                	sd	a7,128(sp)
    80005f64:	e54a                	sd	s2,136(sp)
    80005f66:	e94e                	sd	s3,144(sp)
    80005f68:	ed52                	sd	s4,152(sp)
    80005f6a:	f156                	sd	s5,160(sp)
    80005f6c:	f55a                	sd	s6,168(sp)
    80005f6e:	f95e                	sd	s7,176(sp)
    80005f70:	fd62                	sd	s8,184(sp)
    80005f72:	e1e6                	sd	s9,192(sp)
    80005f74:	e5ea                	sd	s10,200(sp)
    80005f76:	e9ee                	sd	s11,208(sp)
    80005f78:	edf2                	sd	t3,216(sp)
    80005f7a:	f1f6                	sd	t4,224(sp)
    80005f7c:	f5fa                	sd	t5,232(sp)
    80005f7e:	f9fe                	sd	t6,240(sp)
    80005f80:	c7dfc0ef          	jal	ra,80002bfc <kerneltrap>
    80005f84:	6082                	ld	ra,0(sp)
    80005f86:	6122                	ld	sp,8(sp)
    80005f88:	61c2                	ld	gp,16(sp)
    80005f8a:	7282                	ld	t0,32(sp)
    80005f8c:	7322                	ld	t1,40(sp)
    80005f8e:	73c2                	ld	t2,48(sp)
    80005f90:	7462                	ld	s0,56(sp)
    80005f92:	6486                	ld	s1,64(sp)
    80005f94:	6526                	ld	a0,72(sp)
    80005f96:	65c6                	ld	a1,80(sp)
    80005f98:	6666                	ld	a2,88(sp)
    80005f9a:	7686                	ld	a3,96(sp)
    80005f9c:	7726                	ld	a4,104(sp)
    80005f9e:	77c6                	ld	a5,112(sp)
    80005fa0:	7866                	ld	a6,120(sp)
    80005fa2:	688a                	ld	a7,128(sp)
    80005fa4:	692a                	ld	s2,136(sp)
    80005fa6:	69ca                	ld	s3,144(sp)
    80005fa8:	6a6a                	ld	s4,152(sp)
    80005faa:	7a8a                	ld	s5,160(sp)
    80005fac:	7b2a                	ld	s6,168(sp)
    80005fae:	7bca                	ld	s7,176(sp)
    80005fb0:	7c6a                	ld	s8,184(sp)
    80005fb2:	6c8e                	ld	s9,192(sp)
    80005fb4:	6d2e                	ld	s10,200(sp)
    80005fb6:	6dce                	ld	s11,208(sp)
    80005fb8:	6e6e                	ld	t3,216(sp)
    80005fba:	7e8e                	ld	t4,224(sp)
    80005fbc:	7f2e                	ld	t5,232(sp)
    80005fbe:	7fce                	ld	t6,240(sp)
    80005fc0:	6111                	addi	sp,sp,256
    80005fc2:	10200073          	sret
    80005fc6:	00000013          	nop
    80005fca:	00000013          	nop
    80005fce:	0001                	nop

0000000080005fd0 <timervec>:
    80005fd0:	34051573          	csrrw	a0,mscratch,a0
    80005fd4:	e10c                	sd	a1,0(a0)
    80005fd6:	e510                	sd	a2,8(a0)
    80005fd8:	e914                	sd	a3,16(a0)
    80005fda:	6d0c                	ld	a1,24(a0)
    80005fdc:	7110                	ld	a2,32(a0)
    80005fde:	6194                	ld	a3,0(a1)
    80005fe0:	96b2                	add	a3,a3,a2
    80005fe2:	e194                	sd	a3,0(a1)
    80005fe4:	4589                	li	a1,2
    80005fe6:	14459073          	csrw	sip,a1
    80005fea:	6914                	ld	a3,16(a0)
    80005fec:	6510                	ld	a2,8(a0)
    80005fee:	610c                	ld	a1,0(a0)
    80005ff0:	34051573          	csrrw	a0,mscratch,a0
    80005ff4:	30200073          	mret
	...

0000000080005ffa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005ffa:	1141                	addi	sp,sp,-16
    80005ffc:	e422                	sd	s0,8(sp)
    80005ffe:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006000:	0c0007b7          	lui	a5,0xc000
    80006004:	4705                	li	a4,1
    80006006:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006008:	c3d8                	sw	a4,4(a5)
}
    8000600a:	6422                	ld	s0,8(sp)
    8000600c:	0141                	addi	sp,sp,16
    8000600e:	8082                	ret

0000000080006010 <plicinithart>:

void
plicinithart(void)
{
    80006010:	1141                	addi	sp,sp,-16
    80006012:	e406                	sd	ra,8(sp)
    80006014:	e022                	sd	s0,0(sp)
    80006016:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006018:	ffffc097          	auipc	ra,0xffffc
    8000601c:	c5c080e7          	jalr	-932(ra) # 80001c74 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006020:	0085171b          	slliw	a4,a0,0x8
    80006024:	0c0027b7          	lui	a5,0xc002
    80006028:	97ba                	add	a5,a5,a4
    8000602a:	40200713          	li	a4,1026
    8000602e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006032:	00d5151b          	slliw	a0,a0,0xd
    80006036:	0c2017b7          	lui	a5,0xc201
    8000603a:	953e                	add	a0,a0,a5
    8000603c:	00052023          	sw	zero,0(a0)
}
    80006040:	60a2                	ld	ra,8(sp)
    80006042:	6402                	ld	s0,0(sp)
    80006044:	0141                	addi	sp,sp,16
    80006046:	8082                	ret

0000000080006048 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006048:	1141                	addi	sp,sp,-16
    8000604a:	e406                	sd	ra,8(sp)
    8000604c:	e022                	sd	s0,0(sp)
    8000604e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006050:	ffffc097          	auipc	ra,0xffffc
    80006054:	c24080e7          	jalr	-988(ra) # 80001c74 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006058:	00d5179b          	slliw	a5,a0,0xd
    8000605c:	0c201537          	lui	a0,0xc201
    80006060:	953e                	add	a0,a0,a5
  return irq;
}
    80006062:	4148                	lw	a0,4(a0)
    80006064:	60a2                	ld	ra,8(sp)
    80006066:	6402                	ld	s0,0(sp)
    80006068:	0141                	addi	sp,sp,16
    8000606a:	8082                	ret

000000008000606c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000606c:	1101                	addi	sp,sp,-32
    8000606e:	ec06                	sd	ra,24(sp)
    80006070:	e822                	sd	s0,16(sp)
    80006072:	e426                	sd	s1,8(sp)
    80006074:	1000                	addi	s0,sp,32
    80006076:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006078:	ffffc097          	auipc	ra,0xffffc
    8000607c:	bfc080e7          	jalr	-1028(ra) # 80001c74 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006080:	00d5151b          	slliw	a0,a0,0xd
    80006084:	0c2017b7          	lui	a5,0xc201
    80006088:	97aa                	add	a5,a5,a0
    8000608a:	c3c4                	sw	s1,4(a5)
}
    8000608c:	60e2                	ld	ra,24(sp)
    8000608e:	6442                	ld	s0,16(sp)
    80006090:	64a2                	ld	s1,8(sp)
    80006092:	6105                	addi	sp,sp,32
    80006094:	8082                	ret

0000000080006096 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006096:	1141                	addi	sp,sp,-16
    80006098:	e406                	sd	ra,8(sp)
    8000609a:	e022                	sd	s0,0(sp)
    8000609c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000609e:	479d                	li	a5,7
    800060a0:	04a7cc63          	blt	a5,a0,800060f8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    800060a4:	0001c797          	auipc	a5,0x1c
    800060a8:	c0c78793          	addi	a5,a5,-1012 # 80021cb0 <disk>
    800060ac:	97aa                	add	a5,a5,a0
    800060ae:	0187c783          	lbu	a5,24(a5)
    800060b2:	ebb9                	bnez	a5,80006108 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800060b4:	00451613          	slli	a2,a0,0x4
    800060b8:	0001c797          	auipc	a5,0x1c
    800060bc:	bf878793          	addi	a5,a5,-1032 # 80021cb0 <disk>
    800060c0:	6394                	ld	a3,0(a5)
    800060c2:	96b2                	add	a3,a3,a2
    800060c4:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800060c8:	6398                	ld	a4,0(a5)
    800060ca:	9732                	add	a4,a4,a2
    800060cc:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800060d0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800060d4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800060d8:	953e                	add	a0,a0,a5
    800060da:	4785                	li	a5,1
    800060dc:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    800060e0:	0001c517          	auipc	a0,0x1c
    800060e4:	be850513          	addi	a0,a0,-1048 # 80021cc8 <disk+0x18>
    800060e8:	ffffc097          	auipc	ra,0xffffc
    800060ec:	2c4080e7          	jalr	708(ra) # 800023ac <wakeup>
}
    800060f0:	60a2                	ld	ra,8(sp)
    800060f2:	6402                	ld	s0,0(sp)
    800060f4:	0141                	addi	sp,sp,16
    800060f6:	8082                	ret
    panic("free_desc 1");
    800060f8:	00002517          	auipc	a0,0x2
    800060fc:	6f850513          	addi	a0,a0,1784 # 800087f0 <syscalls+0x300>
    80006100:	ffffa097          	auipc	ra,0xffffa
    80006104:	43e080e7          	jalr	1086(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006108:	00002517          	auipc	a0,0x2
    8000610c:	6f850513          	addi	a0,a0,1784 # 80008800 <syscalls+0x310>
    80006110:	ffffa097          	auipc	ra,0xffffa
    80006114:	42e080e7          	jalr	1070(ra) # 8000053e <panic>

0000000080006118 <virtio_disk_init>:
{
    80006118:	1101                	addi	sp,sp,-32
    8000611a:	ec06                	sd	ra,24(sp)
    8000611c:	e822                	sd	s0,16(sp)
    8000611e:	e426                	sd	s1,8(sp)
    80006120:	e04a                	sd	s2,0(sp)
    80006122:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006124:	00002597          	auipc	a1,0x2
    80006128:	6ec58593          	addi	a1,a1,1772 # 80008810 <syscalls+0x320>
    8000612c:	0001c517          	auipc	a0,0x1c
    80006130:	cac50513          	addi	a0,a0,-852 # 80021dd8 <disk+0x128>
    80006134:	ffffb097          	auipc	ra,0xffffb
    80006138:	a12080e7          	jalr	-1518(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000613c:	100017b7          	lui	a5,0x10001
    80006140:	4398                	lw	a4,0(a5)
    80006142:	2701                	sext.w	a4,a4
    80006144:	747277b7          	lui	a5,0x74727
    80006148:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000614c:	14f71c63          	bne	a4,a5,800062a4 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006150:	100017b7          	lui	a5,0x10001
    80006154:	43dc                	lw	a5,4(a5)
    80006156:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006158:	4709                	li	a4,2
    8000615a:	14e79563          	bne	a5,a4,800062a4 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000615e:	100017b7          	lui	a5,0x10001
    80006162:	479c                	lw	a5,8(a5)
    80006164:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006166:	12e79f63          	bne	a5,a4,800062a4 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000616a:	100017b7          	lui	a5,0x10001
    8000616e:	47d8                	lw	a4,12(a5)
    80006170:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006172:	554d47b7          	lui	a5,0x554d4
    80006176:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000617a:	12f71563          	bne	a4,a5,800062a4 <virtio_disk_init+0x18c>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000617e:	100017b7          	lui	a5,0x10001
    80006182:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006186:	4705                	li	a4,1
    80006188:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000618a:	470d                	li	a4,3
    8000618c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000618e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006190:	c7ffe737          	lui	a4,0xc7ffe
    80006194:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc96f>
    80006198:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000619a:	2701                	sext.w	a4,a4
    8000619c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000619e:	472d                	li	a4,11
    800061a0:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    800061a2:	5bbc                	lw	a5,112(a5)
    800061a4:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    800061a8:	8ba1                	andi	a5,a5,8
    800061aa:	10078563          	beqz	a5,800062b4 <virtio_disk_init+0x19c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800061ae:	100017b7          	lui	a5,0x10001
    800061b2:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800061b6:	43fc                	lw	a5,68(a5)
    800061b8:	2781                	sext.w	a5,a5
    800061ba:	10079563          	bnez	a5,800062c4 <virtio_disk_init+0x1ac>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800061be:	100017b7          	lui	a5,0x10001
    800061c2:	5bdc                	lw	a5,52(a5)
    800061c4:	2781                	sext.w	a5,a5
  if(max == 0)
    800061c6:	10078763          	beqz	a5,800062d4 <virtio_disk_init+0x1bc>
  if(max < NUM)
    800061ca:	471d                	li	a4,7
    800061cc:	10f77c63          	bgeu	a4,a5,800062e4 <virtio_disk_init+0x1cc>
  disk.desc = kalloc();
    800061d0:	ffffb097          	auipc	ra,0xffffb
    800061d4:	916080e7          	jalr	-1770(ra) # 80000ae6 <kalloc>
    800061d8:	0001c497          	auipc	s1,0x1c
    800061dc:	ad848493          	addi	s1,s1,-1320 # 80021cb0 <disk>
    800061e0:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800061e2:	ffffb097          	auipc	ra,0xffffb
    800061e6:	904080e7          	jalr	-1788(ra) # 80000ae6 <kalloc>
    800061ea:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800061ec:	ffffb097          	auipc	ra,0xffffb
    800061f0:	8fa080e7          	jalr	-1798(ra) # 80000ae6 <kalloc>
    800061f4:	87aa                	mv	a5,a0
    800061f6:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800061f8:	6088                	ld	a0,0(s1)
    800061fa:	cd6d                	beqz	a0,800062f4 <virtio_disk_init+0x1dc>
    800061fc:	0001c717          	auipc	a4,0x1c
    80006200:	abc73703          	ld	a4,-1348(a4) # 80021cb8 <disk+0x8>
    80006204:	cb65                	beqz	a4,800062f4 <virtio_disk_init+0x1dc>
    80006206:	c7fd                	beqz	a5,800062f4 <virtio_disk_init+0x1dc>
  memset(disk.desc, 0, PGSIZE);
    80006208:	6605                	lui	a2,0x1
    8000620a:	4581                	li	a1,0
    8000620c:	ffffb097          	auipc	ra,0xffffb
    80006210:	ac6080e7          	jalr	-1338(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006214:	0001c497          	auipc	s1,0x1c
    80006218:	a9c48493          	addi	s1,s1,-1380 # 80021cb0 <disk>
    8000621c:	6605                	lui	a2,0x1
    8000621e:	4581                	li	a1,0
    80006220:	6488                	ld	a0,8(s1)
    80006222:	ffffb097          	auipc	ra,0xffffb
    80006226:	ab0080e7          	jalr	-1360(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    8000622a:	6605                	lui	a2,0x1
    8000622c:	4581                	li	a1,0
    8000622e:	6888                	ld	a0,16(s1)
    80006230:	ffffb097          	auipc	ra,0xffffb
    80006234:	aa2080e7          	jalr	-1374(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006238:	100017b7          	lui	a5,0x10001
    8000623c:	4721                	li	a4,8
    8000623e:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006240:	4098                	lw	a4,0(s1)
    80006242:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006246:	40d8                	lw	a4,4(s1)
    80006248:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000624c:	6498                	ld	a4,8(s1)
    8000624e:	0007069b          	sext.w	a3,a4
    80006252:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006256:	9701                	srai	a4,a4,0x20
    80006258:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000625c:	6898                	ld	a4,16(s1)
    8000625e:	0007069b          	sext.w	a3,a4
    80006262:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006266:	9701                	srai	a4,a4,0x20
    80006268:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000626c:	4705                	li	a4,1
    8000626e:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80006270:	00e48c23          	sb	a4,24(s1)
    80006274:	00e48ca3          	sb	a4,25(s1)
    80006278:	00e48d23          	sb	a4,26(s1)
    8000627c:	00e48da3          	sb	a4,27(s1)
    80006280:	00e48e23          	sb	a4,28(s1)
    80006284:	00e48ea3          	sb	a4,29(s1)
    80006288:	00e48f23          	sb	a4,30(s1)
    8000628c:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006290:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006294:	0727a823          	sw	s2,112(a5)
}
    80006298:	60e2                	ld	ra,24(sp)
    8000629a:	6442                	ld	s0,16(sp)
    8000629c:	64a2                	ld	s1,8(sp)
    8000629e:	6902                	ld	s2,0(sp)
    800062a0:	6105                	addi	sp,sp,32
    800062a2:	8082                	ret
    panic("could not find virtio disk");
    800062a4:	00002517          	auipc	a0,0x2
    800062a8:	57c50513          	addi	a0,a0,1404 # 80008820 <syscalls+0x330>
    800062ac:	ffffa097          	auipc	ra,0xffffa
    800062b0:	292080e7          	jalr	658(ra) # 8000053e <panic>
    panic("virtio disk FEATURES_OK unset");
    800062b4:	00002517          	auipc	a0,0x2
    800062b8:	58c50513          	addi	a0,a0,1420 # 80008840 <syscalls+0x350>
    800062bc:	ffffa097          	auipc	ra,0xffffa
    800062c0:	282080e7          	jalr	642(ra) # 8000053e <panic>
    panic("virtio disk should not be ready");
    800062c4:	00002517          	auipc	a0,0x2
    800062c8:	59c50513          	addi	a0,a0,1436 # 80008860 <syscalls+0x370>
    800062cc:	ffffa097          	auipc	ra,0xffffa
    800062d0:	272080e7          	jalr	626(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800062d4:	00002517          	auipc	a0,0x2
    800062d8:	5ac50513          	addi	a0,a0,1452 # 80008880 <syscalls+0x390>
    800062dc:	ffffa097          	auipc	ra,0xffffa
    800062e0:	262080e7          	jalr	610(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800062e4:	00002517          	auipc	a0,0x2
    800062e8:	5bc50513          	addi	a0,a0,1468 # 800088a0 <syscalls+0x3b0>
    800062ec:	ffffa097          	auipc	ra,0xffffa
    800062f0:	252080e7          	jalr	594(ra) # 8000053e <panic>
    panic("virtio disk kalloc");
    800062f4:	00002517          	auipc	a0,0x2
    800062f8:	5cc50513          	addi	a0,a0,1484 # 800088c0 <syscalls+0x3d0>
    800062fc:	ffffa097          	auipc	ra,0xffffa
    80006300:	242080e7          	jalr	578(ra) # 8000053e <panic>

0000000080006304 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006304:	7119                	addi	sp,sp,-128
    80006306:	fc86                	sd	ra,120(sp)
    80006308:	f8a2                	sd	s0,112(sp)
    8000630a:	f4a6                	sd	s1,104(sp)
    8000630c:	f0ca                	sd	s2,96(sp)
    8000630e:	ecce                	sd	s3,88(sp)
    80006310:	e8d2                	sd	s4,80(sp)
    80006312:	e4d6                	sd	s5,72(sp)
    80006314:	e0da                	sd	s6,64(sp)
    80006316:	fc5e                	sd	s7,56(sp)
    80006318:	f862                	sd	s8,48(sp)
    8000631a:	f466                	sd	s9,40(sp)
    8000631c:	f06a                	sd	s10,32(sp)
    8000631e:	ec6e                	sd	s11,24(sp)
    80006320:	0100                	addi	s0,sp,128
    80006322:	8aaa                	mv	s5,a0
    80006324:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006326:	00c52d03          	lw	s10,12(a0)
    8000632a:	001d1d1b          	slliw	s10,s10,0x1
    8000632e:	1d02                	slli	s10,s10,0x20
    80006330:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006334:	0001c517          	auipc	a0,0x1c
    80006338:	aa450513          	addi	a0,a0,-1372 # 80021dd8 <disk+0x128>
    8000633c:	ffffb097          	auipc	ra,0xffffb
    80006340:	89a080e7          	jalr	-1894(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80006344:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006346:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006348:	0001cb97          	auipc	s7,0x1c
    8000634c:	968b8b93          	addi	s7,s7,-1688 # 80021cb0 <disk>
  for(int i = 0; i < 3; i++){
    80006350:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006352:	0001cc97          	auipc	s9,0x1c
    80006356:	a86c8c93          	addi	s9,s9,-1402 # 80021dd8 <disk+0x128>
    8000635a:	a08d                	j	800063bc <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000635c:	00fb8733          	add	a4,s7,a5
    80006360:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006364:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006366:	0207c563          	bltz	a5,80006390 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    8000636a:	2905                	addiw	s2,s2,1
    8000636c:	0611                	addi	a2,a2,4
    8000636e:	05690c63          	beq	s2,s6,800063c6 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006372:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006374:	0001c717          	auipc	a4,0x1c
    80006378:	93c70713          	addi	a4,a4,-1732 # 80021cb0 <disk>
    8000637c:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000637e:	01874683          	lbu	a3,24(a4)
    80006382:	fee9                	bnez	a3,8000635c <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006384:	2785                	addiw	a5,a5,1
    80006386:	0705                	addi	a4,a4,1
    80006388:	fe979be3          	bne	a5,s1,8000637e <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000638c:	57fd                	li	a5,-1
    8000638e:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006390:	01205d63          	blez	s2,800063aa <virtio_disk_rw+0xa6>
    80006394:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006396:	000a2503          	lw	a0,0(s4)
    8000639a:	00000097          	auipc	ra,0x0
    8000639e:	cfc080e7          	jalr	-772(ra) # 80006096 <free_desc>
      for(int j = 0; j < i; j++)
    800063a2:	2d85                	addiw	s11,s11,1
    800063a4:	0a11                	addi	s4,s4,4
    800063a6:	ffb918e3          	bne	s2,s11,80006396 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800063aa:	85e6                	mv	a1,s9
    800063ac:	0001c517          	auipc	a0,0x1c
    800063b0:	91c50513          	addi	a0,a0,-1764 # 80021cc8 <disk+0x18>
    800063b4:	ffffc097          	auipc	ra,0xffffc
    800063b8:	f94080e7          	jalr	-108(ra) # 80002348 <sleep>
  for(int i = 0; i < 3; i++){
    800063bc:	f8040a13          	addi	s4,s0,-128
{
    800063c0:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800063c2:	894e                	mv	s2,s3
    800063c4:	b77d                	j	80006372 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800063c6:	f8042583          	lw	a1,-128(s0)
    800063ca:	00a58793          	addi	a5,a1,10
    800063ce:	0792                	slli	a5,a5,0x4

  if(write)
    800063d0:	0001c617          	auipc	a2,0x1c
    800063d4:	8e060613          	addi	a2,a2,-1824 # 80021cb0 <disk>
    800063d8:	00f60733          	add	a4,a2,a5
    800063dc:	018036b3          	snez	a3,s8
    800063e0:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800063e2:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    800063e6:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800063ea:	f6078693          	addi	a3,a5,-160
    800063ee:	6218                	ld	a4,0(a2)
    800063f0:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800063f2:	00878513          	addi	a0,a5,8
    800063f6:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    800063f8:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800063fa:	6208                	ld	a0,0(a2)
    800063fc:	96aa                	add	a3,a3,a0
    800063fe:	4741                	li	a4,16
    80006400:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006402:	4705                	li	a4,1
    80006404:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006408:	f8442703          	lw	a4,-124(s0)
    8000640c:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006410:	0712                	slli	a4,a4,0x4
    80006412:	953a                	add	a0,a0,a4
    80006414:	058a8693          	addi	a3,s5,88
    80006418:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000641a:	6208                	ld	a0,0(a2)
    8000641c:	972a                	add	a4,a4,a0
    8000641e:	40000693          	li	a3,1024
    80006422:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006424:	001c3c13          	seqz	s8,s8
    80006428:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000642a:	001c6c13          	ori	s8,s8,1
    8000642e:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    80006432:	f8842603          	lw	a2,-120(s0)
    80006436:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    8000643a:	0001c697          	auipc	a3,0x1c
    8000643e:	87668693          	addi	a3,a3,-1930 # 80021cb0 <disk>
    80006442:	00258713          	addi	a4,a1,2
    80006446:	0712                	slli	a4,a4,0x4
    80006448:	9736                	add	a4,a4,a3
    8000644a:	587d                	li	a6,-1
    8000644c:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006450:	0612                	slli	a2,a2,0x4
    80006452:	9532                	add	a0,a0,a2
    80006454:	f9078793          	addi	a5,a5,-112
    80006458:	97b6                	add	a5,a5,a3
    8000645a:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    8000645c:	629c                	ld	a5,0(a3)
    8000645e:	97b2                	add	a5,a5,a2
    80006460:	4605                	li	a2,1
    80006462:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006464:	4509                	li	a0,2
    80006466:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    8000646a:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000646e:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006472:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006476:	6698                	ld	a4,8(a3)
    80006478:	00275783          	lhu	a5,2(a4)
    8000647c:	8b9d                	andi	a5,a5,7
    8000647e:	0786                	slli	a5,a5,0x1
    80006480:	97ba                	add	a5,a5,a4
    80006482:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006486:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000648a:	6698                	ld	a4,8(a3)
    8000648c:	00275783          	lhu	a5,2(a4)
    80006490:	2785                	addiw	a5,a5,1
    80006492:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006496:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000649a:	100017b7          	lui	a5,0x10001
    8000649e:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800064a2:	004aa783          	lw	a5,4(s5)
    800064a6:	02c79163          	bne	a5,a2,800064c8 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800064aa:	0001c917          	auipc	s2,0x1c
    800064ae:	92e90913          	addi	s2,s2,-1746 # 80021dd8 <disk+0x128>
  while(b->disk == 1) {
    800064b2:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800064b4:	85ca                	mv	a1,s2
    800064b6:	8556                	mv	a0,s5
    800064b8:	ffffc097          	auipc	ra,0xffffc
    800064bc:	e90080e7          	jalr	-368(ra) # 80002348 <sleep>
  while(b->disk == 1) {
    800064c0:	004aa783          	lw	a5,4(s5)
    800064c4:	fe9788e3          	beq	a5,s1,800064b4 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    800064c8:	f8042903          	lw	s2,-128(s0)
    800064cc:	00290793          	addi	a5,s2,2
    800064d0:	00479713          	slli	a4,a5,0x4
    800064d4:	0001b797          	auipc	a5,0x1b
    800064d8:	7dc78793          	addi	a5,a5,2012 # 80021cb0 <disk>
    800064dc:	97ba                	add	a5,a5,a4
    800064de:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800064e2:	0001b997          	auipc	s3,0x1b
    800064e6:	7ce98993          	addi	s3,s3,1998 # 80021cb0 <disk>
    800064ea:	00491713          	slli	a4,s2,0x4
    800064ee:	0009b783          	ld	a5,0(s3)
    800064f2:	97ba                	add	a5,a5,a4
    800064f4:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800064f8:	854a                	mv	a0,s2
    800064fa:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800064fe:	00000097          	auipc	ra,0x0
    80006502:	b98080e7          	jalr	-1128(ra) # 80006096 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006506:	8885                	andi	s1,s1,1
    80006508:	f0ed                	bnez	s1,800064ea <virtio_disk_rw+0x1e6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000650a:	0001c517          	auipc	a0,0x1c
    8000650e:	8ce50513          	addi	a0,a0,-1842 # 80021dd8 <disk+0x128>
    80006512:	ffffa097          	auipc	ra,0xffffa
    80006516:	778080e7          	jalr	1912(ra) # 80000c8a <release>
}
    8000651a:	70e6                	ld	ra,120(sp)
    8000651c:	7446                	ld	s0,112(sp)
    8000651e:	74a6                	ld	s1,104(sp)
    80006520:	7906                	ld	s2,96(sp)
    80006522:	69e6                	ld	s3,88(sp)
    80006524:	6a46                	ld	s4,80(sp)
    80006526:	6aa6                	ld	s5,72(sp)
    80006528:	6b06                	ld	s6,64(sp)
    8000652a:	7be2                	ld	s7,56(sp)
    8000652c:	7c42                	ld	s8,48(sp)
    8000652e:	7ca2                	ld	s9,40(sp)
    80006530:	7d02                	ld	s10,32(sp)
    80006532:	6de2                	ld	s11,24(sp)
    80006534:	6109                	addi	sp,sp,128
    80006536:	8082                	ret

0000000080006538 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006538:	1101                	addi	sp,sp,-32
    8000653a:	ec06                	sd	ra,24(sp)
    8000653c:	e822                	sd	s0,16(sp)
    8000653e:	e426                	sd	s1,8(sp)
    80006540:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006542:	0001b497          	auipc	s1,0x1b
    80006546:	76e48493          	addi	s1,s1,1902 # 80021cb0 <disk>
    8000654a:	0001c517          	auipc	a0,0x1c
    8000654e:	88e50513          	addi	a0,a0,-1906 # 80021dd8 <disk+0x128>
    80006552:	ffffa097          	auipc	ra,0xffffa
    80006556:	684080e7          	jalr	1668(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000655a:	10001737          	lui	a4,0x10001
    8000655e:	533c                	lw	a5,96(a4)
    80006560:	8b8d                	andi	a5,a5,3
    80006562:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006564:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006568:	689c                	ld	a5,16(s1)
    8000656a:	0204d703          	lhu	a4,32(s1)
    8000656e:	0027d783          	lhu	a5,2(a5)
    80006572:	04f70863          	beq	a4,a5,800065c2 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006576:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000657a:	6898                	ld	a4,16(s1)
    8000657c:	0204d783          	lhu	a5,32(s1)
    80006580:	8b9d                	andi	a5,a5,7
    80006582:	078e                	slli	a5,a5,0x3
    80006584:	97ba                	add	a5,a5,a4
    80006586:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006588:	00278713          	addi	a4,a5,2
    8000658c:	0712                	slli	a4,a4,0x4
    8000658e:	9726                	add	a4,a4,s1
    80006590:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006594:	e721                	bnez	a4,800065dc <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006596:	0789                	addi	a5,a5,2
    80006598:	0792                	slli	a5,a5,0x4
    8000659a:	97a6                	add	a5,a5,s1
    8000659c:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000659e:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800065a2:	ffffc097          	auipc	ra,0xffffc
    800065a6:	e0a080e7          	jalr	-502(ra) # 800023ac <wakeup>

    disk.used_idx += 1;
    800065aa:	0204d783          	lhu	a5,32(s1)
    800065ae:	2785                	addiw	a5,a5,1
    800065b0:	17c2                	slli	a5,a5,0x30
    800065b2:	93c1                	srli	a5,a5,0x30
    800065b4:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800065b8:	6898                	ld	a4,16(s1)
    800065ba:	00275703          	lhu	a4,2(a4)
    800065be:	faf71ce3          	bne	a4,a5,80006576 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800065c2:	0001c517          	auipc	a0,0x1c
    800065c6:	81650513          	addi	a0,a0,-2026 # 80021dd8 <disk+0x128>
    800065ca:	ffffa097          	auipc	ra,0xffffa
    800065ce:	6c0080e7          	jalr	1728(ra) # 80000c8a <release>
}
    800065d2:	60e2                	ld	ra,24(sp)
    800065d4:	6442                	ld	s0,16(sp)
    800065d6:	64a2                	ld	s1,8(sp)
    800065d8:	6105                	addi	sp,sp,32
    800065da:	8082                	ret
      panic("virtio_disk_intr status");
    800065dc:	00002517          	auipc	a0,0x2
    800065e0:	2fc50513          	addi	a0,a0,764 # 800088d8 <syscalls+0x3e8>
    800065e4:	ffffa097          	auipc	ra,0xffffa
    800065e8:	f5a080e7          	jalr	-166(ra) # 8000053e <panic>
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
