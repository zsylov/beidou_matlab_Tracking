function [signal_modulate_code,signal_phase] = signalcode(settings,code_table)
    global modulate_code_nco;  %% 扩频码初相位
    
    Ncoh = settings.Ncoh;
    signal_modulate_code=[];
    for i=1:Ncoh
        modulate_code_nco = modulate_code_nco + settings.code_word + settings.fd_code;%码频率字 + 多普勒频率字
        modulate_code_nco = mod(modulate_code_nco,2^32*2046);%不要超过一个码周期，2^32 代表一个码片，2046码片是一个周期
        index = 1+fix(modulate_code_nco/2^32);%当超过2^32，表示要进位到下个码片
        c = code_table(index);%查码表
        signal_modulate_code = [signal_modulate_code,c];
        if 1 == i 
            signal_phase = modulate_code_nco/2^32*360;
        end
    end