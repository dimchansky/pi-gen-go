package pigen

import "math/big"

// PiGen is pi digits generator based on the formula:
//
// > piG3 = g(1,180,60,2) where
// >   g(q,r,t,i) = let (u,y)=(3*(3*i+1)*(3*i+2),div(q*(27*i-12)+5*r)(5*t))
// >                in y : g(10*q*i*(2*i-1),10*u*(q*(5*i-2)+r-y*t),t*u,i+1)
type PiGen struct {
	q *big.Int
	r *big.Int
	t *big.Int
	i *big.Int
}

// New creates new instance of PiGen
func New() *PiGen {
	return &PiGen{q: big.NewInt(1), r: big.NewInt(180), t: big.NewInt(60), i: big.NewInt(2)}
}

var (
	bi1  = big.NewInt(1)
	bi2  = big.NewInt(2)
	bi3  = big.NewInt(3)
	bi5  = big.NewInt(5)
	bi10 = big.NewInt(10)
	bi12 = big.NewInt(12)
	bi27 = big.NewInt(27)
)

// NextDigit returns next digit of pi
func (g *PiGen) NextDigit() int64 {
	q := g.q
	r := g.r
	t := g.t
	i := g.i

	bi3MulI := mul(bi3, i)
	u := mul(mul(bi3, add(bi3MulI, bi1)), add(bi3MulI, bi2))
	y := div(add(mul(q, sub(mul(bi27, i), bi12)), mul(bi5, r)), mul(bi5, t))

	g.q = mul(mul(mul(bi10, q), i), sub(mul(bi2, i), bi1))
	g.r = mul(mul(bi10, u), sub(add(mul(q, sub(mul(bi5, i), bi2)), r), mul(y, t)))
	g.t = mul(t, u)
	g.i = add(i, bi1)

	return y.Int64()
}

func mul(x *big.Int, y *big.Int) *big.Int { return new(big.Int).Mul(x, y) }

func div(x *big.Int, y *big.Int) *big.Int { return new(big.Int).Div(x, y) }

func add(x *big.Int, y *big.Int) *big.Int { return new(big.Int).Add(x, y) }

func sub(x *big.Int, y *big.Int) *big.Int { return new(big.Int).Sub(x, y) }