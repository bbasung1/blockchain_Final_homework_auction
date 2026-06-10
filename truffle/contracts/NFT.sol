// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract NFT {
    // NFT 소유권 매핑
    mapping(uint256 => address) public ownerOf;
    mapping(address => uint256) public balanceOf;

    // NFT 메타데이터
    mapping(uint256 => string) public tokenURI;

    // 경매 컨트랙트에 대한 승인
    mapping(uint256 => address) public approved;

    uint256 public nextTokenId = 1;
    address public admin;

    event Transfer(address indexed from, address indexed to, uint256 tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 tokenId);
    event Minted(address indexed to, uint256 tokenId, string uri);

    constructor() {
        admin = msg.sender;
    }

    // NFT 발행 (판매자가 호출)
    function mint(address to, string memory uri) public returns (uint256) {
        uint256 tokenId = nextTokenId++;
        ownerOf[tokenId] = to;
        balanceOf[to]++;
        tokenURI[tokenId] = uri;

        emit Minted(to, tokenId, uri);
        emit Transfer(address(0), to, tokenId);
        return tokenId;
    }

    // 경매 컨트랙트에 NFT 사용 승인
    function approve(address to, uint256 tokenId) public {
        require(ownerOf[tokenId] == msg.sender, "Not owner");
        approved[tokenId] = to;
        emit Approval(msg.sender, to, tokenId);
    }

    // NFT 전송
    function transferFrom(address from, address to, uint256 tokenId) public {
        require(ownerOf[tokenId] == from, "Not owner");
        require(
            msg.sender == from || msg.sender == approved[tokenId],
            "Not authorized"
        );
        ownerOf[tokenId] = to;
        balanceOf[from]--;
        balanceOf[to]++;
        approved[tokenId] = address(0);

        emit Transfer(from, to, tokenId);
    }
}
