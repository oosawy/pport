.PHONY: build install clean

BUILD_DIR := zig-out/bin
BINARY := $(BUILD_DIR)/pport
INSTALL_PATH := /usr/local/bin/pport

build:
	zig build
	sudo setcap cap_net_bind_service,cap_setpcap=eip $(BINARY)

install: build
	sudo cp $(BINARY) $(INSTALL_PATH)
	sudo chown root:root $(INSTALL_PATH)
	sudo chmod 4755 $(INSTALL_PATH)

clean:
	rm -rf zig-out .zig-cache
