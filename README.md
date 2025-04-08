# TheTensorCoreProject
Microarchitecture implementation of my interpretation of Nvidia's CUDA and Hybrid-Precision Tensor Cores

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
