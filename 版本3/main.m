clear; clc; close all;

beta_arr = [128,256,512];               
Block_Num = 20;      
L_arr = [1,2];                  
C = 2;               
Frame_Num = 100000;
total=zeros(2,3,25);

for l=1:length(L_arr)
    L=L_arr(l);
    for b=1:length(beta_arr)
        beta=beta_arr(b);
        M=floor(log2(beta));
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
            ratio(l,b,dB+1)=sum(Bits~=Bitsre)/((Block_Num-1)*M);
            total(l,b,dB+1)=total(l,b,dB+1)+ratio(l,b,dB+1);
            end
            if total(l,b,dB+1)==0
                fprintf('   >>> 误码率极低，跳过后续 SNR 点\n');
                break;
            end
        end
    end
end
total=total/Frame_Num;
figure();
box on; hold on;
markers={'bo-','rs-','k^-'};
for i=1:2
    for j=1:3
        plot(0:1:24,squeeze(total(i,j,:)),markers{j},...
             'LineWidth', 1.5, 'MarkerSize', 7);
    end
end
set(gca, 'Yscale', 'log');
ylim([1e-5 1]);  
xlim([0 24]);        
xlabel('Eb/N0 (dB)', 'FontSize', 12);
ylabel('BER', 'FontSize', 12);
legend('\beta=128, Simulation', ...
       '\beta=256, Simulation', ...
       '\beta=512, Simulation', ...
       'Location', 'SouthWest', 'FontSize', 10);
grid on;