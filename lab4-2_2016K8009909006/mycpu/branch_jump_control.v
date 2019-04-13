module branch_jump_control(
  input exception_cmt,
  input eret_cmt,
  input [31:0] eret_pc,
	input [7:0] PC_control,
	input [31:0] PCbranch,
	input [31:0] PCjump,
	input [31:0] PC,
	input [31:0] rs,
	input [31:0] rt,
	output [31:0] PCnext
	);
wire zero;
wire [31:0] PCbranch_jump;
wire bj;
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

assign PCnext=(exception_cmt)?32'hbfc00380:(eret_cmt==1'd1)?eret_pc:(bj==1'd1)?PCbranch_jump:(PC+32'd4);
endmodule