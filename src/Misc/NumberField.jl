import Nemo.AnticNumberField

################################################################################
#
# convenience ...
#
################################################################################

#CF: we have to "extend" AnticNumberField as NumberField is just defined by
#    NumberField = AnticNumberField in Nemo.
#    Possibly should be replaced by having optional 2nd arguments?

function AnticNumberField(f::fmpq_poly)
  return NumberField(f, "_a")
end

function AnticNumberField(f::fmpz_poly, s::Symbol)
  Qx, x = PolynomialRing(QQ, parent(f).S)
  return NumberField(Qx(f), s)
end

function AnticNumberField(f::fmpz_poly, s::AbstractString)
  Qx, x = PolynomialRing(QQ, parent(f).S)
  return NumberField(Qx(f), s)
end

function AnticNumberField(f::fmpz_poly)
  Qx, x = PolynomialRing(QQ, parent(f).S)
  return NumberField(Qx(f))
end

################################################################################
# given a basis (an array of elements), get a linear combination with
# random integral coefficients
################################################################################

function rand(b::Array{nf_elem,1}, r::UnitRange)
  length(b) == 0 && error("Array must not be empty")

  s = zero(b[1].parent)
  t = zero(b[1].parent)

  for i = 1:length(b)
    mul!(t, b[i], rand(r))
    add!(s, t, s)
  end
  return s
end

function rand!(c::nf_elem, b::Array{nf_elem,1}, r::UnitRange)
  length(b) == 0 && error("Array must not be empty")

  mul!(c, b[1], rand(r))
  t = zero(b[1].parent)

  for i = 2:length(b)
    mul!(t, b[i], rand(r))
    add!(c, t, c)
  end
  nothing
end

################################################################################
#
#  fmpq_poly with denominator 1 to fmpz_poly
#
################################################################################

function Base.call(a::FmpzPolyRing, b::fmpq_poly)
  (den(b) != 1) && error("denominator has to be 1")
  z = a()
  ccall((:fmpq_poly_get_numerator, :libflint), Void,
              (Ptr{fmpz_poly}, Ptr{fmpq_poly}), &z, &b)
  return z
end

function basis(K::AnticNumberField)
  n = degree(K)
  g = gen(K);
  d = Array(typeof(g), n)
  b = K(1)
  for i = 1:n-1
    d[i] = b
    b *= g
  end
  d[n] = b
  return d
end

function representation_mat(a::nf_elem)
  @assert den(a) == 1
  dummy = fmpz(0)
  n = degree(a.parent)
  M = MatrixSpace(FlintZZ, n,n)()::fmpz_mat
  t = gen(a.parent)
  b = a
  for i = 1:n-1
    elem_to_mat_row!(M, i, dummy, b)
    b *= t
  end
  elem_to_mat_row!(M, n, dummy, b)
  return M
end 

function set_den!(a::nf_elem, d::fmpz)
  ccall((:nf_elem_set_den, :libflint), 
        Void, 
       (Ptr{Nemo.nf_elem}, Ptr{Nemo.fmpz}, Ptr{Nemo.AnticNumberField}), 
       &a, &d, &parent(a))
end

function factor(f::PolyElem{nf_elem})
  Kx = parent(f)
  K = base_ring(f)
  Qy = parent(K.pol)
  y = gen(Qy)
  Qyx, x = PolynomialRing(Qy, "x")
  
  Qx = PolynomialRing(QQ, "x")[1]
  Qxy = PolynomialRing(Qx, "y")[1]

  k = 0
  N = zero(Qxy)

  T = zero(Qxy)
  for i in 0:degree(K.pol)
    T = T + coeff(K.pol, i)*gen(Qxy)^i
  end

  g = f

  while true
    G = zero(Qyx)
    for i in 0:degree(g)
      G = G + Qy(coeff(g, i))*x^i
    end

    Gcompose = G

    # Switch the place of the variables

    H = zero(Qxy)

    for i in 0:degree(Gcompose)
      t = coeff(Gcompose, i)
      HH = zero(Qxy)
      for j in 0:degree(t)
        HH = HH + coeff(t, j)*gen(Qxy)^j
      end
      H = H + HH*gen(Qx)^i
    end

    N = resultant(T, H)

    if !is_constant(N) && is_squarefree(N)
      break
    end

    k = k + 1
    g = compose(f, gen(Kx) - k*gen(K))
  end
  
  fac = factor(N)

  res = Dict{PolyElem{nf_elem}, Int64}()

  for i in keys(fac)
    t = zero(Kx)
    for j in 0:degree(i)
      t = t + K(coeff(i, j))*gen(Kx)^j
    end
    t = compose(t, gen(Kx) + k*gen(K))
    res[gcd(f, t)] = 1
  end

  return res
end

################################################################################
#
# Operations for nf_elem
#
################################################################################

function hash(a::nf_elem)
   h = 0xc2a44fbe466a1827%UInt
   for i in 1:degree(parent(a)) + 1
         h $= hash(coeff(a, i))
         h = (h << 1) | (h >> (sizeof(Int)*8 - 1))
   end
   return h
end

function gen!(r::nf_elem)
   a = parent(r)
   ccall((:nf_elem_gen, :libflint), Void, 
         (Ptr{nf_elem}, Ptr{AnticNumberField}), &r, &a)
   return r
end

function one!(r::nf_elem)
   a = parent(r)
   ccall((:nf_elem_one, :libflint), Void, 
         (Ptr{nf_elem}, Ptr{AnticNumberField}), &r, &a)
   return r
end

function zero!(r::nf_elem)
   a = parent(r)
   ccall((:nf_elem_zero, :libflint), Void, 
         (Ptr{nf_elem}, Ptr{AnticNumberField}), &r, &a)
   return r
end

*(a::nf_elem, b::Integer) = a * fmpz(b)

//(a::Integer, b::nf_elem) = parent(b)(a)//b

function norm_div(a::nf_elem, d::fmpz, nb::Int)
   z = fmpq()
   ccall((:nf_elem_norm_div, :libflint), Void,
         (Ptr{fmpq}, Ptr{nf_elem}, Ptr{AnticNumberField}, Ptr{fmpz}, UInt),
         &z, &a, &a.parent, &d, UInt(nb))
   return z
end

function sub!(a::nf_elem, b::nf_elem, c::nf_elem)
   ccall((:nf_elem_sub, :libflint), Void,
         (Ptr{nf_elem}, Ptr{nf_elem}, Ptr{nf_elem}, Ptr{AnticNumberField}),
 
         &a, &b, &c, &a.parent)
end

################################################################################
#
#  Minkowski map
#
################################################################################

doc"""
***
    minkowski_map(a::nf_elem, abs_tol::Int) -> Array{arb, 1}

> Returns the image of $a$ under the Minkowski embedding.
> Every entry of the array returned is of type `arb` with radius less then
> `2^abs_tol`.
"""
function minkowski_map(a::nf_elem, abs_tol::Int)
  K = parent(a)
  A = Array(arb, degree(K))
  r, s = signature(K)
  c = conjugate_data_arb(K)
  R = PolynomialRing(AcbField(c.prec), "x")[1]
  f = R(parent(K.pol)(a))
  CC = AcbField(c.prec)
  T = PolynomialRing(CC, "x")[1]
  g = T(f)

  for i in 1:r
    t = evaluate(g, c.real_roots[i])
    @assert isreal(t)
    A[i] = real(t)
    if !radiuslttwopower(A[i], abs_tol)
      refine(c)
      return minkowski_map(a, abs_tol)
    end
  end

  t = base_ring(g)()

  for i in 1:s
    t = evaluate(g, c.complex_roots[i])
    t = sqrt(CC(2))*t
    if !radiuslttwopower(t, abs_tol)
      refine(c)
      return minkowski_map(a, abs_tol)
    end
    A[r + 2*i - 1] = real(t)
    A[r + 2*i] = imag(t)
  end

  return A
end

################################################################################
#
#  Conjugates and real embeddings
#
################################################################################

doc"""
***
    conjugates_arb(x::nf_elem, abs_tol::Int) -> Array{acb, 1}

> Compute the the conjugates of `x` as elements of type `acb`.
> Recall that we order the complex conjugates
> $\sigma_{r+1}(x),...,\sigma_{r+2s}(x)$ such that
> $\sigma_{i}(x) = \overline{sigma_{i + s}(x)}$ for $r + 1 \leq i \leq r + s$.
>
> Every entry `y` of the array returned satisfies
> `radius(real(y)) < 2^abs_tol` and `radius(imag(y)) < 2^abs_tol` respectively.
"""
function conjugates_arb(x::nf_elem, abs_tol::Int)
  K = parent(x)
  d = degree(K)
  c = conjugate_data_arb(K)
  r, s = signature(K)
  conjugates = Array(acb, r + 2*s)
  CC = AcbField(c.prec)

  for i in 1:r
    conjugates[i] = CC(evaluate(parent(K.pol)(x), c.real_roots[i]))
    if !isfinite(conjugates[i]) || !radiuslttwopower(conjugates[i], abs_tol)
      refine(c)
      return conjugates_arb(x, abs_tol)
    end
  end

  for i in 1:s
    conjugates[r + i] = evaluate(parent(K.pol)(x), c.complex_roots[i])
    if !isfinite(conjugates[i]) || !radiuslttwopower(conjugates[i], abs_tol)
      refine(c)
      return conjugates_arb(x, abs_tol)
    end
    conjugates[r + i + s] = Nemo.conj(conjugates[r + i])
  end
 
  return conjugates
end

doc"""
***
    conjugates_arb_real(x::nf_elem, abs_tol::Int) -> Array{arb, 1}

> Compute the the real conjugates of `x` as elements of type `arb`.
>
> Every entry `y` of the array returned satisfies
> `radius(y) < 2^abs_tol`.
"""
function conjugates_arb_real(x::nf_elem, abs_tol::Int)
  r1, r2 = signature(parent(x))
  c = conjugates_arb(x, abs_tol)
  z = Array(arb, r1)

  for i in 1:r
    z[i] = real(c[i])
  end

  return z
end

doc"""
***
    conjugates_arb_complex(x::nf_elem, abs_tol::Int) -> Array{acb, 1}

> Compute the the complex conjugates of `x` as elements of type `acb`.
> Recall that we order the complex conjugates
> $\sigma_{r+1}(x),...,\sigma_{r+2s}(x)$ such that
> $\sigma_{i}(x) = \overline{sigma_{i + s}(x)}$ for $r + 1 \leq i \leq r + s$.
>
> Every entry `y` of the array returned satisfies
> `radius(real(y)) < 2^abs_tol` and `radius(imag(y)) < 2^abs_tol`.
"""
function conjugates_arb_complex(x::nf_elem, abs_tol::Int)
end

doc"""
***
    conjugates_log(x::nf_elem, abs_tol::Int) -> Array{arb, 1}

> Returns the elements
> $(\log(\lvert \sigma_1(x) \rvert),\dotsc,\log(\lvert\sigma_r(x) \rvert),
> \dotsc,2\log(\lvert \sigma_{r+1}(x) \rvert),\dotsc,
> 2\log(\lvert \sigma_{r+s}(x)\rvert))$ as elements of type `arb` radius
> less then `2^abs_tol`.
"""
function conjugates_arb_log(x::nf_elem, abs_tol::Int)
  K = parent(x)  
  d = degree(K)
  r1, r2 = signature(K)
  c = conjugate_data_arb(K)

  # We should replace this using multipoint evaluation of libarb
  z = Array(arb, r1 + r2)
  for i in 1:r1
    z[i] = log(abs(evaluate(parent(K.pol)(x),c.real_roots[i])))
    if !isfinite(z[i]) || !radiuslttwopower(z[i], abs_tol)
      refine(c)
      return conjugates_arb_log(x, abs_tol)
    end
  end
  for i in 1:r2
    z[r1 + i] = 2*log(abs(evaluate(parent(K.pol)(x), c.complex_roots[i])))
    if !isfinite(z[r1 + i]) || !radiuslttwopower(z[r1 + i], abs_tol)
      refine(c)
      return conjugates_arb_log(x, abs_tol)
    end
  end
  return z
end

################################################################################
#
#  Torsion units and related functions
#
################################################################################

doc"""
***
    is_torsion_unit(x::T, checkisunit::Bool = false) -> Bool
    
    T = Union{nf_elem, FacElem{nf_elem}}

> Returns whether $x$ is a torsion unit, that is, whether there exists $n$ such
> that $x^n = 1$.
> 
> If `checkisunit` is `true`, it is first checked whether $x$ is a unit of the
> maximal order of the number field $x$ is lying in.
"""
function is_torsion_unit{T <: Union{nf_elem, FactoredElem{nf_elem}}}(x::T,
                                                    checkisunit::Bool = false)
  if checkisunit
    _is_unit(x) ? nothing : return false
  end

  K = base_ring(x)
  d = degree(K)
  c = conjugate_data_arb(K)
  r, s = signature(K)

  while true
    l = 0
    cx = conjugates_arb(x, c.prec)
    A = ArbField(c.prec)
    for i in 1:r
      k = abs(cx[i])
      if k > A(1)
        return false
      elseif isnonnegative(A(1) + A(1)//A(6) * log(A(d))//A(d^2) - k)
        l = l + 1
      end
    end
    for i in 1:s
      k = abs(cx[r + i])
      if k > A(1)
        return false
      elseif isnonnegative(A(1) + A(1)//A(6) * log(A(d))//A(d^2) - k)
        l = l + 1
      end
    end

    if l == r + s
      return true
    end
    refine(c)
  end
end

doc"""
***
    torsion_unit_order(x::nf_elem, n::Int)

> Given a torsion unit $x$ together with a multiple $n$ of its order, compute
> the order of $x$, that is, the smallest $k \in \mathbb Z_{\geq 1}$ such
> that $x^`k` = 1$.
>
> It is not checked whether $x$ is a torsion unit.
"""
function torsion_unit_order(x::nf_elem, n::Int)
  # This is lazy
  # Someone please change this
  y = deepcopy(x)
  for i in 1:n
    if y == 1
      return i
    end
    mul!(y, y, x)
  end
  error("Something odd in the torsion unit order computation")
end

################################################################################
#
#  Serialization
#
################################################################################

# This function can be improved by directly accessing the numerator
# of the fmpq_poly representing the nf_elem
doc"""
***
    write(io::IO, A::Array{nf_elem, 1}) -> Void

> Writes the elements of `A` to `io`. The first line are the coefficients of
> the defining polynomial of the ambient number field. The following lines
> contain the coefficients of the elements of `A` with respect to the power
> basis of the ambient number field.
"""
function write(io::IO, A::Array{nf_elem, 1})
  if length(A) == 0
    return
  else
    # print some useful(?) information
    print(io, "# File created by Hecke $VERSION_NUMBER, $(Base.Dates.now()), by function 'write'\n")
    K = parent(A[1])
    polring = parent(K.pol)

    # print the defining polynomial
    g = K.pol
    d = den(g)

    for j in 0:degree(g)
      print(io, coeff(g, j)*d)
      print(io, " ")
    end
    print(io, d)
    print(io, "\n")

    # print the elements
    for i in 1:length(A)

      f = polring(A[i])
      d = den(f)

      for j in 0:degree(K)-1
        print(io, coeff(f, j)*d)
        print(io, " ")
      end

      print(io, d)

      print(io, "\n")
    end
  end
end  

doc"""
***
    write(file::ASCIIString, A::Array{nf_elem, 1}, flag::ASCIString = "w") -> Void

> Writes the elements of `A` to the file `file`. The first line are the coefficients of
> the defining polynomial of the ambient number field. The following lines
> contain the coefficients of the elements of `A` with respect to the power
> basis of the ambient number field.
>
> Unless otherwise specified by the parameter `flag`, the content of `file` will be
> overwritten.
"""
function write(file::ASCIIString, A::Array{nf_elem, 1}, flag::ASCIIString = "w")
  f = open(file, flag)
  write(f, A)
  close(f)
end

# This function has a bad memory footprint
doc"""
***
    read(io::IO, K::AnticNumberField, ::Type{nf_elem}) -> Array{nf_elem, 1}

> Given a file with content adhering the format of the `write` procedure,
> this functions returns the corresponding object of type `Array{nf_elem, 1}` such that
> all elements have parent $K$.

**Example**

    julia> Qx, x = QQ["x"]
    julia> K, a = NumberField(x^3 + 2, "a")
    julia> write("interesting_elements", [1, a, a^2])
    julia> A = read("interesting_elements", K, Hecke.nf_elem)
"""
function read(io::IO, K::AnticNumberField, ::Type{Hecke.nf_elem})
  Qx = parent(K.pol)

  A = Array{nf_elem, 1}()

  i = 1

  for ln in eachline(io)
    if ln[1] == '#'
      continue
    elseif i == 1
      # the first line read should contain the number field and will be ignored
      i = i + 1
    else
      coe = map(Hecke.fmpz, split(ln, " "))
      t = fmpz_poly(Array(slice(coe, 1:(length(coe) - 1))))
      t = Qx(t)
      t = divexact(t, coe[end])
      push!(A, K(t))
      i = i + 1
    end
  end
  
  return A
end

doc"""
***
    read(file::ASCIIString, K::AnticNumberField, ::Type{nf_elem}) -> Array{nf_elem, 1}

> Given a file with content adhering the format of the `write` procedure,
> this functions returns the corresponding object of type `Array{nf_elem, 1}` such that
> all elements have parent $K$.

**Example**

    julia> Qx, x = QQ["x"]
    julia> K, a = NumberField(x^3 + 2, "a")
    julia> write("interesting_elements", [1, a, a^2])
    julia> A = read("interesting_elements", K, Hecke.nf_elem)
"""
function read(file::ASCIIString, K::AnticNumberField, ::Type{Hecke.nf_elem})
  f = open(file, "r")
  A = read(f, K, Hecke.nf_elem)
  close(f)
  return A
end

