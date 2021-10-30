//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract Greeter is AccessControl {
    string private greeting;

    bytes32 public constant MESSAGE_GETTER = keccak256("MESSAGE_GETTER");
    bytes32 public constant MESSAGE_SETTER = keccak256("MESSAGE_SETTER");

	 // Set greeting
	 // Create a new role
    constructor(string memory _greeting) {
        greeting = _greeting;
        _setupRole(MESSAGE_GETTER, msg.sender);
        _setupRole(MESSAGE_SETTER, msg.sender);
    }

    // We can give set access to user directly with this function
    function giveAccessForSET(address account) public onlyRole(MESSAGE_SETTER) {
        grantRole(MESSAGE_SETTER, account);
    }

    function giveAccessForGET(address account) public onlyRole(MESSAGE_GETTER) {
        grantRole(MESSAGE_GETTER, account);
    }

    function greet() public view returns (string memory) {
        require(hasRole(MESSAGE_GETTER, msg.sender), "Caller is not a message getter");
        return greeting;
    }

    function setGreeting(string memory _greeting) public onlyRole(MESSAGE_SETTER) {
        greeting = _greeting;
    }
}
