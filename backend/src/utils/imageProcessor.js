import sharp from 'sharp';
import logger from './logger.js';

/**
 * Image preprocessing utilities for the AI evaluation pipeline.
 */

/**
 * Preprocess a drawing image for AI evaluation.
 * @param {Buffer} imageBuffer - Raw PNG image buffer
 * @param {Object} options
 * @param {number} options.width - Target width (default: 256)
 * @param {number} options.height - Target height (default: 256)
 * @param {boolean} options.grayscale - Convert to grayscale (default: false)
 * @returns {Promise<{ buffer: Buffer, metadata: Object }>}
 */
export async function preprocessImage(imageBuffer, options = {}) {
  const { width = 256, height = 256, grayscale = false } = options;

  try {
    let pipeline = sharp(imageBuffer)
      .resize(width, height, {
        fit: 'contain',
        background: { r: 255, g: 255, b: 255, alpha: 1 },
      })
      .flatten({ background: { r: 255, g: 255, b: 255 } }); // Remove alpha

    if (grayscale) {
      pipeline = pipeline.grayscale();
    }

    const processedBuffer = await pipeline.png().toBuffer();
    const metadata = await sharp(processedBuffer).metadata();

    logger.debug(`Image preprocessed: ${width}x${height}, grayscale=${grayscale}, size=${processedBuffer.length} bytes`);

    return { buffer: processedBuffer, metadata };
  } catch (error) {
    logger.error('Image preprocessing failed:', error);
    throw new Error(`Image preprocessing failed: ${error.message}`);
  }
}

/**
 * Convert image buffer to base64 for API submission.
 * @param {Buffer} imageBuffer
 * @returns {string}
 */
export function imageToBase64(imageBuffer) {
  return imageBuffer.toString('base64');
}

/**
 * Extract basic image features for quality assessment.
 * @param {Buffer} imageBuffer
 * @returns {Promise<Object>}
 */
export async function extractImageFeatures(imageBuffer) {
  try {
    const { data, info } = await sharp(imageBuffer)
      .resize(64, 64)
      .grayscale()
      .raw()
      .toBuffer({ resolveWithObject: true });

    // Calculate basic statistics
    const pixels = Array.from(data);
    const mean = pixels.reduce((a, b) => a + b, 0) / pixels.length;
    const variance = pixels.reduce((acc, val) => acc + Math.pow(val - mean, 2), 0) / pixels.length;
    const stdDev = Math.sqrt(variance);

    // Count non-white pixels (drawing content)
    const threshold = 252;
    const drawnPixels = pixels.filter(p => p < threshold).length;
    const coverage = drawnPixels / pixels.length;

    // Edge detection proxy: count significant pixel differences
    let edgeCount = 0;
    for (let i = 1; i < pixels.length; i++) {
      if (Math.abs(pixels[i] - pixels[i - 1]) > 50) {
        edgeCount++;
      }
    }
    const edgeDensity = edgeCount / pixels.length;

    return {
      width: info.width,
      height: info.height,
      mean: Math.round(mean),
      stdDev: Math.round(stdDev * 100) / 100,
      coverage: Math.round(coverage * 100) / 100,
      edgeDensity: Math.round(edgeDensity * 100) / 100,
      isBlank: coverage < 0.01,
      hasContent: coverage > 0.05,
    };
  } catch (error) {
    logger.error('Feature extraction failed:', error);
    return { isBlank: false, hasContent: true, coverage: 0.5, edgeDensity: 0.3 };
  }
}
