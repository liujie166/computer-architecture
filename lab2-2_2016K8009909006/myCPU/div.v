`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/10/04 20:58:13
// Design Name: 
// Module Name: mul
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module div(
	input div_clk,
	input resetn,
	input div,
	input div_signed,
	input [31:0] x,
	input [31:0] y,
	output [31:0] s,
	output [31:0] r,
	output complete
	);

wire x_signed = x[31] & div_signed;
wire y_signed = y[31] & div_signed;
wire [31:0] x_abs;
wire [31:0] y_abs;
assign x_abs = ({32{x_signed}}^x) + x_signed;
assign y_abs = ({32{y_signed}}^y) + y_signed;
wire s_signed = (x[31]^y[31]) & div_signed;
wire r_signed = x[31] & div_signed;


wire [32:0] div_temp;
reg [64:0] dividend;
reg [31:0] divisor;
reg [5:0] cnt;
reg div_run;
reg [31:0] s_abs;
reg [31:0] r_abs;

assign div_temp = {1'd0,dividend[63:32]} - {1'd0,divisor};

always @(posedge div_clk) begin
    if (~resetn) begin
	    cnt<=6'd0;
	    div_run<=1'd0;
	end
	else if(div&&~div_run) begin
		divisor<=y_abs;
		dividend<={32'd0,x_abs,1'd0};
		div_run<=1'd1;
	end
	else if(~div) begin
	    cnt<=6'd0;
	    div_run<=1'd0;
	end
	else if(div_run) begin
		if(~complete) begin
		    cnt <= cnt +6'd1;
            s_abs<= dividend [31:0];
            r_abs<= dividend [64:33];
			if(cnt<=6'd32) begin
		    	if(div_temp[32] == 1'd1) begin
		    		dividend <= {dividend[63:0],1'd0};
		    	end
		    	else begin
		    		dividend <= {div_temp[31:0],dividend[31:0],1'd1};	
		    	end
			end
		end
	end
end




assign s = ({32{s_signed}}^s_abs) + {30'd0,s_signed};
assign r = ({32{r_signed}}^r_abs) + r_signed;


assign complete = (cnt == 6'd33);

endmodule