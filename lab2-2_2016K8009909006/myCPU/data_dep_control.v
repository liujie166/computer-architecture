module data_dep_control(
	input [4:0] rs,
	input [4:0] rt,
	input [4:0] destE, 
	input [4:0] destM,
	input [4:0] destW,
	input memreadE,
	input memreadM,
	input memwrite,
	input rs_en,
	input rt_en,
	output stall,
	output [3:0] v1E_mux_control,
	output [3:0] v2E_mux_control,
	output [3:0] rtE_mux_control,
	output [3:0] rsE_mux_control
	);

assign stall = (memwrite|rs_en|rt_en)&
               (rs!=5'd0 & rs==destE & memreadE)|(rt!=5'd0 & rt==destE & memreadE)
              |(rs!=5'd0 & rs==destM & memreadM)|(rt!=5'd0 & rt==destM & memreadM);
              
assign rsE_mux_control = v1E_mux_control;
                           
assign rtE_mux_control[0] = ~memwrite|(rt==5'd0)|((rt!=destE)&(rt!=destM)&(rt!=destW));
assign rtE_mux_control[1] = (rt!=5'd0)&(rt==destE)&(~memreadE)&memwrite;
assign rtE_mux_control[2] = (rt!=5'd0)&(rt==destM)&(~memreadM)&memwrite;
assign rtE_mux_control[3] = (rt!=5'd0)&(rt==destW)&memwrite;

assign v1E_mux_control[0] = ~rs_en|(rs==5'd0)|((rs!=destE)&(rs!=destM)&(rs!=destW));
assign v1E_mux_control[1] = (rs!=5'd0)&(rs==destE)&(~memreadE)&rs_en;
assign v1E_mux_control[2] = (rs!=5'd0)&(rs==destM)&(~memreadM)&rs_en;
assign v1E_mux_control[3] = (rs!=5'd0)&(rs==destW)&rs_en;

assign v2E_mux_control[0] = ~rt_en|(rt==5'd0)|((rt!=destE)&(rt!=destM)&(rt!=destW));
assign v2E_mux_control[1] = (rt!=5'd0)&(rt==destE)&(~memreadE)&rt_en;
assign v2E_mux_control[2] = (rt!=5'd0)&(rt==destM)&(~memreadM)&rt_en;
assign v2E_mux_control[3] = (rt!=5'd0)&(rt==destW)&rt_en;
endmodule