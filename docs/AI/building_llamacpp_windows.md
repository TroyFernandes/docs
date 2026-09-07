# Building llamacpp on Windows w/ ROCm

**Nightmare scenario**: trying to build llamacpp from source with rocm on WINDOWS 😱

## Why do this?

If you want llamacpp support with ROCm, you can just download the [lemonade-sdk/llamacpp-rocm](https://github.com/lemonade-sdk/llamacpp-rocm) release which already includes support, however I want to apply a set of patches to llamacpp, so we need to build from scratch.

## My Config for Reference

- Windows 11 (25H2) (Build 26200.9168)
- RX 7900XT (gfx1100 / RDNA3)
- AMD Adrenalin 26.8.1

## Pre-requisites

Im specifically NOT following AMD's ROCm install [guide](https://rocm.docs.amd.com/en/latest/install/rocm.html) because I want to use uv

- x64 Native Tools Command Prompt for VS 2022 (shell)
    - Download Visual Studio and install the "Desktop development with C++" Workload
    - Optional Packages Required:
        - MVSC v143 - VS 2022 C++ x64/x86 build tools (Latest) is checked
        - Windows 11 SDK (10.0.26100.7705)
        - C++ CMake tools for Windows
        - Testing tools core features - Build Tools
        - C++ AddressSanitizer
        - vcpkg package manager
- uv

## References

- [AMD ROCm Docs](https://rocm.docs.amd.com/en/latest/install/rocm.html)
- [rocm wheels](https://nightly.repo.amd.com/rocm/whl-next/)
- [lemonade-sdk/llamacpp-rocm build docs](https://github.com/lemonade-sdk/llamacpp-rocm/blob/main/docs/manual_instructions.md)
- [hatedabamboo notes blogpost](https://notes.hatedabamboo.me/llama-cpp-on-amd-windows/)
- [stew675/llama-cpp-rdna-boosts patches](https://github.com/stew675/llama-cpp-rdna-boosts)

## Steps

### 1) Install ROCm via uv

Create a dedicated virtual environment and install the ROCm wheel from AMD's nightly index:

```powershell
# From your project root (e.g. C:\Code\llamacpp-rocm)
uv venv .venv
.\.venv\Scripts\activate

uv pip install --index-url https://nightly.repo.amd.com/rocm/whl-next/ "rocm[libraries,devel,device-gfx1100]"
```

flags:

- `libraries` — runtime DLLs
- `devel` — headers, .lib import libs, cmake config files (this gives you `_rocm_sdk_devel`)
- `device-gfx1100` — device-specific code for your GPU

example output as of Sept 2026:

```
Resolved 5 packages in 1.40s
Installed 5 packages in 525ms
 + rocm==10.1.0a20260907
 + rocm-sdk-core==10.1.0a20260907
 + rocm-sdk-devel==10.1.0a20260907
 + rocm-sdk-device-gfx1100==10.1.0a20260907
 + rocm-sdk-libraries==10.1.0a20260907
```

Then initialize the devel tree:

```powershell
rocm-sdk init      # expands/links the devel tree into _rocm_sdk_devel
rocm-sdk targets   # confirm gfx1100 is in the supported list
```

### 2) Open the Correct Terminal

You must use the right shell:

- Open the x64 Native Tools Command Prompt for VS 2022 shell

Then switch from cmd to powershell, and activate your venv:

```powershell
powershell
cd C:\Code\llamacpp-rocm
.\.venv\Scripts\Activate.ps1
```

### 3) Clone Both (options) Repo(s)

You can download llamacpp only here if you'd like

```powershell
cd C:\Code\llamacpp-rocm

git clone https://github.com/ggml-org/llama.cpp
git clone https://github.com/stew675/llama-cpp-rdna-boosts
```

### 4) Apply the rdna-boosts Patches (optional)

```powershell
cd llama.cpp

git apply ..\llama-cpp-rdna-boosts\rdna-boosts-all.patch
```
Verify:

```powershell
git status
# Should show modified files
```

### 5) Build with ROCm

#### 5a) Set up paths and environment

```powershell
# Resolve ROCm paths via the rocm-sdk CLI
$rocmRoot  = (rocm-sdk path --root)  -replace '\\','/'
$rocmCmake = (rocm-sdk path --cmake) -replace '\\','/'

$llvmBin = "$rocmRoot/lib/llvm/bin"

$env:PATH = "$llvmBin;$env:PATH"

# ROCm runtime tuning
# With the current version of ROCm I was getting issues with amdhip64_7.dll before adding these
# https://github.com/ROCm/TheRock/issues/7727
# https://github.com/JM00NJ/amdhip64-hipLaunchKernel-crash-fix
# https://github.com/ggml-org/llama.cpp/issues/17429
# Do some research on your card and adjust accordingly
$env:KMP_DUPLICATE_LIB_OK = "TRUE"
$env:HSA_OVERRIDE_GFX_VERSION = "11.0.0"
$env:HSA_ENABLE_SDMA = "0"

# Sanity check — should print clang.exe and clang++.exe
Get-ChildItem $llvmBin -Filter "clang*.exe" | Where-Object { $_.Name -in @("clang.exe","clang++.exe") }
```

#### 5b) Configure

Verify `DGPU_TARGETS` and `DCMAKE_RC_COMPILER`!!

```powershell
# use this default cmake build command if using vanilla llamacpp
cmake -S . -B build -G Ninja `
  -DGGML_HIP=ON `
  -DGPU_TARGETS=gfx1100 `
  -DGGML_HIP_ROCWMMA_FATTN=ON `
  -DCMAKE_C_COMPILER="$llvmBin/clang.exe" `
  -DCMAKE_CXX_COMPILER="$llvmBin/clang++.exe" `
  -DCMAKE_RC_COMPILER="C:/Program Files (x86)/Windows Kits/10/bin/10.0.26100.0/x64/rc.exe" `
  -DCMAKE_BUILD_TYPE=Release `
  -DLLAMA_CURL=OFF `
  -DCMAKE_PREFIX_PATH="$rocmCmake" `
  -DCMAKE_CXX_FLAGS="--rocm-device-lib-path=$rocmRoot/lib/llvm/amdgcn/bitcode"
```
OR
```powershell
# cmake command used when applying patches
cmake -S . -B build -G Ninja `
  -DGGML_HIP=ON `
  -DGPU_TARGETS=gfx1100 `
  -DGGML_HIP_ROCWMMA_FATTN=ON `
  -DGGML_HIP_GRAPHS=ON `
  -DGGML_NATIVE=ON `
  -DHIP_PLATFORM=amd `
  -DCMAKE_C_COMPILER="$llvmBin/clang.exe" `
  -DCMAKE_CXX_COMPILER="$llvmBin/clang++.exe" `
  -DCMAKE_RC_COMPILER="C:/Program Files (x86)/Windows Kits/10/bin/10.0.26100.0/x64/rc.exe" `
  -DCMAKE_BUILD_TYPE=Release `
  -DLLAMA_CURL=OFF `
  -DCMAKE_PREFIX_PATH="$rocmCmake" `
  -DCMAKE_CXX_FLAGS="--rocm-device-lib-path=$rocmRoot/lib/llvm/amdgcn/bitcode -mllvm --amdgpu-unroll-threshold-local=600"
```

#### 5c) Build

```powershell
cmake --build build --config Release -j
```

### 6) Copy ROCm Runtime Libraries to `build\bin`

Your build produces the llama.cpp executables, but the ROCm runtime DLLs and pre-compiled GPU kernel data are not copied automatically. You need to place them alongside your binaries.

Side note: you can probably just download one of the lemonadesdk llamacpp releases and copy the two `rocblas` and `hipblaslt` folders into your bin and be fine, though Ill show you what you need to copy if you don't want to do that.

Destination (all files go here):

```text
C:\Code\llamacpp-rocm\llama.cpp\build\bin\
```

### Option A: Copy specific files (minimum required)

From `C:\Code\llamacpp-rocm\.venv\Lib\site-packages\_rocm_sdk_core\bin\`:

| File | Purpose |
| ------ | --------- |
| `amd_comgr.dll` | AMD compiler runtime |
| `amdhip64_7.dll` | HIP runtime |
| `amdocl64.dll` | AMD OpenCL (dependency of HIP) |
| `rocm_kpack.dll` | Kernel packing utility |
| `hiprtc0716.dll` | HIP JIT compilation |
| `hiprtc-builtins0716.dll` | HIP JIT builtins |

From `C:\Code\llamacpp-rocm\.venv\Lib\site-packages\_rocm_sdk_libraries\bin\`:

| File | Purpose |
| ------ | --------- |
| `hipblas.dll` | HIP BLAS |
| `libhipblaslt.dll` | HIP BLASLt |
| `rocblas.dll` | ROCm BLAS |
| `rocsolver.dll` | ROCm solver |
| `origami.dll` | TensileLite runtime |

Folders (copy the entire folder, not just the file):

| Source | Purpose |
|--------|---------|
| `C:\Code\llamacpp-rocm\.venv\Lib\site-packages\_rocm_sdk_libraries\bin\rocblas\` | Pre-compiled GPU kernels (gfx1100) |
| `C:\Code\llamacpp-rocm\.venv\Lib\site-packages\_rocm_sdk_libraries\bin\hipblaslt\` | Pre-compiled BLASLt kernels (gfx1100) |

After copying, your `build\bin\` should contain:

```text
build\bin\
├── amd_comgr.dll
├── amdhip64_7.dll
├── amdocl64.dll
├── hipblas.dll
├── hiprtc0716.dll
├── hiprtc-builtins0716.dll
├── libhipblaslt.dll
├── origami.dll
├── rocblas\
│   └── library\
│       └── *.hsaco, *.dat, *.co
├── rocblas.dll
├── rocm_kpack.dll
├── rocsolver.dll
├── hipblaslt\
│   └── library\
│       └── gfx1100\
│           └── *.co, *.dat.zlib, *.hsaco
├── llama-server.exe
├── llama-cli.exe
├── ... (other llama.cpp files)
```

### Option B: Just copy everything (simpler, slightly larger)

Open two File Explorer windows:

- **Source window 1:** `C:\Code\llamacpp-rocm\.venv\Lib\site-packages\_rocm_sdk_core\bin\` → Select all `.dll` files → Copy
- **Source window 2:** `C:\Code\llamacpp-rocm\.venv\Lib\site-packages\_rocm_sdk_libraries\bin\` → Select all `.dll` files plus the `rocblas\` folder and the `hipblaslt\` folder → Copy
- **Destination window:** `C:\Code\llamacpp-rocm\llama.cpp\build\bin\` → Paste everything

This grabs a few extra DLLs (MIOpen, hipfft, rocsparse, etc.) that llama.cpp doesn't strictly need, but they're harmless.

### Verify

In your shell, from `C:\Code\llamacpp-rocm\llama.cpp\build\bin\`:

```powershell
.\llama-server.exe --list-devices
```

If it prints your GPU info (e.g. `HGGRT device 0: AMD Radeon RX 7900 XT, gfx1100`) instead of crashing or throwing a DLL error, you're done.

### Step 7: Run

Your binaries will be at `build\bin\`:

```powershell
.\llama-server.exe -m C:\path\to\your\model.gguf --host 0.0.0.0 --port 8080 -ngl 99
```

Done!
---------------------------------------
## Troubleshooting

### "clang not found" or "CMake could not a working compiler"

Make sure you're in the Developer PowerShell and that `$llvmBin` is correct:

```powershell
# Should print a full path to clang.exe
& "$llvmBin/clang.exe" --version
```

If `rocm-sdk path --root` returns empty, re-run `rocm-sdk init`.

### "cannot find ROCm device library" / missing .bc files

Verify the bitcode path exists:

```powershell
Test-Path "$rocmRoot/lib/llvm/amdgcn/bitcode"
# If False, find where the .bc files actually are:
Get-ChildItem -Recurse -Filter "oclc_abi_version_400.bc" $rocmRoot | Select-Object -First 3 -ExpandProperty DirectoryName
```

Then update `-DCMAKE_CXX_FLAGS` to point at the correct directory.

### `rocm-sdk path --bin` doesn't contain clang

This is expected. The top-level `bin/` has `hipcc.exe` and shims. The real compilers are in `$rocmRoot/lib/llvm/bin/`. Always use `$llvmBin` for the compiler flags.


### CMake warning: "ROCM_HOME unused"

Harmless. The current llama.cpp CMake resolves hip/hipBLAS via `CMAKE_PREFIX_PATH` and doesn't read `ROCM_HOME` directly. You can drop it from the command.

### CMake warning: "OpenSSL not found"

Disables HTTPS in the llama-server tool. Irrelevant for local use. If you need it, install OpenSSL for Windows and pass `-DOPENSSL_ROOT_DIR=...`.

----

# Comparing Results (Vulkan vs ROCm)

### TLDR

ROCm with these set of patches is better, even if you take a hit a little bit on token gen. The model will feel more responsive, and prompt processing is way higher. Shout out to [stew675](https://github.com/stew675) for the patches!

## First Test (token generation)

Using llamacpp's llama-bench and the `speed_bench.py` python files, here are some initial results with ROCm + patches.

Heres how im starting llama-server for this test:

```powershell
(llama-benchmarks) PS C:\Users\Troy\Desktop\llama-benchmarks> .\llama-server.exe -m "C:/Code/llamacpp/models/Qwen3.8-27B-IQ4_XS.gguf" -ngl 99 -c 80000 -fa on -np 1 -ctk q4_0 -ctv q4_0 -b 512 -ub 256 --spec-type draft-mtp,ngram-mod --spec-draft-n-max 3 --spec-ngram-mod-n-match 24 --spec-ngram-mod-n-min 8 --spec-ngram-mod-n-max 32 --n-predict 30000 --port 8080 --jinja
```

And here's the test command that was used.:

```powershell
(llama-benchmarks) PS C:\Users\Troy\Desktop\llama-benchmarks> uv run python .\speed_bench.py `
>>   --url localhost:8080 `
>>   --bench qualitative `
>>   --category coding,reasoning `
>>   --osl 256 `
>>   --limit 5 `
>>   --concurrency 1 `
>>   --output vulkan.json
```

The only thing changing here is the `llama-server.exe` between runs (vulkan vs rocm) and of course the output file name. 


| Category | Base Avg Pred t/s | Spec Avg Pred t/s | Decode Speedup | Base Avg Latency | Spec Avg Latency | Latency Speedup | Accept Rate |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **coding** | 58.03 | 59.44 | 1.02x | 9.737s | 8.364s | 1.16x | 0.5766 |
| **reasoning** | 59.71 | 80.71 | 1.35x | 6.815s | 5.728s | 1.19x | 0.6473 |
| **overall** | 58.87 | 70.07 | 1.19x | 8.276s | 7.046s | 1.17x | 0.6100 |

## Second Test

Arguably the more important test is prompt processing. Im using [llama-benchy](https://github.com/eugr/llama-benchy) here to run my actual llama-server config loaded with my `models.ini` file and test against that.

```ini
; models.ini
[*]
host = 0.0.0.0
port = 11434
jinja = true
; log-verbose = 4
parallel = 1
flash-attn = true

[Qwen3.8-27B]
model = C:/Code/llamacpp/models/Qwen3.8-27B-IQ4_XS.gguf
n-gpu-layers = 99
ctx-size = 80000
flash-attn = on
parallel = 1
cache-type-k = q4_0
cache-type-v = q4_0
temp = 1.0
top-p = 0.95
top-k = 20
min-p = 0.0
presence-penalty = 0.0
repeat-penalty = 1.0
no-mmproj-offload = true
no-mmap = true
chat-template-kwargs = {"reasoning_effort": "xhigh"}
n-predict = 30000
batch-size = 512
ubatch-size = 256
load-mode = mlock
spec-type = draft-mtp,ngram-mod
spec-draft-n-max = 3
spec-ngram-mod-n-match = 24
spec-ngram-mod-n-min = 8
spec-ngram-mod-n-max = 32

```

```sh
# llama-benchy command
llama-benchy --base-url http://127.0.0.1:11434 --model "Qwen3.8-27B" --depth 0 4096 8192 16384 32768 65536 79000 --latency-mode generation --format json --save-result rocm.json
```

**Prompt processing (tok/s) — higher is better**

| Context | Vulkan | ROCm | ROCm Speedup | Winner |
| :--- | :---: | :---: | :---: | :---: |
| 0 | 534.5 | **759.8** | 1.42x | ROCm +42.2% |
| 4,096 | 539.7 | **804.6** | 1.49x | ROCm +49.1% |
| 8,192 | 530.6 | **800.3** | 1.51x | ROCm +50.8% |
| 16,384 | 507.0 | **774.6** | 1.53x | ROCm +52.8% |
| 32,768 | 461.2 | **710.6** | 1.54x | ROCm +54.1% |
| 65,536 | 386.9 | **601.6** | 1.56x | ROCm +55.5% |
| 79,000 | 362.8 | **560.8** | 1.55x | ROCm +54.6% |

**Token generation (tok/s) — higher is better**

| Context | Vulkan | ROCm | Winner |
| :--- | :---: | :---: | :---: |
| 0 | **57.36** | 54.10 | Vulkan +6.0% |
| 4,096 | 49.66 | **51.39** | ROCm +3.5% |
| 8,192 | 49.85 | 50.28 | Tie (+0.9%) |
| 16,384 | **53.63** | 50.72 | Vulkan +5.8% |
| 32,768 | **47.48** | 46.07 | Vulkan +3.1% |
| 65,536 | 36.85 | **37.19** | Tie (+0.9%) |
| 79,000 | **36.13** | 29.53 | Vulkan +22.3% |

**Time to first token (s) — lower is better**

| Context | Vulkan | ROCm | ROCm Speedup | Winner |
| :--- | :---: | :---: | :---: | :---: |
| 0 | 3.38 | **2.35** | 1.44x | ROCm −30.5% |
| 4,096 | 9.80 | **6.64** | 1.48x | ROCm −32.2% |
| 8,192 | 16.39 | **10.91** | 1.50x | ROCm −33.4% |
| 16,384 | 31.12 | **20.60** | 1.51x | ROCm −33.8% |
| 32,768 | 64.77 | **42.16** | 1.54x | ROCm −34.9% |
| 65,536 | 150.1 | **96.1** | 1.56x | ROCm −35.9% |
| 79,000 | 191.1 | **123.9** | 1.54x | ROCm −35.2% |