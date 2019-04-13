module cpu_axi_interface
(
    input         clk,
    input         resetn, 

    //inst sram-like 
    input         inst_req     ,
    input         inst_wr      ,
    input  [1 :0] inst_size    ,
    input  [31:0] inst_addr    ,
    input  [31:0] inst_wdata   ,
    output [31:0] inst_rdata   ,
    output        inst_addr_ok ,
    output        inst_data_ok ,
    
    //data sram-like 
    input         data_req     ,
    input         data_wr      ,
    input  [1 :0] data_size    ,
    input  [31:0] data_addr    ,
    input  [31:0] data_wdata   ,
    output [31:0] data_rdata   ,
    output        data_addr_ok ,
    output        data_data_ok ,

    //axi
    //ar
    output [3 :0] arid         ,
    output [31:0] araddr       ,
    output [7 :0] arlen        ,
    output [2 :0] arsize       ,
    output [1 :0] arburst      ,
    output [1 :0] arlock       ,
    output [3 :0] arcache      ,
    output [2 :0] arprot       ,
    output        arvalid      ,
    input         arready      ,
    //r           
    input  [3 :0] rid          ,
    input  [31:0] rdata        ,
    input  [1 :0] rresp        ,
    input         rlast        ,
    input         rvalid       ,
    output        rready       ,
    //aw          
    output [3 :0] awid         ,
    output [31:0] awaddr       ,
    output [7 :0] awlen        ,
    output [2 :0] awsize       ,
    output [1 :0] awburst      ,
    output [1 :0] awlock       ,
    output [3 :0] awcache      ,
    output [2 :0] awprot       ,
    output        awvalid      ,
    input         awready      ,
    //w          
    output [3 :0] wid          ,
    output [31:0] wdata        ,
    output [3 :0] wstrb        ,
    output        wlast        ,
    output        wvalid       ,
    input         wready       ,
    //b           
    input  [3 :0] bid          ,
    input  [1 :0] bresp        ,
    input         bvalid       ,
    output        bready       
);
parameter INIT = 4'd0;

parameter WAIT_RADDR = 4'd1;
parameter WAIT_WADDR = 4'd2;
parameter WAIT_RDATA = 4'd3;
parameter WAIT_WDATA = 4'd4;

reg [3:0] state;


wire [31:0] r_addr;
wire [1:0] r_size;
reg r_id;
reg axi_use;


wire [31:0] w_addr;
reg [31:0] w_data;
wire [1:0] w_size;
reg w_id;




always @(posedge clk ) begin
    if (~resetn) begin
        // reset
        state<=INIT;
        axi_use<=1'd0;
    end
    else begin
        case(state)
            INIT:begin
                if(~axi_use&inst_req&~inst_wr)begin
                    state<=WAIT_RADDR;
                    r_id<=1'd0;
                    axi_use<=1'd1;
                end
                else if(~axi_use&data_req&~data_wr)begin
                    state<=WAIT_RADDR;
                    r_id<=1'd1;
                    axi_use<=1'd1;
                end
                else if(~axi_use&data_req&data_wr)begin
                    state<=WAIT_WADDR;
                    w_id<=1'd1;
                    axi_use<=1'd1;
                end
            end
            WAIT_WADDR:begin
                if(data_addr_ok)begin
                    state<=WAIT_WDATA;
                    w_data<=data_wdata;
                end   
            end 
            WAIT_WDATA:begin
                if(data_data_ok)begin
                    state<=INIT;
                    axi_use<=1'd0;
                end
            end
            WAIT_RADDR:begin
                if(inst_addr_ok)begin
                    state<=WAIT_RDATA;
                end
                else if(data_addr_ok)begin
                    state<=WAIT_RDATA;
                      
                end   
            end 
            WAIT_RDATA:begin
                if(data_data_ok|inst_data_ok)begin
                    state<=INIT;
                    axi_use<=1'd0;
                end
            end
        endcase
    end
end
assign r_addr = (r_id==1'd0)?inst_addr:data_addr;
assign r_size = (r_id==1'd0)?inst_size:data_size;

assign w_addr = data_addr;

assign w_size = data_size;

reg [3:0] w_strb;
always @(posedge clk) begin
    if (~resetn) begin
        // reset
        w_strb<=4'd0;
    end
    else if(data_addr_ok&&data_size==2'b00&&data_addr[1:0]==2'b00)begin
            w_strb<=4'b0001;
    end 
    else if(data_addr_ok&&data_size==2'b00&&data_addr[1:0]==2'b01)begin
            w_strb<=4'b0010;
    end 
    else if(data_addr_ok&&data_size==2'b00&&data_addr[1:0]==2'b10)begin
            w_strb<=4'b0100;
    end 
    else if(data_addr_ok&&data_size==2'b00&&data_addr[1:0]==2'b11)begin
            w_strb<=4'b1000;
    end
    else if(data_addr_ok&&data_size==2'b01&&data_addr[1:0]==2'b00)begin
            w_strb<=4'b0011;
    end
    else if(data_addr_ok&&data_size==2'b01&&data_addr[1:0]==2'b10)begin
            w_strb<=4'b1100;
    end
    else if(data_addr_ok&&data_size==2'b10&&data_addr[1:0]==2'b00)begin
            w_strb<=4'b1111;
    end

end

//inst sram-like
assign inst_rdata = rdata;
assign inst_addr_ok = ((r_id==1'd0)&arready&(state==WAIT_RADDR));
assign inst_data_ok = ((r_id==1'd0)&rvalid &(state==WAIT_RDATA));
//data sram-like
assign data_rdata = rdata;
assign data_addr_ok = ((r_id==1'd1)&arready&(state==WAIT_RADDR))|((w_id==1'd1)&awready&(state==WAIT_WADDR));
assign data_data_ok = ((r_id==1'd1)&rvalid &(state==WAIT_RDATA))|((w_id==1'd1)&bvalid &(state==WAIT_WDATA));


// ar
assign arid    = (r_id==1'd0)?4'd0:4'd1;
assign araddr  = r_addr;
assign arlen   = 8'd0;
assign arsize  = r_size;
assign arburst = 2'b01;
assign arlock  = 2'b00;
assign arcache = 4'd0;
assign arprot  = 3'd0;
assign arvalid = (state==WAIT_RADDR);
//r
assign rready  = (state==WAIT_RDATA);
//aw
assign awid    = (w_id==1'd0)?4'd0:4'd1;
assign awaddr  = w_addr;
assign awlen   = 8'd0;
assign awsize  = w_size;
assign awburst = 2'b01;
assign awlock  = 2'd0;
assign awcache = 4'd0;
assign awprot  = 3'd0;
assign awvalid = (state==WAIT_WADDR);

//w
assign wid     = 4'd1;
assign wdata   = w_data;
assign wstrb   = w_strb;
assign wlast   = 1'b1;
assign wvalid  = (state==WAIT_WDATA);
//b
assign bready  = (state==WAIT_WDATA);
endmodule