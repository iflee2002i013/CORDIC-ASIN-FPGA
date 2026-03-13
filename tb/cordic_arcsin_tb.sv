// cordic_arcsin_tb.sv
`timescale 1ns/1ps

module cordic_arcsin_tb;

    // 引入常量包 (确保编译时包含了此包)
    import cordic_const_pkg::*;

    // -------------------------------------------------------------
    // 时钟与复位
    // -------------------------------------------------------------
    logic clk;
    logic rst_n;
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock
    end

    // -------------------------------------------------------------
    // DUT接口
    // -------------------------------------------------------------
    logic [SINA_W-1:0] sina;
    logic trig;
    logic signed [ARCSIN_SIGN_W-1:0] arcsina;
    logic vld;

    cordic_arcsin u_dut (
        .clk     (clk),
        .rst_n   (rst_n),
        .sina    (sina),
        .trig    (trig),
        .arcsina (arcsina),
        .vld     (vld)
    );

    // -------------------------------------------------------------
    // 测试数据读取与验证
    // -------------------------------------------------------------
    // 从txt读取基准数据
    localparam TEST_NUM = 39;
    int target_data [0:TEST_NUM-1];
    int expected_data [0:TEST_NUM-1];

    initial begin
        int fd_target;
        int fd_ar;
        int i, ret;
        int err_cnt = 0;

        // 1. 读取 输入 激励文件
        fd_target = $fopen("./matlab_src/arcsin/arcsin_fix/report/target_fix.txt", "r");
        if (fd_target == 0) begin
            $display("ERROR: 无法打开 target_fix.txt");
            $stop;
        end
        for (i = 0; i < TEST_NUM; i++) begin
            ret = $fscanf(fd_target, "%d\n", target_data[i]);
        end
        $fclose(fd_target);

        // 2. 读取 预期 输出文件
        fd_ar = $fopen("./matlab_src/arcsin/arcsin_fix/report/ar_fix.txt", "r");
        if (fd_ar == 0) begin
            $display("ERROR: 无法打开 ar_fix.txt");
            $stop;
        end
        for (i = 0; i < TEST_NUM; i++) begin
            ret = $fscanf(fd_ar, "%d\n", expected_data[i]);
        end
        $fclose(fd_ar);

        // 3. 初始状态
        rst_n = 0;
        trig  = 0;
        sina  = '0;
        #30;
        rst_n = 1;
        #20;


        // 4. 开始逐个激励注入并验证
        for (i = 0; i < TEST_NUM; i++) begin
            @(posedge clk);
            sina = target_data[i][SINA_W-1:0];
            trig = 1;
            
            @(posedge clk);
            trig = 0;

            // 等待完成信号 vld
            wait(vld == 1'b1);
            @(posedge clk); // 等待结果稳定

            // 对比输出数据
            if ($signed(arcsina) !== expected_data[i]) begin
                $display("FAIL [Case %0d]: 输入 sina = %d, 期望输出 = %d, 实际输出 = %d", 
                         i, target_data[i], expected_data[i], $signed(arcsina));
                err_cnt++;
            end else begin
                $display("PASS [Case %0d]: 输入 sina = %d, 输出正确 (%d)", 
                         i, target_data[i], $signed(arcsina));
            end
            
            // 随便等几拍再发下一个
            #20;
        end

        // 5. 打印测试结果
        $display("----------------------------------------");
        if (err_cnt == 0) begin
            $display("TEST PASSED: 所有 %0d 个测试用例均验证正确！", TEST_NUM);
        end else begin
            $display("TEST FAILED: 共有 %0d/%0d 个测试用例验证失败！", err_cnt, TEST_NUM);
        end
        $display("----------------------------------------");
        
        $finish;
    end

endmodule
