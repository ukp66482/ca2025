include ../rv32emu/mk/toolchain.mk

ARCH = -march=rv32izicsr
LINKER_SCRIPT = linker.ld

EMU ?= ../rv32emu/bin/rv32emu

AFLAGS = -g $(ARCH)
CFLAGS = -g -march=rv32i_zicsr -mabi=ilp32
LDFLAGS = -T $(LINKER_SCRIPT)
EXEC = test.elf

CC = $(CROSS_COMPILE)gcc
AS = $(CROSS_COMPILE)as
LD = $(CROSS_COMPILE)ld
OBJDUMP = $(CROSS_COMPILE)objdump

OBJS = start.o main.o perfcounter.o hanoi_iter_O0.o hanoi_iter_O2.o hanoi_iter_O3.o hanoi_rec_O0.o hanoi_rec_O2.o hanoi_rec_O3.o hanoi_iter_asm.o

.PHONY: all run dump clean

all: $(EXEC)

$(EXEC): $(OBJS) $(LINKER_SCRIPT)
	$(LD) $(LDFLAGS) -o $@ $(OBJS)

%.o: %.S
	$(AS) $(AFLAGS) $< -o $@

hanoi_rec_O0.o: hanoi_rec.c
	$(CC) $(CFLAGS) -O0 -DHANOI_SUFFIX=_O0 -c $< -o $@

hanoi_rec_O2.o: hanoi_rec.c
	$(CC) $(CFLAGS) -O2 -DHANOI_SUFFIX=_O2 -c $< -o $@

hanoi_rec_O3.o: hanoi_rec.c
	$(CC) $(CFLAGS) -O3 -DHANOI_SUFFIX=_O3 -c $< -o $@

hanoi_iter_O0.o: hanoi_iter.c
	$(CC) $(CFLAGS) -O0 -DHANOI_SUFFIX=_O0 -c $< -o $@

hanoi_iter_O2.o: hanoi_iter.c
	$(CC) $(CFLAGS) -O2 -DHANOI_SUFFIX=_O2 -c $< -o $@

hanoi_iter_O3.o: hanoi_iter.c
	$(CC) $(CFLAGS) -O3 -DHANOI_SUFFIX=_O3 -c $< -o $@

%.o: %.c
	$(CC) $(CFLAGS) $< -o $@ -c

run: $(EXEC)
	@test -f $(EMU) || (echo "Error: $(EMU) not found" && exit 1)
	@grep -q "ENABLE_ELF_LOADER=1" ../rv32emu/bin/.config || (echo "Error: ENABLE_ELF_LOADER=1 not set" && exit 1)
	@grep -q "ENABLE_SYSTEM=1" ../rv32emu/bin/.config || (echo "Error: ENABLE_SYSTEM=1 not set" && exit 1)
	$(EMU) $<

dump: $(EXEC)
	$(OBJDUMP) -Ds $< | less

clean:
	rm -f $(EXEC) $(OBJS)