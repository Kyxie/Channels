function Q = Qfunc(U, B, C)
    A = Afunc(U, B);
    H = Hfunc(U, B, C);
    P = 50;
    Q = zeros(U,B,C);   % Ԥ����һ��U*B*C�ľ���
    for i = 1:U
        for j = 1:B
            for k = 1:C
                Q(i, j, k) = P * H(i, j, k) * A(i, j);
            end
        end
    end
end