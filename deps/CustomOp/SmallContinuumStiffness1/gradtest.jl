using ADCME
using PyCall
using LinearAlgebra
using PyPlot
using Random
using NNFEM
Random.seed!(233)

function small_continuum_stiffness1(k)
    small_continuum_stiffness1_ = load_op_and_grad("./build/libSmallContinuumStiffness1","small_continuum_stiffness1", multiple=true)
    k = convert_to_tensor(Any[k], [Float64]); k = k[1]
    ii, jj, vv = small_continuum_stiffness1_(k)
    A = SparseTensor(ii+1, jj+1, vv, domain.neqs, domain.neqs)
end

# TODO: specify your input parameters
domain = example_static_domain1()
init_nnfem(domain)
N = getNGauss(domain)
k = zeros(N, 2, 2)
for i = 1:N 
    k[i,:,:] = diagm(0=>ones(2))
end
A = small_continuum_stiffness1(k)
A0, _ = compute_stiffness_matrix_and_internal_force1(domain)
sess = Session(); init(sess)
@show run(sess, A)≈ A0

# uncomment it for testing gradients
# error() 


# TODO: change your test parameter to `m`
#       in the case of `multiple=true`, you also need to specify which component you are testings
# gradient check -- v
function scalar_function(m)
    return sum(values(small_continuum_stiffness1(m))^2)
end

# TODO: change `m_` and `v_` to appropriate values
m_ = constant(rand(N,2,2))
v_ = rand(N,2,2)
y_ = scalar_function(m_)
dy_ = gradients(y_, m_)
ms_ = Array{Any}(undef, 5)
ys_ = Array{Any}(undef, 5)
s_ = Array{Any}(undef, 5)
w_ = Array{Any}(undef, 5)
gs_ =  @. 1 / 10^(1:5)

for i = 1:5
    g_ = gs_[i]
    ms_[i] = m_ + g_*v_
    ys_[i] = scalar_function(ms_[i])
    s_[i] = ys_[i] - y_
    w_[i] = s_[i] - g_*sum(v_.*dy_)
end

sess = Session(); init(sess)
sval_ = run(sess, s_)
wval_ = run(sess, w_)
close("all")
loglog(gs_, abs.(sval_), "*-", label="finite difference")
loglog(gs_, abs.(wval_), "+-", label="automatic differentiation")
loglog(gs_, gs_.^2 * 0.5*abs(wval_[1])/gs_[1]^2, "--",label="\$\\mathcal{O}(\\gamma^2)\$")
loglog(gs_, gs_ * 0.5*abs(sval_[1])/gs_[1], "--",label="\$\\mathcal{O}(\\gamma)\$")

plt.gca().invert_xaxis()
legend()
xlabel("\$\\gamma\$")
ylabel("Error")
