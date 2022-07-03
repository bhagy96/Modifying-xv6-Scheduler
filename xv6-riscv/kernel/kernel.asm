
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	93013103          	ld	sp,-1744(sp) # 80008930 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

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
    80000056:	ffe70713          	addi	a4,a4,-2 # 80009050 <timer_scratch>
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
    80000068:	d2c78793          	addi	a5,a5,-724 # 80005d90 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd747f>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de078793          	addi	a5,a5,-544 # 80000e8e <main>
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
    80000130:	54c080e7          	jalr	1356(ra) # 80002678 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	78e080e7          	jalr	1934(ra) # 800008ca <uartputc>
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
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	00450513          	addi	a0,a0,4 # 80011190 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	ff448493          	addi	s1,s1,-12 # 80011190 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	08290913          	addi	s2,s2,130 # 80011228 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405863          	blez	s4,80000224 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71463          	bne	a4,a5,800001e8 <consoleread+0x84>
      if(myproc()->killed){
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	8c8080e7          	jalr	-1848(ra) # 80001a8c <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	0aa080e7          	jalr	170(ra) # 8000227e <sleep>
    while(cons.r == cons.w){
    800001dc:	0984a783          	lw	a5,152(s1)
    800001e0:	09c4a703          	lw	a4,156(s1)
    800001e4:	fef700e3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e8:	0017871b          	addiw	a4,a5,1
    800001ec:	08e4ac23          	sw	a4,152(s1)
    800001f0:	07f7f713          	andi	a4,a5,127
    800001f4:	9726                	add	a4,a4,s1
    800001f6:	01874703          	lbu	a4,24(a4)
    800001fa:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001fe:	079c0663          	beq	s8,s9,8000026a <consoleread+0x106>
    cbuf = c;
    80000202:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	f8f40613          	addi	a2,s0,-113
    8000020c:	85d6                	mv	a1,s5
    8000020e:	855a                	mv	a0,s6
    80000210:	00002097          	auipc	ra,0x2
    80000214:	412080e7          	jalr	1042(ra) # 80002622 <either_copyout>
    80000218:	01a50663          	beq	a0,s10,80000224 <consoleread+0xc0>
    dst++;
    8000021c:	0a85                	addi	s5,s5,1
    --n;
    8000021e:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000220:	f9bc1ae3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000224:	00011517          	auipc	a0,0x11
    80000228:	f6c50513          	addi	a0,a0,-148 # 80011190 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f5650513          	addi	a0,a0,-170 # 80011190 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	a56080e7          	jalr	-1450(ra) # 80000c98 <release>
        return -1;
    8000024a:	557d                	li	a0,-1
}
    8000024c:	70e6                	ld	ra,120(sp)
    8000024e:	7446                	ld	s0,112(sp)
    80000250:	74a6                	ld	s1,104(sp)
    80000252:	7906                	ld	s2,96(sp)
    80000254:	69e6                	ld	s3,88(sp)
    80000256:	6a46                	ld	s4,80(sp)
    80000258:	6aa6                	ld	s5,72(sp)
    8000025a:	6b06                	ld	s6,64(sp)
    8000025c:	7be2                	ld	s7,56(sp)
    8000025e:	7c42                	ld	s8,48(sp)
    80000260:	7ca2                	ld	s9,40(sp)
    80000262:	7d02                	ld	s10,32(sp)
    80000264:	6de2                	ld	s11,24(sp)
    80000266:	6109                	addi	sp,sp,128
    80000268:	8082                	ret
      if(n < target){
    8000026a:	000a071b          	sext.w	a4,s4
    8000026e:	fb777be3          	bgeu	a4,s7,80000224 <consoleread+0xc0>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	faf72b23          	sw	a5,-74(a4) # 80011228 <cons+0x98>
    8000027a:	b76d                	j	80000224 <consoleread+0xc0>

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
    80000290:	564080e7          	jalr	1380(ra) # 800007f0 <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	552080e7          	jalr	1362(ra) # 800007f0 <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	546080e7          	jalr	1350(ra) # 800007f0 <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	53c080e7          	jalr	1340(ra) # 800007f0 <uartputc_sync>
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
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	ec450513          	addi	a0,a0,-316 # 80011190 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	910080e7          	jalr	-1776(ra) # 80000be4 <acquire>

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
    800002f6:	3dc080e7          	jalr	988(ra) # 800026ce <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	e9650513          	addi	a0,a0,-362 # 80011190 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	996080e7          	jalr	-1642(ra) # 80000c98 <release>
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
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	e7270713          	addi	a4,a4,-398 # 80011190 <cons>
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
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	e4878793          	addi	a5,a5,-440 # 80011190 <cons>
    80000350:	0a07a703          	lw	a4,160(a5)
    80000354:	0017069b          	addiw	a3,a4,1
    80000358:	0006861b          	sext.w	a2,a3
    8000035c:	0ad7a023          	sw	a3,160(a5)
    80000360:	07f77713          	andi	a4,a4,127
    80000364:	97ba                	add	a5,a5,a4
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	eb27a783          	lw	a5,-334(a5) # 80011228 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	e0670713          	addi	a4,a4,-506 # 80011190 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	df648493          	addi	s1,s1,-522 # 80011190 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
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
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	dba70713          	addi	a4,a4,-582 # 80011190 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e4f72223          	sw	a5,-444(a4) # 80011230 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	d7e78793          	addi	a5,a5,-642 # 80011190 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	dec7ab23          	sw	a2,-522(a5) # 8001122c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dea50513          	addi	a0,a0,-534 # 80011228 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	fc4080e7          	jalr	-60(ra) # 8000240a <wakeup>
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
    80000460:	00011517          	auipc	a0,0x11
    80000464:	d3050513          	addi	a0,a0,-720 # 80011190 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	3b078793          	addi	a5,a5,944 # 80021828 <devsw>
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
    8000054a:	00011797          	auipc	a5,0x11
    8000054e:	d007a323          	sw	zero,-762(a5) # 80011250 <pr+0x18>
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
    80000570:	cc450513          	addi	a0,a0,-828 # 80008230 <digits+0x1f0>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00009717          	auipc	a4,0x9
    80000582:	a8f72123          	sw	a5,-1406(a4) # 80009000 <panicked>
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
    800005ba:	00011d97          	auipc	s11,0x11
    800005be:	c96dad83          	lw	s11,-874(s11) # 80011250 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	16050263          	beqz	a0,8000073a <printf+0x1b2>
    800005da:	4481                	li	s1,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b13          	li	s6,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b97          	auipc	s7,0x8
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00011517          	auipc	a0,0x11
    800005fc:	c4050513          	addi	a0,a0,-960 # 80011238 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
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
    80000622:	2485                	addiw	s1,s1,1
    80000624:	009a07b3          	add	a5,s4,s1
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050763          	beqz	a0,8000073a <printf+0x1b2>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000642:	cfe5                	beqz	a5,8000073a <printf+0x1b2>
    switch(c){
    80000644:	05678a63          	beq	a5,s6,80000698 <printf+0x110>
    80000648:	02fb7663          	bgeu	s6,a5,80000674 <printf+0xec>
    8000064c:	09978963          	beq	a5,s9,800006de <printf+0x156>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79863          	bne	a5,a4,80000724 <printf+0x19c>
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
    80000674:	0b578263          	beq	a5,s5,80000718 <printf+0x190>
    80000678:	0b879663          	bne	a5,s8,80000724 <printf+0x19c>
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
    800006a4:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c9d793          	srli	a5,s3,0x3c
    800006c6:	97de                	add	a5,a5,s7
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0992                	slli	s3,s3,0x4
    800006d6:	397d                	addiw	s2,s2,-1
    800006d8:	fe0915e3          	bnez	s2,800006c2 <printf+0x13a>
    800006dc:	b799                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	0007b903          	ld	s2,0(a5)
    800006ee:	00090e63          	beqz	s2,8000070a <printf+0x182>
      for(; *s; s++)
    800006f2:	00094503          	lbu	a0,0(s2)
    800006f6:	d515                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f8:	00000097          	auipc	ra,0x0
    800006fc:	b84080e7          	jalr	-1148(ra) # 8000027c <consputc>
      for(; *s; s++)
    80000700:	0905                	addi	s2,s2,1
    80000702:	00094503          	lbu	a0,0(s2)
    80000706:	f96d                	bnez	a0,800006f8 <printf+0x170>
    80000708:	bf29                	j	80000622 <printf+0x9a>
        s = "(null)";
    8000070a:	00008917          	auipc	s2,0x8
    8000070e:	91690913          	addi	s2,s2,-1770 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000712:	02800513          	li	a0,40
    80000716:	b7cd                	j	800006f8 <printf+0x170>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
      break;
    80000722:	b701                	j	80000622 <printf+0x9a>
      consputc('%');
    80000724:	8556                	mv	a0,s5
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b56080e7          	jalr	-1194(ra) # 8000027c <consputc>
      consputc(c);
    8000072e:	854a                	mv	a0,s2
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b4c080e7          	jalr	-1204(ra) # 8000027c <consputc>
      break;
    80000738:	b5ed                	j	80000622 <printf+0x9a>
  if(locking)
    8000073a:	020d9163          	bnez	s11,8000075c <printf+0x1d4>
}
    8000073e:	70e6                	ld	ra,120(sp)
    80000740:	7446                	ld	s0,112(sp)
    80000742:	74a6                	ld	s1,104(sp)
    80000744:	7906                	ld	s2,96(sp)
    80000746:	69e6                	ld	s3,88(sp)
    80000748:	6a46                	ld	s4,80(sp)
    8000074a:	6aa6                	ld	s5,72(sp)
    8000074c:	6b06                	ld	s6,64(sp)
    8000074e:	7be2                	ld	s7,56(sp)
    80000750:	7c42                	ld	s8,48(sp)
    80000752:	7ca2                	ld	s9,40(sp)
    80000754:	7d02                	ld	s10,32(sp)
    80000756:	6de2                	ld	s11,24(sp)
    80000758:	6129                	addi	sp,sp,192
    8000075a:	8082                	ret
    release(&pr.lock);
    8000075c:	00011517          	auipc	a0,0x11
    80000760:	adc50513          	addi	a0,a0,-1316 # 80011238 <pr>
    80000764:	00000097          	auipc	ra,0x0
    80000768:	534080e7          	jalr	1332(ra) # 80000c98 <release>
}
    8000076c:	bfc9                	j	8000073e <printf+0x1b6>

000000008000076e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076e:	1101                	addi	sp,sp,-32
    80000770:	ec06                	sd	ra,24(sp)
    80000772:	e822                	sd	s0,16(sp)
    80000774:	e426                	sd	s1,8(sp)
    80000776:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000778:	00011497          	auipc	s1,0x11
    8000077c:	ac048493          	addi	s1,s1,-1344 # 80011238 <pr>
    80000780:	00008597          	auipc	a1,0x8
    80000784:	8b858593          	addi	a1,a1,-1864 # 80008038 <etext+0x38>
    80000788:	8526                	mv	a0,s1
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	3ca080e7          	jalr	970(ra) # 80000b54 <initlock>
  pr.locking = 1;
    80000792:	4785                	li	a5,1
    80000794:	cc9c                	sw	a5,24(s1)
}
    80000796:	60e2                	ld	ra,24(sp)
    80000798:	6442                	ld	s0,16(sp)
    8000079a:	64a2                	ld	s1,8(sp)
    8000079c:	6105                	addi	sp,sp,32
    8000079e:	8082                	ret

00000000800007a0 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a0:	1141                	addi	sp,sp,-16
    800007a2:	e406                	sd	ra,8(sp)
    800007a4:	e022                	sd	s0,0(sp)
    800007a6:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a8:	100007b7          	lui	a5,0x10000
    800007ac:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b0:	f8000713          	li	a4,-128
    800007b4:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b8:	470d                	li	a4,3
    800007ba:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007be:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c2:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c6:	469d                	li	a3,7
    800007c8:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007cc:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d0:	00008597          	auipc	a1,0x8
    800007d4:	88858593          	addi	a1,a1,-1912 # 80008058 <digits+0x18>
    800007d8:	00011517          	auipc	a0,0x11
    800007dc:	a8050513          	addi	a0,a0,-1408 # 80011258 <uart_tx_lock>
    800007e0:	00000097          	auipc	ra,0x0
    800007e4:	374080e7          	jalr	884(ra) # 80000b54 <initlock>
}
    800007e8:	60a2                	ld	ra,8(sp)
    800007ea:	6402                	ld	s0,0(sp)
    800007ec:	0141                	addi	sp,sp,16
    800007ee:	8082                	ret

00000000800007f0 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f0:	1101                	addi	sp,sp,-32
    800007f2:	ec06                	sd	ra,24(sp)
    800007f4:	e822                	sd	s0,16(sp)
    800007f6:	e426                	sd	s1,8(sp)
    800007f8:	1000                	addi	s0,sp,32
    800007fa:	84aa                	mv	s1,a0
  push_off();
    800007fc:	00000097          	auipc	ra,0x0
    80000800:	39c080e7          	jalr	924(ra) # 80000b98 <push_off>

  if(panicked){
    80000804:	00008797          	auipc	a5,0x8
    80000808:	7fc7a783          	lw	a5,2044(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	10000737          	lui	a4,0x10000
  if(panicked){
    80000810:	c391                	beqz	a5,80000814 <uartputc_sync+0x24>
    for(;;)
    80000812:	a001                	j	80000812 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000814:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000818:	0ff7f793          	andi	a5,a5,255
    8000081c:	0207f793          	andi	a5,a5,32
    80000820:	dbf5                	beqz	a5,80000814 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000822:	0ff4f793          	andi	a5,s1,255
    80000826:	10000737          	lui	a4,0x10000
    8000082a:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000082e:	00000097          	auipc	ra,0x0
    80000832:	40a080e7          	jalr	1034(ra) # 80000c38 <pop_off>
}
    80000836:	60e2                	ld	ra,24(sp)
    80000838:	6442                	ld	s0,16(sp)
    8000083a:	64a2                	ld	s1,8(sp)
    8000083c:	6105                	addi	sp,sp,32
    8000083e:	8082                	ret

0000000080000840 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000840:	00008717          	auipc	a4,0x8
    80000844:	7c873703          	ld	a4,1992(a4) # 80009008 <uart_tx_r>
    80000848:	00008797          	auipc	a5,0x8
    8000084c:	7c87b783          	ld	a5,1992(a5) # 80009010 <uart_tx_w>
    80000850:	06e78c63          	beq	a5,a4,800008c8 <uartstart+0x88>
{
    80000854:	7139                	addi	sp,sp,-64
    80000856:	fc06                	sd	ra,56(sp)
    80000858:	f822                	sd	s0,48(sp)
    8000085a:	f426                	sd	s1,40(sp)
    8000085c:	f04a                	sd	s2,32(sp)
    8000085e:	ec4e                	sd	s3,24(sp)
    80000860:	e852                	sd	s4,16(sp)
    80000862:	e456                	sd	s5,8(sp)
    80000864:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000866:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086a:	00011a17          	auipc	s4,0x11
    8000086e:	9eea0a13          	addi	s4,s4,-1554 # 80011258 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	00008497          	auipc	s1,0x8
    80000876:	79648493          	addi	s1,s1,1942 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	00008997          	auipc	s3,0x8
    8000087e:	79698993          	addi	s3,s3,1942 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000882:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000886:	0ff7f793          	andi	a5,a5,255
    8000088a:	0207f793          	andi	a5,a5,32
    8000088e:	c785                	beqz	a5,800008b6 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000890:	01f77793          	andi	a5,a4,31
    80000894:	97d2                	add	a5,a5,s4
    80000896:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000089a:	0705                	addi	a4,a4,1
    8000089c:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00002097          	auipc	ra,0x2
    800008a4:	b6a080e7          	jalr	-1174(ra) # 8000240a <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	6098                	ld	a4,0(s1)
    800008ae:	0009b783          	ld	a5,0(s3)
    800008b2:	fce798e3          	bne	a5,a4,80000882 <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008dc:	00011517          	auipc	a0,0x11
    800008e0:	97c50513          	addi	a0,a0,-1668 # 80011258 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
  if(panicked){
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	7147a783          	lw	a5,1812(a5) # 80009000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008797          	auipc	a5,0x8
    800008fc:	7187b783          	ld	a5,1816(a5) # 80009010 <uart_tx_w>
    80000900:	00008717          	auipc	a4,0x8
    80000904:	70873703          	ld	a4,1800(a4) # 80009008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00011a17          	auipc	s4,0x11
    80000914:	948a0a13          	addi	s4,s4,-1720 # 80011258 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	952080e7          	jalr	-1710(ra) # 8000227e <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	91648493          	addi	s1,s1,-1770 # 80011258 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	00008717          	auipc	a4,0x8
    8000095a:	6af73d23          	sd	a5,1722(a4) # 80009010 <uart_tx_w>
      uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee2080e7          	jalr	-286(ra) # 80000840 <uartstart>
      release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	330080e7          	jalr	816(ra) # 80000c98 <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret

0000000080000980 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000980:	1141                	addi	sp,sp,-16
    80000982:	e422                	sd	s0,8(sp)
    80000984:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000098e:	8b85                	andi	a5,a5,1
    80000990:	cb91                	beqz	a5,800009a4 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000992:	100007b7          	lui	a5,0x10000
    80000996:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000099a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000099e:	6422                	ld	s0,8(sp)
    800009a0:	0141                	addi	sp,sp,16
    800009a2:	8082                	ret
    return -1;
    800009a4:	557d                	li	a0,-1
    800009a6:	bfe5                	j	8000099e <uartgetc+0x1e>

00000000800009a8 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009a8:	1101                	addi	sp,sp,-32
    800009aa:	ec06                	sd	ra,24(sp)
    800009ac:	e822                	sd	s0,16(sp)
    800009ae:	e426                	sd	s1,8(sp)
    800009b0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b2:	54fd                	li	s1,-1
    int c = uartgetc();
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	fcc080e7          	jalr	-52(ra) # 80000980 <uartgetc>
    if(c == -1)
    800009bc:	00950763          	beq	a0,s1,800009ca <uartintr+0x22>
      break;
    consoleintr(c);
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	8fe080e7          	jalr	-1794(ra) # 800002be <consoleintr>
  while(1){
    800009c8:	b7f5                	j	800009b4 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ca:	00011497          	auipc	s1,0x11
    800009ce:	88e48493          	addi	s1,s1,-1906 # 80011258 <uart_tx_lock>
    800009d2:	8526                	mv	a0,s1
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	210080e7          	jalr	528(ra) # 80000be4 <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	2b2080e7          	jalr	690(ra) # 80000c98 <release>
}
    800009ee:	60e2                	ld	ra,24(sp)
    800009f0:	6442                	ld	s0,16(sp)
    800009f2:	64a2                	ld	s1,8(sp)
    800009f4:	6105                	addi	sp,sp,32
    800009f6:	8082                	ret

00000000800009f8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009f8:	1101                	addi	sp,sp,-32
    800009fa:	ec06                	sd	ra,24(sp)
    800009fc:	e822                	sd	s0,16(sp)
    800009fe:	e426                	sd	s1,8(sp)
    80000a00:	e04a                	sd	s2,0(sp)
    80000a02:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a04:	03451793          	slli	a5,a0,0x34
    80000a08:	ebb9                	bnez	a5,80000a5e <kfree+0x66>
    80000a0a:	84aa                	mv	s1,a0
    80000a0c:	00027797          	auipc	a5,0x27
    80000a10:	97478793          	addi	a5,a5,-1676 # 80027380 <end>
    80000a14:	04f56563          	bltu	a0,a5,80000a5e <kfree+0x66>
    80000a18:	47c5                	li	a5,17
    80000a1a:	07ee                	slli	a5,a5,0x1b
    80000a1c:	04f57163          	bgeu	a0,a5,80000a5e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a20:	6605                	lui	a2,0x1
    80000a22:	4585                	li	a1,1
    80000a24:	00000097          	auipc	ra,0x0
    80000a28:	2bc080e7          	jalr	700(ra) # 80000ce0 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a2c:	00011917          	auipc	s2,0x11
    80000a30:	86490913          	addi	s2,s2,-1948 # 80011290 <kmem>
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	1ae080e7          	jalr	430(ra) # 80000be4 <acquire>
  r->next = kmem.freelist;
    80000a3e:	01893783          	ld	a5,24(s2)
    80000a42:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a44:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a48:	854a                	mv	a0,s2
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	24e080e7          	jalr	590(ra) # 80000c98 <release>
}
    80000a52:	60e2                	ld	ra,24(sp)
    80000a54:	6442                	ld	s0,16(sp)
    80000a56:	64a2                	ld	s1,8(sp)
    80000a58:	6902                	ld	s2,0(sp)
    80000a5a:	6105                	addi	sp,sp,32
    80000a5c:	8082                	ret
    panic("kfree");
    80000a5e:	00007517          	auipc	a0,0x7
    80000a62:	60250513          	addi	a0,a0,1538 # 80008060 <digits+0x20>
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	ad8080e7          	jalr	-1320(ra) # 8000053e <panic>

0000000080000a6e <freerange>:
{
    80000a6e:	7179                	addi	sp,sp,-48
    80000a70:	f406                	sd	ra,40(sp)
    80000a72:	f022                	sd	s0,32(sp)
    80000a74:	ec26                	sd	s1,24(sp)
    80000a76:	e84a                	sd	s2,16(sp)
    80000a78:	e44e                	sd	s3,8(sp)
    80000a7a:	e052                	sd	s4,0(sp)
    80000a7c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a7e:	6785                	lui	a5,0x1
    80000a80:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a84:	94aa                	add	s1,s1,a0
    80000a86:	757d                	lui	a0,0xfffff
    80000a88:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8a:	94be                	add	s1,s1,a5
    80000a8c:	0095ee63          	bltu	a1,s1,80000aa8 <freerange+0x3a>
    80000a90:	892e                	mv	s2,a1
    kfree(p);
    80000a92:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	6985                	lui	s3,0x1
    kfree(p);
    80000a96:	01448533          	add	a0,s1,s4
    80000a9a:	00000097          	auipc	ra,0x0
    80000a9e:	f5e080e7          	jalr	-162(ra) # 800009f8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa2:	94ce                	add	s1,s1,s3
    80000aa4:	fe9979e3          	bgeu	s2,s1,80000a96 <freerange+0x28>
}
    80000aa8:	70a2                	ld	ra,40(sp)
    80000aaa:	7402                	ld	s0,32(sp)
    80000aac:	64e2                	ld	s1,24(sp)
    80000aae:	6942                	ld	s2,16(sp)
    80000ab0:	69a2                	ld	s3,8(sp)
    80000ab2:	6a02                	ld	s4,0(sp)
    80000ab4:	6145                	addi	sp,sp,48
    80000ab6:	8082                	ret

0000000080000ab8 <kinit>:
{
    80000ab8:	1141                	addi	sp,sp,-16
    80000aba:	e406                	sd	ra,8(sp)
    80000abc:	e022                	sd	s0,0(sp)
    80000abe:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac0:	00007597          	auipc	a1,0x7
    80000ac4:	5a858593          	addi	a1,a1,1448 # 80008068 <digits+0x28>
    80000ac8:	00010517          	auipc	a0,0x10
    80000acc:	7c850513          	addi	a0,a0,1992 # 80011290 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	00027517          	auipc	a0,0x27
    80000ae0:	8a450513          	addi	a0,a0,-1884 # 80027380 <end>
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	f8a080e7          	jalr	-118(ra) # 80000a6e <freerange>
}
    80000aec:	60a2                	ld	ra,8(sp)
    80000aee:	6402                	ld	s0,0(sp)
    80000af0:	0141                	addi	sp,sp,16
    80000af2:	8082                	ret

0000000080000af4 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000af4:	1101                	addi	sp,sp,-32
    80000af6:	ec06                	sd	ra,24(sp)
    80000af8:	e822                	sd	s0,16(sp)
    80000afa:	e426                	sd	s1,8(sp)
    80000afc:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000afe:	00010497          	auipc	s1,0x10
    80000b02:	79248493          	addi	s1,s1,1938 # 80011290 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00010517          	auipc	a0,0x10
    80000b1a:	77a50513          	addi	a0,a0,1914 # 80011290 <kmem>
    80000b1e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	178080e7          	jalr	376(ra) # 80000c98 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b28:	6605                	lui	a2,0x1
    80000b2a:	4595                	li	a1,5
    80000b2c:	8526                	mv	a0,s1
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	1b2080e7          	jalr	434(ra) # 80000ce0 <memset>
  return (void*)r;
}
    80000b36:	8526                	mv	a0,s1
    80000b38:	60e2                	ld	ra,24(sp)
    80000b3a:	6442                	ld	s0,16(sp)
    80000b3c:	64a2                	ld	s1,8(sp)
    80000b3e:	6105                	addi	sp,sp,32
    80000b40:	8082                	ret
  release(&kmem.lock);
    80000b42:	00010517          	auipc	a0,0x10
    80000b46:	74e50513          	addi	a0,a0,1870 # 80011290 <kmem>
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	14e080e7          	jalr	334(ra) # 80000c98 <release>
  if(r)
    80000b52:	b7d5                	j	80000b36 <kalloc+0x42>

0000000080000b54 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b54:	1141                	addi	sp,sp,-16
    80000b56:	e422                	sd	s0,8(sp)
    80000b58:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b5a:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b5c:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b60:	00053823          	sd	zero,16(a0)
}
    80000b64:	6422                	ld	s0,8(sp)
    80000b66:	0141                	addi	sp,sp,16
    80000b68:	8082                	ret

0000000080000b6a <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	411c                	lw	a5,0(a0)
    80000b6c:	e399                	bnez	a5,80000b72 <holding+0x8>
    80000b6e:	4501                	li	a0,0
  return r;
}
    80000b70:	8082                	ret
{
    80000b72:	1101                	addi	sp,sp,-32
    80000b74:	ec06                	sd	ra,24(sp)
    80000b76:	e822                	sd	s0,16(sp)
    80000b78:	e426                	sd	s1,8(sp)
    80000b7a:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b7c:	6904                	ld	s1,16(a0)
    80000b7e:	00001097          	auipc	ra,0x1
    80000b82:	ef2080e7          	jalr	-270(ra) # 80001a70 <mycpu>
    80000b86:	40a48533          	sub	a0,s1,a0
    80000b8a:	00153513          	seqz	a0,a0
}
    80000b8e:	60e2                	ld	ra,24(sp)
    80000b90:	6442                	ld	s0,16(sp)
    80000b92:	64a2                	ld	s1,8(sp)
    80000b94:	6105                	addi	sp,sp,32
    80000b96:	8082                	ret

0000000080000b98 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b98:	1101                	addi	sp,sp,-32
    80000b9a:	ec06                	sd	ra,24(sp)
    80000b9c:	e822                	sd	s0,16(sp)
    80000b9e:	e426                	sd	s1,8(sp)
    80000ba0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba2:	100024f3          	csrr	s1,sstatus
    80000ba6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000baa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bac:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb0:	00001097          	auipc	ra,0x1
    80000bb4:	ec0080e7          	jalr	-320(ra) # 80001a70 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	eb4080e7          	jalr	-332(ra) # 80001a70 <mycpu>
    80000bc4:	5d3c                	lw	a5,120(a0)
    80000bc6:	2785                	addiw	a5,a5,1
    80000bc8:	dd3c                	sw	a5,120(a0)
}
    80000bca:	60e2                	ld	ra,24(sp)
    80000bcc:	6442                	ld	s0,16(sp)
    80000bce:	64a2                	ld	s1,8(sp)
    80000bd0:	6105                	addi	sp,sp,32
    80000bd2:	8082                	ret
    mycpu()->intena = old;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	e9c080e7          	jalr	-356(ra) # 80001a70 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bdc:	8085                	srli	s1,s1,0x1
    80000bde:	8885                	andi	s1,s1,1
    80000be0:	dd64                	sw	s1,124(a0)
    80000be2:	bfe9                	j	80000bbc <push_off+0x24>

0000000080000be4 <acquire>:
{
    80000be4:	1101                	addi	sp,sp,-32
    80000be6:	ec06                	sd	ra,24(sp)
    80000be8:	e822                	sd	s0,16(sp)
    80000bea:	e426                	sd	s1,8(sp)
    80000bec:	1000                	addi	s0,sp,32
    80000bee:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	fa8080e7          	jalr	-88(ra) # 80000b98 <push_off>
  if(holding(lk))
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	f70080e7          	jalr	-144(ra) # 80000b6a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c02:	4705                	li	a4,1
  if(holding(lk))
    80000c04:	e115                	bnez	a0,80000c28 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c06:	87ba                	mv	a5,a4
    80000c08:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c0c:	2781                	sext.w	a5,a5
    80000c0e:	ffe5                	bnez	a5,80000c06 <acquire+0x22>
  __sync_synchronize();
    80000c10:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	e5c080e7          	jalr	-420(ra) # 80001a70 <mycpu>
    80000c1c:	e888                	sd	a0,16(s1)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    panic("acquire");
    80000c28:	00007517          	auipc	a0,0x7
    80000c2c:	44850513          	addi	a0,a0,1096 # 80008070 <digits+0x30>
    80000c30:	00000097          	auipc	ra,0x0
    80000c34:	90e080e7          	jalr	-1778(ra) # 8000053e <panic>

0000000080000c38 <pop_off>:

void
pop_off(void)
{
    80000c38:	1141                	addi	sp,sp,-16
    80000c3a:	e406                	sd	ra,8(sp)
    80000c3c:	e022                	sd	s0,0(sp)
    80000c3e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	e30080e7          	jalr	-464(ra) # 80001a70 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c48:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c4c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c4e:	e78d                	bnez	a5,80000c78 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c50:	5d3c                	lw	a5,120(a0)
    80000c52:	02f05b63          	blez	a5,80000c88 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c56:	37fd                	addiw	a5,a5,-1
    80000c58:	0007871b          	sext.w	a4,a5
    80000c5c:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c5e:	eb09                	bnez	a4,80000c70 <pop_off+0x38>
    80000c60:	5d7c                	lw	a5,124(a0)
    80000c62:	c799                	beqz	a5,80000c70 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c6c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c70:	60a2                	ld	ra,8(sp)
    80000c72:	6402                	ld	s0,0(sp)
    80000c74:	0141                	addi	sp,sp,16
    80000c76:	8082                	ret
    panic("pop_off - interruptible");
    80000c78:	00007517          	auipc	a0,0x7
    80000c7c:	40050513          	addi	a0,a0,1024 # 80008078 <digits+0x38>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>
    panic("pop_off");
    80000c88:	00007517          	auipc	a0,0x7
    80000c8c:	40850513          	addi	a0,a0,1032 # 80008090 <digits+0x50>
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	8ae080e7          	jalr	-1874(ra) # 8000053e <panic>

0000000080000c98 <release>:
{
    80000c98:	1101                	addi	sp,sp,-32
    80000c9a:	ec06                	sd	ra,24(sp)
    80000c9c:	e822                	sd	s0,16(sp)
    80000c9e:	e426                	sd	s1,8(sp)
    80000ca0:	1000                	addi	s0,sp,32
    80000ca2:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ca4:	00000097          	auipc	ra,0x0
    80000ca8:	ec6080e7          	jalr	-314(ra) # 80000b6a <holding>
    80000cac:	c115                	beqz	a0,80000cd0 <release+0x38>
  lk->cpu = 0;
    80000cae:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb2:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cb6:	0f50000f          	fence	iorw,ow
    80000cba:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	f7a080e7          	jalr	-134(ra) # 80000c38 <pop_off>
}
    80000cc6:	60e2                	ld	ra,24(sp)
    80000cc8:	6442                	ld	s0,16(sp)
    80000cca:	64a2                	ld	s1,8(sp)
    80000ccc:	6105                	addi	sp,sp,32
    80000cce:	8082                	ret
    panic("release");
    80000cd0:	00007517          	auipc	a0,0x7
    80000cd4:	3c850513          	addi	a0,a0,968 # 80008098 <digits+0x58>
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	866080e7          	jalr	-1946(ra) # 8000053e <panic>

0000000080000ce0 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ce6:	ce09                	beqz	a2,80000d00 <memset+0x20>
    80000ce8:	87aa                	mv	a5,a0
    80000cea:	fff6071b          	addiw	a4,a2,-1
    80000cee:	1702                	slli	a4,a4,0x20
    80000cf0:	9301                	srli	a4,a4,0x20
    80000cf2:	0705                	addi	a4,a4,1
    80000cf4:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cf6:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cfa:	0785                	addi	a5,a5,1
    80000cfc:	fee79de3          	bne	a5,a4,80000cf6 <memset+0x16>
  }
  return dst;
}
    80000d00:	6422                	ld	s0,8(sp)
    80000d02:	0141                	addi	sp,sp,16
    80000d04:	8082                	ret

0000000080000d06 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d06:	1141                	addi	sp,sp,-16
    80000d08:	e422                	sd	s0,8(sp)
    80000d0a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d0c:	ca05                	beqz	a2,80000d3c <memcmp+0x36>
    80000d0e:	fff6069b          	addiw	a3,a2,-1
    80000d12:	1682                	slli	a3,a3,0x20
    80000d14:	9281                	srli	a3,a3,0x20
    80000d16:	0685                	addi	a3,a3,1
    80000d18:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d1a:	00054783          	lbu	a5,0(a0)
    80000d1e:	0005c703          	lbu	a4,0(a1)
    80000d22:	00e79863          	bne	a5,a4,80000d32 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d26:	0505                	addi	a0,a0,1
    80000d28:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d2a:	fed518e3          	bne	a0,a3,80000d1a <memcmp+0x14>
  }

  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	a019                	j	80000d36 <memcmp+0x30>
      return *s1 - *s2;
    80000d32:	40e7853b          	subw	a0,a5,a4
}
    80000d36:	6422                	ld	s0,8(sp)
    80000d38:	0141                	addi	sp,sp,16
    80000d3a:	8082                	ret
  return 0;
    80000d3c:	4501                	li	a0,0
    80000d3e:	bfe5                	j	80000d36 <memcmp+0x30>

0000000080000d40 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d40:	1141                	addi	sp,sp,-16
    80000d42:	e422                	sd	s0,8(sp)
    80000d44:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d46:	ca0d                	beqz	a2,80000d78 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d48:	00a5f963          	bgeu	a1,a0,80000d5a <memmove+0x1a>
    80000d4c:	02061693          	slli	a3,a2,0x20
    80000d50:	9281                	srli	a3,a3,0x20
    80000d52:	00d58733          	add	a4,a1,a3
    80000d56:	02e56463          	bltu	a0,a4,80000d7e <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d5a:	fff6079b          	addiw	a5,a2,-1
    80000d5e:	1782                	slli	a5,a5,0x20
    80000d60:	9381                	srli	a5,a5,0x20
    80000d62:	0785                	addi	a5,a5,1
    80000d64:	97ae                	add	a5,a5,a1
    80000d66:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d68:	0585                	addi	a1,a1,1
    80000d6a:	0705                	addi	a4,a4,1
    80000d6c:	fff5c683          	lbu	a3,-1(a1)
    80000d70:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d74:	fef59ae3          	bne	a1,a5,80000d68 <memmove+0x28>

  return dst;
}
    80000d78:	6422                	ld	s0,8(sp)
    80000d7a:	0141                	addi	sp,sp,16
    80000d7c:	8082                	ret
    d += n;
    80000d7e:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d80:	fff6079b          	addiw	a5,a2,-1
    80000d84:	1782                	slli	a5,a5,0x20
    80000d86:	9381                	srli	a5,a5,0x20
    80000d88:	fff7c793          	not	a5,a5
    80000d8c:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d8e:	177d                	addi	a4,a4,-1
    80000d90:	16fd                	addi	a3,a3,-1
    80000d92:	00074603          	lbu	a2,0(a4)
    80000d96:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d9a:	fef71ae3          	bne	a4,a5,80000d8e <memmove+0x4e>
    80000d9e:	bfe9                	j	80000d78 <memmove+0x38>

0000000080000da0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da0:	1141                	addi	sp,sp,-16
    80000da2:	e406                	sd	ra,8(sp)
    80000da4:	e022                	sd	s0,0(sp)
    80000da6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000da8:	00000097          	auipc	ra,0x0
    80000dac:	f98080e7          	jalr	-104(ra) # 80000d40 <memmove>
}
    80000db0:	60a2                	ld	ra,8(sp)
    80000db2:	6402                	ld	s0,0(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret

0000000080000db8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e422                	sd	s0,8(sp)
    80000dbc:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dbe:	ce11                	beqz	a2,80000dda <strncmp+0x22>
    80000dc0:	00054783          	lbu	a5,0(a0)
    80000dc4:	cf89                	beqz	a5,80000dde <strncmp+0x26>
    80000dc6:	0005c703          	lbu	a4,0(a1)
    80000dca:	00f71a63          	bne	a4,a5,80000dde <strncmp+0x26>
    n--, p++, q++;
    80000dce:	367d                	addiw	a2,a2,-1
    80000dd0:	0505                	addi	a0,a0,1
    80000dd2:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dd4:	f675                	bnez	a2,80000dc0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	a809                	j	80000dea <strncmp+0x32>
    80000dda:	4501                	li	a0,0
    80000ddc:	a039                	j	80000dea <strncmp+0x32>
  if(n == 0)
    80000dde:	ca09                	beqz	a2,80000df0 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de0:	00054503          	lbu	a0,0(a0)
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	9d1d                	subw	a0,a0,a5
}
    80000dea:	6422                	ld	s0,8(sp)
    80000dec:	0141                	addi	sp,sp,16
    80000dee:	8082                	ret
    return 0;
    80000df0:	4501                	li	a0,0
    80000df2:	bfe5                	j	80000dea <strncmp+0x32>

0000000080000df4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000df4:	1141                	addi	sp,sp,-16
    80000df6:	e422                	sd	s0,8(sp)
    80000df8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dfa:	872a                	mv	a4,a0
    80000dfc:	8832                	mv	a6,a2
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	01005963          	blez	a6,80000e12 <strncpy+0x1e>
    80000e04:	0705                	addi	a4,a4,1
    80000e06:	0005c783          	lbu	a5,0(a1)
    80000e0a:	fef70fa3          	sb	a5,-1(a4)
    80000e0e:	0585                	addi	a1,a1,1
    80000e10:	f7f5                	bnez	a5,80000dfc <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e12:	00c05d63          	blez	a2,80000e2c <strncpy+0x38>
    80000e16:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e18:	0685                	addi	a3,a3,1
    80000e1a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e1e:	fff6c793          	not	a5,a3
    80000e22:	9fb9                	addw	a5,a5,a4
    80000e24:	010787bb          	addw	a5,a5,a6
    80000e28:	fef048e3          	bgtz	a5,80000e18 <strncpy+0x24>
  return os;
}
    80000e2c:	6422                	ld	s0,8(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e38:	02c05363          	blez	a2,80000e5e <safestrcpy+0x2c>
    80000e3c:	fff6069b          	addiw	a3,a2,-1
    80000e40:	1682                	slli	a3,a3,0x20
    80000e42:	9281                	srli	a3,a3,0x20
    80000e44:	96ae                	add	a3,a3,a1
    80000e46:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e48:	00d58963          	beq	a1,a3,80000e5a <safestrcpy+0x28>
    80000e4c:	0585                	addi	a1,a1,1
    80000e4e:	0785                	addi	a5,a5,1
    80000e50:	fff5c703          	lbu	a4,-1(a1)
    80000e54:	fee78fa3          	sb	a4,-1(a5)
    80000e58:	fb65                	bnez	a4,80000e48 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e5a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e5e:	6422                	ld	s0,8(sp)
    80000e60:	0141                	addi	sp,sp,16
    80000e62:	8082                	ret

0000000080000e64 <strlen>:

int
strlen(const char *s)
{
    80000e64:	1141                	addi	sp,sp,-16
    80000e66:	e422                	sd	s0,8(sp)
    80000e68:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e6a:	00054783          	lbu	a5,0(a0)
    80000e6e:	cf91                	beqz	a5,80000e8a <strlen+0x26>
    80000e70:	0505                	addi	a0,a0,1
    80000e72:	87aa                	mv	a5,a0
    80000e74:	4685                	li	a3,1
    80000e76:	9e89                	subw	a3,a3,a0
    80000e78:	00f6853b          	addw	a0,a3,a5
    80000e7c:	0785                	addi	a5,a5,1
    80000e7e:	fff7c703          	lbu	a4,-1(a5)
    80000e82:	fb7d                	bnez	a4,80000e78 <strlen+0x14>
    ;
  return n;
}
    80000e84:	6422                	ld	s0,8(sp)
    80000e86:	0141                	addi	sp,sp,16
    80000e88:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e8a:	4501                	li	a0,0
    80000e8c:	bfe5                	j	80000e84 <strlen+0x20>

0000000080000e8e <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e8e:	1141                	addi	sp,sp,-16
    80000e90:	e406                	sd	ra,8(sp)
    80000e92:	e022                	sd	s0,0(sp)
    80000e94:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	bca080e7          	jalr	-1078(ra) # 80001a60 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e9e:	00008717          	auipc	a4,0x8
    80000ea2:	17a70713          	addi	a4,a4,378 # 80009018 <started>
  if(cpuid() == 0){
    80000ea6:	c139                	beqz	a0,80000eec <main+0x5e>
    while(started == 0)
    80000ea8:	431c                	lw	a5,0(a4)
    80000eaa:	2781                	sext.w	a5,a5
    80000eac:	dff5                	beqz	a5,80000ea8 <main+0x1a>
      ;
    __sync_synchronize();
    80000eae:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	bae080e7          	jalr	-1106(ra) # 80001a60 <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800080b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0d8080e7          	jalr	216(ra) # 80000fa4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00002097          	auipc	ra,0x2
    80000ed8:	93a080e7          	jalr	-1734(ra) # 8000280e <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	ef4080e7          	jalr	-268(ra) # 80005dd0 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	196080e7          	jalr	406(ra) # 8000207a <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	33450513          	addi	a0,a0,820 # 80008230 <digits+0x1f0>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	31450513          	addi	a0,a0,788 # 80008230 <digits+0x1f0>
    80000f24:	fffff097          	auipc	ra,0xfffff
    80000f28:	664080e7          	jalr	1636(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f2c:	00000097          	auipc	ra,0x0
    80000f30:	b8c080e7          	jalr	-1140(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f34:	00000097          	auipc	ra,0x0
    80000f38:	322080e7          	jalr	802(ra) # 80001256 <kvminit>
    kvminithart();   // turn on paging
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	068080e7          	jalr	104(ra) # 80000fa4 <kvminithart>
    procinit();      // process table
    80000f44:	00001097          	auipc	ra,0x1
    80000f48:	a6c080e7          	jalr	-1428(ra) # 800019b0 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	89a080e7          	jalr	-1894(ra) # 800027e6 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	8ba080e7          	jalr	-1862(ra) # 8000280e <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	e5e080e7          	jalr	-418(ra) # 80005dba <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	e6c080e7          	jalr	-404(ra) # 80005dd0 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	04e080e7          	jalr	78(ra) # 80002fba <binit>
    iinit();         // inode table
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	6de080e7          	jalr	1758(ra) # 80003652 <iinit>
    fileinit();      // file table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	688080e7          	jalr	1672(ra) # 80004604 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	f6e080e7          	jalr	-146(ra) # 80005ef2 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	ebc080e7          	jalr	-324(ra) # 80001e48 <userinit>
    __sync_synchronize();
    80000f94:	0ff0000f          	fence
    started = 1;
    80000f98:	4785                	li	a5,1
    80000f9a:	00008717          	auipc	a4,0x8
    80000f9e:	06f72f23          	sw	a5,126(a4) # 80009018 <started>
    80000fa2:	b789                	j	80000ee4 <main+0x56>

0000000080000fa4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fa4:	1141                	addi	sp,sp,-16
    80000fa6:	e422                	sd	s0,8(sp)
    80000fa8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000faa:	00008797          	auipc	a5,0x8
    80000fae:	0767b783          	ld	a5,118(a5) # 80009020 <kernel_pagetable>
    80000fb2:	83b1                	srli	a5,a5,0xc
    80000fb4:	577d                	li	a4,-1
    80000fb6:	177e                	slli	a4,a4,0x3f
    80000fb8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fba:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fbe:	12000073          	sfence.vma
  sfence_vma();
}
    80000fc2:	6422                	ld	s0,8(sp)
    80000fc4:	0141                	addi	sp,sp,16
    80000fc6:	8082                	ret

0000000080000fc8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fc8:	7139                	addi	sp,sp,-64
    80000fca:	fc06                	sd	ra,56(sp)
    80000fcc:	f822                	sd	s0,48(sp)
    80000fce:	f426                	sd	s1,40(sp)
    80000fd0:	f04a                	sd	s2,32(sp)
    80000fd2:	ec4e                	sd	s3,24(sp)
    80000fd4:	e852                	sd	s4,16(sp)
    80000fd6:	e456                	sd	s5,8(sp)
    80000fd8:	e05a                	sd	s6,0(sp)
    80000fda:	0080                	addi	s0,sp,64
    80000fdc:	84aa                	mv	s1,a0
    80000fde:	89ae                	mv	s3,a1
    80000fe0:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fe2:	57fd                	li	a5,-1
    80000fe4:	83e9                	srli	a5,a5,0x1a
    80000fe6:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fe8:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fea:	04b7f263          	bgeu	a5,a1,8000102e <walk+0x66>
    panic("walk");
    80000fee:	00007517          	auipc	a0,0x7
    80000ff2:	0e250513          	addi	a0,a0,226 # 800080d0 <digits+0x90>
    80000ff6:	fffff097          	auipc	ra,0xfffff
    80000ffa:	548080e7          	jalr	1352(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000ffe:	060a8663          	beqz	s5,8000106a <walk+0xa2>
    80001002:	00000097          	auipc	ra,0x0
    80001006:	af2080e7          	jalr	-1294(ra) # 80000af4 <kalloc>
    8000100a:	84aa                	mv	s1,a0
    8000100c:	c529                	beqz	a0,80001056 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000100e:	6605                	lui	a2,0x1
    80001010:	4581                	li	a1,0
    80001012:	00000097          	auipc	ra,0x0
    80001016:	cce080e7          	jalr	-818(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000101a:	00c4d793          	srli	a5,s1,0xc
    8000101e:	07aa                	slli	a5,a5,0xa
    80001020:	0017e793          	ori	a5,a5,1
    80001024:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001028:	3a5d                	addiw	s4,s4,-9
    8000102a:	036a0063          	beq	s4,s6,8000104a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000102e:	0149d933          	srl	s2,s3,s4
    80001032:	1ff97913          	andi	s2,s2,511
    80001036:	090e                	slli	s2,s2,0x3
    80001038:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000103a:	00093483          	ld	s1,0(s2)
    8000103e:	0014f793          	andi	a5,s1,1
    80001042:	dfd5                	beqz	a5,80000ffe <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001044:	80a9                	srli	s1,s1,0xa
    80001046:	04b2                	slli	s1,s1,0xc
    80001048:	b7c5                	j	80001028 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000104a:	00c9d513          	srli	a0,s3,0xc
    8000104e:	1ff57513          	andi	a0,a0,511
    80001052:	050e                	slli	a0,a0,0x3
    80001054:	9526                	add	a0,a0,s1
}
    80001056:	70e2                	ld	ra,56(sp)
    80001058:	7442                	ld	s0,48(sp)
    8000105a:	74a2                	ld	s1,40(sp)
    8000105c:	7902                	ld	s2,32(sp)
    8000105e:	69e2                	ld	s3,24(sp)
    80001060:	6a42                	ld	s4,16(sp)
    80001062:	6aa2                	ld	s5,8(sp)
    80001064:	6b02                	ld	s6,0(sp)
    80001066:	6121                	addi	sp,sp,64
    80001068:	8082                	ret
        return 0;
    8000106a:	4501                	li	a0,0
    8000106c:	b7ed                	j	80001056 <walk+0x8e>

000000008000106e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000106e:	57fd                	li	a5,-1
    80001070:	83e9                	srli	a5,a5,0x1a
    80001072:	00b7f463          	bgeu	a5,a1,8000107a <walkaddr+0xc>
    return 0;
    80001076:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001078:	8082                	ret
{
    8000107a:	1141                	addi	sp,sp,-16
    8000107c:	e406                	sd	ra,8(sp)
    8000107e:	e022                	sd	s0,0(sp)
    80001080:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001082:	4601                	li	a2,0
    80001084:	00000097          	auipc	ra,0x0
    80001088:	f44080e7          	jalr	-188(ra) # 80000fc8 <walk>
  if(pte == 0)
    8000108c:	c105                	beqz	a0,800010ac <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000108e:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001090:	0117f693          	andi	a3,a5,17
    80001094:	4745                	li	a4,17
    return 0;
    80001096:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001098:	00e68663          	beq	a3,a4,800010a4 <walkaddr+0x36>
}
    8000109c:	60a2                	ld	ra,8(sp)
    8000109e:	6402                	ld	s0,0(sp)
    800010a0:	0141                	addi	sp,sp,16
    800010a2:	8082                	ret
  pa = PTE2PA(*pte);
    800010a4:	00a7d513          	srli	a0,a5,0xa
    800010a8:	0532                	slli	a0,a0,0xc
  return pa;
    800010aa:	bfcd                	j	8000109c <walkaddr+0x2e>
    return 0;
    800010ac:	4501                	li	a0,0
    800010ae:	b7fd                	j	8000109c <walkaddr+0x2e>

00000000800010b0 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010b0:	715d                	addi	sp,sp,-80
    800010b2:	e486                	sd	ra,72(sp)
    800010b4:	e0a2                	sd	s0,64(sp)
    800010b6:	fc26                	sd	s1,56(sp)
    800010b8:	f84a                	sd	s2,48(sp)
    800010ba:	f44e                	sd	s3,40(sp)
    800010bc:	f052                	sd	s4,32(sp)
    800010be:	ec56                	sd	s5,24(sp)
    800010c0:	e85a                	sd	s6,16(sp)
    800010c2:	e45e                	sd	s7,8(sp)
    800010c4:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010c6:	c205                	beqz	a2,800010e6 <mappages+0x36>
    800010c8:	8aaa                	mv	s5,a0
    800010ca:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010cc:	77fd                	lui	a5,0xfffff
    800010ce:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010d2:	15fd                	addi	a1,a1,-1
    800010d4:	00c589b3          	add	s3,a1,a2
    800010d8:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010dc:	8952                	mv	s2,s4
    800010de:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010e2:	6b85                	lui	s7,0x1
    800010e4:	a015                	j	80001108 <mappages+0x58>
    panic("mappages: size");
    800010e6:	00007517          	auipc	a0,0x7
    800010ea:	ff250513          	addi	a0,a0,-14 # 800080d8 <digits+0x98>
    800010ee:	fffff097          	auipc	ra,0xfffff
    800010f2:	450080e7          	jalr	1104(ra) # 8000053e <panic>
      panic("mappages: remap");
    800010f6:	00007517          	auipc	a0,0x7
    800010fa:	ff250513          	addi	a0,a0,-14 # 800080e8 <digits+0xa8>
    800010fe:	fffff097          	auipc	ra,0xfffff
    80001102:	440080e7          	jalr	1088(ra) # 8000053e <panic>
    a += PGSIZE;
    80001106:	995e                	add	s2,s2,s7
  for(;;){
    80001108:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000110c:	4605                	li	a2,1
    8000110e:	85ca                	mv	a1,s2
    80001110:	8556                	mv	a0,s5
    80001112:	00000097          	auipc	ra,0x0
    80001116:	eb6080e7          	jalr	-330(ra) # 80000fc8 <walk>
    8000111a:	cd19                	beqz	a0,80001138 <mappages+0x88>
    if(*pte & PTE_V)
    8000111c:	611c                	ld	a5,0(a0)
    8000111e:	8b85                	andi	a5,a5,1
    80001120:	fbf9                	bnez	a5,800010f6 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001122:	80b1                	srli	s1,s1,0xc
    80001124:	04aa                	slli	s1,s1,0xa
    80001126:	0164e4b3          	or	s1,s1,s6
    8000112a:	0014e493          	ori	s1,s1,1
    8000112e:	e104                	sd	s1,0(a0)
    if(a == last)
    80001130:	fd391be3          	bne	s2,s3,80001106 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001134:	4501                	li	a0,0
    80001136:	a011                	j	8000113a <mappages+0x8a>
      return -1;
    80001138:	557d                	li	a0,-1
}
    8000113a:	60a6                	ld	ra,72(sp)
    8000113c:	6406                	ld	s0,64(sp)
    8000113e:	74e2                	ld	s1,56(sp)
    80001140:	7942                	ld	s2,48(sp)
    80001142:	79a2                	ld	s3,40(sp)
    80001144:	7a02                	ld	s4,32(sp)
    80001146:	6ae2                	ld	s5,24(sp)
    80001148:	6b42                	ld	s6,16(sp)
    8000114a:	6ba2                	ld	s7,8(sp)
    8000114c:	6161                	addi	sp,sp,80
    8000114e:	8082                	ret

0000000080001150 <kvmmap>:
{
    80001150:	1141                	addi	sp,sp,-16
    80001152:	e406                	sd	ra,8(sp)
    80001154:	e022                	sd	s0,0(sp)
    80001156:	0800                	addi	s0,sp,16
    80001158:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000115a:	86b2                	mv	a3,a2
    8000115c:	863e                	mv	a2,a5
    8000115e:	00000097          	auipc	ra,0x0
    80001162:	f52080e7          	jalr	-174(ra) # 800010b0 <mappages>
    80001166:	e509                	bnez	a0,80001170 <kvmmap+0x20>
}
    80001168:	60a2                	ld	ra,8(sp)
    8000116a:	6402                	ld	s0,0(sp)
    8000116c:	0141                	addi	sp,sp,16
    8000116e:	8082                	ret
    panic("kvmmap");
    80001170:	00007517          	auipc	a0,0x7
    80001174:	f8850513          	addi	a0,a0,-120 # 800080f8 <digits+0xb8>
    80001178:	fffff097          	auipc	ra,0xfffff
    8000117c:	3c6080e7          	jalr	966(ra) # 8000053e <panic>

0000000080001180 <kvmmake>:
{
    80001180:	1101                	addi	sp,sp,-32
    80001182:	ec06                	sd	ra,24(sp)
    80001184:	e822                	sd	s0,16(sp)
    80001186:	e426                	sd	s1,8(sp)
    80001188:	e04a                	sd	s2,0(sp)
    8000118a:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	968080e7          	jalr	-1688(ra) # 80000af4 <kalloc>
    80001194:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001196:	6605                	lui	a2,0x1
    80001198:	4581                	li	a1,0
    8000119a:	00000097          	auipc	ra,0x0
    8000119e:	b46080e7          	jalr	-1210(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011a2:	4719                	li	a4,6
    800011a4:	6685                	lui	a3,0x1
    800011a6:	10000637          	lui	a2,0x10000
    800011aa:	100005b7          	lui	a1,0x10000
    800011ae:	8526                	mv	a0,s1
    800011b0:	00000097          	auipc	ra,0x0
    800011b4:	fa0080e7          	jalr	-96(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011b8:	4719                	li	a4,6
    800011ba:	6685                	lui	a3,0x1
    800011bc:	10001637          	lui	a2,0x10001
    800011c0:	100015b7          	lui	a1,0x10001
    800011c4:	8526                	mv	a0,s1
    800011c6:	00000097          	auipc	ra,0x0
    800011ca:	f8a080e7          	jalr	-118(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011ce:	4719                	li	a4,6
    800011d0:	004006b7          	lui	a3,0x400
    800011d4:	0c000637          	lui	a2,0xc000
    800011d8:	0c0005b7          	lui	a1,0xc000
    800011dc:	8526                	mv	a0,s1
    800011de:	00000097          	auipc	ra,0x0
    800011e2:	f72080e7          	jalr	-142(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011e6:	00007917          	auipc	s2,0x7
    800011ea:	e1a90913          	addi	s2,s2,-486 # 80008000 <etext>
    800011ee:	4729                	li	a4,10
    800011f0:	80007697          	auipc	a3,0x80007
    800011f4:	e1068693          	addi	a3,a3,-496 # 8000 <_entry-0x7fff8000>
    800011f8:	4605                	li	a2,1
    800011fa:	067e                	slli	a2,a2,0x1f
    800011fc:	85b2                	mv	a1,a2
    800011fe:	8526                	mv	a0,s1
    80001200:	00000097          	auipc	ra,0x0
    80001204:	f50080e7          	jalr	-176(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001208:	4719                	li	a4,6
    8000120a:	46c5                	li	a3,17
    8000120c:	06ee                	slli	a3,a3,0x1b
    8000120e:	412686b3          	sub	a3,a3,s2
    80001212:	864a                	mv	a2,s2
    80001214:	85ca                	mv	a1,s2
    80001216:	8526                	mv	a0,s1
    80001218:	00000097          	auipc	ra,0x0
    8000121c:	f38080e7          	jalr	-200(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001220:	4729                	li	a4,10
    80001222:	6685                	lui	a3,0x1
    80001224:	00006617          	auipc	a2,0x6
    80001228:	ddc60613          	addi	a2,a2,-548 # 80007000 <_trampoline>
    8000122c:	040005b7          	lui	a1,0x4000
    80001230:	15fd                	addi	a1,a1,-1
    80001232:	05b2                	slli	a1,a1,0xc
    80001234:	8526                	mv	a0,s1
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	f1a080e7          	jalr	-230(ra) # 80001150 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000123e:	8526                	mv	a0,s1
    80001240:	00000097          	auipc	ra,0x0
    80001244:	6da080e7          	jalr	1754(ra) # 8000191a <proc_mapstacks>
}
    80001248:	8526                	mv	a0,s1
    8000124a:	60e2                	ld	ra,24(sp)
    8000124c:	6442                	ld	s0,16(sp)
    8000124e:	64a2                	ld	s1,8(sp)
    80001250:	6902                	ld	s2,0(sp)
    80001252:	6105                	addi	sp,sp,32
    80001254:	8082                	ret

0000000080001256 <kvminit>:
{
    80001256:	1141                	addi	sp,sp,-16
    80001258:	e406                	sd	ra,8(sp)
    8000125a:	e022                	sd	s0,0(sp)
    8000125c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000125e:	00000097          	auipc	ra,0x0
    80001262:	f22080e7          	jalr	-222(ra) # 80001180 <kvmmake>
    80001266:	00008797          	auipc	a5,0x8
    8000126a:	daa7bd23          	sd	a0,-582(a5) # 80009020 <kernel_pagetable>
}
    8000126e:	60a2                	ld	ra,8(sp)
    80001270:	6402                	ld	s0,0(sp)
    80001272:	0141                	addi	sp,sp,16
    80001274:	8082                	ret

0000000080001276 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001276:	715d                	addi	sp,sp,-80
    80001278:	e486                	sd	ra,72(sp)
    8000127a:	e0a2                	sd	s0,64(sp)
    8000127c:	fc26                	sd	s1,56(sp)
    8000127e:	f84a                	sd	s2,48(sp)
    80001280:	f44e                	sd	s3,40(sp)
    80001282:	f052                	sd	s4,32(sp)
    80001284:	ec56                	sd	s5,24(sp)
    80001286:	e85a                	sd	s6,16(sp)
    80001288:	e45e                	sd	s7,8(sp)
    8000128a:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000128c:	03459793          	slli	a5,a1,0x34
    80001290:	e795                	bnez	a5,800012bc <uvmunmap+0x46>
    80001292:	8a2a                	mv	s4,a0
    80001294:	892e                	mv	s2,a1
    80001296:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001298:	0632                	slli	a2,a2,0xc
    8000129a:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000129e:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a0:	6b05                	lui	s6,0x1
    800012a2:	0735e863          	bltu	a1,s3,80001312 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012a6:	60a6                	ld	ra,72(sp)
    800012a8:	6406                	ld	s0,64(sp)
    800012aa:	74e2                	ld	s1,56(sp)
    800012ac:	7942                	ld	s2,48(sp)
    800012ae:	79a2                	ld	s3,40(sp)
    800012b0:	7a02                	ld	s4,32(sp)
    800012b2:	6ae2                	ld	s5,24(sp)
    800012b4:	6b42                	ld	s6,16(sp)
    800012b6:	6ba2                	ld	s7,8(sp)
    800012b8:	6161                	addi	sp,sp,80
    800012ba:	8082                	ret
    panic("uvmunmap: not aligned");
    800012bc:	00007517          	auipc	a0,0x7
    800012c0:	e4450513          	addi	a0,a0,-444 # 80008100 <digits+0xc0>
    800012c4:	fffff097          	auipc	ra,0xfffff
    800012c8:	27a080e7          	jalr	634(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012cc:	00007517          	auipc	a0,0x7
    800012d0:	e4c50513          	addi	a0,a0,-436 # 80008118 <digits+0xd8>
    800012d4:	fffff097          	auipc	ra,0xfffff
    800012d8:	26a080e7          	jalr	618(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012dc:	00007517          	auipc	a0,0x7
    800012e0:	e4c50513          	addi	a0,a0,-436 # 80008128 <digits+0xe8>
    800012e4:	fffff097          	auipc	ra,0xfffff
    800012e8:	25a080e7          	jalr	602(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012ec:	00007517          	auipc	a0,0x7
    800012f0:	e5450513          	addi	a0,a0,-428 # 80008140 <digits+0x100>
    800012f4:	fffff097          	auipc	ra,0xfffff
    800012f8:	24a080e7          	jalr	586(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    800012fc:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800012fe:	0532                	slli	a0,a0,0xc
    80001300:	fffff097          	auipc	ra,0xfffff
    80001304:	6f8080e7          	jalr	1784(ra) # 800009f8 <kfree>
    *pte = 0;
    80001308:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000130c:	995a                	add	s2,s2,s6
    8000130e:	f9397ce3          	bgeu	s2,s3,800012a6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001312:	4601                	li	a2,0
    80001314:	85ca                	mv	a1,s2
    80001316:	8552                	mv	a0,s4
    80001318:	00000097          	auipc	ra,0x0
    8000131c:	cb0080e7          	jalr	-848(ra) # 80000fc8 <walk>
    80001320:	84aa                	mv	s1,a0
    80001322:	d54d                	beqz	a0,800012cc <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001324:	6108                	ld	a0,0(a0)
    80001326:	00157793          	andi	a5,a0,1
    8000132a:	dbcd                	beqz	a5,800012dc <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000132c:	3ff57793          	andi	a5,a0,1023
    80001330:	fb778ee3          	beq	a5,s7,800012ec <uvmunmap+0x76>
    if(do_free){
    80001334:	fc0a8ae3          	beqz	s5,80001308 <uvmunmap+0x92>
    80001338:	b7d1                	j	800012fc <uvmunmap+0x86>

000000008000133a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000133a:	1101                	addi	sp,sp,-32
    8000133c:	ec06                	sd	ra,24(sp)
    8000133e:	e822                	sd	s0,16(sp)
    80001340:	e426                	sd	s1,8(sp)
    80001342:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001344:	fffff097          	auipc	ra,0xfffff
    80001348:	7b0080e7          	jalr	1968(ra) # 80000af4 <kalloc>
    8000134c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000134e:	c519                	beqz	a0,8000135c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001350:	6605                	lui	a2,0x1
    80001352:	4581                	li	a1,0
    80001354:	00000097          	auipc	ra,0x0
    80001358:	98c080e7          	jalr	-1652(ra) # 80000ce0 <memset>
  return pagetable;
}
    8000135c:	8526                	mv	a0,s1
    8000135e:	60e2                	ld	ra,24(sp)
    80001360:	6442                	ld	s0,16(sp)
    80001362:	64a2                	ld	s1,8(sp)
    80001364:	6105                	addi	sp,sp,32
    80001366:	8082                	ret

0000000080001368 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001368:	7179                	addi	sp,sp,-48
    8000136a:	f406                	sd	ra,40(sp)
    8000136c:	f022                	sd	s0,32(sp)
    8000136e:	ec26                	sd	s1,24(sp)
    80001370:	e84a                	sd	s2,16(sp)
    80001372:	e44e                	sd	s3,8(sp)
    80001374:	e052                	sd	s4,0(sp)
    80001376:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001378:	6785                	lui	a5,0x1
    8000137a:	04f67863          	bgeu	a2,a5,800013ca <uvminit+0x62>
    8000137e:	8a2a                	mv	s4,a0
    80001380:	89ae                	mv	s3,a1
    80001382:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001384:	fffff097          	auipc	ra,0xfffff
    80001388:	770080e7          	jalr	1904(ra) # 80000af4 <kalloc>
    8000138c:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000138e:	6605                	lui	a2,0x1
    80001390:	4581                	li	a1,0
    80001392:	00000097          	auipc	ra,0x0
    80001396:	94e080e7          	jalr	-1714(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000139a:	4779                	li	a4,30
    8000139c:	86ca                	mv	a3,s2
    8000139e:	6605                	lui	a2,0x1
    800013a0:	4581                	li	a1,0
    800013a2:	8552                	mv	a0,s4
    800013a4:	00000097          	auipc	ra,0x0
    800013a8:	d0c080e7          	jalr	-756(ra) # 800010b0 <mappages>
  memmove(mem, src, sz);
    800013ac:	8626                	mv	a2,s1
    800013ae:	85ce                	mv	a1,s3
    800013b0:	854a                	mv	a0,s2
    800013b2:	00000097          	auipc	ra,0x0
    800013b6:	98e080e7          	jalr	-1650(ra) # 80000d40 <memmove>
}
    800013ba:	70a2                	ld	ra,40(sp)
    800013bc:	7402                	ld	s0,32(sp)
    800013be:	64e2                	ld	s1,24(sp)
    800013c0:	6942                	ld	s2,16(sp)
    800013c2:	69a2                	ld	s3,8(sp)
    800013c4:	6a02                	ld	s4,0(sp)
    800013c6:	6145                	addi	sp,sp,48
    800013c8:	8082                	ret
    panic("inituvm: more than a page");
    800013ca:	00007517          	auipc	a0,0x7
    800013ce:	d8e50513          	addi	a0,a0,-626 # 80008158 <digits+0x118>
    800013d2:	fffff097          	auipc	ra,0xfffff
    800013d6:	16c080e7          	jalr	364(ra) # 8000053e <panic>

00000000800013da <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013da:	1101                	addi	sp,sp,-32
    800013dc:	ec06                	sd	ra,24(sp)
    800013de:	e822                	sd	s0,16(sp)
    800013e0:	e426                	sd	s1,8(sp)
    800013e2:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013e4:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013e6:	00b67d63          	bgeu	a2,a1,80001400 <uvmdealloc+0x26>
    800013ea:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013ec:	6785                	lui	a5,0x1
    800013ee:	17fd                	addi	a5,a5,-1
    800013f0:	00f60733          	add	a4,a2,a5
    800013f4:	767d                	lui	a2,0xfffff
    800013f6:	8f71                	and	a4,a4,a2
    800013f8:	97ae                	add	a5,a5,a1
    800013fa:	8ff1                	and	a5,a5,a2
    800013fc:	00f76863          	bltu	a4,a5,8000140c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001400:	8526                	mv	a0,s1
    80001402:	60e2                	ld	ra,24(sp)
    80001404:	6442                	ld	s0,16(sp)
    80001406:	64a2                	ld	s1,8(sp)
    80001408:	6105                	addi	sp,sp,32
    8000140a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000140c:	8f99                	sub	a5,a5,a4
    8000140e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001410:	4685                	li	a3,1
    80001412:	0007861b          	sext.w	a2,a5
    80001416:	85ba                	mv	a1,a4
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	e5e080e7          	jalr	-418(ra) # 80001276 <uvmunmap>
    80001420:	b7c5                	j	80001400 <uvmdealloc+0x26>

0000000080001422 <uvmalloc>:
  if(newsz < oldsz)
    80001422:	0ab66163          	bltu	a2,a1,800014c4 <uvmalloc+0xa2>
{
    80001426:	7139                	addi	sp,sp,-64
    80001428:	fc06                	sd	ra,56(sp)
    8000142a:	f822                	sd	s0,48(sp)
    8000142c:	f426                	sd	s1,40(sp)
    8000142e:	f04a                	sd	s2,32(sp)
    80001430:	ec4e                	sd	s3,24(sp)
    80001432:	e852                	sd	s4,16(sp)
    80001434:	e456                	sd	s5,8(sp)
    80001436:	0080                	addi	s0,sp,64
    80001438:	8aaa                	mv	s5,a0
    8000143a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000143c:	6985                	lui	s3,0x1
    8000143e:	19fd                	addi	s3,s3,-1
    80001440:	95ce                	add	a1,a1,s3
    80001442:	79fd                	lui	s3,0xfffff
    80001444:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001448:	08c9f063          	bgeu	s3,a2,800014c8 <uvmalloc+0xa6>
    8000144c:	894e                	mv	s2,s3
    mem = kalloc();
    8000144e:	fffff097          	auipc	ra,0xfffff
    80001452:	6a6080e7          	jalr	1702(ra) # 80000af4 <kalloc>
    80001456:	84aa                	mv	s1,a0
    if(mem == 0){
    80001458:	c51d                	beqz	a0,80001486 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000145a:	6605                	lui	a2,0x1
    8000145c:	4581                	li	a1,0
    8000145e:	00000097          	auipc	ra,0x0
    80001462:	882080e7          	jalr	-1918(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001466:	4779                	li	a4,30
    80001468:	86a6                	mv	a3,s1
    8000146a:	6605                	lui	a2,0x1
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	c40080e7          	jalr	-960(ra) # 800010b0 <mappages>
    80001478:	e905                	bnez	a0,800014a8 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000147a:	6785                	lui	a5,0x1
    8000147c:	993e                	add	s2,s2,a5
    8000147e:	fd4968e3          	bltu	s2,s4,8000144e <uvmalloc+0x2c>
  return newsz;
    80001482:	8552                	mv	a0,s4
    80001484:	a809                	j	80001496 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001486:	864e                	mv	a2,s3
    80001488:	85ca                	mv	a1,s2
    8000148a:	8556                	mv	a0,s5
    8000148c:	00000097          	auipc	ra,0x0
    80001490:	f4e080e7          	jalr	-178(ra) # 800013da <uvmdealloc>
      return 0;
    80001494:	4501                	li	a0,0
}
    80001496:	70e2                	ld	ra,56(sp)
    80001498:	7442                	ld	s0,48(sp)
    8000149a:	74a2                	ld	s1,40(sp)
    8000149c:	7902                	ld	s2,32(sp)
    8000149e:	69e2                	ld	s3,24(sp)
    800014a0:	6a42                	ld	s4,16(sp)
    800014a2:	6aa2                	ld	s5,8(sp)
    800014a4:	6121                	addi	sp,sp,64
    800014a6:	8082                	ret
      kfree(mem);
    800014a8:	8526                	mv	a0,s1
    800014aa:	fffff097          	auipc	ra,0xfffff
    800014ae:	54e080e7          	jalr	1358(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014b2:	864e                	mv	a2,s3
    800014b4:	85ca                	mv	a1,s2
    800014b6:	8556                	mv	a0,s5
    800014b8:	00000097          	auipc	ra,0x0
    800014bc:	f22080e7          	jalr	-222(ra) # 800013da <uvmdealloc>
      return 0;
    800014c0:	4501                	li	a0,0
    800014c2:	bfd1                	j	80001496 <uvmalloc+0x74>
    return oldsz;
    800014c4:	852e                	mv	a0,a1
}
    800014c6:	8082                	ret
  return newsz;
    800014c8:	8532                	mv	a0,a2
    800014ca:	b7f1                	j	80001496 <uvmalloc+0x74>

00000000800014cc <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014cc:	7179                	addi	sp,sp,-48
    800014ce:	f406                	sd	ra,40(sp)
    800014d0:	f022                	sd	s0,32(sp)
    800014d2:	ec26                	sd	s1,24(sp)
    800014d4:	e84a                	sd	s2,16(sp)
    800014d6:	e44e                	sd	s3,8(sp)
    800014d8:	e052                	sd	s4,0(sp)
    800014da:	1800                	addi	s0,sp,48
    800014dc:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014de:	84aa                	mv	s1,a0
    800014e0:	6905                	lui	s2,0x1
    800014e2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e4:	4985                	li	s3,1
    800014e6:	a821                	j	800014fe <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014e8:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014ea:	0532                	slli	a0,a0,0xc
    800014ec:	00000097          	auipc	ra,0x0
    800014f0:	fe0080e7          	jalr	-32(ra) # 800014cc <freewalk>
      pagetable[i] = 0;
    800014f4:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f8:	04a1                	addi	s1,s1,8
    800014fa:	03248163          	beq	s1,s2,8000151c <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014fe:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001500:	00f57793          	andi	a5,a0,15
    80001504:	ff3782e3          	beq	a5,s3,800014e8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001508:	8905                	andi	a0,a0,1
    8000150a:	d57d                	beqz	a0,800014f8 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000150c:	00007517          	auipc	a0,0x7
    80001510:	c6c50513          	addi	a0,a0,-916 # 80008178 <digits+0x138>
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	02a080e7          	jalr	42(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000151c:	8552                	mv	a0,s4
    8000151e:	fffff097          	auipc	ra,0xfffff
    80001522:	4da080e7          	jalr	1242(ra) # 800009f8 <kfree>
}
    80001526:	70a2                	ld	ra,40(sp)
    80001528:	7402                	ld	s0,32(sp)
    8000152a:	64e2                	ld	s1,24(sp)
    8000152c:	6942                	ld	s2,16(sp)
    8000152e:	69a2                	ld	s3,8(sp)
    80001530:	6a02                	ld	s4,0(sp)
    80001532:	6145                	addi	sp,sp,48
    80001534:	8082                	ret

0000000080001536 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001536:	1101                	addi	sp,sp,-32
    80001538:	ec06                	sd	ra,24(sp)
    8000153a:	e822                	sd	s0,16(sp)
    8000153c:	e426                	sd	s1,8(sp)
    8000153e:	1000                	addi	s0,sp,32
    80001540:	84aa                	mv	s1,a0
  if(sz > 0)
    80001542:	e999                	bnez	a1,80001558 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001544:	8526                	mv	a0,s1
    80001546:	00000097          	auipc	ra,0x0
    8000154a:	f86080e7          	jalr	-122(ra) # 800014cc <freewalk>
}
    8000154e:	60e2                	ld	ra,24(sp)
    80001550:	6442                	ld	s0,16(sp)
    80001552:	64a2                	ld	s1,8(sp)
    80001554:	6105                	addi	sp,sp,32
    80001556:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001558:	6605                	lui	a2,0x1
    8000155a:	167d                	addi	a2,a2,-1
    8000155c:	962e                	add	a2,a2,a1
    8000155e:	4685                	li	a3,1
    80001560:	8231                	srli	a2,a2,0xc
    80001562:	4581                	li	a1,0
    80001564:	00000097          	auipc	ra,0x0
    80001568:	d12080e7          	jalr	-750(ra) # 80001276 <uvmunmap>
    8000156c:	bfe1                	j	80001544 <uvmfree+0xe>

000000008000156e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000156e:	c679                	beqz	a2,8000163c <uvmcopy+0xce>
{
    80001570:	715d                	addi	sp,sp,-80
    80001572:	e486                	sd	ra,72(sp)
    80001574:	e0a2                	sd	s0,64(sp)
    80001576:	fc26                	sd	s1,56(sp)
    80001578:	f84a                	sd	s2,48(sp)
    8000157a:	f44e                	sd	s3,40(sp)
    8000157c:	f052                	sd	s4,32(sp)
    8000157e:	ec56                	sd	s5,24(sp)
    80001580:	e85a                	sd	s6,16(sp)
    80001582:	e45e                	sd	s7,8(sp)
    80001584:	0880                	addi	s0,sp,80
    80001586:	8b2a                	mv	s6,a0
    80001588:	8aae                	mv	s5,a1
    8000158a:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000158c:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000158e:	4601                	li	a2,0
    80001590:	85ce                	mv	a1,s3
    80001592:	855a                	mv	a0,s6
    80001594:	00000097          	auipc	ra,0x0
    80001598:	a34080e7          	jalr	-1484(ra) # 80000fc8 <walk>
    8000159c:	c531                	beqz	a0,800015e8 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000159e:	6118                	ld	a4,0(a0)
    800015a0:	00177793          	andi	a5,a4,1
    800015a4:	cbb1                	beqz	a5,800015f8 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a6:	00a75593          	srli	a1,a4,0xa
    800015aa:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015ae:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015b2:	fffff097          	auipc	ra,0xfffff
    800015b6:	542080e7          	jalr	1346(ra) # 80000af4 <kalloc>
    800015ba:	892a                	mv	s2,a0
    800015bc:	c939                	beqz	a0,80001612 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015be:	6605                	lui	a2,0x1
    800015c0:	85de                	mv	a1,s7
    800015c2:	fffff097          	auipc	ra,0xfffff
    800015c6:	77e080e7          	jalr	1918(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ca:	8726                	mv	a4,s1
    800015cc:	86ca                	mv	a3,s2
    800015ce:	6605                	lui	a2,0x1
    800015d0:	85ce                	mv	a1,s3
    800015d2:	8556                	mv	a0,s5
    800015d4:	00000097          	auipc	ra,0x0
    800015d8:	adc080e7          	jalr	-1316(ra) # 800010b0 <mappages>
    800015dc:	e515                	bnez	a0,80001608 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015de:	6785                	lui	a5,0x1
    800015e0:	99be                	add	s3,s3,a5
    800015e2:	fb49e6e3          	bltu	s3,s4,8000158e <uvmcopy+0x20>
    800015e6:	a081                	j	80001626 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e8:	00007517          	auipc	a0,0x7
    800015ec:	ba050513          	addi	a0,a0,-1120 # 80008188 <digits+0x148>
    800015f0:	fffff097          	auipc	ra,0xfffff
    800015f4:	f4e080e7          	jalr	-178(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015f8:	00007517          	auipc	a0,0x7
    800015fc:	bb050513          	addi	a0,a0,-1104 # 800081a8 <digits+0x168>
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	f3e080e7          	jalr	-194(ra) # 8000053e <panic>
      kfree(mem);
    80001608:	854a                	mv	a0,s2
    8000160a:	fffff097          	auipc	ra,0xfffff
    8000160e:	3ee080e7          	jalr	1006(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001612:	4685                	li	a3,1
    80001614:	00c9d613          	srli	a2,s3,0xc
    80001618:	4581                	li	a1,0
    8000161a:	8556                	mv	a0,s5
    8000161c:	00000097          	auipc	ra,0x0
    80001620:	c5a080e7          	jalr	-934(ra) # 80001276 <uvmunmap>
  return -1;
    80001624:	557d                	li	a0,-1
}
    80001626:	60a6                	ld	ra,72(sp)
    80001628:	6406                	ld	s0,64(sp)
    8000162a:	74e2                	ld	s1,56(sp)
    8000162c:	7942                	ld	s2,48(sp)
    8000162e:	79a2                	ld	s3,40(sp)
    80001630:	7a02                	ld	s4,32(sp)
    80001632:	6ae2                	ld	s5,24(sp)
    80001634:	6b42                	ld	s6,16(sp)
    80001636:	6ba2                	ld	s7,8(sp)
    80001638:	6161                	addi	sp,sp,80
    8000163a:	8082                	ret
  return 0;
    8000163c:	4501                	li	a0,0
}
    8000163e:	8082                	ret

0000000080001640 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001640:	1141                	addi	sp,sp,-16
    80001642:	e406                	sd	ra,8(sp)
    80001644:	e022                	sd	s0,0(sp)
    80001646:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001648:	4601                	li	a2,0
    8000164a:	00000097          	auipc	ra,0x0
    8000164e:	97e080e7          	jalr	-1666(ra) # 80000fc8 <walk>
  if(pte == 0)
    80001652:	c901                	beqz	a0,80001662 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001654:	611c                	ld	a5,0(a0)
    80001656:	9bbd                	andi	a5,a5,-17
    80001658:	e11c                	sd	a5,0(a0)
}
    8000165a:	60a2                	ld	ra,8(sp)
    8000165c:	6402                	ld	s0,0(sp)
    8000165e:	0141                	addi	sp,sp,16
    80001660:	8082                	ret
    panic("uvmclear");
    80001662:	00007517          	auipc	a0,0x7
    80001666:	b6650513          	addi	a0,a0,-1178 # 800081c8 <digits+0x188>
    8000166a:	fffff097          	auipc	ra,0xfffff
    8000166e:	ed4080e7          	jalr	-300(ra) # 8000053e <panic>

0000000080001672 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001672:	c6bd                	beqz	a3,800016e0 <copyout+0x6e>
{
    80001674:	715d                	addi	sp,sp,-80
    80001676:	e486                	sd	ra,72(sp)
    80001678:	e0a2                	sd	s0,64(sp)
    8000167a:	fc26                	sd	s1,56(sp)
    8000167c:	f84a                	sd	s2,48(sp)
    8000167e:	f44e                	sd	s3,40(sp)
    80001680:	f052                	sd	s4,32(sp)
    80001682:	ec56                	sd	s5,24(sp)
    80001684:	e85a                	sd	s6,16(sp)
    80001686:	e45e                	sd	s7,8(sp)
    80001688:	e062                	sd	s8,0(sp)
    8000168a:	0880                	addi	s0,sp,80
    8000168c:	8b2a                	mv	s6,a0
    8000168e:	8c2e                	mv	s8,a1
    80001690:	8a32                	mv	s4,a2
    80001692:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001694:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001696:	6a85                	lui	s5,0x1
    80001698:	a015                	j	800016bc <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000169a:	9562                	add	a0,a0,s8
    8000169c:	0004861b          	sext.w	a2,s1
    800016a0:	85d2                	mv	a1,s4
    800016a2:	41250533          	sub	a0,a0,s2
    800016a6:	fffff097          	auipc	ra,0xfffff
    800016aa:	69a080e7          	jalr	1690(ra) # 80000d40 <memmove>

    len -= n;
    800016ae:	409989b3          	sub	s3,s3,s1
    src += n;
    800016b2:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016b4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b8:	02098263          	beqz	s3,800016dc <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016bc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016c0:	85ca                	mv	a1,s2
    800016c2:	855a                	mv	a0,s6
    800016c4:	00000097          	auipc	ra,0x0
    800016c8:	9aa080e7          	jalr	-1622(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800016cc:	cd01                	beqz	a0,800016e4 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016ce:	418904b3          	sub	s1,s2,s8
    800016d2:	94d6                	add	s1,s1,s5
    if(n > len)
    800016d4:	fc99f3e3          	bgeu	s3,s1,8000169a <copyout+0x28>
    800016d8:	84ce                	mv	s1,s3
    800016da:	b7c1                	j	8000169a <copyout+0x28>
  }
  return 0;
    800016dc:	4501                	li	a0,0
    800016de:	a021                	j	800016e6 <copyout+0x74>
    800016e0:	4501                	li	a0,0
}
    800016e2:	8082                	ret
      return -1;
    800016e4:	557d                	li	a0,-1
}
    800016e6:	60a6                	ld	ra,72(sp)
    800016e8:	6406                	ld	s0,64(sp)
    800016ea:	74e2                	ld	s1,56(sp)
    800016ec:	7942                	ld	s2,48(sp)
    800016ee:	79a2                	ld	s3,40(sp)
    800016f0:	7a02                	ld	s4,32(sp)
    800016f2:	6ae2                	ld	s5,24(sp)
    800016f4:	6b42                	ld	s6,16(sp)
    800016f6:	6ba2                	ld	s7,8(sp)
    800016f8:	6c02                	ld	s8,0(sp)
    800016fa:	6161                	addi	sp,sp,80
    800016fc:	8082                	ret

00000000800016fe <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016fe:	c6bd                	beqz	a3,8000176c <copyin+0x6e>
{
    80001700:	715d                	addi	sp,sp,-80
    80001702:	e486                	sd	ra,72(sp)
    80001704:	e0a2                	sd	s0,64(sp)
    80001706:	fc26                	sd	s1,56(sp)
    80001708:	f84a                	sd	s2,48(sp)
    8000170a:	f44e                	sd	s3,40(sp)
    8000170c:	f052                	sd	s4,32(sp)
    8000170e:	ec56                	sd	s5,24(sp)
    80001710:	e85a                	sd	s6,16(sp)
    80001712:	e45e                	sd	s7,8(sp)
    80001714:	e062                	sd	s8,0(sp)
    80001716:	0880                	addi	s0,sp,80
    80001718:	8b2a                	mv	s6,a0
    8000171a:	8a2e                	mv	s4,a1
    8000171c:	8c32                	mv	s8,a2
    8000171e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001720:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001722:	6a85                	lui	s5,0x1
    80001724:	a015                	j	80001748 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001726:	9562                	add	a0,a0,s8
    80001728:	0004861b          	sext.w	a2,s1
    8000172c:	412505b3          	sub	a1,a0,s2
    80001730:	8552                	mv	a0,s4
    80001732:	fffff097          	auipc	ra,0xfffff
    80001736:	60e080e7          	jalr	1550(ra) # 80000d40 <memmove>

    len -= n;
    8000173a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001740:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001744:	02098263          	beqz	s3,80001768 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001748:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000174c:	85ca                	mv	a1,s2
    8000174e:	855a                	mv	a0,s6
    80001750:	00000097          	auipc	ra,0x0
    80001754:	91e080e7          	jalr	-1762(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    80001758:	cd01                	beqz	a0,80001770 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000175a:	418904b3          	sub	s1,s2,s8
    8000175e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001760:	fc99f3e3          	bgeu	s3,s1,80001726 <copyin+0x28>
    80001764:	84ce                	mv	s1,s3
    80001766:	b7c1                	j	80001726 <copyin+0x28>
  }
  return 0;
    80001768:	4501                	li	a0,0
    8000176a:	a021                	j	80001772 <copyin+0x74>
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
    800017e6:	88c080e7          	jalr	-1908(ra) # 8000106e <walkaddr>
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

000000008000183e <displayStats>:
}

// Scheduler statistics function 
int displayStats(int n, int prog_num)
{
    if(pflag==1)
    8000183e:	00007717          	auipc	a4,0x7
    80001842:	7ea72703          	lw	a4,2026(a4) # 80009028 <pflag>
    80001846:	4785                	li	a5,1
    80001848:	00f70463          	beq	a4,a5,80001850 <displayStats+0x12>
	   printf("Total ticks : %d\n",(ticksArray[prog1id]+ticksArray[prog2id]+ticksArray[prog3id]));
   	   pflag=0;

    }
    return 1;
}
    8000184c:	4505                	li	a0,1
    8000184e:	8082                	ret
{
    80001850:	7179                	addi	sp,sp,-48
    80001852:	f406                	sd	ra,40(sp)
    80001854:	f022                	sd	s0,32(sp)
    80001856:	ec26                	sd	s1,24(sp)
    80001858:	e84a                	sd	s2,16(sp)
    8000185a:	e44e                	sd	s3,8(sp)
    8000185c:	e052                	sd	s4,0(sp)
    8000185e:	1800                	addi	s0,sp,48
	   printf("Ticks in prog 1 : %d\n",ticksArray[prog1id]);
    80001860:	00010497          	auipc	s1,0x10
    80001864:	a5048493          	addi	s1,s1,-1456 # 800112b0 <ticksArray>
    80001868:	00007a17          	auipc	s4,0x7
    8000186c:	7cca0a13          	addi	s4,s4,1996 # 80009034 <prog1id>
    80001870:	000a2783          	lw	a5,0(s4)
    80001874:	078a                	slli	a5,a5,0x2
    80001876:	97a6                	add	a5,a5,s1
    80001878:	438c                	lw	a1,0(a5)
    8000187a:	00007517          	auipc	a0,0x7
    8000187e:	95e50513          	addi	a0,a0,-1698 # 800081d8 <digits+0x198>
    80001882:	fffff097          	auipc	ra,0xfffff
    80001886:	d06080e7          	jalr	-762(ra) # 80000588 <printf>
	   printf("Ticks in prog 2 : %d\n",ticksArray[prog2id]);
    8000188a:	00007997          	auipc	s3,0x7
    8000188e:	7a698993          	addi	s3,s3,1958 # 80009030 <prog2id>
    80001892:	0009a783          	lw	a5,0(s3)
    80001896:	078a                	slli	a5,a5,0x2
    80001898:	97a6                	add	a5,a5,s1
    8000189a:	438c                	lw	a1,0(a5)
    8000189c:	00007517          	auipc	a0,0x7
    800018a0:	95450513          	addi	a0,a0,-1708 # 800081f0 <digits+0x1b0>
    800018a4:	fffff097          	auipc	ra,0xfffff
    800018a8:	ce4080e7          	jalr	-796(ra) # 80000588 <printf>
	   printf("Ticks in prog 3 : %d\n",ticksArray[prog3id]);
    800018ac:	00007917          	auipc	s2,0x7
    800018b0:	78090913          	addi	s2,s2,1920 # 8000902c <prog3id>
    800018b4:	00092783          	lw	a5,0(s2)
    800018b8:	078a                	slli	a5,a5,0x2
    800018ba:	97a6                	add	a5,a5,s1
    800018bc:	438c                	lw	a1,0(a5)
    800018be:	00007517          	auipc	a0,0x7
    800018c2:	94a50513          	addi	a0,a0,-1718 # 80008208 <digits+0x1c8>
    800018c6:	fffff097          	auipc	ra,0xfffff
    800018ca:	cc2080e7          	jalr	-830(ra) # 80000588 <printf>
	   printf("Total ticks : %d\n",(ticksArray[prog1id]+ticksArray[prog2id]+ticksArray[prog3id]));
    800018ce:	000a2703          	lw	a4,0(s4)
    800018d2:	070a                	slli	a4,a4,0x2
    800018d4:	9726                	add	a4,a4,s1
    800018d6:	0009a783          	lw	a5,0(s3)
    800018da:	078a                	slli	a5,a5,0x2
    800018dc:	97a6                	add	a5,a5,s1
    800018de:	430c                	lw	a1,0(a4)
    800018e0:	439c                	lw	a5,0(a5)
    800018e2:	9fad                	addw	a5,a5,a1
    800018e4:	00092703          	lw	a4,0(s2)
    800018e8:	070a                	slli	a4,a4,0x2
    800018ea:	94ba                	add	s1,s1,a4
    800018ec:	408c                	lw	a1,0(s1)
    800018ee:	9dbd                	addw	a1,a1,a5
    800018f0:	00007517          	auipc	a0,0x7
    800018f4:	93050513          	addi	a0,a0,-1744 # 80008220 <digits+0x1e0>
    800018f8:	fffff097          	auipc	ra,0xfffff
    800018fc:	c90080e7          	jalr	-880(ra) # 80000588 <printf>
   	   pflag=0;
    80001900:	00007797          	auipc	a5,0x7
    80001904:	7207a423          	sw	zero,1832(a5) # 80009028 <pflag>
}
    80001908:	4505                	li	a0,1
    8000190a:	70a2                	ld	ra,40(sp)
    8000190c:	7402                	ld	s0,32(sp)
    8000190e:	64e2                	ld	s1,24(sp)
    80001910:	6942                	ld	s2,16(sp)
    80001912:	69a2                	ld	s3,8(sp)
    80001914:	6a02                	ld	s4,0(sp)
    80001916:	6145                	addi	sp,sp,48
    80001918:	8082                	ret

000000008000191a <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    8000191a:	7139                	addi	sp,sp,-64
    8000191c:	fc06                	sd	ra,56(sp)
    8000191e:	f822                	sd	s0,48(sp)
    80001920:	f426                	sd	s1,40(sp)
    80001922:	f04a                	sd	s2,32(sp)
    80001924:	ec4e                	sd	s3,24(sp)
    80001926:	e852                	sd	s4,16(sp)
    80001928:	e456                	sd	s5,8(sp)
    8000192a:	e05a                	sd	s6,0(sp)
    8000192c:	0080                	addi	s0,sp,64
    8000192e:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001930:	00010497          	auipc	s1,0x10
    80001934:	eb048493          	addi	s1,s1,-336 # 800117e0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001938:	8b26                	mv	s6,s1
    8000193a:	00006a97          	auipc	s5,0x6
    8000193e:	6c6a8a93          	addi	s5,s5,1734 # 80008000 <etext>
    80001942:	04000937          	lui	s2,0x4000
    80001946:	197d                	addi	s2,s2,-1
    80001948:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000194a:	00016a17          	auipc	s4,0x16
    8000194e:	c96a0a13          	addi	s4,s4,-874 # 800175e0 <tickslock>
    char *pa = kalloc();
    80001952:	fffff097          	auipc	ra,0xfffff
    80001956:	1a2080e7          	jalr	418(ra) # 80000af4 <kalloc>
    8000195a:	862a                	mv	a2,a0
    if(pa == 0)
    8000195c:	c131                	beqz	a0,800019a0 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    8000195e:	416485b3          	sub	a1,s1,s6
    80001962:	858d                	srai	a1,a1,0x3
    80001964:	000ab783          	ld	a5,0(s5)
    80001968:	02f585b3          	mul	a1,a1,a5
    8000196c:	2585                	addiw	a1,a1,1
    8000196e:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001972:	4719                	li	a4,6
    80001974:	6685                	lui	a3,0x1
    80001976:	40b905b3          	sub	a1,s2,a1
    8000197a:	854e                	mv	a0,s3
    8000197c:	fffff097          	auipc	ra,0xfffff
    80001980:	7d4080e7          	jalr	2004(ra) # 80001150 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001984:	17848493          	addi	s1,s1,376
    80001988:	fd4495e3          	bne	s1,s4,80001952 <proc_mapstacks+0x38>
  }
}
    8000198c:	70e2                	ld	ra,56(sp)
    8000198e:	7442                	ld	s0,48(sp)
    80001990:	74a2                	ld	s1,40(sp)
    80001992:	7902                	ld	s2,32(sp)
    80001994:	69e2                	ld	s3,24(sp)
    80001996:	6a42                	ld	s4,16(sp)
    80001998:	6aa2                	ld	s5,8(sp)
    8000199a:	6b02                	ld	s6,0(sp)
    8000199c:	6121                	addi	sp,sp,64
    8000199e:	8082                	ret
      panic("kalloc");
    800019a0:	00007517          	auipc	a0,0x7
    800019a4:	89850513          	addi	a0,a0,-1896 # 80008238 <digits+0x1f8>
    800019a8:	fffff097          	auipc	ra,0xfffff
    800019ac:	b96080e7          	jalr	-1130(ra) # 8000053e <panic>

00000000800019b0 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800019b0:	7139                	addi	sp,sp,-64
    800019b2:	fc06                	sd	ra,56(sp)
    800019b4:	f822                	sd	s0,48(sp)
    800019b6:	f426                	sd	s1,40(sp)
    800019b8:	f04a                	sd	s2,32(sp)
    800019ba:	ec4e                	sd	s3,24(sp)
    800019bc:	e852                	sd	s4,16(sp)
    800019be:	e456                	sd	s5,8(sp)
    800019c0:	e05a                	sd	s6,0(sp)
    800019c2:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800019c4:	00007597          	auipc	a1,0x7
    800019c8:	87c58593          	addi	a1,a1,-1924 # 80008240 <digits+0x200>
    800019cc:	00010517          	auipc	a0,0x10
    800019d0:	9e450513          	addi	a0,a0,-1564 # 800113b0 <pid_lock>
    800019d4:	fffff097          	auipc	ra,0xfffff
    800019d8:	180080e7          	jalr	384(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    800019dc:	00007597          	auipc	a1,0x7
    800019e0:	86c58593          	addi	a1,a1,-1940 # 80008248 <digits+0x208>
    800019e4:	00010517          	auipc	a0,0x10
    800019e8:	9e450513          	addi	a0,a0,-1564 # 800113c8 <wait_lock>
    800019ec:	fffff097          	auipc	ra,0xfffff
    800019f0:	168080e7          	jalr	360(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    800019f4:	00010497          	auipc	s1,0x10
    800019f8:	dec48493          	addi	s1,s1,-532 # 800117e0 <proc>
      initlock(&p->lock, "proc");
    800019fc:	00007b17          	auipc	s6,0x7
    80001a00:	85cb0b13          	addi	s6,s6,-1956 # 80008258 <digits+0x218>
      p->kstack = KSTACK((int) (p - proc));
    80001a04:	8aa6                	mv	s5,s1
    80001a06:	00006a17          	auipc	s4,0x6
    80001a0a:	5faa0a13          	addi	s4,s4,1530 # 80008000 <etext>
    80001a0e:	04000937          	lui	s2,0x4000
    80001a12:	197d                	addi	s2,s2,-1
    80001a14:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a16:	00016997          	auipc	s3,0x16
    80001a1a:	bca98993          	addi	s3,s3,-1078 # 800175e0 <tickslock>
      initlock(&p->lock, "proc");
    80001a1e:	85da                	mv	a1,s6
    80001a20:	8526                	mv	a0,s1
    80001a22:	fffff097          	auipc	ra,0xfffff
    80001a26:	132080e7          	jalr	306(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001a2a:	415487b3          	sub	a5,s1,s5
    80001a2e:	878d                	srai	a5,a5,0x3
    80001a30:	000a3703          	ld	a4,0(s4)
    80001a34:	02e787b3          	mul	a5,a5,a4
    80001a38:	2785                	addiw	a5,a5,1
    80001a3a:	00d7979b          	slliw	a5,a5,0xd
    80001a3e:	40f907b3          	sub	a5,s2,a5
    80001a42:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a44:	17848493          	addi	s1,s1,376
    80001a48:	fd349be3          	bne	s1,s3,80001a1e <procinit+0x6e>
  }
}
    80001a4c:	70e2                	ld	ra,56(sp)
    80001a4e:	7442                	ld	s0,48(sp)
    80001a50:	74a2                	ld	s1,40(sp)
    80001a52:	7902                	ld	s2,32(sp)
    80001a54:	69e2                	ld	s3,24(sp)
    80001a56:	6a42                	ld	s4,16(sp)
    80001a58:	6aa2                	ld	s5,8(sp)
    80001a5a:	6b02                	ld	s6,0(sp)
    80001a5c:	6121                	addi	sp,sp,64
    80001a5e:	8082                	ret

0000000080001a60 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001a60:	1141                	addi	sp,sp,-16
    80001a62:	e422                	sd	s0,8(sp)
    80001a64:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a66:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001a68:	2501                	sext.w	a0,a0
    80001a6a:	6422                	ld	s0,8(sp)
    80001a6c:	0141                	addi	sp,sp,16
    80001a6e:	8082                	ret

0000000080001a70 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001a70:	1141                	addi	sp,sp,-16
    80001a72:	e422                	sd	s0,8(sp)
    80001a74:	0800                	addi	s0,sp,16
    80001a76:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001a78:	2781                	sext.w	a5,a5
    80001a7a:	079e                	slli	a5,a5,0x7
  return c;
}
    80001a7c:	00010517          	auipc	a0,0x10
    80001a80:	96450513          	addi	a0,a0,-1692 # 800113e0 <cpus>
    80001a84:	953e                	add	a0,a0,a5
    80001a86:	6422                	ld	s0,8(sp)
    80001a88:	0141                	addi	sp,sp,16
    80001a8a:	8082                	ret

0000000080001a8c <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001a8c:	1101                	addi	sp,sp,-32
    80001a8e:	ec06                	sd	ra,24(sp)
    80001a90:	e822                	sd	s0,16(sp)
    80001a92:	e426                	sd	s1,8(sp)
    80001a94:	1000                	addi	s0,sp,32
  push_off();
    80001a96:	fffff097          	auipc	ra,0xfffff
    80001a9a:	102080e7          	jalr	258(ra) # 80000b98 <push_off>
    80001a9e:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001aa0:	2781                	sext.w	a5,a5
    80001aa2:	079e                	slli	a5,a5,0x7
    80001aa4:	00010717          	auipc	a4,0x10
    80001aa8:	80c70713          	addi	a4,a4,-2036 # 800112b0 <ticksArray>
    80001aac:	97ba                	add	a5,a5,a4
    80001aae:	1307b483          	ld	s1,304(a5)
  pop_off();
    80001ab2:	fffff097          	auipc	ra,0xfffff
    80001ab6:	186080e7          	jalr	390(ra) # 80000c38 <pop_off>
  return p;
}
    80001aba:	8526                	mv	a0,s1
    80001abc:	60e2                	ld	ra,24(sp)
    80001abe:	6442                	ld	s0,16(sp)
    80001ac0:	64a2                	ld	s1,8(sp)
    80001ac2:	6105                	addi	sp,sp,32
    80001ac4:	8082                	ret

0000000080001ac6 <allocateTickets>:
{
    80001ac6:	1101                	addi	sp,sp,-32
    80001ac8:	ec06                	sd	ra,24(sp)
    80001aca:	e822                	sd	s0,16(sp)
    80001acc:	e426                	sd	s1,8(sp)
    80001ace:	1000                	addi	s0,sp,32
    80001ad0:	84aa                	mv	s1,a0
    struct proc *p = myproc();
    80001ad2:	00000097          	auipc	ra,0x0
    80001ad6:	fba080e7          	jalr	-70(ra) # 80001a8c <myproc>
    p->tickets=n;
    80001ada:	16952423          	sw	s1,360(a0)
	p->stride = 30000/n;
    80001ade:	679d                	lui	a5,0x7
    80001ae0:	5307879b          	addiw	a5,a5,1328
    80001ae4:	0297c7bb          	divw	a5,a5,s1
    80001ae8:	16f52823          	sw	a5,368(a0)
	p->pass = p->stride;
    80001aec:	16f52623          	sw	a5,364(a0)
    ticksArray[p->pid]=0;
    80001af0:	591c                	lw	a5,48(a0)
    80001af2:	00279713          	slli	a4,a5,0x2
    80001af6:	0000f797          	auipc	a5,0xf
    80001afa:	7ba78793          	addi	a5,a5,1978 # 800112b0 <ticksArray>
    80001afe:	97ba                	add	a5,a5,a4
    80001b00:	0007a023          	sw	zero,0(a5)
    if(n==30){
    80001b04:	47f9                	li	a5,30
    80001b06:	00f48e63          	beq	s1,a5,80001b22 <allocateTickets+0x5c>
    else if(n==20){
    80001b0a:	47d1                	li	a5,20
    80001b0c:	04f48063          	beq	s1,a5,80001b4c <allocateTickets+0x86>
    else if(n==10){
    80001b10:	47a9                	li	a5,10
    80001b12:	06f48263          	beq	s1,a5,80001b76 <allocateTickets+0xb0>
}
    80001b16:	4505                	li	a0,1
    80001b18:	60e2                	ld	ra,24(sp)
    80001b1a:	6442                	ld	s0,16(sp)
    80001b1c:	64a2                	ld	s1,8(sp)
    80001b1e:	6105                	addi	sp,sp,32
    80001b20:	8082                	ret
	    prog1id=p->pid;
    80001b22:	591c                	lw	a5,48(a0)
    80001b24:	00007717          	auipc	a4,0x7
    80001b28:	50f72823          	sw	a5,1296(a4) # 80009034 <prog1id>
	    pflag=1;
    80001b2c:	4785                	li	a5,1
    80001b2e:	00007717          	auipc	a4,0x7
    80001b32:	4ef72d23          	sw	a5,1274(a4) # 80009028 <pflag>
		printf("Pass for prog 1 : %d\n",p->pass);
    80001b36:	3e800593          	li	a1,1000
    80001b3a:	00006517          	auipc	a0,0x6
    80001b3e:	72650513          	addi	a0,a0,1830 # 80008260 <digits+0x220>
    80001b42:	fffff097          	auipc	ra,0xfffff
    80001b46:	a46080e7          	jalr	-1466(ra) # 80000588 <printf>
    80001b4a:	b7f1                	j	80001b16 <allocateTickets+0x50>
	    prog2id=p->pid;
    80001b4c:	591c                	lw	a5,48(a0)
    80001b4e:	00007717          	auipc	a4,0x7
    80001b52:	4ef72123          	sw	a5,1250(a4) # 80009030 <prog2id>
	    pflag=1;
    80001b56:	4785                	li	a5,1
    80001b58:	00007717          	auipc	a4,0x7
    80001b5c:	4cf72823          	sw	a5,1232(a4) # 80009028 <pflag>
		printf("Pass for prog 2 : %d\n",p->pass);
    80001b60:	5dc00593          	li	a1,1500
    80001b64:	00006517          	auipc	a0,0x6
    80001b68:	71450513          	addi	a0,a0,1812 # 80008278 <digits+0x238>
    80001b6c:	fffff097          	auipc	ra,0xfffff
    80001b70:	a1c080e7          	jalr	-1508(ra) # 80000588 <printf>
    80001b74:	b74d                	j	80001b16 <allocateTickets+0x50>
	    prog3id=p->pid;
    80001b76:	591c                	lw	a5,48(a0)
    80001b78:	00007717          	auipc	a4,0x7
    80001b7c:	4af72a23          	sw	a5,1204(a4) # 8000902c <prog3id>
	    pflag=1;
    80001b80:	4785                	li	a5,1
    80001b82:	00007717          	auipc	a4,0x7
    80001b86:	4af72323          	sw	a5,1190(a4) # 80009028 <pflag>
		printf("Pass for prog 3 : %d\n",p->pass);
    80001b8a:	6585                	lui	a1,0x1
    80001b8c:	bb858593          	addi	a1,a1,-1096 # bb8 <_entry-0x7ffff448>
    80001b90:	00006517          	auipc	a0,0x6
    80001b94:	70050513          	addi	a0,a0,1792 # 80008290 <digits+0x250>
    80001b98:	fffff097          	auipc	ra,0xfffff
    80001b9c:	9f0080e7          	jalr	-1552(ra) # 80000588 <printf>
    80001ba0:	bf9d                	j	80001b16 <allocateTickets+0x50>

0000000080001ba2 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001ba2:	1141                	addi	sp,sp,-16
    80001ba4:	e406                	sd	ra,8(sp)
    80001ba6:	e022                	sd	s0,0(sp)
    80001ba8:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001baa:	00000097          	auipc	ra,0x0
    80001bae:	ee2080e7          	jalr	-286(ra) # 80001a8c <myproc>
    80001bb2:	fffff097          	auipc	ra,0xfffff
    80001bb6:	0e6080e7          	jalr	230(ra) # 80000c98 <release>

  if (first) {
    80001bba:	00007797          	auipc	a5,0x7
    80001bbe:	d267a783          	lw	a5,-730(a5) # 800088e0 <first.1705>
    80001bc2:	eb89                	bnez	a5,80001bd4 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001bc4:	00001097          	auipc	ra,0x1
    80001bc8:	c62080e7          	jalr	-926(ra) # 80002826 <usertrapret>
}
    80001bcc:	60a2                	ld	ra,8(sp)
    80001bce:	6402                	ld	s0,0(sp)
    80001bd0:	0141                	addi	sp,sp,16
    80001bd2:	8082                	ret
    first = 0;
    80001bd4:	00007797          	auipc	a5,0x7
    80001bd8:	d007a623          	sw	zero,-756(a5) # 800088e0 <first.1705>
    fsinit(ROOTDEV);
    80001bdc:	4505                	li	a0,1
    80001bde:	00002097          	auipc	ra,0x2
    80001be2:	9f4080e7          	jalr	-1548(ra) # 800035d2 <fsinit>
    80001be6:	bff9                	j	80001bc4 <forkret+0x22>

0000000080001be8 <allocpid>:
allocpid() {
    80001be8:	1101                	addi	sp,sp,-32
    80001bea:	ec06                	sd	ra,24(sp)
    80001bec:	e822                	sd	s0,16(sp)
    80001bee:	e426                	sd	s1,8(sp)
    80001bf0:	e04a                	sd	s2,0(sp)
    80001bf2:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001bf4:	0000f917          	auipc	s2,0xf
    80001bf8:	7bc90913          	addi	s2,s2,1980 # 800113b0 <pid_lock>
    80001bfc:	854a                	mv	a0,s2
    80001bfe:	fffff097          	auipc	ra,0xfffff
    80001c02:	fe6080e7          	jalr	-26(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001c06:	00007797          	auipc	a5,0x7
    80001c0a:	cde78793          	addi	a5,a5,-802 # 800088e4 <nextpid>
    80001c0e:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001c10:	0014871b          	addiw	a4,s1,1
    80001c14:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001c16:	854a                	mv	a0,s2
    80001c18:	fffff097          	auipc	ra,0xfffff
    80001c1c:	080080e7          	jalr	128(ra) # 80000c98 <release>
}
    80001c20:	8526                	mv	a0,s1
    80001c22:	60e2                	ld	ra,24(sp)
    80001c24:	6442                	ld	s0,16(sp)
    80001c26:	64a2                	ld	s1,8(sp)
    80001c28:	6902                	ld	s2,0(sp)
    80001c2a:	6105                	addi	sp,sp,32
    80001c2c:	8082                	ret

0000000080001c2e <proc_pagetable>:
{
    80001c2e:	1101                	addi	sp,sp,-32
    80001c30:	ec06                	sd	ra,24(sp)
    80001c32:	e822                	sd	s0,16(sp)
    80001c34:	e426                	sd	s1,8(sp)
    80001c36:	e04a                	sd	s2,0(sp)
    80001c38:	1000                	addi	s0,sp,32
    80001c3a:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001c3c:	fffff097          	auipc	ra,0xfffff
    80001c40:	6fe080e7          	jalr	1790(ra) # 8000133a <uvmcreate>
    80001c44:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001c46:	c121                	beqz	a0,80001c86 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001c48:	4729                	li	a4,10
    80001c4a:	00005697          	auipc	a3,0x5
    80001c4e:	3b668693          	addi	a3,a3,950 # 80007000 <_trampoline>
    80001c52:	6605                	lui	a2,0x1
    80001c54:	040005b7          	lui	a1,0x4000
    80001c58:	15fd                	addi	a1,a1,-1
    80001c5a:	05b2                	slli	a1,a1,0xc
    80001c5c:	fffff097          	auipc	ra,0xfffff
    80001c60:	454080e7          	jalr	1108(ra) # 800010b0 <mappages>
    80001c64:	02054863          	bltz	a0,80001c94 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001c68:	4719                	li	a4,6
    80001c6a:	05893683          	ld	a3,88(s2)
    80001c6e:	6605                	lui	a2,0x1
    80001c70:	020005b7          	lui	a1,0x2000
    80001c74:	15fd                	addi	a1,a1,-1
    80001c76:	05b6                	slli	a1,a1,0xd
    80001c78:	8526                	mv	a0,s1
    80001c7a:	fffff097          	auipc	ra,0xfffff
    80001c7e:	436080e7          	jalr	1078(ra) # 800010b0 <mappages>
    80001c82:	02054163          	bltz	a0,80001ca4 <proc_pagetable+0x76>
}
    80001c86:	8526                	mv	a0,s1
    80001c88:	60e2                	ld	ra,24(sp)
    80001c8a:	6442                	ld	s0,16(sp)
    80001c8c:	64a2                	ld	s1,8(sp)
    80001c8e:	6902                	ld	s2,0(sp)
    80001c90:	6105                	addi	sp,sp,32
    80001c92:	8082                	ret
    uvmfree(pagetable, 0);
    80001c94:	4581                	li	a1,0
    80001c96:	8526                	mv	a0,s1
    80001c98:	00000097          	auipc	ra,0x0
    80001c9c:	89e080e7          	jalr	-1890(ra) # 80001536 <uvmfree>
    return 0;
    80001ca0:	4481                	li	s1,0
    80001ca2:	b7d5                	j	80001c86 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ca4:	4681                	li	a3,0
    80001ca6:	4605                	li	a2,1
    80001ca8:	040005b7          	lui	a1,0x4000
    80001cac:	15fd                	addi	a1,a1,-1
    80001cae:	05b2                	slli	a1,a1,0xc
    80001cb0:	8526                	mv	a0,s1
    80001cb2:	fffff097          	auipc	ra,0xfffff
    80001cb6:	5c4080e7          	jalr	1476(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001cba:	4581                	li	a1,0
    80001cbc:	8526                	mv	a0,s1
    80001cbe:	00000097          	auipc	ra,0x0
    80001cc2:	878080e7          	jalr	-1928(ra) # 80001536 <uvmfree>
    return 0;
    80001cc6:	4481                	li	s1,0
    80001cc8:	bf7d                	j	80001c86 <proc_pagetable+0x58>

0000000080001cca <proc_freepagetable>:
{
    80001cca:	1101                	addi	sp,sp,-32
    80001ccc:	ec06                	sd	ra,24(sp)
    80001cce:	e822                	sd	s0,16(sp)
    80001cd0:	e426                	sd	s1,8(sp)
    80001cd2:	e04a                	sd	s2,0(sp)
    80001cd4:	1000                	addi	s0,sp,32
    80001cd6:	84aa                	mv	s1,a0
    80001cd8:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001cda:	4681                	li	a3,0
    80001cdc:	4605                	li	a2,1
    80001cde:	040005b7          	lui	a1,0x4000
    80001ce2:	15fd                	addi	a1,a1,-1
    80001ce4:	05b2                	slli	a1,a1,0xc
    80001ce6:	fffff097          	auipc	ra,0xfffff
    80001cea:	590080e7          	jalr	1424(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001cee:	4681                	li	a3,0
    80001cf0:	4605                	li	a2,1
    80001cf2:	020005b7          	lui	a1,0x2000
    80001cf6:	15fd                	addi	a1,a1,-1
    80001cf8:	05b6                	slli	a1,a1,0xd
    80001cfa:	8526                	mv	a0,s1
    80001cfc:	fffff097          	auipc	ra,0xfffff
    80001d00:	57a080e7          	jalr	1402(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001d04:	85ca                	mv	a1,s2
    80001d06:	8526                	mv	a0,s1
    80001d08:	00000097          	auipc	ra,0x0
    80001d0c:	82e080e7          	jalr	-2002(ra) # 80001536 <uvmfree>
}
    80001d10:	60e2                	ld	ra,24(sp)
    80001d12:	6442                	ld	s0,16(sp)
    80001d14:	64a2                	ld	s1,8(sp)
    80001d16:	6902                	ld	s2,0(sp)
    80001d18:	6105                	addi	sp,sp,32
    80001d1a:	8082                	ret

0000000080001d1c <freeproc>:
{
    80001d1c:	1101                	addi	sp,sp,-32
    80001d1e:	ec06                	sd	ra,24(sp)
    80001d20:	e822                	sd	s0,16(sp)
    80001d22:	e426                	sd	s1,8(sp)
    80001d24:	1000                	addi	s0,sp,32
    80001d26:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001d28:	6d28                	ld	a0,88(a0)
    80001d2a:	c509                	beqz	a0,80001d34 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001d2c:	fffff097          	auipc	ra,0xfffff
    80001d30:	ccc080e7          	jalr	-820(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001d34:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001d38:	68a8                	ld	a0,80(s1)
    80001d3a:	c511                	beqz	a0,80001d46 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001d3c:	64ac                	ld	a1,72(s1)
    80001d3e:	00000097          	auipc	ra,0x0
    80001d42:	f8c080e7          	jalr	-116(ra) # 80001cca <proc_freepagetable>
  p->pagetable = 0;
    80001d46:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001d4a:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001d4e:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001d52:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001d56:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001d5a:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001d5e:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001d62:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001d66:	0004ac23          	sw	zero,24(s1)
}
    80001d6a:	60e2                	ld	ra,24(sp)
    80001d6c:	6442                	ld	s0,16(sp)
    80001d6e:	64a2                	ld	s1,8(sp)
    80001d70:	6105                	addi	sp,sp,32
    80001d72:	8082                	ret

0000000080001d74 <allocproc>:
{
    80001d74:	1101                	addi	sp,sp,-32
    80001d76:	ec06                	sd	ra,24(sp)
    80001d78:	e822                	sd	s0,16(sp)
    80001d7a:	e426                	sd	s1,8(sp)
    80001d7c:	e04a                	sd	s2,0(sp)
    80001d7e:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d80:	00010497          	auipc	s1,0x10
    80001d84:	a6048493          	addi	s1,s1,-1440 # 800117e0 <proc>
    80001d88:	00016917          	auipc	s2,0x16
    80001d8c:	85890913          	addi	s2,s2,-1960 # 800175e0 <tickslock>
    acquire(&p->lock);
    80001d90:	8526                	mv	a0,s1
    80001d92:	fffff097          	auipc	ra,0xfffff
    80001d96:	e52080e7          	jalr	-430(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001d9a:	4c9c                	lw	a5,24(s1)
    80001d9c:	cf81                	beqz	a5,80001db4 <allocproc+0x40>
      release(&p->lock);
    80001d9e:	8526                	mv	a0,s1
    80001da0:	fffff097          	auipc	ra,0xfffff
    80001da4:	ef8080e7          	jalr	-264(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001da8:	17848493          	addi	s1,s1,376
    80001dac:	ff2492e3          	bne	s1,s2,80001d90 <allocproc+0x1c>
  return 0;
    80001db0:	4481                	li	s1,0
    80001db2:	a8a1                	j	80001e0a <allocproc+0x96>
  p->pid = allocpid();
    80001db4:	00000097          	auipc	ra,0x0
    80001db8:	e34080e7          	jalr	-460(ra) # 80001be8 <allocpid>
    80001dbc:	d888                	sw	a0,48(s1)
  p->tickets = 10; //default value
    80001dbe:	47a9                	li	a5,10
    80001dc0:	16f4a423          	sw	a5,360(s1)
  p->state = USED;
    80001dc4:	4785                	li	a5,1
    80001dc6:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001dc8:	fffff097          	auipc	ra,0xfffff
    80001dcc:	d2c080e7          	jalr	-724(ra) # 80000af4 <kalloc>
    80001dd0:	892a                	mv	s2,a0
    80001dd2:	eca8                	sd	a0,88(s1)
    80001dd4:	c131                	beqz	a0,80001e18 <allocproc+0xa4>
  p->pagetable = proc_pagetable(p);
    80001dd6:	8526                	mv	a0,s1
    80001dd8:	00000097          	auipc	ra,0x0
    80001ddc:	e56080e7          	jalr	-426(ra) # 80001c2e <proc_pagetable>
    80001de0:	892a                	mv	s2,a0
    80001de2:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001de4:	c531                	beqz	a0,80001e30 <allocproc+0xbc>
  memset(&p->context, 0, sizeof(p->context));
    80001de6:	07000613          	li	a2,112
    80001dea:	4581                	li	a1,0
    80001dec:	06048513          	addi	a0,s1,96
    80001df0:	fffff097          	auipc	ra,0xfffff
    80001df4:	ef0080e7          	jalr	-272(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001df8:	00000797          	auipc	a5,0x0
    80001dfc:	daa78793          	addi	a5,a5,-598 # 80001ba2 <forkret>
    80001e00:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001e02:	60bc                	ld	a5,64(s1)
    80001e04:	6705                	lui	a4,0x1
    80001e06:	97ba                	add	a5,a5,a4
    80001e08:	f4bc                	sd	a5,104(s1)
}
    80001e0a:	8526                	mv	a0,s1
    80001e0c:	60e2                	ld	ra,24(sp)
    80001e0e:	6442                	ld	s0,16(sp)
    80001e10:	64a2                	ld	s1,8(sp)
    80001e12:	6902                	ld	s2,0(sp)
    80001e14:	6105                	addi	sp,sp,32
    80001e16:	8082                	ret
    freeproc(p);
    80001e18:	8526                	mv	a0,s1
    80001e1a:	00000097          	auipc	ra,0x0
    80001e1e:	f02080e7          	jalr	-254(ra) # 80001d1c <freeproc>
    release(&p->lock);
    80001e22:	8526                	mv	a0,s1
    80001e24:	fffff097          	auipc	ra,0xfffff
    80001e28:	e74080e7          	jalr	-396(ra) # 80000c98 <release>
    return 0;
    80001e2c:	84ca                	mv	s1,s2
    80001e2e:	bff1                	j	80001e0a <allocproc+0x96>
    freeproc(p);
    80001e30:	8526                	mv	a0,s1
    80001e32:	00000097          	auipc	ra,0x0
    80001e36:	eea080e7          	jalr	-278(ra) # 80001d1c <freeproc>
    release(&p->lock);
    80001e3a:	8526                	mv	a0,s1
    80001e3c:	fffff097          	auipc	ra,0xfffff
    80001e40:	e5c080e7          	jalr	-420(ra) # 80000c98 <release>
    return 0;
    80001e44:	84ca                	mv	s1,s2
    80001e46:	b7d1                	j	80001e0a <allocproc+0x96>

0000000080001e48 <userinit>:
{
    80001e48:	1101                	addi	sp,sp,-32
    80001e4a:	ec06                	sd	ra,24(sp)
    80001e4c:	e822                	sd	s0,16(sp)
    80001e4e:	e426                	sd	s1,8(sp)
    80001e50:	1000                	addi	s0,sp,32
  p = allocproc();
    80001e52:	00000097          	auipc	ra,0x0
    80001e56:	f22080e7          	jalr	-222(ra) # 80001d74 <allocproc>
    80001e5a:	84aa                	mv	s1,a0
  initproc = p;
    80001e5c:	00007797          	auipc	a5,0x7
    80001e60:	1ca7be23          	sd	a0,476(a5) # 80009038 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001e64:	03400613          	li	a2,52
    80001e68:	00007597          	auipc	a1,0x7
    80001e6c:	a8858593          	addi	a1,a1,-1400 # 800088f0 <initcode>
    80001e70:	6928                	ld	a0,80(a0)
    80001e72:	fffff097          	auipc	ra,0xfffff
    80001e76:	4f6080e7          	jalr	1270(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80001e7a:	6785                	lui	a5,0x1
    80001e7c:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001e7e:	6cb8                	ld	a4,88(s1)
    80001e80:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001e84:	6cb8                	ld	a4,88(s1)
    80001e86:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001e88:	4641                	li	a2,16
    80001e8a:	00006597          	auipc	a1,0x6
    80001e8e:	41e58593          	addi	a1,a1,1054 # 800082a8 <digits+0x268>
    80001e92:	15848513          	addi	a0,s1,344
    80001e96:	fffff097          	auipc	ra,0xfffff
    80001e9a:	f9c080e7          	jalr	-100(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001e9e:	00006517          	auipc	a0,0x6
    80001ea2:	41a50513          	addi	a0,a0,1050 # 800082b8 <digits+0x278>
    80001ea6:	00002097          	auipc	ra,0x2
    80001eaa:	15a080e7          	jalr	346(ra) # 80004000 <namei>
    80001eae:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001eb2:	478d                	li	a5,3
    80001eb4:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001eb6:	8526                	mv	a0,s1
    80001eb8:	fffff097          	auipc	ra,0xfffff
    80001ebc:	de0080e7          	jalr	-544(ra) # 80000c98 <release>
}
    80001ec0:	60e2                	ld	ra,24(sp)
    80001ec2:	6442                	ld	s0,16(sp)
    80001ec4:	64a2                	ld	s1,8(sp)
    80001ec6:	6105                	addi	sp,sp,32
    80001ec8:	8082                	ret

0000000080001eca <growproc>:
{
    80001eca:	1101                	addi	sp,sp,-32
    80001ecc:	ec06                	sd	ra,24(sp)
    80001ece:	e822                	sd	s0,16(sp)
    80001ed0:	e426                	sd	s1,8(sp)
    80001ed2:	e04a                	sd	s2,0(sp)
    80001ed4:	1000                	addi	s0,sp,32
    80001ed6:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001ed8:	00000097          	auipc	ra,0x0
    80001edc:	bb4080e7          	jalr	-1100(ra) # 80001a8c <myproc>
    80001ee0:	892a                	mv	s2,a0
  sz = p->sz;
    80001ee2:	652c                	ld	a1,72(a0)
    80001ee4:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001ee8:	00904f63          	bgtz	s1,80001f06 <growproc+0x3c>
  } else if(n < 0){
    80001eec:	0204cc63          	bltz	s1,80001f24 <growproc+0x5a>
  p->sz = sz;
    80001ef0:	1602                	slli	a2,a2,0x20
    80001ef2:	9201                	srli	a2,a2,0x20
    80001ef4:	04c93423          	sd	a2,72(s2)
  return 0;
    80001ef8:	4501                	li	a0,0
}
    80001efa:	60e2                	ld	ra,24(sp)
    80001efc:	6442                	ld	s0,16(sp)
    80001efe:	64a2                	ld	s1,8(sp)
    80001f00:	6902                	ld	s2,0(sp)
    80001f02:	6105                	addi	sp,sp,32
    80001f04:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001f06:	9e25                	addw	a2,a2,s1
    80001f08:	1602                	slli	a2,a2,0x20
    80001f0a:	9201                	srli	a2,a2,0x20
    80001f0c:	1582                	slli	a1,a1,0x20
    80001f0e:	9181                	srli	a1,a1,0x20
    80001f10:	6928                	ld	a0,80(a0)
    80001f12:	fffff097          	auipc	ra,0xfffff
    80001f16:	510080e7          	jalr	1296(ra) # 80001422 <uvmalloc>
    80001f1a:	0005061b          	sext.w	a2,a0
    80001f1e:	fa69                	bnez	a2,80001ef0 <growproc+0x26>
      return -1;
    80001f20:	557d                	li	a0,-1
    80001f22:	bfe1                	j	80001efa <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001f24:	9e25                	addw	a2,a2,s1
    80001f26:	1602                	slli	a2,a2,0x20
    80001f28:	9201                	srli	a2,a2,0x20
    80001f2a:	1582                	slli	a1,a1,0x20
    80001f2c:	9181                	srli	a1,a1,0x20
    80001f2e:	6928                	ld	a0,80(a0)
    80001f30:	fffff097          	auipc	ra,0xfffff
    80001f34:	4aa080e7          	jalr	1194(ra) # 800013da <uvmdealloc>
    80001f38:	0005061b          	sext.w	a2,a0
    80001f3c:	bf55                	j	80001ef0 <growproc+0x26>

0000000080001f3e <fork>:
{
    80001f3e:	7179                	addi	sp,sp,-48
    80001f40:	f406                	sd	ra,40(sp)
    80001f42:	f022                	sd	s0,32(sp)
    80001f44:	ec26                	sd	s1,24(sp)
    80001f46:	e84a                	sd	s2,16(sp)
    80001f48:	e44e                	sd	s3,8(sp)
    80001f4a:	e052                	sd	s4,0(sp)
    80001f4c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f4e:	00000097          	auipc	ra,0x0
    80001f52:	b3e080e7          	jalr	-1218(ra) # 80001a8c <myproc>
    80001f56:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001f58:	00000097          	auipc	ra,0x0
    80001f5c:	e1c080e7          	jalr	-484(ra) # 80001d74 <allocproc>
    80001f60:	10050b63          	beqz	a0,80002076 <fork+0x138>
    80001f64:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001f66:	04893603          	ld	a2,72(s2)
    80001f6a:	692c                	ld	a1,80(a0)
    80001f6c:	05093503          	ld	a0,80(s2)
    80001f70:	fffff097          	auipc	ra,0xfffff
    80001f74:	5fe080e7          	jalr	1534(ra) # 8000156e <uvmcopy>
    80001f78:	04054663          	bltz	a0,80001fc4 <fork+0x86>
  np->sz = p->sz;
    80001f7c:	04893783          	ld	a5,72(s2)
    80001f80:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001f84:	05893683          	ld	a3,88(s2)
    80001f88:	87b6                	mv	a5,a3
    80001f8a:	0589b703          	ld	a4,88(s3)
    80001f8e:	12068693          	addi	a3,a3,288
    80001f92:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001f96:	6788                	ld	a0,8(a5)
    80001f98:	6b8c                	ld	a1,16(a5)
    80001f9a:	6f90                	ld	a2,24(a5)
    80001f9c:	01073023          	sd	a6,0(a4)
    80001fa0:	e708                	sd	a0,8(a4)
    80001fa2:	eb0c                	sd	a1,16(a4)
    80001fa4:	ef10                	sd	a2,24(a4)
    80001fa6:	02078793          	addi	a5,a5,32
    80001faa:	02070713          	addi	a4,a4,32
    80001fae:	fed792e3          	bne	a5,a3,80001f92 <fork+0x54>
  np->trapframe->a0 = 0;
    80001fb2:	0589b783          	ld	a5,88(s3)
    80001fb6:	0607b823          	sd	zero,112(a5)
    80001fba:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001fbe:	15000a13          	li	s4,336
    80001fc2:	a03d                	j	80001ff0 <fork+0xb2>
    freeproc(np);
    80001fc4:	854e                	mv	a0,s3
    80001fc6:	00000097          	auipc	ra,0x0
    80001fca:	d56080e7          	jalr	-682(ra) # 80001d1c <freeproc>
    release(&np->lock);
    80001fce:	854e                	mv	a0,s3
    80001fd0:	fffff097          	auipc	ra,0xfffff
    80001fd4:	cc8080e7          	jalr	-824(ra) # 80000c98 <release>
    return -1;
    80001fd8:	5a7d                	li	s4,-1
    80001fda:	a069                	j	80002064 <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001fdc:	00002097          	auipc	ra,0x2
    80001fe0:	6ba080e7          	jalr	1722(ra) # 80004696 <filedup>
    80001fe4:	009987b3          	add	a5,s3,s1
    80001fe8:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001fea:	04a1                	addi	s1,s1,8
    80001fec:	01448763          	beq	s1,s4,80001ffa <fork+0xbc>
    if(p->ofile[i])
    80001ff0:	009907b3          	add	a5,s2,s1
    80001ff4:	6388                	ld	a0,0(a5)
    80001ff6:	f17d                	bnez	a0,80001fdc <fork+0x9e>
    80001ff8:	bfcd                	j	80001fea <fork+0xac>
  np->cwd = idup(p->cwd);
    80001ffa:	15093503          	ld	a0,336(s2)
    80001ffe:	00002097          	auipc	ra,0x2
    80002002:	80e080e7          	jalr	-2034(ra) # 8000380c <idup>
    80002006:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    8000200a:	4641                	li	a2,16
    8000200c:	15890593          	addi	a1,s2,344
    80002010:	15898513          	addi	a0,s3,344
    80002014:	fffff097          	auipc	ra,0xfffff
    80002018:	e1e080e7          	jalr	-482(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    8000201c:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80002020:	854e                	mv	a0,s3
    80002022:	fffff097          	auipc	ra,0xfffff
    80002026:	c76080e7          	jalr	-906(ra) # 80000c98 <release>
  acquire(&wait_lock);
    8000202a:	0000f497          	auipc	s1,0xf
    8000202e:	39e48493          	addi	s1,s1,926 # 800113c8 <wait_lock>
    80002032:	8526                	mv	a0,s1
    80002034:	fffff097          	auipc	ra,0xfffff
    80002038:	bb0080e7          	jalr	-1104(ra) # 80000be4 <acquire>
  np->parent = p;
    8000203c:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80002040:	8526                	mv	a0,s1
    80002042:	fffff097          	auipc	ra,0xfffff
    80002046:	c56080e7          	jalr	-938(ra) # 80000c98 <release>
  acquire(&np->lock);
    8000204a:	854e                	mv	a0,s3
    8000204c:	fffff097          	auipc	ra,0xfffff
    80002050:	b98080e7          	jalr	-1128(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80002054:	478d                	li	a5,3
    80002056:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    8000205a:	854e                	mv	a0,s3
    8000205c:	fffff097          	auipc	ra,0xfffff
    80002060:	c3c080e7          	jalr	-964(ra) # 80000c98 <release>
}
    80002064:	8552                	mv	a0,s4
    80002066:	70a2                	ld	ra,40(sp)
    80002068:	7402                	ld	s0,32(sp)
    8000206a:	64e2                	ld	s1,24(sp)
    8000206c:	6942                	ld	s2,16(sp)
    8000206e:	69a2                	ld	s3,8(sp)
    80002070:	6a02                	ld	s4,0(sp)
    80002072:	6145                	addi	sp,sp,48
    80002074:	8082                	ret
    return -1;
    80002076:	5a7d                	li	s4,-1
    80002078:	b7f5                	j	80002064 <fork+0x126>

000000008000207a <scheduler>:
{
    8000207a:	715d                	addi	sp,sp,-80
    8000207c:	e486                	sd	ra,72(sp)
    8000207e:	e0a2                	sd	s0,64(sp)
    80002080:	fc26                	sd	s1,56(sp)
    80002082:	f84a                	sd	s2,48(sp)
    80002084:	f44e                	sd	s3,40(sp)
    80002086:	f052                	sd	s4,32(sp)
    80002088:	ec56                	sd	s5,24(sp)
    8000208a:	e85a                	sd	s6,16(sp)
    8000208c:	e45e                	sd	s7,8(sp)
    8000208e:	0880                	addi	s0,sp,80
    80002090:	8792                	mv	a5,tp
  int id = r_tp();
    80002092:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002094:	00779b13          	slli	s6,a5,0x7
    80002098:	0000f717          	auipc	a4,0xf
    8000209c:	21870713          	addi	a4,a4,536 # 800112b0 <ticksArray>
    800020a0:	975a                	add	a4,a4,s6
    800020a2:	12073823          	sd	zero,304(a4)
			  swtch(&c->context,&current_proc->context);
    800020a6:	0000f717          	auipc	a4,0xf
    800020aa:	34270713          	addi	a4,a4,834 # 800113e8 <cpus+0x8>
    800020ae:	9b3a                	add	s6,s6,a4
		  if(p->state == RUNNABLE &&(p->pass <= minPass || minPass<0))
    800020b0:	490d                	li	s2,3
	  for(p=proc;p<&proc[NPROC];p++){
    800020b2:	00015997          	auipc	s3,0x15
    800020b6:	52e98993          	addi	s3,s3,1326 # 800175e0 <tickslock>
	  int minPass = -1;
    800020ba:	5afd                	li	s5,-1
			  c->proc=current_proc;
    800020bc:	0000fb97          	auipc	s7,0xf
    800020c0:	1f4b8b93          	addi	s7,s7,500 # 800112b0 <ticksArray>
    800020c4:	079e                	slli	a5,a5,0x7
    800020c6:	00fb8a33          	add	s4,s7,a5
    800020ca:	a069                	j	80002154 <scheduler+0xda>
			  minPass = p->pass;
    800020cc:	86ba                	mv	a3,a4
	  for(p=proc;p<&proc[NPROC];p++){
    800020ce:	17878793          	addi	a5,a5,376
    800020d2:	01378d63          	beq	a5,s3,800020ec <scheduler+0x72>
		  if(p->state == RUNNABLE &&(p->pass <= minPass || minPass<0))
    800020d6:	4f98                	lw	a4,24(a5)
    800020d8:	ff271be3          	bne	a4,s2,800020ce <scheduler+0x54>
    800020dc:	16c7a703          	lw	a4,364(a5)
    800020e0:	fee6d6e3          	bge	a3,a4,800020cc <scheduler+0x52>
    800020e4:	fe06d5e3          	bgez	a3,800020ce <scheduler+0x54>
			  minPass = p->pass;
    800020e8:	86ba                	mv	a3,a4
    800020ea:	b7d5                	j	800020ce <scheduler+0x54>
	  for(p=proc; p<&proc[NPROC];p++){
    800020ec:	0000f497          	auipc	s1,0xf
    800020f0:	6f448493          	addi	s1,s1,1780 # 800117e0 <proc>
    800020f4:	a029                	j	800020fe <scheduler+0x84>
    800020f6:	17848493          	addi	s1,s1,376
    800020fa:	05348d63          	beq	s1,s3,80002154 <scheduler+0xda>
		  if(p->state!=RUNNABLE){
    800020fe:	4c9c                	lw	a5,24(s1)
    80002100:	ff279be3          	bne	a5,s2,800020f6 <scheduler+0x7c>
		  if(p->pass == minPass){
    80002104:	16c4a783          	lw	a5,364(s1)
    80002108:	fed797e3          	bne	a5,a3,800020f6 <scheduler+0x7c>
			  acquire(&p->lock);
    8000210c:	8526                	mv	a0,s1
    8000210e:	fffff097          	auipc	ra,0xfffff
    80002112:	ad6080e7          	jalr	-1322(ra) # 80000be4 <acquire>
			  c->proc=current_proc;
    80002116:	129a3823          	sd	s1,304(s4)
			  current_proc->pass+=current_proc->stride;
    8000211a:	16c4a783          	lw	a5,364(s1)
    8000211e:	1704a703          	lw	a4,368(s1)
    80002122:	9fb9                	addw	a5,a5,a4
    80002124:	16f4a623          	sw	a5,364(s1)
			  current_proc->state=RUNNING;
    80002128:	4791                	li	a5,4
    8000212a:	cc9c                	sw	a5,24(s1)
			  ticksArray[current_proc->pid]+=1;
    8000212c:	589c                	lw	a5,48(s1)
    8000212e:	078a                	slli	a5,a5,0x2
    80002130:	97de                	add	a5,a5,s7
    80002132:	4398                	lw	a4,0(a5)
    80002134:	2705                	addiw	a4,a4,1
    80002136:	c398                	sw	a4,0(a5)
			  swtch(&c->context,&current_proc->context);
    80002138:	06048593          	addi	a1,s1,96
    8000213c:	855a                	mv	a0,s6
    8000213e:	00000097          	auipc	ra,0x0
    80002142:	63e080e7          	jalr	1598(ra) # 8000277c <swtch>
			  c->proc=0;
    80002146:	120a3823          	sd	zero,304(s4)
			  release(&p->lock);
    8000214a:	8526                	mv	a0,s1
    8000214c:	fffff097          	auipc	ra,0xfffff
    80002150:	b4c080e7          	jalr	-1204(ra) # 80000c98 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002154:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002158:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000215c:	10079073          	csrw	sstatus,a5
	  int minPass = -1;
    80002160:	86d6                	mv	a3,s5
	  for(p=proc;p<&proc[NPROC];p++){
    80002162:	0000f797          	auipc	a5,0xf
    80002166:	67e78793          	addi	a5,a5,1662 # 800117e0 <proc>
    8000216a:	b7b5                	j	800020d6 <scheduler+0x5c>

000000008000216c <sched>:
{
    8000216c:	7179                	addi	sp,sp,-48
    8000216e:	f406                	sd	ra,40(sp)
    80002170:	f022                	sd	s0,32(sp)
    80002172:	ec26                	sd	s1,24(sp)
    80002174:	e84a                	sd	s2,16(sp)
    80002176:	e44e                	sd	s3,8(sp)
    80002178:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000217a:	00000097          	auipc	ra,0x0
    8000217e:	912080e7          	jalr	-1774(ra) # 80001a8c <myproc>
    80002182:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002184:	fffff097          	auipc	ra,0xfffff
    80002188:	9e6080e7          	jalr	-1562(ra) # 80000b6a <holding>
    8000218c:	c93d                	beqz	a0,80002202 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000218e:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002190:	2781                	sext.w	a5,a5
    80002192:	079e                	slli	a5,a5,0x7
    80002194:	0000f717          	auipc	a4,0xf
    80002198:	11c70713          	addi	a4,a4,284 # 800112b0 <ticksArray>
    8000219c:	97ba                	add	a5,a5,a4
    8000219e:	1a87a703          	lw	a4,424(a5)
    800021a2:	4785                	li	a5,1
    800021a4:	06f71763          	bne	a4,a5,80002212 <sched+0xa6>
  if(p->state == RUNNING)
    800021a8:	4c98                	lw	a4,24(s1)
    800021aa:	4791                	li	a5,4
    800021ac:	06f70b63          	beq	a4,a5,80002222 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021b0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800021b4:	8b89                	andi	a5,a5,2
  if(intr_get())
    800021b6:	efb5                	bnez	a5,80002232 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800021b8:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800021ba:	0000f917          	auipc	s2,0xf
    800021be:	0f690913          	addi	s2,s2,246 # 800112b0 <ticksArray>
    800021c2:	2781                	sext.w	a5,a5
    800021c4:	079e                	slli	a5,a5,0x7
    800021c6:	97ca                	add	a5,a5,s2
    800021c8:	1ac7a983          	lw	s3,428(a5)
    800021cc:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800021ce:	2781                	sext.w	a5,a5
    800021d0:	079e                	slli	a5,a5,0x7
    800021d2:	0000f597          	auipc	a1,0xf
    800021d6:	21658593          	addi	a1,a1,534 # 800113e8 <cpus+0x8>
    800021da:	95be                	add	a1,a1,a5
    800021dc:	06048513          	addi	a0,s1,96
    800021e0:	00000097          	auipc	ra,0x0
    800021e4:	59c080e7          	jalr	1436(ra) # 8000277c <swtch>
    800021e8:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800021ea:	2781                	sext.w	a5,a5
    800021ec:	079e                	slli	a5,a5,0x7
    800021ee:	97ca                	add	a5,a5,s2
    800021f0:	1b37a623          	sw	s3,428(a5)
}
    800021f4:	70a2                	ld	ra,40(sp)
    800021f6:	7402                	ld	s0,32(sp)
    800021f8:	64e2                	ld	s1,24(sp)
    800021fa:	6942                	ld	s2,16(sp)
    800021fc:	69a2                	ld	s3,8(sp)
    800021fe:	6145                	addi	sp,sp,48
    80002200:	8082                	ret
    panic("sched p->lock");
    80002202:	00006517          	auipc	a0,0x6
    80002206:	0be50513          	addi	a0,a0,190 # 800082c0 <digits+0x280>
    8000220a:	ffffe097          	auipc	ra,0xffffe
    8000220e:	334080e7          	jalr	820(ra) # 8000053e <panic>
    panic("sched locks");
    80002212:	00006517          	auipc	a0,0x6
    80002216:	0be50513          	addi	a0,a0,190 # 800082d0 <digits+0x290>
    8000221a:	ffffe097          	auipc	ra,0xffffe
    8000221e:	324080e7          	jalr	804(ra) # 8000053e <panic>
    panic("sched running");
    80002222:	00006517          	auipc	a0,0x6
    80002226:	0be50513          	addi	a0,a0,190 # 800082e0 <digits+0x2a0>
    8000222a:	ffffe097          	auipc	ra,0xffffe
    8000222e:	314080e7          	jalr	788(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002232:	00006517          	auipc	a0,0x6
    80002236:	0be50513          	addi	a0,a0,190 # 800082f0 <digits+0x2b0>
    8000223a:	ffffe097          	auipc	ra,0xffffe
    8000223e:	304080e7          	jalr	772(ra) # 8000053e <panic>

0000000080002242 <yield>:
{
    80002242:	1101                	addi	sp,sp,-32
    80002244:	ec06                	sd	ra,24(sp)
    80002246:	e822                	sd	s0,16(sp)
    80002248:	e426                	sd	s1,8(sp)
    8000224a:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000224c:	00000097          	auipc	ra,0x0
    80002250:	840080e7          	jalr	-1984(ra) # 80001a8c <myproc>
    80002254:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002256:	fffff097          	auipc	ra,0xfffff
    8000225a:	98e080e7          	jalr	-1650(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    8000225e:	478d                	li	a5,3
    80002260:	cc9c                	sw	a5,24(s1)
  sched();
    80002262:	00000097          	auipc	ra,0x0
    80002266:	f0a080e7          	jalr	-246(ra) # 8000216c <sched>
  release(&p->lock);
    8000226a:	8526                	mv	a0,s1
    8000226c:	fffff097          	auipc	ra,0xfffff
    80002270:	a2c080e7          	jalr	-1492(ra) # 80000c98 <release>
}
    80002274:	60e2                	ld	ra,24(sp)
    80002276:	6442                	ld	s0,16(sp)
    80002278:	64a2                	ld	s1,8(sp)
    8000227a:	6105                	addi	sp,sp,32
    8000227c:	8082                	ret

000000008000227e <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000227e:	7179                	addi	sp,sp,-48
    80002280:	f406                	sd	ra,40(sp)
    80002282:	f022                	sd	s0,32(sp)
    80002284:	ec26                	sd	s1,24(sp)
    80002286:	e84a                	sd	s2,16(sp)
    80002288:	e44e                	sd	s3,8(sp)
    8000228a:	1800                	addi	s0,sp,48
    8000228c:	89aa                	mv	s3,a0
    8000228e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002290:	fffff097          	auipc	ra,0xfffff
    80002294:	7fc080e7          	jalr	2044(ra) # 80001a8c <myproc>
    80002298:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000229a:	fffff097          	auipc	ra,0xfffff
    8000229e:	94a080e7          	jalr	-1718(ra) # 80000be4 <acquire>
  release(lk);
    800022a2:	854a                	mv	a0,s2
    800022a4:	fffff097          	auipc	ra,0xfffff
    800022a8:	9f4080e7          	jalr	-1548(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    800022ac:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800022b0:	4789                	li	a5,2
    800022b2:	cc9c                	sw	a5,24(s1)

  sched();
    800022b4:	00000097          	auipc	ra,0x0
    800022b8:	eb8080e7          	jalr	-328(ra) # 8000216c <sched>

  // Tidy up.
  p->chan = 0;
    800022bc:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800022c0:	8526                	mv	a0,s1
    800022c2:	fffff097          	auipc	ra,0xfffff
    800022c6:	9d6080e7          	jalr	-1578(ra) # 80000c98 <release>
  acquire(lk);
    800022ca:	854a                	mv	a0,s2
    800022cc:	fffff097          	auipc	ra,0xfffff
    800022d0:	918080e7          	jalr	-1768(ra) # 80000be4 <acquire>
}
    800022d4:	70a2                	ld	ra,40(sp)
    800022d6:	7402                	ld	s0,32(sp)
    800022d8:	64e2                	ld	s1,24(sp)
    800022da:	6942                	ld	s2,16(sp)
    800022dc:	69a2                	ld	s3,8(sp)
    800022de:	6145                	addi	sp,sp,48
    800022e0:	8082                	ret

00000000800022e2 <wait>:
{
    800022e2:	715d                	addi	sp,sp,-80
    800022e4:	e486                	sd	ra,72(sp)
    800022e6:	e0a2                	sd	s0,64(sp)
    800022e8:	fc26                	sd	s1,56(sp)
    800022ea:	f84a                	sd	s2,48(sp)
    800022ec:	f44e                	sd	s3,40(sp)
    800022ee:	f052                	sd	s4,32(sp)
    800022f0:	ec56                	sd	s5,24(sp)
    800022f2:	e85a                	sd	s6,16(sp)
    800022f4:	e45e                	sd	s7,8(sp)
    800022f6:	e062                	sd	s8,0(sp)
    800022f8:	0880                	addi	s0,sp,80
    800022fa:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800022fc:	fffff097          	auipc	ra,0xfffff
    80002300:	790080e7          	jalr	1936(ra) # 80001a8c <myproc>
    80002304:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002306:	0000f517          	auipc	a0,0xf
    8000230a:	0c250513          	addi	a0,a0,194 # 800113c8 <wait_lock>
    8000230e:	fffff097          	auipc	ra,0xfffff
    80002312:	8d6080e7          	jalr	-1834(ra) # 80000be4 <acquire>
    havekids = 0;
    80002316:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002318:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    8000231a:	00015997          	auipc	s3,0x15
    8000231e:	2c698993          	addi	s3,s3,710 # 800175e0 <tickslock>
        havekids = 1;
    80002322:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002324:	0000fc17          	auipc	s8,0xf
    80002328:	0a4c0c13          	addi	s8,s8,164 # 800113c8 <wait_lock>
    havekids = 0;
    8000232c:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000232e:	0000f497          	auipc	s1,0xf
    80002332:	4b248493          	addi	s1,s1,1202 # 800117e0 <proc>
    80002336:	a0bd                	j	800023a4 <wait+0xc2>
          pid = np->pid;
    80002338:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000233c:	000b0e63          	beqz	s6,80002358 <wait+0x76>
    80002340:	4691                	li	a3,4
    80002342:	02c48613          	addi	a2,s1,44
    80002346:	85da                	mv	a1,s6
    80002348:	05093503          	ld	a0,80(s2)
    8000234c:	fffff097          	auipc	ra,0xfffff
    80002350:	326080e7          	jalr	806(ra) # 80001672 <copyout>
    80002354:	02054563          	bltz	a0,8000237e <wait+0x9c>
          freeproc(np);
    80002358:	8526                	mv	a0,s1
    8000235a:	00000097          	auipc	ra,0x0
    8000235e:	9c2080e7          	jalr	-1598(ra) # 80001d1c <freeproc>
          release(&np->lock);
    80002362:	8526                	mv	a0,s1
    80002364:	fffff097          	auipc	ra,0xfffff
    80002368:	934080e7          	jalr	-1740(ra) # 80000c98 <release>
          release(&wait_lock);
    8000236c:	0000f517          	auipc	a0,0xf
    80002370:	05c50513          	addi	a0,a0,92 # 800113c8 <wait_lock>
    80002374:	fffff097          	auipc	ra,0xfffff
    80002378:	924080e7          	jalr	-1756(ra) # 80000c98 <release>
          return pid;
    8000237c:	a09d                	j	800023e2 <wait+0x100>
            release(&np->lock);
    8000237e:	8526                	mv	a0,s1
    80002380:	fffff097          	auipc	ra,0xfffff
    80002384:	918080e7          	jalr	-1768(ra) # 80000c98 <release>
            release(&wait_lock);
    80002388:	0000f517          	auipc	a0,0xf
    8000238c:	04050513          	addi	a0,a0,64 # 800113c8 <wait_lock>
    80002390:	fffff097          	auipc	ra,0xfffff
    80002394:	908080e7          	jalr	-1784(ra) # 80000c98 <release>
            return -1;
    80002398:	59fd                	li	s3,-1
    8000239a:	a0a1                	j	800023e2 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    8000239c:	17848493          	addi	s1,s1,376
    800023a0:	03348463          	beq	s1,s3,800023c8 <wait+0xe6>
      if(np->parent == p){
    800023a4:	7c9c                	ld	a5,56(s1)
    800023a6:	ff279be3          	bne	a5,s2,8000239c <wait+0xba>
        acquire(&np->lock);
    800023aa:	8526                	mv	a0,s1
    800023ac:	fffff097          	auipc	ra,0xfffff
    800023b0:	838080e7          	jalr	-1992(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    800023b4:	4c9c                	lw	a5,24(s1)
    800023b6:	f94781e3          	beq	a5,s4,80002338 <wait+0x56>
        release(&np->lock);
    800023ba:	8526                	mv	a0,s1
    800023bc:	fffff097          	auipc	ra,0xfffff
    800023c0:	8dc080e7          	jalr	-1828(ra) # 80000c98 <release>
        havekids = 1;
    800023c4:	8756                	mv	a4,s5
    800023c6:	bfd9                	j	8000239c <wait+0xba>
    if(!havekids || p->killed){
    800023c8:	c701                	beqz	a4,800023d0 <wait+0xee>
    800023ca:	02892783          	lw	a5,40(s2)
    800023ce:	c79d                	beqz	a5,800023fc <wait+0x11a>
      release(&wait_lock);
    800023d0:	0000f517          	auipc	a0,0xf
    800023d4:	ff850513          	addi	a0,a0,-8 # 800113c8 <wait_lock>
    800023d8:	fffff097          	auipc	ra,0xfffff
    800023dc:	8c0080e7          	jalr	-1856(ra) # 80000c98 <release>
      return -1;
    800023e0:	59fd                	li	s3,-1
}
    800023e2:	854e                	mv	a0,s3
    800023e4:	60a6                	ld	ra,72(sp)
    800023e6:	6406                	ld	s0,64(sp)
    800023e8:	74e2                	ld	s1,56(sp)
    800023ea:	7942                	ld	s2,48(sp)
    800023ec:	79a2                	ld	s3,40(sp)
    800023ee:	7a02                	ld	s4,32(sp)
    800023f0:	6ae2                	ld	s5,24(sp)
    800023f2:	6b42                	ld	s6,16(sp)
    800023f4:	6ba2                	ld	s7,8(sp)
    800023f6:	6c02                	ld	s8,0(sp)
    800023f8:	6161                	addi	sp,sp,80
    800023fa:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800023fc:	85e2                	mv	a1,s8
    800023fe:	854a                	mv	a0,s2
    80002400:	00000097          	auipc	ra,0x0
    80002404:	e7e080e7          	jalr	-386(ra) # 8000227e <sleep>
    havekids = 0;
    80002408:	b715                	j	8000232c <wait+0x4a>

000000008000240a <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000240a:	7139                	addi	sp,sp,-64
    8000240c:	fc06                	sd	ra,56(sp)
    8000240e:	f822                	sd	s0,48(sp)
    80002410:	f426                	sd	s1,40(sp)
    80002412:	f04a                	sd	s2,32(sp)
    80002414:	ec4e                	sd	s3,24(sp)
    80002416:	e852                	sd	s4,16(sp)
    80002418:	e456                	sd	s5,8(sp)
    8000241a:	0080                	addi	s0,sp,64
    8000241c:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000241e:	0000f497          	auipc	s1,0xf
    80002422:	3c248493          	addi	s1,s1,962 # 800117e0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002426:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002428:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000242a:	00015917          	auipc	s2,0x15
    8000242e:	1b690913          	addi	s2,s2,438 # 800175e0 <tickslock>
    80002432:	a821                	j	8000244a <wakeup+0x40>
        p->state = RUNNABLE;
    80002434:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    80002438:	8526                	mv	a0,s1
    8000243a:	fffff097          	auipc	ra,0xfffff
    8000243e:	85e080e7          	jalr	-1954(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002442:	17848493          	addi	s1,s1,376
    80002446:	03248463          	beq	s1,s2,8000246e <wakeup+0x64>
    if(p != myproc()){
    8000244a:	fffff097          	auipc	ra,0xfffff
    8000244e:	642080e7          	jalr	1602(ra) # 80001a8c <myproc>
    80002452:	fea488e3          	beq	s1,a0,80002442 <wakeup+0x38>
      acquire(&p->lock);
    80002456:	8526                	mv	a0,s1
    80002458:	ffffe097          	auipc	ra,0xffffe
    8000245c:	78c080e7          	jalr	1932(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002460:	4c9c                	lw	a5,24(s1)
    80002462:	fd379be3          	bne	a5,s3,80002438 <wakeup+0x2e>
    80002466:	709c                	ld	a5,32(s1)
    80002468:	fd4798e3          	bne	a5,s4,80002438 <wakeup+0x2e>
    8000246c:	b7e1                	j	80002434 <wakeup+0x2a>
    }
  }
}
    8000246e:	70e2                	ld	ra,56(sp)
    80002470:	7442                	ld	s0,48(sp)
    80002472:	74a2                	ld	s1,40(sp)
    80002474:	7902                	ld	s2,32(sp)
    80002476:	69e2                	ld	s3,24(sp)
    80002478:	6a42                	ld	s4,16(sp)
    8000247a:	6aa2                	ld	s5,8(sp)
    8000247c:	6121                	addi	sp,sp,64
    8000247e:	8082                	ret

0000000080002480 <reparent>:
{
    80002480:	7179                	addi	sp,sp,-48
    80002482:	f406                	sd	ra,40(sp)
    80002484:	f022                	sd	s0,32(sp)
    80002486:	ec26                	sd	s1,24(sp)
    80002488:	e84a                	sd	s2,16(sp)
    8000248a:	e44e                	sd	s3,8(sp)
    8000248c:	e052                	sd	s4,0(sp)
    8000248e:	1800                	addi	s0,sp,48
    80002490:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002492:	0000f497          	auipc	s1,0xf
    80002496:	34e48493          	addi	s1,s1,846 # 800117e0 <proc>
      pp->parent = initproc;
    8000249a:	00007a17          	auipc	s4,0x7
    8000249e:	b9ea0a13          	addi	s4,s4,-1122 # 80009038 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800024a2:	00015997          	auipc	s3,0x15
    800024a6:	13e98993          	addi	s3,s3,318 # 800175e0 <tickslock>
    800024aa:	a029                	j	800024b4 <reparent+0x34>
    800024ac:	17848493          	addi	s1,s1,376
    800024b0:	01348d63          	beq	s1,s3,800024ca <reparent+0x4a>
    if(pp->parent == p){
    800024b4:	7c9c                	ld	a5,56(s1)
    800024b6:	ff279be3          	bne	a5,s2,800024ac <reparent+0x2c>
      pp->parent = initproc;
    800024ba:	000a3503          	ld	a0,0(s4)
    800024be:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800024c0:	00000097          	auipc	ra,0x0
    800024c4:	f4a080e7          	jalr	-182(ra) # 8000240a <wakeup>
    800024c8:	b7d5                	j	800024ac <reparent+0x2c>
}
    800024ca:	70a2                	ld	ra,40(sp)
    800024cc:	7402                	ld	s0,32(sp)
    800024ce:	64e2                	ld	s1,24(sp)
    800024d0:	6942                	ld	s2,16(sp)
    800024d2:	69a2                	ld	s3,8(sp)
    800024d4:	6a02                	ld	s4,0(sp)
    800024d6:	6145                	addi	sp,sp,48
    800024d8:	8082                	ret

00000000800024da <exit>:
{
    800024da:	7179                	addi	sp,sp,-48
    800024dc:	f406                	sd	ra,40(sp)
    800024de:	f022                	sd	s0,32(sp)
    800024e0:	ec26                	sd	s1,24(sp)
    800024e2:	e84a                	sd	s2,16(sp)
    800024e4:	e44e                	sd	s3,8(sp)
    800024e6:	e052                	sd	s4,0(sp)
    800024e8:	1800                	addi	s0,sp,48
    800024ea:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800024ec:	fffff097          	auipc	ra,0xfffff
    800024f0:	5a0080e7          	jalr	1440(ra) # 80001a8c <myproc>
    800024f4:	89aa                	mv	s3,a0
  if(p == initproc)
    800024f6:	00007797          	auipc	a5,0x7
    800024fa:	b427b783          	ld	a5,-1214(a5) # 80009038 <initproc>
    800024fe:	0d050493          	addi	s1,a0,208
    80002502:	15050913          	addi	s2,a0,336
    80002506:	02a79363          	bne	a5,a0,8000252c <exit+0x52>
    panic("init exiting");
    8000250a:	00006517          	auipc	a0,0x6
    8000250e:	dfe50513          	addi	a0,a0,-514 # 80008308 <digits+0x2c8>
    80002512:	ffffe097          	auipc	ra,0xffffe
    80002516:	02c080e7          	jalr	44(ra) # 8000053e <panic>
      fileclose(f);
    8000251a:	00002097          	auipc	ra,0x2
    8000251e:	1ce080e7          	jalr	462(ra) # 800046e8 <fileclose>
      p->ofile[fd] = 0;
    80002522:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002526:	04a1                	addi	s1,s1,8
    80002528:	01248563          	beq	s1,s2,80002532 <exit+0x58>
    if(p->ofile[fd]){
    8000252c:	6088                	ld	a0,0(s1)
    8000252e:	f575                	bnez	a0,8000251a <exit+0x40>
    80002530:	bfdd                	j	80002526 <exit+0x4c>
  begin_op();
    80002532:	00002097          	auipc	ra,0x2
    80002536:	cea080e7          	jalr	-790(ra) # 8000421c <begin_op>
  iput(p->cwd);
    8000253a:	1509b503          	ld	a0,336(s3)
    8000253e:	00001097          	auipc	ra,0x1
    80002542:	4c6080e7          	jalr	1222(ra) # 80003a04 <iput>
  end_op();
    80002546:	00002097          	auipc	ra,0x2
    8000254a:	d56080e7          	jalr	-682(ra) # 8000429c <end_op>
  p->cwd = 0;
    8000254e:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002552:	0000f497          	auipc	s1,0xf
    80002556:	e7648493          	addi	s1,s1,-394 # 800113c8 <wait_lock>
    8000255a:	8526                	mv	a0,s1
    8000255c:	ffffe097          	auipc	ra,0xffffe
    80002560:	688080e7          	jalr	1672(ra) # 80000be4 <acquire>
  reparent(p);
    80002564:	854e                	mv	a0,s3
    80002566:	00000097          	auipc	ra,0x0
    8000256a:	f1a080e7          	jalr	-230(ra) # 80002480 <reparent>
  wakeup(p->parent);
    8000256e:	0389b503          	ld	a0,56(s3)
    80002572:	00000097          	auipc	ra,0x0
    80002576:	e98080e7          	jalr	-360(ra) # 8000240a <wakeup>
  acquire(&p->lock);
    8000257a:	854e                	mv	a0,s3
    8000257c:	ffffe097          	auipc	ra,0xffffe
    80002580:	668080e7          	jalr	1640(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002584:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002588:	4795                	li	a5,5
    8000258a:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000258e:	8526                	mv	a0,s1
    80002590:	ffffe097          	auipc	ra,0xffffe
    80002594:	708080e7          	jalr	1800(ra) # 80000c98 <release>
  sched();
    80002598:	00000097          	auipc	ra,0x0
    8000259c:	bd4080e7          	jalr	-1068(ra) # 8000216c <sched>
  panic("zombie exit");
    800025a0:	00006517          	auipc	a0,0x6
    800025a4:	d7850513          	addi	a0,a0,-648 # 80008318 <digits+0x2d8>
    800025a8:	ffffe097          	auipc	ra,0xffffe
    800025ac:	f96080e7          	jalr	-106(ra) # 8000053e <panic>

00000000800025b0 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800025b0:	7179                	addi	sp,sp,-48
    800025b2:	f406                	sd	ra,40(sp)
    800025b4:	f022                	sd	s0,32(sp)
    800025b6:	ec26                	sd	s1,24(sp)
    800025b8:	e84a                	sd	s2,16(sp)
    800025ba:	e44e                	sd	s3,8(sp)
    800025bc:	1800                	addi	s0,sp,48
    800025be:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800025c0:	0000f497          	auipc	s1,0xf
    800025c4:	22048493          	addi	s1,s1,544 # 800117e0 <proc>
    800025c8:	00015997          	auipc	s3,0x15
    800025cc:	01898993          	addi	s3,s3,24 # 800175e0 <tickslock>
    acquire(&p->lock);
    800025d0:	8526                	mv	a0,s1
    800025d2:	ffffe097          	auipc	ra,0xffffe
    800025d6:	612080e7          	jalr	1554(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    800025da:	589c                	lw	a5,48(s1)
    800025dc:	01278d63          	beq	a5,s2,800025f6 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800025e0:	8526                	mv	a0,s1
    800025e2:	ffffe097          	auipc	ra,0xffffe
    800025e6:	6b6080e7          	jalr	1718(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800025ea:	17848493          	addi	s1,s1,376
    800025ee:	ff3491e3          	bne	s1,s3,800025d0 <kill+0x20>
  }
  return -1;
    800025f2:	557d                	li	a0,-1
    800025f4:	a829                	j	8000260e <kill+0x5e>
      p->killed = 1;
    800025f6:	4785                	li	a5,1
    800025f8:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800025fa:	4c98                	lw	a4,24(s1)
    800025fc:	4789                	li	a5,2
    800025fe:	00f70f63          	beq	a4,a5,8000261c <kill+0x6c>
      release(&p->lock);
    80002602:	8526                	mv	a0,s1
    80002604:	ffffe097          	auipc	ra,0xffffe
    80002608:	694080e7          	jalr	1684(ra) # 80000c98 <release>
      return 0;
    8000260c:	4501                	li	a0,0
}
    8000260e:	70a2                	ld	ra,40(sp)
    80002610:	7402                	ld	s0,32(sp)
    80002612:	64e2                	ld	s1,24(sp)
    80002614:	6942                	ld	s2,16(sp)
    80002616:	69a2                	ld	s3,8(sp)
    80002618:	6145                	addi	sp,sp,48
    8000261a:	8082                	ret
        p->state = RUNNABLE;
    8000261c:	478d                	li	a5,3
    8000261e:	cc9c                	sw	a5,24(s1)
    80002620:	b7cd                	j	80002602 <kill+0x52>

0000000080002622 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002622:	7179                	addi	sp,sp,-48
    80002624:	f406                	sd	ra,40(sp)
    80002626:	f022                	sd	s0,32(sp)
    80002628:	ec26                	sd	s1,24(sp)
    8000262a:	e84a                	sd	s2,16(sp)
    8000262c:	e44e                	sd	s3,8(sp)
    8000262e:	e052                	sd	s4,0(sp)
    80002630:	1800                	addi	s0,sp,48
    80002632:	84aa                	mv	s1,a0
    80002634:	892e                	mv	s2,a1
    80002636:	89b2                	mv	s3,a2
    80002638:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000263a:	fffff097          	auipc	ra,0xfffff
    8000263e:	452080e7          	jalr	1106(ra) # 80001a8c <myproc>
  if(user_dst){
    80002642:	c08d                	beqz	s1,80002664 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002644:	86d2                	mv	a3,s4
    80002646:	864e                	mv	a2,s3
    80002648:	85ca                	mv	a1,s2
    8000264a:	6928                	ld	a0,80(a0)
    8000264c:	fffff097          	auipc	ra,0xfffff
    80002650:	026080e7          	jalr	38(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002654:	70a2                	ld	ra,40(sp)
    80002656:	7402                	ld	s0,32(sp)
    80002658:	64e2                	ld	s1,24(sp)
    8000265a:	6942                	ld	s2,16(sp)
    8000265c:	69a2                	ld	s3,8(sp)
    8000265e:	6a02                	ld	s4,0(sp)
    80002660:	6145                	addi	sp,sp,48
    80002662:	8082                	ret
    memmove((char *)dst, src, len);
    80002664:	000a061b          	sext.w	a2,s4
    80002668:	85ce                	mv	a1,s3
    8000266a:	854a                	mv	a0,s2
    8000266c:	ffffe097          	auipc	ra,0xffffe
    80002670:	6d4080e7          	jalr	1748(ra) # 80000d40 <memmove>
    return 0;
    80002674:	8526                	mv	a0,s1
    80002676:	bff9                	j	80002654 <either_copyout+0x32>

0000000080002678 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002678:	7179                	addi	sp,sp,-48
    8000267a:	f406                	sd	ra,40(sp)
    8000267c:	f022                	sd	s0,32(sp)
    8000267e:	ec26                	sd	s1,24(sp)
    80002680:	e84a                	sd	s2,16(sp)
    80002682:	e44e                	sd	s3,8(sp)
    80002684:	e052                	sd	s4,0(sp)
    80002686:	1800                	addi	s0,sp,48
    80002688:	892a                	mv	s2,a0
    8000268a:	84ae                	mv	s1,a1
    8000268c:	89b2                	mv	s3,a2
    8000268e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002690:	fffff097          	auipc	ra,0xfffff
    80002694:	3fc080e7          	jalr	1020(ra) # 80001a8c <myproc>
  if(user_src){
    80002698:	c08d                	beqz	s1,800026ba <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000269a:	86d2                	mv	a3,s4
    8000269c:	864e                	mv	a2,s3
    8000269e:	85ca                	mv	a1,s2
    800026a0:	6928                	ld	a0,80(a0)
    800026a2:	fffff097          	auipc	ra,0xfffff
    800026a6:	05c080e7          	jalr	92(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800026aa:	70a2                	ld	ra,40(sp)
    800026ac:	7402                	ld	s0,32(sp)
    800026ae:	64e2                	ld	s1,24(sp)
    800026b0:	6942                	ld	s2,16(sp)
    800026b2:	69a2                	ld	s3,8(sp)
    800026b4:	6a02                	ld	s4,0(sp)
    800026b6:	6145                	addi	sp,sp,48
    800026b8:	8082                	ret
    memmove(dst, (char*)src, len);
    800026ba:	000a061b          	sext.w	a2,s4
    800026be:	85ce                	mv	a1,s3
    800026c0:	854a                	mv	a0,s2
    800026c2:	ffffe097          	auipc	ra,0xffffe
    800026c6:	67e080e7          	jalr	1662(ra) # 80000d40 <memmove>
    return 0;
    800026ca:	8526                	mv	a0,s1
    800026cc:	bff9                	j	800026aa <either_copyin+0x32>

00000000800026ce <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800026ce:	715d                	addi	sp,sp,-80
    800026d0:	e486                	sd	ra,72(sp)
    800026d2:	e0a2                	sd	s0,64(sp)
    800026d4:	fc26                	sd	s1,56(sp)
    800026d6:	f84a                	sd	s2,48(sp)
    800026d8:	f44e                	sd	s3,40(sp)
    800026da:	f052                	sd	s4,32(sp)
    800026dc:	ec56                	sd	s5,24(sp)
    800026de:	e85a                	sd	s6,16(sp)
    800026e0:	e45e                	sd	s7,8(sp)
    800026e2:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800026e4:	00006517          	auipc	a0,0x6
    800026e8:	b4c50513          	addi	a0,a0,-1204 # 80008230 <digits+0x1f0>
    800026ec:	ffffe097          	auipc	ra,0xffffe
    800026f0:	e9c080e7          	jalr	-356(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800026f4:	0000f497          	auipc	s1,0xf
    800026f8:	24448493          	addi	s1,s1,580 # 80011938 <proc+0x158>
    800026fc:	00015917          	auipc	s2,0x15
    80002700:	03c90913          	addi	s2,s2,60 # 80017738 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002704:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002706:	00006997          	auipc	s3,0x6
    8000270a:	c2298993          	addi	s3,s3,-990 # 80008328 <digits+0x2e8>
    printf("%d %s %s", p->pid, state, p->name);
    8000270e:	00006a97          	auipc	s5,0x6
    80002712:	c22a8a93          	addi	s5,s5,-990 # 80008330 <digits+0x2f0>
    printf("\n");
    80002716:	00006a17          	auipc	s4,0x6
    8000271a:	b1aa0a13          	addi	s4,s4,-1254 # 80008230 <digits+0x1f0>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000271e:	00006b97          	auipc	s7,0x6
    80002722:	c4ab8b93          	addi	s7,s7,-950 # 80008368 <states.1742>
    80002726:	a00d                	j	80002748 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002728:	ed86a583          	lw	a1,-296(a3)
    8000272c:	8556                	mv	a0,s5
    8000272e:	ffffe097          	auipc	ra,0xffffe
    80002732:	e5a080e7          	jalr	-422(ra) # 80000588 <printf>
    printf("\n");
    80002736:	8552                	mv	a0,s4
    80002738:	ffffe097          	auipc	ra,0xffffe
    8000273c:	e50080e7          	jalr	-432(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002740:	17848493          	addi	s1,s1,376
    80002744:	03248163          	beq	s1,s2,80002766 <procdump+0x98>
    if(p->state == UNUSED)
    80002748:	86a6                	mv	a3,s1
    8000274a:	ec04a783          	lw	a5,-320(s1)
    8000274e:	dbed                	beqz	a5,80002740 <procdump+0x72>
      state = "???";
    80002750:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002752:	fcfb6be3          	bltu	s6,a5,80002728 <procdump+0x5a>
    80002756:	1782                	slli	a5,a5,0x20
    80002758:	9381                	srli	a5,a5,0x20
    8000275a:	078e                	slli	a5,a5,0x3
    8000275c:	97de                	add	a5,a5,s7
    8000275e:	6390                	ld	a2,0(a5)
    80002760:	f661                	bnez	a2,80002728 <procdump+0x5a>
      state = "???";
    80002762:	864e                	mv	a2,s3
    80002764:	b7d1                	j	80002728 <procdump+0x5a>
  }
}
    80002766:	60a6                	ld	ra,72(sp)
    80002768:	6406                	ld	s0,64(sp)
    8000276a:	74e2                	ld	s1,56(sp)
    8000276c:	7942                	ld	s2,48(sp)
    8000276e:	79a2                	ld	s3,40(sp)
    80002770:	7a02                	ld	s4,32(sp)
    80002772:	6ae2                	ld	s5,24(sp)
    80002774:	6b42                	ld	s6,16(sp)
    80002776:	6ba2                	ld	s7,8(sp)
    80002778:	6161                	addi	sp,sp,80
    8000277a:	8082                	ret

000000008000277c <swtch>:
    8000277c:	00153023          	sd	ra,0(a0)
    80002780:	00253423          	sd	sp,8(a0)
    80002784:	e900                	sd	s0,16(a0)
    80002786:	ed04                	sd	s1,24(a0)
    80002788:	03253023          	sd	s2,32(a0)
    8000278c:	03353423          	sd	s3,40(a0)
    80002790:	03453823          	sd	s4,48(a0)
    80002794:	03553c23          	sd	s5,56(a0)
    80002798:	05653023          	sd	s6,64(a0)
    8000279c:	05753423          	sd	s7,72(a0)
    800027a0:	05853823          	sd	s8,80(a0)
    800027a4:	05953c23          	sd	s9,88(a0)
    800027a8:	07a53023          	sd	s10,96(a0)
    800027ac:	07b53423          	sd	s11,104(a0)
    800027b0:	0005b083          	ld	ra,0(a1)
    800027b4:	0085b103          	ld	sp,8(a1)
    800027b8:	6980                	ld	s0,16(a1)
    800027ba:	6d84                	ld	s1,24(a1)
    800027bc:	0205b903          	ld	s2,32(a1)
    800027c0:	0285b983          	ld	s3,40(a1)
    800027c4:	0305ba03          	ld	s4,48(a1)
    800027c8:	0385ba83          	ld	s5,56(a1)
    800027cc:	0405bb03          	ld	s6,64(a1)
    800027d0:	0485bb83          	ld	s7,72(a1)
    800027d4:	0505bc03          	ld	s8,80(a1)
    800027d8:	0585bc83          	ld	s9,88(a1)
    800027dc:	0605bd03          	ld	s10,96(a1)
    800027e0:	0685bd83          	ld	s11,104(a1)
    800027e4:	8082                	ret

00000000800027e6 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800027e6:	1141                	addi	sp,sp,-16
    800027e8:	e406                	sd	ra,8(sp)
    800027ea:	e022                	sd	s0,0(sp)
    800027ec:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800027ee:	00006597          	auipc	a1,0x6
    800027f2:	baa58593          	addi	a1,a1,-1110 # 80008398 <states.1742+0x30>
    800027f6:	00015517          	auipc	a0,0x15
    800027fa:	dea50513          	addi	a0,a0,-534 # 800175e0 <tickslock>
    800027fe:	ffffe097          	auipc	ra,0xffffe
    80002802:	356080e7          	jalr	854(ra) # 80000b54 <initlock>
}
    80002806:	60a2                	ld	ra,8(sp)
    80002808:	6402                	ld	s0,0(sp)
    8000280a:	0141                	addi	sp,sp,16
    8000280c:	8082                	ret

000000008000280e <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000280e:	1141                	addi	sp,sp,-16
    80002810:	e422                	sd	s0,8(sp)
    80002812:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002814:	00003797          	auipc	a5,0x3
    80002818:	4ec78793          	addi	a5,a5,1260 # 80005d00 <kernelvec>
    8000281c:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002820:	6422                	ld	s0,8(sp)
    80002822:	0141                	addi	sp,sp,16
    80002824:	8082                	ret

0000000080002826 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002826:	1141                	addi	sp,sp,-16
    80002828:	e406                	sd	ra,8(sp)
    8000282a:	e022                	sd	s0,0(sp)
    8000282c:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000282e:	fffff097          	auipc	ra,0xfffff
    80002832:	25e080e7          	jalr	606(ra) # 80001a8c <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002836:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000283a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000283c:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002840:	00004617          	auipc	a2,0x4
    80002844:	7c060613          	addi	a2,a2,1984 # 80007000 <_trampoline>
    80002848:	00004697          	auipc	a3,0x4
    8000284c:	7b868693          	addi	a3,a3,1976 # 80007000 <_trampoline>
    80002850:	8e91                	sub	a3,a3,a2
    80002852:	040007b7          	lui	a5,0x4000
    80002856:	17fd                	addi	a5,a5,-1
    80002858:	07b2                	slli	a5,a5,0xc
    8000285a:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000285c:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002860:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002862:	180026f3          	csrr	a3,satp
    80002866:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002868:	6d38                	ld	a4,88(a0)
    8000286a:	6134                	ld	a3,64(a0)
    8000286c:	6585                	lui	a1,0x1
    8000286e:	96ae                	add	a3,a3,a1
    80002870:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002872:	6d38                	ld	a4,88(a0)
    80002874:	00000697          	auipc	a3,0x0
    80002878:	13868693          	addi	a3,a3,312 # 800029ac <usertrap>
    8000287c:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000287e:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002880:	8692                	mv	a3,tp
    80002882:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002884:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002888:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000288c:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002890:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002894:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002896:	6f18                	ld	a4,24(a4)
    80002898:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000289c:	692c                	ld	a1,80(a0)
    8000289e:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800028a0:	00004717          	auipc	a4,0x4
    800028a4:	7f070713          	addi	a4,a4,2032 # 80007090 <userret>
    800028a8:	8f11                	sub	a4,a4,a2
    800028aa:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800028ac:	577d                	li	a4,-1
    800028ae:	177e                	slli	a4,a4,0x3f
    800028b0:	8dd9                	or	a1,a1,a4
    800028b2:	02000537          	lui	a0,0x2000
    800028b6:	157d                	addi	a0,a0,-1
    800028b8:	0536                	slli	a0,a0,0xd
    800028ba:	9782                	jalr	a5
}
    800028bc:	60a2                	ld	ra,8(sp)
    800028be:	6402                	ld	s0,0(sp)
    800028c0:	0141                	addi	sp,sp,16
    800028c2:	8082                	ret

00000000800028c4 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800028c4:	1101                	addi	sp,sp,-32
    800028c6:	ec06                	sd	ra,24(sp)
    800028c8:	e822                	sd	s0,16(sp)
    800028ca:	e426                	sd	s1,8(sp)
    800028cc:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800028ce:	00015497          	auipc	s1,0x15
    800028d2:	d1248493          	addi	s1,s1,-750 # 800175e0 <tickslock>
    800028d6:	8526                	mv	a0,s1
    800028d8:	ffffe097          	auipc	ra,0xffffe
    800028dc:	30c080e7          	jalr	780(ra) # 80000be4 <acquire>
  ticks++;
    800028e0:	00006517          	auipc	a0,0x6
    800028e4:	76050513          	addi	a0,a0,1888 # 80009040 <ticks>
    800028e8:	411c                	lw	a5,0(a0)
    800028ea:	2785                	addiw	a5,a5,1
    800028ec:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800028ee:	00000097          	auipc	ra,0x0
    800028f2:	b1c080e7          	jalr	-1252(ra) # 8000240a <wakeup>
  release(&tickslock);
    800028f6:	8526                	mv	a0,s1
    800028f8:	ffffe097          	auipc	ra,0xffffe
    800028fc:	3a0080e7          	jalr	928(ra) # 80000c98 <release>
}
    80002900:	60e2                	ld	ra,24(sp)
    80002902:	6442                	ld	s0,16(sp)
    80002904:	64a2                	ld	s1,8(sp)
    80002906:	6105                	addi	sp,sp,32
    80002908:	8082                	ret

000000008000290a <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000290a:	1101                	addi	sp,sp,-32
    8000290c:	ec06                	sd	ra,24(sp)
    8000290e:	e822                	sd	s0,16(sp)
    80002910:	e426                	sd	s1,8(sp)
    80002912:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002914:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002918:	00074d63          	bltz	a4,80002932 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000291c:	57fd                	li	a5,-1
    8000291e:	17fe                	slli	a5,a5,0x3f
    80002920:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002922:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002924:	06f70363          	beq	a4,a5,8000298a <devintr+0x80>
  }
}
    80002928:	60e2                	ld	ra,24(sp)
    8000292a:	6442                	ld	s0,16(sp)
    8000292c:	64a2                	ld	s1,8(sp)
    8000292e:	6105                	addi	sp,sp,32
    80002930:	8082                	ret
     (scause & 0xff) == 9){
    80002932:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002936:	46a5                	li	a3,9
    80002938:	fed792e3          	bne	a5,a3,8000291c <devintr+0x12>
    int irq = plic_claim();
    8000293c:	00003097          	auipc	ra,0x3
    80002940:	4cc080e7          	jalr	1228(ra) # 80005e08 <plic_claim>
    80002944:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002946:	47a9                	li	a5,10
    80002948:	02f50763          	beq	a0,a5,80002976 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000294c:	4785                	li	a5,1
    8000294e:	02f50963          	beq	a0,a5,80002980 <devintr+0x76>
    return 1;
    80002952:	4505                	li	a0,1
    } else if(irq){
    80002954:	d8f1                	beqz	s1,80002928 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002956:	85a6                	mv	a1,s1
    80002958:	00006517          	auipc	a0,0x6
    8000295c:	a4850513          	addi	a0,a0,-1464 # 800083a0 <states.1742+0x38>
    80002960:	ffffe097          	auipc	ra,0xffffe
    80002964:	c28080e7          	jalr	-984(ra) # 80000588 <printf>
      plic_complete(irq);
    80002968:	8526                	mv	a0,s1
    8000296a:	00003097          	auipc	ra,0x3
    8000296e:	4c2080e7          	jalr	1218(ra) # 80005e2c <plic_complete>
    return 1;
    80002972:	4505                	li	a0,1
    80002974:	bf55                	j	80002928 <devintr+0x1e>
      uartintr();
    80002976:	ffffe097          	auipc	ra,0xffffe
    8000297a:	032080e7          	jalr	50(ra) # 800009a8 <uartintr>
    8000297e:	b7ed                	j	80002968 <devintr+0x5e>
      virtio_disk_intr();
    80002980:	00004097          	auipc	ra,0x4
    80002984:	98c080e7          	jalr	-1652(ra) # 8000630c <virtio_disk_intr>
    80002988:	b7c5                	j	80002968 <devintr+0x5e>
    if(cpuid() == 0){
    8000298a:	fffff097          	auipc	ra,0xfffff
    8000298e:	0d6080e7          	jalr	214(ra) # 80001a60 <cpuid>
    80002992:	c901                	beqz	a0,800029a2 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002994:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002998:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000299a:	14479073          	csrw	sip,a5
    return 2;
    8000299e:	4509                	li	a0,2
    800029a0:	b761                	j	80002928 <devintr+0x1e>
      clockintr();
    800029a2:	00000097          	auipc	ra,0x0
    800029a6:	f22080e7          	jalr	-222(ra) # 800028c4 <clockintr>
    800029aa:	b7ed                	j	80002994 <devintr+0x8a>

00000000800029ac <usertrap>:
{
    800029ac:	1101                	addi	sp,sp,-32
    800029ae:	ec06                	sd	ra,24(sp)
    800029b0:	e822                	sd	s0,16(sp)
    800029b2:	e426                	sd	s1,8(sp)
    800029b4:	e04a                	sd	s2,0(sp)
    800029b6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029b8:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800029bc:	1007f793          	andi	a5,a5,256
    800029c0:	e3ad                	bnez	a5,80002a22 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029c2:	00003797          	auipc	a5,0x3
    800029c6:	33e78793          	addi	a5,a5,830 # 80005d00 <kernelvec>
    800029ca:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800029ce:	fffff097          	auipc	ra,0xfffff
    800029d2:	0be080e7          	jalr	190(ra) # 80001a8c <myproc>
    800029d6:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800029d8:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029da:	14102773          	csrr	a4,sepc
    800029de:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029e0:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800029e4:	47a1                	li	a5,8
    800029e6:	04f71c63          	bne	a4,a5,80002a3e <usertrap+0x92>
    if(p->killed)
    800029ea:	551c                	lw	a5,40(a0)
    800029ec:	e3b9                	bnez	a5,80002a32 <usertrap+0x86>
    p->trapframe->epc += 4;
    800029ee:	6cb8                	ld	a4,88(s1)
    800029f0:	6f1c                	ld	a5,24(a4)
    800029f2:	0791                	addi	a5,a5,4
    800029f4:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029f6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800029fa:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029fe:	10079073          	csrw	sstatus,a5
    syscall();
    80002a02:	00000097          	auipc	ra,0x0
    80002a06:	2e0080e7          	jalr	736(ra) # 80002ce2 <syscall>
  if(p->killed)
    80002a0a:	549c                	lw	a5,40(s1)
    80002a0c:	ebc1                	bnez	a5,80002a9c <usertrap+0xf0>
  usertrapret();
    80002a0e:	00000097          	auipc	ra,0x0
    80002a12:	e18080e7          	jalr	-488(ra) # 80002826 <usertrapret>
}
    80002a16:	60e2                	ld	ra,24(sp)
    80002a18:	6442                	ld	s0,16(sp)
    80002a1a:	64a2                	ld	s1,8(sp)
    80002a1c:	6902                	ld	s2,0(sp)
    80002a1e:	6105                	addi	sp,sp,32
    80002a20:	8082                	ret
    panic("usertrap: not from user mode");
    80002a22:	00006517          	auipc	a0,0x6
    80002a26:	99e50513          	addi	a0,a0,-1634 # 800083c0 <states.1742+0x58>
    80002a2a:	ffffe097          	auipc	ra,0xffffe
    80002a2e:	b14080e7          	jalr	-1260(ra) # 8000053e <panic>
      exit(-1);
    80002a32:	557d                	li	a0,-1
    80002a34:	00000097          	auipc	ra,0x0
    80002a38:	aa6080e7          	jalr	-1370(ra) # 800024da <exit>
    80002a3c:	bf4d                	j	800029ee <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002a3e:	00000097          	auipc	ra,0x0
    80002a42:	ecc080e7          	jalr	-308(ra) # 8000290a <devintr>
    80002a46:	892a                	mv	s2,a0
    80002a48:	c501                	beqz	a0,80002a50 <usertrap+0xa4>
  if(p->killed)
    80002a4a:	549c                	lw	a5,40(s1)
    80002a4c:	c3a1                	beqz	a5,80002a8c <usertrap+0xe0>
    80002a4e:	a815                	j	80002a82 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a50:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002a54:	5890                	lw	a2,48(s1)
    80002a56:	00006517          	auipc	a0,0x6
    80002a5a:	98a50513          	addi	a0,a0,-1654 # 800083e0 <states.1742+0x78>
    80002a5e:	ffffe097          	auipc	ra,0xffffe
    80002a62:	b2a080e7          	jalr	-1238(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a66:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a6a:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a6e:	00006517          	auipc	a0,0x6
    80002a72:	9a250513          	addi	a0,a0,-1630 # 80008410 <states.1742+0xa8>
    80002a76:	ffffe097          	auipc	ra,0xffffe
    80002a7a:	b12080e7          	jalr	-1262(ra) # 80000588 <printf>
    p->killed = 1;
    80002a7e:	4785                	li	a5,1
    80002a80:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002a82:	557d                	li	a0,-1
    80002a84:	00000097          	auipc	ra,0x0
    80002a88:	a56080e7          	jalr	-1450(ra) # 800024da <exit>
  if(which_dev == 2)
    80002a8c:	4789                	li	a5,2
    80002a8e:	f8f910e3          	bne	s2,a5,80002a0e <usertrap+0x62>
    yield();
    80002a92:	fffff097          	auipc	ra,0xfffff
    80002a96:	7b0080e7          	jalr	1968(ra) # 80002242 <yield>
    80002a9a:	bf95                	j	80002a0e <usertrap+0x62>
  int which_dev = 0;
    80002a9c:	4901                	li	s2,0
    80002a9e:	b7d5                	j	80002a82 <usertrap+0xd6>

0000000080002aa0 <kerneltrap>:
{
    80002aa0:	7179                	addi	sp,sp,-48
    80002aa2:	f406                	sd	ra,40(sp)
    80002aa4:	f022                	sd	s0,32(sp)
    80002aa6:	ec26                	sd	s1,24(sp)
    80002aa8:	e84a                	sd	s2,16(sp)
    80002aaa:	e44e                	sd	s3,8(sp)
    80002aac:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002aae:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ab2:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ab6:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002aba:	1004f793          	andi	a5,s1,256
    80002abe:	cb85                	beqz	a5,80002aee <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ac0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002ac4:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002ac6:	ef85                	bnez	a5,80002afe <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002ac8:	00000097          	auipc	ra,0x0
    80002acc:	e42080e7          	jalr	-446(ra) # 8000290a <devintr>
    80002ad0:	cd1d                	beqz	a0,80002b0e <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ad2:	4789                	li	a5,2
    80002ad4:	06f50a63          	beq	a0,a5,80002b48 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002ad8:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002adc:	10049073          	csrw	sstatus,s1
}
    80002ae0:	70a2                	ld	ra,40(sp)
    80002ae2:	7402                	ld	s0,32(sp)
    80002ae4:	64e2                	ld	s1,24(sp)
    80002ae6:	6942                	ld	s2,16(sp)
    80002ae8:	69a2                	ld	s3,8(sp)
    80002aea:	6145                	addi	sp,sp,48
    80002aec:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002aee:	00006517          	auipc	a0,0x6
    80002af2:	94250513          	addi	a0,a0,-1726 # 80008430 <states.1742+0xc8>
    80002af6:	ffffe097          	auipc	ra,0xffffe
    80002afa:	a48080e7          	jalr	-1464(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002afe:	00006517          	auipc	a0,0x6
    80002b02:	95a50513          	addi	a0,a0,-1702 # 80008458 <states.1742+0xf0>
    80002b06:	ffffe097          	auipc	ra,0xffffe
    80002b0a:	a38080e7          	jalr	-1480(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002b0e:	85ce                	mv	a1,s3
    80002b10:	00006517          	auipc	a0,0x6
    80002b14:	96850513          	addi	a0,a0,-1688 # 80008478 <states.1742+0x110>
    80002b18:	ffffe097          	auipc	ra,0xffffe
    80002b1c:	a70080e7          	jalr	-1424(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b20:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b24:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b28:	00006517          	auipc	a0,0x6
    80002b2c:	96050513          	addi	a0,a0,-1696 # 80008488 <states.1742+0x120>
    80002b30:	ffffe097          	auipc	ra,0xffffe
    80002b34:	a58080e7          	jalr	-1448(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002b38:	00006517          	auipc	a0,0x6
    80002b3c:	96850513          	addi	a0,a0,-1688 # 800084a0 <states.1742+0x138>
    80002b40:	ffffe097          	auipc	ra,0xffffe
    80002b44:	9fe080e7          	jalr	-1538(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b48:	fffff097          	auipc	ra,0xfffff
    80002b4c:	f44080e7          	jalr	-188(ra) # 80001a8c <myproc>
    80002b50:	d541                	beqz	a0,80002ad8 <kerneltrap+0x38>
    80002b52:	fffff097          	auipc	ra,0xfffff
    80002b56:	f3a080e7          	jalr	-198(ra) # 80001a8c <myproc>
    80002b5a:	4d18                	lw	a4,24(a0)
    80002b5c:	4791                	li	a5,4
    80002b5e:	f6f71de3          	bne	a4,a5,80002ad8 <kerneltrap+0x38>
    yield();
    80002b62:	fffff097          	auipc	ra,0xfffff
    80002b66:	6e0080e7          	jalr	1760(ra) # 80002242 <yield>
    80002b6a:	b7bd                	j	80002ad8 <kerneltrap+0x38>

0000000080002b6c <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002b6c:	1101                	addi	sp,sp,-32
    80002b6e:	ec06                	sd	ra,24(sp)
    80002b70:	e822                	sd	s0,16(sp)
    80002b72:	e426                	sd	s1,8(sp)
    80002b74:	1000                	addi	s0,sp,32
    80002b76:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002b78:	fffff097          	auipc	ra,0xfffff
    80002b7c:	f14080e7          	jalr	-236(ra) # 80001a8c <myproc>
  switch (n) {
    80002b80:	4795                	li	a5,5
    80002b82:	0497e163          	bltu	a5,s1,80002bc4 <argraw+0x58>
    80002b86:	048a                	slli	s1,s1,0x2
    80002b88:	00006717          	auipc	a4,0x6
    80002b8c:	95070713          	addi	a4,a4,-1712 # 800084d8 <states.1742+0x170>
    80002b90:	94ba                	add	s1,s1,a4
    80002b92:	409c                	lw	a5,0(s1)
    80002b94:	97ba                	add	a5,a5,a4
    80002b96:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002b98:	6d3c                	ld	a5,88(a0)
    80002b9a:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002b9c:	60e2                	ld	ra,24(sp)
    80002b9e:	6442                	ld	s0,16(sp)
    80002ba0:	64a2                	ld	s1,8(sp)
    80002ba2:	6105                	addi	sp,sp,32
    80002ba4:	8082                	ret
    return p->trapframe->a1;
    80002ba6:	6d3c                	ld	a5,88(a0)
    80002ba8:	7fa8                	ld	a0,120(a5)
    80002baa:	bfcd                	j	80002b9c <argraw+0x30>
    return p->trapframe->a2;
    80002bac:	6d3c                	ld	a5,88(a0)
    80002bae:	63c8                	ld	a0,128(a5)
    80002bb0:	b7f5                	j	80002b9c <argraw+0x30>
    return p->trapframe->a3;
    80002bb2:	6d3c                	ld	a5,88(a0)
    80002bb4:	67c8                	ld	a0,136(a5)
    80002bb6:	b7dd                	j	80002b9c <argraw+0x30>
    return p->trapframe->a4;
    80002bb8:	6d3c                	ld	a5,88(a0)
    80002bba:	6bc8                	ld	a0,144(a5)
    80002bbc:	b7c5                	j	80002b9c <argraw+0x30>
    return p->trapframe->a5;
    80002bbe:	6d3c                	ld	a5,88(a0)
    80002bc0:	6fc8                	ld	a0,152(a5)
    80002bc2:	bfe9                	j	80002b9c <argraw+0x30>
  panic("argraw");
    80002bc4:	00006517          	auipc	a0,0x6
    80002bc8:	8ec50513          	addi	a0,a0,-1812 # 800084b0 <states.1742+0x148>
    80002bcc:	ffffe097          	auipc	ra,0xffffe
    80002bd0:	972080e7          	jalr	-1678(ra) # 8000053e <panic>

0000000080002bd4 <fetchaddr>:
{
    80002bd4:	1101                	addi	sp,sp,-32
    80002bd6:	ec06                	sd	ra,24(sp)
    80002bd8:	e822                	sd	s0,16(sp)
    80002bda:	e426                	sd	s1,8(sp)
    80002bdc:	e04a                	sd	s2,0(sp)
    80002bde:	1000                	addi	s0,sp,32
    80002be0:	84aa                	mv	s1,a0
    80002be2:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002be4:	fffff097          	auipc	ra,0xfffff
    80002be8:	ea8080e7          	jalr	-344(ra) # 80001a8c <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002bec:	653c                	ld	a5,72(a0)
    80002bee:	02f4f863          	bgeu	s1,a5,80002c1e <fetchaddr+0x4a>
    80002bf2:	00848713          	addi	a4,s1,8
    80002bf6:	02e7e663          	bltu	a5,a4,80002c22 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002bfa:	46a1                	li	a3,8
    80002bfc:	8626                	mv	a2,s1
    80002bfe:	85ca                	mv	a1,s2
    80002c00:	6928                	ld	a0,80(a0)
    80002c02:	fffff097          	auipc	ra,0xfffff
    80002c06:	afc080e7          	jalr	-1284(ra) # 800016fe <copyin>
    80002c0a:	00a03533          	snez	a0,a0
    80002c0e:	40a00533          	neg	a0,a0
}
    80002c12:	60e2                	ld	ra,24(sp)
    80002c14:	6442                	ld	s0,16(sp)
    80002c16:	64a2                	ld	s1,8(sp)
    80002c18:	6902                	ld	s2,0(sp)
    80002c1a:	6105                	addi	sp,sp,32
    80002c1c:	8082                	ret
    return -1;
    80002c1e:	557d                	li	a0,-1
    80002c20:	bfcd                	j	80002c12 <fetchaddr+0x3e>
    80002c22:	557d                	li	a0,-1
    80002c24:	b7fd                	j	80002c12 <fetchaddr+0x3e>

0000000080002c26 <fetchstr>:
{
    80002c26:	7179                	addi	sp,sp,-48
    80002c28:	f406                	sd	ra,40(sp)
    80002c2a:	f022                	sd	s0,32(sp)
    80002c2c:	ec26                	sd	s1,24(sp)
    80002c2e:	e84a                	sd	s2,16(sp)
    80002c30:	e44e                	sd	s3,8(sp)
    80002c32:	1800                	addi	s0,sp,48
    80002c34:	892a                	mv	s2,a0
    80002c36:	84ae                	mv	s1,a1
    80002c38:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002c3a:	fffff097          	auipc	ra,0xfffff
    80002c3e:	e52080e7          	jalr	-430(ra) # 80001a8c <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002c42:	86ce                	mv	a3,s3
    80002c44:	864a                	mv	a2,s2
    80002c46:	85a6                	mv	a1,s1
    80002c48:	6928                	ld	a0,80(a0)
    80002c4a:	fffff097          	auipc	ra,0xfffff
    80002c4e:	b40080e7          	jalr	-1216(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002c52:	00054763          	bltz	a0,80002c60 <fetchstr+0x3a>
  return strlen(buf);
    80002c56:	8526                	mv	a0,s1
    80002c58:	ffffe097          	auipc	ra,0xffffe
    80002c5c:	20c080e7          	jalr	524(ra) # 80000e64 <strlen>
}
    80002c60:	70a2                	ld	ra,40(sp)
    80002c62:	7402                	ld	s0,32(sp)
    80002c64:	64e2                	ld	s1,24(sp)
    80002c66:	6942                	ld	s2,16(sp)
    80002c68:	69a2                	ld	s3,8(sp)
    80002c6a:	6145                	addi	sp,sp,48
    80002c6c:	8082                	ret

0000000080002c6e <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002c6e:	1101                	addi	sp,sp,-32
    80002c70:	ec06                	sd	ra,24(sp)
    80002c72:	e822                	sd	s0,16(sp)
    80002c74:	e426                	sd	s1,8(sp)
    80002c76:	1000                	addi	s0,sp,32
    80002c78:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c7a:	00000097          	auipc	ra,0x0
    80002c7e:	ef2080e7          	jalr	-270(ra) # 80002b6c <argraw>
    80002c82:	c088                	sw	a0,0(s1)
  return 0;
}
    80002c84:	4501                	li	a0,0
    80002c86:	60e2                	ld	ra,24(sp)
    80002c88:	6442                	ld	s0,16(sp)
    80002c8a:	64a2                	ld	s1,8(sp)
    80002c8c:	6105                	addi	sp,sp,32
    80002c8e:	8082                	ret

0000000080002c90 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002c90:	1101                	addi	sp,sp,-32
    80002c92:	ec06                	sd	ra,24(sp)
    80002c94:	e822                	sd	s0,16(sp)
    80002c96:	e426                	sd	s1,8(sp)
    80002c98:	1000                	addi	s0,sp,32
    80002c9a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c9c:	00000097          	auipc	ra,0x0
    80002ca0:	ed0080e7          	jalr	-304(ra) # 80002b6c <argraw>
    80002ca4:	e088                	sd	a0,0(s1)
  return 0;
}
    80002ca6:	4501                	li	a0,0
    80002ca8:	60e2                	ld	ra,24(sp)
    80002caa:	6442                	ld	s0,16(sp)
    80002cac:	64a2                	ld	s1,8(sp)
    80002cae:	6105                	addi	sp,sp,32
    80002cb0:	8082                	ret

0000000080002cb2 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002cb2:	1101                	addi	sp,sp,-32
    80002cb4:	ec06                	sd	ra,24(sp)
    80002cb6:	e822                	sd	s0,16(sp)
    80002cb8:	e426                	sd	s1,8(sp)
    80002cba:	e04a                	sd	s2,0(sp)
    80002cbc:	1000                	addi	s0,sp,32
    80002cbe:	84ae                	mv	s1,a1
    80002cc0:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002cc2:	00000097          	auipc	ra,0x0
    80002cc6:	eaa080e7          	jalr	-342(ra) # 80002b6c <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002cca:	864a                	mv	a2,s2
    80002ccc:	85a6                	mv	a1,s1
    80002cce:	00000097          	auipc	ra,0x0
    80002cd2:	f58080e7          	jalr	-168(ra) # 80002c26 <fetchstr>
}
    80002cd6:	60e2                	ld	ra,24(sp)
    80002cd8:	6442                	ld	s0,16(sp)
    80002cda:	64a2                	ld	s1,8(sp)
    80002cdc:	6902                	ld	s2,0(sp)
    80002cde:	6105                	addi	sp,sp,32
    80002ce0:	8082                	ret

0000000080002ce2 <syscall>:
[SYS_schedstatistics] sys_schedstatistics, //schedstatistics entry
};

void
syscall(void)
{
    80002ce2:	1101                	addi	sp,sp,-32
    80002ce4:	ec06                	sd	ra,24(sp)
    80002ce6:	e822                	sd	s0,16(sp)
    80002ce8:	e426                	sd	s1,8(sp)
    80002cea:	e04a                	sd	s2,0(sp)
    80002cec:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002cee:	fffff097          	auipc	ra,0xfffff
    80002cf2:	d9e080e7          	jalr	-610(ra) # 80001a8c <myproc>
    80002cf6:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002cf8:	05853903          	ld	s2,88(a0)
    80002cfc:	0a893783          	ld	a5,168(s2)
    80002d00:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002d04:	37fd                	addiw	a5,a5,-1
    80002d06:	4759                	li	a4,22
    80002d08:	00f76f63          	bltu	a4,a5,80002d26 <syscall+0x44>
    80002d0c:	00369713          	slli	a4,a3,0x3
    80002d10:	00005797          	auipc	a5,0x5
    80002d14:	7e078793          	addi	a5,a5,2016 # 800084f0 <syscalls>
    80002d18:	97ba                	add	a5,a5,a4
    80002d1a:	639c                	ld	a5,0(a5)
    80002d1c:	c789                	beqz	a5,80002d26 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002d1e:	9782                	jalr	a5
    80002d20:	06a93823          	sd	a0,112(s2)
    80002d24:	a839                	j	80002d42 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d26:	15848613          	addi	a2,s1,344
    80002d2a:	588c                	lw	a1,48(s1)
    80002d2c:	00005517          	auipc	a0,0x5
    80002d30:	78c50513          	addi	a0,a0,1932 # 800084b8 <states.1742+0x150>
    80002d34:	ffffe097          	auipc	ra,0xffffe
    80002d38:	854080e7          	jalr	-1964(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d3c:	6cbc                	ld	a5,88(s1)
    80002d3e:	577d                	li	a4,-1
    80002d40:	fbb8                	sd	a4,112(a5)
  }
}
    80002d42:	60e2                	ld	ra,24(sp)
    80002d44:	6442                	ld	s0,16(sp)
    80002d46:	64a2                	ld	s1,8(sp)
    80002d48:	6902                	ld	s2,0(sp)
    80002d4a:	6105                	addi	sp,sp,32
    80002d4c:	8082                	ret

0000000080002d4e <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002d4e:	1101                	addi	sp,sp,-32
    80002d50:	ec06                	sd	ra,24(sp)
    80002d52:	e822                	sd	s0,16(sp)
    80002d54:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002d56:	fec40593          	addi	a1,s0,-20
    80002d5a:	4501                	li	a0,0
    80002d5c:	00000097          	auipc	ra,0x0
    80002d60:	f12080e7          	jalr	-238(ra) # 80002c6e <argint>
    return -1;
    80002d64:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d66:	00054963          	bltz	a0,80002d78 <sys_exit+0x2a>
  exit(n);
    80002d6a:	fec42503          	lw	a0,-20(s0)
    80002d6e:	fffff097          	auipc	ra,0xfffff
    80002d72:	76c080e7          	jalr	1900(ra) # 800024da <exit>
  return 0;  // not reached
    80002d76:	4781                	li	a5,0
}
    80002d78:	853e                	mv	a0,a5
    80002d7a:	60e2                	ld	ra,24(sp)
    80002d7c:	6442                	ld	s0,16(sp)
    80002d7e:	6105                	addi	sp,sp,32
    80002d80:	8082                	ret

0000000080002d82 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002d82:	1141                	addi	sp,sp,-16
    80002d84:	e406                	sd	ra,8(sp)
    80002d86:	e022                	sd	s0,0(sp)
    80002d88:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002d8a:	fffff097          	auipc	ra,0xfffff
    80002d8e:	d02080e7          	jalr	-766(ra) # 80001a8c <myproc>
}
    80002d92:	5908                	lw	a0,48(a0)
    80002d94:	60a2                	ld	ra,8(sp)
    80002d96:	6402                	ld	s0,0(sp)
    80002d98:	0141                	addi	sp,sp,16
    80002d9a:	8082                	ret

0000000080002d9c <sys_fork>:

uint64
sys_fork(void)
{
    80002d9c:	1141                	addi	sp,sp,-16
    80002d9e:	e406                	sd	ra,8(sp)
    80002da0:	e022                	sd	s0,0(sp)
    80002da2:	0800                	addi	s0,sp,16
  return fork();
    80002da4:	fffff097          	auipc	ra,0xfffff
    80002da8:	19a080e7          	jalr	410(ra) # 80001f3e <fork>
}
    80002dac:	60a2                	ld	ra,8(sp)
    80002dae:	6402                	ld	s0,0(sp)
    80002db0:	0141                	addi	sp,sp,16
    80002db2:	8082                	ret

0000000080002db4 <sys_wait>:

uint64
sys_wait(void)
{
    80002db4:	1101                	addi	sp,sp,-32
    80002db6:	ec06                	sd	ra,24(sp)
    80002db8:	e822                	sd	s0,16(sp)
    80002dba:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002dbc:	fe840593          	addi	a1,s0,-24
    80002dc0:	4501                	li	a0,0
    80002dc2:	00000097          	auipc	ra,0x0
    80002dc6:	ece080e7          	jalr	-306(ra) # 80002c90 <argaddr>
    80002dca:	87aa                	mv	a5,a0
    return -1;
    80002dcc:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002dce:	0007c863          	bltz	a5,80002dde <sys_wait+0x2a>
  return wait(p);
    80002dd2:	fe843503          	ld	a0,-24(s0)
    80002dd6:	fffff097          	auipc	ra,0xfffff
    80002dda:	50c080e7          	jalr	1292(ra) # 800022e2 <wait>
}
    80002dde:	60e2                	ld	ra,24(sp)
    80002de0:	6442                	ld	s0,16(sp)
    80002de2:	6105                	addi	sp,sp,32
    80002de4:	8082                	ret

0000000080002de6 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002de6:	7179                	addi	sp,sp,-48
    80002de8:	f406                	sd	ra,40(sp)
    80002dea:	f022                	sd	s0,32(sp)
    80002dec:	ec26                	sd	s1,24(sp)
    80002dee:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002df0:	fdc40593          	addi	a1,s0,-36
    80002df4:	4501                	li	a0,0
    80002df6:	00000097          	auipc	ra,0x0
    80002dfa:	e78080e7          	jalr	-392(ra) # 80002c6e <argint>
    80002dfe:	87aa                	mv	a5,a0
    return -1;
    80002e00:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002e02:	0207c063          	bltz	a5,80002e22 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002e06:	fffff097          	auipc	ra,0xfffff
    80002e0a:	c86080e7          	jalr	-890(ra) # 80001a8c <myproc>
    80002e0e:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002e10:	fdc42503          	lw	a0,-36(s0)
    80002e14:	fffff097          	auipc	ra,0xfffff
    80002e18:	0b6080e7          	jalr	182(ra) # 80001eca <growproc>
    80002e1c:	00054863          	bltz	a0,80002e2c <sys_sbrk+0x46>
    return -1;
  return addr;
    80002e20:	8526                	mv	a0,s1
}
    80002e22:	70a2                	ld	ra,40(sp)
    80002e24:	7402                	ld	s0,32(sp)
    80002e26:	64e2                	ld	s1,24(sp)
    80002e28:	6145                	addi	sp,sp,48
    80002e2a:	8082                	ret
    return -1;
    80002e2c:	557d                	li	a0,-1
    80002e2e:	bfd5                	j	80002e22 <sys_sbrk+0x3c>

0000000080002e30 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002e30:	7139                	addi	sp,sp,-64
    80002e32:	fc06                	sd	ra,56(sp)
    80002e34:	f822                	sd	s0,48(sp)
    80002e36:	f426                	sd	s1,40(sp)
    80002e38:	f04a                	sd	s2,32(sp)
    80002e3a:	ec4e                	sd	s3,24(sp)
    80002e3c:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002e3e:	fcc40593          	addi	a1,s0,-52
    80002e42:	4501                	li	a0,0
    80002e44:	00000097          	auipc	ra,0x0
    80002e48:	e2a080e7          	jalr	-470(ra) # 80002c6e <argint>
    return -1;
    80002e4c:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e4e:	06054563          	bltz	a0,80002eb8 <sys_sleep+0x88>
  acquire(&tickslock);
    80002e52:	00014517          	auipc	a0,0x14
    80002e56:	78e50513          	addi	a0,a0,1934 # 800175e0 <tickslock>
    80002e5a:	ffffe097          	auipc	ra,0xffffe
    80002e5e:	d8a080e7          	jalr	-630(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002e62:	00006917          	auipc	s2,0x6
    80002e66:	1de92903          	lw	s2,478(s2) # 80009040 <ticks>
  while(ticks - ticks0 < n){
    80002e6a:	fcc42783          	lw	a5,-52(s0)
    80002e6e:	cf85                	beqz	a5,80002ea6 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002e70:	00014997          	auipc	s3,0x14
    80002e74:	77098993          	addi	s3,s3,1904 # 800175e0 <tickslock>
    80002e78:	00006497          	auipc	s1,0x6
    80002e7c:	1c848493          	addi	s1,s1,456 # 80009040 <ticks>
    if(myproc()->killed){
    80002e80:	fffff097          	auipc	ra,0xfffff
    80002e84:	c0c080e7          	jalr	-1012(ra) # 80001a8c <myproc>
    80002e88:	551c                	lw	a5,40(a0)
    80002e8a:	ef9d                	bnez	a5,80002ec8 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002e8c:	85ce                	mv	a1,s3
    80002e8e:	8526                	mv	a0,s1
    80002e90:	fffff097          	auipc	ra,0xfffff
    80002e94:	3ee080e7          	jalr	1006(ra) # 8000227e <sleep>
  while(ticks - ticks0 < n){
    80002e98:	409c                	lw	a5,0(s1)
    80002e9a:	412787bb          	subw	a5,a5,s2
    80002e9e:	fcc42703          	lw	a4,-52(s0)
    80002ea2:	fce7efe3          	bltu	a5,a4,80002e80 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002ea6:	00014517          	auipc	a0,0x14
    80002eaa:	73a50513          	addi	a0,a0,1850 # 800175e0 <tickslock>
    80002eae:	ffffe097          	auipc	ra,0xffffe
    80002eb2:	dea080e7          	jalr	-534(ra) # 80000c98 <release>
  return 0;
    80002eb6:	4781                	li	a5,0
}
    80002eb8:	853e                	mv	a0,a5
    80002eba:	70e2                	ld	ra,56(sp)
    80002ebc:	7442                	ld	s0,48(sp)
    80002ebe:	74a2                	ld	s1,40(sp)
    80002ec0:	7902                	ld	s2,32(sp)
    80002ec2:	69e2                	ld	s3,24(sp)
    80002ec4:	6121                	addi	sp,sp,64
    80002ec6:	8082                	ret
      release(&tickslock);
    80002ec8:	00014517          	auipc	a0,0x14
    80002ecc:	71850513          	addi	a0,a0,1816 # 800175e0 <tickslock>
    80002ed0:	ffffe097          	auipc	ra,0xffffe
    80002ed4:	dc8080e7          	jalr	-568(ra) # 80000c98 <release>
      return -1;
    80002ed8:	57fd                	li	a5,-1
    80002eda:	bff9                	j	80002eb8 <sys_sleep+0x88>

0000000080002edc <sys_kill>:

uint64
sys_kill(void)
{
    80002edc:	1101                	addi	sp,sp,-32
    80002ede:	ec06                	sd	ra,24(sp)
    80002ee0:	e822                	sd	s0,16(sp)
    80002ee2:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002ee4:	fec40593          	addi	a1,s0,-20
    80002ee8:	4501                	li	a0,0
    80002eea:	00000097          	auipc	ra,0x0
    80002eee:	d84080e7          	jalr	-636(ra) # 80002c6e <argint>
    80002ef2:	87aa                	mv	a5,a0
    return -1;
    80002ef4:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002ef6:	0007c863          	bltz	a5,80002f06 <sys_kill+0x2a>
  return kill(pid);
    80002efa:	fec42503          	lw	a0,-20(s0)
    80002efe:	fffff097          	auipc	ra,0xfffff
    80002f02:	6b2080e7          	jalr	1714(ra) # 800025b0 <kill>
}
    80002f06:	60e2                	ld	ra,24(sp)
    80002f08:	6442                	ld	s0,16(sp)
    80002f0a:	6105                	addi	sp,sp,32
    80002f0c:	8082                	ret

0000000080002f0e <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002f0e:	1101                	addi	sp,sp,-32
    80002f10:	ec06                	sd	ra,24(sp)
    80002f12:	e822                	sd	s0,16(sp)
    80002f14:	e426                	sd	s1,8(sp)
    80002f16:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f18:	00014517          	auipc	a0,0x14
    80002f1c:	6c850513          	addi	a0,a0,1736 # 800175e0 <tickslock>
    80002f20:	ffffe097          	auipc	ra,0xffffe
    80002f24:	cc4080e7          	jalr	-828(ra) # 80000be4 <acquire>
  xticks = ticks;
    80002f28:	00006497          	auipc	s1,0x6
    80002f2c:	1184a483          	lw	s1,280(s1) # 80009040 <ticks>
  release(&tickslock);
    80002f30:	00014517          	auipc	a0,0x14
    80002f34:	6b050513          	addi	a0,a0,1712 # 800175e0 <tickslock>
    80002f38:	ffffe097          	auipc	ra,0xffffe
    80002f3c:	d60080e7          	jalr	-672(ra) # 80000c98 <release>
  return xticks;
}
    80002f40:	02049513          	slli	a0,s1,0x20
    80002f44:	9101                	srli	a0,a0,0x20
    80002f46:	60e2                	ld	ra,24(sp)
    80002f48:	6442                	ld	s0,16(sp)
    80002f4a:	64a2                	ld	s1,8(sp)
    80002f4c:	6105                	addi	sp,sp,32
    80002f4e:	8082                	ret

0000000080002f50 <sys_settickets>:

//set tickets syscall definition
uint64
sys_settickets(void)
{
    80002f50:	1101                	addi	sp,sp,-32
    80002f52:	ec06                	sd	ra,24(sp)
    80002f54:	e822                	sd	s0,16(sp)
    80002f56:	1000                	addi	s0,sp,32
    int n;
    argint(0,&n);
    80002f58:	fec40593          	addi	a1,s0,-20
    80002f5c:	4501                	li	a0,0
    80002f5e:	00000097          	auipc	ra,0x0
    80002f62:	d10080e7          	jalr	-752(ra) # 80002c6e <argint>
    allocateTickets(n);
    80002f66:	fec42503          	lw	a0,-20(s0)
    80002f6a:	fffff097          	auipc	ra,0xfffff
    80002f6e:	b5c080e7          	jalr	-1188(ra) # 80001ac6 <allocateTickets>
    return 0;
}
    80002f72:	4501                	li	a0,0
    80002f74:	60e2                	ld	ra,24(sp)
    80002f76:	6442                	ld	s0,16(sp)
    80002f78:	6105                	addi	sp,sp,32
    80002f7a:	8082                	ret

0000000080002f7c <sys_schedstatistics>:

//sched statistics syscall definition
uint64
sys_schedstatistics(void)
{
    80002f7c:	1101                	addi	sp,sp,-32
    80002f7e:	ec06                	sd	ra,24(sp)
    80002f80:	e822                	sd	s0,16(sp)
    80002f82:	1000                	addi	s0,sp,32
    int n;
    int prog_num;
    argint(0,&n);
    80002f84:	fec40593          	addi	a1,s0,-20
    80002f88:	4501                	li	a0,0
    80002f8a:	00000097          	auipc	ra,0x0
    80002f8e:	ce4080e7          	jalr	-796(ra) # 80002c6e <argint>
    argint(1,&prog_num);
    80002f92:	fe840593          	addi	a1,s0,-24
    80002f96:	4505                	li	a0,1
    80002f98:	00000097          	auipc	ra,0x0
    80002f9c:	cd6080e7          	jalr	-810(ra) # 80002c6e <argint>
    displayStats(n,prog_num);
    80002fa0:	fe842583          	lw	a1,-24(s0)
    80002fa4:	fec42503          	lw	a0,-20(s0)
    80002fa8:	fffff097          	auipc	ra,0xfffff
    80002fac:	896080e7          	jalr	-1898(ra) # 8000183e <displayStats>
    return 0;
}
    80002fb0:	4501                	li	a0,0
    80002fb2:	60e2                	ld	ra,24(sp)
    80002fb4:	6442                	ld	s0,16(sp)
    80002fb6:	6105                	addi	sp,sp,32
    80002fb8:	8082                	ret

0000000080002fba <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002fba:	7179                	addi	sp,sp,-48
    80002fbc:	f406                	sd	ra,40(sp)
    80002fbe:	f022                	sd	s0,32(sp)
    80002fc0:	ec26                	sd	s1,24(sp)
    80002fc2:	e84a                	sd	s2,16(sp)
    80002fc4:	e44e                	sd	s3,8(sp)
    80002fc6:	e052                	sd	s4,0(sp)
    80002fc8:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002fca:	00005597          	auipc	a1,0x5
    80002fce:	5e658593          	addi	a1,a1,1510 # 800085b0 <syscalls+0xc0>
    80002fd2:	00014517          	auipc	a0,0x14
    80002fd6:	62650513          	addi	a0,a0,1574 # 800175f8 <bcache>
    80002fda:	ffffe097          	auipc	ra,0xffffe
    80002fde:	b7a080e7          	jalr	-1158(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002fe2:	0001c797          	auipc	a5,0x1c
    80002fe6:	61678793          	addi	a5,a5,1558 # 8001f5f8 <bcache+0x8000>
    80002fea:	0001d717          	auipc	a4,0x1d
    80002fee:	87670713          	addi	a4,a4,-1930 # 8001f860 <bcache+0x8268>
    80002ff2:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002ff6:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002ffa:	00014497          	auipc	s1,0x14
    80002ffe:	61648493          	addi	s1,s1,1558 # 80017610 <bcache+0x18>
    b->next = bcache.head.next;
    80003002:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003004:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003006:	00005a17          	auipc	s4,0x5
    8000300a:	5b2a0a13          	addi	s4,s4,1458 # 800085b8 <syscalls+0xc8>
    b->next = bcache.head.next;
    8000300e:	2b893783          	ld	a5,696(s2)
    80003012:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003014:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003018:	85d2                	mv	a1,s4
    8000301a:	01048513          	addi	a0,s1,16
    8000301e:	00001097          	auipc	ra,0x1
    80003022:	4bc080e7          	jalr	1212(ra) # 800044da <initsleeplock>
    bcache.head.next->prev = b;
    80003026:	2b893783          	ld	a5,696(s2)
    8000302a:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000302c:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003030:	45848493          	addi	s1,s1,1112
    80003034:	fd349de3          	bne	s1,s3,8000300e <binit+0x54>
  }
}
    80003038:	70a2                	ld	ra,40(sp)
    8000303a:	7402                	ld	s0,32(sp)
    8000303c:	64e2                	ld	s1,24(sp)
    8000303e:	6942                	ld	s2,16(sp)
    80003040:	69a2                	ld	s3,8(sp)
    80003042:	6a02                	ld	s4,0(sp)
    80003044:	6145                	addi	sp,sp,48
    80003046:	8082                	ret

0000000080003048 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003048:	7179                	addi	sp,sp,-48
    8000304a:	f406                	sd	ra,40(sp)
    8000304c:	f022                	sd	s0,32(sp)
    8000304e:	ec26                	sd	s1,24(sp)
    80003050:	e84a                	sd	s2,16(sp)
    80003052:	e44e                	sd	s3,8(sp)
    80003054:	1800                	addi	s0,sp,48
    80003056:	89aa                	mv	s3,a0
    80003058:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    8000305a:	00014517          	auipc	a0,0x14
    8000305e:	59e50513          	addi	a0,a0,1438 # 800175f8 <bcache>
    80003062:	ffffe097          	auipc	ra,0xffffe
    80003066:	b82080e7          	jalr	-1150(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000306a:	0001d497          	auipc	s1,0x1d
    8000306e:	8464b483          	ld	s1,-1978(s1) # 8001f8b0 <bcache+0x82b8>
    80003072:	0001c797          	auipc	a5,0x1c
    80003076:	7ee78793          	addi	a5,a5,2030 # 8001f860 <bcache+0x8268>
    8000307a:	02f48f63          	beq	s1,a5,800030b8 <bread+0x70>
    8000307e:	873e                	mv	a4,a5
    80003080:	a021                	j	80003088 <bread+0x40>
    80003082:	68a4                	ld	s1,80(s1)
    80003084:	02e48a63          	beq	s1,a4,800030b8 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003088:	449c                	lw	a5,8(s1)
    8000308a:	ff379ce3          	bne	a5,s3,80003082 <bread+0x3a>
    8000308e:	44dc                	lw	a5,12(s1)
    80003090:	ff2799e3          	bne	a5,s2,80003082 <bread+0x3a>
      b->refcnt++;
    80003094:	40bc                	lw	a5,64(s1)
    80003096:	2785                	addiw	a5,a5,1
    80003098:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000309a:	00014517          	auipc	a0,0x14
    8000309e:	55e50513          	addi	a0,a0,1374 # 800175f8 <bcache>
    800030a2:	ffffe097          	auipc	ra,0xffffe
    800030a6:	bf6080e7          	jalr	-1034(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800030aa:	01048513          	addi	a0,s1,16
    800030ae:	00001097          	auipc	ra,0x1
    800030b2:	466080e7          	jalr	1126(ra) # 80004514 <acquiresleep>
      return b;
    800030b6:	a8b9                	j	80003114 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030b8:	0001c497          	auipc	s1,0x1c
    800030bc:	7f04b483          	ld	s1,2032(s1) # 8001f8a8 <bcache+0x82b0>
    800030c0:	0001c797          	auipc	a5,0x1c
    800030c4:	7a078793          	addi	a5,a5,1952 # 8001f860 <bcache+0x8268>
    800030c8:	00f48863          	beq	s1,a5,800030d8 <bread+0x90>
    800030cc:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800030ce:	40bc                	lw	a5,64(s1)
    800030d0:	cf81                	beqz	a5,800030e8 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030d2:	64a4                	ld	s1,72(s1)
    800030d4:	fee49de3          	bne	s1,a4,800030ce <bread+0x86>
  panic("bget: no buffers");
    800030d8:	00005517          	auipc	a0,0x5
    800030dc:	4e850513          	addi	a0,a0,1256 # 800085c0 <syscalls+0xd0>
    800030e0:	ffffd097          	auipc	ra,0xffffd
    800030e4:	45e080e7          	jalr	1118(ra) # 8000053e <panic>
      b->dev = dev;
    800030e8:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800030ec:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800030f0:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800030f4:	4785                	li	a5,1
    800030f6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800030f8:	00014517          	auipc	a0,0x14
    800030fc:	50050513          	addi	a0,a0,1280 # 800175f8 <bcache>
    80003100:	ffffe097          	auipc	ra,0xffffe
    80003104:	b98080e7          	jalr	-1128(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003108:	01048513          	addi	a0,s1,16
    8000310c:	00001097          	auipc	ra,0x1
    80003110:	408080e7          	jalr	1032(ra) # 80004514 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003114:	409c                	lw	a5,0(s1)
    80003116:	cb89                	beqz	a5,80003128 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003118:	8526                	mv	a0,s1
    8000311a:	70a2                	ld	ra,40(sp)
    8000311c:	7402                	ld	s0,32(sp)
    8000311e:	64e2                	ld	s1,24(sp)
    80003120:	6942                	ld	s2,16(sp)
    80003122:	69a2                	ld	s3,8(sp)
    80003124:	6145                	addi	sp,sp,48
    80003126:	8082                	ret
    virtio_disk_rw(b, 0);
    80003128:	4581                	li	a1,0
    8000312a:	8526                	mv	a0,s1
    8000312c:	00003097          	auipc	ra,0x3
    80003130:	f0a080e7          	jalr	-246(ra) # 80006036 <virtio_disk_rw>
    b->valid = 1;
    80003134:	4785                	li	a5,1
    80003136:	c09c                	sw	a5,0(s1)
  return b;
    80003138:	b7c5                	j	80003118 <bread+0xd0>

000000008000313a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000313a:	1101                	addi	sp,sp,-32
    8000313c:	ec06                	sd	ra,24(sp)
    8000313e:	e822                	sd	s0,16(sp)
    80003140:	e426                	sd	s1,8(sp)
    80003142:	1000                	addi	s0,sp,32
    80003144:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003146:	0541                	addi	a0,a0,16
    80003148:	00001097          	auipc	ra,0x1
    8000314c:	466080e7          	jalr	1126(ra) # 800045ae <holdingsleep>
    80003150:	cd01                	beqz	a0,80003168 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003152:	4585                	li	a1,1
    80003154:	8526                	mv	a0,s1
    80003156:	00003097          	auipc	ra,0x3
    8000315a:	ee0080e7          	jalr	-288(ra) # 80006036 <virtio_disk_rw>
}
    8000315e:	60e2                	ld	ra,24(sp)
    80003160:	6442                	ld	s0,16(sp)
    80003162:	64a2                	ld	s1,8(sp)
    80003164:	6105                	addi	sp,sp,32
    80003166:	8082                	ret
    panic("bwrite");
    80003168:	00005517          	auipc	a0,0x5
    8000316c:	47050513          	addi	a0,a0,1136 # 800085d8 <syscalls+0xe8>
    80003170:	ffffd097          	auipc	ra,0xffffd
    80003174:	3ce080e7          	jalr	974(ra) # 8000053e <panic>

0000000080003178 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003178:	1101                	addi	sp,sp,-32
    8000317a:	ec06                	sd	ra,24(sp)
    8000317c:	e822                	sd	s0,16(sp)
    8000317e:	e426                	sd	s1,8(sp)
    80003180:	e04a                	sd	s2,0(sp)
    80003182:	1000                	addi	s0,sp,32
    80003184:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003186:	01050913          	addi	s2,a0,16
    8000318a:	854a                	mv	a0,s2
    8000318c:	00001097          	auipc	ra,0x1
    80003190:	422080e7          	jalr	1058(ra) # 800045ae <holdingsleep>
    80003194:	c92d                	beqz	a0,80003206 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003196:	854a                	mv	a0,s2
    80003198:	00001097          	auipc	ra,0x1
    8000319c:	3d2080e7          	jalr	978(ra) # 8000456a <releasesleep>

  acquire(&bcache.lock);
    800031a0:	00014517          	auipc	a0,0x14
    800031a4:	45850513          	addi	a0,a0,1112 # 800175f8 <bcache>
    800031a8:	ffffe097          	auipc	ra,0xffffe
    800031ac:	a3c080e7          	jalr	-1476(ra) # 80000be4 <acquire>
  b->refcnt--;
    800031b0:	40bc                	lw	a5,64(s1)
    800031b2:	37fd                	addiw	a5,a5,-1
    800031b4:	0007871b          	sext.w	a4,a5
    800031b8:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800031ba:	eb05                	bnez	a4,800031ea <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800031bc:	68bc                	ld	a5,80(s1)
    800031be:	64b8                	ld	a4,72(s1)
    800031c0:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800031c2:	64bc                	ld	a5,72(s1)
    800031c4:	68b8                	ld	a4,80(s1)
    800031c6:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800031c8:	0001c797          	auipc	a5,0x1c
    800031cc:	43078793          	addi	a5,a5,1072 # 8001f5f8 <bcache+0x8000>
    800031d0:	2b87b703          	ld	a4,696(a5)
    800031d4:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800031d6:	0001c717          	auipc	a4,0x1c
    800031da:	68a70713          	addi	a4,a4,1674 # 8001f860 <bcache+0x8268>
    800031de:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800031e0:	2b87b703          	ld	a4,696(a5)
    800031e4:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800031e6:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800031ea:	00014517          	auipc	a0,0x14
    800031ee:	40e50513          	addi	a0,a0,1038 # 800175f8 <bcache>
    800031f2:	ffffe097          	auipc	ra,0xffffe
    800031f6:	aa6080e7          	jalr	-1370(ra) # 80000c98 <release>
}
    800031fa:	60e2                	ld	ra,24(sp)
    800031fc:	6442                	ld	s0,16(sp)
    800031fe:	64a2                	ld	s1,8(sp)
    80003200:	6902                	ld	s2,0(sp)
    80003202:	6105                	addi	sp,sp,32
    80003204:	8082                	ret
    panic("brelse");
    80003206:	00005517          	auipc	a0,0x5
    8000320a:	3da50513          	addi	a0,a0,986 # 800085e0 <syscalls+0xf0>
    8000320e:	ffffd097          	auipc	ra,0xffffd
    80003212:	330080e7          	jalr	816(ra) # 8000053e <panic>

0000000080003216 <bpin>:

void
bpin(struct buf *b) {
    80003216:	1101                	addi	sp,sp,-32
    80003218:	ec06                	sd	ra,24(sp)
    8000321a:	e822                	sd	s0,16(sp)
    8000321c:	e426                	sd	s1,8(sp)
    8000321e:	1000                	addi	s0,sp,32
    80003220:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003222:	00014517          	auipc	a0,0x14
    80003226:	3d650513          	addi	a0,a0,982 # 800175f8 <bcache>
    8000322a:	ffffe097          	auipc	ra,0xffffe
    8000322e:	9ba080e7          	jalr	-1606(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003232:	40bc                	lw	a5,64(s1)
    80003234:	2785                	addiw	a5,a5,1
    80003236:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003238:	00014517          	auipc	a0,0x14
    8000323c:	3c050513          	addi	a0,a0,960 # 800175f8 <bcache>
    80003240:	ffffe097          	auipc	ra,0xffffe
    80003244:	a58080e7          	jalr	-1448(ra) # 80000c98 <release>
}
    80003248:	60e2                	ld	ra,24(sp)
    8000324a:	6442                	ld	s0,16(sp)
    8000324c:	64a2                	ld	s1,8(sp)
    8000324e:	6105                	addi	sp,sp,32
    80003250:	8082                	ret

0000000080003252 <bunpin>:

void
bunpin(struct buf *b) {
    80003252:	1101                	addi	sp,sp,-32
    80003254:	ec06                	sd	ra,24(sp)
    80003256:	e822                	sd	s0,16(sp)
    80003258:	e426                	sd	s1,8(sp)
    8000325a:	1000                	addi	s0,sp,32
    8000325c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000325e:	00014517          	auipc	a0,0x14
    80003262:	39a50513          	addi	a0,a0,922 # 800175f8 <bcache>
    80003266:	ffffe097          	auipc	ra,0xffffe
    8000326a:	97e080e7          	jalr	-1666(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000326e:	40bc                	lw	a5,64(s1)
    80003270:	37fd                	addiw	a5,a5,-1
    80003272:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003274:	00014517          	auipc	a0,0x14
    80003278:	38450513          	addi	a0,a0,900 # 800175f8 <bcache>
    8000327c:	ffffe097          	auipc	ra,0xffffe
    80003280:	a1c080e7          	jalr	-1508(ra) # 80000c98 <release>
}
    80003284:	60e2                	ld	ra,24(sp)
    80003286:	6442                	ld	s0,16(sp)
    80003288:	64a2                	ld	s1,8(sp)
    8000328a:	6105                	addi	sp,sp,32
    8000328c:	8082                	ret

000000008000328e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000328e:	1101                	addi	sp,sp,-32
    80003290:	ec06                	sd	ra,24(sp)
    80003292:	e822                	sd	s0,16(sp)
    80003294:	e426                	sd	s1,8(sp)
    80003296:	e04a                	sd	s2,0(sp)
    80003298:	1000                	addi	s0,sp,32
    8000329a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000329c:	00d5d59b          	srliw	a1,a1,0xd
    800032a0:	0001d797          	auipc	a5,0x1d
    800032a4:	a347a783          	lw	a5,-1484(a5) # 8001fcd4 <sb+0x1c>
    800032a8:	9dbd                	addw	a1,a1,a5
    800032aa:	00000097          	auipc	ra,0x0
    800032ae:	d9e080e7          	jalr	-610(ra) # 80003048 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800032b2:	0074f713          	andi	a4,s1,7
    800032b6:	4785                	li	a5,1
    800032b8:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800032bc:	14ce                	slli	s1,s1,0x33
    800032be:	90d9                	srli	s1,s1,0x36
    800032c0:	00950733          	add	a4,a0,s1
    800032c4:	05874703          	lbu	a4,88(a4)
    800032c8:	00e7f6b3          	and	a3,a5,a4
    800032cc:	c69d                	beqz	a3,800032fa <bfree+0x6c>
    800032ce:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800032d0:	94aa                	add	s1,s1,a0
    800032d2:	fff7c793          	not	a5,a5
    800032d6:	8ff9                	and	a5,a5,a4
    800032d8:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800032dc:	00001097          	auipc	ra,0x1
    800032e0:	118080e7          	jalr	280(ra) # 800043f4 <log_write>
  brelse(bp);
    800032e4:	854a                	mv	a0,s2
    800032e6:	00000097          	auipc	ra,0x0
    800032ea:	e92080e7          	jalr	-366(ra) # 80003178 <brelse>
}
    800032ee:	60e2                	ld	ra,24(sp)
    800032f0:	6442                	ld	s0,16(sp)
    800032f2:	64a2                	ld	s1,8(sp)
    800032f4:	6902                	ld	s2,0(sp)
    800032f6:	6105                	addi	sp,sp,32
    800032f8:	8082                	ret
    panic("freeing free block");
    800032fa:	00005517          	auipc	a0,0x5
    800032fe:	2ee50513          	addi	a0,a0,750 # 800085e8 <syscalls+0xf8>
    80003302:	ffffd097          	auipc	ra,0xffffd
    80003306:	23c080e7          	jalr	572(ra) # 8000053e <panic>

000000008000330a <balloc>:
{
    8000330a:	711d                	addi	sp,sp,-96
    8000330c:	ec86                	sd	ra,88(sp)
    8000330e:	e8a2                	sd	s0,80(sp)
    80003310:	e4a6                	sd	s1,72(sp)
    80003312:	e0ca                	sd	s2,64(sp)
    80003314:	fc4e                	sd	s3,56(sp)
    80003316:	f852                	sd	s4,48(sp)
    80003318:	f456                	sd	s5,40(sp)
    8000331a:	f05a                	sd	s6,32(sp)
    8000331c:	ec5e                	sd	s7,24(sp)
    8000331e:	e862                	sd	s8,16(sp)
    80003320:	e466                	sd	s9,8(sp)
    80003322:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003324:	0001d797          	auipc	a5,0x1d
    80003328:	9987a783          	lw	a5,-1640(a5) # 8001fcbc <sb+0x4>
    8000332c:	cbd1                	beqz	a5,800033c0 <balloc+0xb6>
    8000332e:	8baa                	mv	s7,a0
    80003330:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003332:	0001db17          	auipc	s6,0x1d
    80003336:	986b0b13          	addi	s6,s6,-1658 # 8001fcb8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000333a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000333c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000333e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003340:	6c89                	lui	s9,0x2
    80003342:	a831                	j	8000335e <balloc+0x54>
    brelse(bp);
    80003344:	854a                	mv	a0,s2
    80003346:	00000097          	auipc	ra,0x0
    8000334a:	e32080e7          	jalr	-462(ra) # 80003178 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000334e:	015c87bb          	addw	a5,s9,s5
    80003352:	00078a9b          	sext.w	s5,a5
    80003356:	004b2703          	lw	a4,4(s6)
    8000335a:	06eaf363          	bgeu	s5,a4,800033c0 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000335e:	41fad79b          	sraiw	a5,s5,0x1f
    80003362:	0137d79b          	srliw	a5,a5,0x13
    80003366:	015787bb          	addw	a5,a5,s5
    8000336a:	40d7d79b          	sraiw	a5,a5,0xd
    8000336e:	01cb2583          	lw	a1,28(s6)
    80003372:	9dbd                	addw	a1,a1,a5
    80003374:	855e                	mv	a0,s7
    80003376:	00000097          	auipc	ra,0x0
    8000337a:	cd2080e7          	jalr	-814(ra) # 80003048 <bread>
    8000337e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003380:	004b2503          	lw	a0,4(s6)
    80003384:	000a849b          	sext.w	s1,s5
    80003388:	8662                	mv	a2,s8
    8000338a:	faa4fde3          	bgeu	s1,a0,80003344 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000338e:	41f6579b          	sraiw	a5,a2,0x1f
    80003392:	01d7d69b          	srliw	a3,a5,0x1d
    80003396:	00c6873b          	addw	a4,a3,a2
    8000339a:	00777793          	andi	a5,a4,7
    8000339e:	9f95                	subw	a5,a5,a3
    800033a0:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800033a4:	4037571b          	sraiw	a4,a4,0x3
    800033a8:	00e906b3          	add	a3,s2,a4
    800033ac:	0586c683          	lbu	a3,88(a3)
    800033b0:	00d7f5b3          	and	a1,a5,a3
    800033b4:	cd91                	beqz	a1,800033d0 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033b6:	2605                	addiw	a2,a2,1
    800033b8:	2485                	addiw	s1,s1,1
    800033ba:	fd4618e3          	bne	a2,s4,8000338a <balloc+0x80>
    800033be:	b759                	j	80003344 <balloc+0x3a>
  panic("balloc: out of blocks");
    800033c0:	00005517          	auipc	a0,0x5
    800033c4:	24050513          	addi	a0,a0,576 # 80008600 <syscalls+0x110>
    800033c8:	ffffd097          	auipc	ra,0xffffd
    800033cc:	176080e7          	jalr	374(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800033d0:	974a                	add	a4,a4,s2
    800033d2:	8fd5                	or	a5,a5,a3
    800033d4:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800033d8:	854a                	mv	a0,s2
    800033da:	00001097          	auipc	ra,0x1
    800033de:	01a080e7          	jalr	26(ra) # 800043f4 <log_write>
        brelse(bp);
    800033e2:	854a                	mv	a0,s2
    800033e4:	00000097          	auipc	ra,0x0
    800033e8:	d94080e7          	jalr	-620(ra) # 80003178 <brelse>
  bp = bread(dev, bno);
    800033ec:	85a6                	mv	a1,s1
    800033ee:	855e                	mv	a0,s7
    800033f0:	00000097          	auipc	ra,0x0
    800033f4:	c58080e7          	jalr	-936(ra) # 80003048 <bread>
    800033f8:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800033fa:	40000613          	li	a2,1024
    800033fe:	4581                	li	a1,0
    80003400:	05850513          	addi	a0,a0,88
    80003404:	ffffe097          	auipc	ra,0xffffe
    80003408:	8dc080e7          	jalr	-1828(ra) # 80000ce0 <memset>
  log_write(bp);
    8000340c:	854a                	mv	a0,s2
    8000340e:	00001097          	auipc	ra,0x1
    80003412:	fe6080e7          	jalr	-26(ra) # 800043f4 <log_write>
  brelse(bp);
    80003416:	854a                	mv	a0,s2
    80003418:	00000097          	auipc	ra,0x0
    8000341c:	d60080e7          	jalr	-672(ra) # 80003178 <brelse>
}
    80003420:	8526                	mv	a0,s1
    80003422:	60e6                	ld	ra,88(sp)
    80003424:	6446                	ld	s0,80(sp)
    80003426:	64a6                	ld	s1,72(sp)
    80003428:	6906                	ld	s2,64(sp)
    8000342a:	79e2                	ld	s3,56(sp)
    8000342c:	7a42                	ld	s4,48(sp)
    8000342e:	7aa2                	ld	s5,40(sp)
    80003430:	7b02                	ld	s6,32(sp)
    80003432:	6be2                	ld	s7,24(sp)
    80003434:	6c42                	ld	s8,16(sp)
    80003436:	6ca2                	ld	s9,8(sp)
    80003438:	6125                	addi	sp,sp,96
    8000343a:	8082                	ret

000000008000343c <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000343c:	7179                	addi	sp,sp,-48
    8000343e:	f406                	sd	ra,40(sp)
    80003440:	f022                	sd	s0,32(sp)
    80003442:	ec26                	sd	s1,24(sp)
    80003444:	e84a                	sd	s2,16(sp)
    80003446:	e44e                	sd	s3,8(sp)
    80003448:	e052                	sd	s4,0(sp)
    8000344a:	1800                	addi	s0,sp,48
    8000344c:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000344e:	47ad                	li	a5,11
    80003450:	04b7fe63          	bgeu	a5,a1,800034ac <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003454:	ff45849b          	addiw	s1,a1,-12
    80003458:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000345c:	0ff00793          	li	a5,255
    80003460:	0ae7e363          	bltu	a5,a4,80003506 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003464:	08052583          	lw	a1,128(a0)
    80003468:	c5ad                	beqz	a1,800034d2 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000346a:	00092503          	lw	a0,0(s2)
    8000346e:	00000097          	auipc	ra,0x0
    80003472:	bda080e7          	jalr	-1062(ra) # 80003048 <bread>
    80003476:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003478:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000347c:	02049593          	slli	a1,s1,0x20
    80003480:	9181                	srli	a1,a1,0x20
    80003482:	058a                	slli	a1,a1,0x2
    80003484:	00b784b3          	add	s1,a5,a1
    80003488:	0004a983          	lw	s3,0(s1)
    8000348c:	04098d63          	beqz	s3,800034e6 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003490:	8552                	mv	a0,s4
    80003492:	00000097          	auipc	ra,0x0
    80003496:	ce6080e7          	jalr	-794(ra) # 80003178 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000349a:	854e                	mv	a0,s3
    8000349c:	70a2                	ld	ra,40(sp)
    8000349e:	7402                	ld	s0,32(sp)
    800034a0:	64e2                	ld	s1,24(sp)
    800034a2:	6942                	ld	s2,16(sp)
    800034a4:	69a2                	ld	s3,8(sp)
    800034a6:	6a02                	ld	s4,0(sp)
    800034a8:	6145                	addi	sp,sp,48
    800034aa:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800034ac:	02059493          	slli	s1,a1,0x20
    800034b0:	9081                	srli	s1,s1,0x20
    800034b2:	048a                	slli	s1,s1,0x2
    800034b4:	94aa                	add	s1,s1,a0
    800034b6:	0504a983          	lw	s3,80(s1)
    800034ba:	fe0990e3          	bnez	s3,8000349a <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800034be:	4108                	lw	a0,0(a0)
    800034c0:	00000097          	auipc	ra,0x0
    800034c4:	e4a080e7          	jalr	-438(ra) # 8000330a <balloc>
    800034c8:	0005099b          	sext.w	s3,a0
    800034cc:	0534a823          	sw	s3,80(s1)
    800034d0:	b7e9                	j	8000349a <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800034d2:	4108                	lw	a0,0(a0)
    800034d4:	00000097          	auipc	ra,0x0
    800034d8:	e36080e7          	jalr	-458(ra) # 8000330a <balloc>
    800034dc:	0005059b          	sext.w	a1,a0
    800034e0:	08b92023          	sw	a1,128(s2)
    800034e4:	b759                	j	8000346a <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800034e6:	00092503          	lw	a0,0(s2)
    800034ea:	00000097          	auipc	ra,0x0
    800034ee:	e20080e7          	jalr	-480(ra) # 8000330a <balloc>
    800034f2:	0005099b          	sext.w	s3,a0
    800034f6:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800034fa:	8552                	mv	a0,s4
    800034fc:	00001097          	auipc	ra,0x1
    80003500:	ef8080e7          	jalr	-264(ra) # 800043f4 <log_write>
    80003504:	b771                	j	80003490 <bmap+0x54>
  panic("bmap: out of range");
    80003506:	00005517          	auipc	a0,0x5
    8000350a:	11250513          	addi	a0,a0,274 # 80008618 <syscalls+0x128>
    8000350e:	ffffd097          	auipc	ra,0xffffd
    80003512:	030080e7          	jalr	48(ra) # 8000053e <panic>

0000000080003516 <iget>:
{
    80003516:	7179                	addi	sp,sp,-48
    80003518:	f406                	sd	ra,40(sp)
    8000351a:	f022                	sd	s0,32(sp)
    8000351c:	ec26                	sd	s1,24(sp)
    8000351e:	e84a                	sd	s2,16(sp)
    80003520:	e44e                	sd	s3,8(sp)
    80003522:	e052                	sd	s4,0(sp)
    80003524:	1800                	addi	s0,sp,48
    80003526:	89aa                	mv	s3,a0
    80003528:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000352a:	0001c517          	auipc	a0,0x1c
    8000352e:	7ae50513          	addi	a0,a0,1966 # 8001fcd8 <itable>
    80003532:	ffffd097          	auipc	ra,0xffffd
    80003536:	6b2080e7          	jalr	1714(ra) # 80000be4 <acquire>
  empty = 0;
    8000353a:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000353c:	0001c497          	auipc	s1,0x1c
    80003540:	7b448493          	addi	s1,s1,1972 # 8001fcf0 <itable+0x18>
    80003544:	0001e697          	auipc	a3,0x1e
    80003548:	23c68693          	addi	a3,a3,572 # 80021780 <log>
    8000354c:	a039                	j	8000355a <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000354e:	02090b63          	beqz	s2,80003584 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003552:	08848493          	addi	s1,s1,136
    80003556:	02d48a63          	beq	s1,a3,8000358a <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000355a:	449c                	lw	a5,8(s1)
    8000355c:	fef059e3          	blez	a5,8000354e <iget+0x38>
    80003560:	4098                	lw	a4,0(s1)
    80003562:	ff3716e3          	bne	a4,s3,8000354e <iget+0x38>
    80003566:	40d8                	lw	a4,4(s1)
    80003568:	ff4713e3          	bne	a4,s4,8000354e <iget+0x38>
      ip->ref++;
    8000356c:	2785                	addiw	a5,a5,1
    8000356e:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003570:	0001c517          	auipc	a0,0x1c
    80003574:	76850513          	addi	a0,a0,1896 # 8001fcd8 <itable>
    80003578:	ffffd097          	auipc	ra,0xffffd
    8000357c:	720080e7          	jalr	1824(ra) # 80000c98 <release>
      return ip;
    80003580:	8926                	mv	s2,s1
    80003582:	a03d                	j	800035b0 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003584:	f7f9                	bnez	a5,80003552 <iget+0x3c>
    80003586:	8926                	mv	s2,s1
    80003588:	b7e9                	j	80003552 <iget+0x3c>
  if(empty == 0)
    8000358a:	02090c63          	beqz	s2,800035c2 <iget+0xac>
  ip->dev = dev;
    8000358e:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003592:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003596:	4785                	li	a5,1
    80003598:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000359c:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800035a0:	0001c517          	auipc	a0,0x1c
    800035a4:	73850513          	addi	a0,a0,1848 # 8001fcd8 <itable>
    800035a8:	ffffd097          	auipc	ra,0xffffd
    800035ac:	6f0080e7          	jalr	1776(ra) # 80000c98 <release>
}
    800035b0:	854a                	mv	a0,s2
    800035b2:	70a2                	ld	ra,40(sp)
    800035b4:	7402                	ld	s0,32(sp)
    800035b6:	64e2                	ld	s1,24(sp)
    800035b8:	6942                	ld	s2,16(sp)
    800035ba:	69a2                	ld	s3,8(sp)
    800035bc:	6a02                	ld	s4,0(sp)
    800035be:	6145                	addi	sp,sp,48
    800035c0:	8082                	ret
    panic("iget: no inodes");
    800035c2:	00005517          	auipc	a0,0x5
    800035c6:	06e50513          	addi	a0,a0,110 # 80008630 <syscalls+0x140>
    800035ca:	ffffd097          	auipc	ra,0xffffd
    800035ce:	f74080e7          	jalr	-140(ra) # 8000053e <panic>

00000000800035d2 <fsinit>:
fsinit(int dev) {
    800035d2:	7179                	addi	sp,sp,-48
    800035d4:	f406                	sd	ra,40(sp)
    800035d6:	f022                	sd	s0,32(sp)
    800035d8:	ec26                	sd	s1,24(sp)
    800035da:	e84a                	sd	s2,16(sp)
    800035dc:	e44e                	sd	s3,8(sp)
    800035de:	1800                	addi	s0,sp,48
    800035e0:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800035e2:	4585                	li	a1,1
    800035e4:	00000097          	auipc	ra,0x0
    800035e8:	a64080e7          	jalr	-1436(ra) # 80003048 <bread>
    800035ec:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800035ee:	0001c997          	auipc	s3,0x1c
    800035f2:	6ca98993          	addi	s3,s3,1738 # 8001fcb8 <sb>
    800035f6:	02000613          	li	a2,32
    800035fa:	05850593          	addi	a1,a0,88
    800035fe:	854e                	mv	a0,s3
    80003600:	ffffd097          	auipc	ra,0xffffd
    80003604:	740080e7          	jalr	1856(ra) # 80000d40 <memmove>
  brelse(bp);
    80003608:	8526                	mv	a0,s1
    8000360a:	00000097          	auipc	ra,0x0
    8000360e:	b6e080e7          	jalr	-1170(ra) # 80003178 <brelse>
  if(sb.magic != FSMAGIC)
    80003612:	0009a703          	lw	a4,0(s3)
    80003616:	102037b7          	lui	a5,0x10203
    8000361a:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000361e:	02f71263          	bne	a4,a5,80003642 <fsinit+0x70>
  initlog(dev, &sb);
    80003622:	0001c597          	auipc	a1,0x1c
    80003626:	69658593          	addi	a1,a1,1686 # 8001fcb8 <sb>
    8000362a:	854a                	mv	a0,s2
    8000362c:	00001097          	auipc	ra,0x1
    80003630:	b4c080e7          	jalr	-1204(ra) # 80004178 <initlog>
}
    80003634:	70a2                	ld	ra,40(sp)
    80003636:	7402                	ld	s0,32(sp)
    80003638:	64e2                	ld	s1,24(sp)
    8000363a:	6942                	ld	s2,16(sp)
    8000363c:	69a2                	ld	s3,8(sp)
    8000363e:	6145                	addi	sp,sp,48
    80003640:	8082                	ret
    panic("invalid file system");
    80003642:	00005517          	auipc	a0,0x5
    80003646:	ffe50513          	addi	a0,a0,-2 # 80008640 <syscalls+0x150>
    8000364a:	ffffd097          	auipc	ra,0xffffd
    8000364e:	ef4080e7          	jalr	-268(ra) # 8000053e <panic>

0000000080003652 <iinit>:
{
    80003652:	7179                	addi	sp,sp,-48
    80003654:	f406                	sd	ra,40(sp)
    80003656:	f022                	sd	s0,32(sp)
    80003658:	ec26                	sd	s1,24(sp)
    8000365a:	e84a                	sd	s2,16(sp)
    8000365c:	e44e                	sd	s3,8(sp)
    8000365e:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003660:	00005597          	auipc	a1,0x5
    80003664:	ff858593          	addi	a1,a1,-8 # 80008658 <syscalls+0x168>
    80003668:	0001c517          	auipc	a0,0x1c
    8000366c:	67050513          	addi	a0,a0,1648 # 8001fcd8 <itable>
    80003670:	ffffd097          	auipc	ra,0xffffd
    80003674:	4e4080e7          	jalr	1252(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003678:	0001c497          	auipc	s1,0x1c
    8000367c:	68848493          	addi	s1,s1,1672 # 8001fd00 <itable+0x28>
    80003680:	0001e997          	auipc	s3,0x1e
    80003684:	11098993          	addi	s3,s3,272 # 80021790 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003688:	00005917          	auipc	s2,0x5
    8000368c:	fd890913          	addi	s2,s2,-40 # 80008660 <syscalls+0x170>
    80003690:	85ca                	mv	a1,s2
    80003692:	8526                	mv	a0,s1
    80003694:	00001097          	auipc	ra,0x1
    80003698:	e46080e7          	jalr	-442(ra) # 800044da <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000369c:	08848493          	addi	s1,s1,136
    800036a0:	ff3498e3          	bne	s1,s3,80003690 <iinit+0x3e>
}
    800036a4:	70a2                	ld	ra,40(sp)
    800036a6:	7402                	ld	s0,32(sp)
    800036a8:	64e2                	ld	s1,24(sp)
    800036aa:	6942                	ld	s2,16(sp)
    800036ac:	69a2                	ld	s3,8(sp)
    800036ae:	6145                	addi	sp,sp,48
    800036b0:	8082                	ret

00000000800036b2 <ialloc>:
{
    800036b2:	715d                	addi	sp,sp,-80
    800036b4:	e486                	sd	ra,72(sp)
    800036b6:	e0a2                	sd	s0,64(sp)
    800036b8:	fc26                	sd	s1,56(sp)
    800036ba:	f84a                	sd	s2,48(sp)
    800036bc:	f44e                	sd	s3,40(sp)
    800036be:	f052                	sd	s4,32(sp)
    800036c0:	ec56                	sd	s5,24(sp)
    800036c2:	e85a                	sd	s6,16(sp)
    800036c4:	e45e                	sd	s7,8(sp)
    800036c6:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800036c8:	0001c717          	auipc	a4,0x1c
    800036cc:	5fc72703          	lw	a4,1532(a4) # 8001fcc4 <sb+0xc>
    800036d0:	4785                	li	a5,1
    800036d2:	04e7fa63          	bgeu	a5,a4,80003726 <ialloc+0x74>
    800036d6:	8aaa                	mv	s5,a0
    800036d8:	8bae                	mv	s7,a1
    800036da:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800036dc:	0001ca17          	auipc	s4,0x1c
    800036e0:	5dca0a13          	addi	s4,s4,1500 # 8001fcb8 <sb>
    800036e4:	00048b1b          	sext.w	s6,s1
    800036e8:	0044d593          	srli	a1,s1,0x4
    800036ec:	018a2783          	lw	a5,24(s4)
    800036f0:	9dbd                	addw	a1,a1,a5
    800036f2:	8556                	mv	a0,s5
    800036f4:	00000097          	auipc	ra,0x0
    800036f8:	954080e7          	jalr	-1708(ra) # 80003048 <bread>
    800036fc:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800036fe:	05850993          	addi	s3,a0,88
    80003702:	00f4f793          	andi	a5,s1,15
    80003706:	079a                	slli	a5,a5,0x6
    80003708:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000370a:	00099783          	lh	a5,0(s3)
    8000370e:	c785                	beqz	a5,80003736 <ialloc+0x84>
    brelse(bp);
    80003710:	00000097          	auipc	ra,0x0
    80003714:	a68080e7          	jalr	-1432(ra) # 80003178 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003718:	0485                	addi	s1,s1,1
    8000371a:	00ca2703          	lw	a4,12(s4)
    8000371e:	0004879b          	sext.w	a5,s1
    80003722:	fce7e1e3          	bltu	a5,a4,800036e4 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003726:	00005517          	auipc	a0,0x5
    8000372a:	f4250513          	addi	a0,a0,-190 # 80008668 <syscalls+0x178>
    8000372e:	ffffd097          	auipc	ra,0xffffd
    80003732:	e10080e7          	jalr	-496(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003736:	04000613          	li	a2,64
    8000373a:	4581                	li	a1,0
    8000373c:	854e                	mv	a0,s3
    8000373e:	ffffd097          	auipc	ra,0xffffd
    80003742:	5a2080e7          	jalr	1442(ra) # 80000ce0 <memset>
      dip->type = type;
    80003746:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000374a:	854a                	mv	a0,s2
    8000374c:	00001097          	auipc	ra,0x1
    80003750:	ca8080e7          	jalr	-856(ra) # 800043f4 <log_write>
      brelse(bp);
    80003754:	854a                	mv	a0,s2
    80003756:	00000097          	auipc	ra,0x0
    8000375a:	a22080e7          	jalr	-1502(ra) # 80003178 <brelse>
      return iget(dev, inum);
    8000375e:	85da                	mv	a1,s6
    80003760:	8556                	mv	a0,s5
    80003762:	00000097          	auipc	ra,0x0
    80003766:	db4080e7          	jalr	-588(ra) # 80003516 <iget>
}
    8000376a:	60a6                	ld	ra,72(sp)
    8000376c:	6406                	ld	s0,64(sp)
    8000376e:	74e2                	ld	s1,56(sp)
    80003770:	7942                	ld	s2,48(sp)
    80003772:	79a2                	ld	s3,40(sp)
    80003774:	7a02                	ld	s4,32(sp)
    80003776:	6ae2                	ld	s5,24(sp)
    80003778:	6b42                	ld	s6,16(sp)
    8000377a:	6ba2                	ld	s7,8(sp)
    8000377c:	6161                	addi	sp,sp,80
    8000377e:	8082                	ret

0000000080003780 <iupdate>:
{
    80003780:	1101                	addi	sp,sp,-32
    80003782:	ec06                	sd	ra,24(sp)
    80003784:	e822                	sd	s0,16(sp)
    80003786:	e426                	sd	s1,8(sp)
    80003788:	e04a                	sd	s2,0(sp)
    8000378a:	1000                	addi	s0,sp,32
    8000378c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000378e:	415c                	lw	a5,4(a0)
    80003790:	0047d79b          	srliw	a5,a5,0x4
    80003794:	0001c597          	auipc	a1,0x1c
    80003798:	53c5a583          	lw	a1,1340(a1) # 8001fcd0 <sb+0x18>
    8000379c:	9dbd                	addw	a1,a1,a5
    8000379e:	4108                	lw	a0,0(a0)
    800037a0:	00000097          	auipc	ra,0x0
    800037a4:	8a8080e7          	jalr	-1880(ra) # 80003048 <bread>
    800037a8:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037aa:	05850793          	addi	a5,a0,88
    800037ae:	40c8                	lw	a0,4(s1)
    800037b0:	893d                	andi	a0,a0,15
    800037b2:	051a                	slli	a0,a0,0x6
    800037b4:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800037b6:	04449703          	lh	a4,68(s1)
    800037ba:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800037be:	04649703          	lh	a4,70(s1)
    800037c2:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800037c6:	04849703          	lh	a4,72(s1)
    800037ca:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800037ce:	04a49703          	lh	a4,74(s1)
    800037d2:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800037d6:	44f8                	lw	a4,76(s1)
    800037d8:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800037da:	03400613          	li	a2,52
    800037de:	05048593          	addi	a1,s1,80
    800037e2:	0531                	addi	a0,a0,12
    800037e4:	ffffd097          	auipc	ra,0xffffd
    800037e8:	55c080e7          	jalr	1372(ra) # 80000d40 <memmove>
  log_write(bp);
    800037ec:	854a                	mv	a0,s2
    800037ee:	00001097          	auipc	ra,0x1
    800037f2:	c06080e7          	jalr	-1018(ra) # 800043f4 <log_write>
  brelse(bp);
    800037f6:	854a                	mv	a0,s2
    800037f8:	00000097          	auipc	ra,0x0
    800037fc:	980080e7          	jalr	-1664(ra) # 80003178 <brelse>
}
    80003800:	60e2                	ld	ra,24(sp)
    80003802:	6442                	ld	s0,16(sp)
    80003804:	64a2                	ld	s1,8(sp)
    80003806:	6902                	ld	s2,0(sp)
    80003808:	6105                	addi	sp,sp,32
    8000380a:	8082                	ret

000000008000380c <idup>:
{
    8000380c:	1101                	addi	sp,sp,-32
    8000380e:	ec06                	sd	ra,24(sp)
    80003810:	e822                	sd	s0,16(sp)
    80003812:	e426                	sd	s1,8(sp)
    80003814:	1000                	addi	s0,sp,32
    80003816:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003818:	0001c517          	auipc	a0,0x1c
    8000381c:	4c050513          	addi	a0,a0,1216 # 8001fcd8 <itable>
    80003820:	ffffd097          	auipc	ra,0xffffd
    80003824:	3c4080e7          	jalr	964(ra) # 80000be4 <acquire>
  ip->ref++;
    80003828:	449c                	lw	a5,8(s1)
    8000382a:	2785                	addiw	a5,a5,1
    8000382c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000382e:	0001c517          	auipc	a0,0x1c
    80003832:	4aa50513          	addi	a0,a0,1194 # 8001fcd8 <itable>
    80003836:	ffffd097          	auipc	ra,0xffffd
    8000383a:	462080e7          	jalr	1122(ra) # 80000c98 <release>
}
    8000383e:	8526                	mv	a0,s1
    80003840:	60e2                	ld	ra,24(sp)
    80003842:	6442                	ld	s0,16(sp)
    80003844:	64a2                	ld	s1,8(sp)
    80003846:	6105                	addi	sp,sp,32
    80003848:	8082                	ret

000000008000384a <ilock>:
{
    8000384a:	1101                	addi	sp,sp,-32
    8000384c:	ec06                	sd	ra,24(sp)
    8000384e:	e822                	sd	s0,16(sp)
    80003850:	e426                	sd	s1,8(sp)
    80003852:	e04a                	sd	s2,0(sp)
    80003854:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003856:	c115                	beqz	a0,8000387a <ilock+0x30>
    80003858:	84aa                	mv	s1,a0
    8000385a:	451c                	lw	a5,8(a0)
    8000385c:	00f05f63          	blez	a5,8000387a <ilock+0x30>
  acquiresleep(&ip->lock);
    80003860:	0541                	addi	a0,a0,16
    80003862:	00001097          	auipc	ra,0x1
    80003866:	cb2080e7          	jalr	-846(ra) # 80004514 <acquiresleep>
  if(ip->valid == 0){
    8000386a:	40bc                	lw	a5,64(s1)
    8000386c:	cf99                	beqz	a5,8000388a <ilock+0x40>
}
    8000386e:	60e2                	ld	ra,24(sp)
    80003870:	6442                	ld	s0,16(sp)
    80003872:	64a2                	ld	s1,8(sp)
    80003874:	6902                	ld	s2,0(sp)
    80003876:	6105                	addi	sp,sp,32
    80003878:	8082                	ret
    panic("ilock");
    8000387a:	00005517          	auipc	a0,0x5
    8000387e:	e0650513          	addi	a0,a0,-506 # 80008680 <syscalls+0x190>
    80003882:	ffffd097          	auipc	ra,0xffffd
    80003886:	cbc080e7          	jalr	-836(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000388a:	40dc                	lw	a5,4(s1)
    8000388c:	0047d79b          	srliw	a5,a5,0x4
    80003890:	0001c597          	auipc	a1,0x1c
    80003894:	4405a583          	lw	a1,1088(a1) # 8001fcd0 <sb+0x18>
    80003898:	9dbd                	addw	a1,a1,a5
    8000389a:	4088                	lw	a0,0(s1)
    8000389c:	fffff097          	auipc	ra,0xfffff
    800038a0:	7ac080e7          	jalr	1964(ra) # 80003048 <bread>
    800038a4:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038a6:	05850593          	addi	a1,a0,88
    800038aa:	40dc                	lw	a5,4(s1)
    800038ac:	8bbd                	andi	a5,a5,15
    800038ae:	079a                	slli	a5,a5,0x6
    800038b0:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800038b2:	00059783          	lh	a5,0(a1)
    800038b6:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800038ba:	00259783          	lh	a5,2(a1)
    800038be:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800038c2:	00459783          	lh	a5,4(a1)
    800038c6:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800038ca:	00659783          	lh	a5,6(a1)
    800038ce:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800038d2:	459c                	lw	a5,8(a1)
    800038d4:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800038d6:	03400613          	li	a2,52
    800038da:	05b1                	addi	a1,a1,12
    800038dc:	05048513          	addi	a0,s1,80
    800038e0:	ffffd097          	auipc	ra,0xffffd
    800038e4:	460080e7          	jalr	1120(ra) # 80000d40 <memmove>
    brelse(bp);
    800038e8:	854a                	mv	a0,s2
    800038ea:	00000097          	auipc	ra,0x0
    800038ee:	88e080e7          	jalr	-1906(ra) # 80003178 <brelse>
    ip->valid = 1;
    800038f2:	4785                	li	a5,1
    800038f4:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800038f6:	04449783          	lh	a5,68(s1)
    800038fa:	fbb5                	bnez	a5,8000386e <ilock+0x24>
      panic("ilock: no type");
    800038fc:	00005517          	auipc	a0,0x5
    80003900:	d8c50513          	addi	a0,a0,-628 # 80008688 <syscalls+0x198>
    80003904:	ffffd097          	auipc	ra,0xffffd
    80003908:	c3a080e7          	jalr	-966(ra) # 8000053e <panic>

000000008000390c <iunlock>:
{
    8000390c:	1101                	addi	sp,sp,-32
    8000390e:	ec06                	sd	ra,24(sp)
    80003910:	e822                	sd	s0,16(sp)
    80003912:	e426                	sd	s1,8(sp)
    80003914:	e04a                	sd	s2,0(sp)
    80003916:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003918:	c905                	beqz	a0,80003948 <iunlock+0x3c>
    8000391a:	84aa                	mv	s1,a0
    8000391c:	01050913          	addi	s2,a0,16
    80003920:	854a                	mv	a0,s2
    80003922:	00001097          	auipc	ra,0x1
    80003926:	c8c080e7          	jalr	-884(ra) # 800045ae <holdingsleep>
    8000392a:	cd19                	beqz	a0,80003948 <iunlock+0x3c>
    8000392c:	449c                	lw	a5,8(s1)
    8000392e:	00f05d63          	blez	a5,80003948 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003932:	854a                	mv	a0,s2
    80003934:	00001097          	auipc	ra,0x1
    80003938:	c36080e7          	jalr	-970(ra) # 8000456a <releasesleep>
}
    8000393c:	60e2                	ld	ra,24(sp)
    8000393e:	6442                	ld	s0,16(sp)
    80003940:	64a2                	ld	s1,8(sp)
    80003942:	6902                	ld	s2,0(sp)
    80003944:	6105                	addi	sp,sp,32
    80003946:	8082                	ret
    panic("iunlock");
    80003948:	00005517          	auipc	a0,0x5
    8000394c:	d5050513          	addi	a0,a0,-688 # 80008698 <syscalls+0x1a8>
    80003950:	ffffd097          	auipc	ra,0xffffd
    80003954:	bee080e7          	jalr	-1042(ra) # 8000053e <panic>

0000000080003958 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003958:	7179                	addi	sp,sp,-48
    8000395a:	f406                	sd	ra,40(sp)
    8000395c:	f022                	sd	s0,32(sp)
    8000395e:	ec26                	sd	s1,24(sp)
    80003960:	e84a                	sd	s2,16(sp)
    80003962:	e44e                	sd	s3,8(sp)
    80003964:	e052                	sd	s4,0(sp)
    80003966:	1800                	addi	s0,sp,48
    80003968:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000396a:	05050493          	addi	s1,a0,80
    8000396e:	08050913          	addi	s2,a0,128
    80003972:	a021                	j	8000397a <itrunc+0x22>
    80003974:	0491                	addi	s1,s1,4
    80003976:	01248d63          	beq	s1,s2,80003990 <itrunc+0x38>
    if(ip->addrs[i]){
    8000397a:	408c                	lw	a1,0(s1)
    8000397c:	dde5                	beqz	a1,80003974 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000397e:	0009a503          	lw	a0,0(s3)
    80003982:	00000097          	auipc	ra,0x0
    80003986:	90c080e7          	jalr	-1780(ra) # 8000328e <bfree>
      ip->addrs[i] = 0;
    8000398a:	0004a023          	sw	zero,0(s1)
    8000398e:	b7dd                	j	80003974 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003990:	0809a583          	lw	a1,128(s3)
    80003994:	e185                	bnez	a1,800039b4 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003996:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000399a:	854e                	mv	a0,s3
    8000399c:	00000097          	auipc	ra,0x0
    800039a0:	de4080e7          	jalr	-540(ra) # 80003780 <iupdate>
}
    800039a4:	70a2                	ld	ra,40(sp)
    800039a6:	7402                	ld	s0,32(sp)
    800039a8:	64e2                	ld	s1,24(sp)
    800039aa:	6942                	ld	s2,16(sp)
    800039ac:	69a2                	ld	s3,8(sp)
    800039ae:	6a02                	ld	s4,0(sp)
    800039b0:	6145                	addi	sp,sp,48
    800039b2:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800039b4:	0009a503          	lw	a0,0(s3)
    800039b8:	fffff097          	auipc	ra,0xfffff
    800039bc:	690080e7          	jalr	1680(ra) # 80003048 <bread>
    800039c0:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800039c2:	05850493          	addi	s1,a0,88
    800039c6:	45850913          	addi	s2,a0,1112
    800039ca:	a811                	j	800039de <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800039cc:	0009a503          	lw	a0,0(s3)
    800039d0:	00000097          	auipc	ra,0x0
    800039d4:	8be080e7          	jalr	-1858(ra) # 8000328e <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800039d8:	0491                	addi	s1,s1,4
    800039da:	01248563          	beq	s1,s2,800039e4 <itrunc+0x8c>
      if(a[j])
    800039de:	408c                	lw	a1,0(s1)
    800039e0:	dde5                	beqz	a1,800039d8 <itrunc+0x80>
    800039e2:	b7ed                	j	800039cc <itrunc+0x74>
    brelse(bp);
    800039e4:	8552                	mv	a0,s4
    800039e6:	fffff097          	auipc	ra,0xfffff
    800039ea:	792080e7          	jalr	1938(ra) # 80003178 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800039ee:	0809a583          	lw	a1,128(s3)
    800039f2:	0009a503          	lw	a0,0(s3)
    800039f6:	00000097          	auipc	ra,0x0
    800039fa:	898080e7          	jalr	-1896(ra) # 8000328e <bfree>
    ip->addrs[NDIRECT] = 0;
    800039fe:	0809a023          	sw	zero,128(s3)
    80003a02:	bf51                	j	80003996 <itrunc+0x3e>

0000000080003a04 <iput>:
{
    80003a04:	1101                	addi	sp,sp,-32
    80003a06:	ec06                	sd	ra,24(sp)
    80003a08:	e822                	sd	s0,16(sp)
    80003a0a:	e426                	sd	s1,8(sp)
    80003a0c:	e04a                	sd	s2,0(sp)
    80003a0e:	1000                	addi	s0,sp,32
    80003a10:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a12:	0001c517          	auipc	a0,0x1c
    80003a16:	2c650513          	addi	a0,a0,710 # 8001fcd8 <itable>
    80003a1a:	ffffd097          	auipc	ra,0xffffd
    80003a1e:	1ca080e7          	jalr	458(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a22:	4498                	lw	a4,8(s1)
    80003a24:	4785                	li	a5,1
    80003a26:	02f70363          	beq	a4,a5,80003a4c <iput+0x48>
  ip->ref--;
    80003a2a:	449c                	lw	a5,8(s1)
    80003a2c:	37fd                	addiw	a5,a5,-1
    80003a2e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a30:	0001c517          	auipc	a0,0x1c
    80003a34:	2a850513          	addi	a0,a0,680 # 8001fcd8 <itable>
    80003a38:	ffffd097          	auipc	ra,0xffffd
    80003a3c:	260080e7          	jalr	608(ra) # 80000c98 <release>
}
    80003a40:	60e2                	ld	ra,24(sp)
    80003a42:	6442                	ld	s0,16(sp)
    80003a44:	64a2                	ld	s1,8(sp)
    80003a46:	6902                	ld	s2,0(sp)
    80003a48:	6105                	addi	sp,sp,32
    80003a4a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a4c:	40bc                	lw	a5,64(s1)
    80003a4e:	dff1                	beqz	a5,80003a2a <iput+0x26>
    80003a50:	04a49783          	lh	a5,74(s1)
    80003a54:	fbf9                	bnez	a5,80003a2a <iput+0x26>
    acquiresleep(&ip->lock);
    80003a56:	01048913          	addi	s2,s1,16
    80003a5a:	854a                	mv	a0,s2
    80003a5c:	00001097          	auipc	ra,0x1
    80003a60:	ab8080e7          	jalr	-1352(ra) # 80004514 <acquiresleep>
    release(&itable.lock);
    80003a64:	0001c517          	auipc	a0,0x1c
    80003a68:	27450513          	addi	a0,a0,628 # 8001fcd8 <itable>
    80003a6c:	ffffd097          	auipc	ra,0xffffd
    80003a70:	22c080e7          	jalr	556(ra) # 80000c98 <release>
    itrunc(ip);
    80003a74:	8526                	mv	a0,s1
    80003a76:	00000097          	auipc	ra,0x0
    80003a7a:	ee2080e7          	jalr	-286(ra) # 80003958 <itrunc>
    ip->type = 0;
    80003a7e:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003a82:	8526                	mv	a0,s1
    80003a84:	00000097          	auipc	ra,0x0
    80003a88:	cfc080e7          	jalr	-772(ra) # 80003780 <iupdate>
    ip->valid = 0;
    80003a8c:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a90:	854a                	mv	a0,s2
    80003a92:	00001097          	auipc	ra,0x1
    80003a96:	ad8080e7          	jalr	-1320(ra) # 8000456a <releasesleep>
    acquire(&itable.lock);
    80003a9a:	0001c517          	auipc	a0,0x1c
    80003a9e:	23e50513          	addi	a0,a0,574 # 8001fcd8 <itable>
    80003aa2:	ffffd097          	auipc	ra,0xffffd
    80003aa6:	142080e7          	jalr	322(ra) # 80000be4 <acquire>
    80003aaa:	b741                	j	80003a2a <iput+0x26>

0000000080003aac <iunlockput>:
{
    80003aac:	1101                	addi	sp,sp,-32
    80003aae:	ec06                	sd	ra,24(sp)
    80003ab0:	e822                	sd	s0,16(sp)
    80003ab2:	e426                	sd	s1,8(sp)
    80003ab4:	1000                	addi	s0,sp,32
    80003ab6:	84aa                	mv	s1,a0
  iunlock(ip);
    80003ab8:	00000097          	auipc	ra,0x0
    80003abc:	e54080e7          	jalr	-428(ra) # 8000390c <iunlock>
  iput(ip);
    80003ac0:	8526                	mv	a0,s1
    80003ac2:	00000097          	auipc	ra,0x0
    80003ac6:	f42080e7          	jalr	-190(ra) # 80003a04 <iput>
}
    80003aca:	60e2                	ld	ra,24(sp)
    80003acc:	6442                	ld	s0,16(sp)
    80003ace:	64a2                	ld	s1,8(sp)
    80003ad0:	6105                	addi	sp,sp,32
    80003ad2:	8082                	ret

0000000080003ad4 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003ad4:	1141                	addi	sp,sp,-16
    80003ad6:	e422                	sd	s0,8(sp)
    80003ad8:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003ada:	411c                	lw	a5,0(a0)
    80003adc:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003ade:	415c                	lw	a5,4(a0)
    80003ae0:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003ae2:	04451783          	lh	a5,68(a0)
    80003ae6:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003aea:	04a51783          	lh	a5,74(a0)
    80003aee:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003af2:	04c56783          	lwu	a5,76(a0)
    80003af6:	e99c                	sd	a5,16(a1)
}
    80003af8:	6422                	ld	s0,8(sp)
    80003afa:	0141                	addi	sp,sp,16
    80003afc:	8082                	ret

0000000080003afe <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003afe:	457c                	lw	a5,76(a0)
    80003b00:	0ed7e963          	bltu	a5,a3,80003bf2 <readi+0xf4>
{
    80003b04:	7159                	addi	sp,sp,-112
    80003b06:	f486                	sd	ra,104(sp)
    80003b08:	f0a2                	sd	s0,96(sp)
    80003b0a:	eca6                	sd	s1,88(sp)
    80003b0c:	e8ca                	sd	s2,80(sp)
    80003b0e:	e4ce                	sd	s3,72(sp)
    80003b10:	e0d2                	sd	s4,64(sp)
    80003b12:	fc56                	sd	s5,56(sp)
    80003b14:	f85a                	sd	s6,48(sp)
    80003b16:	f45e                	sd	s7,40(sp)
    80003b18:	f062                	sd	s8,32(sp)
    80003b1a:	ec66                	sd	s9,24(sp)
    80003b1c:	e86a                	sd	s10,16(sp)
    80003b1e:	e46e                	sd	s11,8(sp)
    80003b20:	1880                	addi	s0,sp,112
    80003b22:	8baa                	mv	s7,a0
    80003b24:	8c2e                	mv	s8,a1
    80003b26:	8ab2                	mv	s5,a2
    80003b28:	84b6                	mv	s1,a3
    80003b2a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b2c:	9f35                	addw	a4,a4,a3
    return 0;
    80003b2e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003b30:	0ad76063          	bltu	a4,a3,80003bd0 <readi+0xd2>
  if(off + n > ip->size)
    80003b34:	00e7f463          	bgeu	a5,a4,80003b3c <readi+0x3e>
    n = ip->size - off;
    80003b38:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b3c:	0a0b0963          	beqz	s6,80003bee <readi+0xf0>
    80003b40:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b42:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003b46:	5cfd                	li	s9,-1
    80003b48:	a82d                	j	80003b82 <readi+0x84>
    80003b4a:	020a1d93          	slli	s11,s4,0x20
    80003b4e:	020ddd93          	srli	s11,s11,0x20
    80003b52:	05890613          	addi	a2,s2,88
    80003b56:	86ee                	mv	a3,s11
    80003b58:	963a                	add	a2,a2,a4
    80003b5a:	85d6                	mv	a1,s5
    80003b5c:	8562                	mv	a0,s8
    80003b5e:	fffff097          	auipc	ra,0xfffff
    80003b62:	ac4080e7          	jalr	-1340(ra) # 80002622 <either_copyout>
    80003b66:	05950d63          	beq	a0,s9,80003bc0 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003b6a:	854a                	mv	a0,s2
    80003b6c:	fffff097          	auipc	ra,0xfffff
    80003b70:	60c080e7          	jalr	1548(ra) # 80003178 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b74:	013a09bb          	addw	s3,s4,s3
    80003b78:	009a04bb          	addw	s1,s4,s1
    80003b7c:	9aee                	add	s5,s5,s11
    80003b7e:	0569f763          	bgeu	s3,s6,80003bcc <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b82:	000ba903          	lw	s2,0(s7)
    80003b86:	00a4d59b          	srliw	a1,s1,0xa
    80003b8a:	855e                	mv	a0,s7
    80003b8c:	00000097          	auipc	ra,0x0
    80003b90:	8b0080e7          	jalr	-1872(ra) # 8000343c <bmap>
    80003b94:	0005059b          	sext.w	a1,a0
    80003b98:	854a                	mv	a0,s2
    80003b9a:	fffff097          	auipc	ra,0xfffff
    80003b9e:	4ae080e7          	jalr	1198(ra) # 80003048 <bread>
    80003ba2:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ba4:	3ff4f713          	andi	a4,s1,1023
    80003ba8:	40ed07bb          	subw	a5,s10,a4
    80003bac:	413b06bb          	subw	a3,s6,s3
    80003bb0:	8a3e                	mv	s4,a5
    80003bb2:	2781                	sext.w	a5,a5
    80003bb4:	0006861b          	sext.w	a2,a3
    80003bb8:	f8f679e3          	bgeu	a2,a5,80003b4a <readi+0x4c>
    80003bbc:	8a36                	mv	s4,a3
    80003bbe:	b771                	j	80003b4a <readi+0x4c>
      brelse(bp);
    80003bc0:	854a                	mv	a0,s2
    80003bc2:	fffff097          	auipc	ra,0xfffff
    80003bc6:	5b6080e7          	jalr	1462(ra) # 80003178 <brelse>
      tot = -1;
    80003bca:	59fd                	li	s3,-1
  }
  return tot;
    80003bcc:	0009851b          	sext.w	a0,s3
}
    80003bd0:	70a6                	ld	ra,104(sp)
    80003bd2:	7406                	ld	s0,96(sp)
    80003bd4:	64e6                	ld	s1,88(sp)
    80003bd6:	6946                	ld	s2,80(sp)
    80003bd8:	69a6                	ld	s3,72(sp)
    80003bda:	6a06                	ld	s4,64(sp)
    80003bdc:	7ae2                	ld	s5,56(sp)
    80003bde:	7b42                	ld	s6,48(sp)
    80003be0:	7ba2                	ld	s7,40(sp)
    80003be2:	7c02                	ld	s8,32(sp)
    80003be4:	6ce2                	ld	s9,24(sp)
    80003be6:	6d42                	ld	s10,16(sp)
    80003be8:	6da2                	ld	s11,8(sp)
    80003bea:	6165                	addi	sp,sp,112
    80003bec:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bee:	89da                	mv	s3,s6
    80003bf0:	bff1                	j	80003bcc <readi+0xce>
    return 0;
    80003bf2:	4501                	li	a0,0
}
    80003bf4:	8082                	ret

0000000080003bf6 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003bf6:	457c                	lw	a5,76(a0)
    80003bf8:	10d7e863          	bltu	a5,a3,80003d08 <writei+0x112>
{
    80003bfc:	7159                	addi	sp,sp,-112
    80003bfe:	f486                	sd	ra,104(sp)
    80003c00:	f0a2                	sd	s0,96(sp)
    80003c02:	eca6                	sd	s1,88(sp)
    80003c04:	e8ca                	sd	s2,80(sp)
    80003c06:	e4ce                	sd	s3,72(sp)
    80003c08:	e0d2                	sd	s4,64(sp)
    80003c0a:	fc56                	sd	s5,56(sp)
    80003c0c:	f85a                	sd	s6,48(sp)
    80003c0e:	f45e                	sd	s7,40(sp)
    80003c10:	f062                	sd	s8,32(sp)
    80003c12:	ec66                	sd	s9,24(sp)
    80003c14:	e86a                	sd	s10,16(sp)
    80003c16:	e46e                	sd	s11,8(sp)
    80003c18:	1880                	addi	s0,sp,112
    80003c1a:	8b2a                	mv	s6,a0
    80003c1c:	8c2e                	mv	s8,a1
    80003c1e:	8ab2                	mv	s5,a2
    80003c20:	8936                	mv	s2,a3
    80003c22:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003c24:	00e687bb          	addw	a5,a3,a4
    80003c28:	0ed7e263          	bltu	a5,a3,80003d0c <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003c2c:	00043737          	lui	a4,0x43
    80003c30:	0ef76063          	bltu	a4,a5,80003d10 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c34:	0c0b8863          	beqz	s7,80003d04 <writei+0x10e>
    80003c38:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c3a:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003c3e:	5cfd                	li	s9,-1
    80003c40:	a091                	j	80003c84 <writei+0x8e>
    80003c42:	02099d93          	slli	s11,s3,0x20
    80003c46:	020ddd93          	srli	s11,s11,0x20
    80003c4a:	05848513          	addi	a0,s1,88
    80003c4e:	86ee                	mv	a3,s11
    80003c50:	8656                	mv	a2,s5
    80003c52:	85e2                	mv	a1,s8
    80003c54:	953a                	add	a0,a0,a4
    80003c56:	fffff097          	auipc	ra,0xfffff
    80003c5a:	a22080e7          	jalr	-1502(ra) # 80002678 <either_copyin>
    80003c5e:	07950263          	beq	a0,s9,80003cc2 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003c62:	8526                	mv	a0,s1
    80003c64:	00000097          	auipc	ra,0x0
    80003c68:	790080e7          	jalr	1936(ra) # 800043f4 <log_write>
    brelse(bp);
    80003c6c:	8526                	mv	a0,s1
    80003c6e:	fffff097          	auipc	ra,0xfffff
    80003c72:	50a080e7          	jalr	1290(ra) # 80003178 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c76:	01498a3b          	addw	s4,s3,s4
    80003c7a:	0129893b          	addw	s2,s3,s2
    80003c7e:	9aee                	add	s5,s5,s11
    80003c80:	057a7663          	bgeu	s4,s7,80003ccc <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c84:	000b2483          	lw	s1,0(s6)
    80003c88:	00a9559b          	srliw	a1,s2,0xa
    80003c8c:	855a                	mv	a0,s6
    80003c8e:	fffff097          	auipc	ra,0xfffff
    80003c92:	7ae080e7          	jalr	1966(ra) # 8000343c <bmap>
    80003c96:	0005059b          	sext.w	a1,a0
    80003c9a:	8526                	mv	a0,s1
    80003c9c:	fffff097          	auipc	ra,0xfffff
    80003ca0:	3ac080e7          	jalr	940(ra) # 80003048 <bread>
    80003ca4:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ca6:	3ff97713          	andi	a4,s2,1023
    80003caa:	40ed07bb          	subw	a5,s10,a4
    80003cae:	414b86bb          	subw	a3,s7,s4
    80003cb2:	89be                	mv	s3,a5
    80003cb4:	2781                	sext.w	a5,a5
    80003cb6:	0006861b          	sext.w	a2,a3
    80003cba:	f8f674e3          	bgeu	a2,a5,80003c42 <writei+0x4c>
    80003cbe:	89b6                	mv	s3,a3
    80003cc0:	b749                	j	80003c42 <writei+0x4c>
      brelse(bp);
    80003cc2:	8526                	mv	a0,s1
    80003cc4:	fffff097          	auipc	ra,0xfffff
    80003cc8:	4b4080e7          	jalr	1204(ra) # 80003178 <brelse>
  }

  if(off > ip->size)
    80003ccc:	04cb2783          	lw	a5,76(s6)
    80003cd0:	0127f463          	bgeu	a5,s2,80003cd8 <writei+0xe2>
    ip->size = off;
    80003cd4:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003cd8:	855a                	mv	a0,s6
    80003cda:	00000097          	auipc	ra,0x0
    80003cde:	aa6080e7          	jalr	-1370(ra) # 80003780 <iupdate>

  return tot;
    80003ce2:	000a051b          	sext.w	a0,s4
}
    80003ce6:	70a6                	ld	ra,104(sp)
    80003ce8:	7406                	ld	s0,96(sp)
    80003cea:	64e6                	ld	s1,88(sp)
    80003cec:	6946                	ld	s2,80(sp)
    80003cee:	69a6                	ld	s3,72(sp)
    80003cf0:	6a06                	ld	s4,64(sp)
    80003cf2:	7ae2                	ld	s5,56(sp)
    80003cf4:	7b42                	ld	s6,48(sp)
    80003cf6:	7ba2                	ld	s7,40(sp)
    80003cf8:	7c02                	ld	s8,32(sp)
    80003cfa:	6ce2                	ld	s9,24(sp)
    80003cfc:	6d42                	ld	s10,16(sp)
    80003cfe:	6da2                	ld	s11,8(sp)
    80003d00:	6165                	addi	sp,sp,112
    80003d02:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d04:	8a5e                	mv	s4,s7
    80003d06:	bfc9                	j	80003cd8 <writei+0xe2>
    return -1;
    80003d08:	557d                	li	a0,-1
}
    80003d0a:	8082                	ret
    return -1;
    80003d0c:	557d                	li	a0,-1
    80003d0e:	bfe1                	j	80003ce6 <writei+0xf0>
    return -1;
    80003d10:	557d                	li	a0,-1
    80003d12:	bfd1                	j	80003ce6 <writei+0xf0>

0000000080003d14 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003d14:	1141                	addi	sp,sp,-16
    80003d16:	e406                	sd	ra,8(sp)
    80003d18:	e022                	sd	s0,0(sp)
    80003d1a:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003d1c:	4639                	li	a2,14
    80003d1e:	ffffd097          	auipc	ra,0xffffd
    80003d22:	09a080e7          	jalr	154(ra) # 80000db8 <strncmp>
}
    80003d26:	60a2                	ld	ra,8(sp)
    80003d28:	6402                	ld	s0,0(sp)
    80003d2a:	0141                	addi	sp,sp,16
    80003d2c:	8082                	ret

0000000080003d2e <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003d2e:	7139                	addi	sp,sp,-64
    80003d30:	fc06                	sd	ra,56(sp)
    80003d32:	f822                	sd	s0,48(sp)
    80003d34:	f426                	sd	s1,40(sp)
    80003d36:	f04a                	sd	s2,32(sp)
    80003d38:	ec4e                	sd	s3,24(sp)
    80003d3a:	e852                	sd	s4,16(sp)
    80003d3c:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003d3e:	04451703          	lh	a4,68(a0)
    80003d42:	4785                	li	a5,1
    80003d44:	00f71a63          	bne	a4,a5,80003d58 <dirlookup+0x2a>
    80003d48:	892a                	mv	s2,a0
    80003d4a:	89ae                	mv	s3,a1
    80003d4c:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d4e:	457c                	lw	a5,76(a0)
    80003d50:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003d52:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d54:	e79d                	bnez	a5,80003d82 <dirlookup+0x54>
    80003d56:	a8a5                	j	80003dce <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003d58:	00005517          	auipc	a0,0x5
    80003d5c:	94850513          	addi	a0,a0,-1720 # 800086a0 <syscalls+0x1b0>
    80003d60:	ffffc097          	auipc	ra,0xffffc
    80003d64:	7de080e7          	jalr	2014(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003d68:	00005517          	auipc	a0,0x5
    80003d6c:	95050513          	addi	a0,a0,-1712 # 800086b8 <syscalls+0x1c8>
    80003d70:	ffffc097          	auipc	ra,0xffffc
    80003d74:	7ce080e7          	jalr	1998(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d78:	24c1                	addiw	s1,s1,16
    80003d7a:	04c92783          	lw	a5,76(s2)
    80003d7e:	04f4f763          	bgeu	s1,a5,80003dcc <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d82:	4741                	li	a4,16
    80003d84:	86a6                	mv	a3,s1
    80003d86:	fc040613          	addi	a2,s0,-64
    80003d8a:	4581                	li	a1,0
    80003d8c:	854a                	mv	a0,s2
    80003d8e:	00000097          	auipc	ra,0x0
    80003d92:	d70080e7          	jalr	-656(ra) # 80003afe <readi>
    80003d96:	47c1                	li	a5,16
    80003d98:	fcf518e3          	bne	a0,a5,80003d68 <dirlookup+0x3a>
    if(de.inum == 0)
    80003d9c:	fc045783          	lhu	a5,-64(s0)
    80003da0:	dfe1                	beqz	a5,80003d78 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003da2:	fc240593          	addi	a1,s0,-62
    80003da6:	854e                	mv	a0,s3
    80003da8:	00000097          	auipc	ra,0x0
    80003dac:	f6c080e7          	jalr	-148(ra) # 80003d14 <namecmp>
    80003db0:	f561                	bnez	a0,80003d78 <dirlookup+0x4a>
      if(poff)
    80003db2:	000a0463          	beqz	s4,80003dba <dirlookup+0x8c>
        *poff = off;
    80003db6:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003dba:	fc045583          	lhu	a1,-64(s0)
    80003dbe:	00092503          	lw	a0,0(s2)
    80003dc2:	fffff097          	auipc	ra,0xfffff
    80003dc6:	754080e7          	jalr	1876(ra) # 80003516 <iget>
    80003dca:	a011                	j	80003dce <dirlookup+0xa0>
  return 0;
    80003dcc:	4501                	li	a0,0
}
    80003dce:	70e2                	ld	ra,56(sp)
    80003dd0:	7442                	ld	s0,48(sp)
    80003dd2:	74a2                	ld	s1,40(sp)
    80003dd4:	7902                	ld	s2,32(sp)
    80003dd6:	69e2                	ld	s3,24(sp)
    80003dd8:	6a42                	ld	s4,16(sp)
    80003dda:	6121                	addi	sp,sp,64
    80003ddc:	8082                	ret

0000000080003dde <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003dde:	711d                	addi	sp,sp,-96
    80003de0:	ec86                	sd	ra,88(sp)
    80003de2:	e8a2                	sd	s0,80(sp)
    80003de4:	e4a6                	sd	s1,72(sp)
    80003de6:	e0ca                	sd	s2,64(sp)
    80003de8:	fc4e                	sd	s3,56(sp)
    80003dea:	f852                	sd	s4,48(sp)
    80003dec:	f456                	sd	s5,40(sp)
    80003dee:	f05a                	sd	s6,32(sp)
    80003df0:	ec5e                	sd	s7,24(sp)
    80003df2:	e862                	sd	s8,16(sp)
    80003df4:	e466                	sd	s9,8(sp)
    80003df6:	1080                	addi	s0,sp,96
    80003df8:	84aa                	mv	s1,a0
    80003dfa:	8b2e                	mv	s6,a1
    80003dfc:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003dfe:	00054703          	lbu	a4,0(a0)
    80003e02:	02f00793          	li	a5,47
    80003e06:	02f70363          	beq	a4,a5,80003e2c <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003e0a:	ffffe097          	auipc	ra,0xffffe
    80003e0e:	c82080e7          	jalr	-894(ra) # 80001a8c <myproc>
    80003e12:	15053503          	ld	a0,336(a0)
    80003e16:	00000097          	auipc	ra,0x0
    80003e1a:	9f6080e7          	jalr	-1546(ra) # 8000380c <idup>
    80003e1e:	89aa                	mv	s3,a0
  while(*path == '/')
    80003e20:	02f00913          	li	s2,47
  len = path - s;
    80003e24:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003e26:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003e28:	4c05                	li	s8,1
    80003e2a:	a865                	j	80003ee2 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003e2c:	4585                	li	a1,1
    80003e2e:	4505                	li	a0,1
    80003e30:	fffff097          	auipc	ra,0xfffff
    80003e34:	6e6080e7          	jalr	1766(ra) # 80003516 <iget>
    80003e38:	89aa                	mv	s3,a0
    80003e3a:	b7dd                	j	80003e20 <namex+0x42>
      iunlockput(ip);
    80003e3c:	854e                	mv	a0,s3
    80003e3e:	00000097          	auipc	ra,0x0
    80003e42:	c6e080e7          	jalr	-914(ra) # 80003aac <iunlockput>
      return 0;
    80003e46:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003e48:	854e                	mv	a0,s3
    80003e4a:	60e6                	ld	ra,88(sp)
    80003e4c:	6446                	ld	s0,80(sp)
    80003e4e:	64a6                	ld	s1,72(sp)
    80003e50:	6906                	ld	s2,64(sp)
    80003e52:	79e2                	ld	s3,56(sp)
    80003e54:	7a42                	ld	s4,48(sp)
    80003e56:	7aa2                	ld	s5,40(sp)
    80003e58:	7b02                	ld	s6,32(sp)
    80003e5a:	6be2                	ld	s7,24(sp)
    80003e5c:	6c42                	ld	s8,16(sp)
    80003e5e:	6ca2                	ld	s9,8(sp)
    80003e60:	6125                	addi	sp,sp,96
    80003e62:	8082                	ret
      iunlock(ip);
    80003e64:	854e                	mv	a0,s3
    80003e66:	00000097          	auipc	ra,0x0
    80003e6a:	aa6080e7          	jalr	-1370(ra) # 8000390c <iunlock>
      return ip;
    80003e6e:	bfe9                	j	80003e48 <namex+0x6a>
      iunlockput(ip);
    80003e70:	854e                	mv	a0,s3
    80003e72:	00000097          	auipc	ra,0x0
    80003e76:	c3a080e7          	jalr	-966(ra) # 80003aac <iunlockput>
      return 0;
    80003e7a:	89d2                	mv	s3,s4
    80003e7c:	b7f1                	j	80003e48 <namex+0x6a>
  len = path - s;
    80003e7e:	40b48633          	sub	a2,s1,a1
    80003e82:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003e86:	094cd463          	bge	s9,s4,80003f0e <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003e8a:	4639                	li	a2,14
    80003e8c:	8556                	mv	a0,s5
    80003e8e:	ffffd097          	auipc	ra,0xffffd
    80003e92:	eb2080e7          	jalr	-334(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003e96:	0004c783          	lbu	a5,0(s1)
    80003e9a:	01279763          	bne	a5,s2,80003ea8 <namex+0xca>
    path++;
    80003e9e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003ea0:	0004c783          	lbu	a5,0(s1)
    80003ea4:	ff278de3          	beq	a5,s2,80003e9e <namex+0xc0>
    ilock(ip);
    80003ea8:	854e                	mv	a0,s3
    80003eaa:	00000097          	auipc	ra,0x0
    80003eae:	9a0080e7          	jalr	-1632(ra) # 8000384a <ilock>
    if(ip->type != T_DIR){
    80003eb2:	04499783          	lh	a5,68(s3)
    80003eb6:	f98793e3          	bne	a5,s8,80003e3c <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003eba:	000b0563          	beqz	s6,80003ec4 <namex+0xe6>
    80003ebe:	0004c783          	lbu	a5,0(s1)
    80003ec2:	d3cd                	beqz	a5,80003e64 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003ec4:	865e                	mv	a2,s7
    80003ec6:	85d6                	mv	a1,s5
    80003ec8:	854e                	mv	a0,s3
    80003eca:	00000097          	auipc	ra,0x0
    80003ece:	e64080e7          	jalr	-412(ra) # 80003d2e <dirlookup>
    80003ed2:	8a2a                	mv	s4,a0
    80003ed4:	dd51                	beqz	a0,80003e70 <namex+0x92>
    iunlockput(ip);
    80003ed6:	854e                	mv	a0,s3
    80003ed8:	00000097          	auipc	ra,0x0
    80003edc:	bd4080e7          	jalr	-1068(ra) # 80003aac <iunlockput>
    ip = next;
    80003ee0:	89d2                	mv	s3,s4
  while(*path == '/')
    80003ee2:	0004c783          	lbu	a5,0(s1)
    80003ee6:	05279763          	bne	a5,s2,80003f34 <namex+0x156>
    path++;
    80003eea:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003eec:	0004c783          	lbu	a5,0(s1)
    80003ef0:	ff278de3          	beq	a5,s2,80003eea <namex+0x10c>
  if(*path == 0)
    80003ef4:	c79d                	beqz	a5,80003f22 <namex+0x144>
    path++;
    80003ef6:	85a6                	mv	a1,s1
  len = path - s;
    80003ef8:	8a5e                	mv	s4,s7
    80003efa:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003efc:	01278963          	beq	a5,s2,80003f0e <namex+0x130>
    80003f00:	dfbd                	beqz	a5,80003e7e <namex+0xa0>
    path++;
    80003f02:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003f04:	0004c783          	lbu	a5,0(s1)
    80003f08:	ff279ce3          	bne	a5,s2,80003f00 <namex+0x122>
    80003f0c:	bf8d                	j	80003e7e <namex+0xa0>
    memmove(name, s, len);
    80003f0e:	2601                	sext.w	a2,a2
    80003f10:	8556                	mv	a0,s5
    80003f12:	ffffd097          	auipc	ra,0xffffd
    80003f16:	e2e080e7          	jalr	-466(ra) # 80000d40 <memmove>
    name[len] = 0;
    80003f1a:	9a56                	add	s4,s4,s5
    80003f1c:	000a0023          	sb	zero,0(s4)
    80003f20:	bf9d                	j	80003e96 <namex+0xb8>
  if(nameiparent){
    80003f22:	f20b03e3          	beqz	s6,80003e48 <namex+0x6a>
    iput(ip);
    80003f26:	854e                	mv	a0,s3
    80003f28:	00000097          	auipc	ra,0x0
    80003f2c:	adc080e7          	jalr	-1316(ra) # 80003a04 <iput>
    return 0;
    80003f30:	4981                	li	s3,0
    80003f32:	bf19                	j	80003e48 <namex+0x6a>
  if(*path == 0)
    80003f34:	d7fd                	beqz	a5,80003f22 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003f36:	0004c783          	lbu	a5,0(s1)
    80003f3a:	85a6                	mv	a1,s1
    80003f3c:	b7d1                	j	80003f00 <namex+0x122>

0000000080003f3e <dirlink>:
{
    80003f3e:	7139                	addi	sp,sp,-64
    80003f40:	fc06                	sd	ra,56(sp)
    80003f42:	f822                	sd	s0,48(sp)
    80003f44:	f426                	sd	s1,40(sp)
    80003f46:	f04a                	sd	s2,32(sp)
    80003f48:	ec4e                	sd	s3,24(sp)
    80003f4a:	e852                	sd	s4,16(sp)
    80003f4c:	0080                	addi	s0,sp,64
    80003f4e:	892a                	mv	s2,a0
    80003f50:	8a2e                	mv	s4,a1
    80003f52:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003f54:	4601                	li	a2,0
    80003f56:	00000097          	auipc	ra,0x0
    80003f5a:	dd8080e7          	jalr	-552(ra) # 80003d2e <dirlookup>
    80003f5e:	e93d                	bnez	a0,80003fd4 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f60:	04c92483          	lw	s1,76(s2)
    80003f64:	c49d                	beqz	s1,80003f92 <dirlink+0x54>
    80003f66:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f68:	4741                	li	a4,16
    80003f6a:	86a6                	mv	a3,s1
    80003f6c:	fc040613          	addi	a2,s0,-64
    80003f70:	4581                	li	a1,0
    80003f72:	854a                	mv	a0,s2
    80003f74:	00000097          	auipc	ra,0x0
    80003f78:	b8a080e7          	jalr	-1142(ra) # 80003afe <readi>
    80003f7c:	47c1                	li	a5,16
    80003f7e:	06f51163          	bne	a0,a5,80003fe0 <dirlink+0xa2>
    if(de.inum == 0)
    80003f82:	fc045783          	lhu	a5,-64(s0)
    80003f86:	c791                	beqz	a5,80003f92 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f88:	24c1                	addiw	s1,s1,16
    80003f8a:	04c92783          	lw	a5,76(s2)
    80003f8e:	fcf4ede3          	bltu	s1,a5,80003f68 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f92:	4639                	li	a2,14
    80003f94:	85d2                	mv	a1,s4
    80003f96:	fc240513          	addi	a0,s0,-62
    80003f9a:	ffffd097          	auipc	ra,0xffffd
    80003f9e:	e5a080e7          	jalr	-422(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80003fa2:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fa6:	4741                	li	a4,16
    80003fa8:	86a6                	mv	a3,s1
    80003faa:	fc040613          	addi	a2,s0,-64
    80003fae:	4581                	li	a1,0
    80003fb0:	854a                	mv	a0,s2
    80003fb2:	00000097          	auipc	ra,0x0
    80003fb6:	c44080e7          	jalr	-956(ra) # 80003bf6 <writei>
    80003fba:	872a                	mv	a4,a0
    80003fbc:	47c1                	li	a5,16
  return 0;
    80003fbe:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fc0:	02f71863          	bne	a4,a5,80003ff0 <dirlink+0xb2>
}
    80003fc4:	70e2                	ld	ra,56(sp)
    80003fc6:	7442                	ld	s0,48(sp)
    80003fc8:	74a2                	ld	s1,40(sp)
    80003fca:	7902                	ld	s2,32(sp)
    80003fcc:	69e2                	ld	s3,24(sp)
    80003fce:	6a42                	ld	s4,16(sp)
    80003fd0:	6121                	addi	sp,sp,64
    80003fd2:	8082                	ret
    iput(ip);
    80003fd4:	00000097          	auipc	ra,0x0
    80003fd8:	a30080e7          	jalr	-1488(ra) # 80003a04 <iput>
    return -1;
    80003fdc:	557d                	li	a0,-1
    80003fde:	b7dd                	j	80003fc4 <dirlink+0x86>
      panic("dirlink read");
    80003fe0:	00004517          	auipc	a0,0x4
    80003fe4:	6e850513          	addi	a0,a0,1768 # 800086c8 <syscalls+0x1d8>
    80003fe8:	ffffc097          	auipc	ra,0xffffc
    80003fec:	556080e7          	jalr	1366(ra) # 8000053e <panic>
    panic("dirlink");
    80003ff0:	00004517          	auipc	a0,0x4
    80003ff4:	7e850513          	addi	a0,a0,2024 # 800087d8 <syscalls+0x2e8>
    80003ff8:	ffffc097          	auipc	ra,0xffffc
    80003ffc:	546080e7          	jalr	1350(ra) # 8000053e <panic>

0000000080004000 <namei>:

struct inode*
namei(char *path)
{
    80004000:	1101                	addi	sp,sp,-32
    80004002:	ec06                	sd	ra,24(sp)
    80004004:	e822                	sd	s0,16(sp)
    80004006:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004008:	fe040613          	addi	a2,s0,-32
    8000400c:	4581                	li	a1,0
    8000400e:	00000097          	auipc	ra,0x0
    80004012:	dd0080e7          	jalr	-560(ra) # 80003dde <namex>
}
    80004016:	60e2                	ld	ra,24(sp)
    80004018:	6442                	ld	s0,16(sp)
    8000401a:	6105                	addi	sp,sp,32
    8000401c:	8082                	ret

000000008000401e <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000401e:	1141                	addi	sp,sp,-16
    80004020:	e406                	sd	ra,8(sp)
    80004022:	e022                	sd	s0,0(sp)
    80004024:	0800                	addi	s0,sp,16
    80004026:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004028:	4585                	li	a1,1
    8000402a:	00000097          	auipc	ra,0x0
    8000402e:	db4080e7          	jalr	-588(ra) # 80003dde <namex>
}
    80004032:	60a2                	ld	ra,8(sp)
    80004034:	6402                	ld	s0,0(sp)
    80004036:	0141                	addi	sp,sp,16
    80004038:	8082                	ret

000000008000403a <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000403a:	1101                	addi	sp,sp,-32
    8000403c:	ec06                	sd	ra,24(sp)
    8000403e:	e822                	sd	s0,16(sp)
    80004040:	e426                	sd	s1,8(sp)
    80004042:	e04a                	sd	s2,0(sp)
    80004044:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004046:	0001d917          	auipc	s2,0x1d
    8000404a:	73a90913          	addi	s2,s2,1850 # 80021780 <log>
    8000404e:	01892583          	lw	a1,24(s2)
    80004052:	02892503          	lw	a0,40(s2)
    80004056:	fffff097          	auipc	ra,0xfffff
    8000405a:	ff2080e7          	jalr	-14(ra) # 80003048 <bread>
    8000405e:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004060:	02c92683          	lw	a3,44(s2)
    80004064:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004066:	02d05763          	blez	a3,80004094 <write_head+0x5a>
    8000406a:	0001d797          	auipc	a5,0x1d
    8000406e:	74678793          	addi	a5,a5,1862 # 800217b0 <log+0x30>
    80004072:	05c50713          	addi	a4,a0,92
    80004076:	36fd                	addiw	a3,a3,-1
    80004078:	1682                	slli	a3,a3,0x20
    8000407a:	9281                	srli	a3,a3,0x20
    8000407c:	068a                	slli	a3,a3,0x2
    8000407e:	0001d617          	auipc	a2,0x1d
    80004082:	73660613          	addi	a2,a2,1846 # 800217b4 <log+0x34>
    80004086:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004088:	4390                	lw	a2,0(a5)
    8000408a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000408c:	0791                	addi	a5,a5,4
    8000408e:	0711                	addi	a4,a4,4
    80004090:	fed79ce3          	bne	a5,a3,80004088 <write_head+0x4e>
  }
  bwrite(buf);
    80004094:	8526                	mv	a0,s1
    80004096:	fffff097          	auipc	ra,0xfffff
    8000409a:	0a4080e7          	jalr	164(ra) # 8000313a <bwrite>
  brelse(buf);
    8000409e:	8526                	mv	a0,s1
    800040a0:	fffff097          	auipc	ra,0xfffff
    800040a4:	0d8080e7          	jalr	216(ra) # 80003178 <brelse>
}
    800040a8:	60e2                	ld	ra,24(sp)
    800040aa:	6442                	ld	s0,16(sp)
    800040ac:	64a2                	ld	s1,8(sp)
    800040ae:	6902                	ld	s2,0(sp)
    800040b0:	6105                	addi	sp,sp,32
    800040b2:	8082                	ret

00000000800040b4 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800040b4:	0001d797          	auipc	a5,0x1d
    800040b8:	6f87a783          	lw	a5,1784(a5) # 800217ac <log+0x2c>
    800040bc:	0af05d63          	blez	a5,80004176 <install_trans+0xc2>
{
    800040c0:	7139                	addi	sp,sp,-64
    800040c2:	fc06                	sd	ra,56(sp)
    800040c4:	f822                	sd	s0,48(sp)
    800040c6:	f426                	sd	s1,40(sp)
    800040c8:	f04a                	sd	s2,32(sp)
    800040ca:	ec4e                	sd	s3,24(sp)
    800040cc:	e852                	sd	s4,16(sp)
    800040ce:	e456                	sd	s5,8(sp)
    800040d0:	e05a                	sd	s6,0(sp)
    800040d2:	0080                	addi	s0,sp,64
    800040d4:	8b2a                	mv	s6,a0
    800040d6:	0001da97          	auipc	s5,0x1d
    800040da:	6daa8a93          	addi	s5,s5,1754 # 800217b0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040de:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800040e0:	0001d997          	auipc	s3,0x1d
    800040e4:	6a098993          	addi	s3,s3,1696 # 80021780 <log>
    800040e8:	a035                	j	80004114 <install_trans+0x60>
      bunpin(dbuf);
    800040ea:	8526                	mv	a0,s1
    800040ec:	fffff097          	auipc	ra,0xfffff
    800040f0:	166080e7          	jalr	358(ra) # 80003252 <bunpin>
    brelse(lbuf);
    800040f4:	854a                	mv	a0,s2
    800040f6:	fffff097          	auipc	ra,0xfffff
    800040fa:	082080e7          	jalr	130(ra) # 80003178 <brelse>
    brelse(dbuf);
    800040fe:	8526                	mv	a0,s1
    80004100:	fffff097          	auipc	ra,0xfffff
    80004104:	078080e7          	jalr	120(ra) # 80003178 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004108:	2a05                	addiw	s4,s4,1
    8000410a:	0a91                	addi	s5,s5,4
    8000410c:	02c9a783          	lw	a5,44(s3)
    80004110:	04fa5963          	bge	s4,a5,80004162 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004114:	0189a583          	lw	a1,24(s3)
    80004118:	014585bb          	addw	a1,a1,s4
    8000411c:	2585                	addiw	a1,a1,1
    8000411e:	0289a503          	lw	a0,40(s3)
    80004122:	fffff097          	auipc	ra,0xfffff
    80004126:	f26080e7          	jalr	-218(ra) # 80003048 <bread>
    8000412a:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000412c:	000aa583          	lw	a1,0(s5)
    80004130:	0289a503          	lw	a0,40(s3)
    80004134:	fffff097          	auipc	ra,0xfffff
    80004138:	f14080e7          	jalr	-236(ra) # 80003048 <bread>
    8000413c:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000413e:	40000613          	li	a2,1024
    80004142:	05890593          	addi	a1,s2,88
    80004146:	05850513          	addi	a0,a0,88
    8000414a:	ffffd097          	auipc	ra,0xffffd
    8000414e:	bf6080e7          	jalr	-1034(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004152:	8526                	mv	a0,s1
    80004154:	fffff097          	auipc	ra,0xfffff
    80004158:	fe6080e7          	jalr	-26(ra) # 8000313a <bwrite>
    if(recovering == 0)
    8000415c:	f80b1ce3          	bnez	s6,800040f4 <install_trans+0x40>
    80004160:	b769                	j	800040ea <install_trans+0x36>
}
    80004162:	70e2                	ld	ra,56(sp)
    80004164:	7442                	ld	s0,48(sp)
    80004166:	74a2                	ld	s1,40(sp)
    80004168:	7902                	ld	s2,32(sp)
    8000416a:	69e2                	ld	s3,24(sp)
    8000416c:	6a42                	ld	s4,16(sp)
    8000416e:	6aa2                	ld	s5,8(sp)
    80004170:	6b02                	ld	s6,0(sp)
    80004172:	6121                	addi	sp,sp,64
    80004174:	8082                	ret
    80004176:	8082                	ret

0000000080004178 <initlog>:
{
    80004178:	7179                	addi	sp,sp,-48
    8000417a:	f406                	sd	ra,40(sp)
    8000417c:	f022                	sd	s0,32(sp)
    8000417e:	ec26                	sd	s1,24(sp)
    80004180:	e84a                	sd	s2,16(sp)
    80004182:	e44e                	sd	s3,8(sp)
    80004184:	1800                	addi	s0,sp,48
    80004186:	892a                	mv	s2,a0
    80004188:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000418a:	0001d497          	auipc	s1,0x1d
    8000418e:	5f648493          	addi	s1,s1,1526 # 80021780 <log>
    80004192:	00004597          	auipc	a1,0x4
    80004196:	54658593          	addi	a1,a1,1350 # 800086d8 <syscalls+0x1e8>
    8000419a:	8526                	mv	a0,s1
    8000419c:	ffffd097          	auipc	ra,0xffffd
    800041a0:	9b8080e7          	jalr	-1608(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    800041a4:	0149a583          	lw	a1,20(s3)
    800041a8:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800041aa:	0109a783          	lw	a5,16(s3)
    800041ae:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800041b0:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800041b4:	854a                	mv	a0,s2
    800041b6:	fffff097          	auipc	ra,0xfffff
    800041ba:	e92080e7          	jalr	-366(ra) # 80003048 <bread>
  log.lh.n = lh->n;
    800041be:	4d3c                	lw	a5,88(a0)
    800041c0:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800041c2:	02f05563          	blez	a5,800041ec <initlog+0x74>
    800041c6:	05c50713          	addi	a4,a0,92
    800041ca:	0001d697          	auipc	a3,0x1d
    800041ce:	5e668693          	addi	a3,a3,1510 # 800217b0 <log+0x30>
    800041d2:	37fd                	addiw	a5,a5,-1
    800041d4:	1782                	slli	a5,a5,0x20
    800041d6:	9381                	srli	a5,a5,0x20
    800041d8:	078a                	slli	a5,a5,0x2
    800041da:	06050613          	addi	a2,a0,96
    800041de:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800041e0:	4310                	lw	a2,0(a4)
    800041e2:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800041e4:	0711                	addi	a4,a4,4
    800041e6:	0691                	addi	a3,a3,4
    800041e8:	fef71ce3          	bne	a4,a5,800041e0 <initlog+0x68>
  brelse(buf);
    800041ec:	fffff097          	auipc	ra,0xfffff
    800041f0:	f8c080e7          	jalr	-116(ra) # 80003178 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800041f4:	4505                	li	a0,1
    800041f6:	00000097          	auipc	ra,0x0
    800041fa:	ebe080e7          	jalr	-322(ra) # 800040b4 <install_trans>
  log.lh.n = 0;
    800041fe:	0001d797          	auipc	a5,0x1d
    80004202:	5a07a723          	sw	zero,1454(a5) # 800217ac <log+0x2c>
  write_head(); // clear the log
    80004206:	00000097          	auipc	ra,0x0
    8000420a:	e34080e7          	jalr	-460(ra) # 8000403a <write_head>
}
    8000420e:	70a2                	ld	ra,40(sp)
    80004210:	7402                	ld	s0,32(sp)
    80004212:	64e2                	ld	s1,24(sp)
    80004214:	6942                	ld	s2,16(sp)
    80004216:	69a2                	ld	s3,8(sp)
    80004218:	6145                	addi	sp,sp,48
    8000421a:	8082                	ret

000000008000421c <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000421c:	1101                	addi	sp,sp,-32
    8000421e:	ec06                	sd	ra,24(sp)
    80004220:	e822                	sd	s0,16(sp)
    80004222:	e426                	sd	s1,8(sp)
    80004224:	e04a                	sd	s2,0(sp)
    80004226:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004228:	0001d517          	auipc	a0,0x1d
    8000422c:	55850513          	addi	a0,a0,1368 # 80021780 <log>
    80004230:	ffffd097          	auipc	ra,0xffffd
    80004234:	9b4080e7          	jalr	-1612(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004238:	0001d497          	auipc	s1,0x1d
    8000423c:	54848493          	addi	s1,s1,1352 # 80021780 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004240:	4979                	li	s2,30
    80004242:	a039                	j	80004250 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004244:	85a6                	mv	a1,s1
    80004246:	8526                	mv	a0,s1
    80004248:	ffffe097          	auipc	ra,0xffffe
    8000424c:	036080e7          	jalr	54(ra) # 8000227e <sleep>
    if(log.committing){
    80004250:	50dc                	lw	a5,36(s1)
    80004252:	fbed                	bnez	a5,80004244 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004254:	509c                	lw	a5,32(s1)
    80004256:	0017871b          	addiw	a4,a5,1
    8000425a:	0007069b          	sext.w	a3,a4
    8000425e:	0027179b          	slliw	a5,a4,0x2
    80004262:	9fb9                	addw	a5,a5,a4
    80004264:	0017979b          	slliw	a5,a5,0x1
    80004268:	54d8                	lw	a4,44(s1)
    8000426a:	9fb9                	addw	a5,a5,a4
    8000426c:	00f95963          	bge	s2,a5,8000427e <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004270:	85a6                	mv	a1,s1
    80004272:	8526                	mv	a0,s1
    80004274:	ffffe097          	auipc	ra,0xffffe
    80004278:	00a080e7          	jalr	10(ra) # 8000227e <sleep>
    8000427c:	bfd1                	j	80004250 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000427e:	0001d517          	auipc	a0,0x1d
    80004282:	50250513          	addi	a0,a0,1282 # 80021780 <log>
    80004286:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004288:	ffffd097          	auipc	ra,0xffffd
    8000428c:	a10080e7          	jalr	-1520(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004290:	60e2                	ld	ra,24(sp)
    80004292:	6442                	ld	s0,16(sp)
    80004294:	64a2                	ld	s1,8(sp)
    80004296:	6902                	ld	s2,0(sp)
    80004298:	6105                	addi	sp,sp,32
    8000429a:	8082                	ret

000000008000429c <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000429c:	7139                	addi	sp,sp,-64
    8000429e:	fc06                	sd	ra,56(sp)
    800042a0:	f822                	sd	s0,48(sp)
    800042a2:	f426                	sd	s1,40(sp)
    800042a4:	f04a                	sd	s2,32(sp)
    800042a6:	ec4e                	sd	s3,24(sp)
    800042a8:	e852                	sd	s4,16(sp)
    800042aa:	e456                	sd	s5,8(sp)
    800042ac:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800042ae:	0001d497          	auipc	s1,0x1d
    800042b2:	4d248493          	addi	s1,s1,1234 # 80021780 <log>
    800042b6:	8526                	mv	a0,s1
    800042b8:	ffffd097          	auipc	ra,0xffffd
    800042bc:	92c080e7          	jalr	-1748(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    800042c0:	509c                	lw	a5,32(s1)
    800042c2:	37fd                	addiw	a5,a5,-1
    800042c4:	0007891b          	sext.w	s2,a5
    800042c8:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800042ca:	50dc                	lw	a5,36(s1)
    800042cc:	efb9                	bnez	a5,8000432a <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800042ce:	06091663          	bnez	s2,8000433a <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800042d2:	0001d497          	auipc	s1,0x1d
    800042d6:	4ae48493          	addi	s1,s1,1198 # 80021780 <log>
    800042da:	4785                	li	a5,1
    800042dc:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800042de:	8526                	mv	a0,s1
    800042e0:	ffffd097          	auipc	ra,0xffffd
    800042e4:	9b8080e7          	jalr	-1608(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800042e8:	54dc                	lw	a5,44(s1)
    800042ea:	06f04763          	bgtz	a5,80004358 <end_op+0xbc>
    acquire(&log.lock);
    800042ee:	0001d497          	auipc	s1,0x1d
    800042f2:	49248493          	addi	s1,s1,1170 # 80021780 <log>
    800042f6:	8526                	mv	a0,s1
    800042f8:	ffffd097          	auipc	ra,0xffffd
    800042fc:	8ec080e7          	jalr	-1812(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004300:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004304:	8526                	mv	a0,s1
    80004306:	ffffe097          	auipc	ra,0xffffe
    8000430a:	104080e7          	jalr	260(ra) # 8000240a <wakeup>
    release(&log.lock);
    8000430e:	8526                	mv	a0,s1
    80004310:	ffffd097          	auipc	ra,0xffffd
    80004314:	988080e7          	jalr	-1656(ra) # 80000c98 <release>
}
    80004318:	70e2                	ld	ra,56(sp)
    8000431a:	7442                	ld	s0,48(sp)
    8000431c:	74a2                	ld	s1,40(sp)
    8000431e:	7902                	ld	s2,32(sp)
    80004320:	69e2                	ld	s3,24(sp)
    80004322:	6a42                	ld	s4,16(sp)
    80004324:	6aa2                	ld	s5,8(sp)
    80004326:	6121                	addi	sp,sp,64
    80004328:	8082                	ret
    panic("log.committing");
    8000432a:	00004517          	auipc	a0,0x4
    8000432e:	3b650513          	addi	a0,a0,950 # 800086e0 <syscalls+0x1f0>
    80004332:	ffffc097          	auipc	ra,0xffffc
    80004336:	20c080e7          	jalr	524(ra) # 8000053e <panic>
    wakeup(&log);
    8000433a:	0001d497          	auipc	s1,0x1d
    8000433e:	44648493          	addi	s1,s1,1094 # 80021780 <log>
    80004342:	8526                	mv	a0,s1
    80004344:	ffffe097          	auipc	ra,0xffffe
    80004348:	0c6080e7          	jalr	198(ra) # 8000240a <wakeup>
  release(&log.lock);
    8000434c:	8526                	mv	a0,s1
    8000434e:	ffffd097          	auipc	ra,0xffffd
    80004352:	94a080e7          	jalr	-1718(ra) # 80000c98 <release>
  if(do_commit){
    80004356:	b7c9                	j	80004318 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004358:	0001da97          	auipc	s5,0x1d
    8000435c:	458a8a93          	addi	s5,s5,1112 # 800217b0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004360:	0001da17          	auipc	s4,0x1d
    80004364:	420a0a13          	addi	s4,s4,1056 # 80021780 <log>
    80004368:	018a2583          	lw	a1,24(s4)
    8000436c:	012585bb          	addw	a1,a1,s2
    80004370:	2585                	addiw	a1,a1,1
    80004372:	028a2503          	lw	a0,40(s4)
    80004376:	fffff097          	auipc	ra,0xfffff
    8000437a:	cd2080e7          	jalr	-814(ra) # 80003048 <bread>
    8000437e:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004380:	000aa583          	lw	a1,0(s5)
    80004384:	028a2503          	lw	a0,40(s4)
    80004388:	fffff097          	auipc	ra,0xfffff
    8000438c:	cc0080e7          	jalr	-832(ra) # 80003048 <bread>
    80004390:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004392:	40000613          	li	a2,1024
    80004396:	05850593          	addi	a1,a0,88
    8000439a:	05848513          	addi	a0,s1,88
    8000439e:	ffffd097          	auipc	ra,0xffffd
    800043a2:	9a2080e7          	jalr	-1630(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    800043a6:	8526                	mv	a0,s1
    800043a8:	fffff097          	auipc	ra,0xfffff
    800043ac:	d92080e7          	jalr	-622(ra) # 8000313a <bwrite>
    brelse(from);
    800043b0:	854e                	mv	a0,s3
    800043b2:	fffff097          	auipc	ra,0xfffff
    800043b6:	dc6080e7          	jalr	-570(ra) # 80003178 <brelse>
    brelse(to);
    800043ba:	8526                	mv	a0,s1
    800043bc:	fffff097          	auipc	ra,0xfffff
    800043c0:	dbc080e7          	jalr	-580(ra) # 80003178 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043c4:	2905                	addiw	s2,s2,1
    800043c6:	0a91                	addi	s5,s5,4
    800043c8:	02ca2783          	lw	a5,44(s4)
    800043cc:	f8f94ee3          	blt	s2,a5,80004368 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800043d0:	00000097          	auipc	ra,0x0
    800043d4:	c6a080e7          	jalr	-918(ra) # 8000403a <write_head>
    install_trans(0); // Now install writes to home locations
    800043d8:	4501                	li	a0,0
    800043da:	00000097          	auipc	ra,0x0
    800043de:	cda080e7          	jalr	-806(ra) # 800040b4 <install_trans>
    log.lh.n = 0;
    800043e2:	0001d797          	auipc	a5,0x1d
    800043e6:	3c07a523          	sw	zero,970(a5) # 800217ac <log+0x2c>
    write_head();    // Erase the transaction from the log
    800043ea:	00000097          	auipc	ra,0x0
    800043ee:	c50080e7          	jalr	-944(ra) # 8000403a <write_head>
    800043f2:	bdf5                	j	800042ee <end_op+0x52>

00000000800043f4 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800043f4:	1101                	addi	sp,sp,-32
    800043f6:	ec06                	sd	ra,24(sp)
    800043f8:	e822                	sd	s0,16(sp)
    800043fa:	e426                	sd	s1,8(sp)
    800043fc:	e04a                	sd	s2,0(sp)
    800043fe:	1000                	addi	s0,sp,32
    80004400:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004402:	0001d917          	auipc	s2,0x1d
    80004406:	37e90913          	addi	s2,s2,894 # 80021780 <log>
    8000440a:	854a                	mv	a0,s2
    8000440c:	ffffc097          	auipc	ra,0xffffc
    80004410:	7d8080e7          	jalr	2008(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004414:	02c92603          	lw	a2,44(s2)
    80004418:	47f5                	li	a5,29
    8000441a:	06c7c563          	blt	a5,a2,80004484 <log_write+0x90>
    8000441e:	0001d797          	auipc	a5,0x1d
    80004422:	37e7a783          	lw	a5,894(a5) # 8002179c <log+0x1c>
    80004426:	37fd                	addiw	a5,a5,-1
    80004428:	04f65e63          	bge	a2,a5,80004484 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000442c:	0001d797          	auipc	a5,0x1d
    80004430:	3747a783          	lw	a5,884(a5) # 800217a0 <log+0x20>
    80004434:	06f05063          	blez	a5,80004494 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004438:	4781                	li	a5,0
    8000443a:	06c05563          	blez	a2,800044a4 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000443e:	44cc                	lw	a1,12(s1)
    80004440:	0001d717          	auipc	a4,0x1d
    80004444:	37070713          	addi	a4,a4,880 # 800217b0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004448:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000444a:	4314                	lw	a3,0(a4)
    8000444c:	04b68c63          	beq	a3,a1,800044a4 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004450:	2785                	addiw	a5,a5,1
    80004452:	0711                	addi	a4,a4,4
    80004454:	fef61be3          	bne	a2,a5,8000444a <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004458:	0621                	addi	a2,a2,8
    8000445a:	060a                	slli	a2,a2,0x2
    8000445c:	0001d797          	auipc	a5,0x1d
    80004460:	32478793          	addi	a5,a5,804 # 80021780 <log>
    80004464:	963e                	add	a2,a2,a5
    80004466:	44dc                	lw	a5,12(s1)
    80004468:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000446a:	8526                	mv	a0,s1
    8000446c:	fffff097          	auipc	ra,0xfffff
    80004470:	daa080e7          	jalr	-598(ra) # 80003216 <bpin>
    log.lh.n++;
    80004474:	0001d717          	auipc	a4,0x1d
    80004478:	30c70713          	addi	a4,a4,780 # 80021780 <log>
    8000447c:	575c                	lw	a5,44(a4)
    8000447e:	2785                	addiw	a5,a5,1
    80004480:	d75c                	sw	a5,44(a4)
    80004482:	a835                	j	800044be <log_write+0xca>
    panic("too big a transaction");
    80004484:	00004517          	auipc	a0,0x4
    80004488:	26c50513          	addi	a0,a0,620 # 800086f0 <syscalls+0x200>
    8000448c:	ffffc097          	auipc	ra,0xffffc
    80004490:	0b2080e7          	jalr	178(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004494:	00004517          	auipc	a0,0x4
    80004498:	27450513          	addi	a0,a0,628 # 80008708 <syscalls+0x218>
    8000449c:	ffffc097          	auipc	ra,0xffffc
    800044a0:	0a2080e7          	jalr	162(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800044a4:	00878713          	addi	a4,a5,8
    800044a8:	00271693          	slli	a3,a4,0x2
    800044ac:	0001d717          	auipc	a4,0x1d
    800044b0:	2d470713          	addi	a4,a4,724 # 80021780 <log>
    800044b4:	9736                	add	a4,a4,a3
    800044b6:	44d4                	lw	a3,12(s1)
    800044b8:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800044ba:	faf608e3          	beq	a2,a5,8000446a <log_write+0x76>
  }
  release(&log.lock);
    800044be:	0001d517          	auipc	a0,0x1d
    800044c2:	2c250513          	addi	a0,a0,706 # 80021780 <log>
    800044c6:	ffffc097          	auipc	ra,0xffffc
    800044ca:	7d2080e7          	jalr	2002(ra) # 80000c98 <release>
}
    800044ce:	60e2                	ld	ra,24(sp)
    800044d0:	6442                	ld	s0,16(sp)
    800044d2:	64a2                	ld	s1,8(sp)
    800044d4:	6902                	ld	s2,0(sp)
    800044d6:	6105                	addi	sp,sp,32
    800044d8:	8082                	ret

00000000800044da <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800044da:	1101                	addi	sp,sp,-32
    800044dc:	ec06                	sd	ra,24(sp)
    800044de:	e822                	sd	s0,16(sp)
    800044e0:	e426                	sd	s1,8(sp)
    800044e2:	e04a                	sd	s2,0(sp)
    800044e4:	1000                	addi	s0,sp,32
    800044e6:	84aa                	mv	s1,a0
    800044e8:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800044ea:	00004597          	auipc	a1,0x4
    800044ee:	23e58593          	addi	a1,a1,574 # 80008728 <syscalls+0x238>
    800044f2:	0521                	addi	a0,a0,8
    800044f4:	ffffc097          	auipc	ra,0xffffc
    800044f8:	660080e7          	jalr	1632(ra) # 80000b54 <initlock>
  lk->name = name;
    800044fc:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004500:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004504:	0204a423          	sw	zero,40(s1)
}
    80004508:	60e2                	ld	ra,24(sp)
    8000450a:	6442                	ld	s0,16(sp)
    8000450c:	64a2                	ld	s1,8(sp)
    8000450e:	6902                	ld	s2,0(sp)
    80004510:	6105                	addi	sp,sp,32
    80004512:	8082                	ret

0000000080004514 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004514:	1101                	addi	sp,sp,-32
    80004516:	ec06                	sd	ra,24(sp)
    80004518:	e822                	sd	s0,16(sp)
    8000451a:	e426                	sd	s1,8(sp)
    8000451c:	e04a                	sd	s2,0(sp)
    8000451e:	1000                	addi	s0,sp,32
    80004520:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004522:	00850913          	addi	s2,a0,8
    80004526:	854a                	mv	a0,s2
    80004528:	ffffc097          	auipc	ra,0xffffc
    8000452c:	6bc080e7          	jalr	1724(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004530:	409c                	lw	a5,0(s1)
    80004532:	cb89                	beqz	a5,80004544 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004534:	85ca                	mv	a1,s2
    80004536:	8526                	mv	a0,s1
    80004538:	ffffe097          	auipc	ra,0xffffe
    8000453c:	d46080e7          	jalr	-698(ra) # 8000227e <sleep>
  while (lk->locked) {
    80004540:	409c                	lw	a5,0(s1)
    80004542:	fbed                	bnez	a5,80004534 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004544:	4785                	li	a5,1
    80004546:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004548:	ffffd097          	auipc	ra,0xffffd
    8000454c:	544080e7          	jalr	1348(ra) # 80001a8c <myproc>
    80004550:	591c                	lw	a5,48(a0)
    80004552:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004554:	854a                	mv	a0,s2
    80004556:	ffffc097          	auipc	ra,0xffffc
    8000455a:	742080e7          	jalr	1858(ra) # 80000c98 <release>
}
    8000455e:	60e2                	ld	ra,24(sp)
    80004560:	6442                	ld	s0,16(sp)
    80004562:	64a2                	ld	s1,8(sp)
    80004564:	6902                	ld	s2,0(sp)
    80004566:	6105                	addi	sp,sp,32
    80004568:	8082                	ret

000000008000456a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000456a:	1101                	addi	sp,sp,-32
    8000456c:	ec06                	sd	ra,24(sp)
    8000456e:	e822                	sd	s0,16(sp)
    80004570:	e426                	sd	s1,8(sp)
    80004572:	e04a                	sd	s2,0(sp)
    80004574:	1000                	addi	s0,sp,32
    80004576:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004578:	00850913          	addi	s2,a0,8
    8000457c:	854a                	mv	a0,s2
    8000457e:	ffffc097          	auipc	ra,0xffffc
    80004582:	666080e7          	jalr	1638(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004586:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000458a:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000458e:	8526                	mv	a0,s1
    80004590:	ffffe097          	auipc	ra,0xffffe
    80004594:	e7a080e7          	jalr	-390(ra) # 8000240a <wakeup>
  release(&lk->lk);
    80004598:	854a                	mv	a0,s2
    8000459a:	ffffc097          	auipc	ra,0xffffc
    8000459e:	6fe080e7          	jalr	1790(ra) # 80000c98 <release>
}
    800045a2:	60e2                	ld	ra,24(sp)
    800045a4:	6442                	ld	s0,16(sp)
    800045a6:	64a2                	ld	s1,8(sp)
    800045a8:	6902                	ld	s2,0(sp)
    800045aa:	6105                	addi	sp,sp,32
    800045ac:	8082                	ret

00000000800045ae <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800045ae:	7179                	addi	sp,sp,-48
    800045b0:	f406                	sd	ra,40(sp)
    800045b2:	f022                	sd	s0,32(sp)
    800045b4:	ec26                	sd	s1,24(sp)
    800045b6:	e84a                	sd	s2,16(sp)
    800045b8:	e44e                	sd	s3,8(sp)
    800045ba:	1800                	addi	s0,sp,48
    800045bc:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800045be:	00850913          	addi	s2,a0,8
    800045c2:	854a                	mv	a0,s2
    800045c4:	ffffc097          	auipc	ra,0xffffc
    800045c8:	620080e7          	jalr	1568(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800045cc:	409c                	lw	a5,0(s1)
    800045ce:	ef99                	bnez	a5,800045ec <holdingsleep+0x3e>
    800045d0:	4481                	li	s1,0
  release(&lk->lk);
    800045d2:	854a                	mv	a0,s2
    800045d4:	ffffc097          	auipc	ra,0xffffc
    800045d8:	6c4080e7          	jalr	1732(ra) # 80000c98 <release>
  return r;
}
    800045dc:	8526                	mv	a0,s1
    800045de:	70a2                	ld	ra,40(sp)
    800045e0:	7402                	ld	s0,32(sp)
    800045e2:	64e2                	ld	s1,24(sp)
    800045e4:	6942                	ld	s2,16(sp)
    800045e6:	69a2                	ld	s3,8(sp)
    800045e8:	6145                	addi	sp,sp,48
    800045ea:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800045ec:	0284a983          	lw	s3,40(s1)
    800045f0:	ffffd097          	auipc	ra,0xffffd
    800045f4:	49c080e7          	jalr	1180(ra) # 80001a8c <myproc>
    800045f8:	5904                	lw	s1,48(a0)
    800045fa:	413484b3          	sub	s1,s1,s3
    800045fe:	0014b493          	seqz	s1,s1
    80004602:	bfc1                	j	800045d2 <holdingsleep+0x24>

0000000080004604 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004604:	1141                	addi	sp,sp,-16
    80004606:	e406                	sd	ra,8(sp)
    80004608:	e022                	sd	s0,0(sp)
    8000460a:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000460c:	00004597          	auipc	a1,0x4
    80004610:	12c58593          	addi	a1,a1,300 # 80008738 <syscalls+0x248>
    80004614:	0001d517          	auipc	a0,0x1d
    80004618:	2b450513          	addi	a0,a0,692 # 800218c8 <ftable>
    8000461c:	ffffc097          	auipc	ra,0xffffc
    80004620:	538080e7          	jalr	1336(ra) # 80000b54 <initlock>
}
    80004624:	60a2                	ld	ra,8(sp)
    80004626:	6402                	ld	s0,0(sp)
    80004628:	0141                	addi	sp,sp,16
    8000462a:	8082                	ret

000000008000462c <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000462c:	1101                	addi	sp,sp,-32
    8000462e:	ec06                	sd	ra,24(sp)
    80004630:	e822                	sd	s0,16(sp)
    80004632:	e426                	sd	s1,8(sp)
    80004634:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004636:	0001d517          	auipc	a0,0x1d
    8000463a:	29250513          	addi	a0,a0,658 # 800218c8 <ftable>
    8000463e:	ffffc097          	auipc	ra,0xffffc
    80004642:	5a6080e7          	jalr	1446(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004646:	0001d497          	auipc	s1,0x1d
    8000464a:	29a48493          	addi	s1,s1,666 # 800218e0 <ftable+0x18>
    8000464e:	0001e717          	auipc	a4,0x1e
    80004652:	23270713          	addi	a4,a4,562 # 80022880 <ftable+0xfb8>
    if(f->ref == 0){
    80004656:	40dc                	lw	a5,4(s1)
    80004658:	cf99                	beqz	a5,80004676 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000465a:	02848493          	addi	s1,s1,40
    8000465e:	fee49ce3          	bne	s1,a4,80004656 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004662:	0001d517          	auipc	a0,0x1d
    80004666:	26650513          	addi	a0,a0,614 # 800218c8 <ftable>
    8000466a:	ffffc097          	auipc	ra,0xffffc
    8000466e:	62e080e7          	jalr	1582(ra) # 80000c98 <release>
  return 0;
    80004672:	4481                	li	s1,0
    80004674:	a819                	j	8000468a <filealloc+0x5e>
      f->ref = 1;
    80004676:	4785                	li	a5,1
    80004678:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000467a:	0001d517          	auipc	a0,0x1d
    8000467e:	24e50513          	addi	a0,a0,590 # 800218c8 <ftable>
    80004682:	ffffc097          	auipc	ra,0xffffc
    80004686:	616080e7          	jalr	1558(ra) # 80000c98 <release>
}
    8000468a:	8526                	mv	a0,s1
    8000468c:	60e2                	ld	ra,24(sp)
    8000468e:	6442                	ld	s0,16(sp)
    80004690:	64a2                	ld	s1,8(sp)
    80004692:	6105                	addi	sp,sp,32
    80004694:	8082                	ret

0000000080004696 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004696:	1101                	addi	sp,sp,-32
    80004698:	ec06                	sd	ra,24(sp)
    8000469a:	e822                	sd	s0,16(sp)
    8000469c:	e426                	sd	s1,8(sp)
    8000469e:	1000                	addi	s0,sp,32
    800046a0:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800046a2:	0001d517          	auipc	a0,0x1d
    800046a6:	22650513          	addi	a0,a0,550 # 800218c8 <ftable>
    800046aa:	ffffc097          	auipc	ra,0xffffc
    800046ae:	53a080e7          	jalr	1338(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800046b2:	40dc                	lw	a5,4(s1)
    800046b4:	02f05263          	blez	a5,800046d8 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800046b8:	2785                	addiw	a5,a5,1
    800046ba:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800046bc:	0001d517          	auipc	a0,0x1d
    800046c0:	20c50513          	addi	a0,a0,524 # 800218c8 <ftable>
    800046c4:	ffffc097          	auipc	ra,0xffffc
    800046c8:	5d4080e7          	jalr	1492(ra) # 80000c98 <release>
  return f;
}
    800046cc:	8526                	mv	a0,s1
    800046ce:	60e2                	ld	ra,24(sp)
    800046d0:	6442                	ld	s0,16(sp)
    800046d2:	64a2                	ld	s1,8(sp)
    800046d4:	6105                	addi	sp,sp,32
    800046d6:	8082                	ret
    panic("filedup");
    800046d8:	00004517          	auipc	a0,0x4
    800046dc:	06850513          	addi	a0,a0,104 # 80008740 <syscalls+0x250>
    800046e0:	ffffc097          	auipc	ra,0xffffc
    800046e4:	e5e080e7          	jalr	-418(ra) # 8000053e <panic>

00000000800046e8 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800046e8:	7139                	addi	sp,sp,-64
    800046ea:	fc06                	sd	ra,56(sp)
    800046ec:	f822                	sd	s0,48(sp)
    800046ee:	f426                	sd	s1,40(sp)
    800046f0:	f04a                	sd	s2,32(sp)
    800046f2:	ec4e                	sd	s3,24(sp)
    800046f4:	e852                	sd	s4,16(sp)
    800046f6:	e456                	sd	s5,8(sp)
    800046f8:	0080                	addi	s0,sp,64
    800046fa:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800046fc:	0001d517          	auipc	a0,0x1d
    80004700:	1cc50513          	addi	a0,a0,460 # 800218c8 <ftable>
    80004704:	ffffc097          	auipc	ra,0xffffc
    80004708:	4e0080e7          	jalr	1248(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    8000470c:	40dc                	lw	a5,4(s1)
    8000470e:	06f05163          	blez	a5,80004770 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004712:	37fd                	addiw	a5,a5,-1
    80004714:	0007871b          	sext.w	a4,a5
    80004718:	c0dc                	sw	a5,4(s1)
    8000471a:	06e04363          	bgtz	a4,80004780 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000471e:	0004a903          	lw	s2,0(s1)
    80004722:	0094ca83          	lbu	s5,9(s1)
    80004726:	0104ba03          	ld	s4,16(s1)
    8000472a:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000472e:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004732:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004736:	0001d517          	auipc	a0,0x1d
    8000473a:	19250513          	addi	a0,a0,402 # 800218c8 <ftable>
    8000473e:	ffffc097          	auipc	ra,0xffffc
    80004742:	55a080e7          	jalr	1370(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004746:	4785                	li	a5,1
    80004748:	04f90d63          	beq	s2,a5,800047a2 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000474c:	3979                	addiw	s2,s2,-2
    8000474e:	4785                	li	a5,1
    80004750:	0527e063          	bltu	a5,s2,80004790 <fileclose+0xa8>
    begin_op();
    80004754:	00000097          	auipc	ra,0x0
    80004758:	ac8080e7          	jalr	-1336(ra) # 8000421c <begin_op>
    iput(ff.ip);
    8000475c:	854e                	mv	a0,s3
    8000475e:	fffff097          	auipc	ra,0xfffff
    80004762:	2a6080e7          	jalr	678(ra) # 80003a04 <iput>
    end_op();
    80004766:	00000097          	auipc	ra,0x0
    8000476a:	b36080e7          	jalr	-1226(ra) # 8000429c <end_op>
    8000476e:	a00d                	j	80004790 <fileclose+0xa8>
    panic("fileclose");
    80004770:	00004517          	auipc	a0,0x4
    80004774:	fd850513          	addi	a0,a0,-40 # 80008748 <syscalls+0x258>
    80004778:	ffffc097          	auipc	ra,0xffffc
    8000477c:	dc6080e7          	jalr	-570(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004780:	0001d517          	auipc	a0,0x1d
    80004784:	14850513          	addi	a0,a0,328 # 800218c8 <ftable>
    80004788:	ffffc097          	auipc	ra,0xffffc
    8000478c:	510080e7          	jalr	1296(ra) # 80000c98 <release>
  }
}
    80004790:	70e2                	ld	ra,56(sp)
    80004792:	7442                	ld	s0,48(sp)
    80004794:	74a2                	ld	s1,40(sp)
    80004796:	7902                	ld	s2,32(sp)
    80004798:	69e2                	ld	s3,24(sp)
    8000479a:	6a42                	ld	s4,16(sp)
    8000479c:	6aa2                	ld	s5,8(sp)
    8000479e:	6121                	addi	sp,sp,64
    800047a0:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800047a2:	85d6                	mv	a1,s5
    800047a4:	8552                	mv	a0,s4
    800047a6:	00000097          	auipc	ra,0x0
    800047aa:	34c080e7          	jalr	844(ra) # 80004af2 <pipeclose>
    800047ae:	b7cd                	j	80004790 <fileclose+0xa8>

00000000800047b0 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800047b0:	715d                	addi	sp,sp,-80
    800047b2:	e486                	sd	ra,72(sp)
    800047b4:	e0a2                	sd	s0,64(sp)
    800047b6:	fc26                	sd	s1,56(sp)
    800047b8:	f84a                	sd	s2,48(sp)
    800047ba:	f44e                	sd	s3,40(sp)
    800047bc:	0880                	addi	s0,sp,80
    800047be:	84aa                	mv	s1,a0
    800047c0:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800047c2:	ffffd097          	auipc	ra,0xffffd
    800047c6:	2ca080e7          	jalr	714(ra) # 80001a8c <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800047ca:	409c                	lw	a5,0(s1)
    800047cc:	37f9                	addiw	a5,a5,-2
    800047ce:	4705                	li	a4,1
    800047d0:	04f76763          	bltu	a4,a5,8000481e <filestat+0x6e>
    800047d4:	892a                	mv	s2,a0
    ilock(f->ip);
    800047d6:	6c88                	ld	a0,24(s1)
    800047d8:	fffff097          	auipc	ra,0xfffff
    800047dc:	072080e7          	jalr	114(ra) # 8000384a <ilock>
    stati(f->ip, &st);
    800047e0:	fb840593          	addi	a1,s0,-72
    800047e4:	6c88                	ld	a0,24(s1)
    800047e6:	fffff097          	auipc	ra,0xfffff
    800047ea:	2ee080e7          	jalr	750(ra) # 80003ad4 <stati>
    iunlock(f->ip);
    800047ee:	6c88                	ld	a0,24(s1)
    800047f0:	fffff097          	auipc	ra,0xfffff
    800047f4:	11c080e7          	jalr	284(ra) # 8000390c <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800047f8:	46e1                	li	a3,24
    800047fa:	fb840613          	addi	a2,s0,-72
    800047fe:	85ce                	mv	a1,s3
    80004800:	05093503          	ld	a0,80(s2)
    80004804:	ffffd097          	auipc	ra,0xffffd
    80004808:	e6e080e7          	jalr	-402(ra) # 80001672 <copyout>
    8000480c:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004810:	60a6                	ld	ra,72(sp)
    80004812:	6406                	ld	s0,64(sp)
    80004814:	74e2                	ld	s1,56(sp)
    80004816:	7942                	ld	s2,48(sp)
    80004818:	79a2                	ld	s3,40(sp)
    8000481a:	6161                	addi	sp,sp,80
    8000481c:	8082                	ret
  return -1;
    8000481e:	557d                	li	a0,-1
    80004820:	bfc5                	j	80004810 <filestat+0x60>

0000000080004822 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004822:	7179                	addi	sp,sp,-48
    80004824:	f406                	sd	ra,40(sp)
    80004826:	f022                	sd	s0,32(sp)
    80004828:	ec26                	sd	s1,24(sp)
    8000482a:	e84a                	sd	s2,16(sp)
    8000482c:	e44e                	sd	s3,8(sp)
    8000482e:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004830:	00854783          	lbu	a5,8(a0)
    80004834:	c3d5                	beqz	a5,800048d8 <fileread+0xb6>
    80004836:	84aa                	mv	s1,a0
    80004838:	89ae                	mv	s3,a1
    8000483a:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000483c:	411c                	lw	a5,0(a0)
    8000483e:	4705                	li	a4,1
    80004840:	04e78963          	beq	a5,a4,80004892 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004844:	470d                	li	a4,3
    80004846:	04e78d63          	beq	a5,a4,800048a0 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000484a:	4709                	li	a4,2
    8000484c:	06e79e63          	bne	a5,a4,800048c8 <fileread+0xa6>
    ilock(f->ip);
    80004850:	6d08                	ld	a0,24(a0)
    80004852:	fffff097          	auipc	ra,0xfffff
    80004856:	ff8080e7          	jalr	-8(ra) # 8000384a <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000485a:	874a                	mv	a4,s2
    8000485c:	5094                	lw	a3,32(s1)
    8000485e:	864e                	mv	a2,s3
    80004860:	4585                	li	a1,1
    80004862:	6c88                	ld	a0,24(s1)
    80004864:	fffff097          	auipc	ra,0xfffff
    80004868:	29a080e7          	jalr	666(ra) # 80003afe <readi>
    8000486c:	892a                	mv	s2,a0
    8000486e:	00a05563          	blez	a0,80004878 <fileread+0x56>
      f->off += r;
    80004872:	509c                	lw	a5,32(s1)
    80004874:	9fa9                	addw	a5,a5,a0
    80004876:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004878:	6c88                	ld	a0,24(s1)
    8000487a:	fffff097          	auipc	ra,0xfffff
    8000487e:	092080e7          	jalr	146(ra) # 8000390c <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004882:	854a                	mv	a0,s2
    80004884:	70a2                	ld	ra,40(sp)
    80004886:	7402                	ld	s0,32(sp)
    80004888:	64e2                	ld	s1,24(sp)
    8000488a:	6942                	ld	s2,16(sp)
    8000488c:	69a2                	ld	s3,8(sp)
    8000488e:	6145                	addi	sp,sp,48
    80004890:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004892:	6908                	ld	a0,16(a0)
    80004894:	00000097          	auipc	ra,0x0
    80004898:	3c8080e7          	jalr	968(ra) # 80004c5c <piperead>
    8000489c:	892a                	mv	s2,a0
    8000489e:	b7d5                	j	80004882 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800048a0:	02451783          	lh	a5,36(a0)
    800048a4:	03079693          	slli	a3,a5,0x30
    800048a8:	92c1                	srli	a3,a3,0x30
    800048aa:	4725                	li	a4,9
    800048ac:	02d76863          	bltu	a4,a3,800048dc <fileread+0xba>
    800048b0:	0792                	slli	a5,a5,0x4
    800048b2:	0001d717          	auipc	a4,0x1d
    800048b6:	f7670713          	addi	a4,a4,-138 # 80021828 <devsw>
    800048ba:	97ba                	add	a5,a5,a4
    800048bc:	639c                	ld	a5,0(a5)
    800048be:	c38d                	beqz	a5,800048e0 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800048c0:	4505                	li	a0,1
    800048c2:	9782                	jalr	a5
    800048c4:	892a                	mv	s2,a0
    800048c6:	bf75                	j	80004882 <fileread+0x60>
    panic("fileread");
    800048c8:	00004517          	auipc	a0,0x4
    800048cc:	e9050513          	addi	a0,a0,-368 # 80008758 <syscalls+0x268>
    800048d0:	ffffc097          	auipc	ra,0xffffc
    800048d4:	c6e080e7          	jalr	-914(ra) # 8000053e <panic>
    return -1;
    800048d8:	597d                	li	s2,-1
    800048da:	b765                	j	80004882 <fileread+0x60>
      return -1;
    800048dc:	597d                	li	s2,-1
    800048de:	b755                	j	80004882 <fileread+0x60>
    800048e0:	597d                	li	s2,-1
    800048e2:	b745                	j	80004882 <fileread+0x60>

00000000800048e4 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800048e4:	715d                	addi	sp,sp,-80
    800048e6:	e486                	sd	ra,72(sp)
    800048e8:	e0a2                	sd	s0,64(sp)
    800048ea:	fc26                	sd	s1,56(sp)
    800048ec:	f84a                	sd	s2,48(sp)
    800048ee:	f44e                	sd	s3,40(sp)
    800048f0:	f052                	sd	s4,32(sp)
    800048f2:	ec56                	sd	s5,24(sp)
    800048f4:	e85a                	sd	s6,16(sp)
    800048f6:	e45e                	sd	s7,8(sp)
    800048f8:	e062                	sd	s8,0(sp)
    800048fa:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800048fc:	00954783          	lbu	a5,9(a0)
    80004900:	10078663          	beqz	a5,80004a0c <filewrite+0x128>
    80004904:	892a                	mv	s2,a0
    80004906:	8aae                	mv	s5,a1
    80004908:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000490a:	411c                	lw	a5,0(a0)
    8000490c:	4705                	li	a4,1
    8000490e:	02e78263          	beq	a5,a4,80004932 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004912:	470d                	li	a4,3
    80004914:	02e78663          	beq	a5,a4,80004940 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004918:	4709                	li	a4,2
    8000491a:	0ee79163          	bne	a5,a4,800049fc <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000491e:	0ac05d63          	blez	a2,800049d8 <filewrite+0xf4>
    int i = 0;
    80004922:	4981                	li	s3,0
    80004924:	6b05                	lui	s6,0x1
    80004926:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000492a:	6b85                	lui	s7,0x1
    8000492c:	c00b8b9b          	addiw	s7,s7,-1024
    80004930:	a861                	j	800049c8 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004932:	6908                	ld	a0,16(a0)
    80004934:	00000097          	auipc	ra,0x0
    80004938:	22e080e7          	jalr	558(ra) # 80004b62 <pipewrite>
    8000493c:	8a2a                	mv	s4,a0
    8000493e:	a045                	j	800049de <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004940:	02451783          	lh	a5,36(a0)
    80004944:	03079693          	slli	a3,a5,0x30
    80004948:	92c1                	srli	a3,a3,0x30
    8000494a:	4725                	li	a4,9
    8000494c:	0cd76263          	bltu	a4,a3,80004a10 <filewrite+0x12c>
    80004950:	0792                	slli	a5,a5,0x4
    80004952:	0001d717          	auipc	a4,0x1d
    80004956:	ed670713          	addi	a4,a4,-298 # 80021828 <devsw>
    8000495a:	97ba                	add	a5,a5,a4
    8000495c:	679c                	ld	a5,8(a5)
    8000495e:	cbdd                	beqz	a5,80004a14 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004960:	4505                	li	a0,1
    80004962:	9782                	jalr	a5
    80004964:	8a2a                	mv	s4,a0
    80004966:	a8a5                	j	800049de <filewrite+0xfa>
    80004968:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000496c:	00000097          	auipc	ra,0x0
    80004970:	8b0080e7          	jalr	-1872(ra) # 8000421c <begin_op>
      ilock(f->ip);
    80004974:	01893503          	ld	a0,24(s2)
    80004978:	fffff097          	auipc	ra,0xfffff
    8000497c:	ed2080e7          	jalr	-302(ra) # 8000384a <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004980:	8762                	mv	a4,s8
    80004982:	02092683          	lw	a3,32(s2)
    80004986:	01598633          	add	a2,s3,s5
    8000498a:	4585                	li	a1,1
    8000498c:	01893503          	ld	a0,24(s2)
    80004990:	fffff097          	auipc	ra,0xfffff
    80004994:	266080e7          	jalr	614(ra) # 80003bf6 <writei>
    80004998:	84aa                	mv	s1,a0
    8000499a:	00a05763          	blez	a0,800049a8 <filewrite+0xc4>
        f->off += r;
    8000499e:	02092783          	lw	a5,32(s2)
    800049a2:	9fa9                	addw	a5,a5,a0
    800049a4:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800049a8:	01893503          	ld	a0,24(s2)
    800049ac:	fffff097          	auipc	ra,0xfffff
    800049b0:	f60080e7          	jalr	-160(ra) # 8000390c <iunlock>
      end_op();
    800049b4:	00000097          	auipc	ra,0x0
    800049b8:	8e8080e7          	jalr	-1816(ra) # 8000429c <end_op>

      if(r != n1){
    800049bc:	009c1f63          	bne	s8,s1,800049da <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800049c0:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800049c4:	0149db63          	bge	s3,s4,800049da <filewrite+0xf6>
      int n1 = n - i;
    800049c8:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800049cc:	84be                	mv	s1,a5
    800049ce:	2781                	sext.w	a5,a5
    800049d0:	f8fb5ce3          	bge	s6,a5,80004968 <filewrite+0x84>
    800049d4:	84de                	mv	s1,s7
    800049d6:	bf49                	j	80004968 <filewrite+0x84>
    int i = 0;
    800049d8:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800049da:	013a1f63          	bne	s4,s3,800049f8 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800049de:	8552                	mv	a0,s4
    800049e0:	60a6                	ld	ra,72(sp)
    800049e2:	6406                	ld	s0,64(sp)
    800049e4:	74e2                	ld	s1,56(sp)
    800049e6:	7942                	ld	s2,48(sp)
    800049e8:	79a2                	ld	s3,40(sp)
    800049ea:	7a02                	ld	s4,32(sp)
    800049ec:	6ae2                	ld	s5,24(sp)
    800049ee:	6b42                	ld	s6,16(sp)
    800049f0:	6ba2                	ld	s7,8(sp)
    800049f2:	6c02                	ld	s8,0(sp)
    800049f4:	6161                	addi	sp,sp,80
    800049f6:	8082                	ret
    ret = (i == n ? n : -1);
    800049f8:	5a7d                	li	s4,-1
    800049fa:	b7d5                	j	800049de <filewrite+0xfa>
    panic("filewrite");
    800049fc:	00004517          	auipc	a0,0x4
    80004a00:	d6c50513          	addi	a0,a0,-660 # 80008768 <syscalls+0x278>
    80004a04:	ffffc097          	auipc	ra,0xffffc
    80004a08:	b3a080e7          	jalr	-1222(ra) # 8000053e <panic>
    return -1;
    80004a0c:	5a7d                	li	s4,-1
    80004a0e:	bfc1                	j	800049de <filewrite+0xfa>
      return -1;
    80004a10:	5a7d                	li	s4,-1
    80004a12:	b7f1                	j	800049de <filewrite+0xfa>
    80004a14:	5a7d                	li	s4,-1
    80004a16:	b7e1                	j	800049de <filewrite+0xfa>

0000000080004a18 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004a18:	7179                	addi	sp,sp,-48
    80004a1a:	f406                	sd	ra,40(sp)
    80004a1c:	f022                	sd	s0,32(sp)
    80004a1e:	ec26                	sd	s1,24(sp)
    80004a20:	e84a                	sd	s2,16(sp)
    80004a22:	e44e                	sd	s3,8(sp)
    80004a24:	e052                	sd	s4,0(sp)
    80004a26:	1800                	addi	s0,sp,48
    80004a28:	84aa                	mv	s1,a0
    80004a2a:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004a2c:	0005b023          	sd	zero,0(a1)
    80004a30:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004a34:	00000097          	auipc	ra,0x0
    80004a38:	bf8080e7          	jalr	-1032(ra) # 8000462c <filealloc>
    80004a3c:	e088                	sd	a0,0(s1)
    80004a3e:	c551                	beqz	a0,80004aca <pipealloc+0xb2>
    80004a40:	00000097          	auipc	ra,0x0
    80004a44:	bec080e7          	jalr	-1044(ra) # 8000462c <filealloc>
    80004a48:	00aa3023          	sd	a0,0(s4)
    80004a4c:	c92d                	beqz	a0,80004abe <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004a4e:	ffffc097          	auipc	ra,0xffffc
    80004a52:	0a6080e7          	jalr	166(ra) # 80000af4 <kalloc>
    80004a56:	892a                	mv	s2,a0
    80004a58:	c125                	beqz	a0,80004ab8 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004a5a:	4985                	li	s3,1
    80004a5c:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004a60:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004a64:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004a68:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004a6c:	00004597          	auipc	a1,0x4
    80004a70:	d0c58593          	addi	a1,a1,-756 # 80008778 <syscalls+0x288>
    80004a74:	ffffc097          	auipc	ra,0xffffc
    80004a78:	0e0080e7          	jalr	224(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004a7c:	609c                	ld	a5,0(s1)
    80004a7e:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004a82:	609c                	ld	a5,0(s1)
    80004a84:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004a88:	609c                	ld	a5,0(s1)
    80004a8a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a8e:	609c                	ld	a5,0(s1)
    80004a90:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004a94:	000a3783          	ld	a5,0(s4)
    80004a98:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a9c:	000a3783          	ld	a5,0(s4)
    80004aa0:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004aa4:	000a3783          	ld	a5,0(s4)
    80004aa8:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004aac:	000a3783          	ld	a5,0(s4)
    80004ab0:	0127b823          	sd	s2,16(a5)
  return 0;
    80004ab4:	4501                	li	a0,0
    80004ab6:	a025                	j	80004ade <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004ab8:	6088                	ld	a0,0(s1)
    80004aba:	e501                	bnez	a0,80004ac2 <pipealloc+0xaa>
    80004abc:	a039                	j	80004aca <pipealloc+0xb2>
    80004abe:	6088                	ld	a0,0(s1)
    80004ac0:	c51d                	beqz	a0,80004aee <pipealloc+0xd6>
    fileclose(*f0);
    80004ac2:	00000097          	auipc	ra,0x0
    80004ac6:	c26080e7          	jalr	-986(ra) # 800046e8 <fileclose>
  if(*f1)
    80004aca:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004ace:	557d                	li	a0,-1
  if(*f1)
    80004ad0:	c799                	beqz	a5,80004ade <pipealloc+0xc6>
    fileclose(*f1);
    80004ad2:	853e                	mv	a0,a5
    80004ad4:	00000097          	auipc	ra,0x0
    80004ad8:	c14080e7          	jalr	-1004(ra) # 800046e8 <fileclose>
  return -1;
    80004adc:	557d                	li	a0,-1
}
    80004ade:	70a2                	ld	ra,40(sp)
    80004ae0:	7402                	ld	s0,32(sp)
    80004ae2:	64e2                	ld	s1,24(sp)
    80004ae4:	6942                	ld	s2,16(sp)
    80004ae6:	69a2                	ld	s3,8(sp)
    80004ae8:	6a02                	ld	s4,0(sp)
    80004aea:	6145                	addi	sp,sp,48
    80004aec:	8082                	ret
  return -1;
    80004aee:	557d                	li	a0,-1
    80004af0:	b7fd                	j	80004ade <pipealloc+0xc6>

0000000080004af2 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004af2:	1101                	addi	sp,sp,-32
    80004af4:	ec06                	sd	ra,24(sp)
    80004af6:	e822                	sd	s0,16(sp)
    80004af8:	e426                	sd	s1,8(sp)
    80004afa:	e04a                	sd	s2,0(sp)
    80004afc:	1000                	addi	s0,sp,32
    80004afe:	84aa                	mv	s1,a0
    80004b00:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004b02:	ffffc097          	auipc	ra,0xffffc
    80004b06:	0e2080e7          	jalr	226(ra) # 80000be4 <acquire>
  if(writable){
    80004b0a:	02090d63          	beqz	s2,80004b44 <pipeclose+0x52>
    pi->writeopen = 0;
    80004b0e:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004b12:	21848513          	addi	a0,s1,536
    80004b16:	ffffe097          	auipc	ra,0xffffe
    80004b1a:	8f4080e7          	jalr	-1804(ra) # 8000240a <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004b1e:	2204b783          	ld	a5,544(s1)
    80004b22:	eb95                	bnez	a5,80004b56 <pipeclose+0x64>
    release(&pi->lock);
    80004b24:	8526                	mv	a0,s1
    80004b26:	ffffc097          	auipc	ra,0xffffc
    80004b2a:	172080e7          	jalr	370(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004b2e:	8526                	mv	a0,s1
    80004b30:	ffffc097          	auipc	ra,0xffffc
    80004b34:	ec8080e7          	jalr	-312(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004b38:	60e2                	ld	ra,24(sp)
    80004b3a:	6442                	ld	s0,16(sp)
    80004b3c:	64a2                	ld	s1,8(sp)
    80004b3e:	6902                	ld	s2,0(sp)
    80004b40:	6105                	addi	sp,sp,32
    80004b42:	8082                	ret
    pi->readopen = 0;
    80004b44:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004b48:	21c48513          	addi	a0,s1,540
    80004b4c:	ffffe097          	auipc	ra,0xffffe
    80004b50:	8be080e7          	jalr	-1858(ra) # 8000240a <wakeup>
    80004b54:	b7e9                	j	80004b1e <pipeclose+0x2c>
    release(&pi->lock);
    80004b56:	8526                	mv	a0,s1
    80004b58:	ffffc097          	auipc	ra,0xffffc
    80004b5c:	140080e7          	jalr	320(ra) # 80000c98 <release>
}
    80004b60:	bfe1                	j	80004b38 <pipeclose+0x46>

0000000080004b62 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004b62:	7159                	addi	sp,sp,-112
    80004b64:	f486                	sd	ra,104(sp)
    80004b66:	f0a2                	sd	s0,96(sp)
    80004b68:	eca6                	sd	s1,88(sp)
    80004b6a:	e8ca                	sd	s2,80(sp)
    80004b6c:	e4ce                	sd	s3,72(sp)
    80004b6e:	e0d2                	sd	s4,64(sp)
    80004b70:	fc56                	sd	s5,56(sp)
    80004b72:	f85a                	sd	s6,48(sp)
    80004b74:	f45e                	sd	s7,40(sp)
    80004b76:	f062                	sd	s8,32(sp)
    80004b78:	ec66                	sd	s9,24(sp)
    80004b7a:	1880                	addi	s0,sp,112
    80004b7c:	84aa                	mv	s1,a0
    80004b7e:	8aae                	mv	s5,a1
    80004b80:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004b82:	ffffd097          	auipc	ra,0xffffd
    80004b86:	f0a080e7          	jalr	-246(ra) # 80001a8c <myproc>
    80004b8a:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004b8c:	8526                	mv	a0,s1
    80004b8e:	ffffc097          	auipc	ra,0xffffc
    80004b92:	056080e7          	jalr	86(ra) # 80000be4 <acquire>
  while(i < n){
    80004b96:	0d405163          	blez	s4,80004c58 <pipewrite+0xf6>
    80004b9a:	8ba6                	mv	s7,s1
  int i = 0;
    80004b9c:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b9e:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004ba0:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004ba4:	21c48c13          	addi	s8,s1,540
    80004ba8:	a08d                	j	80004c0a <pipewrite+0xa8>
      release(&pi->lock);
    80004baa:	8526                	mv	a0,s1
    80004bac:	ffffc097          	auipc	ra,0xffffc
    80004bb0:	0ec080e7          	jalr	236(ra) # 80000c98 <release>
      return -1;
    80004bb4:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004bb6:	854a                	mv	a0,s2
    80004bb8:	70a6                	ld	ra,104(sp)
    80004bba:	7406                	ld	s0,96(sp)
    80004bbc:	64e6                	ld	s1,88(sp)
    80004bbe:	6946                	ld	s2,80(sp)
    80004bc0:	69a6                	ld	s3,72(sp)
    80004bc2:	6a06                	ld	s4,64(sp)
    80004bc4:	7ae2                	ld	s5,56(sp)
    80004bc6:	7b42                	ld	s6,48(sp)
    80004bc8:	7ba2                	ld	s7,40(sp)
    80004bca:	7c02                	ld	s8,32(sp)
    80004bcc:	6ce2                	ld	s9,24(sp)
    80004bce:	6165                	addi	sp,sp,112
    80004bd0:	8082                	ret
      wakeup(&pi->nread);
    80004bd2:	8566                	mv	a0,s9
    80004bd4:	ffffe097          	auipc	ra,0xffffe
    80004bd8:	836080e7          	jalr	-1994(ra) # 8000240a <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004bdc:	85de                	mv	a1,s7
    80004bde:	8562                	mv	a0,s8
    80004be0:	ffffd097          	auipc	ra,0xffffd
    80004be4:	69e080e7          	jalr	1694(ra) # 8000227e <sleep>
    80004be8:	a839                	j	80004c06 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004bea:	21c4a783          	lw	a5,540(s1)
    80004bee:	0017871b          	addiw	a4,a5,1
    80004bf2:	20e4ae23          	sw	a4,540(s1)
    80004bf6:	1ff7f793          	andi	a5,a5,511
    80004bfa:	97a6                	add	a5,a5,s1
    80004bfc:	f9f44703          	lbu	a4,-97(s0)
    80004c00:	00e78c23          	sb	a4,24(a5)
      i++;
    80004c04:	2905                	addiw	s2,s2,1
  while(i < n){
    80004c06:	03495d63          	bge	s2,s4,80004c40 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004c0a:	2204a783          	lw	a5,544(s1)
    80004c0e:	dfd1                	beqz	a5,80004baa <pipewrite+0x48>
    80004c10:	0289a783          	lw	a5,40(s3)
    80004c14:	fbd9                	bnez	a5,80004baa <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004c16:	2184a783          	lw	a5,536(s1)
    80004c1a:	21c4a703          	lw	a4,540(s1)
    80004c1e:	2007879b          	addiw	a5,a5,512
    80004c22:	faf708e3          	beq	a4,a5,80004bd2 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c26:	4685                	li	a3,1
    80004c28:	01590633          	add	a2,s2,s5
    80004c2c:	f9f40593          	addi	a1,s0,-97
    80004c30:	0509b503          	ld	a0,80(s3)
    80004c34:	ffffd097          	auipc	ra,0xffffd
    80004c38:	aca080e7          	jalr	-1334(ra) # 800016fe <copyin>
    80004c3c:	fb6517e3          	bne	a0,s6,80004bea <pipewrite+0x88>
  wakeup(&pi->nread);
    80004c40:	21848513          	addi	a0,s1,536
    80004c44:	ffffd097          	auipc	ra,0xffffd
    80004c48:	7c6080e7          	jalr	1990(ra) # 8000240a <wakeup>
  release(&pi->lock);
    80004c4c:	8526                	mv	a0,s1
    80004c4e:	ffffc097          	auipc	ra,0xffffc
    80004c52:	04a080e7          	jalr	74(ra) # 80000c98 <release>
  return i;
    80004c56:	b785                	j	80004bb6 <pipewrite+0x54>
  int i = 0;
    80004c58:	4901                	li	s2,0
    80004c5a:	b7dd                	j	80004c40 <pipewrite+0xde>

0000000080004c5c <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004c5c:	715d                	addi	sp,sp,-80
    80004c5e:	e486                	sd	ra,72(sp)
    80004c60:	e0a2                	sd	s0,64(sp)
    80004c62:	fc26                	sd	s1,56(sp)
    80004c64:	f84a                	sd	s2,48(sp)
    80004c66:	f44e                	sd	s3,40(sp)
    80004c68:	f052                	sd	s4,32(sp)
    80004c6a:	ec56                	sd	s5,24(sp)
    80004c6c:	e85a                	sd	s6,16(sp)
    80004c6e:	0880                	addi	s0,sp,80
    80004c70:	84aa                	mv	s1,a0
    80004c72:	892e                	mv	s2,a1
    80004c74:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004c76:	ffffd097          	auipc	ra,0xffffd
    80004c7a:	e16080e7          	jalr	-490(ra) # 80001a8c <myproc>
    80004c7e:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004c80:	8b26                	mv	s6,s1
    80004c82:	8526                	mv	a0,s1
    80004c84:	ffffc097          	auipc	ra,0xffffc
    80004c88:	f60080e7          	jalr	-160(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c8c:	2184a703          	lw	a4,536(s1)
    80004c90:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c94:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c98:	02f71463          	bne	a4,a5,80004cc0 <piperead+0x64>
    80004c9c:	2244a783          	lw	a5,548(s1)
    80004ca0:	c385                	beqz	a5,80004cc0 <piperead+0x64>
    if(pr->killed){
    80004ca2:	028a2783          	lw	a5,40(s4)
    80004ca6:	ebc1                	bnez	a5,80004d36 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004ca8:	85da                	mv	a1,s6
    80004caa:	854e                	mv	a0,s3
    80004cac:	ffffd097          	auipc	ra,0xffffd
    80004cb0:	5d2080e7          	jalr	1490(ra) # 8000227e <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cb4:	2184a703          	lw	a4,536(s1)
    80004cb8:	21c4a783          	lw	a5,540(s1)
    80004cbc:	fef700e3          	beq	a4,a5,80004c9c <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cc0:	09505263          	blez	s5,80004d44 <piperead+0xe8>
    80004cc4:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004cc6:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004cc8:	2184a783          	lw	a5,536(s1)
    80004ccc:	21c4a703          	lw	a4,540(s1)
    80004cd0:	02f70d63          	beq	a4,a5,80004d0a <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004cd4:	0017871b          	addiw	a4,a5,1
    80004cd8:	20e4ac23          	sw	a4,536(s1)
    80004cdc:	1ff7f793          	andi	a5,a5,511
    80004ce0:	97a6                	add	a5,a5,s1
    80004ce2:	0187c783          	lbu	a5,24(a5)
    80004ce6:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004cea:	4685                	li	a3,1
    80004cec:	fbf40613          	addi	a2,s0,-65
    80004cf0:	85ca                	mv	a1,s2
    80004cf2:	050a3503          	ld	a0,80(s4)
    80004cf6:	ffffd097          	auipc	ra,0xffffd
    80004cfa:	97c080e7          	jalr	-1668(ra) # 80001672 <copyout>
    80004cfe:	01650663          	beq	a0,s6,80004d0a <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d02:	2985                	addiw	s3,s3,1
    80004d04:	0905                	addi	s2,s2,1
    80004d06:	fd3a91e3          	bne	s5,s3,80004cc8 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004d0a:	21c48513          	addi	a0,s1,540
    80004d0e:	ffffd097          	auipc	ra,0xffffd
    80004d12:	6fc080e7          	jalr	1788(ra) # 8000240a <wakeup>
  release(&pi->lock);
    80004d16:	8526                	mv	a0,s1
    80004d18:	ffffc097          	auipc	ra,0xffffc
    80004d1c:	f80080e7          	jalr	-128(ra) # 80000c98 <release>
  return i;
}
    80004d20:	854e                	mv	a0,s3
    80004d22:	60a6                	ld	ra,72(sp)
    80004d24:	6406                	ld	s0,64(sp)
    80004d26:	74e2                	ld	s1,56(sp)
    80004d28:	7942                	ld	s2,48(sp)
    80004d2a:	79a2                	ld	s3,40(sp)
    80004d2c:	7a02                	ld	s4,32(sp)
    80004d2e:	6ae2                	ld	s5,24(sp)
    80004d30:	6b42                	ld	s6,16(sp)
    80004d32:	6161                	addi	sp,sp,80
    80004d34:	8082                	ret
      release(&pi->lock);
    80004d36:	8526                	mv	a0,s1
    80004d38:	ffffc097          	auipc	ra,0xffffc
    80004d3c:	f60080e7          	jalr	-160(ra) # 80000c98 <release>
      return -1;
    80004d40:	59fd                	li	s3,-1
    80004d42:	bff9                	j	80004d20 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d44:	4981                	li	s3,0
    80004d46:	b7d1                	j	80004d0a <piperead+0xae>

0000000080004d48 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004d48:	df010113          	addi	sp,sp,-528
    80004d4c:	20113423          	sd	ra,520(sp)
    80004d50:	20813023          	sd	s0,512(sp)
    80004d54:	ffa6                	sd	s1,504(sp)
    80004d56:	fbca                	sd	s2,496(sp)
    80004d58:	f7ce                	sd	s3,488(sp)
    80004d5a:	f3d2                	sd	s4,480(sp)
    80004d5c:	efd6                	sd	s5,472(sp)
    80004d5e:	ebda                	sd	s6,464(sp)
    80004d60:	e7de                	sd	s7,456(sp)
    80004d62:	e3e2                	sd	s8,448(sp)
    80004d64:	ff66                	sd	s9,440(sp)
    80004d66:	fb6a                	sd	s10,432(sp)
    80004d68:	f76e                	sd	s11,424(sp)
    80004d6a:	0c00                	addi	s0,sp,528
    80004d6c:	84aa                	mv	s1,a0
    80004d6e:	dea43c23          	sd	a0,-520(s0)
    80004d72:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004d76:	ffffd097          	auipc	ra,0xffffd
    80004d7a:	d16080e7          	jalr	-746(ra) # 80001a8c <myproc>
    80004d7e:	892a                	mv	s2,a0

  begin_op();
    80004d80:	fffff097          	auipc	ra,0xfffff
    80004d84:	49c080e7          	jalr	1180(ra) # 8000421c <begin_op>

  if((ip = namei(path)) == 0){
    80004d88:	8526                	mv	a0,s1
    80004d8a:	fffff097          	auipc	ra,0xfffff
    80004d8e:	276080e7          	jalr	630(ra) # 80004000 <namei>
    80004d92:	c92d                	beqz	a0,80004e04 <exec+0xbc>
    80004d94:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d96:	fffff097          	auipc	ra,0xfffff
    80004d9a:	ab4080e7          	jalr	-1356(ra) # 8000384a <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d9e:	04000713          	li	a4,64
    80004da2:	4681                	li	a3,0
    80004da4:	e5040613          	addi	a2,s0,-432
    80004da8:	4581                	li	a1,0
    80004daa:	8526                	mv	a0,s1
    80004dac:	fffff097          	auipc	ra,0xfffff
    80004db0:	d52080e7          	jalr	-686(ra) # 80003afe <readi>
    80004db4:	04000793          	li	a5,64
    80004db8:	00f51a63          	bne	a0,a5,80004dcc <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004dbc:	e5042703          	lw	a4,-432(s0)
    80004dc0:	464c47b7          	lui	a5,0x464c4
    80004dc4:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004dc8:	04f70463          	beq	a4,a5,80004e10 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004dcc:	8526                	mv	a0,s1
    80004dce:	fffff097          	auipc	ra,0xfffff
    80004dd2:	cde080e7          	jalr	-802(ra) # 80003aac <iunlockput>
    end_op();
    80004dd6:	fffff097          	auipc	ra,0xfffff
    80004dda:	4c6080e7          	jalr	1222(ra) # 8000429c <end_op>
  }
  return -1;
    80004dde:	557d                	li	a0,-1
}
    80004de0:	20813083          	ld	ra,520(sp)
    80004de4:	20013403          	ld	s0,512(sp)
    80004de8:	74fe                	ld	s1,504(sp)
    80004dea:	795e                	ld	s2,496(sp)
    80004dec:	79be                	ld	s3,488(sp)
    80004dee:	7a1e                	ld	s4,480(sp)
    80004df0:	6afe                	ld	s5,472(sp)
    80004df2:	6b5e                	ld	s6,464(sp)
    80004df4:	6bbe                	ld	s7,456(sp)
    80004df6:	6c1e                	ld	s8,448(sp)
    80004df8:	7cfa                	ld	s9,440(sp)
    80004dfa:	7d5a                	ld	s10,432(sp)
    80004dfc:	7dba                	ld	s11,424(sp)
    80004dfe:	21010113          	addi	sp,sp,528
    80004e02:	8082                	ret
    end_op();
    80004e04:	fffff097          	auipc	ra,0xfffff
    80004e08:	498080e7          	jalr	1176(ra) # 8000429c <end_op>
    return -1;
    80004e0c:	557d                	li	a0,-1
    80004e0e:	bfc9                	j	80004de0 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004e10:	854a                	mv	a0,s2
    80004e12:	ffffd097          	auipc	ra,0xffffd
    80004e16:	e1c080e7          	jalr	-484(ra) # 80001c2e <proc_pagetable>
    80004e1a:	8baa                	mv	s7,a0
    80004e1c:	d945                	beqz	a0,80004dcc <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e1e:	e7042983          	lw	s3,-400(s0)
    80004e22:	e8845783          	lhu	a5,-376(s0)
    80004e26:	c7ad                	beqz	a5,80004e90 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e28:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e2a:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004e2c:	6c85                	lui	s9,0x1
    80004e2e:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004e32:	def43823          	sd	a5,-528(s0)
    80004e36:	a42d                	j	80005060 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004e38:	00004517          	auipc	a0,0x4
    80004e3c:	94850513          	addi	a0,a0,-1720 # 80008780 <syscalls+0x290>
    80004e40:	ffffb097          	auipc	ra,0xffffb
    80004e44:	6fe080e7          	jalr	1790(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004e48:	8756                	mv	a4,s5
    80004e4a:	012d86bb          	addw	a3,s11,s2
    80004e4e:	4581                	li	a1,0
    80004e50:	8526                	mv	a0,s1
    80004e52:	fffff097          	auipc	ra,0xfffff
    80004e56:	cac080e7          	jalr	-852(ra) # 80003afe <readi>
    80004e5a:	2501                	sext.w	a0,a0
    80004e5c:	1aaa9963          	bne	s5,a0,8000500e <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004e60:	6785                	lui	a5,0x1
    80004e62:	0127893b          	addw	s2,a5,s2
    80004e66:	77fd                	lui	a5,0xfffff
    80004e68:	01478a3b          	addw	s4,a5,s4
    80004e6c:	1f897163          	bgeu	s2,s8,8000504e <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004e70:	02091593          	slli	a1,s2,0x20
    80004e74:	9181                	srli	a1,a1,0x20
    80004e76:	95ea                	add	a1,a1,s10
    80004e78:	855e                	mv	a0,s7
    80004e7a:	ffffc097          	auipc	ra,0xffffc
    80004e7e:	1f4080e7          	jalr	500(ra) # 8000106e <walkaddr>
    80004e82:	862a                	mv	a2,a0
    if(pa == 0)
    80004e84:	d955                	beqz	a0,80004e38 <exec+0xf0>
      n = PGSIZE;
    80004e86:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004e88:	fd9a70e3          	bgeu	s4,s9,80004e48 <exec+0x100>
      n = sz - i;
    80004e8c:	8ad2                	mv	s5,s4
    80004e8e:	bf6d                	j	80004e48 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e90:	4901                	li	s2,0
  iunlockput(ip);
    80004e92:	8526                	mv	a0,s1
    80004e94:	fffff097          	auipc	ra,0xfffff
    80004e98:	c18080e7          	jalr	-1000(ra) # 80003aac <iunlockput>
  end_op();
    80004e9c:	fffff097          	auipc	ra,0xfffff
    80004ea0:	400080e7          	jalr	1024(ra) # 8000429c <end_op>
  p = myproc();
    80004ea4:	ffffd097          	auipc	ra,0xffffd
    80004ea8:	be8080e7          	jalr	-1048(ra) # 80001a8c <myproc>
    80004eac:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004eae:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004eb2:	6785                	lui	a5,0x1
    80004eb4:	17fd                	addi	a5,a5,-1
    80004eb6:	993e                	add	s2,s2,a5
    80004eb8:	757d                	lui	a0,0xfffff
    80004eba:	00a977b3          	and	a5,s2,a0
    80004ebe:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004ec2:	6609                	lui	a2,0x2
    80004ec4:	963e                	add	a2,a2,a5
    80004ec6:	85be                	mv	a1,a5
    80004ec8:	855e                	mv	a0,s7
    80004eca:	ffffc097          	auipc	ra,0xffffc
    80004ece:	558080e7          	jalr	1368(ra) # 80001422 <uvmalloc>
    80004ed2:	8b2a                	mv	s6,a0
  ip = 0;
    80004ed4:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004ed6:	12050c63          	beqz	a0,8000500e <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004eda:	75f9                	lui	a1,0xffffe
    80004edc:	95aa                	add	a1,a1,a0
    80004ede:	855e                	mv	a0,s7
    80004ee0:	ffffc097          	auipc	ra,0xffffc
    80004ee4:	760080e7          	jalr	1888(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80004ee8:	7c7d                	lui	s8,0xfffff
    80004eea:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004eec:	e0043783          	ld	a5,-512(s0)
    80004ef0:	6388                	ld	a0,0(a5)
    80004ef2:	c535                	beqz	a0,80004f5e <exec+0x216>
    80004ef4:	e9040993          	addi	s3,s0,-368
    80004ef8:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004efc:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004efe:	ffffc097          	auipc	ra,0xffffc
    80004f02:	f66080e7          	jalr	-154(ra) # 80000e64 <strlen>
    80004f06:	2505                	addiw	a0,a0,1
    80004f08:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004f0c:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004f10:	13896363          	bltu	s2,s8,80005036 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004f14:	e0043d83          	ld	s11,-512(s0)
    80004f18:	000dba03          	ld	s4,0(s11)
    80004f1c:	8552                	mv	a0,s4
    80004f1e:	ffffc097          	auipc	ra,0xffffc
    80004f22:	f46080e7          	jalr	-186(ra) # 80000e64 <strlen>
    80004f26:	0015069b          	addiw	a3,a0,1
    80004f2a:	8652                	mv	a2,s4
    80004f2c:	85ca                	mv	a1,s2
    80004f2e:	855e                	mv	a0,s7
    80004f30:	ffffc097          	auipc	ra,0xffffc
    80004f34:	742080e7          	jalr	1858(ra) # 80001672 <copyout>
    80004f38:	10054363          	bltz	a0,8000503e <exec+0x2f6>
    ustack[argc] = sp;
    80004f3c:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004f40:	0485                	addi	s1,s1,1
    80004f42:	008d8793          	addi	a5,s11,8
    80004f46:	e0f43023          	sd	a5,-512(s0)
    80004f4a:	008db503          	ld	a0,8(s11)
    80004f4e:	c911                	beqz	a0,80004f62 <exec+0x21a>
    if(argc >= MAXARG)
    80004f50:	09a1                	addi	s3,s3,8
    80004f52:	fb3c96e3          	bne	s9,s3,80004efe <exec+0x1b6>
  sz = sz1;
    80004f56:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f5a:	4481                	li	s1,0
    80004f5c:	a84d                	j	8000500e <exec+0x2c6>
  sp = sz;
    80004f5e:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f60:	4481                	li	s1,0
  ustack[argc] = 0;
    80004f62:	00349793          	slli	a5,s1,0x3
    80004f66:	f9040713          	addi	a4,s0,-112
    80004f6a:	97ba                	add	a5,a5,a4
    80004f6c:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004f70:	00148693          	addi	a3,s1,1
    80004f74:	068e                	slli	a3,a3,0x3
    80004f76:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f7a:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004f7e:	01897663          	bgeu	s2,s8,80004f8a <exec+0x242>
  sz = sz1;
    80004f82:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f86:	4481                	li	s1,0
    80004f88:	a059                	j	8000500e <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f8a:	e9040613          	addi	a2,s0,-368
    80004f8e:	85ca                	mv	a1,s2
    80004f90:	855e                	mv	a0,s7
    80004f92:	ffffc097          	auipc	ra,0xffffc
    80004f96:	6e0080e7          	jalr	1760(ra) # 80001672 <copyout>
    80004f9a:	0a054663          	bltz	a0,80005046 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004f9e:	058ab783          	ld	a5,88(s5)
    80004fa2:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004fa6:	df843783          	ld	a5,-520(s0)
    80004faa:	0007c703          	lbu	a4,0(a5)
    80004fae:	cf11                	beqz	a4,80004fca <exec+0x282>
    80004fb0:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004fb2:	02f00693          	li	a3,47
    80004fb6:	a039                	j	80004fc4 <exec+0x27c>
      last = s+1;
    80004fb8:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004fbc:	0785                	addi	a5,a5,1
    80004fbe:	fff7c703          	lbu	a4,-1(a5)
    80004fc2:	c701                	beqz	a4,80004fca <exec+0x282>
    if(*s == '/')
    80004fc4:	fed71ce3          	bne	a4,a3,80004fbc <exec+0x274>
    80004fc8:	bfc5                	j	80004fb8 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004fca:	4641                	li	a2,16
    80004fcc:	df843583          	ld	a1,-520(s0)
    80004fd0:	158a8513          	addi	a0,s5,344
    80004fd4:	ffffc097          	auipc	ra,0xffffc
    80004fd8:	e5e080e7          	jalr	-418(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80004fdc:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004fe0:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004fe4:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004fe8:	058ab783          	ld	a5,88(s5)
    80004fec:	e6843703          	ld	a4,-408(s0)
    80004ff0:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004ff2:	058ab783          	ld	a5,88(s5)
    80004ff6:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004ffa:	85ea                	mv	a1,s10
    80004ffc:	ffffd097          	auipc	ra,0xffffd
    80005000:	cce080e7          	jalr	-818(ra) # 80001cca <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005004:	0004851b          	sext.w	a0,s1
    80005008:	bbe1                	j	80004de0 <exec+0x98>
    8000500a:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    8000500e:	e0843583          	ld	a1,-504(s0)
    80005012:	855e                	mv	a0,s7
    80005014:	ffffd097          	auipc	ra,0xffffd
    80005018:	cb6080e7          	jalr	-842(ra) # 80001cca <proc_freepagetable>
  if(ip){
    8000501c:	da0498e3          	bnez	s1,80004dcc <exec+0x84>
  return -1;
    80005020:	557d                	li	a0,-1
    80005022:	bb7d                	j	80004de0 <exec+0x98>
    80005024:	e1243423          	sd	s2,-504(s0)
    80005028:	b7dd                	j	8000500e <exec+0x2c6>
    8000502a:	e1243423          	sd	s2,-504(s0)
    8000502e:	b7c5                	j	8000500e <exec+0x2c6>
    80005030:	e1243423          	sd	s2,-504(s0)
    80005034:	bfe9                	j	8000500e <exec+0x2c6>
  sz = sz1;
    80005036:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000503a:	4481                	li	s1,0
    8000503c:	bfc9                	j	8000500e <exec+0x2c6>
  sz = sz1;
    8000503e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005042:	4481                	li	s1,0
    80005044:	b7e9                	j	8000500e <exec+0x2c6>
  sz = sz1;
    80005046:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000504a:	4481                	li	s1,0
    8000504c:	b7c9                	j	8000500e <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000504e:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005052:	2b05                	addiw	s6,s6,1
    80005054:	0389899b          	addiw	s3,s3,56
    80005058:	e8845783          	lhu	a5,-376(s0)
    8000505c:	e2fb5be3          	bge	s6,a5,80004e92 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005060:	2981                	sext.w	s3,s3
    80005062:	03800713          	li	a4,56
    80005066:	86ce                	mv	a3,s3
    80005068:	e1840613          	addi	a2,s0,-488
    8000506c:	4581                	li	a1,0
    8000506e:	8526                	mv	a0,s1
    80005070:	fffff097          	auipc	ra,0xfffff
    80005074:	a8e080e7          	jalr	-1394(ra) # 80003afe <readi>
    80005078:	03800793          	li	a5,56
    8000507c:	f8f517e3          	bne	a0,a5,8000500a <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005080:	e1842783          	lw	a5,-488(s0)
    80005084:	4705                	li	a4,1
    80005086:	fce796e3          	bne	a5,a4,80005052 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    8000508a:	e4043603          	ld	a2,-448(s0)
    8000508e:	e3843783          	ld	a5,-456(s0)
    80005092:	f8f669e3          	bltu	a2,a5,80005024 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005096:	e2843783          	ld	a5,-472(s0)
    8000509a:	963e                	add	a2,a2,a5
    8000509c:	f8f667e3          	bltu	a2,a5,8000502a <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800050a0:	85ca                	mv	a1,s2
    800050a2:	855e                	mv	a0,s7
    800050a4:	ffffc097          	auipc	ra,0xffffc
    800050a8:	37e080e7          	jalr	894(ra) # 80001422 <uvmalloc>
    800050ac:	e0a43423          	sd	a0,-504(s0)
    800050b0:	d141                	beqz	a0,80005030 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    800050b2:	e2843d03          	ld	s10,-472(s0)
    800050b6:	df043783          	ld	a5,-528(s0)
    800050ba:	00fd77b3          	and	a5,s10,a5
    800050be:	fba1                	bnez	a5,8000500e <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800050c0:	e2042d83          	lw	s11,-480(s0)
    800050c4:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800050c8:	f80c03e3          	beqz	s8,8000504e <exec+0x306>
    800050cc:	8a62                	mv	s4,s8
    800050ce:	4901                	li	s2,0
    800050d0:	b345                	j	80004e70 <exec+0x128>

00000000800050d2 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800050d2:	7179                	addi	sp,sp,-48
    800050d4:	f406                	sd	ra,40(sp)
    800050d6:	f022                	sd	s0,32(sp)
    800050d8:	ec26                	sd	s1,24(sp)
    800050da:	e84a                	sd	s2,16(sp)
    800050dc:	1800                	addi	s0,sp,48
    800050de:	892e                	mv	s2,a1
    800050e0:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800050e2:	fdc40593          	addi	a1,s0,-36
    800050e6:	ffffe097          	auipc	ra,0xffffe
    800050ea:	b88080e7          	jalr	-1144(ra) # 80002c6e <argint>
    800050ee:	04054063          	bltz	a0,8000512e <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800050f2:	fdc42703          	lw	a4,-36(s0)
    800050f6:	47bd                	li	a5,15
    800050f8:	02e7ed63          	bltu	a5,a4,80005132 <argfd+0x60>
    800050fc:	ffffd097          	auipc	ra,0xffffd
    80005100:	990080e7          	jalr	-1648(ra) # 80001a8c <myproc>
    80005104:	fdc42703          	lw	a4,-36(s0)
    80005108:	01a70793          	addi	a5,a4,26
    8000510c:	078e                	slli	a5,a5,0x3
    8000510e:	953e                	add	a0,a0,a5
    80005110:	611c                	ld	a5,0(a0)
    80005112:	c395                	beqz	a5,80005136 <argfd+0x64>
    return -1;
  if(pfd)
    80005114:	00090463          	beqz	s2,8000511c <argfd+0x4a>
    *pfd = fd;
    80005118:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000511c:	4501                	li	a0,0
  if(pf)
    8000511e:	c091                	beqz	s1,80005122 <argfd+0x50>
    *pf = f;
    80005120:	e09c                	sd	a5,0(s1)
}
    80005122:	70a2                	ld	ra,40(sp)
    80005124:	7402                	ld	s0,32(sp)
    80005126:	64e2                	ld	s1,24(sp)
    80005128:	6942                	ld	s2,16(sp)
    8000512a:	6145                	addi	sp,sp,48
    8000512c:	8082                	ret
    return -1;
    8000512e:	557d                	li	a0,-1
    80005130:	bfcd                	j	80005122 <argfd+0x50>
    return -1;
    80005132:	557d                	li	a0,-1
    80005134:	b7fd                	j	80005122 <argfd+0x50>
    80005136:	557d                	li	a0,-1
    80005138:	b7ed                	j	80005122 <argfd+0x50>

000000008000513a <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000513a:	1101                	addi	sp,sp,-32
    8000513c:	ec06                	sd	ra,24(sp)
    8000513e:	e822                	sd	s0,16(sp)
    80005140:	e426                	sd	s1,8(sp)
    80005142:	1000                	addi	s0,sp,32
    80005144:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005146:	ffffd097          	auipc	ra,0xffffd
    8000514a:	946080e7          	jalr	-1722(ra) # 80001a8c <myproc>
    8000514e:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005150:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd7d50>
    80005154:	4501                	li	a0,0
    80005156:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005158:	6398                	ld	a4,0(a5)
    8000515a:	cb19                	beqz	a4,80005170 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000515c:	2505                	addiw	a0,a0,1
    8000515e:	07a1                	addi	a5,a5,8
    80005160:	fed51ce3          	bne	a0,a3,80005158 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005164:	557d                	li	a0,-1
}
    80005166:	60e2                	ld	ra,24(sp)
    80005168:	6442                	ld	s0,16(sp)
    8000516a:	64a2                	ld	s1,8(sp)
    8000516c:	6105                	addi	sp,sp,32
    8000516e:	8082                	ret
      p->ofile[fd] = f;
    80005170:	01a50793          	addi	a5,a0,26
    80005174:	078e                	slli	a5,a5,0x3
    80005176:	963e                	add	a2,a2,a5
    80005178:	e204                	sd	s1,0(a2)
      return fd;
    8000517a:	b7f5                	j	80005166 <fdalloc+0x2c>

000000008000517c <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000517c:	715d                	addi	sp,sp,-80
    8000517e:	e486                	sd	ra,72(sp)
    80005180:	e0a2                	sd	s0,64(sp)
    80005182:	fc26                	sd	s1,56(sp)
    80005184:	f84a                	sd	s2,48(sp)
    80005186:	f44e                	sd	s3,40(sp)
    80005188:	f052                	sd	s4,32(sp)
    8000518a:	ec56                	sd	s5,24(sp)
    8000518c:	0880                	addi	s0,sp,80
    8000518e:	89ae                	mv	s3,a1
    80005190:	8ab2                	mv	s5,a2
    80005192:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005194:	fb040593          	addi	a1,s0,-80
    80005198:	fffff097          	auipc	ra,0xfffff
    8000519c:	e86080e7          	jalr	-378(ra) # 8000401e <nameiparent>
    800051a0:	892a                	mv	s2,a0
    800051a2:	12050f63          	beqz	a0,800052e0 <create+0x164>
    return 0;

  ilock(dp);
    800051a6:	ffffe097          	auipc	ra,0xffffe
    800051aa:	6a4080e7          	jalr	1700(ra) # 8000384a <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800051ae:	4601                	li	a2,0
    800051b0:	fb040593          	addi	a1,s0,-80
    800051b4:	854a                	mv	a0,s2
    800051b6:	fffff097          	auipc	ra,0xfffff
    800051ba:	b78080e7          	jalr	-1160(ra) # 80003d2e <dirlookup>
    800051be:	84aa                	mv	s1,a0
    800051c0:	c921                	beqz	a0,80005210 <create+0x94>
    iunlockput(dp);
    800051c2:	854a                	mv	a0,s2
    800051c4:	fffff097          	auipc	ra,0xfffff
    800051c8:	8e8080e7          	jalr	-1816(ra) # 80003aac <iunlockput>
    ilock(ip);
    800051cc:	8526                	mv	a0,s1
    800051ce:	ffffe097          	auipc	ra,0xffffe
    800051d2:	67c080e7          	jalr	1660(ra) # 8000384a <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800051d6:	2981                	sext.w	s3,s3
    800051d8:	4789                	li	a5,2
    800051da:	02f99463          	bne	s3,a5,80005202 <create+0x86>
    800051de:	0444d783          	lhu	a5,68(s1)
    800051e2:	37f9                	addiw	a5,a5,-2
    800051e4:	17c2                	slli	a5,a5,0x30
    800051e6:	93c1                	srli	a5,a5,0x30
    800051e8:	4705                	li	a4,1
    800051ea:	00f76c63          	bltu	a4,a5,80005202 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800051ee:	8526                	mv	a0,s1
    800051f0:	60a6                	ld	ra,72(sp)
    800051f2:	6406                	ld	s0,64(sp)
    800051f4:	74e2                	ld	s1,56(sp)
    800051f6:	7942                	ld	s2,48(sp)
    800051f8:	79a2                	ld	s3,40(sp)
    800051fa:	7a02                	ld	s4,32(sp)
    800051fc:	6ae2                	ld	s5,24(sp)
    800051fe:	6161                	addi	sp,sp,80
    80005200:	8082                	ret
    iunlockput(ip);
    80005202:	8526                	mv	a0,s1
    80005204:	fffff097          	auipc	ra,0xfffff
    80005208:	8a8080e7          	jalr	-1880(ra) # 80003aac <iunlockput>
    return 0;
    8000520c:	4481                	li	s1,0
    8000520e:	b7c5                	j	800051ee <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005210:	85ce                	mv	a1,s3
    80005212:	00092503          	lw	a0,0(s2)
    80005216:	ffffe097          	auipc	ra,0xffffe
    8000521a:	49c080e7          	jalr	1180(ra) # 800036b2 <ialloc>
    8000521e:	84aa                	mv	s1,a0
    80005220:	c529                	beqz	a0,8000526a <create+0xee>
  ilock(ip);
    80005222:	ffffe097          	auipc	ra,0xffffe
    80005226:	628080e7          	jalr	1576(ra) # 8000384a <ilock>
  ip->major = major;
    8000522a:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000522e:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005232:	4785                	li	a5,1
    80005234:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005238:	8526                	mv	a0,s1
    8000523a:	ffffe097          	auipc	ra,0xffffe
    8000523e:	546080e7          	jalr	1350(ra) # 80003780 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005242:	2981                	sext.w	s3,s3
    80005244:	4785                	li	a5,1
    80005246:	02f98a63          	beq	s3,a5,8000527a <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    8000524a:	40d0                	lw	a2,4(s1)
    8000524c:	fb040593          	addi	a1,s0,-80
    80005250:	854a                	mv	a0,s2
    80005252:	fffff097          	auipc	ra,0xfffff
    80005256:	cec080e7          	jalr	-788(ra) # 80003f3e <dirlink>
    8000525a:	06054b63          	bltz	a0,800052d0 <create+0x154>
  iunlockput(dp);
    8000525e:	854a                	mv	a0,s2
    80005260:	fffff097          	auipc	ra,0xfffff
    80005264:	84c080e7          	jalr	-1972(ra) # 80003aac <iunlockput>
  return ip;
    80005268:	b759                	j	800051ee <create+0x72>
    panic("create: ialloc");
    8000526a:	00003517          	auipc	a0,0x3
    8000526e:	53650513          	addi	a0,a0,1334 # 800087a0 <syscalls+0x2b0>
    80005272:	ffffb097          	auipc	ra,0xffffb
    80005276:	2cc080e7          	jalr	716(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    8000527a:	04a95783          	lhu	a5,74(s2)
    8000527e:	2785                	addiw	a5,a5,1
    80005280:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005284:	854a                	mv	a0,s2
    80005286:	ffffe097          	auipc	ra,0xffffe
    8000528a:	4fa080e7          	jalr	1274(ra) # 80003780 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000528e:	40d0                	lw	a2,4(s1)
    80005290:	00003597          	auipc	a1,0x3
    80005294:	52058593          	addi	a1,a1,1312 # 800087b0 <syscalls+0x2c0>
    80005298:	8526                	mv	a0,s1
    8000529a:	fffff097          	auipc	ra,0xfffff
    8000529e:	ca4080e7          	jalr	-860(ra) # 80003f3e <dirlink>
    800052a2:	00054f63          	bltz	a0,800052c0 <create+0x144>
    800052a6:	00492603          	lw	a2,4(s2)
    800052aa:	00003597          	auipc	a1,0x3
    800052ae:	50e58593          	addi	a1,a1,1294 # 800087b8 <syscalls+0x2c8>
    800052b2:	8526                	mv	a0,s1
    800052b4:	fffff097          	auipc	ra,0xfffff
    800052b8:	c8a080e7          	jalr	-886(ra) # 80003f3e <dirlink>
    800052bc:	f80557e3          	bgez	a0,8000524a <create+0xce>
      panic("create dots");
    800052c0:	00003517          	auipc	a0,0x3
    800052c4:	50050513          	addi	a0,a0,1280 # 800087c0 <syscalls+0x2d0>
    800052c8:	ffffb097          	auipc	ra,0xffffb
    800052cc:	276080e7          	jalr	630(ra) # 8000053e <panic>
    panic("create: dirlink");
    800052d0:	00003517          	auipc	a0,0x3
    800052d4:	50050513          	addi	a0,a0,1280 # 800087d0 <syscalls+0x2e0>
    800052d8:	ffffb097          	auipc	ra,0xffffb
    800052dc:	266080e7          	jalr	614(ra) # 8000053e <panic>
    return 0;
    800052e0:	84aa                	mv	s1,a0
    800052e2:	b731                	j	800051ee <create+0x72>

00000000800052e4 <sys_dup>:
{
    800052e4:	7179                	addi	sp,sp,-48
    800052e6:	f406                	sd	ra,40(sp)
    800052e8:	f022                	sd	s0,32(sp)
    800052ea:	ec26                	sd	s1,24(sp)
    800052ec:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800052ee:	fd840613          	addi	a2,s0,-40
    800052f2:	4581                	li	a1,0
    800052f4:	4501                	li	a0,0
    800052f6:	00000097          	auipc	ra,0x0
    800052fa:	ddc080e7          	jalr	-548(ra) # 800050d2 <argfd>
    return -1;
    800052fe:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005300:	02054363          	bltz	a0,80005326 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005304:	fd843503          	ld	a0,-40(s0)
    80005308:	00000097          	auipc	ra,0x0
    8000530c:	e32080e7          	jalr	-462(ra) # 8000513a <fdalloc>
    80005310:	84aa                	mv	s1,a0
    return -1;
    80005312:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005314:	00054963          	bltz	a0,80005326 <sys_dup+0x42>
  filedup(f);
    80005318:	fd843503          	ld	a0,-40(s0)
    8000531c:	fffff097          	auipc	ra,0xfffff
    80005320:	37a080e7          	jalr	890(ra) # 80004696 <filedup>
  return fd;
    80005324:	87a6                	mv	a5,s1
}
    80005326:	853e                	mv	a0,a5
    80005328:	70a2                	ld	ra,40(sp)
    8000532a:	7402                	ld	s0,32(sp)
    8000532c:	64e2                	ld	s1,24(sp)
    8000532e:	6145                	addi	sp,sp,48
    80005330:	8082                	ret

0000000080005332 <sys_read>:
{
    80005332:	7179                	addi	sp,sp,-48
    80005334:	f406                	sd	ra,40(sp)
    80005336:	f022                	sd	s0,32(sp)
    80005338:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000533a:	fe840613          	addi	a2,s0,-24
    8000533e:	4581                	li	a1,0
    80005340:	4501                	li	a0,0
    80005342:	00000097          	auipc	ra,0x0
    80005346:	d90080e7          	jalr	-624(ra) # 800050d2 <argfd>
    return -1;
    8000534a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000534c:	04054163          	bltz	a0,8000538e <sys_read+0x5c>
    80005350:	fe440593          	addi	a1,s0,-28
    80005354:	4509                	li	a0,2
    80005356:	ffffe097          	auipc	ra,0xffffe
    8000535a:	918080e7          	jalr	-1768(ra) # 80002c6e <argint>
    return -1;
    8000535e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005360:	02054763          	bltz	a0,8000538e <sys_read+0x5c>
    80005364:	fd840593          	addi	a1,s0,-40
    80005368:	4505                	li	a0,1
    8000536a:	ffffe097          	auipc	ra,0xffffe
    8000536e:	926080e7          	jalr	-1754(ra) # 80002c90 <argaddr>
    return -1;
    80005372:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005374:	00054d63          	bltz	a0,8000538e <sys_read+0x5c>
  return fileread(f, p, n);
    80005378:	fe442603          	lw	a2,-28(s0)
    8000537c:	fd843583          	ld	a1,-40(s0)
    80005380:	fe843503          	ld	a0,-24(s0)
    80005384:	fffff097          	auipc	ra,0xfffff
    80005388:	49e080e7          	jalr	1182(ra) # 80004822 <fileread>
    8000538c:	87aa                	mv	a5,a0
}
    8000538e:	853e                	mv	a0,a5
    80005390:	70a2                	ld	ra,40(sp)
    80005392:	7402                	ld	s0,32(sp)
    80005394:	6145                	addi	sp,sp,48
    80005396:	8082                	ret

0000000080005398 <sys_write>:
{
    80005398:	7179                	addi	sp,sp,-48
    8000539a:	f406                	sd	ra,40(sp)
    8000539c:	f022                	sd	s0,32(sp)
    8000539e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053a0:	fe840613          	addi	a2,s0,-24
    800053a4:	4581                	li	a1,0
    800053a6:	4501                	li	a0,0
    800053a8:	00000097          	auipc	ra,0x0
    800053ac:	d2a080e7          	jalr	-726(ra) # 800050d2 <argfd>
    return -1;
    800053b0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053b2:	04054163          	bltz	a0,800053f4 <sys_write+0x5c>
    800053b6:	fe440593          	addi	a1,s0,-28
    800053ba:	4509                	li	a0,2
    800053bc:	ffffe097          	auipc	ra,0xffffe
    800053c0:	8b2080e7          	jalr	-1870(ra) # 80002c6e <argint>
    return -1;
    800053c4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053c6:	02054763          	bltz	a0,800053f4 <sys_write+0x5c>
    800053ca:	fd840593          	addi	a1,s0,-40
    800053ce:	4505                	li	a0,1
    800053d0:	ffffe097          	auipc	ra,0xffffe
    800053d4:	8c0080e7          	jalr	-1856(ra) # 80002c90 <argaddr>
    return -1;
    800053d8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053da:	00054d63          	bltz	a0,800053f4 <sys_write+0x5c>
  return filewrite(f, p, n);
    800053de:	fe442603          	lw	a2,-28(s0)
    800053e2:	fd843583          	ld	a1,-40(s0)
    800053e6:	fe843503          	ld	a0,-24(s0)
    800053ea:	fffff097          	auipc	ra,0xfffff
    800053ee:	4fa080e7          	jalr	1274(ra) # 800048e4 <filewrite>
    800053f2:	87aa                	mv	a5,a0
}
    800053f4:	853e                	mv	a0,a5
    800053f6:	70a2                	ld	ra,40(sp)
    800053f8:	7402                	ld	s0,32(sp)
    800053fa:	6145                	addi	sp,sp,48
    800053fc:	8082                	ret

00000000800053fe <sys_close>:
{
    800053fe:	1101                	addi	sp,sp,-32
    80005400:	ec06                	sd	ra,24(sp)
    80005402:	e822                	sd	s0,16(sp)
    80005404:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005406:	fe040613          	addi	a2,s0,-32
    8000540a:	fec40593          	addi	a1,s0,-20
    8000540e:	4501                	li	a0,0
    80005410:	00000097          	auipc	ra,0x0
    80005414:	cc2080e7          	jalr	-830(ra) # 800050d2 <argfd>
    return -1;
    80005418:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000541a:	02054463          	bltz	a0,80005442 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000541e:	ffffc097          	auipc	ra,0xffffc
    80005422:	66e080e7          	jalr	1646(ra) # 80001a8c <myproc>
    80005426:	fec42783          	lw	a5,-20(s0)
    8000542a:	07e9                	addi	a5,a5,26
    8000542c:	078e                	slli	a5,a5,0x3
    8000542e:	97aa                	add	a5,a5,a0
    80005430:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005434:	fe043503          	ld	a0,-32(s0)
    80005438:	fffff097          	auipc	ra,0xfffff
    8000543c:	2b0080e7          	jalr	688(ra) # 800046e8 <fileclose>
  return 0;
    80005440:	4781                	li	a5,0
}
    80005442:	853e                	mv	a0,a5
    80005444:	60e2                	ld	ra,24(sp)
    80005446:	6442                	ld	s0,16(sp)
    80005448:	6105                	addi	sp,sp,32
    8000544a:	8082                	ret

000000008000544c <sys_fstat>:
{
    8000544c:	1101                	addi	sp,sp,-32
    8000544e:	ec06                	sd	ra,24(sp)
    80005450:	e822                	sd	s0,16(sp)
    80005452:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005454:	fe840613          	addi	a2,s0,-24
    80005458:	4581                	li	a1,0
    8000545a:	4501                	li	a0,0
    8000545c:	00000097          	auipc	ra,0x0
    80005460:	c76080e7          	jalr	-906(ra) # 800050d2 <argfd>
    return -1;
    80005464:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005466:	02054563          	bltz	a0,80005490 <sys_fstat+0x44>
    8000546a:	fe040593          	addi	a1,s0,-32
    8000546e:	4505                	li	a0,1
    80005470:	ffffe097          	auipc	ra,0xffffe
    80005474:	820080e7          	jalr	-2016(ra) # 80002c90 <argaddr>
    return -1;
    80005478:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000547a:	00054b63          	bltz	a0,80005490 <sys_fstat+0x44>
  return filestat(f, st);
    8000547e:	fe043583          	ld	a1,-32(s0)
    80005482:	fe843503          	ld	a0,-24(s0)
    80005486:	fffff097          	auipc	ra,0xfffff
    8000548a:	32a080e7          	jalr	810(ra) # 800047b0 <filestat>
    8000548e:	87aa                	mv	a5,a0
}
    80005490:	853e                	mv	a0,a5
    80005492:	60e2                	ld	ra,24(sp)
    80005494:	6442                	ld	s0,16(sp)
    80005496:	6105                	addi	sp,sp,32
    80005498:	8082                	ret

000000008000549a <sys_link>:
{
    8000549a:	7169                	addi	sp,sp,-304
    8000549c:	f606                	sd	ra,296(sp)
    8000549e:	f222                	sd	s0,288(sp)
    800054a0:	ee26                	sd	s1,280(sp)
    800054a2:	ea4a                	sd	s2,272(sp)
    800054a4:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054a6:	08000613          	li	a2,128
    800054aa:	ed040593          	addi	a1,s0,-304
    800054ae:	4501                	li	a0,0
    800054b0:	ffffe097          	auipc	ra,0xffffe
    800054b4:	802080e7          	jalr	-2046(ra) # 80002cb2 <argstr>
    return -1;
    800054b8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054ba:	10054e63          	bltz	a0,800055d6 <sys_link+0x13c>
    800054be:	08000613          	li	a2,128
    800054c2:	f5040593          	addi	a1,s0,-176
    800054c6:	4505                	li	a0,1
    800054c8:	ffffd097          	auipc	ra,0xffffd
    800054cc:	7ea080e7          	jalr	2026(ra) # 80002cb2 <argstr>
    return -1;
    800054d0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054d2:	10054263          	bltz	a0,800055d6 <sys_link+0x13c>
  begin_op();
    800054d6:	fffff097          	auipc	ra,0xfffff
    800054da:	d46080e7          	jalr	-698(ra) # 8000421c <begin_op>
  if((ip = namei(old)) == 0){
    800054de:	ed040513          	addi	a0,s0,-304
    800054e2:	fffff097          	auipc	ra,0xfffff
    800054e6:	b1e080e7          	jalr	-1250(ra) # 80004000 <namei>
    800054ea:	84aa                	mv	s1,a0
    800054ec:	c551                	beqz	a0,80005578 <sys_link+0xde>
  ilock(ip);
    800054ee:	ffffe097          	auipc	ra,0xffffe
    800054f2:	35c080e7          	jalr	860(ra) # 8000384a <ilock>
  if(ip->type == T_DIR){
    800054f6:	04449703          	lh	a4,68(s1)
    800054fa:	4785                	li	a5,1
    800054fc:	08f70463          	beq	a4,a5,80005584 <sys_link+0xea>
  ip->nlink++;
    80005500:	04a4d783          	lhu	a5,74(s1)
    80005504:	2785                	addiw	a5,a5,1
    80005506:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000550a:	8526                	mv	a0,s1
    8000550c:	ffffe097          	auipc	ra,0xffffe
    80005510:	274080e7          	jalr	628(ra) # 80003780 <iupdate>
  iunlock(ip);
    80005514:	8526                	mv	a0,s1
    80005516:	ffffe097          	auipc	ra,0xffffe
    8000551a:	3f6080e7          	jalr	1014(ra) # 8000390c <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000551e:	fd040593          	addi	a1,s0,-48
    80005522:	f5040513          	addi	a0,s0,-176
    80005526:	fffff097          	auipc	ra,0xfffff
    8000552a:	af8080e7          	jalr	-1288(ra) # 8000401e <nameiparent>
    8000552e:	892a                	mv	s2,a0
    80005530:	c935                	beqz	a0,800055a4 <sys_link+0x10a>
  ilock(dp);
    80005532:	ffffe097          	auipc	ra,0xffffe
    80005536:	318080e7          	jalr	792(ra) # 8000384a <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000553a:	00092703          	lw	a4,0(s2)
    8000553e:	409c                	lw	a5,0(s1)
    80005540:	04f71d63          	bne	a4,a5,8000559a <sys_link+0x100>
    80005544:	40d0                	lw	a2,4(s1)
    80005546:	fd040593          	addi	a1,s0,-48
    8000554a:	854a                	mv	a0,s2
    8000554c:	fffff097          	auipc	ra,0xfffff
    80005550:	9f2080e7          	jalr	-1550(ra) # 80003f3e <dirlink>
    80005554:	04054363          	bltz	a0,8000559a <sys_link+0x100>
  iunlockput(dp);
    80005558:	854a                	mv	a0,s2
    8000555a:	ffffe097          	auipc	ra,0xffffe
    8000555e:	552080e7          	jalr	1362(ra) # 80003aac <iunlockput>
  iput(ip);
    80005562:	8526                	mv	a0,s1
    80005564:	ffffe097          	auipc	ra,0xffffe
    80005568:	4a0080e7          	jalr	1184(ra) # 80003a04 <iput>
  end_op();
    8000556c:	fffff097          	auipc	ra,0xfffff
    80005570:	d30080e7          	jalr	-720(ra) # 8000429c <end_op>
  return 0;
    80005574:	4781                	li	a5,0
    80005576:	a085                	j	800055d6 <sys_link+0x13c>
    end_op();
    80005578:	fffff097          	auipc	ra,0xfffff
    8000557c:	d24080e7          	jalr	-732(ra) # 8000429c <end_op>
    return -1;
    80005580:	57fd                	li	a5,-1
    80005582:	a891                	j	800055d6 <sys_link+0x13c>
    iunlockput(ip);
    80005584:	8526                	mv	a0,s1
    80005586:	ffffe097          	auipc	ra,0xffffe
    8000558a:	526080e7          	jalr	1318(ra) # 80003aac <iunlockput>
    end_op();
    8000558e:	fffff097          	auipc	ra,0xfffff
    80005592:	d0e080e7          	jalr	-754(ra) # 8000429c <end_op>
    return -1;
    80005596:	57fd                	li	a5,-1
    80005598:	a83d                	j	800055d6 <sys_link+0x13c>
    iunlockput(dp);
    8000559a:	854a                	mv	a0,s2
    8000559c:	ffffe097          	auipc	ra,0xffffe
    800055a0:	510080e7          	jalr	1296(ra) # 80003aac <iunlockput>
  ilock(ip);
    800055a4:	8526                	mv	a0,s1
    800055a6:	ffffe097          	auipc	ra,0xffffe
    800055aa:	2a4080e7          	jalr	676(ra) # 8000384a <ilock>
  ip->nlink--;
    800055ae:	04a4d783          	lhu	a5,74(s1)
    800055b2:	37fd                	addiw	a5,a5,-1
    800055b4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055b8:	8526                	mv	a0,s1
    800055ba:	ffffe097          	auipc	ra,0xffffe
    800055be:	1c6080e7          	jalr	454(ra) # 80003780 <iupdate>
  iunlockput(ip);
    800055c2:	8526                	mv	a0,s1
    800055c4:	ffffe097          	auipc	ra,0xffffe
    800055c8:	4e8080e7          	jalr	1256(ra) # 80003aac <iunlockput>
  end_op();
    800055cc:	fffff097          	auipc	ra,0xfffff
    800055d0:	cd0080e7          	jalr	-816(ra) # 8000429c <end_op>
  return -1;
    800055d4:	57fd                	li	a5,-1
}
    800055d6:	853e                	mv	a0,a5
    800055d8:	70b2                	ld	ra,296(sp)
    800055da:	7412                	ld	s0,288(sp)
    800055dc:	64f2                	ld	s1,280(sp)
    800055de:	6952                	ld	s2,272(sp)
    800055e0:	6155                	addi	sp,sp,304
    800055e2:	8082                	ret

00000000800055e4 <sys_unlink>:
{
    800055e4:	7151                	addi	sp,sp,-240
    800055e6:	f586                	sd	ra,232(sp)
    800055e8:	f1a2                	sd	s0,224(sp)
    800055ea:	eda6                	sd	s1,216(sp)
    800055ec:	e9ca                	sd	s2,208(sp)
    800055ee:	e5ce                	sd	s3,200(sp)
    800055f0:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800055f2:	08000613          	li	a2,128
    800055f6:	f3040593          	addi	a1,s0,-208
    800055fa:	4501                	li	a0,0
    800055fc:	ffffd097          	auipc	ra,0xffffd
    80005600:	6b6080e7          	jalr	1718(ra) # 80002cb2 <argstr>
    80005604:	18054163          	bltz	a0,80005786 <sys_unlink+0x1a2>
  begin_op();
    80005608:	fffff097          	auipc	ra,0xfffff
    8000560c:	c14080e7          	jalr	-1004(ra) # 8000421c <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005610:	fb040593          	addi	a1,s0,-80
    80005614:	f3040513          	addi	a0,s0,-208
    80005618:	fffff097          	auipc	ra,0xfffff
    8000561c:	a06080e7          	jalr	-1530(ra) # 8000401e <nameiparent>
    80005620:	84aa                	mv	s1,a0
    80005622:	c979                	beqz	a0,800056f8 <sys_unlink+0x114>
  ilock(dp);
    80005624:	ffffe097          	auipc	ra,0xffffe
    80005628:	226080e7          	jalr	550(ra) # 8000384a <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000562c:	00003597          	auipc	a1,0x3
    80005630:	18458593          	addi	a1,a1,388 # 800087b0 <syscalls+0x2c0>
    80005634:	fb040513          	addi	a0,s0,-80
    80005638:	ffffe097          	auipc	ra,0xffffe
    8000563c:	6dc080e7          	jalr	1756(ra) # 80003d14 <namecmp>
    80005640:	14050a63          	beqz	a0,80005794 <sys_unlink+0x1b0>
    80005644:	00003597          	auipc	a1,0x3
    80005648:	17458593          	addi	a1,a1,372 # 800087b8 <syscalls+0x2c8>
    8000564c:	fb040513          	addi	a0,s0,-80
    80005650:	ffffe097          	auipc	ra,0xffffe
    80005654:	6c4080e7          	jalr	1732(ra) # 80003d14 <namecmp>
    80005658:	12050e63          	beqz	a0,80005794 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000565c:	f2c40613          	addi	a2,s0,-212
    80005660:	fb040593          	addi	a1,s0,-80
    80005664:	8526                	mv	a0,s1
    80005666:	ffffe097          	auipc	ra,0xffffe
    8000566a:	6c8080e7          	jalr	1736(ra) # 80003d2e <dirlookup>
    8000566e:	892a                	mv	s2,a0
    80005670:	12050263          	beqz	a0,80005794 <sys_unlink+0x1b0>
  ilock(ip);
    80005674:	ffffe097          	auipc	ra,0xffffe
    80005678:	1d6080e7          	jalr	470(ra) # 8000384a <ilock>
  if(ip->nlink < 1)
    8000567c:	04a91783          	lh	a5,74(s2)
    80005680:	08f05263          	blez	a5,80005704 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005684:	04491703          	lh	a4,68(s2)
    80005688:	4785                	li	a5,1
    8000568a:	08f70563          	beq	a4,a5,80005714 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000568e:	4641                	li	a2,16
    80005690:	4581                	li	a1,0
    80005692:	fc040513          	addi	a0,s0,-64
    80005696:	ffffb097          	auipc	ra,0xffffb
    8000569a:	64a080e7          	jalr	1610(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000569e:	4741                	li	a4,16
    800056a0:	f2c42683          	lw	a3,-212(s0)
    800056a4:	fc040613          	addi	a2,s0,-64
    800056a8:	4581                	li	a1,0
    800056aa:	8526                	mv	a0,s1
    800056ac:	ffffe097          	auipc	ra,0xffffe
    800056b0:	54a080e7          	jalr	1354(ra) # 80003bf6 <writei>
    800056b4:	47c1                	li	a5,16
    800056b6:	0af51563          	bne	a0,a5,80005760 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800056ba:	04491703          	lh	a4,68(s2)
    800056be:	4785                	li	a5,1
    800056c0:	0af70863          	beq	a4,a5,80005770 <sys_unlink+0x18c>
  iunlockput(dp);
    800056c4:	8526                	mv	a0,s1
    800056c6:	ffffe097          	auipc	ra,0xffffe
    800056ca:	3e6080e7          	jalr	998(ra) # 80003aac <iunlockput>
  ip->nlink--;
    800056ce:	04a95783          	lhu	a5,74(s2)
    800056d2:	37fd                	addiw	a5,a5,-1
    800056d4:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800056d8:	854a                	mv	a0,s2
    800056da:	ffffe097          	auipc	ra,0xffffe
    800056de:	0a6080e7          	jalr	166(ra) # 80003780 <iupdate>
  iunlockput(ip);
    800056e2:	854a                	mv	a0,s2
    800056e4:	ffffe097          	auipc	ra,0xffffe
    800056e8:	3c8080e7          	jalr	968(ra) # 80003aac <iunlockput>
  end_op();
    800056ec:	fffff097          	auipc	ra,0xfffff
    800056f0:	bb0080e7          	jalr	-1104(ra) # 8000429c <end_op>
  return 0;
    800056f4:	4501                	li	a0,0
    800056f6:	a84d                	j	800057a8 <sys_unlink+0x1c4>
    end_op();
    800056f8:	fffff097          	auipc	ra,0xfffff
    800056fc:	ba4080e7          	jalr	-1116(ra) # 8000429c <end_op>
    return -1;
    80005700:	557d                	li	a0,-1
    80005702:	a05d                	j	800057a8 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005704:	00003517          	auipc	a0,0x3
    80005708:	0dc50513          	addi	a0,a0,220 # 800087e0 <syscalls+0x2f0>
    8000570c:	ffffb097          	auipc	ra,0xffffb
    80005710:	e32080e7          	jalr	-462(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005714:	04c92703          	lw	a4,76(s2)
    80005718:	02000793          	li	a5,32
    8000571c:	f6e7f9e3          	bgeu	a5,a4,8000568e <sys_unlink+0xaa>
    80005720:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005724:	4741                	li	a4,16
    80005726:	86ce                	mv	a3,s3
    80005728:	f1840613          	addi	a2,s0,-232
    8000572c:	4581                	li	a1,0
    8000572e:	854a                	mv	a0,s2
    80005730:	ffffe097          	auipc	ra,0xffffe
    80005734:	3ce080e7          	jalr	974(ra) # 80003afe <readi>
    80005738:	47c1                	li	a5,16
    8000573a:	00f51b63          	bne	a0,a5,80005750 <sys_unlink+0x16c>
    if(de.inum != 0)
    8000573e:	f1845783          	lhu	a5,-232(s0)
    80005742:	e7a1                	bnez	a5,8000578a <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005744:	29c1                	addiw	s3,s3,16
    80005746:	04c92783          	lw	a5,76(s2)
    8000574a:	fcf9ede3          	bltu	s3,a5,80005724 <sys_unlink+0x140>
    8000574e:	b781                	j	8000568e <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005750:	00003517          	auipc	a0,0x3
    80005754:	0a850513          	addi	a0,a0,168 # 800087f8 <syscalls+0x308>
    80005758:	ffffb097          	auipc	ra,0xffffb
    8000575c:	de6080e7          	jalr	-538(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005760:	00003517          	auipc	a0,0x3
    80005764:	0b050513          	addi	a0,a0,176 # 80008810 <syscalls+0x320>
    80005768:	ffffb097          	auipc	ra,0xffffb
    8000576c:	dd6080e7          	jalr	-554(ra) # 8000053e <panic>
    dp->nlink--;
    80005770:	04a4d783          	lhu	a5,74(s1)
    80005774:	37fd                	addiw	a5,a5,-1
    80005776:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000577a:	8526                	mv	a0,s1
    8000577c:	ffffe097          	auipc	ra,0xffffe
    80005780:	004080e7          	jalr	4(ra) # 80003780 <iupdate>
    80005784:	b781                	j	800056c4 <sys_unlink+0xe0>
    return -1;
    80005786:	557d                	li	a0,-1
    80005788:	a005                	j	800057a8 <sys_unlink+0x1c4>
    iunlockput(ip);
    8000578a:	854a                	mv	a0,s2
    8000578c:	ffffe097          	auipc	ra,0xffffe
    80005790:	320080e7          	jalr	800(ra) # 80003aac <iunlockput>
  iunlockput(dp);
    80005794:	8526                	mv	a0,s1
    80005796:	ffffe097          	auipc	ra,0xffffe
    8000579a:	316080e7          	jalr	790(ra) # 80003aac <iunlockput>
  end_op();
    8000579e:	fffff097          	auipc	ra,0xfffff
    800057a2:	afe080e7          	jalr	-1282(ra) # 8000429c <end_op>
  return -1;
    800057a6:	557d                	li	a0,-1
}
    800057a8:	70ae                	ld	ra,232(sp)
    800057aa:	740e                	ld	s0,224(sp)
    800057ac:	64ee                	ld	s1,216(sp)
    800057ae:	694e                	ld	s2,208(sp)
    800057b0:	69ae                	ld	s3,200(sp)
    800057b2:	616d                	addi	sp,sp,240
    800057b4:	8082                	ret

00000000800057b6 <sys_open>:

uint64
sys_open(void)
{
    800057b6:	7131                	addi	sp,sp,-192
    800057b8:	fd06                	sd	ra,184(sp)
    800057ba:	f922                	sd	s0,176(sp)
    800057bc:	f526                	sd	s1,168(sp)
    800057be:	f14a                	sd	s2,160(sp)
    800057c0:	ed4e                	sd	s3,152(sp)
    800057c2:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800057c4:	08000613          	li	a2,128
    800057c8:	f5040593          	addi	a1,s0,-176
    800057cc:	4501                	li	a0,0
    800057ce:	ffffd097          	auipc	ra,0xffffd
    800057d2:	4e4080e7          	jalr	1252(ra) # 80002cb2 <argstr>
    return -1;
    800057d6:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800057d8:	0c054163          	bltz	a0,8000589a <sys_open+0xe4>
    800057dc:	f4c40593          	addi	a1,s0,-180
    800057e0:	4505                	li	a0,1
    800057e2:	ffffd097          	auipc	ra,0xffffd
    800057e6:	48c080e7          	jalr	1164(ra) # 80002c6e <argint>
    800057ea:	0a054863          	bltz	a0,8000589a <sys_open+0xe4>

  begin_op();
    800057ee:	fffff097          	auipc	ra,0xfffff
    800057f2:	a2e080e7          	jalr	-1490(ra) # 8000421c <begin_op>

  if(omode & O_CREATE){
    800057f6:	f4c42783          	lw	a5,-180(s0)
    800057fa:	2007f793          	andi	a5,a5,512
    800057fe:	cbdd                	beqz	a5,800058b4 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005800:	4681                	li	a3,0
    80005802:	4601                	li	a2,0
    80005804:	4589                	li	a1,2
    80005806:	f5040513          	addi	a0,s0,-176
    8000580a:	00000097          	auipc	ra,0x0
    8000580e:	972080e7          	jalr	-1678(ra) # 8000517c <create>
    80005812:	892a                	mv	s2,a0
    if(ip == 0){
    80005814:	c959                	beqz	a0,800058aa <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005816:	04491703          	lh	a4,68(s2)
    8000581a:	478d                	li	a5,3
    8000581c:	00f71763          	bne	a4,a5,8000582a <sys_open+0x74>
    80005820:	04695703          	lhu	a4,70(s2)
    80005824:	47a5                	li	a5,9
    80005826:	0ce7ec63          	bltu	a5,a4,800058fe <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000582a:	fffff097          	auipc	ra,0xfffff
    8000582e:	e02080e7          	jalr	-510(ra) # 8000462c <filealloc>
    80005832:	89aa                	mv	s3,a0
    80005834:	10050263          	beqz	a0,80005938 <sys_open+0x182>
    80005838:	00000097          	auipc	ra,0x0
    8000583c:	902080e7          	jalr	-1790(ra) # 8000513a <fdalloc>
    80005840:	84aa                	mv	s1,a0
    80005842:	0e054663          	bltz	a0,8000592e <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005846:	04491703          	lh	a4,68(s2)
    8000584a:	478d                	li	a5,3
    8000584c:	0cf70463          	beq	a4,a5,80005914 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005850:	4789                	li	a5,2
    80005852:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005856:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000585a:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000585e:	f4c42783          	lw	a5,-180(s0)
    80005862:	0017c713          	xori	a4,a5,1
    80005866:	8b05                	andi	a4,a4,1
    80005868:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000586c:	0037f713          	andi	a4,a5,3
    80005870:	00e03733          	snez	a4,a4
    80005874:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005878:	4007f793          	andi	a5,a5,1024
    8000587c:	c791                	beqz	a5,80005888 <sys_open+0xd2>
    8000587e:	04491703          	lh	a4,68(s2)
    80005882:	4789                	li	a5,2
    80005884:	08f70f63          	beq	a4,a5,80005922 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005888:	854a                	mv	a0,s2
    8000588a:	ffffe097          	auipc	ra,0xffffe
    8000588e:	082080e7          	jalr	130(ra) # 8000390c <iunlock>
  end_op();
    80005892:	fffff097          	auipc	ra,0xfffff
    80005896:	a0a080e7          	jalr	-1526(ra) # 8000429c <end_op>

  return fd;
}
    8000589a:	8526                	mv	a0,s1
    8000589c:	70ea                	ld	ra,184(sp)
    8000589e:	744a                	ld	s0,176(sp)
    800058a0:	74aa                	ld	s1,168(sp)
    800058a2:	790a                	ld	s2,160(sp)
    800058a4:	69ea                	ld	s3,152(sp)
    800058a6:	6129                	addi	sp,sp,192
    800058a8:	8082                	ret
      end_op();
    800058aa:	fffff097          	auipc	ra,0xfffff
    800058ae:	9f2080e7          	jalr	-1550(ra) # 8000429c <end_op>
      return -1;
    800058b2:	b7e5                	j	8000589a <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800058b4:	f5040513          	addi	a0,s0,-176
    800058b8:	ffffe097          	auipc	ra,0xffffe
    800058bc:	748080e7          	jalr	1864(ra) # 80004000 <namei>
    800058c0:	892a                	mv	s2,a0
    800058c2:	c905                	beqz	a0,800058f2 <sys_open+0x13c>
    ilock(ip);
    800058c4:	ffffe097          	auipc	ra,0xffffe
    800058c8:	f86080e7          	jalr	-122(ra) # 8000384a <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800058cc:	04491703          	lh	a4,68(s2)
    800058d0:	4785                	li	a5,1
    800058d2:	f4f712e3          	bne	a4,a5,80005816 <sys_open+0x60>
    800058d6:	f4c42783          	lw	a5,-180(s0)
    800058da:	dba1                	beqz	a5,8000582a <sys_open+0x74>
      iunlockput(ip);
    800058dc:	854a                	mv	a0,s2
    800058de:	ffffe097          	auipc	ra,0xffffe
    800058e2:	1ce080e7          	jalr	462(ra) # 80003aac <iunlockput>
      end_op();
    800058e6:	fffff097          	auipc	ra,0xfffff
    800058ea:	9b6080e7          	jalr	-1610(ra) # 8000429c <end_op>
      return -1;
    800058ee:	54fd                	li	s1,-1
    800058f0:	b76d                	j	8000589a <sys_open+0xe4>
      end_op();
    800058f2:	fffff097          	auipc	ra,0xfffff
    800058f6:	9aa080e7          	jalr	-1622(ra) # 8000429c <end_op>
      return -1;
    800058fa:	54fd                	li	s1,-1
    800058fc:	bf79                	j	8000589a <sys_open+0xe4>
    iunlockput(ip);
    800058fe:	854a                	mv	a0,s2
    80005900:	ffffe097          	auipc	ra,0xffffe
    80005904:	1ac080e7          	jalr	428(ra) # 80003aac <iunlockput>
    end_op();
    80005908:	fffff097          	auipc	ra,0xfffff
    8000590c:	994080e7          	jalr	-1644(ra) # 8000429c <end_op>
    return -1;
    80005910:	54fd                	li	s1,-1
    80005912:	b761                	j	8000589a <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005914:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005918:	04691783          	lh	a5,70(s2)
    8000591c:	02f99223          	sh	a5,36(s3)
    80005920:	bf2d                	j	8000585a <sys_open+0xa4>
    itrunc(ip);
    80005922:	854a                	mv	a0,s2
    80005924:	ffffe097          	auipc	ra,0xffffe
    80005928:	034080e7          	jalr	52(ra) # 80003958 <itrunc>
    8000592c:	bfb1                	j	80005888 <sys_open+0xd2>
      fileclose(f);
    8000592e:	854e                	mv	a0,s3
    80005930:	fffff097          	auipc	ra,0xfffff
    80005934:	db8080e7          	jalr	-584(ra) # 800046e8 <fileclose>
    iunlockput(ip);
    80005938:	854a                	mv	a0,s2
    8000593a:	ffffe097          	auipc	ra,0xffffe
    8000593e:	172080e7          	jalr	370(ra) # 80003aac <iunlockput>
    end_op();
    80005942:	fffff097          	auipc	ra,0xfffff
    80005946:	95a080e7          	jalr	-1702(ra) # 8000429c <end_op>
    return -1;
    8000594a:	54fd                	li	s1,-1
    8000594c:	b7b9                	j	8000589a <sys_open+0xe4>

000000008000594e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000594e:	7175                	addi	sp,sp,-144
    80005950:	e506                	sd	ra,136(sp)
    80005952:	e122                	sd	s0,128(sp)
    80005954:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005956:	fffff097          	auipc	ra,0xfffff
    8000595a:	8c6080e7          	jalr	-1850(ra) # 8000421c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000595e:	08000613          	li	a2,128
    80005962:	f7040593          	addi	a1,s0,-144
    80005966:	4501                	li	a0,0
    80005968:	ffffd097          	auipc	ra,0xffffd
    8000596c:	34a080e7          	jalr	842(ra) # 80002cb2 <argstr>
    80005970:	02054963          	bltz	a0,800059a2 <sys_mkdir+0x54>
    80005974:	4681                	li	a3,0
    80005976:	4601                	li	a2,0
    80005978:	4585                	li	a1,1
    8000597a:	f7040513          	addi	a0,s0,-144
    8000597e:	fffff097          	auipc	ra,0xfffff
    80005982:	7fe080e7          	jalr	2046(ra) # 8000517c <create>
    80005986:	cd11                	beqz	a0,800059a2 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005988:	ffffe097          	auipc	ra,0xffffe
    8000598c:	124080e7          	jalr	292(ra) # 80003aac <iunlockput>
  end_op();
    80005990:	fffff097          	auipc	ra,0xfffff
    80005994:	90c080e7          	jalr	-1780(ra) # 8000429c <end_op>
  return 0;
    80005998:	4501                	li	a0,0
}
    8000599a:	60aa                	ld	ra,136(sp)
    8000599c:	640a                	ld	s0,128(sp)
    8000599e:	6149                	addi	sp,sp,144
    800059a0:	8082                	ret
    end_op();
    800059a2:	fffff097          	auipc	ra,0xfffff
    800059a6:	8fa080e7          	jalr	-1798(ra) # 8000429c <end_op>
    return -1;
    800059aa:	557d                	li	a0,-1
    800059ac:	b7fd                	j	8000599a <sys_mkdir+0x4c>

00000000800059ae <sys_mknod>:

uint64
sys_mknod(void)
{
    800059ae:	7135                	addi	sp,sp,-160
    800059b0:	ed06                	sd	ra,152(sp)
    800059b2:	e922                	sd	s0,144(sp)
    800059b4:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800059b6:	fffff097          	auipc	ra,0xfffff
    800059ba:	866080e7          	jalr	-1946(ra) # 8000421c <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059be:	08000613          	li	a2,128
    800059c2:	f7040593          	addi	a1,s0,-144
    800059c6:	4501                	li	a0,0
    800059c8:	ffffd097          	auipc	ra,0xffffd
    800059cc:	2ea080e7          	jalr	746(ra) # 80002cb2 <argstr>
    800059d0:	04054a63          	bltz	a0,80005a24 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800059d4:	f6c40593          	addi	a1,s0,-148
    800059d8:	4505                	li	a0,1
    800059da:	ffffd097          	auipc	ra,0xffffd
    800059de:	294080e7          	jalr	660(ra) # 80002c6e <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059e2:	04054163          	bltz	a0,80005a24 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800059e6:	f6840593          	addi	a1,s0,-152
    800059ea:	4509                	li	a0,2
    800059ec:	ffffd097          	auipc	ra,0xffffd
    800059f0:	282080e7          	jalr	642(ra) # 80002c6e <argint>
     argint(1, &major) < 0 ||
    800059f4:	02054863          	bltz	a0,80005a24 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800059f8:	f6841683          	lh	a3,-152(s0)
    800059fc:	f6c41603          	lh	a2,-148(s0)
    80005a00:	458d                	li	a1,3
    80005a02:	f7040513          	addi	a0,s0,-144
    80005a06:	fffff097          	auipc	ra,0xfffff
    80005a0a:	776080e7          	jalr	1910(ra) # 8000517c <create>
     argint(2, &minor) < 0 ||
    80005a0e:	c919                	beqz	a0,80005a24 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a10:	ffffe097          	auipc	ra,0xffffe
    80005a14:	09c080e7          	jalr	156(ra) # 80003aac <iunlockput>
  end_op();
    80005a18:	fffff097          	auipc	ra,0xfffff
    80005a1c:	884080e7          	jalr	-1916(ra) # 8000429c <end_op>
  return 0;
    80005a20:	4501                	li	a0,0
    80005a22:	a031                	j	80005a2e <sys_mknod+0x80>
    end_op();
    80005a24:	fffff097          	auipc	ra,0xfffff
    80005a28:	878080e7          	jalr	-1928(ra) # 8000429c <end_op>
    return -1;
    80005a2c:	557d                	li	a0,-1
}
    80005a2e:	60ea                	ld	ra,152(sp)
    80005a30:	644a                	ld	s0,144(sp)
    80005a32:	610d                	addi	sp,sp,160
    80005a34:	8082                	ret

0000000080005a36 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005a36:	7135                	addi	sp,sp,-160
    80005a38:	ed06                	sd	ra,152(sp)
    80005a3a:	e922                	sd	s0,144(sp)
    80005a3c:	e526                	sd	s1,136(sp)
    80005a3e:	e14a                	sd	s2,128(sp)
    80005a40:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005a42:	ffffc097          	auipc	ra,0xffffc
    80005a46:	04a080e7          	jalr	74(ra) # 80001a8c <myproc>
    80005a4a:	892a                	mv	s2,a0
  
  begin_op();
    80005a4c:	ffffe097          	auipc	ra,0xffffe
    80005a50:	7d0080e7          	jalr	2000(ra) # 8000421c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005a54:	08000613          	li	a2,128
    80005a58:	f6040593          	addi	a1,s0,-160
    80005a5c:	4501                	li	a0,0
    80005a5e:	ffffd097          	auipc	ra,0xffffd
    80005a62:	254080e7          	jalr	596(ra) # 80002cb2 <argstr>
    80005a66:	04054b63          	bltz	a0,80005abc <sys_chdir+0x86>
    80005a6a:	f6040513          	addi	a0,s0,-160
    80005a6e:	ffffe097          	auipc	ra,0xffffe
    80005a72:	592080e7          	jalr	1426(ra) # 80004000 <namei>
    80005a76:	84aa                	mv	s1,a0
    80005a78:	c131                	beqz	a0,80005abc <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a7a:	ffffe097          	auipc	ra,0xffffe
    80005a7e:	dd0080e7          	jalr	-560(ra) # 8000384a <ilock>
  if(ip->type != T_DIR){
    80005a82:	04449703          	lh	a4,68(s1)
    80005a86:	4785                	li	a5,1
    80005a88:	04f71063          	bne	a4,a5,80005ac8 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a8c:	8526                	mv	a0,s1
    80005a8e:	ffffe097          	auipc	ra,0xffffe
    80005a92:	e7e080e7          	jalr	-386(ra) # 8000390c <iunlock>
  iput(p->cwd);
    80005a96:	15093503          	ld	a0,336(s2)
    80005a9a:	ffffe097          	auipc	ra,0xffffe
    80005a9e:	f6a080e7          	jalr	-150(ra) # 80003a04 <iput>
  end_op();
    80005aa2:	ffffe097          	auipc	ra,0xffffe
    80005aa6:	7fa080e7          	jalr	2042(ra) # 8000429c <end_op>
  p->cwd = ip;
    80005aaa:	14993823          	sd	s1,336(s2)
  return 0;
    80005aae:	4501                	li	a0,0
}
    80005ab0:	60ea                	ld	ra,152(sp)
    80005ab2:	644a                	ld	s0,144(sp)
    80005ab4:	64aa                	ld	s1,136(sp)
    80005ab6:	690a                	ld	s2,128(sp)
    80005ab8:	610d                	addi	sp,sp,160
    80005aba:	8082                	ret
    end_op();
    80005abc:	ffffe097          	auipc	ra,0xffffe
    80005ac0:	7e0080e7          	jalr	2016(ra) # 8000429c <end_op>
    return -1;
    80005ac4:	557d                	li	a0,-1
    80005ac6:	b7ed                	j	80005ab0 <sys_chdir+0x7a>
    iunlockput(ip);
    80005ac8:	8526                	mv	a0,s1
    80005aca:	ffffe097          	auipc	ra,0xffffe
    80005ace:	fe2080e7          	jalr	-30(ra) # 80003aac <iunlockput>
    end_op();
    80005ad2:	ffffe097          	auipc	ra,0xffffe
    80005ad6:	7ca080e7          	jalr	1994(ra) # 8000429c <end_op>
    return -1;
    80005ada:	557d                	li	a0,-1
    80005adc:	bfd1                	j	80005ab0 <sys_chdir+0x7a>

0000000080005ade <sys_exec>:

uint64
sys_exec(void)
{
    80005ade:	7145                	addi	sp,sp,-464
    80005ae0:	e786                	sd	ra,456(sp)
    80005ae2:	e3a2                	sd	s0,448(sp)
    80005ae4:	ff26                	sd	s1,440(sp)
    80005ae6:	fb4a                	sd	s2,432(sp)
    80005ae8:	f74e                	sd	s3,424(sp)
    80005aea:	f352                	sd	s4,416(sp)
    80005aec:	ef56                	sd	s5,408(sp)
    80005aee:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005af0:	08000613          	li	a2,128
    80005af4:	f4040593          	addi	a1,s0,-192
    80005af8:	4501                	li	a0,0
    80005afa:	ffffd097          	auipc	ra,0xffffd
    80005afe:	1b8080e7          	jalr	440(ra) # 80002cb2 <argstr>
    return -1;
    80005b02:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b04:	0c054a63          	bltz	a0,80005bd8 <sys_exec+0xfa>
    80005b08:	e3840593          	addi	a1,s0,-456
    80005b0c:	4505                	li	a0,1
    80005b0e:	ffffd097          	auipc	ra,0xffffd
    80005b12:	182080e7          	jalr	386(ra) # 80002c90 <argaddr>
    80005b16:	0c054163          	bltz	a0,80005bd8 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005b1a:	10000613          	li	a2,256
    80005b1e:	4581                	li	a1,0
    80005b20:	e4040513          	addi	a0,s0,-448
    80005b24:	ffffb097          	auipc	ra,0xffffb
    80005b28:	1bc080e7          	jalr	444(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005b2c:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005b30:	89a6                	mv	s3,s1
    80005b32:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005b34:	02000a13          	li	s4,32
    80005b38:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005b3c:	00391513          	slli	a0,s2,0x3
    80005b40:	e3040593          	addi	a1,s0,-464
    80005b44:	e3843783          	ld	a5,-456(s0)
    80005b48:	953e                	add	a0,a0,a5
    80005b4a:	ffffd097          	auipc	ra,0xffffd
    80005b4e:	08a080e7          	jalr	138(ra) # 80002bd4 <fetchaddr>
    80005b52:	02054a63          	bltz	a0,80005b86 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005b56:	e3043783          	ld	a5,-464(s0)
    80005b5a:	c3b9                	beqz	a5,80005ba0 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005b5c:	ffffb097          	auipc	ra,0xffffb
    80005b60:	f98080e7          	jalr	-104(ra) # 80000af4 <kalloc>
    80005b64:	85aa                	mv	a1,a0
    80005b66:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005b6a:	cd11                	beqz	a0,80005b86 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005b6c:	6605                	lui	a2,0x1
    80005b6e:	e3043503          	ld	a0,-464(s0)
    80005b72:	ffffd097          	auipc	ra,0xffffd
    80005b76:	0b4080e7          	jalr	180(ra) # 80002c26 <fetchstr>
    80005b7a:	00054663          	bltz	a0,80005b86 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005b7e:	0905                	addi	s2,s2,1
    80005b80:	09a1                	addi	s3,s3,8
    80005b82:	fb491be3          	bne	s2,s4,80005b38 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b86:	10048913          	addi	s2,s1,256
    80005b8a:	6088                	ld	a0,0(s1)
    80005b8c:	c529                	beqz	a0,80005bd6 <sys_exec+0xf8>
    kfree(argv[i]);
    80005b8e:	ffffb097          	auipc	ra,0xffffb
    80005b92:	e6a080e7          	jalr	-406(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b96:	04a1                	addi	s1,s1,8
    80005b98:	ff2499e3          	bne	s1,s2,80005b8a <sys_exec+0xac>
  return -1;
    80005b9c:	597d                	li	s2,-1
    80005b9e:	a82d                	j	80005bd8 <sys_exec+0xfa>
      argv[i] = 0;
    80005ba0:	0a8e                	slli	s5,s5,0x3
    80005ba2:	fc040793          	addi	a5,s0,-64
    80005ba6:	9abe                	add	s5,s5,a5
    80005ba8:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005bac:	e4040593          	addi	a1,s0,-448
    80005bb0:	f4040513          	addi	a0,s0,-192
    80005bb4:	fffff097          	auipc	ra,0xfffff
    80005bb8:	194080e7          	jalr	404(ra) # 80004d48 <exec>
    80005bbc:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bbe:	10048993          	addi	s3,s1,256
    80005bc2:	6088                	ld	a0,0(s1)
    80005bc4:	c911                	beqz	a0,80005bd8 <sys_exec+0xfa>
    kfree(argv[i]);
    80005bc6:	ffffb097          	auipc	ra,0xffffb
    80005bca:	e32080e7          	jalr	-462(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bce:	04a1                	addi	s1,s1,8
    80005bd0:	ff3499e3          	bne	s1,s3,80005bc2 <sys_exec+0xe4>
    80005bd4:	a011                	j	80005bd8 <sys_exec+0xfa>
  return -1;
    80005bd6:	597d                	li	s2,-1
}
    80005bd8:	854a                	mv	a0,s2
    80005bda:	60be                	ld	ra,456(sp)
    80005bdc:	641e                	ld	s0,448(sp)
    80005bde:	74fa                	ld	s1,440(sp)
    80005be0:	795a                	ld	s2,432(sp)
    80005be2:	79ba                	ld	s3,424(sp)
    80005be4:	7a1a                	ld	s4,416(sp)
    80005be6:	6afa                	ld	s5,408(sp)
    80005be8:	6179                	addi	sp,sp,464
    80005bea:	8082                	ret

0000000080005bec <sys_pipe>:

uint64
sys_pipe(void)
{
    80005bec:	7139                	addi	sp,sp,-64
    80005bee:	fc06                	sd	ra,56(sp)
    80005bf0:	f822                	sd	s0,48(sp)
    80005bf2:	f426                	sd	s1,40(sp)
    80005bf4:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005bf6:	ffffc097          	auipc	ra,0xffffc
    80005bfa:	e96080e7          	jalr	-362(ra) # 80001a8c <myproc>
    80005bfe:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005c00:	fd840593          	addi	a1,s0,-40
    80005c04:	4501                	li	a0,0
    80005c06:	ffffd097          	auipc	ra,0xffffd
    80005c0a:	08a080e7          	jalr	138(ra) # 80002c90 <argaddr>
    return -1;
    80005c0e:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005c10:	0e054063          	bltz	a0,80005cf0 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005c14:	fc840593          	addi	a1,s0,-56
    80005c18:	fd040513          	addi	a0,s0,-48
    80005c1c:	fffff097          	auipc	ra,0xfffff
    80005c20:	dfc080e7          	jalr	-516(ra) # 80004a18 <pipealloc>
    return -1;
    80005c24:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005c26:	0c054563          	bltz	a0,80005cf0 <sys_pipe+0x104>
  fd0 = -1;
    80005c2a:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005c2e:	fd043503          	ld	a0,-48(s0)
    80005c32:	fffff097          	auipc	ra,0xfffff
    80005c36:	508080e7          	jalr	1288(ra) # 8000513a <fdalloc>
    80005c3a:	fca42223          	sw	a0,-60(s0)
    80005c3e:	08054c63          	bltz	a0,80005cd6 <sys_pipe+0xea>
    80005c42:	fc843503          	ld	a0,-56(s0)
    80005c46:	fffff097          	auipc	ra,0xfffff
    80005c4a:	4f4080e7          	jalr	1268(ra) # 8000513a <fdalloc>
    80005c4e:	fca42023          	sw	a0,-64(s0)
    80005c52:	06054863          	bltz	a0,80005cc2 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c56:	4691                	li	a3,4
    80005c58:	fc440613          	addi	a2,s0,-60
    80005c5c:	fd843583          	ld	a1,-40(s0)
    80005c60:	68a8                	ld	a0,80(s1)
    80005c62:	ffffc097          	auipc	ra,0xffffc
    80005c66:	a10080e7          	jalr	-1520(ra) # 80001672 <copyout>
    80005c6a:	02054063          	bltz	a0,80005c8a <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005c6e:	4691                	li	a3,4
    80005c70:	fc040613          	addi	a2,s0,-64
    80005c74:	fd843583          	ld	a1,-40(s0)
    80005c78:	0591                	addi	a1,a1,4
    80005c7a:	68a8                	ld	a0,80(s1)
    80005c7c:	ffffc097          	auipc	ra,0xffffc
    80005c80:	9f6080e7          	jalr	-1546(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c84:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c86:	06055563          	bgez	a0,80005cf0 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005c8a:	fc442783          	lw	a5,-60(s0)
    80005c8e:	07e9                	addi	a5,a5,26
    80005c90:	078e                	slli	a5,a5,0x3
    80005c92:	97a6                	add	a5,a5,s1
    80005c94:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c98:	fc042503          	lw	a0,-64(s0)
    80005c9c:	0569                	addi	a0,a0,26
    80005c9e:	050e                	slli	a0,a0,0x3
    80005ca0:	9526                	add	a0,a0,s1
    80005ca2:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005ca6:	fd043503          	ld	a0,-48(s0)
    80005caa:	fffff097          	auipc	ra,0xfffff
    80005cae:	a3e080e7          	jalr	-1474(ra) # 800046e8 <fileclose>
    fileclose(wf);
    80005cb2:	fc843503          	ld	a0,-56(s0)
    80005cb6:	fffff097          	auipc	ra,0xfffff
    80005cba:	a32080e7          	jalr	-1486(ra) # 800046e8 <fileclose>
    return -1;
    80005cbe:	57fd                	li	a5,-1
    80005cc0:	a805                	j	80005cf0 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005cc2:	fc442783          	lw	a5,-60(s0)
    80005cc6:	0007c863          	bltz	a5,80005cd6 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005cca:	01a78513          	addi	a0,a5,26
    80005cce:	050e                	slli	a0,a0,0x3
    80005cd0:	9526                	add	a0,a0,s1
    80005cd2:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005cd6:	fd043503          	ld	a0,-48(s0)
    80005cda:	fffff097          	auipc	ra,0xfffff
    80005cde:	a0e080e7          	jalr	-1522(ra) # 800046e8 <fileclose>
    fileclose(wf);
    80005ce2:	fc843503          	ld	a0,-56(s0)
    80005ce6:	fffff097          	auipc	ra,0xfffff
    80005cea:	a02080e7          	jalr	-1534(ra) # 800046e8 <fileclose>
    return -1;
    80005cee:	57fd                	li	a5,-1
}
    80005cf0:	853e                	mv	a0,a5
    80005cf2:	70e2                	ld	ra,56(sp)
    80005cf4:	7442                	ld	s0,48(sp)
    80005cf6:	74a2                	ld	s1,40(sp)
    80005cf8:	6121                	addi	sp,sp,64
    80005cfa:	8082                	ret
    80005cfc:	0000                	unimp
	...

0000000080005d00 <kernelvec>:
    80005d00:	7111                	addi	sp,sp,-256
    80005d02:	e006                	sd	ra,0(sp)
    80005d04:	e40a                	sd	sp,8(sp)
    80005d06:	e80e                	sd	gp,16(sp)
    80005d08:	ec12                	sd	tp,24(sp)
    80005d0a:	f016                	sd	t0,32(sp)
    80005d0c:	f41a                	sd	t1,40(sp)
    80005d0e:	f81e                	sd	t2,48(sp)
    80005d10:	fc22                	sd	s0,56(sp)
    80005d12:	e0a6                	sd	s1,64(sp)
    80005d14:	e4aa                	sd	a0,72(sp)
    80005d16:	e8ae                	sd	a1,80(sp)
    80005d18:	ecb2                	sd	a2,88(sp)
    80005d1a:	f0b6                	sd	a3,96(sp)
    80005d1c:	f4ba                	sd	a4,104(sp)
    80005d1e:	f8be                	sd	a5,112(sp)
    80005d20:	fcc2                	sd	a6,120(sp)
    80005d22:	e146                	sd	a7,128(sp)
    80005d24:	e54a                	sd	s2,136(sp)
    80005d26:	e94e                	sd	s3,144(sp)
    80005d28:	ed52                	sd	s4,152(sp)
    80005d2a:	f156                	sd	s5,160(sp)
    80005d2c:	f55a                	sd	s6,168(sp)
    80005d2e:	f95e                	sd	s7,176(sp)
    80005d30:	fd62                	sd	s8,184(sp)
    80005d32:	e1e6                	sd	s9,192(sp)
    80005d34:	e5ea                	sd	s10,200(sp)
    80005d36:	e9ee                	sd	s11,208(sp)
    80005d38:	edf2                	sd	t3,216(sp)
    80005d3a:	f1f6                	sd	t4,224(sp)
    80005d3c:	f5fa                	sd	t5,232(sp)
    80005d3e:	f9fe                	sd	t6,240(sp)
    80005d40:	d61fc0ef          	jal	ra,80002aa0 <kerneltrap>
    80005d44:	6082                	ld	ra,0(sp)
    80005d46:	6122                	ld	sp,8(sp)
    80005d48:	61c2                	ld	gp,16(sp)
    80005d4a:	7282                	ld	t0,32(sp)
    80005d4c:	7322                	ld	t1,40(sp)
    80005d4e:	73c2                	ld	t2,48(sp)
    80005d50:	7462                	ld	s0,56(sp)
    80005d52:	6486                	ld	s1,64(sp)
    80005d54:	6526                	ld	a0,72(sp)
    80005d56:	65c6                	ld	a1,80(sp)
    80005d58:	6666                	ld	a2,88(sp)
    80005d5a:	7686                	ld	a3,96(sp)
    80005d5c:	7726                	ld	a4,104(sp)
    80005d5e:	77c6                	ld	a5,112(sp)
    80005d60:	7866                	ld	a6,120(sp)
    80005d62:	688a                	ld	a7,128(sp)
    80005d64:	692a                	ld	s2,136(sp)
    80005d66:	69ca                	ld	s3,144(sp)
    80005d68:	6a6a                	ld	s4,152(sp)
    80005d6a:	7a8a                	ld	s5,160(sp)
    80005d6c:	7b2a                	ld	s6,168(sp)
    80005d6e:	7bca                	ld	s7,176(sp)
    80005d70:	7c6a                	ld	s8,184(sp)
    80005d72:	6c8e                	ld	s9,192(sp)
    80005d74:	6d2e                	ld	s10,200(sp)
    80005d76:	6dce                	ld	s11,208(sp)
    80005d78:	6e6e                	ld	t3,216(sp)
    80005d7a:	7e8e                	ld	t4,224(sp)
    80005d7c:	7f2e                	ld	t5,232(sp)
    80005d7e:	7fce                	ld	t6,240(sp)
    80005d80:	6111                	addi	sp,sp,256
    80005d82:	10200073          	sret
    80005d86:	00000013          	nop
    80005d8a:	00000013          	nop
    80005d8e:	0001                	nop

0000000080005d90 <timervec>:
    80005d90:	34051573          	csrrw	a0,mscratch,a0
    80005d94:	e10c                	sd	a1,0(a0)
    80005d96:	e510                	sd	a2,8(a0)
    80005d98:	e914                	sd	a3,16(a0)
    80005d9a:	6d0c                	ld	a1,24(a0)
    80005d9c:	7110                	ld	a2,32(a0)
    80005d9e:	6194                	ld	a3,0(a1)
    80005da0:	96b2                	add	a3,a3,a2
    80005da2:	e194                	sd	a3,0(a1)
    80005da4:	4589                	li	a1,2
    80005da6:	14459073          	csrw	sip,a1
    80005daa:	6914                	ld	a3,16(a0)
    80005dac:	6510                	ld	a2,8(a0)
    80005dae:	610c                	ld	a1,0(a0)
    80005db0:	34051573          	csrrw	a0,mscratch,a0
    80005db4:	30200073          	mret
	...

0000000080005dba <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005dba:	1141                	addi	sp,sp,-16
    80005dbc:	e422                	sd	s0,8(sp)
    80005dbe:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005dc0:	0c0007b7          	lui	a5,0xc000
    80005dc4:	4705                	li	a4,1
    80005dc6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005dc8:	c3d8                	sw	a4,4(a5)
}
    80005dca:	6422                	ld	s0,8(sp)
    80005dcc:	0141                	addi	sp,sp,16
    80005dce:	8082                	ret

0000000080005dd0 <plicinithart>:

void
plicinithart(void)
{
    80005dd0:	1141                	addi	sp,sp,-16
    80005dd2:	e406                	sd	ra,8(sp)
    80005dd4:	e022                	sd	s0,0(sp)
    80005dd6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005dd8:	ffffc097          	auipc	ra,0xffffc
    80005ddc:	c88080e7          	jalr	-888(ra) # 80001a60 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005de0:	0085171b          	slliw	a4,a0,0x8
    80005de4:	0c0027b7          	lui	a5,0xc002
    80005de8:	97ba                	add	a5,a5,a4
    80005dea:	40200713          	li	a4,1026
    80005dee:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005df2:	00d5151b          	slliw	a0,a0,0xd
    80005df6:	0c2017b7          	lui	a5,0xc201
    80005dfa:	953e                	add	a0,a0,a5
    80005dfc:	00052023          	sw	zero,0(a0)
}
    80005e00:	60a2                	ld	ra,8(sp)
    80005e02:	6402                	ld	s0,0(sp)
    80005e04:	0141                	addi	sp,sp,16
    80005e06:	8082                	ret

0000000080005e08 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005e08:	1141                	addi	sp,sp,-16
    80005e0a:	e406                	sd	ra,8(sp)
    80005e0c:	e022                	sd	s0,0(sp)
    80005e0e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e10:	ffffc097          	auipc	ra,0xffffc
    80005e14:	c50080e7          	jalr	-944(ra) # 80001a60 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005e18:	00d5179b          	slliw	a5,a0,0xd
    80005e1c:	0c201537          	lui	a0,0xc201
    80005e20:	953e                	add	a0,a0,a5
  return irq;
}
    80005e22:	4148                	lw	a0,4(a0)
    80005e24:	60a2                	ld	ra,8(sp)
    80005e26:	6402                	ld	s0,0(sp)
    80005e28:	0141                	addi	sp,sp,16
    80005e2a:	8082                	ret

0000000080005e2c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005e2c:	1101                	addi	sp,sp,-32
    80005e2e:	ec06                	sd	ra,24(sp)
    80005e30:	e822                	sd	s0,16(sp)
    80005e32:	e426                	sd	s1,8(sp)
    80005e34:	1000                	addi	s0,sp,32
    80005e36:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005e38:	ffffc097          	auipc	ra,0xffffc
    80005e3c:	c28080e7          	jalr	-984(ra) # 80001a60 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005e40:	00d5151b          	slliw	a0,a0,0xd
    80005e44:	0c2017b7          	lui	a5,0xc201
    80005e48:	97aa                	add	a5,a5,a0
    80005e4a:	c3c4                	sw	s1,4(a5)
}
    80005e4c:	60e2                	ld	ra,24(sp)
    80005e4e:	6442                	ld	s0,16(sp)
    80005e50:	64a2                	ld	s1,8(sp)
    80005e52:	6105                	addi	sp,sp,32
    80005e54:	8082                	ret

0000000080005e56 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005e56:	1141                	addi	sp,sp,-16
    80005e58:	e406                	sd	ra,8(sp)
    80005e5a:	e022                	sd	s0,0(sp)
    80005e5c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005e5e:	479d                	li	a5,7
    80005e60:	06a7c963          	blt	a5,a0,80005ed2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005e64:	0001d797          	auipc	a5,0x1d
    80005e68:	19c78793          	addi	a5,a5,412 # 80023000 <disk>
    80005e6c:	00a78733          	add	a4,a5,a0
    80005e70:	6789                	lui	a5,0x2
    80005e72:	97ba                	add	a5,a5,a4
    80005e74:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005e78:	e7ad                	bnez	a5,80005ee2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005e7a:	00451793          	slli	a5,a0,0x4
    80005e7e:	0001f717          	auipc	a4,0x1f
    80005e82:	18270713          	addi	a4,a4,386 # 80025000 <disk+0x2000>
    80005e86:	6314                	ld	a3,0(a4)
    80005e88:	96be                	add	a3,a3,a5
    80005e8a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005e8e:	6314                	ld	a3,0(a4)
    80005e90:	96be                	add	a3,a3,a5
    80005e92:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005e96:	6314                	ld	a3,0(a4)
    80005e98:	96be                	add	a3,a3,a5
    80005e9a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005e9e:	6318                	ld	a4,0(a4)
    80005ea0:	97ba                	add	a5,a5,a4
    80005ea2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005ea6:	0001d797          	auipc	a5,0x1d
    80005eaa:	15a78793          	addi	a5,a5,346 # 80023000 <disk>
    80005eae:	97aa                	add	a5,a5,a0
    80005eb0:	6509                	lui	a0,0x2
    80005eb2:	953e                	add	a0,a0,a5
    80005eb4:	4785                	li	a5,1
    80005eb6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005eba:	0001f517          	auipc	a0,0x1f
    80005ebe:	15e50513          	addi	a0,a0,350 # 80025018 <disk+0x2018>
    80005ec2:	ffffc097          	auipc	ra,0xffffc
    80005ec6:	548080e7          	jalr	1352(ra) # 8000240a <wakeup>
}
    80005eca:	60a2                	ld	ra,8(sp)
    80005ecc:	6402                	ld	s0,0(sp)
    80005ece:	0141                	addi	sp,sp,16
    80005ed0:	8082                	ret
    panic("free_desc 1");
    80005ed2:	00003517          	auipc	a0,0x3
    80005ed6:	94e50513          	addi	a0,a0,-1714 # 80008820 <syscalls+0x330>
    80005eda:	ffffa097          	auipc	ra,0xffffa
    80005ede:	664080e7          	jalr	1636(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005ee2:	00003517          	auipc	a0,0x3
    80005ee6:	94e50513          	addi	a0,a0,-1714 # 80008830 <syscalls+0x340>
    80005eea:	ffffa097          	auipc	ra,0xffffa
    80005eee:	654080e7          	jalr	1620(ra) # 8000053e <panic>

0000000080005ef2 <virtio_disk_init>:
{
    80005ef2:	1101                	addi	sp,sp,-32
    80005ef4:	ec06                	sd	ra,24(sp)
    80005ef6:	e822                	sd	s0,16(sp)
    80005ef8:	e426                	sd	s1,8(sp)
    80005efa:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005efc:	00003597          	auipc	a1,0x3
    80005f00:	94458593          	addi	a1,a1,-1724 # 80008840 <syscalls+0x350>
    80005f04:	0001f517          	auipc	a0,0x1f
    80005f08:	22450513          	addi	a0,a0,548 # 80025128 <disk+0x2128>
    80005f0c:	ffffb097          	auipc	ra,0xffffb
    80005f10:	c48080e7          	jalr	-952(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f14:	100017b7          	lui	a5,0x10001
    80005f18:	4398                	lw	a4,0(a5)
    80005f1a:	2701                	sext.w	a4,a4
    80005f1c:	747277b7          	lui	a5,0x74727
    80005f20:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005f24:	0ef71163          	bne	a4,a5,80006006 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f28:	100017b7          	lui	a5,0x10001
    80005f2c:	43dc                	lw	a5,4(a5)
    80005f2e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f30:	4705                	li	a4,1
    80005f32:	0ce79a63          	bne	a5,a4,80006006 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f36:	100017b7          	lui	a5,0x10001
    80005f3a:	479c                	lw	a5,8(a5)
    80005f3c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f3e:	4709                	li	a4,2
    80005f40:	0ce79363          	bne	a5,a4,80006006 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005f44:	100017b7          	lui	a5,0x10001
    80005f48:	47d8                	lw	a4,12(a5)
    80005f4a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f4c:	554d47b7          	lui	a5,0x554d4
    80005f50:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005f54:	0af71963          	bne	a4,a5,80006006 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f58:	100017b7          	lui	a5,0x10001
    80005f5c:	4705                	li	a4,1
    80005f5e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f60:	470d                	li	a4,3
    80005f62:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005f64:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005f66:	c7ffe737          	lui	a4,0xc7ffe
    80005f6a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd73df>
    80005f6e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005f70:	2701                	sext.w	a4,a4
    80005f72:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f74:	472d                	li	a4,11
    80005f76:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f78:	473d                	li	a4,15
    80005f7a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005f7c:	6705                	lui	a4,0x1
    80005f7e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005f80:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005f84:	5bdc                	lw	a5,52(a5)
    80005f86:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f88:	c7d9                	beqz	a5,80006016 <virtio_disk_init+0x124>
  if(max < NUM)
    80005f8a:	471d                	li	a4,7
    80005f8c:	08f77d63          	bgeu	a4,a5,80006026 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f90:	100014b7          	lui	s1,0x10001
    80005f94:	47a1                	li	a5,8
    80005f96:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005f98:	6609                	lui	a2,0x2
    80005f9a:	4581                	li	a1,0
    80005f9c:	0001d517          	auipc	a0,0x1d
    80005fa0:	06450513          	addi	a0,a0,100 # 80023000 <disk>
    80005fa4:	ffffb097          	auipc	ra,0xffffb
    80005fa8:	d3c080e7          	jalr	-708(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005fac:	0001d717          	auipc	a4,0x1d
    80005fb0:	05470713          	addi	a4,a4,84 # 80023000 <disk>
    80005fb4:	00c75793          	srli	a5,a4,0xc
    80005fb8:	2781                	sext.w	a5,a5
    80005fba:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005fbc:	0001f797          	auipc	a5,0x1f
    80005fc0:	04478793          	addi	a5,a5,68 # 80025000 <disk+0x2000>
    80005fc4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005fc6:	0001d717          	auipc	a4,0x1d
    80005fca:	0ba70713          	addi	a4,a4,186 # 80023080 <disk+0x80>
    80005fce:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005fd0:	0001e717          	auipc	a4,0x1e
    80005fd4:	03070713          	addi	a4,a4,48 # 80024000 <disk+0x1000>
    80005fd8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005fda:	4705                	li	a4,1
    80005fdc:	00e78c23          	sb	a4,24(a5)
    80005fe0:	00e78ca3          	sb	a4,25(a5)
    80005fe4:	00e78d23          	sb	a4,26(a5)
    80005fe8:	00e78da3          	sb	a4,27(a5)
    80005fec:	00e78e23          	sb	a4,28(a5)
    80005ff0:	00e78ea3          	sb	a4,29(a5)
    80005ff4:	00e78f23          	sb	a4,30(a5)
    80005ff8:	00e78fa3          	sb	a4,31(a5)
}
    80005ffc:	60e2                	ld	ra,24(sp)
    80005ffe:	6442                	ld	s0,16(sp)
    80006000:	64a2                	ld	s1,8(sp)
    80006002:	6105                	addi	sp,sp,32
    80006004:	8082                	ret
    panic("could not find virtio disk");
    80006006:	00003517          	auipc	a0,0x3
    8000600a:	84a50513          	addi	a0,a0,-1974 # 80008850 <syscalls+0x360>
    8000600e:	ffffa097          	auipc	ra,0xffffa
    80006012:	530080e7          	jalr	1328(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006016:	00003517          	auipc	a0,0x3
    8000601a:	85a50513          	addi	a0,a0,-1958 # 80008870 <syscalls+0x380>
    8000601e:	ffffa097          	auipc	ra,0xffffa
    80006022:	520080e7          	jalr	1312(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006026:	00003517          	auipc	a0,0x3
    8000602a:	86a50513          	addi	a0,a0,-1942 # 80008890 <syscalls+0x3a0>
    8000602e:	ffffa097          	auipc	ra,0xffffa
    80006032:	510080e7          	jalr	1296(ra) # 8000053e <panic>

0000000080006036 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006036:	7159                	addi	sp,sp,-112
    80006038:	f486                	sd	ra,104(sp)
    8000603a:	f0a2                	sd	s0,96(sp)
    8000603c:	eca6                	sd	s1,88(sp)
    8000603e:	e8ca                	sd	s2,80(sp)
    80006040:	e4ce                	sd	s3,72(sp)
    80006042:	e0d2                	sd	s4,64(sp)
    80006044:	fc56                	sd	s5,56(sp)
    80006046:	f85a                	sd	s6,48(sp)
    80006048:	f45e                	sd	s7,40(sp)
    8000604a:	f062                	sd	s8,32(sp)
    8000604c:	ec66                	sd	s9,24(sp)
    8000604e:	e86a                	sd	s10,16(sp)
    80006050:	1880                	addi	s0,sp,112
    80006052:	892a                	mv	s2,a0
    80006054:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006056:	00c52c83          	lw	s9,12(a0)
    8000605a:	001c9c9b          	slliw	s9,s9,0x1
    8000605e:	1c82                	slli	s9,s9,0x20
    80006060:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006064:	0001f517          	auipc	a0,0x1f
    80006068:	0c450513          	addi	a0,a0,196 # 80025128 <disk+0x2128>
    8000606c:	ffffb097          	auipc	ra,0xffffb
    80006070:	b78080e7          	jalr	-1160(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006074:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006076:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006078:	0001db97          	auipc	s7,0x1d
    8000607c:	f88b8b93          	addi	s7,s7,-120 # 80023000 <disk>
    80006080:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006082:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006084:	8a4e                	mv	s4,s3
    80006086:	a051                	j	8000610a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006088:	00fb86b3          	add	a3,s7,a5
    8000608c:	96da                	add	a3,a3,s6
    8000608e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006092:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006094:	0207c563          	bltz	a5,800060be <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006098:	2485                	addiw	s1,s1,1
    8000609a:	0711                	addi	a4,a4,4
    8000609c:	25548063          	beq	s1,s5,800062dc <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    800060a0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800060a2:	0001f697          	auipc	a3,0x1f
    800060a6:	f7668693          	addi	a3,a3,-138 # 80025018 <disk+0x2018>
    800060aa:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800060ac:	0006c583          	lbu	a1,0(a3)
    800060b0:	fde1                	bnez	a1,80006088 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800060b2:	2785                	addiw	a5,a5,1
    800060b4:	0685                	addi	a3,a3,1
    800060b6:	ff879be3          	bne	a5,s8,800060ac <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800060ba:	57fd                	li	a5,-1
    800060bc:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800060be:	02905a63          	blez	s1,800060f2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800060c2:	f9042503          	lw	a0,-112(s0)
    800060c6:	00000097          	auipc	ra,0x0
    800060ca:	d90080e7          	jalr	-624(ra) # 80005e56 <free_desc>
      for(int j = 0; j < i; j++)
    800060ce:	4785                	li	a5,1
    800060d0:	0297d163          	bge	a5,s1,800060f2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800060d4:	f9442503          	lw	a0,-108(s0)
    800060d8:	00000097          	auipc	ra,0x0
    800060dc:	d7e080e7          	jalr	-642(ra) # 80005e56 <free_desc>
      for(int j = 0; j < i; j++)
    800060e0:	4789                	li	a5,2
    800060e2:	0097d863          	bge	a5,s1,800060f2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800060e6:	f9842503          	lw	a0,-104(s0)
    800060ea:	00000097          	auipc	ra,0x0
    800060ee:	d6c080e7          	jalr	-660(ra) # 80005e56 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800060f2:	0001f597          	auipc	a1,0x1f
    800060f6:	03658593          	addi	a1,a1,54 # 80025128 <disk+0x2128>
    800060fa:	0001f517          	auipc	a0,0x1f
    800060fe:	f1e50513          	addi	a0,a0,-226 # 80025018 <disk+0x2018>
    80006102:	ffffc097          	auipc	ra,0xffffc
    80006106:	17c080e7          	jalr	380(ra) # 8000227e <sleep>
  for(int i = 0; i < 3; i++){
    8000610a:	f9040713          	addi	a4,s0,-112
    8000610e:	84ce                	mv	s1,s3
    80006110:	bf41                	j	800060a0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006112:	20058713          	addi	a4,a1,512
    80006116:	00471693          	slli	a3,a4,0x4
    8000611a:	0001d717          	auipc	a4,0x1d
    8000611e:	ee670713          	addi	a4,a4,-282 # 80023000 <disk>
    80006122:	9736                	add	a4,a4,a3
    80006124:	4685                	li	a3,1
    80006126:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000612a:	20058713          	addi	a4,a1,512
    8000612e:	00471693          	slli	a3,a4,0x4
    80006132:	0001d717          	auipc	a4,0x1d
    80006136:	ece70713          	addi	a4,a4,-306 # 80023000 <disk>
    8000613a:	9736                	add	a4,a4,a3
    8000613c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006140:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006144:	7679                	lui	a2,0xffffe
    80006146:	963e                	add	a2,a2,a5
    80006148:	0001f697          	auipc	a3,0x1f
    8000614c:	eb868693          	addi	a3,a3,-328 # 80025000 <disk+0x2000>
    80006150:	6298                	ld	a4,0(a3)
    80006152:	9732                	add	a4,a4,a2
    80006154:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006156:	6298                	ld	a4,0(a3)
    80006158:	9732                	add	a4,a4,a2
    8000615a:	4541                	li	a0,16
    8000615c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000615e:	6298                	ld	a4,0(a3)
    80006160:	9732                	add	a4,a4,a2
    80006162:	4505                	li	a0,1
    80006164:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006168:	f9442703          	lw	a4,-108(s0)
    8000616c:	6288                	ld	a0,0(a3)
    8000616e:	962a                	add	a2,a2,a0
    80006170:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd6c8e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006174:	0712                	slli	a4,a4,0x4
    80006176:	6290                	ld	a2,0(a3)
    80006178:	963a                	add	a2,a2,a4
    8000617a:	05890513          	addi	a0,s2,88
    8000617e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006180:	6294                	ld	a3,0(a3)
    80006182:	96ba                	add	a3,a3,a4
    80006184:	40000613          	li	a2,1024
    80006188:	c690                	sw	a2,8(a3)
  if(write)
    8000618a:	140d0063          	beqz	s10,800062ca <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000618e:	0001f697          	auipc	a3,0x1f
    80006192:	e726b683          	ld	a3,-398(a3) # 80025000 <disk+0x2000>
    80006196:	96ba                	add	a3,a3,a4
    80006198:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000619c:	0001d817          	auipc	a6,0x1d
    800061a0:	e6480813          	addi	a6,a6,-412 # 80023000 <disk>
    800061a4:	0001f517          	auipc	a0,0x1f
    800061a8:	e5c50513          	addi	a0,a0,-420 # 80025000 <disk+0x2000>
    800061ac:	6114                	ld	a3,0(a0)
    800061ae:	96ba                	add	a3,a3,a4
    800061b0:	00c6d603          	lhu	a2,12(a3)
    800061b4:	00166613          	ori	a2,a2,1
    800061b8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800061bc:	f9842683          	lw	a3,-104(s0)
    800061c0:	6110                	ld	a2,0(a0)
    800061c2:	9732                	add	a4,a4,a2
    800061c4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800061c8:	20058613          	addi	a2,a1,512
    800061cc:	0612                	slli	a2,a2,0x4
    800061ce:	9642                	add	a2,a2,a6
    800061d0:	577d                	li	a4,-1
    800061d2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800061d6:	00469713          	slli	a4,a3,0x4
    800061da:	6114                	ld	a3,0(a0)
    800061dc:	96ba                	add	a3,a3,a4
    800061de:	03078793          	addi	a5,a5,48
    800061e2:	97c2                	add	a5,a5,a6
    800061e4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800061e6:	611c                	ld	a5,0(a0)
    800061e8:	97ba                	add	a5,a5,a4
    800061ea:	4685                	li	a3,1
    800061ec:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800061ee:	611c                	ld	a5,0(a0)
    800061f0:	97ba                	add	a5,a5,a4
    800061f2:	4809                	li	a6,2
    800061f4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800061f8:	611c                	ld	a5,0(a0)
    800061fa:	973e                	add	a4,a4,a5
    800061fc:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006200:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006204:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006208:	6518                	ld	a4,8(a0)
    8000620a:	00275783          	lhu	a5,2(a4)
    8000620e:	8b9d                	andi	a5,a5,7
    80006210:	0786                	slli	a5,a5,0x1
    80006212:	97ba                	add	a5,a5,a4
    80006214:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006218:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000621c:	6518                	ld	a4,8(a0)
    8000621e:	00275783          	lhu	a5,2(a4)
    80006222:	2785                	addiw	a5,a5,1
    80006224:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006228:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000622c:	100017b7          	lui	a5,0x10001
    80006230:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006234:	00492703          	lw	a4,4(s2)
    80006238:	4785                	li	a5,1
    8000623a:	02f71163          	bne	a4,a5,8000625c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000623e:	0001f997          	auipc	s3,0x1f
    80006242:	eea98993          	addi	s3,s3,-278 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006246:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006248:	85ce                	mv	a1,s3
    8000624a:	854a                	mv	a0,s2
    8000624c:	ffffc097          	auipc	ra,0xffffc
    80006250:	032080e7          	jalr	50(ra) # 8000227e <sleep>
  while(b->disk == 1) {
    80006254:	00492783          	lw	a5,4(s2)
    80006258:	fe9788e3          	beq	a5,s1,80006248 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000625c:	f9042903          	lw	s2,-112(s0)
    80006260:	20090793          	addi	a5,s2,512
    80006264:	00479713          	slli	a4,a5,0x4
    80006268:	0001d797          	auipc	a5,0x1d
    8000626c:	d9878793          	addi	a5,a5,-616 # 80023000 <disk>
    80006270:	97ba                	add	a5,a5,a4
    80006272:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006276:	0001f997          	auipc	s3,0x1f
    8000627a:	d8a98993          	addi	s3,s3,-630 # 80025000 <disk+0x2000>
    8000627e:	00491713          	slli	a4,s2,0x4
    80006282:	0009b783          	ld	a5,0(s3)
    80006286:	97ba                	add	a5,a5,a4
    80006288:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000628c:	854a                	mv	a0,s2
    8000628e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006292:	00000097          	auipc	ra,0x0
    80006296:	bc4080e7          	jalr	-1084(ra) # 80005e56 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000629a:	8885                	andi	s1,s1,1
    8000629c:	f0ed                	bnez	s1,8000627e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000629e:	0001f517          	auipc	a0,0x1f
    800062a2:	e8a50513          	addi	a0,a0,-374 # 80025128 <disk+0x2128>
    800062a6:	ffffb097          	auipc	ra,0xffffb
    800062aa:	9f2080e7          	jalr	-1550(ra) # 80000c98 <release>
}
    800062ae:	70a6                	ld	ra,104(sp)
    800062b0:	7406                	ld	s0,96(sp)
    800062b2:	64e6                	ld	s1,88(sp)
    800062b4:	6946                	ld	s2,80(sp)
    800062b6:	69a6                	ld	s3,72(sp)
    800062b8:	6a06                	ld	s4,64(sp)
    800062ba:	7ae2                	ld	s5,56(sp)
    800062bc:	7b42                	ld	s6,48(sp)
    800062be:	7ba2                	ld	s7,40(sp)
    800062c0:	7c02                	ld	s8,32(sp)
    800062c2:	6ce2                	ld	s9,24(sp)
    800062c4:	6d42                	ld	s10,16(sp)
    800062c6:	6165                	addi	sp,sp,112
    800062c8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800062ca:	0001f697          	auipc	a3,0x1f
    800062ce:	d366b683          	ld	a3,-714(a3) # 80025000 <disk+0x2000>
    800062d2:	96ba                	add	a3,a3,a4
    800062d4:	4609                	li	a2,2
    800062d6:	00c69623          	sh	a2,12(a3)
    800062da:	b5c9                	j	8000619c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800062dc:	f9042583          	lw	a1,-112(s0)
    800062e0:	20058793          	addi	a5,a1,512
    800062e4:	0792                	slli	a5,a5,0x4
    800062e6:	0001d517          	auipc	a0,0x1d
    800062ea:	dc250513          	addi	a0,a0,-574 # 800230a8 <disk+0xa8>
    800062ee:	953e                	add	a0,a0,a5
  if(write)
    800062f0:	e20d11e3          	bnez	s10,80006112 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800062f4:	20058713          	addi	a4,a1,512
    800062f8:	00471693          	slli	a3,a4,0x4
    800062fc:	0001d717          	auipc	a4,0x1d
    80006300:	d0470713          	addi	a4,a4,-764 # 80023000 <disk>
    80006304:	9736                	add	a4,a4,a3
    80006306:	0a072423          	sw	zero,168(a4)
    8000630a:	b505                	j	8000612a <virtio_disk_rw+0xf4>

000000008000630c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000630c:	1101                	addi	sp,sp,-32
    8000630e:	ec06                	sd	ra,24(sp)
    80006310:	e822                	sd	s0,16(sp)
    80006312:	e426                	sd	s1,8(sp)
    80006314:	e04a                	sd	s2,0(sp)
    80006316:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006318:	0001f517          	auipc	a0,0x1f
    8000631c:	e1050513          	addi	a0,a0,-496 # 80025128 <disk+0x2128>
    80006320:	ffffb097          	auipc	ra,0xffffb
    80006324:	8c4080e7          	jalr	-1852(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006328:	10001737          	lui	a4,0x10001
    8000632c:	533c                	lw	a5,96(a4)
    8000632e:	8b8d                	andi	a5,a5,3
    80006330:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006332:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006336:	0001f797          	auipc	a5,0x1f
    8000633a:	cca78793          	addi	a5,a5,-822 # 80025000 <disk+0x2000>
    8000633e:	6b94                	ld	a3,16(a5)
    80006340:	0207d703          	lhu	a4,32(a5)
    80006344:	0026d783          	lhu	a5,2(a3)
    80006348:	06f70163          	beq	a4,a5,800063aa <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000634c:	0001d917          	auipc	s2,0x1d
    80006350:	cb490913          	addi	s2,s2,-844 # 80023000 <disk>
    80006354:	0001f497          	auipc	s1,0x1f
    80006358:	cac48493          	addi	s1,s1,-852 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000635c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006360:	6898                	ld	a4,16(s1)
    80006362:	0204d783          	lhu	a5,32(s1)
    80006366:	8b9d                	andi	a5,a5,7
    80006368:	078e                	slli	a5,a5,0x3
    8000636a:	97ba                	add	a5,a5,a4
    8000636c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000636e:	20078713          	addi	a4,a5,512
    80006372:	0712                	slli	a4,a4,0x4
    80006374:	974a                	add	a4,a4,s2
    80006376:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000637a:	e731                	bnez	a4,800063c6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000637c:	20078793          	addi	a5,a5,512
    80006380:	0792                	slli	a5,a5,0x4
    80006382:	97ca                	add	a5,a5,s2
    80006384:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006386:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000638a:	ffffc097          	auipc	ra,0xffffc
    8000638e:	080080e7          	jalr	128(ra) # 8000240a <wakeup>

    disk.used_idx += 1;
    80006392:	0204d783          	lhu	a5,32(s1)
    80006396:	2785                	addiw	a5,a5,1
    80006398:	17c2                	slli	a5,a5,0x30
    8000639a:	93c1                	srli	a5,a5,0x30
    8000639c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800063a0:	6898                	ld	a4,16(s1)
    800063a2:	00275703          	lhu	a4,2(a4)
    800063a6:	faf71be3          	bne	a4,a5,8000635c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800063aa:	0001f517          	auipc	a0,0x1f
    800063ae:	d7e50513          	addi	a0,a0,-642 # 80025128 <disk+0x2128>
    800063b2:	ffffb097          	auipc	ra,0xffffb
    800063b6:	8e6080e7          	jalr	-1818(ra) # 80000c98 <release>
}
    800063ba:	60e2                	ld	ra,24(sp)
    800063bc:	6442                	ld	s0,16(sp)
    800063be:	64a2                	ld	s1,8(sp)
    800063c0:	6902                	ld	s2,0(sp)
    800063c2:	6105                	addi	sp,sp,32
    800063c4:	8082                	ret
      panic("virtio_disk_intr status");
    800063c6:	00002517          	auipc	a0,0x2
    800063ca:	4ea50513          	addi	a0,a0,1258 # 800088b0 <syscalls+0x3c0>
    800063ce:	ffffa097          	auipc	ra,0xffffa
    800063d2:	170080e7          	jalr	368(ra) # 8000053e <panic>

00000000800063d6 <sgenrand>:
static int mti=N+1; /* mti==N+1 means mt[N] is not initialized */

/* initializing the array with a NONZERO seed */
void
sgenrand(unsigned long seed)
{
    800063d6:	1141                	addi	sp,sp,-16
    800063d8:	e422                	sd	s0,8(sp)
    800063da:	0800                	addi	s0,sp,16
    /* setting initial seeds to mt[N] using         */
    /* the generator Line 25 of Table 1 in          */
    /* [KNUTH 1981, The Art of Computer Programming */
    /*    Vol. 2 (2nd Ed.), pp102]                  */
    mt[0]= seed & 0xffffffff;
    800063dc:	00020717          	auipc	a4,0x20
    800063e0:	c2470713          	addi	a4,a4,-988 # 80026000 <mt>
    800063e4:	1502                	slli	a0,a0,0x20
    800063e6:	9101                	srli	a0,a0,0x20
    800063e8:	e308                	sd	a0,0(a4)
    for (mti=1; mti<N; mti++)
    800063ea:	00021597          	auipc	a1,0x21
    800063ee:	f8e58593          	addi	a1,a1,-114 # 80027378 <mt+0x1378>
        mt[mti] = (69069 * mt[mti-1]) & 0xffffffff;
    800063f2:	6645                	lui	a2,0x11
    800063f4:	dcd60613          	addi	a2,a2,-563 # 10dcd <_entry-0x7ffef233>
    800063f8:	56fd                	li	a3,-1
    800063fa:	9281                	srli	a3,a3,0x20
    800063fc:	631c                	ld	a5,0(a4)
    800063fe:	02c787b3          	mul	a5,a5,a2
    80006402:	8ff5                	and	a5,a5,a3
    80006404:	e71c                	sd	a5,8(a4)
    for (mti=1; mti<N; mti++)
    80006406:	0721                	addi	a4,a4,8
    80006408:	feb71ae3          	bne	a4,a1,800063fc <sgenrand+0x26>
    8000640c:	27000793          	li	a5,624
    80006410:	00002717          	auipc	a4,0x2
    80006414:	4cf72c23          	sw	a5,1240(a4) # 800088e8 <mti>
}
    80006418:	6422                	ld	s0,8(sp)
    8000641a:	0141                	addi	sp,sp,16
    8000641c:	8082                	ret

000000008000641e <genrand>:

long /* for integer generation */
genrand()
{
    8000641e:	1141                	addi	sp,sp,-16
    80006420:	e406                	sd	ra,8(sp)
    80006422:	e022                	sd	s0,0(sp)
    80006424:	0800                	addi	s0,sp,16
    unsigned long y;
    static unsigned long mag01[2]={0x0, MATRIX_A};
    /* mag01[x] = x * MATRIX_A  for x=0,1 */

    if (mti >= N) { /* generate N words at one time */
    80006426:	00002797          	auipc	a5,0x2
    8000642a:	4c27a783          	lw	a5,1218(a5) # 800088e8 <mti>
    8000642e:	26f00713          	li	a4,623
    80006432:	0ef75963          	bge	a4,a5,80006524 <genrand+0x106>
        int kk;

        if (mti == N+1)   /* if sgenrand() has not been called, */
    80006436:	27100713          	li	a4,625
    8000643a:	12e78f63          	beq	a5,a4,80006578 <genrand+0x15a>
            sgenrand(4357); /* a default initial seed is used   */

        for (kk=0;kk<N-M;kk++) {
    8000643e:	00020817          	auipc	a6,0x20
    80006442:	bc280813          	addi	a6,a6,-1086 # 80026000 <mt>
    80006446:	00020e17          	auipc	t3,0x20
    8000644a:	2d2e0e13          	addi	t3,t3,722 # 80026718 <mt+0x718>
{
    8000644e:	8742                	mv	a4,a6
            y = (mt[kk]&UPPER_MASK)|(mt[kk+1]&LOWER_MASK);
    80006450:	4885                	li	a7,1
    80006452:	08fe                	slli	a7,a7,0x1f
    80006454:	80000537          	lui	a0,0x80000
    80006458:	fff54513          	not	a0,a0
            mt[kk] = mt[kk+M] ^ (y >> 1) ^ mag01[y & 0x1];
    8000645c:	6585                	lui	a1,0x1
    8000645e:	c6858593          	addi	a1,a1,-920 # c68 <_entry-0x7ffff398>
    80006462:	00002317          	auipc	t1,0x2
    80006466:	46630313          	addi	t1,t1,1126 # 800088c8 <mag01.985>
            y = (mt[kk]&UPPER_MASK)|(mt[kk+1]&LOWER_MASK);
    8000646a:	631c                	ld	a5,0(a4)
    8000646c:	0117f7b3          	and	a5,a5,a7
    80006470:	6714                	ld	a3,8(a4)
    80006472:	8ee9                	and	a3,a3,a0
    80006474:	8fd5                	or	a5,a5,a3
            mt[kk] = mt[kk+M] ^ (y >> 1) ^ mag01[y & 0x1];
    80006476:	00b70633          	add	a2,a4,a1
    8000647a:	0017d693          	srli	a3,a5,0x1
    8000647e:	6210                	ld	a2,0(a2)
    80006480:	8eb1                	xor	a3,a3,a2
    80006482:	8b85                	andi	a5,a5,1
    80006484:	078e                	slli	a5,a5,0x3
    80006486:	979a                	add	a5,a5,t1
    80006488:	639c                	ld	a5,0(a5)
    8000648a:	8fb5                	xor	a5,a5,a3
    8000648c:	e31c                	sd	a5,0(a4)
        for (kk=0;kk<N-M;kk++) {
    8000648e:	0721                	addi	a4,a4,8
    80006490:	fdc71de3          	bne	a4,t3,8000646a <genrand+0x4c>
        }
        for (;kk<N-1;kk++) {
    80006494:	6605                	lui	a2,0x1
    80006496:	c6060613          	addi	a2,a2,-928 # c60 <_entry-0x7ffff3a0>
    8000649a:	9642                	add	a2,a2,a6
            y = (mt[kk]&UPPER_MASK)|(mt[kk+1]&LOWER_MASK);
    8000649c:	4505                	li	a0,1
    8000649e:	057e                	slli	a0,a0,0x1f
    800064a0:	800005b7          	lui	a1,0x80000
    800064a4:	fff5c593          	not	a1,a1
            mt[kk] = mt[kk+(M-N)] ^ (y >> 1) ^ mag01[y & 0x1];
    800064a8:	00002897          	auipc	a7,0x2
    800064ac:	42088893          	addi	a7,a7,1056 # 800088c8 <mag01.985>
            y = (mt[kk]&UPPER_MASK)|(mt[kk+1]&LOWER_MASK);
    800064b0:	71883783          	ld	a5,1816(a6)
    800064b4:	8fe9                	and	a5,a5,a0
    800064b6:	72083703          	ld	a4,1824(a6)
    800064ba:	8f6d                	and	a4,a4,a1
    800064bc:	8fd9                	or	a5,a5,a4
            mt[kk] = mt[kk+(M-N)] ^ (y >> 1) ^ mag01[y & 0x1];
    800064be:	0017d713          	srli	a4,a5,0x1
    800064c2:	00083683          	ld	a3,0(a6)
    800064c6:	8f35                	xor	a4,a4,a3
    800064c8:	8b85                	andi	a5,a5,1
    800064ca:	078e                	slli	a5,a5,0x3
    800064cc:	97c6                	add	a5,a5,a7
    800064ce:	639c                	ld	a5,0(a5)
    800064d0:	8fb9                	xor	a5,a5,a4
    800064d2:	70f83c23          	sd	a5,1816(a6)
        for (;kk<N-1;kk++) {
    800064d6:	0821                	addi	a6,a6,8
    800064d8:	fcc81ce3          	bne	a6,a2,800064b0 <genrand+0x92>
        }
        y = (mt[N-1]&UPPER_MASK)|(mt[0]&LOWER_MASK);
    800064dc:	00021697          	auipc	a3,0x21
    800064e0:	b2468693          	addi	a3,a3,-1244 # 80027000 <mt+0x1000>
    800064e4:	3786b783          	ld	a5,888(a3)
    800064e8:	4705                	li	a4,1
    800064ea:	077e                	slli	a4,a4,0x1f
    800064ec:	8ff9                	and	a5,a5,a4
    800064ee:	00020717          	auipc	a4,0x20
    800064f2:	b1273703          	ld	a4,-1262(a4) # 80026000 <mt>
    800064f6:	1706                	slli	a4,a4,0x21
    800064f8:	9305                	srli	a4,a4,0x21
    800064fa:	8fd9                	or	a5,a5,a4
        mt[N-1] = mt[M-1] ^ (y >> 1) ^ mag01[y & 0x1];
    800064fc:	0017d713          	srli	a4,a5,0x1
    80006500:	c606b603          	ld	a2,-928(a3)
    80006504:	8f31                	xor	a4,a4,a2
    80006506:	8b85                	andi	a5,a5,1
    80006508:	078e                	slli	a5,a5,0x3
    8000650a:	00002617          	auipc	a2,0x2
    8000650e:	3be60613          	addi	a2,a2,958 # 800088c8 <mag01.985>
    80006512:	97b2                	add	a5,a5,a2
    80006514:	639c                	ld	a5,0(a5)
    80006516:	8fb9                	xor	a5,a5,a4
    80006518:	36f6bc23          	sd	a5,888(a3)

        mti = 0;
    8000651c:	00002797          	auipc	a5,0x2
    80006520:	3c07a623          	sw	zero,972(a5) # 800088e8 <mti>
    }
  
    y = mt[mti++];
    80006524:	00002717          	auipc	a4,0x2
    80006528:	3c470713          	addi	a4,a4,964 # 800088e8 <mti>
    8000652c:	431c                	lw	a5,0(a4)
    8000652e:	0017869b          	addiw	a3,a5,1
    80006532:	c314                	sw	a3,0(a4)
    80006534:	078e                	slli	a5,a5,0x3
    80006536:	00020717          	auipc	a4,0x20
    8000653a:	aca70713          	addi	a4,a4,-1334 # 80026000 <mt>
    8000653e:	97ba                	add	a5,a5,a4
    80006540:	6398                	ld	a4,0(a5)
    y ^= TEMPERING_SHIFT_U(y);
    80006542:	00b75793          	srli	a5,a4,0xb
    80006546:	8f3d                	xor	a4,a4,a5
    y ^= TEMPERING_SHIFT_S(y) & TEMPERING_MASK_B;
    80006548:	013a67b7          	lui	a5,0x13a6
    8000654c:	8ad78793          	addi	a5,a5,-1875 # 13a58ad <_entry-0x7ec5a753>
    80006550:	8ff9                	and	a5,a5,a4
    80006552:	079e                	slli	a5,a5,0x7
    80006554:	8fb9                	xor	a5,a5,a4
    y ^= TEMPERING_SHIFT_T(y) & TEMPERING_MASK_C;
    80006556:	00f79713          	slli	a4,a5,0xf
    8000655a:	077e36b7          	lui	a3,0x77e3
    8000655e:	0696                	slli	a3,a3,0x5
    80006560:	8f75                	and	a4,a4,a3
    80006562:	8fb9                	xor	a5,a5,a4
    y ^= TEMPERING_SHIFT_L(y);
    80006564:	0127d513          	srli	a0,a5,0x12
    80006568:	8fa9                	xor	a5,a5,a0

    // Strip off uppermost bit because we want a long,
    // not an unsigned long
    return y & RAND_MAX;
    8000656a:	02179513          	slli	a0,a5,0x21
}
    8000656e:	9105                	srli	a0,a0,0x21
    80006570:	60a2                	ld	ra,8(sp)
    80006572:	6402                	ld	s0,0(sp)
    80006574:	0141                	addi	sp,sp,16
    80006576:	8082                	ret
            sgenrand(4357); /* a default initial seed is used   */
    80006578:	6505                	lui	a0,0x1
    8000657a:	10550513          	addi	a0,a0,261 # 1105 <_entry-0x7fffeefb>
    8000657e:	00000097          	auipc	ra,0x0
    80006582:	e58080e7          	jalr	-424(ra) # 800063d6 <sgenrand>
    80006586:	bd65                	j	8000643e <genrand+0x20>

0000000080006588 <random_at_most>:

// Assumes 0 <= max <= RAND_MAX
// Returns in the half-open interval [0, max]
long random_at_most(long max) {
    80006588:	1101                	addi	sp,sp,-32
    8000658a:	ec06                	sd	ra,24(sp)
    8000658c:	e822                	sd	s0,16(sp)
    8000658e:	e426                	sd	s1,8(sp)
    80006590:	e04a                	sd	s2,0(sp)
    80006592:	1000                	addi	s0,sp,32
  unsigned long
    // max <= RAND_MAX < ULONG_MAX, so this is okay.
    num_bins = (unsigned long) max + 1,
    80006594:	0505                	addi	a0,a0,1
    num_rand = (unsigned long) RAND_MAX + 1,
    bin_size = num_rand / num_bins,
    80006596:	4485                	li	s1,1
    80006598:	04fe                	slli	s1,s1,0x1f
    8000659a:	02a4d933          	divu	s2,s1,a0
    defect   = num_rand % num_bins;
    8000659e:	02a4f533          	remu	a0,s1,a0
  long x;
  do {
   x = genrand();
  }
  // This is carefully written not to overflow
  while (num_rand - defect <= (unsigned long)x);
    800065a2:	4485                	li	s1,1
    800065a4:	04fe                	slli	s1,s1,0x1f
    800065a6:	8c89                	sub	s1,s1,a0
   x = genrand();
    800065a8:	00000097          	auipc	ra,0x0
    800065ac:	e76080e7          	jalr	-394(ra) # 8000641e <genrand>
  while (num_rand - defect <= (unsigned long)x);
    800065b0:	fe957ce3          	bgeu	a0,s1,800065a8 <random_at_most+0x20>

  // Truncated division is intentional
  return x/bin_size;
    800065b4:	03255533          	divu	a0,a0,s2
    800065b8:	60e2                	ld	ra,24(sp)
    800065ba:	6442                	ld	s0,16(sp)
    800065bc:	64a2                	ld	s1,8(sp)
    800065be:	6902                	ld	s2,0(sp)
    800065c0:	6105                	addi	sp,sp,32
    800065c2:	8082                	ret
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
