function [r_k, noise_sigma] = AWGN_Channel(S_k, EbN0_dB, beta, bits_per_block)
% 输入:
%   S_k            : 发射信号向量 (实数序列)
%   EbN0_dB        : 目标信噪比 (dB)
%   beta           : 扩频因子 (每个符号的采样点数/长度)
%   bits_per_block : 每个符号块携带的比特数 (用于归一化Eb)
%
% 输出:
%   r_k            : 接收信号 (S_k + Noise)
%   noise_sigma    : 添加噪声的标准差 (用于调试)

    %% 1. 计算信号功率
    P_sig = mean(S_k.^2);
    
    %% 2. 计算每比特能量 (Eb)
    % 能量 E = 功率 * 时间(采样点数)
    % Eb = (P_sig * beta) / bits_per_block
    Eb = P_sig * (beta / bits_per_block);
    
    %% 3. 计算噪声功率谱密度 (N0)
    % 转换 dB 为线性值
    EbN0_lin = 10^(EbN0_dB / 10);
    
    % 根据定义: Eb/N0 = EbN0_lin  =>  N0 = Eb / EbN0_lin
    N0 = Eb / EbN0_lin;
    
    %% 4. 生成噪声
    % 对于实数信号仿真，噪声方差 sigma^2 = N0 / 2
    noise_sigma = sqrt(N0 / 2);
    
    % 生成标准正态分布噪声并缩放
    noise = noise_sigma * randn(size(S_k));
    
    %% 5. 叠加噪声
    r_k = S_k + noise;

end