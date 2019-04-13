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

wire [31:0] v1E_mux;
wire [31:0] v2E_mux;	
//regfile
wire [4:0] regdst_mux;
wire [31:0] wbrf_mux;
wire [31:0] regtoalu1;
wire [31:0] regtoalu2;

//control output
wire [11:0] alu_control;
wire [2:0] regdst_mux_control;
wire [3:0] PC_control;
wire [3:0] wbrf_mux_control;
wire [1:0] hi_lo_control;
wire [3:0] regwrite;
wire [2:0] alusrc1_mux_control;
wire [3:0] alusrc2_mux_control;
wire [3:0] div_mul_control;
wire memwrite;
wire memread;

wire stall;
reg wait_div;
wire set_zero = ~(stall|wait_div);
wire [1:0] hi_lo_control2= ({2{set_zero}}&hi_lo_control);
wire [4:0] regdst_mux2 = ({5{set_zero}}&regdst_mux);
wire [3:0] wbrf_mux_control2 = ({4{set_zero}}&wbrf_mux_control);
wire [3:0] regwrite2 = ({4{set_zero}}&regwrite);
wire [3:0] div_mul_control2 = ({4{set_zero}}&div_mul_control);
wire memwrite2 = (~stall)&memwrite;
wire memread2 = (~stall)&memread;

// IF
reg [31:0] PC;
reg [31:0] PCD;
reg [31:0] IR;
wire [31:0] PCnext;
wire [31:0] PCbranch,PCjump;
wire [31:0] PCplus4;
wire [31:0] PCbranch_jump;
wire zero;
assign zero = (v1E_mux==v2E_mux);

wire [31:0] signextend;
assign signextend=(IR[15]==0)?{16'h0000,IR[15:0]}:{16'hffff,IR[15:0]};


wire [31:0] zeroextend;
assign zeroextend = {16'h0000,IR[15:0]};



reg [31:0] HI;
reg [31:0] LO;
wire [63:0] div_result;
wire complete;
wire div;


assign PCplus4 = PCD+32'd4;    
assign PCbranch_jump=({32{PC_control[3]}} & v1E_mux)//jr
   |({32{PC_control[2]}} & PCjump   )//jal
   |({32{PC_control[1]&(~zero)}} & PCbranch)//bne
   |({32{PC_control[0]&zero}} & PCbranch);//beq
assign PCnext=(PC_control[3]|PC_control[2]|(PC_control[1]&(~zero))|(PC_control[0]&zero))?PCbranch_jump:(PC+32'd4);
assign PCbranch= PCplus4+(signextend<<2);
assign PCjump = {PC[31:28],IR[25:0],2'b00};


always @(posedge clk) begin
    if (~resetn) begin
        PC<=32'hbfc00000;
    end
    else if(~stall&&~wait_div) begin
            PC <= PCnext;
    end
end
//ID
always @(posedge clk) begin
    if(~resetn) begin
        IR<=32'd0;
    end
    else if(~stall&&~wait_div) begin
        IR<=inst_sram_rdata;
        PCD<=PC;
    end
end
// EX
reg [31:0] PCE;
reg [11:0] aluopE;
reg [4:0] destE;
reg  [3:0] wbrfE;
reg  [3:0] regwriteE;
reg memwriteE,memreadE;
reg [3:0] div_mulE;
reg [1:0] hiloE;
reg [31:0] v1E,v2E;
reg [31:0] rtE;
reg [31:0] rsE;
wire [31:0] rsE_mux;
wire [31:0] rtE_mux;
wire [3:0] rtE_mux_control;
wire [3:0] rsE_mux_control;

always @(posedge clk) begin
if(resetn&&~wait_div) begin
    rtE<=rtE_mux;
    rsE<=rsE_mux;
    PCE<=PCD;
    v1E<=v1E_mux;
    v2E<=v2E_mux;
    //CONTROL
    hiloE<=hi_lo_control2;
    div_mulE<=div_mul_control2;
	aluopE<=alu_control;
    destE<=regdst_mux2;
    wbrfE<=wbrf_mux_control2;
    regwriteE<=regwrite2;
    memwriteE<=memwrite2;
    memreadE<=memread2;
end
end

wire wait_divD = (div_mul_control[0]||div_mul_control[1])?(~complete):1'd0;
assign div = div_mulE[0]|div_mulE[1];
wire div_signed = div_mulE[0];
always @(posedge clk) begin
    if(~resetn)
       wait_div<=1'd0;
    else if(wait_divD)
       wait_div<=1'd1;
    else if(complete)
       wait_div<=1'd0;
end
div div1(.div_clk(clk),.resetn(resetn),.div(div),.div_signed(div_signed),.x(v1E),.y(v2E),.s(div_result[31:0]),.r(div_result[63:32]),.complete(complete));
wire mul_signed = div_mulE[2];
wire signed [63:0] mul_result;
mul mul1(.mul_clk(clk),.resetn(resetn),.mul_signed(mul_signed),.x(v1E),.y(v2E),.result(mul_result));
// MEM
reg [31:0] PCM;
reg [31:0] resM;
reg [31:0] v2M;
reg [4:0] destM;
reg [3:0] wbrfM;
reg [3:0] div_mulM;
reg memwriteM;
reg memreadM;
reg [3:0] regwriteM;
reg [31:0] rtM;
reg [31:0] rsM;
reg [1:0] hiloM;
wire hiloE2 = (~wait_div)&hiloE;
wire memreadE2 = (~wait_div)&memreadE;
wire [4:0] destE2 = {5{~wait_div}}&destE;
wire [3:0] wbrfE2 = {4{~wait_div}}&wbrfE;
wire memwriteE2 = (~wait_div)&memwriteE;
wire [3:0] regwriteE2 = {4{~wait_div}}&regwriteE;

wire [31:0] res_mux;
assign res_mux = ({32{wbrfE[3]}} & HI      )
               |({32{wbrfE[2]}}  & LO      )
               |({32{wbrfE[1]|wbrfE[0]}} & aluresult);
always @(posedge clk) begin
if(resetn) begin
    memreadM<=memreadE2;
    rtM<=rtE;
    rsM<=rsE;
    PCM<=PCE;
    resM<=res_mux;
    v2M<=v2E;
    destM<=destE2;
    wbrfM<=wbrfE2;
    div_mulM<=div_mulE;
    memwriteM<=memwriteE2;
    regwriteM<=regwriteE2;
    hiloM<=hiloE2;
end
end

always @(posedge clk) begin
    if (~resetn) begin
        HI<=32'd0;
        LO<=32'd0;
    end
    else if (div_mulE[0]==1'd1||div_mulE[1]==1'd1) begin
        HI<=div_result[63:32];
        LO<=div_result[31:0];
    end
    else if (div_mulM[2]==1'd1||div_mulM[3]==1'd1) begin
        HI<=mul_result[63:32];
        LO<=mul_result[31:0];
    end
    else if (hiloE[0]==1'd1)begin
        HI<=rsE;
    end
    else if (hiloE[1]==1'd1)begin
        LO<=rsE;
    end
end
// WB
reg [31:0] PCW;
wire [31:0] readdata;
reg [31:0] resW;
reg [4:0] destW;
reg [3:0] regwriteW;
reg [3:0] wbrfW;
assign readdata=data_sram_rdata;
always @(posedge clk) begin
if(resetn) begin
    wbrfW<=wbrfM;
    PCW<=PCM;
    resW<=resM;
    destW<=destM;
    regwriteW<=regwriteM;
end
end




//regfiles
assign wbrf_mux=({32{wbrfW[3]}} & HI      )
               |({32{wbrfW[2]}} & LO      )
               |({32{wbrfW[1]}} & readdata)
               |({32{wbrfW[0]}} & resW    );

assign regdst_mux=({5{regdst_mux_control[0]&~memwrite&~PC_control[0]&~PC_control[1]}} & IR[20:16] )
				 |({5{regdst_mux_control[1]&~PC_control[3]}} & IR[15:11] )
				 |({5{regdst_mux_control[2]}} & 5'h1f     );

reg_file regfile(.clk(clk),.wen(regwriteW),.waddr(destW),.raddr1(IR[25:21]),.raddr2(IR[20:16]),.wdata(wbrf_mux),.rdata1(regtoalu1),.rdata2(regtoalu2));

//alu
assign alusrc1_mux = ({32{alusrc1_mux_control[0]}} & regtoalu1 )
                    |({32{alusrc1_mux_control[1]}} & 32'd8     )
                    |({32{alusrc1_mux_control[2]}} & {6'd0,IR[31:6]});

assign alusrc2_mux = ({32{alusrc2_mux_control[0]}} & regtoalu2 )
                    |({32{alusrc2_mux_control[1]}} & signextend)
                    |({32{alusrc2_mux_control[2]}} & PCD       )
                    |({32{alusrc2_mux_control[3]}} & zeroextend);

wire [3:0] v1E_mux_control;
wire [3:0] v2E_mux_control;

assign v1E_mux = ({32{v1E_mux_control[0]}} & alusrc1_mux )
                |({32{v1E_mux_control[1]}} & res_mux   )
                |({32{v1E_mux_control[2]&~v1E_mux_control[1]}} & resM        )
                |({32{v1E_mux_control[3]&~v1E_mux_control[1]&~v1E_mux_control[2]}} & wbrf_mux    );

assign v2E_mux = ({32{v2E_mux_control[0]}} & alusrc2_mux )
                |({32{v2E_mux_control[1]}} & res_mux   )
                |({32{v2E_mux_control[2]&~v2E_mux_control[1]}} & resM        )
                |({32{v2E_mux_control[3]&~v2E_mux_control[1]&~v2E_mux_control[2]}} & wbrf_mux    );
                
assign rtE_mux =  ({32{rtE_mux_control[0]}} & regtoalu2   )
                   |({32{rtE_mux_control[1]}} & res_mux   )
                   |({32{rtE_mux_control[2]&~rtE_mux_control[1]}} & resM        )
                   |({32{rtE_mux_control[3]&~rtE_mux_control[1]&~rtE_mux_control[2]}} & wbrf_mux    );

assign rsE_mux =  ({32{rsE_mux_control[0]}} & regtoalu1   )
                   |({32{rsE_mux_control[1]}} & res_mux   )
                   |({32{rsE_mux_control[2]&~rsE_mux_control[1]}} & resM        )
                   |({32{rsE_mux_control[3]&~rsE_mux_control[1]&~rsE_mux_control[2]}} & wbrf_mux    );
wire rs_en = alusrc1_mux_control[0]| hi_lo_control[0]| hi_lo_control[1];
data_dep_control data_dep_control(
    .rs(IR[25:21]),
    .rt(IR[20:16]),
    .destE(destE), 
    .destM(destM),
    .destW(destW),
    .memreadE(memreadE),
    .memreadM(memreadM),
    .memwrite(memwrite),
    .stall(stall),
    .rs_en(rs_en),
    .rt_en(alusrc2_mux_control[0]),
    .v1E_mux_control(v1E_mux_control),
    .v2E_mux_control(v2E_mux_control),
    .rtE_mux_control(rtE_mux_control),
    .rsE_mux_control(rsE_mux_control)
    );            
simple_alu ALU(.alu_src1(v1E),.alu_src2(v2E),.alu_result(aluresult),.alu_control(aluopE));

//output signal       
assign inst_sram_wen = 4'b0;
assign inst_sram_wdata = 32'b0;
assign inst_sram_addr = (resetn==1'd0)?32'hbfc00000:PCnext;
assign inst_sram_en = (~stall)&(~wait_div);

assign data_sram_addr = resM;
assign data_sram_wdata= rtM;
assign data_sram_wen = {4{memwriteM}};
assign data_sram_en = memwriteM|memreadM;
	
assign debug_wb_pc = PCW;
assign debug_wb_rf_wdata = wbrf_mux;
assign debug_wb_rf_wnum = destW;
assign debug_wb_rf_wen = regwriteW;

//Control
control control(.opcode(IR[31:26]),
    	    .Function(IR[5:0]),
			.alu_control(alu_control),
			.PC_control(PC_control),
			.regdst_mux_control(regdst_mux_control),
			.regfile_wen(regwrite),
			.memread(memread),
			.memwrite(memwrite),
			.alusrc1_mux_control(alusrc1_mux_control),
			.alusrc2_mux_control(alusrc2_mux_control),
			.wbrf_mux_control(wbrf_mux_control),
			.hi_lo_control(hi_lo_control),
            .div_mul_control(div_mul_control));
endmodule