% record_xyzt_single_target.m
% 这是一个用于记录单个 target 在查表迭代过程中所有中间变量(X,Y,Z,T)的脚本并导出到CSV

clc; clear; close all;

% 1. 用户输入 target 值 (例如: 0.5)
target = input('请输入 target 值 (-1 到 1 之间, 默认 0.5): ');
if isempty(target)
    target = 0.5; % 默认值
end

% 2. 参数设置
M = 12; % 总迭代次数
exp_dp = 11; % target X Y T小数位宽
exp_ar = 9; % ar Z 小数位宽

% ===============================================================
% 定点化数据与初始值设置 (与 arcsin_fixed.m 保持一致)
INIT_XY = 1546;
INIT_Target = 2172;
INIT_Z  = 402;
angle_rom = [237, 125, 64, 32, 16, 8, 4, 2, 1, 0, 0];
% ===============================================================

% 3. 初始化变量
target_fix = round(target * 2^exp_dp);
is_negative = target_fix < 0;
abs_target = abs(target_fix); 

X = INIT_XY;
Y = INIT_XY;
Z = INIT_Z;
T = floor(abs_target * INIT_Target / 2^(exp_dp));

% 预分配记录数组：列包括 [Iteration, X, Y, Z, T]
% M次迭代（0到M-1次）
record_matrix = zeros(M, 5);

% 记录初始值 (定义为第0次迭代状态)
record_matrix(1, :) = [0, X, Y, Z, T]; 

% 4. 迭代过程
for i = 1:M-1
    X_current = X;
    Y_current = Y;
    X_shift = floor(X_current / 2^i);
    Y_shift = floor(Y_current / 2^i);
    T_shift = floor(T / (2^(2*i+1)));
    
    if Y < T
        X = X_current - Y_shift;
        Y = Y_current + X_shift;
        Z = Z + angle_rom(i);
        T = T + T_shift;
    else
        X = X_current + Y_shift;
        Y = Y_current - X_shift;
        Z = Z - angle_rom(i);
        T = T + T_shift;
    end
    
    % 记录每次迭代结束后的结果 (第 i 次迭代)
    record_matrix(i+1, :) = [i, X, Y, Z, T];
end

% 5. 处理最终符号并计算实际浮点值
if is_negative
    ar = -Z;
else
    ar = Z;
end
ar_real = ar / 2^exp_ar;

fprintf('\n==== 结果结算 ====\n');
fprintf('输入的 Target: %f\n', target);
fprintf('CORDIC 固定点解: %f\n', ar_real);
fprintf('MATLAB 真实解: %f\n', asin(target));

% 6. 保存结果到 CSV 文件
output_dir = 'report';
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

% 文件名附加上 target 值
output_file = fullfile(output_dir, sprintf('xyzt_iter_record_target_%.3f.csv', target));

% 转换为 Table 格式附加表头
T_out = array2table(record_matrix, 'VariableNames', {'Iteration_Index', 'X', 'Y', 'Z', 'T'});
writetable(T_out, output_file);

fprintf('\n=> 迭代过程已成功保存到文件: %s\n', output_file);
