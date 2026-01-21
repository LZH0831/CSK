function Bitsre=Receiver(M,Block_Num,C,Symbols1)
    Bitsre=zeros(1,(Block_Num-1)*M);
    for b=2:Block_Num
        pre_clock=Symbols1(C+1:end,b-1);
        cur_clock=Symbols1(C+1:end,b);
        correlation=ifft(conj(fft(pre_clock)).*fft(cur_clock));
        [~,max_idx]=max(abs(correlation));
        shift=max_idx-1;
        bin_str=dec2bin(shift,M);
        cur_bits=zeros(1,M);
        for k=1:M
            cur_bits(k)=str2double(bin_str(k));
        end

        idx_start=(b-2)*M+1;
        idx_end=(b-2)*M+M;
        Bitsre(idx_start:idx_end)=cur_bits;
    end
end