% 对cos和sin的迭代更新公式进行改进，使用移位和加法来动态更新目标阈值 T_i
% 该算法的误差较大

function [ar] = arcsin_improved(target)
    itr = 12;
    cosa = 0.60725293501;
    sina = 0;
    ar = 0;

    % 论文提出的算法：使用移位和加法来动态更新目标阈值 T_i
    % 初始化阈值 T。因为初始向量 X_0 被缩放为 0.60725293501，目标阈值也必须同步缩放
    T = target * 0.60725293501;

    for cnt = 0:itr-1
        tt = atan(2^(-cnt)); 
        tmp1 = (2^-cnt)*sina;
        tmp2 = (2^-cnt)*cosa;
        
        % 论文公式(16)：通过比较 Y_i (即 sina) 和当前迭代的 T_i (即 T) 来决定旋转方向 
        if sina >= T
            cosa = cosa + tmp1;
            sina = sina - tmp2; 
            ar = ar - tt;
        else
            cosa = cosa - tmp1;
            sina = sina + tmp2;   
            ar = ar + tt;
        end
        
        % 论文核心近似：使用移位和加法更新 T_i 
        % 对应数学公式: T_{i+1} = T_i + T_i * 2^{-2i-1}
        T = T + T * 2^(-2*cnt - 1) - T * 2^(-4*cnt - 3); 
    end
end