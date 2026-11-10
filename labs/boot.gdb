set pagination off
set architecture aarch64
target remote :1234
# Start GDB with work/out/vmlinux; Image must match, with KASLR disabled.
hbreak start_kernel
continue
# Selectively add setup_arch, rest_init, kernel_init, run_init_process,
# load_elf_binary after the first stop. Avoid every-timer-IRQ breakpoints.
