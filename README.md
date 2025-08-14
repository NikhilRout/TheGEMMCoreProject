# TheTensorCoreProject
SystemVerilog implementation of Nvidia's SIMT CUDA, Hybrid-Precision Tensor Core, and Google's Systolic Array TPU MXU GEMM Operations. 
These modules are by no means really emulating the actual microarchitecture executing CUDA/Tensor Core instructions, instead they're simply performing the same operation for direct usage in FPGA designs. 

Go check out my work on the Vortex GPGPU's [Tensor Core Unit (TCU) extension's DRL Floating Point RTL backend](https://github.com/vortexgpgpu/vortex/tree/bug_fixes/hw/rtl/tcu) for a more optimized, realistic microarchitecture implementation.

## Tensor Core Versions
### TensorCore v0: Volta Architecture [FP16MUL FP32ADD]
<div align="center">
  <img src="./Arch%20Diags/VoltaTensorCore2.png" alt="Volta Tensor Core Architecture Diagram" width="600">
</div>
<div align="center">
  <img src="./Arch%20Diags/VoltaTensorCore.png" alt="Volta Tensor Core Architecture Diagram" width="600">
</div>

### TensorCore v1: Ampere Architecture [TF32MUL FP32ADD / BF16MUL FP32ADD] + Fine-Grained Structured Sparsity
<div align="center">
  <img src="./Arch%20Diags/AmpereTensorCoreTF32.png" alt="Ampere Tensor Core Architecture Diagram" width="600">
</div>
<div align="center">
  <img src="./Arch Diags/Fine-Grained Structured Sparsity.png" alt="Ampere Tensor Core Architecture Diagram" width="600">
</div>

### TensorCore v2: Hopper Architecture [FP8(E5M2/E4M3)MUL FP16ADD]
<div align="center">
  <img src="./Arch Diags/FP8HopperTensorCore.png" alt="Hopper Tensor Core Architecture Diagram" width="600">
</div>
