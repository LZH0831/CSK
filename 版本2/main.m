clear; clc; close all;

beta = 128;             
M = floor(log2(beta));  
Block_Num = 20;      
L = 2;                  
C = 2;               
Frame_Num = 200000;
total=zeros(1,25);


for dB=0:1:24
    disp(dB);
    SNR=10^(dB/10);
    for f=1:Frame_Num
        if L==1
            cur_alpha=1;
        else
            cur_alpha=sqrt(1/(2*L))*(randn(1,L)+1i*randn(1,L));
        end
    [Bits,Symbols0]=Transmitter(M,beta,Block_Num,C);
    Symbols1=Channel(Symbols0,L,SNR,M,beta,cur_alpha);
    Bitsre=Receiver(M,Block_Num,C,Symbols1);
    ratio(1,dB+1)=sum(Bits~=Bitsre)/((Block_Num-1)*M);
    total(1,dB+1)=total(1,dB+1)+ratio(1,dB+1);
    end
end
total=total/Frame_Num;

figure();
box on; hold on;
plot(0:1:24, total(1,:), 'bo-');
set(gca, 'Yscale', 'log');
ylim([1e-6 1]);          
xlabel('Eb/N0 (dB)');
ylabel('BER');
legend('CSK');
grid on;