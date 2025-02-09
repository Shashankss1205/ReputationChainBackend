// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ReputationToken.sol"; // Import the Reputation token contract

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Main Platform Contract
contract DeSciPlatform {
    ReputationToken public reputationToken;
    
    struct Researcher {
        string name;
        string credentials;
        uint256 reputationScore;
        bool isVerified;
        address walletAddress;
    }
    
    struct Publication {
        uint256 id;
        address author;
        string title;
        string contentHash;
        uint256 upvotes;
        mapping(address => bool) hasVoted;
    }
    
    mapping(address => Researcher) public researchers;
    mapping(uint256 => Publication) public publications;
    uint256 public publicationCount;
    
    event ResearcherRegistered(address indexed researcher, string name);
    event PublicationSubmitted(uint256 indexed id, address indexed author, string title);
    event PublicationUpvoted(uint256 indexed id, address indexed voter);
    
    constructor(address _reputationToken) {
        reputationToken = ReputationToken(_reputationToken);
    }
    
    function registerResearcher(
        string memory _name,
        string memory _credentials
    ) public {
        require(researchers[msg.sender].walletAddress == address(0), "Already registered");
        
        researchers[msg.sender] = Researcher({
            name: _name,
            credentials: _credentials,
            reputationScore: 0,
            isVerified: false,
            walletAddress: msg.sender
        });
        
        emit ResearcherRegistered(msg.sender, _name);
    }
    
    function submitPublication(
        string memory _title,
        string memory _contentHash
    ) public {
        require(researchers[msg.sender].walletAddress != address(0), "Not registered");
        
        uint256 newPublicationId = publicationCount++;
        Publication storage newPublication = publications[newPublicationId];
        newPublication.id = newPublicationId;
        newPublication.author = msg.sender;
        newPublication.title = _title;
        newPublication.contentHash = _contentHash;
        newPublication.upvotes = 0;
        
        // Award initial reputation for publishing
        updateReputation(msg.sender, 10);
        
        emit PublicationSubmitted(newPublicationId, msg.sender, _title);
    }
    
    function upvotePublication(uint256 _publicationId) public {
        require(researchers[msg.sender].walletAddress != address(0), "Not registered");
        require(!publications[_publicationId].hasVoted[msg.sender], "Already voted");
        
        Publication storage publication = publications[_publicationId];
        publication.upvotes += 1;
        publication.hasVoted[msg.sender] = true;
        
        // Award reputation to the author
        updateReputation(publication.author, 1);
        
        emit PublicationUpvoted(_publicationId, msg.sender);
    }
    
    function updateReputation(address _researcher, uint256 _points) internal {
        researchers[_researcher].reputationScore += _points;
        reputationToken.mint(_researcher, _points * 1e18); // 1 token per point
    }
    
    function getResearcherDetails(address _researcher) public view returns (
        string memory name,
        string memory credentials,
        uint256 reputationScore,
        bool isVerified
    ) {
        Researcher memory researcher = researchers[_researcher];
        return (
            researcher.name,
            researcher.credentials,
            researcher.reputationScore,
            researcher.isVerified
        );
    }
}
