function [r_k, noise_sigma] = AWGN_Channel(S_k, EbN0_dB, beta, bits_per_block)

    P_sig = mean(S_k.^2);
    
    Eb = P_sig * (beta / bits_per_block);
    
    EbN0_lin = 10^(EbN0_dB / 10);
    N0 = Eb / EbN0_lin;
    
    noise_sigma = sqrt(N0 / 2);
    noise = noise_sigma * randn(size(S_k));
    
    r_k = S_k + noise;

end