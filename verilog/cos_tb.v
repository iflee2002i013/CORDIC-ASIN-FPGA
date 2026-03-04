`timescale 1ns/1ps

module cos_tb;


//-------------------------------------------
//clk / rstn    
logic               clk         ;
logic               rstn        ;

int                 ii          ;

logic               trig        ;
wire                vld         ;

real                delta       ;
real                a           ;
logic       [10:0]  a_fix       ;

wire signed [12:0]  cosa_fix    ;
wire signed [12:0]  sina_fix    ;

real                cosa        ;
real                sina        ;

real                cosa_real   ;
real                sina_real   ;

real                err_cos     ;
real                err_sin     ;

real                max_ecos    ;
real                max_esin    ;



//-------------------------------------------
initial
begin
    $fsdbDumpfile("tb.fsdb");
    $fsdbDumpvars(0);
end


//-----------------------------------------------------------
initial
begin
    clk = 1'b0; 

    #30;
    forever 
    begin
        #(1e9/(2.0*20e6)) clk = ~clk;
    end
end


initial
begin
    rstn = 0;
    #60 rstn = 1;
end


initial
begin
    delta       = 0.006135923151543;
    a           = 0;
    a_fix       = 0;
    trig        = 1'b0;
    cosa_real   = 1;
    sina_real   = 0;
    cosa        = 1;
    sina        = 0;
    err_cos     = 0;
    err_sin     = 0;
    max_ecos    = 0;
    max_esin    = 0;

    @(posedge rstn);
    #700;
    
    for (a_fix = 0; a_fix < 1024; a_fix ++)
    begin
        @(posedge clk);
        trig      <= 1;
        a         <= real'(a_fix) * delta;

        fork
            begin
                @(posedge clk);
                trig <= 0;
            end

            begin
                @(negedge vld);
                cosa        = real'(cosa_fix)/2048;
                sina        = real'(sina_fix)/2048;
                cosa_real   = $cos(a);
                sina_real   = $sin(a);
                err_cos     <= $abs(cosa_real - cosa);
                err_sin     <= $abs(sina_real - sina);
                
                #1;
                if (max_ecos < err_cos)
                    max_ecos = err_cos;
                
                if (max_esin < err_sin)
                    max_esin = err_sin;
            end
        join
    end
    
    #100 $finish;
end



//------------------------------------------------------------
cos     u_cos
(
    .clk         (clk       ),//i        
    .rstn        (rstn      ),//i        

    .trig        (trig      ),//i        
    .vld         (vld       ),//o        

    .a           (a_fix     ),//i[9:0]   
    .cosa3_latch (cosa_fix  ),//o[12:0],signed    
    .sina3_latch (sina_fix  ) //o[12:0],signed      
);






endmodule
