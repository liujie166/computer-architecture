module branch_jump_control(
  input clk,
  input resetn,
  input inst_addr_ok,
  input exception_cmt,
  input eret_cmt,
  input [31:0] eret_pc,
	input [7:0] PC_control,
	input [31:0] PCbranch,
	input [31:0] PCjump,
	input [31:0] PC,
	input [31:0] rs,
	input [31:0] rt,
	output reg [31:0] PCnext
	);
wire zero;
wire [31:0] PCbranch_jump;
wire bj;
wire [31:0] PCnext_wire;
assign bj =  (PC_control[7]&(rs[31]|(rs==32'd0)))|(PC_control[6]&(~rs[31])&(rs!=32'd0))
          |(PC_control[5]&rs[31]) | (PC_control[4]&(~rs[31])) 
          | PC_control[3] | PC_control[2] | (PC_control[1]&(~zero)) |(PC_control[0]&zero);

assign zero = (rs==rt);
assign PCbranch_jump=({32{PC_control[7]&(rs[31]|(rs==32'd0))}} & PCbranch)//blez
   |({32{PC_control[6]&(~rs[31])&(rs!=32'd0)}} & PCbranch)//bgtz
   |({32{PC_control[5]&rs[31]}} & PCbranch)//bltz
   |({32{PC_control[4]&(~rs[31])}} & PCbranch)//bgez
   |({32{PC_control[3]}} & rs)//jr
   |({32{PC_control[2]}} & PCjump   )//jal
   |({32{PC_control[1]&(~zero)}} & PCbranch)//bne
   |({32{PC_control[0]&zero}} & PCbranch);//beq

assign PCnext_wire=(exception_cmt|ready_to_ex)?32'hbfc00380:(eret_cmt==1'd1)?eret_pc:(bj==1'd1)?PCbranch_jump:(PC+32'd4);
reg ready_to_ex;
always @(posedge clk) begin
  if (~resetn) begin
    // reset
    PCnext<=32'hbfc00000;
    ready_to_ex<=1'd0;
  end
  else if (inst_addr_ok) begin
    PCnext<=PCnext_wire;
    ready_to_ex<=1'd0;
  end
  else if (exception_cmt)begin
    ready_to_ex<=1'd1;
  end
end
endmodule