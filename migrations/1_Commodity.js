const Commodity = artifacts.require("Commodity");

module.exports = function (deployer) {
  deployer.deploy(Commodity);
};
