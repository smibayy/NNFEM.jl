using SparseArrays
export assembleStiffAndForce,assembleInternalForce,assembleMassMatrix!
function assembleInternalForce(globdat::GlobalData, domain::Domain)
    Fint = zeros(Float64, domain.neqs)
    neles = domain.neles
  
    # Loop over the elements in the elementGroup
    for iele  = 1:neles
      element = domain.elements[iele]
  
      # Get the element nodes
      el_nodes = getNodes(element)
  
      # Get the element nodes
      el_eqns = getEqns(domain,iele)
  
      el_dofs = getDofs(domain,iele)
  
      el_state  = getState(domain,el_dofs)
  
      el_Dstate = getDstate(domain,el_dofs)
  
      # Get the element contribution by calling the specified action
      fint = getInternalForce(element, el_state, el_Dstate)
  
      # Assemble in the global array
      el_eqns_active = (el_eqns .>= 1)
      Fint[el_eqns[el_eqns_active]] += fint[el_eqns_active]
    end
  
    return Fint
end

function assembleStiffAndForce(globdat::GlobalData, domain::Domain)
    # Fint = zeros(Float64, domain.neqs)
    
    # K = zeros(Float64, domain.neqs, domain.neqs)
    neles = domain.neles

    FII = Array{Array{Int64}}(undef, neles)
    FVV = Array{Array{Float64}}(undef, neles)
    II = Array{Array{Int64}}(undef, neles)
    JJ = Array{Array{Int64}}(undef, neles)
    VV = Array{Array{Float64}}(undef, neles)
    # Loop over the elements in the elementGroup
    for iele  = 1:neles
      element = domain.elements[iele]
  
      # Get the element nodes
      el_nodes = getNodes(element)
  
      # Get the element nodes
      el_eqns = getEqns(domain,iele)
  
      el_dofs = getDofs(domain,iele)

      #@show "iele", iele, el_dofs 
      
      #@show "domain.state", iele, domain.state 

      el_state  = getState(domain,el_dofs)
  
      el_Dstate = getDstate(domain,el_dofs)
      # #@show "+++++", el_state, el_Dstate
  
      # Get the element contribution by calling the specified action
      #@info "ele id is ", iele
      fint, stiff  = getStiffAndForce(element, el_state, el_Dstate)

      # Assemble in the global array
      el_eqns_active = el_eqns .>= 1
      # K[el_eqns[el_eqns_active], el_eqns[el_eqns_active]] += stiff[el_eqns_active,el_eqns_active]

      el_act = el_eqns[el_eqns_active]
      # el_act = reshape(el_eqns[el_eqns_active], length(el_eqns[el_eqns_active]), 1)
      II[iele] = (el_act*ones(Int64, 1, length(el_act)))[:]
      JJ[iele] = (el_act*ones(Int64, 1, length(el_act)))'[:]
      VV[iele] = stiff[el_eqns_active,el_eqns_active][:]
      FII[iele] = el_act
      FVV[iele] = fint[el_eqns_active]
      # Fint[el_act] += fint[el_eqns_active]
    end
    II = vcat(II...); JJ = vcat(JJ...); VV = vcat(VV...); FII=vcat(FII...); FVV = vcat(FVV...)
    K = sparse(II,JJ,VV,domain.neqs,domain.neqs)
    Fint = sparse(FII, ones(length(FII)), FVV, domain.neqs, 1)|>Array
    # Ksp = sparse(II,JJ,VV)
    # @show norm(K-Ksp)
    return Fint, K
end

function assembleMassMatrix!(globaldat::GlobalData, domain::Domain)
    Mlumped = zeros(Float64, domain.neqs)
    M = zeros(Float64, domain.neqs, domain.neqs)
    Mlumped = zeros(Float64, domain.neqs)
    neles = domain.neles

    # Loop over the elements in the elementGroup
    for iele = 1:neles
        element = domain.elements[iele]

        # Get the element nodes
        el_nodes = getNodes(element)
    
        # Get the element nodes
        el_eqns = getEqns(domain,iele)

        # Get the element contribution by calling the specified action
        lM, lumped = getMassMatrix(element)

        # Assemble in the global array
        
        el_eqns_active = (el_eqns .>= 1)
        M[el_eqns[el_eqns_active], el_eqns[el_eqns_active]] += lM[el_eqns_active, el_eqns_active]
        Mlumped[el_eqns[el_eqns_active]] += lumped[el_eqns_active]

        
    end

    globaldat.M = sparse(M)
    globaldat.Mlumped = sparse(Mlumped)
  
end

