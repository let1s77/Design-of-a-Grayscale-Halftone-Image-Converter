# Design-of-a-Grayscale-Halftone-Image-Converter
📌 Introduction

This project implements a digital image processing system on hardware (Verilog HDL) that can:

Convert a color RGB image into a grayscale image.

Apply Error Diffusion (Floyd–Steinberg algorithm) to generate a halftone (binary) image from the grayscale version.

Such systems are useful in printing, image compression, and low-resource multimedia displays, where storage and display devices are limited to black-and-white but still need to preserve visual quality.

🖼️ Workflow
The system processes images step by step:

Input: Original RGB image (24-bit, Red–Green–Blue channels).

Grayscale Conversion: The image is converted into a single-channel 8-bit grayscale image, where each pixel intensity represents brightness.

Halftone Conversion: The grayscale image is transformed into a binary halftone image (only black and white pixels), simulating shades of gray through pixel distribution.
| Original (RGB) | Grayscale | Halftone |
|----------------|-----------|----------|
| ![Original](images/xiu_mai.bmp) | ![Grayscale](images/gray_test.bmp) | ![Halftone](images/dot_test.bmp) |

⚙️ System Architecture

The converter consists of the following hardware blocks:

ROM – Stores the input RGB image.

Grayscale Converter – Uses weighted coefficients to calculate pixel brightness:

Y = 0.3125R + 0.5625G + 0.125B


(optimized using fixed-point arithmetic and bit-shifting).

Error Diffusion Unit – Implements Floyd–Steinberg error diffusion to produce halftone output (0 or 255).

RAM – Temporarily stores grayscale results and final halftone output.

Controller – FSM-based controller that manages all read/write and processing steps.
