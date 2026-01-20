function seq = generate_chaos_seq(beta, x0)
    seq = zeros(1, beta);
    x = x0;
    for n = 1:beta
        x = 1 - 2 * x^2;   
        seq(n) = x;
    end
end