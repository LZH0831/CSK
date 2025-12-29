%% CSK-DCSK 系统 BER 性能仿真 
clear; clc; close all;

%% 1. 全局仿真参数
sim_global.beta = 512;          
sim_global.min_errors = 100;    
sim_global.max_bits = 1e7;      
sim_global.EbN0_dB = 0:1:24;   
sim_global.x0 = 0.123456;       
sim_global.blocks_per_batch = 20;  

configs = {
    struct('channel_type', 'AWGN', 'color', 'b', 'marker', 'o', 'name', 'AWGN Channel'), ...
    struct('channel_type', 'Rayleigh', 'color', 'r', 'marker', 's', 'name', 'Multipath Rayleigh') ...
};

rayleigh_cfg.L = 2;
rayleigh_cfg.delays = [0, 5];
rayleigh_cfg.powers = [0.5, 0.5];

num_configs = length(configs);
num_snr = length(sim_global.EbN0_dB);
BER_results = zeros(num_configs, num_snr);

fprintf('=== CSK-DCSK 系统 BER 仿真启动 ===\n');
fprintf('扩频因子(Beta): %d\n', sim_global.beta);
fprintf('停止准则: 累计错误 >= %d 或 总比特 >= %.1e\n', ...
    sim_global.min_errors, sim_global.max_bits);

h_bar = waitbar(0, '初始化仿真...');

%% 2. 仿真主循环
initial_chaos = generate_chaos_seq(sim_global.beta, sim_global.x0);

M_p = floor(log2(sim_global.beta));    
bits_per_batch = (sim_global.blocks_per_batch - 1) * M_p;

for cfg_idx = 1:num_configs
    curr_cfg = configs{cfg_idx};
    fprintf('\n正在仿真配置 [%s] ...\n', curr_cfg.name);
    
    for snr_idx = 1:num_snr
        EbN0_dB = sim_global.EbN0_dB(snr_idx);
        
        total_errors = 0;
        total_bits = 0;
        batch_count=0;
        
        progress = ((cfg_idx-1)*num_snr + snr_idx) / (num_configs*num_snr);
        waitbar(progress, h_bar, ...
            sprintf('配置 %d/%d | SNR %.1f dB | 搜集错误中...', ...
            cfg_idx, num_configs, EbN0_dB));
        
            min_batches = 10000; 

       while (total_errors < sim_global.min_errors || batch_count < min_batches) ...
            && total_bits < sim_global.max_bits
            
            batch_count = batch_count + 1;
            
            % 1. 生成随机数据
            batch_data = randi([0, 1], 1, bits_per_batch);
            
            % 2. 发射机
            tx_matrix = transmitter(batch_data, sim_global.blocks_per_batch, ...
                                        sim_global.beta, M_p, initial_chaos);
            
            tx_serial = reshape(tx_matrix.', 1, []);            
            % 3. 信道传输
            if strcmp(curr_cfg.channel_type, 'Rayleigh')
                rx_serial = Multipath_Rayleigh_Channel(tx_serial, EbN0_dB, ...
                            sim_global.beta, M_p, rayleigh_cfg);
            else
                [rx_serial, ~] = AWGN_Channel(tx_serial, EbN0_dB, ...
                                 sim_global.beta, M_p);
            end
            
            % 4. 接收机
            rx_matrix = reshape(rx_serial, sim_global.beta, []).';
            
            rec_bits_raw = receiver(rx_matrix, sim_global.blocks_per_batch, M_p);
            rec_bits = rec_bits_raw(1:length(batch_data));
            
            % 5. 统计错误
            curr_errs = sum(abs(batch_data - rec_bits));
            total_errors = total_errors + curr_errs;
            total_bits = total_bits + length(batch_data);
        end
        
        if total_bits > 0
            BER_results(cfg_idx, snr_idx) = total_errors / total_bits;
        else
            BER_results(cfg_idx, snr_idx) = 0; 
        end
        
        fprintf('  Eb/N0 = %4.1f dB | BER = %.2e | 错误数 = %d | 总比特 = %d\n', ...
            EbN0_dB, BER_results(cfg_idx, snr_idx), total_errors, total_bits);
    end
end
close(h_bar);

%% 3. 绘图
figure('Name', 'CSK-DCSK BER Performance', 'NumberTitle', 'off');
for i = 1:num_configs
    semilogy(sim_global.EbN0_dB, BER_results(i, :), ...
        [configs{i}.color, '-' configs{i}.marker], ...
        'LineWidth', 1.5, 'MarkerFaceColor', configs{i}.color, ...
        'DisplayName', configs{i}.name);
    hold on;
end

grid on;
title(['CSK-DCSK BER Performance (\beta=' num2str(sim_global.beta) ')']);
xlabel('E_b/N_0 (dB)');
ylabel('Bit Error Rate (BER)');
legend('Location', 'southwest');
axis([min(sim_global.EbN0_dB) max(sim_global.EbN0_dB) 1e-6 1]);