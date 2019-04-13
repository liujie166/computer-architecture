module mycpu_top(
    input [5:0] int,
	input aclk, 
	input aresetn, 

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
    output        bready       ,

    output [31:0]debug_wb_pc, 
    output [3:0]debug_wb_rf_wen,
    output [4:0]debug_wb_rf_wnum, 
    output [31:0]debug_wb_rf_wdata
    );


//cpu inst sram-like
wire        cpu_inst_req;
wire        cpu_inst_wr;
wire [1 :0] cpu_inst_size;
wire [31:0] cpu_inst_addr;
wire [31:0] cpu_inst_wdata;
wire [31:0] cpu_inst_rdata;
wire        cpu_inst_addr_ok;
wire        cpu_inst_data_ok;

//cpu data sram-like
wire        cpu_data_req;
wire        cpu_data_wr;
wire [1 :0] cpu_data_size;
wire [31:0] cpu_data_addr;
wire [31:0] cpu_data_wdata;
wire [31:0] cpu_data_rdata;
wire        cpu_data_addr_ok;
wire        cpu_data_data_ok;

wire [3:0] data_sram_wen;
//
wire [31:0] cpu_debug_wb_pc     ;
wire [3:0 ] cpu_debug_wb_rf_wen  ;
wire [4:0 ] cpu_debug_wb_rf_wnum ; 
wire [31:0] cpu_debug_wb_rf_wdata;
assign debug_wb_pc      = cpu_debug_wb_pc       ;
assign debug_wb_rf_wen  = cpu_debug_wb_rf_wen   ;
assign debug_wb_rf_wnum = cpu_debug_wb_rf_wnum  ; 
assign debug_wb_rf_wdata= cpu_debug_wb_rf_wdata ;
mycpu_sram cpu_low(
	.clk           (aclk               ),
	.resetn        (aresetn            ),

   //inst sram-like 
    .inst_req      ( cpu_inst_req     ),
    .inst_wr       ( cpu_inst_wr      ),
    .inst_size     ( cpu_inst_size    ),
    .inst_addr     ( cpu_inst_addr    ),
    .inst_wdata    ( cpu_inst_wdata   ),
    .inst_rdata    ( cpu_inst_rdata   ),
    .inst_addr_ok  ( cpu_inst_addr_ok ),
    .inst_data_ok  ( cpu_inst_data_ok ),
    
    //data sram-like 
    .data_req      ( cpu_data_req     ),
    .data_wr       ( cpu_data_wr      ),
    .data_size     ( cpu_data_size    ),
    .data_addr     ( cpu_data_addr    ),
    .data_wdata    ( cpu_data_wdata   ),
    .data_rdata    ( cpu_data_rdata   ),
    .data_addr_ok  ( cpu_data_addr_ok ),
    .data_data_ok  ( cpu_data_data_ok ),
    
    .debug_sram_wen ( data_sram_wen    ),
    .debug_wb_pc     ( cpu_debug_wb_pc    ),
    .debug_wb_rf_wen ( cpu_debug_wb_rf_wen),
    .debug_wb_rf_wnum( cpu_debug_wb_rf_wnum),
    .debug_wb_rf_wdata(cpu_debug_wb_rf_wdata)
    );
//axi
//ar
wire [3 :0] axi_arid   ;
wire [31:0] axi_araddr ;
wire [7 :0] axi_arlen  ;
wire [2 :0] axi_arsize ;
wire [1 :0] axi_arburst;
wire [1 :0] axi_arlock ;
wire [3 :0] axi_arcache;
wire [2 :0] axi_arprot ;
wire        axi_arvalid;
wire        axi_arready;

assign arid = axi_arid;
assign araddr = axi_araddr;
assign arlen = axi_arlen;
assign arsize = axi_arsize;
assign arburst = axi_arburst;
assign arlock = axi_arlock;
assign arcache = axi_arcache;
assign arprot = axi_arprot;
assign arvalid = axi_arvalid;
assign axi_arready = arready;

//r
wire [3 :0] axi_rid    ;
wire [31:0] axi_rdata  ;
wire [1 :0] axi_rresp  ;
wire        axi_rlast  ;
wire        axi_rvalid ;
wire        axi_rready ;

assign axi_rid = rid;
assign axi_rdata = rdata;
assign axi_rresp = rresp;
assign axi_rlast = rlast;
assign axi_rvalid = rvalid;
assign rready = axi_rready;
//aw
wire [3 :0] axi_awid   ;
wire [31:0] axi_awaddr ;
wire [7 :0] axi_awlen  ;
wire [2 :0] axi_awsize ;
wire [1 :0] axi_awburst;
wire [1 :0] axi_awlock ;
wire [3 :0] axi_awcache;
wire [2 :0] axi_awprot ;
wire        axi_awvalid;
wire        axi_awready;

assign awid = axi_awid;
assign awaddr = axi_awaddr;
assign awlen = axi_awlen;
assign awsize = axi_awsize;
assign awburst = axi_awburst;
assign awlock = axi_awlock;
assign awcache = axi_awcache;
assign awprot = axi_awprot;
assign awvalid = axi_awvalid;
assign axi_awready = awready;
//w
wire [3 :0] axi_wid    ;
wire [31:0] axi_wdata  ;
wire [3 :0] axi_wstrb  ;
wire        axi_wlast  ;
wire        axi_wvalid ;
wire        axi_wready ;

assign wid = axi_wid;
assign wdata = axi_wdata;
assign wstrb = axi_wstrb;
assign wlast = axi_wlast;
assign wvalid = axi_wvalid;
assign axi_wready = wready;
//b
wire [3 :0] axi_bid    ;
wire [1 :0] axi_bresp  ;
wire        axi_bvalid ;
wire        axi_bready ;

assign axi_bid = bid;
assign axi_bresp = bresp;
assign axi_bvalid = bvalid;
assign bready = axi_bready;
cpu_axi_interface cpu_axi_interface(
    .clk           ( aclk          ),
    .resetn        ( aresetn       ),
    .data_sram_wen ( data_sram_wen ),
    //inst sram-like 
    .inst_req      ( cpu_inst_req     ),
    .inst_wr       ( cpu_inst_wr      ),
    .inst_size     ( cpu_inst_size    ),
    .inst_addr     ( cpu_inst_addr    ),
    .inst_wdata    ( cpu_inst_wdata   ),
    .inst_rdata    ( cpu_inst_rdata   ),
    .inst_addr_ok  ( cpu_inst_addr_ok ),
    .inst_data_ok  ( cpu_inst_data_ok ),
    
    //data sram-like 
    .data_req      ( cpu_data_req     ),
    .data_wr       ( cpu_data_wr      ),
    .data_size     ( cpu_data_size    ),
    .data_addr     ( cpu_data_addr    ),
    .data_wdata    ( cpu_data_wdata   ),
    .data_rdata    ( cpu_data_rdata   ),
    .data_addr_ok  ( cpu_data_addr_ok ),
    .data_data_ok  ( cpu_data_data_ok ),

    //axi
    //ar
    .arid      ( axi_arid         ),
    .araddr    ( axi_araddr       ),
    .arlen     ( axi_arlen        ),
    .arsize    ( axi_arsize       ),
    .arburst   ( axi_arburst      ),
    .arlock    ( axi_arlock       ),
    .arcache   ( axi_arcache      ),
    .arprot    ( axi_arprot       ),
    .arvalid   ( axi_arvalid      ),
    .arready   ( axi_arready      ),
    //r              
    .rid       ( axi_rid          ),
    .rdata     ( axi_rdata        ),
    .rresp     ( axi_rresp        ),
    .rlast     ( axi_rlast        ),
    .rvalid    ( axi_rvalid       ),
    .rready    ( axi_rready       ),
    //aw           
    .awid      ( axi_awid         ),
    .awaddr    ( axi_awaddr       ),
    .awlen     ( axi_awlen        ),
    .awsize    ( axi_awsize       ),
    .awburst   ( axi_awburst      ),
    .awlock    ( axi_awlock       ),
    .awcache   ( axi_awcache      ),
    .awprot    ( axi_awprot       ),
    .awvalid   ( axi_awvalid      ),
    .awready   ( axi_awready      ),
    //w          
    .wid       ( axi_wid          ),
    .wdata     ( axi_wdata        ),
    .wstrb     ( axi_wstrb        ),
    .wlast     ( axi_wlast        ),
    .wvalid    ( axi_wvalid       ),
    .wready    ( axi_wready       ),
    //b              
    .bid       ( axi_bid          ),
    .bresp     ( axi_bresp        ),
    .bvalid    ( axi_bvalid       ),
    .bready    ( axi_bready       )

);
endmodule