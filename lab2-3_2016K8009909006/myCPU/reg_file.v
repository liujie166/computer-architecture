module reg_file(
	input clk,
	input [4:0] waddr,
	input [4:0] raddr1,
	input [4:0] raddr2,
	input [3:0] wen,
	input [31:0] wdata,
	output [31:0] rdata1,
	output [31:0] rdata2
);

reg [31:0] rf [31:0];

always@ (posedge clk) begin
    if(wen==4'b1111) rf[waddr] <= wdata;
end

// READ OUT 1
assign rdata1 = (raddr1==5'd0) ? 32'd0 : rf[raddr1];
// READ OUT 2
assign rdata2 = (raddr2==5'd0) ? 32'd0 : rf[raddr2];
	

endmodule