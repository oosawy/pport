.PHONY: build install clean

BUILD_DIR := zig-out/bin
BINARY := $(BUILD_DIR)/pport

build:
	zig build
	sudo setcap cap_net_bind_service,cap_setpcap=eip $(BINARY)

install: build
	sudo cp $(BINARY) /usr/local/bin/pport

clean:
	rm -rf zig-out .zig-cache
