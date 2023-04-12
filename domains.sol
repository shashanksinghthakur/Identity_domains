// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DomainRegistrar {
    struct Domain {
        address owner;
        mapping(bytes32 => address) subdomains;
        mapping(bytes32 => address) soulBoundSubdomains; // New mapping for soul-bound subdomains
    }

    mapping(bytes32 => Domain) private domains;

    function registerDomain(string memory domainName) public {
        bytes32 domainNameBytes32 = stringToBytes32(domainName);
        require(domains[domainNameBytes32].owner == address(0), "Domain already registered");
        domains[domainNameBytes32].owner = msg.sender;
    }

    function registerSubdomain(string memory domainName, string memory subdomainName, address targetAddress, bool soulBound) public {
        bytes32 domainNameBytes32 = stringToBytes32(domainName);
        bytes32 subdomainNameBytes32 = stringToBytes32(subdomainName);
        require(domains[domainNameBytes32].owner == msg.sender, "Only domain owner can register subdomains");
        domains[domainNameBytes32].subdomains[subdomainNameBytes32] = targetAddress;
        
        if (soulBound) {
            domains[domainNameBytes32].soulBoundSubdomains[subdomainNameBytes32] = targetAddress;
        }
    }

    function resolveDomain(string memory domainName, string memory subdomainName) public view returns (address) {
        bytes32 domainNameBytes32 = stringToBytes32(domainName);
        bytes32 subdomainNameBytes32 = stringToBytes32(subdomainName);
        address targetAddress = domains[domainNameBytes32].subdomains[subdomainNameBytes32];
        if (targetAddress == address(0)) {
            return domains[domainNameBytes32].owner;
        }
        return targetAddress;
    }
    
    function resolveSoulBoundSubdomain(string memory domainName, string memory subdomainName) public view returns (address) {
        bytes32 domainNameBytes32 = stringToBytes32(domainName);
        bytes32 subdomainNameBytes32 = stringToBytes32(subdomainName);
        return domains[domainNameBytes32].soulBoundSubdomains[subdomainNameBytes32];
    }
    
    function stringToBytes32(string memory str) private pure returns (bytes32) {
        bytes32 result;
        assembly {
            result := mload(add(str, 32))
        }
        return result;
    }
}
