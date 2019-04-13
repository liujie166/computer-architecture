module cp0_regfiles(
    input clk,
	input mtc0_wen,
	input exception_cmt,
	input sys_cmt,
	input eret_cmt,
	input reset,
	input inst_in_ds,
	input [31:0] inst_pc,
	input [4:0] cp0_raddr,
	input [4:0] cp0_waddr,
	input [31:0] cp0_wdata,
	output [31:0] cp0_rdata,
	output [31:0] eret_pc
	);
wire mtc0_wen_count    = (cp0_waddr == 5'd9 ) & mtc0_wen;
wire mtc0_wen_compare  = (cp0_waddr == 5'd11) & mtc0_wen;
wire mtc0_wen_status   = (cp0_waddr == 5'd12) & mtc0_wen;
wire mtc0_wen_cause    = (cp0_waddr == 5'd13) & mtc0_wen;
wire mtc0_wen_epc      = (cp0_waddr == 5'd14) & mtc0_wen;
//cp0_count&cp0_compare
wire [31:0] cp0_count;
wire [31:0] cp0_compare;
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
                     15'd0,
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
	else if (cp0_count==cp0_compare) begin
		cp0_cause_ti <= 1'b1;
	end
	else if (mtc0_wen_compare) begin
		cp0_cause_ti <= 1'b0;
	end
	else if (inst_in_ds) begin
		cp0_cause_bd<= 1'd1;
	end
	else if (sys_cmt)begin
		cp0_cause_exccode<= 5'h08;
	end
end
//cp0_epc
reg [31:0] cp0_epc;
wire [31:0] now_inst_brpc;
assign now_inst_brpc = inst_in_ds ? inst_pc -3'd4 : inst_pc;
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

wire from_cp0_status  = (cp0_raddr == 5'd12);
wire from_cp0_cause   = (cp0_raddr == 5'd13);
wire from_cp0_epc     = (cp0_raddr == 5'd14);
assign cp0_rdata = ({32{from_cp0_status  }}&cp0_status  )
                  |({32{from_cp0_cause   }}&cp0_cause   )
                  |({32{from_cp0_epc     }}&cp0_epc     );
endmodule