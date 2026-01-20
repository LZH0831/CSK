%% CSK系统 BER 性能仿真 - 不同 Beta 因子下 AWGN 与 Rayleigh 对比
clear; clc; close all;

%% 1. 全局仿真参数
% 研究对象：扩频因子列表
sim_global.beta_list = [128, 256, 512, 1024]; 

sim_global.min_errors = 100;    
sim_global.max_bits = 1e7;      
sim_global.EbN0_dB = 0:1:24;    % 步长设为2dB以避免图表过密
sim_global.x0 = 0.123456;       % 固定初始值 (按要求保持不变)
sim_global.blocks_per_batch = 20;  

% 定义两种信道配置
configs = {
    struct('channel_type', 'AWGN', 'linestyle', '--', 'marker', 'o', 'name', 'AWGN'), ...
    struct('channel_type', 'Rayleigh', 'linestyle', '-', 'marker', 's', 'name', 'Rayleigh') ...
};

% 瑞利信道具体参数
rayleigh_cfg.L = 2;
rayleigh_cfg.delays = [0, 1];
rayleigh_cfg.powers = [0.5, 0.5];

num_betas = length(sim_global.beta_list);
num_configs = length(configs);
num_snr = length(sim_global.EbN0_dB);

% 使用三维矩阵存储结果: [Beta维度, 信道维度, SNR维度]
BER_results = zeros(num_betas, num_configs, num_snr);

fprintf('=== CSK Beta 因子影响分析 (AWGN + Rayleigh) ===\n');
fprintf('Beta 列表: %s\n', mat2str(sim_global.beta_list));

%% 2. 仿真主循环
for b_idx = 1:num_betas
    current_beta = sim_global.beta_list(b_idx);
    
    % 1. 动态计算当前 Beta 下的参数
    M_p = floor(log2(current_beta)); 
    bits_per_batch = (sim_global.blocks_per_batch - 1) * M_p;
    
    % 2. 生成初始混沌序列 (固定 x0)
    initial_chaos = generate_chaos_seq(current_beta, sim_global.x0);
    
    fprintf('\n>> [进度 %d/%d] 正在仿真 Beta = %3d (M_p=%d)...\n', ...
        b_idx, num_betas, current_beta, M_p);
    
    % --- 信道配置循环 (AWGN / Rayleigh) ---
    for cfg_idx = 1:num_configs
        curr_cfg = configs{cfg_idx};
        fprintf('   正在运行信道: %s ...\n', curr_cfg.name);
        
        % --- SNR 循环 ---
        for snr_idx = 1:num_snr
            EbN0_dB = sim_global.EbN0_dB(snr_idx);
            
            total_errors = 0;
            total_bits = 0;
            batch_count = 0;
            
            % 最小批次设置：Rayleigh 信道通常需要更多样本来平滑衰落
            if strcmp(curr_cfg.channel_type, 'Rayleigh')
                min_batches = 10000; 
            else
                min_batches = 1000; % AWGN 收敛快，可以少跑点
            end
    
            while (total_errors < sim_global.min_errors || batch_count < min_batches) ...
                    && total_bits < sim_global.max_bits
                
                batch_count = batch_count + 1;
                
                % 生成数据
                batch_data = randi([0, 1], 1, bits_per_batch);
                
                % 发射机
                tx_matrix = transmitter(batch_data, sim_global.blocks_per_batch, ...
                                        current_beta, M_p, initial_chaos);
                
                % 1. 确定 CP 长度 (必须大于信道最大时延)
                if strcmp(curr_cfg.channel_type, 'Rayleigh')
                    L_cp = max(rayleigh_cfg.delays); 
                else
                    L_cp = 0; % AWGN 信道理论上不需要，但为了代码统一也可以设为0
                end
                
                % 2. 拼接 CP: 取每行最后 L_cp 个点，放到行首
                % tx_matrix 维度: [blocks, beta] -> [blocks, L_cp + beta]
                if L_cp > 0
                    tx_matrix_cp = [tx_matrix(:, end-L_cp+1:end), tx_matrix];
                else
                    tx_matrix_cp = tx_matrix;
                end
                
                % 3. 串行化 (注意现在包含了 CP)
                tx_serial = reshape(tx_matrix_cp.', 1, []);        
    
                % 通过信道
                if strcmp(curr_cfg.channel_type, 'Rayleigh')
                    rx_serial = Multipath_Rayleigh_Channel(tx_serial, EbN0_dB, ...
                                current_beta, M_p, rayleigh_cfg);
                else
                    [rx_serial, ~] = AWGN_Channel(tx_serial, EbN0_dB, ...
                                     current_beta, M_p);
                end
                
                % 接收机
                % 1. 截断接收信号 (防止信道卷积导致长度变长，只取只要的部分)
                % 我们的发送长度是 length(tx_serial)，接收长度应对齐
                rx_serial = rx_serial(1:length(tx_serial));
                
                % 2. 反串行化: 恢复为矩阵 [blocks, L_cp + beta]
                % 注意这里第二个维度是 current_beta + L_cp
                rx_matrix_cp = reshape(rx_serial, current_beta + L_cp, []).';
                
                % 3. 去掉 CP: 丢弃每行的前 L_cp 个点
                if L_cp > 0
                    rx_matrix = rx_matrix_cp(:, L_cp+1:end);
                else
                    rx_matrix = rx_matrix_cp;
                end
                % 现在 rx_matrix 恢复为 [blocks, beta]，且已通过 CP 吸收了 ISI
                rec_bits_raw = receiver(rx_matrix, sim_global.blocks_per_batch, M_p);
                rec_bits = rec_bits_raw(1:length(batch_data));
                
                % 统计错误
                curr_errs = sum(abs(batch_data - rec_bits));
                total_errors = total_errors + curr_errs;
                total_bits = total_bits + length(batch_data);
            end
            
            % 记录 BER
            if total_bits > 0
                BER_results(b_idx, cfg_idx, snr_idx) = total_errors / total_bits;
            else
                BER_results(b_idx, cfg_idx, snr_idx) = 0;
            end
            
            % 简略日志输出
             fprintf('      Eb/N0=%4.1f | BER=%.2e (%s)\n', ...
                EbN0_dB, BER_results(b_idx, cfg_idx, snr_idx), curr_cfg.name);
            
            % 优化：检测到 0 误码自动跳过当前配置的后续 SNR
            if total_errors == 0 && total_bits >= sim_global.max_bits
                fprintf('      >>> Eb/N0=%.1f 检测到 BER=0, 跳过后续点。\n', EbN0_dB);
                break; 
            end
        end
    end
end

%% 3. 绘图对比分析
figure('Name', 'Beta Impact: AWGN vs Rayleigh', 'Color', 'w', 'NumberTitle', 'off');

% 定义颜色列表 (对应不同的 Beta)
colors = {'b', 'r', 'k', 'm'}; % 蓝, 红, 黑, 紫

legend_str = {};
plot_handles = [];

for b_idx = 1:num_betas
    beta_val = sim_global.beta_list(b_idx);
    color = colors{mod(b_idx-1, length(colors))+1};
    
    for cfg_idx = 1:num_configs
        cfg = configs{cfg_idx};
        
        % 提取当前 Beta 和 当前信道 的 BER 曲线
        current_ber = reshape(BER_results(b_idx, cfg_idx, :), 1, []);
        
        % 绘图
        h = semilogy(sim_global.EbN0_dB, current_ber, ...
            [cfg.linestyle, cfg.marker], ...
            'Color', color, ...
            'LineWidth', 1.5, ...
            'MarkerSize', 6, ...
            'MarkerFaceColor', color);
        hold on;
        
        % 收集图例句柄 (为了图例整洁，这里只收集非零数据点，防止空句柄报错)
        % 但通常直接加进去即可
        plot_handles(end+1) = h;
        legend_str{end+1} = sprintf('\\beta=%d (%s)', beta_val, cfg.name);
    end
end

grid on;
title('BER Performance vs Beta (AWGN & Multipath Rayleigh)');
xlabel('E_b/N_0 (dB)');
ylabel('Bit Error Rate (BER)');
legend(plot_handles, legend_str, 'Location', 'southwest', 'FontSize', 9, 'NumColumns', 2);
axis([min(sim_global.EbN0_dB) max(sim_global.EbN0_dB) 1e-6 1]);

fprintf('\n=== 仿真完成 ===\n');