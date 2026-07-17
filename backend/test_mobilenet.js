import * as tf from '@tensorflow/tfjs';
import * as mobilenet from '@tensorflow-models/mobilenet';
import sharp from 'sharp';

async function run() {
  console.log('Loading MobileNet...');
  const model = await mobilenet.load();
  console.log('MobileNet loaded successfully!');

  // Create a 224x224 raw buffer using sharp
  const buffer = await sharp({
    create: {
      width: 224,
      height: 224,
      channels: 3,
      background: { r: 255, g: 0, b: 0 } // Red image
    }
  }).raw().toBuffer({ resolveWithObject: true });

  console.log('Image buffer created. Converting to tensor...');
  const tensor = tf.tensor3d(new Uint8Array(buffer.data), [224, 224, 3]);

  console.log('Running prediction...');
  const predictions = await model.classify(tensor);
  console.log('Predictions:', predictions);

  tensor.dispose();
}

run().catch(console.error);
