module mycpu_sram(
	input clk, 
	input resetn, 

    //------inst sram-like-------
    output        inst_req    ,
    output        inst_wr     ,
    output [1 :0] inst_size   ,
    output [31:0] inst_addr   ,
    output [31:0] inst_wdata  ,
    input  [31:0] inst_rdata  ,
    input         inst_addr_ok,
    input         inst_data_ok,
        
    //------data sram-like-------
    output        data_req    ,
    output        data_wr     ,
    output [1 :0] data_size   ,
    output [31:0] data_addr   ,
    output [31:0] data_wdata  ,
    input  [31:0] data_rdata  ,
    input         data_addr_ok,
    input         data_data_ok,
    
    output [3:0] debug_sram_wen,
    output [31:0]debug_wb_pc, 
    output [3:0]debug_wb_rf_wen,
    output [4:0]debug_wb_rf_wnum, 
    output [31:0]debug_wb_rf_wdata
);

assign debug_sram_wen = data_sram_wen;
wire inst_sram_en;
wire [3:0] inst_sram_wen; 
wire [31:0] inst_sram_addr;
wire [31:0] inst_sram_wdata;  
wire [31:0] inst_sram_rdata; 
reg inst_req_reg;
reg inst_used;
always @(posedge clk) begin
    if (~resetn) begin
        // reset
        inst_req_reg<=1'd0;
    end
    else if (inst_addr_ok) begin
        inst_req_reg<=1'd1;
    end
    else if (inst_data_ok)begin
        inst_req_reg<=1'd0;
    end
end


assign inst_wr = 1'b0;
assign inst_size = 2'd2;
assign inst_addr = inst_sram_addr;
assign inst_wdata = 32'd0;
assign inst_sram_rdata = inst_rdata;
wire data_sram_en;
wire [3:0] data_sram_wen; 
wire [31:0]data_sram_addr; 
wire [31:0]data_sram_wdata;
wire [31:0]data_sram_rdata;

wire [2:0] byte_cnt;
wire [1:0] wdata_size;
reg data_req_reg;
always @(posedge clk) begin
    if (~resetn) begin
        // reset
        data_req_reg<=1'd0;

    end
    else if (data_addr_ok) begin
        data_req_reg<=1'd1;
    end
    else if (data_data_ok)begin
        data_req_reg<=1'd0;
    end
end

assign wdata_size = (byte_cnt == 3'd4)?2'd2:(byte_cnt == 3'd2)?2'd1:2'd0;
assign data_req = (data_sram_en&~data_req_reg);
assign data_wr = ~(data_sram_wen==4'd0);
assign data_size = (data_wr == 1'd0)?2'd2:wdata_size;
assign data_addr = data_sram_addr;
assign data_wdata = data_sram_wdata;
assign data_sram_rdata = data_rdata;

//alu signal
wire [31:0] alusrc1_mux;
wire [31:0] alusrc2_mux;
wire [31:0] aluresult;
wire overflow;

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
wire brk_flag;
wire over_req;
wire ri_flag;
wire eret_flag;

wire [6:0] memdata_control;
wire [3:0] wdata_strb;
wire stall;
reg wait_div;
wire [7:0] PC_control2;
reg sys_en;
reg brk_en;
reg over_en;
reg data_adel_en;
reg ades_en;
reg inst_adel_en;
reg ri_en;
reg int_en;
reg eret_en;
reg eret_flagE;
reg softint_en;
wire int_flag;
wire softint_flag;
wire exception_cmt;
assign PC_control2 = (eret_flagE|sys_en|brk_en|over_en|data_adel_en|ades_en|ri_en|int_en|softint_en)?8'd0:PC_control;

wire wait_inst = ~inst_used&inst_sram_en;
wire wait_data;
wire set_zero = ~(wait_data|wait_inst|stall|wait_div|eret_flagE|sys_en|brk_en|over_en|data_adel_en|ades_en|inst_adel_en|ri_en|int_en|softint_en);
wire [3:0] div_mul_control2 = ({4{set_zero}}&div_mul_control);
wire [1:0] hi_lo_control2= ({2{set_zero}}&hi_lo_control);
wire [4:0] regdst_mux2 = ({5{set_zero}}&regdst_mux);
wire [5:0] wbrf_mux_control2 = ({6{set_zero}}&wbrf_mux_control);
wire [3:0] regwrite2 = ({4{set_zero}}&regwrite);
wire mtc0_wen2 = (set_zero)&mtc0_wen;
wire memwrite2 = (set_zero)&memwrite;
wire memread2 = (set_zero)&memread;

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
wire inst_adel_flag1 = (PC[1:0]!=2'b00)&(~inst_adel_en);
wire inst_adel_flag = inst_adel_flag1&~sys_flag&~ri_flag&~brk_flag;
assign zeroextend = {16'h0000,IR[15:0]};
assign signextend=(IR[15]==0)?{16'h0000,IR[15:0]}:{16'hffff,IR[15:0]};
assign PCplus4 = PCD+32'd4;
assign PCbranch= PCplus4 +(signextend<<2);
assign PCjump = {PC[31:28],IR[25:0],2'b00};
wire inst_in_ds;
assign inst_in_ds = (PC_control!=8'd0);

always @(posedge clk) begin
    if (~resetn) begin
        PC<=32'hbfc00000;
    end
    else if(~stall&&~wait_div&&~wait_inst&&~wait_data) begin
        PC <= PCnext;
    end
end
//ID
reg inst_adel_flagD;
wire ri_flag1;
wire sys_flag1;
assign sys_flag = sys_flag1;
assign ri_flag = ri_flag1&~inst_adel_en;
reg [31:0] inst_sram_rdataD;
//Control
control control(.inst(IR),.alu_control(alu_control),.PC_control(PC_control),.regdst_mux_control(regdst_mux_control),.regfile_wen(regwrite),
                .memread(memread),.memwrite(memwrite),.memdata_control(memdata_control),.alusrc1_mux_control(alusrc1_mux_control),.alusrc2_mux_control(alusrc2_mux_control),
                .wbrf_mux_control(wbrf_mux_control),.hi_lo_control(hi_lo_control),.div_mul_control(div_mul_control),.mtc0_wen(mtc0_wen),.eret_flag(eret_flag),
                .sys_flag(sys_flag1),.brk_flag(brk_flag),.over_req(over_req),.ri_flag(ri_flag1));
reg inst_in_dsD;

always @(posedge clk) begin
    if(~resetn) begin
        IR<=32'd0;
        inst_adel_flagD<=1'd0;
        inst_used<=1'd0;
        inst_sram_rdataD<=32'd0;
    end
    else if(~stall&&~wait_div&&~wait_inst&&~wait_data) begin
        IR<=inst_sram_rdataD;
        PCD<=PC;
        inst_in_dsD<=inst_in_ds;
        inst_adel_flagD<=inst_adel_flag;
        inst_used<=1'd0;
    end
    else if(inst_data_ok)begin
        inst_used<=1'd1;
        inst_sram_rdataD<=inst_sram_rdata;
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
reg brk_flagE;
reg inst_in_dsE;
reg over_reqE;
reg inst_adel_flagE;

reg ri_flagE;
reg int_flagE;
reg softint_flagE;
wire [3:0] rtE_mux_control;
wire [3:0] rsE_mux_control;
wire over_flagE;
wire data_adel_flagE;
wire ades_flagE;

assign data_adel_flagE = (memreadE&changedataE[0]&(aluresult[1:0]!=2'b00))
                        |(memreadE&(changedataE[3]|changedataE[4])&(aluresult[0]!=1'b0));
assign ades_flagE = (memwriteE&changedataE[0]&(aluresult[1:0]!=2'b00))
                   |(memwriteE&changedataE[3]&(aluresult[0]!=1'b0));
assign over_flagE = over_reqE&overflow;
assign PCplus8 = PCE+32'd8;    
always @(posedge clk) begin
if(~resetn)begin
    int_flagE<=1'b0; 
    brk_flagE<=1'b0;
    sys_flagE<=1'b0;
    over_reqE<=1'b0;
    softint_flagE<=1'b0;
    eret_flagE<=1'b0;
    ri_flagE<=1'b0;
    inst_adel_flagE<=1'b0;
    memwriteE<=1'b0;
    memreadE<=1'b0;
    changedataE<=7'd0;
end

else if(~wait_div&&~wait_data) begin
    rtE<=rtE_mux;
    rsE<=rsE_mux;
    PCE<=PCD;
    v1E<=v1E_mux;
    v2E<=v2E_mux;
    sys_flagE<=sys_flag;
    brk_flagE<=brk_flag;
    over_reqE<=over_req;
    inst_adel_flagE<=inst_adel_flagD;
    ri_flagE<=ri_flag;
    int_flagE<=int_flag;
    softint_flagE<=softint_flag;
    cp0_rdataE<=cp0_rdata;
    //CONTROL
    mtc0_wenE<=mtc0_wen2;
    eret_flagE<=eret_flag;
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
wire [3:0] div_mulE2 = {4{~(over_en|data_adel_en|ades_en)}}&div_mulE;
wire wait_divD = (div_mul_control2[0]||div_mul_control2[1])?(~complete):1'd0;
assign div = div_mulE2[0]|div_mulE2[1];
wire div_signed = div_mulE2[0];
always @(posedge clk) begin
    if(~resetn)
       wait_div<=1'd0;
    else if(wait_divD)
       wait_div<=1'd1;
    else if(over_en|data_adel_en|ades_en)begin
       wait_div<=1'd0;
    end
    else if(complete)
       wait_div<=1'd0;
end
div div1(.div_clk(clk),.resetn(resetn),.div(div),.div_signed(div_signed),.x(v1E),.y(v2E),.s(div_result[31:0]),.r(div_result[63:32]),.complete(complete));
wire mul_signed = div_mulE2[2];
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
reg brk_flagM;
reg over_flagM;
reg inst_in_dsM;
reg data_adel_flagM;
reg ades_flagM;
reg ri_flagM;
reg int_flagM;
reg softint_flagM;
reg eret_flagM;
reg inst_adel_flagM;
reg [31:0] mem_rdataM;
wire set_zeroE = ~(wait_div|over_en|data_adel_en|ades_en);
wire hiloE2 = (set_zeroE)&hiloE;

wire memreadE2 = (set_zeroE)&memreadE;
wire [4:0] destE2 = {5{set_zeroE}}&destE;
wire [5:0] wbrfE2 = {6{set_zeroE}}&wbrfE;
wire memwriteE2 = (set_zeroE)&memwriteE;
wire [3:0] regwriteE2 = {4{set_zeroE}}&regwriteE;
wire mtc0_wenE2 = (set_zeroE)&mtc0_wenE;
wire [31:0] res_mux;
assign inst_req = (inst_sram_en&~inst_req_reg&~data_sram_en&~inst_used);
assign wait_data = (~data_data_ok&data_sram_en);
assign res_mux =({32{wbrfE[5]}} & cp0_rdataE)
               |({32{wbrfE[4]}} & PCplus8  )
               |({32{wbrfE[3]}} & HI       )
               |({32{wbrfE[2]}} & LO       )
               |({32{wbrfE[1]|wbrfE[0]}} & aluresult);
always @(posedge clk) begin
if (~resetn) begin
    int_flagM<=1'b0;
    eret_flagM<=1'b0;
    ri_flagM<=1'b0;
    softint_flagM<=1'b0;
    sys_flagM<=1'b0;
    brk_flagM<=1'b0;
    over_flagM<=1'b0;
    data_adel_flagM<=1'b0;
    inst_adel_flagM<=1'b0;
    ades_flagM<=1'b0;
    memwriteM<=1'd0;
    memreadM<=1'd0;
end
else if(~wait_data)begin
    mem_rdataM<=readdata;
    memreadM<=memreadE2;
    mtc0_wenM<=mtc0_wenE2;
    rtM<=rtE;
    rsM<=rsE;
    PCM<=PCE;
    resM<=res_mux;
    v2M<=v2E;
    destM<=destE2;
    wbrfM<=wbrfE2;
    div_mulM<=div_mulE2;
    memwriteM<=memwriteE2;
    changedataM<=changedataE;
    regwriteM<=regwriteE2;
    hiloM<=hiloE2;
    eret_flagM<=eret_flagE;
    sys_flagM<=sys_flagE;
    brk_flagM<=brk_flagE;
    softint_flagM<=softint_flagE;
    ri_flagM<=ri_flagE;
    int_flagM<=int_flagE;
    over_flagM<=over_flagE;
    data_adel_flagM<=data_adel_flagE;
    ades_flagM<=ades_flagE;
    inst_adel_flagM<=inst_adel_flagE;
    inst_in_dsM<=inst_in_dsE;
end
end

always @(posedge clk) begin
    if (div_mulE2[0]==1'd1||div_mulE2[1]==1'd1) begin
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
reg [3:0] regwriteW2;
reg mtc0_wenW;
reg [5:0] wbrfW;
reg [31:0] memdataW;
reg [6:0] changedataW;
reg sys_flagW;
reg brk_flagW;
reg over_flagW;
reg data_adel_flagW;
reg inst_adel_flagW;
reg ades_flagW;
reg ri_flagW;
reg int_flagW;
reg softint_flagW;
reg inst_in_dsW;
reg eret_flagW;
wire [31:0] mem_wdata;
wire [31:0] resM2;
reg [31:0] mem_rdataW;
assign resM2 = ({32{wbrfM[3]}}&HI)
              |({32{wbrfM[2]}}&LO)
              |({32{wbrfM[0]|wbrfM[1]|wbrfM[4]|wbrfM[5]}}&resM);
assign readdata=data_sram_rdata;
always @(posedge clk) begin
if(~resetn) begin
    sys_flagW<=1'b0;
    eret_flagW<=1'b0;
    int_flagW<=1'b0;
    softint_flagW<=1'b0;
    brk_flagW<=1'b0;
    over_flagW<=1'b0;
    data_adel_flagW<=1'b0;
    inst_adel_flagW<=1'b0;
    ri_flagW<=1'b0;
    ades_flagW<=1'b0;
end
else begin
    mem_rdataW<=mem_rdata;
    memdataW<=mem_wdata;
    mtc0_wenW<=mtc0_wenM;
    rtW<=rtM;
    wbrfW<=wbrfM;
    PCW<=PCM;
    resW<=resM2;
    destW<=destM;
    regwriteW2<=regwriteM;
    changedataW<=changedataM;
    sys_flagW<=sys_flagM;
    eret_flagW<=eret_flagM;
    brk_flagW<=brk_flagM;
    ri_flagW<=ri_flagM;
    int_flagW<=int_flagM;
    softint_flagW<=softint_flagM;
    over_flagW<=over_flagM;
    data_adel_flagW<=data_adel_flagM;
    inst_adel_flagW<=inst_adel_flagM;
    ades_flagW<=ades_flagM;
    inst_in_dsW<=inst_in_dsM;
end
end
wire [3:0] regwriteW;
assign regwriteW = (wait_data|data_data_ok)?4'd0:regwriteW2;

//regfiles

assign regdst_mux=({5{regdst_mux_control[0]&~memwrite&~PC_control[0]&~PC_control[1]}} & IR[20:16] )
				 |({5{regdst_mux_control[1]}} & IR[15:11] )
				 |({5{regdst_mux_control[2]}} & 5'h1f     );

reg_file regfile(.clk(clk),.wen(regwriteW&({4{~over_flagW}}&{4{~data_adel_flagW}}&{4{~int_flagW}})),.waddr(destW),.raddr1(IR[25:21]),.raddr2(IR[20:16]),.wdata(wbrf_mux),.rdata1(regtoalu1),.rdata2(regtoalu2));

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

simple_alu ALU(.alu_src1(v1E),.alu_src2(v2E),.alu_result(aluresult),.alu_control(aluopE),.overflow(overflow));

wire [1:0] eaM;
wire [1:0] eaW;
assign eaM = resM[1:0];
assign eaW = resW[1:0];

wire [31:0] mem_rdata;
memdata_change memdata_change(.origin_mem_wdata(rtM),.origin_mem_rdata(mem_rdataM),.eaM(eaM),.eaW(eaM),.rt(rtM),.wdata_control(changedataM),.rdata_control(changedataM),.wdata_strb(wdata_strb),.mem_wdata(mem_wdata),.mem_rdata(mem_rdata));
assign wbrf_mux=({32{wbrfW[5]|wbrfW[4]|wbrfW[3]|wbrfW[2]|wbrfW[0]}} & resW      )
               |({32{wbrfW[1]}} & mem_rdataW );
 
assign byte_cnt = wdata_strb[0]+wdata_strb[1]+wdata_strb[2]+wdata_strb[3];

//exception
always @(posedge clk) begin
    if (~resetn) begin
        // reset
        int_en<=1'd0;
        softint_en<=1'd0;
        sys_en<=1'd0;
        brk_en<=1'd0;
        over_en<=1'd0;
        data_adel_en<=1'd0;
        ades_en<=1'd0;
        inst_adel_en<=1'd0;
        ri_en<=1'd0;
    end
    else if (sys_flag==1'd1) begin
        sys_en<=1'd1;
    end
    else if (brk_flag==1'd1)begin
        brk_en<=1'd1;
    end
    else if (over_flagE==1'd1)begin
        over_en<=1'd1;
    end
    else if(data_adel_flagE==1'd1)begin
        data_adel_en<=1'd1;
    end
    else if(ades_flagE==1'd1)begin
        ades_en<=1'd1;
    end
    else if(inst_adel_flag==1'd1)begin
        inst_adel_en<=1'd1;
    end
    else if (ri_flag==1'd1)begin
        ri_en<=1'd1;
    end
    else if (int_flag==1'd1)begin
        int_en<=1'd1;
    end
    else if(softint_flag==1'd1)begin
        softint_en<=1'd1;
    end
    else if (PCD==32'hbfc00380)begin
        sys_en<=1'd0;
        brk_en<=1'd0;
        over_en<=1'd0;
        data_adel_en<=1'd0;
        ades_en<=1'd0;
        inst_adel_en<=1'd0;
        ri_en<=1'd0;
        int_en<=1'd0;
        softint_en<=1'd0;
    end
end
wire some_exc_en = sys_en|brk_en|over_en|data_adel_en|ades_en|ri_en|int_en|softint_en;
reg handler_exc;
always @(posedge clk) begin
    if (~resetn) begin
        // reset
        handler_exc<=1'd0;
    end
    else if (PCnext==32'hbfc00380) begin
        handler_exc<=1'd1;
    end
    else if (eret_flagE)begin
        handler_exc<=1'd0;
    end
end
wire exception_cmt2;
wire exl;
assign exception_cmt = (wait_data)?1'd0:exception_cmt2;
assign exception_cmt2 = ~exl&(~handler_exc)&(sys_flagW|brk_flagW|over_flagW|data_adel_flagW|ades_flagW|inst_adel_flagW|ri_flagW|int_flagW|softint_flagW);
cp0_regfiles cp0_regfiles(.clk(clk),.mtc0_wen(mtc0_wen2),.exception_cmt(exception_cmt),.sys_cmt(sys_flagW),.brk_cmt(brk_flagW),.over_cmt(over_flagW),.ri_cmt(ri_flagW),.int_cmt(int_flagW),
                    .data_adel_cmt(data_adel_flagW),.ades_cmt(ades_flagW),.inst_adel_cmt(inst_adel_flagW),.eret_cmt(eret_flag),.reset(resetn),.inst_in_ds(inst_in_dsW),.exl(exl),
                    .inst_pc(PCW),.bad_addr(resW),.cp0_raddr(IR[15:11]),.cp0_waddr(IR[15:11]),.cp0_wdata(rtE_mux),.cp0_rdata(cp0_rdata),.eret_pc(eret_pc),.int_flag(int_flag),.softint_flag(softint_flag));
//output signal       
assign inst_sram_wen = 4'b0;
assign inst_sram_wdata = 32'b0;
assign inst_sram_addr = PCnext;
assign inst_sram_en = (~stall)&(~wait_div)&(((~inst_adel_flag)&(~inst_adel_flagD)&(~inst_adel_flagE)&(~inst_adel_flagM))|some_exc_en|PCnext==32'hbfc00380);

assign data_sram_addr = (memwriteM)?resM:res_mux;
assign data_sram_wdata= mem_wdata;
assign data_sram_wen = wdata_strb&{4{memwriteM}}&{4{~ades_flagM}}&{4{~int_flagM}};
assign data_sram_en = (memwriteM|memreadE2)&(~data_adel_flagE)&(~data_adel_flagM)&(~ades_flagM)&(~int_flagM);
	
assign debug_wb_pc = PCW;
assign debug_wb_rf_wdata = wbrf_mux;
assign debug_wb_rf_wnum = destW;
assign debug_wb_rf_wen = regwriteW&{4{~over_flagW}}&{4{~data_adel_flagW}}&{4{~int_flagW}};
//
branch_jump_control branch_jump_control(.clk(clk),.resetn(resetn),.inst_addr_ok(inst_addr_ok),.exception_cmt(exception_cmt),.eret_cmt(eret_flag),.eret_pc(eret_pc),.PC_control(PC_control2),.PCbranch(PCbranch),.PCjump(PCjump),.PC(PC),.rs(v1E_mux),.rt(v2E_mux),.PCnext(PCnext));
endmodule