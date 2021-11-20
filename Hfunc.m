function ChanPowGain = Hfunc(U, B, C)         % H和基站用户信道都有关
    NOU = U * B * C;
    x = normrnd(0, 1/sqrt(2), 1, NOU);
    y = normrnd(0, 1/sqrt(2), 1, NOU);
    ChanGain = sqrt(x.^2 + y.^2);
    ChanPowGain = ChanGain.^2;
    ChanPowGain = reshape(ChanPowGain, U, B, C);
end