const Supplier = artifacts.require("./entity/Supplier");

module.exports = function (deployer) {
  deployer.deploy(Supplier);
};
