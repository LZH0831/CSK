% CSK-DCSK 系统
clear; clc; close all;
%% 参数设置
beta = 512;        
num_blocks = 10;   
x0 = 0.123456;     
%% 系统容量
M_p = floor(log2(beta));
total_bits = (num_blocks - 1) * M_p;
%% 生成随机测试数据
data_bits = randi([0, 1], 1, total_bits);
fprintf('原始数据比特:\n');
disp(reshape(data_bits, M_p, [])');

%%发射机
transmitted_signals = zeros(num_blocks, beta);

%第一个块
%fprintf('生成初始混沌参考序列...\n');
initial_chaos = zeros(1, beta);
x = x0;
for n = 1:beta
    x = 1 - 2 * x^2;   
    initial_chaos(n) = x;
end
transmitted_signals(1, :) = initial_chaos;
fprintf('块 1: 初始参考序列 (无信息)\n');

% 后面信息承载块
current_block = initial_chaos;
for block_idx = 2:num_blocks
    start_bit = (block_idx-2) * M_p + 1;
    end_bit = min(start_bit + M_p - 1, length(data_bits));
    
    if start_bit > length(data_bits)
        break;
    end
    
    current_bits = data_bits(start_bit:end_bit);
  
    if length(current_bits) < M_p
        current_bits = [current_bits, zeros(1, M_p - length(current_bits))];
    end
    
    shift_amount = bi2de(current_bits,'left-msb');
    
    current_block = circshift(current_block, [0, shift_amount]);
    transmitted_signals(block_idx, :) = current_block;
    
    fprintf('块 %d: 移位量 = %d, 承载比特 = ', block_idx, shift_amount);
    fprintf('%d ', current_bits);
    fprintf('\n');
end

%% ==================== 理想信道 ====================
fprintf('\n=== 理想信道传输 ===\n');
fprintf('无噪声，无损耗...\n');
received_signals = transmitted_signals; % 完美接收

%%接收机
recovered_bits = [];
fprintf('每个块承载比特数: %d\n', M_p);

for block_idx = 2:num_blocks
    prev_block = received_signals(block_idx-1, :);
    curr_block = received_signals(block_idx, :);
    % 频域差分相关检测
    % ifft(conj(fft(R_i)) .* fft(R_(i+1)))
    fft_prev = fft(prev_block);
    fft_curr = fft(curr_block);
    correlation = ifft(conj(fft_prev) .* fft_curr);
    
    [max_corr, peak_position] = max(abs(correlation));
    estimated_shift = peak_position - 1;

    current_bits = de2bi(estimated_shift, M_p,'left-msb');
    recovered_bits = [recovered_bits, current_bits];
    
    fprintf('块 %d: 检测移位量 = %d, 恢复比特 = ', block_idx, estimated_shift);
    fprintf('%d ', current_bits);
    fprintf('(相关峰值: %.4f)\n', max_corr);
end

