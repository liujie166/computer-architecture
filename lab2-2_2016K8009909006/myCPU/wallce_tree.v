module wallce_tree(
	input [16:0] src,
	input [13:0] cin,
	output [13:0] cout,
	output c,
	output s
	);

wire temp_s[13:0];
assign {cout[0],temp_s[0]} = src[16] + src[15] + src[14];
assign {cout[1],temp_s[1]} = src[13] + src[12] + src[11];
assign {cout[2],temp_s[2]} = src[10] + src[9] + src[8];
assign {cout[3],temp_s[3]} = src[7] + src[6] + src[5];
assign {cout[4],temp_s[4]} = src[4] + src[3] + src[2];

assign {cout[5],temp_s[5]} = temp_s[0] + temp_s[1] + temp_s[2];
assign {cout[6],temp_s[6]} = temp_s[3] + temp_s[4] + src[1];
assign {cout[7],temp_s[7]} = src[0] + cin[0] + cin[1];
assign {cout[8],temp_s[8]} = cin[2] + cin[3] + cin[4];

assign {cout[9],temp_s[9]} = temp_s[5] + temp_s[6] + temp_s[7];
assign {cout[10],temp_s[10]} = temp_s[8] + cin[5] + cin[6];

assign {cout[11],temp_s[11]} = temp_s[9] + temp_s[10] + cin[7];
assign {cout[12],temp_s[12]} = cin[8] + cin[9] + cin[10];

assign {cout[13],temp_s[13]} = temp_s[11] + temp_s[12] + cin[11];

assign {c,s} = temp_s[13] + cin[12] + cin[13];
endmodule
