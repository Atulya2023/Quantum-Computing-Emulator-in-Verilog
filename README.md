# **Quantum Computing Emulator in Verilog**
## Overview
This repository contains the verilog implementation of a Quantum Computing Emulator. The system takes as input an initial state of qubits and a set of gates. The computed output is written to an external SRAM. 


| Address      | 127:64                              | 63:0                                 |
|--------------|-------------------------------------|--------------------------------------|
| x0           | N (Number of qubits)                | M (Number of operator Matrices)      |
| x1           | Real Coefficient of \|0&#9002; | Imaginary Coefficient of \|0&#9002; |
| x2           | Real Coefficient of \|1&#9002; | Imaginary Coefficient of \|1&#9002;|
| x3           | Real Coefficient of \|2&#9002; | Imaginary Coefficient of \|2&#9002; |
| ...          | ...                                 | ...                                  |
| x2\(^N\)     | Real Coefficient of \|2<sup>N</sup>-1&#9002; | Imaginary Coefficient of \|2<sup>N</sup>-1&#9002; |

**Gates SRAM**, that contains the values of the elements in the N-qubit gate matrices stored
in row-order.
The circuit also assumes the availability of two empty SRAMs. One where the output is
to be stored and the other an empty SRAM to be used to offload memory during the
simulation.

The order of operations for multiplying two matrices are as follows:
```math
O[k] = \sum \left( G[k+n]_{\text{Real}} \times I[n]_{\text{Real}} - G[k+n]_{\text{Imag}} \times I[n]_{\text{Imag}} \right)
```


Where ```G``` is the operator matrix, ```I``` the input matrix and ```O``` the output matrix.
