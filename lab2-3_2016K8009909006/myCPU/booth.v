module booth(
	input [63:0] x,
	input y0,
	input y1,
	input y2,
	output c,
	output [63:0] p
	);
wire sub_x;
wire add_x;
wire sub_2x;
wire add_2x;
wire zero= 1'd0;
assign sub_x = ~(~(y2&y1&~y0)&~(y2&~y1&y0));
assign add_x = ~(~(~y2&y1&~y0)&~(~y2&~y1&y0));
assign sub_2x = ~(~(y2&~y1&~y0));
assign add_2x = ~(~(~y2&y1&y0));

assign p[0] = ~(~(sub_x&~x[0])&~(sub_2x&~zero)&~(add_x&x[0])&~(add_2x&zero));
genvar gi;
generate
    for(gi = 1;gi <64;gi = gi + 1) begin
        assign p[gi] =  ~(~(sub_x&~x[gi])&~(sub_2x&~x[gi-1])&~(add_x&x[gi])&~(add_2x&x[gi-1]));
    end
endgenerate
assign c = sub_2x|sub_x;
endmodule

