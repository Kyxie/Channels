function Amw = Afunc(U, B)    % A���û��ͻ�վ�й�
    distance = (600 - 300) * rand(U * B, 1) + 300;  % ����U*B�����������Χ��[300, 600]��distanceΪ1*(U*B)�ľ���
    distance = reshape(distance, U, B); % ��distance�޸�shape����ΪU*B�ľ���
    AdBm = 128 + 37.6 .* log10(distance ./ 1000);
    Amw = 10 .^ (-AdBm / 10);
end