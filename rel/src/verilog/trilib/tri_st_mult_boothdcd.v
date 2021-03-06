// © IBM Corp. 2020
// This softcore is licensed under and subject to the terms of the CC-BY 4.0
// license (https://creativecommons.org/licenses/by/4.0/legalcode). 
// Additional rights, including the right to physically implement a softcore 
// that is compliant with the required sections of the Power ISA 
// Specification, will be available at no cost via the OpenPOWER Foundation. 
// This README will be updated with additional information when OpenPOWER's 
// license is available.


module tri_st_mult_boothdcd(
   i0,
   i1,
   i2,
   s_neg,
   s_x,
   s_x2
);
   input   i0;
   input   i1;
   input   i2;
   output  s_neg;
   output  s_x;
   output  s_x2;

   wire    s_add;
   wire    sx1_a0_b;
   wire    sx1_a1_b;
   wire    sx1_t;
   wire    sx1_i;
   wire    sx2_a0_b;
   wire    sx2_a1_b;
   wire    sx2_t;
   wire    sx2_i;
   wire    i0_b;
   wire    i1_b;
   wire    i2_b;




   assign i0_b = (~(i0));
   assign i1_b = (~(i1));
   assign i2_b = (~(i2));

   assign s_add = (~(i0));
   assign s_neg = (~(s_add));

   assign sx1_a0_b = (~(i1_b & i2));
   assign sx1_a1_b = (~(i1 & i2_b));
   assign sx1_t = (~(sx1_a0_b & sx1_a1_b));
   assign sx1_i = (~(sx1_t));
   assign s_x = (~(sx1_i));

   assign sx2_a0_b = (~(i0 & i1_b & i2_b));
   assign sx2_a1_b = (~(i0_b & i1 & i2));
   assign sx2_t = (~(sx2_a0_b & sx2_a1_b));
   assign sx2_i = (~(sx2_t));
   assign s_x2 = (~(sx2_i));
      
endmodule
