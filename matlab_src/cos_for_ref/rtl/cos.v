// a 10b represent 360 deg
// cosa: 13=1+1+11
// sina: 13=1+1+11

module cos
(
    input                           clk         ,
    input                           rstn        ,
    
    input                           trig        ,
    output  reg                     vld         ,

    input                   [9:0]   a           ,
    output  reg     signed  [12:0]  cosa3_latch ,  
    output  reg     signed  [12:0]  sina3_latch             
);


//-----------------------------------------
reg         [3:0]   cnt         ;
reg                 vld_pre     ;

reg         [8:0]   a2          ;
reg  signed [15:0]  ar          ;
reg         [13:0]  tt          ;

reg  signed [14:0]  tmp1        ;
reg  signed [15:0]  tmp2        ;
reg  signed [16:0]  cosa        ;
reg  signed [16:0]  sina        ;
wire        [12:0]  cosa2_tmp   ;
wire        [12:0]  sina2_tmp   ;
wire        [11:0]  cosa2       ;
wire        [11:0]  sina2       ;
reg  signed [12:0]  cosa3       ;
reg  signed [12:0]  sina3       ;




// -----------------------------------------
always @(posedge clk or negedge rstn)
begin
    if (!rstn)
        cnt <= 4'd0;
    else
    begin
        if (trig)
            cnt <= 4'd1;
        else if ((cnt > 4'd0) & (cnt < 4'd14))
            cnt <= cnt + 4'd1;
        else
            cnt <= 4'd0;
    end
end


always @(posedge clk or negedge rstn)
begin
    if (!rstn)
        vld_pre <= 1'b0;
    else
        vld_pre <= (cnt == 4'd14);
end


always @(posedge clk or negedge rstn)
begin
    if (!rstn)
        vld <= 1'b0;
    else
        vld <= vld_pre;
end


always @(posedge clk or negedge rstn)
begin
    if (!rstn)
    begin
        cosa3_latch <= {1'b0,1'b1,11'd0};
        sina3_latch <= 13'd0;
    end
    else if (vld_pre)
    begin
        cosa3_latch <= cosa3;
        sina3_latch <= sina3;
    end
end





//data -----------------------------------------
//a2: 9=0+9+0
always @(*)
begin
    if (a < 10'd256)
        a2 = a;
    else if ((a >= 10'd256) & (a < 10'd512))
        a2 = 11'd512 - a;
    else if ((a >= 10'd512) & (a < 10'd768))
        a2 = a - 11'd512;
    else
        a2 = 11'd1024 - a;
end


//tmp1: 15=1+0+14
//tmp2: 16=1+0+15
always @(*)
begin
    case(cnt)
        4'd1:
        begin
            tmp1 = sina;
            tmp2 = cosa;
        end
        4'd2:
        begin
            tmp1 = sina>>>1;
            tmp2 = cosa>>>1;
        end
        4'd3:
        begin
            tmp1 = sina>>>2;
            tmp2 = cosa>>>2;
        end
        4'd4:
        begin
            tmp1 = sina>>>3;
            tmp2 = cosa>>>3;
        end
        4'd5:
        begin
            tmp1 = sina>>>4;
            tmp2 = cosa>>>4;
        end
        4'd6:
        begin
            tmp1 = sina>>>5;
            tmp2 = cosa>>>5;
        end
        4'd7:
        begin
            tmp1 = sina>>>6;
            tmp2 = cosa>>>6;
        end
        4'd8:
        begin
            tmp1 = sina>>>7;
            tmp2 = cosa>>>7;
        end
        4'd9:
        begin
            tmp1 = sina>>>8;
            tmp2 = cosa>>>8;
        end
        4'd10:
        begin
            tmp1 = sina>>>9;
            tmp2 = cosa>>>9;
        end
        4'd11:
        begin
            tmp1 = sina>>>10;
            tmp2 = cosa>>>10;
        end
        4'd12:
        begin
            tmp1 = sina>>>11;
            tmp2 = cosa>>>11;
        end
        4'd13:
        begin
            tmp1 = sina>>>12;
            tmp2 = cosa>>>12;
        end
        4'd14:
        begin
            tmp1 = sina>>>13;
            tmp2 = cosa>>>13;
        end
        default:      
        begin
            tmp1 = 15'd0;
            tmp2 = 16'd0;
        end
    endcase
end


//cosa: 17=1+1+15
//sina: 17=1+1+15
//ar:   16=1+9+6
always @(posedge clk or negedge rstn)
begin
    if (!rstn)
    begin
        cosa <= 17'd19898;
        sina <= 17'd0;
        ar   <= 16'd0;
    end
    else
    begin
        if (cnt == 4'd0)
        begin
            cosa <= 17'd19898;
            sina <= 17'd0;
            ar   <= {1'b0,a2,6'd0};
        end
        else
        begin
            if (~ar[15])
            begin
                cosa <= cosa - tmp1;
                sina <= sina + tmp2;
                ar   <= ar   - signed'({1'b0,tt});
            end
            else
            begin
                cosa <= cosa + tmp1;
                sina <= sina - tmp2;
                ar   <= ar   + signed'({1'b0,tt});
            end
        end
    end
end


always @(*)
begin
    case (cnt)
        4'd00  : tt = 14'd0;
        4'd01  : tt = 14'd8192;
        4'd02  : tt = 14'd4836;
        4'd03  : tt = 14'd2555;
        4'd04  : tt = 14'd1297;
        4'd05  : tt = 14'd651; 
        4'd06  : tt = 14'd326; 
        4'd07  : tt = 14'd163; 
        4'd08  : tt = 14'd81; 
        4'd09  : tt = 14'd41; 
        4'd10  : tt = 14'd20; 
        4'd11  : tt = 14'd10;     
        4'd12  : tt = 14'd5;  
        4'd13  : tt = 14'd3;  
        4'd14  : tt = 14'd1;  
        default: tt = 14'd0;
    endcase
end


//cosa2_tmp: 13=0+1+12
//sina2_tmp: 13=0+1+12
assign cosa2_tmp = (cosa>>>3) + signed'(14'd1);
assign sina2_tmp = (sina>>>3) + signed'(14'd1);


//cosa2: 12=0+1+11
//sina2: 12=0+1+11
assign cosa2 = cosa2_tmp >> 1;
assign sina2 = sina2_tmp >> 1;



//cosa3: 13=1+1+11
//sina3: 13=1+1+11
always @(*)
begin
    if (a < 10'd256)
    begin
        cosa3 = cosa2;
        sina3 = sina2;
    end
    else if ((a >= 10'd256) & (a < 10'd512))
    begin
        cosa3 = -cosa2;
        sina3 = sina2;
    end
    else if ((a >= 10'd512) & (a < 10'd768))
    begin
        cosa3 = -cosa2;
        sina3 = -sina2;
    end
    else
    begin
        cosa3 = cosa2;
        sina3 = -sina2;
    end
end







endmodule
