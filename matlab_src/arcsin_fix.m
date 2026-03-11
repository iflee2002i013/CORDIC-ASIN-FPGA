% 对基于改进的CORDIC 算法进行初步定点化实现，使用动态更新的目标阈值 T_i 来提高精度
function [ar] = arcsin_fix(target)
    % 参数设置
    % ar = 正整数
    % A_M_prime = 符号位+1整数位+10小数位
    % target = 1+10(1个符号位+10个小数位)
    % T = 正整数
    M = 12; % 总迭代次数
    exp_in = 12; % 输入数据小数位宽，十进制的精度是 2^-12 ≈ 0.000244，足以覆盖误差范围
    exp_ar = 12; % 暑促数据小数位宽

    A_M_prime = 1.0;
        for i = 0:M-1
            A_M_prime = A_M_prime * (1 + 2^(-2*i-1)) / sqrt(1 + 2^(-2*i));
        end
    
    INIT_XY = round(A_M_prime * cos(pi/4) * 2^exp_in); % 定点化A_M_prime
    % 定点化T值
    T_SCALE = round((1.5 / sqrt(2)) * 2^(exp_in)); % 定点化T的比例因子

    INIT_Z = round((pi/4) * 2^exp_ar); % 定点并初始化Z

    % ===============================================================

    target_fix = round(target * 2^exp_in); % 定点化sin值
    is_negative = target_fix < 0;
    abs_target = abs(target_fix); 
    
    T = floor((abs_target * T_SCALE) / 2^exp_in); % 定点化初始T
    
    X = INIT_XY;
    Y = INIT_XY;
    Z = INIT_Z;

    for i = 1:M-1
        if Y < T
            delta = 1;
        else
            delta = -1;
        end
        
        X_current = X;
        Y_current = Y;

        % 模拟硬件移位
        X_shift = floor(X_current / 2^i);
        Y_shift = floor(Y_current / 2^i);

        % 模拟T的右移
        T_shift = floor(T / (2^(2*i + 1)));

        % 定点化 ROM表
        angle_rom = round(atan(2^-i) * 2^exp_ar);

        % 纯整数状态机更新
        X = X_current - delta * Y_shift;
        Y = Y_current + delta * X_shift;
        Z = Z + delta * angle_rom;

        T = T + T_shift; % 定点化T的更新
    end
    
    if is_negative
        ar = -Z;
    else
        ar = Z;
    end

    % （可选）返回浮点真实值用于验证误差：
    ar = ar / 2^exp_ar;
end