module control
	#(
		//Instruction Opcode 
            parameter INST_LUI    =    6'b001111,
            parameter INST_ADDU   =    6'b000000,
            parameter INST_ADDIU  =    6'b001001,
            parameter INST_SLT    =    6'b000000,
            parameter INST_SUBU   =    6'b000000,
            parameter INST_SLTU   =    6'b000000,
            parameter INST_AND    =    6'b000000,
            parameter INST_OR     =    6'b000000,
            parameter INST_XOR    =    6'b000000,
            parameter INST_NOR    =    6'b000000,
            parameter INST_SLL    =    6'b000000,
            parameter INST_SRL    =    6'b000000,
            parameter INST_SRA    =    6'b000000,
            parameter INST_LW     =    6'b100011,
            parameter INST_SW     =    6'b101011,
            parameter INST_BEQ    =    6'b000100,
            parameter INST_BNE    =    6'b000101,
            parameter INST_JR     =    6'b000000,
            parameter INST_JAL    =    6'b000011,
            parameter INST_ADD    =    6'b000000,
            parameter INST_ADDI   =    6'b001000,
            parameter INST_SUB    =    6'b000000,
            parameter INST_SLTI   =    6'b001010,
            parameter INST_SLTIU  =    6'b001011,
            parameter INST_ANDI   =    6'b001100,
            parameter INST_ORI    =    6'b001101,
            parameter INST_XORI   =    6'b001110,
            parameter INST_SLLV   =    6'b000000,
            parameter INST_SRAV   =    6'b000000,
            parameter INST_SRLV   =    6'b000000,
            parameter INST_DIV    =    6'b000000,
            parameter INST_DIVU   =    6'b000000,
            parameter INST_MULT   =    6'b000000,
            parameter INST_MULTU  =    6'b000000,
            parameter INST_MFHI   =    6'b000000,
            parameter INST_MFLO   =    6'b000000,
            parameter INST_MTHI   =    6'b000000,
            parameter INST_MTLO   =    6'b000000,

    
            //Rtype Instruction Function
            parameter FUNCTION_JR   = 6'b001000,
            parameter FUNCTION_ADDU = 6'b100001,
            parameter FUNCTION_SUBU = 6'b100011,
            parameter FUNCTION_SLT  = 6'b101010,
            parameter FUNCTION_SLTU = 6'b101011,
            parameter FUNCTION_AND  = 6'b100100,
            parameter FUNCTION_OR   = 6'b100101,
            parameter FUNCTION_XOR  = 6'b100110,
            parameter FUNCTION_NOR  = 6'b100111,
            parameter FUNCTION_SLL  = 6'b000000,
            parameter FUNCTION_SRL  = 6'b000010,
            parameter FUNCTION_SRA  = 6'b000011,
            parameter FUNCTION_ADD  = 6'b100000,
            parameter FUNCTION_SUB  = 6'b100010,
            parameter FUNCTION_SLLV = 6'b000100,
            parameter FUNCTION_SRAV = 6'b000111,
            parameter FUNCTION_SRLV = 6'b000110,
            parameter FUNCTION_DIV  = 6'b011010,
            parameter FUNCTION_DIVU = 6'b011011,
            parameter FUNCTION_MULT = 6'b011000,
            parameter FUNCTION_MULTU= 6'b011001,
            parameter FUNCTION_MFHI = 6'b010000,
            parameter FUNCTION_MFLO = 6'b010010,
            parameter FUNCTION_MTHI = 6'b010001,
            parameter FUNCTION_MTLO = 6'b010011

		)
	(
	input [5:0] opcode,
	input [5:0] Function,
	output [11:0] alu_control,
	output [3:0] PC_control,
	output [2:0] regdst_mux_control,
	output [3:0] regfile_wen,
	output memread,
	output memwrite,
	output [2:0] alusrc1_mux_control,
	output [3:0] alusrc2_mux_control,
	output [3:0] wbrf_mux_control,
	output [1:0] hi_lo_control,
    output [3:0] div_mul_control
	);

wire inst_addiu   = (opcode==INST_ADDIU   );
wire inst_lui     = (opcode==INST_LUI     );
wire inst_lw      = (opcode==INST_LW      );
wire inst_sw      = (opcode==INST_SW      );
wire inst_beq     = (opcode==INST_BEQ     );
wire inst_bne     = (opcode==INST_BNE     );
wire inst_jal     = (opcode==INST_JAL     );
wire inst_addi    = (opcode==INST_ADDI    );
wire inst_slti    = (opcode==INST_SLTI    );
wire inst_sltiu   = (opcode==INST_SLTIU   );
wire inst_andi    = (opcode==INST_ANDI    );
wire inst_ori     = (opcode==INST_ORI     );
wire inst_xori    = (opcode==INST_XORI    );


wire inst_addu    = (opcode==INST_ADDU    )&&(Function==FUNCTION_ADDU     );
wire inst_slt     = (opcode==INST_SLT     )&&(Function==FUNCTION_SLT      );
wire inst_subu    = (opcode==INST_SUBU    )&&(Function==FUNCTION_SUBU     );
wire inst_sltu    = (opcode==INST_SLTU    )&&(Function==FUNCTION_SLTU     );
wire inst_and     = (opcode==INST_AND     )&&(Function==FUNCTION_AND      );
wire inst_or      = (opcode==INST_OR      )&&(Function==FUNCTION_OR       );
wire inst_xor     = (opcode==INST_XOR     )&&(Function==FUNCTION_XOR      );
wire inst_nor     = (opcode==INST_NOR     )&&(Function==FUNCTION_NOR      );
wire inst_sll     = (opcode==INST_SLL     )&&(Function==FUNCTION_SLL      );
wire inst_srl     = (opcode==INST_SRL     )&&(Function==FUNCTION_SRL      );
wire inst_sra     = (opcode==INST_SRA     )&&(Function==FUNCTION_SRA      );
wire inst_jr      = (opcode==INST_JR      )&&(Function==FUNCTION_JR       );
wire inst_add     = (opcode==INST_ADD     )&&(Function==FUNCTION_ADD      );
wire inst_sub     = (opcode==INST_SUB     )&&(Function==FUNCTION_SUB      );
wire inst_sllv    = (opcode==INST_SLLV    )&&(Function==FUNCTION_SLLV     );
wire inst_srav    = (opcode==INST_SRAV    )&&(Function==FUNCTION_SRAV     );
wire inst_srlv    = (opcode==INST_SRLV    )&&(Function==FUNCTION_SRLV     );
wire inst_div     = (opcode==INST_DIV     )&&(Function==FUNCTION_DIV      );
wire inst_divu    = (opcode==INST_DIVU    )&&(Function==FUNCTION_DIVU     );
wire inst_mult    = (opcode==INST_MULT    )&&(Function==FUNCTION_MULT     );
wire inst_multu   = (opcode==INST_MULTU   )&&(Function==FUNCTION_MULTU    );
wire inst_mfhi    = (opcode==INST_MFHI    )&&(Function==FUNCTION_MFHI     );
wire inst_mflo    = (opcode==INST_MFLO    )&&(Function==FUNCTION_MFLO     );
wire inst_mthi    = (opcode==INST_MTHI    )&&(Function==FUNCTION_MTHI     );
wire inst_mtlo    = (opcode==INST_MTLO    )&&(Function==FUNCTION_MTLO     );

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
assign alu_control[11] =  inst_addu | inst_addiu | inst_addi | inst_add | inst_lw | inst_sw | inst_jal  ;

//div_mul_control
assign div_mul_control[0] = inst_div  ;
assign div_mul_control[1] = inst_divu ;
assign div_mul_control[2] = inst_mult ;
assign div_mul_control[3] = inst_multu;

//regdst_mux control
assign regdst_mux_control[0] = inst_lui  | inst_addiu | inst_lw   | inst_sw   | inst_beq  | inst_bne 
                             | inst_addi | inst_slti  | inst_sltiu| inst_andi | inst_ori  | inst_xori;

assign regdst_mux_control[1] = inst_addu | inst_slt   | inst_subu | inst_sltu | inst_and  | inst_or  
                             | inst_xor  | inst_nor   | inst_sll  | inst_srl  | inst_sra  | inst_jr  
                             | inst_add  | inst_sub   | inst_sllv | inst_srav | inst_srlv | inst_mflo
                             | inst_mfhi  ;

assign regdst_mux_control[2] = inst_jal                                                              ;


//alusrc_mux control
//alusrc1_mux

assign alusrc1_mux_control[0] =   inst_or    | inst_nor  | inst_and | inst_sltu | inst_slt | inst_subu 
                                | inst_addu  | inst_jr   | inst_xor | inst_lui  | inst_bne | inst_beq 
                                | inst_addiu | inst_lw   | inst_sw  | inst_add  | inst_sub | inst_addi  
                                | inst_slti  | inst_sltiu| inst_andi| inst_ori  | inst_xori| inst_sllv
                                | inst_srav  | inst_srlv | inst_div | inst_divu | inst_mult| inst_multu;

assign alusrc1_mux_control[1] =   inst_jal                                                             ;

assign alusrc1_mux_control[2] =   inst_sll   | inst_srl | inst_sra                                     ;
            
//alusrc2_mux
assign alusrc2_mux_control[0] =   inst_addu  | inst_slt   | inst_subu | inst_sltu | inst_and  | inst_or  | inst_xor  
                                | inst_nor   | inst_sll   | inst_srl  | inst_sra  | inst_jr   | inst_bne | inst_beq  
                                | inst_add   | inst_sub   | inst_sllv | inst_srlv | inst_srav | inst_div | inst_divu 
                                | inst_mult  | inst_multu;


assign alusrc2_mux_control[1] =   inst_lui   | inst_addiu | inst_lw   | inst_sw   | inst_addi | inst_slti| inst_sltiu    ;
                               

assign alusrc2_mux_control[2] =   inst_jal                                                                           ;

assign alusrc2_mux_control[3] =   inst_andi  | inst_ori | inst_xori ;
//li ho control
assign hi_lo_control[0] = inst_mthi;
assign hi_lo_control[1] = inst_mtlo;
//memwrite & memread control
assign memread  = inst_lw ;
assign memwrite = inst_sw ;

//wb_rf_mux control
assign wbrf_mux_control[0] =    inst_lui  | inst_addiu | inst_jal  | inst_sw  | inst_addu | inst_slt  | inst_subu | inst_sltu 
                              | inst_and  | inst_or    | inst_xor  | inst_nor | inst_sll  | inst_srl  | inst_sra  | inst_jr  
                              | inst_add  | inst_addi  | inst_sub  | inst_slti| inst_sltiu| inst_andi | inst_ori  | inst_xori 
                              | inst_sllv | inst_srav  | inst_srlv ;

assign wbrf_mux_control[1] =    inst_lw			                                                                             ;				

assign wbrf_mux_control[2] =    inst_mflo;

assign wbrf_mux_control[3] =    inst_mfhi;

//regfile_wen control
wire regwrite;
assign regwrite =  inst_lui  | inst_addiu | inst_jal  |  inst_lw    | inst_addu | inst_slt | inst_subu | inst_sltu 
                 | inst_and  | inst_or    | inst_xor  |  inst_nor   | inst_sll  | inst_srl | inst_sra  | inst_add  
                 | inst_addi | inst_sub   | inst_slti | inst_sltiu  | inst_andi | inst_ori | inst_xori | inst_sllv 
                 | inst_srav | inst_srlv  | inst_mflo | inst_mfhi ;
assign regfile_wen = {4{regwrite}};

//branch jump control
assign PC_control[0] = inst_beq;
assign PC_control[1] = inst_bne;
assign PC_control[2] = inst_jal;
assign PC_control[3] = inst_jr ;

endmodule