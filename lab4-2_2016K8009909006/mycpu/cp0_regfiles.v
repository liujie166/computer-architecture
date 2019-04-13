module cp0_regfiles(
    input clk,
	input mtc0_wen,
	input exception_cmt,
	input sys_cmt,
	input brk_cmt,
	input over_cmt,
	input ri_cmt,
	input int_cmt,
	input data_adel_cmt,
	input ades_cmt,
	input inst_adel_cmt,
	input eret_cmt,
	input reset,
	input inst_in_ds,
	input [31:0] inst_pc,
	input [31:0] bad_addr,
	input [4:0] cp0_raddr,
	input [4:0] cp0_waddr,
	input [31:0] cp0_wdata,
	output [31:0] cp0_rdata,
	output [31:0] eret_pc,
	output int_flag,
	output softint_flag
		);
wire mtc0_wen_badvaddr = (cp0_waddr == 5'd8 ) & mtc0_wen;
wire mtc0_wen_count    = (cp0_waddr == 5'd9 ) & mtc0_wen;
wire mtc0_wen_compare  = (cp0_waddr == 5'd11) & mtc0_wen;
wire mtc0_wen_status   = (cp0_waddr == 5'd12) & mtc0_wen;
wire mtc0_wen_cause    = (cp0_waddr == 5'd13) & mtc0_wen;
wire mtc0_wen_epc      = (cp0_waddr == 5'd14) & mtc0_wen;
//cp0_count&cp0_compare
reg [31:0] cp0_count;
reg [31:0] cp0_compare;
reg cnt_2clk;
always @(posedge clk) begin
	if (~reset) begin
		// reset
		cnt_2clk<=1'd0;
	end
	else begin
		cnt_2clk<=~cnt_2clk;
	end
end
always @(posedge clk) begin
	if (~reset) begin
		// reset
		cp0_count<=32'd0;
	end
	else if (~mtc0_wen_count) begin
	    if(cnt_2clk==1'd1)begin
	    	cp0_count<=cp0_count+32'd1;
	    end
	end
	else if (mtc0_wen_count)begin
		cp0_count<=cp0_wdata;
	end
end
always @(posedge clk) begin
    if(~reset) begin
    	cp0_compare<=32'hffffffff;
    end
	else if (mtc0_wen_compare) begin
		cp0_compare<=cp0_wdata;
	end
end

//cp0_status
wire [31:0] cp0_status;

wire       cp0_status_bev;
reg [7:0]  cp0_status_im;
reg        cp0_status_exl;
reg        cp0_status_ie;

assign cp0_status_bev = 1'b1;
assign cp0_status = { 9'd0,
					  cp0_status_bev,
					  6'd0,
					  cp0_status_im,
					  6'd0,
					  cp0_status_exl,
					  cp0_status_ie
                    };

always @(posedge clk) begin
	if (~reset) begin
		// reset
		cp0_status_exl<=1'b0;
		cp0_status_im<=8'd0;
		cp0_status_ie<=1'b0;
	end
	else if (mtc0_wen_status) begin
	    cp0_status_im <= cp0_wdata[15:8];
		cp0_status_exl<= cp0_wdata[1];
		cp0_status_ie <= cp0_wdata[0];
	end
	else if(exception_cmt) begin
		cp0_status_exl<=1'b1;
	end
	else if(eret_cmt) begin
		cp0_status_exl<=1'b0;
	end
end
//cp0_cause
wire [31:0] cp0_cause;

reg cp0_cause_bd;
reg cp0_cause_ti;
reg [7:0] cp0_cause_ip;
reg [4:0] cp0_cause_exccode;

assign cp0_cause =  { cp0_cause_bd,
                     cp0_cause_ti,
                     14'd0,
                     cp0_cause_ip,
                     1'd0,
                     cp0_cause_exccode,
                     2'd0
                    };

always @(posedge clk) begin
	if (~reset) begin
		// reset
		cp0_cause_bd <=1'b0;
		cp0_cause_ti <=1'b0;
		cp0_cause_ip <=8'd0;	
	end
	else if (mtc0_wen_cause) begin
	    cp0_cause_bd <= cp0_wdata[31];
		cp0_cause_ti <= cp0_wdata[30];
		cp0_cause_ip <= cp0_wdata[15:8];
		//cp0_cause_exccode <= cp0_wdata[6:2];
	end
	else if ((cp0_count==cp0_compare)&(cp0_count!=32'd0)) begin
		cp0_cause_ti <= 1'b1;
		cp0_cause_ip[7]<=1'b1;
	end
	else if(softint_flag)begin
		cp0_cause_ip[1:0]<=2'b00;
	end
	else if (mtc0_wen_compare) begin
		cp0_cause_ti <= 1'b0;
	end
	else if (inst_in_ds&exception_cmt&~inst_adel_cmt) begin
		cp0_cause_bd<= 1'd1;
	end
	if (sys_cmt&exception_cmt)begin
		cp0_cause_exccode<= 5'h08;
	end
	if (brk_cmt&exception_cmt)begin
		cp0_cause_exccode<= 5'h09;
	end
	if (over_cmt&exception_cmt)begin
		cp0_cause_exccode<= 5'h0c;
	end
	if ((data_adel_cmt|inst_adel_cmt)&exception_cmt)begin
		cp0_cause_exccode<= 5'h04;
	end
	if (ades_cmt&exception_cmt) begin
		cp0_cause_exccode<= 5'h05;
	end
	if (ri_cmt&exception_cmt) begin
		cp0_cause_exccode<= 5'h0a;
	end
	if (int_cmt&exception_cmt)begin
		cp0_cause_exccode<= 5'h00;
	end
end
assign softint_flag = (cp0_cause_ip[0]&cp0_status_im[0])
                     |(cp0_cause_ip[1]&cp0_status_im[1]);
assign int_flag = (cp0_compare==cp0_count)&(cp0_count!=32'd0)&(cp0_cause_ti==1'd0);
//cp0_epc
reg [31:0] cp0_epc;
wire [31:0] now_inst_brpc;
assign now_inst_brpc = (inst_adel_cmt)?inst_pc:(inst_in_ds)? inst_pc -3'd4 : inst_pc;
assign eret_pc = cp0_epc;
always @(posedge clk) begin
	if (~reset) begin
        cp0_epc<= 32'h19980105;
	end
	else if (mtc0_wen_epc) begin
		cp0_epc<= cp0_wdata;
	end
	else if (exception_cmt&&cp0_status_exl==1'b0) begin
		cp0_epc<=now_inst_brpc;
	end
end
//cp0_badvaddr
reg [31:0] cp0_badvaddr;
always @(posedge clk) begin
	if (~reset) begin
        cp0_badvaddr<= 32'h19980105;
	end
	else if (mtc0_wen_badvaddr) begin
		cp0_badvaddr<= cp0_wdata;
	end
	else if ((data_adel_cmt|ades_cmt)&exception_cmt) begin
		cp0_badvaddr<=bad_addr;
	end
	else if (inst_adel_cmt&exception_cmt)begin
		cp0_badvaddr<=inst_pc;
	end
end
wire from_cp0_badvaddr= (cp0_raddr == 5'd8 );
wire from_cp0_count   = (cp0_raddr == 5'd9 );
wire from_cp0_compare = (cp0_raddr == 5'd11);
wire from_cp0_status  = (cp0_raddr == 5'd12);
wire from_cp0_cause   = (cp0_raddr == 5'd13);
wire from_cp0_epc     = (cp0_raddr == 5'd14);
assign cp0_rdata = ({32{from_cp0_status  }}&cp0_status  )
                  |({32{from_cp0_cause   }}&cp0_cause   )
                  |({32{from_cp0_epc     }}&cp0_epc     )
                  |({32{from_cp0_badvaddr}}&cp0_badvaddr)
                  |({32{from_cp0_count   }}&cp0_count   )
                  |({32{from_cp0_compare }}&cp0_compare );
endmodule