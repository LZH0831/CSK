function Symbols1=Channel(Symbols0,L,SNR,M,beta,cur_alpha)
    [P,Block_Num]=size(Symbols0);
    Symbols1=zeros(P,Block_Num);
    for b=1:Block_Num
        cur_block=zeros(P,1);
        for l=1:L
            Tau=l-1;
            shifted=[zeros(Tau,1);Symbols0(1:end-Tau,b)];
            cur_block=cur_block+cur_alpha(l)*shifted;
        end
        pre_block=zeros(P,1);
        if b>1
            for l=2:L
                Tau=l-1;
                tail=Symbols0(end-Tau+1:end,b-1);
                pre_block(1:Tau)=pre_block(1:Tau)+cur_alpha(l)*tail;
            end
        end
        Symbols1(:,b)=cur_block+pre_block;
    end
    nr=randn(P,Block_Num);          
    ni=randn(P,Block_Num);
    power=mean(sum(abs(Symbols0).^2))/P;
    Eb=power*beta/M;
    Noise=sqrt(Eb/SNR)*(sqrt(2)/2)*(nr+1i*ni); 
    Symbols1=Symbols1+Noise;
end