function [ar] = arcsin_proposed(target)
    % 参数设置
    M = 12; % 总迭代次数
    
    % 1. 预计算常数 A'_M (公式 18) [cite: 181]
    % 用于补偿近似增益与真实增益之间的微小差异 [cite: 180]
    A_M_prime = 1.0;
    for i = 0:M-1
        A_M_prime = A_M_prime * (1 + 2^(-2*i-1)) / sqrt(1 + 2^(-2*i));
    end
    
    % 2. 象限映射与绝对值处理 
    % 反正弦是奇函数，仅处理正数输入以缩小计算域，最后再恢复符号 [cite: 176, 178]
    is_negative = target < 0;
    abs_target = abs(target); 
    
    % 3. 算法初始化 (跳过 i=0 的首级迭代) [cite: 175]
    % 直接从 i=1 的状态开始，此时相位为 arctan(1) = pi/4 
    X = A_M_prime * cos(pi/4);
    Y = A_M_prime * sin(pi/4);
    Z = pi/4;
    
    % 目标阈值 T_0 = abs_target，由于跳过了 i=0，需要手动计算 T_1 [cite: 168, 177]
    % T_1 = T_0 + T_0 * 2^(-2*0-1) = T_0 * (1 + 2^-1)
    T = abs_target * (1 + 2^(-1)); 
    
    % 4. 核心微旋转计算 (从 i = 1 到 M-1) [cite: 210]
    for i = 1:M-1
        % 确定微旋转方向：比较当前 Y 分量与动态阈值 T [cite: 168]
        if Y < T
            delta = 1;
        else
            delta = -1;
        end
        
        % 记录当前步的 X 和 Y，避免在后续计算中相互覆盖
        X_current = X;
        Y_current = Y;
        
        % 更新 X, Y 和 Z (在硬件中等同于移位和加减法) [cite: 168]
        X = X_current - delta * Y_current * (2^-i);
        Y = Y_current + delta * X_current * (2^-i);
        Z = Z + delta * atan(2^-i);
        
        % 更新目标阈值 T (近似增益补偿，无需真实乘法器) [cite: 155, 166, 168]
        T = T + T * (2^(-2*i-1));
    end
    
    % 5. 符号恢复 [cite: 178]
    % 如果原始输入为负，则将结果移至第四象限 [cite: 178]
    if is_negative
        ar = -Z;
    else
        ar = Z;
    end
end