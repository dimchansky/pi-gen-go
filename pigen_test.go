package pigen

import (
	"testing"
)

var digit int64

func BenchmarkNextDigit100(b *testing.B) { benchmarkNextDigit(100, b) }
func BenchmarkNextDigit10(b *testing.B) { benchmarkNextDigit(10, b) }

func benchmarkNextDigit(cnt int, b *testing.B) {
	g := New()

	b.ReportAllocs()
	b.ResetTimer()

	for n := 0; n < b.N; n++ {
		for j := 0; j < cnt; j++ {
			digit = g.NextDigit()
		}
	}
}
