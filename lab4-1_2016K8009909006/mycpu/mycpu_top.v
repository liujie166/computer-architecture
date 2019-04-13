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
//cp0
wire [31:0] cp0_rdata;
//control output
wire [11:0] alu_control;
wire [2:0] regdst_mux_control;
wire [7:0] PC_control;
wire [5:0] wbrf_mux_control;
wire [1:0] hi_lo_control;
wire [3:0] regwrite;
wire [1:0] alusrc1_mux_control;
wire [2:0] alusrc2_mux_control;
wire [3:0] div_mul_control;
wire memwrite;
wire memread;
wire mtc0_wen;
wire eret_cmt;
wire [31:0] eret_pc;
wire sys_flag;
wire inst_in_ds;
wire [6:0] memdata_control;
wire [3:0] wdata_strb;
wire stall;
reg wait_div;
wire [7:0] PC_control2;
wire sys_en;
wire exception_cmt;
assign PC_control2 = (eret_cmt|sys_en)?8'd0:PC_control;

wire set_zero = ~(stall|wait_div|eret_cmt|sys_flag|sys_flagE);
wire [3:0] div_mul_control2 = ({4{set_zero}}&div_mul_control);
wire [1:0] hi_lo_control2= ({2{set_zero}}&hi_lo_control);
wire [4:0] regdst_mux2 = ({5{set_zero}}&regdst_mux);
wire [5:0] wbrf_mux_control2 = ({6{set_zero}}&wbrf_mux_control);
wire [3:0] regwrite2 = ({4{set_zero}}&regwrite);
wire mtc0_wen2 = (~stall)&mtc0_wen;
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
wire [31:0] signextend;
wire [31:0] zeroextend;
wire [31:0] rsE_mux;
wire [31:0] rtE_mux;
wire [31:0] PCplus8;
assign zeroextend = {16'h0000,IR[15:0]};
assign signextend=(IR[15]==0)?{16'h0000,IR[15:0]}:{16'hffff,IR[15:0]};
assign PCplus4 = PCD+32'd4;
assign PCbranch= PCplus4 +(signextend<<2);
assign PCjump = {PC[31:28],IR[25:0],2'b00};
assign inst_in_ds = (PC_control[0]|PC_control[1]|PC_control[4]|PC_control[5]|PC_control[6]|PC_control[7]);


always @(posedge clk) begin
    if (~resetn) begin
        PC<=32'hbfc00000;
    end
    else if(~stall&&~wait_div) begin
        PC <= PCnext;
    end
end
//ID

//Control
control control(.inst(IR),.alu_control(alu_control),.PC_control(PC_control),.regdst_mux_control(regdst_mux_control),.regfile_wen(regwrite),
                .memread(memread),.memwrite(memwrite),.memdata_control(memdata_control),.alusrc1_mux_control(alusrc1_mux_control),.alusrc2_mux_control(alusrc2_mux_control),
                .wbrf_mux_control(wbrf_mux_control),.hi_lo_control(hi_lo_control),.div_mul_control(div_mul_control),.mtc0_wen(mtc0_wen),.eret_cmt(eret_cmt),
                .sys_flag(sys_flag));
reg inst_in_dsD;
always @(posedge clk) begin
    if(~resetn) begin
        IR<=32'd0;
    end
    else if(~stall&&~wait_div) begin
        IR<=inst_sram_rdata;
        PCD<=PC;
        inst_in_dsD<=inst_in_ds;
    end
end
// EX
reg [31:0] PCE;
reg [11:0] aluopE;
reg [4:0] destE;
reg  [5:0] wbrfE;
reg  [3:0] regwriteE;
reg memwriteE,memreadE,mtc0_wenE;
reg [6:0] changedataE;
reg [3:0] div_mulE;
reg [1:0] hiloE;
reg [31:0] v1E,v2E;
reg [31:0] rtE;
reg [31:0] rsE;
reg [31:0] cp0_rdataE;
reg sys_flagE;
reg inst_in_dsE;
wire [3:0] rtE_mux_control;
wire [3:0] rsE_mux_control;
assign PCplus8 = PCE+32'd8;    
always @(posedge clk) begin
if(~resetn)begin
    sys_flagE<=1'b0;
end

else if(resetn&&~wait_div) begin
    rtE<=rtE_mux;
    rsE<=rsE_mux;
    PCE<=PCD;
    v1E<=v1E_mux;
    v2E<=v2E_mux;
    sys_flagE<=sys_flag;
    cp0_rdataE<=cp0_rdata;
    //CONTROL
    mtc0_wenE<=mtc0_wen;
    changedataE<=memdata_control;
    hiloE<=hi_lo_control2;
    div_mulE<=div_mul_control2;
	  aluopE<=alu_control;
    destE<=regdst_mux2;
    wbrfE<=wbrf_mux_control2;
    regwriteE<=regwrite2;
    memwriteE<=memwrite2;
    memreadE<=memread2;
    inst_in_dsE<=inst_in_dsD;
end
end

reg [31:0] HI;
reg [31:0] LO;
wire [63:0] div_result;
wire complete;
wire div;

wire wait_divD = (div_mul_control2[0]||div_mul_control2[1])?(~complete):1'd0;
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
reg [5:0] wbrfM;
reg [3:0] div_mulM;
reg memwriteM;
reg memreadM;
reg mtc0_wenM;
reg [6:0] changedataM;
reg [3:0] regwriteM;
reg [31:0] rtM;
reg [31:0] rsM;
reg [1:0] hiloM;
reg sys_flagM;
reg inst_in_dsM;
wire hiloE2 = (~wait_div)&hiloE;
wire memreadE2 = (~wait_div)&memreadE;
wire [4:0] destE2 = {5{~wait_div}}&destE;
wire [5:0] wbrfE2 = {6{~wait_div}}&wbrfE;
wire memwriteE2 = (~wait_div)&memwriteE;
wire [3:0] regwriteE2 = {4{~wait_div}}&regwriteE;
wire mtc0_wenE2 = (~wait_div)&mtc0_wenE;
wire [31:0] res_mux;
assign res_mux =({32{wbrfE[5]}} & cp0_rdataE)
               |({32{wbrfE[4]}} & PCplus8  )
               |({32{wbrfE[3]}} & HI       )
               |({32{wbrfE[2]}} & LO       )
               |({32{wbrfE[1]|wbrfE[0]}} & aluresult);
always @(posedge clk) begin
if (~resetn) begin
    sys_flagM<=1'b0;
end
else begin
    memreadM<=memreadE2;
    mtc0_wenM<=mtc0_wenE2;
    rtM<=rtE;
    rsM<=rsE;
    PCM<=PCE;
    resM<=res_mux;
    v2M<=v2E;
    destM<=destE2;
    wbrfM<=wbrfE2;
    div_mulM<=div_mulE;
    memwriteM<=memwriteE2;
    changedataM<=changedataE;
    regwriteM<=regwriteE2;
    hiloM<=hiloE2;
    sys_flagM<=sys_flagE;
    inst_in_dsM<=inst_in_dsE;
end
end

always @(posedge clk) begin
    if (div_mulE[0]==1'd1||div_mulE[1]==1'd1) begin
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
reg [31:0] rtW;
reg [4:0] destW;
reg [3:0] regwriteW;
reg mtc0_wenW;
reg [5:0] wbrfW;
reg [6:0] changedataW;
reg sys_flagW;
reg inst_in_dsW;
wire [31:0] resM2;
assign resM2 = ({32{wbrfM[3]}}&HI)
              |({32{wbrfM[2]}}&LO)
              |({32{wbrfM[0]|wbrfM[1]|wbrfM[4]|wbrfM[5]}}&resM);
assign readdata=data_sram_rdata;
always @(posedge clk) begin
if(~resetn) begin
    sys_flagW<=1'b0;
end
else begin
    mtc0_wenW<=mtc0_wenM;
    rtW<=rtM;
    wbrfW<=wbrfM;
    PCW<=PCM;
    resW<=resM2;
    destW<=destM;
    regwriteW<=regwriteM;
    changedataW<=changedataM;
    sys_flagW<=sys_flagM;
    inst_in_dsW<=inst_in_dsM;
end
end
//regfiles

assign regdst_mux=({5{regdst_mux_control[0]&~memwrite&~PC_control[0]&~PC_control[1]}} & IR[20:16] )
				 |({5{regdst_mux_control[1]}} & IR[15:11] )
				 |({5{regdst_mux_control[2]}} & 5'h1f     );

reg_file regfile(.clk(clk),.wen(regwriteW),.waddr(destW),.raddr1(IR[25:21]),.raddr2(IR[20:16]),.wdata(wbrf_mux),.rdata1(regtoalu1),.rdata2(regtoalu2));

//alu
assign alusrc1_mux = ({32{alusrc1_mux_control[0]}} & regtoalu1 )
                    |({32{alusrc1_mux_control[1]}} & {6'd0,IR[31:6]});

assign alusrc2_mux = ({32{alusrc2_mux_control[0]}} & regtoalu2 )
                    |({32{alusrc2_mux_control[1]}} & signextend)
                    |({32{alusrc2_mux_control[2]}} & zeroextend);

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
wire rs_en = alusrc1_mux_control[0]|hi_lo_control[0]|hi_lo_control[1] ;
wire rt_en = alusrc2_mux_control[0]|mtc0_wen;
data_dep_control data_dep_control(.rs(IR[25:21]),.rt(IR[20:16]),.destE(destE), .destM(destM),.destW(destW),.mtc0_wen(mtc0_wen),
                                  .memreadE(memreadE),.memreadM(memreadM),.memwrite(memwrite),.stall(stall),.rs_en(rs_en),
                                  .rt_en(rt_en),.div_mulE(div_mulE),.wbrf_mux_control(wbrf_mux_control),.v1E_mux_control(v1E_mux_control),.v2E_mux_control(v2E_mux_control),
                                  .rtE_mux_control(rtE_mux_control),.rsE_mux_control(rsE_mux_control));

simple_alu ALU(.alu_src1(v1E),.alu_src2(v2E),.alu_result(aluresult),.alu_control(aluopE));

wire [1:0] eaM;
wire [1:0] eaW;
assign eaM = resM[1:0];
assign eaW = resW[1:0];
wire [31:0] mem_wdata;
wire [31:0] mem_rdata;

memdata_change memdata_change(.origin_mem_wdata(rtM),.origin_mem_rdata(readdata),.eaM(eaM),.eaW(eaW),.rt(rtW),.wdata_control(changedataM),.rdata_control(changedataW),.wdata_strb(wdata_strb),.mem_wdata(mem_wdata),.mem_rdata(mem_rdata));
assign wbrf_mux=({32{wbrfW[5]|wbrfW[4]|wbrfW[3]|wbrfW[2]|wbrfW[0]}} & resW      )
               |({32{wbrfW[1]}} & mem_rdata );
 


//exception
assign sys_en = sys_flag|sys_flagE|sys_flagM|sys_flagW;

assign exception_cmt = sys_flagW;
cp0_regfiles cp0_regfiles(.clk(clk),.mtc0_wen(mtc0_wen),.exception_cmt(exception_cmt),.sys_cmt(sys_flagE),.eret_cmt(eret_cmt),.reset(resetn),.inst_in_ds(inst_in_dsW),
                    .inst_pc(PCW),.cp0_raddr(IR[15:11]),.cp0_waddr(IR[15:11]),.cp0_wdata(rtE_mux),.cp0_rdata(cp0_rdata),.eret_pc(eret_pc));
//output signal       
assign inst_sram_wen = 4'b0;
assign inst_sram_wdata = 32'b0;
assign inst_sram_addr = (resetn==1'd0)?32'hbfc00000:PCnext;
assign inst_sram_en = (~stall)&(~wait_div);

assign data_sram_addr = resM;
assign data_sram_wdata= mem_wdata;
assign data_sram_wen = wdata_strb&{4{memwriteM}}&{4{~exception_cmt}};
assign data_sram_en = memwriteM|memreadM;
	
assign debug_wb_pc = PCW;
assign debug_wb_rf_wdata = wbrf_mux;
assign debug_wb_rf_wnum = destW;
assign debug_wb_rf_wen = regwriteW;
//
branch_jump_control branch_jump_control(.sys_exc(sys_flag),.eret_cmt(eret_cmt),.eret_pc(eret_pc),.PC_control(PC_control2),.PCbranch(PCbranch),.PCjump(PCjump),.PC(PC),.rs(v1E_mux),.rt(v2E_mux),.PCnext(PCnext));
endmodule