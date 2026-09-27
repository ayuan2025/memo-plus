package com.memoflow.hzc073.audio

import kotlin.math.cos
import kotlin.math.sin

object Radix2Fft {
    fun transform(real: DoubleArray, imag: DoubleArray) {
        require(real.size == imag.size) { "Real and imaginary arrays must match in size." }
        val n = real.size
        require(n > 0 && n and (n - 1) == 0) { "FFT size must be a power of two." }

        var j = 0
        for (i in 0 until n) {
            if (i < j) {
                val tempReal = real[i]
                real[i] = real[j]
                real[j] = tempReal

                val tempImag = imag[i]
                imag[i] = imag[j]
                imag[j] = tempImag
            }

            var bit = n shr 1
            while (bit > 0 && (j and bit) != 0) {
                j = j xor bit
                bit = bit shr 1
            }
            j = j xor bit
        }

        var length = 2
        while (length <= n) {
            val angle = -2.0 * Math.PI / length
            val wLenCos = cos(angle)
            val wLenSin = sin(angle)

            var start = 0
            while (start < n) {
                var wCos = 1.0
                var wSin = 0.0

                for (k in 0 until length / 2) {
                    val evenIndex = start + k
                    val oddIndex = evenIndex + length / 2

                    val oddReal = real[oddIndex] * wCos - imag[oddIndex] * wSin
                    val oddImag = real[oddIndex] * wSin + imag[oddIndex] * wCos

                    real[oddIndex] = real[evenIndex] - oddReal
                    imag[oddIndex] = imag[evenIndex] - oddImag
                    real[evenIndex] += oddReal
                    imag[evenIndex] += oddImag

                    val nextWCos = wCos * wLenCos - wSin * wLenSin
                    wSin = wCos * wLenSin + wSin * wLenCos
                    wCos = nextWCos
                }

                start += length
            }

            length = length shl 1
        }
    }
}
