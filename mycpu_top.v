module mycpu_top(
	input clk, 
	input resetn, 
	output inst_sram_en,  
	output [3:0] inst_sram_wen,  
	output [31:0] inst_sram_addr, 
	output [31:0] inst_sram_wdata,  
	input [31:0] inst_sram_rdata, 

	output data_sram_en, 
	output [3:0] data_sram_wen, 
	output [31:0]data_sram_addr, 
	output [31:0]data_sram_wdata,
	input [31:0]data_sram_rdata,

    output [31:0]debug_wb_pc, 
	output [3:0]debug_wb_rf_wen,
	output [4:0]debug_wb_rf_wnum, 
	output [31:0]debug_wb_rf_wdata 
);

//alu signal
wire [31:0] alusrc1_mux;
wire [31:0] alusrc2_mux;
wire [31:0] aluresult;
	
//regfile
wire [4:0] regdst_mux;
wire [31:0] wbrf_mux;
wire [31:0] regtoalu1;
wire [31:0] regtoalu2;

//control output
wire [11:0] alu_control;
wire [2:0] regdst_mux_control;
wire [3:0] PC_control;
wire [1:0] wbrf_mux_control;
wire [3:0] regwrite;
wire [2:0] alusrc1_mux_control;
wire [2:0] alusrc2_mux_control;
wire memwrite;
wire memread;
    


// IF
reg [31:0] PC;
reg [31:0] PCD;
wire [31:0] IR;
wire [31:0] PCnext;
wire [31:0] PCbranch,PCjump;
wire [31:0] PCplus4;
wire [31:0] PCbranch_jump;
wire [31:0] signextend;
wire zero;
assign zero = (regtoalu1==regtoalu2)?1:0;

assign PCplus4 = PCD+32'd4;    
assign PCbranch_jump=({32{PC_control[3]}} & regtoalu1)//jr
   |({32{PC_control[2]}} & PCjump   )//jal
   |({32{PC_control[1]&(~zero)}} & PCbranch)//bne
   |({32{PC_control[0]&zero}} & PCbranch);//beq
assign PCnext=(PC_control[3]|PC_control[2]|(PC_control[1]&(~zero))|(PC_control[0]&zero))?PCbranch_jump:(PC+32'd4);
assign PCbranch= PCplus4+(signextend<<2);
assign PCjump = {PC[31:28],IR[25:0],2'b00};

assign IR= inst_sram_rdata;
assign signextend=(IR[15]==0)?{16'h0000,IR[15:0]}:{16'hffff,IR[15:0]};

always @(posedge clk) begin
    if (!resetn) begin
        PC<=32'hbfc00000;
    end
    else begin
            PC <= PCnext;
    end
end

always @(posedge clk) begin
    PCD<=PC;
end

// ID
reg [31:0] PCE;
reg [11:0] aluopE;
reg [4:0] destE;
reg  [1:0] wbrfE;
reg  [3:0] regwriteE;
reg memwriteE,memreadE;
reg [31:0] v1E,v2E;
reg [31:0] dataE;
always @(posedge clk) begin
    dataE<=regtoalu2;
    PCE<=PCD;
    v1E<=alusrc1_mux;
    v2E<=alusrc2_mux;
    //CONTROL
	aluopE<=alu_control;
    destE<=regdst_mux;
    wbrfE<=wbrf_mux_control;
    regwriteE<=regwrite;
    memwriteE<=memwrite;
    memreadE<=memread;
end


// EX
reg [31:0] PCM;
reg [31:0] resM;
reg [31:0] v2M;
reg [4:0] destM;
reg [1:0] wbrfM;
reg memwriteM;
reg memreadM;
reg [3:0] regwriteM;
reg [31:0] dataM;
always @(posedge clk) begin
    memreadM<=memreadE;
    dataM<=dataE;
    PCM<=PCE;
    resM<=aluresult;
    v2M<=v2E;
    destM<=destE;
    wbrfM<=wbrfE;
    memwriteM<=memwriteE;
    regwriteM<=regwriteE;
end

// MEM
reg [31:0] PCW;
wire [31:0] readdata;
reg [31:0] resW;
reg [4:0] destW;
reg [3:0] regwriteW;
reg [1:0] wbrfW;
assign readdata=data_sram_rdata;
always @(posedge clk) begin
    wbrfW<=wbrfM;
    PCW<=PCM;
    resW<=resM;
    destW<=destM;
    regwriteW<=regwriteM;
end

//regfiles
assign wbrf_mux=({32{wbrfW[1]}} & readdata)
               |({32{wbrfW[0]}} & resW    );

assign regdst_mux=({5{regdst_mux_control[0]}} & IR[20:16] )
				 |({5{regdst_mux_control[1]}} & IR[15:11] )
				 |({5{regdst_mux_control[2]}} & 5'h1f     );
reg_file 
    regfile(.clk(clk),.wen(regwriteW),.waddr(destW),.raddr1(IR[25:21]),.raddr2(IR[20:16]),.wdata(wbrf_mux),.rdata1(regtoalu1),.rdata2(regtoalu2));

//alu

assign alusrc2_mux = ({32{alusrc2_mux_control[0]}} & regtoalu2 )
                    |({32{alusrc2_mux_control[1]}} & signextend)
                    |({32{alusrc2_mux_control[2]}} & PCD       );

assign alusrc1_mux = ({32{alusrc1_mux_control[0]}} & regtoalu1 )
                    |({32{alusrc1_mux_control[1]}} & 32'd8     )
                    |({32{alusrc1_mux_control[2]}} & IR        );
simple_alu
    ALU(.alu_src1(v1E),.alu_src2(v2E),.alu_result(aluresult),.alu_control(aluopE));

//output signal       
assign inst_sram_wen = 4'b0;
assign inst_sram_wdata = 32'b0;
assign inst_sram_addr = PC ;
assign inst_sram_en = resetn;

assign data_sram_addr = resM;
assign data_sram_wdata= dataM;
assign data_sram_wen = {4{memwriteM}};
assign data_sram_en = memwriteM|memreadM;
	
assign debug_wb_pc = PCW;
assign debug_wb_rf_wdata = wbrf_mux;
assign debug_wb_rf_wnum = destW;
assign debug_wb_rf_wen = regwriteW;

//Control
control
    control(.opcode(IR[31:26]),
    	    .Function(IR[5:0]),
			.alu_control(alu_control),
			.PC_control(PC_control),
			.regdst_mux_control(regdst_mux_control),
			.regfile_wen(regwrite),
			.memread(memread),
			.memwrite(memwrite),
			.alusrc1_mux_control(alusrc1_mux_control),
			.alusrc2_mux_control(alusrc2_mux_control),
			.wbrf_mux_control(wbrf_mux_control));
endmodule