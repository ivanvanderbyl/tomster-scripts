module.exports = {
  assets: {
    accessKeyId: process.env.TOMSTER_ACCESS_KEY_ID,
    secretAccessKey: process.env.TOMSTER_SECRET_ACCESS_KEY,
    sessionToken: process.env.TOMSTER_SESSION_TOKEN,
    bucket: process.env.TOMSTER_BUCKET_NAME,
    filePattern: '**/*.*',
  },

  index: {
    host: 'localhost',
    port: '6379',
  }
};
