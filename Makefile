NASM ?= nasm
QEMU ?= qemu-system-i386

BUILD_DIR := build
IMAGE := $(BUILD_DIR)/olddos.img
BOOT_BIN := $(BUILD_DIR)/boot.bin

.PHONY: all run clean

all: $(IMAGE)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BOOT_BIN): boot/boot.asm | $(BUILD_DIR)
	$(NASM) -f bin $< -o $@

$(IMAGE): $(BOOT_BIN)
	dd if=/dev/zero of=$@ bs=512 count=2880
	dd if=$(BOOT_BIN) of=$@ conv=notrunc

run: $(IMAGE)
	$(QEMU) -drive format=raw,file=$(IMAGE),if=floppy

clean:
	rm -rf $(BUILD_DIR)
