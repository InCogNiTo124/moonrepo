from sympy import sin, cos, series, symbols, simplify, diff, tanh
from sympy.polys.ring_series import rs_series_reversion
from sympy.polys.ring_series import rs_series_reversion_newton
from scipy.interpolate import pade
from math import pi


def format_i(i) -> str:
    if i == 0:
        return ""
    return f"x^{i}"


def format_poly(p) -> str:
    c = p.coef[::-1]
    (n,) = c.shape
    elems = [
        f"{'-' if e < 0 else '+'}{abs(e)}{format_i(i)}" for i, e in enumerate(c) if e != 0
    ]
    return "".join(elems)


N = 16

x, k = symbols('x k', real=True)
t = 2*pi*tanh(x)
# p = (t - sin(t)) / (1 - cos(t))
p = x*(1 - cos(t))/(t - sin(t)) - 0.477464829275686
# t = 2*pi-x
# p = (1 - cos(t))/(t - sin(t))
ps = simplify(series(p, x, 0, n=N).removeO())
Rx = ps.as_poly(x).domain[x]
pr = Rx.from_sympy(ps)
xr = Rx.from_sympy(x)

# q = rs_series_reversion_newton(pr, xr, N)
q = rs_series_reversion(pr, xr, N, xr)
# coeffs = [2 * pi if i == 0 else -float(q.coeff(xr**i)) for i in range(N)]
coeffs = [float(q.coeff(xr**i)) for i in range(N)]
num, denom = pade(coeffs, N // 2, N // 2-1)
desmos = f"({format_poly(num)})/({format_poly(denom)})"
print(desmos)
print('vec![' + ',\n'.join(str(t) for t in num) + '];')
print('vec![' + ',\n'.join(str(t) for t in denom) + '];')
