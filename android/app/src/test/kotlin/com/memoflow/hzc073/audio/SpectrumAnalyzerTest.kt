package com.memoflow.hzc073.audio

import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.math.PI
import kotlin.math.max
import kotlin.math.sin

class SpectrumAnalyzerTest {
    @Test
    fun silenceStaysNearZero() {
        val analyzer = SpectrumAnalyzer()
        var latest: SpectrumSnapshot? = null

        analyzer.processPcm(ByteArray(2048), 2048) {
            latest = it
        }

        val snapshot = requireNotNull(latest)
        assertTrue(snapshot.bars.all { it <= 0.02 })
        assertTrue(snapshot.rmsLevel <= 0.001)
        assertTrue(!snapshot.hasVoice)
    }

    @Test
    fun lowFrequencySineProducesVisibleEnergy() {
        val analyzer = SpectrumAnalyzer()
        var latest: SpectrumSnapshot? = null

        analyzer.processPcm(generateSinePcm(frequency = 440.0), 2048) {
            latest = it
        }

        val snapshot = requireNotNull(latest)
        assertTrue(snapshot.bars.maxOrNull() ?: 0.0 > 0.2)
        assertTrue(snapshot.hasVoice)
    }

    @Test
    fun higherFrequencySineShiftsEnergyRight() {
        val analyzer = SpectrumAnalyzer()
        var lowSnapshot: SpectrumSnapshot? = null
        var highSnapshot: SpectrumSnapshot? = null

        analyzer.processPcm(generateSinePcm(frequency = 440.0), 2048) {
            lowSnapshot = it
        }
        analyzer.reset()
        analyzer.processPcm(generateSinePcm(frequency = 2000.0), 2048) {
            highSnapshot = it
        }

        val lowPeakIndex = requireNotNull(lowSnapshot).bars.indices.maxByOrNull { index ->
            lowSnapshot!!.bars[index]
        } ?: 0
        val highPeakIndex = requireNotNull(highSnapshot).bars.indices.maxByOrNull { index ->
            highSnapshot!!.bars[index]
        } ?: 0

        assertTrue(highPeakIndex > lowPeakIndex)
    }

    private fun generateSinePcm(
        frequency: Double,
        sampleRate: Int = 16_000,
        sampleCount: Int = 1024,
        amplitude: Double = 0.9,
    ): ByteArray {
        val output = ByteArray(sampleCount * 2)
        for (index in 0 until sampleCount) {
            val value = sin((2.0 * PI * frequency * index) / sampleRate) * amplitude
            val sample = max(-32768.0, minOf(32767.0, value * 32767.0)).toInt().toShort()
            output[index * 2] = (sample.toInt() and 0xFF).toByte()
            output[index * 2 + 1] = ((sample.toInt() shr 8) and 0xFF).toByte()
        }
        return output
    }
}
