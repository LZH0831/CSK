function seq = generate_chaos_seq(beta, x0)
% 输入:
%   beta - 序列长度 
%   x0   - 初始值
% 输出:
%   seq  - 生成的混沌序列 

    seq = zeros(1, beta);
    x = x0;
    for n = 1:beta
        x = 1 - 2 * x^2;   
        seq(n) = x;
    end
end