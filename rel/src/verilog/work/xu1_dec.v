// © IBM Corp. 2020
// This softcore is licensed under and subject to the terms of the CC-BY 4.0
// license (https://creativecommons.org/licenses/by/4.0/legalcode). 
// Additional rights, including the right to physically implement a softcore 
// that is compliant with the required sections of the Power ISA 
// Specification, will be available at no cost via the OpenPOWER Foundation. 
// This README will be updated with additional information when OpenPOWER's 
// license is available.

`include "tri_a2o.vh"
module xu1_dec(
   input [0:`NCLK_WIDTH-1]                         nclk,
   inout                                           vdd,
   inout                                           gnd,
   
   input                                           d_mode_dc,
   input                                           delay_lclkr_dc,
   input                                           mpw1_dc_b,
   input                                           mpw2_dc_b,
   input                                           func_sl_force,
   input                                           func_sl_thold_0_b,
   input                                           sg_0,
   input                                           scan_in,
   output                                          scan_out,
   
   input [0:`THREADS-1]                            spr_msr_cm,		
   
   input [0:`THREADS-1]                            cp_flush,
   
   input [0:`THREADS-1]                            rv_xu1_vld,
   input [0:31]                                    rv_xu1_ex0_instr,
   input [0:`ITAG_SIZE_ENC-1]                      rv_xu1_ex0_itag,
   input                                           rv_xu1_ex0_isstore,
   input [1:1]                                     rv_xu1_ex0_ucode,
   input                                           rv_xu1_ex0_t1_v,
   input [0:`GPR_POOL_ENC-1]                       rv_xu1_ex0_t1_p,
   input                                           rv_xu1_ex0_t2_v,
   input [0:`GPR_POOL_ENC-1]                       rv_xu1_ex0_t2_p,
   input                                           rv_xu1_ex0_t3_v,
   input [0:`GPR_POOL_ENC-1]                       rv_xu1_ex0_t3_p,
   input                                           rv_xu1_ex0_s1_v,
   input [0:2]                                     rv_xu1_ex0_s3_t,
   input [0:`THREADS-1]                            rv_xu1_ex0_spec_flush,
   input [0:`THREADS-1]                            rv_xu1_ex1_spec_flush,
   input [0:`THREADS-1]                            rv_xu1_ex2_spec_flush,
   
   output [0:`THREADS-1]                            xu1_lq_ex2_stq_val,
   output [0:`ITAG_SIZE_ENC-1]                      xu1_lq_ex2_stq_itag,
   output [1:4]                                     xu1_lq_ex2_stq_size,
   output                                           xu1_lq_ex3_illeg_lswx,
   output                                           xu1_lq_ex3_strg_noop,
   
   output [0:`THREADS-1]                            xu1_iu_execute_vld,
   output [0:`ITAG_SIZE_ENC-1]                      xu1_iu_itag,
   
   output                                           xu1_pc_ram_done,
   
   output [0:`THREADS-1]                            xu_iu_ucode_xer_val,
   
   output                                           dec_alu_ex1_act,
   output [0:31]                                    dec_alu_ex1_instr,
   output                                           dec_alu_ex1_sel_isel,
   output [0:`GPR_WIDTH/8-1]                        dec_alu_ex1_add_rs1_inv,
   output [0:1]                                     dec_alu_ex2_add_ci_sel,
   output                                           dec_alu_ex1_sel_trap,
   output                                           dec_alu_ex1_sel_cmpl,
   output                                           dec_alu_ex1_sel_cmp,
   output                                           dec_alu_ex1_msb_64b_sel,
   output                                           dec_alu_ex1_xer_ov_en,
   output                                           dec_alu_ex1_xer_ca_en,
   output                                           xu1_xu0_ex3_act,
   
   input                                            byp_dec_ex2_abort,
   output                                           dec_byp_ex2_val,
   output                                           dec_byp_ex0_act,
   output [64-`GPR_WIDTH:63]                        dec_byp_ex1_imm,
   output [24:25]                                   dec_byp_ex1_instr,
   output                                           dec_byp_ex0_rs2_sel_imm,
   output                                           dec_byp_ex0_rs1_sel_zero,
   output [0:`THREADS-1]                            dec_byp_ex2_tid,
   output [(64-`GPR_WIDTH)/8:7]                     dec_byp_ex2_dvc_mask,
   
   input [3:9]                                      byp_dec_ex2_xer,
   
   output                                           xu1_gpr_ex3_we,
   output [0:`GPR_POOL_ENC+`THREADS_POOL_ENC-1]     xu1_gpr_ex3_wa,
   output                                           xu1_xer_ex3_we,
   output [0:`XER_POOL_ENC+`THREADS_POOL_ENC-1]     xu1_xer_ex3_wa,
   output                                           xu1_cr_ex3_we,
   output [0:`CR_POOL_ENC+`THREADS_POOL_ENC-1]      xu1_cr_ex3_wa,
   
   input [0:`THREADS-1]                             pc_xu_ram_active
);
   localparam xer_pool_l            = `GPR_POOL_ENC-`XER_POOL_ENC;
   localparam cr_pool_l             = `GPR_POOL_ENC-`CR_POOL_ENC;
   wire [1:3]                   exx_act_q,                  exx_act_d                  ; 
   wire [0:2]                   ex1_s3_type_q                                          ; 
   wire                         ex1_t1_v_q                                             ; 
   wire                         ex1_t2_v_q                                             ; 
   wire                         ex1_t3_v_q                                             ; 
   wire [0:`GPR_POOL_ENC-1]     ex1_t1_p_q                                             ; 
   wire [0:`XER_POOL_ENC-1]     ex1_t2_p_q                                             ; 
   wire [0:`CR_POOL_ENC-1]      ex1_t3_p_q                                             ; 
   wire [0:31]                  ex1_instr_q                                            ; 
   wire [1:1]                   ex1_ucode_q                                            ; 
   wire [0:`ITAG_SIZE_ENC-1]    ex1_itag_q                                             ; 
   wire [0:1]                   ex2_add_ci_sel_q,           ex1_add_ci_sel             ; 
   wire [0:`ITAG_SIZE_ENC-1]    ex2_itag_q                                             ; 
   wire [0:`GPR_POOL_ENC-1]     ex2_t1_p_q                                             ; 
   wire [xer_pool_l:`GPR_POOL_ENC-1] ex2_t2_p_q                                        ; 
   wire [cr_pool_l:`GPR_POOL_ENC-1]  ex2_t3_p_q                                        ; 
   wire [6:20]                  ex2_instr_q                                            ; 
   wire                         ex2_gpr_we_q,               ex1_gpr_we                 ; 
   wire                         ex2_xer_we_q,               ex1_xer_we                 ; 
   wire                         ex2_cr_we_q,                ex1_cr_we                  ; 
   wire [1:4]                   ex2_opsize_q,               ex1_opsize                 ; 
   wire                         ex2_is_lswx_q                                          ; 
   wire                         ex2_is_stswx_q                                         ; 
   wire [0:`GPR_POOL_ENC-1]     ex3_t1_p_q                                             ; 
   wire [xer_pool_l:`GPR_POOL_ENC-1] ex3_t2_p_q                                        ; 
   wire [cr_pool_l:`GPR_POOL_ENC-1]  ex3_t3_p_q                                        ; 
   wire [0:`ITAG_SIZE_ENC-1]    ex3_itag_q                                             ; 
   wire                         ex3_gpr_we_q,               ex2_gpr_we                 ; 
   wire                         ex3_xer_we_q,               ex2_xer_we                 ; 
   wire                         ex3_cr_we_q,                ex2_cr_we                  ; 
   wire                         ex3_illeg_lswx_q,           ex2_illeg_lswx             ; 
   wire                         ex3_strg_noop_q,            ex2_strg_noop              ; 
   wire [0:`THREADS-1]          cp_flush_q                                             ; 
   wire [0:`THREADS-1]          ex0_val_q,                  rv2_val                    ; 
   wire [0:`THREADS-1]          ex1_val_q,                  ex0_val                    ; 
   wire [0:`THREADS-1]          ex2_val_q,                  ex1_val                    ; 
   wire [0:`THREADS-1]          ex3_val_q,                  ex2_val                    ; 
   wire [0:`THREADS-1]          ex2_stq_val_q,              ex1_stq_val                ; 
   wire                         ex2_xer_val_q,              ex1_xer_val                ; 
   wire [0:`THREADS-1]          msr_cm_q                                               ; 
   wire                         ex3_ram_active_q,           ex3_ram_active_d           ; 
   wire [(64-`GPR_WIDTH)/8:7]   ex2_dvc_mask_q                                         ; 
   localparam exx_act_offset                             = 0;
   localparam ex1_s3_type_offset                         = exx_act_offset                 + 3;
   localparam ex1_t1_v_offset                            = ex1_s3_type_offset             + 3;
   localparam ex1_t2_v_offset                            = ex1_t1_v_offset                + 1;
   localparam ex1_t3_v_offset                            = ex1_t2_v_offset                + 1;
   localparam ex1_t1_p_offset                            = ex1_t3_v_offset                + 1;
   localparam ex1_t2_p_offset                            = ex1_t1_p_offset                + `GPR_POOL_ENC;
   localparam ex1_t3_p_offset                            = ex1_t2_p_offset                + `XER_POOL_ENC;
   localparam ex1_instr_offset                           = ex1_t3_p_offset                + `CR_POOL_ENC;
   localparam ex1_ucode_offset                           = ex1_instr_offset               + 32;
   localparam ex1_itag_offset                            = ex1_ucode_offset               + 1;
   localparam ex2_add_ci_sel_offset                      = ex1_itag_offset                + `ITAG_SIZE_ENC;
   localparam ex2_itag_offset                            = ex2_add_ci_sel_offset          + 2;
   localparam ex2_t1_p_offset                            = ex2_itag_offset                + `ITAG_SIZE_ENC;
   localparam ex2_t2_p_offset                            = ex2_t1_p_offset                + `GPR_POOL_ENC;
   localparam ex2_t3_p_offset                            = ex2_t2_p_offset                + `XER_POOL_ENC;
   localparam ex2_instr_offset                           = ex2_t3_p_offset                + `CR_POOL_ENC;
   localparam ex2_gpr_we_offset                          = ex2_instr_offset               + 15;
   localparam ex2_xer_we_offset                          = ex2_gpr_we_offset              + 1;
   localparam ex2_cr_we_offset                           = ex2_xer_we_offset              + 1;
   localparam ex2_opsize_offset                          = ex2_cr_we_offset               + 1;
   localparam ex2_is_lswx_offset                         = ex2_opsize_offset              + 4;
   localparam ex2_is_stswx_offset                        = ex2_is_lswx_offset             + 1;
   localparam ex3_t1_p_offset                            = ex2_is_stswx_offset            + 1;
   localparam ex3_t2_p_offset                            = ex3_t1_p_offset                + `GPR_POOL_ENC;
   localparam ex3_t3_p_offset                            = ex3_t2_p_offset                + `XER_POOL_ENC;
   localparam ex3_itag_offset                            = ex3_t3_p_offset                + `CR_POOL_ENC;
   localparam ex3_gpr_we_offset                          = ex3_itag_offset                + `ITAG_SIZE_ENC;
   localparam ex3_xer_we_offset                          = ex3_gpr_we_offset              + 1;
   localparam ex3_cr_we_offset                           = ex3_xer_we_offset              + 1;
   localparam ex3_illeg_lswx_offset                      = ex3_cr_we_offset               + 1;
   localparam ex3_strg_noop_offset                       = ex3_illeg_lswx_offset          + 1;
   localparam cp_flush_offset                            = ex3_strg_noop_offset           + 1;
   localparam ex0_val_offset                             = cp_flush_offset                + `THREADS;
   localparam ex1_val_offset                             = ex0_val_offset                 + `THREADS;
   localparam ex2_val_offset                             = ex1_val_offset                 + `THREADS;
   localparam ex3_val_offset                             = ex2_val_offset                 + `THREADS;
   localparam ex2_stq_val_offset                         = ex3_val_offset                 + `THREADS;
   localparam ex2_xer_val_offset                         = ex2_stq_val_offset             + `THREADS;
   localparam msr_cm_offset                              = ex2_xer_val_offset             + 1;
   localparam ex3_ram_active_offset                      = msr_cm_offset                  + `THREADS;
   localparam ex2_dvc_mask_offset                        = ex3_ram_active_offset          + 1;
   localparam scan_right                                 = ex2_dvc_mask_offset            + `GPR_WIDTH/8;
   wire [0:scan_right-1]                           siv;
   wire [0:scan_right-1]                           sov;

   wire [0:3]                                      exx_act;
   wire                                            ex1_add_rs1_inv;
   wire                                            ex1_any_trap;
   wire                                            ex1_any_cmpl;
   wire                                            ex1_any_cmp;
   wire                                            ex1_alu_cmp;
   wire                                            ex1_any_tw;
   wire                                            ex1_any_td;
   wire                                            ex1_force_64b_cmp;
   wire                                            ex1_force_32b_cmp;
   wire                                            ex0_use_imm;
   wire                                            ex1_imm_size;
   wire                                            ex1_imm_signext;
   wire                                            ex1_shift_imm;
   wire                                            ex1_zero_imm;
   wire                                            ex1_ones_imm;
   wire [0:15]                                     ex1_16b_imm;
   wire [6:31]                                     ex1_extd_imm;
   wire [64-`GPR_WIDTH:63]                          ex1_shifted_imm;
   wire                                            ex1_any_store;
   wire                                            ex1_drop_preissue;
   wire [0:`THREADS-1]                              ex2_stq_val;
   wire [0:`THREADS-1]                              ex3_val;
   wire                                            ex3_valid;
   wire                                            ex2_valid;
   wire [0:7]                                      ex2_num_bytes;
   wire [0:7]                                      ex2_num_bytes_plus3;
   wire [0:5]                                      ex2_num_regs;
   wire [0:5]                                      ex2_lower_bnd;
   wire [0:5]                                      ex2_upper_bnd;
   wire [0:5]                                      ex2_upper_bnd_wrap;
   wire                                            ex2_range_wrap;
   wire                                            ex2_ra_in_rng_nowrap;
   wire                                            ex2_ra_in_rng_wrap;
   wire                                            ex2_ra_in_rng;
   wire                                            ex2_rb_in_rng_nowrap;
   wire                                            ex2_rb_in_rng_wrap;
   wire                                            ex2_rb_in_rng;
   wire                                            ex2_ra_eq_rt;
   wire                                            ex2_rb_eq_rt;
   wire [0:7]                                      ex1_dvc_mask;

   wire                                            ex0_opcode_is_31;
   wire                                            ex0_is_addi;
   wire                                            ex0_is_addic;
   wire                                            ex0_is_addicr;
   wire                                            ex0_is_addme;
   wire                                            ex0_is_addis;
   wire                                            ex0_is_addze;
   wire                                            ex0_is_andir;
   wire                                            ex0_is_andisr;
   wire                                            ex0_is_cmpi;
   wire                                            ex0_is_cmpli;
   wire                                            ex0_is_neg;
   wire                                            ex0_is_ori;
   wire                                            ex0_is_oris;
   wire                                            ex0_is_subfic;
   wire                                            ex0_is_subfze;
   wire                                            ex0_is_twi;
   wire                                            ex0_is_tdi;
   wire                                            ex0_is_xori;
   wire                                            ex0_is_xoris;
   wire                                            ex0_is_subfme;

   wire                                            ex1_opcode_is_62;
   wire                                            ex1_opcode_is_31;
   wire                                            ex1_is_adde;
   wire                                            ex1_is_addi;
   wire                                            ex1_is_addic;
   wire                                            ex1_is_addicr;
   wire                                            ex1_is_addis;
   wire                                            ex1_is_addme;
   wire                                            ex1_is_addze;
   wire                                            ex1_is_andir;
   wire                                            ex1_is_andisr;
   wire                                            ex1_is_cmp;
   wire                                            ex1_is_cmpi;
   wire                                            ex1_is_cmpl;
   wire                                            ex1_is_cmpli;
   wire                                            ex1_is_icswepx;
   wire                                            ex1_is_icswx;
   wire                                            ex1_is_lswx;
   wire                                            ex1_is_neg;
   wire                                            ex1_is_ori;
   wire                                            ex1_is_oris;
   wire                                            ex1_is_stb;
   wire                                            ex1_is_stbepx;
   wire                                            ex1_is_stbcrx;
   wire                                            ex1_is_stbu;
   wire                                            ex1_is_stbux;
   wire                                            ex1_is_stbx;
   wire                                            ex1_is_std;
   wire                                            ex1_is_stdbrx;
   wire                                            ex1_is_stdcrx;
   wire                                            ex1_is_stdepx;
   wire                                            ex1_is_stdu;
   wire                                            ex1_is_stdux;
   wire                                            ex1_is_stdx;
   wire                                            ex1_is_sth;
   wire                                            ex1_is_sthbrx;
   wire                                            ex1_is_sthcrx;
   wire                                            ex1_is_sthepx;
   wire                                            ex1_is_sthu;
   wire                                            ex1_is_sthux;
   wire                                            ex1_is_sthx;
   wire                                            ex1_is_stmw;
   wire                                            ex1_is_stswi;
   wire                                            ex1_is_stswx;
   wire                                            ex1_is_stw;
   wire                                            ex1_is_stwbrx;
   wire                                            ex1_is_stwcrx;
   wire                                            ex1_is_stwepx;
   wire                                            ex1_is_stwu;
   wire                                            ex1_is_stwux;
   wire                                            ex1_is_stwx;
   wire                                            ex1_is_subf;
   wire                                            ex1_is_subfc;
   wire                                            ex1_is_subfe;
   wire                                            ex1_is_subfic;
   wire                                            ex1_is_subfme;
   wire                                            ex1_is_subfze;
   wire                                            ex1_is_td;
   wire                                            ex1_is_tdi;
   wire                                            ex1_is_tw;
   wire                                            ex1_is_twi;
   wire                                            ex1_is_xori;
   wire                                            ex1_is_xoris;
   wire                                            ex1_is_isel;
   wire                                            ex1_is_add;
   wire                                            ex1_is_addc;
   wire                                            ex1_is_srad;
   wire                                            ex1_is_sradi;
   wire                                            ex1_is_sraw;
   wire                                            ex1_is_srawi;
   wire                                            ex1_is_mfdp;
   wire                                            ex1_is_mfdpx;
   (* analysis_not_referenced="true" *)
   wire                                            unused;
   


   assign rv2_val       = rv_xu1_vld & ~ cp_flush_q;
   assign ex0_val       = ex0_val_q  & ~(cp_flush_q | rv_xu1_ex0_spec_flush);
   assign ex1_val       = ex1_val_q  & ~(cp_flush_q | rv_xu1_ex1_spec_flush) & {`THREADS{~ex1_any_store}};
   assign ex2_val       = ex2_val_q  & ~(cp_flush_q | rv_xu1_ex2_spec_flush | {`THREADS{byp_dec_ex2_abort}});
   assign ex3_val       = ex3_val_q  & ~ cp_flush_q;
   assign ex2_valid     = |ex2_val;
   assign ex3_valid     = |ex3_val;

   assign ex1_stq_val   = ex1_val_q       & ~(cp_flush_q | rv_xu1_ex1_spec_flush) & {`THREADS{(ex1_any_store & ~ex1_drop_preissue)}};
   assign ex2_stq_val   = ex2_stq_val_q   & ~(cp_flush_q | rv_xu1_ex2_spec_flush | {`THREADS{byp_dec_ex2_abort}});

   assign exx_act[0]    = |ex0_val_q;
   assign exx_act[1]    = exx_act_q[1];
   assign exx_act[2]    = exx_act_q[2];
   assign exx_act[3]    = exx_act_q[3];

   assign exx_act_d[1:3] = exx_act[0:2];

   assign xu1_xu0_ex3_act = exx_act[3];

   assign dec_alu_ex1_act           = exx_act[1];
   assign dec_alu_ex1_instr         = ex1_instr_q;
   assign dec_alu_ex1_sel_isel      = ex1_is_isel;
   assign dec_alu_ex2_add_ci_sel    = ex2_add_ci_sel_q;
   assign dec_alu_ex1_add_rs1_inv   = {`GPR_WIDTH/8{ex1_add_rs1_inv}};
   assign dec_alu_ex1_sel_trap      = ex1_any_trap;
   assign dec_alu_ex1_sel_cmpl      = ex1_any_cmpl;
   assign dec_alu_ex1_sel_cmp       = ex1_any_cmp;
   assign dec_byp_ex0_act           = exx_act[0];
   assign dec_byp_ex2_val           = |ex2_val;
   assign dec_byp_ex1_instr         = ex1_instr_q[24:25];
   assign dec_byp_ex0_rs1_sel_zero  = (~rv_xu1_ex0_s1_v);
   assign dec_byp_ex2_tid           = ex2_stq_val_q;

   assign ex1_add_ci_sel[0] = ex1_is_adde | ex1_is_addme | ex1_is_addze | ex1_is_subfme | ex1_is_subfze | ex1_is_subfe;
   assign ex1_add_ci_sel[1] = ex1_is_subf | ex1_is_subfc | ex1_is_subfic | ex1_is_neg | ex1_alu_cmp | ex1_any_trap;

   assign ex1_add_rs1_inv  = ex1_add_ci_sel[1] | ex1_is_subfme | ex1_is_subfze | ex1_is_subfe;

   assign ex1_any_tw       = ex1_is_tw | ex1_is_twi;
   assign ex1_any_td       = ex1_is_td | ex1_is_tdi;

   assign ex1_any_trap     = ex1_any_tw | ex1_any_td;

   assign ex1_any_cmp      = ex1_is_cmp | ex1_is_cmpi;

   assign ex1_any_cmpl     = ex1_is_cmpl | ex1_is_cmpli;

   assign ex1_alu_cmp      = ex1_any_cmp | ex1_any_cmpl;

   assign ex1_force_64b_cmp = ex1_any_td | (ex1_alu_cmp &  ex1_instr_q[10]);
   assign ex1_force_32b_cmp = ex1_any_tw | (ex1_alu_cmp & ~ex1_instr_q[10]);

   assign dec_alu_ex1_msb_64b_sel = (|(ex1_val_q & msr_cm_q) & ~ex1_force_32b_cmp) | ex1_force_64b_cmp;

   assign dec_alu_ex1_xer_ca_en  = ex1_is_addc  | ex1_is_addic  | ex1_is_addicr | ex1_is_adde  | ex1_is_addme  | ex1_is_addze | 
                                   ex1_is_subfc | ex1_is_subfic | ex1_is_subfme | ex1_is_subfe | ex1_is_subfze |
                                   ex1_is_srad  | ex1_is_sradi  | ex1_is_sraw   | ex1_is_srawi;

   assign dec_alu_ex1_xer_ov_en  = ex1_instr_q[21] & (
                                   ex1_is_add   | ex1_is_addc   | ex1_is_adde   | ex1_is_addme  | ex1_is_addze  |
                                   ex1_is_subf  | ex1_is_subfc  | ex1_is_subfe  | ex1_is_subfme | ex1_is_subfze | ex1_is_neg);

   assign ex0_use_imm            = ex0_is_addi  | ex0_is_addic  | ex0_is_addicr | ex0_is_addme  | ex0_is_addis  | ex0_is_addze | 
                                   ex0_is_andir | ex0_is_andisr | ex0_is_cmpi   | ex0_is_cmpli  | ex0_is_neg    | ex0_is_ori   | ex0_is_oris | 
                                   ex0_is_subfic | ex0_is_subfze | ex0_is_twi | ex0_is_tdi | ex0_is_xori | ex0_is_xoris | ex0_is_subfme | 
                                   rv_xu1_ex0_isstore;

   assign ex1_imm_size           = ex1_is_addi  | ex1_is_addis  | ex1_is_subfic | ex1_is_addic  | ex1_is_addicr | 
                                   ex1_is_stb   | ex1_is_ori    | ex1_is_oris   | ex1_is_andir  | ex1_is_andisr | 
                                   ex1_is_xori  | ex1_is_xoris  | ex1_is_sth    | ex1_is_stw    | ex1_is_stbu   | 
                                   ex1_is_sthu  | ex1_is_stwu   | ex1_is_stdu   | ex1_is_std    | ex1_is_stmw   |
                                   ex1_is_cmpli | ex1_is_cmpi   | ex1_is_twi    | ex1_is_tdi;

   assign ex1_imm_signext        = ex1_is_addi  | ex1_is_addis  | ex1_is_subfic | ex1_is_addic  | ex1_is_addicr | 
                                   ex1_is_sth   | ex1_is_stw    | ex1_is_stbu   | ex1_is_sthu   | ex1_is_stwu   | 
                                   ex1_is_stdu  | ex1_is_std    | ex1_is_stmw   | ex1_is_stb    | ex1_is_cmpi   | 
                                   ex1_is_twi   | ex1_is_tdi;

   assign ex1_shift_imm          = ex1_is_addis | ex1_is_oris   | ex1_is_andisr | ex1_is_xoris;		
   assign ex1_zero_imm           = ex1_is_neg   | ex1_is_addze  | ex1_is_subfze | ex1_any_store;
   assign ex1_ones_imm           = ex1_is_addme | ex1_is_subfme;		

   assign ex1_16b_imm            = ((ex1_is_std | ex1_is_stdu) == 1'b0) ? ex1_instr_q[16:31] : {ex1_instr_q[16:29], 2'b0};

   assign ex1_extd_imm = ({ex1_imm_size, ex1_imm_signext} == 2'b11) ? {{10{ex1_16b_imm[0]}}, ex1_16b_imm} : 
                         ({ex1_imm_size, ex1_imm_signext} == 2'b10) ? {               10'b0, ex1_16b_imm} : 
                                                                      ex1_instr_q[6:31];

   assign ex1_shifted_imm = (ex1_shift_imm == 1'b0) ? {{`GPR_WIDTH-26{ex1_extd_imm[6]}},  ex1_extd_imm} : 
                                                      {{`GPR_WIDTH-32{ex1_extd_imm[15]}}, ex1_extd_imm[16:31], 16'b0};
                                                      
   assign dec_byp_ex1_imm = ex1_shifted_imm & {`GPR_WIDTH{~ex1_zero_imm}} | {`GPR_WIDTH{ex1_ones_imm}};

   assign dec_byp_ex0_rs2_sel_imm = ex0_use_imm;

   assign ex1_opsize[1] = ex1_is_std | ex1_is_stdbrx | ex1_is_stdcrx | ex1_is_stdu | ex1_is_stdux | ex1_is_stdx | ex1_is_stdepx;
   assign ex1_opsize[2] = ex1_is_stw | ex1_is_stwbrx | ex1_is_stwcrx | ex1_is_stwu | ex1_is_stwux | ex1_is_stwx | ex1_is_stwepx;
   assign ex1_opsize[3] = ex1_is_sth | ex1_is_sthbrx | ex1_is_sthcrx | ex1_is_sthu | ex1_is_sthux | ex1_is_sthx | ex1_is_sthepx;
   assign ex1_opsize[4] = ex1_is_stb | ex1_is_stbu   | ex1_is_stbux  | ex1_is_stbx | ex1_is_stbepx | ex1_is_stbcrx;

   assign ex1_any_store = ex1_is_std | ex1_is_stdbrx | ex1_is_stdcrx | ex1_is_stdu | ex1_is_stdux | ex1_is_stdx | ex1_is_stdepx |
                          ex1_is_stw | ex1_is_stwbrx | ex1_is_stwcrx | ex1_is_stwu | ex1_is_stwux | ex1_is_stwx | ex1_is_stwepx | 
                          ex1_is_sth | ex1_is_sthbrx | ex1_is_sthcrx | ex1_is_sthu | ex1_is_sthux | ex1_is_sthx | ex1_is_sthepx | 
                        ex1_is_stswx | ex1_is_stswi  | ex1_is_stb    | ex1_is_stbu | ex1_is_stbux | ex1_is_stbx | ex1_is_stbepx | 
                       ex1_is_stbcrx | ex1_is_lswx   | ex1_is_icswx  | ex1_is_icswepx | ex1_is_mfdp | ex1_is_mfdpx;

   assign ex1_drop_preissue   = (ex1_ucode_q[1] & ~(ex1_s3_type_q == 3'b100)) | ex1_is_mfdp | ex1_is_mfdpx;		
   assign ex1_xer_val         =  ex1_ucode_q[1]  & (ex1_s3_type_q == 3'b100);

   assign xu1_lq_ex2_stq_val     = ex2_stq_val;
   assign xu1_lq_ex2_stq_itag    = ex2_itag_q;
   assign xu1_lq_ex2_stq_size    = ex2_opsize_q;
   assign xu1_lq_ex3_illeg_lswx  = ex3_illeg_lswx_q;
   assign xu1_lq_ex3_strg_noop   = ex3_strg_noop_q;

   assign ex1_dvc_mask = (8'h01 & {8{ex1_opsize[4]}}) | 
                         (8'h03 & {8{ex1_opsize[3]}}) |
                         (8'h0F & {8{ex1_opsize[2]}}) |
                         (8'hFF & {8{ex1_opsize[1]}}) ;

   assign dec_byp_ex2_dvc_mask = ex2_dvc_mask_q;

   assign xu_iu_ucode_xer_val =  ex2_xer_val_q==1'b1 ? (ex2_stq_val_q & ~{`THREADS{byp_dec_ex2_abort}})  : `THREADS'b0;

   assign ex2_num_bytes          = {1'b0, byp_dec_ex2_xer[3:9]};
   assign ex2_num_bytes_plus3    = ex2_num_bytes + 8'd3;
   assign ex2_num_regs           = ex2_num_bytes_plus3[0:5];		
   assign ex2_lower_bnd          = {1'b0, ex2_instr_q[6:10]};		
   assign ex2_upper_bnd          = ex2_lower_bnd + ex2_num_regs;
   assign ex2_upper_bnd_wrap     = {1'b0, ex2_upper_bnd[1:5]};
   assign ex2_range_wrap         = ex2_upper_bnd[0];		         

   assign ex2_ra_in_rng_nowrap   = (({1'b0, ex2_instr_q[11:15]}) >= ex2_lower_bnd) & (({1'b0, ex2_instr_q[11:15]}) < ex2_upper_bnd);
   assign ex2_ra_in_rng_wrap     = (({1'b0, ex2_instr_q[11:15]}) < ex2_upper_bnd_wrap);
   assign ex2_ra_in_rng          = (ex2_ra_in_rng_nowrap) | (ex2_ra_in_rng_wrap & ex2_range_wrap);

   assign ex2_rb_in_rng_nowrap   = (({1'b0, ex2_instr_q[16:20]}) >= ex2_lower_bnd) & (({1'b0, ex2_instr_q[16:20]}) < ex2_upper_bnd);
   assign ex2_rb_in_rng_wrap     = (({1'b0, ex2_instr_q[16:20]}) < ex2_upper_bnd_wrap);
   assign ex2_rb_in_rng          = (ex2_rb_in_rng_nowrap) | (ex2_rb_in_rng_wrap & ex2_range_wrap);
   assign ex2_ra_eq_rt           = (ex2_instr_q[11:15] == ex2_instr_q[6:10]);
   assign ex2_rb_eq_rt           = (ex2_instr_q[16:20] == ex2_instr_q[6:10]);
   assign ex2_illeg_lswx         = ex2_is_lswx_q & (ex2_ra_in_rng | ex2_rb_in_rng | ex2_ra_eq_rt | ex2_rb_eq_rt);
   assign ex2_strg_noop          = (ex2_is_lswx_q | ex2_is_stswx_q) & ~|byp_dec_ex2_xer;

   assign ex1_gpr_we          = ex1_t1_v_q;
   assign ex1_xer_we          = ex1_t2_v_q;
   assign ex1_cr_we           = ex1_t3_v_q;

   assign ex2_gpr_we          = ex2_valid & ex2_gpr_we_q;
   assign ex2_xer_we          = ex2_valid & ex2_xer_we_q;
   assign ex2_cr_we           = ex2_valid & ex2_cr_we_q;

   assign xu1_gpr_ex3_we      = ex3_gpr_we_q;
   assign xu1_xer_ex3_we      = ex3_xer_we_q;
   assign xu1_cr_ex3_we       = ex3_cr_we_q;

   `ifdef THREADS1
      assign xu1_gpr_ex3_wa   = ex3_t1_p_q;
      assign xu1_xer_ex3_wa   = ex3_t2_p_q;
      assign xu1_cr_ex3_wa    = ex3_t3_p_q;
   `else
      assign xu1_gpr_ex3_wa   = {ex3_t1_p_q,ex3_val_q[1]};
      assign xu1_xer_ex3_wa   = {ex3_t2_p_q,ex3_val_q[1]};
      assign xu1_cr_ex3_wa    = {ex3_t3_p_q,ex3_val_q[1]};
   `endif

   assign xu1_iu_execute_vld  = ex3_val;
   assign xu1_iu_itag         = ex3_itag_q;

   assign ex3_ram_active_d    = |(ex2_val_q & pc_xu_ram_active);

   assign xu1_pc_ram_done     = ex3_valid & ex3_ram_active_q;

   assign ex0_opcode_is_31    = rv_xu1_ex0_instr[0:5] == 6'b011111;

   assign ex0_is_addi         =                    rv_xu1_ex0_instr[0:5] == 6'b001110;
   assign ex0_is_addic        =                    rv_xu1_ex0_instr[0:5] == 6'b001100;
   assign ex0_is_addicr       =                    rv_xu1_ex0_instr[0:5] == 6'b001101;
   assign ex0_is_addme        = ex0_opcode_is_31 & rv_xu1_ex0_instr[22:30] == 9'b011101010;
   assign ex0_is_addis        =                    rv_xu1_ex0_instr[0:5] == 6'b001111;
   assign ex0_is_addze        = ex0_opcode_is_31 & rv_xu1_ex0_instr[22:30] == 9'b011001010;
   assign ex0_is_andir        =                    rv_xu1_ex0_instr[0:5] == 6'b011100;
   assign ex0_is_andisr       =                    rv_xu1_ex0_instr[0:5] == 6'b011101;
   assign ex0_is_cmpi         =                    rv_xu1_ex0_instr[0:5] == 6'b001011;
   assign ex0_is_cmpli        =                    rv_xu1_ex0_instr[0:5] == 6'b001010;
   assign ex0_is_neg          = ex0_opcode_is_31 & rv_xu1_ex0_instr[22:30] == 9'b001101000;
   assign ex0_is_ori          =                    rv_xu1_ex0_instr[0:5] == 6'b011000;
   assign ex0_is_oris         =                    rv_xu1_ex0_instr[0:5] == 6'b011001;
   assign ex0_is_subfic       =                    rv_xu1_ex0_instr[0:5] == 6'b001000;
   assign ex0_is_subfze       = ex0_opcode_is_31 & rv_xu1_ex0_instr[22:30] == 9'b011001000;
   assign ex0_is_twi          =                    rv_xu1_ex0_instr[0:5] == 6'b000011;
   assign ex0_is_tdi          =                    rv_xu1_ex0_instr[0:5] == 6'b000010;
   assign ex0_is_xori         =                    rv_xu1_ex0_instr[0:5] == 6'b011010;
   assign ex0_is_xoris        =                    rv_xu1_ex0_instr[0:5] == 6'b011011;
   assign ex0_is_subfme       = ex0_opcode_is_31 & rv_xu1_ex0_instr[22:30] == 9'b011101000;

   assign ex1_opcode_is_62 = ex1_instr_q[0:5] == 6'b111110;
   assign ex1_opcode_is_31 = ex1_instr_q[0:5] == 6'b011111;

   assign ex1_is_add          = ex1_opcode_is_31 & ex1_instr_q[22:30] == 9'b100001010;      
   assign ex1_is_addc         = ex1_opcode_is_31 & ex1_instr_q[22:30] == 9'b000001010;      
   assign ex1_is_adde         = ex1_opcode_is_31 & ex1_instr_q[22:30] == 9'b010001010;      
   assign ex1_is_addi         =                    ex1_instr_q[0:5]   == 6'b001110;         
   assign ex1_is_addic        =                    ex1_instr_q[0:5]   == 6'b001100;         
   assign ex1_is_addicr       =                    ex1_instr_q[0:5]   == 6'b001101;         
   assign ex1_is_addis        =                    ex1_instr_q[0:5]   == 6'b001111;         
   assign ex1_is_addme        = ex1_opcode_is_31 & ex1_instr_q[22:30] == 9'b011101010;      
   assign ex1_is_addze        = ex1_opcode_is_31 & ex1_instr_q[22:30] == 9'b011001010;      
   assign ex1_is_andir        =                    ex1_instr_q[0:5]   == 6'b011100;         
   assign ex1_is_andisr       =                    ex1_instr_q[0:5]   == 6'b011101;         
   assign ex1_is_cmp          = ex1_opcode_is_31 & ex1_instr_q[21:30] == 10'b0000000000;    
   assign ex1_is_cmpi         =                    ex1_instr_q[0:5]   == 6'b001011;         
   assign ex1_is_cmpl         = ex1_opcode_is_31 & ex1_instr_q[21:30] == 10'b0000100000;    
   assign ex1_is_cmpli        =                    ex1_instr_q[0:5]   == 6'b001010;         
   assign ex1_is_icswx        = ex1_opcode_is_31 & ex1_instr_q[21:30] == 10'b0110010110;    
   assign ex1_is_icswepx      = ex1_opcode_is_31 & ex1_instr_q[21:30] == 10'b1110110110;    
   assign ex1_is_isel         = ex1_opcode_is_31 & ex1_instr_q[26:30] == 5'b01111;          
   assign ex1_is_lswx         = ex1_opcode_is_31 & ex1_instr_q[21:30] == 10'b1000010101;    
   assign ex1_is_mfdp         = ex1_opcode_is_31 & ex1_instr_q[21:30] == 10'b0000100011;    
   assign ex1_is_mfdpx        = ex1_opcode_is_31 & ex1_instr_q[21:30] == 10'b0000000011;    
   assign ex1_is_neg          = ex1_opcode_is_31 & ex1_instr_q[22:30] == 9'b001101000;      
   assign ex1_is_ori          =                    ex1_instr_q[0:5]   == 6'b011000;         
   assign ex1_is_oris         =                    ex1_instr_q[0:5]   == 6'b011001;         
   assign ex1_is_srad         = ex1_opcode_is_31 & ex1_instr_q[21:30] == 10'b1100011010;    
   assign ex1_is_sradi        = ex1_opcode_is_31 & ex1_instr_q[21:29] == 9'b110011101;      
   assign ex1_is_sraw         = ex1_opcode_is_31 & ex1_instr_q[21:30] == 10'b1100011000;    
   assign ex1_is_srawi        = ex1_opcode_is_31 & ex1_instr_q[21:30] == 10'b1100111000;    
   assign ex1_is_stb          =                    ex1_instr_q[0:5]   == 6'b100110;         
   assign ex1_is_stbcrx       = ex1_opcode_is_31 & ex1_instr_q[21:30] == 10'b1010110110;    
   assign ex1_is_stbepx       = ex1_opcode_is_31 & ex1_instr_q[21:30] == 10'b0011011111;    
   assign ex1_is_stbu         =                    ex1_instr_q[0:5]   == 6'b100111;         
   assign ex1_is_stbux        = ex1_opcode_is_31 & ex1_instr_q[21:30] == 10'b0011110111;    
   assign ex1_is_stbx         = ex1_opcode_is_31 & ex1_instr_q[21:30] == 10'b0011010111;    
   assign ex1_is_std          = ex1_opcode_is_62 & ex1_instr_q[30:31] == 2'b00;             
   assign ex1_is_stdbrx       = ex1_opcode_is_31 & ex1_instr_q[21:30] == 10'b1010010100;    
   assign ex1_is_stdcrx       = ex1_opcode_is_31 & ex1_instr_q[21:30] == 10'b0011010110;    
   assign ex1_is_stdepx       = ex1_opcode_is_31 & ex1_instr_q[21:30] == 10'b0010011101;    
   assign ex1_is_stdu         = ex1_opcode_is_62 & ex1_instr_q[30:31] == 2'b01;             
   assign ex1_is_stdux        = ex1_opcode_is_31 & ex1_instr_q[21:30] == 10'b0010110101;    
   assign ex1_is_stdx         = ex1_opcode_is_31 & ex1_instr_q[21:30] == 10'b0010010101;    
   assign ex1_is_sth          =                    ex1_instr_q[0:5]   == 6'b101100;         
   assign ex1_is_sthu         =                    ex1_instr_q[0:5]   == 6'b101101;         
   assign ex1_is_sthux        = ex1_opcode_is_31 & ex1_instr_q[21:30] == 10'b0110110111;    
   assign ex1_is_sthx         = ex1_opcode_is_31 & ex1_instr_q[21:30] == 10'b0110010111;    
   assign ex1_is_sthbrx       = ex1_opcode_is_31 & ex1_instr_q[21:30] == 10'b1110010110;    
   assign ex1_is_sthcrx       = ex1_opcode_is_31 & ex1_instr_q[21:30] == 10'b1011010110;    
   assign ex1_is_sthepx       = ex1_opcode_is_31 & ex1_instr_q[21:30] == 10'b0110011111;    
   assign ex1_is_stmw         =                    ex1_instr_q[0:5]   == 6'b101111;         
   assign ex1_is_stswi        = ex1_opcode_is_31 & ex1_instr_q[21:30] == 10'b1011010101;    
   assign ex1_is_stswx        = ex1_opcode_is_31 & ex1_instr_q[21:30] == 10'b1010010101;    
   assign ex1_is_stw          =                    ex1_instr_q[0:5]   == 6'b100100;         
   assign ex1_is_stwbrx       = ex1_opcode_is_31 & ex1_instr_q[21:30] == 10'b1010010110;    
   assign ex1_is_stwcrx       = ex1_opcode_is_31 & ex1_instr_q[21:30] == 10'b0010010110;    
   assign ex1_is_stwepx       = ex1_opcode_is_31 & ex1_instr_q[21:30] == 10'b0010011111;    
   assign ex1_is_stwu         =                    ex1_instr_q[0:5]   == 6'b100101;         
   assign ex1_is_stwux        = ex1_opcode_is_31 & ex1_instr_q[21:30] == 10'b0010110111;    
   assign ex1_is_stwx         = ex1_opcode_is_31 & ex1_instr_q[21:30] == 10'b0010010111;    
   assign ex1_is_subf         = ex1_opcode_is_31 & ex1_instr_q[22:30] == 9'b000101000;      
   assign ex1_is_subfc        = ex1_opcode_is_31 & ex1_instr_q[22:30] == 9'b000001000;      
   assign ex1_is_subfe        = ex1_opcode_is_31 & ex1_instr_q[22:30] == 9'b010001000;      
   assign ex1_is_subfic       =                    ex1_instr_q[0:5]   == 6'b001000;         
   assign ex1_is_subfme       = ex1_opcode_is_31 & ex1_instr_q[22:30] == 9'b011101000;      
   assign ex1_is_subfze       = ex1_opcode_is_31 & ex1_instr_q[22:30] == 9'b011001000;      
   assign ex1_is_td           = ex1_opcode_is_31 & ex1_instr_q[21:30] == 10'b0001000100;    
   assign ex1_is_tdi          =                    ex1_instr_q[0:5]   == 6'b000010;         
   assign ex1_is_tw           = ex1_opcode_is_31 & ex1_instr_q[21:30] == 10'b0000000100;    
   assign ex1_is_twi          =                    ex1_instr_q[0:5]   == 6'b000011;         
   assign ex1_is_xori         =                    ex1_instr_q[0:5]   == 6'b011010;         
   assign ex1_is_xoris        =                    ex1_instr_q[0:5]   == 6'b011011;         


   tri_rlmreg_p #(.WIDTH(3), .INIT(0), .NEEDS_SRESET(1)) exx_act_latch(
      .nclk(nclk),
      .vd(vdd),
      .gd(gnd),
      .act(1'b1),
      .force_t(func_sl_force),
      .d_mode(d_mode_dc),
      .delay_lclkr(delay_lclkr_dc),
      .mpw1_b(mpw1_dc_b),
      .mpw2_b(mpw2_dc_b),
      .thold_b(func_sl_thold_0_b),
      .sg(sg_0),
      .scin(siv[exx_act_offset:exx_act_offset + 3 - 1]),
      .scout(sov[exx_act_offset:exx_act_offset + 3 - 1]),
      .din(exx_act_d),
      .dout(exx_act_q)
   );

   tri_rlmreg_p #(.WIDTH(3), .INIT(0), .NEEDS_SRESET(1)) ex1_s3_type_latch(
      .nclk(nclk),
      .vd(vdd),
      .gd(gnd),
      .act(exx_act[0]),
      .force_t(func_sl_force),
      .d_mode(d_mode_dc),
      .delay_lclkr(delay_lclkr_dc),
      .mpw1_b(mpw1_dc_b),
      .mpw2_b(mpw2_dc_b),
      .thold_b(func_sl_thold_0_b),
      .sg(sg_0),
      .scin(siv[ex1_s3_type_offset:ex1_s3_type_offset + 3 - 1]),
      .scout(sov[ex1_s3_type_offset:ex1_s3_type_offset + 3 - 1]),
      .din(rv_xu1_ex0_s3_t),
      .dout(ex1_s3_type_q)
   );

   tri_rlmlatch_p #(.INIT(0), .NEEDS_SRESET(1)) ex1_t1_v_latch(
      .nclk(nclk),
      .vd(vdd),
      .gd(gnd),
      .act(exx_act[0]),
      .force_t(func_sl_force),
      .d_mode(d_mode_dc),
      .delay_lclkr(delay_lclkr_dc),
      .mpw1_b(mpw1_dc_b),
      .mpw2_b(mpw2_dc_b),
      .thold_b(func_sl_thold_0_b),
      .sg(sg_0),
      .scin(siv[ex1_t1_v_offset]),
      .scout(sov[ex1_t1_v_offset]),
      .din(rv_xu1_ex0_t1_v),
      .dout(ex1_t1_v_q)
   );

   tri_rlmlatch_p #(.INIT(0), .NEEDS_SRESET(1)) ex1_t2_v_latch(
      .nclk(nclk),
      .vd(vdd),
      .gd(gnd),
      .act(exx_act[0]),
      .force_t(func_sl_force),
      .d_mode(d_mode_dc),
      .delay_lclkr(delay_lclkr_dc),
      .mpw1_b(mpw1_dc_b),
      .mpw2_b(mpw2_dc_b),
      .thold_b(func_sl_thold_0_b),
      .sg(sg_0),
      .scin(siv[ex1_t2_v_offset]),
      .scout(sov[ex1_t2_v_offset]),
      .din(rv_xu1_ex0_t2_v),
      .dout(ex1_t2_v_q)
   );

   tri_rlmlatch_p #(.INIT(0), .NEEDS_SRESET(1)) ex1_t3_v_latch(
      .nclk(nclk),
      .vd(vdd),
      .gd(gnd),
      .act(exx_act[0]),
      .force_t(func_sl_force),
      .d_mode(d_mode_dc),
      .delay_lclkr(delay_lclkr_dc),
      .mpw1_b(mpw1_dc_b),
      .mpw2_b(mpw2_dc_b),
      .thold_b(func_sl_thold_0_b),
      .sg(sg_0),
      .scin(siv[ex1_t3_v_offset]),
      .scout(sov[ex1_t3_v_offset]),
      .din(rv_xu1_ex0_t3_v),
      .dout(ex1_t3_v_q)
   );

   tri_rlmreg_p #(.WIDTH(`GPR_POOL_ENC), .INIT(0), .NEEDS_SRESET(1)) ex1_t1_p_latch(
      .nclk(nclk),
      .vd(vdd),
      .gd(gnd),
      .act(exx_act[0]),
      .force_t(func_sl_force),
      .d_mode(d_mode_dc),
      .delay_lclkr(delay_lclkr_dc),
      .mpw1_b(mpw1_dc_b),
      .mpw2_b(mpw2_dc_b),
      .thold_b(func_sl_thold_0_b),
      .sg(sg_0),
      .scin(siv[ex1_t1_p_offset:ex1_t1_p_offset + `GPR_POOL_ENC - 1]),
      .scout(sov[ex1_t1_p_offset:ex1_t1_p_offset + `GPR_POOL_ENC - 1]),
      .din(rv_xu1_ex0_t1_p),
      .dout(ex1_t1_p_q)
   );

   tri_rlmreg_p #(.WIDTH(`XER_POOL_ENC), .INIT(0), .NEEDS_SRESET(1)) ex1_t2_p_latch(
      .nclk(nclk),
      .vd(vdd),
      .gd(gnd),
      .act(exx_act[0]),
      .force_t(func_sl_force),
      .d_mode(d_mode_dc),
      .delay_lclkr(delay_lclkr_dc),
      .mpw1_b(mpw1_dc_b),
      .mpw2_b(mpw2_dc_b),
      .thold_b(func_sl_thold_0_b),
      .sg(sg_0),
      .scin(siv[ex1_t2_p_offset:ex1_t2_p_offset + `XER_POOL_ENC - 1]),
      .scout(sov[ex1_t2_p_offset:ex1_t2_p_offset + `XER_POOL_ENC - 1]),
      .din(rv_xu1_ex0_t2_p[`GPR_POOL_ENC-`XER_POOL_ENC:`GPR_POOL_ENC-1]),
      .dout(ex1_t2_p_q)
   );

   tri_rlmreg_p #(.WIDTH(`CR_POOL_ENC), .INIT(0), .NEEDS_SRESET(1)) ex1_t3_p_latch(
      .nclk(nclk),
      .vd(vdd),
      .gd(gnd),
      .act(exx_act[0]),
      .force_t(func_sl_force),
      .d_mode(d_mode_dc),
      .delay_lclkr(delay_lclkr_dc),
      .mpw1_b(mpw1_dc_b),
      .mpw2_b(mpw2_dc_b),
      .thold_b(func_sl_thold_0_b),
      .sg(sg_0),
      .scin(siv[ex1_t3_p_offset:ex1_t3_p_offset + `CR_POOL_ENC - 1]),
      .scout(sov[ex1_t3_p_offset:ex1_t3_p_offset + `CR_POOL_ENC - 1]),
      .din(rv_xu1_ex0_t3_p[`GPR_POOL_ENC-`CR_POOL_ENC:`GPR_POOL_ENC-1]),
      .dout(ex1_t3_p_q)
   );

   tri_rlmreg_p #(.WIDTH(32), .INIT(0), .NEEDS_SRESET(1)) ex1_instr_latch(
      .nclk(nclk),
      .vd(vdd),
      .gd(gnd),
      .act(exx_act[0]),
      .force_t(func_sl_force),
      .d_mode(d_mode_dc),
      .delay_lclkr(delay_lclkr_dc),
      .mpw1_b(mpw1_dc_b),
      .mpw2_b(mpw2_dc_b),
      .thold_b(func_sl_thold_0_b),
      .sg(sg_0),
      .scin(siv[ex1_instr_offset:ex1_instr_offset + 32 - 1]),
      .scout(sov[ex1_instr_offset:ex1_instr_offset + 32 - 1]),
      .din(rv_xu1_ex0_instr),
      .dout(ex1_instr_q)
   );

   tri_rlmreg_p #(.WIDTH(1), .INIT(0), .NEEDS_SRESET(1)) ex1_ucode_latch(
      .nclk(nclk),
      .vd(vdd),
      .gd(gnd),
      .act(exx_act[0]),
      .force_t(func_sl_force),
      .d_mode(d_mode_dc),
      .delay_lclkr(delay_lclkr_dc),
      .mpw1_b(mpw1_dc_b),
      .mpw2_b(mpw2_dc_b),
      .thold_b(func_sl_thold_0_b),
      .sg(sg_0),
      .scin(siv[ex1_ucode_offset:ex1_ucode_offset + 1 - 1]),
      .scout(sov[ex1_ucode_offset:ex1_ucode_offset + 1 - 1]),
      .din(rv_xu1_ex0_ucode[1:1]),
      .dout(ex1_ucode_q)
   );

   tri_rlmreg_p #(.WIDTH(`ITAG_SIZE_ENC), .INIT(0), .NEEDS_SRESET(1)) ex1_itag_latch(
      .nclk(nclk),
      .vd(vdd),
      .gd(gnd),
      .act(exx_act[0]),
      .force_t(func_sl_force),
      .d_mode(d_mode_dc),
      .delay_lclkr(delay_lclkr_dc),
      .mpw1_b(mpw1_dc_b),
      .mpw2_b(mpw2_dc_b),
      .thold_b(func_sl_thold_0_b),
      .sg(sg_0),
      .scin(siv[ex1_itag_offset:ex1_itag_offset + `ITAG_SIZE_ENC - 1]),
      .scout(sov[ex1_itag_offset:ex1_itag_offset + `ITAG_SIZE_ENC - 1]),
      .din(rv_xu1_ex0_itag),
      .dout(ex1_itag_q)
   );

   tri_rlmreg_p #(.WIDTH(2), .INIT(0), .NEEDS_SRESET(1)) ex2_add_ci_sel_latch(
      .nclk(nclk),
      .vd(vdd),
      .gd(gnd),
      .act(exx_act[1]),
      .force_t(func_sl_force),
      .d_mode(d_mode_dc),
      .delay_lclkr(delay_lclkr_dc),
      .mpw1_b(mpw1_dc_b),
      .mpw2_b(mpw2_dc_b),
      .thold_b(func_sl_thold_0_b),
      .sg(sg_0),
      .scin(siv[ex2_add_ci_sel_offset:ex2_add_ci_sel_offset + 2 - 1]),
      .scout(sov[ex2_add_ci_sel_offset:ex2_add_ci_sel_offset + 2 - 1]),
      .din(ex1_add_ci_sel),
      .dout(ex2_add_ci_sel_q)
   );

   tri_rlmreg_p #(.WIDTH(`ITAG_SIZE_ENC), .INIT(0), .NEEDS_SRESET(1)) ex2_itag_latch(
      .nclk(nclk),
      .vd(vdd),
      .gd(gnd),
      .act(exx_act[1]),
      .force_t(func_sl_force),
      .d_mode(d_mode_dc),
      .delay_lclkr(delay_lclkr_dc),
      .mpw1_b(mpw1_dc_b),
      .mpw2_b(mpw2_dc_b),
      .thold_b(func_sl_thold_0_b),
      .sg(sg_0),
      .scin(siv[ex2_itag_offset:ex2_itag_offset + `ITAG_SIZE_ENC - 1]),
      .scout(sov[ex2_itag_offset:ex2_itag_offset + `ITAG_SIZE_ENC - 1]),
      .din(ex1_itag_q),
      .dout(ex2_itag_q)
   );

   tri_rlmreg_p #(.WIDTH(`GPR_POOL_ENC), .INIT(0), .NEEDS_SRESET(1)) ex2_t1_p_latch(
      .nclk(nclk),
      .vd(vdd),
      .gd(gnd),
      .act(exx_act[1]),
      .force_t(func_sl_force),
      .d_mode(d_mode_dc),
      .delay_lclkr(delay_lclkr_dc),
      .mpw1_b(mpw1_dc_b),
      .mpw2_b(mpw2_dc_b),
      .thold_b(func_sl_thold_0_b),
      .sg(sg_0),
      .scin(siv[ex2_t1_p_offset:ex2_t1_p_offset + `GPR_POOL_ENC - 1]),
      .scout(sov[ex2_t1_p_offset:ex2_t1_p_offset + `GPR_POOL_ENC - 1]),
      .din(ex1_t1_p_q),
      .dout(ex2_t1_p_q)
   );

   tri_rlmreg_p #(.WIDTH(`XER_POOL_ENC), .INIT(0), .NEEDS_SRESET(1)) ex2_t2_p_latch(
      .nclk(nclk),
      .vd(vdd),
      .gd(gnd),
      .act(exx_act[1]),
      .force_t(func_sl_force),
      .d_mode(d_mode_dc),
      .delay_lclkr(delay_lclkr_dc),
      .mpw1_b(mpw1_dc_b),
      .mpw2_b(mpw2_dc_b),
      .thold_b(func_sl_thold_0_b),
      .sg(sg_0),
      .scin(siv[ex2_t2_p_offset :ex2_t2_p_offset + `XER_POOL_ENC- 1]),
      .scout(sov[ex2_t2_p_offset:ex2_t2_p_offset + `XER_POOL_ENC- 1]),
      .din(ex1_t2_p_q),
      .dout(ex2_t2_p_q)
   );

   tri_rlmreg_p #(.WIDTH(`CR_POOL_ENC), .INIT(0), .NEEDS_SRESET(1)) ex2_t3_p_latch(
      .nclk(nclk),
      .vd(vdd),
      .gd(gnd),
      .act(exx_act[1]),
      .force_t(func_sl_force),
      .d_mode(d_mode_dc),
      .delay_lclkr(delay_lclkr_dc),
      .mpw1_b(mpw1_dc_b),
      .mpw2_b(mpw2_dc_b),
      .thold_b(func_sl_thold_0_b),
      .sg(sg_0),
      .scin(siv[ex2_t3_p_offset :ex2_t3_p_offset + `CR_POOL_ENC - 1]),
      .scout(sov[ex2_t3_p_offset:ex2_t3_p_offset + `CR_POOL_ENC - 1]),
      .din(ex1_t3_p_q),
      .dout(ex2_t3_p_q)
   );

   tri_rlmreg_p #(.WIDTH(15), .INIT(0), .NEEDS_SRESET(1)) ex2_instr_latch(
      .nclk(nclk),
      .vd(vdd),
      .gd(gnd),
      .act(exx_act[1]),
      .force_t(func_sl_force),
      .d_mode(d_mode_dc),
      .delay_lclkr(delay_lclkr_dc),
      .mpw1_b(mpw1_dc_b),
      .mpw2_b(mpw2_dc_b),
      .thold_b(func_sl_thold_0_b),
      .sg(sg_0),
      .scin(siv[ex2_instr_offset:ex2_instr_offset + 15 - 1]),
      .scout(sov[ex2_instr_offset:ex2_instr_offset + 15 - 1]),
      .din(ex1_instr_q[6:20]),
      .dout(ex2_instr_q)
   );

   tri_rlmlatch_p #(.INIT(0), .NEEDS_SRESET(1)) ex2_gpr_we_latch(
      .nclk(nclk),
      .vd(vdd),
      .gd(gnd),
      .act(exx_act[1]),
      .force_t(func_sl_force),
      .d_mode(d_mode_dc),
      .delay_lclkr(delay_lclkr_dc),
      .mpw1_b(mpw1_dc_b),
      .mpw2_b(mpw2_dc_b),
      .thold_b(func_sl_thold_0_b),
      .sg(sg_0),
      .scin(siv[ex2_gpr_we_offset]),
      .scout(sov[ex2_gpr_we_offset]),
      .din(ex1_gpr_we),
      .dout(ex2_gpr_we_q)
   );

   tri_rlmlatch_p #(.INIT(0), .NEEDS_SRESET(1)) ex2_xer_we_latch(
      .nclk(nclk),
      .vd(vdd),
      .gd(gnd),
      .act(exx_act[1]),
      .force_t(func_sl_force),
      .d_mode(d_mode_dc),
      .delay_lclkr(delay_lclkr_dc),
      .mpw1_b(mpw1_dc_b),
      .mpw2_b(mpw2_dc_b),
      .thold_b(func_sl_thold_0_b),
      .sg(sg_0),
      .scin(siv[ex2_xer_we_offset]),
      .scout(sov[ex2_xer_we_offset]),
      .din(ex1_xer_we),
      .dout(ex2_xer_we_q)
   );

   tri_rlmlatch_p #(.INIT(0), .NEEDS_SRESET(1)) ex2_cr_we_latch(
      .nclk(nclk),
      .vd(vdd),
      .gd(gnd),
      .act(exx_act[1]),
      .force_t(func_sl_force),
      .d_mode(d_mode_dc),
      .delay_lclkr(delay_lclkr_dc),
      .mpw1_b(mpw1_dc_b),
      .mpw2_b(mpw2_dc_b),
      .thold_b(func_sl_thold_0_b),
      .sg(sg_0),
      .scin(siv[ex2_cr_we_offset]),
      .scout(sov[ex2_cr_we_offset]),
      .din(ex1_cr_we),
      .dout(ex2_cr_we_q)
   );

   tri_rlmreg_p #(.WIDTH(4), .INIT(0), .NEEDS_SRESET(1)) ex2_opsize_latch(
      .nclk(nclk),
      .vd(vdd),
      .gd(gnd),
      .act(exx_act[1]),
      .force_t(func_sl_force),
      .d_mode(d_mode_dc),
      .delay_lclkr(delay_lclkr_dc),
      .mpw1_b(mpw1_dc_b),
      .mpw2_b(mpw2_dc_b),
      .thold_b(func_sl_thold_0_b),
      .sg(sg_0),
      .scin(siv[ex2_opsize_offset:ex2_opsize_offset + 4 - 1]),
      .scout(sov[ex2_opsize_offset:ex2_opsize_offset + 4 - 1]),
      .din(ex1_opsize),
      .dout(ex2_opsize_q)
   );

   tri_rlmlatch_p #(.INIT(0), .NEEDS_SRESET(1)) ex2_is_lswx_latch(
      .nclk(nclk),
      .vd(vdd),
      .gd(gnd),
      .act(exx_act[1]),
      .force_t(func_sl_force),
      .d_mode(d_mode_dc),
      .delay_lclkr(delay_lclkr_dc),
      .mpw1_b(mpw1_dc_b),
      .mpw2_b(mpw2_dc_b),
      .thold_b(func_sl_thold_0_b),
      .sg(sg_0),
      .scin(siv[ex2_is_lswx_offset]),
      .scout(sov[ex2_is_lswx_offset]),
      .din(ex1_is_lswx),
      .dout(ex2_is_lswx_q)
   );

   tri_rlmlatch_p #(.INIT(0), .NEEDS_SRESET(1)) ex2_is_stswx_latch(
      .nclk(nclk),
      .vd(vdd),
      .gd(gnd),
      .act(exx_act[1]),
      .force_t(func_sl_force),
      .d_mode(d_mode_dc),
      .delay_lclkr(delay_lclkr_dc),
      .mpw1_b(mpw1_dc_b),
      .mpw2_b(mpw2_dc_b),
      .thold_b(func_sl_thold_0_b),
      .sg(sg_0),
      .scin(siv[ex2_is_stswx_offset]),
      .scout(sov[ex2_is_stswx_offset]),
      .din(ex1_is_stswx),
      .dout(ex2_is_stswx_q)
   );

   tri_rlmreg_p #(.WIDTH(`GPR_POOL_ENC), .INIT(0), .NEEDS_SRESET(1)) ex3_t1_p_latch(
      .nclk(nclk),
      .vd(vdd),
      .gd(gnd),
      .act(exx_act[2]),
      .force_t(func_sl_force),
      .d_mode(d_mode_dc),
      .delay_lclkr(delay_lclkr_dc),
      .mpw1_b(mpw1_dc_b),
      .mpw2_b(mpw2_dc_b),
      .thold_b(func_sl_thold_0_b),
      .sg(sg_0),
      .scin(siv[ex3_t1_p_offset:ex3_t1_p_offset + `GPR_POOL_ENC - 1]),
      .scout(sov[ex3_t1_p_offset:ex3_t1_p_offset + `GPR_POOL_ENC - 1]),
      .din(ex2_t1_p_q),
      .dout(ex3_t1_p_q)
   );

   tri_rlmreg_p #(.WIDTH(`XER_POOL_ENC), .INIT(0), .NEEDS_SRESET(1)) ex3_t2_p_latch(
      .nclk(nclk),
      .vd(vdd),
      .gd(gnd),
      .act(exx_act[2]),
      .force_t(func_sl_force),
      .d_mode(d_mode_dc),
      .delay_lclkr(delay_lclkr_dc),
      .mpw1_b(mpw1_dc_b),
      .mpw2_b(mpw2_dc_b),
      .thold_b(func_sl_thold_0_b),
      .sg(sg_0),
      .scin(siv[ex3_t2_p_offset :ex3_t2_p_offset + `XER_POOL_ENC- 1]),
      .scout(sov[ex3_t2_p_offset:ex3_t2_p_offset + `XER_POOL_ENC- 1]),
      .din(ex2_t2_p_q[xer_pool_l:`GPR_POOL_ENC-1]),
      .dout(ex3_t2_p_q)
   );

   tri_rlmreg_p #(.WIDTH(`CR_POOL_ENC), .INIT(0), .NEEDS_SRESET(1)) ex3_t3_p_latch(
      .nclk(nclk),
      .vd(vdd),
      .gd(gnd),
      .act(exx_act[2]),
      .force_t(func_sl_force),
      .d_mode(d_mode_dc),
      .delay_lclkr(delay_lclkr_dc),
      .mpw1_b(mpw1_dc_b),
      .mpw2_b(mpw2_dc_b),
      .thold_b(func_sl_thold_0_b),
      .sg(sg_0),
      .scin(siv[ex3_t3_p_offset :ex3_t3_p_offset + `CR_POOL_ENC- 1]),
      .scout(sov[ex3_t3_p_offset:ex3_t3_p_offset + `CR_POOL_ENC- 1]),
      .din(ex2_t3_p_q[cr_pool_l:`GPR_POOL_ENC-1]),
      .dout(ex3_t3_p_q)
   );

   tri_rlmreg_p #(.WIDTH(`ITAG_SIZE_ENC), .INIT(0), .NEEDS_SRESET(1)) ex3_itag_latch(
      .nclk(nclk),
      .vd(vdd),
      .gd(gnd),
      .act(exx_act[2]),
      .force_t(func_sl_force),
      .d_mode(d_mode_dc),
      .delay_lclkr(delay_lclkr_dc),
      .mpw1_b(mpw1_dc_b),
      .mpw2_b(mpw2_dc_b),
      .thold_b(func_sl_thold_0_b),
      .sg(sg_0),
      .scin(siv[ex3_itag_offset:ex3_itag_offset + `ITAG_SIZE_ENC - 1]),
      .scout(sov[ex3_itag_offset:ex3_itag_offset + `ITAG_SIZE_ENC - 1]),
      .din(ex2_itag_q),
      .dout(ex3_itag_q)
   );

   tri_rlmlatch_p #(.INIT(0), .NEEDS_SRESET(1)) ex3_gpr_we_latch(
      .nclk(nclk),
      .vd(vdd),
      .gd(gnd),
      .act(1'b1),
      .force_t(func_sl_force),
      .d_mode(d_mode_dc),
      .delay_lclkr(delay_lclkr_dc),
      .mpw1_b(mpw1_dc_b),
      .mpw2_b(mpw2_dc_b),
      .thold_b(func_sl_thold_0_b),
      .sg(sg_0),
      .scin(siv[ex3_gpr_we_offset]),
      .scout(sov[ex3_gpr_we_offset]),
      .din(ex2_gpr_we),
      .dout(ex3_gpr_we_q)
   );

   tri_rlmlatch_p #(.INIT(0), .NEEDS_SRESET(1)) ex3_xer_we_latch(
      .nclk(nclk),
      .vd(vdd),
      .gd(gnd),
      .act(1'b1),
      .force_t(func_sl_force),
      .d_mode(d_mode_dc),
      .delay_lclkr(delay_lclkr_dc),
      .mpw1_b(mpw1_dc_b),
      .mpw2_b(mpw2_dc_b),
      .thold_b(func_sl_thold_0_b),
      .sg(sg_0),
      .scin(siv[ex3_xer_we_offset]),
      .scout(sov[ex3_xer_we_offset]),
      .din(ex2_xer_we),
      .dout(ex3_xer_we_q)
   );

   tri_rlmlatch_p #(.INIT(0), .NEEDS_SRESET(1)) ex3_cr_we_latch(
      .nclk(nclk),
      .vd(vdd),
      .gd(gnd),
      .act(1'b1),
      .force_t(func_sl_force),
      .d_mode(d_mode_dc),
      .delay_lclkr(delay_lclkr_dc),
      .mpw1_b(mpw1_dc_b),
      .mpw2_b(mpw2_dc_b),
      .thold_b(func_sl_thold_0_b),
      .sg(sg_0),
      .scin(siv[ex3_cr_we_offset]),
      .scout(sov[ex3_cr_we_offset]),
      .din(ex2_cr_we),
      .dout(ex3_cr_we_q)
   );

   tri_rlmlatch_p #(.INIT(0), .NEEDS_SRESET(1)) ex3_illeg_lswx_latch(
      .nclk(nclk),
      .vd(vdd),
      .gd(gnd),
      .act(exx_act[2]),
      .force_t(func_sl_force),
      .d_mode(d_mode_dc),
      .delay_lclkr(delay_lclkr_dc),
      .mpw1_b(mpw1_dc_b),
      .mpw2_b(mpw2_dc_b),
      .thold_b(func_sl_thold_0_b),
      .sg(sg_0),
      .scin(siv[ex3_illeg_lswx_offset]),
      .scout(sov[ex3_illeg_lswx_offset]),
      .din(ex2_illeg_lswx),
      .dout(ex3_illeg_lswx_q)
   );

   tri_rlmlatch_p #(.INIT(0), .NEEDS_SRESET(1)) ex3_strg_noop_latch(
      .nclk(nclk),
      .vd(vdd),
      .gd(gnd),
      .act(exx_act[2]),
      .force_t(func_sl_force),
      .d_mode(d_mode_dc),
      .delay_lclkr(delay_lclkr_dc),
      .mpw1_b(mpw1_dc_b),
      .mpw2_b(mpw2_dc_b),
      .thold_b(func_sl_thold_0_b),
      .sg(sg_0),
      .scin(siv[ex3_strg_noop_offset]),
      .scout(sov[ex3_strg_noop_offset]),
      .din(ex2_strg_noop),
      .dout(ex3_strg_noop_q)
   );

   tri_rlmreg_p #(.WIDTH(`THREADS), .INIT(0), .NEEDS_SRESET(1)) cp_flush_latch(
      .nclk(nclk),
      .vd(vdd),
      .gd(gnd),
      .act(1'b1),
      .force_t(func_sl_force),
      .d_mode(d_mode_dc),
      .delay_lclkr(delay_lclkr_dc),
      .mpw1_b(mpw1_dc_b),
      .mpw2_b(mpw2_dc_b),
      .thold_b(func_sl_thold_0_b),
      .sg(sg_0),
      .scin(siv[cp_flush_offset:cp_flush_offset + `THREADS - 1]),
      .scout(sov[cp_flush_offset:cp_flush_offset + `THREADS - 1]),
      .din(cp_flush),
      .dout(cp_flush_q)
   );

   tri_rlmreg_p #(.WIDTH(`THREADS), .INIT(0), .NEEDS_SRESET(1)) ex0_val_latch(
      .nclk(nclk),
      .vd(vdd),
      .gd(gnd),
      .act(1'b1),
      .force_t(func_sl_force),
      .d_mode(d_mode_dc),
      .delay_lclkr(delay_lclkr_dc),
      .mpw1_b(mpw1_dc_b),
      .mpw2_b(mpw2_dc_b),
      .thold_b(func_sl_thold_0_b),
      .sg(sg_0),
      .scin(siv[ex0_val_offset:ex0_val_offset + `THREADS - 1]),
      .scout(sov[ex0_val_offset:ex0_val_offset + `THREADS - 1]),
      .din(rv2_val),
      .dout(ex0_val_q)
   );

   tri_rlmreg_p #(.WIDTH(`THREADS), .INIT(0), .NEEDS_SRESET(1)) ex1_val_latch(
      .nclk(nclk),
      .vd(vdd),
      .gd(gnd),
      .act(1'b1),
      .force_t(func_sl_force),
      .d_mode(d_mode_dc),
      .delay_lclkr(delay_lclkr_dc),
      .mpw1_b(mpw1_dc_b),
      .mpw2_b(mpw2_dc_b),
      .thold_b(func_sl_thold_0_b),
      .sg(sg_0),
      .scin(siv[ex1_val_offset:ex1_val_offset + `THREADS - 1]),
      .scout(sov[ex1_val_offset:ex1_val_offset + `THREADS - 1]),
      .din(ex0_val),
      .dout(ex1_val_q)
   );

   tri_rlmreg_p #(.WIDTH(`THREADS), .INIT(0), .NEEDS_SRESET(1)) ex2_val_latch(
      .nclk(nclk),
      .vd(vdd),
      .gd(gnd),
      .act(1'b1),
      .force_t(func_sl_force),
      .d_mode(d_mode_dc),
      .delay_lclkr(delay_lclkr_dc),
      .mpw1_b(mpw1_dc_b),
      .mpw2_b(mpw2_dc_b),
      .thold_b(func_sl_thold_0_b),
      .sg(sg_0),
      .scin(siv[ex2_val_offset:ex2_val_offset + `THREADS - 1]),
      .scout(sov[ex2_val_offset:ex2_val_offset + `THREADS - 1]),
      .din(ex1_val),
      .dout(ex2_val_q)
   );

   tri_rlmreg_p #(.WIDTH(`THREADS), .INIT(0), .NEEDS_SRESET(1)) ex3_val_latch(
      .nclk(nclk),
      .vd(vdd),
      .gd(gnd),
      .act(1'b1),
      .force_t(func_sl_force),
      .d_mode(d_mode_dc),
      .delay_lclkr(delay_lclkr_dc),
      .mpw1_b(mpw1_dc_b),
      .mpw2_b(mpw2_dc_b),
      .thold_b(func_sl_thold_0_b),
      .sg(sg_0),
      .scin(siv[ex3_val_offset:ex3_val_offset + `THREADS - 1]),
      .scout(sov[ex3_val_offset:ex3_val_offset + `THREADS - 1]),
      .din(ex2_val),
      .dout(ex3_val_q)
   );

   tri_rlmreg_p #(.WIDTH(`THREADS), .INIT(0), .NEEDS_SRESET(1)) ex2_stq_val_latch(
      .nclk(nclk),
      .vd(vdd),
      .gd(gnd),
      .act(1'b1),
      .force_t(func_sl_force),
      .d_mode(d_mode_dc),
      .delay_lclkr(delay_lclkr_dc),
      .mpw1_b(mpw1_dc_b),
      .mpw2_b(mpw2_dc_b),
      .thold_b(func_sl_thold_0_b),
      .sg(sg_0),
      .scin(siv[ex2_stq_val_offset:ex2_stq_val_offset + `THREADS - 1]),
      .scout(sov[ex2_stq_val_offset:ex2_stq_val_offset + `THREADS - 1]),
      .din(ex1_stq_val),
      .dout(ex2_stq_val_q)
   );

   tri_rlmlatch_p #(.INIT(0), .NEEDS_SRESET(1)) ex2_xer_val_latch(
      .nclk(nclk),
      .vd(vdd),
      .gd(gnd),
      .act(exx_act[1]),
      .force_t(func_sl_force),
      .d_mode(d_mode_dc),
      .delay_lclkr(delay_lclkr_dc),
      .mpw1_b(mpw1_dc_b),
      .mpw2_b(mpw2_dc_b),
      .thold_b(func_sl_thold_0_b),
      .sg(sg_0),
      .scin(siv[ex2_xer_val_offset]),
      .scout(sov[ex2_xer_val_offset]),
      .din(ex1_xer_val),
      .dout(ex2_xer_val_q)
   );

   tri_rlmreg_p #(.WIDTH(`THREADS), .INIT(0), .NEEDS_SRESET(1)) msr_cm_latch(
      .nclk(nclk),
      .vd(vdd),
      .gd(gnd),
      .act(1'b1),
      .force_t(func_sl_force),
      .d_mode(d_mode_dc),
      .delay_lclkr(delay_lclkr_dc),
      .mpw1_b(mpw1_dc_b),
      .mpw2_b(mpw2_dc_b),
      .thold_b(func_sl_thold_0_b),
      .sg(sg_0),
      .scin(siv[msr_cm_offset:msr_cm_offset + `THREADS - 1]),
      .scout(sov[msr_cm_offset:msr_cm_offset + `THREADS - 1]),
      .din(spr_msr_cm),
      .dout(msr_cm_q)
   );

   tri_rlmlatch_p #(.INIT(0), .NEEDS_SRESET(1)) ex3_ram_active_latch(
      .nclk(nclk),
      .vd(vdd),
      .gd(gnd),
      .act(1'b1),
      .force_t(func_sl_force),
      .d_mode(d_mode_dc),
      .delay_lclkr(delay_lclkr_dc),
      .mpw1_b(mpw1_dc_b),
      .mpw2_b(mpw2_dc_b),
      .thold_b(func_sl_thold_0_b),
      .sg(sg_0),
      .scin(siv[ex3_ram_active_offset]),
      .scout(sov[ex3_ram_active_offset]),
      .din(ex3_ram_active_d),
      .dout(ex3_ram_active_q)
   );

   tri_rlmreg_p #(.WIDTH(`GPR_WIDTH/8), .INIT(0), .NEEDS_SRESET(1)) ex2_dvc_mask_latch(
      .nclk(nclk),
      .vd(vdd),
      .gd(gnd),
      .act(exx_act[1]),
      .force_t(func_sl_force),
      .d_mode(d_mode_dc),
      .delay_lclkr(delay_lclkr_dc),
      .mpw1_b(mpw1_dc_b),
      .mpw2_b(mpw2_dc_b),
      .thold_b(func_sl_thold_0_b),
      .sg(sg_0),
      .scin(siv[ex2_dvc_mask_offset:ex2_dvc_mask_offset + `GPR_WIDTH/8-1]),
      .scout(sov[ex2_dvc_mask_offset:ex2_dvc_mask_offset + `GPR_WIDTH/8-1]),
      .din(ex1_dvc_mask[(64-`GPR_WIDTH)/8:7]),
      .dout(ex2_dvc_mask_q)
   );

   assign siv[0:scan_right-1] = {sov[1:scan_right-1], scan_in};
   assign scan_out = sov[0];

   assign unused = |{ex2_num_bytes_plus3[6:7], rv_xu1_ex0_t2_p[0:1], rv_xu1_ex0_t3_p[0]};

endmodule
