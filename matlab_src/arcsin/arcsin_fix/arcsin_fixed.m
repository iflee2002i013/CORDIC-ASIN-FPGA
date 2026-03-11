% 最终定点化设计
function [ar] = arcsin_fixed(target)
    % 参数设置
    M = 12; % 总迭代次数
    exp_dp = 11; % target X Y T小数位宽
    exp_ar = 9; % ar Z 小数位宽
    
    % ===============================================================
    % 定点化数据
    A_M_prime = 2187; % 注意是10进制
    INIT_XY = 1546;
    INIT_Target = 2172;
    INIT_Z  = 402;

    angle_rom = [237, 125, 64, 32, 16, 8, 4, 2, 1, 0, 0];


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

        Z = Z + delta * angle_rom(i);
        
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