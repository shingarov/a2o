// © IBM Corp. 2020
// This softcore is licensed under and subject to the terms of the CC-BY 4.0
// license (https://creativecommons.org/licenses/by/4.0/legalcode). 
// Additional rights, including the right to physically implement a softcore 
// that is compliant with the required sections of the Power ISA 
// Specification, will be available at no cost via the OpenPOWER Foundation. 
// This README will be updated with additional information when OpenPOWER's 
// license is available.

`timescale 1 ns / 1 ns


`include "tri_a2o.vh"

module tri_nand4(
   y,
   a,
   b,
   c,
   d
);
   parameter                      WIDTH = 1;
   parameter                      BTR = "NAND4_X2M_NONE";  
   output [0:WIDTH-1]  y;
   input [0:WIDTH-1]   a;
   input [0:WIDTH-1]   b;
   input [0:WIDTH-1]   c;
   input [0:WIDTH-1]   d;
   genvar 	       i;
   
   generate
      begin : t
	 for (i = 0; i < WIDTH; i = i + 1)
	   begin : w

      	      nand I0(y[i], a[i], b[i], c[i], d[i]);

	      
	   end 
      end
      
   endgenerate
endmodule


