function [Bits,Symbols0]=Transmitter(M,beta,Block_Num,C)
    Bits=randi([0,1],1,(Block_Num-1)*M);
    Symbols=zeros(beta,Block_Num);
    x0=rand();
    cx0=generate_chaos_seq(beta,x0);
    cx=(cx0-mean(cx0))/std(cx0);
    Symbols(:,1)=cx';
    cur_block=cx;
    for b=2:Block_Num
        bits_start=(b-2)*M+1;
        bits_end=(b-2)*M+M;
        cur_bits=Bits(bits_start:bits_end);
        zn=0;
        for k=1:M
            zn=zn+cur_bits(k)*2^(M-k);
        end
        cur_block=circshift(cur_block,[0,zn]);
        Symbols(:,b)=cur_block';
    end
    Symbols0=[Symbols(end-C+1:end,:);Symbols];
end
