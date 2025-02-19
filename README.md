# rust-vtpm-td

A Trust Platform Module (TPM) provides the Root-of-Trust for Reporting (RTR) and Root-of-Trust for Storage (RTS) for the platform. With a platform specific Root-of-Trust for Measurement (RTM), usually the first boot code, the platform can support TPM-based attestation or TPM-based sealing.

In virtual platform, a virtual TPM (vTPM) may be used to support similar TPM-based attestation. It is widely adopted in the hypervisor environment and supported by the virtual machine monitor (VMM) vendor. A VMM may provide virtual TPM services to the guest environment.

However, with the Intel Trust Domain Extension, the VMM is out of Trust Computing Base (TCB) and no longer trusted. As such, a pure VMM-based virtual TPM is not feasible. We need have other way to support vTPM based solution.

rust-vtpm-td is a Trust Domain (TD) based vTPM solution, which can support vTPM functionality with VMM out of TCB.

![Overview](doc/vtpm-overview.png)

## Known limitation

## Build

### Prerequisties

1. Rust toolchain

* Install [Rust](https://www.rust-lang.org/tools/install):
```
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```
* Install toolchain and components required by vtpmtd:
```
rustup toolchain install nightly-2022-11-15
rustup component add --toolchain nightly-2022-11-15 rust-src
cargo install cargo-xbuild
```

2. [clang](https://releases.llvm.org/download.html#13.0.1)

3. [NASM](https://www.nasm.us/)

### Prepare source code

```
mkdir vtpm
pushd vtpm
mkdir vtpm-td

git clone --recursive https://github.com/intel/vtpm-td.git vtpm-td

export CC=clang
export AR=llvm-ar
```

### Build vtpm-td

```
# build vtpm-td service
pushd vtpm-td
git submodule update --init --recursive
# make dir for run-vtpm-td
mkdir ../run-vtpm-td
# build
bash sh_script/pre-build.sh
bash sh_script/build.sh
cp target/x86_64-unknown-none/release/vtpmtd.bin ../run-vtpm-td
popd
```

## Run

### Prerequisites

1. Linux Kernel (KVM) and QEMU with with TDX 1.5 support

### Run vtpm-td in shell-A
```
pushd vtpm/run-vtpm-td
QEMU=/usr/bin/qemu-system-x86_64
BIOS=./vtpmtd.bin
USERTD_ID=aabbccdd-2012-ffff-1234-123456789abc
LOGFILE=./vtpm-td.log
MEM=256M

$QEMU \
  -accel kvm \
  -name debug-threads=on,process=vtpm-td \
  -cpu host,host-phys-bits,-kvm-steal-time,-arch-lbr \
  -smp 1 -m $MEM \
  -object tdx-guest,id=tdx,debug=on,vtpm-type=server,vtpm-userid=${USERTD_ID},vtpm-path=unix:/tmp/vtpm-123.sock -qmp unix:/tmp/qmp-sock-vtpm,server,nowait \
  -object memory-backend-memfd-private,id=ram1,size=${MEM} \
  -machine q35,kernel_irqchip=split,confidential-guest-support=tdx,memory-backend=ram1 \
  -bios ${BIOS} \
  -nographic \
  -vga none \
  -no-hpet \
  -nodefaults \
  -chardev stdio,id=mux,mux=on,signal=off,logfile=$LOGFILE \
  -device virtio-serial,romfile= \
  -device virtconsole,chardev=mux -serial chardev:mux -monitor chardev:mux \
  -d int -no-reboot
```
