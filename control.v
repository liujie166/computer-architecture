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
            parameter FUNCTION_SRA  = 6'b000011
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
	output [2:0] alusrc2_mux_control,
	output [1:0] wbrf_mux_control
	);

wire inst_addiu   = (opcode==INST_ADDIU   );
wire inst_lui     = (opcode==INST_LUI     );
wire inst_lw      = (opcode==INST_LW      );
wire inst_sw      = (opcode==INST_SW      );
wire inst_beq     = (opcode==INST_BEQ     );
wire inst_bne     = (opcode==INST_BNE     );
wire inst_jal     = (opcode==INST_JAL     );

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


//alu control 
assign alu_control[0]  =  inst_lui                                              ;
assign alu_control[1]  =  inst_sra                                              ;
assign alu_control[2]  =  inst_srl                                              ;
assign alu_control[3]  =  inst_sll                                              ;
assign alu_control[4]  =  inst_xor                                              ;
assign alu_control[5]  =  inst_or                                               ;
assign alu_control[6]  =  inst_nor                                              ;
assign alu_control[7]  =  inst_and                                              ;
assign alu_control[8]  =  inst_sltu                                             ; 
assign alu_control[9]  =  inst_slt                                              ;
assign alu_control[10] =  inst_subu                                             ;
assign alu_control[11] =  inst_addu | inst_addiu | inst_lw | inst_sw | inst_jal ;

//regdst_mux control
assign regdst_mux_control[0] = inst_lui  | inst_addiu | inst_lw   | inst_sw   | inst_beq  | inst_bne ;

assign regdst_mux_control[1] = inst_addu | inst_slt   | inst_subu | inst_sltu | inst_and  | inst_or  
                             | inst_xor  | inst_nor   | inst_sll  | inst_srl  | inst_sra  | inst_jr  ;

assign regdst_mux_control[2] = inst_jal                                                              ;

//alusrc_mux control
//alusrc1_mux

assign alusrc1_mux_control[0] =   inst_or    | inst_nor | inst_and | inst_sltu | inst_slt | inst_subu 
                                | inst_addu  | inst_jr  | inst_xor | inst_lui  | inst_bne | inst_beq 
                                | inst_addiu | inst_lw  | inst_sw                                      ;

assign alusrc1_mux_control[1] =   inst_jal                                                             ;

assign alusrc1_mux_control[2] =   inst_sll   | inst_srl | inst_sra                                     ;
            
//alusrc2_mux
assign alusrc2_mux_control[0] =   inst_addu  | inst_slt   | inst_subu | inst_sltu | inst_and  | inst_or  | inst_xor  
                                | inst_nor   | inst_sll   | inst_srl  | inst_sra  | inst_jr   | inst_bne | inst_beq  ;

assign alusrc2_mux_control[1] =   inst_lui   | inst_addiu | inst_lw   | inst_sw                                      ;
                               

assign alusrc2_mux_control[2] =   inst_jal                                                                           ;

//memwrite & memread control
assign memread  = inst_lw ;
assign memwrite = inst_sw ;

//wb_rf_mux control
assign wbrf_mux_control[0] =    inst_lui  | inst_addiu | inst_jal  | inst_sw  | inst_addu | inst_slt  | inst_subu | inst_sltu 
                              | inst_and  | inst_or    | inst_xor  | inst_nor | inst_sll  | inst_srl  | inst_sra  | inst_jr  ;

assign wbrf_mux_control[1] =    inst_lw			                                                                             ;				



//regfile_wen control
wire regwrite;
assign regwrite =  inst_lui  | inst_addiu | inst_jal  |  inst_lw    | inst_addu | inst_slt | inst_subu | inst_sltu 
                 | inst_and  | inst_or    | inst_xor  |  inst_nor   | inst_sll  | inst_srl | inst_sra  ;
assign regfile_wen = {4{regwrite}};

//branch jump control
assign PC_control[0] = inst_beq;
assign PC_control[1] = inst_bne;
assign PC_control[2] = inst_jal;
assign PC_control[3] = inst_jr ;

endmodule