function [tx_signals] = transmitter(data_bits, num_blocks, beta, M_p, initial_chaos)
% 输入:
%   data_bits     - 原始二进制数据
%   num_blocks    - 总块数
%   beta          - 块长度
%   M_p           - 每块承载的比特数
%   initial_chaos - 初始参考混沌序列
% 输出:
%   tx_signals    - 发送信号矩阵 (num_blocks x beta)

    tx_signals = zeros(num_blocks, beta);
    
    % 设置第一个块 
    tx_signals(1, :) = initial_chaos;
    current_block = initial_chaos;
    
    % 循环处理后续信息块
    for block_idx = 2:num_blocks
        start_bit = (block_idx-2) * M_p + 1;
        end_bit = min(start_bit + M_p - 1, length(data_bits));
        
        if start_bit > length(data_bits)
            break;
        end
        
        current_bits = data_bits(start_bit:end_bit);
        
        if length(current_bits) < M_p
            padding_len = M_p - length(current_bits);
            current_bits = [current_bits, zeros(1, padding_len)];
        end
        
        shift_amount = bi2de(current_bits);
        current_block = circshift(current_block, [0, shift_amount]);
        
        tx_signals(block_idx, :) = current_block;
        
        % fprintf('块 %d: 移位量 = %d\n', block_idx, shift_amount);
    end
end