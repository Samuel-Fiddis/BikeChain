module.exports = {
  server: {
    baseDir: ["./src", "./build/contracts"],
    middleware: [require('ipfs-api')()]
  },
  watchOptions: {
    ignored: null,
  }
};
