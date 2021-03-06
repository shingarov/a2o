// © IBM Corp. 2020
// This softcore is licensed under and subject to the terms of the CC-BY 4.0
// license (https://creativecommons.org/licenses/by/4.0/legalcode). 
// Additional rights, including the right to physically implement a softcore 
// that is compliant with the required sections of the Power ISA 
// Specification, will be available at no cost via the OpenPOWER Foundation. 
// This README will be updated with additional information when OpenPOWER's 
// license is available.

`timescale 1 ns / 1 ns

module rv_barf(
	       w0_dat,
	       w0_addr,
	       w0_en,
	       w1_dat,
	       w1_addr,
	       w1_en,
	       w_act,
	       r0_addr,
	       r0_dat,
	       vdd,
	       gnd,
	       nclk,
	       sg_1,
	       func_sl_thold_1,
	       ccflush_dc,
	       act_dis,
	       clkoff_b,
	       d_mode,
	       delay_lclkr,
	       mpw1_b,
	       mpw2_b,
	       scan_in,
	       scan_out
	       );
`include "tri_a2o.vh"
   
   parameter                   q_dat_width_g = 137;
   parameter                   q_num_entries_g = 16;
   parameter                   q_barf_enc_g=4;
   
   
   input [0:q_dat_width_g-1]   w0_dat;
   input [0:q_barf_enc_g-1]    w0_addr;
   input                       w0_en;
   
   input [0:q_dat_width_g-1]   w1_dat;
   input [0:q_barf_enc_g-1]    w1_addr;
   input                       w1_en;

   input [0:q_num_entries_g-1] w_act;
   
   input [0:q_barf_enc_g-1]    r0_addr;
   output [0:q_dat_width_g-1]  r0_dat;
   
   inout                       vdd;
   inout                       gnd;
   input [0:`NCLK_WIDTH-1]     nclk;
   input                       sg_1;
   input                       func_sl_thold_1;
   input                       ccflush_dc;
   input                       act_dis;
   input                       clkoff_b; 		       
   input                       d_mode;
   input                       delay_lclkr;
   input                       mpw1_b;
   input                       mpw2_b;
   input                       scan_in;
   
   output                      scan_out;
   
   
   
   
   
  
   wire [0:q_num_entries_g-1]  sg_0;
   wire [0:q_num_entries_g-1]  func_sl_thold_0;
   wire [0:q_num_entries_g-1]  func_sl_thold_0_b;
   wire [0:q_num_entries_g-1]  force_t;
   
   wire [0:q_num_entries_g-1]  q_entry_load0;
   wire [0:q_num_entries_g-1]  q_entry_load1;
   wire [0:q_num_entries_g-1]  q_entry_hold;
   wire [0:q_num_entries_g-1]  q_entry_read;
   wire [0:q_num_entries_g-1]  q_read_dat[0:q_dat_width_g-1];

   wire [0:q_num_entries_g-1]  q_dat_act;
   wire [0:q_dat_width_g-1]    q_dat_d[0:q_num_entries_g-1];
   wire [0:q_dat_width_g-1]    q_dat_q[0:q_num_entries_g-1];
   
   
   parameter                   q_dat_offset = 0;
   parameter                   scan_right = q_dat_offset + q_num_entries_g * q_dat_width_g;
   wire [0:scan_right-1]       siv;
   wire [0:scan_right-1]       sov;
   
   
   
		      
   
   generate
      begin : xhdl1
         genvar                      n;
         for (n = 0; n <= (q_num_entries_g - 1); n = n + 1)
           begin : q_dat_gen
	      wire [0:q_barf_enc_g-1] id= n;
	      
              assign q_entry_load0[n] = (w0_addr == id) & w0_en;
              assign q_entry_load1[n] = (w1_addr == id) & w1_en;
              assign q_entry_hold[n] = (~q_entry_load0[n]) & (~q_entry_load1[n]);
              assign q_dat_d[n] = (w0_dat & {q_dat_width_g{q_entry_load0[n]}}) | 
				  (w1_dat & {q_dat_width_g{q_entry_load1[n]}}) | 
				  (q_dat_q[n] & {q_dat_width_g{q_entry_hold[n]}});		
	      assign q_dat_act[n] = w_act[n];
	      
           end
      end
   endgenerate
      
      
   generate
      begin : xhdl1r
         genvar                      n, b;
         for (n = 0; n <= (q_num_entries_g - 1); n = n + 1)
           begin : rgene
	      wire [0:q_barf_enc_g-1] idd= n;
              assign q_entry_read[n] = (r0_addr == idd);
	      
	      for (b = 0; b <= (q_dat_width_g - 1); b = b + 1)
		begin : rgenb
		   assign q_read_dat[b][n] = q_dat_q[n][b] & q_entry_read[n];
		end

           end
      end
   endgenerate
      
   generate
      begin : xhdl1o
         genvar                      b;
         for (b = 0; b <= (q_dat_width_g - 1); b = b + 1)
           begin : rgeneo
	      assign r0_dat[b] = |(q_read_dat[b]);

           end
      end
   endgenerate
   
      
   generate
      begin : xhdl2
         genvar                      n;
         for (n = 0; n <= q_num_entries_g - 1; n = n + 1)
           begin : q_x_q_gen

	      tri_plat #(.WIDTH(2)) 
	      perv_1to0_reg(
			    .vd(vdd),
			    .gd(gnd),
			    .nclk(nclk),
			    .flush(ccflush_dc),
			    .din({func_sl_thold_1, sg_1}),
			    .q({func_sl_thold_0[n], sg_0[n]})
			    );
   
   
	      tri_lcbor
		perv_lcbor(
			   .clkoff_b(clkoff_b),
			   .thold(func_sl_thold_0[n]),
			   .sg(sg_0[n]),
			   .act_dis(act_dis),
			   .force_t(force_t[n]),
			   .thold_b(func_sl_thold_0_b[n])
			   );

	      
              tri_rlmreg_p #(.WIDTH(q_dat_width_g), .INIT(0))
	      q_dat_q_reg(
			  .vd(vdd),
			  .gd(gnd),
			  .nclk(nclk),
			  .act(q_dat_act[n]),
			  .thold_b(func_sl_thold_0_b[n]),
			  .sg(sg_0[n]),
			  .force_t(force_t[n]),
			  .delay_lclkr(delay_lclkr),
			  .mpw1_b(mpw1_b),
			  .mpw2_b(mpw2_b),
			  .d_mode(d_mode),
			  .scin(siv[q_dat_offset + q_dat_width_g * n:q_dat_offset + q_dat_width_g * (n + 1) - 1]),
			  .scout(sov[q_dat_offset + q_dat_width_g * n:q_dat_offset + q_dat_width_g * (n + 1) - 1]),
			  .din(q_dat_d[n]),
			  .dout(q_dat_q[n])
			  );
           end
      end
   endgenerate
   
   assign siv[0:scan_right-1] = {sov[1:scan_right-1], scan_in};
   assign scan_out = sov[0];
         
endmodule




