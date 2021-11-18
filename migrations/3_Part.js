const Part = artifacts.require("Part");
const name = 'Part Token';
const symbol = 'PART';

module.exports = function (deployer) {
  deployer.deploy(Part, name, symbol);
};
