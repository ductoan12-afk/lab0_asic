CROSS := riscv64-unknown-elf-
CFLAGS := -march=rv32i -mabi=ilp32 -nostdlib -nostartfiles -O2
SRC ?= test_alu.S
NAME := $(basename $(SRC))

all: $(NAME).hex $(NAME).dump

$(NAME).elf: $(SRC) link.ld
	$(CROSS)gcc $(CFLAGS) -T link.ld -o $@ $(SRC)

$(NAME).bin: $(NAME).elf
	$(CROSS)objcopy -O binary $< $@

$(NAME).hex: $(NAME).bin
	od -An -tx4 -v $< | tr -s ' ' '\n' | grep '[0-9a-fA-F]' > $@

$(NAME).dump: $(NAME).elf
	$(CROSS)objdump -d -M no-aliases $< > $@

clean:
	rm -f *.elf *.bin *.hex *.dump

