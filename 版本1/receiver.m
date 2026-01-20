function recovered_bits = receiver(rx_signals, num_blocks, M_p)

    recovered_bits = [];
    
    for block_idx = 2:num_blocks
        prev_block = rx_signals(block_idx-1, :);
        curr_block = rx_signals(block_idx, :);
        
        fft_prev = fft(prev_block);
        fft_curr = fft(curr_block);
        
        correlation = ifft(conj(fft_prev) .* fft_curr);
        
        [~, peak_position] = max(abs(correlation));
        estimated_shift = peak_position - 1;
       
        current_bits = de2bi(estimated_shift, M_p,'left-msb');
        recovered_bits = [recovered_bits, current_bits];
    end
end