// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract CollectionTREXNFT is ERC1155, Ownable, Pausable, ERC1155Supply {
    using Counters for Counters.Counter;
    Counters.Counter private tokenIds;
    uint256 public mintingCost;
    uint256 public maxSupply;
    bool public hidden;
    string public name;
    string public symbol;

    constructor()
        ERC1155("ipfs://<CID>/hidden")
    {
        setMintingCost(0.06 ether);
        setMaxSupply(10000);
        setName("TREXNFT");
        setSymbol("TREX");
        setHidden(true);
        pause();
    }

    //
    // Modifiers
    //

    modifier mintCompliance(uint256 mintAmount) {
        require(
            tokenIds.current() + mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        _;
    }

    //
    // Internal Functions
    //

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    //
    //  OWNER ONLY Public Functions
    //

    // Minting function available to only the owner address
    function ownerMint(address to, uint256 mintAmount)
        public
        onlyOwner
        whenNotPaused
        mintCompliance(mintAmount)
    {
        if (mintAmount == 1) {
            tokenIds.increment();
            _mint(to, tokenIds.current(), 1, "");
        } else if (mintAmount > 1) {
            uint256[] memory ids = new uint256[](mintAmount);
            uint256[] memory amounts = new uint256[](mintAmount);
            for (uint256 i = 0; i < mintAmount; i++) {
                tokenIds.increment();
                ids[i] = tokenIds.current();
                amounts[i] = 1;
            }
            _mintBatch(to, ids, amounts, "");
        }
    }

    function setMintingCost(uint256 newMintingCost) public onlyOwner {
        require(
            mintingCost != newMintingCost,
            "Minting cost already set to value"
        );
        mintingCost = newMintingCost;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function setHidden(bool newHidden) public onlyOwner {
        hidden = newHidden;
    }

    function revealTokens(string memory newuri) public onlyOwner {
        require(hidden != false, "Tokens already revealed");
        _setURI(newuri);
        hidden = false;
    }

    function setMaxSupply(uint256 newMaxSupply) public onlyOwner {
        require(maxSupply == 0, "Max supply can only be set once");
        maxSupply = newMaxSupply;
    }

    function setName(string memory newName) public onlyOwner {
        require(bytes(name).length == 0, "Name can only be set once");
        name = newName;
    }

    function setSymbol(string memory newSymbol) public onlyOwner {
        require(bytes(symbol).length == 0, "Symbol can only be set once");
        symbol = newSymbol;
    }

    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    //
    //  Exposed Public Functions
    //

    // Minting function available to public addresses, meant to interface with minting dapp
    function publicMint(address to, uint256 mintAmount)
        public
        payable
        whenNotPaused
        mintCompliance(mintAmount)
    {
        require(msg.value >= mintingCost * mintAmount, "Insufficient funds!");
        if (mintAmount == 1) {
            tokenIds.increment();
            _mint(to, tokenIds.current(), 1, "");
        } else if (mintAmount > 1) {
            uint256[] memory ids = new uint256[](mintAmount);
            uint256[] memory amounts = new uint256[](mintAmount);
            for (uint256 i = 0; i < mintAmount; i++) {
                tokenIds.increment();
                ids[i] = tokenIds.current();
                amounts[i] = 1;
            }
            _mintBatch(to, ids, amounts, "");
        }
    }

    function currentSupply() public view returns (uint256) {
        return tokenIds.current();
    }

    // Returns uri of token id, for fetching metaData on OpenSea
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        returns (string memory)
    {
        require(exists(_tokenId), "ERC1155: URI query for nonexistent token");

        if (hidden) {
            return string(abi.encodePacked(uri(0), "hidden.json"));
        }

        return
            string(
                abi.encodePacked(
                    uri(_tokenId),
                    Strings.toString(_tokenId),
                    ".json"
                )
            );
    }
}
