# Blur
There are three files:
 - *StackBlur.pas*
 - *BoxBlur.pas*
 - *GaussBlur.pas*
 
 
Each file contains adaptation of the original source code I have found in Internet.

Original author and developer of source code is **Mario Klingemann**.  
Author's web-site: http://incubator.quasimondo.com

**How to use**
 - It is enough simply to add appropriate unit to 'uses' clause of your program and call only one procedure.

**Some notes about ported code**
 - Despite of the code in *'StackBlur.pas'* is really big its speed is very high. At this day, this is the fastest blur I have ever seen (without taking into account proprietary solutions).
 - Works ONLY with 32-bit bitmaps.
