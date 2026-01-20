function r_k = Multipath_Rayleigh_Channel(S_k, EbN0_dB, beta, bits_per_block, path_props)

    if nargin < 5
        L = 2;
        path_delays = [0, 1];     
        path_powers = [0.5, 0.5]; 
    else
        L = path_props.L;
        path_delays = path_props.delays;
        path_powers = path_props.powers;
    end

    P_sig = mean(abs(S_k).^2); 
    
    Eb = P_sig * (beta / bits_per_block);
    
    EbN0_lin = 10^(EbN0_dB / 10);
    N0 = Eb / EbN0_lin;
    noise_variance = N0 / 2;

    h_channel = sqrt(path_powers/2) .* (randn(1, L) + 1i * randn(1, L));

    max_delay = max(path_delays);
    r_k_multipath = zeros(1, length(S_k) + max_delay);
    
    for l = 1:L
        d = path_delays(l);
        % 模拟延迟：前补 d 个 0，后补 (max_delay - d) 个 0
        % 这样所有路径的信号长度对齐，且保留了尾部信息
        delayed_signal = [zeros(1, d), S_k, zeros(1, max_delay - d)];
        
        r_k_multipath = r_k_multipath + h_channel(l) * delayed_signal;
    end
    
    % 添加噪声 (噪声也覆盖整个长度)
    noise = sqrt(noise_variance) * (randn(size(r_k_multipath)) + 1i * randn(size(r_k_multipath)));
    r_k = r_k_multipath + noise;
    
    % 注意：这里返回的 r_k 长度比输入 S_k 长。
    % 我们在 main.m 中通过 rx_serial(1:length(tx_serial)) 来模拟接收窗截断。

end