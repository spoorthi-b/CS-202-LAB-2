
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	19010113          	addi	sp,sp,400 # 80009190 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
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
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	00070713          	mv	a4,a4
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	d3e78793          	addi	a5,a5,-706 # 80005da0 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd747f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	dc678793          	addi	a5,a5,-570 # 80000e72 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	53a080e7          	jalr	1338(ra) # 80002664 <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	77e080e7          	jalr	1918(ra) # 800008b8 <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
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
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

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
    8000018e:	00650513          	addi	a0,a0,6 # 80011190 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a3e080e7          	jalr	-1474(ra) # 80000bd0 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	ff648493          	addi	s1,s1,-10 # 80011190 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	08690913          	addi	s2,s2,134 # 80011228 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

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
    800001b0:	07305863          	blez	s3,80000220 <consoleread+0xbc>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71463          	bne	a4,a5,800001e4 <consoleread+0x80>
      if(myproc()->killed){
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	8b2080e7          	jalr	-1870(ra) # 80001a72 <myproc>
    800001c8:	551c                	lw	a5,40(a0)
    800001ca:	e7b5                	bnez	a5,80000236 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001cc:	85a6                	mv	a1,s1
    800001ce:	854a                	mv	a0,s2
    800001d0:	00002097          	auipc	ra,0x2
    800001d4:	09a080e7          	jalr	154(ra) # 8000226a <sleep>
    while(cons.r == cons.w){
    800001d8:	0984a783          	lw	a5,152(s1)
    800001dc:	09c4a703          	lw	a4,156(s1)
    800001e0:	fef700e3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e4:	0017871b          	addiw	a4,a5,1
    800001e8:	08e4ac23          	sw	a4,152(s1)
    800001ec:	07f7f713          	andi	a4,a5,127
    800001f0:	9726                	add	a4,a4,s1
    800001f2:	01874703          	lbu	a4,24(a4)
    800001f6:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    800001fa:	077d0563          	beq	s10,s7,80000264 <consoleread+0x100>
    cbuf = c;
    800001fe:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000202:	4685                	li	a3,1
    80000204:	f9f40613          	addi	a2,s0,-97
    80000208:	85d2                	mv	a1,s4
    8000020a:	8556                	mv	a0,s5
    8000020c:	00002097          	auipc	ra,0x2
    80000210:	402080e7          	jalr	1026(ra) # 8000260e <either_copyout>
    80000214:	01850663          	beq	a0,s8,80000220 <consoleread+0xbc>
    dst++;
    80000218:	0a05                	addi	s4,s4,1
    --n;
    8000021a:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    8000021c:	f99d1ae3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000220:	00011517          	auipc	a0,0x11
    80000224:	f7050513          	addi	a0,a0,-144 # 80011190 <cons>
    80000228:	00001097          	auipc	ra,0x1
    8000022c:	a5c080e7          	jalr	-1444(ra) # 80000c84 <release>

  return target - n;
    80000230:	413b053b          	subw	a0,s6,s3
    80000234:	a811                	j	80000248 <consoleread+0xe4>
        release(&cons.lock);
    80000236:	00011517          	auipc	a0,0x11
    8000023a:	f5a50513          	addi	a0,a0,-166 # 80011190 <cons>
    8000023e:	00001097          	auipc	ra,0x1
    80000242:	a46080e7          	jalr	-1466(ra) # 80000c84 <release>
        return -1;
    80000246:	557d                	li	a0,-1
}
    80000248:	70a6                	ld	ra,104(sp)
    8000024a:	7406                	ld	s0,96(sp)
    8000024c:	64e6                	ld	s1,88(sp)
    8000024e:	6946                	ld	s2,80(sp)
    80000250:	69a6                	ld	s3,72(sp)
    80000252:	6a06                	ld	s4,64(sp)
    80000254:	7ae2                	ld	s5,56(sp)
    80000256:	7b42                	ld	s6,48(sp)
    80000258:	7ba2                	ld	s7,40(sp)
    8000025a:	7c02                	ld	s8,32(sp)
    8000025c:	6ce2                	ld	s9,24(sp)
    8000025e:	6d42                	ld	s10,16(sp)
    80000260:	6165                	addi	sp,sp,112
    80000262:	8082                	ret
      if(n < target){
    80000264:	0009871b          	sext.w	a4,s3
    80000268:	fb677ce3          	bgeu	a4,s6,80000220 <consoleread+0xbc>
        cons.r--;
    8000026c:	00011717          	auipc	a4,0x11
    80000270:	faf72e23          	sw	a5,-68(a4) # 80011228 <cons+0x98>
    80000274:	b775                	j	80000220 <consoleread+0xbc>

0000000080000276 <consputc>:
{
    80000276:	1141                	addi	sp,sp,-16
    80000278:	e406                	sd	ra,8(sp)
    8000027a:	e022                	sd	s0,0(sp)
    8000027c:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000027e:	10000793          	li	a5,256
    80000282:	00f50a63          	beq	a0,a5,80000296 <consputc+0x20>
    uartputc_sync(c);
    80000286:	00000097          	auipc	ra,0x0
    8000028a:	560080e7          	jalr	1376(ra) # 800007e6 <uartputc_sync>
}
    8000028e:	60a2                	ld	ra,8(sp)
    80000290:	6402                	ld	s0,0(sp)
    80000292:	0141                	addi	sp,sp,16
    80000294:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000296:	4521                	li	a0,8
    80000298:	00000097          	auipc	ra,0x0
    8000029c:	54e080e7          	jalr	1358(ra) # 800007e6 <uartputc_sync>
    800002a0:	02000513          	li	a0,32
    800002a4:	00000097          	auipc	ra,0x0
    800002a8:	542080e7          	jalr	1346(ra) # 800007e6 <uartputc_sync>
    800002ac:	4521                	li	a0,8
    800002ae:	00000097          	auipc	ra,0x0
    800002b2:	538080e7          	jalr	1336(ra) # 800007e6 <uartputc_sync>
    800002b6:	bfe1                	j	8000028e <consputc+0x18>

00000000800002b8 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002b8:	1101                	addi	sp,sp,-32
    800002ba:	ec06                	sd	ra,24(sp)
    800002bc:	e822                	sd	s0,16(sp)
    800002be:	e426                	sd	s1,8(sp)
    800002c0:	e04a                	sd	s2,0(sp)
    800002c2:	1000                	addi	s0,sp,32
    800002c4:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002c6:	00011517          	auipc	a0,0x11
    800002ca:	eca50513          	addi	a0,a0,-310 # 80011190 <cons>
    800002ce:	00001097          	auipc	ra,0x1
    800002d2:	902080e7          	jalr	-1790(ra) # 80000bd0 <acquire>

  switch(c){
    800002d6:	47d5                	li	a5,21
    800002d8:	0af48663          	beq	s1,a5,80000384 <consoleintr+0xcc>
    800002dc:	0297ca63          	blt	a5,s1,80000310 <consoleintr+0x58>
    800002e0:	47a1                	li	a5,8
    800002e2:	0ef48763          	beq	s1,a5,800003d0 <consoleintr+0x118>
    800002e6:	47c1                	li	a5,16
    800002e8:	10f49a63          	bne	s1,a5,800003fc <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002ec:	00002097          	auipc	ra,0x2
    800002f0:	3ce080e7          	jalr	974(ra) # 800026ba <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002f4:	00011517          	auipc	a0,0x11
    800002f8:	e9c50513          	addi	a0,a0,-356 # 80011190 <cons>
    800002fc:	00001097          	auipc	ra,0x1
    80000300:	988080e7          	jalr	-1656(ra) # 80000c84 <release>
}
    80000304:	60e2                	ld	ra,24(sp)
    80000306:	6442                	ld	s0,16(sp)
    80000308:	64a2                	ld	s1,8(sp)
    8000030a:	6902                	ld	s2,0(sp)
    8000030c:	6105                	addi	sp,sp,32
    8000030e:	8082                	ret
  switch(c){
    80000310:	07f00793          	li	a5,127
    80000314:	0af48e63          	beq	s1,a5,800003d0 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000318:	00011717          	auipc	a4,0x11
    8000031c:	e7870713          	addi	a4,a4,-392 # 80011190 <cons>
    80000320:	0a072783          	lw	a5,160(a4)
    80000324:	09872703          	lw	a4,152(a4)
    80000328:	9f99                	subw	a5,a5,a4
    8000032a:	07f00713          	li	a4,127
    8000032e:	fcf763e3          	bltu	a4,a5,800002f4 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000332:	47b5                	li	a5,13
    80000334:	0cf48763          	beq	s1,a5,80000402 <consoleintr+0x14a>
      consputc(c);
    80000338:	8526                	mv	a0,s1
    8000033a:	00000097          	auipc	ra,0x0
    8000033e:	f3c080e7          	jalr	-196(ra) # 80000276 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000342:	00011797          	auipc	a5,0x11
    80000346:	e4e78793          	addi	a5,a5,-434 # 80011190 <cons>
    8000034a:	0a07a703          	lw	a4,160(a5)
    8000034e:	0017069b          	addiw	a3,a4,1
    80000352:	0006861b          	sext.w	a2,a3
    80000356:	0ad7a023          	sw	a3,160(a5)
    8000035a:	07f77713          	andi	a4,a4,127
    8000035e:	97ba                	add	a5,a5,a4
    80000360:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000364:	47a9                	li	a5,10
    80000366:	0cf48563          	beq	s1,a5,80000430 <consoleintr+0x178>
    8000036a:	4791                	li	a5,4
    8000036c:	0cf48263          	beq	s1,a5,80000430 <consoleintr+0x178>
    80000370:	00011797          	auipc	a5,0x11
    80000374:	eb87a783          	lw	a5,-328(a5) # 80011228 <cons+0x98>
    80000378:	0807879b          	addiw	a5,a5,128
    8000037c:	f6f61ce3          	bne	a2,a5,800002f4 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000380:	863e                	mv	a2,a5
    80000382:	a07d                	j	80000430 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000384:	00011717          	auipc	a4,0x11
    80000388:	e0c70713          	addi	a4,a4,-500 # 80011190 <cons>
    8000038c:	0a072783          	lw	a5,160(a4)
    80000390:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    80000394:	00011497          	auipc	s1,0x11
    80000398:	dfc48493          	addi	s1,s1,-516 # 80011190 <cons>
    while(cons.e != cons.w &&
    8000039c:	4929                	li	s2,10
    8000039e:	f4f70be3          	beq	a4,a5,800002f4 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a2:	37fd                	addiw	a5,a5,-1
    800003a4:	07f7f713          	andi	a4,a5,127
    800003a8:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003aa:	01874703          	lbu	a4,24(a4)
    800003ae:	f52703e3          	beq	a4,s2,800002f4 <consoleintr+0x3c>
      cons.e--;
    800003b2:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003b6:	10000513          	li	a0,256
    800003ba:	00000097          	auipc	ra,0x0
    800003be:	ebc080e7          	jalr	-324(ra) # 80000276 <consputc>
    while(cons.e != cons.w &&
    800003c2:	0a04a783          	lw	a5,160(s1)
    800003c6:	09c4a703          	lw	a4,156(s1)
    800003ca:	fcf71ce3          	bne	a4,a5,800003a2 <consoleintr+0xea>
    800003ce:	b71d                	j	800002f4 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d0:	00011717          	auipc	a4,0x11
    800003d4:	dc070713          	addi	a4,a4,-576 # 80011190 <cons>
    800003d8:	0a072783          	lw	a5,160(a4)
    800003dc:	09c72703          	lw	a4,156(a4)
    800003e0:	f0f70ae3          	beq	a4,a5,800002f4 <consoleintr+0x3c>
      cons.e--;
    800003e4:	37fd                	addiw	a5,a5,-1
    800003e6:	00011717          	auipc	a4,0x11
    800003ea:	e4f72523          	sw	a5,-438(a4) # 80011230 <cons+0xa0>
      consputc(BACKSPACE);
    800003ee:	10000513          	li	a0,256
    800003f2:	00000097          	auipc	ra,0x0
    800003f6:	e84080e7          	jalr	-380(ra) # 80000276 <consputc>
    800003fa:	bded                	j	800002f4 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    800003fc:	ee048ce3          	beqz	s1,800002f4 <consoleintr+0x3c>
    80000400:	bf21                	j	80000318 <consoleintr+0x60>
      consputc(c);
    80000402:	4529                	li	a0,10
    80000404:	00000097          	auipc	ra,0x0
    80000408:	e72080e7          	jalr	-398(ra) # 80000276 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000040c:	00011797          	auipc	a5,0x11
    80000410:	d8478793          	addi	a5,a5,-636 # 80011190 <cons>
    80000414:	0a07a703          	lw	a4,160(a5)
    80000418:	0017069b          	addiw	a3,a4,1
    8000041c:	0006861b          	sext.w	a2,a3
    80000420:	0ad7a023          	sw	a3,160(a5)
    80000424:	07f77713          	andi	a4,a4,127
    80000428:	97ba                	add	a5,a5,a4
    8000042a:	4729                	li	a4,10
    8000042c:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000430:	00011797          	auipc	a5,0x11
    80000434:	dec7ae23          	sw	a2,-516(a5) # 8001122c <cons+0x9c>
        wakeup(&cons.r);
    80000438:	00011517          	auipc	a0,0x11
    8000043c:	df050513          	addi	a0,a0,-528 # 80011228 <cons+0x98>
    80000440:	00002097          	auipc	ra,0x2
    80000444:	fb6080e7          	jalr	-74(ra) # 800023f6 <wakeup>
    80000448:	b575                	j	800002f4 <consoleintr+0x3c>

000000008000044a <consoleinit>:

void
consoleinit(void)
{
    8000044a:	1141                	addi	sp,sp,-16
    8000044c:	e406                	sd	ra,8(sp)
    8000044e:	e022                	sd	s0,0(sp)
    80000450:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000452:	00008597          	auipc	a1,0x8
    80000456:	bbe58593          	addi	a1,a1,-1090 # 80008010 <etext+0x10>
    8000045a:	00011517          	auipc	a0,0x11
    8000045e:	d3650513          	addi	a0,a0,-714 # 80011190 <cons>
    80000462:	00000097          	auipc	ra,0x0
    80000466:	6de080e7          	jalr	1758(ra) # 80000b40 <initlock>

  uartinit();
    8000046a:	00000097          	auipc	ra,0x0
    8000046e:	32c080e7          	jalr	812(ra) # 80000796 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000472:	00021797          	auipc	a5,0x21
    80000476:	3b678793          	addi	a5,a5,950 # 80021828 <devsw>
    8000047a:	00000717          	auipc	a4,0x0
    8000047e:	cea70713          	addi	a4,a4,-790 # 80000164 <consoleread>
    80000482:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000484:	00000717          	auipc	a4,0x0
    80000488:	c7c70713          	addi	a4,a4,-900 # 80000100 <consolewrite>
    8000048c:	ef98                	sd	a4,24(a5)
}
    8000048e:	60a2                	ld	ra,8(sp)
    80000490:	6402                	ld	s0,0(sp)
    80000492:	0141                	addi	sp,sp,16
    80000494:	8082                	ret

0000000080000496 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    80000496:	7179                	addi	sp,sp,-48
    80000498:	f406                	sd	ra,40(sp)
    8000049a:	f022                	sd	s0,32(sp)
    8000049c:	ec26                	sd	s1,24(sp)
    8000049e:	e84a                	sd	s2,16(sp)
    800004a0:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a2:	c219                	beqz	a2,800004a8 <printint+0x12>
    800004a4:	08054763          	bltz	a0,80000532 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004a8:	2501                	sext.w	a0,a0
    800004aa:	4881                	li	a7,0
    800004ac:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b0:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b2:	2581                	sext.w	a1,a1
    800004b4:	00008617          	auipc	a2,0x8
    800004b8:	b8c60613          	addi	a2,a2,-1140 # 80008040 <digits>
    800004bc:	883a                	mv	a6,a4
    800004be:	2705                	addiw	a4,a4,1
    800004c0:	02b577bb          	remuw	a5,a0,a1
    800004c4:	1782                	slli	a5,a5,0x20
    800004c6:	9381                	srli	a5,a5,0x20
    800004c8:	97b2                	add	a5,a5,a2
    800004ca:	0007c783          	lbu	a5,0(a5)
    800004ce:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d2:	0005079b          	sext.w	a5,a0
    800004d6:	02b5553b          	divuw	a0,a0,a1
    800004da:	0685                	addi	a3,a3,1
    800004dc:	feb7f0e3          	bgeu	a5,a1,800004bc <printint+0x26>

  if(sign)
    800004e0:	00088c63          	beqz	a7,800004f8 <printint+0x62>
    buf[i++] = '-';
    800004e4:	fe070793          	addi	a5,a4,-32
    800004e8:	00878733          	add	a4,a5,s0
    800004ec:	02d00793          	li	a5,45
    800004f0:	fef70823          	sb	a5,-16(a4)
    800004f4:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004f8:	02e05763          	blez	a4,80000526 <printint+0x90>
    800004fc:	fd040793          	addi	a5,s0,-48
    80000500:	00e784b3          	add	s1,a5,a4
    80000504:	fff78913          	addi	s2,a5,-1
    80000508:	993a                	add	s2,s2,a4
    8000050a:	377d                	addiw	a4,a4,-1
    8000050c:	1702                	slli	a4,a4,0x20
    8000050e:	9301                	srli	a4,a4,0x20
    80000510:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000514:	fff4c503          	lbu	a0,-1(s1)
    80000518:	00000097          	auipc	ra,0x0
    8000051c:	d5e080e7          	jalr	-674(ra) # 80000276 <consputc>
  while(--i >= 0)
    80000520:	14fd                	addi	s1,s1,-1
    80000522:	ff2499e3          	bne	s1,s2,80000514 <printint+0x7e>
}
    80000526:	70a2                	ld	ra,40(sp)
    80000528:	7402                	ld	s0,32(sp)
    8000052a:	64e2                	ld	s1,24(sp)
    8000052c:	6942                	ld	s2,16(sp)
    8000052e:	6145                	addi	sp,sp,48
    80000530:	8082                	ret
    x = -xx;
    80000532:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000536:	4885                	li	a7,1
    x = -xx;
    80000538:	bf95                	j	800004ac <printint+0x16>

000000008000053a <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053a:	1101                	addi	sp,sp,-32
    8000053c:	ec06                	sd	ra,24(sp)
    8000053e:	e822                	sd	s0,16(sp)
    80000540:	e426                	sd	s1,8(sp)
    80000542:	1000                	addi	s0,sp,32
    80000544:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000546:	00011797          	auipc	a5,0x11
    8000054a:	d007a523          	sw	zero,-758(a5) # 80011250 <pr+0x18>
  printf("panic: ");
    8000054e:	00008517          	auipc	a0,0x8
    80000552:	aca50513          	addi	a0,a0,-1334 # 80008018 <etext+0x18>
    80000556:	00000097          	auipc	ra,0x0
    8000055a:	02e080e7          	jalr	46(ra) # 80000584 <printf>
  printf(s);
    8000055e:	8526                	mv	a0,s1
    80000560:	00000097          	auipc	ra,0x0
    80000564:	024080e7          	jalr	36(ra) # 80000584 <printf>
  printf("\n");
    80000568:	00008517          	auipc	a0,0x8
    8000056c:	b6050513          	addi	a0,a0,-1184 # 800080c8 <digits+0x88>
    80000570:	00000097          	auipc	ra,0x0
    80000574:	014080e7          	jalr	20(ra) # 80000584 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000578:	4785                	li	a5,1
    8000057a:	00009717          	auipc	a4,0x9
    8000057e:	a8f72323          	sw	a5,-1402(a4) # 80009000 <panicked>
  for(;;)
    80000582:	a001                	j	80000582 <panic+0x48>

0000000080000584 <printf>:
{
    80000584:	7131                	addi	sp,sp,-192
    80000586:	fc86                	sd	ra,120(sp)
    80000588:	f8a2                	sd	s0,112(sp)
    8000058a:	f4a6                	sd	s1,104(sp)
    8000058c:	f0ca                	sd	s2,96(sp)
    8000058e:	ecce                	sd	s3,88(sp)
    80000590:	e8d2                	sd	s4,80(sp)
    80000592:	e4d6                	sd	s5,72(sp)
    80000594:	e0da                	sd	s6,64(sp)
    80000596:	fc5e                	sd	s7,56(sp)
    80000598:	f862                	sd	s8,48(sp)
    8000059a:	f466                	sd	s9,40(sp)
    8000059c:	f06a                	sd	s10,32(sp)
    8000059e:	ec6e                	sd	s11,24(sp)
    800005a0:	0100                	addi	s0,sp,128
    800005a2:	8a2a                	mv	s4,a0
    800005a4:	e40c                	sd	a1,8(s0)
    800005a6:	e810                	sd	a2,16(s0)
    800005a8:	ec14                	sd	a3,24(s0)
    800005aa:	f018                	sd	a4,32(s0)
    800005ac:	f41c                	sd	a5,40(s0)
    800005ae:	03043823          	sd	a6,48(s0)
    800005b2:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005b6:	00011d97          	auipc	s11,0x11
    800005ba:	c9adad83          	lw	s11,-870(s11) # 80011250 <pr+0x18>
  if(locking)
    800005be:	020d9b63          	bnez	s11,800005f4 <printf+0x70>
  if (fmt == 0)
    800005c2:	040a0263          	beqz	s4,80000606 <printf+0x82>
  va_start(ap, fmt);
    800005c6:	00840793          	addi	a5,s0,8
    800005ca:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005ce:	000a4503          	lbu	a0,0(s4)
    800005d2:	14050f63          	beqz	a0,80000730 <printf+0x1ac>
    800005d6:	4981                	li	s3,0
    if(c != '%'){
    800005d8:	02500a93          	li	s5,37
    switch(c){
    800005dc:	07000b93          	li	s7,112
  consputc('x');
    800005e0:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e2:	00008b17          	auipc	s6,0x8
    800005e6:	a5eb0b13          	addi	s6,s6,-1442 # 80008040 <digits>
    switch(c){
    800005ea:	07300c93          	li	s9,115
    800005ee:	06400c13          	li	s8,100
    800005f2:	a82d                	j	8000062c <printf+0xa8>
    acquire(&pr.lock);
    800005f4:	00011517          	auipc	a0,0x11
    800005f8:	c4450513          	addi	a0,a0,-956 # 80011238 <pr>
    800005fc:	00000097          	auipc	ra,0x0
    80000600:	5d4080e7          	jalr	1492(ra) # 80000bd0 <acquire>
    80000604:	bf7d                	j	800005c2 <printf+0x3e>
    panic("null fmt");
    80000606:	00008517          	auipc	a0,0x8
    8000060a:	a2250513          	addi	a0,a0,-1502 # 80008028 <etext+0x28>
    8000060e:	00000097          	auipc	ra,0x0
    80000612:	f2c080e7          	jalr	-212(ra) # 8000053a <panic>
      consputc(c);
    80000616:	00000097          	auipc	ra,0x0
    8000061a:	c60080e7          	jalr	-928(ra) # 80000276 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000061e:	2985                	addiw	s3,s3,1
    80000620:	013a07b3          	add	a5,s4,s3
    80000624:	0007c503          	lbu	a0,0(a5)
    80000628:	10050463          	beqz	a0,80000730 <printf+0x1ac>
    if(c != '%'){
    8000062c:	ff5515e3          	bne	a0,s5,80000616 <printf+0x92>
    c = fmt[++i] & 0xff;
    80000630:	2985                	addiw	s3,s3,1
    80000632:	013a07b3          	add	a5,s4,s3
    80000636:	0007c783          	lbu	a5,0(a5)
    8000063a:	0007849b          	sext.w	s1,a5
    if(c == 0)
    8000063e:	cbed                	beqz	a5,80000730 <printf+0x1ac>
    switch(c){
    80000640:	05778a63          	beq	a5,s7,80000694 <printf+0x110>
    80000644:	02fbf663          	bgeu	s7,a5,80000670 <printf+0xec>
    80000648:	09978863          	beq	a5,s9,800006d8 <printf+0x154>
    8000064c:	07800713          	li	a4,120
    80000650:	0ce79563          	bne	a5,a4,8000071a <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000654:	f8843783          	ld	a5,-120(s0)
    80000658:	00878713          	addi	a4,a5,8
    8000065c:	f8e43423          	sd	a4,-120(s0)
    80000660:	4605                	li	a2,1
    80000662:	85ea                	mv	a1,s10
    80000664:	4388                	lw	a0,0(a5)
    80000666:	00000097          	auipc	ra,0x0
    8000066a:	e30080e7          	jalr	-464(ra) # 80000496 <printint>
      break;
    8000066e:	bf45                	j	8000061e <printf+0x9a>
    switch(c){
    80000670:	09578f63          	beq	a5,s5,8000070e <printf+0x18a>
    80000674:	0b879363          	bne	a5,s8,8000071a <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000678:	f8843783          	ld	a5,-120(s0)
    8000067c:	00878713          	addi	a4,a5,8
    80000680:	f8e43423          	sd	a4,-120(s0)
    80000684:	4605                	li	a2,1
    80000686:	45a9                	li	a1,10
    80000688:	4388                	lw	a0,0(a5)
    8000068a:	00000097          	auipc	ra,0x0
    8000068e:	e0c080e7          	jalr	-500(ra) # 80000496 <printint>
      break;
    80000692:	b771                	j	8000061e <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000694:	f8843783          	ld	a5,-120(s0)
    80000698:	00878713          	addi	a4,a5,8
    8000069c:	f8e43423          	sd	a4,-120(s0)
    800006a0:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a4:	03000513          	li	a0,48
    800006a8:	00000097          	auipc	ra,0x0
    800006ac:	bce080e7          	jalr	-1074(ra) # 80000276 <consputc>
  consputc('x');
    800006b0:	07800513          	li	a0,120
    800006b4:	00000097          	auipc	ra,0x0
    800006b8:	bc2080e7          	jalr	-1086(ra) # 80000276 <consputc>
    800006bc:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006be:	03c95793          	srli	a5,s2,0x3c
    800006c2:	97da                	add	a5,a5,s6
    800006c4:	0007c503          	lbu	a0,0(a5)
    800006c8:	00000097          	auipc	ra,0x0
    800006cc:	bae080e7          	jalr	-1106(ra) # 80000276 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d0:	0912                	slli	s2,s2,0x4
    800006d2:	34fd                	addiw	s1,s1,-1
    800006d4:	f4ed                	bnez	s1,800006be <printf+0x13a>
    800006d6:	b7a1                	j	8000061e <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006d8:	f8843783          	ld	a5,-120(s0)
    800006dc:	00878713          	addi	a4,a5,8
    800006e0:	f8e43423          	sd	a4,-120(s0)
    800006e4:	6384                	ld	s1,0(a5)
    800006e6:	cc89                	beqz	s1,80000700 <printf+0x17c>
      for(; *s; s++)
    800006e8:	0004c503          	lbu	a0,0(s1)
    800006ec:	d90d                	beqz	a0,8000061e <printf+0x9a>
        consputc(*s);
    800006ee:	00000097          	auipc	ra,0x0
    800006f2:	b88080e7          	jalr	-1144(ra) # 80000276 <consputc>
      for(; *s; s++)
    800006f6:	0485                	addi	s1,s1,1
    800006f8:	0004c503          	lbu	a0,0(s1)
    800006fc:	f96d                	bnez	a0,800006ee <printf+0x16a>
    800006fe:	b705                	j	8000061e <printf+0x9a>
        s = "(null)";
    80000700:	00008497          	auipc	s1,0x8
    80000704:	92048493          	addi	s1,s1,-1760 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000708:	02800513          	li	a0,40
    8000070c:	b7cd                	j	800006ee <printf+0x16a>
      consputc('%');
    8000070e:	8556                	mv	a0,s5
    80000710:	00000097          	auipc	ra,0x0
    80000714:	b66080e7          	jalr	-1178(ra) # 80000276 <consputc>
      break;
    80000718:	b719                	j	8000061e <printf+0x9a>
      consputc('%');
    8000071a:	8556                	mv	a0,s5
    8000071c:	00000097          	auipc	ra,0x0
    80000720:	b5a080e7          	jalr	-1190(ra) # 80000276 <consputc>
      consputc(c);
    80000724:	8526                	mv	a0,s1
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b50080e7          	jalr	-1200(ra) # 80000276 <consputc>
      break;
    8000072e:	bdc5                	j	8000061e <printf+0x9a>
  if(locking)
    80000730:	020d9163          	bnez	s11,80000752 <printf+0x1ce>
}
    80000734:	70e6                	ld	ra,120(sp)
    80000736:	7446                	ld	s0,112(sp)
    80000738:	74a6                	ld	s1,104(sp)
    8000073a:	7906                	ld	s2,96(sp)
    8000073c:	69e6                	ld	s3,88(sp)
    8000073e:	6a46                	ld	s4,80(sp)
    80000740:	6aa6                	ld	s5,72(sp)
    80000742:	6b06                	ld	s6,64(sp)
    80000744:	7be2                	ld	s7,56(sp)
    80000746:	7c42                	ld	s8,48(sp)
    80000748:	7ca2                	ld	s9,40(sp)
    8000074a:	7d02                	ld	s10,32(sp)
    8000074c:	6de2                	ld	s11,24(sp)
    8000074e:	6129                	addi	sp,sp,192
    80000750:	8082                	ret
    release(&pr.lock);
    80000752:	00011517          	auipc	a0,0x11
    80000756:	ae650513          	addi	a0,a0,-1306 # 80011238 <pr>
    8000075a:	00000097          	auipc	ra,0x0
    8000075e:	52a080e7          	jalr	1322(ra) # 80000c84 <release>
}
    80000762:	bfc9                	j	80000734 <printf+0x1b0>

0000000080000764 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000764:	1101                	addi	sp,sp,-32
    80000766:	ec06                	sd	ra,24(sp)
    80000768:	e822                	sd	s0,16(sp)
    8000076a:	e426                	sd	s1,8(sp)
    8000076c:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000076e:	00011497          	auipc	s1,0x11
    80000772:	aca48493          	addi	s1,s1,-1334 # 80011238 <pr>
    80000776:	00008597          	auipc	a1,0x8
    8000077a:	8c258593          	addi	a1,a1,-1854 # 80008038 <etext+0x38>
    8000077e:	8526                	mv	a0,s1
    80000780:	00000097          	auipc	ra,0x0
    80000784:	3c0080e7          	jalr	960(ra) # 80000b40 <initlock>
  pr.locking = 1;
    80000788:	4785                	li	a5,1
    8000078a:	cc9c                	sw	a5,24(s1)
}
    8000078c:	60e2                	ld	ra,24(sp)
    8000078e:	6442                	ld	s0,16(sp)
    80000790:	64a2                	ld	s1,8(sp)
    80000792:	6105                	addi	sp,sp,32
    80000794:	8082                	ret

0000000080000796 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000796:	1141                	addi	sp,sp,-16
    80000798:	e406                	sd	ra,8(sp)
    8000079a:	e022                	sd	s0,0(sp)
    8000079c:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    8000079e:	100007b7          	lui	a5,0x10000
    800007a2:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007a6:	f8000713          	li	a4,-128
    800007aa:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007ae:	470d                	li	a4,3
    800007b0:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b4:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007b8:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007bc:	469d                	li	a3,7
    800007be:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c2:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007c6:	00008597          	auipc	a1,0x8
    800007ca:	89258593          	addi	a1,a1,-1902 # 80008058 <digits+0x18>
    800007ce:	00011517          	auipc	a0,0x11
    800007d2:	a8a50513          	addi	a0,a0,-1398 # 80011258 <uart_tx_lock>
    800007d6:	00000097          	auipc	ra,0x0
    800007da:	36a080e7          	jalr	874(ra) # 80000b40 <initlock>
}
    800007de:	60a2                	ld	ra,8(sp)
    800007e0:	6402                	ld	s0,0(sp)
    800007e2:	0141                	addi	sp,sp,16
    800007e4:	8082                	ret

00000000800007e6 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007e6:	1101                	addi	sp,sp,-32
    800007e8:	ec06                	sd	ra,24(sp)
    800007ea:	e822                	sd	s0,16(sp)
    800007ec:	e426                	sd	s1,8(sp)
    800007ee:	1000                	addi	s0,sp,32
    800007f0:	84aa                	mv	s1,a0
  push_off();
    800007f2:	00000097          	auipc	ra,0x0
    800007f6:	392080e7          	jalr	914(ra) # 80000b84 <push_off>

  if(panicked){
    800007fa:	00009797          	auipc	a5,0x9
    800007fe:	8067a783          	lw	a5,-2042(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000802:	10000737          	lui	a4,0x10000
  if(panicked){
    80000806:	c391                	beqz	a5,8000080a <uartputc_sync+0x24>
    for(;;)
    80000808:	a001                	j	80000808 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080a:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000080e:	0207f793          	andi	a5,a5,32
    80000812:	dfe5                	beqz	a5,8000080a <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000814:	0ff4f513          	zext.b	a0,s1
    80000818:	100007b7          	lui	a5,0x10000
    8000081c:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000820:	00000097          	auipc	ra,0x0
    80000824:	404080e7          	jalr	1028(ra) # 80000c24 <pop_off>
}
    80000828:	60e2                	ld	ra,24(sp)
    8000082a:	6442                	ld	s0,16(sp)
    8000082c:	64a2                	ld	s1,8(sp)
    8000082e:	6105                	addi	sp,sp,32
    80000830:	8082                	ret

0000000080000832 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000832:	00008797          	auipc	a5,0x8
    80000836:	7d67b783          	ld	a5,2006(a5) # 80009008 <uart_tx_r>
    8000083a:	00008717          	auipc	a4,0x8
    8000083e:	7d673703          	ld	a4,2006(a4) # 80009010 <uart_tx_w>
    80000842:	06f70a63          	beq	a4,a5,800008b6 <uartstart+0x84>
{
    80000846:	7139                	addi	sp,sp,-64
    80000848:	fc06                	sd	ra,56(sp)
    8000084a:	f822                	sd	s0,48(sp)
    8000084c:	f426                	sd	s1,40(sp)
    8000084e:	f04a                	sd	s2,32(sp)
    80000850:	ec4e                	sd	s3,24(sp)
    80000852:	e852                	sd	s4,16(sp)
    80000854:	e456                	sd	s5,8(sp)
    80000856:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000858:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000085c:	00011a17          	auipc	s4,0x11
    80000860:	9fca0a13          	addi	s4,s4,-1540 # 80011258 <uart_tx_lock>
    uart_tx_r += 1;
    80000864:	00008497          	auipc	s1,0x8
    80000868:	7a448493          	addi	s1,s1,1956 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000086c:	00008997          	auipc	s3,0x8
    80000870:	7a498993          	addi	s3,s3,1956 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000874:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000878:	02077713          	andi	a4,a4,32
    8000087c:	c705                	beqz	a4,800008a4 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000087e:	01f7f713          	andi	a4,a5,31
    80000882:	9752                	add	a4,a4,s4
    80000884:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    80000888:	0785                	addi	a5,a5,1
    8000088a:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000088c:	8526                	mv	a0,s1
    8000088e:	00002097          	auipc	ra,0x2
    80000892:	b68080e7          	jalr	-1176(ra) # 800023f6 <wakeup>
    
    WriteReg(THR, c);
    80000896:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089a:	609c                	ld	a5,0(s1)
    8000089c:	0009b703          	ld	a4,0(s3)
    800008a0:	fcf71ae3          	bne	a4,a5,80000874 <uartstart+0x42>
  }
}
    800008a4:	70e2                	ld	ra,56(sp)
    800008a6:	7442                	ld	s0,48(sp)
    800008a8:	74a2                	ld	s1,40(sp)
    800008aa:	7902                	ld	s2,32(sp)
    800008ac:	69e2                	ld	s3,24(sp)
    800008ae:	6a42                	ld	s4,16(sp)
    800008b0:	6aa2                	ld	s5,8(sp)
    800008b2:	6121                	addi	sp,sp,64
    800008b4:	8082                	ret
    800008b6:	8082                	ret

00000000800008b8 <uartputc>:
{
    800008b8:	7179                	addi	sp,sp,-48
    800008ba:	f406                	sd	ra,40(sp)
    800008bc:	f022                	sd	s0,32(sp)
    800008be:	ec26                	sd	s1,24(sp)
    800008c0:	e84a                	sd	s2,16(sp)
    800008c2:	e44e                	sd	s3,8(sp)
    800008c4:	e052                	sd	s4,0(sp)
    800008c6:	1800                	addi	s0,sp,48
    800008c8:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ca:	00011517          	auipc	a0,0x11
    800008ce:	98e50513          	addi	a0,a0,-1650 # 80011258 <uart_tx_lock>
    800008d2:	00000097          	auipc	ra,0x0
    800008d6:	2fe080e7          	jalr	766(ra) # 80000bd0 <acquire>
  if(panicked){
    800008da:	00008797          	auipc	a5,0x8
    800008de:	7267a783          	lw	a5,1830(a5) # 80009000 <panicked>
    800008e2:	c391                	beqz	a5,800008e6 <uartputc+0x2e>
    for(;;)
    800008e4:	a001                	j	800008e4 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e6:	00008717          	auipc	a4,0x8
    800008ea:	72a73703          	ld	a4,1834(a4) # 80009010 <uart_tx_w>
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	71a7b783          	ld	a5,1818(a5) # 80009008 <uart_tx_r>
    800008f6:	02078793          	addi	a5,a5,32
    800008fa:	02e79b63          	bne	a5,a4,80000930 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00011997          	auipc	s3,0x11
    80000902:	95a98993          	addi	s3,s3,-1702 # 80011258 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	70248493          	addi	s1,s1,1794 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	70290913          	addi	s2,s2,1794 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000916:	85ce                	mv	a1,s3
    80000918:	8526                	mv	a0,s1
    8000091a:	00002097          	auipc	ra,0x2
    8000091e:	950080e7          	jalr	-1712(ra) # 8000226a <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000922:	00093703          	ld	a4,0(s2)
    80000926:	609c                	ld	a5,0(s1)
    80000928:	02078793          	addi	a5,a5,32
    8000092c:	fee785e3          	beq	a5,a4,80000916 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000930:	00011497          	auipc	s1,0x11
    80000934:	92848493          	addi	s1,s1,-1752 # 80011258 <uart_tx_lock>
    80000938:	01f77793          	andi	a5,a4,31
    8000093c:	97a6                	add	a5,a5,s1
    8000093e:	01478c23          	sb	s4,24(a5)
      uart_tx_w += 1;
    80000942:	0705                	addi	a4,a4,1
    80000944:	00008797          	auipc	a5,0x8
    80000948:	6ce7b623          	sd	a4,1740(a5) # 80009010 <uart_tx_w>
      uartstart();
    8000094c:	00000097          	auipc	ra,0x0
    80000950:	ee6080e7          	jalr	-282(ra) # 80000832 <uartstart>
      release(&uart_tx_lock);
    80000954:	8526                	mv	a0,s1
    80000956:	00000097          	auipc	ra,0x0
    8000095a:	32e080e7          	jalr	814(ra) # 80000c84 <release>
}
    8000095e:	70a2                	ld	ra,40(sp)
    80000960:	7402                	ld	s0,32(sp)
    80000962:	64e2                	ld	s1,24(sp)
    80000964:	6942                	ld	s2,16(sp)
    80000966:	69a2                	ld	s3,8(sp)
    80000968:	6a02                	ld	s4,0(sp)
    8000096a:	6145                	addi	sp,sp,48
    8000096c:	8082                	ret

000000008000096e <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    8000096e:	1141                	addi	sp,sp,-16
    80000970:	e422                	sd	s0,8(sp)
    80000972:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000974:	100007b7          	lui	a5,0x10000
    80000978:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000097c:	8b85                	andi	a5,a5,1
    8000097e:	cb81                	beqz	a5,8000098e <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000980:	100007b7          	lui	a5,0x10000
    80000984:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    80000988:	6422                	ld	s0,8(sp)
    8000098a:	0141                	addi	sp,sp,16
    8000098c:	8082                	ret
    return -1;
    8000098e:	557d                	li	a0,-1
    80000990:	bfe5                	j	80000988 <uartgetc+0x1a>

0000000080000992 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    80000992:	1101                	addi	sp,sp,-32
    80000994:	ec06                	sd	ra,24(sp)
    80000996:	e822                	sd	s0,16(sp)
    80000998:	e426                	sd	s1,8(sp)
    8000099a:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    8000099c:	54fd                	li	s1,-1
    8000099e:	a029                	j	800009a8 <uartintr+0x16>
      break;
    consoleintr(c);
    800009a0:	00000097          	auipc	ra,0x0
    800009a4:	918080e7          	jalr	-1768(ra) # 800002b8 <consoleintr>
    int c = uartgetc();
    800009a8:	00000097          	auipc	ra,0x0
    800009ac:	fc6080e7          	jalr	-58(ra) # 8000096e <uartgetc>
    if(c == -1)
    800009b0:	fe9518e3          	bne	a0,s1,800009a0 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009b4:	00011497          	auipc	s1,0x11
    800009b8:	8a448493          	addi	s1,s1,-1884 # 80011258 <uart_tx_lock>
    800009bc:	8526                	mv	a0,s1
    800009be:	00000097          	auipc	ra,0x0
    800009c2:	212080e7          	jalr	530(ra) # 80000bd0 <acquire>
  uartstart();
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	e6c080e7          	jalr	-404(ra) # 80000832 <uartstart>
  release(&uart_tx_lock);
    800009ce:	8526                	mv	a0,s1
    800009d0:	00000097          	auipc	ra,0x0
    800009d4:	2b4080e7          	jalr	692(ra) # 80000c84 <release>
}
    800009d8:	60e2                	ld	ra,24(sp)
    800009da:	6442                	ld	s0,16(sp)
    800009dc:	64a2                	ld	s1,8(sp)
    800009de:	6105                	addi	sp,sp,32
    800009e0:	8082                	ret

00000000800009e2 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e2:	1101                	addi	sp,sp,-32
    800009e4:	ec06                	sd	ra,24(sp)
    800009e6:	e822                	sd	s0,16(sp)
    800009e8:	e426                	sd	s1,8(sp)
    800009ea:	e04a                	sd	s2,0(sp)
    800009ec:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009ee:	03451793          	slli	a5,a0,0x34
    800009f2:	ebb9                	bnez	a5,80000a48 <kfree+0x66>
    800009f4:	84aa                	mv	s1,a0
    800009f6:	00027797          	auipc	a5,0x27
    800009fa:	98a78793          	addi	a5,a5,-1654 # 80027380 <end>
    800009fe:	04f56563          	bltu	a0,a5,80000a48 <kfree+0x66>
    80000a02:	47c5                	li	a5,17
    80000a04:	07ee                	slli	a5,a5,0x1b
    80000a06:	04f57163          	bgeu	a0,a5,80000a48 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a0a:	6605                	lui	a2,0x1
    80000a0c:	4585                	li	a1,1
    80000a0e:	00000097          	auipc	ra,0x0
    80000a12:	2be080e7          	jalr	702(ra) # 80000ccc <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a16:	00011917          	auipc	s2,0x11
    80000a1a:	87a90913          	addi	s2,s2,-1926 # 80011290 <kmem>
    80000a1e:	854a                	mv	a0,s2
    80000a20:	00000097          	auipc	ra,0x0
    80000a24:	1b0080e7          	jalr	432(ra) # 80000bd0 <acquire>
  r->next = kmem.freelist;
    80000a28:	01893783          	ld	a5,24(s2)
    80000a2c:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a2e:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a32:	854a                	mv	a0,s2
    80000a34:	00000097          	auipc	ra,0x0
    80000a38:	250080e7          	jalr	592(ra) # 80000c84 <release>
}
    80000a3c:	60e2                	ld	ra,24(sp)
    80000a3e:	6442                	ld	s0,16(sp)
    80000a40:	64a2                	ld	s1,8(sp)
    80000a42:	6902                	ld	s2,0(sp)
    80000a44:	6105                	addi	sp,sp,32
    80000a46:	8082                	ret
    panic("kfree");
    80000a48:	00007517          	auipc	a0,0x7
    80000a4c:	61850513          	addi	a0,a0,1560 # 80008060 <digits+0x20>
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	aea080e7          	jalr	-1302(ra) # 8000053a <panic>

0000000080000a58 <freerange>:
{
    80000a58:	7179                	addi	sp,sp,-48
    80000a5a:	f406                	sd	ra,40(sp)
    80000a5c:	f022                	sd	s0,32(sp)
    80000a5e:	ec26                	sd	s1,24(sp)
    80000a60:	e84a                	sd	s2,16(sp)
    80000a62:	e44e                	sd	s3,8(sp)
    80000a64:	e052                	sd	s4,0(sp)
    80000a66:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a68:	6785                	lui	a5,0x1
    80000a6a:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a6e:	00e504b3          	add	s1,a0,a4
    80000a72:	777d                	lui	a4,0xfffff
    80000a74:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a76:	94be                	add	s1,s1,a5
    80000a78:	0095ee63          	bltu	a1,s1,80000a94 <freerange+0x3c>
    80000a7c:	892e                	mv	s2,a1
    kfree(p);
    80000a7e:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a80:	6985                	lui	s3,0x1
    kfree(p);
    80000a82:	01448533          	add	a0,s1,s4
    80000a86:	00000097          	auipc	ra,0x0
    80000a8a:	f5c080e7          	jalr	-164(ra) # 800009e2 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8e:	94ce                	add	s1,s1,s3
    80000a90:	fe9979e3          	bgeu	s2,s1,80000a82 <freerange+0x2a>
}
    80000a94:	70a2                	ld	ra,40(sp)
    80000a96:	7402                	ld	s0,32(sp)
    80000a98:	64e2                	ld	s1,24(sp)
    80000a9a:	6942                	ld	s2,16(sp)
    80000a9c:	69a2                	ld	s3,8(sp)
    80000a9e:	6a02                	ld	s4,0(sp)
    80000aa0:	6145                	addi	sp,sp,48
    80000aa2:	8082                	ret

0000000080000aa4 <kinit>:
{
    80000aa4:	1141                	addi	sp,sp,-16
    80000aa6:	e406                	sd	ra,8(sp)
    80000aa8:	e022                	sd	s0,0(sp)
    80000aaa:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000aac:	00007597          	auipc	a1,0x7
    80000ab0:	5bc58593          	addi	a1,a1,1468 # 80008068 <digits+0x28>
    80000ab4:	00010517          	auipc	a0,0x10
    80000ab8:	7dc50513          	addi	a0,a0,2012 # 80011290 <kmem>
    80000abc:	00000097          	auipc	ra,0x0
    80000ac0:	084080e7          	jalr	132(ra) # 80000b40 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ac4:	45c5                	li	a1,17
    80000ac6:	05ee                	slli	a1,a1,0x1b
    80000ac8:	00027517          	auipc	a0,0x27
    80000acc:	8b850513          	addi	a0,a0,-1864 # 80027380 <end>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	f88080e7          	jalr	-120(ra) # 80000a58 <freerange>
}
    80000ad8:	60a2                	ld	ra,8(sp)
    80000ada:	6402                	ld	s0,0(sp)
    80000adc:	0141                	addi	sp,sp,16
    80000ade:	8082                	ret

0000000080000ae0 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae0:	1101                	addi	sp,sp,-32
    80000ae2:	ec06                	sd	ra,24(sp)
    80000ae4:	e822                	sd	s0,16(sp)
    80000ae6:	e426                	sd	s1,8(sp)
    80000ae8:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000aea:	00010497          	auipc	s1,0x10
    80000aee:	7a648493          	addi	s1,s1,1958 # 80011290 <kmem>
    80000af2:	8526                	mv	a0,s1
    80000af4:	00000097          	auipc	ra,0x0
    80000af8:	0dc080e7          	jalr	220(ra) # 80000bd0 <acquire>
  r = kmem.freelist;
    80000afc:	6c84                	ld	s1,24(s1)
  if(r)
    80000afe:	c885                	beqz	s1,80000b2e <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b00:	609c                	ld	a5,0(s1)
    80000b02:	00010517          	auipc	a0,0x10
    80000b06:	78e50513          	addi	a0,a0,1934 # 80011290 <kmem>
    80000b0a:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b0c:	00000097          	auipc	ra,0x0
    80000b10:	178080e7          	jalr	376(ra) # 80000c84 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b14:	6605                	lui	a2,0x1
    80000b16:	4595                	li	a1,5
    80000b18:	8526                	mv	a0,s1
    80000b1a:	00000097          	auipc	ra,0x0
    80000b1e:	1b2080e7          	jalr	434(ra) # 80000ccc <memset>
  return (void*)r;
}
    80000b22:	8526                	mv	a0,s1
    80000b24:	60e2                	ld	ra,24(sp)
    80000b26:	6442                	ld	s0,16(sp)
    80000b28:	64a2                	ld	s1,8(sp)
    80000b2a:	6105                	addi	sp,sp,32
    80000b2c:	8082                	ret
  release(&kmem.lock);
    80000b2e:	00010517          	auipc	a0,0x10
    80000b32:	76250513          	addi	a0,a0,1890 # 80011290 <kmem>
    80000b36:	00000097          	auipc	ra,0x0
    80000b3a:	14e080e7          	jalr	334(ra) # 80000c84 <release>
  if(r)
    80000b3e:	b7d5                	j	80000b22 <kalloc+0x42>

0000000080000b40 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b40:	1141                	addi	sp,sp,-16
    80000b42:	e422                	sd	s0,8(sp)
    80000b44:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b46:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b48:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b4c:	00053823          	sd	zero,16(a0)
}
    80000b50:	6422                	ld	s0,8(sp)
    80000b52:	0141                	addi	sp,sp,16
    80000b54:	8082                	ret

0000000080000b56 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b56:	411c                	lw	a5,0(a0)
    80000b58:	e399                	bnez	a5,80000b5e <holding+0x8>
    80000b5a:	4501                	li	a0,0
  return r;
}
    80000b5c:	8082                	ret
{
    80000b5e:	1101                	addi	sp,sp,-32
    80000b60:	ec06                	sd	ra,24(sp)
    80000b62:	e822                	sd	s0,16(sp)
    80000b64:	e426                	sd	s1,8(sp)
    80000b66:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b68:	6904                	ld	s1,16(a0)
    80000b6a:	00001097          	auipc	ra,0x1
    80000b6e:	eec080e7          	jalr	-276(ra) # 80001a56 <mycpu>
    80000b72:	40a48533          	sub	a0,s1,a0
    80000b76:	00153513          	seqz	a0,a0
}
    80000b7a:	60e2                	ld	ra,24(sp)
    80000b7c:	6442                	ld	s0,16(sp)
    80000b7e:	64a2                	ld	s1,8(sp)
    80000b80:	6105                	addi	sp,sp,32
    80000b82:	8082                	ret

0000000080000b84 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b84:	1101                	addi	sp,sp,-32
    80000b86:	ec06                	sd	ra,24(sp)
    80000b88:	e822                	sd	s0,16(sp)
    80000b8a:	e426                	sd	s1,8(sp)
    80000b8c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b8e:	100024f3          	csrr	s1,sstatus
    80000b92:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b96:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b98:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000b9c:	00001097          	auipc	ra,0x1
    80000ba0:	eba080e7          	jalr	-326(ra) # 80001a56 <mycpu>
    80000ba4:	5d3c                	lw	a5,120(a0)
    80000ba6:	cf89                	beqz	a5,80000bc0 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000ba8:	00001097          	auipc	ra,0x1
    80000bac:	eae080e7          	jalr	-338(ra) # 80001a56 <mycpu>
    80000bb0:	5d3c                	lw	a5,120(a0)
    80000bb2:	2785                	addiw	a5,a5,1
    80000bb4:	dd3c                	sw	a5,120(a0)
}
    80000bb6:	60e2                	ld	ra,24(sp)
    80000bb8:	6442                	ld	s0,16(sp)
    80000bba:	64a2                	ld	s1,8(sp)
    80000bbc:	6105                	addi	sp,sp,32
    80000bbe:	8082                	ret
    mycpu()->intena = old;
    80000bc0:	00001097          	auipc	ra,0x1
    80000bc4:	e96080e7          	jalr	-362(ra) # 80001a56 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bc8:	8085                	srli	s1,s1,0x1
    80000bca:	8885                	andi	s1,s1,1
    80000bcc:	dd64                	sw	s1,124(a0)
    80000bce:	bfe9                	j	80000ba8 <push_off+0x24>

0000000080000bd0 <acquire>:
{
    80000bd0:	1101                	addi	sp,sp,-32
    80000bd2:	ec06                	sd	ra,24(sp)
    80000bd4:	e822                	sd	s0,16(sp)
    80000bd6:	e426                	sd	s1,8(sp)
    80000bd8:	1000                	addi	s0,sp,32
    80000bda:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bdc:	00000097          	auipc	ra,0x0
    80000be0:	fa8080e7          	jalr	-88(ra) # 80000b84 <push_off>
  if(holding(lk))
    80000be4:	8526                	mv	a0,s1
    80000be6:	00000097          	auipc	ra,0x0
    80000bea:	f70080e7          	jalr	-144(ra) # 80000b56 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bee:	4705                	li	a4,1
  if(holding(lk))
    80000bf0:	e115                	bnez	a0,80000c14 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf2:	87ba                	mv	a5,a4
    80000bf4:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bf8:	2781                	sext.w	a5,a5
    80000bfa:	ffe5                	bnez	a5,80000bf2 <acquire+0x22>
  __sync_synchronize();
    80000bfc:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c00:	00001097          	auipc	ra,0x1
    80000c04:	e56080e7          	jalr	-426(ra) # 80001a56 <mycpu>
    80000c08:	e888                	sd	a0,16(s1)
}
    80000c0a:	60e2                	ld	ra,24(sp)
    80000c0c:	6442                	ld	s0,16(sp)
    80000c0e:	64a2                	ld	s1,8(sp)
    80000c10:	6105                	addi	sp,sp,32
    80000c12:	8082                	ret
    panic("acquire");
    80000c14:	00007517          	auipc	a0,0x7
    80000c18:	45c50513          	addi	a0,a0,1116 # 80008070 <digits+0x30>
    80000c1c:	00000097          	auipc	ra,0x0
    80000c20:	91e080e7          	jalr	-1762(ra) # 8000053a <panic>

0000000080000c24 <pop_off>:

void
pop_off(void)
{
    80000c24:	1141                	addi	sp,sp,-16
    80000c26:	e406                	sd	ra,8(sp)
    80000c28:	e022                	sd	s0,0(sp)
    80000c2a:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c2c:	00001097          	auipc	ra,0x1
    80000c30:	e2a080e7          	jalr	-470(ra) # 80001a56 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c34:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c38:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c3a:	e78d                	bnez	a5,80000c64 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c3c:	5d3c                	lw	a5,120(a0)
    80000c3e:	02f05b63          	blez	a5,80000c74 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c42:	37fd                	addiw	a5,a5,-1
    80000c44:	0007871b          	sext.w	a4,a5
    80000c48:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c4a:	eb09                	bnez	a4,80000c5c <pop_off+0x38>
    80000c4c:	5d7c                	lw	a5,124(a0)
    80000c4e:	c799                	beqz	a5,80000c5c <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c50:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c54:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c58:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c5c:	60a2                	ld	ra,8(sp)
    80000c5e:	6402                	ld	s0,0(sp)
    80000c60:	0141                	addi	sp,sp,16
    80000c62:	8082                	ret
    panic("pop_off - interruptible");
    80000c64:	00007517          	auipc	a0,0x7
    80000c68:	41450513          	addi	a0,a0,1044 # 80008078 <digits+0x38>
    80000c6c:	00000097          	auipc	ra,0x0
    80000c70:	8ce080e7          	jalr	-1842(ra) # 8000053a <panic>
    panic("pop_off");
    80000c74:	00007517          	auipc	a0,0x7
    80000c78:	41c50513          	addi	a0,a0,1052 # 80008090 <digits+0x50>
    80000c7c:	00000097          	auipc	ra,0x0
    80000c80:	8be080e7          	jalr	-1858(ra) # 8000053a <panic>

0000000080000c84 <release>:
{
    80000c84:	1101                	addi	sp,sp,-32
    80000c86:	ec06                	sd	ra,24(sp)
    80000c88:	e822                	sd	s0,16(sp)
    80000c8a:	e426                	sd	s1,8(sp)
    80000c8c:	1000                	addi	s0,sp,32
    80000c8e:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	ec6080e7          	jalr	-314(ra) # 80000b56 <holding>
    80000c98:	c115                	beqz	a0,80000cbc <release+0x38>
  lk->cpu = 0;
    80000c9a:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000c9e:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca2:	0f50000f          	fence	iorw,ow
    80000ca6:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000caa:	00000097          	auipc	ra,0x0
    80000cae:	f7a080e7          	jalr	-134(ra) # 80000c24 <pop_off>
}
    80000cb2:	60e2                	ld	ra,24(sp)
    80000cb4:	6442                	ld	s0,16(sp)
    80000cb6:	64a2                	ld	s1,8(sp)
    80000cb8:	6105                	addi	sp,sp,32
    80000cba:	8082                	ret
    panic("release");
    80000cbc:	00007517          	auipc	a0,0x7
    80000cc0:	3dc50513          	addi	a0,a0,988 # 80008098 <digits+0x58>
    80000cc4:	00000097          	auipc	ra,0x0
    80000cc8:	876080e7          	jalr	-1930(ra) # 8000053a <panic>

0000000080000ccc <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ccc:	1141                	addi	sp,sp,-16
    80000cce:	e422                	sd	s0,8(sp)
    80000cd0:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd2:	ca19                	beqz	a2,80000ce8 <memset+0x1c>
    80000cd4:	87aa                	mv	a5,a0
    80000cd6:	1602                	slli	a2,a2,0x20
    80000cd8:	9201                	srli	a2,a2,0x20
    80000cda:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000cde:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce2:	0785                	addi	a5,a5,1
    80000ce4:	fee79de3          	bne	a5,a4,80000cde <memset+0x12>
  }
  return dst;
}
    80000ce8:	6422                	ld	s0,8(sp)
    80000cea:	0141                	addi	sp,sp,16
    80000cec:	8082                	ret

0000000080000cee <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cee:	1141                	addi	sp,sp,-16
    80000cf0:	e422                	sd	s0,8(sp)
    80000cf2:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cf4:	ca05                	beqz	a2,80000d24 <memcmp+0x36>
    80000cf6:	fff6069b          	addiw	a3,a2,-1
    80000cfa:	1682                	slli	a3,a3,0x20
    80000cfc:	9281                	srli	a3,a3,0x20
    80000cfe:	0685                	addi	a3,a3,1
    80000d00:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d02:	00054783          	lbu	a5,0(a0)
    80000d06:	0005c703          	lbu	a4,0(a1)
    80000d0a:	00e79863          	bne	a5,a4,80000d1a <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d0e:	0505                	addi	a0,a0,1
    80000d10:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d12:	fed518e3          	bne	a0,a3,80000d02 <memcmp+0x14>
  }

  return 0;
    80000d16:	4501                	li	a0,0
    80000d18:	a019                	j	80000d1e <memcmp+0x30>
      return *s1 - *s2;
    80000d1a:	40e7853b          	subw	a0,a5,a4
}
    80000d1e:	6422                	ld	s0,8(sp)
    80000d20:	0141                	addi	sp,sp,16
    80000d22:	8082                	ret
  return 0;
    80000d24:	4501                	li	a0,0
    80000d26:	bfe5                	j	80000d1e <memcmp+0x30>

0000000080000d28 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d28:	1141                	addi	sp,sp,-16
    80000d2a:	e422                	sd	s0,8(sp)
    80000d2c:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d2e:	c205                	beqz	a2,80000d4e <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d30:	02a5e263          	bltu	a1,a0,80000d54 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d34:	1602                	slli	a2,a2,0x20
    80000d36:	9201                	srli	a2,a2,0x20
    80000d38:	00c587b3          	add	a5,a1,a2
{
    80000d3c:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d3e:	0585                	addi	a1,a1,1
    80000d40:	0705                	addi	a4,a4,1
    80000d42:	fff5c683          	lbu	a3,-1(a1)
    80000d46:	fed70fa3          	sb	a3,-1(a4) # ffffffffffffefff <end+0xffffffff7ffd7c7f>
    while(n-- > 0)
    80000d4a:	fef59ae3          	bne	a1,a5,80000d3e <memmove+0x16>

  return dst;
}
    80000d4e:	6422                	ld	s0,8(sp)
    80000d50:	0141                	addi	sp,sp,16
    80000d52:	8082                	ret
  if(s < d && s + n > d){
    80000d54:	02061693          	slli	a3,a2,0x20
    80000d58:	9281                	srli	a3,a3,0x20
    80000d5a:	00d58733          	add	a4,a1,a3
    80000d5e:	fce57be3          	bgeu	a0,a4,80000d34 <memmove+0xc>
    d += n;
    80000d62:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d64:	fff6079b          	addiw	a5,a2,-1
    80000d68:	1782                	slli	a5,a5,0x20
    80000d6a:	9381                	srli	a5,a5,0x20
    80000d6c:	fff7c793          	not	a5,a5
    80000d70:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d72:	177d                	addi	a4,a4,-1
    80000d74:	16fd                	addi	a3,a3,-1
    80000d76:	00074603          	lbu	a2,0(a4)
    80000d7a:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d7e:	fee79ae3          	bne	a5,a4,80000d72 <memmove+0x4a>
    80000d82:	b7f1                	j	80000d4e <memmove+0x26>

0000000080000d84 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d84:	1141                	addi	sp,sp,-16
    80000d86:	e406                	sd	ra,8(sp)
    80000d88:	e022                	sd	s0,0(sp)
    80000d8a:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d8c:	00000097          	auipc	ra,0x0
    80000d90:	f9c080e7          	jalr	-100(ra) # 80000d28 <memmove>
}
    80000d94:	60a2                	ld	ra,8(sp)
    80000d96:	6402                	ld	s0,0(sp)
    80000d98:	0141                	addi	sp,sp,16
    80000d9a:	8082                	ret

0000000080000d9c <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000d9c:	1141                	addi	sp,sp,-16
    80000d9e:	e422                	sd	s0,8(sp)
    80000da0:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da2:	ce11                	beqz	a2,80000dbe <strncmp+0x22>
    80000da4:	00054783          	lbu	a5,0(a0)
    80000da8:	cf89                	beqz	a5,80000dc2 <strncmp+0x26>
    80000daa:	0005c703          	lbu	a4,0(a1)
    80000dae:	00f71a63          	bne	a4,a5,80000dc2 <strncmp+0x26>
    n--, p++, q++;
    80000db2:	367d                	addiw	a2,a2,-1
    80000db4:	0505                	addi	a0,a0,1
    80000db6:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000db8:	f675                	bnez	a2,80000da4 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dba:	4501                	li	a0,0
    80000dbc:	a809                	j	80000dce <strncmp+0x32>
    80000dbe:	4501                	li	a0,0
    80000dc0:	a039                	j	80000dce <strncmp+0x32>
  if(n == 0)
    80000dc2:	ca09                	beqz	a2,80000dd4 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dc4:	00054503          	lbu	a0,0(a0)
    80000dc8:	0005c783          	lbu	a5,0(a1)
    80000dcc:	9d1d                	subw	a0,a0,a5
}
    80000dce:	6422                	ld	s0,8(sp)
    80000dd0:	0141                	addi	sp,sp,16
    80000dd2:	8082                	ret
    return 0;
    80000dd4:	4501                	li	a0,0
    80000dd6:	bfe5                	j	80000dce <strncmp+0x32>

0000000080000dd8 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dd8:	1141                	addi	sp,sp,-16
    80000dda:	e422                	sd	s0,8(sp)
    80000ddc:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dde:	872a                	mv	a4,a0
    80000de0:	8832                	mv	a6,a2
    80000de2:	367d                	addiw	a2,a2,-1
    80000de4:	01005963          	blez	a6,80000df6 <strncpy+0x1e>
    80000de8:	0705                	addi	a4,a4,1
    80000dea:	0005c783          	lbu	a5,0(a1)
    80000dee:	fef70fa3          	sb	a5,-1(a4)
    80000df2:	0585                	addi	a1,a1,1
    80000df4:	f7f5                	bnez	a5,80000de0 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000df6:	86ba                	mv	a3,a4
    80000df8:	00c05c63          	blez	a2,80000e10 <strncpy+0x38>
    *s++ = 0;
    80000dfc:	0685                	addi	a3,a3,1
    80000dfe:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e02:	40d707bb          	subw	a5,a4,a3
    80000e06:	37fd                	addiw	a5,a5,-1
    80000e08:	010787bb          	addw	a5,a5,a6
    80000e0c:	fef048e3          	bgtz	a5,80000dfc <strncpy+0x24>
  return os;
}
    80000e10:	6422                	ld	s0,8(sp)
    80000e12:	0141                	addi	sp,sp,16
    80000e14:	8082                	ret

0000000080000e16 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e16:	1141                	addi	sp,sp,-16
    80000e18:	e422                	sd	s0,8(sp)
    80000e1a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e1c:	02c05363          	blez	a2,80000e42 <safestrcpy+0x2c>
    80000e20:	fff6069b          	addiw	a3,a2,-1
    80000e24:	1682                	slli	a3,a3,0x20
    80000e26:	9281                	srli	a3,a3,0x20
    80000e28:	96ae                	add	a3,a3,a1
    80000e2a:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e2c:	00d58963          	beq	a1,a3,80000e3e <safestrcpy+0x28>
    80000e30:	0585                	addi	a1,a1,1
    80000e32:	0785                	addi	a5,a5,1
    80000e34:	fff5c703          	lbu	a4,-1(a1)
    80000e38:	fee78fa3          	sb	a4,-1(a5)
    80000e3c:	fb65                	bnez	a4,80000e2c <safestrcpy+0x16>
    ;
  *s = 0;
    80000e3e:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e42:	6422                	ld	s0,8(sp)
    80000e44:	0141                	addi	sp,sp,16
    80000e46:	8082                	ret

0000000080000e48 <strlen>:

int
strlen(const char *s)
{
    80000e48:	1141                	addi	sp,sp,-16
    80000e4a:	e422                	sd	s0,8(sp)
    80000e4c:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e4e:	00054783          	lbu	a5,0(a0)
    80000e52:	cf91                	beqz	a5,80000e6e <strlen+0x26>
    80000e54:	0505                	addi	a0,a0,1
    80000e56:	87aa                	mv	a5,a0
    80000e58:	4685                	li	a3,1
    80000e5a:	9e89                	subw	a3,a3,a0
    80000e5c:	00f6853b          	addw	a0,a3,a5
    80000e60:	0785                	addi	a5,a5,1
    80000e62:	fff7c703          	lbu	a4,-1(a5)
    80000e66:	fb7d                	bnez	a4,80000e5c <strlen+0x14>
    ;
  return n;
}
    80000e68:	6422                	ld	s0,8(sp)
    80000e6a:	0141                	addi	sp,sp,16
    80000e6c:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e6e:	4501                	li	a0,0
    80000e70:	bfe5                	j	80000e68 <strlen+0x20>

0000000080000e72 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e72:	1141                	addi	sp,sp,-16
    80000e74:	e406                	sd	ra,8(sp)
    80000e76:	e022                	sd	s0,0(sp)
    80000e78:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e7a:	00001097          	auipc	ra,0x1
    80000e7e:	bcc080e7          	jalr	-1076(ra) # 80001a46 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e82:	00008717          	auipc	a4,0x8
    80000e86:	19670713          	addi	a4,a4,406 # 80009018 <started>
  if(cpuid() == 0){
    80000e8a:	c139                	beqz	a0,80000ed0 <main+0x5e>
    while(started == 0)
    80000e8c:	431c                	lw	a5,0(a4)
    80000e8e:	2781                	sext.w	a5,a5
    80000e90:	dff5                	beqz	a5,80000e8c <main+0x1a>
      ;
    __sync_synchronize();
    80000e92:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	bb0080e7          	jalr	-1104(ra) # 80001a46 <cpuid>
    80000e9e:	85aa                	mv	a1,a0
    80000ea0:	00007517          	auipc	a0,0x7
    80000ea4:	21850513          	addi	a0,a0,536 # 800080b8 <digits+0x78>
    80000ea8:	fffff097          	auipc	ra,0xfffff
    80000eac:	6dc080e7          	jalr	1756(ra) # 80000584 <printf>
    kvminithart();    // turn on paging
    80000eb0:	00000097          	auipc	ra,0x0
    80000eb4:	0d8080e7          	jalr	216(ra) # 80000f88 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eb8:	00002097          	auipc	ra,0x2
    80000ebc:	944080e7          	jalr	-1724(ra) # 800027fc <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec0:	00005097          	auipc	ra,0x5
    80000ec4:	f20080e7          	jalr	-224(ra) # 80005de0 <plicinithart>
  }

  scheduler();        
    80000ec8:	00001097          	auipc	ra,0x1
    80000ecc:	19e080e7          	jalr	414(ra) # 80002066 <scheduler>
    consoleinit();
    80000ed0:	fffff097          	auipc	ra,0xfffff
    80000ed4:	57a080e7          	jalr	1402(ra) # 8000044a <consoleinit>
    printfinit();
    80000ed8:	00000097          	auipc	ra,0x0
    80000edc:	88c080e7          	jalr	-1908(ra) # 80000764 <printfinit>
    printf("\n");
    80000ee0:	00007517          	auipc	a0,0x7
    80000ee4:	1e850513          	addi	a0,a0,488 # 800080c8 <digits+0x88>
    80000ee8:	fffff097          	auipc	ra,0xfffff
    80000eec:	69c080e7          	jalr	1692(ra) # 80000584 <printf>
    printf("xv6 kernel is booting\n");
    80000ef0:	00007517          	auipc	a0,0x7
    80000ef4:	1b050513          	addi	a0,a0,432 # 800080a0 <digits+0x60>
    80000ef8:	fffff097          	auipc	ra,0xfffff
    80000efc:	68c080e7          	jalr	1676(ra) # 80000584 <printf>
    printf("\n");
    80000f00:	00007517          	auipc	a0,0x7
    80000f04:	1c850513          	addi	a0,a0,456 # 800080c8 <digits+0x88>
    80000f08:	fffff097          	auipc	ra,0xfffff
    80000f0c:	67c080e7          	jalr	1660(ra) # 80000584 <printf>
    kinit();         // physical page allocator
    80000f10:	00000097          	auipc	ra,0x0
    80000f14:	b94080e7          	jalr	-1132(ra) # 80000aa4 <kinit>
    kvminit();       // create kernel page table
    80000f18:	00000097          	auipc	ra,0x0
    80000f1c:	322080e7          	jalr	802(ra) # 8000123a <kvminit>
    kvminithart();   // turn on paging
    80000f20:	00000097          	auipc	ra,0x0
    80000f24:	068080e7          	jalr	104(ra) # 80000f88 <kvminithart>
    procinit();      // process table
    80000f28:	00001097          	auipc	ra,0x1
    80000f2c:	a6e080e7          	jalr	-1426(ra) # 80001996 <procinit>
    trapinit();      // trap vectors
    80000f30:	00002097          	auipc	ra,0x2
    80000f34:	8a4080e7          	jalr	-1884(ra) # 800027d4 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f38:	00002097          	auipc	ra,0x2
    80000f3c:	8c4080e7          	jalr	-1852(ra) # 800027fc <trapinithart>
    plicinit();      // set up interrupt controller
    80000f40:	00005097          	auipc	ra,0x5
    80000f44:	e8a080e7          	jalr	-374(ra) # 80005dca <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f48:	00005097          	auipc	ra,0x5
    80000f4c:	e98080e7          	jalr	-360(ra) # 80005de0 <plicinithart>
    binit();         // buffer cache
    80000f50:	00002097          	auipc	ra,0x2
    80000f54:	058080e7          	jalr	88(ra) # 80002fa8 <binit>
    iinit();         // inode table
    80000f58:	00002097          	auipc	ra,0x2
    80000f5c:	6e6080e7          	jalr	1766(ra) # 8000363e <iinit>
    fileinit();      // file table
    80000f60:	00003097          	auipc	ra,0x3
    80000f64:	698080e7          	jalr	1688(ra) # 800045f8 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f68:	00005097          	auipc	ra,0x5
    80000f6c:	f98080e7          	jalr	-104(ra) # 80005f00 <virtio_disk_init>
    userinit();      // first user process
    80000f70:	00001097          	auipc	ra,0x1
    80000f74:	ebc080e7          	jalr	-324(ra) # 80001e2c <userinit>
    __sync_synchronize();
    80000f78:	0ff0000f          	fence
    started = 1;
    80000f7c:	4785                	li	a5,1
    80000f7e:	00008717          	auipc	a4,0x8
    80000f82:	08f72d23          	sw	a5,154(a4) # 80009018 <started>
    80000f86:	b789                	j	80000ec8 <main+0x56>

0000000080000f88 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f88:	1141                	addi	sp,sp,-16
    80000f8a:	e422                	sd	s0,8(sp)
    80000f8c:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000f8e:	00008797          	auipc	a5,0x8
    80000f92:	0927b783          	ld	a5,146(a5) # 80009020 <kernel_pagetable>
    80000f96:	83b1                	srli	a5,a5,0xc
    80000f98:	577d                	li	a4,-1
    80000f9a:	177e                	slli	a4,a4,0x3f
    80000f9c:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000f9e:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fa2:	12000073          	sfence.vma
  sfence_vma();
}
    80000fa6:	6422                	ld	s0,8(sp)
    80000fa8:	0141                	addi	sp,sp,16
    80000faa:	8082                	ret

0000000080000fac <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fac:	7139                	addi	sp,sp,-64
    80000fae:	fc06                	sd	ra,56(sp)
    80000fb0:	f822                	sd	s0,48(sp)
    80000fb2:	f426                	sd	s1,40(sp)
    80000fb4:	f04a                	sd	s2,32(sp)
    80000fb6:	ec4e                	sd	s3,24(sp)
    80000fb8:	e852                	sd	s4,16(sp)
    80000fba:	e456                	sd	s5,8(sp)
    80000fbc:	e05a                	sd	s6,0(sp)
    80000fbe:	0080                	addi	s0,sp,64
    80000fc0:	84aa                	mv	s1,a0
    80000fc2:	89ae                	mv	s3,a1
    80000fc4:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fc6:	57fd                	li	a5,-1
    80000fc8:	83e9                	srli	a5,a5,0x1a
    80000fca:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fcc:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fce:	04b7f263          	bgeu	a5,a1,80001012 <walk+0x66>
    panic("walk");
    80000fd2:	00007517          	auipc	a0,0x7
    80000fd6:	0fe50513          	addi	a0,a0,254 # 800080d0 <digits+0x90>
    80000fda:	fffff097          	auipc	ra,0xfffff
    80000fde:	560080e7          	jalr	1376(ra) # 8000053a <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fe2:	060a8663          	beqz	s5,8000104e <walk+0xa2>
    80000fe6:	00000097          	auipc	ra,0x0
    80000fea:	afa080e7          	jalr	-1286(ra) # 80000ae0 <kalloc>
    80000fee:	84aa                	mv	s1,a0
    80000ff0:	c529                	beqz	a0,8000103a <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ff2:	6605                	lui	a2,0x1
    80000ff4:	4581                	li	a1,0
    80000ff6:	00000097          	auipc	ra,0x0
    80000ffa:	cd6080e7          	jalr	-810(ra) # 80000ccc <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80000ffe:	00c4d793          	srli	a5,s1,0xc
    80001002:	07aa                	slli	a5,a5,0xa
    80001004:	0017e793          	ori	a5,a5,1
    80001008:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000100c:	3a5d                	addiw	s4,s4,-9
    8000100e:	036a0063          	beq	s4,s6,8000102e <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001012:	0149d933          	srl	s2,s3,s4
    80001016:	1ff97913          	andi	s2,s2,511
    8000101a:	090e                	slli	s2,s2,0x3
    8000101c:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000101e:	00093483          	ld	s1,0(s2)
    80001022:	0014f793          	andi	a5,s1,1
    80001026:	dfd5                	beqz	a5,80000fe2 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001028:	80a9                	srli	s1,s1,0xa
    8000102a:	04b2                	slli	s1,s1,0xc
    8000102c:	b7c5                	j	8000100c <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000102e:	00c9d513          	srli	a0,s3,0xc
    80001032:	1ff57513          	andi	a0,a0,511
    80001036:	050e                	slli	a0,a0,0x3
    80001038:	9526                	add	a0,a0,s1
}
    8000103a:	70e2                	ld	ra,56(sp)
    8000103c:	7442                	ld	s0,48(sp)
    8000103e:	74a2                	ld	s1,40(sp)
    80001040:	7902                	ld	s2,32(sp)
    80001042:	69e2                	ld	s3,24(sp)
    80001044:	6a42                	ld	s4,16(sp)
    80001046:	6aa2                	ld	s5,8(sp)
    80001048:	6b02                	ld	s6,0(sp)
    8000104a:	6121                	addi	sp,sp,64
    8000104c:	8082                	ret
        return 0;
    8000104e:	4501                	li	a0,0
    80001050:	b7ed                	j	8000103a <walk+0x8e>

0000000080001052 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001052:	57fd                	li	a5,-1
    80001054:	83e9                	srli	a5,a5,0x1a
    80001056:	00b7f463          	bgeu	a5,a1,8000105e <walkaddr+0xc>
    return 0;
    8000105a:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000105c:	8082                	ret
{
    8000105e:	1141                	addi	sp,sp,-16
    80001060:	e406                	sd	ra,8(sp)
    80001062:	e022                	sd	s0,0(sp)
    80001064:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001066:	4601                	li	a2,0
    80001068:	00000097          	auipc	ra,0x0
    8000106c:	f44080e7          	jalr	-188(ra) # 80000fac <walk>
  if(pte == 0)
    80001070:	c105                	beqz	a0,80001090 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001072:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001074:	0117f693          	andi	a3,a5,17
    80001078:	4745                	li	a4,17
    return 0;
    8000107a:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000107c:	00e68663          	beq	a3,a4,80001088 <walkaddr+0x36>
}
    80001080:	60a2                	ld	ra,8(sp)
    80001082:	6402                	ld	s0,0(sp)
    80001084:	0141                	addi	sp,sp,16
    80001086:	8082                	ret
  pa = PTE2PA(*pte);
    80001088:	83a9                	srli	a5,a5,0xa
    8000108a:	00c79513          	slli	a0,a5,0xc
  return pa;
    8000108e:	bfcd                	j	80001080 <walkaddr+0x2e>
    return 0;
    80001090:	4501                	li	a0,0
    80001092:	b7fd                	j	80001080 <walkaddr+0x2e>

0000000080001094 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001094:	715d                	addi	sp,sp,-80
    80001096:	e486                	sd	ra,72(sp)
    80001098:	e0a2                	sd	s0,64(sp)
    8000109a:	fc26                	sd	s1,56(sp)
    8000109c:	f84a                	sd	s2,48(sp)
    8000109e:	f44e                	sd	s3,40(sp)
    800010a0:	f052                	sd	s4,32(sp)
    800010a2:	ec56                	sd	s5,24(sp)
    800010a4:	e85a                	sd	s6,16(sp)
    800010a6:	e45e                	sd	s7,8(sp)
    800010a8:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010aa:	c639                	beqz	a2,800010f8 <mappages+0x64>
    800010ac:	8aaa                	mv	s5,a0
    800010ae:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010b0:	777d                	lui	a4,0xfffff
    800010b2:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010b6:	fff58993          	addi	s3,a1,-1
    800010ba:	99b2                	add	s3,s3,a2
    800010bc:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010c0:	893e                	mv	s2,a5
    800010c2:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010c6:	6b85                	lui	s7,0x1
    800010c8:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010cc:	4605                	li	a2,1
    800010ce:	85ca                	mv	a1,s2
    800010d0:	8556                	mv	a0,s5
    800010d2:	00000097          	auipc	ra,0x0
    800010d6:	eda080e7          	jalr	-294(ra) # 80000fac <walk>
    800010da:	cd1d                	beqz	a0,80001118 <mappages+0x84>
    if(*pte & PTE_V)
    800010dc:	611c                	ld	a5,0(a0)
    800010de:	8b85                	andi	a5,a5,1
    800010e0:	e785                	bnez	a5,80001108 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010e2:	80b1                	srli	s1,s1,0xc
    800010e4:	04aa                	slli	s1,s1,0xa
    800010e6:	0164e4b3          	or	s1,s1,s6
    800010ea:	0014e493          	ori	s1,s1,1
    800010ee:	e104                	sd	s1,0(a0)
    if(a == last)
    800010f0:	05390063          	beq	s2,s3,80001130 <mappages+0x9c>
    a += PGSIZE;
    800010f4:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800010f6:	bfc9                	j	800010c8 <mappages+0x34>
    panic("mappages: size");
    800010f8:	00007517          	auipc	a0,0x7
    800010fc:	fe050513          	addi	a0,a0,-32 # 800080d8 <digits+0x98>
    80001100:	fffff097          	auipc	ra,0xfffff
    80001104:	43a080e7          	jalr	1082(ra) # 8000053a <panic>
      panic("mappages: remap");
    80001108:	00007517          	auipc	a0,0x7
    8000110c:	fe050513          	addi	a0,a0,-32 # 800080e8 <digits+0xa8>
    80001110:	fffff097          	auipc	ra,0xfffff
    80001114:	42a080e7          	jalr	1066(ra) # 8000053a <panic>
      return -1;
    80001118:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000111a:	60a6                	ld	ra,72(sp)
    8000111c:	6406                	ld	s0,64(sp)
    8000111e:	74e2                	ld	s1,56(sp)
    80001120:	7942                	ld	s2,48(sp)
    80001122:	79a2                	ld	s3,40(sp)
    80001124:	7a02                	ld	s4,32(sp)
    80001126:	6ae2                	ld	s5,24(sp)
    80001128:	6b42                	ld	s6,16(sp)
    8000112a:	6ba2                	ld	s7,8(sp)
    8000112c:	6161                	addi	sp,sp,80
    8000112e:	8082                	ret
  return 0;
    80001130:	4501                	li	a0,0
    80001132:	b7e5                	j	8000111a <mappages+0x86>

0000000080001134 <kvmmap>:
{
    80001134:	1141                	addi	sp,sp,-16
    80001136:	e406                	sd	ra,8(sp)
    80001138:	e022                	sd	s0,0(sp)
    8000113a:	0800                	addi	s0,sp,16
    8000113c:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000113e:	86b2                	mv	a3,a2
    80001140:	863e                	mv	a2,a5
    80001142:	00000097          	auipc	ra,0x0
    80001146:	f52080e7          	jalr	-174(ra) # 80001094 <mappages>
    8000114a:	e509                	bnez	a0,80001154 <kvmmap+0x20>
}
    8000114c:	60a2                	ld	ra,8(sp)
    8000114e:	6402                	ld	s0,0(sp)
    80001150:	0141                	addi	sp,sp,16
    80001152:	8082                	ret
    panic("kvmmap");
    80001154:	00007517          	auipc	a0,0x7
    80001158:	fa450513          	addi	a0,a0,-92 # 800080f8 <digits+0xb8>
    8000115c:	fffff097          	auipc	ra,0xfffff
    80001160:	3de080e7          	jalr	990(ra) # 8000053a <panic>

0000000080001164 <kvmmake>:
{
    80001164:	1101                	addi	sp,sp,-32
    80001166:	ec06                	sd	ra,24(sp)
    80001168:	e822                	sd	s0,16(sp)
    8000116a:	e426                	sd	s1,8(sp)
    8000116c:	e04a                	sd	s2,0(sp)
    8000116e:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001170:	00000097          	auipc	ra,0x0
    80001174:	970080e7          	jalr	-1680(ra) # 80000ae0 <kalloc>
    80001178:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000117a:	6605                	lui	a2,0x1
    8000117c:	4581                	li	a1,0
    8000117e:	00000097          	auipc	ra,0x0
    80001182:	b4e080e7          	jalr	-1202(ra) # 80000ccc <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001186:	4719                	li	a4,6
    80001188:	6685                	lui	a3,0x1
    8000118a:	10000637          	lui	a2,0x10000
    8000118e:	100005b7          	lui	a1,0x10000
    80001192:	8526                	mv	a0,s1
    80001194:	00000097          	auipc	ra,0x0
    80001198:	fa0080e7          	jalr	-96(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000119c:	4719                	li	a4,6
    8000119e:	6685                	lui	a3,0x1
    800011a0:	10001637          	lui	a2,0x10001
    800011a4:	100015b7          	lui	a1,0x10001
    800011a8:	8526                	mv	a0,s1
    800011aa:	00000097          	auipc	ra,0x0
    800011ae:	f8a080e7          	jalr	-118(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011b2:	4719                	li	a4,6
    800011b4:	004006b7          	lui	a3,0x400
    800011b8:	0c000637          	lui	a2,0xc000
    800011bc:	0c0005b7          	lui	a1,0xc000
    800011c0:	8526                	mv	a0,s1
    800011c2:	00000097          	auipc	ra,0x0
    800011c6:	f72080e7          	jalr	-142(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011ca:	00007917          	auipc	s2,0x7
    800011ce:	e3690913          	addi	s2,s2,-458 # 80008000 <etext>
    800011d2:	4729                	li	a4,10
    800011d4:	80007697          	auipc	a3,0x80007
    800011d8:	e2c68693          	addi	a3,a3,-468 # 8000 <_entry-0x7fff8000>
    800011dc:	4605                	li	a2,1
    800011de:	067e                	slli	a2,a2,0x1f
    800011e0:	85b2                	mv	a1,a2
    800011e2:	8526                	mv	a0,s1
    800011e4:	00000097          	auipc	ra,0x0
    800011e8:	f50080e7          	jalr	-176(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011ec:	4719                	li	a4,6
    800011ee:	46c5                	li	a3,17
    800011f0:	06ee                	slli	a3,a3,0x1b
    800011f2:	412686b3          	sub	a3,a3,s2
    800011f6:	864a                	mv	a2,s2
    800011f8:	85ca                	mv	a1,s2
    800011fa:	8526                	mv	a0,s1
    800011fc:	00000097          	auipc	ra,0x0
    80001200:	f38080e7          	jalr	-200(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001204:	4729                	li	a4,10
    80001206:	6685                	lui	a3,0x1
    80001208:	00006617          	auipc	a2,0x6
    8000120c:	df860613          	addi	a2,a2,-520 # 80007000 <_trampoline>
    80001210:	040005b7          	lui	a1,0x4000
    80001214:	15fd                	addi	a1,a1,-1
    80001216:	05b2                	slli	a1,a1,0xc
    80001218:	8526                	mv	a0,s1
    8000121a:	00000097          	auipc	ra,0x0
    8000121e:	f1a080e7          	jalr	-230(ra) # 80001134 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	6dc080e7          	jalr	1756(ra) # 80001900 <proc_mapstacks>
}
    8000122c:	8526                	mv	a0,s1
    8000122e:	60e2                	ld	ra,24(sp)
    80001230:	6442                	ld	s0,16(sp)
    80001232:	64a2                	ld	s1,8(sp)
    80001234:	6902                	ld	s2,0(sp)
    80001236:	6105                	addi	sp,sp,32
    80001238:	8082                	ret

000000008000123a <kvminit>:
{
    8000123a:	1141                	addi	sp,sp,-16
    8000123c:	e406                	sd	ra,8(sp)
    8000123e:	e022                	sd	s0,0(sp)
    80001240:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001242:	00000097          	auipc	ra,0x0
    80001246:	f22080e7          	jalr	-222(ra) # 80001164 <kvmmake>
    8000124a:	00008797          	auipc	a5,0x8
    8000124e:	dca7bb23          	sd	a0,-554(a5) # 80009020 <kernel_pagetable>
}
    80001252:	60a2                	ld	ra,8(sp)
    80001254:	6402                	ld	s0,0(sp)
    80001256:	0141                	addi	sp,sp,16
    80001258:	8082                	ret

000000008000125a <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000125a:	715d                	addi	sp,sp,-80
    8000125c:	e486                	sd	ra,72(sp)
    8000125e:	e0a2                	sd	s0,64(sp)
    80001260:	fc26                	sd	s1,56(sp)
    80001262:	f84a                	sd	s2,48(sp)
    80001264:	f44e                	sd	s3,40(sp)
    80001266:	f052                	sd	s4,32(sp)
    80001268:	ec56                	sd	s5,24(sp)
    8000126a:	e85a                	sd	s6,16(sp)
    8000126c:	e45e                	sd	s7,8(sp)
    8000126e:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001270:	03459793          	slli	a5,a1,0x34
    80001274:	e795                	bnez	a5,800012a0 <uvmunmap+0x46>
    80001276:	8a2a                	mv	s4,a0
    80001278:	892e                	mv	s2,a1
    8000127a:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000127c:	0632                	slli	a2,a2,0xc
    8000127e:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001282:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001284:	6b05                	lui	s6,0x1
    80001286:	0735e263          	bltu	a1,s3,800012ea <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000128a:	60a6                	ld	ra,72(sp)
    8000128c:	6406                	ld	s0,64(sp)
    8000128e:	74e2                	ld	s1,56(sp)
    80001290:	7942                	ld	s2,48(sp)
    80001292:	79a2                	ld	s3,40(sp)
    80001294:	7a02                	ld	s4,32(sp)
    80001296:	6ae2                	ld	s5,24(sp)
    80001298:	6b42                	ld	s6,16(sp)
    8000129a:	6ba2                	ld	s7,8(sp)
    8000129c:	6161                	addi	sp,sp,80
    8000129e:	8082                	ret
    panic("uvmunmap: not aligned");
    800012a0:	00007517          	auipc	a0,0x7
    800012a4:	e6050513          	addi	a0,a0,-416 # 80008100 <digits+0xc0>
    800012a8:	fffff097          	auipc	ra,0xfffff
    800012ac:	292080e7          	jalr	658(ra) # 8000053a <panic>
      panic("uvmunmap: walk");
    800012b0:	00007517          	auipc	a0,0x7
    800012b4:	e6850513          	addi	a0,a0,-408 # 80008118 <digits+0xd8>
    800012b8:	fffff097          	auipc	ra,0xfffff
    800012bc:	282080e7          	jalr	642(ra) # 8000053a <panic>
      panic("uvmunmap: not mapped");
    800012c0:	00007517          	auipc	a0,0x7
    800012c4:	e6850513          	addi	a0,a0,-408 # 80008128 <digits+0xe8>
    800012c8:	fffff097          	auipc	ra,0xfffff
    800012cc:	272080e7          	jalr	626(ra) # 8000053a <panic>
      panic("uvmunmap: not a leaf");
    800012d0:	00007517          	auipc	a0,0x7
    800012d4:	e7050513          	addi	a0,a0,-400 # 80008140 <digits+0x100>
    800012d8:	fffff097          	auipc	ra,0xfffff
    800012dc:	262080e7          	jalr	610(ra) # 8000053a <panic>
    *pte = 0;
    800012e0:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012e4:	995a                	add	s2,s2,s6
    800012e6:	fb3972e3          	bgeu	s2,s3,8000128a <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012ea:	4601                	li	a2,0
    800012ec:	85ca                	mv	a1,s2
    800012ee:	8552                	mv	a0,s4
    800012f0:	00000097          	auipc	ra,0x0
    800012f4:	cbc080e7          	jalr	-836(ra) # 80000fac <walk>
    800012f8:	84aa                	mv	s1,a0
    800012fa:	d95d                	beqz	a0,800012b0 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800012fc:	6108                	ld	a0,0(a0)
    800012fe:	00157793          	andi	a5,a0,1
    80001302:	dfdd                	beqz	a5,800012c0 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001304:	3ff57793          	andi	a5,a0,1023
    80001308:	fd7784e3          	beq	a5,s7,800012d0 <uvmunmap+0x76>
    if(do_free){
    8000130c:	fc0a8ae3          	beqz	s5,800012e0 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001310:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001312:	0532                	slli	a0,a0,0xc
    80001314:	fffff097          	auipc	ra,0xfffff
    80001318:	6ce080e7          	jalr	1742(ra) # 800009e2 <kfree>
    8000131c:	b7d1                	j	800012e0 <uvmunmap+0x86>

000000008000131e <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000131e:	1101                	addi	sp,sp,-32
    80001320:	ec06                	sd	ra,24(sp)
    80001322:	e822                	sd	s0,16(sp)
    80001324:	e426                	sd	s1,8(sp)
    80001326:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001328:	fffff097          	auipc	ra,0xfffff
    8000132c:	7b8080e7          	jalr	1976(ra) # 80000ae0 <kalloc>
    80001330:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001332:	c519                	beqz	a0,80001340 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001334:	6605                	lui	a2,0x1
    80001336:	4581                	li	a1,0
    80001338:	00000097          	auipc	ra,0x0
    8000133c:	994080e7          	jalr	-1644(ra) # 80000ccc <memset>
  return pagetable;
}
    80001340:	8526                	mv	a0,s1
    80001342:	60e2                	ld	ra,24(sp)
    80001344:	6442                	ld	s0,16(sp)
    80001346:	64a2                	ld	s1,8(sp)
    80001348:	6105                	addi	sp,sp,32
    8000134a:	8082                	ret

000000008000134c <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000134c:	7179                	addi	sp,sp,-48
    8000134e:	f406                	sd	ra,40(sp)
    80001350:	f022                	sd	s0,32(sp)
    80001352:	ec26                	sd	s1,24(sp)
    80001354:	e84a                	sd	s2,16(sp)
    80001356:	e44e                	sd	s3,8(sp)
    80001358:	e052                	sd	s4,0(sp)
    8000135a:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000135c:	6785                	lui	a5,0x1
    8000135e:	04f67863          	bgeu	a2,a5,800013ae <uvminit+0x62>
    80001362:	8a2a                	mv	s4,a0
    80001364:	89ae                	mv	s3,a1
    80001366:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001368:	fffff097          	auipc	ra,0xfffff
    8000136c:	778080e7          	jalr	1912(ra) # 80000ae0 <kalloc>
    80001370:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001372:	6605                	lui	a2,0x1
    80001374:	4581                	li	a1,0
    80001376:	00000097          	auipc	ra,0x0
    8000137a:	956080e7          	jalr	-1706(ra) # 80000ccc <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000137e:	4779                	li	a4,30
    80001380:	86ca                	mv	a3,s2
    80001382:	6605                	lui	a2,0x1
    80001384:	4581                	li	a1,0
    80001386:	8552                	mv	a0,s4
    80001388:	00000097          	auipc	ra,0x0
    8000138c:	d0c080e7          	jalr	-756(ra) # 80001094 <mappages>
  memmove(mem, src, sz);
    80001390:	8626                	mv	a2,s1
    80001392:	85ce                	mv	a1,s3
    80001394:	854a                	mv	a0,s2
    80001396:	00000097          	auipc	ra,0x0
    8000139a:	992080e7          	jalr	-1646(ra) # 80000d28 <memmove>
}
    8000139e:	70a2                	ld	ra,40(sp)
    800013a0:	7402                	ld	s0,32(sp)
    800013a2:	64e2                	ld	s1,24(sp)
    800013a4:	6942                	ld	s2,16(sp)
    800013a6:	69a2                	ld	s3,8(sp)
    800013a8:	6a02                	ld	s4,0(sp)
    800013aa:	6145                	addi	sp,sp,48
    800013ac:	8082                	ret
    panic("inituvm: more than a page");
    800013ae:	00007517          	auipc	a0,0x7
    800013b2:	daa50513          	addi	a0,a0,-598 # 80008158 <digits+0x118>
    800013b6:	fffff097          	auipc	ra,0xfffff
    800013ba:	184080e7          	jalr	388(ra) # 8000053a <panic>

00000000800013be <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013be:	1101                	addi	sp,sp,-32
    800013c0:	ec06                	sd	ra,24(sp)
    800013c2:	e822                	sd	s0,16(sp)
    800013c4:	e426                	sd	s1,8(sp)
    800013c6:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013c8:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013ca:	00b67d63          	bgeu	a2,a1,800013e4 <uvmdealloc+0x26>
    800013ce:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013d0:	6785                	lui	a5,0x1
    800013d2:	17fd                	addi	a5,a5,-1
    800013d4:	00f60733          	add	a4,a2,a5
    800013d8:	76fd                	lui	a3,0xfffff
    800013da:	8f75                	and	a4,a4,a3
    800013dc:	97ae                	add	a5,a5,a1
    800013de:	8ff5                	and	a5,a5,a3
    800013e0:	00f76863          	bltu	a4,a5,800013f0 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013e4:	8526                	mv	a0,s1
    800013e6:	60e2                	ld	ra,24(sp)
    800013e8:	6442                	ld	s0,16(sp)
    800013ea:	64a2                	ld	s1,8(sp)
    800013ec:	6105                	addi	sp,sp,32
    800013ee:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013f0:	8f99                	sub	a5,a5,a4
    800013f2:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013f4:	4685                	li	a3,1
    800013f6:	0007861b          	sext.w	a2,a5
    800013fa:	85ba                	mv	a1,a4
    800013fc:	00000097          	auipc	ra,0x0
    80001400:	e5e080e7          	jalr	-418(ra) # 8000125a <uvmunmap>
    80001404:	b7c5                	j	800013e4 <uvmdealloc+0x26>

0000000080001406 <uvmalloc>:
  if(newsz < oldsz)
    80001406:	0ab66163          	bltu	a2,a1,800014a8 <uvmalloc+0xa2>
{
    8000140a:	7139                	addi	sp,sp,-64
    8000140c:	fc06                	sd	ra,56(sp)
    8000140e:	f822                	sd	s0,48(sp)
    80001410:	f426                	sd	s1,40(sp)
    80001412:	f04a                	sd	s2,32(sp)
    80001414:	ec4e                	sd	s3,24(sp)
    80001416:	e852                	sd	s4,16(sp)
    80001418:	e456                	sd	s5,8(sp)
    8000141a:	0080                	addi	s0,sp,64
    8000141c:	8aaa                	mv	s5,a0
    8000141e:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001420:	6785                	lui	a5,0x1
    80001422:	17fd                	addi	a5,a5,-1
    80001424:	95be                	add	a1,a1,a5
    80001426:	77fd                	lui	a5,0xfffff
    80001428:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000142c:	08c9f063          	bgeu	s3,a2,800014ac <uvmalloc+0xa6>
    80001430:	894e                	mv	s2,s3
    mem = kalloc();
    80001432:	fffff097          	auipc	ra,0xfffff
    80001436:	6ae080e7          	jalr	1710(ra) # 80000ae0 <kalloc>
    8000143a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000143c:	c51d                	beqz	a0,8000146a <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000143e:	6605                	lui	a2,0x1
    80001440:	4581                	li	a1,0
    80001442:	00000097          	auipc	ra,0x0
    80001446:	88a080e7          	jalr	-1910(ra) # 80000ccc <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000144a:	4779                	li	a4,30
    8000144c:	86a6                	mv	a3,s1
    8000144e:	6605                	lui	a2,0x1
    80001450:	85ca                	mv	a1,s2
    80001452:	8556                	mv	a0,s5
    80001454:	00000097          	auipc	ra,0x0
    80001458:	c40080e7          	jalr	-960(ra) # 80001094 <mappages>
    8000145c:	e905                	bnez	a0,8000148c <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000145e:	6785                	lui	a5,0x1
    80001460:	993e                	add	s2,s2,a5
    80001462:	fd4968e3          	bltu	s2,s4,80001432 <uvmalloc+0x2c>
  return newsz;
    80001466:	8552                	mv	a0,s4
    80001468:	a809                	j	8000147a <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000146a:	864e                	mv	a2,s3
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	f4e080e7          	jalr	-178(ra) # 800013be <uvmdealloc>
      return 0;
    80001478:	4501                	li	a0,0
}
    8000147a:	70e2                	ld	ra,56(sp)
    8000147c:	7442                	ld	s0,48(sp)
    8000147e:	74a2                	ld	s1,40(sp)
    80001480:	7902                	ld	s2,32(sp)
    80001482:	69e2                	ld	s3,24(sp)
    80001484:	6a42                	ld	s4,16(sp)
    80001486:	6aa2                	ld	s5,8(sp)
    80001488:	6121                	addi	sp,sp,64
    8000148a:	8082                	ret
      kfree(mem);
    8000148c:	8526                	mv	a0,s1
    8000148e:	fffff097          	auipc	ra,0xfffff
    80001492:	554080e7          	jalr	1364(ra) # 800009e2 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001496:	864e                	mv	a2,s3
    80001498:	85ca                	mv	a1,s2
    8000149a:	8556                	mv	a0,s5
    8000149c:	00000097          	auipc	ra,0x0
    800014a0:	f22080e7          	jalr	-222(ra) # 800013be <uvmdealloc>
      return 0;
    800014a4:	4501                	li	a0,0
    800014a6:	bfd1                	j	8000147a <uvmalloc+0x74>
    return oldsz;
    800014a8:	852e                	mv	a0,a1
}
    800014aa:	8082                	ret
  return newsz;
    800014ac:	8532                	mv	a0,a2
    800014ae:	b7f1                	j	8000147a <uvmalloc+0x74>

00000000800014b0 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014b0:	7179                	addi	sp,sp,-48
    800014b2:	f406                	sd	ra,40(sp)
    800014b4:	f022                	sd	s0,32(sp)
    800014b6:	ec26                	sd	s1,24(sp)
    800014b8:	e84a                	sd	s2,16(sp)
    800014ba:	e44e                	sd	s3,8(sp)
    800014bc:	e052                	sd	s4,0(sp)
    800014be:	1800                	addi	s0,sp,48
    800014c0:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014c2:	84aa                	mv	s1,a0
    800014c4:	6905                	lui	s2,0x1
    800014c6:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014c8:	4985                	li	s3,1
    800014ca:	a829                	j	800014e4 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014cc:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014ce:	00c79513          	slli	a0,a5,0xc
    800014d2:	00000097          	auipc	ra,0x0
    800014d6:	fde080e7          	jalr	-34(ra) # 800014b0 <freewalk>
      pagetable[i] = 0;
    800014da:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014de:	04a1                	addi	s1,s1,8
    800014e0:	03248163          	beq	s1,s2,80001502 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800014e4:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e6:	00f7f713          	andi	a4,a5,15
    800014ea:	ff3701e3          	beq	a4,s3,800014cc <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014ee:	8b85                	andi	a5,a5,1
    800014f0:	d7fd                	beqz	a5,800014de <freewalk+0x2e>
      panic("freewalk: leaf");
    800014f2:	00007517          	auipc	a0,0x7
    800014f6:	c8650513          	addi	a0,a0,-890 # 80008178 <digits+0x138>
    800014fa:	fffff097          	auipc	ra,0xfffff
    800014fe:	040080e7          	jalr	64(ra) # 8000053a <panic>
    }
  }
  kfree((void*)pagetable);
    80001502:	8552                	mv	a0,s4
    80001504:	fffff097          	auipc	ra,0xfffff
    80001508:	4de080e7          	jalr	1246(ra) # 800009e2 <kfree>
}
    8000150c:	70a2                	ld	ra,40(sp)
    8000150e:	7402                	ld	s0,32(sp)
    80001510:	64e2                	ld	s1,24(sp)
    80001512:	6942                	ld	s2,16(sp)
    80001514:	69a2                	ld	s3,8(sp)
    80001516:	6a02                	ld	s4,0(sp)
    80001518:	6145                	addi	sp,sp,48
    8000151a:	8082                	ret

000000008000151c <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000151c:	1101                	addi	sp,sp,-32
    8000151e:	ec06                	sd	ra,24(sp)
    80001520:	e822                	sd	s0,16(sp)
    80001522:	e426                	sd	s1,8(sp)
    80001524:	1000                	addi	s0,sp,32
    80001526:	84aa                	mv	s1,a0
  if(sz > 0)
    80001528:	e999                	bnez	a1,8000153e <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000152a:	8526                	mv	a0,s1
    8000152c:	00000097          	auipc	ra,0x0
    80001530:	f84080e7          	jalr	-124(ra) # 800014b0 <freewalk>
}
    80001534:	60e2                	ld	ra,24(sp)
    80001536:	6442                	ld	s0,16(sp)
    80001538:	64a2                	ld	s1,8(sp)
    8000153a:	6105                	addi	sp,sp,32
    8000153c:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000153e:	6785                	lui	a5,0x1
    80001540:	17fd                	addi	a5,a5,-1
    80001542:	95be                	add	a1,a1,a5
    80001544:	4685                	li	a3,1
    80001546:	00c5d613          	srli	a2,a1,0xc
    8000154a:	4581                	li	a1,0
    8000154c:	00000097          	auipc	ra,0x0
    80001550:	d0e080e7          	jalr	-754(ra) # 8000125a <uvmunmap>
    80001554:	bfd9                	j	8000152a <uvmfree+0xe>

0000000080001556 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001556:	c679                	beqz	a2,80001624 <uvmcopy+0xce>
{
    80001558:	715d                	addi	sp,sp,-80
    8000155a:	e486                	sd	ra,72(sp)
    8000155c:	e0a2                	sd	s0,64(sp)
    8000155e:	fc26                	sd	s1,56(sp)
    80001560:	f84a                	sd	s2,48(sp)
    80001562:	f44e                	sd	s3,40(sp)
    80001564:	f052                	sd	s4,32(sp)
    80001566:	ec56                	sd	s5,24(sp)
    80001568:	e85a                	sd	s6,16(sp)
    8000156a:	e45e                	sd	s7,8(sp)
    8000156c:	0880                	addi	s0,sp,80
    8000156e:	8b2a                	mv	s6,a0
    80001570:	8aae                	mv	s5,a1
    80001572:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001574:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001576:	4601                	li	a2,0
    80001578:	85ce                	mv	a1,s3
    8000157a:	855a                	mv	a0,s6
    8000157c:	00000097          	auipc	ra,0x0
    80001580:	a30080e7          	jalr	-1488(ra) # 80000fac <walk>
    80001584:	c531                	beqz	a0,800015d0 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001586:	6118                	ld	a4,0(a0)
    80001588:	00177793          	andi	a5,a4,1
    8000158c:	cbb1                	beqz	a5,800015e0 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000158e:	00a75593          	srli	a1,a4,0xa
    80001592:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001596:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    8000159a:	fffff097          	auipc	ra,0xfffff
    8000159e:	546080e7          	jalr	1350(ra) # 80000ae0 <kalloc>
    800015a2:	892a                	mv	s2,a0
    800015a4:	c939                	beqz	a0,800015fa <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015a6:	6605                	lui	a2,0x1
    800015a8:	85de                	mv	a1,s7
    800015aa:	fffff097          	auipc	ra,0xfffff
    800015ae:	77e080e7          	jalr	1918(ra) # 80000d28 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015b2:	8726                	mv	a4,s1
    800015b4:	86ca                	mv	a3,s2
    800015b6:	6605                	lui	a2,0x1
    800015b8:	85ce                	mv	a1,s3
    800015ba:	8556                	mv	a0,s5
    800015bc:	00000097          	auipc	ra,0x0
    800015c0:	ad8080e7          	jalr	-1320(ra) # 80001094 <mappages>
    800015c4:	e515                	bnez	a0,800015f0 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015c6:	6785                	lui	a5,0x1
    800015c8:	99be                	add	s3,s3,a5
    800015ca:	fb49e6e3          	bltu	s3,s4,80001576 <uvmcopy+0x20>
    800015ce:	a081                	j	8000160e <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015d0:	00007517          	auipc	a0,0x7
    800015d4:	bb850513          	addi	a0,a0,-1096 # 80008188 <digits+0x148>
    800015d8:	fffff097          	auipc	ra,0xfffff
    800015dc:	f62080e7          	jalr	-158(ra) # 8000053a <panic>
      panic("uvmcopy: page not present");
    800015e0:	00007517          	auipc	a0,0x7
    800015e4:	bc850513          	addi	a0,a0,-1080 # 800081a8 <digits+0x168>
    800015e8:	fffff097          	auipc	ra,0xfffff
    800015ec:	f52080e7          	jalr	-174(ra) # 8000053a <panic>
      kfree(mem);
    800015f0:	854a                	mv	a0,s2
    800015f2:	fffff097          	auipc	ra,0xfffff
    800015f6:	3f0080e7          	jalr	1008(ra) # 800009e2 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800015fa:	4685                	li	a3,1
    800015fc:	00c9d613          	srli	a2,s3,0xc
    80001600:	4581                	li	a1,0
    80001602:	8556                	mv	a0,s5
    80001604:	00000097          	auipc	ra,0x0
    80001608:	c56080e7          	jalr	-938(ra) # 8000125a <uvmunmap>
  return -1;
    8000160c:	557d                	li	a0,-1
}
    8000160e:	60a6                	ld	ra,72(sp)
    80001610:	6406                	ld	s0,64(sp)
    80001612:	74e2                	ld	s1,56(sp)
    80001614:	7942                	ld	s2,48(sp)
    80001616:	79a2                	ld	s3,40(sp)
    80001618:	7a02                	ld	s4,32(sp)
    8000161a:	6ae2                	ld	s5,24(sp)
    8000161c:	6b42                	ld	s6,16(sp)
    8000161e:	6ba2                	ld	s7,8(sp)
    80001620:	6161                	addi	sp,sp,80
    80001622:	8082                	ret
  return 0;
    80001624:	4501                	li	a0,0
}
    80001626:	8082                	ret

0000000080001628 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001628:	1141                	addi	sp,sp,-16
    8000162a:	e406                	sd	ra,8(sp)
    8000162c:	e022                	sd	s0,0(sp)
    8000162e:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001630:	4601                	li	a2,0
    80001632:	00000097          	auipc	ra,0x0
    80001636:	97a080e7          	jalr	-1670(ra) # 80000fac <walk>
  if(pte == 0)
    8000163a:	c901                	beqz	a0,8000164a <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000163c:	611c                	ld	a5,0(a0)
    8000163e:	9bbd                	andi	a5,a5,-17
    80001640:	e11c                	sd	a5,0(a0)
}
    80001642:	60a2                	ld	ra,8(sp)
    80001644:	6402                	ld	s0,0(sp)
    80001646:	0141                	addi	sp,sp,16
    80001648:	8082                	ret
    panic("uvmclear");
    8000164a:	00007517          	auipc	a0,0x7
    8000164e:	b7e50513          	addi	a0,a0,-1154 # 800081c8 <digits+0x188>
    80001652:	fffff097          	auipc	ra,0xfffff
    80001656:	ee8080e7          	jalr	-280(ra) # 8000053a <panic>

000000008000165a <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000165a:	c6bd                	beqz	a3,800016c8 <copyout+0x6e>
{
    8000165c:	715d                	addi	sp,sp,-80
    8000165e:	e486                	sd	ra,72(sp)
    80001660:	e0a2                	sd	s0,64(sp)
    80001662:	fc26                	sd	s1,56(sp)
    80001664:	f84a                	sd	s2,48(sp)
    80001666:	f44e                	sd	s3,40(sp)
    80001668:	f052                	sd	s4,32(sp)
    8000166a:	ec56                	sd	s5,24(sp)
    8000166c:	e85a                	sd	s6,16(sp)
    8000166e:	e45e                	sd	s7,8(sp)
    80001670:	e062                	sd	s8,0(sp)
    80001672:	0880                	addi	s0,sp,80
    80001674:	8b2a                	mv	s6,a0
    80001676:	8c2e                	mv	s8,a1
    80001678:	8a32                	mv	s4,a2
    8000167a:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000167c:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000167e:	6a85                	lui	s5,0x1
    80001680:	a015                	j	800016a4 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001682:	9562                	add	a0,a0,s8
    80001684:	0004861b          	sext.w	a2,s1
    80001688:	85d2                	mv	a1,s4
    8000168a:	41250533          	sub	a0,a0,s2
    8000168e:	fffff097          	auipc	ra,0xfffff
    80001692:	69a080e7          	jalr	1690(ra) # 80000d28 <memmove>

    len -= n;
    80001696:	409989b3          	sub	s3,s3,s1
    src += n;
    8000169a:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    8000169c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016a0:	02098263          	beqz	s3,800016c4 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016a4:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016a8:	85ca                	mv	a1,s2
    800016aa:	855a                	mv	a0,s6
    800016ac:	00000097          	auipc	ra,0x0
    800016b0:	9a6080e7          	jalr	-1626(ra) # 80001052 <walkaddr>
    if(pa0 == 0)
    800016b4:	cd01                	beqz	a0,800016cc <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016b6:	418904b3          	sub	s1,s2,s8
    800016ba:	94d6                	add	s1,s1,s5
    800016bc:	fc99f3e3          	bgeu	s3,s1,80001682 <copyout+0x28>
    800016c0:	84ce                	mv	s1,s3
    800016c2:	b7c1                	j	80001682 <copyout+0x28>
  }
  return 0;
    800016c4:	4501                	li	a0,0
    800016c6:	a021                	j	800016ce <copyout+0x74>
    800016c8:	4501                	li	a0,0
}
    800016ca:	8082                	ret
      return -1;
    800016cc:	557d                	li	a0,-1
}
    800016ce:	60a6                	ld	ra,72(sp)
    800016d0:	6406                	ld	s0,64(sp)
    800016d2:	74e2                	ld	s1,56(sp)
    800016d4:	7942                	ld	s2,48(sp)
    800016d6:	79a2                	ld	s3,40(sp)
    800016d8:	7a02                	ld	s4,32(sp)
    800016da:	6ae2                	ld	s5,24(sp)
    800016dc:	6b42                	ld	s6,16(sp)
    800016de:	6ba2                	ld	s7,8(sp)
    800016e0:	6c02                	ld	s8,0(sp)
    800016e2:	6161                	addi	sp,sp,80
    800016e4:	8082                	ret

00000000800016e6 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016e6:	caa5                	beqz	a3,80001756 <copyin+0x70>
{
    800016e8:	715d                	addi	sp,sp,-80
    800016ea:	e486                	sd	ra,72(sp)
    800016ec:	e0a2                	sd	s0,64(sp)
    800016ee:	fc26                	sd	s1,56(sp)
    800016f0:	f84a                	sd	s2,48(sp)
    800016f2:	f44e                	sd	s3,40(sp)
    800016f4:	f052                	sd	s4,32(sp)
    800016f6:	ec56                	sd	s5,24(sp)
    800016f8:	e85a                	sd	s6,16(sp)
    800016fa:	e45e                	sd	s7,8(sp)
    800016fc:	e062                	sd	s8,0(sp)
    800016fe:	0880                	addi	s0,sp,80
    80001700:	8b2a                	mv	s6,a0
    80001702:	8a2e                	mv	s4,a1
    80001704:	8c32                	mv	s8,a2
    80001706:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001708:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000170a:	6a85                	lui	s5,0x1
    8000170c:	a01d                	j	80001732 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000170e:	018505b3          	add	a1,a0,s8
    80001712:	0004861b          	sext.w	a2,s1
    80001716:	412585b3          	sub	a1,a1,s2
    8000171a:	8552                	mv	a0,s4
    8000171c:	fffff097          	auipc	ra,0xfffff
    80001720:	60c080e7          	jalr	1548(ra) # 80000d28 <memmove>

    len -= n;
    80001724:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001728:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000172a:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000172e:	02098263          	beqz	s3,80001752 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001732:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001736:	85ca                	mv	a1,s2
    80001738:	855a                	mv	a0,s6
    8000173a:	00000097          	auipc	ra,0x0
    8000173e:	918080e7          	jalr	-1768(ra) # 80001052 <walkaddr>
    if(pa0 == 0)
    80001742:	cd01                	beqz	a0,8000175a <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001744:	418904b3          	sub	s1,s2,s8
    80001748:	94d6                	add	s1,s1,s5
    8000174a:	fc99f2e3          	bgeu	s3,s1,8000170e <copyin+0x28>
    8000174e:	84ce                	mv	s1,s3
    80001750:	bf7d                	j	8000170e <copyin+0x28>
  }
  return 0;
    80001752:	4501                	li	a0,0
    80001754:	a021                	j	8000175c <copyin+0x76>
    80001756:	4501                	li	a0,0
}
    80001758:	8082                	ret
      return -1;
    8000175a:	557d                	li	a0,-1
}
    8000175c:	60a6                	ld	ra,72(sp)
    8000175e:	6406                	ld	s0,64(sp)
    80001760:	74e2                	ld	s1,56(sp)
    80001762:	7942                	ld	s2,48(sp)
    80001764:	79a2                	ld	s3,40(sp)
    80001766:	7a02                	ld	s4,32(sp)
    80001768:	6ae2                	ld	s5,24(sp)
    8000176a:	6b42                	ld	s6,16(sp)
    8000176c:	6ba2                	ld	s7,8(sp)
    8000176e:	6c02                	ld	s8,0(sp)
    80001770:	6161                	addi	sp,sp,80
    80001772:	8082                	ret

0000000080001774 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001774:	c2dd                	beqz	a3,8000181a <copyinstr+0xa6>
{
    80001776:	715d                	addi	sp,sp,-80
    80001778:	e486                	sd	ra,72(sp)
    8000177a:	e0a2                	sd	s0,64(sp)
    8000177c:	fc26                	sd	s1,56(sp)
    8000177e:	f84a                	sd	s2,48(sp)
    80001780:	f44e                	sd	s3,40(sp)
    80001782:	f052                	sd	s4,32(sp)
    80001784:	ec56                	sd	s5,24(sp)
    80001786:	e85a                	sd	s6,16(sp)
    80001788:	e45e                	sd	s7,8(sp)
    8000178a:	0880                	addi	s0,sp,80
    8000178c:	8a2a                	mv	s4,a0
    8000178e:	8b2e                	mv	s6,a1
    80001790:	8bb2                	mv	s7,a2
    80001792:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001794:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001796:	6985                	lui	s3,0x1
    80001798:	a02d                	j	800017c2 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    8000179a:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    8000179e:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017a0:	37fd                	addiw	a5,a5,-1
    800017a2:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017a6:	60a6                	ld	ra,72(sp)
    800017a8:	6406                	ld	s0,64(sp)
    800017aa:	74e2                	ld	s1,56(sp)
    800017ac:	7942                	ld	s2,48(sp)
    800017ae:	79a2                	ld	s3,40(sp)
    800017b0:	7a02                	ld	s4,32(sp)
    800017b2:	6ae2                	ld	s5,24(sp)
    800017b4:	6b42                	ld	s6,16(sp)
    800017b6:	6ba2                	ld	s7,8(sp)
    800017b8:	6161                	addi	sp,sp,80
    800017ba:	8082                	ret
    srcva = va0 + PGSIZE;
    800017bc:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017c0:	c8a9                	beqz	s1,80001812 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017c2:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017c6:	85ca                	mv	a1,s2
    800017c8:	8552                	mv	a0,s4
    800017ca:	00000097          	auipc	ra,0x0
    800017ce:	888080e7          	jalr	-1912(ra) # 80001052 <walkaddr>
    if(pa0 == 0)
    800017d2:	c131                	beqz	a0,80001816 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017d4:	417906b3          	sub	a3,s2,s7
    800017d8:	96ce                	add	a3,a3,s3
    800017da:	00d4f363          	bgeu	s1,a3,800017e0 <copyinstr+0x6c>
    800017de:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017e0:	955e                	add	a0,a0,s7
    800017e2:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017e6:	daf9                	beqz	a3,800017bc <copyinstr+0x48>
    800017e8:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017ea:	41650633          	sub	a2,a0,s6
    800017ee:	fff48593          	addi	a1,s1,-1
    800017f2:	95da                	add	a1,a1,s6
    while(n > 0){
    800017f4:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    800017f6:	00f60733          	add	a4,a2,a5
    800017fa:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd7c80>
    800017fe:	df51                	beqz	a4,8000179a <copyinstr+0x26>
        *dst = *p;
    80001800:	00e78023          	sb	a4,0(a5)
      --max;
    80001804:	40f584b3          	sub	s1,a1,a5
      dst++;
    80001808:	0785                	addi	a5,a5,1
    while(n > 0){
    8000180a:	fed796e3          	bne	a5,a3,800017f6 <copyinstr+0x82>
      dst++;
    8000180e:	8b3e                	mv	s6,a5
    80001810:	b775                	j	800017bc <copyinstr+0x48>
    80001812:	4781                	li	a5,0
    80001814:	b771                	j	800017a0 <copyinstr+0x2c>
      return -1;
    80001816:	557d                	li	a0,-1
    80001818:	b779                	j	800017a6 <copyinstr+0x32>
  int got_null = 0;
    8000181a:	4781                	li	a5,0
  if(got_null){
    8000181c:	37fd                	addiw	a5,a5,-1
    8000181e:	0007851b          	sext.w	a0,a5
}
    80001822:	8082                	ret

0000000080001824 <printStats>:
}

// Scheduler statistics function 
int printStats(int n, int prog_num)
{
    if(pflag==1)
    80001824:	00008717          	auipc	a4,0x8
    80001828:	80472703          	lw	a4,-2044(a4) # 80009028 <pflag>
    8000182c:	4785                	li	a5,1
    8000182e:	00f70463          	beq	a4,a5,80001836 <printStats+0x12>
	   printf("Total # tickets : %d\n",(TCount[prog1id]+TCount[prog2id]+TCount[prog3id]));
   	   pflag=0;

    }
    return 1;
}
    80001832:	4505                	li	a0,1
    80001834:	8082                	ret
{
    80001836:	7179                	addi	sp,sp,-48
    80001838:	f406                	sd	ra,40(sp)
    8000183a:	f022                	sd	s0,32(sp)
    8000183c:	ec26                	sd	s1,24(sp)
    8000183e:	e84a                	sd	s2,16(sp)
    80001840:	e44e                	sd	s3,8(sp)
    80001842:	e052                	sd	s4,0(sp)
    80001844:	1800                	addi	s0,sp,48
	   printf("# Tickets--P1 : %d\n",TCount[prog1id]);
    80001846:	00010497          	auipc	s1,0x10
    8000184a:	a6a48493          	addi	s1,s1,-1430 # 800112b0 <TCount>
    8000184e:	00007a17          	auipc	s4,0x7
    80001852:	7e6a0a13          	addi	s4,s4,2022 # 80009034 <prog1id>
    80001856:	000a2783          	lw	a5,0(s4)
    8000185a:	078a                	slli	a5,a5,0x2
    8000185c:	97a6                	add	a5,a5,s1
    8000185e:	438c                	lw	a1,0(a5)
    80001860:	00007517          	auipc	a0,0x7
    80001864:	97850513          	addi	a0,a0,-1672 # 800081d8 <digits+0x198>
    80001868:	fffff097          	auipc	ra,0xfffff
    8000186c:	d1c080e7          	jalr	-740(ra) # 80000584 <printf>
	   printf("# Tickets--P2 : %d\n",TCount[prog2id]);
    80001870:	00007997          	auipc	s3,0x7
    80001874:	7c098993          	addi	s3,s3,1984 # 80009030 <prog2id>
    80001878:	0009a783          	lw	a5,0(s3)
    8000187c:	078a                	slli	a5,a5,0x2
    8000187e:	97a6                	add	a5,a5,s1
    80001880:	438c                	lw	a1,0(a5)
    80001882:	00007517          	auipc	a0,0x7
    80001886:	96e50513          	addi	a0,a0,-1682 # 800081f0 <digits+0x1b0>
    8000188a:	fffff097          	auipc	ra,0xfffff
    8000188e:	cfa080e7          	jalr	-774(ra) # 80000584 <printf>
	   printf("# Tickets--P3 : %d\n",TCount[prog3id]);
    80001892:	00007917          	auipc	s2,0x7
    80001896:	79a90913          	addi	s2,s2,1946 # 8000902c <prog3id>
    8000189a:	00092783          	lw	a5,0(s2)
    8000189e:	078a                	slli	a5,a5,0x2
    800018a0:	97a6                	add	a5,a5,s1
    800018a2:	438c                	lw	a1,0(a5)
    800018a4:	00007517          	auipc	a0,0x7
    800018a8:	96450513          	addi	a0,a0,-1692 # 80008208 <digits+0x1c8>
    800018ac:	fffff097          	auipc	ra,0xfffff
    800018b0:	cd8080e7          	jalr	-808(ra) # 80000584 <printf>
	   printf("Total # tickets : %d\n",(TCount[prog1id]+TCount[prog2id]+TCount[prog3id]));
    800018b4:	000a2703          	lw	a4,0(s4)
    800018b8:	070a                	slli	a4,a4,0x2
    800018ba:	9726                	add	a4,a4,s1
    800018bc:	0009a783          	lw	a5,0(s3)
    800018c0:	078a                	slli	a5,a5,0x2
    800018c2:	97a6                	add	a5,a5,s1
    800018c4:	4318                	lw	a4,0(a4)
    800018c6:	439c                	lw	a5,0(a5)
    800018c8:	9fb9                	addw	a5,a5,a4
    800018ca:	00092703          	lw	a4,0(s2)
    800018ce:	070a                	slli	a4,a4,0x2
    800018d0:	94ba                	add	s1,s1,a4
    800018d2:	408c                	lw	a1,0(s1)
    800018d4:	9dbd                	addw	a1,a1,a5
    800018d6:	00007517          	auipc	a0,0x7
    800018da:	94a50513          	addi	a0,a0,-1718 # 80008220 <digits+0x1e0>
    800018de:	fffff097          	auipc	ra,0xfffff
    800018e2:	ca6080e7          	jalr	-858(ra) # 80000584 <printf>
   	   pflag=0;
    800018e6:	00007797          	auipc	a5,0x7
    800018ea:	7407a123          	sw	zero,1858(a5) # 80009028 <pflag>
}
    800018ee:	4505                	li	a0,1
    800018f0:	70a2                	ld	ra,40(sp)
    800018f2:	7402                	ld	s0,32(sp)
    800018f4:	64e2                	ld	s1,24(sp)
    800018f6:	6942                	ld	s2,16(sp)
    800018f8:	69a2                	ld	s3,8(sp)
    800018fa:	6a02                	ld	s4,0(sp)
    800018fc:	6145                	addi	sp,sp,48
    800018fe:	8082                	ret

0000000080001900 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001900:	7139                	addi	sp,sp,-64
    80001902:	fc06                	sd	ra,56(sp)
    80001904:	f822                	sd	s0,48(sp)
    80001906:	f426                	sd	s1,40(sp)
    80001908:	f04a                	sd	s2,32(sp)
    8000190a:	ec4e                	sd	s3,24(sp)
    8000190c:	e852                	sd	s4,16(sp)
    8000190e:	e456                	sd	s5,8(sp)
    80001910:	e05a                	sd	s6,0(sp)
    80001912:	0080                	addi	s0,sp,64
    80001914:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001916:	00010497          	auipc	s1,0x10
    8000191a:	eca48493          	addi	s1,s1,-310 # 800117e0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000191e:	8b26                	mv	s6,s1
    80001920:	00006a97          	auipc	s5,0x6
    80001924:	6e0a8a93          	addi	s5,s5,1760 # 80008000 <etext>
    80001928:	04000937          	lui	s2,0x4000
    8000192c:	197d                	addi	s2,s2,-1
    8000192e:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001930:	00016a17          	auipc	s4,0x16
    80001934:	cb0a0a13          	addi	s4,s4,-848 # 800175e0 <tickslock>
    char *pa = kalloc();
    80001938:	fffff097          	auipc	ra,0xfffff
    8000193c:	1a8080e7          	jalr	424(ra) # 80000ae0 <kalloc>
    80001940:	862a                	mv	a2,a0
    if(pa == 0)
    80001942:	c131                	beqz	a0,80001986 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001944:	416485b3          	sub	a1,s1,s6
    80001948:	858d                	srai	a1,a1,0x3
    8000194a:	000ab783          	ld	a5,0(s5)
    8000194e:	02f585b3          	mul	a1,a1,a5
    80001952:	2585                	addiw	a1,a1,1
    80001954:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001958:	4719                	li	a4,6
    8000195a:	6685                	lui	a3,0x1
    8000195c:	40b905b3          	sub	a1,s2,a1
    80001960:	854e                	mv	a0,s3
    80001962:	fffff097          	auipc	ra,0xfffff
    80001966:	7d2080e7          	jalr	2002(ra) # 80001134 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000196a:	17848493          	addi	s1,s1,376
    8000196e:	fd4495e3          	bne	s1,s4,80001938 <proc_mapstacks+0x38>
  }
}
    80001972:	70e2                	ld	ra,56(sp)
    80001974:	7442                	ld	s0,48(sp)
    80001976:	74a2                	ld	s1,40(sp)
    80001978:	7902                	ld	s2,32(sp)
    8000197a:	69e2                	ld	s3,24(sp)
    8000197c:	6a42                	ld	s4,16(sp)
    8000197e:	6aa2                	ld	s5,8(sp)
    80001980:	6b02                	ld	s6,0(sp)
    80001982:	6121                	addi	sp,sp,64
    80001984:	8082                	ret
      panic("kalloc");
    80001986:	00007517          	auipc	a0,0x7
    8000198a:	8b250513          	addi	a0,a0,-1870 # 80008238 <digits+0x1f8>
    8000198e:	fffff097          	auipc	ra,0xfffff
    80001992:	bac080e7          	jalr	-1108(ra) # 8000053a <panic>

0000000080001996 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001996:	7139                	addi	sp,sp,-64
    80001998:	fc06                	sd	ra,56(sp)
    8000199a:	f822                	sd	s0,48(sp)
    8000199c:	f426                	sd	s1,40(sp)
    8000199e:	f04a                	sd	s2,32(sp)
    800019a0:	ec4e                	sd	s3,24(sp)
    800019a2:	e852                	sd	s4,16(sp)
    800019a4:	e456                	sd	s5,8(sp)
    800019a6:	e05a                	sd	s6,0(sp)
    800019a8:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800019aa:	00007597          	auipc	a1,0x7
    800019ae:	89658593          	addi	a1,a1,-1898 # 80008240 <digits+0x200>
    800019b2:	00010517          	auipc	a0,0x10
    800019b6:	9fe50513          	addi	a0,a0,-1538 # 800113b0 <pid_lock>
    800019ba:	fffff097          	auipc	ra,0xfffff
    800019be:	186080e7          	jalr	390(ra) # 80000b40 <initlock>
  initlock(&wait_lock, "wait_lock");
    800019c2:	00007597          	auipc	a1,0x7
    800019c6:	88658593          	addi	a1,a1,-1914 # 80008248 <digits+0x208>
    800019ca:	00010517          	auipc	a0,0x10
    800019ce:	9fe50513          	addi	a0,a0,-1538 # 800113c8 <wait_lock>
    800019d2:	fffff097          	auipc	ra,0xfffff
    800019d6:	16e080e7          	jalr	366(ra) # 80000b40 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    800019da:	00010497          	auipc	s1,0x10
    800019de:	e0648493          	addi	s1,s1,-506 # 800117e0 <proc>
      initlock(&p->lock, "proc");
    800019e2:	00007b17          	auipc	s6,0x7
    800019e6:	876b0b13          	addi	s6,s6,-1930 # 80008258 <digits+0x218>
      p->kstack = KSTACK((int) (p - proc));
    800019ea:	8aa6                	mv	s5,s1
    800019ec:	00006a17          	auipc	s4,0x6
    800019f0:	614a0a13          	addi	s4,s4,1556 # 80008000 <etext>
    800019f4:	04000937          	lui	s2,0x4000
    800019f8:	197d                	addi	s2,s2,-1
    800019fa:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800019fc:	00016997          	auipc	s3,0x16
    80001a00:	be498993          	addi	s3,s3,-1052 # 800175e0 <tickslock>
      initlock(&p->lock, "proc");
    80001a04:	85da                	mv	a1,s6
    80001a06:	8526                	mv	a0,s1
    80001a08:	fffff097          	auipc	ra,0xfffff
    80001a0c:	138080e7          	jalr	312(ra) # 80000b40 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001a10:	415487b3          	sub	a5,s1,s5
    80001a14:	878d                	srai	a5,a5,0x3
    80001a16:	000a3703          	ld	a4,0(s4)
    80001a1a:	02e787b3          	mul	a5,a5,a4
    80001a1e:	2785                	addiw	a5,a5,1
    80001a20:	00d7979b          	slliw	a5,a5,0xd
    80001a24:	40f907b3          	sub	a5,s2,a5
    80001a28:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a2a:	17848493          	addi	s1,s1,376
    80001a2e:	fd349be3          	bne	s1,s3,80001a04 <procinit+0x6e>
  }
}
    80001a32:	70e2                	ld	ra,56(sp)
    80001a34:	7442                	ld	s0,48(sp)
    80001a36:	74a2                	ld	s1,40(sp)
    80001a38:	7902                	ld	s2,32(sp)
    80001a3a:	69e2                	ld	s3,24(sp)
    80001a3c:	6a42                	ld	s4,16(sp)
    80001a3e:	6aa2                	ld	s5,8(sp)
    80001a40:	6b02                	ld	s6,0(sp)
    80001a42:	6121                	addi	sp,sp,64
    80001a44:	8082                	ret

0000000080001a46 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001a46:	1141                	addi	sp,sp,-16
    80001a48:	e422                	sd	s0,8(sp)
    80001a4a:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a4c:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001a4e:	2501                	sext.w	a0,a0
    80001a50:	6422                	ld	s0,8(sp)
    80001a52:	0141                	addi	sp,sp,16
    80001a54:	8082                	ret

0000000080001a56 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001a56:	1141                	addi	sp,sp,-16
    80001a58:	e422                	sd	s0,8(sp)
    80001a5a:	0800                	addi	s0,sp,16
    80001a5c:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001a5e:	2781                	sext.w	a5,a5
    80001a60:	079e                	slli	a5,a5,0x7
  return c;
}
    80001a62:	00010517          	auipc	a0,0x10
    80001a66:	97e50513          	addi	a0,a0,-1666 # 800113e0 <cpus>
    80001a6a:	953e                	add	a0,a0,a5
    80001a6c:	6422                	ld	s0,8(sp)
    80001a6e:	0141                	addi	sp,sp,16
    80001a70:	8082                	ret

0000000080001a72 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001a72:	1101                	addi	sp,sp,-32
    80001a74:	ec06                	sd	ra,24(sp)
    80001a76:	e822                	sd	s0,16(sp)
    80001a78:	e426                	sd	s1,8(sp)
    80001a7a:	1000                	addi	s0,sp,32
  push_off();
    80001a7c:	fffff097          	auipc	ra,0xfffff
    80001a80:	108080e7          	jalr	264(ra) # 80000b84 <push_off>
    80001a84:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001a86:	2781                	sext.w	a5,a5
    80001a88:	079e                	slli	a5,a5,0x7
    80001a8a:	00010717          	auipc	a4,0x10
    80001a8e:	82670713          	addi	a4,a4,-2010 # 800112b0 <TCount>
    80001a92:	97ba                	add	a5,a5,a4
    80001a94:	1307b483          	ld	s1,304(a5)
  pop_off();
    80001a98:	fffff097          	auipc	ra,0xfffff
    80001a9c:	18c080e7          	jalr	396(ra) # 80000c24 <pop_off>
  return p;
}
    80001aa0:	8526                	mv	a0,s1
    80001aa2:	60e2                	ld	ra,24(sp)
    80001aa4:	6442                	ld	s0,16(sp)
    80001aa6:	64a2                	ld	s1,8(sp)
    80001aa8:	6105                	addi	sp,sp,32
    80001aaa:	8082                	ret

0000000080001aac <createTickets>:
{
    80001aac:	1101                	addi	sp,sp,-32
    80001aae:	ec06                	sd	ra,24(sp)
    80001ab0:	e822                	sd	s0,16(sp)
    80001ab2:	e426                	sd	s1,8(sp)
    80001ab4:	1000                	addi	s0,sp,32
    80001ab6:	84aa                	mv	s1,a0
    struct proc *p = myproc();
    80001ab8:	00000097          	auipc	ra,0x0
    80001abc:	fba080e7          	jalr	-70(ra) # 80001a72 <myproc>
    p->tickets=n;
    80001ac0:	16952423          	sw	s1,360(a0)
	p->stride = 30000/n;
    80001ac4:	679d                	lui	a5,0x7
    80001ac6:	5307879b          	addiw	a5,a5,1328
    80001aca:	0297c7bb          	divw	a5,a5,s1
    80001ace:	16f52823          	sw	a5,368(a0)
	p->pass = p->stride;
    80001ad2:	16f52623          	sw	a5,364(a0)
    TCount[p->pid]=0;
    80001ad6:	5918                	lw	a4,48(a0)
    80001ad8:	070a                	slli	a4,a4,0x2
    80001ada:	0000f797          	auipc	a5,0xf
    80001ade:	7d678793          	addi	a5,a5,2006 # 800112b0 <TCount>
    80001ae2:	97ba                	add	a5,a5,a4
    80001ae4:	0007a023          	sw	zero,0(a5)
    if(n==30){
    80001ae8:	47f9                	li	a5,30
    80001aea:	00f48e63          	beq	s1,a5,80001b06 <createTickets+0x5a>
    else if(n==20){
    80001aee:	47d1                	li	a5,20
    80001af0:	04f48063          	beq	s1,a5,80001b30 <createTickets+0x84>
    else if(n==10){
    80001af4:	47a9                	li	a5,10
    80001af6:	06f48263          	beq	s1,a5,80001b5a <createTickets+0xae>
}
    80001afa:	4505                	li	a0,1
    80001afc:	60e2                	ld	ra,24(sp)
    80001afe:	6442                	ld	s0,16(sp)
    80001b00:	64a2                	ld	s1,8(sp)
    80001b02:	6105                	addi	sp,sp,32
    80001b04:	8082                	ret
	    prog1id=p->pid;
    80001b06:	591c                	lw	a5,48(a0)
    80001b08:	00007717          	auipc	a4,0x7
    80001b0c:	52f72623          	sw	a5,1324(a4) # 80009034 <prog1id>
	    pflag=1;
    80001b10:	4785                	li	a5,1
    80001b12:	00007717          	auipc	a4,0x7
    80001b16:	50f72b23          	sw	a5,1302(a4) # 80009028 <pflag>
		printf("Pass--P1 : %d\n",p->pass);
    80001b1a:	3e800593          	li	a1,1000
    80001b1e:	00006517          	auipc	a0,0x6
    80001b22:	74250513          	addi	a0,a0,1858 # 80008260 <digits+0x220>
    80001b26:	fffff097          	auipc	ra,0xfffff
    80001b2a:	a5e080e7          	jalr	-1442(ra) # 80000584 <printf>
    80001b2e:	b7f1                	j	80001afa <createTickets+0x4e>
	    prog2id=p->pid;
    80001b30:	591c                	lw	a5,48(a0)
    80001b32:	00007717          	auipc	a4,0x7
    80001b36:	4ef72f23          	sw	a5,1278(a4) # 80009030 <prog2id>
	    pflag=1;
    80001b3a:	4785                	li	a5,1
    80001b3c:	00007717          	auipc	a4,0x7
    80001b40:	4ef72623          	sw	a5,1260(a4) # 80009028 <pflag>
		printf("Pass--P2 : %d\n",p->pass);
    80001b44:	5dc00593          	li	a1,1500
    80001b48:	00006517          	auipc	a0,0x6
    80001b4c:	72850513          	addi	a0,a0,1832 # 80008270 <digits+0x230>
    80001b50:	fffff097          	auipc	ra,0xfffff
    80001b54:	a34080e7          	jalr	-1484(ra) # 80000584 <printf>
    80001b58:	b74d                	j	80001afa <createTickets+0x4e>
	    prog3id=p->pid;
    80001b5a:	591c                	lw	a5,48(a0)
    80001b5c:	00007717          	auipc	a4,0x7
    80001b60:	4cf72823          	sw	a5,1232(a4) # 8000902c <prog3id>
	    pflag=1;
    80001b64:	4785                	li	a5,1
    80001b66:	00007717          	auipc	a4,0x7
    80001b6a:	4cf72123          	sw	a5,1218(a4) # 80009028 <pflag>
		printf("Pass--P3 : %d\n",p->pass);
    80001b6e:	6585                	lui	a1,0x1
    80001b70:	bb858593          	addi	a1,a1,-1096 # bb8 <_entry-0x7ffff448>
    80001b74:	00006517          	auipc	a0,0x6
    80001b78:	70c50513          	addi	a0,a0,1804 # 80008280 <digits+0x240>
    80001b7c:	fffff097          	auipc	ra,0xfffff
    80001b80:	a08080e7          	jalr	-1528(ra) # 80000584 <printf>
    80001b84:	bf9d                	j	80001afa <createTickets+0x4e>

0000000080001b86 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001b86:	1141                	addi	sp,sp,-16
    80001b88:	e406                	sd	ra,8(sp)
    80001b8a:	e022                	sd	s0,0(sp)
    80001b8c:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001b8e:	00000097          	auipc	ra,0x0
    80001b92:	ee4080e7          	jalr	-284(ra) # 80001a72 <myproc>
    80001b96:	fffff097          	auipc	ra,0xfffff
    80001b9a:	0ee080e7          	jalr	238(ra) # 80000c84 <release>

  if (first) {
    80001b9e:	00007797          	auipc	a5,0x7
    80001ba2:	d227a783          	lw	a5,-734(a5) # 800088c0 <first.1>
    80001ba6:	eb89                	bnez	a5,80001bb8 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001ba8:	00001097          	auipc	ra,0x1
    80001bac:	c6c080e7          	jalr	-916(ra) # 80002814 <usertrapret>
}
    80001bb0:	60a2                	ld	ra,8(sp)
    80001bb2:	6402                	ld	s0,0(sp)
    80001bb4:	0141                	addi	sp,sp,16
    80001bb6:	8082                	ret
    first = 0;
    80001bb8:	00007797          	auipc	a5,0x7
    80001bbc:	d007a423          	sw	zero,-760(a5) # 800088c0 <first.1>
    fsinit(ROOTDEV);
    80001bc0:	4505                	li	a0,1
    80001bc2:	00002097          	auipc	ra,0x2
    80001bc6:	9fc080e7          	jalr	-1540(ra) # 800035be <fsinit>
    80001bca:	bff9                	j	80001ba8 <forkret+0x22>

0000000080001bcc <allocpid>:
allocpid() {
    80001bcc:	1101                	addi	sp,sp,-32
    80001bce:	ec06                	sd	ra,24(sp)
    80001bd0:	e822                	sd	s0,16(sp)
    80001bd2:	e426                	sd	s1,8(sp)
    80001bd4:	e04a                	sd	s2,0(sp)
    80001bd6:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001bd8:	0000f917          	auipc	s2,0xf
    80001bdc:	7d890913          	addi	s2,s2,2008 # 800113b0 <pid_lock>
    80001be0:	854a                	mv	a0,s2
    80001be2:	fffff097          	auipc	ra,0xfffff
    80001be6:	fee080e7          	jalr	-18(ra) # 80000bd0 <acquire>
  pid = nextpid;
    80001bea:	00007797          	auipc	a5,0x7
    80001bee:	cda78793          	addi	a5,a5,-806 # 800088c4 <nextpid>
    80001bf2:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001bf4:	0014871b          	addiw	a4,s1,1
    80001bf8:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001bfa:	854a                	mv	a0,s2
    80001bfc:	fffff097          	auipc	ra,0xfffff
    80001c00:	088080e7          	jalr	136(ra) # 80000c84 <release>
}
    80001c04:	8526                	mv	a0,s1
    80001c06:	60e2                	ld	ra,24(sp)
    80001c08:	6442                	ld	s0,16(sp)
    80001c0a:	64a2                	ld	s1,8(sp)
    80001c0c:	6902                	ld	s2,0(sp)
    80001c0e:	6105                	addi	sp,sp,32
    80001c10:	8082                	ret

0000000080001c12 <proc_pagetable>:
{
    80001c12:	1101                	addi	sp,sp,-32
    80001c14:	ec06                	sd	ra,24(sp)
    80001c16:	e822                	sd	s0,16(sp)
    80001c18:	e426                	sd	s1,8(sp)
    80001c1a:	e04a                	sd	s2,0(sp)
    80001c1c:	1000                	addi	s0,sp,32
    80001c1e:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001c20:	fffff097          	auipc	ra,0xfffff
    80001c24:	6fe080e7          	jalr	1790(ra) # 8000131e <uvmcreate>
    80001c28:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001c2a:	c121                	beqz	a0,80001c6a <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001c2c:	4729                	li	a4,10
    80001c2e:	00005697          	auipc	a3,0x5
    80001c32:	3d268693          	addi	a3,a3,978 # 80007000 <_trampoline>
    80001c36:	6605                	lui	a2,0x1
    80001c38:	040005b7          	lui	a1,0x4000
    80001c3c:	15fd                	addi	a1,a1,-1
    80001c3e:	05b2                	slli	a1,a1,0xc
    80001c40:	fffff097          	auipc	ra,0xfffff
    80001c44:	454080e7          	jalr	1108(ra) # 80001094 <mappages>
    80001c48:	02054863          	bltz	a0,80001c78 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001c4c:	4719                	li	a4,6
    80001c4e:	05893683          	ld	a3,88(s2)
    80001c52:	6605                	lui	a2,0x1
    80001c54:	020005b7          	lui	a1,0x2000
    80001c58:	15fd                	addi	a1,a1,-1
    80001c5a:	05b6                	slli	a1,a1,0xd
    80001c5c:	8526                	mv	a0,s1
    80001c5e:	fffff097          	auipc	ra,0xfffff
    80001c62:	436080e7          	jalr	1078(ra) # 80001094 <mappages>
    80001c66:	02054163          	bltz	a0,80001c88 <proc_pagetable+0x76>
}
    80001c6a:	8526                	mv	a0,s1
    80001c6c:	60e2                	ld	ra,24(sp)
    80001c6e:	6442                	ld	s0,16(sp)
    80001c70:	64a2                	ld	s1,8(sp)
    80001c72:	6902                	ld	s2,0(sp)
    80001c74:	6105                	addi	sp,sp,32
    80001c76:	8082                	ret
    uvmfree(pagetable, 0);
    80001c78:	4581                	li	a1,0
    80001c7a:	8526                	mv	a0,s1
    80001c7c:	00000097          	auipc	ra,0x0
    80001c80:	8a0080e7          	jalr	-1888(ra) # 8000151c <uvmfree>
    return 0;
    80001c84:	4481                	li	s1,0
    80001c86:	b7d5                	j	80001c6a <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c88:	4681                	li	a3,0
    80001c8a:	4605                	li	a2,1
    80001c8c:	040005b7          	lui	a1,0x4000
    80001c90:	15fd                	addi	a1,a1,-1
    80001c92:	05b2                	slli	a1,a1,0xc
    80001c94:	8526                	mv	a0,s1
    80001c96:	fffff097          	auipc	ra,0xfffff
    80001c9a:	5c4080e7          	jalr	1476(ra) # 8000125a <uvmunmap>
    uvmfree(pagetable, 0);
    80001c9e:	4581                	li	a1,0
    80001ca0:	8526                	mv	a0,s1
    80001ca2:	00000097          	auipc	ra,0x0
    80001ca6:	87a080e7          	jalr	-1926(ra) # 8000151c <uvmfree>
    return 0;
    80001caa:	4481                	li	s1,0
    80001cac:	bf7d                	j	80001c6a <proc_pagetable+0x58>

0000000080001cae <proc_freepagetable>:
{
    80001cae:	1101                	addi	sp,sp,-32
    80001cb0:	ec06                	sd	ra,24(sp)
    80001cb2:	e822                	sd	s0,16(sp)
    80001cb4:	e426                	sd	s1,8(sp)
    80001cb6:	e04a                	sd	s2,0(sp)
    80001cb8:	1000                	addi	s0,sp,32
    80001cba:	84aa                	mv	s1,a0
    80001cbc:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001cbe:	4681                	li	a3,0
    80001cc0:	4605                	li	a2,1
    80001cc2:	040005b7          	lui	a1,0x4000
    80001cc6:	15fd                	addi	a1,a1,-1
    80001cc8:	05b2                	slli	a1,a1,0xc
    80001cca:	fffff097          	auipc	ra,0xfffff
    80001cce:	590080e7          	jalr	1424(ra) # 8000125a <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001cd2:	4681                	li	a3,0
    80001cd4:	4605                	li	a2,1
    80001cd6:	020005b7          	lui	a1,0x2000
    80001cda:	15fd                	addi	a1,a1,-1
    80001cdc:	05b6                	slli	a1,a1,0xd
    80001cde:	8526                	mv	a0,s1
    80001ce0:	fffff097          	auipc	ra,0xfffff
    80001ce4:	57a080e7          	jalr	1402(ra) # 8000125a <uvmunmap>
  uvmfree(pagetable, sz);
    80001ce8:	85ca                	mv	a1,s2
    80001cea:	8526                	mv	a0,s1
    80001cec:	00000097          	auipc	ra,0x0
    80001cf0:	830080e7          	jalr	-2000(ra) # 8000151c <uvmfree>
}
    80001cf4:	60e2                	ld	ra,24(sp)
    80001cf6:	6442                	ld	s0,16(sp)
    80001cf8:	64a2                	ld	s1,8(sp)
    80001cfa:	6902                	ld	s2,0(sp)
    80001cfc:	6105                	addi	sp,sp,32
    80001cfe:	8082                	ret

0000000080001d00 <freeproc>:
{
    80001d00:	1101                	addi	sp,sp,-32
    80001d02:	ec06                	sd	ra,24(sp)
    80001d04:	e822                	sd	s0,16(sp)
    80001d06:	e426                	sd	s1,8(sp)
    80001d08:	1000                	addi	s0,sp,32
    80001d0a:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001d0c:	6d28                	ld	a0,88(a0)
    80001d0e:	c509                	beqz	a0,80001d18 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001d10:	fffff097          	auipc	ra,0xfffff
    80001d14:	cd2080e7          	jalr	-814(ra) # 800009e2 <kfree>
  p->trapframe = 0;
    80001d18:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001d1c:	68a8                	ld	a0,80(s1)
    80001d1e:	c511                	beqz	a0,80001d2a <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001d20:	64ac                	ld	a1,72(s1)
    80001d22:	00000097          	auipc	ra,0x0
    80001d26:	f8c080e7          	jalr	-116(ra) # 80001cae <proc_freepagetable>
  p->pagetable = 0;
    80001d2a:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001d2e:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001d32:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001d36:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001d3a:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001d3e:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001d42:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001d46:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001d4a:	0004ac23          	sw	zero,24(s1)
}
    80001d4e:	60e2                	ld	ra,24(sp)
    80001d50:	6442                	ld	s0,16(sp)
    80001d52:	64a2                	ld	s1,8(sp)
    80001d54:	6105                	addi	sp,sp,32
    80001d56:	8082                	ret

0000000080001d58 <allocproc>:
{
    80001d58:	1101                	addi	sp,sp,-32
    80001d5a:	ec06                	sd	ra,24(sp)
    80001d5c:	e822                	sd	s0,16(sp)
    80001d5e:	e426                	sd	s1,8(sp)
    80001d60:	e04a                	sd	s2,0(sp)
    80001d62:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d64:	00010497          	auipc	s1,0x10
    80001d68:	a7c48493          	addi	s1,s1,-1412 # 800117e0 <proc>
    80001d6c:	00016917          	auipc	s2,0x16
    80001d70:	87490913          	addi	s2,s2,-1932 # 800175e0 <tickslock>
    acquire(&p->lock);
    80001d74:	8526                	mv	a0,s1
    80001d76:	fffff097          	auipc	ra,0xfffff
    80001d7a:	e5a080e7          	jalr	-422(ra) # 80000bd0 <acquire>
    if(p->state == UNUSED) {
    80001d7e:	4c9c                	lw	a5,24(s1)
    80001d80:	cf81                	beqz	a5,80001d98 <allocproc+0x40>
      release(&p->lock);
    80001d82:	8526                	mv	a0,s1
    80001d84:	fffff097          	auipc	ra,0xfffff
    80001d88:	f00080e7          	jalr	-256(ra) # 80000c84 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d8c:	17848493          	addi	s1,s1,376
    80001d90:	ff2492e3          	bne	s1,s2,80001d74 <allocproc+0x1c>
  return 0;
    80001d94:	4481                	li	s1,0
    80001d96:	a8a1                	j	80001dee <allocproc+0x96>
  p->pid = allocpid();
    80001d98:	00000097          	auipc	ra,0x0
    80001d9c:	e34080e7          	jalr	-460(ra) # 80001bcc <allocpid>
    80001da0:	d888                	sw	a0,48(s1)
  p->tickets = 10; //default value
    80001da2:	47a9                	li	a5,10
    80001da4:	16f4a423          	sw	a5,360(s1)
  p->state = USED;
    80001da8:	4785                	li	a5,1
    80001daa:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001dac:	fffff097          	auipc	ra,0xfffff
    80001db0:	d34080e7          	jalr	-716(ra) # 80000ae0 <kalloc>
    80001db4:	892a                	mv	s2,a0
    80001db6:	eca8                	sd	a0,88(s1)
    80001db8:	c131                	beqz	a0,80001dfc <allocproc+0xa4>
  p->pagetable = proc_pagetable(p);
    80001dba:	8526                	mv	a0,s1
    80001dbc:	00000097          	auipc	ra,0x0
    80001dc0:	e56080e7          	jalr	-426(ra) # 80001c12 <proc_pagetable>
    80001dc4:	892a                	mv	s2,a0
    80001dc6:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001dc8:	c531                	beqz	a0,80001e14 <allocproc+0xbc>
  memset(&p->context, 0, sizeof(p->context));
    80001dca:	07000613          	li	a2,112
    80001dce:	4581                	li	a1,0
    80001dd0:	06048513          	addi	a0,s1,96
    80001dd4:	fffff097          	auipc	ra,0xfffff
    80001dd8:	ef8080e7          	jalr	-264(ra) # 80000ccc <memset>
  p->context.ra = (uint64)forkret;
    80001ddc:	00000797          	auipc	a5,0x0
    80001de0:	daa78793          	addi	a5,a5,-598 # 80001b86 <forkret>
    80001de4:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001de6:	60bc                	ld	a5,64(s1)
    80001de8:	6705                	lui	a4,0x1
    80001dea:	97ba                	add	a5,a5,a4
    80001dec:	f4bc                	sd	a5,104(s1)
}
    80001dee:	8526                	mv	a0,s1
    80001df0:	60e2                	ld	ra,24(sp)
    80001df2:	6442                	ld	s0,16(sp)
    80001df4:	64a2                	ld	s1,8(sp)
    80001df6:	6902                	ld	s2,0(sp)
    80001df8:	6105                	addi	sp,sp,32
    80001dfa:	8082                	ret
    freeproc(p);
    80001dfc:	8526                	mv	a0,s1
    80001dfe:	00000097          	auipc	ra,0x0
    80001e02:	f02080e7          	jalr	-254(ra) # 80001d00 <freeproc>
    release(&p->lock);
    80001e06:	8526                	mv	a0,s1
    80001e08:	fffff097          	auipc	ra,0xfffff
    80001e0c:	e7c080e7          	jalr	-388(ra) # 80000c84 <release>
    return 0;
    80001e10:	84ca                	mv	s1,s2
    80001e12:	bff1                	j	80001dee <allocproc+0x96>
    freeproc(p);
    80001e14:	8526                	mv	a0,s1
    80001e16:	00000097          	auipc	ra,0x0
    80001e1a:	eea080e7          	jalr	-278(ra) # 80001d00 <freeproc>
    release(&p->lock);
    80001e1e:	8526                	mv	a0,s1
    80001e20:	fffff097          	auipc	ra,0xfffff
    80001e24:	e64080e7          	jalr	-412(ra) # 80000c84 <release>
    return 0;
    80001e28:	84ca                	mv	s1,s2
    80001e2a:	b7d1                	j	80001dee <allocproc+0x96>

0000000080001e2c <userinit>:
{
    80001e2c:	1101                	addi	sp,sp,-32
    80001e2e:	ec06                	sd	ra,24(sp)
    80001e30:	e822                	sd	s0,16(sp)
    80001e32:	e426                	sd	s1,8(sp)
    80001e34:	1000                	addi	s0,sp,32
  p = allocproc();
    80001e36:	00000097          	auipc	ra,0x0
    80001e3a:	f22080e7          	jalr	-222(ra) # 80001d58 <allocproc>
    80001e3e:	84aa                	mv	s1,a0
  initproc = p;
    80001e40:	00007797          	auipc	a5,0x7
    80001e44:	1ea7bc23          	sd	a0,504(a5) # 80009038 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001e48:	03400613          	li	a2,52
    80001e4c:	00007597          	auipc	a1,0x7
    80001e50:	a8458593          	addi	a1,a1,-1404 # 800088d0 <initcode>
    80001e54:	6928                	ld	a0,80(a0)
    80001e56:	fffff097          	auipc	ra,0xfffff
    80001e5a:	4f6080e7          	jalr	1270(ra) # 8000134c <uvminit>
  p->sz = PGSIZE;
    80001e5e:	6785                	lui	a5,0x1
    80001e60:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001e62:	6cb8                	ld	a4,88(s1)
    80001e64:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001e68:	6cb8                	ld	a4,88(s1)
    80001e6a:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001e6c:	4641                	li	a2,16
    80001e6e:	00006597          	auipc	a1,0x6
    80001e72:	42258593          	addi	a1,a1,1058 # 80008290 <digits+0x250>
    80001e76:	15848513          	addi	a0,s1,344
    80001e7a:	fffff097          	auipc	ra,0xfffff
    80001e7e:	f9c080e7          	jalr	-100(ra) # 80000e16 <safestrcpy>
  p->cwd = namei("/");
    80001e82:	00006517          	auipc	a0,0x6
    80001e86:	41e50513          	addi	a0,a0,1054 # 800082a0 <digits+0x260>
    80001e8a:	00002097          	auipc	ra,0x2
    80001e8e:	16a080e7          	jalr	362(ra) # 80003ff4 <namei>
    80001e92:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001e96:	478d                	li	a5,3
    80001e98:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001e9a:	8526                	mv	a0,s1
    80001e9c:	fffff097          	auipc	ra,0xfffff
    80001ea0:	de8080e7          	jalr	-536(ra) # 80000c84 <release>
}
    80001ea4:	60e2                	ld	ra,24(sp)
    80001ea6:	6442                	ld	s0,16(sp)
    80001ea8:	64a2                	ld	s1,8(sp)
    80001eaa:	6105                	addi	sp,sp,32
    80001eac:	8082                	ret

0000000080001eae <growproc>:
{
    80001eae:	1101                	addi	sp,sp,-32
    80001eb0:	ec06                	sd	ra,24(sp)
    80001eb2:	e822                	sd	s0,16(sp)
    80001eb4:	e426                	sd	s1,8(sp)
    80001eb6:	e04a                	sd	s2,0(sp)
    80001eb8:	1000                	addi	s0,sp,32
    80001eba:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001ebc:	00000097          	auipc	ra,0x0
    80001ec0:	bb6080e7          	jalr	-1098(ra) # 80001a72 <myproc>
    80001ec4:	892a                	mv	s2,a0
  sz = p->sz;
    80001ec6:	652c                	ld	a1,72(a0)
    80001ec8:	0005879b          	sext.w	a5,a1
  if(n > 0){
    80001ecc:	00904f63          	bgtz	s1,80001eea <growproc+0x3c>
  } else if(n < 0){
    80001ed0:	0204cd63          	bltz	s1,80001f0a <growproc+0x5c>
  p->sz = sz;
    80001ed4:	1782                	slli	a5,a5,0x20
    80001ed6:	9381                	srli	a5,a5,0x20
    80001ed8:	04f93423          	sd	a5,72(s2)
  return 0;
    80001edc:	4501                	li	a0,0
}
    80001ede:	60e2                	ld	ra,24(sp)
    80001ee0:	6442                	ld	s0,16(sp)
    80001ee2:	64a2                	ld	s1,8(sp)
    80001ee4:	6902                	ld	s2,0(sp)
    80001ee6:	6105                	addi	sp,sp,32
    80001ee8:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001eea:	00f4863b          	addw	a2,s1,a5
    80001eee:	1602                	slli	a2,a2,0x20
    80001ef0:	9201                	srli	a2,a2,0x20
    80001ef2:	1582                	slli	a1,a1,0x20
    80001ef4:	9181                	srli	a1,a1,0x20
    80001ef6:	6928                	ld	a0,80(a0)
    80001ef8:	fffff097          	auipc	ra,0xfffff
    80001efc:	50e080e7          	jalr	1294(ra) # 80001406 <uvmalloc>
    80001f00:	0005079b          	sext.w	a5,a0
    80001f04:	fbe1                	bnez	a5,80001ed4 <growproc+0x26>
      return -1;
    80001f06:	557d                	li	a0,-1
    80001f08:	bfd9                	j	80001ede <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001f0a:	00f4863b          	addw	a2,s1,a5
    80001f0e:	1602                	slli	a2,a2,0x20
    80001f10:	9201                	srli	a2,a2,0x20
    80001f12:	1582                	slli	a1,a1,0x20
    80001f14:	9181                	srli	a1,a1,0x20
    80001f16:	6928                	ld	a0,80(a0)
    80001f18:	fffff097          	auipc	ra,0xfffff
    80001f1c:	4a6080e7          	jalr	1190(ra) # 800013be <uvmdealloc>
    80001f20:	0005079b          	sext.w	a5,a0
    80001f24:	bf45                	j	80001ed4 <growproc+0x26>

0000000080001f26 <fork>:
{
    80001f26:	7139                	addi	sp,sp,-64
    80001f28:	fc06                	sd	ra,56(sp)
    80001f2a:	f822                	sd	s0,48(sp)
    80001f2c:	f426                	sd	s1,40(sp)
    80001f2e:	f04a                	sd	s2,32(sp)
    80001f30:	ec4e                	sd	s3,24(sp)
    80001f32:	e852                	sd	s4,16(sp)
    80001f34:	e456                	sd	s5,8(sp)
    80001f36:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001f38:	00000097          	auipc	ra,0x0
    80001f3c:	b3a080e7          	jalr	-1222(ra) # 80001a72 <myproc>
    80001f40:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001f42:	00000097          	auipc	ra,0x0
    80001f46:	e16080e7          	jalr	-490(ra) # 80001d58 <allocproc>
    80001f4a:	10050c63          	beqz	a0,80002062 <fork+0x13c>
    80001f4e:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001f50:	048ab603          	ld	a2,72(s5)
    80001f54:	692c                	ld	a1,80(a0)
    80001f56:	050ab503          	ld	a0,80(s5)
    80001f5a:	fffff097          	auipc	ra,0xfffff
    80001f5e:	5fc080e7          	jalr	1532(ra) # 80001556 <uvmcopy>
    80001f62:	04054863          	bltz	a0,80001fb2 <fork+0x8c>
  np->sz = p->sz;
    80001f66:	048ab783          	ld	a5,72(s5)
    80001f6a:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001f6e:	058ab683          	ld	a3,88(s5)
    80001f72:	87b6                	mv	a5,a3
    80001f74:	058a3703          	ld	a4,88(s4)
    80001f78:	12068693          	addi	a3,a3,288
    80001f7c:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001f80:	6788                	ld	a0,8(a5)
    80001f82:	6b8c                	ld	a1,16(a5)
    80001f84:	6f90                	ld	a2,24(a5)
    80001f86:	01073023          	sd	a6,0(a4)
    80001f8a:	e708                	sd	a0,8(a4)
    80001f8c:	eb0c                	sd	a1,16(a4)
    80001f8e:	ef10                	sd	a2,24(a4)
    80001f90:	02078793          	addi	a5,a5,32
    80001f94:	02070713          	addi	a4,a4,32
    80001f98:	fed792e3          	bne	a5,a3,80001f7c <fork+0x56>
  np->trapframe->a0 = 0;
    80001f9c:	058a3783          	ld	a5,88(s4)
    80001fa0:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001fa4:	0d0a8493          	addi	s1,s5,208
    80001fa8:	0d0a0913          	addi	s2,s4,208
    80001fac:	150a8993          	addi	s3,s5,336
    80001fb0:	a00d                	j	80001fd2 <fork+0xac>
    freeproc(np);
    80001fb2:	8552                	mv	a0,s4
    80001fb4:	00000097          	auipc	ra,0x0
    80001fb8:	d4c080e7          	jalr	-692(ra) # 80001d00 <freeproc>
    release(&np->lock);
    80001fbc:	8552                	mv	a0,s4
    80001fbe:	fffff097          	auipc	ra,0xfffff
    80001fc2:	cc6080e7          	jalr	-826(ra) # 80000c84 <release>
    return -1;
    80001fc6:	597d                	li	s2,-1
    80001fc8:	a059                	j	8000204e <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001fca:	04a1                	addi	s1,s1,8
    80001fcc:	0921                	addi	s2,s2,8
    80001fce:	01348b63          	beq	s1,s3,80001fe4 <fork+0xbe>
    if(p->ofile[i])
    80001fd2:	6088                	ld	a0,0(s1)
    80001fd4:	d97d                	beqz	a0,80001fca <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001fd6:	00002097          	auipc	ra,0x2
    80001fda:	6b4080e7          	jalr	1716(ra) # 8000468a <filedup>
    80001fde:	00a93023          	sd	a0,0(s2)
    80001fe2:	b7e5                	j	80001fca <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001fe4:	150ab503          	ld	a0,336(s5)
    80001fe8:	00002097          	auipc	ra,0x2
    80001fec:	812080e7          	jalr	-2030(ra) # 800037fa <idup>
    80001ff0:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001ff4:	4641                	li	a2,16
    80001ff6:	158a8593          	addi	a1,s5,344
    80001ffa:	158a0513          	addi	a0,s4,344
    80001ffe:	fffff097          	auipc	ra,0xfffff
    80002002:	e18080e7          	jalr	-488(ra) # 80000e16 <safestrcpy>
  pid = np->pid;
    80002006:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    8000200a:	8552                	mv	a0,s4
    8000200c:	fffff097          	auipc	ra,0xfffff
    80002010:	c78080e7          	jalr	-904(ra) # 80000c84 <release>
  acquire(&wait_lock);
    80002014:	0000f497          	auipc	s1,0xf
    80002018:	3b448493          	addi	s1,s1,948 # 800113c8 <wait_lock>
    8000201c:	8526                	mv	a0,s1
    8000201e:	fffff097          	auipc	ra,0xfffff
    80002022:	bb2080e7          	jalr	-1102(ra) # 80000bd0 <acquire>
  np->parent = p;
    80002026:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    8000202a:	8526                	mv	a0,s1
    8000202c:	fffff097          	auipc	ra,0xfffff
    80002030:	c58080e7          	jalr	-936(ra) # 80000c84 <release>
  acquire(&np->lock);
    80002034:	8552                	mv	a0,s4
    80002036:	fffff097          	auipc	ra,0xfffff
    8000203a:	b9a080e7          	jalr	-1126(ra) # 80000bd0 <acquire>
  np->state = RUNNABLE;
    8000203e:	478d                	li	a5,3
    80002040:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80002044:	8552                	mv	a0,s4
    80002046:	fffff097          	auipc	ra,0xfffff
    8000204a:	c3e080e7          	jalr	-962(ra) # 80000c84 <release>
}
    8000204e:	854a                	mv	a0,s2
    80002050:	70e2                	ld	ra,56(sp)
    80002052:	7442                	ld	s0,48(sp)
    80002054:	74a2                	ld	s1,40(sp)
    80002056:	7902                	ld	s2,32(sp)
    80002058:	69e2                	ld	s3,24(sp)
    8000205a:	6a42                	ld	s4,16(sp)
    8000205c:	6aa2                	ld	s5,8(sp)
    8000205e:	6121                	addi	sp,sp,64
    80002060:	8082                	ret
    return -1;
    80002062:	597d                	li	s2,-1
    80002064:	b7ed                	j	8000204e <fork+0x128>

0000000080002066 <scheduler>:
{
    80002066:	715d                	addi	sp,sp,-80
    80002068:	e486                	sd	ra,72(sp)
    8000206a:	e0a2                	sd	s0,64(sp)
    8000206c:	fc26                	sd	s1,56(sp)
    8000206e:	f84a                	sd	s2,48(sp)
    80002070:	f44e                	sd	s3,40(sp)
    80002072:	f052                	sd	s4,32(sp)
    80002074:	ec56                	sd	s5,24(sp)
    80002076:	e85a                	sd	s6,16(sp)
    80002078:	e45e                	sd	s7,8(sp)
    8000207a:	0880                	addi	s0,sp,80
    8000207c:	8792                	mv	a5,tp
  int id = r_tp();
    8000207e:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002080:	00779b13          	slli	s6,a5,0x7
    80002084:	0000f717          	auipc	a4,0xf
    80002088:	22c70713          	addi	a4,a4,556 # 800112b0 <TCount>
    8000208c:	975a                	add	a4,a4,s6
    8000208e:	12073823          	sd	zero,304(a4)
			  swtch(&c->context,&curr_proc->context);                 //context switching
    80002092:	0000f717          	auipc	a4,0xf
    80002096:	35670713          	addi	a4,a4,854 # 800113e8 <cpus+0x8>
    8000209a:	9b3a                	add	s6,s6,a4
	  int minPass = -1;
    8000209c:	5afd                	li	s5,-1
		  if(p->state == RUNNABLE &&(p->pass <= minPass || minPass<0)) //loop to get the minimum pass number
    8000209e:	490d                	li	s2,3
	  for(p=proc;p<&proc[NPROC];p++){
    800020a0:	00015997          	auipc	s3,0x15
    800020a4:	54098993          	addi	s3,s3,1344 # 800175e0 <tickslock>
			  c->proc=curr_proc;
    800020a8:	0000fb97          	auipc	s7,0xf
    800020ac:	208b8b93          	addi	s7,s7,520 # 800112b0 <TCount>
    800020b0:	079e                	slli	a5,a5,0x7
    800020b2:	00fb8a33          	add	s4,s7,a5
    800020b6:	a069                	j	80002140 <scheduler+0xda>
			  minPass = p->pass;
    800020b8:	86ba                	mv	a3,a4
	  for(p=proc;p<&proc[NPROC];p++){
    800020ba:	17878793          	addi	a5,a5,376
    800020be:	01378d63          	beq	a5,s3,800020d8 <scheduler+0x72>
		  if(p->state == RUNNABLE &&(p->pass <= minPass || minPass<0)) //loop to get the minimum pass number
    800020c2:	4f98                	lw	a4,24(a5)
    800020c4:	ff271be3          	bne	a4,s2,800020ba <scheduler+0x54>
    800020c8:	16c7a703          	lw	a4,364(a5)
    800020cc:	fee6d6e3          	bge	a3,a4,800020b8 <scheduler+0x52>
    800020d0:	fe06d5e3          	bgez	a3,800020ba <scheduler+0x54>
			  minPass = p->pass;
    800020d4:	86ba                	mv	a3,a4
    800020d6:	b7d5                	j	800020ba <scheduler+0x54>
	  for(p=proc; p<&proc[NPROC];p++){
    800020d8:	0000f497          	auipc	s1,0xf
    800020dc:	70848493          	addi	s1,s1,1800 # 800117e0 <proc>
    800020e0:	a029                	j	800020ea <scheduler+0x84>
    800020e2:	17848493          	addi	s1,s1,376
    800020e6:	05348d63          	beq	s1,s3,80002140 <scheduler+0xda>
		  if(p->state!=RUNNABLE){
    800020ea:	4c9c                	lw	a5,24(s1)
    800020ec:	ff279be3          	bne	a5,s2,800020e2 <scheduler+0x7c>
		  if(p->pass == minPass){
    800020f0:	16c4a783          	lw	a5,364(s1)
    800020f4:	fed797e3          	bne	a5,a3,800020e2 <scheduler+0x7c>
			  acquire(&p->lock);
    800020f8:	8526                	mv	a0,s1
    800020fa:	fffff097          	auipc	ra,0xfffff
    800020fe:	ad6080e7          	jalr	-1322(ra) # 80000bd0 <acquire>
			  c->proc=curr_proc;
    80002102:	129a3823          	sd	s1,304(s4)
			  curr_proc->pass+=curr_proc->stride;                  //updating pass
    80002106:	16c4a703          	lw	a4,364(s1)
    8000210a:	1704a783          	lw	a5,368(s1)
    8000210e:	9fb9                	addw	a5,a5,a4
    80002110:	16f4a623          	sw	a5,364(s1)
			  curr_proc->state=RUNNING;                               //updating state to Running state
    80002114:	4791                	li	a5,4
    80002116:	cc9c                	sw	a5,24(s1)
			  TCount[curr_proc->pid]+=1;                          //adding ticket count
    80002118:	589c                	lw	a5,48(s1)
    8000211a:	078a                	slli	a5,a5,0x2
    8000211c:	97de                	add	a5,a5,s7
    8000211e:	4398                	lw	a4,0(a5)
    80002120:	2705                	addiw	a4,a4,1
    80002122:	c398                	sw	a4,0(a5)
			  swtch(&c->context,&curr_proc->context);                 //context switching
    80002124:	06048593          	addi	a1,s1,96
    80002128:	855a                	mv	a0,s6
    8000212a:	00000097          	auipc	ra,0x0
    8000212e:	640080e7          	jalr	1600(ra) # 8000276a <swtch>
			  c->proc=0;
    80002132:	120a3823          	sd	zero,304(s4)
			  release(&p->lock);
    80002136:	8526                	mv	a0,s1
    80002138:	fffff097          	auipc	ra,0xfffff
    8000213c:	b4c080e7          	jalr	-1204(ra) # 80000c84 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002140:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002144:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002148:	10079073          	csrw	sstatus,a5
	  int minPass = -1;
    8000214c:	86d6                	mv	a3,s5
	  for(p=proc;p<&proc[NPROC];p++){
    8000214e:	0000f797          	auipc	a5,0xf
    80002152:	69278793          	addi	a5,a5,1682 # 800117e0 <proc>
    80002156:	b7b5                	j	800020c2 <scheduler+0x5c>

0000000080002158 <sched>:
{
    80002158:	7179                	addi	sp,sp,-48
    8000215a:	f406                	sd	ra,40(sp)
    8000215c:	f022                	sd	s0,32(sp)
    8000215e:	ec26                	sd	s1,24(sp)
    80002160:	e84a                	sd	s2,16(sp)
    80002162:	e44e                	sd	s3,8(sp)
    80002164:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002166:	00000097          	auipc	ra,0x0
    8000216a:	90c080e7          	jalr	-1780(ra) # 80001a72 <myproc>
    8000216e:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002170:	fffff097          	auipc	ra,0xfffff
    80002174:	9e6080e7          	jalr	-1562(ra) # 80000b56 <holding>
    80002178:	c93d                	beqz	a0,800021ee <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000217a:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000217c:	2781                	sext.w	a5,a5
    8000217e:	079e                	slli	a5,a5,0x7
    80002180:	0000f717          	auipc	a4,0xf
    80002184:	13070713          	addi	a4,a4,304 # 800112b0 <TCount>
    80002188:	97ba                	add	a5,a5,a4
    8000218a:	1a87a703          	lw	a4,424(a5)
    8000218e:	4785                	li	a5,1
    80002190:	06f71763          	bne	a4,a5,800021fe <sched+0xa6>
  if(p->state == RUNNING)
    80002194:	4c98                	lw	a4,24(s1)
    80002196:	4791                	li	a5,4
    80002198:	06f70b63          	beq	a4,a5,8000220e <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000219c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800021a0:	8b89                	andi	a5,a5,2
  if(intr_get())
    800021a2:	efb5                	bnez	a5,8000221e <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800021a4:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800021a6:	0000f917          	auipc	s2,0xf
    800021aa:	10a90913          	addi	s2,s2,266 # 800112b0 <TCount>
    800021ae:	2781                	sext.w	a5,a5
    800021b0:	079e                	slli	a5,a5,0x7
    800021b2:	97ca                	add	a5,a5,s2
    800021b4:	1ac7a983          	lw	s3,428(a5)
    800021b8:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800021ba:	2781                	sext.w	a5,a5
    800021bc:	079e                	slli	a5,a5,0x7
    800021be:	0000f597          	auipc	a1,0xf
    800021c2:	22a58593          	addi	a1,a1,554 # 800113e8 <cpus+0x8>
    800021c6:	95be                	add	a1,a1,a5
    800021c8:	06048513          	addi	a0,s1,96
    800021cc:	00000097          	auipc	ra,0x0
    800021d0:	59e080e7          	jalr	1438(ra) # 8000276a <swtch>
    800021d4:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800021d6:	2781                	sext.w	a5,a5
    800021d8:	079e                	slli	a5,a5,0x7
    800021da:	993e                	add	s2,s2,a5
    800021dc:	1b392623          	sw	s3,428(s2)
}
    800021e0:	70a2                	ld	ra,40(sp)
    800021e2:	7402                	ld	s0,32(sp)
    800021e4:	64e2                	ld	s1,24(sp)
    800021e6:	6942                	ld	s2,16(sp)
    800021e8:	69a2                	ld	s3,8(sp)
    800021ea:	6145                	addi	sp,sp,48
    800021ec:	8082                	ret
    panic("sched p->lock");
    800021ee:	00006517          	auipc	a0,0x6
    800021f2:	0ba50513          	addi	a0,a0,186 # 800082a8 <digits+0x268>
    800021f6:	ffffe097          	auipc	ra,0xffffe
    800021fa:	344080e7          	jalr	836(ra) # 8000053a <panic>
    panic("sched locks");
    800021fe:	00006517          	auipc	a0,0x6
    80002202:	0ba50513          	addi	a0,a0,186 # 800082b8 <digits+0x278>
    80002206:	ffffe097          	auipc	ra,0xffffe
    8000220a:	334080e7          	jalr	820(ra) # 8000053a <panic>
    panic("sched running");
    8000220e:	00006517          	auipc	a0,0x6
    80002212:	0ba50513          	addi	a0,a0,186 # 800082c8 <digits+0x288>
    80002216:	ffffe097          	auipc	ra,0xffffe
    8000221a:	324080e7          	jalr	804(ra) # 8000053a <panic>
    panic("sched interruptible");
    8000221e:	00006517          	auipc	a0,0x6
    80002222:	0ba50513          	addi	a0,a0,186 # 800082d8 <digits+0x298>
    80002226:	ffffe097          	auipc	ra,0xffffe
    8000222a:	314080e7          	jalr	788(ra) # 8000053a <panic>

000000008000222e <yield>:
{
    8000222e:	1101                	addi	sp,sp,-32
    80002230:	ec06                	sd	ra,24(sp)
    80002232:	e822                	sd	s0,16(sp)
    80002234:	e426                	sd	s1,8(sp)
    80002236:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002238:	00000097          	auipc	ra,0x0
    8000223c:	83a080e7          	jalr	-1990(ra) # 80001a72 <myproc>
    80002240:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002242:	fffff097          	auipc	ra,0xfffff
    80002246:	98e080e7          	jalr	-1650(ra) # 80000bd0 <acquire>
  p->state = RUNNABLE;
    8000224a:	478d                	li	a5,3
    8000224c:	cc9c                	sw	a5,24(s1)
  sched();
    8000224e:	00000097          	auipc	ra,0x0
    80002252:	f0a080e7          	jalr	-246(ra) # 80002158 <sched>
  release(&p->lock);
    80002256:	8526                	mv	a0,s1
    80002258:	fffff097          	auipc	ra,0xfffff
    8000225c:	a2c080e7          	jalr	-1492(ra) # 80000c84 <release>
}
    80002260:	60e2                	ld	ra,24(sp)
    80002262:	6442                	ld	s0,16(sp)
    80002264:	64a2                	ld	s1,8(sp)
    80002266:	6105                	addi	sp,sp,32
    80002268:	8082                	ret

000000008000226a <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000226a:	7179                	addi	sp,sp,-48
    8000226c:	f406                	sd	ra,40(sp)
    8000226e:	f022                	sd	s0,32(sp)
    80002270:	ec26                	sd	s1,24(sp)
    80002272:	e84a                	sd	s2,16(sp)
    80002274:	e44e                	sd	s3,8(sp)
    80002276:	1800                	addi	s0,sp,48
    80002278:	89aa                	mv	s3,a0
    8000227a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000227c:	fffff097          	auipc	ra,0xfffff
    80002280:	7f6080e7          	jalr	2038(ra) # 80001a72 <myproc>
    80002284:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002286:	fffff097          	auipc	ra,0xfffff
    8000228a:	94a080e7          	jalr	-1718(ra) # 80000bd0 <acquire>
  release(lk);
    8000228e:	854a                	mv	a0,s2
    80002290:	fffff097          	auipc	ra,0xfffff
    80002294:	9f4080e7          	jalr	-1548(ra) # 80000c84 <release>

  // Go to sleep.
  p->chan = chan;
    80002298:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000229c:	4789                	li	a5,2
    8000229e:	cc9c                	sw	a5,24(s1)

  sched();
    800022a0:	00000097          	auipc	ra,0x0
    800022a4:	eb8080e7          	jalr	-328(ra) # 80002158 <sched>

  // Tidy up.
  p->chan = 0;
    800022a8:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800022ac:	8526                	mv	a0,s1
    800022ae:	fffff097          	auipc	ra,0xfffff
    800022b2:	9d6080e7          	jalr	-1578(ra) # 80000c84 <release>
  acquire(lk);
    800022b6:	854a                	mv	a0,s2
    800022b8:	fffff097          	auipc	ra,0xfffff
    800022bc:	918080e7          	jalr	-1768(ra) # 80000bd0 <acquire>
}
    800022c0:	70a2                	ld	ra,40(sp)
    800022c2:	7402                	ld	s0,32(sp)
    800022c4:	64e2                	ld	s1,24(sp)
    800022c6:	6942                	ld	s2,16(sp)
    800022c8:	69a2                	ld	s3,8(sp)
    800022ca:	6145                	addi	sp,sp,48
    800022cc:	8082                	ret

00000000800022ce <wait>:
{
    800022ce:	715d                	addi	sp,sp,-80
    800022d0:	e486                	sd	ra,72(sp)
    800022d2:	e0a2                	sd	s0,64(sp)
    800022d4:	fc26                	sd	s1,56(sp)
    800022d6:	f84a                	sd	s2,48(sp)
    800022d8:	f44e                	sd	s3,40(sp)
    800022da:	f052                	sd	s4,32(sp)
    800022dc:	ec56                	sd	s5,24(sp)
    800022de:	e85a                	sd	s6,16(sp)
    800022e0:	e45e                	sd	s7,8(sp)
    800022e2:	e062                	sd	s8,0(sp)
    800022e4:	0880                	addi	s0,sp,80
    800022e6:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800022e8:	fffff097          	auipc	ra,0xfffff
    800022ec:	78a080e7          	jalr	1930(ra) # 80001a72 <myproc>
    800022f0:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800022f2:	0000f517          	auipc	a0,0xf
    800022f6:	0d650513          	addi	a0,a0,214 # 800113c8 <wait_lock>
    800022fa:	fffff097          	auipc	ra,0xfffff
    800022fe:	8d6080e7          	jalr	-1834(ra) # 80000bd0 <acquire>
    havekids = 0;
    80002302:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002304:	4a15                	li	s4,5
        havekids = 1;
    80002306:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    80002308:	00015997          	auipc	s3,0x15
    8000230c:	2d898993          	addi	s3,s3,728 # 800175e0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002310:	0000fc17          	auipc	s8,0xf
    80002314:	0b8c0c13          	addi	s8,s8,184 # 800113c8 <wait_lock>
    havekids = 0;
    80002318:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000231a:	0000f497          	auipc	s1,0xf
    8000231e:	4c648493          	addi	s1,s1,1222 # 800117e0 <proc>
    80002322:	a0bd                	j	80002390 <wait+0xc2>
          pid = np->pid;
    80002324:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002328:	000b0e63          	beqz	s6,80002344 <wait+0x76>
    8000232c:	4691                	li	a3,4
    8000232e:	02c48613          	addi	a2,s1,44
    80002332:	85da                	mv	a1,s6
    80002334:	05093503          	ld	a0,80(s2)
    80002338:	fffff097          	auipc	ra,0xfffff
    8000233c:	322080e7          	jalr	802(ra) # 8000165a <copyout>
    80002340:	02054563          	bltz	a0,8000236a <wait+0x9c>
          freeproc(np);
    80002344:	8526                	mv	a0,s1
    80002346:	00000097          	auipc	ra,0x0
    8000234a:	9ba080e7          	jalr	-1606(ra) # 80001d00 <freeproc>
          release(&np->lock);
    8000234e:	8526                	mv	a0,s1
    80002350:	fffff097          	auipc	ra,0xfffff
    80002354:	934080e7          	jalr	-1740(ra) # 80000c84 <release>
          release(&wait_lock);
    80002358:	0000f517          	auipc	a0,0xf
    8000235c:	07050513          	addi	a0,a0,112 # 800113c8 <wait_lock>
    80002360:	fffff097          	auipc	ra,0xfffff
    80002364:	924080e7          	jalr	-1756(ra) # 80000c84 <release>
          return pid;
    80002368:	a09d                	j	800023ce <wait+0x100>
            release(&np->lock);
    8000236a:	8526                	mv	a0,s1
    8000236c:	fffff097          	auipc	ra,0xfffff
    80002370:	918080e7          	jalr	-1768(ra) # 80000c84 <release>
            release(&wait_lock);
    80002374:	0000f517          	auipc	a0,0xf
    80002378:	05450513          	addi	a0,a0,84 # 800113c8 <wait_lock>
    8000237c:	fffff097          	auipc	ra,0xfffff
    80002380:	908080e7          	jalr	-1784(ra) # 80000c84 <release>
            return -1;
    80002384:	59fd                	li	s3,-1
    80002386:	a0a1                	j	800023ce <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002388:	17848493          	addi	s1,s1,376
    8000238c:	03348463          	beq	s1,s3,800023b4 <wait+0xe6>
      if(np->parent == p){
    80002390:	7c9c                	ld	a5,56(s1)
    80002392:	ff279be3          	bne	a5,s2,80002388 <wait+0xba>
        acquire(&np->lock);
    80002396:	8526                	mv	a0,s1
    80002398:	fffff097          	auipc	ra,0xfffff
    8000239c:	838080e7          	jalr	-1992(ra) # 80000bd0 <acquire>
        if(np->state == ZOMBIE){
    800023a0:	4c9c                	lw	a5,24(s1)
    800023a2:	f94781e3          	beq	a5,s4,80002324 <wait+0x56>
        release(&np->lock);
    800023a6:	8526                	mv	a0,s1
    800023a8:	fffff097          	auipc	ra,0xfffff
    800023ac:	8dc080e7          	jalr	-1828(ra) # 80000c84 <release>
        havekids = 1;
    800023b0:	8756                	mv	a4,s5
    800023b2:	bfd9                	j	80002388 <wait+0xba>
    if(!havekids || p->killed){
    800023b4:	c701                	beqz	a4,800023bc <wait+0xee>
    800023b6:	02892783          	lw	a5,40(s2)
    800023ba:	c79d                	beqz	a5,800023e8 <wait+0x11a>
      release(&wait_lock);
    800023bc:	0000f517          	auipc	a0,0xf
    800023c0:	00c50513          	addi	a0,a0,12 # 800113c8 <wait_lock>
    800023c4:	fffff097          	auipc	ra,0xfffff
    800023c8:	8c0080e7          	jalr	-1856(ra) # 80000c84 <release>
      return -1;
    800023cc:	59fd                	li	s3,-1
}
    800023ce:	854e                	mv	a0,s3
    800023d0:	60a6                	ld	ra,72(sp)
    800023d2:	6406                	ld	s0,64(sp)
    800023d4:	74e2                	ld	s1,56(sp)
    800023d6:	7942                	ld	s2,48(sp)
    800023d8:	79a2                	ld	s3,40(sp)
    800023da:	7a02                	ld	s4,32(sp)
    800023dc:	6ae2                	ld	s5,24(sp)
    800023de:	6b42                	ld	s6,16(sp)
    800023e0:	6ba2                	ld	s7,8(sp)
    800023e2:	6c02                	ld	s8,0(sp)
    800023e4:	6161                	addi	sp,sp,80
    800023e6:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800023e8:	85e2                	mv	a1,s8
    800023ea:	854a                	mv	a0,s2
    800023ec:	00000097          	auipc	ra,0x0
    800023f0:	e7e080e7          	jalr	-386(ra) # 8000226a <sleep>
    havekids = 0;
    800023f4:	b715                	j	80002318 <wait+0x4a>

00000000800023f6 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800023f6:	7139                	addi	sp,sp,-64
    800023f8:	fc06                	sd	ra,56(sp)
    800023fa:	f822                	sd	s0,48(sp)
    800023fc:	f426                	sd	s1,40(sp)
    800023fe:	f04a                	sd	s2,32(sp)
    80002400:	ec4e                	sd	s3,24(sp)
    80002402:	e852                	sd	s4,16(sp)
    80002404:	e456                	sd	s5,8(sp)
    80002406:	0080                	addi	s0,sp,64
    80002408:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000240a:	0000f497          	auipc	s1,0xf
    8000240e:	3d648493          	addi	s1,s1,982 # 800117e0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002412:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002414:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002416:	00015917          	auipc	s2,0x15
    8000241a:	1ca90913          	addi	s2,s2,458 # 800175e0 <tickslock>
    8000241e:	a811                	j	80002432 <wakeup+0x3c>
      }
      release(&p->lock);
    80002420:	8526                	mv	a0,s1
    80002422:	fffff097          	auipc	ra,0xfffff
    80002426:	862080e7          	jalr	-1950(ra) # 80000c84 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000242a:	17848493          	addi	s1,s1,376
    8000242e:	03248663          	beq	s1,s2,8000245a <wakeup+0x64>
    if(p != myproc()){
    80002432:	fffff097          	auipc	ra,0xfffff
    80002436:	640080e7          	jalr	1600(ra) # 80001a72 <myproc>
    8000243a:	fea488e3          	beq	s1,a0,8000242a <wakeup+0x34>
      acquire(&p->lock);
    8000243e:	8526                	mv	a0,s1
    80002440:	ffffe097          	auipc	ra,0xffffe
    80002444:	790080e7          	jalr	1936(ra) # 80000bd0 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002448:	4c9c                	lw	a5,24(s1)
    8000244a:	fd379be3          	bne	a5,s3,80002420 <wakeup+0x2a>
    8000244e:	709c                	ld	a5,32(s1)
    80002450:	fd4798e3          	bne	a5,s4,80002420 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002454:	0154ac23          	sw	s5,24(s1)
    80002458:	b7e1                	j	80002420 <wakeup+0x2a>
    }
  }
}
    8000245a:	70e2                	ld	ra,56(sp)
    8000245c:	7442                	ld	s0,48(sp)
    8000245e:	74a2                	ld	s1,40(sp)
    80002460:	7902                	ld	s2,32(sp)
    80002462:	69e2                	ld	s3,24(sp)
    80002464:	6a42                	ld	s4,16(sp)
    80002466:	6aa2                	ld	s5,8(sp)
    80002468:	6121                	addi	sp,sp,64
    8000246a:	8082                	ret

000000008000246c <reparent>:
{
    8000246c:	7179                	addi	sp,sp,-48
    8000246e:	f406                	sd	ra,40(sp)
    80002470:	f022                	sd	s0,32(sp)
    80002472:	ec26                	sd	s1,24(sp)
    80002474:	e84a                	sd	s2,16(sp)
    80002476:	e44e                	sd	s3,8(sp)
    80002478:	e052                	sd	s4,0(sp)
    8000247a:	1800                	addi	s0,sp,48
    8000247c:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000247e:	0000f497          	auipc	s1,0xf
    80002482:	36248493          	addi	s1,s1,866 # 800117e0 <proc>
      pp->parent = initproc;
    80002486:	00007a17          	auipc	s4,0x7
    8000248a:	bb2a0a13          	addi	s4,s4,-1102 # 80009038 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000248e:	00015997          	auipc	s3,0x15
    80002492:	15298993          	addi	s3,s3,338 # 800175e0 <tickslock>
    80002496:	a029                	j	800024a0 <reparent+0x34>
    80002498:	17848493          	addi	s1,s1,376
    8000249c:	01348d63          	beq	s1,s3,800024b6 <reparent+0x4a>
    if(pp->parent == p){
    800024a0:	7c9c                	ld	a5,56(s1)
    800024a2:	ff279be3          	bne	a5,s2,80002498 <reparent+0x2c>
      pp->parent = initproc;
    800024a6:	000a3503          	ld	a0,0(s4)
    800024aa:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800024ac:	00000097          	auipc	ra,0x0
    800024b0:	f4a080e7          	jalr	-182(ra) # 800023f6 <wakeup>
    800024b4:	b7d5                	j	80002498 <reparent+0x2c>
}
    800024b6:	70a2                	ld	ra,40(sp)
    800024b8:	7402                	ld	s0,32(sp)
    800024ba:	64e2                	ld	s1,24(sp)
    800024bc:	6942                	ld	s2,16(sp)
    800024be:	69a2                	ld	s3,8(sp)
    800024c0:	6a02                	ld	s4,0(sp)
    800024c2:	6145                	addi	sp,sp,48
    800024c4:	8082                	ret

00000000800024c6 <exit>:
{
    800024c6:	7179                	addi	sp,sp,-48
    800024c8:	f406                	sd	ra,40(sp)
    800024ca:	f022                	sd	s0,32(sp)
    800024cc:	ec26                	sd	s1,24(sp)
    800024ce:	e84a                	sd	s2,16(sp)
    800024d0:	e44e                	sd	s3,8(sp)
    800024d2:	e052                	sd	s4,0(sp)
    800024d4:	1800                	addi	s0,sp,48
    800024d6:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800024d8:	fffff097          	auipc	ra,0xfffff
    800024dc:	59a080e7          	jalr	1434(ra) # 80001a72 <myproc>
    800024e0:	89aa                	mv	s3,a0
  if(p == initproc)
    800024e2:	00007797          	auipc	a5,0x7
    800024e6:	b567b783          	ld	a5,-1194(a5) # 80009038 <initproc>
    800024ea:	0d050493          	addi	s1,a0,208
    800024ee:	15050913          	addi	s2,a0,336
    800024f2:	02a79363          	bne	a5,a0,80002518 <exit+0x52>
    panic("init exiting");
    800024f6:	00006517          	auipc	a0,0x6
    800024fa:	dfa50513          	addi	a0,a0,-518 # 800082f0 <digits+0x2b0>
    800024fe:	ffffe097          	auipc	ra,0xffffe
    80002502:	03c080e7          	jalr	60(ra) # 8000053a <panic>
      fileclose(f);
    80002506:	00002097          	auipc	ra,0x2
    8000250a:	1d6080e7          	jalr	470(ra) # 800046dc <fileclose>
      p->ofile[fd] = 0;
    8000250e:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002512:	04a1                	addi	s1,s1,8
    80002514:	01248563          	beq	s1,s2,8000251e <exit+0x58>
    if(p->ofile[fd]){
    80002518:	6088                	ld	a0,0(s1)
    8000251a:	f575                	bnez	a0,80002506 <exit+0x40>
    8000251c:	bfdd                	j	80002512 <exit+0x4c>
  begin_op();
    8000251e:	00002097          	auipc	ra,0x2
    80002522:	cf6080e7          	jalr	-778(ra) # 80004214 <begin_op>
  iput(p->cwd);
    80002526:	1509b503          	ld	a0,336(s3)
    8000252a:	00001097          	auipc	ra,0x1
    8000252e:	4c8080e7          	jalr	1224(ra) # 800039f2 <iput>
  end_op();
    80002532:	00002097          	auipc	ra,0x2
    80002536:	d60080e7          	jalr	-672(ra) # 80004292 <end_op>
  p->cwd = 0;
    8000253a:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000253e:	0000f497          	auipc	s1,0xf
    80002542:	e8a48493          	addi	s1,s1,-374 # 800113c8 <wait_lock>
    80002546:	8526                	mv	a0,s1
    80002548:	ffffe097          	auipc	ra,0xffffe
    8000254c:	688080e7          	jalr	1672(ra) # 80000bd0 <acquire>
  reparent(p);
    80002550:	854e                	mv	a0,s3
    80002552:	00000097          	auipc	ra,0x0
    80002556:	f1a080e7          	jalr	-230(ra) # 8000246c <reparent>
  wakeup(p->parent);
    8000255a:	0389b503          	ld	a0,56(s3)
    8000255e:	00000097          	auipc	ra,0x0
    80002562:	e98080e7          	jalr	-360(ra) # 800023f6 <wakeup>
  acquire(&p->lock);
    80002566:	854e                	mv	a0,s3
    80002568:	ffffe097          	auipc	ra,0xffffe
    8000256c:	668080e7          	jalr	1640(ra) # 80000bd0 <acquire>
  p->xstate = status;
    80002570:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002574:	4795                	li	a5,5
    80002576:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000257a:	8526                	mv	a0,s1
    8000257c:	ffffe097          	auipc	ra,0xffffe
    80002580:	708080e7          	jalr	1800(ra) # 80000c84 <release>
  sched();
    80002584:	00000097          	auipc	ra,0x0
    80002588:	bd4080e7          	jalr	-1068(ra) # 80002158 <sched>
  panic("zombie exit");
    8000258c:	00006517          	auipc	a0,0x6
    80002590:	d7450513          	addi	a0,a0,-652 # 80008300 <digits+0x2c0>
    80002594:	ffffe097          	auipc	ra,0xffffe
    80002598:	fa6080e7          	jalr	-90(ra) # 8000053a <panic>

000000008000259c <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000259c:	7179                	addi	sp,sp,-48
    8000259e:	f406                	sd	ra,40(sp)
    800025a0:	f022                	sd	s0,32(sp)
    800025a2:	ec26                	sd	s1,24(sp)
    800025a4:	e84a                	sd	s2,16(sp)
    800025a6:	e44e                	sd	s3,8(sp)
    800025a8:	1800                	addi	s0,sp,48
    800025aa:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800025ac:	0000f497          	auipc	s1,0xf
    800025b0:	23448493          	addi	s1,s1,564 # 800117e0 <proc>
    800025b4:	00015997          	auipc	s3,0x15
    800025b8:	02c98993          	addi	s3,s3,44 # 800175e0 <tickslock>
    acquire(&p->lock);
    800025bc:	8526                	mv	a0,s1
    800025be:	ffffe097          	auipc	ra,0xffffe
    800025c2:	612080e7          	jalr	1554(ra) # 80000bd0 <acquire>
    if(p->pid == pid){
    800025c6:	589c                	lw	a5,48(s1)
    800025c8:	01278d63          	beq	a5,s2,800025e2 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800025cc:	8526                	mv	a0,s1
    800025ce:	ffffe097          	auipc	ra,0xffffe
    800025d2:	6b6080e7          	jalr	1718(ra) # 80000c84 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800025d6:	17848493          	addi	s1,s1,376
    800025da:	ff3491e3          	bne	s1,s3,800025bc <kill+0x20>
  }
  return -1;
    800025de:	557d                	li	a0,-1
    800025e0:	a829                	j	800025fa <kill+0x5e>
      p->killed = 1;
    800025e2:	4785                	li	a5,1
    800025e4:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800025e6:	4c98                	lw	a4,24(s1)
    800025e8:	4789                	li	a5,2
    800025ea:	00f70f63          	beq	a4,a5,80002608 <kill+0x6c>
      release(&p->lock);
    800025ee:	8526                	mv	a0,s1
    800025f0:	ffffe097          	auipc	ra,0xffffe
    800025f4:	694080e7          	jalr	1684(ra) # 80000c84 <release>
      return 0;
    800025f8:	4501                	li	a0,0
}
    800025fa:	70a2                	ld	ra,40(sp)
    800025fc:	7402                	ld	s0,32(sp)
    800025fe:	64e2                	ld	s1,24(sp)
    80002600:	6942                	ld	s2,16(sp)
    80002602:	69a2                	ld	s3,8(sp)
    80002604:	6145                	addi	sp,sp,48
    80002606:	8082                	ret
        p->state = RUNNABLE;
    80002608:	478d                	li	a5,3
    8000260a:	cc9c                	sw	a5,24(s1)
    8000260c:	b7cd                	j	800025ee <kill+0x52>

000000008000260e <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000260e:	7179                	addi	sp,sp,-48
    80002610:	f406                	sd	ra,40(sp)
    80002612:	f022                	sd	s0,32(sp)
    80002614:	ec26                	sd	s1,24(sp)
    80002616:	e84a                	sd	s2,16(sp)
    80002618:	e44e                	sd	s3,8(sp)
    8000261a:	e052                	sd	s4,0(sp)
    8000261c:	1800                	addi	s0,sp,48
    8000261e:	84aa                	mv	s1,a0
    80002620:	892e                	mv	s2,a1
    80002622:	89b2                	mv	s3,a2
    80002624:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002626:	fffff097          	auipc	ra,0xfffff
    8000262a:	44c080e7          	jalr	1100(ra) # 80001a72 <myproc>
  if(user_dst){
    8000262e:	c08d                	beqz	s1,80002650 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002630:	86d2                	mv	a3,s4
    80002632:	864e                	mv	a2,s3
    80002634:	85ca                	mv	a1,s2
    80002636:	6928                	ld	a0,80(a0)
    80002638:	fffff097          	auipc	ra,0xfffff
    8000263c:	022080e7          	jalr	34(ra) # 8000165a <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002640:	70a2                	ld	ra,40(sp)
    80002642:	7402                	ld	s0,32(sp)
    80002644:	64e2                	ld	s1,24(sp)
    80002646:	6942                	ld	s2,16(sp)
    80002648:	69a2                	ld	s3,8(sp)
    8000264a:	6a02                	ld	s4,0(sp)
    8000264c:	6145                	addi	sp,sp,48
    8000264e:	8082                	ret
    memmove((char *)dst, src, len);
    80002650:	000a061b          	sext.w	a2,s4
    80002654:	85ce                	mv	a1,s3
    80002656:	854a                	mv	a0,s2
    80002658:	ffffe097          	auipc	ra,0xffffe
    8000265c:	6d0080e7          	jalr	1744(ra) # 80000d28 <memmove>
    return 0;
    80002660:	8526                	mv	a0,s1
    80002662:	bff9                	j	80002640 <either_copyout+0x32>

0000000080002664 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002664:	7179                	addi	sp,sp,-48
    80002666:	f406                	sd	ra,40(sp)
    80002668:	f022                	sd	s0,32(sp)
    8000266a:	ec26                	sd	s1,24(sp)
    8000266c:	e84a                	sd	s2,16(sp)
    8000266e:	e44e                	sd	s3,8(sp)
    80002670:	e052                	sd	s4,0(sp)
    80002672:	1800                	addi	s0,sp,48
    80002674:	892a                	mv	s2,a0
    80002676:	84ae                	mv	s1,a1
    80002678:	89b2                	mv	s3,a2
    8000267a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000267c:	fffff097          	auipc	ra,0xfffff
    80002680:	3f6080e7          	jalr	1014(ra) # 80001a72 <myproc>
  if(user_src){
    80002684:	c08d                	beqz	s1,800026a6 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002686:	86d2                	mv	a3,s4
    80002688:	864e                	mv	a2,s3
    8000268a:	85ca                	mv	a1,s2
    8000268c:	6928                	ld	a0,80(a0)
    8000268e:	fffff097          	auipc	ra,0xfffff
    80002692:	058080e7          	jalr	88(ra) # 800016e6 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002696:	70a2                	ld	ra,40(sp)
    80002698:	7402                	ld	s0,32(sp)
    8000269a:	64e2                	ld	s1,24(sp)
    8000269c:	6942                	ld	s2,16(sp)
    8000269e:	69a2                	ld	s3,8(sp)
    800026a0:	6a02                	ld	s4,0(sp)
    800026a2:	6145                	addi	sp,sp,48
    800026a4:	8082                	ret
    memmove(dst, (char*)src, len);
    800026a6:	000a061b          	sext.w	a2,s4
    800026aa:	85ce                	mv	a1,s3
    800026ac:	854a                	mv	a0,s2
    800026ae:	ffffe097          	auipc	ra,0xffffe
    800026b2:	67a080e7          	jalr	1658(ra) # 80000d28 <memmove>
    return 0;
    800026b6:	8526                	mv	a0,s1
    800026b8:	bff9                	j	80002696 <either_copyin+0x32>

00000000800026ba <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800026ba:	715d                	addi	sp,sp,-80
    800026bc:	e486                	sd	ra,72(sp)
    800026be:	e0a2                	sd	s0,64(sp)
    800026c0:	fc26                	sd	s1,56(sp)
    800026c2:	f84a                	sd	s2,48(sp)
    800026c4:	f44e                	sd	s3,40(sp)
    800026c6:	f052                	sd	s4,32(sp)
    800026c8:	ec56                	sd	s5,24(sp)
    800026ca:	e85a                	sd	s6,16(sp)
    800026cc:	e45e                	sd	s7,8(sp)
    800026ce:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800026d0:	00006517          	auipc	a0,0x6
    800026d4:	9f850513          	addi	a0,a0,-1544 # 800080c8 <digits+0x88>
    800026d8:	ffffe097          	auipc	ra,0xffffe
    800026dc:	eac080e7          	jalr	-340(ra) # 80000584 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800026e0:	0000f497          	auipc	s1,0xf
    800026e4:	25848493          	addi	s1,s1,600 # 80011938 <proc+0x158>
    800026e8:	00015917          	auipc	s2,0x15
    800026ec:	05090913          	addi	s2,s2,80 # 80017738 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026f0:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800026f2:	00006997          	auipc	s3,0x6
    800026f6:	c1e98993          	addi	s3,s3,-994 # 80008310 <digits+0x2d0>
    printf("%d %s %s", p->pid, state, p->name);
    800026fa:	00006a97          	auipc	s5,0x6
    800026fe:	c1ea8a93          	addi	s5,s5,-994 # 80008318 <digits+0x2d8>
    printf("\n");
    80002702:	00006a17          	auipc	s4,0x6
    80002706:	9c6a0a13          	addi	s4,s4,-1594 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000270a:	00006b97          	auipc	s7,0x6
    8000270e:	c46b8b93          	addi	s7,s7,-954 # 80008350 <states.0>
    80002712:	a00d                	j	80002734 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002714:	ed86a583          	lw	a1,-296(a3)
    80002718:	8556                	mv	a0,s5
    8000271a:	ffffe097          	auipc	ra,0xffffe
    8000271e:	e6a080e7          	jalr	-406(ra) # 80000584 <printf>
    printf("\n");
    80002722:	8552                	mv	a0,s4
    80002724:	ffffe097          	auipc	ra,0xffffe
    80002728:	e60080e7          	jalr	-416(ra) # 80000584 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000272c:	17848493          	addi	s1,s1,376
    80002730:	03248263          	beq	s1,s2,80002754 <procdump+0x9a>
    if(p->state == UNUSED)
    80002734:	86a6                	mv	a3,s1
    80002736:	ec04a783          	lw	a5,-320(s1)
    8000273a:	dbed                	beqz	a5,8000272c <procdump+0x72>
      state = "???";
    8000273c:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000273e:	fcfb6be3          	bltu	s6,a5,80002714 <procdump+0x5a>
    80002742:	02079713          	slli	a4,a5,0x20
    80002746:	01d75793          	srli	a5,a4,0x1d
    8000274a:	97de                	add	a5,a5,s7
    8000274c:	6390                	ld	a2,0(a5)
    8000274e:	f279                	bnez	a2,80002714 <procdump+0x5a>
      state = "???";
    80002750:	864e                	mv	a2,s3
    80002752:	b7c9                	j	80002714 <procdump+0x5a>
  }
}
    80002754:	60a6                	ld	ra,72(sp)
    80002756:	6406                	ld	s0,64(sp)
    80002758:	74e2                	ld	s1,56(sp)
    8000275a:	7942                	ld	s2,48(sp)
    8000275c:	79a2                	ld	s3,40(sp)
    8000275e:	7a02                	ld	s4,32(sp)
    80002760:	6ae2                	ld	s5,24(sp)
    80002762:	6b42                	ld	s6,16(sp)
    80002764:	6ba2                	ld	s7,8(sp)
    80002766:	6161                	addi	sp,sp,80
    80002768:	8082                	ret

000000008000276a <swtch>:
    8000276a:	00153023          	sd	ra,0(a0)
    8000276e:	00253423          	sd	sp,8(a0)
    80002772:	e900                	sd	s0,16(a0)
    80002774:	ed04                	sd	s1,24(a0)
    80002776:	03253023          	sd	s2,32(a0)
    8000277a:	03353423          	sd	s3,40(a0)
    8000277e:	03453823          	sd	s4,48(a0)
    80002782:	03553c23          	sd	s5,56(a0)
    80002786:	05653023          	sd	s6,64(a0)
    8000278a:	05753423          	sd	s7,72(a0)
    8000278e:	05853823          	sd	s8,80(a0)
    80002792:	05953c23          	sd	s9,88(a0)
    80002796:	07a53023          	sd	s10,96(a0)
    8000279a:	07b53423          	sd	s11,104(a0)
    8000279e:	0005b083          	ld	ra,0(a1)
    800027a2:	0085b103          	ld	sp,8(a1)
    800027a6:	6980                	ld	s0,16(a1)
    800027a8:	6d84                	ld	s1,24(a1)
    800027aa:	0205b903          	ld	s2,32(a1)
    800027ae:	0285b983          	ld	s3,40(a1)
    800027b2:	0305ba03          	ld	s4,48(a1)
    800027b6:	0385ba83          	ld	s5,56(a1)
    800027ba:	0405bb03          	ld	s6,64(a1)
    800027be:	0485bb83          	ld	s7,72(a1)
    800027c2:	0505bc03          	ld	s8,80(a1)
    800027c6:	0585bc83          	ld	s9,88(a1)
    800027ca:	0605bd03          	ld	s10,96(a1)
    800027ce:	0685bd83          	ld	s11,104(a1)
    800027d2:	8082                	ret

00000000800027d4 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800027d4:	1141                	addi	sp,sp,-16
    800027d6:	e406                	sd	ra,8(sp)
    800027d8:	e022                	sd	s0,0(sp)
    800027da:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800027dc:	00006597          	auipc	a1,0x6
    800027e0:	ba458593          	addi	a1,a1,-1116 # 80008380 <states.0+0x30>
    800027e4:	00015517          	auipc	a0,0x15
    800027e8:	dfc50513          	addi	a0,a0,-516 # 800175e0 <tickslock>
    800027ec:	ffffe097          	auipc	ra,0xffffe
    800027f0:	354080e7          	jalr	852(ra) # 80000b40 <initlock>
}
    800027f4:	60a2                	ld	ra,8(sp)
    800027f6:	6402                	ld	s0,0(sp)
    800027f8:	0141                	addi	sp,sp,16
    800027fa:	8082                	ret

00000000800027fc <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800027fc:	1141                	addi	sp,sp,-16
    800027fe:	e422                	sd	s0,8(sp)
    80002800:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002802:	00003797          	auipc	a5,0x3
    80002806:	50e78793          	addi	a5,a5,1294 # 80005d10 <kernelvec>
    8000280a:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000280e:	6422                	ld	s0,8(sp)
    80002810:	0141                	addi	sp,sp,16
    80002812:	8082                	ret

0000000080002814 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002814:	1141                	addi	sp,sp,-16
    80002816:	e406                	sd	ra,8(sp)
    80002818:	e022                	sd	s0,0(sp)
    8000281a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000281c:	fffff097          	auipc	ra,0xfffff
    80002820:	256080e7          	jalr	598(ra) # 80001a72 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002824:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002828:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000282a:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000282e:	00004697          	auipc	a3,0x4
    80002832:	7d268693          	addi	a3,a3,2002 # 80007000 <_trampoline>
    80002836:	00004717          	auipc	a4,0x4
    8000283a:	7ca70713          	addi	a4,a4,1994 # 80007000 <_trampoline>
    8000283e:	8f15                	sub	a4,a4,a3
    80002840:	040007b7          	lui	a5,0x4000
    80002844:	17fd                	addi	a5,a5,-1
    80002846:	07b2                	slli	a5,a5,0xc
    80002848:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000284a:	10571073          	csrw	stvec,a4

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000284e:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002850:	18002673          	csrr	a2,satp
    80002854:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002856:	6d30                	ld	a2,88(a0)
    80002858:	6138                	ld	a4,64(a0)
    8000285a:	6585                	lui	a1,0x1
    8000285c:	972e                	add	a4,a4,a1
    8000285e:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002860:	6d38                	ld	a4,88(a0)
    80002862:	00000617          	auipc	a2,0x0
    80002866:	13860613          	addi	a2,a2,312 # 8000299a <usertrap>
    8000286a:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000286c:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000286e:	8612                	mv	a2,tp
    80002870:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002872:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002876:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000287a:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000287e:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002882:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002884:	6f18                	ld	a4,24(a4)
    80002886:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000288a:	692c                	ld	a1,80(a0)
    8000288c:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    8000288e:	00005717          	auipc	a4,0x5
    80002892:	80270713          	addi	a4,a4,-2046 # 80007090 <userret>
    80002896:	8f15                	sub	a4,a4,a3
    80002898:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    8000289a:	577d                	li	a4,-1
    8000289c:	177e                	slli	a4,a4,0x3f
    8000289e:	8dd9                	or	a1,a1,a4
    800028a0:	02000537          	lui	a0,0x2000
    800028a4:	157d                	addi	a0,a0,-1
    800028a6:	0536                	slli	a0,a0,0xd
    800028a8:	9782                	jalr	a5
}
    800028aa:	60a2                	ld	ra,8(sp)
    800028ac:	6402                	ld	s0,0(sp)
    800028ae:	0141                	addi	sp,sp,16
    800028b0:	8082                	ret

00000000800028b2 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800028b2:	1101                	addi	sp,sp,-32
    800028b4:	ec06                	sd	ra,24(sp)
    800028b6:	e822                	sd	s0,16(sp)
    800028b8:	e426                	sd	s1,8(sp)
    800028ba:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800028bc:	00015497          	auipc	s1,0x15
    800028c0:	d2448493          	addi	s1,s1,-732 # 800175e0 <tickslock>
    800028c4:	8526                	mv	a0,s1
    800028c6:	ffffe097          	auipc	ra,0xffffe
    800028ca:	30a080e7          	jalr	778(ra) # 80000bd0 <acquire>
  ticks++;
    800028ce:	00006517          	auipc	a0,0x6
    800028d2:	77250513          	addi	a0,a0,1906 # 80009040 <ticks>
    800028d6:	411c                	lw	a5,0(a0)
    800028d8:	2785                	addiw	a5,a5,1
    800028da:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800028dc:	00000097          	auipc	ra,0x0
    800028e0:	b1a080e7          	jalr	-1254(ra) # 800023f6 <wakeup>
  release(&tickslock);
    800028e4:	8526                	mv	a0,s1
    800028e6:	ffffe097          	auipc	ra,0xffffe
    800028ea:	39e080e7          	jalr	926(ra) # 80000c84 <release>
}
    800028ee:	60e2                	ld	ra,24(sp)
    800028f0:	6442                	ld	s0,16(sp)
    800028f2:	64a2                	ld	s1,8(sp)
    800028f4:	6105                	addi	sp,sp,32
    800028f6:	8082                	ret

00000000800028f8 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800028f8:	1101                	addi	sp,sp,-32
    800028fa:	ec06                	sd	ra,24(sp)
    800028fc:	e822                	sd	s0,16(sp)
    800028fe:	e426                	sd	s1,8(sp)
    80002900:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002902:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002906:	00074d63          	bltz	a4,80002920 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000290a:	57fd                	li	a5,-1
    8000290c:	17fe                	slli	a5,a5,0x3f
    8000290e:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002910:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002912:	06f70363          	beq	a4,a5,80002978 <devintr+0x80>
  }
}
    80002916:	60e2                	ld	ra,24(sp)
    80002918:	6442                	ld	s0,16(sp)
    8000291a:	64a2                	ld	s1,8(sp)
    8000291c:	6105                	addi	sp,sp,32
    8000291e:	8082                	ret
     (scause & 0xff) == 9){
    80002920:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    80002924:	46a5                	li	a3,9
    80002926:	fed792e3          	bne	a5,a3,8000290a <devintr+0x12>
    int irq = plic_claim();
    8000292a:	00003097          	auipc	ra,0x3
    8000292e:	4ee080e7          	jalr	1262(ra) # 80005e18 <plic_claim>
    80002932:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002934:	47a9                	li	a5,10
    80002936:	02f50763          	beq	a0,a5,80002964 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000293a:	4785                	li	a5,1
    8000293c:	02f50963          	beq	a0,a5,8000296e <devintr+0x76>
    return 1;
    80002940:	4505                	li	a0,1
    } else if(irq){
    80002942:	d8f1                	beqz	s1,80002916 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002944:	85a6                	mv	a1,s1
    80002946:	00006517          	auipc	a0,0x6
    8000294a:	a4250513          	addi	a0,a0,-1470 # 80008388 <states.0+0x38>
    8000294e:	ffffe097          	auipc	ra,0xffffe
    80002952:	c36080e7          	jalr	-970(ra) # 80000584 <printf>
      plic_complete(irq);
    80002956:	8526                	mv	a0,s1
    80002958:	00003097          	auipc	ra,0x3
    8000295c:	4e4080e7          	jalr	1252(ra) # 80005e3c <plic_complete>
    return 1;
    80002960:	4505                	li	a0,1
    80002962:	bf55                	j	80002916 <devintr+0x1e>
      uartintr();
    80002964:	ffffe097          	auipc	ra,0xffffe
    80002968:	02e080e7          	jalr	46(ra) # 80000992 <uartintr>
    8000296c:	b7ed                	j	80002956 <devintr+0x5e>
      virtio_disk_intr();
    8000296e:	00004097          	auipc	ra,0x4
    80002972:	95a080e7          	jalr	-1702(ra) # 800062c8 <virtio_disk_intr>
    80002976:	b7c5                	j	80002956 <devintr+0x5e>
    if(cpuid() == 0){
    80002978:	fffff097          	auipc	ra,0xfffff
    8000297c:	0ce080e7          	jalr	206(ra) # 80001a46 <cpuid>
    80002980:	c901                	beqz	a0,80002990 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002982:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002986:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002988:	14479073          	csrw	sip,a5
    return 2;
    8000298c:	4509                	li	a0,2
    8000298e:	b761                	j	80002916 <devintr+0x1e>
      clockintr();
    80002990:	00000097          	auipc	ra,0x0
    80002994:	f22080e7          	jalr	-222(ra) # 800028b2 <clockintr>
    80002998:	b7ed                	j	80002982 <devintr+0x8a>

000000008000299a <usertrap>:
{
    8000299a:	1101                	addi	sp,sp,-32
    8000299c:	ec06                	sd	ra,24(sp)
    8000299e:	e822                	sd	s0,16(sp)
    800029a0:	e426                	sd	s1,8(sp)
    800029a2:	e04a                	sd	s2,0(sp)
    800029a4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029a6:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800029aa:	1007f793          	andi	a5,a5,256
    800029ae:	e3ad                	bnez	a5,80002a10 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029b0:	00003797          	auipc	a5,0x3
    800029b4:	36078793          	addi	a5,a5,864 # 80005d10 <kernelvec>
    800029b8:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800029bc:	fffff097          	auipc	ra,0xfffff
    800029c0:	0b6080e7          	jalr	182(ra) # 80001a72 <myproc>
    800029c4:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800029c6:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029c8:	14102773          	csrr	a4,sepc
    800029cc:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029ce:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800029d2:	47a1                	li	a5,8
    800029d4:	04f71c63          	bne	a4,a5,80002a2c <usertrap+0x92>
    if(p->killed)
    800029d8:	551c                	lw	a5,40(a0)
    800029da:	e3b9                	bnez	a5,80002a20 <usertrap+0x86>
    p->trapframe->epc += 4;
    800029dc:	6cb8                	ld	a4,88(s1)
    800029de:	6f1c                	ld	a5,24(a4)
    800029e0:	0791                	addi	a5,a5,4
    800029e2:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029e4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800029e8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029ec:	10079073          	csrw	sstatus,a5
    syscall();
    800029f0:	00000097          	auipc	ra,0x0
    800029f4:	2e0080e7          	jalr	736(ra) # 80002cd0 <syscall>
  if(p->killed)
    800029f8:	549c                	lw	a5,40(s1)
    800029fa:	ebc1                	bnez	a5,80002a8a <usertrap+0xf0>
  usertrapret();
    800029fc:	00000097          	auipc	ra,0x0
    80002a00:	e18080e7          	jalr	-488(ra) # 80002814 <usertrapret>
}
    80002a04:	60e2                	ld	ra,24(sp)
    80002a06:	6442                	ld	s0,16(sp)
    80002a08:	64a2                	ld	s1,8(sp)
    80002a0a:	6902                	ld	s2,0(sp)
    80002a0c:	6105                	addi	sp,sp,32
    80002a0e:	8082                	ret
    panic("usertrap: not from user mode");
    80002a10:	00006517          	auipc	a0,0x6
    80002a14:	99850513          	addi	a0,a0,-1640 # 800083a8 <states.0+0x58>
    80002a18:	ffffe097          	auipc	ra,0xffffe
    80002a1c:	b22080e7          	jalr	-1246(ra) # 8000053a <panic>
      exit(-1);
    80002a20:	557d                	li	a0,-1
    80002a22:	00000097          	auipc	ra,0x0
    80002a26:	aa4080e7          	jalr	-1372(ra) # 800024c6 <exit>
    80002a2a:	bf4d                	j	800029dc <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002a2c:	00000097          	auipc	ra,0x0
    80002a30:	ecc080e7          	jalr	-308(ra) # 800028f8 <devintr>
    80002a34:	892a                	mv	s2,a0
    80002a36:	c501                	beqz	a0,80002a3e <usertrap+0xa4>
  if(p->killed)
    80002a38:	549c                	lw	a5,40(s1)
    80002a3a:	c3a1                	beqz	a5,80002a7a <usertrap+0xe0>
    80002a3c:	a815                	j	80002a70 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a3e:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002a42:	5890                	lw	a2,48(s1)
    80002a44:	00006517          	auipc	a0,0x6
    80002a48:	98450513          	addi	a0,a0,-1660 # 800083c8 <states.0+0x78>
    80002a4c:	ffffe097          	auipc	ra,0xffffe
    80002a50:	b38080e7          	jalr	-1224(ra) # 80000584 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a54:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a58:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a5c:	00006517          	auipc	a0,0x6
    80002a60:	99c50513          	addi	a0,a0,-1636 # 800083f8 <states.0+0xa8>
    80002a64:	ffffe097          	auipc	ra,0xffffe
    80002a68:	b20080e7          	jalr	-1248(ra) # 80000584 <printf>
    p->killed = 1;
    80002a6c:	4785                	li	a5,1
    80002a6e:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002a70:	557d                	li	a0,-1
    80002a72:	00000097          	auipc	ra,0x0
    80002a76:	a54080e7          	jalr	-1452(ra) # 800024c6 <exit>
  if(which_dev == 2)
    80002a7a:	4789                	li	a5,2
    80002a7c:	f8f910e3          	bne	s2,a5,800029fc <usertrap+0x62>
    yield();
    80002a80:	fffff097          	auipc	ra,0xfffff
    80002a84:	7ae080e7          	jalr	1966(ra) # 8000222e <yield>
    80002a88:	bf95                	j	800029fc <usertrap+0x62>
  int which_dev = 0;
    80002a8a:	4901                	li	s2,0
    80002a8c:	b7d5                	j	80002a70 <usertrap+0xd6>

0000000080002a8e <kerneltrap>:
{
    80002a8e:	7179                	addi	sp,sp,-48
    80002a90:	f406                	sd	ra,40(sp)
    80002a92:	f022                	sd	s0,32(sp)
    80002a94:	ec26                	sd	s1,24(sp)
    80002a96:	e84a                	sd	s2,16(sp)
    80002a98:	e44e                	sd	s3,8(sp)
    80002a9a:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a9c:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002aa0:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002aa4:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002aa8:	1004f793          	andi	a5,s1,256
    80002aac:	cb85                	beqz	a5,80002adc <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002aae:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002ab2:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002ab4:	ef85                	bnez	a5,80002aec <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002ab6:	00000097          	auipc	ra,0x0
    80002aba:	e42080e7          	jalr	-446(ra) # 800028f8 <devintr>
    80002abe:	cd1d                	beqz	a0,80002afc <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ac0:	4789                	li	a5,2
    80002ac2:	06f50a63          	beq	a0,a5,80002b36 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002ac6:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002aca:	10049073          	csrw	sstatus,s1
}
    80002ace:	70a2                	ld	ra,40(sp)
    80002ad0:	7402                	ld	s0,32(sp)
    80002ad2:	64e2                	ld	s1,24(sp)
    80002ad4:	6942                	ld	s2,16(sp)
    80002ad6:	69a2                	ld	s3,8(sp)
    80002ad8:	6145                	addi	sp,sp,48
    80002ada:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002adc:	00006517          	auipc	a0,0x6
    80002ae0:	93c50513          	addi	a0,a0,-1732 # 80008418 <states.0+0xc8>
    80002ae4:	ffffe097          	auipc	ra,0xffffe
    80002ae8:	a56080e7          	jalr	-1450(ra) # 8000053a <panic>
    panic("kerneltrap: interrupts enabled");
    80002aec:	00006517          	auipc	a0,0x6
    80002af0:	95450513          	addi	a0,a0,-1708 # 80008440 <states.0+0xf0>
    80002af4:	ffffe097          	auipc	ra,0xffffe
    80002af8:	a46080e7          	jalr	-1466(ra) # 8000053a <panic>
    printf("scause %p\n", scause);
    80002afc:	85ce                	mv	a1,s3
    80002afe:	00006517          	auipc	a0,0x6
    80002b02:	96250513          	addi	a0,a0,-1694 # 80008460 <states.0+0x110>
    80002b06:	ffffe097          	auipc	ra,0xffffe
    80002b0a:	a7e080e7          	jalr	-1410(ra) # 80000584 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b0e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b12:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b16:	00006517          	auipc	a0,0x6
    80002b1a:	95a50513          	addi	a0,a0,-1702 # 80008470 <states.0+0x120>
    80002b1e:	ffffe097          	auipc	ra,0xffffe
    80002b22:	a66080e7          	jalr	-1434(ra) # 80000584 <printf>
    panic("kerneltrap");
    80002b26:	00006517          	auipc	a0,0x6
    80002b2a:	96250513          	addi	a0,a0,-1694 # 80008488 <states.0+0x138>
    80002b2e:	ffffe097          	auipc	ra,0xffffe
    80002b32:	a0c080e7          	jalr	-1524(ra) # 8000053a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b36:	fffff097          	auipc	ra,0xfffff
    80002b3a:	f3c080e7          	jalr	-196(ra) # 80001a72 <myproc>
    80002b3e:	d541                	beqz	a0,80002ac6 <kerneltrap+0x38>
    80002b40:	fffff097          	auipc	ra,0xfffff
    80002b44:	f32080e7          	jalr	-206(ra) # 80001a72 <myproc>
    80002b48:	4d18                	lw	a4,24(a0)
    80002b4a:	4791                	li	a5,4
    80002b4c:	f6f71de3          	bne	a4,a5,80002ac6 <kerneltrap+0x38>
    yield();
    80002b50:	fffff097          	auipc	ra,0xfffff
    80002b54:	6de080e7          	jalr	1758(ra) # 8000222e <yield>
    80002b58:	b7bd                	j	80002ac6 <kerneltrap+0x38>

0000000080002b5a <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002b5a:	1101                	addi	sp,sp,-32
    80002b5c:	ec06                	sd	ra,24(sp)
    80002b5e:	e822                	sd	s0,16(sp)
    80002b60:	e426                	sd	s1,8(sp)
    80002b62:	1000                	addi	s0,sp,32
    80002b64:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002b66:	fffff097          	auipc	ra,0xfffff
    80002b6a:	f0c080e7          	jalr	-244(ra) # 80001a72 <myproc>
  switch (n) {
    80002b6e:	4795                	li	a5,5
    80002b70:	0497e163          	bltu	a5,s1,80002bb2 <argraw+0x58>
    80002b74:	048a                	slli	s1,s1,0x2
    80002b76:	00006717          	auipc	a4,0x6
    80002b7a:	94a70713          	addi	a4,a4,-1718 # 800084c0 <states.0+0x170>
    80002b7e:	94ba                	add	s1,s1,a4
    80002b80:	409c                	lw	a5,0(s1)
    80002b82:	97ba                	add	a5,a5,a4
    80002b84:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002b86:	6d3c                	ld	a5,88(a0)
    80002b88:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002b8a:	60e2                	ld	ra,24(sp)
    80002b8c:	6442                	ld	s0,16(sp)
    80002b8e:	64a2                	ld	s1,8(sp)
    80002b90:	6105                	addi	sp,sp,32
    80002b92:	8082                	ret
    return p->trapframe->a1;
    80002b94:	6d3c                	ld	a5,88(a0)
    80002b96:	7fa8                	ld	a0,120(a5)
    80002b98:	bfcd                	j	80002b8a <argraw+0x30>
    return p->trapframe->a2;
    80002b9a:	6d3c                	ld	a5,88(a0)
    80002b9c:	63c8                	ld	a0,128(a5)
    80002b9e:	b7f5                	j	80002b8a <argraw+0x30>
    return p->trapframe->a3;
    80002ba0:	6d3c                	ld	a5,88(a0)
    80002ba2:	67c8                	ld	a0,136(a5)
    80002ba4:	b7dd                	j	80002b8a <argraw+0x30>
    return p->trapframe->a4;
    80002ba6:	6d3c                	ld	a5,88(a0)
    80002ba8:	6bc8                	ld	a0,144(a5)
    80002baa:	b7c5                	j	80002b8a <argraw+0x30>
    return p->trapframe->a5;
    80002bac:	6d3c                	ld	a5,88(a0)
    80002bae:	6fc8                	ld	a0,152(a5)
    80002bb0:	bfe9                	j	80002b8a <argraw+0x30>
  panic("argraw");
    80002bb2:	00006517          	auipc	a0,0x6
    80002bb6:	8e650513          	addi	a0,a0,-1818 # 80008498 <states.0+0x148>
    80002bba:	ffffe097          	auipc	ra,0xffffe
    80002bbe:	980080e7          	jalr	-1664(ra) # 8000053a <panic>

0000000080002bc2 <fetchaddr>:
{
    80002bc2:	1101                	addi	sp,sp,-32
    80002bc4:	ec06                	sd	ra,24(sp)
    80002bc6:	e822                	sd	s0,16(sp)
    80002bc8:	e426                	sd	s1,8(sp)
    80002bca:	e04a                	sd	s2,0(sp)
    80002bcc:	1000                	addi	s0,sp,32
    80002bce:	84aa                	mv	s1,a0
    80002bd0:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002bd2:	fffff097          	auipc	ra,0xfffff
    80002bd6:	ea0080e7          	jalr	-352(ra) # 80001a72 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002bda:	653c                	ld	a5,72(a0)
    80002bdc:	02f4f863          	bgeu	s1,a5,80002c0c <fetchaddr+0x4a>
    80002be0:	00848713          	addi	a4,s1,8
    80002be4:	02e7e663          	bltu	a5,a4,80002c10 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002be8:	46a1                	li	a3,8
    80002bea:	8626                	mv	a2,s1
    80002bec:	85ca                	mv	a1,s2
    80002bee:	6928                	ld	a0,80(a0)
    80002bf0:	fffff097          	auipc	ra,0xfffff
    80002bf4:	af6080e7          	jalr	-1290(ra) # 800016e6 <copyin>
    80002bf8:	00a03533          	snez	a0,a0
    80002bfc:	40a00533          	neg	a0,a0
}
    80002c00:	60e2                	ld	ra,24(sp)
    80002c02:	6442                	ld	s0,16(sp)
    80002c04:	64a2                	ld	s1,8(sp)
    80002c06:	6902                	ld	s2,0(sp)
    80002c08:	6105                	addi	sp,sp,32
    80002c0a:	8082                	ret
    return -1;
    80002c0c:	557d                	li	a0,-1
    80002c0e:	bfcd                	j	80002c00 <fetchaddr+0x3e>
    80002c10:	557d                	li	a0,-1
    80002c12:	b7fd                	j	80002c00 <fetchaddr+0x3e>

0000000080002c14 <fetchstr>:
{
    80002c14:	7179                	addi	sp,sp,-48
    80002c16:	f406                	sd	ra,40(sp)
    80002c18:	f022                	sd	s0,32(sp)
    80002c1a:	ec26                	sd	s1,24(sp)
    80002c1c:	e84a                	sd	s2,16(sp)
    80002c1e:	e44e                	sd	s3,8(sp)
    80002c20:	1800                	addi	s0,sp,48
    80002c22:	892a                	mv	s2,a0
    80002c24:	84ae                	mv	s1,a1
    80002c26:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002c28:	fffff097          	auipc	ra,0xfffff
    80002c2c:	e4a080e7          	jalr	-438(ra) # 80001a72 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002c30:	86ce                	mv	a3,s3
    80002c32:	864a                	mv	a2,s2
    80002c34:	85a6                	mv	a1,s1
    80002c36:	6928                	ld	a0,80(a0)
    80002c38:	fffff097          	auipc	ra,0xfffff
    80002c3c:	b3c080e7          	jalr	-1220(ra) # 80001774 <copyinstr>
  if(err < 0)
    80002c40:	00054763          	bltz	a0,80002c4e <fetchstr+0x3a>
  return strlen(buf);
    80002c44:	8526                	mv	a0,s1
    80002c46:	ffffe097          	auipc	ra,0xffffe
    80002c4a:	202080e7          	jalr	514(ra) # 80000e48 <strlen>
}
    80002c4e:	70a2                	ld	ra,40(sp)
    80002c50:	7402                	ld	s0,32(sp)
    80002c52:	64e2                	ld	s1,24(sp)
    80002c54:	6942                	ld	s2,16(sp)
    80002c56:	69a2                	ld	s3,8(sp)
    80002c58:	6145                	addi	sp,sp,48
    80002c5a:	8082                	ret

0000000080002c5c <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002c5c:	1101                	addi	sp,sp,-32
    80002c5e:	ec06                	sd	ra,24(sp)
    80002c60:	e822                	sd	s0,16(sp)
    80002c62:	e426                	sd	s1,8(sp)
    80002c64:	1000                	addi	s0,sp,32
    80002c66:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c68:	00000097          	auipc	ra,0x0
    80002c6c:	ef2080e7          	jalr	-270(ra) # 80002b5a <argraw>
    80002c70:	c088                	sw	a0,0(s1)
  return 0;
}
    80002c72:	4501                	li	a0,0
    80002c74:	60e2                	ld	ra,24(sp)
    80002c76:	6442                	ld	s0,16(sp)
    80002c78:	64a2                	ld	s1,8(sp)
    80002c7a:	6105                	addi	sp,sp,32
    80002c7c:	8082                	ret

0000000080002c7e <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002c7e:	1101                	addi	sp,sp,-32
    80002c80:	ec06                	sd	ra,24(sp)
    80002c82:	e822                	sd	s0,16(sp)
    80002c84:	e426                	sd	s1,8(sp)
    80002c86:	1000                	addi	s0,sp,32
    80002c88:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c8a:	00000097          	auipc	ra,0x0
    80002c8e:	ed0080e7          	jalr	-304(ra) # 80002b5a <argraw>
    80002c92:	e088                	sd	a0,0(s1)
  return 0;
}
    80002c94:	4501                	li	a0,0
    80002c96:	60e2                	ld	ra,24(sp)
    80002c98:	6442                	ld	s0,16(sp)
    80002c9a:	64a2                	ld	s1,8(sp)
    80002c9c:	6105                	addi	sp,sp,32
    80002c9e:	8082                	ret

0000000080002ca0 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002ca0:	1101                	addi	sp,sp,-32
    80002ca2:	ec06                	sd	ra,24(sp)
    80002ca4:	e822                	sd	s0,16(sp)
    80002ca6:	e426                	sd	s1,8(sp)
    80002ca8:	e04a                	sd	s2,0(sp)
    80002caa:	1000                	addi	s0,sp,32
    80002cac:	84ae                	mv	s1,a1
    80002cae:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002cb0:	00000097          	auipc	ra,0x0
    80002cb4:	eaa080e7          	jalr	-342(ra) # 80002b5a <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002cb8:	864a                	mv	a2,s2
    80002cba:	85a6                	mv	a1,s1
    80002cbc:	00000097          	auipc	ra,0x0
    80002cc0:	f58080e7          	jalr	-168(ra) # 80002c14 <fetchstr>
}
    80002cc4:	60e2                	ld	ra,24(sp)
    80002cc6:	6442                	ld	s0,16(sp)
    80002cc8:	64a2                	ld	s1,8(sp)
    80002cca:	6902                	ld	s2,0(sp)
    80002ccc:	6105                	addi	sp,sp,32
    80002cce:	8082                	ret

0000000080002cd0 <syscall>:
[SYS_schedulerstats] sys_schedulerstats, //schedulerstats entry
};

void
syscall(void)
{
    80002cd0:	1101                	addi	sp,sp,-32
    80002cd2:	ec06                	sd	ra,24(sp)
    80002cd4:	e822                	sd	s0,16(sp)
    80002cd6:	e426                	sd	s1,8(sp)
    80002cd8:	e04a                	sd	s2,0(sp)
    80002cda:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002cdc:	fffff097          	auipc	ra,0xfffff
    80002ce0:	d96080e7          	jalr	-618(ra) # 80001a72 <myproc>
    80002ce4:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002ce6:	05853903          	ld	s2,88(a0)
    80002cea:	0a893783          	ld	a5,168(s2)
    80002cee:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002cf2:	37fd                	addiw	a5,a5,-1
    80002cf4:	4759                	li	a4,22
    80002cf6:	00f76f63          	bltu	a4,a5,80002d14 <syscall+0x44>
    80002cfa:	00369713          	slli	a4,a3,0x3
    80002cfe:	00005797          	auipc	a5,0x5
    80002d02:	7da78793          	addi	a5,a5,2010 # 800084d8 <syscalls>
    80002d06:	97ba                	add	a5,a5,a4
    80002d08:	639c                	ld	a5,0(a5)
    80002d0a:	c789                	beqz	a5,80002d14 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002d0c:	9782                	jalr	a5
    80002d0e:	06a93823          	sd	a0,112(s2)
    80002d12:	a839                	j	80002d30 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d14:	15848613          	addi	a2,s1,344
    80002d18:	588c                	lw	a1,48(s1)
    80002d1a:	00005517          	auipc	a0,0x5
    80002d1e:	78650513          	addi	a0,a0,1926 # 800084a0 <states.0+0x150>
    80002d22:	ffffe097          	auipc	ra,0xffffe
    80002d26:	862080e7          	jalr	-1950(ra) # 80000584 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d2a:	6cbc                	ld	a5,88(s1)
    80002d2c:	577d                	li	a4,-1
    80002d2e:	fbb8                	sd	a4,112(a5)
  }
}
    80002d30:	60e2                	ld	ra,24(sp)
    80002d32:	6442                	ld	s0,16(sp)
    80002d34:	64a2                	ld	s1,8(sp)
    80002d36:	6902                	ld	s2,0(sp)
    80002d38:	6105                	addi	sp,sp,32
    80002d3a:	8082                	ret

0000000080002d3c <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002d3c:	1101                	addi	sp,sp,-32
    80002d3e:	ec06                	sd	ra,24(sp)
    80002d40:	e822                	sd	s0,16(sp)
    80002d42:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002d44:	fec40593          	addi	a1,s0,-20
    80002d48:	4501                	li	a0,0
    80002d4a:	00000097          	auipc	ra,0x0
    80002d4e:	f12080e7          	jalr	-238(ra) # 80002c5c <argint>
    return -1;
    80002d52:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d54:	00054963          	bltz	a0,80002d66 <sys_exit+0x2a>
  exit(n);
    80002d58:	fec42503          	lw	a0,-20(s0)
    80002d5c:	fffff097          	auipc	ra,0xfffff
    80002d60:	76a080e7          	jalr	1898(ra) # 800024c6 <exit>
  return 0;  // not reached
    80002d64:	4781                	li	a5,0
}
    80002d66:	853e                	mv	a0,a5
    80002d68:	60e2                	ld	ra,24(sp)
    80002d6a:	6442                	ld	s0,16(sp)
    80002d6c:	6105                	addi	sp,sp,32
    80002d6e:	8082                	ret

0000000080002d70 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002d70:	1141                	addi	sp,sp,-16
    80002d72:	e406                	sd	ra,8(sp)
    80002d74:	e022                	sd	s0,0(sp)
    80002d76:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002d78:	fffff097          	auipc	ra,0xfffff
    80002d7c:	cfa080e7          	jalr	-774(ra) # 80001a72 <myproc>
}
    80002d80:	5908                	lw	a0,48(a0)
    80002d82:	60a2                	ld	ra,8(sp)
    80002d84:	6402                	ld	s0,0(sp)
    80002d86:	0141                	addi	sp,sp,16
    80002d88:	8082                	ret

0000000080002d8a <sys_fork>:

uint64
sys_fork(void)
{
    80002d8a:	1141                	addi	sp,sp,-16
    80002d8c:	e406                	sd	ra,8(sp)
    80002d8e:	e022                	sd	s0,0(sp)
    80002d90:	0800                	addi	s0,sp,16
  return fork();
    80002d92:	fffff097          	auipc	ra,0xfffff
    80002d96:	194080e7          	jalr	404(ra) # 80001f26 <fork>
}
    80002d9a:	60a2                	ld	ra,8(sp)
    80002d9c:	6402                	ld	s0,0(sp)
    80002d9e:	0141                	addi	sp,sp,16
    80002da0:	8082                	ret

0000000080002da2 <sys_wait>:

uint64
sys_wait(void)
{
    80002da2:	1101                	addi	sp,sp,-32
    80002da4:	ec06                	sd	ra,24(sp)
    80002da6:	e822                	sd	s0,16(sp)
    80002da8:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002daa:	fe840593          	addi	a1,s0,-24
    80002dae:	4501                	li	a0,0
    80002db0:	00000097          	auipc	ra,0x0
    80002db4:	ece080e7          	jalr	-306(ra) # 80002c7e <argaddr>
    80002db8:	87aa                	mv	a5,a0
    return -1;
    80002dba:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002dbc:	0007c863          	bltz	a5,80002dcc <sys_wait+0x2a>
  return wait(p);
    80002dc0:	fe843503          	ld	a0,-24(s0)
    80002dc4:	fffff097          	auipc	ra,0xfffff
    80002dc8:	50a080e7          	jalr	1290(ra) # 800022ce <wait>
}
    80002dcc:	60e2                	ld	ra,24(sp)
    80002dce:	6442                	ld	s0,16(sp)
    80002dd0:	6105                	addi	sp,sp,32
    80002dd2:	8082                	ret

0000000080002dd4 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002dd4:	7179                	addi	sp,sp,-48
    80002dd6:	f406                	sd	ra,40(sp)
    80002dd8:	f022                	sd	s0,32(sp)
    80002dda:	ec26                	sd	s1,24(sp)
    80002ddc:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002dde:	fdc40593          	addi	a1,s0,-36
    80002de2:	4501                	li	a0,0
    80002de4:	00000097          	auipc	ra,0x0
    80002de8:	e78080e7          	jalr	-392(ra) # 80002c5c <argint>
    80002dec:	87aa                	mv	a5,a0
    return -1;
    80002dee:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002df0:	0207c063          	bltz	a5,80002e10 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002df4:	fffff097          	auipc	ra,0xfffff
    80002df8:	c7e080e7          	jalr	-898(ra) # 80001a72 <myproc>
    80002dfc:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002dfe:	fdc42503          	lw	a0,-36(s0)
    80002e02:	fffff097          	auipc	ra,0xfffff
    80002e06:	0ac080e7          	jalr	172(ra) # 80001eae <growproc>
    80002e0a:	00054863          	bltz	a0,80002e1a <sys_sbrk+0x46>
    return -1;
  return addr;
    80002e0e:	8526                	mv	a0,s1
}
    80002e10:	70a2                	ld	ra,40(sp)
    80002e12:	7402                	ld	s0,32(sp)
    80002e14:	64e2                	ld	s1,24(sp)
    80002e16:	6145                	addi	sp,sp,48
    80002e18:	8082                	ret
    return -1;
    80002e1a:	557d                	li	a0,-1
    80002e1c:	bfd5                	j	80002e10 <sys_sbrk+0x3c>

0000000080002e1e <sys_sleep>:

uint64
sys_sleep(void)
{
    80002e1e:	7139                	addi	sp,sp,-64
    80002e20:	fc06                	sd	ra,56(sp)
    80002e22:	f822                	sd	s0,48(sp)
    80002e24:	f426                	sd	s1,40(sp)
    80002e26:	f04a                	sd	s2,32(sp)
    80002e28:	ec4e                	sd	s3,24(sp)
    80002e2a:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002e2c:	fcc40593          	addi	a1,s0,-52
    80002e30:	4501                	li	a0,0
    80002e32:	00000097          	auipc	ra,0x0
    80002e36:	e2a080e7          	jalr	-470(ra) # 80002c5c <argint>
    return -1;
    80002e3a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e3c:	06054563          	bltz	a0,80002ea6 <sys_sleep+0x88>
  acquire(&tickslock);
    80002e40:	00014517          	auipc	a0,0x14
    80002e44:	7a050513          	addi	a0,a0,1952 # 800175e0 <tickslock>
    80002e48:	ffffe097          	auipc	ra,0xffffe
    80002e4c:	d88080e7          	jalr	-632(ra) # 80000bd0 <acquire>
  ticks0 = ticks;
    80002e50:	00006917          	auipc	s2,0x6
    80002e54:	1f092903          	lw	s2,496(s2) # 80009040 <ticks>
  while(ticks - ticks0 < n){
    80002e58:	fcc42783          	lw	a5,-52(s0)
    80002e5c:	cf85                	beqz	a5,80002e94 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002e5e:	00014997          	auipc	s3,0x14
    80002e62:	78298993          	addi	s3,s3,1922 # 800175e0 <tickslock>
    80002e66:	00006497          	auipc	s1,0x6
    80002e6a:	1da48493          	addi	s1,s1,474 # 80009040 <ticks>
    if(myproc()->killed){
    80002e6e:	fffff097          	auipc	ra,0xfffff
    80002e72:	c04080e7          	jalr	-1020(ra) # 80001a72 <myproc>
    80002e76:	551c                	lw	a5,40(a0)
    80002e78:	ef9d                	bnez	a5,80002eb6 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002e7a:	85ce                	mv	a1,s3
    80002e7c:	8526                	mv	a0,s1
    80002e7e:	fffff097          	auipc	ra,0xfffff
    80002e82:	3ec080e7          	jalr	1004(ra) # 8000226a <sleep>
  while(ticks - ticks0 < n){
    80002e86:	409c                	lw	a5,0(s1)
    80002e88:	412787bb          	subw	a5,a5,s2
    80002e8c:	fcc42703          	lw	a4,-52(s0)
    80002e90:	fce7efe3          	bltu	a5,a4,80002e6e <sys_sleep+0x50>
  }
  release(&tickslock);
    80002e94:	00014517          	auipc	a0,0x14
    80002e98:	74c50513          	addi	a0,a0,1868 # 800175e0 <tickslock>
    80002e9c:	ffffe097          	auipc	ra,0xffffe
    80002ea0:	de8080e7          	jalr	-536(ra) # 80000c84 <release>
  return 0;
    80002ea4:	4781                	li	a5,0
}
    80002ea6:	853e                	mv	a0,a5
    80002ea8:	70e2                	ld	ra,56(sp)
    80002eaa:	7442                	ld	s0,48(sp)
    80002eac:	74a2                	ld	s1,40(sp)
    80002eae:	7902                	ld	s2,32(sp)
    80002eb0:	69e2                	ld	s3,24(sp)
    80002eb2:	6121                	addi	sp,sp,64
    80002eb4:	8082                	ret
      release(&tickslock);
    80002eb6:	00014517          	auipc	a0,0x14
    80002eba:	72a50513          	addi	a0,a0,1834 # 800175e0 <tickslock>
    80002ebe:	ffffe097          	auipc	ra,0xffffe
    80002ec2:	dc6080e7          	jalr	-570(ra) # 80000c84 <release>
      return -1;
    80002ec6:	57fd                	li	a5,-1
    80002ec8:	bff9                	j	80002ea6 <sys_sleep+0x88>

0000000080002eca <sys_kill>:

uint64
sys_kill(void)
{
    80002eca:	1101                	addi	sp,sp,-32
    80002ecc:	ec06                	sd	ra,24(sp)
    80002ece:	e822                	sd	s0,16(sp)
    80002ed0:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002ed2:	fec40593          	addi	a1,s0,-20
    80002ed6:	4501                	li	a0,0
    80002ed8:	00000097          	auipc	ra,0x0
    80002edc:	d84080e7          	jalr	-636(ra) # 80002c5c <argint>
    80002ee0:	87aa                	mv	a5,a0
    return -1;
    80002ee2:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002ee4:	0007c863          	bltz	a5,80002ef4 <sys_kill+0x2a>
  return kill(pid);
    80002ee8:	fec42503          	lw	a0,-20(s0)
    80002eec:	fffff097          	auipc	ra,0xfffff
    80002ef0:	6b0080e7          	jalr	1712(ra) # 8000259c <kill>
}
    80002ef4:	60e2                	ld	ra,24(sp)
    80002ef6:	6442                	ld	s0,16(sp)
    80002ef8:	6105                	addi	sp,sp,32
    80002efa:	8082                	ret

0000000080002efc <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002efc:	1101                	addi	sp,sp,-32
    80002efe:	ec06                	sd	ra,24(sp)
    80002f00:	e822                	sd	s0,16(sp)
    80002f02:	e426                	sd	s1,8(sp)
    80002f04:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f06:	00014517          	auipc	a0,0x14
    80002f0a:	6da50513          	addi	a0,a0,1754 # 800175e0 <tickslock>
    80002f0e:	ffffe097          	auipc	ra,0xffffe
    80002f12:	cc2080e7          	jalr	-830(ra) # 80000bd0 <acquire>
  xticks = ticks;
    80002f16:	00006497          	auipc	s1,0x6
    80002f1a:	12a4a483          	lw	s1,298(s1) # 80009040 <ticks>
  release(&tickslock);
    80002f1e:	00014517          	auipc	a0,0x14
    80002f22:	6c250513          	addi	a0,a0,1730 # 800175e0 <tickslock>
    80002f26:	ffffe097          	auipc	ra,0xffffe
    80002f2a:	d5e080e7          	jalr	-674(ra) # 80000c84 <release>
  return xticks;
}
    80002f2e:	02049513          	slli	a0,s1,0x20
    80002f32:	9101                	srli	a0,a0,0x20
    80002f34:	60e2                	ld	ra,24(sp)
    80002f36:	6442                	ld	s0,16(sp)
    80002f38:	64a2                	ld	s1,8(sp)
    80002f3a:	6105                	addi	sp,sp,32
    80002f3c:	8082                	ret

0000000080002f3e <sys_setticks>:

//LAB2
//set tickets syscall definition
uint64
sys_setticks(void)
{
    80002f3e:	1101                	addi	sp,sp,-32
    80002f40:	ec06                	sd	ra,24(sp)
    80002f42:	e822                	sd	s0,16(sp)
    80002f44:	1000                	addi	s0,sp,32
    int n;
    argint(0,&n);
    80002f46:	fec40593          	addi	a1,s0,-20
    80002f4a:	4501                	li	a0,0
    80002f4c:	00000097          	auipc	ra,0x0
    80002f50:	d10080e7          	jalr	-752(ra) # 80002c5c <argint>
    createTickets(n);
    80002f54:	fec42503          	lw	a0,-20(s0)
    80002f58:	fffff097          	auipc	ra,0xfffff
    80002f5c:	b54080e7          	jalr	-1196(ra) # 80001aac <createTickets>
    return 0;
}
    80002f60:	4501                	li	a0,0
    80002f62:	60e2                	ld	ra,24(sp)
    80002f64:	6442                	ld	s0,16(sp)
    80002f66:	6105                	addi	sp,sp,32
    80002f68:	8082                	ret

0000000080002f6a <sys_schedulerstats>:

//sched statistics syscall definition
uint64
sys_schedulerstats(void)
{
    80002f6a:	1101                	addi	sp,sp,-32
    80002f6c:	ec06                	sd	ra,24(sp)
    80002f6e:	e822                	sd	s0,16(sp)
    80002f70:	1000                	addi	s0,sp,32
    int n;
    int prog_num;
    argint(0,&n);
    80002f72:	fec40593          	addi	a1,s0,-20
    80002f76:	4501                	li	a0,0
    80002f78:	00000097          	auipc	ra,0x0
    80002f7c:	ce4080e7          	jalr	-796(ra) # 80002c5c <argint>
    argint(1,&prog_num);
    80002f80:	fe840593          	addi	a1,s0,-24
    80002f84:	4505                	li	a0,1
    80002f86:	00000097          	auipc	ra,0x0
    80002f8a:	cd6080e7          	jalr	-810(ra) # 80002c5c <argint>
    printStats(n,prog_num);
    80002f8e:	fe842583          	lw	a1,-24(s0)
    80002f92:	fec42503          	lw	a0,-20(s0)
    80002f96:	fffff097          	auipc	ra,0xfffff
    80002f9a:	88e080e7          	jalr	-1906(ra) # 80001824 <printStats>
    return 0;
}
    80002f9e:	4501                	li	a0,0
    80002fa0:	60e2                	ld	ra,24(sp)
    80002fa2:	6442                	ld	s0,16(sp)
    80002fa4:	6105                	addi	sp,sp,32
    80002fa6:	8082                	ret

0000000080002fa8 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002fa8:	7179                	addi	sp,sp,-48
    80002faa:	f406                	sd	ra,40(sp)
    80002fac:	f022                	sd	s0,32(sp)
    80002fae:	ec26                	sd	s1,24(sp)
    80002fb0:	e84a                	sd	s2,16(sp)
    80002fb2:	e44e                	sd	s3,8(sp)
    80002fb4:	e052                	sd	s4,0(sp)
    80002fb6:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002fb8:	00005597          	auipc	a1,0x5
    80002fbc:	5e058593          	addi	a1,a1,1504 # 80008598 <syscalls+0xc0>
    80002fc0:	00014517          	auipc	a0,0x14
    80002fc4:	63850513          	addi	a0,a0,1592 # 800175f8 <bcache>
    80002fc8:	ffffe097          	auipc	ra,0xffffe
    80002fcc:	b78080e7          	jalr	-1160(ra) # 80000b40 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002fd0:	0001c797          	auipc	a5,0x1c
    80002fd4:	62878793          	addi	a5,a5,1576 # 8001f5f8 <bcache+0x8000>
    80002fd8:	0001d717          	auipc	a4,0x1d
    80002fdc:	88870713          	addi	a4,a4,-1912 # 8001f860 <bcache+0x8268>
    80002fe0:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002fe4:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002fe8:	00014497          	auipc	s1,0x14
    80002fec:	62848493          	addi	s1,s1,1576 # 80017610 <bcache+0x18>
    b->next = bcache.head.next;
    80002ff0:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002ff2:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002ff4:	00005a17          	auipc	s4,0x5
    80002ff8:	5aca0a13          	addi	s4,s4,1452 # 800085a0 <syscalls+0xc8>
    b->next = bcache.head.next;
    80002ffc:	2b893783          	ld	a5,696(s2)
    80003000:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003002:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003006:	85d2                	mv	a1,s4
    80003008:	01048513          	addi	a0,s1,16
    8000300c:	00001097          	auipc	ra,0x1
    80003010:	4c2080e7          	jalr	1218(ra) # 800044ce <initsleeplock>
    bcache.head.next->prev = b;
    80003014:	2b893783          	ld	a5,696(s2)
    80003018:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000301a:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000301e:	45848493          	addi	s1,s1,1112
    80003022:	fd349de3          	bne	s1,s3,80002ffc <binit+0x54>
  }
}
    80003026:	70a2                	ld	ra,40(sp)
    80003028:	7402                	ld	s0,32(sp)
    8000302a:	64e2                	ld	s1,24(sp)
    8000302c:	6942                	ld	s2,16(sp)
    8000302e:	69a2                	ld	s3,8(sp)
    80003030:	6a02                	ld	s4,0(sp)
    80003032:	6145                	addi	sp,sp,48
    80003034:	8082                	ret

0000000080003036 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003036:	7179                	addi	sp,sp,-48
    80003038:	f406                	sd	ra,40(sp)
    8000303a:	f022                	sd	s0,32(sp)
    8000303c:	ec26                	sd	s1,24(sp)
    8000303e:	e84a                	sd	s2,16(sp)
    80003040:	e44e                	sd	s3,8(sp)
    80003042:	1800                	addi	s0,sp,48
    80003044:	892a                	mv	s2,a0
    80003046:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003048:	00014517          	auipc	a0,0x14
    8000304c:	5b050513          	addi	a0,a0,1456 # 800175f8 <bcache>
    80003050:	ffffe097          	auipc	ra,0xffffe
    80003054:	b80080e7          	jalr	-1152(ra) # 80000bd0 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003058:	0001d497          	auipc	s1,0x1d
    8000305c:	8584b483          	ld	s1,-1960(s1) # 8001f8b0 <bcache+0x82b8>
    80003060:	0001d797          	auipc	a5,0x1d
    80003064:	80078793          	addi	a5,a5,-2048 # 8001f860 <bcache+0x8268>
    80003068:	02f48f63          	beq	s1,a5,800030a6 <bread+0x70>
    8000306c:	873e                	mv	a4,a5
    8000306e:	a021                	j	80003076 <bread+0x40>
    80003070:	68a4                	ld	s1,80(s1)
    80003072:	02e48a63          	beq	s1,a4,800030a6 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003076:	449c                	lw	a5,8(s1)
    80003078:	ff279ce3          	bne	a5,s2,80003070 <bread+0x3a>
    8000307c:	44dc                	lw	a5,12(s1)
    8000307e:	ff3799e3          	bne	a5,s3,80003070 <bread+0x3a>
      b->refcnt++;
    80003082:	40bc                	lw	a5,64(s1)
    80003084:	2785                	addiw	a5,a5,1
    80003086:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003088:	00014517          	auipc	a0,0x14
    8000308c:	57050513          	addi	a0,a0,1392 # 800175f8 <bcache>
    80003090:	ffffe097          	auipc	ra,0xffffe
    80003094:	bf4080e7          	jalr	-1036(ra) # 80000c84 <release>
      acquiresleep(&b->lock);
    80003098:	01048513          	addi	a0,s1,16
    8000309c:	00001097          	auipc	ra,0x1
    800030a0:	46c080e7          	jalr	1132(ra) # 80004508 <acquiresleep>
      return b;
    800030a4:	a8b9                	j	80003102 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030a6:	0001d497          	auipc	s1,0x1d
    800030aa:	8024b483          	ld	s1,-2046(s1) # 8001f8a8 <bcache+0x82b0>
    800030ae:	0001c797          	auipc	a5,0x1c
    800030b2:	7b278793          	addi	a5,a5,1970 # 8001f860 <bcache+0x8268>
    800030b6:	00f48863          	beq	s1,a5,800030c6 <bread+0x90>
    800030ba:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800030bc:	40bc                	lw	a5,64(s1)
    800030be:	cf81                	beqz	a5,800030d6 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030c0:	64a4                	ld	s1,72(s1)
    800030c2:	fee49de3          	bne	s1,a4,800030bc <bread+0x86>
  panic("bget: no buffers");
    800030c6:	00005517          	auipc	a0,0x5
    800030ca:	4e250513          	addi	a0,a0,1250 # 800085a8 <syscalls+0xd0>
    800030ce:	ffffd097          	auipc	ra,0xffffd
    800030d2:	46c080e7          	jalr	1132(ra) # 8000053a <panic>
      b->dev = dev;
    800030d6:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800030da:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800030de:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800030e2:	4785                	li	a5,1
    800030e4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800030e6:	00014517          	auipc	a0,0x14
    800030ea:	51250513          	addi	a0,a0,1298 # 800175f8 <bcache>
    800030ee:	ffffe097          	auipc	ra,0xffffe
    800030f2:	b96080e7          	jalr	-1130(ra) # 80000c84 <release>
      acquiresleep(&b->lock);
    800030f6:	01048513          	addi	a0,s1,16
    800030fa:	00001097          	auipc	ra,0x1
    800030fe:	40e080e7          	jalr	1038(ra) # 80004508 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003102:	409c                	lw	a5,0(s1)
    80003104:	cb89                	beqz	a5,80003116 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003106:	8526                	mv	a0,s1
    80003108:	70a2                	ld	ra,40(sp)
    8000310a:	7402                	ld	s0,32(sp)
    8000310c:	64e2                	ld	s1,24(sp)
    8000310e:	6942                	ld	s2,16(sp)
    80003110:	69a2                	ld	s3,8(sp)
    80003112:	6145                	addi	sp,sp,48
    80003114:	8082                	ret
    virtio_disk_rw(b, 0);
    80003116:	4581                	li	a1,0
    80003118:	8526                	mv	a0,s1
    8000311a:	00003097          	auipc	ra,0x3
    8000311e:	f28080e7          	jalr	-216(ra) # 80006042 <virtio_disk_rw>
    b->valid = 1;
    80003122:	4785                	li	a5,1
    80003124:	c09c                	sw	a5,0(s1)
  return b;
    80003126:	b7c5                	j	80003106 <bread+0xd0>

0000000080003128 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003128:	1101                	addi	sp,sp,-32
    8000312a:	ec06                	sd	ra,24(sp)
    8000312c:	e822                	sd	s0,16(sp)
    8000312e:	e426                	sd	s1,8(sp)
    80003130:	1000                	addi	s0,sp,32
    80003132:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003134:	0541                	addi	a0,a0,16
    80003136:	00001097          	auipc	ra,0x1
    8000313a:	46c080e7          	jalr	1132(ra) # 800045a2 <holdingsleep>
    8000313e:	cd01                	beqz	a0,80003156 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003140:	4585                	li	a1,1
    80003142:	8526                	mv	a0,s1
    80003144:	00003097          	auipc	ra,0x3
    80003148:	efe080e7          	jalr	-258(ra) # 80006042 <virtio_disk_rw>
}
    8000314c:	60e2                	ld	ra,24(sp)
    8000314e:	6442                	ld	s0,16(sp)
    80003150:	64a2                	ld	s1,8(sp)
    80003152:	6105                	addi	sp,sp,32
    80003154:	8082                	ret
    panic("bwrite");
    80003156:	00005517          	auipc	a0,0x5
    8000315a:	46a50513          	addi	a0,a0,1130 # 800085c0 <syscalls+0xe8>
    8000315e:	ffffd097          	auipc	ra,0xffffd
    80003162:	3dc080e7          	jalr	988(ra) # 8000053a <panic>

0000000080003166 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003166:	1101                	addi	sp,sp,-32
    80003168:	ec06                	sd	ra,24(sp)
    8000316a:	e822                	sd	s0,16(sp)
    8000316c:	e426                	sd	s1,8(sp)
    8000316e:	e04a                	sd	s2,0(sp)
    80003170:	1000                	addi	s0,sp,32
    80003172:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003174:	01050913          	addi	s2,a0,16
    80003178:	854a                	mv	a0,s2
    8000317a:	00001097          	auipc	ra,0x1
    8000317e:	428080e7          	jalr	1064(ra) # 800045a2 <holdingsleep>
    80003182:	c92d                	beqz	a0,800031f4 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003184:	854a                	mv	a0,s2
    80003186:	00001097          	auipc	ra,0x1
    8000318a:	3d8080e7          	jalr	984(ra) # 8000455e <releasesleep>

  acquire(&bcache.lock);
    8000318e:	00014517          	auipc	a0,0x14
    80003192:	46a50513          	addi	a0,a0,1130 # 800175f8 <bcache>
    80003196:	ffffe097          	auipc	ra,0xffffe
    8000319a:	a3a080e7          	jalr	-1478(ra) # 80000bd0 <acquire>
  b->refcnt--;
    8000319e:	40bc                	lw	a5,64(s1)
    800031a0:	37fd                	addiw	a5,a5,-1
    800031a2:	0007871b          	sext.w	a4,a5
    800031a6:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800031a8:	eb05                	bnez	a4,800031d8 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800031aa:	68bc                	ld	a5,80(s1)
    800031ac:	64b8                	ld	a4,72(s1)
    800031ae:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800031b0:	64bc                	ld	a5,72(s1)
    800031b2:	68b8                	ld	a4,80(s1)
    800031b4:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800031b6:	0001c797          	auipc	a5,0x1c
    800031ba:	44278793          	addi	a5,a5,1090 # 8001f5f8 <bcache+0x8000>
    800031be:	2b87b703          	ld	a4,696(a5)
    800031c2:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800031c4:	0001c717          	auipc	a4,0x1c
    800031c8:	69c70713          	addi	a4,a4,1692 # 8001f860 <bcache+0x8268>
    800031cc:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800031ce:	2b87b703          	ld	a4,696(a5)
    800031d2:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800031d4:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800031d8:	00014517          	auipc	a0,0x14
    800031dc:	42050513          	addi	a0,a0,1056 # 800175f8 <bcache>
    800031e0:	ffffe097          	auipc	ra,0xffffe
    800031e4:	aa4080e7          	jalr	-1372(ra) # 80000c84 <release>
}
    800031e8:	60e2                	ld	ra,24(sp)
    800031ea:	6442                	ld	s0,16(sp)
    800031ec:	64a2                	ld	s1,8(sp)
    800031ee:	6902                	ld	s2,0(sp)
    800031f0:	6105                	addi	sp,sp,32
    800031f2:	8082                	ret
    panic("brelse");
    800031f4:	00005517          	auipc	a0,0x5
    800031f8:	3d450513          	addi	a0,a0,980 # 800085c8 <syscalls+0xf0>
    800031fc:	ffffd097          	auipc	ra,0xffffd
    80003200:	33e080e7          	jalr	830(ra) # 8000053a <panic>

0000000080003204 <bpin>:

void
bpin(struct buf *b) {
    80003204:	1101                	addi	sp,sp,-32
    80003206:	ec06                	sd	ra,24(sp)
    80003208:	e822                	sd	s0,16(sp)
    8000320a:	e426                	sd	s1,8(sp)
    8000320c:	1000                	addi	s0,sp,32
    8000320e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003210:	00014517          	auipc	a0,0x14
    80003214:	3e850513          	addi	a0,a0,1000 # 800175f8 <bcache>
    80003218:	ffffe097          	auipc	ra,0xffffe
    8000321c:	9b8080e7          	jalr	-1608(ra) # 80000bd0 <acquire>
  b->refcnt++;
    80003220:	40bc                	lw	a5,64(s1)
    80003222:	2785                	addiw	a5,a5,1
    80003224:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003226:	00014517          	auipc	a0,0x14
    8000322a:	3d250513          	addi	a0,a0,978 # 800175f8 <bcache>
    8000322e:	ffffe097          	auipc	ra,0xffffe
    80003232:	a56080e7          	jalr	-1450(ra) # 80000c84 <release>
}
    80003236:	60e2                	ld	ra,24(sp)
    80003238:	6442                	ld	s0,16(sp)
    8000323a:	64a2                	ld	s1,8(sp)
    8000323c:	6105                	addi	sp,sp,32
    8000323e:	8082                	ret

0000000080003240 <bunpin>:

void
bunpin(struct buf *b) {
    80003240:	1101                	addi	sp,sp,-32
    80003242:	ec06                	sd	ra,24(sp)
    80003244:	e822                	sd	s0,16(sp)
    80003246:	e426                	sd	s1,8(sp)
    80003248:	1000                	addi	s0,sp,32
    8000324a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000324c:	00014517          	auipc	a0,0x14
    80003250:	3ac50513          	addi	a0,a0,940 # 800175f8 <bcache>
    80003254:	ffffe097          	auipc	ra,0xffffe
    80003258:	97c080e7          	jalr	-1668(ra) # 80000bd0 <acquire>
  b->refcnt--;
    8000325c:	40bc                	lw	a5,64(s1)
    8000325e:	37fd                	addiw	a5,a5,-1
    80003260:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003262:	00014517          	auipc	a0,0x14
    80003266:	39650513          	addi	a0,a0,918 # 800175f8 <bcache>
    8000326a:	ffffe097          	auipc	ra,0xffffe
    8000326e:	a1a080e7          	jalr	-1510(ra) # 80000c84 <release>
}
    80003272:	60e2                	ld	ra,24(sp)
    80003274:	6442                	ld	s0,16(sp)
    80003276:	64a2                	ld	s1,8(sp)
    80003278:	6105                	addi	sp,sp,32
    8000327a:	8082                	ret

000000008000327c <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000327c:	1101                	addi	sp,sp,-32
    8000327e:	ec06                	sd	ra,24(sp)
    80003280:	e822                	sd	s0,16(sp)
    80003282:	e426                	sd	s1,8(sp)
    80003284:	e04a                	sd	s2,0(sp)
    80003286:	1000                	addi	s0,sp,32
    80003288:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000328a:	00d5d59b          	srliw	a1,a1,0xd
    8000328e:	0001d797          	auipc	a5,0x1d
    80003292:	a467a783          	lw	a5,-1466(a5) # 8001fcd4 <sb+0x1c>
    80003296:	9dbd                	addw	a1,a1,a5
    80003298:	00000097          	auipc	ra,0x0
    8000329c:	d9e080e7          	jalr	-610(ra) # 80003036 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800032a0:	0074f713          	andi	a4,s1,7
    800032a4:	4785                	li	a5,1
    800032a6:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800032aa:	14ce                	slli	s1,s1,0x33
    800032ac:	90d9                	srli	s1,s1,0x36
    800032ae:	00950733          	add	a4,a0,s1
    800032b2:	05874703          	lbu	a4,88(a4)
    800032b6:	00e7f6b3          	and	a3,a5,a4
    800032ba:	c69d                	beqz	a3,800032e8 <bfree+0x6c>
    800032bc:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800032be:	94aa                	add	s1,s1,a0
    800032c0:	fff7c793          	not	a5,a5
    800032c4:	8f7d                	and	a4,a4,a5
    800032c6:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800032ca:	00001097          	auipc	ra,0x1
    800032ce:	120080e7          	jalr	288(ra) # 800043ea <log_write>
  brelse(bp);
    800032d2:	854a                	mv	a0,s2
    800032d4:	00000097          	auipc	ra,0x0
    800032d8:	e92080e7          	jalr	-366(ra) # 80003166 <brelse>
}
    800032dc:	60e2                	ld	ra,24(sp)
    800032de:	6442                	ld	s0,16(sp)
    800032e0:	64a2                	ld	s1,8(sp)
    800032e2:	6902                	ld	s2,0(sp)
    800032e4:	6105                	addi	sp,sp,32
    800032e6:	8082                	ret
    panic("freeing free block");
    800032e8:	00005517          	auipc	a0,0x5
    800032ec:	2e850513          	addi	a0,a0,744 # 800085d0 <syscalls+0xf8>
    800032f0:	ffffd097          	auipc	ra,0xffffd
    800032f4:	24a080e7          	jalr	586(ra) # 8000053a <panic>

00000000800032f8 <balloc>:
{
    800032f8:	711d                	addi	sp,sp,-96
    800032fa:	ec86                	sd	ra,88(sp)
    800032fc:	e8a2                	sd	s0,80(sp)
    800032fe:	e4a6                	sd	s1,72(sp)
    80003300:	e0ca                	sd	s2,64(sp)
    80003302:	fc4e                	sd	s3,56(sp)
    80003304:	f852                	sd	s4,48(sp)
    80003306:	f456                	sd	s5,40(sp)
    80003308:	f05a                	sd	s6,32(sp)
    8000330a:	ec5e                	sd	s7,24(sp)
    8000330c:	e862                	sd	s8,16(sp)
    8000330e:	e466                	sd	s9,8(sp)
    80003310:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003312:	0001d797          	auipc	a5,0x1d
    80003316:	9aa7a783          	lw	a5,-1622(a5) # 8001fcbc <sb+0x4>
    8000331a:	cbc1                	beqz	a5,800033aa <balloc+0xb2>
    8000331c:	8baa                	mv	s7,a0
    8000331e:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003320:	0001db17          	auipc	s6,0x1d
    80003324:	998b0b13          	addi	s6,s6,-1640 # 8001fcb8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003328:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000332a:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000332c:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000332e:	6c89                	lui	s9,0x2
    80003330:	a831                	j	8000334c <balloc+0x54>
    brelse(bp);
    80003332:	854a                	mv	a0,s2
    80003334:	00000097          	auipc	ra,0x0
    80003338:	e32080e7          	jalr	-462(ra) # 80003166 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000333c:	015c87bb          	addw	a5,s9,s5
    80003340:	00078a9b          	sext.w	s5,a5
    80003344:	004b2703          	lw	a4,4(s6)
    80003348:	06eaf163          	bgeu	s5,a4,800033aa <balloc+0xb2>
    bp = bread(dev, BBLOCK(b, sb));
    8000334c:	41fad79b          	sraiw	a5,s5,0x1f
    80003350:	0137d79b          	srliw	a5,a5,0x13
    80003354:	015787bb          	addw	a5,a5,s5
    80003358:	40d7d79b          	sraiw	a5,a5,0xd
    8000335c:	01cb2583          	lw	a1,28(s6)
    80003360:	9dbd                	addw	a1,a1,a5
    80003362:	855e                	mv	a0,s7
    80003364:	00000097          	auipc	ra,0x0
    80003368:	cd2080e7          	jalr	-814(ra) # 80003036 <bread>
    8000336c:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000336e:	004b2503          	lw	a0,4(s6)
    80003372:	000a849b          	sext.w	s1,s5
    80003376:	8762                	mv	a4,s8
    80003378:	faa4fde3          	bgeu	s1,a0,80003332 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000337c:	00777693          	andi	a3,a4,7
    80003380:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003384:	41f7579b          	sraiw	a5,a4,0x1f
    80003388:	01d7d79b          	srliw	a5,a5,0x1d
    8000338c:	9fb9                	addw	a5,a5,a4
    8000338e:	4037d79b          	sraiw	a5,a5,0x3
    80003392:	00f90633          	add	a2,s2,a5
    80003396:	05864603          	lbu	a2,88(a2)
    8000339a:	00c6f5b3          	and	a1,a3,a2
    8000339e:	cd91                	beqz	a1,800033ba <balloc+0xc2>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033a0:	2705                	addiw	a4,a4,1
    800033a2:	2485                	addiw	s1,s1,1
    800033a4:	fd471ae3          	bne	a4,s4,80003378 <balloc+0x80>
    800033a8:	b769                	j	80003332 <balloc+0x3a>
  panic("balloc: out of blocks");
    800033aa:	00005517          	auipc	a0,0x5
    800033ae:	23e50513          	addi	a0,a0,574 # 800085e8 <syscalls+0x110>
    800033b2:	ffffd097          	auipc	ra,0xffffd
    800033b6:	188080e7          	jalr	392(ra) # 8000053a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800033ba:	97ca                	add	a5,a5,s2
    800033bc:	8e55                	or	a2,a2,a3
    800033be:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800033c2:	854a                	mv	a0,s2
    800033c4:	00001097          	auipc	ra,0x1
    800033c8:	026080e7          	jalr	38(ra) # 800043ea <log_write>
        brelse(bp);
    800033cc:	854a                	mv	a0,s2
    800033ce:	00000097          	auipc	ra,0x0
    800033d2:	d98080e7          	jalr	-616(ra) # 80003166 <brelse>
  bp = bread(dev, bno);
    800033d6:	85a6                	mv	a1,s1
    800033d8:	855e                	mv	a0,s7
    800033da:	00000097          	auipc	ra,0x0
    800033de:	c5c080e7          	jalr	-932(ra) # 80003036 <bread>
    800033e2:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800033e4:	40000613          	li	a2,1024
    800033e8:	4581                	li	a1,0
    800033ea:	05850513          	addi	a0,a0,88
    800033ee:	ffffe097          	auipc	ra,0xffffe
    800033f2:	8de080e7          	jalr	-1826(ra) # 80000ccc <memset>
  log_write(bp);
    800033f6:	854a                	mv	a0,s2
    800033f8:	00001097          	auipc	ra,0x1
    800033fc:	ff2080e7          	jalr	-14(ra) # 800043ea <log_write>
  brelse(bp);
    80003400:	854a                	mv	a0,s2
    80003402:	00000097          	auipc	ra,0x0
    80003406:	d64080e7          	jalr	-668(ra) # 80003166 <brelse>
}
    8000340a:	8526                	mv	a0,s1
    8000340c:	60e6                	ld	ra,88(sp)
    8000340e:	6446                	ld	s0,80(sp)
    80003410:	64a6                	ld	s1,72(sp)
    80003412:	6906                	ld	s2,64(sp)
    80003414:	79e2                	ld	s3,56(sp)
    80003416:	7a42                	ld	s4,48(sp)
    80003418:	7aa2                	ld	s5,40(sp)
    8000341a:	7b02                	ld	s6,32(sp)
    8000341c:	6be2                	ld	s7,24(sp)
    8000341e:	6c42                	ld	s8,16(sp)
    80003420:	6ca2                	ld	s9,8(sp)
    80003422:	6125                	addi	sp,sp,96
    80003424:	8082                	ret

0000000080003426 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003426:	7179                	addi	sp,sp,-48
    80003428:	f406                	sd	ra,40(sp)
    8000342a:	f022                	sd	s0,32(sp)
    8000342c:	ec26                	sd	s1,24(sp)
    8000342e:	e84a                	sd	s2,16(sp)
    80003430:	e44e                	sd	s3,8(sp)
    80003432:	e052                	sd	s4,0(sp)
    80003434:	1800                	addi	s0,sp,48
    80003436:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003438:	47ad                	li	a5,11
    8000343a:	04b7fe63          	bgeu	a5,a1,80003496 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000343e:	ff45849b          	addiw	s1,a1,-12
    80003442:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003446:	0ff00793          	li	a5,255
    8000344a:	0ae7e463          	bltu	a5,a4,800034f2 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000344e:	08052583          	lw	a1,128(a0)
    80003452:	c5b5                	beqz	a1,800034be <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003454:	00092503          	lw	a0,0(s2)
    80003458:	00000097          	auipc	ra,0x0
    8000345c:	bde080e7          	jalr	-1058(ra) # 80003036 <bread>
    80003460:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003462:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003466:	02049713          	slli	a4,s1,0x20
    8000346a:	01e75593          	srli	a1,a4,0x1e
    8000346e:	00b784b3          	add	s1,a5,a1
    80003472:	0004a983          	lw	s3,0(s1)
    80003476:	04098e63          	beqz	s3,800034d2 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000347a:	8552                	mv	a0,s4
    8000347c:	00000097          	auipc	ra,0x0
    80003480:	cea080e7          	jalr	-790(ra) # 80003166 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003484:	854e                	mv	a0,s3
    80003486:	70a2                	ld	ra,40(sp)
    80003488:	7402                	ld	s0,32(sp)
    8000348a:	64e2                	ld	s1,24(sp)
    8000348c:	6942                	ld	s2,16(sp)
    8000348e:	69a2                	ld	s3,8(sp)
    80003490:	6a02                	ld	s4,0(sp)
    80003492:	6145                	addi	sp,sp,48
    80003494:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003496:	02059793          	slli	a5,a1,0x20
    8000349a:	01e7d593          	srli	a1,a5,0x1e
    8000349e:	00b504b3          	add	s1,a0,a1
    800034a2:	0504a983          	lw	s3,80(s1)
    800034a6:	fc099fe3          	bnez	s3,80003484 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800034aa:	4108                	lw	a0,0(a0)
    800034ac:	00000097          	auipc	ra,0x0
    800034b0:	e4c080e7          	jalr	-436(ra) # 800032f8 <balloc>
    800034b4:	0005099b          	sext.w	s3,a0
    800034b8:	0534a823          	sw	s3,80(s1)
    800034bc:	b7e1                	j	80003484 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800034be:	4108                	lw	a0,0(a0)
    800034c0:	00000097          	auipc	ra,0x0
    800034c4:	e38080e7          	jalr	-456(ra) # 800032f8 <balloc>
    800034c8:	0005059b          	sext.w	a1,a0
    800034cc:	08b92023          	sw	a1,128(s2)
    800034d0:	b751                	j	80003454 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800034d2:	00092503          	lw	a0,0(s2)
    800034d6:	00000097          	auipc	ra,0x0
    800034da:	e22080e7          	jalr	-478(ra) # 800032f8 <balloc>
    800034de:	0005099b          	sext.w	s3,a0
    800034e2:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800034e6:	8552                	mv	a0,s4
    800034e8:	00001097          	auipc	ra,0x1
    800034ec:	f02080e7          	jalr	-254(ra) # 800043ea <log_write>
    800034f0:	b769                	j	8000347a <bmap+0x54>
  panic("bmap: out of range");
    800034f2:	00005517          	auipc	a0,0x5
    800034f6:	10e50513          	addi	a0,a0,270 # 80008600 <syscalls+0x128>
    800034fa:	ffffd097          	auipc	ra,0xffffd
    800034fe:	040080e7          	jalr	64(ra) # 8000053a <panic>

0000000080003502 <iget>:
{
    80003502:	7179                	addi	sp,sp,-48
    80003504:	f406                	sd	ra,40(sp)
    80003506:	f022                	sd	s0,32(sp)
    80003508:	ec26                	sd	s1,24(sp)
    8000350a:	e84a                	sd	s2,16(sp)
    8000350c:	e44e                	sd	s3,8(sp)
    8000350e:	e052                	sd	s4,0(sp)
    80003510:	1800                	addi	s0,sp,48
    80003512:	89aa                	mv	s3,a0
    80003514:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003516:	0001c517          	auipc	a0,0x1c
    8000351a:	7c250513          	addi	a0,a0,1986 # 8001fcd8 <itable>
    8000351e:	ffffd097          	auipc	ra,0xffffd
    80003522:	6b2080e7          	jalr	1714(ra) # 80000bd0 <acquire>
  empty = 0;
    80003526:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003528:	0001c497          	auipc	s1,0x1c
    8000352c:	7c848493          	addi	s1,s1,1992 # 8001fcf0 <itable+0x18>
    80003530:	0001e697          	auipc	a3,0x1e
    80003534:	25068693          	addi	a3,a3,592 # 80021780 <log>
    80003538:	a039                	j	80003546 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000353a:	02090b63          	beqz	s2,80003570 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000353e:	08848493          	addi	s1,s1,136
    80003542:	02d48a63          	beq	s1,a3,80003576 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003546:	449c                	lw	a5,8(s1)
    80003548:	fef059e3          	blez	a5,8000353a <iget+0x38>
    8000354c:	4098                	lw	a4,0(s1)
    8000354e:	ff3716e3          	bne	a4,s3,8000353a <iget+0x38>
    80003552:	40d8                	lw	a4,4(s1)
    80003554:	ff4713e3          	bne	a4,s4,8000353a <iget+0x38>
      ip->ref++;
    80003558:	2785                	addiw	a5,a5,1
    8000355a:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000355c:	0001c517          	auipc	a0,0x1c
    80003560:	77c50513          	addi	a0,a0,1916 # 8001fcd8 <itable>
    80003564:	ffffd097          	auipc	ra,0xffffd
    80003568:	720080e7          	jalr	1824(ra) # 80000c84 <release>
      return ip;
    8000356c:	8926                	mv	s2,s1
    8000356e:	a03d                	j	8000359c <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003570:	f7f9                	bnez	a5,8000353e <iget+0x3c>
    80003572:	8926                	mv	s2,s1
    80003574:	b7e9                	j	8000353e <iget+0x3c>
  if(empty == 0)
    80003576:	02090c63          	beqz	s2,800035ae <iget+0xac>
  ip->dev = dev;
    8000357a:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000357e:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003582:	4785                	li	a5,1
    80003584:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003588:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000358c:	0001c517          	auipc	a0,0x1c
    80003590:	74c50513          	addi	a0,a0,1868 # 8001fcd8 <itable>
    80003594:	ffffd097          	auipc	ra,0xffffd
    80003598:	6f0080e7          	jalr	1776(ra) # 80000c84 <release>
}
    8000359c:	854a                	mv	a0,s2
    8000359e:	70a2                	ld	ra,40(sp)
    800035a0:	7402                	ld	s0,32(sp)
    800035a2:	64e2                	ld	s1,24(sp)
    800035a4:	6942                	ld	s2,16(sp)
    800035a6:	69a2                	ld	s3,8(sp)
    800035a8:	6a02                	ld	s4,0(sp)
    800035aa:	6145                	addi	sp,sp,48
    800035ac:	8082                	ret
    panic("iget: no inodes");
    800035ae:	00005517          	auipc	a0,0x5
    800035b2:	06a50513          	addi	a0,a0,106 # 80008618 <syscalls+0x140>
    800035b6:	ffffd097          	auipc	ra,0xffffd
    800035ba:	f84080e7          	jalr	-124(ra) # 8000053a <panic>

00000000800035be <fsinit>:
fsinit(int dev) {
    800035be:	7179                	addi	sp,sp,-48
    800035c0:	f406                	sd	ra,40(sp)
    800035c2:	f022                	sd	s0,32(sp)
    800035c4:	ec26                	sd	s1,24(sp)
    800035c6:	e84a                	sd	s2,16(sp)
    800035c8:	e44e                	sd	s3,8(sp)
    800035ca:	1800                	addi	s0,sp,48
    800035cc:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800035ce:	4585                	li	a1,1
    800035d0:	00000097          	auipc	ra,0x0
    800035d4:	a66080e7          	jalr	-1434(ra) # 80003036 <bread>
    800035d8:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800035da:	0001c997          	auipc	s3,0x1c
    800035de:	6de98993          	addi	s3,s3,1758 # 8001fcb8 <sb>
    800035e2:	02000613          	li	a2,32
    800035e6:	05850593          	addi	a1,a0,88
    800035ea:	854e                	mv	a0,s3
    800035ec:	ffffd097          	auipc	ra,0xffffd
    800035f0:	73c080e7          	jalr	1852(ra) # 80000d28 <memmove>
  brelse(bp);
    800035f4:	8526                	mv	a0,s1
    800035f6:	00000097          	auipc	ra,0x0
    800035fa:	b70080e7          	jalr	-1168(ra) # 80003166 <brelse>
  if(sb.magic != FSMAGIC)
    800035fe:	0009a703          	lw	a4,0(s3)
    80003602:	102037b7          	lui	a5,0x10203
    80003606:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000360a:	02f71263          	bne	a4,a5,8000362e <fsinit+0x70>
  initlog(dev, &sb);
    8000360e:	0001c597          	auipc	a1,0x1c
    80003612:	6aa58593          	addi	a1,a1,1706 # 8001fcb8 <sb>
    80003616:	854a                	mv	a0,s2
    80003618:	00001097          	auipc	ra,0x1
    8000361c:	b56080e7          	jalr	-1194(ra) # 8000416e <initlog>
}
    80003620:	70a2                	ld	ra,40(sp)
    80003622:	7402                	ld	s0,32(sp)
    80003624:	64e2                	ld	s1,24(sp)
    80003626:	6942                	ld	s2,16(sp)
    80003628:	69a2                	ld	s3,8(sp)
    8000362a:	6145                	addi	sp,sp,48
    8000362c:	8082                	ret
    panic("invalid file system");
    8000362e:	00005517          	auipc	a0,0x5
    80003632:	ffa50513          	addi	a0,a0,-6 # 80008628 <syscalls+0x150>
    80003636:	ffffd097          	auipc	ra,0xffffd
    8000363a:	f04080e7          	jalr	-252(ra) # 8000053a <panic>

000000008000363e <iinit>:
{
    8000363e:	7179                	addi	sp,sp,-48
    80003640:	f406                	sd	ra,40(sp)
    80003642:	f022                	sd	s0,32(sp)
    80003644:	ec26                	sd	s1,24(sp)
    80003646:	e84a                	sd	s2,16(sp)
    80003648:	e44e                	sd	s3,8(sp)
    8000364a:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000364c:	00005597          	auipc	a1,0x5
    80003650:	ff458593          	addi	a1,a1,-12 # 80008640 <syscalls+0x168>
    80003654:	0001c517          	auipc	a0,0x1c
    80003658:	68450513          	addi	a0,a0,1668 # 8001fcd8 <itable>
    8000365c:	ffffd097          	auipc	ra,0xffffd
    80003660:	4e4080e7          	jalr	1252(ra) # 80000b40 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003664:	0001c497          	auipc	s1,0x1c
    80003668:	69c48493          	addi	s1,s1,1692 # 8001fd00 <itable+0x28>
    8000366c:	0001e997          	auipc	s3,0x1e
    80003670:	12498993          	addi	s3,s3,292 # 80021790 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003674:	00005917          	auipc	s2,0x5
    80003678:	fd490913          	addi	s2,s2,-44 # 80008648 <syscalls+0x170>
    8000367c:	85ca                	mv	a1,s2
    8000367e:	8526                	mv	a0,s1
    80003680:	00001097          	auipc	ra,0x1
    80003684:	e4e080e7          	jalr	-434(ra) # 800044ce <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003688:	08848493          	addi	s1,s1,136
    8000368c:	ff3498e3          	bne	s1,s3,8000367c <iinit+0x3e>
}
    80003690:	70a2                	ld	ra,40(sp)
    80003692:	7402                	ld	s0,32(sp)
    80003694:	64e2                	ld	s1,24(sp)
    80003696:	6942                	ld	s2,16(sp)
    80003698:	69a2                	ld	s3,8(sp)
    8000369a:	6145                	addi	sp,sp,48
    8000369c:	8082                	ret

000000008000369e <ialloc>:
{
    8000369e:	715d                	addi	sp,sp,-80
    800036a0:	e486                	sd	ra,72(sp)
    800036a2:	e0a2                	sd	s0,64(sp)
    800036a4:	fc26                	sd	s1,56(sp)
    800036a6:	f84a                	sd	s2,48(sp)
    800036a8:	f44e                	sd	s3,40(sp)
    800036aa:	f052                	sd	s4,32(sp)
    800036ac:	ec56                	sd	s5,24(sp)
    800036ae:	e85a                	sd	s6,16(sp)
    800036b0:	e45e                	sd	s7,8(sp)
    800036b2:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800036b4:	0001c717          	auipc	a4,0x1c
    800036b8:	61072703          	lw	a4,1552(a4) # 8001fcc4 <sb+0xc>
    800036bc:	4785                	li	a5,1
    800036be:	04e7fa63          	bgeu	a5,a4,80003712 <ialloc+0x74>
    800036c2:	8aaa                	mv	s5,a0
    800036c4:	8bae                	mv	s7,a1
    800036c6:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800036c8:	0001ca17          	auipc	s4,0x1c
    800036cc:	5f0a0a13          	addi	s4,s4,1520 # 8001fcb8 <sb>
    800036d0:	00048b1b          	sext.w	s6,s1
    800036d4:	0044d593          	srli	a1,s1,0x4
    800036d8:	018a2783          	lw	a5,24(s4)
    800036dc:	9dbd                	addw	a1,a1,a5
    800036de:	8556                	mv	a0,s5
    800036e0:	00000097          	auipc	ra,0x0
    800036e4:	956080e7          	jalr	-1706(ra) # 80003036 <bread>
    800036e8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800036ea:	05850993          	addi	s3,a0,88
    800036ee:	00f4f793          	andi	a5,s1,15
    800036f2:	079a                	slli	a5,a5,0x6
    800036f4:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800036f6:	00099783          	lh	a5,0(s3)
    800036fa:	c785                	beqz	a5,80003722 <ialloc+0x84>
    brelse(bp);
    800036fc:	00000097          	auipc	ra,0x0
    80003700:	a6a080e7          	jalr	-1430(ra) # 80003166 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003704:	0485                	addi	s1,s1,1
    80003706:	00ca2703          	lw	a4,12(s4)
    8000370a:	0004879b          	sext.w	a5,s1
    8000370e:	fce7e1e3          	bltu	a5,a4,800036d0 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003712:	00005517          	auipc	a0,0x5
    80003716:	f3e50513          	addi	a0,a0,-194 # 80008650 <syscalls+0x178>
    8000371a:	ffffd097          	auipc	ra,0xffffd
    8000371e:	e20080e7          	jalr	-480(ra) # 8000053a <panic>
      memset(dip, 0, sizeof(*dip));
    80003722:	04000613          	li	a2,64
    80003726:	4581                	li	a1,0
    80003728:	854e                	mv	a0,s3
    8000372a:	ffffd097          	auipc	ra,0xffffd
    8000372e:	5a2080e7          	jalr	1442(ra) # 80000ccc <memset>
      dip->type = type;
    80003732:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003736:	854a                	mv	a0,s2
    80003738:	00001097          	auipc	ra,0x1
    8000373c:	cb2080e7          	jalr	-846(ra) # 800043ea <log_write>
      brelse(bp);
    80003740:	854a                	mv	a0,s2
    80003742:	00000097          	auipc	ra,0x0
    80003746:	a24080e7          	jalr	-1500(ra) # 80003166 <brelse>
      return iget(dev, inum);
    8000374a:	85da                	mv	a1,s6
    8000374c:	8556                	mv	a0,s5
    8000374e:	00000097          	auipc	ra,0x0
    80003752:	db4080e7          	jalr	-588(ra) # 80003502 <iget>
}
    80003756:	60a6                	ld	ra,72(sp)
    80003758:	6406                	ld	s0,64(sp)
    8000375a:	74e2                	ld	s1,56(sp)
    8000375c:	7942                	ld	s2,48(sp)
    8000375e:	79a2                	ld	s3,40(sp)
    80003760:	7a02                	ld	s4,32(sp)
    80003762:	6ae2                	ld	s5,24(sp)
    80003764:	6b42                	ld	s6,16(sp)
    80003766:	6ba2                	ld	s7,8(sp)
    80003768:	6161                	addi	sp,sp,80
    8000376a:	8082                	ret

000000008000376c <iupdate>:
{
    8000376c:	1101                	addi	sp,sp,-32
    8000376e:	ec06                	sd	ra,24(sp)
    80003770:	e822                	sd	s0,16(sp)
    80003772:	e426                	sd	s1,8(sp)
    80003774:	e04a                	sd	s2,0(sp)
    80003776:	1000                	addi	s0,sp,32
    80003778:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000377a:	415c                	lw	a5,4(a0)
    8000377c:	0047d79b          	srliw	a5,a5,0x4
    80003780:	0001c597          	auipc	a1,0x1c
    80003784:	5505a583          	lw	a1,1360(a1) # 8001fcd0 <sb+0x18>
    80003788:	9dbd                	addw	a1,a1,a5
    8000378a:	4108                	lw	a0,0(a0)
    8000378c:	00000097          	auipc	ra,0x0
    80003790:	8aa080e7          	jalr	-1878(ra) # 80003036 <bread>
    80003794:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003796:	05850793          	addi	a5,a0,88
    8000379a:	40d8                	lw	a4,4(s1)
    8000379c:	8b3d                	andi	a4,a4,15
    8000379e:	071a                	slli	a4,a4,0x6
    800037a0:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    800037a2:	04449703          	lh	a4,68(s1)
    800037a6:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    800037aa:	04649703          	lh	a4,70(s1)
    800037ae:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    800037b2:	04849703          	lh	a4,72(s1)
    800037b6:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    800037ba:	04a49703          	lh	a4,74(s1)
    800037be:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    800037c2:	44f8                	lw	a4,76(s1)
    800037c4:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800037c6:	03400613          	li	a2,52
    800037ca:	05048593          	addi	a1,s1,80
    800037ce:	00c78513          	addi	a0,a5,12
    800037d2:	ffffd097          	auipc	ra,0xffffd
    800037d6:	556080e7          	jalr	1366(ra) # 80000d28 <memmove>
  log_write(bp);
    800037da:	854a                	mv	a0,s2
    800037dc:	00001097          	auipc	ra,0x1
    800037e0:	c0e080e7          	jalr	-1010(ra) # 800043ea <log_write>
  brelse(bp);
    800037e4:	854a                	mv	a0,s2
    800037e6:	00000097          	auipc	ra,0x0
    800037ea:	980080e7          	jalr	-1664(ra) # 80003166 <brelse>
}
    800037ee:	60e2                	ld	ra,24(sp)
    800037f0:	6442                	ld	s0,16(sp)
    800037f2:	64a2                	ld	s1,8(sp)
    800037f4:	6902                	ld	s2,0(sp)
    800037f6:	6105                	addi	sp,sp,32
    800037f8:	8082                	ret

00000000800037fa <idup>:
{
    800037fa:	1101                	addi	sp,sp,-32
    800037fc:	ec06                	sd	ra,24(sp)
    800037fe:	e822                	sd	s0,16(sp)
    80003800:	e426                	sd	s1,8(sp)
    80003802:	1000                	addi	s0,sp,32
    80003804:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003806:	0001c517          	auipc	a0,0x1c
    8000380a:	4d250513          	addi	a0,a0,1234 # 8001fcd8 <itable>
    8000380e:	ffffd097          	auipc	ra,0xffffd
    80003812:	3c2080e7          	jalr	962(ra) # 80000bd0 <acquire>
  ip->ref++;
    80003816:	449c                	lw	a5,8(s1)
    80003818:	2785                	addiw	a5,a5,1
    8000381a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000381c:	0001c517          	auipc	a0,0x1c
    80003820:	4bc50513          	addi	a0,a0,1212 # 8001fcd8 <itable>
    80003824:	ffffd097          	auipc	ra,0xffffd
    80003828:	460080e7          	jalr	1120(ra) # 80000c84 <release>
}
    8000382c:	8526                	mv	a0,s1
    8000382e:	60e2                	ld	ra,24(sp)
    80003830:	6442                	ld	s0,16(sp)
    80003832:	64a2                	ld	s1,8(sp)
    80003834:	6105                	addi	sp,sp,32
    80003836:	8082                	ret

0000000080003838 <ilock>:
{
    80003838:	1101                	addi	sp,sp,-32
    8000383a:	ec06                	sd	ra,24(sp)
    8000383c:	e822                	sd	s0,16(sp)
    8000383e:	e426                	sd	s1,8(sp)
    80003840:	e04a                	sd	s2,0(sp)
    80003842:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003844:	c115                	beqz	a0,80003868 <ilock+0x30>
    80003846:	84aa                	mv	s1,a0
    80003848:	451c                	lw	a5,8(a0)
    8000384a:	00f05f63          	blez	a5,80003868 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000384e:	0541                	addi	a0,a0,16
    80003850:	00001097          	auipc	ra,0x1
    80003854:	cb8080e7          	jalr	-840(ra) # 80004508 <acquiresleep>
  if(ip->valid == 0){
    80003858:	40bc                	lw	a5,64(s1)
    8000385a:	cf99                	beqz	a5,80003878 <ilock+0x40>
}
    8000385c:	60e2                	ld	ra,24(sp)
    8000385e:	6442                	ld	s0,16(sp)
    80003860:	64a2                	ld	s1,8(sp)
    80003862:	6902                	ld	s2,0(sp)
    80003864:	6105                	addi	sp,sp,32
    80003866:	8082                	ret
    panic("ilock");
    80003868:	00005517          	auipc	a0,0x5
    8000386c:	e0050513          	addi	a0,a0,-512 # 80008668 <syscalls+0x190>
    80003870:	ffffd097          	auipc	ra,0xffffd
    80003874:	cca080e7          	jalr	-822(ra) # 8000053a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003878:	40dc                	lw	a5,4(s1)
    8000387a:	0047d79b          	srliw	a5,a5,0x4
    8000387e:	0001c597          	auipc	a1,0x1c
    80003882:	4525a583          	lw	a1,1106(a1) # 8001fcd0 <sb+0x18>
    80003886:	9dbd                	addw	a1,a1,a5
    80003888:	4088                	lw	a0,0(s1)
    8000388a:	fffff097          	auipc	ra,0xfffff
    8000388e:	7ac080e7          	jalr	1964(ra) # 80003036 <bread>
    80003892:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003894:	05850593          	addi	a1,a0,88
    80003898:	40dc                	lw	a5,4(s1)
    8000389a:	8bbd                	andi	a5,a5,15
    8000389c:	079a                	slli	a5,a5,0x6
    8000389e:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800038a0:	00059783          	lh	a5,0(a1)
    800038a4:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800038a8:	00259783          	lh	a5,2(a1)
    800038ac:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800038b0:	00459783          	lh	a5,4(a1)
    800038b4:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800038b8:	00659783          	lh	a5,6(a1)
    800038bc:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800038c0:	459c                	lw	a5,8(a1)
    800038c2:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800038c4:	03400613          	li	a2,52
    800038c8:	05b1                	addi	a1,a1,12
    800038ca:	05048513          	addi	a0,s1,80
    800038ce:	ffffd097          	auipc	ra,0xffffd
    800038d2:	45a080e7          	jalr	1114(ra) # 80000d28 <memmove>
    brelse(bp);
    800038d6:	854a                	mv	a0,s2
    800038d8:	00000097          	auipc	ra,0x0
    800038dc:	88e080e7          	jalr	-1906(ra) # 80003166 <brelse>
    ip->valid = 1;
    800038e0:	4785                	li	a5,1
    800038e2:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800038e4:	04449783          	lh	a5,68(s1)
    800038e8:	fbb5                	bnez	a5,8000385c <ilock+0x24>
      panic("ilock: no type");
    800038ea:	00005517          	auipc	a0,0x5
    800038ee:	d8650513          	addi	a0,a0,-634 # 80008670 <syscalls+0x198>
    800038f2:	ffffd097          	auipc	ra,0xffffd
    800038f6:	c48080e7          	jalr	-952(ra) # 8000053a <panic>

00000000800038fa <iunlock>:
{
    800038fa:	1101                	addi	sp,sp,-32
    800038fc:	ec06                	sd	ra,24(sp)
    800038fe:	e822                	sd	s0,16(sp)
    80003900:	e426                	sd	s1,8(sp)
    80003902:	e04a                	sd	s2,0(sp)
    80003904:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003906:	c905                	beqz	a0,80003936 <iunlock+0x3c>
    80003908:	84aa                	mv	s1,a0
    8000390a:	01050913          	addi	s2,a0,16
    8000390e:	854a                	mv	a0,s2
    80003910:	00001097          	auipc	ra,0x1
    80003914:	c92080e7          	jalr	-878(ra) # 800045a2 <holdingsleep>
    80003918:	cd19                	beqz	a0,80003936 <iunlock+0x3c>
    8000391a:	449c                	lw	a5,8(s1)
    8000391c:	00f05d63          	blez	a5,80003936 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003920:	854a                	mv	a0,s2
    80003922:	00001097          	auipc	ra,0x1
    80003926:	c3c080e7          	jalr	-964(ra) # 8000455e <releasesleep>
}
    8000392a:	60e2                	ld	ra,24(sp)
    8000392c:	6442                	ld	s0,16(sp)
    8000392e:	64a2                	ld	s1,8(sp)
    80003930:	6902                	ld	s2,0(sp)
    80003932:	6105                	addi	sp,sp,32
    80003934:	8082                	ret
    panic("iunlock");
    80003936:	00005517          	auipc	a0,0x5
    8000393a:	d4a50513          	addi	a0,a0,-694 # 80008680 <syscalls+0x1a8>
    8000393e:	ffffd097          	auipc	ra,0xffffd
    80003942:	bfc080e7          	jalr	-1028(ra) # 8000053a <panic>

0000000080003946 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003946:	7179                	addi	sp,sp,-48
    80003948:	f406                	sd	ra,40(sp)
    8000394a:	f022                	sd	s0,32(sp)
    8000394c:	ec26                	sd	s1,24(sp)
    8000394e:	e84a                	sd	s2,16(sp)
    80003950:	e44e                	sd	s3,8(sp)
    80003952:	e052                	sd	s4,0(sp)
    80003954:	1800                	addi	s0,sp,48
    80003956:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003958:	05050493          	addi	s1,a0,80
    8000395c:	08050913          	addi	s2,a0,128
    80003960:	a021                	j	80003968 <itrunc+0x22>
    80003962:	0491                	addi	s1,s1,4
    80003964:	01248d63          	beq	s1,s2,8000397e <itrunc+0x38>
    if(ip->addrs[i]){
    80003968:	408c                	lw	a1,0(s1)
    8000396a:	dde5                	beqz	a1,80003962 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000396c:	0009a503          	lw	a0,0(s3)
    80003970:	00000097          	auipc	ra,0x0
    80003974:	90c080e7          	jalr	-1780(ra) # 8000327c <bfree>
      ip->addrs[i] = 0;
    80003978:	0004a023          	sw	zero,0(s1)
    8000397c:	b7dd                	j	80003962 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000397e:	0809a583          	lw	a1,128(s3)
    80003982:	e185                	bnez	a1,800039a2 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003984:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003988:	854e                	mv	a0,s3
    8000398a:	00000097          	auipc	ra,0x0
    8000398e:	de2080e7          	jalr	-542(ra) # 8000376c <iupdate>
}
    80003992:	70a2                	ld	ra,40(sp)
    80003994:	7402                	ld	s0,32(sp)
    80003996:	64e2                	ld	s1,24(sp)
    80003998:	6942                	ld	s2,16(sp)
    8000399a:	69a2                	ld	s3,8(sp)
    8000399c:	6a02                	ld	s4,0(sp)
    8000399e:	6145                	addi	sp,sp,48
    800039a0:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800039a2:	0009a503          	lw	a0,0(s3)
    800039a6:	fffff097          	auipc	ra,0xfffff
    800039aa:	690080e7          	jalr	1680(ra) # 80003036 <bread>
    800039ae:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800039b0:	05850493          	addi	s1,a0,88
    800039b4:	45850913          	addi	s2,a0,1112
    800039b8:	a021                	j	800039c0 <itrunc+0x7a>
    800039ba:	0491                	addi	s1,s1,4
    800039bc:	01248b63          	beq	s1,s2,800039d2 <itrunc+0x8c>
      if(a[j])
    800039c0:	408c                	lw	a1,0(s1)
    800039c2:	dde5                	beqz	a1,800039ba <itrunc+0x74>
        bfree(ip->dev, a[j]);
    800039c4:	0009a503          	lw	a0,0(s3)
    800039c8:	00000097          	auipc	ra,0x0
    800039cc:	8b4080e7          	jalr	-1868(ra) # 8000327c <bfree>
    800039d0:	b7ed                	j	800039ba <itrunc+0x74>
    brelse(bp);
    800039d2:	8552                	mv	a0,s4
    800039d4:	fffff097          	auipc	ra,0xfffff
    800039d8:	792080e7          	jalr	1938(ra) # 80003166 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800039dc:	0809a583          	lw	a1,128(s3)
    800039e0:	0009a503          	lw	a0,0(s3)
    800039e4:	00000097          	auipc	ra,0x0
    800039e8:	898080e7          	jalr	-1896(ra) # 8000327c <bfree>
    ip->addrs[NDIRECT] = 0;
    800039ec:	0809a023          	sw	zero,128(s3)
    800039f0:	bf51                	j	80003984 <itrunc+0x3e>

00000000800039f2 <iput>:
{
    800039f2:	1101                	addi	sp,sp,-32
    800039f4:	ec06                	sd	ra,24(sp)
    800039f6:	e822                	sd	s0,16(sp)
    800039f8:	e426                	sd	s1,8(sp)
    800039fa:	e04a                	sd	s2,0(sp)
    800039fc:	1000                	addi	s0,sp,32
    800039fe:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a00:	0001c517          	auipc	a0,0x1c
    80003a04:	2d850513          	addi	a0,a0,728 # 8001fcd8 <itable>
    80003a08:	ffffd097          	auipc	ra,0xffffd
    80003a0c:	1c8080e7          	jalr	456(ra) # 80000bd0 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a10:	4498                	lw	a4,8(s1)
    80003a12:	4785                	li	a5,1
    80003a14:	02f70363          	beq	a4,a5,80003a3a <iput+0x48>
  ip->ref--;
    80003a18:	449c                	lw	a5,8(s1)
    80003a1a:	37fd                	addiw	a5,a5,-1
    80003a1c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a1e:	0001c517          	auipc	a0,0x1c
    80003a22:	2ba50513          	addi	a0,a0,698 # 8001fcd8 <itable>
    80003a26:	ffffd097          	auipc	ra,0xffffd
    80003a2a:	25e080e7          	jalr	606(ra) # 80000c84 <release>
}
    80003a2e:	60e2                	ld	ra,24(sp)
    80003a30:	6442                	ld	s0,16(sp)
    80003a32:	64a2                	ld	s1,8(sp)
    80003a34:	6902                	ld	s2,0(sp)
    80003a36:	6105                	addi	sp,sp,32
    80003a38:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a3a:	40bc                	lw	a5,64(s1)
    80003a3c:	dff1                	beqz	a5,80003a18 <iput+0x26>
    80003a3e:	04a49783          	lh	a5,74(s1)
    80003a42:	fbf9                	bnez	a5,80003a18 <iput+0x26>
    acquiresleep(&ip->lock);
    80003a44:	01048913          	addi	s2,s1,16
    80003a48:	854a                	mv	a0,s2
    80003a4a:	00001097          	auipc	ra,0x1
    80003a4e:	abe080e7          	jalr	-1346(ra) # 80004508 <acquiresleep>
    release(&itable.lock);
    80003a52:	0001c517          	auipc	a0,0x1c
    80003a56:	28650513          	addi	a0,a0,646 # 8001fcd8 <itable>
    80003a5a:	ffffd097          	auipc	ra,0xffffd
    80003a5e:	22a080e7          	jalr	554(ra) # 80000c84 <release>
    itrunc(ip);
    80003a62:	8526                	mv	a0,s1
    80003a64:	00000097          	auipc	ra,0x0
    80003a68:	ee2080e7          	jalr	-286(ra) # 80003946 <itrunc>
    ip->type = 0;
    80003a6c:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003a70:	8526                	mv	a0,s1
    80003a72:	00000097          	auipc	ra,0x0
    80003a76:	cfa080e7          	jalr	-774(ra) # 8000376c <iupdate>
    ip->valid = 0;
    80003a7a:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a7e:	854a                	mv	a0,s2
    80003a80:	00001097          	auipc	ra,0x1
    80003a84:	ade080e7          	jalr	-1314(ra) # 8000455e <releasesleep>
    acquire(&itable.lock);
    80003a88:	0001c517          	auipc	a0,0x1c
    80003a8c:	25050513          	addi	a0,a0,592 # 8001fcd8 <itable>
    80003a90:	ffffd097          	auipc	ra,0xffffd
    80003a94:	140080e7          	jalr	320(ra) # 80000bd0 <acquire>
    80003a98:	b741                	j	80003a18 <iput+0x26>

0000000080003a9a <iunlockput>:
{
    80003a9a:	1101                	addi	sp,sp,-32
    80003a9c:	ec06                	sd	ra,24(sp)
    80003a9e:	e822                	sd	s0,16(sp)
    80003aa0:	e426                	sd	s1,8(sp)
    80003aa2:	1000                	addi	s0,sp,32
    80003aa4:	84aa                	mv	s1,a0
  iunlock(ip);
    80003aa6:	00000097          	auipc	ra,0x0
    80003aaa:	e54080e7          	jalr	-428(ra) # 800038fa <iunlock>
  iput(ip);
    80003aae:	8526                	mv	a0,s1
    80003ab0:	00000097          	auipc	ra,0x0
    80003ab4:	f42080e7          	jalr	-190(ra) # 800039f2 <iput>
}
    80003ab8:	60e2                	ld	ra,24(sp)
    80003aba:	6442                	ld	s0,16(sp)
    80003abc:	64a2                	ld	s1,8(sp)
    80003abe:	6105                	addi	sp,sp,32
    80003ac0:	8082                	ret

0000000080003ac2 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003ac2:	1141                	addi	sp,sp,-16
    80003ac4:	e422                	sd	s0,8(sp)
    80003ac6:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003ac8:	411c                	lw	a5,0(a0)
    80003aca:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003acc:	415c                	lw	a5,4(a0)
    80003ace:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003ad0:	04451783          	lh	a5,68(a0)
    80003ad4:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003ad8:	04a51783          	lh	a5,74(a0)
    80003adc:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003ae0:	04c56783          	lwu	a5,76(a0)
    80003ae4:	e99c                	sd	a5,16(a1)
}
    80003ae6:	6422                	ld	s0,8(sp)
    80003ae8:	0141                	addi	sp,sp,16
    80003aea:	8082                	ret

0000000080003aec <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003aec:	457c                	lw	a5,76(a0)
    80003aee:	0ed7e963          	bltu	a5,a3,80003be0 <readi+0xf4>
{
    80003af2:	7159                	addi	sp,sp,-112
    80003af4:	f486                	sd	ra,104(sp)
    80003af6:	f0a2                	sd	s0,96(sp)
    80003af8:	eca6                	sd	s1,88(sp)
    80003afa:	e8ca                	sd	s2,80(sp)
    80003afc:	e4ce                	sd	s3,72(sp)
    80003afe:	e0d2                	sd	s4,64(sp)
    80003b00:	fc56                	sd	s5,56(sp)
    80003b02:	f85a                	sd	s6,48(sp)
    80003b04:	f45e                	sd	s7,40(sp)
    80003b06:	f062                	sd	s8,32(sp)
    80003b08:	ec66                	sd	s9,24(sp)
    80003b0a:	e86a                	sd	s10,16(sp)
    80003b0c:	e46e                	sd	s11,8(sp)
    80003b0e:	1880                	addi	s0,sp,112
    80003b10:	8baa                	mv	s7,a0
    80003b12:	8c2e                	mv	s8,a1
    80003b14:	8ab2                	mv	s5,a2
    80003b16:	84b6                	mv	s1,a3
    80003b18:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b1a:	9f35                	addw	a4,a4,a3
    return 0;
    80003b1c:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003b1e:	0ad76063          	bltu	a4,a3,80003bbe <readi+0xd2>
  if(off + n > ip->size)
    80003b22:	00e7f463          	bgeu	a5,a4,80003b2a <readi+0x3e>
    n = ip->size - off;
    80003b26:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b2a:	0a0b0963          	beqz	s6,80003bdc <readi+0xf0>
    80003b2e:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b30:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003b34:	5cfd                	li	s9,-1
    80003b36:	a82d                	j	80003b70 <readi+0x84>
    80003b38:	020a1d93          	slli	s11,s4,0x20
    80003b3c:	020ddd93          	srli	s11,s11,0x20
    80003b40:	05890613          	addi	a2,s2,88
    80003b44:	86ee                	mv	a3,s11
    80003b46:	963a                	add	a2,a2,a4
    80003b48:	85d6                	mv	a1,s5
    80003b4a:	8562                	mv	a0,s8
    80003b4c:	fffff097          	auipc	ra,0xfffff
    80003b50:	ac2080e7          	jalr	-1342(ra) # 8000260e <either_copyout>
    80003b54:	05950d63          	beq	a0,s9,80003bae <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003b58:	854a                	mv	a0,s2
    80003b5a:	fffff097          	auipc	ra,0xfffff
    80003b5e:	60c080e7          	jalr	1548(ra) # 80003166 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b62:	013a09bb          	addw	s3,s4,s3
    80003b66:	009a04bb          	addw	s1,s4,s1
    80003b6a:	9aee                	add	s5,s5,s11
    80003b6c:	0569f763          	bgeu	s3,s6,80003bba <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b70:	000ba903          	lw	s2,0(s7)
    80003b74:	00a4d59b          	srliw	a1,s1,0xa
    80003b78:	855e                	mv	a0,s7
    80003b7a:	00000097          	auipc	ra,0x0
    80003b7e:	8ac080e7          	jalr	-1876(ra) # 80003426 <bmap>
    80003b82:	0005059b          	sext.w	a1,a0
    80003b86:	854a                	mv	a0,s2
    80003b88:	fffff097          	auipc	ra,0xfffff
    80003b8c:	4ae080e7          	jalr	1198(ra) # 80003036 <bread>
    80003b90:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b92:	3ff4f713          	andi	a4,s1,1023
    80003b96:	40ed07bb          	subw	a5,s10,a4
    80003b9a:	413b06bb          	subw	a3,s6,s3
    80003b9e:	8a3e                	mv	s4,a5
    80003ba0:	2781                	sext.w	a5,a5
    80003ba2:	0006861b          	sext.w	a2,a3
    80003ba6:	f8f679e3          	bgeu	a2,a5,80003b38 <readi+0x4c>
    80003baa:	8a36                	mv	s4,a3
    80003bac:	b771                	j	80003b38 <readi+0x4c>
      brelse(bp);
    80003bae:	854a                	mv	a0,s2
    80003bb0:	fffff097          	auipc	ra,0xfffff
    80003bb4:	5b6080e7          	jalr	1462(ra) # 80003166 <brelse>
      tot = -1;
    80003bb8:	59fd                	li	s3,-1
  }
  return tot;
    80003bba:	0009851b          	sext.w	a0,s3
}
    80003bbe:	70a6                	ld	ra,104(sp)
    80003bc0:	7406                	ld	s0,96(sp)
    80003bc2:	64e6                	ld	s1,88(sp)
    80003bc4:	6946                	ld	s2,80(sp)
    80003bc6:	69a6                	ld	s3,72(sp)
    80003bc8:	6a06                	ld	s4,64(sp)
    80003bca:	7ae2                	ld	s5,56(sp)
    80003bcc:	7b42                	ld	s6,48(sp)
    80003bce:	7ba2                	ld	s7,40(sp)
    80003bd0:	7c02                	ld	s8,32(sp)
    80003bd2:	6ce2                	ld	s9,24(sp)
    80003bd4:	6d42                	ld	s10,16(sp)
    80003bd6:	6da2                	ld	s11,8(sp)
    80003bd8:	6165                	addi	sp,sp,112
    80003bda:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bdc:	89da                	mv	s3,s6
    80003bde:	bff1                	j	80003bba <readi+0xce>
    return 0;
    80003be0:	4501                	li	a0,0
}
    80003be2:	8082                	ret

0000000080003be4 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003be4:	457c                	lw	a5,76(a0)
    80003be6:	10d7e863          	bltu	a5,a3,80003cf6 <writei+0x112>
{
    80003bea:	7159                	addi	sp,sp,-112
    80003bec:	f486                	sd	ra,104(sp)
    80003bee:	f0a2                	sd	s0,96(sp)
    80003bf0:	eca6                	sd	s1,88(sp)
    80003bf2:	e8ca                	sd	s2,80(sp)
    80003bf4:	e4ce                	sd	s3,72(sp)
    80003bf6:	e0d2                	sd	s4,64(sp)
    80003bf8:	fc56                	sd	s5,56(sp)
    80003bfa:	f85a                	sd	s6,48(sp)
    80003bfc:	f45e                	sd	s7,40(sp)
    80003bfe:	f062                	sd	s8,32(sp)
    80003c00:	ec66                	sd	s9,24(sp)
    80003c02:	e86a                	sd	s10,16(sp)
    80003c04:	e46e                	sd	s11,8(sp)
    80003c06:	1880                	addi	s0,sp,112
    80003c08:	8b2a                	mv	s6,a0
    80003c0a:	8c2e                	mv	s8,a1
    80003c0c:	8ab2                	mv	s5,a2
    80003c0e:	8936                	mv	s2,a3
    80003c10:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003c12:	00e687bb          	addw	a5,a3,a4
    80003c16:	0ed7e263          	bltu	a5,a3,80003cfa <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003c1a:	00043737          	lui	a4,0x43
    80003c1e:	0ef76063          	bltu	a4,a5,80003cfe <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c22:	0c0b8863          	beqz	s7,80003cf2 <writei+0x10e>
    80003c26:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c28:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003c2c:	5cfd                	li	s9,-1
    80003c2e:	a091                	j	80003c72 <writei+0x8e>
    80003c30:	02099d93          	slli	s11,s3,0x20
    80003c34:	020ddd93          	srli	s11,s11,0x20
    80003c38:	05848513          	addi	a0,s1,88
    80003c3c:	86ee                	mv	a3,s11
    80003c3e:	8656                	mv	a2,s5
    80003c40:	85e2                	mv	a1,s8
    80003c42:	953a                	add	a0,a0,a4
    80003c44:	fffff097          	auipc	ra,0xfffff
    80003c48:	a20080e7          	jalr	-1504(ra) # 80002664 <either_copyin>
    80003c4c:	07950263          	beq	a0,s9,80003cb0 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003c50:	8526                	mv	a0,s1
    80003c52:	00000097          	auipc	ra,0x0
    80003c56:	798080e7          	jalr	1944(ra) # 800043ea <log_write>
    brelse(bp);
    80003c5a:	8526                	mv	a0,s1
    80003c5c:	fffff097          	auipc	ra,0xfffff
    80003c60:	50a080e7          	jalr	1290(ra) # 80003166 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c64:	01498a3b          	addw	s4,s3,s4
    80003c68:	0129893b          	addw	s2,s3,s2
    80003c6c:	9aee                	add	s5,s5,s11
    80003c6e:	057a7663          	bgeu	s4,s7,80003cba <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c72:	000b2483          	lw	s1,0(s6)
    80003c76:	00a9559b          	srliw	a1,s2,0xa
    80003c7a:	855a                	mv	a0,s6
    80003c7c:	fffff097          	auipc	ra,0xfffff
    80003c80:	7aa080e7          	jalr	1962(ra) # 80003426 <bmap>
    80003c84:	0005059b          	sext.w	a1,a0
    80003c88:	8526                	mv	a0,s1
    80003c8a:	fffff097          	auipc	ra,0xfffff
    80003c8e:	3ac080e7          	jalr	940(ra) # 80003036 <bread>
    80003c92:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c94:	3ff97713          	andi	a4,s2,1023
    80003c98:	40ed07bb          	subw	a5,s10,a4
    80003c9c:	414b86bb          	subw	a3,s7,s4
    80003ca0:	89be                	mv	s3,a5
    80003ca2:	2781                	sext.w	a5,a5
    80003ca4:	0006861b          	sext.w	a2,a3
    80003ca8:	f8f674e3          	bgeu	a2,a5,80003c30 <writei+0x4c>
    80003cac:	89b6                	mv	s3,a3
    80003cae:	b749                	j	80003c30 <writei+0x4c>
      brelse(bp);
    80003cb0:	8526                	mv	a0,s1
    80003cb2:	fffff097          	auipc	ra,0xfffff
    80003cb6:	4b4080e7          	jalr	1204(ra) # 80003166 <brelse>
  }

  if(off > ip->size)
    80003cba:	04cb2783          	lw	a5,76(s6)
    80003cbe:	0127f463          	bgeu	a5,s2,80003cc6 <writei+0xe2>
    ip->size = off;
    80003cc2:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003cc6:	855a                	mv	a0,s6
    80003cc8:	00000097          	auipc	ra,0x0
    80003ccc:	aa4080e7          	jalr	-1372(ra) # 8000376c <iupdate>

  return tot;
    80003cd0:	000a051b          	sext.w	a0,s4
}
    80003cd4:	70a6                	ld	ra,104(sp)
    80003cd6:	7406                	ld	s0,96(sp)
    80003cd8:	64e6                	ld	s1,88(sp)
    80003cda:	6946                	ld	s2,80(sp)
    80003cdc:	69a6                	ld	s3,72(sp)
    80003cde:	6a06                	ld	s4,64(sp)
    80003ce0:	7ae2                	ld	s5,56(sp)
    80003ce2:	7b42                	ld	s6,48(sp)
    80003ce4:	7ba2                	ld	s7,40(sp)
    80003ce6:	7c02                	ld	s8,32(sp)
    80003ce8:	6ce2                	ld	s9,24(sp)
    80003cea:	6d42                	ld	s10,16(sp)
    80003cec:	6da2                	ld	s11,8(sp)
    80003cee:	6165                	addi	sp,sp,112
    80003cf0:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cf2:	8a5e                	mv	s4,s7
    80003cf4:	bfc9                	j	80003cc6 <writei+0xe2>
    return -1;
    80003cf6:	557d                	li	a0,-1
}
    80003cf8:	8082                	ret
    return -1;
    80003cfa:	557d                	li	a0,-1
    80003cfc:	bfe1                	j	80003cd4 <writei+0xf0>
    return -1;
    80003cfe:	557d                	li	a0,-1
    80003d00:	bfd1                	j	80003cd4 <writei+0xf0>

0000000080003d02 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003d02:	1141                	addi	sp,sp,-16
    80003d04:	e406                	sd	ra,8(sp)
    80003d06:	e022                	sd	s0,0(sp)
    80003d08:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003d0a:	4639                	li	a2,14
    80003d0c:	ffffd097          	auipc	ra,0xffffd
    80003d10:	090080e7          	jalr	144(ra) # 80000d9c <strncmp>
}
    80003d14:	60a2                	ld	ra,8(sp)
    80003d16:	6402                	ld	s0,0(sp)
    80003d18:	0141                	addi	sp,sp,16
    80003d1a:	8082                	ret

0000000080003d1c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003d1c:	7139                	addi	sp,sp,-64
    80003d1e:	fc06                	sd	ra,56(sp)
    80003d20:	f822                	sd	s0,48(sp)
    80003d22:	f426                	sd	s1,40(sp)
    80003d24:	f04a                	sd	s2,32(sp)
    80003d26:	ec4e                	sd	s3,24(sp)
    80003d28:	e852                	sd	s4,16(sp)
    80003d2a:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003d2c:	04451703          	lh	a4,68(a0)
    80003d30:	4785                	li	a5,1
    80003d32:	00f71a63          	bne	a4,a5,80003d46 <dirlookup+0x2a>
    80003d36:	892a                	mv	s2,a0
    80003d38:	89ae                	mv	s3,a1
    80003d3a:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d3c:	457c                	lw	a5,76(a0)
    80003d3e:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003d40:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d42:	e79d                	bnez	a5,80003d70 <dirlookup+0x54>
    80003d44:	a8a5                	j	80003dbc <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003d46:	00005517          	auipc	a0,0x5
    80003d4a:	94250513          	addi	a0,a0,-1726 # 80008688 <syscalls+0x1b0>
    80003d4e:	ffffc097          	auipc	ra,0xffffc
    80003d52:	7ec080e7          	jalr	2028(ra) # 8000053a <panic>
      panic("dirlookup read");
    80003d56:	00005517          	auipc	a0,0x5
    80003d5a:	94a50513          	addi	a0,a0,-1718 # 800086a0 <syscalls+0x1c8>
    80003d5e:	ffffc097          	auipc	ra,0xffffc
    80003d62:	7dc080e7          	jalr	2012(ra) # 8000053a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d66:	24c1                	addiw	s1,s1,16
    80003d68:	04c92783          	lw	a5,76(s2)
    80003d6c:	04f4f763          	bgeu	s1,a5,80003dba <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d70:	4741                	li	a4,16
    80003d72:	86a6                	mv	a3,s1
    80003d74:	fc040613          	addi	a2,s0,-64
    80003d78:	4581                	li	a1,0
    80003d7a:	854a                	mv	a0,s2
    80003d7c:	00000097          	auipc	ra,0x0
    80003d80:	d70080e7          	jalr	-656(ra) # 80003aec <readi>
    80003d84:	47c1                	li	a5,16
    80003d86:	fcf518e3          	bne	a0,a5,80003d56 <dirlookup+0x3a>
    if(de.inum == 0)
    80003d8a:	fc045783          	lhu	a5,-64(s0)
    80003d8e:	dfe1                	beqz	a5,80003d66 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d90:	fc240593          	addi	a1,s0,-62
    80003d94:	854e                	mv	a0,s3
    80003d96:	00000097          	auipc	ra,0x0
    80003d9a:	f6c080e7          	jalr	-148(ra) # 80003d02 <namecmp>
    80003d9e:	f561                	bnez	a0,80003d66 <dirlookup+0x4a>
      if(poff)
    80003da0:	000a0463          	beqz	s4,80003da8 <dirlookup+0x8c>
        *poff = off;
    80003da4:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003da8:	fc045583          	lhu	a1,-64(s0)
    80003dac:	00092503          	lw	a0,0(s2)
    80003db0:	fffff097          	auipc	ra,0xfffff
    80003db4:	752080e7          	jalr	1874(ra) # 80003502 <iget>
    80003db8:	a011                	j	80003dbc <dirlookup+0xa0>
  return 0;
    80003dba:	4501                	li	a0,0
}
    80003dbc:	70e2                	ld	ra,56(sp)
    80003dbe:	7442                	ld	s0,48(sp)
    80003dc0:	74a2                	ld	s1,40(sp)
    80003dc2:	7902                	ld	s2,32(sp)
    80003dc4:	69e2                	ld	s3,24(sp)
    80003dc6:	6a42                	ld	s4,16(sp)
    80003dc8:	6121                	addi	sp,sp,64
    80003dca:	8082                	ret

0000000080003dcc <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003dcc:	711d                	addi	sp,sp,-96
    80003dce:	ec86                	sd	ra,88(sp)
    80003dd0:	e8a2                	sd	s0,80(sp)
    80003dd2:	e4a6                	sd	s1,72(sp)
    80003dd4:	e0ca                	sd	s2,64(sp)
    80003dd6:	fc4e                	sd	s3,56(sp)
    80003dd8:	f852                	sd	s4,48(sp)
    80003dda:	f456                	sd	s5,40(sp)
    80003ddc:	f05a                	sd	s6,32(sp)
    80003dde:	ec5e                	sd	s7,24(sp)
    80003de0:	e862                	sd	s8,16(sp)
    80003de2:	e466                	sd	s9,8(sp)
    80003de4:	e06a                	sd	s10,0(sp)
    80003de6:	1080                	addi	s0,sp,96
    80003de8:	84aa                	mv	s1,a0
    80003dea:	8b2e                	mv	s6,a1
    80003dec:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003dee:	00054703          	lbu	a4,0(a0)
    80003df2:	02f00793          	li	a5,47
    80003df6:	02f70363          	beq	a4,a5,80003e1c <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003dfa:	ffffe097          	auipc	ra,0xffffe
    80003dfe:	c78080e7          	jalr	-904(ra) # 80001a72 <myproc>
    80003e02:	15053503          	ld	a0,336(a0)
    80003e06:	00000097          	auipc	ra,0x0
    80003e0a:	9f4080e7          	jalr	-1548(ra) # 800037fa <idup>
    80003e0e:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003e10:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003e14:	4cb5                	li	s9,13
  len = path - s;
    80003e16:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003e18:	4c05                	li	s8,1
    80003e1a:	a87d                	j	80003ed8 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003e1c:	4585                	li	a1,1
    80003e1e:	4505                	li	a0,1
    80003e20:	fffff097          	auipc	ra,0xfffff
    80003e24:	6e2080e7          	jalr	1762(ra) # 80003502 <iget>
    80003e28:	8a2a                	mv	s4,a0
    80003e2a:	b7dd                	j	80003e10 <namex+0x44>
      iunlockput(ip);
    80003e2c:	8552                	mv	a0,s4
    80003e2e:	00000097          	auipc	ra,0x0
    80003e32:	c6c080e7          	jalr	-916(ra) # 80003a9a <iunlockput>
      return 0;
    80003e36:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003e38:	8552                	mv	a0,s4
    80003e3a:	60e6                	ld	ra,88(sp)
    80003e3c:	6446                	ld	s0,80(sp)
    80003e3e:	64a6                	ld	s1,72(sp)
    80003e40:	6906                	ld	s2,64(sp)
    80003e42:	79e2                	ld	s3,56(sp)
    80003e44:	7a42                	ld	s4,48(sp)
    80003e46:	7aa2                	ld	s5,40(sp)
    80003e48:	7b02                	ld	s6,32(sp)
    80003e4a:	6be2                	ld	s7,24(sp)
    80003e4c:	6c42                	ld	s8,16(sp)
    80003e4e:	6ca2                	ld	s9,8(sp)
    80003e50:	6d02                	ld	s10,0(sp)
    80003e52:	6125                	addi	sp,sp,96
    80003e54:	8082                	ret
      iunlock(ip);
    80003e56:	8552                	mv	a0,s4
    80003e58:	00000097          	auipc	ra,0x0
    80003e5c:	aa2080e7          	jalr	-1374(ra) # 800038fa <iunlock>
      return ip;
    80003e60:	bfe1                	j	80003e38 <namex+0x6c>
      iunlockput(ip);
    80003e62:	8552                	mv	a0,s4
    80003e64:	00000097          	auipc	ra,0x0
    80003e68:	c36080e7          	jalr	-970(ra) # 80003a9a <iunlockput>
      return 0;
    80003e6c:	8a4e                	mv	s4,s3
    80003e6e:	b7e9                	j	80003e38 <namex+0x6c>
  len = path - s;
    80003e70:	40998633          	sub	a2,s3,s1
    80003e74:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80003e78:	09acd863          	bge	s9,s10,80003f08 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80003e7c:	4639                	li	a2,14
    80003e7e:	85a6                	mv	a1,s1
    80003e80:	8556                	mv	a0,s5
    80003e82:	ffffd097          	auipc	ra,0xffffd
    80003e86:	ea6080e7          	jalr	-346(ra) # 80000d28 <memmove>
    80003e8a:	84ce                	mv	s1,s3
  while(*path == '/')
    80003e8c:	0004c783          	lbu	a5,0(s1)
    80003e90:	01279763          	bne	a5,s2,80003e9e <namex+0xd2>
    path++;
    80003e94:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e96:	0004c783          	lbu	a5,0(s1)
    80003e9a:	ff278de3          	beq	a5,s2,80003e94 <namex+0xc8>
    ilock(ip);
    80003e9e:	8552                	mv	a0,s4
    80003ea0:	00000097          	auipc	ra,0x0
    80003ea4:	998080e7          	jalr	-1640(ra) # 80003838 <ilock>
    if(ip->type != T_DIR){
    80003ea8:	044a1783          	lh	a5,68(s4)
    80003eac:	f98790e3          	bne	a5,s8,80003e2c <namex+0x60>
    if(nameiparent && *path == '\0'){
    80003eb0:	000b0563          	beqz	s6,80003eba <namex+0xee>
    80003eb4:	0004c783          	lbu	a5,0(s1)
    80003eb8:	dfd9                	beqz	a5,80003e56 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003eba:	865e                	mv	a2,s7
    80003ebc:	85d6                	mv	a1,s5
    80003ebe:	8552                	mv	a0,s4
    80003ec0:	00000097          	auipc	ra,0x0
    80003ec4:	e5c080e7          	jalr	-420(ra) # 80003d1c <dirlookup>
    80003ec8:	89aa                	mv	s3,a0
    80003eca:	dd41                	beqz	a0,80003e62 <namex+0x96>
    iunlockput(ip);
    80003ecc:	8552                	mv	a0,s4
    80003ece:	00000097          	auipc	ra,0x0
    80003ed2:	bcc080e7          	jalr	-1076(ra) # 80003a9a <iunlockput>
    ip = next;
    80003ed6:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003ed8:	0004c783          	lbu	a5,0(s1)
    80003edc:	01279763          	bne	a5,s2,80003eea <namex+0x11e>
    path++;
    80003ee0:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003ee2:	0004c783          	lbu	a5,0(s1)
    80003ee6:	ff278de3          	beq	a5,s2,80003ee0 <namex+0x114>
  if(*path == 0)
    80003eea:	cb9d                	beqz	a5,80003f20 <namex+0x154>
  while(*path != '/' && *path != 0)
    80003eec:	0004c783          	lbu	a5,0(s1)
    80003ef0:	89a6                	mv	s3,s1
  len = path - s;
    80003ef2:	8d5e                	mv	s10,s7
    80003ef4:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003ef6:	01278963          	beq	a5,s2,80003f08 <namex+0x13c>
    80003efa:	dbbd                	beqz	a5,80003e70 <namex+0xa4>
    path++;
    80003efc:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003efe:	0009c783          	lbu	a5,0(s3)
    80003f02:	ff279ce3          	bne	a5,s2,80003efa <namex+0x12e>
    80003f06:	b7ad                	j	80003e70 <namex+0xa4>
    memmove(name, s, len);
    80003f08:	2601                	sext.w	a2,a2
    80003f0a:	85a6                	mv	a1,s1
    80003f0c:	8556                	mv	a0,s5
    80003f0e:	ffffd097          	auipc	ra,0xffffd
    80003f12:	e1a080e7          	jalr	-486(ra) # 80000d28 <memmove>
    name[len] = 0;
    80003f16:	9d56                	add	s10,s10,s5
    80003f18:	000d0023          	sb	zero,0(s10)
    80003f1c:	84ce                	mv	s1,s3
    80003f1e:	b7bd                	j	80003e8c <namex+0xc0>
  if(nameiparent){
    80003f20:	f00b0ce3          	beqz	s6,80003e38 <namex+0x6c>
    iput(ip);
    80003f24:	8552                	mv	a0,s4
    80003f26:	00000097          	auipc	ra,0x0
    80003f2a:	acc080e7          	jalr	-1332(ra) # 800039f2 <iput>
    return 0;
    80003f2e:	4a01                	li	s4,0
    80003f30:	b721                	j	80003e38 <namex+0x6c>

0000000080003f32 <dirlink>:
{
    80003f32:	7139                	addi	sp,sp,-64
    80003f34:	fc06                	sd	ra,56(sp)
    80003f36:	f822                	sd	s0,48(sp)
    80003f38:	f426                	sd	s1,40(sp)
    80003f3a:	f04a                	sd	s2,32(sp)
    80003f3c:	ec4e                	sd	s3,24(sp)
    80003f3e:	e852                	sd	s4,16(sp)
    80003f40:	0080                	addi	s0,sp,64
    80003f42:	892a                	mv	s2,a0
    80003f44:	8a2e                	mv	s4,a1
    80003f46:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003f48:	4601                	li	a2,0
    80003f4a:	00000097          	auipc	ra,0x0
    80003f4e:	dd2080e7          	jalr	-558(ra) # 80003d1c <dirlookup>
    80003f52:	e93d                	bnez	a0,80003fc8 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f54:	04c92483          	lw	s1,76(s2)
    80003f58:	c49d                	beqz	s1,80003f86 <dirlink+0x54>
    80003f5a:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f5c:	4741                	li	a4,16
    80003f5e:	86a6                	mv	a3,s1
    80003f60:	fc040613          	addi	a2,s0,-64
    80003f64:	4581                	li	a1,0
    80003f66:	854a                	mv	a0,s2
    80003f68:	00000097          	auipc	ra,0x0
    80003f6c:	b84080e7          	jalr	-1148(ra) # 80003aec <readi>
    80003f70:	47c1                	li	a5,16
    80003f72:	06f51163          	bne	a0,a5,80003fd4 <dirlink+0xa2>
    if(de.inum == 0)
    80003f76:	fc045783          	lhu	a5,-64(s0)
    80003f7a:	c791                	beqz	a5,80003f86 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f7c:	24c1                	addiw	s1,s1,16
    80003f7e:	04c92783          	lw	a5,76(s2)
    80003f82:	fcf4ede3          	bltu	s1,a5,80003f5c <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f86:	4639                	li	a2,14
    80003f88:	85d2                	mv	a1,s4
    80003f8a:	fc240513          	addi	a0,s0,-62
    80003f8e:	ffffd097          	auipc	ra,0xffffd
    80003f92:	e4a080e7          	jalr	-438(ra) # 80000dd8 <strncpy>
  de.inum = inum;
    80003f96:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f9a:	4741                	li	a4,16
    80003f9c:	86a6                	mv	a3,s1
    80003f9e:	fc040613          	addi	a2,s0,-64
    80003fa2:	4581                	li	a1,0
    80003fa4:	854a                	mv	a0,s2
    80003fa6:	00000097          	auipc	ra,0x0
    80003faa:	c3e080e7          	jalr	-962(ra) # 80003be4 <writei>
    80003fae:	872a                	mv	a4,a0
    80003fb0:	47c1                	li	a5,16
  return 0;
    80003fb2:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fb4:	02f71863          	bne	a4,a5,80003fe4 <dirlink+0xb2>
}
    80003fb8:	70e2                	ld	ra,56(sp)
    80003fba:	7442                	ld	s0,48(sp)
    80003fbc:	74a2                	ld	s1,40(sp)
    80003fbe:	7902                	ld	s2,32(sp)
    80003fc0:	69e2                	ld	s3,24(sp)
    80003fc2:	6a42                	ld	s4,16(sp)
    80003fc4:	6121                	addi	sp,sp,64
    80003fc6:	8082                	ret
    iput(ip);
    80003fc8:	00000097          	auipc	ra,0x0
    80003fcc:	a2a080e7          	jalr	-1494(ra) # 800039f2 <iput>
    return -1;
    80003fd0:	557d                	li	a0,-1
    80003fd2:	b7dd                	j	80003fb8 <dirlink+0x86>
      panic("dirlink read");
    80003fd4:	00004517          	auipc	a0,0x4
    80003fd8:	6dc50513          	addi	a0,a0,1756 # 800086b0 <syscalls+0x1d8>
    80003fdc:	ffffc097          	auipc	ra,0xffffc
    80003fe0:	55e080e7          	jalr	1374(ra) # 8000053a <panic>
    panic("dirlink");
    80003fe4:	00004517          	auipc	a0,0x4
    80003fe8:	7dc50513          	addi	a0,a0,2012 # 800087c0 <syscalls+0x2e8>
    80003fec:	ffffc097          	auipc	ra,0xffffc
    80003ff0:	54e080e7          	jalr	1358(ra) # 8000053a <panic>

0000000080003ff4 <namei>:

struct inode*
namei(char *path)
{
    80003ff4:	1101                	addi	sp,sp,-32
    80003ff6:	ec06                	sd	ra,24(sp)
    80003ff8:	e822                	sd	s0,16(sp)
    80003ffa:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003ffc:	fe040613          	addi	a2,s0,-32
    80004000:	4581                	li	a1,0
    80004002:	00000097          	auipc	ra,0x0
    80004006:	dca080e7          	jalr	-566(ra) # 80003dcc <namex>
}
    8000400a:	60e2                	ld	ra,24(sp)
    8000400c:	6442                	ld	s0,16(sp)
    8000400e:	6105                	addi	sp,sp,32
    80004010:	8082                	ret

0000000080004012 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004012:	1141                	addi	sp,sp,-16
    80004014:	e406                	sd	ra,8(sp)
    80004016:	e022                	sd	s0,0(sp)
    80004018:	0800                	addi	s0,sp,16
    8000401a:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000401c:	4585                	li	a1,1
    8000401e:	00000097          	auipc	ra,0x0
    80004022:	dae080e7          	jalr	-594(ra) # 80003dcc <namex>
}
    80004026:	60a2                	ld	ra,8(sp)
    80004028:	6402                	ld	s0,0(sp)
    8000402a:	0141                	addi	sp,sp,16
    8000402c:	8082                	ret

000000008000402e <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000402e:	1101                	addi	sp,sp,-32
    80004030:	ec06                	sd	ra,24(sp)
    80004032:	e822                	sd	s0,16(sp)
    80004034:	e426                	sd	s1,8(sp)
    80004036:	e04a                	sd	s2,0(sp)
    80004038:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000403a:	0001d917          	auipc	s2,0x1d
    8000403e:	74690913          	addi	s2,s2,1862 # 80021780 <log>
    80004042:	01892583          	lw	a1,24(s2)
    80004046:	02892503          	lw	a0,40(s2)
    8000404a:	fffff097          	auipc	ra,0xfffff
    8000404e:	fec080e7          	jalr	-20(ra) # 80003036 <bread>
    80004052:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004054:	02c92683          	lw	a3,44(s2)
    80004058:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000405a:	02d05863          	blez	a3,8000408a <write_head+0x5c>
    8000405e:	0001d797          	auipc	a5,0x1d
    80004062:	75278793          	addi	a5,a5,1874 # 800217b0 <log+0x30>
    80004066:	05c50713          	addi	a4,a0,92
    8000406a:	36fd                	addiw	a3,a3,-1
    8000406c:	02069613          	slli	a2,a3,0x20
    80004070:	01e65693          	srli	a3,a2,0x1e
    80004074:	0001d617          	auipc	a2,0x1d
    80004078:	74060613          	addi	a2,a2,1856 # 800217b4 <log+0x34>
    8000407c:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000407e:	4390                	lw	a2,0(a5)
    80004080:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004082:	0791                	addi	a5,a5,4
    80004084:	0711                	addi	a4,a4,4
    80004086:	fed79ce3          	bne	a5,a3,8000407e <write_head+0x50>
  }
  bwrite(buf);
    8000408a:	8526                	mv	a0,s1
    8000408c:	fffff097          	auipc	ra,0xfffff
    80004090:	09c080e7          	jalr	156(ra) # 80003128 <bwrite>
  brelse(buf);
    80004094:	8526                	mv	a0,s1
    80004096:	fffff097          	auipc	ra,0xfffff
    8000409a:	0d0080e7          	jalr	208(ra) # 80003166 <brelse>
}
    8000409e:	60e2                	ld	ra,24(sp)
    800040a0:	6442                	ld	s0,16(sp)
    800040a2:	64a2                	ld	s1,8(sp)
    800040a4:	6902                	ld	s2,0(sp)
    800040a6:	6105                	addi	sp,sp,32
    800040a8:	8082                	ret

00000000800040aa <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800040aa:	0001d797          	auipc	a5,0x1d
    800040ae:	7027a783          	lw	a5,1794(a5) # 800217ac <log+0x2c>
    800040b2:	0af05d63          	blez	a5,8000416c <install_trans+0xc2>
{
    800040b6:	7139                	addi	sp,sp,-64
    800040b8:	fc06                	sd	ra,56(sp)
    800040ba:	f822                	sd	s0,48(sp)
    800040bc:	f426                	sd	s1,40(sp)
    800040be:	f04a                	sd	s2,32(sp)
    800040c0:	ec4e                	sd	s3,24(sp)
    800040c2:	e852                	sd	s4,16(sp)
    800040c4:	e456                	sd	s5,8(sp)
    800040c6:	e05a                	sd	s6,0(sp)
    800040c8:	0080                	addi	s0,sp,64
    800040ca:	8b2a                	mv	s6,a0
    800040cc:	0001da97          	auipc	s5,0x1d
    800040d0:	6e4a8a93          	addi	s5,s5,1764 # 800217b0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040d4:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800040d6:	0001d997          	auipc	s3,0x1d
    800040da:	6aa98993          	addi	s3,s3,1706 # 80021780 <log>
    800040de:	a00d                	j	80004100 <install_trans+0x56>
    brelse(lbuf);
    800040e0:	854a                	mv	a0,s2
    800040e2:	fffff097          	auipc	ra,0xfffff
    800040e6:	084080e7          	jalr	132(ra) # 80003166 <brelse>
    brelse(dbuf);
    800040ea:	8526                	mv	a0,s1
    800040ec:	fffff097          	auipc	ra,0xfffff
    800040f0:	07a080e7          	jalr	122(ra) # 80003166 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040f4:	2a05                	addiw	s4,s4,1
    800040f6:	0a91                	addi	s5,s5,4
    800040f8:	02c9a783          	lw	a5,44(s3)
    800040fc:	04fa5e63          	bge	s4,a5,80004158 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004100:	0189a583          	lw	a1,24(s3)
    80004104:	014585bb          	addw	a1,a1,s4
    80004108:	2585                	addiw	a1,a1,1
    8000410a:	0289a503          	lw	a0,40(s3)
    8000410e:	fffff097          	auipc	ra,0xfffff
    80004112:	f28080e7          	jalr	-216(ra) # 80003036 <bread>
    80004116:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004118:	000aa583          	lw	a1,0(s5)
    8000411c:	0289a503          	lw	a0,40(s3)
    80004120:	fffff097          	auipc	ra,0xfffff
    80004124:	f16080e7          	jalr	-234(ra) # 80003036 <bread>
    80004128:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000412a:	40000613          	li	a2,1024
    8000412e:	05890593          	addi	a1,s2,88
    80004132:	05850513          	addi	a0,a0,88
    80004136:	ffffd097          	auipc	ra,0xffffd
    8000413a:	bf2080e7          	jalr	-1038(ra) # 80000d28 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000413e:	8526                	mv	a0,s1
    80004140:	fffff097          	auipc	ra,0xfffff
    80004144:	fe8080e7          	jalr	-24(ra) # 80003128 <bwrite>
    if(recovering == 0)
    80004148:	f80b1ce3          	bnez	s6,800040e0 <install_trans+0x36>
      bunpin(dbuf);
    8000414c:	8526                	mv	a0,s1
    8000414e:	fffff097          	auipc	ra,0xfffff
    80004152:	0f2080e7          	jalr	242(ra) # 80003240 <bunpin>
    80004156:	b769                	j	800040e0 <install_trans+0x36>
}
    80004158:	70e2                	ld	ra,56(sp)
    8000415a:	7442                	ld	s0,48(sp)
    8000415c:	74a2                	ld	s1,40(sp)
    8000415e:	7902                	ld	s2,32(sp)
    80004160:	69e2                	ld	s3,24(sp)
    80004162:	6a42                	ld	s4,16(sp)
    80004164:	6aa2                	ld	s5,8(sp)
    80004166:	6b02                	ld	s6,0(sp)
    80004168:	6121                	addi	sp,sp,64
    8000416a:	8082                	ret
    8000416c:	8082                	ret

000000008000416e <initlog>:
{
    8000416e:	7179                	addi	sp,sp,-48
    80004170:	f406                	sd	ra,40(sp)
    80004172:	f022                	sd	s0,32(sp)
    80004174:	ec26                	sd	s1,24(sp)
    80004176:	e84a                	sd	s2,16(sp)
    80004178:	e44e                	sd	s3,8(sp)
    8000417a:	1800                	addi	s0,sp,48
    8000417c:	892a                	mv	s2,a0
    8000417e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004180:	0001d497          	auipc	s1,0x1d
    80004184:	60048493          	addi	s1,s1,1536 # 80021780 <log>
    80004188:	00004597          	auipc	a1,0x4
    8000418c:	53858593          	addi	a1,a1,1336 # 800086c0 <syscalls+0x1e8>
    80004190:	8526                	mv	a0,s1
    80004192:	ffffd097          	auipc	ra,0xffffd
    80004196:	9ae080e7          	jalr	-1618(ra) # 80000b40 <initlock>
  log.start = sb->logstart;
    8000419a:	0149a583          	lw	a1,20(s3)
    8000419e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800041a0:	0109a783          	lw	a5,16(s3)
    800041a4:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800041a6:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800041aa:	854a                	mv	a0,s2
    800041ac:	fffff097          	auipc	ra,0xfffff
    800041b0:	e8a080e7          	jalr	-374(ra) # 80003036 <bread>
  log.lh.n = lh->n;
    800041b4:	4d34                	lw	a3,88(a0)
    800041b6:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800041b8:	02d05663          	blez	a3,800041e4 <initlog+0x76>
    800041bc:	05c50793          	addi	a5,a0,92
    800041c0:	0001d717          	auipc	a4,0x1d
    800041c4:	5f070713          	addi	a4,a4,1520 # 800217b0 <log+0x30>
    800041c8:	36fd                	addiw	a3,a3,-1
    800041ca:	02069613          	slli	a2,a3,0x20
    800041ce:	01e65693          	srli	a3,a2,0x1e
    800041d2:	06050613          	addi	a2,a0,96
    800041d6:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800041d8:	4390                	lw	a2,0(a5)
    800041da:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800041dc:	0791                	addi	a5,a5,4
    800041de:	0711                	addi	a4,a4,4
    800041e0:	fed79ce3          	bne	a5,a3,800041d8 <initlog+0x6a>
  brelse(buf);
    800041e4:	fffff097          	auipc	ra,0xfffff
    800041e8:	f82080e7          	jalr	-126(ra) # 80003166 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800041ec:	4505                	li	a0,1
    800041ee:	00000097          	auipc	ra,0x0
    800041f2:	ebc080e7          	jalr	-324(ra) # 800040aa <install_trans>
  log.lh.n = 0;
    800041f6:	0001d797          	auipc	a5,0x1d
    800041fa:	5a07ab23          	sw	zero,1462(a5) # 800217ac <log+0x2c>
  write_head(); // clear the log
    800041fe:	00000097          	auipc	ra,0x0
    80004202:	e30080e7          	jalr	-464(ra) # 8000402e <write_head>
}
    80004206:	70a2                	ld	ra,40(sp)
    80004208:	7402                	ld	s0,32(sp)
    8000420a:	64e2                	ld	s1,24(sp)
    8000420c:	6942                	ld	s2,16(sp)
    8000420e:	69a2                	ld	s3,8(sp)
    80004210:	6145                	addi	sp,sp,48
    80004212:	8082                	ret

0000000080004214 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004214:	1101                	addi	sp,sp,-32
    80004216:	ec06                	sd	ra,24(sp)
    80004218:	e822                	sd	s0,16(sp)
    8000421a:	e426                	sd	s1,8(sp)
    8000421c:	e04a                	sd	s2,0(sp)
    8000421e:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004220:	0001d517          	auipc	a0,0x1d
    80004224:	56050513          	addi	a0,a0,1376 # 80021780 <log>
    80004228:	ffffd097          	auipc	ra,0xffffd
    8000422c:	9a8080e7          	jalr	-1624(ra) # 80000bd0 <acquire>
  while(1){
    if(log.committing){
    80004230:	0001d497          	auipc	s1,0x1d
    80004234:	55048493          	addi	s1,s1,1360 # 80021780 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004238:	4979                	li	s2,30
    8000423a:	a039                	j	80004248 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000423c:	85a6                	mv	a1,s1
    8000423e:	8526                	mv	a0,s1
    80004240:	ffffe097          	auipc	ra,0xffffe
    80004244:	02a080e7          	jalr	42(ra) # 8000226a <sleep>
    if(log.committing){
    80004248:	50dc                	lw	a5,36(s1)
    8000424a:	fbed                	bnez	a5,8000423c <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000424c:	5098                	lw	a4,32(s1)
    8000424e:	2705                	addiw	a4,a4,1
    80004250:	0007069b          	sext.w	a3,a4
    80004254:	0027179b          	slliw	a5,a4,0x2
    80004258:	9fb9                	addw	a5,a5,a4
    8000425a:	0017979b          	slliw	a5,a5,0x1
    8000425e:	54d8                	lw	a4,44(s1)
    80004260:	9fb9                	addw	a5,a5,a4
    80004262:	00f95963          	bge	s2,a5,80004274 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004266:	85a6                	mv	a1,s1
    80004268:	8526                	mv	a0,s1
    8000426a:	ffffe097          	auipc	ra,0xffffe
    8000426e:	000080e7          	jalr	ra # 8000226a <sleep>
    80004272:	bfd9                	j	80004248 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004274:	0001d517          	auipc	a0,0x1d
    80004278:	50c50513          	addi	a0,a0,1292 # 80021780 <log>
    8000427c:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000427e:	ffffd097          	auipc	ra,0xffffd
    80004282:	a06080e7          	jalr	-1530(ra) # 80000c84 <release>
      break;
    }
  }
}
    80004286:	60e2                	ld	ra,24(sp)
    80004288:	6442                	ld	s0,16(sp)
    8000428a:	64a2                	ld	s1,8(sp)
    8000428c:	6902                	ld	s2,0(sp)
    8000428e:	6105                	addi	sp,sp,32
    80004290:	8082                	ret

0000000080004292 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004292:	7139                	addi	sp,sp,-64
    80004294:	fc06                	sd	ra,56(sp)
    80004296:	f822                	sd	s0,48(sp)
    80004298:	f426                	sd	s1,40(sp)
    8000429a:	f04a                	sd	s2,32(sp)
    8000429c:	ec4e                	sd	s3,24(sp)
    8000429e:	e852                	sd	s4,16(sp)
    800042a0:	e456                	sd	s5,8(sp)
    800042a2:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800042a4:	0001d497          	auipc	s1,0x1d
    800042a8:	4dc48493          	addi	s1,s1,1244 # 80021780 <log>
    800042ac:	8526                	mv	a0,s1
    800042ae:	ffffd097          	auipc	ra,0xffffd
    800042b2:	922080e7          	jalr	-1758(ra) # 80000bd0 <acquire>
  log.outstanding -= 1;
    800042b6:	509c                	lw	a5,32(s1)
    800042b8:	37fd                	addiw	a5,a5,-1
    800042ba:	0007891b          	sext.w	s2,a5
    800042be:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800042c0:	50dc                	lw	a5,36(s1)
    800042c2:	e7b9                	bnez	a5,80004310 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800042c4:	04091e63          	bnez	s2,80004320 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800042c8:	0001d497          	auipc	s1,0x1d
    800042cc:	4b848493          	addi	s1,s1,1208 # 80021780 <log>
    800042d0:	4785                	li	a5,1
    800042d2:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800042d4:	8526                	mv	a0,s1
    800042d6:	ffffd097          	auipc	ra,0xffffd
    800042da:	9ae080e7          	jalr	-1618(ra) # 80000c84 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800042de:	54dc                	lw	a5,44(s1)
    800042e0:	06f04763          	bgtz	a5,8000434e <end_op+0xbc>
    acquire(&log.lock);
    800042e4:	0001d497          	auipc	s1,0x1d
    800042e8:	49c48493          	addi	s1,s1,1180 # 80021780 <log>
    800042ec:	8526                	mv	a0,s1
    800042ee:	ffffd097          	auipc	ra,0xffffd
    800042f2:	8e2080e7          	jalr	-1822(ra) # 80000bd0 <acquire>
    log.committing = 0;
    800042f6:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800042fa:	8526                	mv	a0,s1
    800042fc:	ffffe097          	auipc	ra,0xffffe
    80004300:	0fa080e7          	jalr	250(ra) # 800023f6 <wakeup>
    release(&log.lock);
    80004304:	8526                	mv	a0,s1
    80004306:	ffffd097          	auipc	ra,0xffffd
    8000430a:	97e080e7          	jalr	-1666(ra) # 80000c84 <release>
}
    8000430e:	a03d                	j	8000433c <end_op+0xaa>
    panic("log.committing");
    80004310:	00004517          	auipc	a0,0x4
    80004314:	3b850513          	addi	a0,a0,952 # 800086c8 <syscalls+0x1f0>
    80004318:	ffffc097          	auipc	ra,0xffffc
    8000431c:	222080e7          	jalr	546(ra) # 8000053a <panic>
    wakeup(&log);
    80004320:	0001d497          	auipc	s1,0x1d
    80004324:	46048493          	addi	s1,s1,1120 # 80021780 <log>
    80004328:	8526                	mv	a0,s1
    8000432a:	ffffe097          	auipc	ra,0xffffe
    8000432e:	0cc080e7          	jalr	204(ra) # 800023f6 <wakeup>
  release(&log.lock);
    80004332:	8526                	mv	a0,s1
    80004334:	ffffd097          	auipc	ra,0xffffd
    80004338:	950080e7          	jalr	-1712(ra) # 80000c84 <release>
}
    8000433c:	70e2                	ld	ra,56(sp)
    8000433e:	7442                	ld	s0,48(sp)
    80004340:	74a2                	ld	s1,40(sp)
    80004342:	7902                	ld	s2,32(sp)
    80004344:	69e2                	ld	s3,24(sp)
    80004346:	6a42                	ld	s4,16(sp)
    80004348:	6aa2                	ld	s5,8(sp)
    8000434a:	6121                	addi	sp,sp,64
    8000434c:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000434e:	0001da97          	auipc	s5,0x1d
    80004352:	462a8a93          	addi	s5,s5,1122 # 800217b0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004356:	0001da17          	auipc	s4,0x1d
    8000435a:	42aa0a13          	addi	s4,s4,1066 # 80021780 <log>
    8000435e:	018a2583          	lw	a1,24(s4)
    80004362:	012585bb          	addw	a1,a1,s2
    80004366:	2585                	addiw	a1,a1,1
    80004368:	028a2503          	lw	a0,40(s4)
    8000436c:	fffff097          	auipc	ra,0xfffff
    80004370:	cca080e7          	jalr	-822(ra) # 80003036 <bread>
    80004374:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004376:	000aa583          	lw	a1,0(s5)
    8000437a:	028a2503          	lw	a0,40(s4)
    8000437e:	fffff097          	auipc	ra,0xfffff
    80004382:	cb8080e7          	jalr	-840(ra) # 80003036 <bread>
    80004386:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004388:	40000613          	li	a2,1024
    8000438c:	05850593          	addi	a1,a0,88
    80004390:	05848513          	addi	a0,s1,88
    80004394:	ffffd097          	auipc	ra,0xffffd
    80004398:	994080e7          	jalr	-1644(ra) # 80000d28 <memmove>
    bwrite(to);  // write the log
    8000439c:	8526                	mv	a0,s1
    8000439e:	fffff097          	auipc	ra,0xfffff
    800043a2:	d8a080e7          	jalr	-630(ra) # 80003128 <bwrite>
    brelse(from);
    800043a6:	854e                	mv	a0,s3
    800043a8:	fffff097          	auipc	ra,0xfffff
    800043ac:	dbe080e7          	jalr	-578(ra) # 80003166 <brelse>
    brelse(to);
    800043b0:	8526                	mv	a0,s1
    800043b2:	fffff097          	auipc	ra,0xfffff
    800043b6:	db4080e7          	jalr	-588(ra) # 80003166 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043ba:	2905                	addiw	s2,s2,1
    800043bc:	0a91                	addi	s5,s5,4
    800043be:	02ca2783          	lw	a5,44(s4)
    800043c2:	f8f94ee3          	blt	s2,a5,8000435e <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800043c6:	00000097          	auipc	ra,0x0
    800043ca:	c68080e7          	jalr	-920(ra) # 8000402e <write_head>
    install_trans(0); // Now install writes to home locations
    800043ce:	4501                	li	a0,0
    800043d0:	00000097          	auipc	ra,0x0
    800043d4:	cda080e7          	jalr	-806(ra) # 800040aa <install_trans>
    log.lh.n = 0;
    800043d8:	0001d797          	auipc	a5,0x1d
    800043dc:	3c07aa23          	sw	zero,980(a5) # 800217ac <log+0x2c>
    write_head();    // Erase the transaction from the log
    800043e0:	00000097          	auipc	ra,0x0
    800043e4:	c4e080e7          	jalr	-946(ra) # 8000402e <write_head>
    800043e8:	bdf5                	j	800042e4 <end_op+0x52>

00000000800043ea <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800043ea:	1101                	addi	sp,sp,-32
    800043ec:	ec06                	sd	ra,24(sp)
    800043ee:	e822                	sd	s0,16(sp)
    800043f0:	e426                	sd	s1,8(sp)
    800043f2:	e04a                	sd	s2,0(sp)
    800043f4:	1000                	addi	s0,sp,32
    800043f6:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800043f8:	0001d917          	auipc	s2,0x1d
    800043fc:	38890913          	addi	s2,s2,904 # 80021780 <log>
    80004400:	854a                	mv	a0,s2
    80004402:	ffffc097          	auipc	ra,0xffffc
    80004406:	7ce080e7          	jalr	1998(ra) # 80000bd0 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000440a:	02c92603          	lw	a2,44(s2)
    8000440e:	47f5                	li	a5,29
    80004410:	06c7c563          	blt	a5,a2,8000447a <log_write+0x90>
    80004414:	0001d797          	auipc	a5,0x1d
    80004418:	3887a783          	lw	a5,904(a5) # 8002179c <log+0x1c>
    8000441c:	37fd                	addiw	a5,a5,-1
    8000441e:	04f65e63          	bge	a2,a5,8000447a <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004422:	0001d797          	auipc	a5,0x1d
    80004426:	37e7a783          	lw	a5,894(a5) # 800217a0 <log+0x20>
    8000442a:	06f05063          	blez	a5,8000448a <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000442e:	4781                	li	a5,0
    80004430:	06c05563          	blez	a2,8000449a <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004434:	44cc                	lw	a1,12(s1)
    80004436:	0001d717          	auipc	a4,0x1d
    8000443a:	37a70713          	addi	a4,a4,890 # 800217b0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000443e:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004440:	4314                	lw	a3,0(a4)
    80004442:	04b68c63          	beq	a3,a1,8000449a <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004446:	2785                	addiw	a5,a5,1
    80004448:	0711                	addi	a4,a4,4
    8000444a:	fef61be3          	bne	a2,a5,80004440 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000444e:	0621                	addi	a2,a2,8
    80004450:	060a                	slli	a2,a2,0x2
    80004452:	0001d797          	auipc	a5,0x1d
    80004456:	32e78793          	addi	a5,a5,814 # 80021780 <log>
    8000445a:	97b2                	add	a5,a5,a2
    8000445c:	44d8                	lw	a4,12(s1)
    8000445e:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004460:	8526                	mv	a0,s1
    80004462:	fffff097          	auipc	ra,0xfffff
    80004466:	da2080e7          	jalr	-606(ra) # 80003204 <bpin>
    log.lh.n++;
    8000446a:	0001d717          	auipc	a4,0x1d
    8000446e:	31670713          	addi	a4,a4,790 # 80021780 <log>
    80004472:	575c                	lw	a5,44(a4)
    80004474:	2785                	addiw	a5,a5,1
    80004476:	d75c                	sw	a5,44(a4)
    80004478:	a82d                	j	800044b2 <log_write+0xc8>
    panic("too big a transaction");
    8000447a:	00004517          	auipc	a0,0x4
    8000447e:	25e50513          	addi	a0,a0,606 # 800086d8 <syscalls+0x200>
    80004482:	ffffc097          	auipc	ra,0xffffc
    80004486:	0b8080e7          	jalr	184(ra) # 8000053a <panic>
    panic("log_write outside of trans");
    8000448a:	00004517          	auipc	a0,0x4
    8000448e:	26650513          	addi	a0,a0,614 # 800086f0 <syscalls+0x218>
    80004492:	ffffc097          	auipc	ra,0xffffc
    80004496:	0a8080e7          	jalr	168(ra) # 8000053a <panic>
  log.lh.block[i] = b->blockno;
    8000449a:	00878693          	addi	a3,a5,8
    8000449e:	068a                	slli	a3,a3,0x2
    800044a0:	0001d717          	auipc	a4,0x1d
    800044a4:	2e070713          	addi	a4,a4,736 # 80021780 <log>
    800044a8:	9736                	add	a4,a4,a3
    800044aa:	44d4                	lw	a3,12(s1)
    800044ac:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800044ae:	faf609e3          	beq	a2,a5,80004460 <log_write+0x76>
  }
  release(&log.lock);
    800044b2:	0001d517          	auipc	a0,0x1d
    800044b6:	2ce50513          	addi	a0,a0,718 # 80021780 <log>
    800044ba:	ffffc097          	auipc	ra,0xffffc
    800044be:	7ca080e7          	jalr	1994(ra) # 80000c84 <release>
}
    800044c2:	60e2                	ld	ra,24(sp)
    800044c4:	6442                	ld	s0,16(sp)
    800044c6:	64a2                	ld	s1,8(sp)
    800044c8:	6902                	ld	s2,0(sp)
    800044ca:	6105                	addi	sp,sp,32
    800044cc:	8082                	ret

00000000800044ce <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800044ce:	1101                	addi	sp,sp,-32
    800044d0:	ec06                	sd	ra,24(sp)
    800044d2:	e822                	sd	s0,16(sp)
    800044d4:	e426                	sd	s1,8(sp)
    800044d6:	e04a                	sd	s2,0(sp)
    800044d8:	1000                	addi	s0,sp,32
    800044da:	84aa                	mv	s1,a0
    800044dc:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800044de:	00004597          	auipc	a1,0x4
    800044e2:	23258593          	addi	a1,a1,562 # 80008710 <syscalls+0x238>
    800044e6:	0521                	addi	a0,a0,8
    800044e8:	ffffc097          	auipc	ra,0xffffc
    800044ec:	658080e7          	jalr	1624(ra) # 80000b40 <initlock>
  lk->name = name;
    800044f0:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800044f4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044f8:	0204a423          	sw	zero,40(s1)
}
    800044fc:	60e2                	ld	ra,24(sp)
    800044fe:	6442                	ld	s0,16(sp)
    80004500:	64a2                	ld	s1,8(sp)
    80004502:	6902                	ld	s2,0(sp)
    80004504:	6105                	addi	sp,sp,32
    80004506:	8082                	ret

0000000080004508 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004508:	1101                	addi	sp,sp,-32
    8000450a:	ec06                	sd	ra,24(sp)
    8000450c:	e822                	sd	s0,16(sp)
    8000450e:	e426                	sd	s1,8(sp)
    80004510:	e04a                	sd	s2,0(sp)
    80004512:	1000                	addi	s0,sp,32
    80004514:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004516:	00850913          	addi	s2,a0,8
    8000451a:	854a                	mv	a0,s2
    8000451c:	ffffc097          	auipc	ra,0xffffc
    80004520:	6b4080e7          	jalr	1716(ra) # 80000bd0 <acquire>
  while (lk->locked) {
    80004524:	409c                	lw	a5,0(s1)
    80004526:	cb89                	beqz	a5,80004538 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004528:	85ca                	mv	a1,s2
    8000452a:	8526                	mv	a0,s1
    8000452c:	ffffe097          	auipc	ra,0xffffe
    80004530:	d3e080e7          	jalr	-706(ra) # 8000226a <sleep>
  while (lk->locked) {
    80004534:	409c                	lw	a5,0(s1)
    80004536:	fbed                	bnez	a5,80004528 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004538:	4785                	li	a5,1
    8000453a:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000453c:	ffffd097          	auipc	ra,0xffffd
    80004540:	536080e7          	jalr	1334(ra) # 80001a72 <myproc>
    80004544:	591c                	lw	a5,48(a0)
    80004546:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004548:	854a                	mv	a0,s2
    8000454a:	ffffc097          	auipc	ra,0xffffc
    8000454e:	73a080e7          	jalr	1850(ra) # 80000c84 <release>
}
    80004552:	60e2                	ld	ra,24(sp)
    80004554:	6442                	ld	s0,16(sp)
    80004556:	64a2                	ld	s1,8(sp)
    80004558:	6902                	ld	s2,0(sp)
    8000455a:	6105                	addi	sp,sp,32
    8000455c:	8082                	ret

000000008000455e <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000455e:	1101                	addi	sp,sp,-32
    80004560:	ec06                	sd	ra,24(sp)
    80004562:	e822                	sd	s0,16(sp)
    80004564:	e426                	sd	s1,8(sp)
    80004566:	e04a                	sd	s2,0(sp)
    80004568:	1000                	addi	s0,sp,32
    8000456a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000456c:	00850913          	addi	s2,a0,8
    80004570:	854a                	mv	a0,s2
    80004572:	ffffc097          	auipc	ra,0xffffc
    80004576:	65e080e7          	jalr	1630(ra) # 80000bd0 <acquire>
  lk->locked = 0;
    8000457a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000457e:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004582:	8526                	mv	a0,s1
    80004584:	ffffe097          	auipc	ra,0xffffe
    80004588:	e72080e7          	jalr	-398(ra) # 800023f6 <wakeup>
  release(&lk->lk);
    8000458c:	854a                	mv	a0,s2
    8000458e:	ffffc097          	auipc	ra,0xffffc
    80004592:	6f6080e7          	jalr	1782(ra) # 80000c84 <release>
}
    80004596:	60e2                	ld	ra,24(sp)
    80004598:	6442                	ld	s0,16(sp)
    8000459a:	64a2                	ld	s1,8(sp)
    8000459c:	6902                	ld	s2,0(sp)
    8000459e:	6105                	addi	sp,sp,32
    800045a0:	8082                	ret

00000000800045a2 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800045a2:	7179                	addi	sp,sp,-48
    800045a4:	f406                	sd	ra,40(sp)
    800045a6:	f022                	sd	s0,32(sp)
    800045a8:	ec26                	sd	s1,24(sp)
    800045aa:	e84a                	sd	s2,16(sp)
    800045ac:	e44e                	sd	s3,8(sp)
    800045ae:	1800                	addi	s0,sp,48
    800045b0:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800045b2:	00850913          	addi	s2,a0,8
    800045b6:	854a                	mv	a0,s2
    800045b8:	ffffc097          	auipc	ra,0xffffc
    800045bc:	618080e7          	jalr	1560(ra) # 80000bd0 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800045c0:	409c                	lw	a5,0(s1)
    800045c2:	ef99                	bnez	a5,800045e0 <holdingsleep+0x3e>
    800045c4:	4481                	li	s1,0
  release(&lk->lk);
    800045c6:	854a                	mv	a0,s2
    800045c8:	ffffc097          	auipc	ra,0xffffc
    800045cc:	6bc080e7          	jalr	1724(ra) # 80000c84 <release>
  return r;
}
    800045d0:	8526                	mv	a0,s1
    800045d2:	70a2                	ld	ra,40(sp)
    800045d4:	7402                	ld	s0,32(sp)
    800045d6:	64e2                	ld	s1,24(sp)
    800045d8:	6942                	ld	s2,16(sp)
    800045da:	69a2                	ld	s3,8(sp)
    800045dc:	6145                	addi	sp,sp,48
    800045de:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800045e0:	0284a983          	lw	s3,40(s1)
    800045e4:	ffffd097          	auipc	ra,0xffffd
    800045e8:	48e080e7          	jalr	1166(ra) # 80001a72 <myproc>
    800045ec:	5904                	lw	s1,48(a0)
    800045ee:	413484b3          	sub	s1,s1,s3
    800045f2:	0014b493          	seqz	s1,s1
    800045f6:	bfc1                	j	800045c6 <holdingsleep+0x24>

00000000800045f8 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800045f8:	1141                	addi	sp,sp,-16
    800045fa:	e406                	sd	ra,8(sp)
    800045fc:	e022                	sd	s0,0(sp)
    800045fe:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004600:	00004597          	auipc	a1,0x4
    80004604:	12058593          	addi	a1,a1,288 # 80008720 <syscalls+0x248>
    80004608:	0001d517          	auipc	a0,0x1d
    8000460c:	2c050513          	addi	a0,a0,704 # 800218c8 <ftable>
    80004610:	ffffc097          	auipc	ra,0xffffc
    80004614:	530080e7          	jalr	1328(ra) # 80000b40 <initlock>
}
    80004618:	60a2                	ld	ra,8(sp)
    8000461a:	6402                	ld	s0,0(sp)
    8000461c:	0141                	addi	sp,sp,16
    8000461e:	8082                	ret

0000000080004620 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004620:	1101                	addi	sp,sp,-32
    80004622:	ec06                	sd	ra,24(sp)
    80004624:	e822                	sd	s0,16(sp)
    80004626:	e426                	sd	s1,8(sp)
    80004628:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000462a:	0001d517          	auipc	a0,0x1d
    8000462e:	29e50513          	addi	a0,a0,670 # 800218c8 <ftable>
    80004632:	ffffc097          	auipc	ra,0xffffc
    80004636:	59e080e7          	jalr	1438(ra) # 80000bd0 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000463a:	0001d497          	auipc	s1,0x1d
    8000463e:	2a648493          	addi	s1,s1,678 # 800218e0 <ftable+0x18>
    80004642:	0001e717          	auipc	a4,0x1e
    80004646:	23e70713          	addi	a4,a4,574 # 80022880 <ftable+0xfb8>
    if(f->ref == 0){
    8000464a:	40dc                	lw	a5,4(s1)
    8000464c:	cf99                	beqz	a5,8000466a <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000464e:	02848493          	addi	s1,s1,40
    80004652:	fee49ce3          	bne	s1,a4,8000464a <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004656:	0001d517          	auipc	a0,0x1d
    8000465a:	27250513          	addi	a0,a0,626 # 800218c8 <ftable>
    8000465e:	ffffc097          	auipc	ra,0xffffc
    80004662:	626080e7          	jalr	1574(ra) # 80000c84 <release>
  return 0;
    80004666:	4481                	li	s1,0
    80004668:	a819                	j	8000467e <filealloc+0x5e>
      f->ref = 1;
    8000466a:	4785                	li	a5,1
    8000466c:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000466e:	0001d517          	auipc	a0,0x1d
    80004672:	25a50513          	addi	a0,a0,602 # 800218c8 <ftable>
    80004676:	ffffc097          	auipc	ra,0xffffc
    8000467a:	60e080e7          	jalr	1550(ra) # 80000c84 <release>
}
    8000467e:	8526                	mv	a0,s1
    80004680:	60e2                	ld	ra,24(sp)
    80004682:	6442                	ld	s0,16(sp)
    80004684:	64a2                	ld	s1,8(sp)
    80004686:	6105                	addi	sp,sp,32
    80004688:	8082                	ret

000000008000468a <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000468a:	1101                	addi	sp,sp,-32
    8000468c:	ec06                	sd	ra,24(sp)
    8000468e:	e822                	sd	s0,16(sp)
    80004690:	e426                	sd	s1,8(sp)
    80004692:	1000                	addi	s0,sp,32
    80004694:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004696:	0001d517          	auipc	a0,0x1d
    8000469a:	23250513          	addi	a0,a0,562 # 800218c8 <ftable>
    8000469e:	ffffc097          	auipc	ra,0xffffc
    800046a2:	532080e7          	jalr	1330(ra) # 80000bd0 <acquire>
  if(f->ref < 1)
    800046a6:	40dc                	lw	a5,4(s1)
    800046a8:	02f05263          	blez	a5,800046cc <filedup+0x42>
    panic("filedup");
  f->ref++;
    800046ac:	2785                	addiw	a5,a5,1
    800046ae:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800046b0:	0001d517          	auipc	a0,0x1d
    800046b4:	21850513          	addi	a0,a0,536 # 800218c8 <ftable>
    800046b8:	ffffc097          	auipc	ra,0xffffc
    800046bc:	5cc080e7          	jalr	1484(ra) # 80000c84 <release>
  return f;
}
    800046c0:	8526                	mv	a0,s1
    800046c2:	60e2                	ld	ra,24(sp)
    800046c4:	6442                	ld	s0,16(sp)
    800046c6:	64a2                	ld	s1,8(sp)
    800046c8:	6105                	addi	sp,sp,32
    800046ca:	8082                	ret
    panic("filedup");
    800046cc:	00004517          	auipc	a0,0x4
    800046d0:	05c50513          	addi	a0,a0,92 # 80008728 <syscalls+0x250>
    800046d4:	ffffc097          	auipc	ra,0xffffc
    800046d8:	e66080e7          	jalr	-410(ra) # 8000053a <panic>

00000000800046dc <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800046dc:	7139                	addi	sp,sp,-64
    800046de:	fc06                	sd	ra,56(sp)
    800046e0:	f822                	sd	s0,48(sp)
    800046e2:	f426                	sd	s1,40(sp)
    800046e4:	f04a                	sd	s2,32(sp)
    800046e6:	ec4e                	sd	s3,24(sp)
    800046e8:	e852                	sd	s4,16(sp)
    800046ea:	e456                	sd	s5,8(sp)
    800046ec:	0080                	addi	s0,sp,64
    800046ee:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800046f0:	0001d517          	auipc	a0,0x1d
    800046f4:	1d850513          	addi	a0,a0,472 # 800218c8 <ftable>
    800046f8:	ffffc097          	auipc	ra,0xffffc
    800046fc:	4d8080e7          	jalr	1240(ra) # 80000bd0 <acquire>
  if(f->ref < 1)
    80004700:	40dc                	lw	a5,4(s1)
    80004702:	06f05163          	blez	a5,80004764 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004706:	37fd                	addiw	a5,a5,-1
    80004708:	0007871b          	sext.w	a4,a5
    8000470c:	c0dc                	sw	a5,4(s1)
    8000470e:	06e04363          	bgtz	a4,80004774 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004712:	0004a903          	lw	s2,0(s1)
    80004716:	0094ca83          	lbu	s5,9(s1)
    8000471a:	0104ba03          	ld	s4,16(s1)
    8000471e:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004722:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004726:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000472a:	0001d517          	auipc	a0,0x1d
    8000472e:	19e50513          	addi	a0,a0,414 # 800218c8 <ftable>
    80004732:	ffffc097          	auipc	ra,0xffffc
    80004736:	552080e7          	jalr	1362(ra) # 80000c84 <release>

  if(ff.type == FD_PIPE){
    8000473a:	4785                	li	a5,1
    8000473c:	04f90d63          	beq	s2,a5,80004796 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004740:	3979                	addiw	s2,s2,-2
    80004742:	4785                	li	a5,1
    80004744:	0527e063          	bltu	a5,s2,80004784 <fileclose+0xa8>
    begin_op();
    80004748:	00000097          	auipc	ra,0x0
    8000474c:	acc080e7          	jalr	-1332(ra) # 80004214 <begin_op>
    iput(ff.ip);
    80004750:	854e                	mv	a0,s3
    80004752:	fffff097          	auipc	ra,0xfffff
    80004756:	2a0080e7          	jalr	672(ra) # 800039f2 <iput>
    end_op();
    8000475a:	00000097          	auipc	ra,0x0
    8000475e:	b38080e7          	jalr	-1224(ra) # 80004292 <end_op>
    80004762:	a00d                	j	80004784 <fileclose+0xa8>
    panic("fileclose");
    80004764:	00004517          	auipc	a0,0x4
    80004768:	fcc50513          	addi	a0,a0,-52 # 80008730 <syscalls+0x258>
    8000476c:	ffffc097          	auipc	ra,0xffffc
    80004770:	dce080e7          	jalr	-562(ra) # 8000053a <panic>
    release(&ftable.lock);
    80004774:	0001d517          	auipc	a0,0x1d
    80004778:	15450513          	addi	a0,a0,340 # 800218c8 <ftable>
    8000477c:	ffffc097          	auipc	ra,0xffffc
    80004780:	508080e7          	jalr	1288(ra) # 80000c84 <release>
  }
}
    80004784:	70e2                	ld	ra,56(sp)
    80004786:	7442                	ld	s0,48(sp)
    80004788:	74a2                	ld	s1,40(sp)
    8000478a:	7902                	ld	s2,32(sp)
    8000478c:	69e2                	ld	s3,24(sp)
    8000478e:	6a42                	ld	s4,16(sp)
    80004790:	6aa2                	ld	s5,8(sp)
    80004792:	6121                	addi	sp,sp,64
    80004794:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004796:	85d6                	mv	a1,s5
    80004798:	8552                	mv	a0,s4
    8000479a:	00000097          	auipc	ra,0x0
    8000479e:	34c080e7          	jalr	844(ra) # 80004ae6 <pipeclose>
    800047a2:	b7cd                	j	80004784 <fileclose+0xa8>

00000000800047a4 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800047a4:	715d                	addi	sp,sp,-80
    800047a6:	e486                	sd	ra,72(sp)
    800047a8:	e0a2                	sd	s0,64(sp)
    800047aa:	fc26                	sd	s1,56(sp)
    800047ac:	f84a                	sd	s2,48(sp)
    800047ae:	f44e                	sd	s3,40(sp)
    800047b0:	0880                	addi	s0,sp,80
    800047b2:	84aa                	mv	s1,a0
    800047b4:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800047b6:	ffffd097          	auipc	ra,0xffffd
    800047ba:	2bc080e7          	jalr	700(ra) # 80001a72 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800047be:	409c                	lw	a5,0(s1)
    800047c0:	37f9                	addiw	a5,a5,-2
    800047c2:	4705                	li	a4,1
    800047c4:	04f76763          	bltu	a4,a5,80004812 <filestat+0x6e>
    800047c8:	892a                	mv	s2,a0
    ilock(f->ip);
    800047ca:	6c88                	ld	a0,24(s1)
    800047cc:	fffff097          	auipc	ra,0xfffff
    800047d0:	06c080e7          	jalr	108(ra) # 80003838 <ilock>
    stati(f->ip, &st);
    800047d4:	fb840593          	addi	a1,s0,-72
    800047d8:	6c88                	ld	a0,24(s1)
    800047da:	fffff097          	auipc	ra,0xfffff
    800047de:	2e8080e7          	jalr	744(ra) # 80003ac2 <stati>
    iunlock(f->ip);
    800047e2:	6c88                	ld	a0,24(s1)
    800047e4:	fffff097          	auipc	ra,0xfffff
    800047e8:	116080e7          	jalr	278(ra) # 800038fa <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800047ec:	46e1                	li	a3,24
    800047ee:	fb840613          	addi	a2,s0,-72
    800047f2:	85ce                	mv	a1,s3
    800047f4:	05093503          	ld	a0,80(s2)
    800047f8:	ffffd097          	auipc	ra,0xffffd
    800047fc:	e62080e7          	jalr	-414(ra) # 8000165a <copyout>
    80004800:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004804:	60a6                	ld	ra,72(sp)
    80004806:	6406                	ld	s0,64(sp)
    80004808:	74e2                	ld	s1,56(sp)
    8000480a:	7942                	ld	s2,48(sp)
    8000480c:	79a2                	ld	s3,40(sp)
    8000480e:	6161                	addi	sp,sp,80
    80004810:	8082                	ret
  return -1;
    80004812:	557d                	li	a0,-1
    80004814:	bfc5                	j	80004804 <filestat+0x60>

0000000080004816 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004816:	7179                	addi	sp,sp,-48
    80004818:	f406                	sd	ra,40(sp)
    8000481a:	f022                	sd	s0,32(sp)
    8000481c:	ec26                	sd	s1,24(sp)
    8000481e:	e84a                	sd	s2,16(sp)
    80004820:	e44e                	sd	s3,8(sp)
    80004822:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004824:	00854783          	lbu	a5,8(a0)
    80004828:	c3d5                	beqz	a5,800048cc <fileread+0xb6>
    8000482a:	84aa                	mv	s1,a0
    8000482c:	89ae                	mv	s3,a1
    8000482e:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004830:	411c                	lw	a5,0(a0)
    80004832:	4705                	li	a4,1
    80004834:	04e78963          	beq	a5,a4,80004886 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004838:	470d                	li	a4,3
    8000483a:	04e78d63          	beq	a5,a4,80004894 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000483e:	4709                	li	a4,2
    80004840:	06e79e63          	bne	a5,a4,800048bc <fileread+0xa6>
    ilock(f->ip);
    80004844:	6d08                	ld	a0,24(a0)
    80004846:	fffff097          	auipc	ra,0xfffff
    8000484a:	ff2080e7          	jalr	-14(ra) # 80003838 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000484e:	874a                	mv	a4,s2
    80004850:	5094                	lw	a3,32(s1)
    80004852:	864e                	mv	a2,s3
    80004854:	4585                	li	a1,1
    80004856:	6c88                	ld	a0,24(s1)
    80004858:	fffff097          	auipc	ra,0xfffff
    8000485c:	294080e7          	jalr	660(ra) # 80003aec <readi>
    80004860:	892a                	mv	s2,a0
    80004862:	00a05563          	blez	a0,8000486c <fileread+0x56>
      f->off += r;
    80004866:	509c                	lw	a5,32(s1)
    80004868:	9fa9                	addw	a5,a5,a0
    8000486a:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000486c:	6c88                	ld	a0,24(s1)
    8000486e:	fffff097          	auipc	ra,0xfffff
    80004872:	08c080e7          	jalr	140(ra) # 800038fa <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004876:	854a                	mv	a0,s2
    80004878:	70a2                	ld	ra,40(sp)
    8000487a:	7402                	ld	s0,32(sp)
    8000487c:	64e2                	ld	s1,24(sp)
    8000487e:	6942                	ld	s2,16(sp)
    80004880:	69a2                	ld	s3,8(sp)
    80004882:	6145                	addi	sp,sp,48
    80004884:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004886:	6908                	ld	a0,16(a0)
    80004888:	00000097          	auipc	ra,0x0
    8000488c:	3c0080e7          	jalr	960(ra) # 80004c48 <piperead>
    80004890:	892a                	mv	s2,a0
    80004892:	b7d5                	j	80004876 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004894:	02451783          	lh	a5,36(a0)
    80004898:	03079693          	slli	a3,a5,0x30
    8000489c:	92c1                	srli	a3,a3,0x30
    8000489e:	4725                	li	a4,9
    800048a0:	02d76863          	bltu	a4,a3,800048d0 <fileread+0xba>
    800048a4:	0792                	slli	a5,a5,0x4
    800048a6:	0001d717          	auipc	a4,0x1d
    800048aa:	f8270713          	addi	a4,a4,-126 # 80021828 <devsw>
    800048ae:	97ba                	add	a5,a5,a4
    800048b0:	639c                	ld	a5,0(a5)
    800048b2:	c38d                	beqz	a5,800048d4 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800048b4:	4505                	li	a0,1
    800048b6:	9782                	jalr	a5
    800048b8:	892a                	mv	s2,a0
    800048ba:	bf75                	j	80004876 <fileread+0x60>
    panic("fileread");
    800048bc:	00004517          	auipc	a0,0x4
    800048c0:	e8450513          	addi	a0,a0,-380 # 80008740 <syscalls+0x268>
    800048c4:	ffffc097          	auipc	ra,0xffffc
    800048c8:	c76080e7          	jalr	-906(ra) # 8000053a <panic>
    return -1;
    800048cc:	597d                	li	s2,-1
    800048ce:	b765                	j	80004876 <fileread+0x60>
      return -1;
    800048d0:	597d                	li	s2,-1
    800048d2:	b755                	j	80004876 <fileread+0x60>
    800048d4:	597d                	li	s2,-1
    800048d6:	b745                	j	80004876 <fileread+0x60>

00000000800048d8 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800048d8:	715d                	addi	sp,sp,-80
    800048da:	e486                	sd	ra,72(sp)
    800048dc:	e0a2                	sd	s0,64(sp)
    800048de:	fc26                	sd	s1,56(sp)
    800048e0:	f84a                	sd	s2,48(sp)
    800048e2:	f44e                	sd	s3,40(sp)
    800048e4:	f052                	sd	s4,32(sp)
    800048e6:	ec56                	sd	s5,24(sp)
    800048e8:	e85a                	sd	s6,16(sp)
    800048ea:	e45e                	sd	s7,8(sp)
    800048ec:	e062                	sd	s8,0(sp)
    800048ee:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800048f0:	00954783          	lbu	a5,9(a0)
    800048f4:	10078663          	beqz	a5,80004a00 <filewrite+0x128>
    800048f8:	892a                	mv	s2,a0
    800048fa:	8b2e                	mv	s6,a1
    800048fc:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800048fe:	411c                	lw	a5,0(a0)
    80004900:	4705                	li	a4,1
    80004902:	02e78263          	beq	a5,a4,80004926 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004906:	470d                	li	a4,3
    80004908:	02e78663          	beq	a5,a4,80004934 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000490c:	4709                	li	a4,2
    8000490e:	0ee79163          	bne	a5,a4,800049f0 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004912:	0ac05d63          	blez	a2,800049cc <filewrite+0xf4>
    int i = 0;
    80004916:	4981                	li	s3,0
    80004918:	6b85                	lui	s7,0x1
    8000491a:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    8000491e:	6c05                	lui	s8,0x1
    80004920:	c00c0c1b          	addiw	s8,s8,-1024
    80004924:	a861                	j	800049bc <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004926:	6908                	ld	a0,16(a0)
    80004928:	00000097          	auipc	ra,0x0
    8000492c:	22e080e7          	jalr	558(ra) # 80004b56 <pipewrite>
    80004930:	8a2a                	mv	s4,a0
    80004932:	a045                	j	800049d2 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004934:	02451783          	lh	a5,36(a0)
    80004938:	03079693          	slli	a3,a5,0x30
    8000493c:	92c1                	srli	a3,a3,0x30
    8000493e:	4725                	li	a4,9
    80004940:	0cd76263          	bltu	a4,a3,80004a04 <filewrite+0x12c>
    80004944:	0792                	slli	a5,a5,0x4
    80004946:	0001d717          	auipc	a4,0x1d
    8000494a:	ee270713          	addi	a4,a4,-286 # 80021828 <devsw>
    8000494e:	97ba                	add	a5,a5,a4
    80004950:	679c                	ld	a5,8(a5)
    80004952:	cbdd                	beqz	a5,80004a08 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004954:	4505                	li	a0,1
    80004956:	9782                	jalr	a5
    80004958:	8a2a                	mv	s4,a0
    8000495a:	a8a5                	j	800049d2 <filewrite+0xfa>
    8000495c:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004960:	00000097          	auipc	ra,0x0
    80004964:	8b4080e7          	jalr	-1868(ra) # 80004214 <begin_op>
      ilock(f->ip);
    80004968:	01893503          	ld	a0,24(s2)
    8000496c:	fffff097          	auipc	ra,0xfffff
    80004970:	ecc080e7          	jalr	-308(ra) # 80003838 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004974:	8756                	mv	a4,s5
    80004976:	02092683          	lw	a3,32(s2)
    8000497a:	01698633          	add	a2,s3,s6
    8000497e:	4585                	li	a1,1
    80004980:	01893503          	ld	a0,24(s2)
    80004984:	fffff097          	auipc	ra,0xfffff
    80004988:	260080e7          	jalr	608(ra) # 80003be4 <writei>
    8000498c:	84aa                	mv	s1,a0
    8000498e:	00a05763          	blez	a0,8000499c <filewrite+0xc4>
        f->off += r;
    80004992:	02092783          	lw	a5,32(s2)
    80004996:	9fa9                	addw	a5,a5,a0
    80004998:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000499c:	01893503          	ld	a0,24(s2)
    800049a0:	fffff097          	auipc	ra,0xfffff
    800049a4:	f5a080e7          	jalr	-166(ra) # 800038fa <iunlock>
      end_op();
    800049a8:	00000097          	auipc	ra,0x0
    800049ac:	8ea080e7          	jalr	-1814(ra) # 80004292 <end_op>

      if(r != n1){
    800049b0:	009a9f63          	bne	s5,s1,800049ce <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800049b4:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800049b8:	0149db63          	bge	s3,s4,800049ce <filewrite+0xf6>
      int n1 = n - i;
    800049bc:	413a04bb          	subw	s1,s4,s3
    800049c0:	0004879b          	sext.w	a5,s1
    800049c4:	f8fbdce3          	bge	s7,a5,8000495c <filewrite+0x84>
    800049c8:	84e2                	mv	s1,s8
    800049ca:	bf49                	j	8000495c <filewrite+0x84>
    int i = 0;
    800049cc:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800049ce:	013a1f63          	bne	s4,s3,800049ec <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800049d2:	8552                	mv	a0,s4
    800049d4:	60a6                	ld	ra,72(sp)
    800049d6:	6406                	ld	s0,64(sp)
    800049d8:	74e2                	ld	s1,56(sp)
    800049da:	7942                	ld	s2,48(sp)
    800049dc:	79a2                	ld	s3,40(sp)
    800049de:	7a02                	ld	s4,32(sp)
    800049e0:	6ae2                	ld	s5,24(sp)
    800049e2:	6b42                	ld	s6,16(sp)
    800049e4:	6ba2                	ld	s7,8(sp)
    800049e6:	6c02                	ld	s8,0(sp)
    800049e8:	6161                	addi	sp,sp,80
    800049ea:	8082                	ret
    ret = (i == n ? n : -1);
    800049ec:	5a7d                	li	s4,-1
    800049ee:	b7d5                	j	800049d2 <filewrite+0xfa>
    panic("filewrite");
    800049f0:	00004517          	auipc	a0,0x4
    800049f4:	d6050513          	addi	a0,a0,-672 # 80008750 <syscalls+0x278>
    800049f8:	ffffc097          	auipc	ra,0xffffc
    800049fc:	b42080e7          	jalr	-1214(ra) # 8000053a <panic>
    return -1;
    80004a00:	5a7d                	li	s4,-1
    80004a02:	bfc1                	j	800049d2 <filewrite+0xfa>
      return -1;
    80004a04:	5a7d                	li	s4,-1
    80004a06:	b7f1                	j	800049d2 <filewrite+0xfa>
    80004a08:	5a7d                	li	s4,-1
    80004a0a:	b7e1                	j	800049d2 <filewrite+0xfa>

0000000080004a0c <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004a0c:	7179                	addi	sp,sp,-48
    80004a0e:	f406                	sd	ra,40(sp)
    80004a10:	f022                	sd	s0,32(sp)
    80004a12:	ec26                	sd	s1,24(sp)
    80004a14:	e84a                	sd	s2,16(sp)
    80004a16:	e44e                	sd	s3,8(sp)
    80004a18:	e052                	sd	s4,0(sp)
    80004a1a:	1800                	addi	s0,sp,48
    80004a1c:	84aa                	mv	s1,a0
    80004a1e:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004a20:	0005b023          	sd	zero,0(a1)
    80004a24:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004a28:	00000097          	auipc	ra,0x0
    80004a2c:	bf8080e7          	jalr	-1032(ra) # 80004620 <filealloc>
    80004a30:	e088                	sd	a0,0(s1)
    80004a32:	c551                	beqz	a0,80004abe <pipealloc+0xb2>
    80004a34:	00000097          	auipc	ra,0x0
    80004a38:	bec080e7          	jalr	-1044(ra) # 80004620 <filealloc>
    80004a3c:	00aa3023          	sd	a0,0(s4)
    80004a40:	c92d                	beqz	a0,80004ab2 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004a42:	ffffc097          	auipc	ra,0xffffc
    80004a46:	09e080e7          	jalr	158(ra) # 80000ae0 <kalloc>
    80004a4a:	892a                	mv	s2,a0
    80004a4c:	c125                	beqz	a0,80004aac <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004a4e:	4985                	li	s3,1
    80004a50:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004a54:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004a58:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004a5c:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004a60:	00004597          	auipc	a1,0x4
    80004a64:	d0058593          	addi	a1,a1,-768 # 80008760 <syscalls+0x288>
    80004a68:	ffffc097          	auipc	ra,0xffffc
    80004a6c:	0d8080e7          	jalr	216(ra) # 80000b40 <initlock>
  (*f0)->type = FD_PIPE;
    80004a70:	609c                	ld	a5,0(s1)
    80004a72:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004a76:	609c                	ld	a5,0(s1)
    80004a78:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004a7c:	609c                	ld	a5,0(s1)
    80004a7e:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a82:	609c                	ld	a5,0(s1)
    80004a84:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004a88:	000a3783          	ld	a5,0(s4)
    80004a8c:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a90:	000a3783          	ld	a5,0(s4)
    80004a94:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a98:	000a3783          	ld	a5,0(s4)
    80004a9c:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004aa0:	000a3783          	ld	a5,0(s4)
    80004aa4:	0127b823          	sd	s2,16(a5)
  return 0;
    80004aa8:	4501                	li	a0,0
    80004aaa:	a025                	j	80004ad2 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004aac:	6088                	ld	a0,0(s1)
    80004aae:	e501                	bnez	a0,80004ab6 <pipealloc+0xaa>
    80004ab0:	a039                	j	80004abe <pipealloc+0xb2>
    80004ab2:	6088                	ld	a0,0(s1)
    80004ab4:	c51d                	beqz	a0,80004ae2 <pipealloc+0xd6>
    fileclose(*f0);
    80004ab6:	00000097          	auipc	ra,0x0
    80004aba:	c26080e7          	jalr	-986(ra) # 800046dc <fileclose>
  if(*f1)
    80004abe:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004ac2:	557d                	li	a0,-1
  if(*f1)
    80004ac4:	c799                	beqz	a5,80004ad2 <pipealloc+0xc6>
    fileclose(*f1);
    80004ac6:	853e                	mv	a0,a5
    80004ac8:	00000097          	auipc	ra,0x0
    80004acc:	c14080e7          	jalr	-1004(ra) # 800046dc <fileclose>
  return -1;
    80004ad0:	557d                	li	a0,-1
}
    80004ad2:	70a2                	ld	ra,40(sp)
    80004ad4:	7402                	ld	s0,32(sp)
    80004ad6:	64e2                	ld	s1,24(sp)
    80004ad8:	6942                	ld	s2,16(sp)
    80004ada:	69a2                	ld	s3,8(sp)
    80004adc:	6a02                	ld	s4,0(sp)
    80004ade:	6145                	addi	sp,sp,48
    80004ae0:	8082                	ret
  return -1;
    80004ae2:	557d                	li	a0,-1
    80004ae4:	b7fd                	j	80004ad2 <pipealloc+0xc6>

0000000080004ae6 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004ae6:	1101                	addi	sp,sp,-32
    80004ae8:	ec06                	sd	ra,24(sp)
    80004aea:	e822                	sd	s0,16(sp)
    80004aec:	e426                	sd	s1,8(sp)
    80004aee:	e04a                	sd	s2,0(sp)
    80004af0:	1000                	addi	s0,sp,32
    80004af2:	84aa                	mv	s1,a0
    80004af4:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004af6:	ffffc097          	auipc	ra,0xffffc
    80004afa:	0da080e7          	jalr	218(ra) # 80000bd0 <acquire>
  if(writable){
    80004afe:	02090d63          	beqz	s2,80004b38 <pipeclose+0x52>
    pi->writeopen = 0;
    80004b02:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004b06:	21848513          	addi	a0,s1,536
    80004b0a:	ffffe097          	auipc	ra,0xffffe
    80004b0e:	8ec080e7          	jalr	-1812(ra) # 800023f6 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004b12:	2204b783          	ld	a5,544(s1)
    80004b16:	eb95                	bnez	a5,80004b4a <pipeclose+0x64>
    release(&pi->lock);
    80004b18:	8526                	mv	a0,s1
    80004b1a:	ffffc097          	auipc	ra,0xffffc
    80004b1e:	16a080e7          	jalr	362(ra) # 80000c84 <release>
    kfree((char*)pi);
    80004b22:	8526                	mv	a0,s1
    80004b24:	ffffc097          	auipc	ra,0xffffc
    80004b28:	ebe080e7          	jalr	-322(ra) # 800009e2 <kfree>
  } else
    release(&pi->lock);
}
    80004b2c:	60e2                	ld	ra,24(sp)
    80004b2e:	6442                	ld	s0,16(sp)
    80004b30:	64a2                	ld	s1,8(sp)
    80004b32:	6902                	ld	s2,0(sp)
    80004b34:	6105                	addi	sp,sp,32
    80004b36:	8082                	ret
    pi->readopen = 0;
    80004b38:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004b3c:	21c48513          	addi	a0,s1,540
    80004b40:	ffffe097          	auipc	ra,0xffffe
    80004b44:	8b6080e7          	jalr	-1866(ra) # 800023f6 <wakeup>
    80004b48:	b7e9                	j	80004b12 <pipeclose+0x2c>
    release(&pi->lock);
    80004b4a:	8526                	mv	a0,s1
    80004b4c:	ffffc097          	auipc	ra,0xffffc
    80004b50:	138080e7          	jalr	312(ra) # 80000c84 <release>
}
    80004b54:	bfe1                	j	80004b2c <pipeclose+0x46>

0000000080004b56 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004b56:	711d                	addi	sp,sp,-96
    80004b58:	ec86                	sd	ra,88(sp)
    80004b5a:	e8a2                	sd	s0,80(sp)
    80004b5c:	e4a6                	sd	s1,72(sp)
    80004b5e:	e0ca                	sd	s2,64(sp)
    80004b60:	fc4e                	sd	s3,56(sp)
    80004b62:	f852                	sd	s4,48(sp)
    80004b64:	f456                	sd	s5,40(sp)
    80004b66:	f05a                	sd	s6,32(sp)
    80004b68:	ec5e                	sd	s7,24(sp)
    80004b6a:	e862                	sd	s8,16(sp)
    80004b6c:	1080                	addi	s0,sp,96
    80004b6e:	84aa                	mv	s1,a0
    80004b70:	8aae                	mv	s5,a1
    80004b72:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004b74:	ffffd097          	auipc	ra,0xffffd
    80004b78:	efe080e7          	jalr	-258(ra) # 80001a72 <myproc>
    80004b7c:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004b7e:	8526                	mv	a0,s1
    80004b80:	ffffc097          	auipc	ra,0xffffc
    80004b84:	050080e7          	jalr	80(ra) # 80000bd0 <acquire>
  while(i < n){
    80004b88:	0b405363          	blez	s4,80004c2e <pipewrite+0xd8>
  int i = 0;
    80004b8c:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b8e:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004b90:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b94:	21c48b93          	addi	s7,s1,540
    80004b98:	a089                	j	80004bda <pipewrite+0x84>
      release(&pi->lock);
    80004b9a:	8526                	mv	a0,s1
    80004b9c:	ffffc097          	auipc	ra,0xffffc
    80004ba0:	0e8080e7          	jalr	232(ra) # 80000c84 <release>
      return -1;
    80004ba4:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004ba6:	854a                	mv	a0,s2
    80004ba8:	60e6                	ld	ra,88(sp)
    80004baa:	6446                	ld	s0,80(sp)
    80004bac:	64a6                	ld	s1,72(sp)
    80004bae:	6906                	ld	s2,64(sp)
    80004bb0:	79e2                	ld	s3,56(sp)
    80004bb2:	7a42                	ld	s4,48(sp)
    80004bb4:	7aa2                	ld	s5,40(sp)
    80004bb6:	7b02                	ld	s6,32(sp)
    80004bb8:	6be2                	ld	s7,24(sp)
    80004bba:	6c42                	ld	s8,16(sp)
    80004bbc:	6125                	addi	sp,sp,96
    80004bbe:	8082                	ret
      wakeup(&pi->nread);
    80004bc0:	8562                	mv	a0,s8
    80004bc2:	ffffe097          	auipc	ra,0xffffe
    80004bc6:	834080e7          	jalr	-1996(ra) # 800023f6 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004bca:	85a6                	mv	a1,s1
    80004bcc:	855e                	mv	a0,s7
    80004bce:	ffffd097          	auipc	ra,0xffffd
    80004bd2:	69c080e7          	jalr	1692(ra) # 8000226a <sleep>
  while(i < n){
    80004bd6:	05495d63          	bge	s2,s4,80004c30 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80004bda:	2204a783          	lw	a5,544(s1)
    80004bde:	dfd5                	beqz	a5,80004b9a <pipewrite+0x44>
    80004be0:	0289a783          	lw	a5,40(s3)
    80004be4:	fbdd                	bnez	a5,80004b9a <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004be6:	2184a783          	lw	a5,536(s1)
    80004bea:	21c4a703          	lw	a4,540(s1)
    80004bee:	2007879b          	addiw	a5,a5,512
    80004bf2:	fcf707e3          	beq	a4,a5,80004bc0 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004bf6:	4685                	li	a3,1
    80004bf8:	01590633          	add	a2,s2,s5
    80004bfc:	faf40593          	addi	a1,s0,-81
    80004c00:	0509b503          	ld	a0,80(s3)
    80004c04:	ffffd097          	auipc	ra,0xffffd
    80004c08:	ae2080e7          	jalr	-1310(ra) # 800016e6 <copyin>
    80004c0c:	03650263          	beq	a0,s6,80004c30 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004c10:	21c4a783          	lw	a5,540(s1)
    80004c14:	0017871b          	addiw	a4,a5,1
    80004c18:	20e4ae23          	sw	a4,540(s1)
    80004c1c:	1ff7f793          	andi	a5,a5,511
    80004c20:	97a6                	add	a5,a5,s1
    80004c22:	faf44703          	lbu	a4,-81(s0)
    80004c26:	00e78c23          	sb	a4,24(a5)
      i++;
    80004c2a:	2905                	addiw	s2,s2,1
    80004c2c:	b76d                	j	80004bd6 <pipewrite+0x80>
  int i = 0;
    80004c2e:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004c30:	21848513          	addi	a0,s1,536
    80004c34:	ffffd097          	auipc	ra,0xffffd
    80004c38:	7c2080e7          	jalr	1986(ra) # 800023f6 <wakeup>
  release(&pi->lock);
    80004c3c:	8526                	mv	a0,s1
    80004c3e:	ffffc097          	auipc	ra,0xffffc
    80004c42:	046080e7          	jalr	70(ra) # 80000c84 <release>
  return i;
    80004c46:	b785                	j	80004ba6 <pipewrite+0x50>

0000000080004c48 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004c48:	715d                	addi	sp,sp,-80
    80004c4a:	e486                	sd	ra,72(sp)
    80004c4c:	e0a2                	sd	s0,64(sp)
    80004c4e:	fc26                	sd	s1,56(sp)
    80004c50:	f84a                	sd	s2,48(sp)
    80004c52:	f44e                	sd	s3,40(sp)
    80004c54:	f052                	sd	s4,32(sp)
    80004c56:	ec56                	sd	s5,24(sp)
    80004c58:	e85a                	sd	s6,16(sp)
    80004c5a:	0880                	addi	s0,sp,80
    80004c5c:	84aa                	mv	s1,a0
    80004c5e:	892e                	mv	s2,a1
    80004c60:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004c62:	ffffd097          	auipc	ra,0xffffd
    80004c66:	e10080e7          	jalr	-496(ra) # 80001a72 <myproc>
    80004c6a:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004c6c:	8526                	mv	a0,s1
    80004c6e:	ffffc097          	auipc	ra,0xffffc
    80004c72:	f62080e7          	jalr	-158(ra) # 80000bd0 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c76:	2184a703          	lw	a4,536(s1)
    80004c7a:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c7e:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c82:	02f71463          	bne	a4,a5,80004caa <piperead+0x62>
    80004c86:	2244a783          	lw	a5,548(s1)
    80004c8a:	c385                	beqz	a5,80004caa <piperead+0x62>
    if(pr->killed){
    80004c8c:	028a2783          	lw	a5,40(s4)
    80004c90:	ebc9                	bnez	a5,80004d22 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c92:	85a6                	mv	a1,s1
    80004c94:	854e                	mv	a0,s3
    80004c96:	ffffd097          	auipc	ra,0xffffd
    80004c9a:	5d4080e7          	jalr	1492(ra) # 8000226a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c9e:	2184a703          	lw	a4,536(s1)
    80004ca2:	21c4a783          	lw	a5,540(s1)
    80004ca6:	fef700e3          	beq	a4,a5,80004c86 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004caa:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004cac:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cae:	05505463          	blez	s5,80004cf6 <piperead+0xae>
    if(pi->nread == pi->nwrite)
    80004cb2:	2184a783          	lw	a5,536(s1)
    80004cb6:	21c4a703          	lw	a4,540(s1)
    80004cba:	02f70e63          	beq	a4,a5,80004cf6 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004cbe:	0017871b          	addiw	a4,a5,1
    80004cc2:	20e4ac23          	sw	a4,536(s1)
    80004cc6:	1ff7f793          	andi	a5,a5,511
    80004cca:	97a6                	add	a5,a5,s1
    80004ccc:	0187c783          	lbu	a5,24(a5)
    80004cd0:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004cd4:	4685                	li	a3,1
    80004cd6:	fbf40613          	addi	a2,s0,-65
    80004cda:	85ca                	mv	a1,s2
    80004cdc:	050a3503          	ld	a0,80(s4)
    80004ce0:	ffffd097          	auipc	ra,0xffffd
    80004ce4:	97a080e7          	jalr	-1670(ra) # 8000165a <copyout>
    80004ce8:	01650763          	beq	a0,s6,80004cf6 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cec:	2985                	addiw	s3,s3,1
    80004cee:	0905                	addi	s2,s2,1
    80004cf0:	fd3a91e3          	bne	s5,s3,80004cb2 <piperead+0x6a>
    80004cf4:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004cf6:	21c48513          	addi	a0,s1,540
    80004cfa:	ffffd097          	auipc	ra,0xffffd
    80004cfe:	6fc080e7          	jalr	1788(ra) # 800023f6 <wakeup>
  release(&pi->lock);
    80004d02:	8526                	mv	a0,s1
    80004d04:	ffffc097          	auipc	ra,0xffffc
    80004d08:	f80080e7          	jalr	-128(ra) # 80000c84 <release>
  return i;
}
    80004d0c:	854e                	mv	a0,s3
    80004d0e:	60a6                	ld	ra,72(sp)
    80004d10:	6406                	ld	s0,64(sp)
    80004d12:	74e2                	ld	s1,56(sp)
    80004d14:	7942                	ld	s2,48(sp)
    80004d16:	79a2                	ld	s3,40(sp)
    80004d18:	7a02                	ld	s4,32(sp)
    80004d1a:	6ae2                	ld	s5,24(sp)
    80004d1c:	6b42                	ld	s6,16(sp)
    80004d1e:	6161                	addi	sp,sp,80
    80004d20:	8082                	ret
      release(&pi->lock);
    80004d22:	8526                	mv	a0,s1
    80004d24:	ffffc097          	auipc	ra,0xffffc
    80004d28:	f60080e7          	jalr	-160(ra) # 80000c84 <release>
      return -1;
    80004d2c:	59fd                	li	s3,-1
    80004d2e:	bff9                	j	80004d0c <piperead+0xc4>

0000000080004d30 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004d30:	de010113          	addi	sp,sp,-544
    80004d34:	20113c23          	sd	ra,536(sp)
    80004d38:	20813823          	sd	s0,528(sp)
    80004d3c:	20913423          	sd	s1,520(sp)
    80004d40:	21213023          	sd	s2,512(sp)
    80004d44:	ffce                	sd	s3,504(sp)
    80004d46:	fbd2                	sd	s4,496(sp)
    80004d48:	f7d6                	sd	s5,488(sp)
    80004d4a:	f3da                	sd	s6,480(sp)
    80004d4c:	efde                	sd	s7,472(sp)
    80004d4e:	ebe2                	sd	s8,464(sp)
    80004d50:	e7e6                	sd	s9,456(sp)
    80004d52:	e3ea                	sd	s10,448(sp)
    80004d54:	ff6e                	sd	s11,440(sp)
    80004d56:	1400                	addi	s0,sp,544
    80004d58:	892a                	mv	s2,a0
    80004d5a:	dea43423          	sd	a0,-536(s0)
    80004d5e:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004d62:	ffffd097          	auipc	ra,0xffffd
    80004d66:	d10080e7          	jalr	-752(ra) # 80001a72 <myproc>
    80004d6a:	84aa                	mv	s1,a0

  begin_op();
    80004d6c:	fffff097          	auipc	ra,0xfffff
    80004d70:	4a8080e7          	jalr	1192(ra) # 80004214 <begin_op>

  if((ip = namei(path)) == 0){
    80004d74:	854a                	mv	a0,s2
    80004d76:	fffff097          	auipc	ra,0xfffff
    80004d7a:	27e080e7          	jalr	638(ra) # 80003ff4 <namei>
    80004d7e:	c93d                	beqz	a0,80004df4 <exec+0xc4>
    80004d80:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d82:	fffff097          	auipc	ra,0xfffff
    80004d86:	ab6080e7          	jalr	-1354(ra) # 80003838 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d8a:	04000713          	li	a4,64
    80004d8e:	4681                	li	a3,0
    80004d90:	e5040613          	addi	a2,s0,-432
    80004d94:	4581                	li	a1,0
    80004d96:	8556                	mv	a0,s5
    80004d98:	fffff097          	auipc	ra,0xfffff
    80004d9c:	d54080e7          	jalr	-684(ra) # 80003aec <readi>
    80004da0:	04000793          	li	a5,64
    80004da4:	00f51a63          	bne	a0,a5,80004db8 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004da8:	e5042703          	lw	a4,-432(s0)
    80004dac:	464c47b7          	lui	a5,0x464c4
    80004db0:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004db4:	04f70663          	beq	a4,a5,80004e00 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004db8:	8556                	mv	a0,s5
    80004dba:	fffff097          	auipc	ra,0xfffff
    80004dbe:	ce0080e7          	jalr	-800(ra) # 80003a9a <iunlockput>
    end_op();
    80004dc2:	fffff097          	auipc	ra,0xfffff
    80004dc6:	4d0080e7          	jalr	1232(ra) # 80004292 <end_op>
  }
  return -1;
    80004dca:	557d                	li	a0,-1
}
    80004dcc:	21813083          	ld	ra,536(sp)
    80004dd0:	21013403          	ld	s0,528(sp)
    80004dd4:	20813483          	ld	s1,520(sp)
    80004dd8:	20013903          	ld	s2,512(sp)
    80004ddc:	79fe                	ld	s3,504(sp)
    80004dde:	7a5e                	ld	s4,496(sp)
    80004de0:	7abe                	ld	s5,488(sp)
    80004de2:	7b1e                	ld	s6,480(sp)
    80004de4:	6bfe                	ld	s7,472(sp)
    80004de6:	6c5e                	ld	s8,464(sp)
    80004de8:	6cbe                	ld	s9,456(sp)
    80004dea:	6d1e                	ld	s10,448(sp)
    80004dec:	7dfa                	ld	s11,440(sp)
    80004dee:	22010113          	addi	sp,sp,544
    80004df2:	8082                	ret
    end_op();
    80004df4:	fffff097          	auipc	ra,0xfffff
    80004df8:	49e080e7          	jalr	1182(ra) # 80004292 <end_op>
    return -1;
    80004dfc:	557d                	li	a0,-1
    80004dfe:	b7f9                	j	80004dcc <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004e00:	8526                	mv	a0,s1
    80004e02:	ffffd097          	auipc	ra,0xffffd
    80004e06:	e10080e7          	jalr	-496(ra) # 80001c12 <proc_pagetable>
    80004e0a:	8b2a                	mv	s6,a0
    80004e0c:	d555                	beqz	a0,80004db8 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e0e:	e7042783          	lw	a5,-400(s0)
    80004e12:	e8845703          	lhu	a4,-376(s0)
    80004e16:	c735                	beqz	a4,80004e82 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e18:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e1a:	e0043423          	sd	zero,-504(s0)
    if((ph.vaddr % PGSIZE) != 0)
    80004e1e:	6a05                	lui	s4,0x1
    80004e20:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004e24:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004e28:	6d85                	lui	s11,0x1
    80004e2a:	7d7d                	lui	s10,0xfffff
    80004e2c:	ac1d                	j	80005062 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004e2e:	00004517          	auipc	a0,0x4
    80004e32:	93a50513          	addi	a0,a0,-1734 # 80008768 <syscalls+0x290>
    80004e36:	ffffb097          	auipc	ra,0xffffb
    80004e3a:	704080e7          	jalr	1796(ra) # 8000053a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004e3e:	874a                	mv	a4,s2
    80004e40:	009c86bb          	addw	a3,s9,s1
    80004e44:	4581                	li	a1,0
    80004e46:	8556                	mv	a0,s5
    80004e48:	fffff097          	auipc	ra,0xfffff
    80004e4c:	ca4080e7          	jalr	-860(ra) # 80003aec <readi>
    80004e50:	2501                	sext.w	a0,a0
    80004e52:	1aa91863          	bne	s2,a0,80005002 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004e56:	009d84bb          	addw	s1,s11,s1
    80004e5a:	013d09bb          	addw	s3,s10,s3
    80004e5e:	1f74f263          	bgeu	s1,s7,80005042 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004e62:	02049593          	slli	a1,s1,0x20
    80004e66:	9181                	srli	a1,a1,0x20
    80004e68:	95e2                	add	a1,a1,s8
    80004e6a:	855a                	mv	a0,s6
    80004e6c:	ffffc097          	auipc	ra,0xffffc
    80004e70:	1e6080e7          	jalr	486(ra) # 80001052 <walkaddr>
    80004e74:	862a                	mv	a2,a0
    if(pa == 0)
    80004e76:	dd45                	beqz	a0,80004e2e <exec+0xfe>
      n = PGSIZE;
    80004e78:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004e7a:	fd49f2e3          	bgeu	s3,s4,80004e3e <exec+0x10e>
      n = sz - i;
    80004e7e:	894e                	mv	s2,s3
    80004e80:	bf7d                	j	80004e3e <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e82:	4481                	li	s1,0
  iunlockput(ip);
    80004e84:	8556                	mv	a0,s5
    80004e86:	fffff097          	auipc	ra,0xfffff
    80004e8a:	c14080e7          	jalr	-1004(ra) # 80003a9a <iunlockput>
  end_op();
    80004e8e:	fffff097          	auipc	ra,0xfffff
    80004e92:	404080e7          	jalr	1028(ra) # 80004292 <end_op>
  p = myproc();
    80004e96:	ffffd097          	auipc	ra,0xffffd
    80004e9a:	bdc080e7          	jalr	-1060(ra) # 80001a72 <myproc>
    80004e9e:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004ea0:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004ea4:	6785                	lui	a5,0x1
    80004ea6:	17fd                	addi	a5,a5,-1
    80004ea8:	97a6                	add	a5,a5,s1
    80004eaa:	777d                	lui	a4,0xfffff
    80004eac:	8ff9                	and	a5,a5,a4
    80004eae:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004eb2:	6609                	lui	a2,0x2
    80004eb4:	963e                	add	a2,a2,a5
    80004eb6:	85be                	mv	a1,a5
    80004eb8:	855a                	mv	a0,s6
    80004eba:	ffffc097          	auipc	ra,0xffffc
    80004ebe:	54c080e7          	jalr	1356(ra) # 80001406 <uvmalloc>
    80004ec2:	8c2a                	mv	s8,a0
  ip = 0;
    80004ec4:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004ec6:	12050e63          	beqz	a0,80005002 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004eca:	75f9                	lui	a1,0xffffe
    80004ecc:	95aa                	add	a1,a1,a0
    80004ece:	855a                	mv	a0,s6
    80004ed0:	ffffc097          	auipc	ra,0xffffc
    80004ed4:	758080e7          	jalr	1880(ra) # 80001628 <uvmclear>
  stackbase = sp - PGSIZE;
    80004ed8:	7afd                	lui	s5,0xfffff
    80004eda:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004edc:	df043783          	ld	a5,-528(s0)
    80004ee0:	6388                	ld	a0,0(a5)
    80004ee2:	c925                	beqz	a0,80004f52 <exec+0x222>
    80004ee4:	e9040993          	addi	s3,s0,-368
    80004ee8:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004eec:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004eee:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004ef0:	ffffc097          	auipc	ra,0xffffc
    80004ef4:	f58080e7          	jalr	-168(ra) # 80000e48 <strlen>
    80004ef8:	0015079b          	addiw	a5,a0,1
    80004efc:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004f00:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004f04:	13596363          	bltu	s2,s5,8000502a <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004f08:	df043d83          	ld	s11,-528(s0)
    80004f0c:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004f10:	8552                	mv	a0,s4
    80004f12:	ffffc097          	auipc	ra,0xffffc
    80004f16:	f36080e7          	jalr	-202(ra) # 80000e48 <strlen>
    80004f1a:	0015069b          	addiw	a3,a0,1
    80004f1e:	8652                	mv	a2,s4
    80004f20:	85ca                	mv	a1,s2
    80004f22:	855a                	mv	a0,s6
    80004f24:	ffffc097          	auipc	ra,0xffffc
    80004f28:	736080e7          	jalr	1846(ra) # 8000165a <copyout>
    80004f2c:	10054363          	bltz	a0,80005032 <exec+0x302>
    ustack[argc] = sp;
    80004f30:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004f34:	0485                	addi	s1,s1,1
    80004f36:	008d8793          	addi	a5,s11,8
    80004f3a:	def43823          	sd	a5,-528(s0)
    80004f3e:	008db503          	ld	a0,8(s11)
    80004f42:	c911                	beqz	a0,80004f56 <exec+0x226>
    if(argc >= MAXARG)
    80004f44:	09a1                	addi	s3,s3,8
    80004f46:	fb3c95e3          	bne	s9,s3,80004ef0 <exec+0x1c0>
  sz = sz1;
    80004f4a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f4e:	4a81                	li	s5,0
    80004f50:	a84d                	j	80005002 <exec+0x2d2>
  sp = sz;
    80004f52:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004f54:	4481                	li	s1,0
  ustack[argc] = 0;
    80004f56:	00349793          	slli	a5,s1,0x3
    80004f5a:	f9078793          	addi	a5,a5,-112 # f90 <_entry-0x7ffff070>
    80004f5e:	97a2                	add	a5,a5,s0
    80004f60:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004f64:	00148693          	addi	a3,s1,1
    80004f68:	068e                	slli	a3,a3,0x3
    80004f6a:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f6e:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004f72:	01597663          	bgeu	s2,s5,80004f7e <exec+0x24e>
  sz = sz1;
    80004f76:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f7a:	4a81                	li	s5,0
    80004f7c:	a059                	j	80005002 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f7e:	e9040613          	addi	a2,s0,-368
    80004f82:	85ca                	mv	a1,s2
    80004f84:	855a                	mv	a0,s6
    80004f86:	ffffc097          	auipc	ra,0xffffc
    80004f8a:	6d4080e7          	jalr	1748(ra) # 8000165a <copyout>
    80004f8e:	0a054663          	bltz	a0,8000503a <exec+0x30a>
  p->trapframe->a1 = sp;
    80004f92:	058bb783          	ld	a5,88(s7)
    80004f96:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f9a:	de843783          	ld	a5,-536(s0)
    80004f9e:	0007c703          	lbu	a4,0(a5)
    80004fa2:	cf11                	beqz	a4,80004fbe <exec+0x28e>
    80004fa4:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004fa6:	02f00693          	li	a3,47
    80004faa:	a039                	j	80004fb8 <exec+0x288>
      last = s+1;
    80004fac:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004fb0:	0785                	addi	a5,a5,1
    80004fb2:	fff7c703          	lbu	a4,-1(a5)
    80004fb6:	c701                	beqz	a4,80004fbe <exec+0x28e>
    if(*s == '/')
    80004fb8:	fed71ce3          	bne	a4,a3,80004fb0 <exec+0x280>
    80004fbc:	bfc5                	j	80004fac <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80004fbe:	4641                	li	a2,16
    80004fc0:	de843583          	ld	a1,-536(s0)
    80004fc4:	158b8513          	addi	a0,s7,344
    80004fc8:	ffffc097          	auipc	ra,0xffffc
    80004fcc:	e4e080e7          	jalr	-434(ra) # 80000e16 <safestrcpy>
  oldpagetable = p->pagetable;
    80004fd0:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004fd4:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004fd8:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004fdc:	058bb783          	ld	a5,88(s7)
    80004fe0:	e6843703          	ld	a4,-408(s0)
    80004fe4:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004fe6:	058bb783          	ld	a5,88(s7)
    80004fea:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004fee:	85ea                	mv	a1,s10
    80004ff0:	ffffd097          	auipc	ra,0xffffd
    80004ff4:	cbe080e7          	jalr	-834(ra) # 80001cae <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004ff8:	0004851b          	sext.w	a0,s1
    80004ffc:	bbc1                	j	80004dcc <exec+0x9c>
    80004ffe:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005002:	df843583          	ld	a1,-520(s0)
    80005006:	855a                	mv	a0,s6
    80005008:	ffffd097          	auipc	ra,0xffffd
    8000500c:	ca6080e7          	jalr	-858(ra) # 80001cae <proc_freepagetable>
  if(ip){
    80005010:	da0a94e3          	bnez	s5,80004db8 <exec+0x88>
  return -1;
    80005014:	557d                	li	a0,-1
    80005016:	bb5d                	j	80004dcc <exec+0x9c>
    80005018:	de943c23          	sd	s1,-520(s0)
    8000501c:	b7dd                	j	80005002 <exec+0x2d2>
    8000501e:	de943c23          	sd	s1,-520(s0)
    80005022:	b7c5                	j	80005002 <exec+0x2d2>
    80005024:	de943c23          	sd	s1,-520(s0)
    80005028:	bfe9                	j	80005002 <exec+0x2d2>
  sz = sz1;
    8000502a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000502e:	4a81                	li	s5,0
    80005030:	bfc9                	j	80005002 <exec+0x2d2>
  sz = sz1;
    80005032:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005036:	4a81                	li	s5,0
    80005038:	b7e9                	j	80005002 <exec+0x2d2>
  sz = sz1;
    8000503a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000503e:	4a81                	li	s5,0
    80005040:	b7c9                	j	80005002 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005042:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005046:	e0843783          	ld	a5,-504(s0)
    8000504a:	0017869b          	addiw	a3,a5,1
    8000504e:	e0d43423          	sd	a3,-504(s0)
    80005052:	e0043783          	ld	a5,-512(s0)
    80005056:	0387879b          	addiw	a5,a5,56
    8000505a:	e8845703          	lhu	a4,-376(s0)
    8000505e:	e2e6d3e3          	bge	a3,a4,80004e84 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005062:	2781                	sext.w	a5,a5
    80005064:	e0f43023          	sd	a5,-512(s0)
    80005068:	03800713          	li	a4,56
    8000506c:	86be                	mv	a3,a5
    8000506e:	e1840613          	addi	a2,s0,-488
    80005072:	4581                	li	a1,0
    80005074:	8556                	mv	a0,s5
    80005076:	fffff097          	auipc	ra,0xfffff
    8000507a:	a76080e7          	jalr	-1418(ra) # 80003aec <readi>
    8000507e:	03800793          	li	a5,56
    80005082:	f6f51ee3          	bne	a0,a5,80004ffe <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80005086:	e1842783          	lw	a5,-488(s0)
    8000508a:	4705                	li	a4,1
    8000508c:	fae79de3          	bne	a5,a4,80005046 <exec+0x316>
    if(ph.memsz < ph.filesz)
    80005090:	e4043603          	ld	a2,-448(s0)
    80005094:	e3843783          	ld	a5,-456(s0)
    80005098:	f8f660e3          	bltu	a2,a5,80005018 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000509c:	e2843783          	ld	a5,-472(s0)
    800050a0:	963e                	add	a2,a2,a5
    800050a2:	f6f66ee3          	bltu	a2,a5,8000501e <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800050a6:	85a6                	mv	a1,s1
    800050a8:	855a                	mv	a0,s6
    800050aa:	ffffc097          	auipc	ra,0xffffc
    800050ae:	35c080e7          	jalr	860(ra) # 80001406 <uvmalloc>
    800050b2:	dea43c23          	sd	a0,-520(s0)
    800050b6:	d53d                	beqz	a0,80005024 <exec+0x2f4>
    if((ph.vaddr % PGSIZE) != 0)
    800050b8:	e2843c03          	ld	s8,-472(s0)
    800050bc:	de043783          	ld	a5,-544(s0)
    800050c0:	00fc77b3          	and	a5,s8,a5
    800050c4:	ff9d                	bnez	a5,80005002 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800050c6:	e2042c83          	lw	s9,-480(s0)
    800050ca:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800050ce:	f60b8ae3          	beqz	s7,80005042 <exec+0x312>
    800050d2:	89de                	mv	s3,s7
    800050d4:	4481                	li	s1,0
    800050d6:	b371                	j	80004e62 <exec+0x132>

00000000800050d8 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800050d8:	7179                	addi	sp,sp,-48
    800050da:	f406                	sd	ra,40(sp)
    800050dc:	f022                	sd	s0,32(sp)
    800050de:	ec26                	sd	s1,24(sp)
    800050e0:	e84a                	sd	s2,16(sp)
    800050e2:	1800                	addi	s0,sp,48
    800050e4:	892e                	mv	s2,a1
    800050e6:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800050e8:	fdc40593          	addi	a1,s0,-36
    800050ec:	ffffe097          	auipc	ra,0xffffe
    800050f0:	b70080e7          	jalr	-1168(ra) # 80002c5c <argint>
    800050f4:	04054063          	bltz	a0,80005134 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800050f8:	fdc42703          	lw	a4,-36(s0)
    800050fc:	47bd                	li	a5,15
    800050fe:	02e7ed63          	bltu	a5,a4,80005138 <argfd+0x60>
    80005102:	ffffd097          	auipc	ra,0xffffd
    80005106:	970080e7          	jalr	-1680(ra) # 80001a72 <myproc>
    8000510a:	fdc42703          	lw	a4,-36(s0)
    8000510e:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffd7c9a>
    80005112:	078e                	slli	a5,a5,0x3
    80005114:	953e                	add	a0,a0,a5
    80005116:	611c                	ld	a5,0(a0)
    80005118:	c395                	beqz	a5,8000513c <argfd+0x64>
    return -1;
  if(pfd)
    8000511a:	00090463          	beqz	s2,80005122 <argfd+0x4a>
    *pfd = fd;
    8000511e:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005122:	4501                	li	a0,0
  if(pf)
    80005124:	c091                	beqz	s1,80005128 <argfd+0x50>
    *pf = f;
    80005126:	e09c                	sd	a5,0(s1)
}
    80005128:	70a2                	ld	ra,40(sp)
    8000512a:	7402                	ld	s0,32(sp)
    8000512c:	64e2                	ld	s1,24(sp)
    8000512e:	6942                	ld	s2,16(sp)
    80005130:	6145                	addi	sp,sp,48
    80005132:	8082                	ret
    return -1;
    80005134:	557d                	li	a0,-1
    80005136:	bfcd                	j	80005128 <argfd+0x50>
    return -1;
    80005138:	557d                	li	a0,-1
    8000513a:	b7fd                	j	80005128 <argfd+0x50>
    8000513c:	557d                	li	a0,-1
    8000513e:	b7ed                	j	80005128 <argfd+0x50>

0000000080005140 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005140:	1101                	addi	sp,sp,-32
    80005142:	ec06                	sd	ra,24(sp)
    80005144:	e822                	sd	s0,16(sp)
    80005146:	e426                	sd	s1,8(sp)
    80005148:	1000                	addi	s0,sp,32
    8000514a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000514c:	ffffd097          	auipc	ra,0xffffd
    80005150:	926080e7          	jalr	-1754(ra) # 80001a72 <myproc>
    80005154:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005156:	0d050793          	addi	a5,a0,208
    8000515a:	4501                	li	a0,0
    8000515c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000515e:	6398                	ld	a4,0(a5)
    80005160:	cb19                	beqz	a4,80005176 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005162:	2505                	addiw	a0,a0,1
    80005164:	07a1                	addi	a5,a5,8
    80005166:	fed51ce3          	bne	a0,a3,8000515e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000516a:	557d                	li	a0,-1
}
    8000516c:	60e2                	ld	ra,24(sp)
    8000516e:	6442                	ld	s0,16(sp)
    80005170:	64a2                	ld	s1,8(sp)
    80005172:	6105                	addi	sp,sp,32
    80005174:	8082                	ret
      p->ofile[fd] = f;
    80005176:	01a50793          	addi	a5,a0,26
    8000517a:	078e                	slli	a5,a5,0x3
    8000517c:	963e                	add	a2,a2,a5
    8000517e:	e204                	sd	s1,0(a2)
      return fd;
    80005180:	b7f5                	j	8000516c <fdalloc+0x2c>

0000000080005182 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005182:	715d                	addi	sp,sp,-80
    80005184:	e486                	sd	ra,72(sp)
    80005186:	e0a2                	sd	s0,64(sp)
    80005188:	fc26                	sd	s1,56(sp)
    8000518a:	f84a                	sd	s2,48(sp)
    8000518c:	f44e                	sd	s3,40(sp)
    8000518e:	f052                	sd	s4,32(sp)
    80005190:	ec56                	sd	s5,24(sp)
    80005192:	0880                	addi	s0,sp,80
    80005194:	89ae                	mv	s3,a1
    80005196:	8ab2                	mv	s5,a2
    80005198:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000519a:	fb040593          	addi	a1,s0,-80
    8000519e:	fffff097          	auipc	ra,0xfffff
    800051a2:	e74080e7          	jalr	-396(ra) # 80004012 <nameiparent>
    800051a6:	892a                	mv	s2,a0
    800051a8:	12050e63          	beqz	a0,800052e4 <create+0x162>
    return 0;

  ilock(dp);
    800051ac:	ffffe097          	auipc	ra,0xffffe
    800051b0:	68c080e7          	jalr	1676(ra) # 80003838 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800051b4:	4601                	li	a2,0
    800051b6:	fb040593          	addi	a1,s0,-80
    800051ba:	854a                	mv	a0,s2
    800051bc:	fffff097          	auipc	ra,0xfffff
    800051c0:	b60080e7          	jalr	-1184(ra) # 80003d1c <dirlookup>
    800051c4:	84aa                	mv	s1,a0
    800051c6:	c921                	beqz	a0,80005216 <create+0x94>
    iunlockput(dp);
    800051c8:	854a                	mv	a0,s2
    800051ca:	fffff097          	auipc	ra,0xfffff
    800051ce:	8d0080e7          	jalr	-1840(ra) # 80003a9a <iunlockput>
    ilock(ip);
    800051d2:	8526                	mv	a0,s1
    800051d4:	ffffe097          	auipc	ra,0xffffe
    800051d8:	664080e7          	jalr	1636(ra) # 80003838 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800051dc:	2981                	sext.w	s3,s3
    800051de:	4789                	li	a5,2
    800051e0:	02f99463          	bne	s3,a5,80005208 <create+0x86>
    800051e4:	0444d783          	lhu	a5,68(s1)
    800051e8:	37f9                	addiw	a5,a5,-2
    800051ea:	17c2                	slli	a5,a5,0x30
    800051ec:	93c1                	srli	a5,a5,0x30
    800051ee:	4705                	li	a4,1
    800051f0:	00f76c63          	bltu	a4,a5,80005208 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800051f4:	8526                	mv	a0,s1
    800051f6:	60a6                	ld	ra,72(sp)
    800051f8:	6406                	ld	s0,64(sp)
    800051fa:	74e2                	ld	s1,56(sp)
    800051fc:	7942                	ld	s2,48(sp)
    800051fe:	79a2                	ld	s3,40(sp)
    80005200:	7a02                	ld	s4,32(sp)
    80005202:	6ae2                	ld	s5,24(sp)
    80005204:	6161                	addi	sp,sp,80
    80005206:	8082                	ret
    iunlockput(ip);
    80005208:	8526                	mv	a0,s1
    8000520a:	fffff097          	auipc	ra,0xfffff
    8000520e:	890080e7          	jalr	-1904(ra) # 80003a9a <iunlockput>
    return 0;
    80005212:	4481                	li	s1,0
    80005214:	b7c5                	j	800051f4 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005216:	85ce                	mv	a1,s3
    80005218:	00092503          	lw	a0,0(s2)
    8000521c:	ffffe097          	auipc	ra,0xffffe
    80005220:	482080e7          	jalr	1154(ra) # 8000369e <ialloc>
    80005224:	84aa                	mv	s1,a0
    80005226:	c521                	beqz	a0,8000526e <create+0xec>
  ilock(ip);
    80005228:	ffffe097          	auipc	ra,0xffffe
    8000522c:	610080e7          	jalr	1552(ra) # 80003838 <ilock>
  ip->major = major;
    80005230:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005234:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005238:	4a05                	li	s4,1
    8000523a:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    8000523e:	8526                	mv	a0,s1
    80005240:	ffffe097          	auipc	ra,0xffffe
    80005244:	52c080e7          	jalr	1324(ra) # 8000376c <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005248:	2981                	sext.w	s3,s3
    8000524a:	03498a63          	beq	s3,s4,8000527e <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    8000524e:	40d0                	lw	a2,4(s1)
    80005250:	fb040593          	addi	a1,s0,-80
    80005254:	854a                	mv	a0,s2
    80005256:	fffff097          	auipc	ra,0xfffff
    8000525a:	cdc080e7          	jalr	-804(ra) # 80003f32 <dirlink>
    8000525e:	06054b63          	bltz	a0,800052d4 <create+0x152>
  iunlockput(dp);
    80005262:	854a                	mv	a0,s2
    80005264:	fffff097          	auipc	ra,0xfffff
    80005268:	836080e7          	jalr	-1994(ra) # 80003a9a <iunlockput>
  return ip;
    8000526c:	b761                	j	800051f4 <create+0x72>
    panic("create: ialloc");
    8000526e:	00003517          	auipc	a0,0x3
    80005272:	51a50513          	addi	a0,a0,1306 # 80008788 <syscalls+0x2b0>
    80005276:	ffffb097          	auipc	ra,0xffffb
    8000527a:	2c4080e7          	jalr	708(ra) # 8000053a <panic>
    dp->nlink++;  // for ".."
    8000527e:	04a95783          	lhu	a5,74(s2)
    80005282:	2785                	addiw	a5,a5,1
    80005284:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005288:	854a                	mv	a0,s2
    8000528a:	ffffe097          	auipc	ra,0xffffe
    8000528e:	4e2080e7          	jalr	1250(ra) # 8000376c <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005292:	40d0                	lw	a2,4(s1)
    80005294:	00003597          	auipc	a1,0x3
    80005298:	50458593          	addi	a1,a1,1284 # 80008798 <syscalls+0x2c0>
    8000529c:	8526                	mv	a0,s1
    8000529e:	fffff097          	auipc	ra,0xfffff
    800052a2:	c94080e7          	jalr	-876(ra) # 80003f32 <dirlink>
    800052a6:	00054f63          	bltz	a0,800052c4 <create+0x142>
    800052aa:	00492603          	lw	a2,4(s2)
    800052ae:	00003597          	auipc	a1,0x3
    800052b2:	4f258593          	addi	a1,a1,1266 # 800087a0 <syscalls+0x2c8>
    800052b6:	8526                	mv	a0,s1
    800052b8:	fffff097          	auipc	ra,0xfffff
    800052bc:	c7a080e7          	jalr	-902(ra) # 80003f32 <dirlink>
    800052c0:	f80557e3          	bgez	a0,8000524e <create+0xcc>
      panic("create dots");
    800052c4:	00003517          	auipc	a0,0x3
    800052c8:	4e450513          	addi	a0,a0,1252 # 800087a8 <syscalls+0x2d0>
    800052cc:	ffffb097          	auipc	ra,0xffffb
    800052d0:	26e080e7          	jalr	622(ra) # 8000053a <panic>
    panic("create: dirlink");
    800052d4:	00003517          	auipc	a0,0x3
    800052d8:	4e450513          	addi	a0,a0,1252 # 800087b8 <syscalls+0x2e0>
    800052dc:	ffffb097          	auipc	ra,0xffffb
    800052e0:	25e080e7          	jalr	606(ra) # 8000053a <panic>
    return 0;
    800052e4:	84aa                	mv	s1,a0
    800052e6:	b739                	j	800051f4 <create+0x72>

00000000800052e8 <sys_dup>:
{
    800052e8:	7179                	addi	sp,sp,-48
    800052ea:	f406                	sd	ra,40(sp)
    800052ec:	f022                	sd	s0,32(sp)
    800052ee:	ec26                	sd	s1,24(sp)
    800052f0:	e84a                	sd	s2,16(sp)
    800052f2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800052f4:	fd840613          	addi	a2,s0,-40
    800052f8:	4581                	li	a1,0
    800052fa:	4501                	li	a0,0
    800052fc:	00000097          	auipc	ra,0x0
    80005300:	ddc080e7          	jalr	-548(ra) # 800050d8 <argfd>
    return -1;
    80005304:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005306:	02054363          	bltz	a0,8000532c <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    8000530a:	fd843903          	ld	s2,-40(s0)
    8000530e:	854a                	mv	a0,s2
    80005310:	00000097          	auipc	ra,0x0
    80005314:	e30080e7          	jalr	-464(ra) # 80005140 <fdalloc>
    80005318:	84aa                	mv	s1,a0
    return -1;
    8000531a:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000531c:	00054863          	bltz	a0,8000532c <sys_dup+0x44>
  filedup(f);
    80005320:	854a                	mv	a0,s2
    80005322:	fffff097          	auipc	ra,0xfffff
    80005326:	368080e7          	jalr	872(ra) # 8000468a <filedup>
  return fd;
    8000532a:	87a6                	mv	a5,s1
}
    8000532c:	853e                	mv	a0,a5
    8000532e:	70a2                	ld	ra,40(sp)
    80005330:	7402                	ld	s0,32(sp)
    80005332:	64e2                	ld	s1,24(sp)
    80005334:	6942                	ld	s2,16(sp)
    80005336:	6145                	addi	sp,sp,48
    80005338:	8082                	ret

000000008000533a <sys_read>:
{
    8000533a:	7179                	addi	sp,sp,-48
    8000533c:	f406                	sd	ra,40(sp)
    8000533e:	f022                	sd	s0,32(sp)
    80005340:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005342:	fe840613          	addi	a2,s0,-24
    80005346:	4581                	li	a1,0
    80005348:	4501                	li	a0,0
    8000534a:	00000097          	auipc	ra,0x0
    8000534e:	d8e080e7          	jalr	-626(ra) # 800050d8 <argfd>
    return -1;
    80005352:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005354:	04054163          	bltz	a0,80005396 <sys_read+0x5c>
    80005358:	fe440593          	addi	a1,s0,-28
    8000535c:	4509                	li	a0,2
    8000535e:	ffffe097          	auipc	ra,0xffffe
    80005362:	8fe080e7          	jalr	-1794(ra) # 80002c5c <argint>
    return -1;
    80005366:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005368:	02054763          	bltz	a0,80005396 <sys_read+0x5c>
    8000536c:	fd840593          	addi	a1,s0,-40
    80005370:	4505                	li	a0,1
    80005372:	ffffe097          	auipc	ra,0xffffe
    80005376:	90c080e7          	jalr	-1780(ra) # 80002c7e <argaddr>
    return -1;
    8000537a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000537c:	00054d63          	bltz	a0,80005396 <sys_read+0x5c>
  return fileread(f, p, n);
    80005380:	fe442603          	lw	a2,-28(s0)
    80005384:	fd843583          	ld	a1,-40(s0)
    80005388:	fe843503          	ld	a0,-24(s0)
    8000538c:	fffff097          	auipc	ra,0xfffff
    80005390:	48a080e7          	jalr	1162(ra) # 80004816 <fileread>
    80005394:	87aa                	mv	a5,a0
}
    80005396:	853e                	mv	a0,a5
    80005398:	70a2                	ld	ra,40(sp)
    8000539a:	7402                	ld	s0,32(sp)
    8000539c:	6145                	addi	sp,sp,48
    8000539e:	8082                	ret

00000000800053a0 <sys_write>:
{
    800053a0:	7179                	addi	sp,sp,-48
    800053a2:	f406                	sd	ra,40(sp)
    800053a4:	f022                	sd	s0,32(sp)
    800053a6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053a8:	fe840613          	addi	a2,s0,-24
    800053ac:	4581                	li	a1,0
    800053ae:	4501                	li	a0,0
    800053b0:	00000097          	auipc	ra,0x0
    800053b4:	d28080e7          	jalr	-728(ra) # 800050d8 <argfd>
    return -1;
    800053b8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053ba:	04054163          	bltz	a0,800053fc <sys_write+0x5c>
    800053be:	fe440593          	addi	a1,s0,-28
    800053c2:	4509                	li	a0,2
    800053c4:	ffffe097          	auipc	ra,0xffffe
    800053c8:	898080e7          	jalr	-1896(ra) # 80002c5c <argint>
    return -1;
    800053cc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053ce:	02054763          	bltz	a0,800053fc <sys_write+0x5c>
    800053d2:	fd840593          	addi	a1,s0,-40
    800053d6:	4505                	li	a0,1
    800053d8:	ffffe097          	auipc	ra,0xffffe
    800053dc:	8a6080e7          	jalr	-1882(ra) # 80002c7e <argaddr>
    return -1;
    800053e0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053e2:	00054d63          	bltz	a0,800053fc <sys_write+0x5c>
  return filewrite(f, p, n);
    800053e6:	fe442603          	lw	a2,-28(s0)
    800053ea:	fd843583          	ld	a1,-40(s0)
    800053ee:	fe843503          	ld	a0,-24(s0)
    800053f2:	fffff097          	auipc	ra,0xfffff
    800053f6:	4e6080e7          	jalr	1254(ra) # 800048d8 <filewrite>
    800053fa:	87aa                	mv	a5,a0
}
    800053fc:	853e                	mv	a0,a5
    800053fe:	70a2                	ld	ra,40(sp)
    80005400:	7402                	ld	s0,32(sp)
    80005402:	6145                	addi	sp,sp,48
    80005404:	8082                	ret

0000000080005406 <sys_close>:
{
    80005406:	1101                	addi	sp,sp,-32
    80005408:	ec06                	sd	ra,24(sp)
    8000540a:	e822                	sd	s0,16(sp)
    8000540c:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000540e:	fe040613          	addi	a2,s0,-32
    80005412:	fec40593          	addi	a1,s0,-20
    80005416:	4501                	li	a0,0
    80005418:	00000097          	auipc	ra,0x0
    8000541c:	cc0080e7          	jalr	-832(ra) # 800050d8 <argfd>
    return -1;
    80005420:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005422:	02054463          	bltz	a0,8000544a <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005426:	ffffc097          	auipc	ra,0xffffc
    8000542a:	64c080e7          	jalr	1612(ra) # 80001a72 <myproc>
    8000542e:	fec42783          	lw	a5,-20(s0)
    80005432:	07e9                	addi	a5,a5,26
    80005434:	078e                	slli	a5,a5,0x3
    80005436:	953e                	add	a0,a0,a5
    80005438:	00053023          	sd	zero,0(a0)
  fileclose(f);
    8000543c:	fe043503          	ld	a0,-32(s0)
    80005440:	fffff097          	auipc	ra,0xfffff
    80005444:	29c080e7          	jalr	668(ra) # 800046dc <fileclose>
  return 0;
    80005448:	4781                	li	a5,0
}
    8000544a:	853e                	mv	a0,a5
    8000544c:	60e2                	ld	ra,24(sp)
    8000544e:	6442                	ld	s0,16(sp)
    80005450:	6105                	addi	sp,sp,32
    80005452:	8082                	ret

0000000080005454 <sys_fstat>:
{
    80005454:	1101                	addi	sp,sp,-32
    80005456:	ec06                	sd	ra,24(sp)
    80005458:	e822                	sd	s0,16(sp)
    8000545a:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000545c:	fe840613          	addi	a2,s0,-24
    80005460:	4581                	li	a1,0
    80005462:	4501                	li	a0,0
    80005464:	00000097          	auipc	ra,0x0
    80005468:	c74080e7          	jalr	-908(ra) # 800050d8 <argfd>
    return -1;
    8000546c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000546e:	02054563          	bltz	a0,80005498 <sys_fstat+0x44>
    80005472:	fe040593          	addi	a1,s0,-32
    80005476:	4505                	li	a0,1
    80005478:	ffffe097          	auipc	ra,0xffffe
    8000547c:	806080e7          	jalr	-2042(ra) # 80002c7e <argaddr>
    return -1;
    80005480:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005482:	00054b63          	bltz	a0,80005498 <sys_fstat+0x44>
  return filestat(f, st);
    80005486:	fe043583          	ld	a1,-32(s0)
    8000548a:	fe843503          	ld	a0,-24(s0)
    8000548e:	fffff097          	auipc	ra,0xfffff
    80005492:	316080e7          	jalr	790(ra) # 800047a4 <filestat>
    80005496:	87aa                	mv	a5,a0
}
    80005498:	853e                	mv	a0,a5
    8000549a:	60e2                	ld	ra,24(sp)
    8000549c:	6442                	ld	s0,16(sp)
    8000549e:	6105                	addi	sp,sp,32
    800054a0:	8082                	ret

00000000800054a2 <sys_link>:
{
    800054a2:	7169                	addi	sp,sp,-304
    800054a4:	f606                	sd	ra,296(sp)
    800054a6:	f222                	sd	s0,288(sp)
    800054a8:	ee26                	sd	s1,280(sp)
    800054aa:	ea4a                	sd	s2,272(sp)
    800054ac:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054ae:	08000613          	li	a2,128
    800054b2:	ed040593          	addi	a1,s0,-304
    800054b6:	4501                	li	a0,0
    800054b8:	ffffd097          	auipc	ra,0xffffd
    800054bc:	7e8080e7          	jalr	2024(ra) # 80002ca0 <argstr>
    return -1;
    800054c0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054c2:	10054e63          	bltz	a0,800055de <sys_link+0x13c>
    800054c6:	08000613          	li	a2,128
    800054ca:	f5040593          	addi	a1,s0,-176
    800054ce:	4505                	li	a0,1
    800054d0:	ffffd097          	auipc	ra,0xffffd
    800054d4:	7d0080e7          	jalr	2000(ra) # 80002ca0 <argstr>
    return -1;
    800054d8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054da:	10054263          	bltz	a0,800055de <sys_link+0x13c>
  begin_op();
    800054de:	fffff097          	auipc	ra,0xfffff
    800054e2:	d36080e7          	jalr	-714(ra) # 80004214 <begin_op>
  if((ip = namei(old)) == 0){
    800054e6:	ed040513          	addi	a0,s0,-304
    800054ea:	fffff097          	auipc	ra,0xfffff
    800054ee:	b0a080e7          	jalr	-1270(ra) # 80003ff4 <namei>
    800054f2:	84aa                	mv	s1,a0
    800054f4:	c551                	beqz	a0,80005580 <sys_link+0xde>
  ilock(ip);
    800054f6:	ffffe097          	auipc	ra,0xffffe
    800054fa:	342080e7          	jalr	834(ra) # 80003838 <ilock>
  if(ip->type == T_DIR){
    800054fe:	04449703          	lh	a4,68(s1)
    80005502:	4785                	li	a5,1
    80005504:	08f70463          	beq	a4,a5,8000558c <sys_link+0xea>
  ip->nlink++;
    80005508:	04a4d783          	lhu	a5,74(s1)
    8000550c:	2785                	addiw	a5,a5,1
    8000550e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005512:	8526                	mv	a0,s1
    80005514:	ffffe097          	auipc	ra,0xffffe
    80005518:	258080e7          	jalr	600(ra) # 8000376c <iupdate>
  iunlock(ip);
    8000551c:	8526                	mv	a0,s1
    8000551e:	ffffe097          	auipc	ra,0xffffe
    80005522:	3dc080e7          	jalr	988(ra) # 800038fa <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005526:	fd040593          	addi	a1,s0,-48
    8000552a:	f5040513          	addi	a0,s0,-176
    8000552e:	fffff097          	auipc	ra,0xfffff
    80005532:	ae4080e7          	jalr	-1308(ra) # 80004012 <nameiparent>
    80005536:	892a                	mv	s2,a0
    80005538:	c935                	beqz	a0,800055ac <sys_link+0x10a>
  ilock(dp);
    8000553a:	ffffe097          	auipc	ra,0xffffe
    8000553e:	2fe080e7          	jalr	766(ra) # 80003838 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005542:	00092703          	lw	a4,0(s2)
    80005546:	409c                	lw	a5,0(s1)
    80005548:	04f71d63          	bne	a4,a5,800055a2 <sys_link+0x100>
    8000554c:	40d0                	lw	a2,4(s1)
    8000554e:	fd040593          	addi	a1,s0,-48
    80005552:	854a                	mv	a0,s2
    80005554:	fffff097          	auipc	ra,0xfffff
    80005558:	9de080e7          	jalr	-1570(ra) # 80003f32 <dirlink>
    8000555c:	04054363          	bltz	a0,800055a2 <sys_link+0x100>
  iunlockput(dp);
    80005560:	854a                	mv	a0,s2
    80005562:	ffffe097          	auipc	ra,0xffffe
    80005566:	538080e7          	jalr	1336(ra) # 80003a9a <iunlockput>
  iput(ip);
    8000556a:	8526                	mv	a0,s1
    8000556c:	ffffe097          	auipc	ra,0xffffe
    80005570:	486080e7          	jalr	1158(ra) # 800039f2 <iput>
  end_op();
    80005574:	fffff097          	auipc	ra,0xfffff
    80005578:	d1e080e7          	jalr	-738(ra) # 80004292 <end_op>
  return 0;
    8000557c:	4781                	li	a5,0
    8000557e:	a085                	j	800055de <sys_link+0x13c>
    end_op();
    80005580:	fffff097          	auipc	ra,0xfffff
    80005584:	d12080e7          	jalr	-750(ra) # 80004292 <end_op>
    return -1;
    80005588:	57fd                	li	a5,-1
    8000558a:	a891                	j	800055de <sys_link+0x13c>
    iunlockput(ip);
    8000558c:	8526                	mv	a0,s1
    8000558e:	ffffe097          	auipc	ra,0xffffe
    80005592:	50c080e7          	jalr	1292(ra) # 80003a9a <iunlockput>
    end_op();
    80005596:	fffff097          	auipc	ra,0xfffff
    8000559a:	cfc080e7          	jalr	-772(ra) # 80004292 <end_op>
    return -1;
    8000559e:	57fd                	li	a5,-1
    800055a0:	a83d                	j	800055de <sys_link+0x13c>
    iunlockput(dp);
    800055a2:	854a                	mv	a0,s2
    800055a4:	ffffe097          	auipc	ra,0xffffe
    800055a8:	4f6080e7          	jalr	1270(ra) # 80003a9a <iunlockput>
  ilock(ip);
    800055ac:	8526                	mv	a0,s1
    800055ae:	ffffe097          	auipc	ra,0xffffe
    800055b2:	28a080e7          	jalr	650(ra) # 80003838 <ilock>
  ip->nlink--;
    800055b6:	04a4d783          	lhu	a5,74(s1)
    800055ba:	37fd                	addiw	a5,a5,-1
    800055bc:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055c0:	8526                	mv	a0,s1
    800055c2:	ffffe097          	auipc	ra,0xffffe
    800055c6:	1aa080e7          	jalr	426(ra) # 8000376c <iupdate>
  iunlockput(ip);
    800055ca:	8526                	mv	a0,s1
    800055cc:	ffffe097          	auipc	ra,0xffffe
    800055d0:	4ce080e7          	jalr	1230(ra) # 80003a9a <iunlockput>
  end_op();
    800055d4:	fffff097          	auipc	ra,0xfffff
    800055d8:	cbe080e7          	jalr	-834(ra) # 80004292 <end_op>
  return -1;
    800055dc:	57fd                	li	a5,-1
}
    800055de:	853e                	mv	a0,a5
    800055e0:	70b2                	ld	ra,296(sp)
    800055e2:	7412                	ld	s0,288(sp)
    800055e4:	64f2                	ld	s1,280(sp)
    800055e6:	6952                	ld	s2,272(sp)
    800055e8:	6155                	addi	sp,sp,304
    800055ea:	8082                	ret

00000000800055ec <sys_unlink>:
{
    800055ec:	7151                	addi	sp,sp,-240
    800055ee:	f586                	sd	ra,232(sp)
    800055f0:	f1a2                	sd	s0,224(sp)
    800055f2:	eda6                	sd	s1,216(sp)
    800055f4:	e9ca                	sd	s2,208(sp)
    800055f6:	e5ce                	sd	s3,200(sp)
    800055f8:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800055fa:	08000613          	li	a2,128
    800055fe:	f3040593          	addi	a1,s0,-208
    80005602:	4501                	li	a0,0
    80005604:	ffffd097          	auipc	ra,0xffffd
    80005608:	69c080e7          	jalr	1692(ra) # 80002ca0 <argstr>
    8000560c:	18054163          	bltz	a0,8000578e <sys_unlink+0x1a2>
  begin_op();
    80005610:	fffff097          	auipc	ra,0xfffff
    80005614:	c04080e7          	jalr	-1020(ra) # 80004214 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005618:	fb040593          	addi	a1,s0,-80
    8000561c:	f3040513          	addi	a0,s0,-208
    80005620:	fffff097          	auipc	ra,0xfffff
    80005624:	9f2080e7          	jalr	-1550(ra) # 80004012 <nameiparent>
    80005628:	84aa                	mv	s1,a0
    8000562a:	c979                	beqz	a0,80005700 <sys_unlink+0x114>
  ilock(dp);
    8000562c:	ffffe097          	auipc	ra,0xffffe
    80005630:	20c080e7          	jalr	524(ra) # 80003838 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005634:	00003597          	auipc	a1,0x3
    80005638:	16458593          	addi	a1,a1,356 # 80008798 <syscalls+0x2c0>
    8000563c:	fb040513          	addi	a0,s0,-80
    80005640:	ffffe097          	auipc	ra,0xffffe
    80005644:	6c2080e7          	jalr	1730(ra) # 80003d02 <namecmp>
    80005648:	14050a63          	beqz	a0,8000579c <sys_unlink+0x1b0>
    8000564c:	00003597          	auipc	a1,0x3
    80005650:	15458593          	addi	a1,a1,340 # 800087a0 <syscalls+0x2c8>
    80005654:	fb040513          	addi	a0,s0,-80
    80005658:	ffffe097          	auipc	ra,0xffffe
    8000565c:	6aa080e7          	jalr	1706(ra) # 80003d02 <namecmp>
    80005660:	12050e63          	beqz	a0,8000579c <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005664:	f2c40613          	addi	a2,s0,-212
    80005668:	fb040593          	addi	a1,s0,-80
    8000566c:	8526                	mv	a0,s1
    8000566e:	ffffe097          	auipc	ra,0xffffe
    80005672:	6ae080e7          	jalr	1710(ra) # 80003d1c <dirlookup>
    80005676:	892a                	mv	s2,a0
    80005678:	12050263          	beqz	a0,8000579c <sys_unlink+0x1b0>
  ilock(ip);
    8000567c:	ffffe097          	auipc	ra,0xffffe
    80005680:	1bc080e7          	jalr	444(ra) # 80003838 <ilock>
  if(ip->nlink < 1)
    80005684:	04a91783          	lh	a5,74(s2)
    80005688:	08f05263          	blez	a5,8000570c <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000568c:	04491703          	lh	a4,68(s2)
    80005690:	4785                	li	a5,1
    80005692:	08f70563          	beq	a4,a5,8000571c <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005696:	4641                	li	a2,16
    80005698:	4581                	li	a1,0
    8000569a:	fc040513          	addi	a0,s0,-64
    8000569e:	ffffb097          	auipc	ra,0xffffb
    800056a2:	62e080e7          	jalr	1582(ra) # 80000ccc <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056a6:	4741                	li	a4,16
    800056a8:	f2c42683          	lw	a3,-212(s0)
    800056ac:	fc040613          	addi	a2,s0,-64
    800056b0:	4581                	li	a1,0
    800056b2:	8526                	mv	a0,s1
    800056b4:	ffffe097          	auipc	ra,0xffffe
    800056b8:	530080e7          	jalr	1328(ra) # 80003be4 <writei>
    800056bc:	47c1                	li	a5,16
    800056be:	0af51563          	bne	a0,a5,80005768 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800056c2:	04491703          	lh	a4,68(s2)
    800056c6:	4785                	li	a5,1
    800056c8:	0af70863          	beq	a4,a5,80005778 <sys_unlink+0x18c>
  iunlockput(dp);
    800056cc:	8526                	mv	a0,s1
    800056ce:	ffffe097          	auipc	ra,0xffffe
    800056d2:	3cc080e7          	jalr	972(ra) # 80003a9a <iunlockput>
  ip->nlink--;
    800056d6:	04a95783          	lhu	a5,74(s2)
    800056da:	37fd                	addiw	a5,a5,-1
    800056dc:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800056e0:	854a                	mv	a0,s2
    800056e2:	ffffe097          	auipc	ra,0xffffe
    800056e6:	08a080e7          	jalr	138(ra) # 8000376c <iupdate>
  iunlockput(ip);
    800056ea:	854a                	mv	a0,s2
    800056ec:	ffffe097          	auipc	ra,0xffffe
    800056f0:	3ae080e7          	jalr	942(ra) # 80003a9a <iunlockput>
  end_op();
    800056f4:	fffff097          	auipc	ra,0xfffff
    800056f8:	b9e080e7          	jalr	-1122(ra) # 80004292 <end_op>
  return 0;
    800056fc:	4501                	li	a0,0
    800056fe:	a84d                	j	800057b0 <sys_unlink+0x1c4>
    end_op();
    80005700:	fffff097          	auipc	ra,0xfffff
    80005704:	b92080e7          	jalr	-1134(ra) # 80004292 <end_op>
    return -1;
    80005708:	557d                	li	a0,-1
    8000570a:	a05d                	j	800057b0 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000570c:	00003517          	auipc	a0,0x3
    80005710:	0bc50513          	addi	a0,a0,188 # 800087c8 <syscalls+0x2f0>
    80005714:	ffffb097          	auipc	ra,0xffffb
    80005718:	e26080e7          	jalr	-474(ra) # 8000053a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000571c:	04c92703          	lw	a4,76(s2)
    80005720:	02000793          	li	a5,32
    80005724:	f6e7f9e3          	bgeu	a5,a4,80005696 <sys_unlink+0xaa>
    80005728:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000572c:	4741                	li	a4,16
    8000572e:	86ce                	mv	a3,s3
    80005730:	f1840613          	addi	a2,s0,-232
    80005734:	4581                	li	a1,0
    80005736:	854a                	mv	a0,s2
    80005738:	ffffe097          	auipc	ra,0xffffe
    8000573c:	3b4080e7          	jalr	948(ra) # 80003aec <readi>
    80005740:	47c1                	li	a5,16
    80005742:	00f51b63          	bne	a0,a5,80005758 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005746:	f1845783          	lhu	a5,-232(s0)
    8000574a:	e7a1                	bnez	a5,80005792 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000574c:	29c1                	addiw	s3,s3,16
    8000574e:	04c92783          	lw	a5,76(s2)
    80005752:	fcf9ede3          	bltu	s3,a5,8000572c <sys_unlink+0x140>
    80005756:	b781                	j	80005696 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005758:	00003517          	auipc	a0,0x3
    8000575c:	08850513          	addi	a0,a0,136 # 800087e0 <syscalls+0x308>
    80005760:	ffffb097          	auipc	ra,0xffffb
    80005764:	dda080e7          	jalr	-550(ra) # 8000053a <panic>
    panic("unlink: writei");
    80005768:	00003517          	auipc	a0,0x3
    8000576c:	09050513          	addi	a0,a0,144 # 800087f8 <syscalls+0x320>
    80005770:	ffffb097          	auipc	ra,0xffffb
    80005774:	dca080e7          	jalr	-566(ra) # 8000053a <panic>
    dp->nlink--;
    80005778:	04a4d783          	lhu	a5,74(s1)
    8000577c:	37fd                	addiw	a5,a5,-1
    8000577e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005782:	8526                	mv	a0,s1
    80005784:	ffffe097          	auipc	ra,0xffffe
    80005788:	fe8080e7          	jalr	-24(ra) # 8000376c <iupdate>
    8000578c:	b781                	j	800056cc <sys_unlink+0xe0>
    return -1;
    8000578e:	557d                	li	a0,-1
    80005790:	a005                	j	800057b0 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005792:	854a                	mv	a0,s2
    80005794:	ffffe097          	auipc	ra,0xffffe
    80005798:	306080e7          	jalr	774(ra) # 80003a9a <iunlockput>
  iunlockput(dp);
    8000579c:	8526                	mv	a0,s1
    8000579e:	ffffe097          	auipc	ra,0xffffe
    800057a2:	2fc080e7          	jalr	764(ra) # 80003a9a <iunlockput>
  end_op();
    800057a6:	fffff097          	auipc	ra,0xfffff
    800057aa:	aec080e7          	jalr	-1300(ra) # 80004292 <end_op>
  return -1;
    800057ae:	557d                	li	a0,-1
}
    800057b0:	70ae                	ld	ra,232(sp)
    800057b2:	740e                	ld	s0,224(sp)
    800057b4:	64ee                	ld	s1,216(sp)
    800057b6:	694e                	ld	s2,208(sp)
    800057b8:	69ae                	ld	s3,200(sp)
    800057ba:	616d                	addi	sp,sp,240
    800057bc:	8082                	ret

00000000800057be <sys_open>:

uint64
sys_open(void)
{
    800057be:	7131                	addi	sp,sp,-192
    800057c0:	fd06                	sd	ra,184(sp)
    800057c2:	f922                	sd	s0,176(sp)
    800057c4:	f526                	sd	s1,168(sp)
    800057c6:	f14a                	sd	s2,160(sp)
    800057c8:	ed4e                	sd	s3,152(sp)
    800057ca:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800057cc:	08000613          	li	a2,128
    800057d0:	f5040593          	addi	a1,s0,-176
    800057d4:	4501                	li	a0,0
    800057d6:	ffffd097          	auipc	ra,0xffffd
    800057da:	4ca080e7          	jalr	1226(ra) # 80002ca0 <argstr>
    return -1;
    800057de:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800057e0:	0c054163          	bltz	a0,800058a2 <sys_open+0xe4>
    800057e4:	f4c40593          	addi	a1,s0,-180
    800057e8:	4505                	li	a0,1
    800057ea:	ffffd097          	auipc	ra,0xffffd
    800057ee:	472080e7          	jalr	1138(ra) # 80002c5c <argint>
    800057f2:	0a054863          	bltz	a0,800058a2 <sys_open+0xe4>

  begin_op();
    800057f6:	fffff097          	auipc	ra,0xfffff
    800057fa:	a1e080e7          	jalr	-1506(ra) # 80004214 <begin_op>

  if(omode & O_CREATE){
    800057fe:	f4c42783          	lw	a5,-180(s0)
    80005802:	2007f793          	andi	a5,a5,512
    80005806:	cbdd                	beqz	a5,800058bc <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005808:	4681                	li	a3,0
    8000580a:	4601                	li	a2,0
    8000580c:	4589                	li	a1,2
    8000580e:	f5040513          	addi	a0,s0,-176
    80005812:	00000097          	auipc	ra,0x0
    80005816:	970080e7          	jalr	-1680(ra) # 80005182 <create>
    8000581a:	892a                	mv	s2,a0
    if(ip == 0){
    8000581c:	c959                	beqz	a0,800058b2 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000581e:	04491703          	lh	a4,68(s2)
    80005822:	478d                	li	a5,3
    80005824:	00f71763          	bne	a4,a5,80005832 <sys_open+0x74>
    80005828:	04695703          	lhu	a4,70(s2)
    8000582c:	47a5                	li	a5,9
    8000582e:	0ce7ec63          	bltu	a5,a4,80005906 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005832:	fffff097          	auipc	ra,0xfffff
    80005836:	dee080e7          	jalr	-530(ra) # 80004620 <filealloc>
    8000583a:	89aa                	mv	s3,a0
    8000583c:	10050263          	beqz	a0,80005940 <sys_open+0x182>
    80005840:	00000097          	auipc	ra,0x0
    80005844:	900080e7          	jalr	-1792(ra) # 80005140 <fdalloc>
    80005848:	84aa                	mv	s1,a0
    8000584a:	0e054663          	bltz	a0,80005936 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000584e:	04491703          	lh	a4,68(s2)
    80005852:	478d                	li	a5,3
    80005854:	0cf70463          	beq	a4,a5,8000591c <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005858:	4789                	li	a5,2
    8000585a:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000585e:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005862:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005866:	f4c42783          	lw	a5,-180(s0)
    8000586a:	0017c713          	xori	a4,a5,1
    8000586e:	8b05                	andi	a4,a4,1
    80005870:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005874:	0037f713          	andi	a4,a5,3
    80005878:	00e03733          	snez	a4,a4
    8000587c:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005880:	4007f793          	andi	a5,a5,1024
    80005884:	c791                	beqz	a5,80005890 <sys_open+0xd2>
    80005886:	04491703          	lh	a4,68(s2)
    8000588a:	4789                	li	a5,2
    8000588c:	08f70f63          	beq	a4,a5,8000592a <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005890:	854a                	mv	a0,s2
    80005892:	ffffe097          	auipc	ra,0xffffe
    80005896:	068080e7          	jalr	104(ra) # 800038fa <iunlock>
  end_op();
    8000589a:	fffff097          	auipc	ra,0xfffff
    8000589e:	9f8080e7          	jalr	-1544(ra) # 80004292 <end_op>

  return fd;
}
    800058a2:	8526                	mv	a0,s1
    800058a4:	70ea                	ld	ra,184(sp)
    800058a6:	744a                	ld	s0,176(sp)
    800058a8:	74aa                	ld	s1,168(sp)
    800058aa:	790a                	ld	s2,160(sp)
    800058ac:	69ea                	ld	s3,152(sp)
    800058ae:	6129                	addi	sp,sp,192
    800058b0:	8082                	ret
      end_op();
    800058b2:	fffff097          	auipc	ra,0xfffff
    800058b6:	9e0080e7          	jalr	-1568(ra) # 80004292 <end_op>
      return -1;
    800058ba:	b7e5                	j	800058a2 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800058bc:	f5040513          	addi	a0,s0,-176
    800058c0:	ffffe097          	auipc	ra,0xffffe
    800058c4:	734080e7          	jalr	1844(ra) # 80003ff4 <namei>
    800058c8:	892a                	mv	s2,a0
    800058ca:	c905                	beqz	a0,800058fa <sys_open+0x13c>
    ilock(ip);
    800058cc:	ffffe097          	auipc	ra,0xffffe
    800058d0:	f6c080e7          	jalr	-148(ra) # 80003838 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800058d4:	04491703          	lh	a4,68(s2)
    800058d8:	4785                	li	a5,1
    800058da:	f4f712e3          	bne	a4,a5,8000581e <sys_open+0x60>
    800058de:	f4c42783          	lw	a5,-180(s0)
    800058e2:	dba1                	beqz	a5,80005832 <sys_open+0x74>
      iunlockput(ip);
    800058e4:	854a                	mv	a0,s2
    800058e6:	ffffe097          	auipc	ra,0xffffe
    800058ea:	1b4080e7          	jalr	436(ra) # 80003a9a <iunlockput>
      end_op();
    800058ee:	fffff097          	auipc	ra,0xfffff
    800058f2:	9a4080e7          	jalr	-1628(ra) # 80004292 <end_op>
      return -1;
    800058f6:	54fd                	li	s1,-1
    800058f8:	b76d                	j	800058a2 <sys_open+0xe4>
      end_op();
    800058fa:	fffff097          	auipc	ra,0xfffff
    800058fe:	998080e7          	jalr	-1640(ra) # 80004292 <end_op>
      return -1;
    80005902:	54fd                	li	s1,-1
    80005904:	bf79                	j	800058a2 <sys_open+0xe4>
    iunlockput(ip);
    80005906:	854a                	mv	a0,s2
    80005908:	ffffe097          	auipc	ra,0xffffe
    8000590c:	192080e7          	jalr	402(ra) # 80003a9a <iunlockput>
    end_op();
    80005910:	fffff097          	auipc	ra,0xfffff
    80005914:	982080e7          	jalr	-1662(ra) # 80004292 <end_op>
    return -1;
    80005918:	54fd                	li	s1,-1
    8000591a:	b761                	j	800058a2 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000591c:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005920:	04691783          	lh	a5,70(s2)
    80005924:	02f99223          	sh	a5,36(s3)
    80005928:	bf2d                	j	80005862 <sys_open+0xa4>
    itrunc(ip);
    8000592a:	854a                	mv	a0,s2
    8000592c:	ffffe097          	auipc	ra,0xffffe
    80005930:	01a080e7          	jalr	26(ra) # 80003946 <itrunc>
    80005934:	bfb1                	j	80005890 <sys_open+0xd2>
      fileclose(f);
    80005936:	854e                	mv	a0,s3
    80005938:	fffff097          	auipc	ra,0xfffff
    8000593c:	da4080e7          	jalr	-604(ra) # 800046dc <fileclose>
    iunlockput(ip);
    80005940:	854a                	mv	a0,s2
    80005942:	ffffe097          	auipc	ra,0xffffe
    80005946:	158080e7          	jalr	344(ra) # 80003a9a <iunlockput>
    end_op();
    8000594a:	fffff097          	auipc	ra,0xfffff
    8000594e:	948080e7          	jalr	-1720(ra) # 80004292 <end_op>
    return -1;
    80005952:	54fd                	li	s1,-1
    80005954:	b7b9                	j	800058a2 <sys_open+0xe4>

0000000080005956 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005956:	7175                	addi	sp,sp,-144
    80005958:	e506                	sd	ra,136(sp)
    8000595a:	e122                	sd	s0,128(sp)
    8000595c:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000595e:	fffff097          	auipc	ra,0xfffff
    80005962:	8b6080e7          	jalr	-1866(ra) # 80004214 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005966:	08000613          	li	a2,128
    8000596a:	f7040593          	addi	a1,s0,-144
    8000596e:	4501                	li	a0,0
    80005970:	ffffd097          	auipc	ra,0xffffd
    80005974:	330080e7          	jalr	816(ra) # 80002ca0 <argstr>
    80005978:	02054963          	bltz	a0,800059aa <sys_mkdir+0x54>
    8000597c:	4681                	li	a3,0
    8000597e:	4601                	li	a2,0
    80005980:	4585                	li	a1,1
    80005982:	f7040513          	addi	a0,s0,-144
    80005986:	fffff097          	auipc	ra,0xfffff
    8000598a:	7fc080e7          	jalr	2044(ra) # 80005182 <create>
    8000598e:	cd11                	beqz	a0,800059aa <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005990:	ffffe097          	auipc	ra,0xffffe
    80005994:	10a080e7          	jalr	266(ra) # 80003a9a <iunlockput>
  end_op();
    80005998:	fffff097          	auipc	ra,0xfffff
    8000599c:	8fa080e7          	jalr	-1798(ra) # 80004292 <end_op>
  return 0;
    800059a0:	4501                	li	a0,0
}
    800059a2:	60aa                	ld	ra,136(sp)
    800059a4:	640a                	ld	s0,128(sp)
    800059a6:	6149                	addi	sp,sp,144
    800059a8:	8082                	ret
    end_op();
    800059aa:	fffff097          	auipc	ra,0xfffff
    800059ae:	8e8080e7          	jalr	-1816(ra) # 80004292 <end_op>
    return -1;
    800059b2:	557d                	li	a0,-1
    800059b4:	b7fd                	j	800059a2 <sys_mkdir+0x4c>

00000000800059b6 <sys_mknod>:

uint64
sys_mknod(void)
{
    800059b6:	7135                	addi	sp,sp,-160
    800059b8:	ed06                	sd	ra,152(sp)
    800059ba:	e922                	sd	s0,144(sp)
    800059bc:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800059be:	fffff097          	auipc	ra,0xfffff
    800059c2:	856080e7          	jalr	-1962(ra) # 80004214 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059c6:	08000613          	li	a2,128
    800059ca:	f7040593          	addi	a1,s0,-144
    800059ce:	4501                	li	a0,0
    800059d0:	ffffd097          	auipc	ra,0xffffd
    800059d4:	2d0080e7          	jalr	720(ra) # 80002ca0 <argstr>
    800059d8:	04054a63          	bltz	a0,80005a2c <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800059dc:	f6c40593          	addi	a1,s0,-148
    800059e0:	4505                	li	a0,1
    800059e2:	ffffd097          	auipc	ra,0xffffd
    800059e6:	27a080e7          	jalr	634(ra) # 80002c5c <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059ea:	04054163          	bltz	a0,80005a2c <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800059ee:	f6840593          	addi	a1,s0,-152
    800059f2:	4509                	li	a0,2
    800059f4:	ffffd097          	auipc	ra,0xffffd
    800059f8:	268080e7          	jalr	616(ra) # 80002c5c <argint>
     argint(1, &major) < 0 ||
    800059fc:	02054863          	bltz	a0,80005a2c <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005a00:	f6841683          	lh	a3,-152(s0)
    80005a04:	f6c41603          	lh	a2,-148(s0)
    80005a08:	458d                	li	a1,3
    80005a0a:	f7040513          	addi	a0,s0,-144
    80005a0e:	fffff097          	auipc	ra,0xfffff
    80005a12:	774080e7          	jalr	1908(ra) # 80005182 <create>
     argint(2, &minor) < 0 ||
    80005a16:	c919                	beqz	a0,80005a2c <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a18:	ffffe097          	auipc	ra,0xffffe
    80005a1c:	082080e7          	jalr	130(ra) # 80003a9a <iunlockput>
  end_op();
    80005a20:	fffff097          	auipc	ra,0xfffff
    80005a24:	872080e7          	jalr	-1934(ra) # 80004292 <end_op>
  return 0;
    80005a28:	4501                	li	a0,0
    80005a2a:	a031                	j	80005a36 <sys_mknod+0x80>
    end_op();
    80005a2c:	fffff097          	auipc	ra,0xfffff
    80005a30:	866080e7          	jalr	-1946(ra) # 80004292 <end_op>
    return -1;
    80005a34:	557d                	li	a0,-1
}
    80005a36:	60ea                	ld	ra,152(sp)
    80005a38:	644a                	ld	s0,144(sp)
    80005a3a:	610d                	addi	sp,sp,160
    80005a3c:	8082                	ret

0000000080005a3e <sys_chdir>:

uint64
sys_chdir(void)
{
    80005a3e:	7135                	addi	sp,sp,-160
    80005a40:	ed06                	sd	ra,152(sp)
    80005a42:	e922                	sd	s0,144(sp)
    80005a44:	e526                	sd	s1,136(sp)
    80005a46:	e14a                	sd	s2,128(sp)
    80005a48:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005a4a:	ffffc097          	auipc	ra,0xffffc
    80005a4e:	028080e7          	jalr	40(ra) # 80001a72 <myproc>
    80005a52:	892a                	mv	s2,a0
  
  begin_op();
    80005a54:	ffffe097          	auipc	ra,0xffffe
    80005a58:	7c0080e7          	jalr	1984(ra) # 80004214 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005a5c:	08000613          	li	a2,128
    80005a60:	f6040593          	addi	a1,s0,-160
    80005a64:	4501                	li	a0,0
    80005a66:	ffffd097          	auipc	ra,0xffffd
    80005a6a:	23a080e7          	jalr	570(ra) # 80002ca0 <argstr>
    80005a6e:	04054b63          	bltz	a0,80005ac4 <sys_chdir+0x86>
    80005a72:	f6040513          	addi	a0,s0,-160
    80005a76:	ffffe097          	auipc	ra,0xffffe
    80005a7a:	57e080e7          	jalr	1406(ra) # 80003ff4 <namei>
    80005a7e:	84aa                	mv	s1,a0
    80005a80:	c131                	beqz	a0,80005ac4 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a82:	ffffe097          	auipc	ra,0xffffe
    80005a86:	db6080e7          	jalr	-586(ra) # 80003838 <ilock>
  if(ip->type != T_DIR){
    80005a8a:	04449703          	lh	a4,68(s1)
    80005a8e:	4785                	li	a5,1
    80005a90:	04f71063          	bne	a4,a5,80005ad0 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a94:	8526                	mv	a0,s1
    80005a96:	ffffe097          	auipc	ra,0xffffe
    80005a9a:	e64080e7          	jalr	-412(ra) # 800038fa <iunlock>
  iput(p->cwd);
    80005a9e:	15093503          	ld	a0,336(s2)
    80005aa2:	ffffe097          	auipc	ra,0xffffe
    80005aa6:	f50080e7          	jalr	-176(ra) # 800039f2 <iput>
  end_op();
    80005aaa:	ffffe097          	auipc	ra,0xffffe
    80005aae:	7e8080e7          	jalr	2024(ra) # 80004292 <end_op>
  p->cwd = ip;
    80005ab2:	14993823          	sd	s1,336(s2)
  return 0;
    80005ab6:	4501                	li	a0,0
}
    80005ab8:	60ea                	ld	ra,152(sp)
    80005aba:	644a                	ld	s0,144(sp)
    80005abc:	64aa                	ld	s1,136(sp)
    80005abe:	690a                	ld	s2,128(sp)
    80005ac0:	610d                	addi	sp,sp,160
    80005ac2:	8082                	ret
    end_op();
    80005ac4:	ffffe097          	auipc	ra,0xffffe
    80005ac8:	7ce080e7          	jalr	1998(ra) # 80004292 <end_op>
    return -1;
    80005acc:	557d                	li	a0,-1
    80005ace:	b7ed                	j	80005ab8 <sys_chdir+0x7a>
    iunlockput(ip);
    80005ad0:	8526                	mv	a0,s1
    80005ad2:	ffffe097          	auipc	ra,0xffffe
    80005ad6:	fc8080e7          	jalr	-56(ra) # 80003a9a <iunlockput>
    end_op();
    80005ada:	ffffe097          	auipc	ra,0xffffe
    80005ade:	7b8080e7          	jalr	1976(ra) # 80004292 <end_op>
    return -1;
    80005ae2:	557d                	li	a0,-1
    80005ae4:	bfd1                	j	80005ab8 <sys_chdir+0x7a>

0000000080005ae6 <sys_exec>:

uint64
sys_exec(void)
{
    80005ae6:	7145                	addi	sp,sp,-464
    80005ae8:	e786                	sd	ra,456(sp)
    80005aea:	e3a2                	sd	s0,448(sp)
    80005aec:	ff26                	sd	s1,440(sp)
    80005aee:	fb4a                	sd	s2,432(sp)
    80005af0:	f74e                	sd	s3,424(sp)
    80005af2:	f352                	sd	s4,416(sp)
    80005af4:	ef56                	sd	s5,408(sp)
    80005af6:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005af8:	08000613          	li	a2,128
    80005afc:	f4040593          	addi	a1,s0,-192
    80005b00:	4501                	li	a0,0
    80005b02:	ffffd097          	auipc	ra,0xffffd
    80005b06:	19e080e7          	jalr	414(ra) # 80002ca0 <argstr>
    return -1;
    80005b0a:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b0c:	0c054b63          	bltz	a0,80005be2 <sys_exec+0xfc>
    80005b10:	e3840593          	addi	a1,s0,-456
    80005b14:	4505                	li	a0,1
    80005b16:	ffffd097          	auipc	ra,0xffffd
    80005b1a:	168080e7          	jalr	360(ra) # 80002c7e <argaddr>
    80005b1e:	0c054263          	bltz	a0,80005be2 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005b22:	10000613          	li	a2,256
    80005b26:	4581                	li	a1,0
    80005b28:	e4040513          	addi	a0,s0,-448
    80005b2c:	ffffb097          	auipc	ra,0xffffb
    80005b30:	1a0080e7          	jalr	416(ra) # 80000ccc <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005b34:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005b38:	89a6                	mv	s3,s1
    80005b3a:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005b3c:	02000a13          	li	s4,32
    80005b40:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005b44:	00391513          	slli	a0,s2,0x3
    80005b48:	e3040593          	addi	a1,s0,-464
    80005b4c:	e3843783          	ld	a5,-456(s0)
    80005b50:	953e                	add	a0,a0,a5
    80005b52:	ffffd097          	auipc	ra,0xffffd
    80005b56:	070080e7          	jalr	112(ra) # 80002bc2 <fetchaddr>
    80005b5a:	02054a63          	bltz	a0,80005b8e <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005b5e:	e3043783          	ld	a5,-464(s0)
    80005b62:	c3b9                	beqz	a5,80005ba8 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005b64:	ffffb097          	auipc	ra,0xffffb
    80005b68:	f7c080e7          	jalr	-132(ra) # 80000ae0 <kalloc>
    80005b6c:	85aa                	mv	a1,a0
    80005b6e:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005b72:	cd11                	beqz	a0,80005b8e <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005b74:	6605                	lui	a2,0x1
    80005b76:	e3043503          	ld	a0,-464(s0)
    80005b7a:	ffffd097          	auipc	ra,0xffffd
    80005b7e:	09a080e7          	jalr	154(ra) # 80002c14 <fetchstr>
    80005b82:	00054663          	bltz	a0,80005b8e <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005b86:	0905                	addi	s2,s2,1
    80005b88:	09a1                	addi	s3,s3,8
    80005b8a:	fb491be3          	bne	s2,s4,80005b40 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b8e:	f4040913          	addi	s2,s0,-192
    80005b92:	6088                	ld	a0,0(s1)
    80005b94:	c531                	beqz	a0,80005be0 <sys_exec+0xfa>
    kfree(argv[i]);
    80005b96:	ffffb097          	auipc	ra,0xffffb
    80005b9a:	e4c080e7          	jalr	-436(ra) # 800009e2 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b9e:	04a1                	addi	s1,s1,8
    80005ba0:	ff2499e3          	bne	s1,s2,80005b92 <sys_exec+0xac>
  return -1;
    80005ba4:	597d                	li	s2,-1
    80005ba6:	a835                	j	80005be2 <sys_exec+0xfc>
      argv[i] = 0;
    80005ba8:	0a8e                	slli	s5,s5,0x3
    80005baa:	fc0a8793          	addi	a5,s5,-64 # ffffffffffffefc0 <end+0xffffffff7ffd7c40>
    80005bae:	00878ab3          	add	s5,a5,s0
    80005bb2:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005bb6:	e4040593          	addi	a1,s0,-448
    80005bba:	f4040513          	addi	a0,s0,-192
    80005bbe:	fffff097          	auipc	ra,0xfffff
    80005bc2:	172080e7          	jalr	370(ra) # 80004d30 <exec>
    80005bc6:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bc8:	f4040993          	addi	s3,s0,-192
    80005bcc:	6088                	ld	a0,0(s1)
    80005bce:	c911                	beqz	a0,80005be2 <sys_exec+0xfc>
    kfree(argv[i]);
    80005bd0:	ffffb097          	auipc	ra,0xffffb
    80005bd4:	e12080e7          	jalr	-494(ra) # 800009e2 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bd8:	04a1                	addi	s1,s1,8
    80005bda:	ff3499e3          	bne	s1,s3,80005bcc <sys_exec+0xe6>
    80005bde:	a011                	j	80005be2 <sys_exec+0xfc>
  return -1;
    80005be0:	597d                	li	s2,-1
}
    80005be2:	854a                	mv	a0,s2
    80005be4:	60be                	ld	ra,456(sp)
    80005be6:	641e                	ld	s0,448(sp)
    80005be8:	74fa                	ld	s1,440(sp)
    80005bea:	795a                	ld	s2,432(sp)
    80005bec:	79ba                	ld	s3,424(sp)
    80005bee:	7a1a                	ld	s4,416(sp)
    80005bf0:	6afa                	ld	s5,408(sp)
    80005bf2:	6179                	addi	sp,sp,464
    80005bf4:	8082                	ret

0000000080005bf6 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005bf6:	7139                	addi	sp,sp,-64
    80005bf8:	fc06                	sd	ra,56(sp)
    80005bfa:	f822                	sd	s0,48(sp)
    80005bfc:	f426                	sd	s1,40(sp)
    80005bfe:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005c00:	ffffc097          	auipc	ra,0xffffc
    80005c04:	e72080e7          	jalr	-398(ra) # 80001a72 <myproc>
    80005c08:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005c0a:	fd840593          	addi	a1,s0,-40
    80005c0e:	4501                	li	a0,0
    80005c10:	ffffd097          	auipc	ra,0xffffd
    80005c14:	06e080e7          	jalr	110(ra) # 80002c7e <argaddr>
    return -1;
    80005c18:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005c1a:	0e054063          	bltz	a0,80005cfa <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005c1e:	fc840593          	addi	a1,s0,-56
    80005c22:	fd040513          	addi	a0,s0,-48
    80005c26:	fffff097          	auipc	ra,0xfffff
    80005c2a:	de6080e7          	jalr	-538(ra) # 80004a0c <pipealloc>
    return -1;
    80005c2e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005c30:	0c054563          	bltz	a0,80005cfa <sys_pipe+0x104>
  fd0 = -1;
    80005c34:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005c38:	fd043503          	ld	a0,-48(s0)
    80005c3c:	fffff097          	auipc	ra,0xfffff
    80005c40:	504080e7          	jalr	1284(ra) # 80005140 <fdalloc>
    80005c44:	fca42223          	sw	a0,-60(s0)
    80005c48:	08054c63          	bltz	a0,80005ce0 <sys_pipe+0xea>
    80005c4c:	fc843503          	ld	a0,-56(s0)
    80005c50:	fffff097          	auipc	ra,0xfffff
    80005c54:	4f0080e7          	jalr	1264(ra) # 80005140 <fdalloc>
    80005c58:	fca42023          	sw	a0,-64(s0)
    80005c5c:	06054963          	bltz	a0,80005cce <sys_pipe+0xd8>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c60:	4691                	li	a3,4
    80005c62:	fc440613          	addi	a2,s0,-60
    80005c66:	fd843583          	ld	a1,-40(s0)
    80005c6a:	68a8                	ld	a0,80(s1)
    80005c6c:	ffffc097          	auipc	ra,0xffffc
    80005c70:	9ee080e7          	jalr	-1554(ra) # 8000165a <copyout>
    80005c74:	02054063          	bltz	a0,80005c94 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005c78:	4691                	li	a3,4
    80005c7a:	fc040613          	addi	a2,s0,-64
    80005c7e:	fd843583          	ld	a1,-40(s0)
    80005c82:	0591                	addi	a1,a1,4
    80005c84:	68a8                	ld	a0,80(s1)
    80005c86:	ffffc097          	auipc	ra,0xffffc
    80005c8a:	9d4080e7          	jalr	-1580(ra) # 8000165a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c8e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c90:	06055563          	bgez	a0,80005cfa <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005c94:	fc442783          	lw	a5,-60(s0)
    80005c98:	07e9                	addi	a5,a5,26
    80005c9a:	078e                	slli	a5,a5,0x3
    80005c9c:	97a6                	add	a5,a5,s1
    80005c9e:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005ca2:	fc042783          	lw	a5,-64(s0)
    80005ca6:	07e9                	addi	a5,a5,26
    80005ca8:	078e                	slli	a5,a5,0x3
    80005caa:	00f48533          	add	a0,s1,a5
    80005cae:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005cb2:	fd043503          	ld	a0,-48(s0)
    80005cb6:	fffff097          	auipc	ra,0xfffff
    80005cba:	a26080e7          	jalr	-1498(ra) # 800046dc <fileclose>
    fileclose(wf);
    80005cbe:	fc843503          	ld	a0,-56(s0)
    80005cc2:	fffff097          	auipc	ra,0xfffff
    80005cc6:	a1a080e7          	jalr	-1510(ra) # 800046dc <fileclose>
    return -1;
    80005cca:	57fd                	li	a5,-1
    80005ccc:	a03d                	j	80005cfa <sys_pipe+0x104>
    if(fd0 >= 0)
    80005cce:	fc442783          	lw	a5,-60(s0)
    80005cd2:	0007c763          	bltz	a5,80005ce0 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005cd6:	07e9                	addi	a5,a5,26
    80005cd8:	078e                	slli	a5,a5,0x3
    80005cda:	97a6                	add	a5,a5,s1
    80005cdc:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005ce0:	fd043503          	ld	a0,-48(s0)
    80005ce4:	fffff097          	auipc	ra,0xfffff
    80005ce8:	9f8080e7          	jalr	-1544(ra) # 800046dc <fileclose>
    fileclose(wf);
    80005cec:	fc843503          	ld	a0,-56(s0)
    80005cf0:	fffff097          	auipc	ra,0xfffff
    80005cf4:	9ec080e7          	jalr	-1556(ra) # 800046dc <fileclose>
    return -1;
    80005cf8:	57fd                	li	a5,-1
}
    80005cfa:	853e                	mv	a0,a5
    80005cfc:	70e2                	ld	ra,56(sp)
    80005cfe:	7442                	ld	s0,48(sp)
    80005d00:	74a2                	ld	s1,40(sp)
    80005d02:	6121                	addi	sp,sp,64
    80005d04:	8082                	ret
	...

0000000080005d10 <kernelvec>:
    80005d10:	7111                	addi	sp,sp,-256
    80005d12:	e006                	sd	ra,0(sp)
    80005d14:	e40a                	sd	sp,8(sp)
    80005d16:	e80e                	sd	gp,16(sp)
    80005d18:	ec12                	sd	tp,24(sp)
    80005d1a:	f016                	sd	t0,32(sp)
    80005d1c:	f41a                	sd	t1,40(sp)
    80005d1e:	f81e                	sd	t2,48(sp)
    80005d20:	fc22                	sd	s0,56(sp)
    80005d22:	e0a6                	sd	s1,64(sp)
    80005d24:	e4aa                	sd	a0,72(sp)
    80005d26:	e8ae                	sd	a1,80(sp)
    80005d28:	ecb2                	sd	a2,88(sp)
    80005d2a:	f0b6                	sd	a3,96(sp)
    80005d2c:	f4ba                	sd	a4,104(sp)
    80005d2e:	f8be                	sd	a5,112(sp)
    80005d30:	fcc2                	sd	a6,120(sp)
    80005d32:	e146                	sd	a7,128(sp)
    80005d34:	e54a                	sd	s2,136(sp)
    80005d36:	e94e                	sd	s3,144(sp)
    80005d38:	ed52                	sd	s4,152(sp)
    80005d3a:	f156                	sd	s5,160(sp)
    80005d3c:	f55a                	sd	s6,168(sp)
    80005d3e:	f95e                	sd	s7,176(sp)
    80005d40:	fd62                	sd	s8,184(sp)
    80005d42:	e1e6                	sd	s9,192(sp)
    80005d44:	e5ea                	sd	s10,200(sp)
    80005d46:	e9ee                	sd	s11,208(sp)
    80005d48:	edf2                	sd	t3,216(sp)
    80005d4a:	f1f6                	sd	t4,224(sp)
    80005d4c:	f5fa                	sd	t5,232(sp)
    80005d4e:	f9fe                	sd	t6,240(sp)
    80005d50:	d3ffc0ef          	jal	ra,80002a8e <kerneltrap>
    80005d54:	6082                	ld	ra,0(sp)
    80005d56:	6122                	ld	sp,8(sp)
    80005d58:	61c2                	ld	gp,16(sp)
    80005d5a:	7282                	ld	t0,32(sp)
    80005d5c:	7322                	ld	t1,40(sp)
    80005d5e:	73c2                	ld	t2,48(sp)
    80005d60:	7462                	ld	s0,56(sp)
    80005d62:	6486                	ld	s1,64(sp)
    80005d64:	6526                	ld	a0,72(sp)
    80005d66:	65c6                	ld	a1,80(sp)
    80005d68:	6666                	ld	a2,88(sp)
    80005d6a:	7686                	ld	a3,96(sp)
    80005d6c:	7726                	ld	a4,104(sp)
    80005d6e:	77c6                	ld	a5,112(sp)
    80005d70:	7866                	ld	a6,120(sp)
    80005d72:	688a                	ld	a7,128(sp)
    80005d74:	692a                	ld	s2,136(sp)
    80005d76:	69ca                	ld	s3,144(sp)
    80005d78:	6a6a                	ld	s4,152(sp)
    80005d7a:	7a8a                	ld	s5,160(sp)
    80005d7c:	7b2a                	ld	s6,168(sp)
    80005d7e:	7bca                	ld	s7,176(sp)
    80005d80:	7c6a                	ld	s8,184(sp)
    80005d82:	6c8e                	ld	s9,192(sp)
    80005d84:	6d2e                	ld	s10,200(sp)
    80005d86:	6dce                	ld	s11,208(sp)
    80005d88:	6e6e                	ld	t3,216(sp)
    80005d8a:	7e8e                	ld	t4,224(sp)
    80005d8c:	7f2e                	ld	t5,232(sp)
    80005d8e:	7fce                	ld	t6,240(sp)
    80005d90:	6111                	addi	sp,sp,256
    80005d92:	10200073          	sret
    80005d96:	00000013          	nop
    80005d9a:	00000013          	nop
    80005d9e:	0001                	nop

0000000080005da0 <timervec>:
    80005da0:	34051573          	csrrw	a0,mscratch,a0
    80005da4:	e10c                	sd	a1,0(a0)
    80005da6:	e510                	sd	a2,8(a0)
    80005da8:	e914                	sd	a3,16(a0)
    80005daa:	6d0c                	ld	a1,24(a0)
    80005dac:	7110                	ld	a2,32(a0)
    80005dae:	6194                	ld	a3,0(a1)
    80005db0:	96b2                	add	a3,a3,a2
    80005db2:	e194                	sd	a3,0(a1)
    80005db4:	4589                	li	a1,2
    80005db6:	14459073          	csrw	sip,a1
    80005dba:	6914                	ld	a3,16(a0)
    80005dbc:	6510                	ld	a2,8(a0)
    80005dbe:	610c                	ld	a1,0(a0)
    80005dc0:	34051573          	csrrw	a0,mscratch,a0
    80005dc4:	30200073          	mret
	...

0000000080005dca <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005dca:	1141                	addi	sp,sp,-16
    80005dcc:	e422                	sd	s0,8(sp)
    80005dce:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005dd0:	0c0007b7          	lui	a5,0xc000
    80005dd4:	4705                	li	a4,1
    80005dd6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005dd8:	c3d8                	sw	a4,4(a5)
}
    80005dda:	6422                	ld	s0,8(sp)
    80005ddc:	0141                	addi	sp,sp,16
    80005dde:	8082                	ret

0000000080005de0 <plicinithart>:

void
plicinithart(void)
{
    80005de0:	1141                	addi	sp,sp,-16
    80005de2:	e406                	sd	ra,8(sp)
    80005de4:	e022                	sd	s0,0(sp)
    80005de6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005de8:	ffffc097          	auipc	ra,0xffffc
    80005dec:	c5e080e7          	jalr	-930(ra) # 80001a46 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005df0:	0085171b          	slliw	a4,a0,0x8
    80005df4:	0c0027b7          	lui	a5,0xc002
    80005df8:	97ba                	add	a5,a5,a4
    80005dfa:	40200713          	li	a4,1026
    80005dfe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005e02:	00d5151b          	slliw	a0,a0,0xd
    80005e06:	0c2017b7          	lui	a5,0xc201
    80005e0a:	97aa                	add	a5,a5,a0
    80005e0c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005e10:	60a2                	ld	ra,8(sp)
    80005e12:	6402                	ld	s0,0(sp)
    80005e14:	0141                	addi	sp,sp,16
    80005e16:	8082                	ret

0000000080005e18 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005e18:	1141                	addi	sp,sp,-16
    80005e1a:	e406                	sd	ra,8(sp)
    80005e1c:	e022                	sd	s0,0(sp)
    80005e1e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e20:	ffffc097          	auipc	ra,0xffffc
    80005e24:	c26080e7          	jalr	-986(ra) # 80001a46 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005e28:	00d5151b          	slliw	a0,a0,0xd
    80005e2c:	0c2017b7          	lui	a5,0xc201
    80005e30:	97aa                	add	a5,a5,a0
  return irq;
}
    80005e32:	43c8                	lw	a0,4(a5)
    80005e34:	60a2                	ld	ra,8(sp)
    80005e36:	6402                	ld	s0,0(sp)
    80005e38:	0141                	addi	sp,sp,16
    80005e3a:	8082                	ret

0000000080005e3c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005e3c:	1101                	addi	sp,sp,-32
    80005e3e:	ec06                	sd	ra,24(sp)
    80005e40:	e822                	sd	s0,16(sp)
    80005e42:	e426                	sd	s1,8(sp)
    80005e44:	1000                	addi	s0,sp,32
    80005e46:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005e48:	ffffc097          	auipc	ra,0xffffc
    80005e4c:	bfe080e7          	jalr	-1026(ra) # 80001a46 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005e50:	00d5151b          	slliw	a0,a0,0xd
    80005e54:	0c2017b7          	lui	a5,0xc201
    80005e58:	97aa                	add	a5,a5,a0
    80005e5a:	c3c4                	sw	s1,4(a5)
}
    80005e5c:	60e2                	ld	ra,24(sp)
    80005e5e:	6442                	ld	s0,16(sp)
    80005e60:	64a2                	ld	s1,8(sp)
    80005e62:	6105                	addi	sp,sp,32
    80005e64:	8082                	ret

0000000080005e66 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005e66:	1141                	addi	sp,sp,-16
    80005e68:	e406                	sd	ra,8(sp)
    80005e6a:	e022                	sd	s0,0(sp)
    80005e6c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005e6e:	479d                	li	a5,7
    80005e70:	06a7c863          	blt	a5,a0,80005ee0 <free_desc+0x7a>
    panic("free_desc 1");
  if(disk.free[i])
    80005e74:	0001d717          	auipc	a4,0x1d
    80005e78:	18c70713          	addi	a4,a4,396 # 80023000 <disk>
    80005e7c:	972a                	add	a4,a4,a0
    80005e7e:	6789                	lui	a5,0x2
    80005e80:	97ba                	add	a5,a5,a4
    80005e82:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005e86:	e7ad                	bnez	a5,80005ef0 <free_desc+0x8a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005e88:	00451793          	slli	a5,a0,0x4
    80005e8c:	0001f717          	auipc	a4,0x1f
    80005e90:	17470713          	addi	a4,a4,372 # 80025000 <disk+0x2000>
    80005e94:	6314                	ld	a3,0(a4)
    80005e96:	96be                	add	a3,a3,a5
    80005e98:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005e9c:	6314                	ld	a3,0(a4)
    80005e9e:	96be                	add	a3,a3,a5
    80005ea0:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005ea4:	6314                	ld	a3,0(a4)
    80005ea6:	96be                	add	a3,a3,a5
    80005ea8:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005eac:	6318                	ld	a4,0(a4)
    80005eae:	97ba                	add	a5,a5,a4
    80005eb0:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005eb4:	0001d717          	auipc	a4,0x1d
    80005eb8:	14c70713          	addi	a4,a4,332 # 80023000 <disk>
    80005ebc:	972a                	add	a4,a4,a0
    80005ebe:	6789                	lui	a5,0x2
    80005ec0:	97ba                	add	a5,a5,a4
    80005ec2:	4705                	li	a4,1
    80005ec4:	00e78c23          	sb	a4,24(a5) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005ec8:	0001f517          	auipc	a0,0x1f
    80005ecc:	15050513          	addi	a0,a0,336 # 80025018 <disk+0x2018>
    80005ed0:	ffffc097          	auipc	ra,0xffffc
    80005ed4:	526080e7          	jalr	1318(ra) # 800023f6 <wakeup>
}
    80005ed8:	60a2                	ld	ra,8(sp)
    80005eda:	6402                	ld	s0,0(sp)
    80005edc:	0141                	addi	sp,sp,16
    80005ede:	8082                	ret
    panic("free_desc 1");
    80005ee0:	00003517          	auipc	a0,0x3
    80005ee4:	92850513          	addi	a0,a0,-1752 # 80008808 <syscalls+0x330>
    80005ee8:	ffffa097          	auipc	ra,0xffffa
    80005eec:	652080e7          	jalr	1618(ra) # 8000053a <panic>
    panic("free_desc 2");
    80005ef0:	00003517          	auipc	a0,0x3
    80005ef4:	92850513          	addi	a0,a0,-1752 # 80008818 <syscalls+0x340>
    80005ef8:	ffffa097          	auipc	ra,0xffffa
    80005efc:	642080e7          	jalr	1602(ra) # 8000053a <panic>

0000000080005f00 <virtio_disk_init>:
{
    80005f00:	1101                	addi	sp,sp,-32
    80005f02:	ec06                	sd	ra,24(sp)
    80005f04:	e822                	sd	s0,16(sp)
    80005f06:	e426                	sd	s1,8(sp)
    80005f08:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005f0a:	00003597          	auipc	a1,0x3
    80005f0e:	91e58593          	addi	a1,a1,-1762 # 80008828 <syscalls+0x350>
    80005f12:	0001f517          	auipc	a0,0x1f
    80005f16:	21650513          	addi	a0,a0,534 # 80025128 <disk+0x2128>
    80005f1a:	ffffb097          	auipc	ra,0xffffb
    80005f1e:	c26080e7          	jalr	-986(ra) # 80000b40 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f22:	100017b7          	lui	a5,0x10001
    80005f26:	4398                	lw	a4,0(a5)
    80005f28:	2701                	sext.w	a4,a4
    80005f2a:	747277b7          	lui	a5,0x74727
    80005f2e:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005f32:	0ef71063          	bne	a4,a5,80006012 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f36:	100017b7          	lui	a5,0x10001
    80005f3a:	43dc                	lw	a5,4(a5)
    80005f3c:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f3e:	4705                	li	a4,1
    80005f40:	0ce79963          	bne	a5,a4,80006012 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f44:	100017b7          	lui	a5,0x10001
    80005f48:	479c                	lw	a5,8(a5)
    80005f4a:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f4c:	4709                	li	a4,2
    80005f4e:	0ce79263          	bne	a5,a4,80006012 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005f52:	100017b7          	lui	a5,0x10001
    80005f56:	47d8                	lw	a4,12(a5)
    80005f58:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f5a:	554d47b7          	lui	a5,0x554d4
    80005f5e:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005f62:	0af71863          	bne	a4,a5,80006012 <virtio_disk_init+0x112>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f66:	100017b7          	lui	a5,0x10001
    80005f6a:	4705                	li	a4,1
    80005f6c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f6e:	470d                	li	a4,3
    80005f70:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005f72:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005f74:	c7ffe6b7          	lui	a3,0xc7ffe
    80005f78:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd73df>
    80005f7c:	8f75                	and	a4,a4,a3
    80005f7e:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f80:	472d                	li	a4,11
    80005f82:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f84:	473d                	li	a4,15
    80005f86:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005f88:	6705                	lui	a4,0x1
    80005f8a:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005f8c:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005f90:	5bdc                	lw	a5,52(a5)
    80005f92:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f94:	c7d9                	beqz	a5,80006022 <virtio_disk_init+0x122>
  if(max < NUM)
    80005f96:	471d                	li	a4,7
    80005f98:	08f77d63          	bgeu	a4,a5,80006032 <virtio_disk_init+0x132>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f9c:	100014b7          	lui	s1,0x10001
    80005fa0:	47a1                	li	a5,8
    80005fa2:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005fa4:	6609                	lui	a2,0x2
    80005fa6:	4581                	li	a1,0
    80005fa8:	0001d517          	auipc	a0,0x1d
    80005fac:	05850513          	addi	a0,a0,88 # 80023000 <disk>
    80005fb0:	ffffb097          	auipc	ra,0xffffb
    80005fb4:	d1c080e7          	jalr	-740(ra) # 80000ccc <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005fb8:	0001d717          	auipc	a4,0x1d
    80005fbc:	04870713          	addi	a4,a4,72 # 80023000 <disk>
    80005fc0:	00c75793          	srli	a5,a4,0xc
    80005fc4:	2781                	sext.w	a5,a5
    80005fc6:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005fc8:	0001f797          	auipc	a5,0x1f
    80005fcc:	03878793          	addi	a5,a5,56 # 80025000 <disk+0x2000>
    80005fd0:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005fd2:	0001d717          	auipc	a4,0x1d
    80005fd6:	0ae70713          	addi	a4,a4,174 # 80023080 <disk+0x80>
    80005fda:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005fdc:	0001e717          	auipc	a4,0x1e
    80005fe0:	02470713          	addi	a4,a4,36 # 80024000 <disk+0x1000>
    80005fe4:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005fe6:	4705                	li	a4,1
    80005fe8:	00e78c23          	sb	a4,24(a5)
    80005fec:	00e78ca3          	sb	a4,25(a5)
    80005ff0:	00e78d23          	sb	a4,26(a5)
    80005ff4:	00e78da3          	sb	a4,27(a5)
    80005ff8:	00e78e23          	sb	a4,28(a5)
    80005ffc:	00e78ea3          	sb	a4,29(a5)
    80006000:	00e78f23          	sb	a4,30(a5)
    80006004:	00e78fa3          	sb	a4,31(a5)
}
    80006008:	60e2                	ld	ra,24(sp)
    8000600a:	6442                	ld	s0,16(sp)
    8000600c:	64a2                	ld	s1,8(sp)
    8000600e:	6105                	addi	sp,sp,32
    80006010:	8082                	ret
    panic("could not find virtio disk");
    80006012:	00003517          	auipc	a0,0x3
    80006016:	82650513          	addi	a0,a0,-2010 # 80008838 <syscalls+0x360>
    8000601a:	ffffa097          	auipc	ra,0xffffa
    8000601e:	520080e7          	jalr	1312(ra) # 8000053a <panic>
    panic("virtio disk has no queue 0");
    80006022:	00003517          	auipc	a0,0x3
    80006026:	83650513          	addi	a0,a0,-1994 # 80008858 <syscalls+0x380>
    8000602a:	ffffa097          	auipc	ra,0xffffa
    8000602e:	510080e7          	jalr	1296(ra) # 8000053a <panic>
    panic("virtio disk max queue too short");
    80006032:	00003517          	auipc	a0,0x3
    80006036:	84650513          	addi	a0,a0,-1978 # 80008878 <syscalls+0x3a0>
    8000603a:	ffffa097          	auipc	ra,0xffffa
    8000603e:	500080e7          	jalr	1280(ra) # 8000053a <panic>

0000000080006042 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006042:	7119                	addi	sp,sp,-128
    80006044:	fc86                	sd	ra,120(sp)
    80006046:	f8a2                	sd	s0,112(sp)
    80006048:	f4a6                	sd	s1,104(sp)
    8000604a:	f0ca                	sd	s2,96(sp)
    8000604c:	ecce                	sd	s3,88(sp)
    8000604e:	e8d2                	sd	s4,80(sp)
    80006050:	e4d6                	sd	s5,72(sp)
    80006052:	e0da                	sd	s6,64(sp)
    80006054:	fc5e                	sd	s7,56(sp)
    80006056:	f862                	sd	s8,48(sp)
    80006058:	f466                	sd	s9,40(sp)
    8000605a:	f06a                	sd	s10,32(sp)
    8000605c:	ec6e                	sd	s11,24(sp)
    8000605e:	0100                	addi	s0,sp,128
    80006060:	8aaa                	mv	s5,a0
    80006062:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006064:	00c52c83          	lw	s9,12(a0)
    80006068:	001c9c9b          	slliw	s9,s9,0x1
    8000606c:	1c82                	slli	s9,s9,0x20
    8000606e:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006072:	0001f517          	auipc	a0,0x1f
    80006076:	0b650513          	addi	a0,a0,182 # 80025128 <disk+0x2128>
    8000607a:	ffffb097          	auipc	ra,0xffffb
    8000607e:	b56080e7          	jalr	-1194(ra) # 80000bd0 <acquire>
  for(int i = 0; i < 3; i++){
    80006082:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006084:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006086:	0001dc17          	auipc	s8,0x1d
    8000608a:	f7ac0c13          	addi	s8,s8,-134 # 80023000 <disk>
    8000608e:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006090:	4b0d                	li	s6,3
    80006092:	a0ad                	j	800060fc <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006094:	00fc0733          	add	a4,s8,a5
    80006098:	975e                	add	a4,a4,s7
    8000609a:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    8000609e:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800060a0:	0207c563          	bltz	a5,800060ca <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800060a4:	2905                	addiw	s2,s2,1
    800060a6:	0611                	addi	a2,a2,4
    800060a8:	19690c63          	beq	s2,s6,80006240 <virtio_disk_rw+0x1fe>
    idx[i] = alloc_desc();
    800060ac:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800060ae:	0001f717          	auipc	a4,0x1f
    800060b2:	f6a70713          	addi	a4,a4,-150 # 80025018 <disk+0x2018>
    800060b6:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800060b8:	00074683          	lbu	a3,0(a4)
    800060bc:	fee1                	bnez	a3,80006094 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800060be:	2785                	addiw	a5,a5,1
    800060c0:	0705                	addi	a4,a4,1
    800060c2:	fe979be3          	bne	a5,s1,800060b8 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800060c6:	57fd                	li	a5,-1
    800060c8:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800060ca:	01205d63          	blez	s2,800060e4 <virtio_disk_rw+0xa2>
    800060ce:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800060d0:	000a2503          	lw	a0,0(s4)
    800060d4:	00000097          	auipc	ra,0x0
    800060d8:	d92080e7          	jalr	-622(ra) # 80005e66 <free_desc>
      for(int j = 0; j < i; j++)
    800060dc:	2d85                	addiw	s11,s11,1
    800060de:	0a11                	addi	s4,s4,4
    800060e0:	ff2d98e3          	bne	s11,s2,800060d0 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800060e4:	0001f597          	auipc	a1,0x1f
    800060e8:	04458593          	addi	a1,a1,68 # 80025128 <disk+0x2128>
    800060ec:	0001f517          	auipc	a0,0x1f
    800060f0:	f2c50513          	addi	a0,a0,-212 # 80025018 <disk+0x2018>
    800060f4:	ffffc097          	auipc	ra,0xffffc
    800060f8:	176080e7          	jalr	374(ra) # 8000226a <sleep>
  for(int i = 0; i < 3; i++){
    800060fc:	f8040a13          	addi	s4,s0,-128
{
    80006100:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006102:	894e                	mv	s2,s3
    80006104:	b765                	j	800060ac <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006106:	0001f697          	auipc	a3,0x1f
    8000610a:	efa6b683          	ld	a3,-262(a3) # 80025000 <disk+0x2000>
    8000610e:	96ba                	add	a3,a3,a4
    80006110:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006114:	0001d817          	auipc	a6,0x1d
    80006118:	eec80813          	addi	a6,a6,-276 # 80023000 <disk>
    8000611c:	0001f697          	auipc	a3,0x1f
    80006120:	ee468693          	addi	a3,a3,-284 # 80025000 <disk+0x2000>
    80006124:	6290                	ld	a2,0(a3)
    80006126:	963a                	add	a2,a2,a4
    80006128:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    8000612c:	0015e593          	ori	a1,a1,1
    80006130:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80006134:	f8842603          	lw	a2,-120(s0)
    80006138:	628c                	ld	a1,0(a3)
    8000613a:	972e                	add	a4,a4,a1
    8000613c:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006140:	20050593          	addi	a1,a0,512
    80006144:	0592                	slli	a1,a1,0x4
    80006146:	95c2                	add	a1,a1,a6
    80006148:	577d                	li	a4,-1
    8000614a:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000614e:	00461713          	slli	a4,a2,0x4
    80006152:	6290                	ld	a2,0(a3)
    80006154:	963a                	add	a2,a2,a4
    80006156:	03078793          	addi	a5,a5,48
    8000615a:	97c2                	add	a5,a5,a6
    8000615c:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    8000615e:	629c                	ld	a5,0(a3)
    80006160:	97ba                	add	a5,a5,a4
    80006162:	4605                	li	a2,1
    80006164:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006166:	629c                	ld	a5,0(a3)
    80006168:	97ba                	add	a5,a5,a4
    8000616a:	4809                	li	a6,2
    8000616c:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006170:	629c                	ld	a5,0(a3)
    80006172:	97ba                	add	a5,a5,a4
    80006174:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006178:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    8000617c:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006180:	6698                	ld	a4,8(a3)
    80006182:	00275783          	lhu	a5,2(a4)
    80006186:	8b9d                	andi	a5,a5,7
    80006188:	0786                	slli	a5,a5,0x1
    8000618a:	973e                	add	a4,a4,a5
    8000618c:	00a71223          	sh	a0,4(a4)

  __sync_synchronize();
    80006190:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006194:	6698                	ld	a4,8(a3)
    80006196:	00275783          	lhu	a5,2(a4)
    8000619a:	2785                	addiw	a5,a5,1
    8000619c:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800061a0:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800061a4:	100017b7          	lui	a5,0x10001
    800061a8:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800061ac:	004aa783          	lw	a5,4(s5)
    800061b0:	02c79163          	bne	a5,a2,800061d2 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    800061b4:	0001f917          	auipc	s2,0x1f
    800061b8:	f7490913          	addi	s2,s2,-140 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    800061bc:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800061be:	85ca                	mv	a1,s2
    800061c0:	8556                	mv	a0,s5
    800061c2:	ffffc097          	auipc	ra,0xffffc
    800061c6:	0a8080e7          	jalr	168(ra) # 8000226a <sleep>
  while(b->disk == 1) {
    800061ca:	004aa783          	lw	a5,4(s5)
    800061ce:	fe9788e3          	beq	a5,s1,800061be <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    800061d2:	f8042903          	lw	s2,-128(s0)
    800061d6:	20090713          	addi	a4,s2,512
    800061da:	0712                	slli	a4,a4,0x4
    800061dc:	0001d797          	auipc	a5,0x1d
    800061e0:	e2478793          	addi	a5,a5,-476 # 80023000 <disk>
    800061e4:	97ba                	add	a5,a5,a4
    800061e6:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800061ea:	0001f997          	auipc	s3,0x1f
    800061ee:	e1698993          	addi	s3,s3,-490 # 80025000 <disk+0x2000>
    800061f2:	00491713          	slli	a4,s2,0x4
    800061f6:	0009b783          	ld	a5,0(s3)
    800061fa:	97ba                	add	a5,a5,a4
    800061fc:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006200:	854a                	mv	a0,s2
    80006202:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006206:	00000097          	auipc	ra,0x0
    8000620a:	c60080e7          	jalr	-928(ra) # 80005e66 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000620e:	8885                	andi	s1,s1,1
    80006210:	f0ed                	bnez	s1,800061f2 <virtio_disk_rw+0x1b0>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006212:	0001f517          	auipc	a0,0x1f
    80006216:	f1650513          	addi	a0,a0,-234 # 80025128 <disk+0x2128>
    8000621a:	ffffb097          	auipc	ra,0xffffb
    8000621e:	a6a080e7          	jalr	-1430(ra) # 80000c84 <release>
}
    80006222:	70e6                	ld	ra,120(sp)
    80006224:	7446                	ld	s0,112(sp)
    80006226:	74a6                	ld	s1,104(sp)
    80006228:	7906                	ld	s2,96(sp)
    8000622a:	69e6                	ld	s3,88(sp)
    8000622c:	6a46                	ld	s4,80(sp)
    8000622e:	6aa6                	ld	s5,72(sp)
    80006230:	6b06                	ld	s6,64(sp)
    80006232:	7be2                	ld	s7,56(sp)
    80006234:	7c42                	ld	s8,48(sp)
    80006236:	7ca2                	ld	s9,40(sp)
    80006238:	7d02                	ld	s10,32(sp)
    8000623a:	6de2                	ld	s11,24(sp)
    8000623c:	6109                	addi	sp,sp,128
    8000623e:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006240:	f8042503          	lw	a0,-128(s0)
    80006244:	20050793          	addi	a5,a0,512
    80006248:	0792                	slli	a5,a5,0x4
  if(write)
    8000624a:	0001d817          	auipc	a6,0x1d
    8000624e:	db680813          	addi	a6,a6,-586 # 80023000 <disk>
    80006252:	00f80733          	add	a4,a6,a5
    80006256:	01a036b3          	snez	a3,s10
    8000625a:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    8000625e:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006262:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006266:	7679                	lui	a2,0xffffe
    80006268:	963e                	add	a2,a2,a5
    8000626a:	0001f697          	auipc	a3,0x1f
    8000626e:	d9668693          	addi	a3,a3,-618 # 80025000 <disk+0x2000>
    80006272:	6298                	ld	a4,0(a3)
    80006274:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006276:	0a878593          	addi	a1,a5,168
    8000627a:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000627c:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000627e:	6298                	ld	a4,0(a3)
    80006280:	9732                	add	a4,a4,a2
    80006282:	45c1                	li	a1,16
    80006284:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006286:	6298                	ld	a4,0(a3)
    80006288:	9732                	add	a4,a4,a2
    8000628a:	4585                	li	a1,1
    8000628c:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006290:	f8442703          	lw	a4,-124(s0)
    80006294:	628c                	ld	a1,0(a3)
    80006296:	962e                	add	a2,a2,a1
    80006298:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd6c8e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    8000629c:	0712                	slli	a4,a4,0x4
    8000629e:	6290                	ld	a2,0(a3)
    800062a0:	963a                	add	a2,a2,a4
    800062a2:	058a8593          	addi	a1,s5,88
    800062a6:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800062a8:	6294                	ld	a3,0(a3)
    800062aa:	96ba                	add	a3,a3,a4
    800062ac:	40000613          	li	a2,1024
    800062b0:	c690                	sw	a2,8(a3)
  if(write)
    800062b2:	e40d1ae3          	bnez	s10,80006106 <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800062b6:	0001f697          	auipc	a3,0x1f
    800062ba:	d4a6b683          	ld	a3,-694(a3) # 80025000 <disk+0x2000>
    800062be:	96ba                	add	a3,a3,a4
    800062c0:	4609                	li	a2,2
    800062c2:	00c69623          	sh	a2,12(a3)
    800062c6:	b5b9                	j	80006114 <virtio_disk_rw+0xd2>

00000000800062c8 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800062c8:	1101                	addi	sp,sp,-32
    800062ca:	ec06                	sd	ra,24(sp)
    800062cc:	e822                	sd	s0,16(sp)
    800062ce:	e426                	sd	s1,8(sp)
    800062d0:	e04a                	sd	s2,0(sp)
    800062d2:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800062d4:	0001f517          	auipc	a0,0x1f
    800062d8:	e5450513          	addi	a0,a0,-428 # 80025128 <disk+0x2128>
    800062dc:	ffffb097          	auipc	ra,0xffffb
    800062e0:	8f4080e7          	jalr	-1804(ra) # 80000bd0 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800062e4:	10001737          	lui	a4,0x10001
    800062e8:	533c                	lw	a5,96(a4)
    800062ea:	8b8d                	andi	a5,a5,3
    800062ec:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800062ee:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800062f2:	0001f797          	auipc	a5,0x1f
    800062f6:	d0e78793          	addi	a5,a5,-754 # 80025000 <disk+0x2000>
    800062fa:	6b94                	ld	a3,16(a5)
    800062fc:	0207d703          	lhu	a4,32(a5)
    80006300:	0026d783          	lhu	a5,2(a3)
    80006304:	06f70163          	beq	a4,a5,80006366 <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006308:	0001d917          	auipc	s2,0x1d
    8000630c:	cf890913          	addi	s2,s2,-776 # 80023000 <disk>
    80006310:	0001f497          	auipc	s1,0x1f
    80006314:	cf048493          	addi	s1,s1,-784 # 80025000 <disk+0x2000>
    __sync_synchronize();
    80006318:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000631c:	6898                	ld	a4,16(s1)
    8000631e:	0204d783          	lhu	a5,32(s1)
    80006322:	8b9d                	andi	a5,a5,7
    80006324:	078e                	slli	a5,a5,0x3
    80006326:	97ba                	add	a5,a5,a4
    80006328:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000632a:	20078713          	addi	a4,a5,512
    8000632e:	0712                	slli	a4,a4,0x4
    80006330:	974a                	add	a4,a4,s2
    80006332:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006336:	e731                	bnez	a4,80006382 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006338:	20078793          	addi	a5,a5,512
    8000633c:	0792                	slli	a5,a5,0x4
    8000633e:	97ca                	add	a5,a5,s2
    80006340:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006342:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006346:	ffffc097          	auipc	ra,0xffffc
    8000634a:	0b0080e7          	jalr	176(ra) # 800023f6 <wakeup>

    disk.used_idx += 1;
    8000634e:	0204d783          	lhu	a5,32(s1)
    80006352:	2785                	addiw	a5,a5,1
    80006354:	17c2                	slli	a5,a5,0x30
    80006356:	93c1                	srli	a5,a5,0x30
    80006358:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    8000635c:	6898                	ld	a4,16(s1)
    8000635e:	00275703          	lhu	a4,2(a4)
    80006362:	faf71be3          	bne	a4,a5,80006318 <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006366:	0001f517          	auipc	a0,0x1f
    8000636a:	dc250513          	addi	a0,a0,-574 # 80025128 <disk+0x2128>
    8000636e:	ffffb097          	auipc	ra,0xffffb
    80006372:	916080e7          	jalr	-1770(ra) # 80000c84 <release>
}
    80006376:	60e2                	ld	ra,24(sp)
    80006378:	6442                	ld	s0,16(sp)
    8000637a:	64a2                	ld	s1,8(sp)
    8000637c:	6902                	ld	s2,0(sp)
    8000637e:	6105                	addi	sp,sp,32
    80006380:	8082                	ret
      panic("virtio_disk_intr status");
    80006382:	00002517          	auipc	a0,0x2
    80006386:	51650513          	addi	a0,a0,1302 # 80008898 <syscalls+0x3c0>
    8000638a:	ffffa097          	auipc	ra,0xffffa
    8000638e:	1b0080e7          	jalr	432(ra) # 8000053a <panic>

0000000080006392 <sgenrand>:
static int mti=N+1; /* mti==N+1 means mt[N] is not initialized */

/* initializing the array with a NONZERO seed */
void
sgenrand(unsigned long seed)
{
    80006392:	1141                	addi	sp,sp,-16
    80006394:	e422                	sd	s0,8(sp)
    80006396:	0800                	addi	s0,sp,16
    /* setting initial seeds to mt[N] using         */
    /* the generator Line 25 of Table 1 in          */
    /* [KNUTH 1981, The Art of Computer Programming */
    /*    Vol. 2 (2nd Ed.), pp102]                  */
    mt[0]= seed & 0xffffffff;
    80006398:	00020717          	auipc	a4,0x20
    8000639c:	c6870713          	addi	a4,a4,-920 # 80026000 <mt>
    800063a0:	1502                	slli	a0,a0,0x20
    800063a2:	9101                	srli	a0,a0,0x20
    800063a4:	e308                	sd	a0,0(a4)
    for (mti=1; mti<N; mti++)
    800063a6:	00021597          	auipc	a1,0x21
    800063aa:	fd258593          	addi	a1,a1,-46 # 80027378 <mt+0x1378>
        mt[mti] = (69069 * mt[mti-1]) & 0xffffffff;
    800063ae:	6645                	lui	a2,0x11
    800063b0:	dcd60613          	addi	a2,a2,-563 # 10dcd <_entry-0x7ffef233>
    800063b4:	56fd                	li	a3,-1
    800063b6:	9281                	srli	a3,a3,0x20
    800063b8:	631c                	ld	a5,0(a4)
    800063ba:	02c787b3          	mul	a5,a5,a2
    800063be:	8ff5                	and	a5,a5,a3
    800063c0:	e71c                	sd	a5,8(a4)
    for (mti=1; mti<N; mti++)
    800063c2:	0721                	addi	a4,a4,8
    800063c4:	feb71ae3          	bne	a4,a1,800063b8 <sgenrand+0x26>
    800063c8:	27000793          	li	a5,624
    800063cc:	00002717          	auipc	a4,0x2
    800063d0:	4ef72e23          	sw	a5,1276(a4) # 800088c8 <mti>
}
    800063d4:	6422                	ld	s0,8(sp)
    800063d6:	0141                	addi	sp,sp,16
    800063d8:	8082                	ret

00000000800063da <genrand>:

long /* for integer generation */
genrand()
{
    800063da:	1141                	addi	sp,sp,-16
    800063dc:	e406                	sd	ra,8(sp)
    800063de:	e022                	sd	s0,0(sp)
    800063e0:	0800                	addi	s0,sp,16
    unsigned long y;
    static unsigned long mag01[2]={0x0, MATRIX_A};
    /* mag01[x] = x * MATRIX_A  for x=0,1 */

    if (mti >= N) { /* generate N words at one time */
    800063e2:	00002797          	auipc	a5,0x2
    800063e6:	4e67a783          	lw	a5,1254(a5) # 800088c8 <mti>
    800063ea:	26f00713          	li	a4,623
    800063ee:	0ef75963          	bge	a4,a5,800064e0 <genrand+0x106>
        int kk;

        if (mti == N+1)   /* if sgenrand() has not been called, */
    800063f2:	27100713          	li	a4,625
    800063f6:	12e78e63          	beq	a5,a4,80006532 <genrand+0x158>
            sgenrand(4357); /* a default initial seed is used   */

        for (kk=0;kk<N-M;kk++) {
    800063fa:	00020817          	auipc	a6,0x20
    800063fe:	c0680813          	addi	a6,a6,-1018 # 80026000 <mt>
    80006402:	00020e17          	auipc	t3,0x20
    80006406:	316e0e13          	addi	t3,t3,790 # 80026718 <mt+0x718>
{
    8000640a:	8742                	mv	a4,a6
            y = (mt[kk]&UPPER_MASK)|(mt[kk+1]&LOWER_MASK);
    8000640c:	4885                	li	a7,1
    8000640e:	08fe                	slli	a7,a7,0x1f
    80006410:	80000537          	lui	a0,0x80000
    80006414:	fff54513          	not	a0,a0
            mt[kk] = mt[kk+M] ^ (y >> 1) ^ mag01[y & 0x1];
    80006418:	6585                	lui	a1,0x1
    8000641a:	c6858593          	addi	a1,a1,-920 # c68 <_entry-0x7ffff398>
    8000641e:	00002317          	auipc	t1,0x2
    80006422:	49230313          	addi	t1,t1,1170 # 800088b0 <mag01.0>
            y = (mt[kk]&UPPER_MASK)|(mt[kk+1]&LOWER_MASK);
    80006426:	631c                	ld	a5,0(a4)
    80006428:	0117f7b3          	and	a5,a5,a7
    8000642c:	6714                	ld	a3,8(a4)
    8000642e:	8ee9                	and	a3,a3,a0
    80006430:	8fd5                	or	a5,a5,a3
            mt[kk] = mt[kk+M] ^ (y >> 1) ^ mag01[y & 0x1];
    80006432:	00b70633          	add	a2,a4,a1
    80006436:	0017d693          	srli	a3,a5,0x1
    8000643a:	6210                	ld	a2,0(a2)
    8000643c:	8eb1                	xor	a3,a3,a2
    8000643e:	8b85                	andi	a5,a5,1
    80006440:	078e                	slli	a5,a5,0x3
    80006442:	979a                	add	a5,a5,t1
    80006444:	639c                	ld	a5,0(a5)
    80006446:	8fb5                	xor	a5,a5,a3
    80006448:	e31c                	sd	a5,0(a4)
        for (kk=0;kk<N-M;kk++) {
    8000644a:	0721                	addi	a4,a4,8
    8000644c:	fdc71de3          	bne	a4,t3,80006426 <genrand+0x4c>
        }
        for (;kk<N-1;kk++) {
    80006450:	6605                	lui	a2,0x1
    80006452:	c6060613          	addi	a2,a2,-928 # c60 <_entry-0x7ffff3a0>
    80006456:	9642                	add	a2,a2,a6
            y = (mt[kk]&UPPER_MASK)|(mt[kk+1]&LOWER_MASK);
    80006458:	4505                	li	a0,1
    8000645a:	057e                	slli	a0,a0,0x1f
    8000645c:	800005b7          	lui	a1,0x80000
    80006460:	fff5c593          	not	a1,a1
            mt[kk] = mt[kk+(M-N)] ^ (y >> 1) ^ mag01[y & 0x1];
    80006464:	00002897          	auipc	a7,0x2
    80006468:	44c88893          	addi	a7,a7,1100 # 800088b0 <mag01.0>
            y = (mt[kk]&UPPER_MASK)|(mt[kk+1]&LOWER_MASK);
    8000646c:	71883783          	ld	a5,1816(a6)
    80006470:	8fe9                	and	a5,a5,a0
    80006472:	72083703          	ld	a4,1824(a6)
    80006476:	8f6d                	and	a4,a4,a1
    80006478:	8fd9                	or	a5,a5,a4
            mt[kk] = mt[kk+(M-N)] ^ (y >> 1) ^ mag01[y & 0x1];
    8000647a:	0017d713          	srli	a4,a5,0x1
    8000647e:	00083683          	ld	a3,0(a6)
    80006482:	8f35                	xor	a4,a4,a3
    80006484:	8b85                	andi	a5,a5,1
    80006486:	078e                	slli	a5,a5,0x3
    80006488:	97c6                	add	a5,a5,a7
    8000648a:	639c                	ld	a5,0(a5)
    8000648c:	8fb9                	xor	a5,a5,a4
    8000648e:	70f83c23          	sd	a5,1816(a6)
        for (;kk<N-1;kk++) {
    80006492:	0821                	addi	a6,a6,8
    80006494:	fcc81ce3          	bne	a6,a2,8000646c <genrand+0x92>
        }
        y = (mt[N-1]&UPPER_MASK)|(mt[0]&LOWER_MASK);
    80006498:	00021697          	auipc	a3,0x21
    8000649c:	b6868693          	addi	a3,a3,-1176 # 80027000 <mt+0x1000>
    800064a0:	3786b783          	ld	a5,888(a3)
    800064a4:	4705                	li	a4,1
    800064a6:	077e                	slli	a4,a4,0x1f
    800064a8:	8ff9                	and	a5,a5,a4
    800064aa:	00020717          	auipc	a4,0x20
    800064ae:	b5673703          	ld	a4,-1194(a4) # 80026000 <mt>
    800064b2:	1706                	slli	a4,a4,0x21
    800064b4:	9305                	srli	a4,a4,0x21
    800064b6:	8fd9                	or	a5,a5,a4
        mt[N-1] = mt[M-1] ^ (y >> 1) ^ mag01[y & 0x1];
    800064b8:	0017d713          	srli	a4,a5,0x1
    800064bc:	c606b603          	ld	a2,-928(a3)
    800064c0:	8f31                	xor	a4,a4,a2
    800064c2:	8b85                	andi	a5,a5,1
    800064c4:	078e                	slli	a5,a5,0x3
    800064c6:	00002617          	auipc	a2,0x2
    800064ca:	3ea60613          	addi	a2,a2,1002 # 800088b0 <mag01.0>
    800064ce:	97b2                	add	a5,a5,a2
    800064d0:	639c                	ld	a5,0(a5)
    800064d2:	8fb9                	xor	a5,a5,a4
    800064d4:	36f6bc23          	sd	a5,888(a3)

        mti = 0;
    800064d8:	00002797          	auipc	a5,0x2
    800064dc:	3e07a823          	sw	zero,1008(a5) # 800088c8 <mti>
    }
  
    y = mt[mti++];
    800064e0:	00002717          	auipc	a4,0x2
    800064e4:	3e870713          	addi	a4,a4,1000 # 800088c8 <mti>
    800064e8:	431c                	lw	a5,0(a4)
    800064ea:	0017869b          	addiw	a3,a5,1
    800064ee:	c314                	sw	a3,0(a4)
    800064f0:	078e                	slli	a5,a5,0x3
    800064f2:	00020717          	auipc	a4,0x20
    800064f6:	b0e70713          	addi	a4,a4,-1266 # 80026000 <mt>
    800064fa:	97ba                	add	a5,a5,a4
    800064fc:	639c                	ld	a5,0(a5)
    y ^= TEMPERING_SHIFT_U(y);
    800064fe:	00b7d713          	srli	a4,a5,0xb
    80006502:	8f3d                	xor	a4,a4,a5
    y ^= TEMPERING_SHIFT_S(y) & TEMPERING_MASK_B;
    80006504:	013a67b7          	lui	a5,0x13a6
    80006508:	8ad78793          	addi	a5,a5,-1875 # 13a58ad <_entry-0x7ec5a753>
    8000650c:	8ff9                	and	a5,a5,a4
    8000650e:	079e                	slli	a5,a5,0x7
    80006510:	8fb9                	xor	a5,a5,a4
    y ^= TEMPERING_SHIFT_T(y) & TEMPERING_MASK_C;
    80006512:	00f79713          	slli	a4,a5,0xf
    80006516:	077e36b7          	lui	a3,0x77e3
    8000651a:	0696                	slli	a3,a3,0x5
    8000651c:	8f75                	and	a4,a4,a3
    8000651e:	8fb9                	xor	a5,a5,a4
    y ^= TEMPERING_SHIFT_L(y);
    80006520:	0127d513          	srli	a0,a5,0x12
    80006524:	8d3d                	xor	a0,a0,a5

    // Strip off uppermost bit because we want a long,
    // not an unsigned long
    return y & RAND_MAX;
    80006526:	1506                	slli	a0,a0,0x21
}
    80006528:	9105                	srli	a0,a0,0x21
    8000652a:	60a2                	ld	ra,8(sp)
    8000652c:	6402                	ld	s0,0(sp)
    8000652e:	0141                	addi	sp,sp,16
    80006530:	8082                	ret
            sgenrand(4357); /* a default initial seed is used   */
    80006532:	6505                	lui	a0,0x1
    80006534:	10550513          	addi	a0,a0,261 # 1105 <_entry-0x7fffeefb>
    80006538:	00000097          	auipc	ra,0x0
    8000653c:	e5a080e7          	jalr	-422(ra) # 80006392 <sgenrand>
    80006540:	bd6d                	j	800063fa <genrand+0x20>

0000000080006542 <random_at_most>:

// Assumes 0 <= max <= RAND_MAX
// Returns in the half-open interval [0, max]
long random_at_most(long max) {
    80006542:	1101                	addi	sp,sp,-32
    80006544:	ec06                	sd	ra,24(sp)
    80006546:	e822                	sd	s0,16(sp)
    80006548:	e426                	sd	s1,8(sp)
    8000654a:	e04a                	sd	s2,0(sp)
    8000654c:	1000                	addi	s0,sp,32
  unsigned long
    // max <= RAND_MAX < ULONG_MAX, so this is okay.
    num_bins = (unsigned long) max + 1,
    8000654e:	0505                	addi	a0,a0,1
    num_rand = (unsigned long) RAND_MAX + 1,
    bin_size = num_rand / num_bins,
    80006550:	4785                	li	a5,1
    80006552:	07fe                	slli	a5,a5,0x1f
    80006554:	02a7d933          	divu	s2,a5,a0
    defect   = num_rand % num_bins;
    80006558:	02a7f7b3          	remu	a5,a5,a0
  long x;
  do {
   x = genrand();
  }
  // This is carefully written not to overflow
  while (num_rand - defect <= (unsigned long)x);
    8000655c:	4485                	li	s1,1
    8000655e:	04fe                	slli	s1,s1,0x1f
    80006560:	8c9d                	sub	s1,s1,a5
   x = genrand();
    80006562:	00000097          	auipc	ra,0x0
    80006566:	e78080e7          	jalr	-392(ra) # 800063da <genrand>
  while (num_rand - defect <= (unsigned long)x);
    8000656a:	fe957ce3          	bgeu	a0,s1,80006562 <random_at_most+0x20>

  // Truncated division is intentional
  return x/bin_size;
    8000656e:	03255533          	divu	a0,a0,s2
    80006572:	60e2                	ld	ra,24(sp)
    80006574:	6442                	ld	s0,16(sp)
    80006576:	64a2                	ld	s1,8(sp)
    80006578:	6902                	ld	s2,0(sp)
    8000657a:	6105                	addi	sp,sp,32
    8000657c:	8082                	ret
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
