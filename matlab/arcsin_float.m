% sina为输入的正弦值，ar为输出的反正弦值(即角度），cosa为cos(arcsin(sina))的值

function [ar] = arcsin_float(target)
    itr = 12;
    cosa = 0.60725293501;
    sina = 0;
    ar = 0;

    % 预计算每一步的瞬时模长补偿系数
    T_scale = zeros(1, itr);
    current_mag = 0.60725293501;
    for i = 0:itr-1
        T_scale(i+1) = current_mag;
        current_mag = current_mag * sqrt(1 + 2^(-2*i)); % 迭代过程中模长增大
    end

    for cnt = 0:itr-1
        tt = atan(2^(-cnt)); % tt = arctan(2^-cnt)
        tmp1 = (2^-cnt)*sina;
        tmp2 = (2^-cnt)*cosa;
        
        if sina >= target * T_scale(i+1)
            cosa = cosa + tmp1;
            sina = sina - tmp2; 
            ar = ar - tt;
        else
            cosa = cosa - tmp1;
            sina = sina + tmp2;   
            ar = ar + tt;
        end
    end
end
