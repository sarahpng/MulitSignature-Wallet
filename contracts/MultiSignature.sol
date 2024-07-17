// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MultiSignature{

struct Transaction {
  address to; // this will be address where the transaction is executed
  uint value; // this will be the amount of ethers sent to the ‘to’ address
  bytes data; // this will be the data sent to the ‘to’ address
  bool executed; // once the transaction is executed we will set it to true
}

  using ECDSA for bytes32;

  uint256 public requiredApprovals;
  address[] public owners;
  Transaction[] public transactions;
  mapping(uint => mapping(address => bool)) public approved;
  mapping(address => bool) public isOwner;

constructor(address[] memory _owners, uint _requiredApprovals) {
  require(_owners.length > 0, "Owners required");
  require(_requiredApprovals > 0 && _requiredApprovals <= _owners.length, "Invalid required number of owners");

  for(uint i; i < _owners.length; i++) {
    isOwner[_owners[i]] = true;
    owners.push(_owners[i]);
  }

  requiredApprovals = _requiredApprovals;
}

modifier onlyOwner {
	require(isOwner[msg.sender], "not owner");
	_;
}

modifier txExists(uint _txId) {
	require(_txId < transactions.length, "tx does not exists");
	_;
}

modifier notApproved(uint _txId){
	require(!approved[_txId][msg.sender], "tx already approved");
	_;
}

modifier notExecuted(uint _txId) {
	require(!transactions[_txId].executed, "tx already executed");
	_;
}

function createTransaction(address _to, uint _value, bytes calldata _data) external onlyOwner {
	transactions.push(Transaction({
		to: _to,
		value: _value,
		data: _data,
		executed: false
}));
}

function execute(uint _txId,  bytes memory signature, bytes32 msgHash) external txExists(_txId) notExecuted(_txId) {
	require(_getApprovalCount(_txId) >= requiredApprovals, "approvals < required");
  bytes32 messageHash = getMessageHash(_txId);
	bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
  require(ethSignedMessageHash == msgHash, "message hash not equal");
  address _singer = recoverSigner(ethSignedMessageHash, signature);
  require(isOwner[_singer] && approved[_txId][_singer],"Unknown signer or signer didnt approve");

  (bool success, ) = payable(transactions[_txId].to).call{value: transactions[_txId].value}(transactions[_txId].data);

  Transaction storage transaction = transactions[_txId];
	transaction.executed = success;
	
}

  function approve(uint _txId) external onlyOwner txExists(_txId) notApproved(_txId) notExecuted(_txId){
	approved[_txId][msg.sender] = true;
}

  function getMessageHash(uint _txId) public view returns (bytes32) {
        return keccak256(abi.encodePacked(transactions[_txId].to, transactions[_txId].value));
    }

 function getEthSignedMessageHash(
        bytes32 _messageHash
    ) public pure returns (bytes32) {
        // return _messageHash.toEthSignedMessageHash();
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            ); 
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) public pure returns (address) {
        return _ethSignedMessageHash.recover(_signature);

        // return ecrecover(_ethSignedMessageHash, v, r, s);
    }

function _getApprovalCount(uint _txId) private view returns(uint count) {
	for (uint i; i < owners.length; i++) {
	  if(approved[_txId][owners[i]]) {
		  count += 1;
    }
  }
}


receive() external payable {
}


}
