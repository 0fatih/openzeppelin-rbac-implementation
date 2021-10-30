# Openzeppelin's Role-Based-Access-Control Contract

This contract's original name in OpenZeppelin is `AccessControl.sol` but I preferred to use RBAC. Because according to OpenZeppelin docs:

>OpenZeppelin Contracts provides AccessControl for implementing role-based access control.

## What is Role-Based Access Control

You are probably need to access manages of your contract functions. But sometimes [Ownable](https://github.com/0fatih/openzeppelin-ownable-implementation) is not enough. So you can create your own roles and give access to them with this method.

## Inspect

You can look at the `AccessControl` contract from [here](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.0/contracts/access/AccessControl.sol) by yourself.

Our contract starts with a struct. This struct stores which address has which role. And there is an `adminRole`, it is using for which role can grant or revoke this role. I can give an example for usage of this struct: We have also a function named `hasRole`. When you are querying an address does have that role, you are basically doing: `_roles[role].members[account]`. Now let's look what is `_roles`.
```solidity
struct RoleData {
    mapping(address => bool) members;
    bytes32 adminRole;
}
```

`_roles` is a mapping from bytes32 to RoleData struct. Why bytes32? Because we are creating our roles with their `keccak256`. For example if you want to create a role named "coder", you have to use `keccak256("coder")`.
```solidity
mapping(bytes32 => RoleData) private _roles;
```

This variable for which address going to default for `roleAdmins`.
```solidity
bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
```

This modifier checks the `msg.sender` has the `role`. If it have not, then `_checkRole` reverts the transaction.
```solidity
modifier onlyRole(bytes32 role) {
    _checkRole(role, _msgSender());
    _;
}
```

Here is ERC165 implementation. If you want to learn more about it, [this](https://medium.com/@chiqing/ethereum-standard-erc165-explained-63b54ca0d273) one is a great article.
```solidity
function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
}
```

This function returns a boolean for does `account` have `role`. Attention! It is a function and `onlyRole` is a modifier. And this one takes an address to check.
```solidity
function hasRole(bytes32 role, address account) public view override returns (bool) {
    return _roles[role].members[account];
}
```

Checks does `account` has `role`. If it doesn't returns an error message.
```solidity
function _checkRole(bytes32 role, address account) internal view {
    if (!hasRole(role, account)) {
        revert(
            string(
                abi.encodePacked(
                    "AccessControl: account ",
                    Strings.toHexString(uint160(account), 20),
                    " is missing role ",
                    Strings.toHexString(uint256(role), 32)
                )
            )
        );
    }
}
```

Only role admin (admin in the RoleData) can grant and revoke role an address. And this function returns adminRole for `role`.
```solidity
function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
    return _roles[role].adminRole;
}
```

We are checking the `msg.sender` does have the `adminRole` for the `role`. If it does, `account` granting to `role`.
```solidity
function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
    _grantRole(role, account);
}
```

Same as above.
```solidity
function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
    _revokeRole(role, account);
}
```

An account can revoke from which `role` he wants by calling this function.
```solidity
function renounceRole(bytes32 role, address account) public virtual override {
    require(account == _msgSender(), "AccessControl: can only renounce roles for self");

    _revokeRole(role, account);
}
```

OpenZeppelin says for `_setupRole`: 
> This function should only be called from the constructor when setting up the initial roles for the system.

You can see an example of this in implementation.
```solidity
function _setupRole(bytes32 role, address account) internal virtual {
    _grantRole(role, account);
}
```

We can set the `roleAdmin` for `role`.
```solidity
function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
    bytes32 previousAdminRole = getRoleAdmin(role);
    _roles[role].adminRole = adminRole;
    emit RoleAdminChanged(role, previousAdminRole, adminRole);
}
```

Give `role` to `account`.
```solidity
function _grantRole(bytes32 role, address account) private {
    if (!hasRole(role, account)) {
        _roles[role].members[account] = true;
        emit RoleGranted(role, account, _msgSender());
    }
}
```

Take back `role` from `account`.
```solidity
function _revokeRole(bytes32 role, address account) private {
    if (hasRole(role, account)) {
        _roles[role].members[account] = false;
        emit RoleRevoked(role, account, _msgSender());
    }
}
```

## Implementation

Here is an example usage of `AccessControl` in `contracts/Implementation.sol`.

```solidity
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
```

If you want to interact or something else with this contract, you can look at usage of [hardhat](https://hardhat.org/getting-started/).