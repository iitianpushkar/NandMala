// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./Pool.sol";
import "./PTYT.sol";

import "@openzeppelin/contracts/proxy/Clones.sol";

contract PoolFactory {
    address public immutable poolImplementation;
    address public immutable ptImplementation;
    address public immutable ytImplementation;

    address[] public allPools;

    event PoolCreated(address pool, address pt, address yt, address owner);

    constructor(address _poolImpl, address _ptImpl, address _ytImpl) {
        poolImplementation = _poolImpl;
        ptImplementation = _ptImpl;
        ytImplementation = _ytImpl;
    }

    function createPool(string memory ptName, string memory ytName) external returns (address pool, address pt, address yt) {
        // 1️⃣ Deploy PT + YT clones
        pt = Clones.clone(ptImplementation);
        PTYT(pt).initialize(ptName, "PT");

        yt = Clones.clone(ytImplementation);
        PTYT(yt).initialize(ytName, "YT");

        // 2️⃣ Deploy Pool clone
        pool = Clones.clone(poolImplementation);
        Pool(pool).initialize(pt, yt);

        // 3️⃣ Set Pool as minter for PT + YT
        PTYT(pt).setMinter(pool);
        PTYT(yt).setMinter(pool);

        allPools.push(pool);

        emit PoolCreated(pool, pt, yt, msg.sender);
    }

    function allPoolsLength() external view returns (uint256) {
        return allPools.length;
    }
}
