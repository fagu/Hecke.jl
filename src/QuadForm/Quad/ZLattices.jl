export *,+, basis_matrix, ambient_space, base_ring, base_field, root_lattice,
       kernel_lattice, invariant_lattice, hyperbolic_plane_lattice, signature_tuple,
       root_sublattice, root_lattice_recognition, root_lattice_recognition_fundamental,
       glue_map, overlattice, primitive_closure, is_primitive,
       lattice_in_same_ambient_space, maximal_even_lattice, is_maximal_even,
       leech_lattice, highest_root, coxeter_number, embed_in_unimodular, irreducible_components,
       divisibility, coinvariant_lattice

# scope & verbose scope: :Lattice
@doc raw"""
    basis_matrix(L::ZZLat) -> QQMatrix

Return the basis matrix $B$ of the integer lattice $L$.

The lattice is given by the row span of $B$ seen inside of the
ambient quadratic space of $L$.
"""
basis_matrix(L::ZZLat) = L.basis_matrix

ambient_space(L::ZZLat) = L.space

base_ring(L::ZZLat) = FlintZZ

base_field(L::ZZLat) = base_ring(gram_matrix(ambient_space(L)))

################################################################################
#
#  Creation
#
################################################################################

@doc raw"""
    integer_lattice([B::MatElem]; gram) -> ZZLat

Return the Z-lattice with basis matrix $B$ inside the quadratic space with
Gram matrix `gram`.

If the keyword `gram` is not specified, the Gram matrix is the identity matrix.
If $B$ is not specified, the basis matrix is the identity matrix.

# Examples
```jldoctest
julia> L = integer_lattice(matrix(QQ, 2, 2, [1//2, 0, 0, 2]));

julia> gram_matrix(L) == matrix(QQ, 2, 2, [1//4, 0, 0, 4])
true

julia> L = integer_lattice(gram = matrix(ZZ, [2 -1; -1 2]));

julia> gram_matrix(L) == matrix(ZZ, [2 -1; -1 2])
true
```
"""
function integer_lattice(B::QQMatrix; gram = identity_matrix(FlintQQ, ncols(B)), check::Bool=true)
  V = quadratic_space(FlintQQ, gram, check=check)
  return lattice(V, B, check=check)
end

function integer_lattice(B::ZZMatrix; gram = identity_matrix(FlintQQ, ncols(B)), check::Bool=true)
  V = quadratic_space(FlintQQ, gram, check=check)
  return lattice(V, B, check=check)
end

### Documentation in ./Lattices.jl
quadratic_lattice(::QQField, B::Union{ZZMatrix, QQMatrix}; gram = identity_matrix(QQ, ncols(B)), check::Bool = true) = integer_lattice(B, gram = gram, check = check)

function integer_lattice(;gram, check=true)
  n = nrows(gram)
  return lattice(quadratic_space(FlintQQ, gram, check=check), identity_matrix(FlintQQ, n), check=check)
end

### Documentation in ./Lattices.jl
quadratic_lattice(::QQField; gram, check::Bool = true) = integer_lattice(gram = gram, check = check)

### Documentation in ./Lattices.jl
function quadratic_lattice(::QQField, gens::Vector{T}; gram = nothing, check::Bool = true) where T <: Union{QQMatrix, ZZMatrix, Vector{RationalUnion}}
  if length(gens) == 0
    @assert gram !== nothing
    B = zero_matrix(QQ, 0, nrows(gram))
    return quadratic_lattice(QQ, B, gram = gram, check = check)
  end
  @assert length(gens[1]) > 0
  if gram === nothing
    gram = identity_matrix(QQ, length(gens[1]))
  end
  if check
    @assert gram isa MatElem
    @req gram == transpose(gram) "Gram matrix must be symmetric"
    @req all(v -> length(v) == ncols(gram), gens) "Incompatible arguments: elements in gens must all have the same number of entries. This number must be equal to the size of the square matrix gram (if specified)"
  end
  gram = map_entries(QQ, gram)
  V = quadratic_space(QQ, gram)
  B = zero_matrix(QQ, length(gens), length(gens[1]))
  for i in 1:length(gens)
    B[i,:] = gens[i]
  end
  return lattice(V, B, isbasis = false)
end

@doc raw"""
    lattice(V::QuadSpace{QQField, QQMatrix}, B::QQMatrix; isbasis=true, check=true) -> ZZLat

Return the $\mathbb Z$-lattice with basis matrix $B$ inside the quadratic space $V$.
"""
function lattice(V::QuadSpace{QQField, QQMatrix}, B::MatElem{<:RationalUnion}; isbasis::Bool = true, check::Bool = true)
  @req dim(V) == ncols(B) "Ambient space and the matrix B have incompatible dimension"
  if typeof(B) !== QQMatrix
    B = map_entries(QQ, B)
  end

  # We need to produce a basis matrix

  if !isbasis
    BB = QQMatrix(hnf(FakeFmpqMat(B), :upper_right))
    i = nrows(BB)
    while i > 0 && is_zero_row(BB, i)
      i = i - 1
    end
    return ZZLat(V, BB[1:i, :])
  else
    @req !check || rank(B) == nrows(B) "The rows of B must define a free system of vectors in V"
    return ZZLat(V, B)
  end
end

function lattice_in_same_ambient_space(L::ZZLat, B::MatElem; check::Bool = true)
  @req !check || (rank(B) == nrows(B)) "The rows of B must define a free system of vectors"
  V = ambient_space(L)
  return lattice(V, B, check = false)
end

@doc raw"""
    rescale(L::ZZLat, r::RationalUnion) -> ZZLat

Return the lattice `L` in the quadratic space with form `r \Phi`.

#  Examples
This can be useful to apply methods intended for positive definite lattices.

```jldoctest
julia> L = integer_lattice(gram=ZZ[-1 0; 0 -1])
Integer lattice of rank 2 and degree 2
with gram matrix
[-1    0]
[ 0   -1]

julia> shortest_vectors(rescale(L, -1))
2-element Vector{Vector{ZZRingElem}}:
 [0, 1]
 [1, 0]
```
"""
function rescale(L::ZZLat, r::RationalUnion)
  B = basis_matrix(L)
  gram_space = gram_matrix(ambient_space(L))
  Vr = quadratic_space(QQ, r*gram_space)
  return lattice(Vr, B, check = false)
end

################################################################################
#
#  Gram matrix
#
################################################################################

@doc raw"""
    gram_matrix(L::ZZLat) -> QQMatrix

Return the gram matrix of $L$.

# Examples
```jldoctest
julia> L = integer_lattice(matrix(ZZ, [2 0; -1 2]));

julia> gram_matrix(L)
[ 4   -2]
[-2    5]
```
"""
function gram_matrix(L::ZZLat)
  if isdefined(L, :gram_matrix)
    return L.gram_matrix
  end
  b = basis_matrix(L)
  V = ambient_space(L)
  if isone(b) && nrows(b) == dim(V)
    G = gram_matrix(V)
  else
    G = inner_product(V, b)
  end

  #G = b * gram_matrix(ambient_space(L)) * transpose(b)
  L.gram_matrix = G
  return G
end

gram_matrix_of_rational_span(L::ZZLat) = gram_matrix(L)

################################################################################
#
#  Rational span
#
################################################################################

@doc raw"""
    rational_span(L::ZZLat) -> QuadSpace

Return the rational span of $L$, which is the quadratic space with Gram matrix
equal to `gram_matrix(L)`.

# Examples
```jldoctest
julia> L = integer_lattice(matrix(ZZ, [2 0; -1 2]));

julia> rational_span(L)
Quadratic space of dimension 2
  over rational field
with gram matrix
[ 4   -2]
[-2    5]
```
"""
function rational_span(L::ZZLat)
  if isdefined(L, :rational_span)
    return L.rational_span
  else
    G = gram_matrix(L)
    V = quadratic_space(FlintQQ, G)
    L.rational_span = V
    return V
  end
end

################################################################################
#
#  Direct sums
#
################################################################################

function _biproduct(x::Vector{ZZLat})
  Bs = basis_matrix.(x)
  B = diagonal_matrix(Bs)
  return B
end

@doc raw"""
    direct_sum(x::Vararg{ZZLat}) -> ZZLat, Vector{AbstractSpaceMor}
    direct_sum(x::Vector{ZZLat}) -> ZZLat, Vector{AbstractSpaceMor}

Given a collection of $\mathbb Z$-lattices $L_1, \ldots, L_n$,
return their direct sum $L := L_1 \oplus \ldots \oplus L_n$,
together with the injections $L_i \to L$.
(seen as maps between the corresponding ambient spaces).

For objects of type `ZZLat`, finite direct sums and finite direct products
agree and they are therefore called biproducts.
If one wants to obtain `L` as a direct product with the projections $L \to L_i$,
one should call `direct_product(x)`.
If one wants to obtain `L` as a biproduct with the injections $L_i \to L$ and
the projections $L \to L_i$, one should call `biproduct(x)`.
"""
function direct_sum(x::Vector{ZZLat})
  W, inj = direct_sum(ambient_space.(x))
  B = _biproduct(x)
  return lattice(W, B, check = false), inj
end

direct_sum(x::Vararg{ZZLat}) = direct_sum(collect(x))

@doc raw"""
    direct_product(x::Vararg{ZZLat}) -> ZZLat, Vector{AbstractSpaceMor}
    direct_product(x::Vector{ZZLat}) -> ZZLat, Vector{AbstractSpaceMor}

Given a collection of $\mathbb Z$-lattices $L_1, \ldots, L_n$,
return their direct product $L := L_1 \times \ldots \times L_n$,
together with the projections $L \to L_i$.
(seen as maps between the corresponding ambient spaces).

For objects of type `ZZLat`, finite direct sums and finite direct products
agree and they are therefore called biproducts.
If one wants to obtain `L` as a direct sum with the injections $L_i \to L$,
one should call `direct_sum(x)`.
If one wants to obtain `L` as a biproduct with the injections $L_i \to L$ and
the projections $L \to L_i$, one should call `biproduct(x)`.
"""
function direct_product(x::Vector{ZZLat})
  W, proj = direct_product(ambient_space.(x))
  B = _biproduct(x)
  return lattice(W, B, check = false), proj
end

direct_product(x::Vararg{ZZLat}) = direct_product(collect(x))

@doc raw"""
    biproduct(x::Vararg{ZZLat}) -> ZZLat, Vector{AbstractSpaceMor}, Vector{AbstractSpaceMor}
    biproduct(x::Vector{ZZLat}) -> ZZLat, Vector{AbstractSpaceMor}, Vector{AbstractSpaceMor}

Given a collection of $\mathbb Z$-lattices $L_1, \ldots, L_n$,
return their biproduct $L := L_1 \oplus \ldots \oplus L_n$,
together with the injections $L_i \to L$ and the projections $L \to L_i$.
(seen as maps between the corresponding ambient spaces).

For objects of type `ZZLat`, finite direct sums and finite direct products
agree and they are therefore called biproducts.
If one wants to obtain `L` as a direct sum with the injections $L_i \to L$,
one should call `direct_sum(x)`.
If one wants to obtain `L` as a direct product with the projections $L \to L_i$,
one should call `direct_product(x)`.
"""
function biproduct(x::Vector{ZZLat})
  W, inj, proj = biproduct(ambient_space.(x))
  B = _biproduct(x)
  return lattice(W, B, check = false), inj, proj
end

biproduct(x::Vararg{ZZLat}) = biproduct(collect(x))

@doc raw"""
    orthogonal_submodule(L::ZZLat, S::ZZLat) -> ZZLat

Return the largest submodule of ``L`` orthogonal to ``S``.
"""
function orthogonal_submodule(L::ZZLat, S::ZZLat)
  @assert ambient_space(L)==ambient_space(S) "L and S must have the same ambient space"
  return orthogonal_submodule(L, basis_matrix(S))
end

@doc raw"""
    orthogonal_submodule(L::ZZLat, S::QQMatrix) -> ZZLat

Return the largest submodule of ``L`` orthogonal to each row of ``S``.
"""
function orthogonal_submodule(L::ZZLat, C::QQMatrix)
  B = basis_matrix(L)
  V = ambient_space(L)
  G = gram_matrix(V)
  M = B * G * transpose(C)
  _, K = left_kernel(M)
  K = change_base_ring(ZZ, K*denominator(K))
  Ks = saturate(K)
  return lattice(V, Ks*B, check = false)
end

################################################################################
#
#  String I/O
#
################################################################################

function show(io::IO, ::MIME"text/plain", L::ZZLat)
  println(io, "Integer lattice of rank $(rank(L)) and degree $(degree(L))")
  println(io, "with gram matrix")
  show(io, MIME"text/plain"(), gram_matrix(L))
end

function show(io::IO, L::ZZLat)
  if get(io, :supercompact, false)
    print(io, "Integer lattice")
  else
    print(io, "Integer lattice of rank $(rank(L)) and degree $(degree(L))")
  end
end

################################################################################
#
#  Automorphism groups
#
################################################################################

# This is an internal function, which sets
# L.automorphism_group_generators
# L.automorphism_group_order
function assert_has_automorphisms(L::ZZLat; redo::Bool = false,
                                           try_small::Bool = true)

  if !redo && isdefined(L, :automorphism_group_generators)
    return nothing
  end

  if rank(L) == 0
    L.automorphism_group_generators = ZZMatrix[identity_matrix(ZZ, 0)]
    L.automorphism_group_order = one(ZZRingElem)
    return nothing
  end

  if !is_definite(L)
    @assert rank(L) == 2
    G = gram_matrix(L)
    d = denominator(G)
    GG = change_base_ring(ZZ, d*G)
    b = binary_quadratic_form(GG[1,1], 2*GG[1,2], GG[2,2])
    gens = transpose.(automorphism_group_generators(b))
    L.automorphism_group_generators = gens
    return nothing
  end

  V = ambient_space(L)
  GL = gram_matrix(L)
  d = denominator(GL)
  res = ZZMatrix[change_base_ring(FlintZZ, d * GL)]
  # So the first one is either positive definite or negative definite
  # Make it positive definite. This does not change the automorphisms.
  if res[1][1, 1] < 0
    res[1] = -res[1]
  end
  Glll, T = lll_gram_with_transform(res[1])
  Ttr = transpose(T)
  res_orig = copy(res)
  res[1] = Glll

  bm = basis_matrix(L)

  # Make the Gram matrix small

  C = ZLatAutoCtx(res)
  if try_small
    fl, Csmall = try_init_small(C)
    if fl
      auto(Csmall)
      _gens, order = _get_generators(Csmall)
      gens = ZZMatrix[matrix(FlintZZ, g) for g in _gens]
    else
      init(C)
      auto(C)
      gens, order = _get_generators(C)
    end
  else
    init(C)
    auto(C)
    gens, order = _get_generators(C)
  end

  # Now translate back
  Tinv = inv(T)
  for i in 1:length(gens)
    gens[i] = Tinv * gens[i] * T
  end

  # Now gens are with respect to the basis of L
  @hassert :Lattice 1 all(let gens = gens; i -> change_base_ring(FlintQQ, gens[i]) * GL *
                          transpose(change_base_ring(FlintQQ, gens[i])) == GL; end, 1:length(gens))

  L.automorphism_group_generators = gens
  L.automorphism_group_order = order

  return nothing
end

# documented in ../Lattices.jl

function automorphism_group_generators(L::ZZLat; ambient_representation::Bool = true)

  @req rank(L) in [0, 2] || is_definite(L) "The lattice must be definite or of rank at most 2"
  assert_has_automorphisms(L)

  gens = L.automorphism_group_generators
  if !ambient_representation
    return QQMatrix[ change_base_ring(FlintQQ, g) for g in gens]
  else
    # Now translate to get the automorphisms with respect to basis_matrix(L)
    bm = basis_matrix(L)
    V = ambient_space(L)
    if rank(L) == rank(V)
      bminv = inv(bm)
      res = QQMatrix[bminv * change_base_ring(FlintQQ, g) * bm for g in gens]
    else
      # Extend trivially to the orthogonal complement of the rational span
      !is_regular(V) &&
        error(
          """Can compute ambient representation only if ambient space is
             regular""")
      C = orthogonal_complement(V, basis_matrix(L))
      C = vcat(basis_matrix(L), C)
      Cinv = inv(C)
      D = identity_matrix(FlintQQ, rank(V) - rank(L))
      res = QQMatrix[Cinv * diagonal_matrix(change_base_ring(FlintQQ, g), D) * C for g in gens]
    end
    @hassert :Lattice 1 all(g * gram_matrix(V) * transpose(g) == gram_matrix(V)
                            for g in res)
    return res
  end
end

# documented in ../Lattices.jl

function automorphism_group_order(L::ZZLat)
  @req is_definite(L) "The lattice must be definite"
  assert_has_automorphisms(L)
  return L.automorphism_group_order
end

################################################################################
#
#  Isometry
#
################################################################################

# documented in ../Lattices.jl

function is_isometric(L::ZZLat, M::ZZLat)
  if L == M
    return true
  end

  if rank(L) != rank(M)
    return false
  end

  if genus(L) != genus(M)
    return false
  end

  if rank(L) == 1
    return gram_matrix(L) == gram_matrix(M)
  end

  if rank(L) == 2
    A = gram_matrix(L)
    B = gram_matrix(M)
    d = denominator(A)
    A = change_base_ring(ZZ, d * A)
    B = change_base_ring(ZZ, d * B)
    q1 = binary_quadratic_form(ZZ, A[1,1], 2 * A[1,2], A[2,2])
    q2 = binary_quadratic_form(ZZ, B[1,1], 2 * B[1,2], B[2,2])
    return is_isometric(q1, q2)
  end

  if is_definite(L) && is_definite(M)
    return is_isometric_with_isometry(L, M)[1]
  end
  return _is_isometric_indef(L, M)
end

function is_isometric_with_isometry(L::ZZLat, M::ZZLat; ambient_representation::Bool = false)
  @req is_definite(L) && is_definite(M) "The lattices must be definite"

  if rank(L) != rank(M)
    return false, zero_matrix(FlintQQ, 0, 0)
  end

  if genus(L) != genus(M)
    return false, zero_matrix(FlintQQ, 0, 0)
  end

  if rank(L) == 0
    return true, identity_matrix(FlintQQ, 0, 0)
  end

  i = sign(gram_matrix(L)[1,1])
  j = sign(gram_matrix(M)[1,1])
  @req i==j "The lattices must have the same signatures"

  if i < 0
    L = rescale(L,-1)
    M = rescale(M,-1)
  end

  GL = gram_matrix(L)
  dL = denominator(GL)
  GLint = change_base_ring(FlintZZ, dL * GL)
  cL = content(GLint)
  GLint = divexact(GLint, cL)

  GM = gram_matrix(M)
  dM = denominator(GM)
  GMint = change_base_ring(FlintZZ, dM * GM)
  cM = content(GMint)
  GMint = divexact(GMint, cM)

  # GLint, GMint are integral, primitive scalings of GL and GM
  # If they are isometric, then the scalars must be identical.
  if dL//cL != dM//cM
    return false, zero_matrix(FlintQQ, 0, 0)
  end

  # Now compute LLL reduces gram matrices

  GLlll, TL = lll_gram_with_transform(GLint)
  @hassert :Lattice 1 TL * change_base_ring(FlintZZ, dL*GL) * transpose(TL) == GLlll *cL
  GMlll, TM = lll_gram_with_transform(GMint)
  @hassert :Lattice 1 TM * change_base_ring(FlintZZ, dM*GM) * transpose(TM) == GMlll *cM

  # Setup for Plesken--Souvignier

  G1 = ZZMatrix[GLlll]
  G2 = ZZMatrix[GMlll]

  fl, CLsmall, CMsmall = _try_iso_setup_small(G1, G2)
  if fl
    b, _T = isometry(CLsmall, CMsmall)
    T = matrix(FlintZZ, _T)
  else
    CL, CM = _iso_setup(ZZMatrix[GLlll], ZZMatrix[GMlll])
    b, T = isometry(CL, CM)
  end

  if b
    T = change_base_ring(FlintQQ, inv(TL)*T*TM)
    if !ambient_representation
      @hassert :Lattice 1 T * gram_matrix(M) * transpose(T) == gram_matrix(L)
      return true, T
    else
      V = ambient_space(L)
      W = ambient_space(M)
      if rank(L) == rank(V)
        T = inv(basis_matrix(L)) * T * basis_matrix(M)
      else
        (!is_regular(V) || !is_regular(W)) &&
          error(
            """Can compute ambient representation only if ambient space is
               regular""")
          (rank(V) != rank(W)) &&
          error(
            """Can compute ambient representation only if ambient spaces
            have the same dimension.""")

        CV = orthogonal_complement(V, basis_matrix(L))
        CV = vcat(basis_matrix(L), CV)
        CW = orthogonal_complement(W, basis_matrix(M))
        CW = vcat(basis_matrix(M), CW)
        D = identity_matrix(FlintQQ, rank(V) - rank(L))
        T = inv(CV) * diagonal_matrix(T, D) * CW
      end
      @hassert :Lattice 1 T * gram_matrix(ambient_space(M))  * transpose(T) ==
                  gram_matrix(ambient_space(L))
      return true, T
    end
  else
    return false, zero_matrix(FlintQQ, 0, 0)
  end
end

################################################################################
#
#  Is sublattice?
#
################################################################################

function is_sublattice(M::ZZLat, N::ZZLat)
  if ambient_space(M) != ambient_space(N)
    return false
  end

  hassol, _rels = can_solve_with_solution(basis_matrix(M), basis_matrix(N), side=:left)

  if !hassol || !isone(denominator(_rels))
    return false
  end

  return true
end

@doc raw"""
    is_sublattice_with_relations(M::ZZLat, N::ZZLat) -> Bool, QQMatrix

Returns whether $N$ is a sublattice of $M$. In this case, the second return
value is a matrix $B$ such that $B B_M = B_N$, where $B_M$ and $B_N$ are the
basis matrices of $M$ and $N$ respectively.
"""
function is_sublattice_with_relations(M::ZZLat, N::ZZLat)
   if ambient_space(M) != ambient_space(N)
     return false, basis_matrix(M)
   end

   hassol, _rels = can_solve_with_solution(basis_matrix(M), basis_matrix(N), side=:left)

   if !hassol || !isone(denominator(_rels))
     return false, basis_matrix(M)
   end

   return true, _rels
 end

################################################################################
#
#  Root lattice
#
################################################################################

@doc raw"""
    root_lattice(R::Symbol, n::Int) -> ZZLat

Return the root lattice of type `R` given by `:A`, `:D` or `:E` with parameter `n`.
"""
function root_lattice(R::Symbol, n::Int)
  if R === :A
    return integer_lattice(gram = _root_lattice_A(n))
  elseif R === :E
    return integer_lattice(gram = _root_lattice_E(n))
  elseif R === :D
    return integer_lattice(gram = _root_lattice_D(n))
  else
    error("Type (:$R) must be :A, :D or :E")
  end
end

@doc raw"""
    root_lattice(R::Vector{Tuple{Symbol,Int}}) -> ZZLat

Return the root lattice of type `R`.

#Example
```jldoctest
julia> root_lattice([(:A,2),(:A,1)])
Integer lattice of rank 3 and degree 3
with gram matrix
[ 2   -1   0]
[-1    2   0]
[ 0    0   2]

```
"""
function root_lattice(R::Vector{Tuple{Symbol,Int}})
  S = [gram_matrix(root_lattice(i[1],i[2])) for i in R]
  return integer_lattice(gram=block_diagonal_matrix(S))
end

function _root_lattice_A(n::Int)
  n < 0 && error("Parameter ($n) for root lattice of type :A must be positive")
  z = zero_matrix(FlintQQ, n, n)
  for i in 1:n
    z[i, i] = 2
    if i > 1
      z[i, i - 1] = -1
    end
    if i < n
      z[i, i + 1] = -1
    end
  end
  return z
end

function _root_lattice_D(n::Int)
  n < 2 && error("Parameter ($n) for root lattices of type :D must be greater or equal to 2")
  if n == 2
    G = matrix(ZZ, [2 0 ;0 2])
  elseif n == 3
    return _root_lattice_A(n)
  else
    G = zero_matrix(ZZ, n, n)
    G[1,3] = G[3,1] = -1
    for i in 1:n
      G[i,i] = 2
      if 2 <= i <= n-1
        G[i,i+1] = G[i+1,i] = -1
      end
    end
  end
  return G
end

function _root_lattice_E(n::Int)
  n in [6,7,8] || error("Parameter ($n) for lattice of type :E must be 6, 7 or 8")
  if n == 6
    G = [2 -1 0 0 0 0;
        -1 2 -1 0 0 0;
        0 -1 2 -1 0 -1;
        0 0 -1 2 -1 0;
        0 0 0 -1 2 0;
        0 0 -1 0 0 2]
  elseif n == 7
    G = [2 -1 0 0 0 0 0;
        -1 2 -1 0 0 0 0;
        0 -1 2 -1 0 0 -1;
        0 0 -1 2 -1 0 0;
        0 0 0 -1 2 -1 0;
        0 0 0 0 -1 2 0;
        0 0 -1 0 0 0 2]
  else
    G = [2 -1 0 0 0 0 0 0;
        -1 2 -1 0 0 0 0 0;
        0 -1 2 -1 0 0 0 -1;
        0 0 -1 2 -1 0 0 0;
        0 0 0 -1 2 -1 0 0;
        0 0 0 0 -1 2 -1 0;
        0 0 0 0 0 -1 2 0;
        0 0 -1 0 0 0 0 2]
  end
  return matrix(ZZ, G)
end

################################################################################
#
#  Hyperbolic plane
#
################################################################################

@doc raw"""
    integer_lattice(S::Symbol, n::RationalUnion = 1) -> ZZlat

Given `S = :H` or `S = :U`, return a $\mathbb Z$-lattice admitting $n*J_2$ as
Gram matrix in some basis, where $J_2$ is the 2-by-2 matrix with 0's on the
main diagonal and 1's elsewhere.
"""
function integer_lattice(S::Symbol, n::RationalUnion = 1)
  @req S === :H || S === :U "Only available for the hyperbolic plane"
  gram = n*identity_matrix(QQ, 2)
  gram = reverse_cols!(gram)
  return integer_lattice(gram = gram)
end

@doc raw"""
    hyperbolic_plane_lattice(n::RationalUnion = 1) -> ZZLat

Return the hyperbolic plane with intersection form of scale `n`, that is,
the unique (up to isometry) even unimodular hyperbolic $\mathbb Z$-lattice
of rank 2, rescaled by `n`.

# Examples

```jldoctest
julia> L = hyperbolic_plane_lattice(6);

julia> gram_matrix(L)
[0   6]
[6   0]

julia> L = hyperbolic_plane_lattice(ZZ(-13));

julia> gram_matrix(L)
[  0   -13]
[-13     0]
```
"""
hyperbolic_plane_lattice(n::RationalUnion = 1) = integer_lattice(:H, n)

################################################################################
#
#  Dual lattice
#
################################################################################

# documented in ../Lattices.jl

function dual(L::ZZLat)
  G = gram_matrix(L)
  new_bmat = inv(G)*basis_matrix(L)
  return lattice(ambient_space(L), new_bmat, check = false)
end

################################################################################
#
#  Scale
#
################################################################################

@doc raw"""
    scale(L::ZZLat) -> QQFieldElem

Return the scale of `L`.

The scale of `L` is defined as the positive generator of the $\mathbb Z$-ideal
generated by $\{\Phi(x, y) : x, y \in L\}$.
"""
function scale(L::ZZLat)
  if isdefined(L, :scale)
    return L.scale
  end
  G = gram_matrix(L)
  s = zero(QQFieldElem)
  for i in 1:nrows(G)
    for j in 1:i
      s = gcd(s, G[i, j])
    end
  end
  L.scale = s
  return s
end

################################################################################
#
#  Norm
#
################################################################################

@doc raw"""
    norm(L::ZZLat) -> QQFieldElem

Return the norm of `L`.

The norm of `L` is defined as the positive generator of the $\mathbb Z$- ideal
generated by $\{\Phi(x,x) : x \in L\}$.
"""
function norm(L::ZZLat)
  if isdefined(L, :norm)
    return L.norm
  end
  n = 2 * scale(L)
  G = gram_matrix(L)
  for i in 1:nrows(G)
    n = gcd(n, G[i, i])
  end
  L.norm = n
  return n
end

################################################################################
#
#  Eveness
#
################################################################################

@doc raw"""
    iseven(L::ZZLat) -> Bool

Return whether `L` is even.

An integer lattice `L` in the rational quadratic space $(V,\Phi)$ is called even
if $\Phi(x,x) \in 2\mathbb{Z}$ for all $x in L$.
"""
iseven(L::ZZLat) = is_integral(L) && iseven(numerator(norm(L)))

################################################################################
#
#  Discriminant
#
################################################################################

@doc raw"""
    discriminant(L::ZZLat) -> QQFieldElem

Return the discriminant of the rational span of `L`.
"""
discriminant(L::ZZLat) = discriminant(rational_span(L))

################################################################################
#
#  Determinant
#
################################################################################

@doc raw"""
    det(L::ZZLat) -> QQFieldElem

Return the determinant of the gram matrix of `L`.
"""
function det(L::ZZLat)
  return det(gram_matrix(L))
end

################################################################################
#
#  Rank
#
################################################################################

function rank(L::ZZLat)
  return nrows(basis_matrix(L))
end

################################################################################
#
#  Signature
#
################################################################################

@doc raw"""
    signature_tuple(L::ZZLat) -> Tuple{Int,Int,Int}

Return the number of (positive, zero, negative) inertia of `L`.
"""
signature_tuple(L::ZZLat) = signature_tuple(rational_span(L))

################################################################################
#
#  Modularity
#
################################################################################

function is_modular(L::ZZLat, p::IntegerUnion)
  a = scale(L)
  v = valuation(a, p)
  if v * rank(L) == valuation(volume(L), p)
    return true, v
  else
    return false, 0
  end
end

################################################################################
#
#  Local basis matrix
#
################################################################################

# so that abstract lattice functions also work with Z-lattices

local_basis_matrix(L::ZZLat, p) = basis_matrix(L)

################################################################################
#
#  Intersection
#
################################################################################

function intersect(M::ZZLat, N::ZZLat)
  @req ambient_space(M) === ambient_space(N) "Lattices must have same ambient space"
  BM = basis_matrix(M)
  BN = basis_matrix(N)
  dM = denominator(BM)
  dN = denominator(BN)
  d = lcm(dM, dN)
  BMint = change_base_ring(FlintZZ, d * BM)
  BNint = change_base_ring(FlintZZ, d * BN)
  H = vcat(BMint, BNint)
  k, K = left_kernel(H)
  BI = divexact(change_base_ring(FlintQQ, hnf(view(K, 1:k, 1:nrows(BM)) * BMint)), d)
  return lattice(ambient_space(M), BI, check = false)
end

################################################################################
#
#  Sum
#
################################################################################

function +(M::ZZLat, N::ZZLat)
  @req ambient_space(M) === ambient_space(N) "Lattices must have same ambient space"
  BM = basis_matrix(M)
  BN = basis_matrix(N)
  B = QQMatrix(hnf(FakeFmpqMat(vcat(BM, BN))))
  i = 1
  while is_zero_row(B, i)
    i += 1
  end
  return lattice(ambient_space(M), B[i:end, 1:ncols(B)], check = false)
end

################################################################################
#
#  Local isometry
#
################################################################################

@doc raw"""
    is_locally_isometric(L::ZZLat, M::ZZLat, p::Int) -> Bool

Return whether `L` and `M` are isometric over the `p`-adic integers.

i.e. whether $L \otimes \mathbb{Z}_p \cong M\otimes \mathbb{Z}_p$.
"""
function is_locally_isometric(L::ZZLat, M::ZZLat, p::Int)
  return is_locally_isometric(L, M, ZZRingElem(p))
end

function is_locally_isometric(L::ZZLat, M::ZZLat, p::ZZRingElem)
  return genus(L, p) == genus(M, p)
end

################################################################################
#
#  Conversion between ZZLat and QuadLat
#
################################################################################

function _to_number_field_lattice(L::ZZLat, K, V)
  LL = lattice(V, change_base_ring(K, basis_matrix(L)))
  return LL
end

function _to_number_field_lattice(L::ZZLat;
                                  K::AnticNumberField = rationals_as_number_field()[1],
                                  V::QuadSpace = quadratic_space(K, gram_matrix(ambient_space(L))))
  return _to_number_field_lattice(L, K, V)
end


function _to_ZLat(L::QuadLat, K, V)
  pm = pseudo_matrix(L)
  cm = coefficient_ideals(pm)
  pmm = matrix(pm)
  bm = zero_matrix(FlintQQ, rank(L), dim(V))
  for i in 1:nrows(pm)
    a = norm(cm[i])
    for j in 1:ncols(pm)
      bm[i, j] = a * FlintQQ(pmm[i, j])
    end
  end
  return lattice(V, bm, check = false)
end

function _to_ZLat(L::QuadLat;
                  K::QQField = FlintQQ,
                  V::QuadSpace = quadratic_space(K, map_entries(FlintQQ, gram_matrix(ambient_space(L)))))
  return _to_ZLat(L, K, V)
end

################################################################################
#
#  Mass
#
################################################################################

@doc raw"""
    mass(L::ZZLat) -> QQFieldElem

Return the mass of the genus of `L`.
"""
function mass(L::ZZLat)
  @req is_definite(L) "L must be a definite lattice"
  return mass(genus(L))
end

################################################################################
#
#  Genus representatives
#
################################################################################

@doc raw"""
    genus_representatives(L::ZZLat) -> Vector{ZZLat}

Return representatives for the isometry classes in the genus of `L`.
"""
function genus_representatives(L::ZZLat)
  s = denominator(scale(L))
  L = rescale(L, s)
  LL = _to_number_field_lattice(L)
  K = base_field(L)
  G = genus_representatives(LL)
  res = ZZLat[]
  for N in G
    push!(res, _to_ZLat(N, K = K))
  end
  return [rescale(L, 1//s) for L in res]
end

################################################################################
#
#  Maximal integral lattice
#
################################################################################

# kept for testing
function _maximal_integral_lattice(L::ZZLat)
  LL = _to_number_field_lattice(L)
  M = maximal_integral_lattice(LL)
  return _to_ZLat(M, V = ambient_space(L))
end

@doc raw"""
    maximal_even_lattice(L::ZZLat, p) -> ZZLat

Given an even lattice `L` and a prime number `p` return an overlattice of `M`
which is maximal at `p` and agrees locally with `L` at all other places.

Recall that $L$ is called even if $\Phi(x,x) \in 2 \mathbb Z$ for all $x in L$.
"""
function maximal_even_lattice(L::ZZLat, p)
  while true
    ok, L = is_maximal_even(L, p)
    if ok
      return L
    end
  end
end

@doc raw"""
    maximal_even_lattice(L::ZZLat) -> ZZLat

Return a maximal even overlattice `M` of the even lattice `L`.

Recall that $L$ is called even if $\Phi(x,x) \in 2 \mathbb Z$ for all $x in L$.
Note that the genus of `M` is uniquely determined by the genus of `L`.
"""
function maximal_even_lattice(L::ZZLat)
  @req iseven(L) "The lattice must be even"
  for p in prime_divisors(ZZ(det(L)))
    L = maximal_even_lattice(L, p)
  end
  return L
end

function maximal_integral_lattice(L::ZZLat)
  @req denominator(norm(L)) == 1 "The quadratic form is not integral"
  L2 = rescale(L, 2)
  LL2 = maximal_even_lattice(L2)
  return rescale(LL2, QQ(1//2))
end


@doc raw"""
    is_maximal_even(L::ZZLat, p) -> Bool, ZZLat

Return if the (`p`-locally) even lattice `L` is maximal at `p` and an even overlattice `M`
of `L` with $[M:L]=p$ if `L` is not maximal and $1$ else.

Recall that $L$ is called even if $\Phi(x,x) \in 2 \mathbb{Z}$ for all $x in L$.
"""

function is_maximal_even(L::ZZLat, p)
  @req denominator(scale(L)) == 1 "The bilinear form is not integral"
  @req p != 2 || mod(ZZ(norm(L)),2) == 0 "The bilinear form is not even"

  # o-maximal lattices are classified
  # see Kirschmer Lemma 3.5.3
  if valuation(det(L), p)<= 1
    return true, L
  end
  G = change_base_ring(ZZ, gram_matrix(L))
  k = Native.GF(p)
  Gmodp = change_base_ring(k, G)
  r, V = left_kernel(Gmodp)
  VZ = lift(V[1:r,:])
  H = divexact(VZ * G * transpose(VZ), p)
  if p != 2
    Hk = change_base_ring(k, H)
    ok, __v = _isisotropic_with_vector_finite(Hk)
    if !ok
      @assert r == 2
      return true, L
    end
    _v = matrix(k, 1, length(__v), __v)
    v = lift(_v)
    sp = (v * H * transpose(v))[1,1]
    valv = iszero(sp) ? inf : valuation(sp, p)
    v = v * VZ
    sp = (v * G * transpose(v))[1,1]
    valv = iszero(sp) ? inf : valuation(sp, p)
    @assert valv >= 2
    v = QQ(1, p) * change_base_ring(QQ,v)
  else
    p = ZZ(p)
    R8 = residue_ring(ZZ, ZZ(8))
    R4 = residue_ring(ZZ, ZZ(4))
    findzero_mod4 = function(HR)
      z = R4(0)
      i = findfirst(==(z), R4.(diagonal(HR)))
      v = zero_matrix(ZZ, 1, r)
      if !(i isa Nothing)
        v[1, i] = 1
        return true, v
      else
        return false, v
      end
    end
    HR8 = change_base_ring(R8, H)
    ok, v = findzero_mod4(HR8)
    B = identity_matrix(R8, nrows(H))
    if !ok
      D, B = _jordan_2_adic(HR8)
      ok, v = findzero_mod4(D)
    end
    if !ok
      D, B1 = Hecke._normalize(D, p)
      B = B1 * B
      ok, v = findzero_mod4(D)
    end
    if !ok
      D, B1 = _two_adic_normal_forms(D, p, partial = true)
      B = B1 * B
      ok, v = _is_isotropic_with_vector_mod4(D)
      if !ok
        return true, L
      end
    end
    v = v * B
    v = map_entries(ZZ, v)
    v = v * VZ
    v = QQ(1,2) * change_base_ring(QQ, v)
  end
  v = v * basis_matrix(L)
  B = vcat(basis_matrix(L), v)
  LL = lattice(ambient_space(L), B, isbasis=false)
  @assert det(L) ==  det(LL) * p^2 && valuation(norm(LL), p) >= 0
  @assert denominator(scale(LL))==1
  @assert p!=2 || mod(ZZ(norm(LL)),2)==0
  return false, LL
end

@doc raw"""
    _is_isotropic_with_vector_mod4(Gnormal) -> Bool, MatElem

Return if `Gnormal` is isotropic mod 4 and an isotropic vector.

Assumes that G is in partial 2-adic normal form.
"""
function _is_isotropic_with_vector_mod4(Gnormal)
  R4 = residue_ring(ZZ, 4)
  G = change_base_ring(R4, Gnormal)
  D = diagonal(G)
  z = R4(0)
  v = zero_matrix(ZZ, 1, ncols(G))
  i = findfirst(==(z), D)
  if !(i isa Nothing)
    v[1, i] = 1
    return true, v
  end
  @assert nrows(G) <= 6 "$G"
  if nrows(G) == 1
    return false, v
  end
  # hardcoded isotropic vector for G in normal form (and no 0 mod 4 on the diag)
  if nrows(G) == 2
    if G[1,2] == 0 && D[1]+D[2] == 0
      v[1,1] = 1
      v[1,2] = 1
      return true, v
    else
      return false, v
    end
  end
  if nrows(G) == 3
    if D[3] in [R4(1),R4(3)]
      return false, v
    end
    @assert D[3] == R4(2)
    if sum(D[2:3]) == 0
      v[1,2] = 1; v[1,3] = 1
      return true, v
    end
    if G[1,2] == 0 && sum(D[1:2]) == 0
      v[1,1] = 1; v[1,2] = 1
      return true, v
    end
    if G[1,2] == 0 && sum(D) == 0
      v[1,1] = 1; v[1,2] = 1; v[1,3] = 1
      return true, v
    end
  end
  n = nrows(G)
  if D[1]+D[n] == 0
    v[1,1] = 1
    v[1,n] = 1
    return true, v
  end
  if D[n-1]+D[n] == 0
    v[1,n-1] = 1
    v[1,n] = 1
    return true, v
  end
  if D[1]+D[n-1] + D[n] == 0
    v[1,1] = 1
    v[1,n-1] = 1
    v[1,n] = 1
    return true, v
  end
  error("Something wrong!")
end

################################################################################
#
#  Scalar multiplication
#
################################################################################

@doc raw"""
    *(a::RationalUnion, L::ZZLat) -> ZZLat

Return the lattice $aM$ inside the ambient space of $M$.
"""
function Base.:(*)(a::RationalUnion, L::ZZLat)
  @assert has_ambient_space(L)
  if is_zero(a)
    B = zero_matrix(QQ, 0, degree(L))
  else
    B = a*basis_matrix(L)
  end
  return lattice_in_same_ambient_space(L, B, check = false)
end

function Base.:(*)(L::ZZLat, a::RationalUnion)
  return a * L
end

################################################################################
#
#  Canonical basis matrix
#
################################################################################

@attr FakeFmpqMat function _canonical_basis_matrix(L::ZZLat)
  return hnf(FakeFmpqMat(basis_matrix(L)))
end

################################################################################
#
#  Equality and hash
#
################################################################################

@doc raw"""
Return `true` if both lattices have the same ambient quadratic space
and the same underlying module.
"""
function Base.:(==)(L1::ZZLat, L2::ZZLat)
  V1 = ambient_space(L1)
  V2 = ambient_space(L2)
  if V1 != V2
    return false
  end
  return _canonical_basis_matrix(L1) == _canonical_basis_matrix(L2)
end

function Base.hash(L::ZZLat, u::UInt)
  V = ambient_space(L)
  B = hnf(FakeFmpqMat(basis_matrix(L)))
  # We compare lattices in the same ambient space, and since hnf for the basis
  # matric is unique, one just needs to compare them.
  h = xor(hash(V), hash(B))
  return xor(h, u)
end

@doc raw"""
    local_modification(M::ZZLat, L::ZZLat, p)

Return a local modification of `M` that matches `L` at `p`.

INPUT:

- ``M`` -- a `\mathbb{Z}_p`-maximal lattice
- ``L`` -- the a lattice
            isomorphic to `M` over `\QQ_p`
- ``p`` -- a prime number

OUTPUT:

an integral lattice `M'` in the ambient space of `M` such that `M` and `M'` are locally equal at all
completions except at `p` where `M'` is locally isometric to the lattice `L`.
"""
function local_modification(M::ZZLat, L::ZZLat, p)
  # notation
  d = denominator(inv(gram_matrix(L)))
  level = valuation(d,p)
  d = p^(level+1) # +1 since scale(M) <= 1/2 ZZ

  @req is_isometric(L.space, M.space, p) "Quadratic spaces must be locally isometric at p"
  s = denominator(scale(L))
  L_max = rescale(L, s)
  L_max = maximal_integral_lattice(L_max)
  L_max = rescale(L_max, 1//s)

  # invert the gerstein operations
  GLm, U = padic_normal_form(gram_matrix(L_max), p, prec=level+3)
  B1 = inv(U*basis_matrix(L_max))

  GM, UM = padic_normal_form(gram_matrix(M), p, prec=level+3)
  # assert GLm == GM at least modulo p^prec
  B2 = B1 * UM * basis_matrix(M)
  Lp = lattice(M.space, B2, check = false)

  # the local modification
  S = intersect(Lp, M) + d * M
  # confirm result
  @hassert :Lattice 2 genus(S, p)==genus(L, p)
  return S
end

################################################################################
#
#  Kernel lattice
#
################################################################################

@doc raw"""
    kernel_lattice(L::ZZLat, f::MatElem;
                   ambient_representation::Bool = true) -> ZZLat

Given a $\mathbf{Z}$-lattice $L$ and a matrix $f$ inducing an endomorphism of
$L$, return $\ker(f)$ is a sublattice of $L$.

If `ambient_representation` is `true` (the default), the endomorphism is
represented with respect to the ambient space of $L$. Otherwise, the
endomorphism is represented with respect to the basis of $L$.
"""
function kernel_lattice(L::ZZLat, f::MatElem; ambient_representation::Bool = true)
  bL = basis_matrix(L)
  if ambient_representation
    if !is_square(bL)
      fl, finL = can_solve_with_solution(bL, bL * f, side = :left)
      @req fl "f must preserve the lattice L"
    else
      finL = bL * f * inv(bL)
    end
  else
    finL = f
  end
  k, K = left_kernel(change_base_ring(ZZ, finL))
  return lattice(ambient_space(L), K*basis_matrix(L), check = false)
end

################################################################################
#
#  Co/Invariant lattice
#
################################################################################

@doc raw"""
    invariant_lattice(L::ZZLat, G::Vector{MatElem};
                      ambient_representation::Bool = true) -> ZZLat
    invariant_lattice(L::ZZLat, G::MatElem;
                      ambient_representation::Bool = true) -> ZZLat

Given a $\mathbf{Z}$-lattice $L$ and a list of matrices $G$ inducing
endomorphisms of $L$ (or just one matrix $G$), return the lattice $L^G$,
consisting on elements fixed by $G$.

If `ambient_representation` is `true` (the default), the endomorphism is
represented with respect to the ambient space of $L$. Otherwise, the
endomorphism is represented with respect to the basis of $L$.
"""
function invariant_lattice(L::ZZLat, G::Vector{<:MatElem};
                           ambient_representation::Bool = true)
  if length(G) == 0
    return L
  end

  M = kernel_lattice(L, G[1] - 1,
                     ambient_representation = ambient_representation)
  for i in 2:length(G)
    N = kernel_lattice(L, G[i] - 1,
                       ambient_representation = ambient_representation)
    M = intersect(M, N)
  end
  return M
end

function invariant_lattice(L::ZZLat, G::MatElem;
                           ambient_representation::Bool = true)
  return kernel_lattice(L, G - 1, ambient_representation = ambient_representation)
end

@doc raw"""
    coinvariant_lattice(L::ZZLat, G::Vector{MatElem};
                        ambient_representation::Bool = true) -> ZZLat
    coinvariant_lattice(L::ZZLat, G::MatElem;
                        ambient_representation::Bool = true) -> ZZLat

Given a $\mathbf{Z}$-lattice $L$ and a list of matrices $G$ inducing
endomorphisms of $L$ (or just one matrix $G$), return the orthogonal
complement $L_G$ in $L$ of the fixed lattice $L^G$
(see [`invariant_lattice`](@ref)).

If `ambient_representation` is `true` (the default), the endomorphism is
represented with respect to the ambient space of $L$. Otherwise, the
endomorphism is represented with respect to the basis of $L$.
"""
coinvariant_lattice(L::ZZLat, G::Union{MatElem, Vector{<:MatElem}}; ambient_representation::Bool = true) =
  orthogonal_submodule(L, invariant_lattice(L, G, ambient_representation = ambient_representation))

################################################################################
#
#  Membership check
#
################################################################################

@doc raw"""
    Base.in(v::Vector, L::ZZLat) -> Bool

Return whether the vector `v` lies in the lattice `L`.
"""
function Base.in(v::Vector, L::ZZLat)
  @req length(v) == degree(L) "The vector should have the same length as the degree of the lattice."
  V = matrix(QQ, 1, length(v), v)
  return V in L
end

@doc raw"""
    Base.in(v::QQMatrix, L::ZZLat) -> Bool

Return whether the row span of `v` lies in the lattice `L`.
"""
function Base.in(v::QQMatrix, L::ZZLat)
  @req ncols(v) == degree(L) "The vector should have the same length as the degree of the lattice."
  @req nrows(v) == 1 "Must be a row vector."
  B = basis_matrix(L)
  fl, w = can_solve_with_solution(B, v, side=:left)
  return fl && isone(denominator(w))
end

@doc raw"""
    is_primitive(L::ZZLat, v::Union{Vector, QQMatrix}) -> Bool

Return whether the vector `v` is primitive in `L`.

A vector `v` in a $\mathbb Z$-lattice `L` is called primitive
if for all `w` in `L` such that $v = dw$ for some integer `d`,
then $d = \pm 1$.
"""
is_primitive(::ZZLat, ::Union{Vector, QQMatrix})

function is_primitive(L::ZZLat, v::Vector{<: RationalUnion})
  @req v in L "v is not contained in L"
  is_zero(v) && return true
  M = lattice_in_same_ambient_space(L, matrix(QQ,1,length(v), v), check = false)
  return is_primitive(L, M)
end

function is_primitive(L::ZZLat, v::QQMatrix)
  @req v in L "v is not contained in L"
  is_zero(v) && return true
  M = lattice_in_same_ambient_space(L, v, check = false)
  return is_primitive(L, M)
end

@doc raw"""
    divisibility(L::ZZLat, v::Union{Vector, QQMatrix}) -> QQFieldElem

Return the divisibility of `v` with respect to `L`.

For a vector `v` in the ambient quadratic space $(V, \Phi)$ of `L`,
we call the divisibility of `v` with the respect to `L` the
non-negative generator of the fractional $\mathbb Z$-ideal
$\Phi(v, L)$.
"""
divisibility(::ZZLat, ::Union{Vector, QQMatrix})

function divisibility(L::ZZLat, v::Vector{<: RationalUnion})
  @req length(v) == degree(L) "The vector should have the same length as the degree of the lattice"
  imv = matrix(QQ, 1, length(v), v)*gram_matrix(ambient_space(L))*transpose(basis_matrix(L))
  imv = fractional_ideal(ZZ, vec(collect(imv)))
  return gen(imv)
end

function divisibility(L::ZZLat, v::QQMatrix)
  @req ncols(v) == degree(L) "The vector should have the same length as the degree of the lattice"
  @req nrows(v) == 1 "v must be a row vector"
  imv = v*gram_matrix(ambient_space(L))*transpose(basis_matrix(L))
  imv = fractional_ideal(ZZ, vec(collect(imv)))
  return gen(imv)
end

################################################################################
#
#  LLL-reduction
#
################################################################################

@doc raw"""
    lll(L::ZZLat, same_ambient::Bool = true) -> ZZLat

Given an integral $\mathbb Z$-lattice `L` with basis matrix `B`, compute a basis
`C` of `L` such that the gram matrix $G_C$ of `L` with respect to `C` is LLL-reduced.

By default, it creates the lattice in the same ambient space as `L`. This
can be disabled by setting `same_ambient = false`.
Works with both definite and indefinite lattices.
"""
function lll(L::ZZLat; same_ambient::Bool = true)
  rank(L) == 0 && return L
  def = is_definite(L)
  G = gram_matrix(L)
  d = denominator(G)
  M = change_base_ring(ZZ, d*G)
  if def
    neg = M[1,1] < 0
    if neg
      G2, U = lll_gram_with_transform(-M)
      G2 = -G2
    else
      G2, U = lll_gram_with_transform(M)
    end
  elseif (rank(L) == 3) && (abs(det(M)) == 1)
    G2, U = lll_gram_indef_ternary_hyperbolic(M)
  elseif det(M) == 1
    G2, U = lll_gram_indef_with_transform(M)
  else
    # In the modular case, one may perform another LLL-reduction to obtain
    # a better output
    G21, U21 = lll_gram_indef_with_transform(M)
    G2, U2 = lll_gram_indef_with_transform(G21)
    U = U2*U21
  end
  if same_ambient
    B2 = U*basis_matrix(L)
    return lattice(ambient_space(L), B2, check = false)::ZZLat
  else
    return integer_lattice(gram = (1//d)*change_base_ring(QQ, G2))
  end
end

################################################################################
#
#  Root lattice recognition
#
################################################################################

@doc raw"""
    root_lattice_recognition(L::ZZLat)

Return the ADE type of the root sublattice of `L`.

Input:

`L` -- a definite and integral $\mathbb{Z}$-lattice.

Output:

Two lists, the first one containing the ADE types
and the second one the irreducible root sublattices.

For more recognizable gram matrices use [`root_lattice_recognition_fundamental`](@ref).

# Examples

```jldoctest
julia> L = integer_lattice(gram=ZZ[4  0 0  0 3  0 3  0;
                            0 16 8 12 2 12 6 10;
                            0  8 8  6 2  8 4  5;
                            0 12 6 10 2  9 5  8;
                            3  2 2  2 4  2 4  2;
                            0 12 8  9 2 12 6  9;
                            3  6 4  5 4  6 6  5;
                            0 10 5  8 2  9 5  8])
Integer lattice of rank 8 and degree 8
with gram matrix
[4    0   0    0   3    0   3    0]
[0   16   8   12   2   12   6   10]
[0    8   8    6   2    8   4    5]
[0   12   6   10   2    9   5    8]
[3    2   2    2   4    2   4    2]
[0   12   8    9   2   12   6    9]
[3    6   4    5   4    6   6    5]
[0   10   5    8   2    9   5    8]

julia> R = root_lattice_recognition(L)
([(:A, 1), (:D, 6)], ZZLat[Integer lattice of rank 1 and degree 8, Integer lattice of rank 6 and degree 8])
```
"""
function root_lattice_recognition(L::ZZLat)
  irr = irreducible_components(root_sublattice(L))
  return Tuple{Symbol, Int}[ADE_type(gram_matrix(i)) for i in irr], irr
end

@doc raw"""
    irreducible_components(L::ZZLat) -> Vector{ZZLat}

Return the irreducible components ``L_i`` of the positive definite lattice ``L``.

This yields a maximal orthogonal splitting of `L` as
```math
L = \bigoplus_i L_i.
```
"""
function irreducible_components(L::ZZLat)
  @req is_definite(L) "L must be definite"
  if is_positive_definite(L)
    return _irreducible_components_pos_def(L)
  end
  Lpos = rescale(L, -1)
  irr = _irreducible_components_pos_def(Lpos)
  V = ambient_space(L)
  return ZZLat[lattice(V, basis_matrix(i), check = false) for i in irr]
end

function _irreducible_components_pos_def(L::ZZLat, upper_bound=nothing)
  components1 =  _irreducible_components_gram(L)
  components2 = ZZLat[]
  irreducible = ZZLat[]
  # special for root lattices
  for c in components1
    if all(abs(i)==2 for i in diagonal(gram_matrix(c)))
      push!(irreducible, c)
    else
      append!(components2, _irreducible_components_gram(c))
    end
  end
  # try once more with an lll -- maybe we are lucky
  components3 = []
  for c in components2
    if all(abs(i)==2 for i in diagonal(gram_matrix(c)))
      push!(irreducible, c)
    else
      append!(components3, _irreducible_components_gram(c))
    end
  end

  # fall back to short vectors
  for c in components3
    if upper_bound === nothing
      ub = maximum([abs(i) for i in diagonal(gram_matrix(c))])
    else
      ub = upper_bound
    end
    append!(irreducible, _irreducible_components_short_vectors(c, ub))
  end
  @hassert :Lattice 0 sum(Int[rank(i) for i in irreducible], init=0) == rank(L)
  return irreducible
end

# finds the irreducible components of the graph of the gram matrix
# if it has only 2 on the diagonal, this is good enough
# otherwise it may be insufficient
function _irreducible_components_gram(L::ZZLat)
  L = lll(L)
  V = ambient_space(L)
  B = basis_matrix(L)
  B = [B[i,:] for i in 1:nrows(B)]
  C = QQMatrix[]
  components = ZZLat[]
  while length(B) > 0
    basis = QQMatrix[]
    b = pop!(B)
    push!(basis, b)
    flag = true
    while flag
      flag = false
      for c in B
        if any([inner_product(V, a, c) != 0 for a in basis])
          push!(basis,c)
          deleteat!(B,findfirst(==(c), B))
          flag = true
          break
        end
      end
    end
    S = lattice(ambient_space(L),reduce(vcat, basis), check = false)
    push!(components, S)
  end
  @hassert :Lattice 0 sum(Int[rank(i) for i in components], init=0)==rank(L)
  return components
end

# assumes that L is integral
function _irreducible_components_short_vectors(L, ub)
  sv = short_vectors(L, ub)
  if length(sv) == 0
    return [lattice(ambient_space(L), zero_matrix(QQ, 0, degree(L)))]
  end
  sort!(sv, by=(i->i[2]))
  B = matrix(ZZ, 1, rank(L), sv[1][1])
  G = change_base_ring(ZZ,gram_matrix(L))
  l = sv[1][2]
  for s in sv
    if s[2]>l
      # we hit a new length and should check if we can split
      l = s[2]
      k, K = kernel(B*G)
      if isone(hnf(vcat(B,transpose(K))))
        break
      end
    end

    if (B*G*s[1])[1] == 0
      continue
    end
    v = matrix(ZZ,1,rank(L),s[1])
    reduce_mod_hnf_ur!(v, B)
    if iszero(v)
      continue
    end
    B = hnf(vcat(B, v))
    B = B[1:rank(B),:]
    if nrows(B) == ncols(B) && all(abs(B[i,i])==1 for i in 1:nrows(B))
      break
    end
  end
  # We have found some irreducible component.
  if nrows(B) == rank(L)
    return [L]
  end
  L1 = lattice(ambient_space(L), B*basis_matrix(L), check = false)
  L2 = orthogonal_submodule(L, L1)
  return append!([L1], _irreducible_components_short_vectors(L2, ub))
end

@doc raw"""
    root_lattice_recognition_fundamental(L::ZZLat)

Return the ADE type of the root sublattice of `L`
as well as the corresponding irreducible root sublattices
with basis given by a fundamental root system.

Input:

`L` -- a definite and integral $\mathbb Z$-lattice.

Output:

- the root sublattice, with basis given by a fundamental root system
- the ADE types
- a Vector consisting of the irreducible root sublattices.

# Examples

```jldoctest
julia> L = integer_lattice(gram=ZZ[4  0 0  0 3  0 3  0;
                            0 16 8 12 2 12 6 10;
                            0  8 8  6 2  8 4  5;
                            0 12 6 10 2  9 5  8;
                            3  2 2  2 4  2 4  2;
                            0 12 8  9 2 12 6  9;
                            3  6 4  5 4  6 6  5;
                            0 10 5  8 2  9 5  8])
Integer lattice of rank 8 and degree 8
with gram matrix
[4    0   0    0   3    0   3    0]
[0   16   8   12   2   12   6   10]
[0    8   8    6   2    8   4    5]
[0   12   6   10   2    9   5    8]
[3    2   2    2   4    2   4    2]
[0   12   8    9   2   12   6    9]
[3    6   4    5   4    6   6    5]
[0   10   5    8   2    9   5    8]

julia> R = root_lattice_recognition_fundamental(L);

julia> gram_matrix(R[1])
[2    0    0    0    0    0    0]
[0    2    0   -1    0    0    0]
[0    0    2   -1    0    0    0]
[0   -1   -1    2   -1    0    0]
[0    0    0   -1    2   -1    0]
[0    0    0    0   -1    2   -1]
[0    0    0    0    0   -1    2]

```
"""
function root_lattice_recognition_fundamental(L::ZZLat)
  V = ambient_space(L)
  ADE,components = root_lattice_recognition(L)
  components_new = ZZLat[]
  basis = zero_matrix(QQ,0,degree(L))
  for i in 1:length(ADE)
    ade = ADE[i]
    S = components[i]
    _, trafo = _ADE_type_with_isometry_irreducible(S)
    BS = trafo * basis_matrix(S)
    Snew = lattice(V, BS)
    push!(components_new, Snew)
    basis = vcat(basis, BS)
  end
  C = lattice(ambient_space(L), basis, check = false)
  return C, ADE, components_new
end

@doc raw"""
    ADE_type(G::MatrixElem) -> Tuple{Symbol,Int64}

Return the type of the irreducible root lattice
with gram matrix `G`.

See also [`root_lattice_recognition`](@ref).

# Examples
```jldoctest
julia> Hecke.ADE_type(gram_matrix(root_lattice(:A,3)))
(:A, 3)
```
"""
function ADE_type(G::MatrixElem)
  r = rank(G)
  d = abs(det(G))
  if r == 8 && d==1
    return (:E,8)
  end
  if r == 7 && d == 2
    return (:E,7)
  end
  if r == 6 && d ==3
    return (:E,6)
  end
  if d == r + 1
    return (:A, r)
  end
  if d == 4
    return (:D, r)
  end
  error("not a definite root lattice")
end

function _ADE_type_with_isometry_irreducible(L)
  ADE = ADE_type(gram_matrix(L))
  R = root_lattice(ADE...)
  e = sign(gram_matrix(L)[1,1])
  if e == -1
    R = rescale(R,-1)
  end
  t, T = is_isometric_with_isometry(R, L, ambient_representation=false)
  @hassert :Lattice 1 t
  return ADE, T
end

@doc raw"""
    root_sublattice(L::ZZLat) -> ZZLat

Return the sublattice spanned by the roots
of length at most $2$.

Input:

`L` - a definite integral lattice

Output:

The sublattice of `L` spanned by all
vectors `x` of `L` with $|x^2|\leq 2$.

# Examples
```jldoctest
julia> L = integer_lattice(gram = ZZ[2 0; 0 4]);

julia> root_sublattice(L)
Integer lattice of rank 1 and degree 2
with gram matrix
[2]

julia> basis_matrix(root_sublattice(L))
[1   0]

```
"""
function root_sublattice(L::ZZLat)
  V = ambient_space(L)
  @req is_integral(L) "L must be integral"
  @req is_definite(L) "L must be definite"
  if is_negative_definite(L)
    L = rescale(L,-1)
  end
  sv = reduce(vcat, ZZMatrix[matrix(ZZ,1,rank(L),a[1]) for a in short_vectors(L, 2)],init=zero_matrix(ZZ,0,rank(L)))
  hnf!(sv)
  B = sv[1:rank(sv),:]*basis_matrix(L)
  return lattice(V, B, check=false)
end

################################################################################
#
#  Primitive extensions and glue maps
#
################################################################################

@doc raw"""
    primitive_closure(M::ZZLat, N::ZZLat) -> ZZLat

Given two $\mathbb Z$-lattices `M` and `N` with $N \subseteq \mathbb{Q} M$,
return the primitive closure $M \cap \mathbb{Q} N$ of `N` in `M`.

# Examples

```jldoctest
julia> M = root_lattice(:D, 6);

julia> N = lattice_in_same_ambient_space(M, 3*basis_matrix(M)[1,:]);

julia> basis_matrix(N)
[3   0   0   0   0   0]

julia> N2 = primitive_closure(M, N)
Integer lattice of rank 1 and degree 6
with gram matrix
[2]

julia> basis_matrix(N2)
[1   0   0   0   0   0]

julia> M2 = primitive_closure(dual(M), M);

julia> is_integral(M2)
false

```
"""
function primitive_closure(M::ZZLat, N::ZZLat)
  @req ambient_space(M) === ambient_space(N) "Lattices must be in the same ambient space"

  ok, B = can_solve_with_solution(basis_matrix(M), basis_matrix(N), side = :left)

  @req ok "N must be contained in the rational span of M"

  Bz = numerator(FakeFmpqMat(B))
  Bz = saturate(Bz)
  return lattice(ambient_space(M), Bz*basis_matrix(M), check = false)
end

@doc raw"""
    is_primitive(M::ZZLat, N::ZZLat) -> Bool

Given two $\mathbb Z$-lattices $N \subseteq M$, return whether `N` is a
primitive sublattice of `M`.

# Examples

```jldoctest
julia> U = hyperbolic_plane_lattice(3);

julia> bU = basis_matrix(U);

julia> e1, e2 = bU[1,:], bU[2,:]
([1 0], [0 1])

julia> N = lattice_in_same_ambient_space(U, e1 + e2)
Integer lattice of rank 1 and degree 2
with gram matrix
[6]

julia> is_primitive(U, N)
true

julia> M = root_lattice(:A, 3);

julia> f = matrix(QQ, 3, 3, [0 1 1; -1 -1 -1; 1 1 0]);

julia> N = kernel_lattice(M, f+1)
Integer lattice of rank 1 and degree 3
with gram matrix
[4]

julia> is_primitive(M, N)
true
```
"""
function is_primitive(M::ZZLat, N::ZZLat)
  @req is_sublattice(M, N) "N must be a sublattice of M"

  return primitive_closure(M, N) == N
end

@doc raw"""
    glue_map(L::ZZLat, S::ZZLat, R::ZZLat; check=true)
                           -> Tuple{TorQuadModuleMor, TorQuadModuleMor, TorQuadModuleMor}

Given three integral $\mathbb Z$-lattices `L`, `S` and `R`, with `S` and `R`
primitive sublattices of `L` and such that the sum of the ranks of `S` and `R`
is equal to the rank of `L`, return the glue map $\gamma$ of the primitive
extension $S+R \subseteq L$, as well as the inclusion maps of the domain and
codomain of $\gamma$ into the respective discriminant groups of `S` and `R`.

# Example

```jldoctest
julia> M = root_lattice(:E,8);

julia> f = matrix(QQ, 8, 8, [-1 -1  0  0  0  0  0  0;
                              1  0  0  0  0  0  0  0;
                              0  1  1  0  0  0  0  0;
                              0  0  0  1  0  0  0  0;
                              0  0  0  0  1  0  0  0;
                              0  0  0  0  0  1  1  0;
                             -2 -4 -6 -5 -4 -3 -2 -3;
                              0  0  0  0  0  0  0  1]);

julia> S = kernel_lattice(M ,f-1)
Integer lattice of rank 4 and degree 8
with gram matrix
[12   -3    0   -3]
[-3    2   -1    0]
[ 0   -1    2    0]
[-3    0    0    2]

julia> R = kernel_lattice(M , f^2+f+1)
Integer lattice of rank 4 and degree 8
with gram matrix
[ 2   -1    0    0]
[-1    2   -6    0]
[ 0   -6   30   -3]
[ 0    0   -3    2]

julia> glue, iS, iR = glue_map(M, S, R)
(Map: finite quadratic module -> finite quadratic module, Map: finite quadratic module -> finite quadratic module, Map: finite quadratic module -> finite quadratic module)

julia> is_bijective(glue)
true
```
"""
function glue_map(L::ZZLat, S::ZZLat, R::ZZLat; check=true)
  if check
    @req is_integral(L) "The lattices must be integral"
    @req is_primitive(L, S) && is_primitive(L, R) "S and R must be primitive in L"
    @req iszero(basis_matrix(S)*gram_matrix(ambient_space(L))*transpose(basis_matrix(R))) "S and R must be orthogonal in L"
    @req rank(L) == rank(S) + rank(R) "The sum of the ranks of S and R must be equal to the rank of L"
  end

  SR = S+R
  @assert rank(SR) == rank(L)
  orth = orthogonal_submodule(lattice(ambient_space(L)), SR)
  bSR = vcat(basis_matrix(S), basis_matrix(R), basis_matrix(orth))
  ibSR = inv(bSR)
  I = identity_matrix(QQ,degree(L))
  prS = ibSR * I[:,1:rank(S)] * basis_matrix(S)
  prR = ibSR * I[:,rank(S)+1:rank(R)+rank(S)] * basis_matrix(R)
  bL = basis_matrix(L)
  DS = discriminant_group(S)
  DR = discriminant_group(R)
  gens = TorQuadModuleElem[]
  imgs = TorQuadModuleElem[]
  for i in 1:rank(L)
    d = bL[i,:]
    g = DS(vec(collect(d * prS)))
    if all(i == 0 for i in lift(g))
      continue
    end
    push!(gens, g)
    push!(imgs, DR(vec(collect(d * prR))))
  end
  HS, iS = sub(DS, gens)
  HR, iR = sub(DR, imgs)
  glue_map = hom(HS, HR, [HR(lift(i)) for i in imgs])
  @hassert :Lattice 2 is_bijective(glue_map)
  @hassert :Lattice 2 overlattice(glue_map) == L
  return glue_map, iS, iR
end

@doc raw"""
    overlattice(glue_map::TorQuadModuleMor) -> ZZLat

Given the glue map of a primitive extension of $\mathbb Z$-lattices
$S+R \subseteq L$, return `L`.

# Example

```jldoctest
julia> M = root_lattice(:E,8);

julia> f = matrix(QQ, 8, 8, [ 1  0  0  0  0  0  0  0;
                              0  1  0  0  0  0  0  0;
                              1  2  4  4  3  2  1  2;
                             -2 -4 -6 -5 -4 -3 -2 -3;
                              2  4  6  4  3  2  1  3;
                             -1 -2 -3 -2 -1  0  0 -2;
                              0  0  0  0  0 -1  0  0;
                             -1 -2 -3 -3 -2 -1  0 -1]);

julia> S = kernel_lattice(M ,f-1)
Integer lattice of rank 4 and degree 8
with gram matrix
[ 2   -1     0     0]
[-1    2    -1     0]
[ 0   -1    12   -15]
[ 0    0   -15    20]

julia> R = kernel_lattice(M , f^4+f^3+f^2+f+1)
Integer lattice of rank 4 and degree 8
with gram matrix
[10   -4    0    1]
[-4    2   -1    0]
[ 0   -1    4   -3]
[ 1    0   -3    4]

julia> glue, iS, iR = glue_map(M, S, R);

julia> overlattice(glue) == M
true
```
"""
function overlattice(glue_map::TorQuadModuleMor)
  S = relations(domain(glue_map))
  R = relations(codomain(glue_map))
  glue = [lift(g) + lift(glue_map(g)) for g in gens(domain(glue_map))]
  z = zero_matrix(QQ, 0, degree(S))
  glue = reduce(vcat, [matrix(QQ, 1, degree(S), g) for g in glue], init=z)
  glue = vcat(basis_matrix(S + R), glue)
  glue = FakeFmpqMat(glue)
  B = hnf(glue)
  B = QQ(1, denominator(glue))*change_base_ring(QQ, numerator(B))
  return lattice(ambient_space(S), B[end-rank(S)-rank(R)+1:end,:], check=false)
end

################################################################################
#
#  Primary/elementary lattices
#
################################################################################

@doc raw"""
    is_primary_with_prime(L::ZZLat) -> Bool, ZZRingElem

Given a $\mathbb Z$-lattice `L`, return whether `L` is primary, that is whether `L`
is integral and its discriminant group (see [`discriminant_group`](@ref)) is a
`p`-group for some prime number `p`. In case it is, `p` is also returned as
second output.

Note that for unimodular lattices, this function returns `(true, 1)`. If the
lattice is not primary, the second return value is `-1` by default.
"""
function is_primary_with_prime(L::ZZLat)
  @req is_integral(L) "L must be integral"
  d = ZZ(abs(det(L)))
  if d == 1
    return true, d
  end
  pd = prime_divisors(d)
  if length(pd) != 1
    return false, ZZ(-1)
  end
  return true, pd[1]
end

@doc raw"""
    is_primary(L::ZZLat, p::Union{Integer, ZZRingElem}) -> Bool

Given an integral $\mathbb Z$-lattice `L` and a prime number `p`,
return whether `L` is `p`-primary, that is whether its discriminant group
(see [`discriminant_group`](@ref)) is a `p`-group.
"""
function is_primary(L::ZZLat, p::Union{Integer, ZZRingElem})
  bool, q = is_primary_with_prime(L)
  return bool && q == p
end

@doc raw"""
    is_unimodular(L::ZZLat) -> Bool

Given an integral $\mathbb Z$-lattice `L`, return whether `L` is unimodular,
that is whether its discriminant group (see [`discriminant_group`](@ref))
is trivial.
"""
is_unimodular(L::ZZLat) = is_primary(L, 1)

@doc raw"""
    is_elementary_with_prime(L::ZZLat) -> Bool, ZZRingElem

Given a $\mathbb Z$-lattice `L`, return whether `L` is elementary, that is whether
`L` is integral and its discriminant group (see [`discriminant_group`](@ref)) is
an elemenentary `p`-group for some prime number `p`. In case it is, `p` is also
returned as second output.

Note that for unimodular lattices, this function returns `(true, 1)`. If the lattice
is not elementary, the second return value is `-1` by default.
"""
function is_elementary_with_prime(L::ZZLat)
  bool, p = is_primary_with_prime(L)
  bool || return false, ZZ(-1)
  if !is_integer(p*scale(dual(L)))
    return false, ZZ(-1)
  end
  return bool, p
end

@doc raw"""
    is_elementary(L::ZZLat, p::Union{Integer, ZZRingElem}) -> Bool

Given an integral $\mathbb Z$-lattice `L` and a prime number `p`, return whether
`L` is `p`-elementary, that is whether its discriminant group
(see [`discriminant_group`](@ref)) is an elementary `p`-group.
"""
function is_elementary(L::ZZLat, p::Union{Integer, ZZRingElem})
  bool, q = is_elementary_with_prime(L)
  return bool && q == p
end

################################################################################
#
#  Isometry test indefinite lattices
#
################################################################################

@doc raw"""
    reflection(gram::QQMatrix, v::QQMatrix) -> QQMatrix

Return the matrix representation of the orthogonal reflection in the row vector `v`.
"""
function reflection(gram::MatElem, v::MatElem)
  n = ncols(gram)
  E = identity_matrix(base_ring(gram), n)
  c = base_ring(gram)(2) * ((v * gram * transpose(v)))[1,1]^(-1)
  ref = zero_matrix(base_ring(gram), n, n)
  for k in 1:n
    ref[k,:] = E[k,:] - c*(E[k,:] * gram * transpose(v))*v
  end
  return ref
end

@doc raw"""
    _decompose_in_reflections(G::QQMatrix, T::QQMatrix, p, nu) -> (err, Vector{QQMatrix})

Decompose the approximate isometry `T` into a product of reflections
and return the error.

The algorithm follows Shimada [Shim2018](@cite)
The error depends on the approximation error of `T`, i.e. $T G T^t - G$.

# Arguments
- `G::QQMatrix`: a diagonal matrix
- `T::QQMatrix`: an isometry up to some padic precision
- `p`: a prime number
"""
function _decompose_in_reflections(G::QQMatrix, T::QQMatrix, p)
  @assert is_diagonal(G)
  p = ZZ(p)
  if p == 2
    delta = 1
  else
    delta = 0
  end
  gammaL = [valuation(d, p) for d in diagonal(G)]
  gamma = minimum(gammaL)
  l = ncols(G)
  E = parent(G)(1)
  reflection_vectors = QQMatrix[]
  Trem = deepcopy(T)
  k = 1
  while k <= l
    g = Trem[k,:]
    bm = g - E[k,:]
    qm = bm * G * transpose(bm)
    if valuation(qm, p) <= gammaL[k] + 2*delta
      tau1 = reflection(G, bm)
      push!(reflection_vectors, bm)
      Trem = Trem * tau1
    else
      bp = g + E[k,:]
      qp = bp * G * transpose(bp)
      @assert valuation(qp, p) <= gammaL[k] + 2*delta
      tau1 = reflection(G, bp)
      tau2 = reflection(G, E[k,:])
      push!(reflection_vectors,bp)
      push!(reflection_vectors,E[k,:])
      Trem = Trem * tau1 * tau2
    end
    k += 1
  end
  reverse!(reflection_vectors)
  R = reduce(*, reflection(G, v) for v in reflection_vectors)
  err = valuation(T - R, p)
  return err, reflection_vectors
end


function _is_isometric_indef(L::ZZLat, M::ZZLat)
  @req rank(L)>=3 "Strong approximation needs rank at least 3"
  @req degree(L)==rank(L) "Lattice needs to be full for now"

  # scale integral
  n = rank(L)
  s = scale(M)
  M = rescale(M,s)
  L = rescale(L,s)
  @assert scale(M)==1
  @assert scale(L)==1
  g = genus(L)
  if g != genus(M)
    return false
  end
  S, isS = _improper_spinor_generators(g)
  if length(S)==0
    # unique spinor genus
    return true
  end
  f, r = _is_isometric_indef_approx(L, M)
  return is_zero(isS(r))
end

function _is_isometric_indef_approx(L::ZZLat, M::ZZLat)
  # move to same ambient space
  qL = ambient_space(L)
  diag, trafo = Hecke._gram_schmidt(gram_matrix(qL), identity)
  qL1 = quadratic_space(QQ, diag)

  L1 = lattice(qL1, basis_matrix(L)*inv(trafo), check=false)
  @hassert :Lattice 1 genus(L1) == genus(L)
  qM = ambient_space(M)
  b, T = is_isometric_with_isometry(qM, qL1)
  @assert b  # same genus implies isomorphic space
  M1 = lattice(qL1, basis_matrix(M)*T, check=false)
  @hassert :Lattice 1 genus(M1) == genus(L)
  r1 = index(M1,intersect(M1,L1))

  V = ambient_space(L1)
  gramV = gram_matrix(V)
  sL = 8//scale(dual(L1))
  bad = support(2*det(L1))
  extra = 10
  @label more_precision
  targets = Tuple{QQMatrix,ZZRingElem,Int}[]
  for p in bad
    vp = valuation(sL, p) + 1
    if valuation(r1, p)==0
      fp = identity_matrix(QQ, dim(qL1))
      push!(targets,(fp, p , vp))
      continue
    end
    # precision seems to deteriorate along the number of reflections
    precp = vp + 2*rank(L) + extra
    # Approximate an isometry fp: Lp --> Mp
    normalM1, TM1 = Hecke.padic_normal_form(gram_matrix(M1), p, prec=precp)
    normalL1, TL1 = Hecke.padic_normal_form(gram_matrix(L1), p, prec=precp)
    @assert normalM1 == normalL1
    TT = inv(TL1) * TM1
    fp = inv(basis_matrix(L1))* TT * basis_matrix(M1)
    if valuation(det(fp)-1,p)<= vp
      # we want fp in SO(Vp)
      # compose with a reflection preserving Lp
      norm_gen = _norm_generator(normalL1, p) * inv(TL1) * basis_matrix(L1)
      @assert valuation((norm_gen * gramV * transpose(norm_gen))[1,1],p)==valuation(norm(L1), p)
      fp = reflection(gramV, norm_gen) * fp
      @assert valuation(det(fp)-1, p)>= vp
    end
    # double check that fp: Lp --> Mp
    M1fp = lattice(V, basis_matrix(L1) * fp, check=false)
    indexp = index(M1,intersect(M1fp, M1))
    @assert valuation(indexp,p)==0
    push!(targets,(fp, p, vp))
  end
  f = zero_matrix(QQ,0,0)
  try
    f = weak_approximation(V, targets)
  catch e
    if isa(e, ErrorException) && startswith(e.msg,"insufficient precision of fp")
      extra = extra + 5
      @goto more_precision
    else
      rethrow(e)
    end
  end

  L1f = lattice(V, basis_matrix(L1) * f, check=false)
  indexL1f_M1 = index(M1, intersect(L1f, M1))
  # confirm computation
  for p in bad
    v = valuation(indexL1f_M1, p)
    @assert v == 0 "$p: $v"
  end
  return f, indexL1f_M1
end

@doc raw"""
    index(L::ZZLat, M::ZZLat) -> IntExt

Return the index $[L:M]=|L/M|$ of $M$ in $L$.
"""
function index(L::ZZLat, M::ZZLat)
  b, M = is_sublattice_with_relations(L, M)
  b || error("M must be a sublattice of L to have a well defined index [L:M]")
  if rank(L)>rank(M)
    return inf
  end
  return abs(det(M))
end

function _norm_generator(gram_normal, p)
  # the norm generator is the last diagonal entry of the first jordan block.
  # except if the last 2x2 block is a hyperbolic plane
  R = residue_ring(ZZ, p)
  n = ncols(gram_normal)
  gram_normal = change_base_ring(ZZ, gram_normal)
  gram_modp = change_base_ring(R, gram_normal)
  ind,vals = _block_indices_vals(gram_modp, p)
  @assert vals[1]==0
  if length(ind)==1
    i = nrows(gram_normal)
  else
    i = ind[2]-1
  end
  E = identity_matrix(QQ, n)
  q = gram_normal[i,i]
  if q!=0 && valuation(q, p) <= 1
    return E[i,:]
  end
  @assert p==2
  return E[i,:] + E[i-1,:]
end

################################################################################
#
# The 23 holy constructions of the Leech lattice
#
################################################################################

@doc raw"""
    coxeter_number(ADE::Symbol, n) -> Int

Return the Coxeter number of the corresponding ADE root lattice.

If ``L`` is a root lattice and ``R`` its set of roots, then the Coxeter number ``h``
is ``|R|/n`` where `n` is the rank of ``L``.

# Examples
```jldoctest
julia> coxeter_number(:D, 4)
6

```
"""
function coxeter_number(ADE::Symbol, n)
  if ADE == :A
    return n+1
  elseif ADE == :D
    return 2*(n-1)
  elseif ADE == :E && n == 6
    return 12
  elseif ADE == :E && n == 7
    return 18
  elseif ADE == :E && n == 8
    return 30
  end
end

@doc raw"""
    highest_root(ADE::Symbol, n) -> ZZMatrix

Return coordinates of the highest root of `root_lattice(ADE, n)`.

# Examples
```jldoctest
julia> highest_root(:E, 6)
[1   2   3   2   1   2]
```
"""
function highest_root(ADE::Symbol, n)
  if ADE == :A
    w = [1 for i in 1:n]
  elseif ADE == :D
    w = vcat([1,1],[2 for i in 3:n-1])
    w = vcat(w,[1])
  elseif ADE == :E && n == 6
    w = [1,2,3,2,1,2]
  elseif ADE == :E && n == 7
    w = [2,3,4,3,2,1,2]
  elseif ADE == :E && n == 8
    w = [2,4,6,5,4,3,2,3]
  end
  w = matrix(ZZ, 1, n, w)
  g = gram_matrix(root_lattice(ADE,n))
  @hassert :Lattice 2 all(0<=i for i in collect(w*g))
  @hassert :Lattice 2 (w*g*transpose(w))[1,1]==2
  return w
end

function _weyl_vector(R::ZZLat)
  weyl = matrix(ZZ,1,rank(R),ones(1,rank(R)))*inv(gram_matrix(R))
  return weyl*basis_matrix(R)
end

@doc raw"""
    leech_lattice() -> ZZLat

Return the Leech lattice.
"""
function leech_lattice()
  R = integer_lattice(gram=2*identity_matrix(ZZ,24))
  N = maximal_even_lattice(R) # niemeier lattice
  return leech_lattice(N)[1]
end

@doc raw"""
    leech_lattice(niemeier_lattice::ZZLat) -> ZZLat, QQMatrix, Int

Return a triple `L, v, h` where `L` is the Leech lattice.

L is an `h`-neighbor of the Niemeier lattice `N` with respect to `v`.
This means that `L / L ∩ N  ≅ ℤ / h ℤ`.
Here `h` is the Coxeter number of the Niemeier lattice.

This implements the 23 holy constructions of the Leech lattice in [CS99](@cite).

# Examples
```jldoctest leech
julia> R = integer_lattice(gram=2 * identity_matrix(ZZ, 24));

julia> N = maximal_even_lattice(R) # Some Niemeier lattice
Integer lattice of rank 24 and degree 24
with gram matrix
[2   1   1   1   0   0   0   0   0   0   0   0   0   0   0   0   1   0   1   1   0   0   0   0]
[1   2   1   1   0   0   0   0   0   0   0   0   0   0   0   0   1   1   0   1   0   0   0   0]
[1   1   2   1   0   0   0   0   0   0   0   0   0   0   0   0   1   1   1   0   0   0   0   0]
[1   1   1   2   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0]
[0   0   0   0   2   1   1   1   0   0   0   0   1   0   1   1   0   0   0   0   0   0   0   0]
[0   0   0   0   1   2   1   1   0   0   0   0   1   1   0   1   0   0   0   0   0   0   0   0]
[0   0   0   0   1   1   2   1   0   0   0   0   1   1   1   0   0   0   0   0   0   0   0   0]
[0   0   0   0   1   1   1   2   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0]
[0   0   0   0   0   0   0   0   2   1   1   1   0   0   0   0   0   0   0   0   1   1   1   0]
[0   0   0   0   0   0   0   0   1   2   1   1   0   0   0   0   0   0   0   0   1   0   1   1]
[0   0   0   0   0   0   0   0   1   1   2   1   0   0   0   0   0   0   0   0   1   1   0   1]
[0   0   0   0   0   0   0   0   1   1   1   2   0   0   0   0   0   0   0   0   0   0   0   0]
[0   0   0   0   1   1   1   0   0   0   0   0   2   1   1   1   0   0   0   0   0   0   0   0]
[0   0   0   0   0   1   1   0   0   0   0   0   1   2   0   0   0   0   0   0   0   0   0   0]
[0   0   0   0   1   0   1   0   0   0   0   0   1   0   2   0   0   0   0   0   0   0   0   0]
[0   0   0   0   1   1   0   0   0   0   0   0   1   0   0   2   0   0   0   0   0   0   0   0]
[1   1   1   0   0   0   0   0   0   0   0   0   0   0   0   0   2   1   1   1   0   0   0   0]
[0   1   1   0   0   0   0   0   0   0   0   0   0   0   0   0   1   2   0   0   0   0   0   0]
[1   0   1   0   0   0   0   0   0   0   0   0   0   0   0   0   1   0   2   0   0   0   0   0]
[1   1   0   0   0   0   0   0   0   0   0   0   0   0   0   0   1   0   0   2   0   0   0   0]
[0   0   0   0   0   0   0   0   1   1   1   0   0   0   0   0   0   0   0   0   2   1   1   1]
[0   0   0   0   0   0   0   0   1   0   1   0   0   0   0   0   0   0   0   0   1   2   0   0]
[0   0   0   0   0   0   0   0   1   1   0   0   0   0   0   0   0   0   0   0   1   0   2   0]
[0   0   0   0   0   0   0   0   0   1   1   0   0   0   0   0   0   0   0   0   1   0   0   2]

julia> minimum(N)
2

julia> det(N)
1

julia> L, v, h = leech_lattice(N);

julia> minimum(L)
4

julia> det(L)
1

julia> h == index(L, intersect(L, N))
true

```

We illustrate how the Leech lattice is constructed from `N`, `h` and `v`.

```jldoctest leech
julia> Zmodh = residue_ring(ZZ, h);

julia> V = ambient_space(N);

julia> vG = map_entries(x->Zmodh(ZZ(x)), inner_product(V, v, basis_matrix(N)));

julia> LN = transpose(lift(kernel(vG)[2]))*basis_matrix(N); # vectors whose inner product with `v` is divisible by `h`.

julia> lattice(V, LN) == intersect(L, N)
true

julia> gensL = vcat(LN, 1//h * v);

julia> lattice(V, gensL, isbasis=false) == L
true

```
"""
function leech_lattice(niemeier_lattice::ZZLat)
  # construct the leech lattice from one of the 23 holy constructions in SPLAG
  # we follow a mix of Ebeling and SPLAG
  # there seem to be some signs wrong in Ebeling?
  N = niemeier_lattice
  @req rank(N)==24 && norm(N)==2 && scale(N)==1 && det(N)==1 && is_definite(N) "not a Niemeier lattice"
  # figure out which Niemeier lattice it is
  V = ambient_space(N)
  ADE, ade, RR = root_lattice_recognition_fundamental(N)
  rank(ADE)==24 || error("not a niemeier lattice")
  F = basis_matrix(ADE)
  for i in 1:length(ade)
    F = vcat(F, -highest_root(ade[i]...) * basis_matrix(RR[i]))
  end
  rho = sum(_weyl_vector(r) for r in RR)
  h = coxeter_number(ade[1]...)
  # sanity checks
  @hassert :Lattice 1 inner_product(V, rho, rho) == 2 * h * (h+1)
  @hassert :Lattice 1 all(h == coxeter_number(i...) for i in ade)
  rhoB = solve_left(basis_matrix(N), rho)
  v = QQ(1, h) * transpose(rhoB)
  A = integer_lattice(gram=gram_matrix(N))
  c = QQ(2 + 2//h)
  vv = vec(collect(v))
  sv = [matrix(QQ, 1, 24, vv - i)*basis_matrix(N) for (i, _) in Hecke.close_vectors(A, vv, c, c, check=false)]
  @hassert :Lattice 1 all(inner_product(V, i, i)==(2 + 2//h) for i in sv)
  @hassert :Lattice 1 length(sv)^2 == abs(det(ADE))
  G = reduce(vcat, sv)
  FG = vcat(F, G)
  K = transpose(kernel(matrix(ZZ, ones(Int, 1, nrows(FG))))[2])
  B = change_base_ring(QQ, K) * FG
  B = hnf(FakeFmpqMat(B))
  B = QQ(1, B.den) * change_base_ring(QQ, B.num[end-23:end, :])
  leech_lattice = lattice(V, B)
  leech_lattice = lll(leech_lattice) # make it a bit prettier
  # confirm computation
  @hassert :Lattice 1 rank(B)==24
  @hassert :Lattice 1 scale(leech_lattice)==1 && norm(leech_lattice)==2
  @hassert :Lattice 1 det(leech_lattice)==1
  @hassert :Lattice 1 minimum(leech_lattice)==4

  # figure out the glue vector
  T = torsion_quadratic_module(leech_lattice, intersect(leech_lattice, N))
  @assert length(gens(T))==1 "something is wrong"
  w = transpose(matrix(lift(gens(T)[1])))

  return leech_lattice, h*w, h
end

