# Skill: Wikimedia Commons SVG Sourcing

Download public-domain SVG files from Wikimedia Commons without an API key,
using MD5-based URL computation and rate-limit-aware batching.

---

## Quick Reference

```bash
# Compute the direct upload URL for a Commons file
python3 -c "
import hashlib
name = 'ICS_Alfa.svg'
h = hashlib.md5(name.encode()).hexdigest()
print(f'https://upload.wikimedia.org/wikipedia/commons/{h[0]}/{h[:2]}/{name}')
"

# Download with rate-limit courtesy delay
curl -sL -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
  -o ICS_Alfa.svg -w "%{http_code}\n" \
  "https://upload.wikimedia.org/wikipedia/commons/8/85/ICS_Alfa.svg"
```

---

## Pattern: MD5 URL Computation

Wikimedia upload server uses the first character and first two characters of
the MD5 hash of the **filename** (not the full path) to build the directory
path:

```
https://upload.wikimedia.org/wikipedia/commons/<h[0]>/<h[:2]>/<filename>
```

```python
import hashlib

def wikimedia_url(filename: str) -> str:
    h = hashlib.md5(filename.encode()).hexdigest()
    return f"https://upload.wikimedia.org/wikipedia/commons/{h[0]}/{h[:2]}/{filename}"
```

Alternatively, verify the URL via the Commons API (more reliable, avoids
guessing filenames):

```bash
curl -s "https://commons.wikimedia.org/w/api.php?action=query&titles=File:ICS_Alfa.svg&prop=imageinfo&iiprop=url&format=json"
```

---

## Pattern: Batch Download with Rate-Limit Handling

The upload server (upload.wikimedia.org) imposes aggressive rate limits.
HTTP 429 responses can persist for 10–15 minutes after a burst.

**Safe parameters:**
- Delay between requests: **3 seconds minimum**
- Batch size before mandatory pause: **~20 files**
- Cooldown after a 429: **15 minutes**
- User-Agent: set a real browser string (blank UA is blocked outright)

```python
import hashlib, subprocess, time

UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"

files = ["ICS_Alfa.svg", "ICS_Bravo.svg", ...]  # filenames to download

for fname in files:
    h = hashlib.md5(fname.encode()).hexdigest()
    url = f"https://upload.wikimedia.org/wikipedia/commons/{h[0]}/{h[:2]}/{fname}"
    result = subprocess.run(
        ["curl", "-sL", "-A", UA, "-o", fname, "-w", "%{http_code}", url],
        capture_output=True, text=True,
    )
    code = result.stdout.strip()
    if code != "200":
        print(f"FAIL {fname}: HTTP {code}")
    else:
        print(f"OK   {fname}")
    time.sleep(3.0)
```

**Fallback URL** if upload server is still throttled:

```
https://commons.wikimedia.org/wiki/Special:FilePath/<filename>
```

---

## Pattern: Verify Downloaded Files

HTTP 4xx/5xx responses write an HTML error page to the `-o` target. Always
verify by checking size and first bytes, do not assume a `200` code if using
`-w` separately from `-o`:

```bash
for f in *.svg; do
  size=$(stat -f%z "$f")
  first=$(head -c 10 "$f")
  if echo "$first" | grep -q "DOCTYPE\|html"; then
    echo "BAD  $f [$size bytes]"
  else
    echo "OK   $f [$size bytes]"
  fi
done
```

Real SVGs from Wikimedia are typically 200–2000 bytes for simple flag designs.
An HTML 429 error page is ~2000–3000 bytes starting with `<!DOCTYPE html>`.

---

## ICS Signal Flag Naming (Wikimedia Commons)

| Range | Wikimedia filename | Notes |
|-------|-------------------|-------|
| Letters A-W, Y-Z | `ICS_<Phonetic>.svg` | e.g. `ICS_Alfa.svg` |
| Letter X | `ICS_X-ray.svg` | Hyphen required; `ICS_Xray.svg` redirects but may 404 |
| Digits 0-9 | `ICS_<Word>.svg` | e.g. `ICS_Zero.svg`, `ICS_Niner.svg` (not `ICS_Numeral_Zero.svg`) |
