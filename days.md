# Progress Updates

## Day 1
### Read up on CUDA vs Tensor Cores (blog + white paper)
- understanding systolic architectures vs SIMD-like fully parallel approach memory/bandwidth and performance tradeoffs
- 4x4 matrix fused multiplication add (FMA) instr vs MAC (used in CUDA cores)
- noted differences between nvidia tensor core arch versions --> volta (v0), ampere(v1), hooper(v2)
- essentially based on different floating point rep formats and how they affect model training/inference accuracy
### Implemented rudimentary fp16 multiplication module
- figuring out limits/accuracy of significand in fp32 product
- read up on methods for dealing with overflow for partial product summation --> clamping, block summation, exponent scaling
- decided against supporting overflow/NaN in v0.0
- normalization methodology (msb or second msb must be set)

## Day 2
### Implemented fp32 adder
- figuring out overflow/underflow/NaN
- decided not to support overflow/NaN in v0.0
- added support for negative numbers and operating on opposite signs
- added support for zero rep (kinda)
- will require a leading zero detector module - for dealing with subtractions of numbers with minimal differnce in magnitude - later (v0.1), just using a for loop through mantissa bits atm
- verified and tested the fp32 adder -> works just alr (exceptions are an exception)
- will have to figure out smth for dealing with subtracting numbers of the same magnitude
- could rewrite the complete module in dataflow if required later (v0.1)
### Proved normalization methodology in mul and add of +ve nums
- calculated minimum and maximum possibilities for each case --> msb or second msb must be set

## Day 3
### Figured and fixed major issues with fp16mul
- fixed product exponent bias calculation
- noted significant loss in precision of answer (fp32 can represent the true value closer, but fp16 inputs dont allow for a more accurate product mantissa)
- leaving rounding, NaN, overflow and underflow logic for v0.1

## Day 4
### Implemented [4x4] Matrix Multiplication Module
- 
