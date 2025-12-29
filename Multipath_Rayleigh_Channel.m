function r_k = Multipath_Rayleigh_Channel(S_k, EbN0_dB, beta, bits_per_block, path_props)
% MULTIPATH_RAYLEIGH_CHANNEL 多径瑞利衰落信道
%
% 输入:
%   S_k            : 发射信号向量
%   EbN0_dB        : 信噪比 (dB)
%   beta           : 扩频因子
%   bits_per_block : 每块比特数
%   path_props     : (可选) 路径参数结构体，包含 .L, .delays, .powers
%                    如果不传，默认使用 main10.m 中的双径配置
%
% 输出:
%   r_k            : 接收信号 (复数序列)

    %% 1. 设置默认路径参数
    if nargin < 5
        % 默认为 main10.m 中的配置 (双径等增益)
        L = 2;
        path_delays = [0, 1];     % 延迟 (采样点)
        path_powers = [0.5, 0.5]; % 功率分配
    else
        L = path_props.L;
        path_delays = path_props.delays;
        path_powers = path_props.powers;
    end

    %% 2. 计算噪声参数
    % 信号功率
    P_sig = mean(abs(S_k).^2); 
    
    % 每比特能量 Eb
    Eb = P_sig * (beta / bits_per_block);
    
    % 噪声功率谱密度 N0
    EbN0_lin = 10^(EbN0_dB / 10);
    N0 = Eb / EbN0_lin;
    
    % 噪声方差 (对于复数噪声，总功率为 N0)
    % main10.m 中定义 noise_variance = N0 / 2，然后实部虚部各乘 sqrt(noise_variance)
    % 这种定义下，总噪声功率 = (N0/2)*1 + (N0/2)*1 = N0。逻辑正确。
    noise_variance = N0 / 2;

    %% 3. 生成瑞利衰落系数 (复数)
    % 每一径都有独立的衰落系数
    % 系数 = sqrt(功率/2) * (实部高斯 + 虚部高斯)
    h_channel = sqrt(path_powers/2) .* (randn(1, L) + 1i * randn(1, L));

    %% 4. 多径叠加
    r_k_multipath = zeros(1, length(S_k));
    
    for l = 1:L
        d = path_delays(l);
        % 构造延迟信号: 前面补 d 个 0
        delayed_signal = [zeros(1, d), S_k];
        
        % 截断: 保持与原信号长度一致 (模拟有限观测窗)
        % 注意: main10.m 是截断到 r_k_multipath 的长度
        delayed_signal = delayed_signal(1:length(S_k));
        
        % 加权叠加
        r_k_multipath = r_k_multipath + h_channel(l) * delayed_signal;
    end

    %% 5. 添加复高斯白噪声
    % 实部和虚部独立加噪
    noise = sqrt(noise_variance) * (randn(size(S_k)) + 1i * randn(size(S_k)));
    
    r_k = r_k_multipath + noise;

end