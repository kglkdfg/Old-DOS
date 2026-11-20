NASM ?= nasm
QEMU ?= qemu-system-i386
DD ?= dd

BUILD_DIR := build
IMAGE := $(BUILD_DIR)/olddos.img
BOOT_BIN := $(BUILD_DIR)/boot.bin
KERNEL_BIN := $(BUILD_DIR)/kernel.bin
KERNEL_MAX_SIZE := 4096

.PHONY: all run clean

all: $(IMAGE)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BOOT_BIN): boot/boot.asm | $(BUILD_DIR)
	$(NASM) -f bin $< -o $@
	test $$(wc -c < $@) -eq 512

$(KERNEL_BIN): kernel/kernel.asm | $(BUILD_DIR)
	$(NASM) -f bin $< -o $@
	test $$(wc -c < $@) -le $(KERNEL_MAX_SIZE)

$(IMAGE): $(BOOT_BIN) $(KERNEL_BIN)
	$(DD) if=/dev/zero of=$@ bs=512 count=2880
	$(DD) if=$(BOOT_BIN) of=$@ conv=notrunc
	$(DD) if=$(KERNEL_BIN) of=$@ bs=512 seek=1 conv=notrunc

run: $(IMAGE)
	$(QEMU) -drive format=raw,file=$(IMAGE),if=floppy

debug: $(IMAGE)
	$(QEMU) -drive format=raw,file=$(IMAGE),if=floppy -no-reboot -no-shutdown

clean:
	rm -rf $(BUILD_DIR)
