
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
    if(~resetn)begin
        cE<=17'd0;
        p1E<=64'd0;
        p2E<=64'd0;
        p3E<=64'd0;
        p4E<=64'd0;
        p5E<=64'd0;
        p6E<=64'd0;
        p7E<=64'd0;
        p8E<=64'd0;
        p9E<=64'd0;
        p10E<=64'd0;
        p11E<=64'd0;
        p12E<=64'd0;
        p13E<=64'd0;
        p14E<=64'd0;
        p15E<=64'd0;
        p16E<=64'd0;
        p17E<=64'd0;  
    end
    else begin
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

genvar gi;
generate
    for(gi = 0;gi <64;gi = gi + 1) begin
        assign tree_src[gi]={t1[gi],t2[gi],t3[gi],t4[gi],t5[gi],t6[gi],t7[gi],t8[gi],t9[gi],t10[gi],t11[gi],t12[gi],t13[gi],t14[gi],t15[gi],t16[gi],t17[gi]};
    end
endgenerate
wire [63:0] s;
wire [63:0] c;
wire [13:0] out [63:0];
wallce_tree tree1(.src(tree_src[0]),.cin(cE[13:0]),.cout(out[0]),.c(c[0]),.s(s[0]));
wallce_tree tree2(.src(tree_src[1]),.cin(out[0]),.cout(out[1]),.c(c[1]),.s(s[1]));
wallce_tree tree3(.src(tree_src[2]),.cin(out[1]),.cout(out[2]),.c(c[2]),.s(s[2]));
wallce_tree tree4(.src(tree_src[3]),.cin(out[2]),.cout(out[3]),.c(c[3]),.s(s[3]));
wallce_tree tree5(.src(tree_src[4]),.cin(out[3]),.cout(out[4]),.c(c[4]),.s(s[4]));
wallce_tree tree6(.src(tree_src[5]),.cin(out[4]),.cout(out[5]),.c(c[5]),.s(s[5]));
wallce_tree tree7(.src(tree_src[6]),.cin(out[5]),.cout(out[6]),.c(c[6]),.s(s[6]));
wallce_tree tree8(.src(tree_src[7]),.cin(out[6]),.cout(out[7]),.c(c[7]),.s(s[7]));
wallce_tree tree9(.src(tree_src[8]),.cin(out[7]),.cout(out[8]),.c(c[8]),.s(s[8]));
wallce_tree tree10(.src(tree_src[9]),.cin(out[8]),.cout(out[9]),.c(c[9]),.s(s[9]));
wallce_tree tree11(.src(tree_src[10]),.cin(out[9]),.cout(out[10]),.c(c[10]),.s(s[10]));
wallce_tree tree12(.src(tree_src[11]),.cin(out[10]),.cout(out[11]),.c(c[11]),.s(s[11]));
wallce_tree tree13(.src(tree_src[12]),.cin(out[11]),.cout(out[12]),.c(c[12]),.s(s[12]));
wallce_tree tree14(.src(tree_src[13]),.cin(out[12]),.cout(out[13]),.c(c[13]),.s(s[13]));
wallce_tree tree15(.src(tree_src[14]),.cin(out[13]),.cout(out[14]),.c(c[14]),.s(s[14]));
wallce_tree tree16(.src(tree_src[15]),.cin(out[14]),.cout(out[15]),.c(c[15]),.s(s[15]));
wallce_tree tree17(.src(tree_src[16]),.cin(out[15]),.cout(out[16]),.c(c[16]),.s(s[16]));
wallce_tree tree18(.src(tree_src[17]),.cin(out[16]),.cout(out[17]),.c(c[17]),.s(s[17]));
wallce_tree tree19(.src(tree_src[18]),.cin(out[17]),.cout(out[18]),.c(c[18]),.s(s[18]));
wallce_tree tree20(.src(tree_src[19]),.cin(out[18]),.cout(out[19]),.c(c[19]),.s(s[19]));
wallce_tree tree21(.src(tree_src[20]),.cin(out[19]),.cout(out[20]),.c(c[20]),.s(s[20]));
wallce_tree tree22(.src(tree_src[21]),.cin(out[20]),.cout(out[21]),.c(c[21]),.s(s[21]));
wallce_tree tree23(.src(tree_src[22]),.cin(out[21]),.cout(out[22]),.c(c[22]),.s(s[22]));
wallce_tree tree24(.src(tree_src[23]),.cin(out[22]),.cout(out[23]),.c(c[23]),.s(s[23]));
wallce_tree tree25(.src(tree_src[24]),.cin(out[23]),.cout(out[24]),.c(c[24]),.s(s[24]));
wallce_tree tree26(.src(tree_src[25]),.cin(out[24]),.cout(out[25]),.c(c[25]),.s(s[25]));
wallce_tree tree27(.src(tree_src[26]),.cin(out[25]),.cout(out[26]),.c(c[26]),.s(s[26]));
wallce_tree tree28(.src(tree_src[27]),.cin(out[26]),.cout(out[27]),.c(c[27]),.s(s[27]));
wallce_tree tree29(.src(tree_src[28]),.cin(out[27]),.cout(out[28]),.c(c[28]),.s(s[28]));
wallce_tree tree30(.src(tree_src[29]),.cin(out[28]),.cout(out[29]),.c(c[29]),.s(s[29]));
wallce_tree tree31(.src(tree_src[30]),.cin(out[29]),.cout(out[30]),.c(c[30]),.s(s[30]));
wallce_tree tree32(.src(tree_src[31]),.cin(out[30]),.cout(out[31]),.c(c[31]),.s(s[31]));
wallce_tree tree33(.src(tree_src[32]),.cin(out[31]),.cout(out[32]),.c(c[32]),.s(s[32]));
wallce_tree tree34(.src(tree_src[33]),.cin(out[32]),.cout(out[33]),.c(c[33]),.s(s[33]));
wallce_tree tree35(.src(tree_src[34]),.cin(out[33]),.cout(out[34]),.c(c[34]),.s(s[34]));
wallce_tree tree36(.src(tree_src[35]),.cin(out[34]),.cout(out[35]),.c(c[35]),.s(s[35]));
wallce_tree tree37(.src(tree_src[36]),.cin(out[35]),.cout(out[36]),.c(c[36]),.s(s[36]));
wallce_tree tree38(.src(tree_src[37]),.cin(out[36]),.cout(out[37]),.c(c[37]),.s(s[37]));
wallce_tree tree39(.src(tree_src[38]),.cin(out[37]),.cout(out[38]),.c(c[38]),.s(s[38]));
wallce_tree tree40(.src(tree_src[39]),.cin(out[38]),.cout(out[39]),.c(c[39]),.s(s[39]));
wallce_tree tree41(.src(tree_src[40]),.cin(out[39]),.cout(out[40]),.c(c[40]),.s(s[40]));
wallce_tree tree42(.src(tree_src[41]),.cin(out[40]),.cout(out[41]),.c(c[41]),.s(s[41]));
wallce_tree tree43(.src(tree_src[42]),.cin(out[41]),.cout(out[42]),.c(c[42]),.s(s[42]));
wallce_tree tree44(.src(tree_src[43]),.cin(out[42]),.cout(out[43]),.c(c[43]),.s(s[43]));
wallce_tree tree45(.src(tree_src[44]),.cin(out[43]),.cout(out[44]),.c(c[44]),.s(s[44]));
wallce_tree tree46(.src(tree_src[45]),.cin(out[44]),.cout(out[45]),.c(c[45]),.s(s[45]));
wallce_tree tree47(.src(tree_src[46]),.cin(out[45]),.cout(out[46]),.c(c[46]),.s(s[46]));
wallce_tree tree48(.src(tree_src[47]),.cin(out[46]),.cout(out[47]),.c(c[47]),.s(s[47]));
wallce_tree tree49(.src(tree_src[48]),.cin(out[47]),.cout(out[48]),.c(c[48]),.s(s[48]));
wallce_tree tree50(.src(tree_src[49]),.cin(out[48]),.cout(out[49]),.c(c[49]),.s(s[49]));
wallce_tree tree51(.src(tree_src[50]),.cin(out[49]),.cout(out[50]),.c(c[50]),.s(s[50]));
wallce_tree tree52(.src(tree_src[51]),.cin(out[50]),.cout(out[51]),.c(c[51]),.s(s[51]));
wallce_tree tree53(.src(tree_src[52]),.cin(out[51]),.cout(out[52]),.c(c[52]),.s(s[52]));
wallce_tree tree54(.src(tree_src[53]),.cin(out[52]),.cout(out[53]),.c(c[53]),.s(s[53]));
wallce_tree tree55(.src(tree_src[54]),.cin(out[53]),.cout(out[54]),.c(c[54]),.s(s[54]));
wallce_tree tree56(.src(tree_src[55]),.cin(out[54]),.cout(out[55]),.c(c[55]),.s(s[55]));
wallce_tree tree57(.src(tree_src[56]),.cin(out[55]),.cout(out[56]),.c(c[56]),.s(s[56]));
wallce_tree tree58(.src(tree_src[57]),.cin(out[56]),.cout(out[57]),.c(c[57]),.s(s[57]));
wallce_tree tree59(.src(tree_src[58]),.cin(out[57]),.cout(out[58]),.c(c[58]),.s(s[58]));
wallce_tree tree60(.src(tree_src[59]),.cin(out[58]),.cout(out[59]),.c(c[59]),.s(s[59]));
wallce_tree tree61(.src(tree_src[60]),.cin(out[59]),.cout(out[60]),.c(c[60]),.s(s[60]));
wallce_tree tree62(.src(tree_src[61]),.cin(out[60]),.cout(out[61]),.c(c[61]),.s(s[61]));
wallce_tree tree63(.src(tree_src[62]),.cin(out[61]),.cout(out[62]),.c(c[62]),.s(s[62]));
wallce_tree tree64(.src(tree_src[63]),.cin(out[62]),.cout(out[63]),.c(c[63]),.s(s[63]));



assign result = s + {c[62:0],cE[14]} + cE[15];
    


/*reg mul_signedM;
reg [31:0] xM,yM;
always @(posedge mul_clk) begin
	if (~resetn) begin
		// reset
		xM<=32'd0;
		yM<=32'd0;
		mul_signedM<=1'd0;
	end
	else  begin
		xM<=x;
		yM<=y;
		mul_signedM<=mul_signed;
	end

end
wire signed [32:0] x33;
wire signed [32:0] y33;
assign x33 = {mul_signedM & xM[31],xM};
assign y33 = {mul_signedM & yM[31],yM};
assign result = x33*y33;
endmodule
*/
endmodule
