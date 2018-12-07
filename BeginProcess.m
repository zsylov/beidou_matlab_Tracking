clc;
clear all;
close all;
format long g;
settings = setting_canshu();%设置环路运行参数
loop_para = loop_canshu_calculate(settings);%计算环路滤波器参数
code_table=GOLD_code(); %调用函数，产生伪随机码

fll_nco_adder = 0;
carrier_nco_sum = 0;
pll_nco_adder = 0;
loop_count = 0;
code_nco_sum = 0;
code_nco_adder = 0;
n_IQ = 2;
n = 3;
output_fll(2:3) = 0;
output_filter_fll(1:3) = 0;
output_filter_pll(1:3) = 0;
output_pll(2:3) = 0;
output_filter_ddll(1:3) = 0;
pll_after_filter = 0;

Tcoh = settings.Tcoh;

global modulate_code_nco;  %信号源扩频码初相位
modulate_code_nco = settings.modulate_code_bias_phsae;
global early_code_nco;
% early_code_nco = setting.e_code_original_phase;

local_early_code_last = local_earlycode_initial(settings,code_table);%产生本地超前码

for loop_num = 1 : 1500
    signal_original = source_(settings); %产生信号源，加噪声，未调制
    settings.dot_length = settings.dot_length + 10000;%产生相位连续的信号；
    flag(loop_num) = settings.PLL_flag;
    fd_plot(loop_num) = settings.dup_freq;
    
    [signal_modulate_code,settings.signal_phase] = signalcode(settings,code_table);  %信号源的CB1码
    receive_signal = signal_modulate_code.* signal_original;  %扩频后的信号


%     receive_signal =  original_signal;  %扩频后的信号
    %产生本地再生载波
    for demond_num = 1:settings.Ncoh 
        local_cos(demond_num) = cos(2*pi*carrier_nco_sum/2^settings.nco_Length);
        local_sin(demond_num) = -sin(2*pi*carrier_nco_sum/2^settings.nco_Length);
        carrier_nco_sum = carrier_nco_sum + settings.middle_freq_nco + fll_nco_adder + pll_nco_adder ;%本地再生载波NCO
%         carrier_nco_sum = mod(carrier_nco_sum,2^setting.nco_Length);
    end,
    
    code_nco_sum = code_nco_adder + settings.code_word + fll_nco_adder*settings.cofe_FLL_auxi_DDLL;  %本地再生码环NCO    
    %code_nco_sum = code_nco_adder + settings.code_word + fll_nco_adder*(1/763);  %本地再生码环NCO     
    %产生本地超前，即时，滞后码
    [local_early_code,local_prompt_code,local_late_code,settings.local_phase]=localcode_generate(local_early_code_last,code_nco_sum,code_table,settings);
    local_early_code_last = local_early_code;
    %载波解调    
    I_demon_carrier = local_cos.*receive_signal;
    Q_demon_carrier = local_sin.*receive_signal;
%     save_I_demon_carrier = [save_I_demon_carrier I_demon_carrier];
%     save_Q_demon_carrier = [save_Q_demon_carrier Q_demon_carrier];
    
    %信号解扩并积分清除
    I_E_final = sum(I_demon_carrier.*local_early_code);
    Q_E_final = sum(Q_demon_carrier.*local_early_code);
    I_P_final(n_IQ) = sum(I_demon_carrier.*local_prompt_code);
    Q_P_final(n_IQ) = sum(Q_demon_carrier.*local_prompt_code);
    I_L_final = sum(I_demon_carrier.*local_late_code);
    Q_L_final = sum(Q_demon_carrier.*local_late_code);
    
    
%     I_P_final(n_IQ) = sum(I_demon_carrier);
%     Q_P_final(n_IQ) = sum(Q_demon_carrier);
    
    
    if  1 == loop_num
        I_P_final(n_IQ - 1) = I_P_final(n_IQ);
        Q_P_final(n_IQ - 1) = Q_P_final(n_IQ);
    else
% %         四象限反正切鉴频器
        dot_fll = I_P_final(n_IQ - 1) * I_P_final(n_IQ) + Q_P_final(n_IQ - 1) * Q_P_final(n_IQ);
        cross_fll = I_P_final(n_IQ - 1) * Q_P_final(n_IQ) - I_P_final(n_IQ) * Q_P_final(n_IQ - 1);
        output_fll(n) = atan2(cross_fll,dot_fll)/(Tcoh*2*pi); 
        result_discriminator_Fll(loop_num) = output_fll(n);
        
        output_filter_fll(n) = (loop_para.cofeone_FLL * output_fll(n)) + (loop_para.cofetwo_FLL * output_fll(n - 1)) + (2 * output_filter_fll(n - 1)) - output_filter_fll(n - 2);
        fll_after_filter(loop_num) = output_filter_fll(n);
        
        fll_nco_adder = output_filter_fll(n) * settings.transfer_coef ;  %频率字转换      
        output_fll(n - 1)=output_fll(n);
        output_filter_fll(n - 2)=output_filter_fll(n - 1);
        output_filter_fll(n - 1)=output_filter_fll(n);
        
         if settings.PLL_flag == 1
            %锁相环鉴相器
            output_pll(n) = atan2(Q_P_final(n_IQ),I_P_final(n_IQ)); 
            output_filter_pll(n) = loop_para.cofeone_PLL*output_pll(n) + loop_para.cofetwo_PLL*output_pll(n-1)+loop_para.cofethree_PLL*output_pll(n-2)+2*output_filter_pll(n-1)-output_filter_pll(n-2);
            result_discriminator_Pll(loop_num) = output_pll(n);
            pll_after_filter(loop_num) = output_filter_pll(n);
            pll_nco_adder = (output_filter_pll(n)/(2*pi)) * settings.transfer_coef;  %频率字转换
            
%             output_pll(1:2) = output_pll(2:3);
%             output_filter_pll(1:2) = output_filter_pll(2:3);
            output_pll(n-2) = output_pll(n-1);
            output_pll(n-1) = output_pll(n);
            output_filter_pll(n-2) = output_filter_pll(n-1);
            output_filter_pll(n-1) = output_filter_pll(n);
        end

        I_P_final(n_IQ - 1) = I_P_final(n_IQ);
        Q_P_final(n_IQ - 1) = Q_P_final(n_IQ);
       if 0 == settings.PLL_flag  && abs(output_fll(n))<10  %锁频环工作状态下，信号与本地频差小于10时
            loop_count = loop_count + 1;
            if  loop_count>200            
                   settings.PLL_flag = 1;
            end
       elseif  1 == settings.PLL_flag && abs(output_fll(n))>30      %在锁相环工作状态下，锁频环所鉴出的信号与本地频差大于30时
            loop_count = loop_count-1;
            if  0 == loop_count
                settings.PLL_flag = 0;
            end
       end
    end,
 %码环鉴别器
    output_ddll(n) = ((I_E_final - I_L_final)*I_P_final(n_IQ) + (Q_E_final - Q_L_final)*Q_P_final(n_IQ) )/((I_P_final(n_IQ)^2 + Q_P_final(n_IQ)^2)*2);  % DDLL_discri_1
       
    result_ddll(loop_num) = output_ddll(n);
    %码环滤波器（二阶）
    output_filter_ddll(n) = output_filter_ddll(n -1) + (loop_para.cofeone_DDLL*output_ddll(n)) + loop_para.cofetwo_DDLL*output_ddll(n - 1);
    result_DDLL_filter(loop_num) = output_filter_ddll(n);
    % 转换成频率控制字
    code_nco_adder = output_filter_ddll(n) * settings.transfer_coef ; %频率字转换
%     Code_NCO=0;
%     C(loop_num)=code_nco_adder;
    %替换
    output_ddll(n - 1)=output_ddll(n);
    output_filter_ddll(n - 1) = output_filter_ddll(n);
    code_phase_discrim(loop_num) = settings.signal_phase - settings.local_phase ;
end

figure ;
subplot(2,1,1);
plot(flag);
title('FLL+PLL工作  信噪比为-20dB 多普勒频率为80hz');
legend('PLL 工作标志');
xlabel('循环次数')
subplot(2,1,2);
plot(fll_after_filter + (pll_after_filter/(2*pi)),'b');
hold on;
plot(fd_plot,'r');
legend('载波环路滤波器输出值','多普勒频率的真实值');
xlabel('循环次数')

figure ;
subplot(2,1,1);
plot(result_ddll);
title('FLL+PLL工作  信噪比为-20dB 多普勒频率为80hz');
legend('DLL 鉴别结果');
xlabel('循环次数')
subplot(2,1,2);
plot(result_DDLL_filter,'b');
hold on;
% plot(fd_plot,'r');%
% legend('DDLL环路滤波器输出值','多普勒频率的真实值');
legend('DLL环路滤波器输出值');
xlabel('循环次数')

% figure ;
% subplot(2,1,1);
% plot(result_discriminator_Fll);
% title('单FLL工作  信噪比为-2dB 多普勒频率为80hz');
% legend('PLL 鉴别结果');
% xlabel('循环次数')
% subplot(2,1,2);
% plot(fll_after_filter,'b');
% hold on;
% plot(fd_plot,'r');
% legend('FLL环路滤波器输出值','多普勒频率的真实值');
% xlabel('循环次数')
% 
% figure ;
% subplot(2,1,1);
% plot(result_discriminator_Pll);
% title('单PLL工作  信噪比为-2dB 多普勒频率为80hz');
% legend('PLL 鉴别结果');
% xlabel('循环次数')
% subplot(2,1,2);
% plot((pll_after_filter/(2*pi)),'b');
% hold on;
% plot(fd_plot,'r');
% legend('PLL环路滤波器输出值','多普勒频率的真实值');
% xlabel('循环次数')
% figure ;
% subplot(2,2,1);
% plot(result_discriminator_Fll);
% ylabel('FLL 鉴别结果');
% xlabel('循环次数')
% subplot(2,2,2);
% plot(fll_after_filter + (pll_after_filter/(2*pi)));
% ylabel('载波环 滤波结果');
% xlabel('循环次数')
% subplot(2,2,3);
% plot( flag);
% ylabel('PLL启动模式');
% xlabel('循环次数')
% subplot(2,2,4);
% plot( fll_after_filter);
% ylabel(' fLL滤波结果');
% xlabel('循环次数')
% disp('环路循环完毕！');