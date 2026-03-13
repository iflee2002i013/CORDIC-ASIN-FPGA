% CORDIC-Based Computation of Arcsine and Arccosine Functions
% Reference: Paz & Garrido (2023)
function [theta_asin] = arcsin_proposed2(target)
    % ---------------------------------------------------------
    % 1. 预计算阶段 (在硬件中这些常数在综合时计算并硬连线)
    % ---------------------------------------------------------
    % 计算补偿增益 A'_M (公式 18)
    M = 12;
    Am_prime = 1.0;
    for i = 0:(M-1)
        real_gain = sqrt(1 + 2^(-2*i));
        approx_gain = 1 + 2^(-2*i - 1);
        Am_prime = Am_prime * (approx_gain / real_gain);
    end
    
    % 算法跳过了 i=0 的迭代，直接从 i=1 开始。
    % 初始化 X1, Y1, Z1 (公式 19)
    X1_init = Am_prime * cos(atan(1)); % 等价于 Am_prime / sqrt(2)
    Y1_init = Am_prime * sin(atan(1)); % 等价于 Am_prime / sqrt(2)
    Z1_init = atan(1);                 % 等价于 pi/4
    
    % ---------------------------------------------------------
    % 2. 输入处理阶段
    % ---------------------------------------------------------
    % 硬件优化：利用奇偶性和定义域，只处理绝对值
    val = abs(target);
    
    % 初始化 T1。因为跳过了 i=0，而 T0 = val，
    % 在 i=0 时，T 会经历一次计算：T1 = T0 + T0 * 2^(-1)
    T1_init = val + val * 2^(-1); 
    
    % ---------------------------------------------------------
    % 3. CORDIC 核心迭代引擎 (i = 1 到 M-1)
    % ---------------------------------------------------------
    % Arcsine 计算路径
    X_asin = X1_init; Y_asin = Y1_init; Z_asin = Z1_init; T_asin = T1_init;
    
    % Arccosine 计算路径
    X_acos = X1_init; Y_acos = Y1_init; Z_acos = Z1_init; T_acos = T1_init;
    
    for i = 1:(M-1)
        % --- Arcsine 迭代 (公式 16) ---
        if Y_asin < T_asin
            delta_asin = 1;
        else
            delta_asin = -1;
        end
        
        X_asin_next = X_asin - delta_asin * Y_asin * 2^(-i);
        Y_asin_next = Y_asin + delta_asin * X_asin * 2^(-i);
        Z_asin_next = Z_asin + delta_asin * atan(2^(-i));
        T_asin_next = T_asin + T_asin * 2^(-2*i - 1);
        
        X_asin = X_asin_next; Y_asin = Y_asin_next; 
        Z_asin = Z_asin_next; T_asin = T_asin_next;
        
        % --- Arccosine 迭代 (公式 17) ---
        if X_acos < T_acos
            delta_acos = 1;
        else
            delta_acos = -1;
        end
        
        X_acos_next = X_acos - delta_acos * Y_acos * 2^(-i);
        Y_acos_next = Y_acos + delta_acos * X_acos * 2^(-i);
        Z_acos_next = Z_acos + delta_acos * atan(2^(-i));
        T_acos_next = T_acos + T_acos * 2^(-2*i - 1);
        
        X_acos = X_acos_next; Y_acos = Y_acos_next; 
        Z_acos = Z_acos_next; T_acos = T_acos_next;
    end
    
    % ---------------------------------------------------------
    % 4. 象限恢复 (后处理)
    % ---------------------------------------------------------
    % Arcsine 恢复
    if target < 0
        theta_asin = -Z_asin;
    else
        theta_asin = Z_asin;
    end
    
    %% Arccosine 恢复
    %if target < 0
    %    theta_acos = pi - Z_acos;
    %else
    %    theta_acos = Z_acos;
    %end
    
end