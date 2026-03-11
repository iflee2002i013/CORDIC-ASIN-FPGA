clc;
clear;
close all;

%% 配置
% 输出文件路径
output_file = 'report/xyzt_record.csv';
if ~exist('report', 'dir')
    mkdir('report');
end

%% 参数设置 (与 arcsin_fix.m 保持一致)
M = 12; % 总迭代次数
exp_dp = 11; % 定点小数位宽
exp_ar = 9; % 定点化输出的位宽

% 预计算常数
A_M_prime = 1.0;
for i = 0:M-1
    A_M_prime = A_M_prime * (1 + 2^(-2*i-1)) / sqrt(1 + 2^(-2*i));
end
fprintf('A_M_prime = %.10f\n', A_M_prime);
INIT_XY = round((A_M_prime * cos(pi/4)) * 2^exp_dp);
INIT_Target = round((1.5 / sqrt(2)) * 2^exp_dp);
INIT_Z  = round((pi/4) * 2^exp_ar);

%% 构造测试输入
delt_sin = 2/2^12; % 步长
target_values = -0.95:0.05:0.95; % 测试点，可以根据需要修改密度
% target_values = [-0.5, 0.5]; % 简单测试

num_test_cases = length(target_values);

% 初始化结果存储矩阵
% 列定义: target_float, target_fix, X_final, Y_final, Z_final, T_final, ar_fix, ar_float
results = zeros(num_test_cases, 8);

%% 循环运行算法并记录
for k = 1:num_test_cases
    target_in = target_values(k);
    
    % ===============================================================
    % 算法核心逻辑 (来自 arcsin_fix.m)
    
    target_fix = round(target_in * 2^exp_dp);
    is_negative = target_fix < 0;
    abs_target = abs(target_fix); 
    
    X = INIT_XY;
    Y = INIT_XY;
    Z = INIT_Z; % 注意：这里 Z 是角度累加器
    
    % T 的初始值计算
    T = floor(abs_target * INIT_Target / 2^(exp_dp));
    
    % 迭代过程
    for i = 1:M-1
        if Y < T
            delta = 1;
        else
            delta = -1;
        end
        
        X_current = X;
        Y_current = Y;

        X_shift = floor(X_current / 2^i);
        Y_shift = floor(Y_current / 2^i);
        T_shift = floor(T / (2^(2*i+1)));

        X = X_current - delta * Y_shift;
        Y = Y_current + delta * X_shift;
        
        % 定点化 ROM表 (注意：atan(2^-i))
        angle_rom = round(atan(2^-i) * 2^exp_ar);

        Z = Z + delta * angle_rom;
        
        T = T + T_shift;
    end
    
    if is_negative
        ar_fix = -Z;
    else
        ar_fix = Z;
    end
    
    ar_float = ar_fix / 2^exp_ar;
    
    % ===============================================================
    
    % 记录结果
    results(k, :) = [target_in, target_fix, X, Y, Z, T, ar_fix, ar_float];
end

%% 保存结果到 CSV 表格
% 表头
headers = {'Target_Float', 'Target_Fix', 'X_Final', 'Y_Final', 'Z_Final', 'T_Final', 'AR_Fix', 'AR_Float'};

% 写入文件
fid = fopen(output_file, 'w');
fprintf(fid, '%s,%s,%s,%s,%s,%s,%s,%s\n', headers{1}, headers{2}, headers{3}, headers{4}, headers{5}, headers{6}, headers{7}, headers{8});
fclose(fid);

writematrix(results, output_file, 'WriteMode', 'append');

fprintf('处理完成。结果已保存至: %s\n', output_file);
disp('前 5 行数据预览:');
disp(headers);
disp(results(1:min(5, num_test_cases), :));
