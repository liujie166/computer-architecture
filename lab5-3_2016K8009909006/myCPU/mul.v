
module mul(
    input mul_clk,
    input resetn,
    input mul_signed,
    input [31:0] x,
    input [31:0] y,
    output signed [63:0] result
    );

wire [32:0] x33;
wire [32:0] y33;
assign x33 = (mul_signed==1'd1)?{x[31],x}:{1'd0,x};
assign y33 = (mul_signed==1'd1)?{y[31],y}:{1'd0,y};
wire [63:0] x64;
assign x64 = {{31{x33[32]}},x33[32:0]};

wire [63:0] p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17;
wire [16:0] cb;
booth booth1(.x(x64),.y0(1'd0),.y1(y33[0]),.y2(y33[1]),.c(cb[0]),.p(p1));
booth booth2(.x(x64<<6'd2),.y0(y33[1]),.y1(y33[2]),.y2(y33[3]),.c(cb[1]),.p(p2));
booth booth3(.x(x64<<6'd4),.y0(y33[3]),.y1(y33[4]),.y2(y33[5]),.c(cb[2]),.p(p3));
booth booth4(.x(x64<<6'd6),.y0(y33[5]),.y1(y33[6]),.y2(y33[7]),.c(cb[3]),.p(p4));
booth booth5(.x(x64<<6'd8),.y0(y33[7]),.y1(y33[8]),.y2(y33[9]),.c(cb[4]),.p(p5));
booth booth6(.x(x64<<6'd10),.y0(y33[9]),.y1(y33[10]),.y2(y33[11]),.c(cb[5]),.p(p6));
booth booth7(.x(x64<<6'd12),.y0(y33[11]),.y1(y33[12]),.y2(y33[13]),.c(cb[6]),.p(p7));
booth booth8(.x(x64<<6'd14),.y0(y33[13]),.y1(y33[14]),.y2(y33[15]),.c(cb[7]),.p(p8));
booth booth9(.x(x64<<6'd16),.y0(y33[15]),.y1(y33[16]),.y2(y33[17]),.c(cb[8]),.p(p9));
booth booth10(.x(x64<<6'd18),.y0(y33[17]),.y1(y33[18]),.y2(y33[19]),.c(cb[9]),.p(p10));
booth booth11(.x(x64<<6'd20),.y0(y33[19]),.y1(y33[20]),.y2(y33[21]),.c(cb[10]),.p(p11));
booth booth12(.x(x64<<6'd22),.y0(y33[21]),.y1(y33[22]),.y2(y33[23]),.c(cb[11]),.p(p12));
booth booth13(.x(x64<<6'd24),.y0(y33[23]),.y1(y33[24]),.y2(y33[25]),.c(cb[12]),.p(p13));
booth booth14(.x(x64<<6'd26),.y0(y33[25]),.y1(y33[26]),.y2(y33[27]),.c(cb[13]),.p(p14));
booth booth15(.x(x64<<6'd28),.y0(y33[27]),.y1(y33[28]),.y2(y33[29]),.c(cb[14]),.p(p15));
booth booth16(.x(x64<<6'd30),.y0(y33[29]),.y1(y33[30]),.y2(y33[31]),.c(cb[15]),.p(p16));
booth booth17(.x(x64<<6'd32),.y0(y33[31]),.y1(y33[32]),.y2(y33[32]),.c(cb[16]),.p(p17));
//switch
wire [16:0] tree_src [63:0];
reg [63:0] p1E,p2E,p3E,p4E,p5E,p6E,p7E,p8E,p9E,p10E,p11E,p12E,p13E,p14E,p15E,p16E,p17E;
reg [16:0] cE;
always @(posedge mul_clk) begin
    if(resetn)begin
        cE<=cb;
        p1E<=p1;
        p2E<=p2;
        p3E<=p3;
        p4E<=p4;
        p5E<=p5;
        p6E<=p6;
        p7E<=p7;
        p8E<=p8;
        p9E<=p9;
        p10E<=p10;
        p11E<=p11;
        p12E<=p12;
        p13E<=p13;
        p14E<=p14;
        p15E<=p15;
        p16E<=p16;
        p17E<=p17;
    end
end
wire [63:0] t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12,t13,t14,t15,t16,t17;
assign t1=p1E;
assign t2=p2E;
assign t3=p3E;
assign t4=p4E;
assign t5=p5E;
assign t6=p6E;
assign t7=p7E;
assign t8=p8E;
assign t9=p9E;
assign t10=p10E;
assign t11=p11E;
assign t12=p12E;
assign t13=p13E;
assign t14=p14E;
assign t15=p15E;
assign t16=p16E;
assign t17=p17E;
generate
    genvar gi;
    for(gi = 0;gi <64;gi = gi + 1) begin
        assign tree_src[gi]={t1[gi],t2[gi],t3[gi],t4[gi],t5[gi],t6[gi],t7[gi],t8[gi],t9[gi],t10[gi],t11[gi],t12[gi],t13[gi],t14[gi],t15[gi],t16[gi],t17[gi]};
    end
endgenerate
wire [63:0] s;
wire [63:0] c;
wire [13:0] out [63:0];

wallce_tree tree1(.src(tree_src[0]),.cin(cE[13:0]),.cout(out[0]),.c(c[0]),.s(s[0]));
generate
    genvar i;
    for(i=1;i<=63;i=i+1)
    begin : wallce
    wallce_tree tree(.src(tree_src[i]),.cin(out[i-1]),.cout(out[i]),.c(c[i]),.s(s[i]));
    end
endgenerate

assign result = s + {c[62:0],cE[14]} + cE[15];
endmodule
