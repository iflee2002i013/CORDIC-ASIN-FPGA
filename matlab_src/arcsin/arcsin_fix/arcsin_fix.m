% 基于改进的 CORDIC 算法实现反正弦函数，使用动态更新的目标阈值 T_i 来提高精度
function [ar] = arcsin_fix(target)
    % 参数设置
    M = 12; % 总迭代次数
    exp_dp = 11; % 定点小数位宽
    exp_ar = 9; % 定点化输出的位宽
    
    % ===============================================================
    % 定点化数据
    A_M_prime = 1.0;
    for i = 0:M-1
        A_M_prime = A_M_prime * (1 + 2^(-2*i-1)) / sqrt(1 + 2^(-2*i));
    end
    INIT_XY = round((A_M_prime * cos(pi/4)) * 2^exp_dp);
    INIT_Target = round((1.5 / sqrt(2)) * 2^exp_dp);
    INIT_Z  = round((pi/4) * 2^exp_ar);


    % ===============================================================
    target_fix = round(target * 2^exp_dp);
    is_negative = target_fix < 0;
    abs_target = abs(target_fix); 
    
    X = INIT_XY;
    Y = INIT_XY;
    Z = INIT_Z;
    
    T = floor(abs_target * INIT_Target / 2^(exp_dp));
    
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
        
        % 定点化 ROM表
        angle_rom = round(atan(2^-i) * 2^exp_ar);

        Z = Z + delta * angle_rom;
        
        T = T + T_shift;
    end
    
    if is_negative
        ar = -Z;
    else
        ar = Z;
    end

    % （可选）返回浮点真实值用于验证误差：
    ar = ar / 2^exp_ar;
end