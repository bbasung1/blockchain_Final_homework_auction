// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./NFT.sol";

contract Auction {
    NFT public nftContract;
    address public admin;

    struct AuctionItem {
        uint256 tokenId;
        address payable seller;
        uint256 startPrice;
        uint256 highestBid;
        address payable highestBidder;
        uint256 endTime;
        bool ended;
    }

    mapping(uint256 => AuctionItem) public auctions;                        // auctionId => AuctionItem
    mapping(uint256 => mapping(address => uint256)) public pendingReturns;  // 환불 대기
    uint256 public nextAuctionId = 1;

    event AuctionCreated(uint256 auctionId, uint256 tokenId, address seller, uint256 startPrice, uint256 endTime);
    event BidPlaced(uint256 auctionId, address bidder, uint256 amount);
    event AuctionEnded(uint256 auctionId, address winner, uint256 amount);
    event AuctionCancelled(uint256 auctionId, address seller);
    event Refunded(uint256 auctionId, address bidder, uint256 amount);

    constructor(address nftAddress) {
        nftContract = NFT(nftAddress);
        admin = msg.sender;
    }

    // 경매 등록 (판매자)
    function createAuction(
        uint256 tokenId,
        uint256 startPrice,
        uint256 durationSeconds
    ) public returns (uint256) {
        require(nftContract.ownerOf(tokenId) == msg.sender, "Not NFT owner");
        require(nftContract.approved(tokenId) == address(this), "Auction not approved");

        uint256 auctionId = nextAuctionId++;
        auctions[auctionId] = AuctionItem({
            tokenId: tokenId,
            seller: payable(msg.sender),
            startPrice: startPrice,
            highestBid: 0,
            highestBidder: payable(address(0)),
            endTime: block.timestamp + durationSeconds,
            ended: false
        });

        emit AuctionCreated(auctionId, tokenId, msg.sender, startPrice, block.timestamp + durationSeconds);
        return auctionId;
    }

    // 입찰 (구매자)
    function bid(uint256 auctionId) public payable {
        AuctionItem storage auction = auctions[auctionId];
        require(block.timestamp < auction.endTime, "Auction ended");
        require(!auction.ended, "Already ended");
        require(msg.value > auction.highestBid, "Bid too low");
        require(msg.value >= auction.startPrice, "Below start price");

        // 이전 최고 입찰자 환불 대기 등록
        if (auction.highestBidder != address(0)) {
            pendingReturns[auctionId][auction.highestBidder] += auction.highestBid;
        }

        auction.highestBid = msg.value;
        auction.highestBidder = payable(msg.sender);

        emit BidPlaced(auctionId, msg.sender, msg.value);
    }

    // 경매 종료 및 낙찰 처리
    function endAuction(uint256 auctionId) public {
        AuctionItem storage auction = auctions[auctionId];
        require(block.timestamp >= auction.endTime, "Not yet ended");
        require(!auction.ended, "Already ended");

        auction.ended = true;

        if (auction.highestBidder != address(0)) {
            // NFT를 낙찰자에게 전송
            nftContract.transferFrom(auction.seller, auction.highestBidder, auction.tokenId);
            // 낙찰금을 판매자에게 전송
            auction.seller.transfer(auction.highestBid);
        }

        emit AuctionEnded(auctionId, auction.highestBidder, auction.highestBid);
    }

    // 경매 강제 취소 (판매자 전용)
    function cancelAuction(uint256 auctionId) public {
        AuctionItem storage auction = auctions[auctionId];
        require(msg.sender == auction.seller, "Not seller");
        require(!auction.ended, "Already ended");
        require(block.timestamp < auction.endTime, "Auction already expired");

        auction.ended = true;

        // 최고 입찰자가 있으면 즉시 환불
        if (auction.highestBidder != address(0)) {
            address payable refundTo = auction.highestBidder;
            uint256 refundAmount = auction.highestBid;
            auction.highestBid = 0;
            auction.highestBidder = payable(address(0));
            refundTo.transfer(refundAmount);
        }

        emit AuctionCancelled(auctionId, msg.sender);
    }

    // 환불 (낙찰 실패한 입찰자)
    function withdraw(uint256 auctionId) public {
        uint256 amount = pendingReturns[auctionId][msg.sender];
        require(amount > 0, "Nothing to withdraw");

        pendingReturns[auctionId][msg.sender] = 0;
        payable(msg.sender).transfer(amount);

        emit Refunded(auctionId, msg.sender, amount);
    }
}
