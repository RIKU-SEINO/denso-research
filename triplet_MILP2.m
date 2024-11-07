function [M_opt, u_max] = triplet_MILP2(U,U_v,U_ps,n_step_index)
%
[i,j,k] = size(U);

% reshape
f = reshape(U,[],1);




% equality constraints

Aeq = zeros(i+2*j+2*k-5 ,length(f));
constraint_cnt = 1;

% all players belong to one triplet

% for taxi
for ii = 2:i
    A_tmp = zeros(size(U));
    A_tmp(ii,:,:) = 1;
    Aeq(constraint_cnt,:) = reshape(A_tmp,1,[]);
    constraint_cnt = constraint_cnt + 1;
end

% for passenger
for jj = 2:j
    A_tmp = zeros(size(U));
    A_tmp(:,jj,:) = 1;
    
    Aeq(constraint_cnt,:) = reshape(A_tmp,1,[]);
    constraint_cnt = constraint_cnt + 1;
end

% for package
for kk = 2:k
    A_tmp = zeros(size(U));
    A_tmp(:,:,kk) = 1;
    Aeq(constraint_cnt,:) = reshape(A_tmp,1,[]);
    constraint_cnt = constraint_cnt + 1;
end

% constraints against matching without any taxi

for jjj = 2:j
    A_tmp = zeros(size(U));
    A_tmp(1,jjj,2:k) = 1;
    Aeq(constraint_cnt,:) = reshape(A_tmp,1,[]);
    constraint_cnt = constraint_cnt + 1;
end
for kkk = 2:k
    A_tmp = zeros(size(U));
    A_tmp(1,2:j,kkk) = 1;
    Aeq(constraint_cnt,:) = reshape(A_tmp,1,[]);
    constraint_cnt = constraint_cnt + 1;
end



 

beq = [ones(i+j+k-3,1);zeros(j+k-2,1)];

% % inequality constraints
% 
% A =  zeros(i-1, length(f));
% b = zeros(i-1,1);
% 
% for iii = 2:i
%     A_tmp = zeros(size(U));
%     A_tmp(iii,:,:) = U_v(iii,:,:);
%     A(iii-1,:) = reshape(A_tmp,1,[]);
%     b(iii-1,1) = U_v(iii,1,1);
% end


% MILP
options = optimoptions('intlinprog', 'Display', 'off');
%[x,fval] = intlinprog(-f,1:length(f),-A,b,Aeq,beq,zeros(length(f),1),[0;ones(length(f)-1,1)],options);
[x,fval] = intlinprog(-f,1:length(f),[],[],Aeq,beq,zeros(length(f),1),[0;ones(length(f)-1,1)],options);

u_max = -fval;
M_opt = reshape(x,[i,j,k]);
M_opt = round(M_opt);

if check_feasibility(M_opt) == 0
    warning('M is unfeasible')
    global error_M
    error_M = M_opt
end