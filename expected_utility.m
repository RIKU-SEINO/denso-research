clear

a = 1/2;


feasiblity = zeros(5,2);
util_exp = zeros(5,2);

%Ax = U, By = V, Cz = Wとする
%b1 = 1 if x3+z3 < u2+v2
for i = 1:5
    for b1 = 0
        
        p1 = 2^-(i);
        p2 = p1;

        p1_ = 1 - p1;
        p2_ = 1 - p2;

        u1 = 1; u2 = 0;
        v1 = 0; v2 = -a;

        A = eye(4) - [p1_*p2_, 0, (1-b1)*p1_*p2, 0;
                      0, 0, 0, 0;
                      0, 0, (1-b1)*(p1_*p2_+p1_*p2), 0;
                      0 ,0, 0, 0];
        U = [(p1*p2_+p1*p2)*u1 + b1*p1_*p2*u2;
             u1;
             (p1*p2_+p1*p2)*u1 + b1*(p1_*p2_+p1_*p2)*u2;
             u1];
        x(:,i) = A\U;

        B = eye(4) - [0, 0, 0, 0;
                      0, 0, 0, 0;
                      (p1_*p2_+p1*p2_), (p1_*p2+p1*p2), 0, 0;
                      0, 1, 0, 0];
        V = [v1-a;
             v1-a;
             -a;
             -a];
        y(:,i) = B\V;
    
        C = eye(4) - [(1-b1)*(p1_*p2_+p1_*p2), 0, (p1*p2_+p1*p2), 0;
                      0, 0, (p1_*p2_+p1_*p2), (p1*p2_+p1*p2);
                      (p1_*p2_+p1_*p2), (p1*p2_+p1*p2), 0, 0;
                      0, 1, 0, 0];

        W = [b1*(p1_*p2_+p1_*p2)*(v2)-a;
             -a;
             -a;
             -a];
        z(:,i) = C\W;

        if i == 1
            b1,x(3),z(1),u2,v2,rank(C)
        end
        feasiblity(i,b1+1) = ((x(3)+z(1)<u2+v2)==b1) || (x(3)+z(1)==u2+v2);
        util_exp(i,b1+1) = x(3)+z(1);
    end
end
