# pport

Run commands with the ability to bind to privileged ports (< 1024) without root.

## Overview

`pport` is a simple wrapper that grants `CAP_NET_BIND_SERVICE` capability to child processes using Linux ambient capabilities. This allows non-root users to run services on privileged ports.

## Usage

```bash
pport [options] [--] <command> [args...]
```

### Examples

```bash
# Run a web server on port 80
pport python -m http.server 80

# Run nginx
pport -- nginx -g 'daemon off;'

# Run Node.js app
pport node server.js
```

### Options

- `-h, --help` - Show help message
- `-V, --version` - Show version
- `--` - End of options (optional)

## Installation

### Build from source

Requires Zig 0.15+.

```bash
make build    # Build and set capabilities
make install  # Install to /usr/local/bin
```

### Manual setup

```bash
zig build
sudo setcap cap_net_bind_service,cap_setpcap=eip ./zig-out/bin/pport
```

## How it works

1. Gets current process capabilities via `capget`
2. Adds `CAP_NET_BIND_SERVICE` and `CAP_SETPCAP` to the inheritable set via `capset`
3. Raises `CAP_NET_BIND_SERVICE` to the ambient set via `prctl`
4. Executes the target command with `execvpe`

The ambient capability is inherited by the child process, allowing it to bind to privileged ports.

## Requirements

- Linux kernel 4.3+ (for ambient capabilities)
- The binary must have file capabilities set:
  ```bash
  sudo setcap cap_net_bind_service,cap_setpcap=eip /path/to/pport
  ```

## License

MIT
