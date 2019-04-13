module memdata_change(
	input [31:0] origin_mem_wdata,
	input [31:0] origin_mem_rdata,
	input [1:0] eaM,
	input [1:0] eaW,
	input [31:0] rt,
	input [6:0] wdata_control,
	input [6:0] rdata_control,
	output [3:0] wdata_strb,
	output [31:0] mem_wdata,
	output [31:0] mem_rdata
	);
//rdata
wire [3:0] byte_selectW;
assign byte_selectW[0] = (eaW == 2'b00);
assign byte_selectW[1] = (eaW == 2'b01);
assign byte_selectW[2] = (eaW == 2'b10);
assign byte_selectW[3] = (eaW == 2'b11);
wire [1:0] half_selectW;
assign half_selectW[0] = (eaW[1] == 1'b0);
assign half_selectW[1] = (eaW[1] == 1'b1);

wire [7:0] rdata_b;
wire [15:0] rdata_h;
wire [31:0] rdata_left;
wire [31:0] rdata_right;
assign rdata_b = ({8{byte_selectW[0]}}&origin_mem_rdata[7:0]  )
				|({8{byte_selectW[1]}}&origin_mem_rdata[15:8] )
				|({8{byte_selectW[2]}}&origin_mem_rdata[23:16])
				|({8{byte_selectW[3]}}&origin_mem_rdata[31:24]);

assign rdata_h =  ({16{half_selectW[0]}}&origin_mem_rdata[15:0])
				 |({16{half_selectW[1]}}&origin_mem_rdata[31:16]);

assign rdata_left= ({32{byte_selectW[0]}}&{origin_mem_rdata[7:0],rt[23:0]}  )
				  |({32{byte_selectW[1]}}&{origin_mem_rdata[15:0],rt[15:0]} )
				  |({32{byte_selectW[2]}}&{origin_mem_rdata[23:0],rt[7:0]} )
				  |({32{byte_selectW[3]}}& origin_mem_rdata[31:0]           );

assign rdata_right = ({32{byte_selectW[3]}}&{rt[31:8],origin_mem_rdata[31:24]}  )
				    |({32{byte_selectW[2]}}&{rt[31:16],origin_mem_rdata[31:16]} )
				    |({32{byte_selectW[1]}}&{rt[31:24],origin_mem_rdata[31:8]}  )
				    |({32{byte_selectW[0]}}& origin_mem_rdata[31:0]             );

assign mem_rdata =    ({32{rdata_control[0]}}&origin_mem_rdata           )
                     |({32{rdata_control[1]}}&{{24{rdata_b[7]}},rdata_b} )
                     |({32{rdata_control[2]}}&{24'd0,rdata_b}            )
                     |({32{rdata_control[3]}}&{{16{rdata_h[15]}},rdata_h})
                     |({32{rdata_control[4]}}&{16'd0,rdata_h}            )
                     |({32{rdata_control[5]}}&rdata_left                 )
                     |({32{rdata_control[6]}}&rdata_right                );
//wdata
wire [3:0] byte_selectM;
assign byte_selectM[0] = (eaM == 2'b00);
assign byte_selectM[1] = (eaM == 2'b01);
assign byte_selectM[2] = (eaM == 2'b10);
assign byte_selectM[3] = (eaM == 2'b11);
wire [1:0] half_selectM;
assign half_selectM[0] = (eaM[1] == 1'b0);
assign half_selectM[1] = (eaM[1] == 1'b1);

assign wdata_strb[0] = wdata_control[0]|(wdata_control[1]&byte_selectM[0])|(wdata_control[3]&half_selectM[0])|wdata_control[5]|(wdata_control[6]&byte_selectM[0]);
assign wdata_strb[1] = wdata_control[0]|(wdata_control[1]&byte_selectM[1])|(wdata_control[3]&half_selectM[0])|(wdata_control[5]&(~byte_selectM[0]))|(wdata_control[6]&(byte_selectM[0]|byte_selectM[1]));
assign wdata_strb[2] = wdata_control[0]|(wdata_control[1]&byte_selectM[2])|(wdata_control[3]&half_selectM[1])|(wdata_control[5]&(byte_selectM[2]|byte_selectM[3]))|(wdata_control[6]&(~byte_selectM[3]));
assign wdata_strb[3] = wdata_control[0]|(wdata_control[1]&byte_selectM[3])|(wdata_control[3]&half_selectM[1])|(wdata_control[5]&byte_selectM[3])|wdata_control[6];
wire [4:0] shift;
assign shift = ({5{(wdata_control[5]&byte_selectM[0])|(wdata_control[6]&byte_selectM[3])}}&5'd24)
			  |({5{(wdata_control[5]&byte_selectM[1])|(wdata_control[6]&byte_selectM[2])}}&5'd16)
			  |({5{(wdata_control[5]&byte_selectM[2])|(wdata_control[6]&byte_selectM[1])}}&5'd8 )
			  |({5{(wdata_control[5]&byte_selectM[3])|(wdata_control[6]&byte_selectM[0])}}&5'd0 );


assign mem_wdata = ({32{wdata_control[0]}}&origin_mem_wdata)
	              |({32{wdata_control[1]}}&{4{origin_mem_wdata[7:0]}})
	              |({32{wdata_control[3]}}&{2{origin_mem_wdata[15:0]}})
	              |({32{wdata_control[5]}}&(origin_mem_wdata>>shift))
	              |({32{wdata_control[6]}}&(origin_mem_wdata<<shift));

endmodule
