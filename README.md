# Loopsafe

Redirect TCP traffic to a different place, but immediately fall back to the original destination if the new destination is not available.

# Usage
```
git clone https://github.com/B00TK1D/loopsafe.git
sh loopsafe/loopsafe.sh <original_port> <new_port> [remote_host]
```