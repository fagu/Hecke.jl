export splitting_field, is_subfield, is_defining_polynomial_nice,
       quadratic_field, is_linearly_disjoint, rationals_as_number_field

################################################################################
#
#  Order type
#
################################################################################

order_type(::AnticNumberField) = NfAbsOrd{AnticNumberField, nf_elem}

order_type(::Type{AnticNumberField}) = NfAbsOrd{AnticNumberField, nf_elem}

################################################################################
#
#  Predicates
#
################################################################################

is_simple(::Type{AnticNumberField}) = true

is_simple(::AnticNumberField) = true

################################################################################
#
#  Field constructions
#
################################################################################

@doc raw"""
    number_field(S::Generic.ResidueRing{QQPolyRingElem}; cached::Bool = true, check::Bool = true) -> AnticNumberField, Map

 The number field $K$ isomorphic to the ring $S$ and the map from $K\to S$.
"""
function number_field(S::Generic.ResidueRing{QQPolyRingElem}; cached::Bool = true, check::Bool = true)
  Qx = parent(modulus(S))
  K, a = number_field(modulus(S), "_a", cached = cached, check = check)
  mp = MapFromFunc(K, S, y -> S(Qx(y)), x -> K(lift(x)))
  return K, mp
end

function number_field(f::ZZPolyRingElem, s::Symbol; cached::Bool = true, check::Bool = true)
  Qx = Globals.Qx
  return number_field(Qx(f), String(s), cached = cached, check = check)
end

function number_field(f::ZZPolyRingElem, s::AbstractString; cached::Bool = true, check::Bool = true)
  Qx = Globals.Qx
  return number_field(Qx(f), s, cached = cached, check = check)
end

function number_field(f::ZZPolyRingElem; cached::Bool = true, check::Bool = true)
  Qx = Globals.Qx
  return number_field(Qx(f), cached = cached, check = check)
end

function radical_extension(n::Int, gen::Integer; cached::Bool = true, check::Bool = true)
  return radical_extension(n, ZZRingElem(gen), cached = cached, check = check)
end

function radical_extension(n::Int, gen::ZZRingElem; cached::Bool = true, check::Bool = true)
  x = Hecke.gen(Globals.Qx)
  return number_field(x^n - gen, cached = cached, check = check)
end

# TODO: Some sort of reference?
@doc doc"""
    wildanger_field(n::Int, B::ZZRingElem) -> AnticNumberField, nf_elem

Returns the field with defining polynomial $x^n + \sum_{i=0}^{n-1} (-1)^{n-i}Bx^i$.
These fields tend to have non-trivial class groups.

# Examples

```jldoctest
julia> wildanger_field(3, ZZ(10), "a")
(Number field of degree 3 over QQ, a)
```
"""
function wildanger_field(n::Int, B::ZZRingElem, s::String = "_\$"; check::Bool = true, cached::Bool = true)
  x = gen(Globals.Qx)
  f = x^n
  for i=0:n-1
    f += (-1)^(n-i)*B*x^i
  end
  return number_field(f, s, cached = cached, check = check)
end

function wildanger_field(n::Int, B::Integer, s::String = "_\$"; cached::Bool = true, check::Bool = true)
  return wildanger_field(n, ZZRingElem(B), s, cached = cached, check = check)
end

@doc raw"""
    quadratic_field(d::IntegerUnion) -> AnticNumberField, nf_elem

Returns the field with defining polynomial $x^2 - d$.

# Examples

```jldoctest
julia> quadratic_field(5)
(Real quadratic field defined by x^2 - 5, sqrt(5))
```
"""
function quadratic_field(d::IntegerUnion; cached::Bool = true, check::Bool = true)
end

function quadratic_field(d::ZZRingElem; cached::Bool = true, check::Bool = true)
  x = gen(Globals.Qx)
  if nbits(d) > 100
    a = div(d, ZZRingElem(10)^(ndigits(d, 10) - 4))
    b = mod(abs(d), 10^4)
    s = "sqrt($a..($(nbits(d)) bits)..$b)"
  else
    s = "sqrt($d)"
  end
  q, a = number_field(x^2-d, s, cached = cached, check = check)
  set_attribute!(q, :show => show_quad)
  return q, a
end

function show_quad(io::IO, q::AnticNumberField)
  d = trailing_coefficient(q.pol)
  if d < 0
    print(io, "Real quadratic field defined by ", q.pol)
  else
    print(io, "Imaginary quadratic field defined by ", q.pol)
  end
end

function quadratic_field(d::Integer; cached::Bool = true, check::Bool = true)
  return quadratic_field(ZZRingElem(d), cached = cached, check = check)
end

@doc doc"""
    rationals_as_number_field() -> AnticNumberField, nf_elem

Returns the rational numbers as the number field defined by $x - 1$.

# Examples

```jldoctest
julia> rationals_as_number_field()
(Number field of degree 1 over QQ, 1)
```
"""
function rationals_as_number_field()
  x = gen(Globals.Qx)
  return number_field(x-1)
end

################################################################################
#
#  Predicates
#
################################################################################

@doc raw"""
    is_defining_polynomial_nice(K::AnticNumberField)

Tests if the defining polynomial of $K$ is integral and monic.
"""
function is_defining_polynomial_nice(K::AnticNumberField)
  return Bool(K.flag & UInt(1))
end

function is_defining_polynomial_nice(K::NfAbsNS)
  pols = K.pol
  for i = 1:length(pols)
    d = denominator(pols[i])
    if !isone(d)
      return false
    end
    if !isone(leading_coefficient(pols[i]))
      return false
    end
  end
  return true
end

################################################################################
#
#  Class group
#
################################################################################

@doc raw"""
    class_group(K::AnticNumberField) -> GrpAbFinGen, Map

Shortcut for `class_group(maximal_order(K))`: returns the class
group as an abelian group and a map from this group to the set
of ideals of the maximal order.
"""
function class_group(K::AnticNumberField)
  return class_group(maximal_order(K))
end

################################################################################
#
#  Class number
#
################################################################################

@doc raw"""
    class_number(K::AnticNumberField) -> ZZRingElem

Returns the class number of $K$.
"""
function class_number(K::AnticNumberField)
  return order(class_group(maximal_order(K))[1])
end

################################################################################
#
#  Relative class number
#
################################################################################

@doc raw"""
    relative_class_number(K::AnticNumberField) -> ZZRingElem

Returns the relative class number of $K$. The field must be a CM-field.
"""
function relative_class_number(K::AnticNumberField)
  if degree(K) == 2
    @req is_totally_complex(K) "Field must be a CM-field"
    return class_number(K)
  end

  fl, c = is_cm_field(K)
  @req fl "Field must be a CM-field"
  h = class_number(K)
  L, _ = fixed_field(K, c)
  hp = class_number(L)
  @assert mod(h, hp) == 0
  return divexact(h, hp)
end


################################################################################
#
#  Torsion units and related functions
#
################################################################################

@doc raw"""
    is_torsion_unit(x::nf_elem, checkisunit::Bool = false) -> Bool

Returns whether $x$ is a torsion unit, that is, whether there exists $n$ such
that $x^n = 1$.

If `checkisunit` is `true`, it is first checked whether $x$ is a unit of the
maximal order of the number field $x$ is lying in.
"""
function is_torsion_unit(x::nf_elem, checkisunit::Bool = false)
  if checkisunit
    _isunit(x) ? nothing : return false
  end

  K = parent(x)
  d = degree(K)
  c = conjugate_data_arb(K)
  r, s = signature(K)

  while true
    @vprintln :UnitGroup 2 "Precision is now $(c.prec)"
    l = 0
    @vprintln :UnitGroup 2 "Computing conjugates ..."
    cx = conjugates_arb(x, c.prec)
    A = ArbField(c.prec, cached = false)
    for i in 1:r
      k = abs(cx[i])
      if k > A(1)
        return false
      elseif is_nonnegative(A(1) + A(1)//A(6) * log(A(d))//A(d^2) - k)
        l = l + 1
      end
    end
    for i in 1:s
      k = abs(cx[r + i])
      if k > A(1)
        return false
      elseif is_nonnegative(A(1) + A(1)//A(6) * log(A(d))//A(d^2) - k)
        l = l + 1
      end
    end

    if l == r + s
      return true
    end
    refine(c)
  end
end

@doc raw"""
    torsion_unit_order(x::nf_elem, n::Int)

Given a torsion unit $x$ together with a multiple $n$ of its order, compute
the order of $x$, that is, the smallest $k \in \mathbb Z_{\geq 1}$ such
that $x^k = 1$.

It is not checked whether $x$ is a torsion unit.
"""
function torsion_unit_order(x::nf_elem, n::Int)
  ord = 1
  fac = factor(n)
  for (p, v) in fac
    p1 = Int(p)
    s = x^divexact(n, p1^v)
    if isone(s)
      continue
    end
    cnt = 0
    while !isone(s) && cnt < v+1
      s = s^p1
      ord *= p1
      cnt += 1
    end
    if cnt > v+1
      error("The element is not a torsion unit")
    end
  end
  return ord
end

#################################################################################################
#
#  Normal Basis
#
#################################################################################################

function normal_basis(K::AnticNumberField)
  # First try basis elements of LLL basis
  # or rather not
  # n = degree(K)
  # Aut = automorphism_list(K)

  # length(Aut) != n && error("The field is not normal over the rationals!")

  # A = zero_matrix(FlintQQ, n, n)
  # _B = basis(lll(maximal_order(K)))
  # for i in 1:n
  #   r = elem_in_nf(_B[i])
  #   for i = 1:n
  #     y = Aut[i](r)
  #     for j = 1:n
  #       A[i,j] = coeff(y, j - 1)
  #     end
  #   end
  #   if rank(A) == n
  #     return r
  #   end
  # end

  O = EquationOrder(K)
  Qx = parent(K.pol)
  d = discriminant(O)
  p = 1
  for q in PrimesSet(degree(K), -1)
    if divisible(d, q)
      continue
    end
    #Now, I check if p is totally split
    R = GF(q, cached = false)
    Rt, t = polynomial_ring(R, "t", cached = false)
    ft = Rt(K.pol)
    pt = powermod(t, q, ft)
    if degree(gcd(ft, pt-t)) == degree(ft)
      p = q
      break
    end
  end

  return _normal_basis_generator(K, p)
end

function _normal_basis_generator(K, p)
  Qx = parent(K.pol)

  #Now, I only need to lift an idempotent of O/pO
  R = GF(p, cached = false)
  Rx, x = polynomial_ring(R, "x", cached = false)
  f = Rx(K.pol)
  fac = factor(f)
  g = divexact(f, first(keys(fac.fac)))
  Zy, y = polynomial_ring(FlintZZ, "y", cached = false)
  g1 = lift(Zy, g)
  return K(g1)
end

################################################################################
#
#  Subfield check
#
################################################################################

function _issubfield(K::AnticNumberField, L::AnticNumberField)
  f = K.pol
  R = roots(L, f, max_roots = 1)
  if isempty(R)
    return false, L()
  else
    h = parent(L.pol)(R[1])
    return true, h(gen(L))
  end
end

function _issubfield_first_checks(K::AnticNumberField, L::AnticNumberField)
  f = K.pol
  g = L.pol
  if mod(degree(g), degree(f)) != 0
    return false
  end
  t = divexact(degree(g), degree(f))
  if is_maximal_order_known(K) && is_maximal_order_known(L)
    OK = maximal_order(K)
    OL = maximal_order(L)
    if mod(discriminant(OL), discriminant(OK)^t) != 0
      return false
    end
  end
  # We could factorize the discriminant of f, but we only test small primes.
  cnt_threshold = 10*degree(K)
  p = 3
  cnt = 0
  while cnt < cnt_threshold
    F = GF(p, cached = false)
    Fx = polynomial_ring(F, "x", cached = false)[1]
    fp = Fx(f)
    gp = Fx(g)
    if !is_squarefree(fp) || !is_squarefree(gp)
      p = next_prime(p)
	    continue
    end
    cnt += 1
    fs = factor_shape(fp)
    gs = factor_shape(gp)
    if !divisible(lcm(collect(keys(gs))), lcm(collect(keys(fs))))
      return false
    end
    p = next_prime(p)
  end
  return true
end

function is_subfield(K::AnticNumberField, L::AnticNumberField)
  fl = _issubfield_first_checks(K, L)
  if !fl
    return false, hom(K, L, zero(L), check = false)
  end
  b, prim_img = _issubfield(K, L)
  return b, hom(K, L, prim_img, check = false)
end

function _issubfield_normal(K::AnticNumberField, L::AnticNumberField)
  f = K.pol
  f1 = change_base_ring(L, f)
  r = roots(f1, max_roots = 1, is_normal = true)
  if length(r) > 0
    h = parent(L.pol)(r[1])
    return true, h(gen(L))
  else
    return false, L()
  end
end

@doc raw"""
      is_subfield_normal(K::AnticNumberField, L::AnticNumberField) -> Bool, NfToNfMor

Returns `true` and an injection from $K$ to $L$ if $K$ is a subfield of $L$.
Otherwise the function returns "false" and a morphism mapping everything to 0.

This function assumes that $K$ is normal.
"""
function is_subfield_normal(K::AnticNumberField, L::AnticNumberField)
  fl = _issubfield_first_checks(K, L)
  if !fl
    return false, hom(K, L, zero(L), check = false)
  end
  b, prim_img = _issubfield_normal(K, L)
  return b, hom(K, L, prim_img, check = false)

end

################################################################################
#
#  Isomorphism
#
################################################################################

@doc raw"""
    is_isomorphic_with_map(K::AnticNumberField, L::AnticNumberField) -> Bool, NfToNfMor

Return `true` and an isomorphism from $K$ to $L$ if $K$ and $L$ are isomorphic.
Otherwise the function returns "false" and a morphism mapping everything to 0.
"""
function is_isomorphic_with_map(K::AnticNumberField, L::AnticNumberField)
  f = K.pol
  g = L.pol
  if degree(f) != degree(g)
    return false, hom(K, L, zero(L), check = false)
  end
  if QQFieldElem[coeff(f, i) for i = 0:degree(f)] == QQFieldElem[coeff(g, i) for i = 0:degree(g)]
    return true, hom(K, L, gen(L))
  end
  if signature(K) != signature(L)
    return false, hom(K, L, zero(L), check = false)
  end
  if is_maximal_order_known(K) && is_maximal_order_known(L)
    OK = maximal_order(K)
    OL = maximal_order(L)
    if discriminant(OK) != discriminant(OL)
      return false, hom(K, L, zero(L), check = false)
    end
  else
    t = discriminant(f)//discriminant(g)
    if !is_square(numerator(t)) || !is_square(denominator(t))
      return false, hom(K, L, zero(L), check = false)
    end
  end
  p = 10^5
  cnt = 0
  df = denominator(f)
  dg = denominator(g)
  while cnt < max(20, 2*degree(K))
    p = next_prime(p)
    if divisible(df, p) || divisible(dg, p)
      continue
    end
    F = GF(p, cached = false)
    Fx = polynomial_ring(F, "x", cached = false)[1]
    fp = Fx(f)
    if degree(fp) != degree(f) || !is_squarefree(fp)
      continue
    end
    gp = Fx(g)
    if degree(gp) != degree(g) || !is_squarefree(gp)
      continue
    end
    cnt += 1
    lf = factor_shape(fp)
    lg = factor_shape(gp)
    if lf != lg
      return false, hom(K, L, zero(L), check = false)
    end
  end
  b, prim_img = _issubfield(K, L)
  if !b
    return b, hom(K, L, zero(L), check = false)
  else
    return b, hom(K, L, prim_img, check = false)
  end
end

################################################################################
#
#  Compositum
#
################################################################################

@doc raw"""
    compositum(K::AnticNumberField, L::AnticNumberField) -> AnticNumberField, Map, Map

Assuming $L$ is normal (which is not checked), compute the compositum $C$ of the
2 fields together with the embedding of $K \to C$ and $L \to C$.
"""
function compositum(K::AnticNumberField, L::AnticNumberField)
  lf = factor(L, K.pol)
  d = degree(first(lf.fac)[1])
  if any(x->degree(x) != d, keys(lf.fac))
    error("2nd field cannot be normal")
  end
  KK = number_field(first(lf.fac)[1])[1]
  Ka, mKa = absolute_simple_field(KK)
  mK = hom(K, Ka, mKa\gen(KK))
  mL = hom(L, Ka, mKa\(KK(gen(L))))
  embed(mK)
  embed(mL)
  return Ka, mK, mL
end

################################################################################
#
#  Serialization
#
################################################################################

# This function can be improved by directly accessing the numerator
# of the QQPolyRingElem representing the nf_elem
@doc raw"""
    write(io::IO, A::Vector{nf_elem}) -> Nothing

Writes the elements of `A` to `io`. The first line are the coefficients of
the defining polynomial of the ambient number field. The following lines
contain the coefficients of the elements of `A` with respect to the power
basis of the ambient number field.
"""
function write(io::IO, A::Vector{nf_elem})
  if length(A) == 0
    return
  else
    # print some useful(?) information
    print(io, "# File created by Hecke $VERSION_NUMBER, $(Base.Dates.now()), by function 'write'\n")
    K = parent(A[1])
    polring = parent(K.pol)

    # print the defining polynomial
    g = K.pol
    d = denominator(g)

    for j in 0:degree(g)
      print(io, coeff(g, j)*d)
      print(io, " ")
    end
    print(io, d)
    print(io, "\n")

    # print the elements
    for i in 1:length(A)

      f = polring(A[i])
      d = denominator(f)

      for j in 0:degree(K)-1
        print(io, coeff(f, j)*d)
        print(io, " ")
      end

      print(io, d)

      print(io, "\n")
    end
  end
end

@doc raw"""
    write(file::String, A::Vector{nf_elem}, flag::ASCIString = "w") -> Nothing

Writes the elements of `A` to the file `file`. The first line are the coefficients of
the defining polynomial of the ambient number field. The following lines
contain the coefficients of the elements of `A` with respect to the power
basis of the ambient number field.

Unless otherwise specified by the parameter `flag`, the content of `file` will be
overwritten.
"""
function write(file::String, A::Vector{nf_elem}, flag::String = "w")
  f = open(file, flag)
  write(f, A)
  close(f)
end

# This function has a bad memory footprint
@doc raw"""
    read(io::IO, K::AnticNumberField, ::Type{nf_elem}) -> Vector{nf_elem}

Given a file with content adhering the format of the `write` procedure,
this function returns the corresponding object of type `Vector{nf_elem}` such that
all elements have parent $K$.

**Example**

    julia> Qx, x = FlintQQ["x"]
    julia> K, a = number_field(x^3 + 2, "a")
    julia> write("interesting_elements", [1, a, a^2])
    julia> A = read("interesting_elements", K, Hecke.nf_elem)
"""
function read(io::IO, K::AnticNumberField, ::Type{Hecke.nf_elem})
  Qx = parent(K.pol)

  A = Vector{nf_elem}()

  i = 1

  for ln in eachline(io)
    if ln[1] == '#'
      continue
    elseif i == 1
      # the first line read should contain the number field and will be ignored
      i = i + 1
    else
      coe = map(Hecke.ZZRingElem, split(ln, " "))
      t = ZZPolyRingElem(Array(slice(coe, 1:(length(coe) - 1))))
      t = Qx(t)
      t = divexact(t, coe[end])
      push!(A, K(t))
      i = i + 1
    end
  end

  return A
end

@doc raw"""
    read(file::String, K::AnticNumberField, ::Type{nf_elem}) -> Vector{nf_elem}

Given a file with content adhering the format of the `write` procedure,
this function returns the corresponding object of type `Vector{nf_elem}` such that
all elements have parent $K$.

**Example**

    julia> Qx, x = FlintQQ["x"]
    julia> K, a = number_field(x^3 + 2, "a")
    julia> write("interesting_elements", [1, a, a^2])
    julia> A = read("interesting_elements", K, Hecke.nf_elem)
"""
function read(file::String, K::AnticNumberField, ::Type{Hecke.nf_elem})
  f = open(file, "r")
  A = read(f, K, Hecke.nf_elem)
  close(f)
  return A
end

#TODO: get a more intelligent implementation!!!
@doc raw"""
    splitting_field(f::ZZPolyRingElem) -> AnticNumberField
    splitting_field(f::QQPolyRingElem) -> AnticNumberField

Computes the splitting field of $f$ as an absolute field.
"""
function splitting_field(f::ZZPolyRingElem; do_roots::Bool = false)
  Qx = polynomial_ring(FlintQQ, parent(f).S, cached = false)[1]
  return splitting_field(Qx(f), do_roots = do_roots)
end

function splitting_field(f::QQPolyRingElem; do_roots::Bool = false)
  return splitting_field([f], do_roots = do_roots)
end

function splitting_field(fl::Vector{ZZPolyRingElem}; coprime::Bool = false, do_roots::Bool = false)
  Qx = polynomial_ring(FlintQQ, parent(fl[1]).S, cached = false)[1]
  return splitting_field([Qx(x) for x = fl], coprime = coprime, do_roots = do_roots)
end

function splitting_field(fl::Vector{QQPolyRingElem}; coprime::Bool = false, do_roots::Bool = false)
  if !coprime
    fl = coprime_base(fl)
  end
  ffl = QQPolyRingElem[]
  for x = fl
    append!(ffl, collect(keys(factor(x).fac)))
  end
  fl = ffl
  r = []
  if do_roots
    r = [roots(x)[1] for x = fl if degree(x) == 1]
  end
  fl = fl[findall(x->degree(x) > 1, fl)]
  if length(fl) == 0
    if do_roots
      return FlintQQ, r
    else
      return FlintQQ
    end
  end
  K, a = number_field(fl[1])#, check = false, cached = false)

  @assert fl[1](a) == 0
  gl = [change_base_ring(K, fl[1])]
  gl[1] = divexact(gl[1], gen(parent(gl[1])) - a)
  for i=2:length(fl)
    push!(gl, change_base_ring(K, fl[i]))
  end

  if do_roots
    K, R = _splitting_field(gl, coprime = true, do_roots = Val{true})
    return K, vcat(r, [K(a)], R)
  else
    return _splitting_field(gl, coprime = true, do_roots = Val{false})
  end
end

gcd_into!(a::QQPolyRingElem, b::QQPolyRingElem, c::QQPolyRingElem) = gcd(b, c)

@doc raw"""
    splitting_field(f::PolyRingElem{nf_elem}) -> AnticNumberField

Computes the splitting field of $f$ as an absolute field.
"""
splitting_field(f::PolyRingElem{nf_elem}; do_roots::Bool = false) = splitting_field([f], do_roots = do_roots)

function splitting_field(fl::Vector{<:PolyRingElem{nf_elem}}; do_roots::Bool = false, coprime::Bool = false)
  if !coprime
    fl = coprime_base(fl)
  end
  ffl = eltype(fl)[]
  for x = fl
    append!(ffl, collect(keys(factor(x).fac)))
  end
  fl = ffl
  r = []
  if do_roots
    r = [roots(x)[1] for x = fl if degree(x) == 1]
  end
  lg = [k for k = fl if degree(k) > 1]
  if length(lg) == 0
    if do_roots
      return base_ring(fl[1]), r
    else
      return base_ring(fl[1])
    end
  end

  K, a = number_field(lg[1], check = false, cached = false)
  ggl = [map_coefficients(K, lg[1])]
  ggl[1] = divexact(ggl[1], gen(parent(ggl[1])) - a)

  for i = 2:length(lg)
    push!(ggl, map_coefficients(K, lg[i]))
  end
  if do_roots
    R = [K(x) for x = r]
    push!(R, a)
    Kst, t = polynomial_ring(K, cached = false)
    return _splitting_field(vcat(ggl, [t-y for y in R]), coprime = true, do_roots = Val{true})
  else
    return _splitting_field(ggl, coprime = true, do_roots = Val{false})
  end
end


function _splitting_field(fl::Vector{<:PolyRingElem{<:NumFieldElem}}; do_roots::Type{Val{T}} = Val{false}, coprime::Bool = false) where T
  if !coprime
    fl = coprime_base(fl)
  end
  ffl = eltype(fl)[]
  for x = fl
    append!(ffl, collect(keys(factor(x).fac)))
  end
  fl = ffl
  K = base_ring(fl[1])
  r = elem_type(K)[]
  if do_roots == Val{true}
    r = elem_type(K)[roots(x)[1] for x = fl if degree(x) == 1]
  end
  lg = eltype(fl)[k for k = fl if degree(k) > 1]
  if iszero(length(lg))
    if do_roots == Val{true}
      return K, r
    else
      return K
    end
  end

  K, a = number_field(lg[1], check = false, cached = false)
  do_embedding = length(lg) > 1 || degree(K)>2 || (do_roots == Val{true})
  Ks, nk, mk = collapse_top_layer(K, do_embedding = do_embedding)
  if !do_embedding
    return Ks
  end


  ggl = [map_coefficients(mk, lg[1])]
  ggl[1] = divexact(ggl[1], gen(parent(ggl[1])) - preimage(nk, a))

  for i = 2:length(lg)
    push!(ggl, map_coefficients(mk, lg[i]))
  end
  if do_roots == Val{true}
    R = [mk(x) for x = r]
    push!(R, preimage(nk, a))
    Kst, t = polynomial_ring(Ks, cached = false)
    return _splitting_field(vcat(ggl, [t-y for y in R]), coprime = true, do_roots = Val{true})
  else
    return _splitting_field(ggl, coprime = true, do_roots = Val{false})
  end
end


@doc raw"""
    normal_closure(K::AnticNumberField) -> AnticNumberField, NfToNfMor

The normal closure of $K$ together with the embedding map.
"""
function normal_closure(K::AnticNumberField)
  s = splitting_field(K.pol)
  r = roots(s, K.pol)[1]
  return s, hom(K, s, r, check = false)
end

################################################################################
#
#  Is linearly disjoint
#
################################################################################

function is_linearly_disjoint(K1::AnticNumberField, K2::AnticNumberField)
  if gcd(degree(K1), degree(K2)) == 1
    return true
  end
  d1 = numerator(discriminant(K1.pol))
  d2 = numerator(discriminant(K2.pol))
  if gcd(d1, d2) == 1
    return true
  end
  if is_maximal_order_known(K1) && is_maximal_order_known(K2)
    OK1 = maximal_order(K1)
    OK2 = maximal_order(K2)
    if is_coprime(discriminant(K1), discriminant(K2))
      return true
    end
  end
  f = change_base_ring(K2, K1.pol)
  return is_irreducible(f)
end

################################################################################
#
#  more general coercion, field lattice
#
################################################################################

function force_coerce(a::NumField{T}, b::NumFieldElem, throw_error::Type{Val{S}} = Val{true}) where {T, S}
  if Nemo.is_cyclo_type(a) && Nemo.is_cyclo_type(parent(b))
    return force_coerce_cyclo(a, b, throw_error)::elem_type(a)
  end
  if absolute_degree(parent(b)) <= absolute_degree(a)
    c = find_one_chain(parent(b), a)
    if c !== nothing
      x = b
      for f = c
        @assert parent(x) == domain(f)
        x = f(x)
      end
      return x::elem_type(a)
    end
  end
  if throw_error === Val{true}
    error("no coercion possible")
  else
    return false
  end
end

@noinline function force_coerce_throwing(a::NumField{T}, b::NumFieldElem) where {T}
  if absolute_degree(parent(b)) <= absolute_degree(a)
    c = find_one_chain(parent(b), a)
    if c !== nothing
      x = b
      for f = c
        @assert parent(x) == domain(f)
        x = f(x)
      end
      return x::elem_type(a)
    else
      error("no coercion possible")
    end
  else
    error("no coercion possible")
  end
end

#(large) fields have a list of embeddings from subfields stored (special -> subs)
#this traverses the lattice downwards collecting all chains of embeddings
function collect_all_chains(a::NumField, filter::Function = x->true)
  s = get_attribute(a, :subs)::Union{Nothing, Vector{Any}}
  s === nothing && return s
  all_chain = Dict{UInt, Array{Any}}(objectid(domain(f)) => [f] for f = s if filter(f))
  if isa(base_field(a), NumField)
    all_chain[objectid(base_field(a))] = [MapFromFunc(base_field(a), a, x->a(x))]
  end
  new_k = Any[domain(f) for f = s]
  while length(new_k) > 0
    k = pop!(new_k)
    s = get_attribute(k, :subs)::Union{Nothing, Vector{Any}}
    s === nothing && continue
    for f in s
      if filter(domain(f))
        o = objectid(domain(f))
        if haskey(all_chain, o)
          continue
        end
        @assert !haskey(all_chain, o)
        all_chain[o] = vcat([f], all_chain[objectid(codomain(f))])
        @assert !(o in new_k)
        push!(new_k, domain(f))
        if isa(base_field(domain(f)), NumField)
          b = base_field(domain(f))
          ob = objectid(b)
          if !haskey(all_chain, ob)
            g = MapFromFunc(b, domain(f), x->domain(f)(x))
            all_chain[ob] = vcat([g], all_chain[objectid(domain(f))])
            push!(new_k, b)
          end
        end
      end
    end
  end
  return all_chain
end

#tries to find one chain (array of embeddings) from a -> .. -> t
function find_one_chain(t::NumField, a::NumField)
  s = get_attribute(a, :subs)::Union{Nothing, Vector{Any}}
  s === nothing && return s
  ot = objectid(t)
  all_chain = Dict{UInt, Array{Any}}(objectid(domain(f)) => [f] for f = s)
  if isa(base_field(a), NumField)
    all_chain[objectid(base_field(a))] = [MapFromFunc(base_field(a), a, x->a(x))]
  end
  new_k = Any[domain(f) for f = s]
  if haskey(all_chain, ot)
    return all_chain[ot]
  end
  new_k = Any[domain(f) for f = s]
  while length(new_k) > 0
    k = pop!(new_k)
    s = get_attribute(k, :subs)::Union{Nothing, Vector{Any}}
    s === nothing && continue
    for f in s
      o = objectid(domain(f))
      if o == ot
        return vcat([f], all_chain[objectid(codomain(f))])
      end
      if o in keys(all_chain)
        continue
      end
      @assert !haskey(all_chain, o)
      all_chain[o] = vcat([f], all_chain[objectid(codomain(f))])
      @assert !(o in new_k)
      push!(new_k, domain(f))
      if isa(base_field(domain(f)), NumField)
        b = base_field(domain(f))
        ob = objectid(b)
        if !haskey(all_chain, ob)
          g = MapFromFunc(b, domain(f), x->domain(f)(x))
          all_chain[ob] = vcat([g], all_chain[objectid(domain(f))])
          push!(new_k, b)
        end
        if ob == ot
          return all_chain[ob]
        end
      end
    end
  end
  return nothing
end

@doc raw"""
    embed(f::Map{<:NumField, <:NumField})

Registers `f` as a canonical embedding from the domain into the co-domain.
Once this embedding is registered, it cannot be changed.
"""
function embed(f::Map{<:NumField, <:NumField})
  d = domain(f)
  c = codomain(f)
  if c == d
    return
  end
  @assert absolute_degree(d) <= absolute_degree(c)
  cn = find_one_chain(d, c)
  if cn !== nothing
    if is_simple(d)
      cgend = force_coerce(c, gen(d))
      if cgend != f(gen(d))
        error("different embedding already installed")
        return
      end
    else
      if any(x->c(x) != f(x), gens(d))
        error("different embedding already installed")
      end
    end
  end
  s = get_attribute!(c, :subs, [])::Vector{Any}
  push!(s, f)
  s = get_attribute!(c, :sub_of, WeakRef[])::Vector{WeakRef}
  push!(s, WeakRef(c))
end

@doc raw"""
    has_embedding(F::NumField, G::NumField) -> Bool

Checks if an embedding from $F$ into $G$ is already known.
"""
function has_embedding(F::NumField, G::NumField)
  if F == G
    return true
  end
  if absolute_degree(G) % absolute_degree(F) != 0
    return false
  end
  cn = find_one_chain(d, c)
  return cn !== nothing
end

#in (small) fields, super fields are stored via WeakRef's
# special -> :sub_of
#this find all superfields registered
function find_all_super(A::NumField, filter::Function = x->true)
  s = get_attribute(A, :sub_of)::Union{Nothing, Vector{WeakRef}}
  s === nothing && return Set([A])

  # Remove dead weak refs (since we edit s in-place, this
  # automatically updates the :sub_of attribute of A, too.
  filter!(x->x.value !== nothing, s)

  #the gc could(?) run anytime, so even after the pruning above
  #things could get deleted

  all_s = Set([x.value for x = s if x.value !== nothing && filter(x.value)])
  new_s = copy(all_s)
  while length(new_s) > 0
    B = pop!(new_s)
    s = get_attribute(B, :sub_of)::Union{Nothing, Vector{WeakRef}}
    s === nothing && continue
    filter!(x->x.value !== nothing, s)
    for x in s
      v = x.value
      if v !== nothing && filter(v)
        push!(new_s, v)
        push!(all_s, v)
      end
    end
  end
  return all_s
end

#finds a common super field for A and B, using the weak-refs
# in special -> :sub_of
function common_super(A::NumField, B::NumField)
  A === B && return A
  if Nemo.is_cyclo_type(A) && Nemo.is_cyclo_type(B)
    fa = get_attribute(A, :cyclo)::Int
    fb = get_attribute(B, :cyclo)::Int
    return cyclotomic_field(lcm(fa, fb))[1]
  end

  c = intersect(find_all_super(A), find_all_super(B))
  first = true
  m = nothing
  for C = c
    if first
      m = C
      first = false
    else
      if absolute_degree(C) < absolute_degree(m)
        m = C
      end
    end
  end
  return m
end

function common_super(a::NumFieldElem, b::NumFieldElem)
  C = common_super(parent(a), parent(b))
  if C === nothing
    return C, C
  end
  return C(a), C(b)
end

#tries to find a common parent for all "a" and then calls op on it.
function force_op(op::T, throw_error::Type{Val{S}}, a::NumFieldElem...) where {T <: Function, S}
  C = parent(a[1])
  for b = a
    C = common_super(parent(b), C)
    if C === nothing
      if throw_error === Val{true}
        error("no common parent known")
      else
        return nothing
      end
    end
  end
  return op(map(C, a)...)
end

@doc raw"""
    embedding(k::NumField, K::NumField) -> Map

Assuming $k$ is known to be a subfield of $K$, return the embedding map.
"""
function embedding(k::NumField, K::NumField)
  if is_simple(k)
    return hom(k, K, K(gen(k)))
  else
    return hom(k, K, map(K, gens(k)))
  end
end

function force_coerce_cyclo(a::AnticNumberField, b::nf_elem, throw_error::Type{Val{T}} = Val{true}) where {T}
  if iszero(b)
    return a(0)
  end
#  Base.show_backtrace(stdout, backtrace())
  fa = get_attribute(a, :cyclo)::Int
  fb = get_attribute(parent(b), :cyclo)::Int

  if degree(parent(b)) == 2
    b_length = 2
  elseif degree(parent(b)) == 1
    b_length = 1
  else
    b_length = b.elem_length
  end

  # We want to write `b` as an element in `a`.
  # This is possible if and only if `b` can be written as an element
  # in the `fg`-th cyclotomic field, where `fg = gcd(fa, fb)`
  fg = gcd(fa, fb)
  if fg <= 2
    # the code below would not work
    if is_rational(b)
      return a(coeff(b, 0))
    elseif throw_error === Val{true}
      error("no coercion possible")
    else
      return
    end
  end

  ff = parent(parent(b).pol)(b)
  if fg < fb
    # first coerce down from fb to fg
    zb = gen(parent(b))
    q = divexact(fb, fg)
    za = zb^q

    cb = [i for i=1:fb if gcd(i, fb) == 1] # the "conjugates" in the large field
    cg = [[i for i = cb if i % fg == j] for j=1:fg if gcd(j, fg) == 1] #broken into blocks

    #in general one could test first if the evaluation is constant on a block
    #equivalently, if the element is Galois invariant under the fix group of a.
    #the result of the interpolation is supposed to be over Q, so we could
    #do this modulo deg-1-primes as well
    #using a fast(er) interpolation would be nice as well
    #but, this is avoiding matrices, so the complexity is better
    #
    #Idea
    # b is a poly in Qx, evaluating at gen(a)... will produce the conjugates
    # b in a is also a poly, of smaller degree producing the same conjugates
    # so I compute the conjugates from the large field and interpolate them to get
    # the small degree poly
    #actually, since we're using roots of one, we probably should use FFT techniques

    ex = [x[1] for x = cg]
    ky = polynomial_ring(parent(b), cached = false)[1]
    f = interpolate(ky, [(za)^(i) for i=ex],
                        [ff(zb^(i)) for i=ex])
    g = parent(ff)()
    for i=0:length(f)
      c = coeff(f, i)
      if !is_rational(c)
        if throw_error === Val{true}
          error("no coercion possible")
        else
          return
        end
      end
      setcoeff!(g, i, FlintQQ(c))
    end

    ff = g
  end

  # now ff is a polynomial for b w.r.t. the fg-th cyclotomic field
  if fg < fa
    # coerce up from fg to fa
    #so a = p(z) for p in Q(x) and z = gen(parent(b))
    q = divexact(fa, fg)
    c = parent(a.pol)()
    for i=0:degree(ff)
      setcoeff!(c, i*q, coeff(ff, i))
    end
    ff = c
  end

  # now ff is a polynomial for b w.r.t. the fa-th cyclotomic field
  return a(ff)
end