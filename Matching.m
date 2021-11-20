clear;
clc;
tic
%% ����
N = 1000;                                   % �ظ�����
Op = 3;                                     % ������
User = 10;                                  % ������
Normal = User - Op;                         % ��ͨ����
Base = 2;                                   % ��վ��
Channel = 5;                                % �ŵ���
UserExp = zeros(Base * Channel, 3, User);   % ������������ʽ����վ | �ŵ� | ����
ChannelExp = zeros(User, 4, Base * Channel);% �ŵ���������ʽ����վ | �ŵ� | �� | ����
SINR = zeros(1, 10);                        % SINR
sigma = 10 ^ -16.2 * 180000;
%% �㷨
for iter = 1:N
    Q = Qfunc(User, Base, Channel);
%     disp(Q);
    QBC = Q;
    QOp = Q;
    
    Data = zeros(User, 5);                      % User*5�ı�񣬸�ʽ����id | Q�е���id | ��վid | �ŵ�id | Q
    
    % ����������ѭ�����ҵ�ÿ������������Q��󣩵Ļ�վ�ŵ�
    for i = 1:User
        for j = 1:Base * Channel
            [~, Bindex, Cindex, Max] = FindMaxQ(Q(i, :, :));
            UserExp(j, 1, i) = Bindex;
            UserExp(j, 2, i) = Cindex;
            UserExp(j, 3, i) = Max;
            Q(i, Bindex, Cindex) = 0;
        end
    end

    for i = 1:Base * Channel
        % ChannelExp��ʼ��
        ChannelExp(:, 1, i) = floor(i / (Channel + 1)) + 1;
        if(i <= Channel)
            ChannelExp(:, 2, i) = mod(i, Channel + 1);
        elseif(i == Base * Channel)
            ChannelExp(:, 2, i) = Channel;
        else
            ChannelExp(:, 2, i) = mod(i, Channel);
        end

        % �Ի�վ�ŵ���ѭ�����ҵ�ÿ��[��վ���ŵ�]��������Q��С������
        for j = 1:User
            [UBCindex, ~, ~, BCMin] = FindMinQ(QBC(:, InvBase(ChannelExp(1, 1, i)), ChannelExp(1, 2, i)));
            ChannelExp(j, 3, i) = UBCindex;
            ChannelExp(j, 4, i) = BCMin;
            QBC(UBCindex, InvBase(ChannelExp(1, 1, i)), ChannelExp(1, 2, i)) = 0;
        end
    end

    % HaveBeenChosen��ʾ��ǰ����Ľ��
    HaveBeenChosen = zeros(User, 2);
    % DisOpDone��ʾ��û�гɹ�����Ĳ���������ʼֵΪ1:Op
    DisOpDone = 1:User;
    while(length(DisOpDone))
        ZeroRow = FindFirstZero(Data);
        Data(ZeroRow, 1) = ZeroRow;
        Data(ZeroRow, 2) = DisOpDone(1, 1);
        Data(ZeroRow, 3) = UserExp(1, 1, DisOpDone(1, 1));
        Data(ZeroRow, 4) = UserExp(1, 2, DisOpDone(1, 1));
        Data(ZeroRow, 5) = UserExp(1, 3, DisOpDone(1, 1));
        HaveBeenChosen(ZeroRow, 1) = Data(ZeroRow, 3);
        HaveBeenChosen(ZeroRow, 2) = Data(ZeroRow, 4);
        % ��һ���˲���Ҫ����
        if(ZeroRow == 1)
            DisOpDone(:, 1) = [];
            continue;
        else
            [Logic, ChosenIndex] = ismember(HaveBeenChosen(ZeroRow, :), HaveBeenChosen(1:ZeroRow - 1, :), 'rows');
            % ���ظ�
            if(Logic == 1)
                QFront = QOp(ChosenIndex, InvBase(HaveBeenChosen(ZeroRow, 1)), HaveBeenChosen(ZeroRow, 2));
                QBack = QOp(ZeroRow, InvBase(HaveBeenChosen(ZeroRow, 1)), HaveBeenChosen(ZeroRow, 2));
                % ���޳ɹ�
                if(QFront < QBack)
                    % �Ȱѵ�ZeroRow���˵�UserExp�ĵ�һ�е������һ�У����Ҫ��
                    UserExp(:, :, Data(ZeroRow, 2)) = UpsideDown(UserExp(:, :, Data(ZeroRow, 2)), 1);
                    % �ٰѸղŷ���ı�0����һ�в��ܱ䣩
                    Data(ZeroRow, :) = 0;
                    HaveBeenChosen(ZeroRow, :) = 0;
                    continue;
                else
                    ShouldbeReplaced = Data(ChosenIndex, 2);
                    % �Ȱ�ChosenIndex��һ�б�0
                    Data(ChosenIndex, :) = 0;
                    HaveBeenChosen(ChosenIndex, :) = 0;
                    % �ٰ���һ�зŵ����
                    Data = UpsideDown(Data, ChosenIndex);
                    HaveBeenChosen = UpsideDown(HaveBeenChosen, ChosenIndex);
                    % �޸�Data��һ�е����
                    for i = ChosenIndex:ZeroRow - 1
                        Data(i, 1) = Data(i, 1) - 1;
                    end
                    % �ٰѵ�ChosenIndex���˵�UserExp�ĵ�һ�е������һ�У����Ҫ��
                    UserExp(:, :, ShouldbeReplaced) = UpsideDown(UserExp(:, :, ShouldbeReplaced), 1);

                    DisOpDone(:, 1) = [];
                    % ���ѵ�ChosenIndex���˼���DisOpDone����ǰ��
                    DisOpDone = [ShouldbeReplaced, DisOpDone];
                    continue;
                end 
            else
                DisOpDone(:, 1) = [];
                continue;
            end
        end
    end

%     % DisNormalDone��ʾ��û�гɹ��������ͨ��������ʼֵΪ1:Normal 
%     DisNormalDone = 1:Normal;
%     while(length(DisNormalDone))
%         ZeroRow = FindFirstZero(Data);
%         Data(ZeroRow, 1) = ZeroRow;
%         Data(ZeroRow, 2) = DisNormalDone(1, 1) + Op;
%         Data(ZeroRow, 3) = UserExp(1, 1, DisNormalDone(1, 1) + Op);
%         Data(ZeroRow, 4) = UserExp(1, 2, DisNormalDone(1, 1) + Op);
%         Data(ZeroRow, 5) = UserExp(1, 3, DisNormalDone(1, 1) + Op);
%         HaveBeenChosen(ZeroRow, 1) = Data(ZeroRow, 3);
%         HaveBeenChosen(ZeroRow, 2) = Data(ZeroRow, 4);
%         % �����һ����Ҳ��Ҫ������
%         [Logic, ChosenIndex] = ismember(HaveBeenChosen(ZeroRow, :), HaveBeenChosen(1:ZeroRow - 1, :), 'rows');
%         % ���ظ�
%         if(Logic == 1)
%             % ��ͨ����Ȩ���没�˵�ѡ��
%             if(ChosenIndex <= Op)
%                 % ��ͨ�˵������ı�
%                 UserExp(:, :, DisNormalDone(1, 1) + Op) = UpsideDown(UserExp(:, :, DisNormalDone(1, 1) + Op), 1);
%                 % ���ղŷ���ı�Ϊ0
%                 Data(ZeroRow, :) = 0;
%                 HaveBeenChosen(ZeroRow, :) = 0;
%                 continue;
%             else
%                 QFront = QOp(Data(ChosenIndex, 2), InvBase(HaveBeenChosen(ZeroRow, 1)), HaveBeenChosen(ZeroRow, 2));
%                 QBack = QOp(ZeroRow, InvBase(HaveBeenChosen(ZeroRow, 1)), HaveBeenChosen(ZeroRow, 2));
%                 % ���޳ɹ�
%                 if(QFront < QBack)
%                     % �ȰѸղŷ���ı�0����һ�в��ܱ䣩
%                     Data(ZeroRow, :) = 0;
%                     HaveBeenChosen(ZeroRow, :) = 0;
%                     % �ٰѵ�DisNormalDone(1, 1) + Op���˵�UserExp�ĵ�һ�е������һ�У����Ҫ��
%                     UserExp(:, :, DisNormalDone(1, 1) + Op) = UpsideDown(UserExp(:, :, DisNormalDone(1, 1) + Op), 1);
%                     continue;
%                 else
%                     % �Ȱ�ChosenIndex��һ�б�0
%                     Data(ChosenIndex, :) = 0;
%                     HaveBeenChosen(ChosenIndex, :) = 0;
%                     % �ٰ���һ�зŵ����
%                     Data = UpsideDown(Data, ChosenIndex);
%                     HaveBeenChosen = UpsideDown(HaveBeenChosen, ChosenIndex);
%                     % �޸�Data��һ�е����
%                     for i = ChosenIndex:ZeroRow - 1
%                         Data(i, 1) = Data(i, 1) - 1;
%                     end
%                     % �ٰѵ�ChosenIndex���˵�UserExp�ĵ�һ�е������һ�У����Ҫ��
%                     UserExp(:, :, Data(ChosenIndex, 2)) = UpsideDown(UserExp(:, :, Data(ChosenIndex, 2)), 1);
% 
%                     DisNormalDone(:, 1) = [];
%                     % ���ѵ�ChosenIndex���˼���DisOpDone����ǰ��
%                     DisNormalDone = [Data(ChosenIndex, 2) - Op, DisNormalDone];
%                     continue;
%                 end
%             end
%         else
%             DisNormalDone(:, 1) = [];
%             continue;
%         end
%     end
    
%     Data = sortrows(Data, 2);
    % ����SINR
    for i = 1:User
        Qsig = Data(i, 5);
        Basesig = Data(i, 3);
        Channelsig = Data(i, 4);
        for j = 1:User
            if((InvBase(Data(j, 3)) == Basesig) && (Data(j, 4) == Channelsig))
                Qinte = QOp(j, Basesig, Channelsig);
            end
        end
        SINR(1, i) = SINR(1, i) + Qsig / (Qinte + sigma);
    end
end

%% ��ͼ
SINR = SINR / N;
bar(1:User, SINR);
grid on;
title("Matching Algrithm");
xlabel("Users");
ylabel("SINR");
time = toc;
% ɾ���ڶ���
Data(:, 2) = [];

%% �������ݵ�Excel
xlswrite('Results.xlsx', SINR', 1, 'E2:E11');
xlswrite('Results.xlsx', SINR(1:Op)', 2, 'E2:E4');
SINRNorAve = SINR(Op + 1:User);
SINRNorAve = mean(SINRNorAve);
SINRTotAve = mean(SINR);
xlswrite('Results.xlsx', SINRNorAve, 2, 'E5');
xlswrite('Results.xlsx', SINRTotAve, 2, 'E6');
xlswrite('Results.xlsx', time, 3, 'B5');