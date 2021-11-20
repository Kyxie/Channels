clear;
clc;
tic
%% Data
N = 1000;               % Repeat time
Op = 3;                 % Patients
User = 10;              % Total users
Normal = User - Op;     % Normal users
Base = 2;               % Base station
Channel = 5;            % Channel
Data = zeros(User, 5);  % User*5 list，form：user id | Q user id | BS id | channel id | Q value
SINR = zeros(1, 10);    % SINR
sigma = 10 ^ -16.2 * 180000;
%% Algorithm
for iter = 1:N
    Q = Qfunc(User, Base, Channel);
    QOp = Q(1:Op, :, :);
    QNormal = Q(Op + 1:User, :, :);

    % Assign Q to OPs
    for i = 1:Op
        [Uindex, Bindex, Cindex, Max] = FindMaxQ(QOp);
        Data(i, 1) = i;
        Data(i, 2) = Uindex;
        Data(i, 3) = Bindex;
        Data(i, 4) = Cindex;
        Data(i, 5) = Max;

        % change the whole channel to 0
        QOp(:, :, Cindex) = 0; %clear
        QOp(Uindex, :, :) = 0; %clear

        QPre = zeros(Normal, 2);
        %get the interference of 7 noemal users for the OP
        for j = 1:Normal
            QPre(j, 1) = j; %the first coloumn 
            QPre(j, 2) = QNormal(j, InvBase(Data(i, 3)), Data(i, 4)); % the second coloumn is Q power
        end
        % find the least interference among 7 users
        [UNorIndex, ~, ~, Min] = FindMinQ(QPre);
        Data(i + Op, 1) = i + Op; % record the row number
        Data(i + Op, 2) = UNorIndex + Op;  %record the user number
        Data(i + Op, 3) = InvBase(Data(i, 3));  %record the user's BS
        Data(i + Op, 4) = Data(i, 4);  %record the user's channel
        Data(i + Op, 5) = QNormal(UNorIndex, InvBase(Data(i, 3)), Data(i, 4));  %record the user's Q power
        QNormal(UNorIndex, :, :) = 0;  %clear the picking user's BS and channel to 0
        QNormal(:, Data(i + Op, 3), Data(i + Op, 4)) = 0;  %clear other users in the picking user's position to 0 
        QNormal(:, Data(i, 3), Data(i, 4)) = 0;  %clear other users in the OP's position to 0
    end

    % A是所有信道
    A = [1 1;
        1 2;
        1 3;
        1 4;
        1 5;
        2 1;
        2 2;
        2 3;
        2 4;
        2 5;];
    % B是已经分配的信道
    B = Data(1:2 * Op, 3:4);
    
    % 在A中找B，如果有则变为0
    for i = 1:2 * Op
        [Logic, ChosenIndex] = ismember(B(i, :), A, 'rows');
        if(Logic == 1)
            A(ChosenIndex, :) = 0;
            continue;
        end
    end
    
    % 删除A中所有的0，这时候A是未分配的信道
    A(all(A == 0,2),:) = [];
    
    % 同理，让C为所有人
    C = [1; 2; 3; 4; 5; 6; 7; 8; 9; 10];
    % D为已经分配了的人
    D = Data(1:2 * Op, 2);
    % 在C中找D，如果有则变为0
    for i = 1:2 * Op
        [Logic, ChosenIndex] = ismember(D(i, :), C, 'rows');
        if(Logic == 1)
            C(ChosenIndex, :) = 0;
            continue;
        end
    end
    % 删除C中所有的0，这时候C是未分配的人
    C(all(C == 0,2),:) = [];
    
    % find where the other left users want to go, assign them
    for i = 1:User - 2 * Op
        [rowchannel, ~] = size(A);
        [rowpeople, ~] = size(C);
        
        seedchannel = floor(rowchannel * rand(1, 1)) + 1;
        seedpeople = floor(rowpeople * rand(1, 1)) + 1;
    
        Data(i + 2 * Op, 1) = i + 2 * Op;
        Data(i + 2 * Op, 2) = C(seedpeople, 1);
        Data(i + 2 * Op, 3) = A(seedchannel, 1);
        Data(i + 2 * Op, 4) = A(seedchannel, 2);
        Data(i + 2 * Op, 5) = Q(C(seedpeople, 1), Data(i + 2 * Op, 3), Data(i + 2 * Op, 4));
        A(seedchannel, :) = [];
        C(seedpeople, :) = [];
    end

    Data = sortrows(Data, 2);  %rank by user number
    % calculate SINR
    for i = 1:User
        Qsig = Data(i, 5);
        Basesig = Data(i, 3);
        Channelsig = Data(i, 4);
        for j = 1:User
            if((InvBase(Data(j, 3)) == Basesig) && (Data(j, 4) == Channelsig))
                Qinte = Q(j, Basesig, Channelsig);
            end
        end
        SINR(1, i) = SINR(1, i) + Qsig / (Qinte + sigma);
    end
end

%% plot
SINR = SINR / N;
bar(1:User, SINR);
grid on;
title("Heuristic Algrithm");
xlabel("Users");
ylabel("SINR");
time = toc;
%% save data to Excel
xlswrite('Results.xlsx', SINR', 1, 'C2:C11');
xlswrite('Results.xlsx', SINR(1:Op)', 2, 'C2:C4');
SINRNorAve = SINR(Op + 1:User);
SINRNorAve = mean(SINRNorAve);
SINRTotAve = mean(SINR);
xlswrite('Results.xlsx', SINRNorAve, 2, 'C5');
xlswrite('Results.xlsx', SINRTotAve, 2, 'C6');
xlswrite('Results.xlsx', time, 3, 'B3');