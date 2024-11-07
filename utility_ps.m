function u_ps = utility_ps(ps,l_c,t)
    global w_ps alpha_u_ps;
    l_ps = abs(ps.x_o-ps.x_d) + abs(ps.y_o-ps.y_d);
    l_ratio = (l_c + t-ps.t0 - l_ps) / l_ps;
    u_ps = w_ps * exp(-alpha_u_ps*l_ratio^2);
end