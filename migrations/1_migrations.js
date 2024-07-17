var MultiSignature = artifacts.require("MultiSignature");
owners = ["0x3b1b31f1a805C36Af1CFe12237549EdcB5370B3a"];
approvals = 1;
module.exports = function (deployer) {
  // deployment steps
  deployer.deploy(MultiSignature, owners, approvals); // deployment of the proxy contract and passing the owner address we want to set
};
