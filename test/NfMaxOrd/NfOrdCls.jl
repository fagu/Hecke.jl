function test_NfOrdCls()
  Qx, x = PolynomialRing(FlintQQ, "x")

  K1, a1 = NumberField(x^3 - 2, "a")
  O1 = EquationOrder(K1)

  K2, a2 = NumberField(x - 2, "a")
  O2 = EquationOrder(K2)

  f3 = x^64 - 64*x^62 + 1952*x^60 - 37760*x^58 + 520144*x^56 - 5430656*x^54 + 44662464*x^52 - 296854272*x^50 + 1623421800*x^48 - 7398867840*x^46 + 28362326720*x^44 - 92043777280*x^42 + 254005423840*x^40 - 597659820800*x^38 + 1200442440064*x^36 - 2057901325824*x^34 + 3006465218196*x^32 - 3732682723968*x^30 + 3922021702720*x^28 - 3467892873984*x^26 + 2561511781920*x^24 - 1565841089280*x^22 + 782920544640*x^20 - 315492902400*x^18 + 100563362640*x^16 - 24754058496*x^14 + 4559958144*x^12 - 602516992*x^10 + 53796160*x^8 - 2968064*x^6 + 87296*x^4 - 1024*x^2 + 2

  K3, a3 = NumberField(f3, "a")
  O3 = EquationOrder(K3)

  @test_and_infer(signature, (O1, ), (1, 1))
  @test_and_infer(signature, O2, (1, 0))
  @test_and_infer(signature, (O3, ), (64, 0))

end

