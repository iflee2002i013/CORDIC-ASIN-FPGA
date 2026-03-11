clc;
clear;
close all;

%% 配置
% 输出文件路径
output_dir = 'report';
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end
output_file = fullfile(output_dir, 'xyzt_record_proposed.csv');

%% 参数设置 (与 arcsin_proposed.m 保持一致)
M = 12; % 总迭代次数

% 1. 预计算常数 A'_M
A_M_prime = 1.0;
for i = 0:M-1
    A_M_prime = A_M_prime * (1 + 2^(-2*i-1)) / sqrt(1 + 2^(-2*i));
end

%% 构造测试输入
target_values = -0.95:0.05:0.95; % 测试点，可以根据需要修改密度
num_test_cases = length(target_values);

% 初始化结果存储矩阵
% 列定义: Target, X_final, Y_final, Z_final, T_final, Ar
results = zeros(num_test_cases, 6);

%% 循环运行算法并记录
for k = 1:num_test_cases
    target_in = target_values(k);
    
    % ===============================================================
    % 算法核心逻辑 (来自 arcsin_proposed.m)
    
    % 2. 象限映射与绝对值处理 
    is_negative = target_in < 0;
    abs_target = abs(target_in); 
    
    % 3. 算法初始化 (跳过 i=0 的首级迭代)
    X = A_M_prime * cos(pi/4);
    Y = X;
    Z = pi/4;
    
    % T_1 = T_0 + T_0 * 2^(-2*0-1) = T_0 * (1 + 2^-1)
    T = abs_target * (1.5 / sqrt(2));
    
    % 4. 核心微旋转计算 (从 i = 1 到 M-1)
    for i = 1:M-1
        % 确定微旋转方向
        if Y < T
            delta = 1;
        else
            delta = -1;
        end
        
        % 记录当前步的 X 和 Y
        X_current = X;
        Y_current = Y;
        
        % 更新 X, Y 和 Z
        X = X_current - delta * Y_current * (2^-i);
        Y = Y_current + delta * X_current * (2^-i);
        Z = Z + delta * atan(2^-i);
        
        % 更新目标阈值 T
        T = T + T * (2^(-2*i-1));
    end
    
    % 5. 符号恢复
    if is_negative
        ar = -Z;
    else
        ar = Z;
    end
    
    % ===============================================================
    
    % 记录结果
    results(k, :) = [target_in, X, Y, Z, T, ar];
end

%% 保存结果到 CSV 表格
% 表头
headers = {'Target', 'X_Final', 'Y_Final', 'Z_Final', 'T_Final', 'Ar'};

% 写入文件
fid = fopen(output_file, 'w');
fprintf(fid, '%s,%s,%s,%s,%s,%s\n', headers{1}, headers{2}, headers{3}, headers{4}, headers{5}, headers{6});
fclose(fid);

writematrix(results, output_file, 'WriteMode', 'append');

fprintf('处理完成。结果已保存至: %s\n', output_file);
disp('前 5 行数据预览:');
disp(headers);
disp(results(1:min(5, num_test_cases), :));
