module control(
    input  [31:0] inst,
	output [11:0] alu_control,
	output [7:0] PC_control,
	output [2:0] regdst_mux_control,
	output [3:0] regfile_wen,
	output memread,
	output memwrite,
    output [6:0] memdata_control,
	output [1:0] alusrc1_mux_control,
	output [2:0] alusrc2_mux_control,
	output [4:0] wbrf_mux_control,
	output [1:0] hi_lo_control,
    output [3:0] div_mul_control
	);

wire inst_slti    = (inst[31:26]==6'b001010    );
wire inst_sltiu   = (inst[31:26]==6'b001011    );
wire inst_addi    = (inst[31:26]==6'b001000    );
wire inst_addiu   = (inst[31:26]==6'b001001    );
wire inst_andi    = (inst[31:26]==6'b001100    );
wire inst_ori     = (inst[31:26]==6'b001101    );
wire inst_xori    = (inst[31:26]==6'b001110    );
wire inst_lw      = (inst[31:26]==6'b100011    );
wire inst_sw      = (inst[31:26]==6'b101011    );
wire inst_lb      = (inst[31:26]==6'b100000    );
wire inst_lbu     = (inst[31:26]==6'b100100    );
wire inst_lh      = (inst[31:26]==6'b100001    );
wire inst_lhu     = (inst[31:26]==6'b100101    );
wire inst_lwl     = (inst[31:26]==6'b100010    );
wire inst_lwr     = (inst[31:26]==6'b100110    );
wire inst_sb      = (inst[31:26]==6'b101000    );
wire inst_sh      = (inst[31:26]==6'b101001    );
wire inst_swl     = (inst[31:26]==6'b101010    );
wire inst_swr     = (inst[31:26]==6'b101110    );

wire inst_jal     = (inst[31:26]==6'b000011    );
wire inst_j       = (inst[31:26]==6'b000010    );

wire inst_beq     = (inst[31:26]==6'b000100    );
wire inst_bne     = (inst[31:26]==6'b000101    );
wire inst_bgez    = (inst[31:26]==6'b000001    )&&(inst[20:16]==5'b00001);
wire inst_bgtz    = (inst[31:26]==6'b000111    )&&(inst[20:16]==5'b00000);
wire inst_blez    = (inst[31:26]==6'b000110    )&&(inst[20:16]==5'b00000);
wire inst_bltz    = (inst[31:26]==6'b000001    )&&(inst[20:16]==5'b00000);
wire inst_bgezal  = (inst[31:26]==6'b000001    )&&(inst[20:16]==5'b10001);
wire inst_bltzal  = (inst[31:26]==6'b000001    )&&(inst[20:16]==5'b10000);


wire inst_lui     = (inst[31:26]==6'b001111    )&&(inst[25:21]==5'b00000);

wire inst_sll     = (inst[31:26]==6'b000000    )&&(inst[25:21]==5'b00000)&&(inst[5:0]== 6'b000000    );
wire inst_srl     = (inst[31:26]==6'b000000    )&&(inst[25:21]==5'b00000)&&(inst[5:0]== 6'b000010    );
wire inst_sra     = (inst[31:26]==6'b000000    )&&(inst[25:21]==5'b00000)&&(inst[5:0]== 6'b000011    );
wire inst_addu    = (inst[31:26]==6'b000000    )&&(inst[10:6]==5'b00000)&&(inst[5:0]== 6'b100001    );
wire inst_slt     = (inst[31:26]==6'b000000    )&&(inst[10:6]==5'b00000)&&(inst[5:0]== 6'b101010    );
wire inst_subu    = (inst[31:26]==6'b000000    )&&(inst[10:6]==5'b00000)&&(inst[5:0]== 6'b100011    );
wire inst_sltu    = (inst[31:26]==6'b000000    )&&(inst[10:6]==5'b00000)&&(inst[5:0]== 6'b101011    );
wire inst_and     = (inst[31:26]==6'b000000    )&&(inst[10:6]==5'b00000)&&(inst[5:0]== 6'b100100    );
wire inst_or      = (inst[31:26]==6'b000000    )&&(inst[10:6]==5'b00000)&&(inst[5:0]== 6'b100101    );
wire inst_xor     = (inst[31:26]==6'b000000    )&&(inst[10:6]==5'b00000)&&(inst[5:0]== 6'b100110    );
wire inst_nor     = (inst[31:26]==6'b000000    )&&(inst[10:6]==5'b00000)&&(inst[5:0]== 6'b100111    );
wire inst_add     = (inst[31:26]==6'b000000    )&&(inst[10:6]==5'b00000)&&(inst[5:0]== 6'b100000    );
wire inst_sub     = (inst[31:26]==6'b000000    )&&(inst[10:6]==5'b00000)&&(inst[5:0]== 6'b100010    );
wire inst_sllv    = (inst[31:26]==6'b000000    )&&(inst[10:6]==5'b00000)&&(inst[5:0]== 6'b000100    );
wire inst_srav    = (inst[31:26]==6'b000000    )&&(inst[10:6]==5'b00000)&&(inst[5:0]== 6'b000111    );
wire inst_srlv    = (inst[31:26]==6'b000000    )&&(inst[10:6]==5'b00000)&&(inst[5:0]== 6'b000110    );
wire inst_div     = (inst[31:26]==6'b000000    )&&(inst[15:6]==10'b0000000000)&&(inst[5:0]== 6'b011010    );
wire inst_divu    = (inst[31:26]==6'b000000    )&&(inst[15:6]==10'b0000000000)&&(inst[5:0]== 6'b011011    );
wire inst_mult    = (inst[31:26]==6'b000000    )&&(inst[15:6]==10'b0000000000)&&(inst[5:0]== 6'b011000    );
wire inst_multu   = (inst[31:26]==6'b000000    )&&(inst[15:6]==10'b0000000000)&&(inst[5:0]== 6'b011001    );
wire inst_mfhi    = (inst[31:26]==6'b000000    )&&(inst[25:16]==10'b0000000000)&&(inst[10:6]==5'b00000)&&(inst[5:0]== 6'b010000    );
wire inst_mflo    = (inst[31:26]==6'b000000    )&&(inst[25:16]==10'b0000000000)&&(inst[10:6]==5'b00000)&&(inst[5:0]== 6'b010010    );
wire inst_mthi    = (inst[31:26]==6'b000000    )&&(inst[20:6]==15'b000000000000000)&&(inst[5:0]== 6'b010001    );
wire inst_mtlo    = (inst[31:26]==6'b000000    )&&(inst[20:6]==15'b000000000000000)&&(inst[5:0]== 6'b010011    );
wire inst_jr      = (inst[31:26]==6'b000000    )&&(inst[20:6]==15'b000000000000000)&&(inst[5:0]== 6'b001000    );
wire inst_jalr    = (inst[31:26]==6'b000000    )&&(inst[20:16]==5'b00000)&&(inst[10:6]==5'b00000)&&(inst[5:0]== 6'b001001    );
//alu control 
assign alu_control[0]  =  inst_lui                                                                      ;
assign alu_control[1]  =  inst_sra  | inst_srav                                                         ;
assign alu_control[2]  =  inst_srl  | inst_srlv                                                         ;
assign alu_control[3]  =  inst_sll  | inst_sllv                                                         ;
assign alu_control[4]  =  inst_xor  | inst_xori                                                         ;
assign alu_control[5]  =  inst_or   | inst_ori                                                          ;
assign alu_control[6]  =  inst_nor                                                                      ;
assign alu_control[7]  =  inst_and  | inst_andi                                                         ;
assign alu_control[8]  =  inst_sltu | inst_sltiu                                                        ; 
assign alu_control[9]  =  inst_slt  | inst_slti                                                         ;
assign alu_control[10] =  inst_subu | inst_sub                                                          ;
assign alu_control[11] =  inst_addu | inst_addiu | inst_addi | inst_add | inst_lw | inst_sw | inst_sb 
                         |inst_lb   | inst_lbu   | inst_lh   | inst_lhu | inst_lwl| inst_lwr| inst_sh   
                         |inst_swl  | inst_swr  ;

//div_mul_control
assign div_mul_control[0] = inst_div  ;
assign div_mul_control[1] = inst_divu ;
assign div_mul_control[2] = inst_mult ;
assign div_mul_control[3] = inst_multu;

//regdst_mux control
assign regdst_mux_control[0] = inst_lui  | inst_addiu | inst_lw   | inst_sw   | inst_beq  | inst_bne 
                             | inst_addi | inst_slti  | inst_sltiu| inst_andi | inst_ori  | inst_xori
                             | inst_lb   | inst_lbu   | inst_lh   | inst_lhu  | inst_lwl  | inst_lwr;

assign regdst_mux_control[1] = inst_addu | inst_slt   | inst_subu | inst_sltu | inst_and  | inst_or  
                             | inst_xor  | inst_nor   | inst_sll  | inst_srl  | inst_sra  | inst_jr  
                             | inst_add  | inst_sub   | inst_sllv | inst_srav | inst_srlv | inst_mflo
                             | inst_mfhi | inst_jalr ;

assign regdst_mux_control[2] = inst_jal | inst_bltzal | inst_bgezal;


//alusrc_mux control
//alusrc1_mux

assign alusrc1_mux_control[0] =   inst_or    | inst_nor  | inst_and   | inst_sltu   | inst_slt | inst_subu 
                                | inst_addu  | inst_jr   | inst_xor   | inst_lui    | inst_bne | inst_beq 
                                | inst_addiu | inst_lw   | inst_sw    | inst_add    | inst_sub | inst_addi  
                                | inst_slti  | inst_sltiu| inst_andi  | inst_ori    | inst_xori| inst_sllv
                                | inst_srav  | inst_srlv | inst_div   | inst_divu   | inst_mult| inst_multu
                                | inst_lb    | inst_lbu  | inst_lh    | inst_lhu    | inst_lwl | inst_lwr
                                | inst_sb    | inst_sh   | inst_swl   | inst_swr    | inst_bgez| inst_bgtz
                                | inst_blez  | inst_bltz | inst_bltzal| inst_bgezal | inst_jalr;



assign alusrc1_mux_control[1] =   inst_sll   | inst_srl | inst_sra ;
            
//alusrc2_mux
assign alusrc2_mux_control[0] =   inst_addu  | inst_slt   | inst_subu | inst_sltu | inst_and  | inst_or  | inst_xor  
                                | inst_nor   | inst_sll   | inst_srl  | inst_sra  | inst_jr   | inst_bne | inst_beq  
                                | inst_add   | inst_sub   | inst_sllv | inst_srlv | inst_srav | inst_div | inst_divu 
                                | inst_mult  | inst_multu;


assign alusrc2_mux_control[1] =   inst_lui   | inst_addiu | inst_lw   | inst_sw   | inst_addi | inst_slti| inst_sltiu 
                                | inst_lb    | inst_lbu   | inst_lh   | inst_lhu  | inst_lwl  | inst_lwr | inst_sb    
                                | inst_sh    | inst_swl   | inst_swr;
                               



assign alusrc2_mux_control[2] =   inst_andi  | inst_ori | inst_xori ;
//li ho control
assign hi_lo_control[0] = inst_mthi;
assign hi_lo_control[1] = inst_mtlo;
//memwrite & memread control
assign memread  = inst_lw | inst_lb | inst_lbu | inst_lh  | inst_lhu | inst_lwl | inst_lwr ;
assign memwrite = inst_sw | inst_sb | inst_sh  | inst_swl | inst_swr;
//memdata_control
assign memdata_control[0] = inst_lw | inst_sw;
assign memdata_control[1] = inst_lb | inst_sb;
assign memdata_control[2] = inst_lbu;
assign memdata_control[3] = inst_lh | inst_sh;
assign memdata_control[4] = inst_lhu;
assign memdata_control[5] = inst_lwl| inst_swl;
assign memdata_control[6] = inst_lwr| inst_swr;
//wb_rf_mux control
assign wbrf_mux_control[0] =    inst_lui   | inst_addiu | inst_sw   | inst_addu | inst_slt  | inst_subu | inst_sltu | inst_jr 
                              | inst_and   | inst_or    | inst_xor  | inst_nor  | inst_sll  | inst_srl  | inst_sra  | inst_xori 
                              | inst_add   | inst_addi  | inst_sub  | inst_slti | inst_sltiu| inst_andi | inst_ori  | inst_swr 
                              | inst_sllv  | inst_srav  | inst_srlv | inst_sb   | inst_sh   | inst_swl  ;

assign wbrf_mux_control[1] =    inst_lw	  | inst_lb    | inst_lbu  | inst_lh  | inst_lhu  | inst_lwl  | inst_lwr;				

assign wbrf_mux_control[2] =    inst_mflo;

assign wbrf_mux_control[3] =    inst_mfhi;

assign wbrf_mux_control[4] =    inst_jal | inst_jalr | inst_bgezal| inst_bltzal;
//regfile_wen control
wire regwrite;
assign regwrite =  inst_lui  | inst_addiu | inst_jal  |  inst_lw    | inst_addu | inst_slt | inst_subu | inst_sltu 
                 | inst_and  | inst_or    | inst_xor  |  inst_nor   | inst_sll  | inst_srl | inst_sra  | inst_add  
                 | inst_addi | inst_sub   | inst_slti | inst_sltiu  | inst_andi | inst_ori | inst_xori | inst_sllv 
                 | inst_srav | inst_srlv  | inst_mflo | inst_mfhi   | inst_jalr | inst_lb  | inst_lbu  | inst_lh   
                 | inst_lhu  | inst_lwl   | inst_lwr  | inst_bltzal | inst_bgezal;
assign regfile_wen = {4{regwrite}};

//branch jump control
assign PC_control[0] = inst_beq;
assign PC_control[1] = inst_bne;
assign PC_control[2] = inst_jal | inst_j;
assign PC_control[3] = inst_jr  | inst_jalr;
assign PC_control[4] = inst_bgez| inst_bgezal;
assign PC_control[5] = inst_bltz| inst_bltzal;
assign PC_control[6] = inst_bgtz;
assign PC_control[7] = inst_blez;

endmodule