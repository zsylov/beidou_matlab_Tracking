function [local_early_code,local_prompt_code,local_late_code,local_phase]=localcode_generate(local_early_code_last,code_nco_sum,code_table,settings)

    global early_code_nco;
    Ncoh = settings.Ncoh;
    code_temp = [];
    for n=1:Ncoh
        early_code_nco = early_code_nco + code_nco_sum;
        early_code_nco = mod(early_code_nco,2^32*2046);
        index = 1 + fix(early_code_nco/2^32);
        c = code_table(index);
        code_temp = [code_temp,c];
        if 1 == n 
            local_phase = early_code_nco/2^32*360;
        end
    end
    local_early_code = code_temp;
    local_prompt_code = [local_early_code_last(Ncoh-2:Ncoh),local_early_code(1:Ncoh-3)];
    local_late_code = [local_early_code_last(Ncoh-5:Ncoh),local_early_code(1:Ncoh-6)];