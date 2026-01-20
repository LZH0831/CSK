clear; clc; close all;

beta = 512;             
M = floor(log2(beta));  
Block_Num = 10000;      
L = 2;                  
C = 2;               
total=zeros(1,25);


for dB=0:1:24
    disp(dB);
    SNR=10^(dB/10);
    [Bits,Symbols0]=Transmitter(M,beta,Block_Num,C);
    Symbols1=Channel(Symbols0,L,SNR,M,beta);
    Bitsre=Receiver(M,Block_Num,C,Symbols1);
    total(1,dB+1)=sum(Bits~=Bitsre)/((Block_Num-1)*M);
end

figure();
box on; hold on;
plot(0:1:24, total(1,:), 'bo-');
set(gca, 'Yscale', 'log');
ylim([1e-6 1]);          
xlabel('Eb/N0 (dB)');
ylabel('BER');
legend('CSK');
grid on;