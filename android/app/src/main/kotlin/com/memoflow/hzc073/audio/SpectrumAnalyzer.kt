package com.memoflow.hzc073.audio

import kotlin.math.ceil
import kotlin.math.cos
import kotlin.math.floor
import kotlin.math.ln
import kotlin.math.max
import kotlin.math.min
import kotlin.math.pow
import kotlin.math.sqrt

data class SpectrumSnapshot(
    val bars: List<Double>,
    val rmsLevel: Double,
    val peakLevel: Double,
    val hasVoice: Boolean,
)

class SpectrumAnalyzer(
    private val sampleRate: Int = 16_000,
    private val fftSize: Int = 1024,
    private val hopSize: Int = 256,
    private val barCount: Int = 48,
    private val minFrequency: Double = 60.0,
    private val maxFrequency: Double = 8_000.0,
) {
    companion object {
        private const val EPSILON = 1.0e-9
        private const val DB_FLOOR = -72.0
    }

    private data class BandRange(val startBin: Int, val endBinExclusive: Int)

    private val window = DoubleArray(fftSize) { index ->
        0.5 - 0.5 * cos((2.0 * Math.PI * index) / (fftSize - 1).coerceAtLeast(1))
    }
    private val bandRanges = buildBandRanges()
    private val sampleBuffer = DoubleArray(fftSize)
    private var bufferedSamples = 0

    fun reset() {
        bufferedSamples = 0
        sampleBuffer.fill(0.0)
    }

    fun processPcm(bytes: ByteArray, length: Int, onFrame: (SpectrumSnapshot) -> Unit) {
        var offset = 0
        while (offset + 1 < length) {
            val low = bytes[offset].toInt() and 0xFF
            val high = bytes[offset + 1].toInt()
            val sample = ((high shl 8) or low).toShort().toDouble() / 32768.0
            sampleBuffer[bufferedSamples] = sample.coerceIn(-1.0, 1.0)
            bufferedSamples += 1
            offset += 2

            if (bufferedSamples == fftSize) {
                onFrame(analyzeFrame())
                val remaining = fftSize - hopSize
                System.arraycopy(sampleBuffer, hopSize, sampleBuffer, 0, remaining)
                bufferedSamples = remaining
            }
        }
    }

    private fun analyzeFrame(): SpectrumSnapshot {
        val real = DoubleArray(fftSize)
        val imag = DoubleArray(fftSize)
        var rmsAccumulator = 0.0
        var peak = 0.0

        for (index in 0 until fftSize) {
            val sample = sampleBuffer[index]
            rmsAccumulator += sample * sample
            peak = max(peak, kotlin.math.abs(sample))
            real[index] = sample * window[index]
        }

        Radix2Fft.transform(real, imag)

        val halfBinCount = fftSize / 2
        val magnitudes = DoubleArray(halfBinCount)
        val scale = fftSize / 2.0
        for (index in 1 until halfBinCount) {
            val magnitude = sqrt(real[index] * real[index] + imag[index] * imag[index]) / scale
            magnitudes[index] = magnitude
        }

        val bars = List(barCount) { bandIndex ->
            val range = bandRanges[bandIndex]
            var powerSum = 0.0
            var peakMagnitude = 0.0
            var count = 0
            for (bin in range.startBin until range.endBinExclusive) {
                val magnitude = magnitudes[bin]
                powerSum += magnitude * magnitude
                peakMagnitude = max(peakMagnitude, magnitude)
                count += 1
            }

            if (count == 0) {
                0.0
            } else {
                val rms = sqrt(powerSum / count)
                val blended = rms * 0.7 + peakMagnitude * 0.3
                val db = 20.0 * ln(blended + EPSILON) / ln(10.0)
                val normalized = ((db - DB_FLOOR) / -DB_FLOOR).coerceIn(0.0, 1.0)
                normalized.pow(0.82).coerceIn(0.0, 1.0)
            }
        }

        val rmsLevel = sqrt(rmsAccumulator / fftSize).coerceIn(0.0, 1.0)
        val peakLevel = peak.coerceIn(0.0, 1.0)
        val hasVoice = rmsLevel >= 0.035 || (bars.maxOrNull() ?: 0.0) >= 0.16

        return SpectrumSnapshot(
            bars = bars,
            rmsLevel = rmsLevel,
            peakLevel = peakLevel,
            hasVoice = hasVoice,
        )
    }

    private fun buildBandRanges(): List<BandRange> {
        val nyquist = sampleRate / 2.0
        val clampedMax = max(minFrequency + 1.0, min(maxFrequency, nyquist))
        return List(barCount) { index ->
            val startFrequency = minFrequency * (clampedMax / minFrequency).pow(index.toDouble() / barCount)
            val endFrequency = minFrequency * (clampedMax / minFrequency).pow((index + 1).toDouble() / barCount)

            val startBin = max(1, floor(startFrequency * fftSize / sampleRate).toInt())
            val endBinExclusive = min(
                fftSize / 2,
                max(startBin + 1, ceil(endFrequency * fftSize / sampleRate).toInt()),
            )

            BandRange(startBin = startBin, endBinExclusive = endBinExclusive)
        }
    }
}
