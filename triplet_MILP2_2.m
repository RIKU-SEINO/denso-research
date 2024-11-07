function [M_opt, u_max] = triplet_MILP2_2(U,U_v,U_ps,n_step_index)
%n step以上をマッチ
[i,j,k] = size(U);
num_nstep_matched=0;

% reshape
f = reshape(U,[],1);
n_index=length(n_step_index);

% equality constraints
Aeq = zeros(i+2*j+2*k-5 +n_index,length(f));
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

%nstepをマッチ
for jjjj=2:j
    A_tmp = zeros(size(U));
    if ismember(jjjj-1, n_step_index)
        if i-1>=n_index
            A_tmp(1,jjjj,1) = 1;
        elseif num_nstep_matched<i-1

            A_tmp(1,jjjj,1) = 1;
            num_nstep_matched=num_nstep_matched+1;
            
        else
            A_tmp(1,jjjj,1) = 0;

        end
        
        Aeq(constraint_cnt,:) = reshape(A_tmp,1,[]);
        constraint_cnt = constraint_cnt + 1;
    end
end
% for jjjj = 2:j
%         if ismember(jjjj - 1, n_step_index)
%             A_tmp = zeros(size(U));
%             A_tmp(1, jjjj, :) = 1;
%             Aeq(constraint_cnt,:) = reshape(A_tmp,1,[]);
%             constraint_cnt = constraint_cnt + 1;
%         end
%  end

beq = [ones(i+j+k-3,1);zeros(j+k-2,1);zeros(n_index,1)];

% inequality constraints
% A =  zeros(i-1, length(f));
% b = zeros(i-1,1);
% 
% for iii = 2:i
%     A_tmp = zeros(size(U));
%     A_tmp(iii,:,:) = U_v(iii,:,:);
%     A(iii-1,:) = reshape(A_tmp,1,[]);
%     b(iii-1,1) = U_v(iii,1,1);
% end


% disp(['Size of U_platform: ', num2str(i), ' x ', num2str(j), ' x ', num2str(k)]);
% disp(['Size of Aeq: ', num2str(size(Aeq))]);
% disp(['Size of beq: ', num2str(length(beq))]);
% disp(['Length of n_step_index: ', num2str(length(n_step_index))]);
% disp(n_step_index);
% MILP
options = optimoptions('intlinprog', 'Display', 'off');
% [x,fval] = intlinprog(-f,1:length(f),-A,b,Aeq,beq,zeros(length(f),1),[0;ones(length(f)-1,1)],options);
[x,fval] = intlinprog(-f,1:length(f),[],[],Aeq,beq,zeros(length(f),1),[0;ones(length(f)-1,1)],options);
u_max = -fval;

% Check if the solution size matches the expected size
if numel(x) == i*j*k
    M_opt = reshape(x, [i, j, k]);
    M_opt = round(M_opt);
else
%     disp(Aeq);
%     disp(beq);
%     disp(exitflag);
%     disp(output.constrviolation);
disp(['Size of U_platform: ', num2str(i), ' x ', num2str(j), ' x ', num2str(k)]);
disp(['Size of Aeq: ', num2str(size(Aeq))]);
disp(['Size of beq: ', num2str(length(beq))]);
disp(['Length of n_step_index: ', num2str(length(n_step_index))]);
disp(n_step_index);
    error('Size mismatch: Expected %d elements, but got %d elements.i= %d', i*j*k, numel(x),i);
   
end


if check_feasibility(M_opt) == 0
    warning('M is unfeasible')
    global error_M
    error_M = M_opt;
end
