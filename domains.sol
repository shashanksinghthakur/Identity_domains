// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ChainAgnosticDomainRegistrar is ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("ChainAgnosticDomainRegistrar", "WAGMI") {}

    function safeMint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }


    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

contract DomainRegistrar is ChainAgnosticDomainRegistrar {
    struct Domain {
        address owner;
        mapping(bytes32 => address) subdomains;
        mapping(bytes32 => address) soulBoundSubdomains; 
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
