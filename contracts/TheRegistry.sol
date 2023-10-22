// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@sismo-core/sismo-connect-solidity/contracts/SismoConnectLib.sol";
import "@tableland/evm/contracts/utils/TablelandDeployments.sol";
import "@tableland/evm/contracts/utils/SQLHelpers.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract TheRegistry is SismoConnect, ERC721Holder {
    bytes16 private _appId = 0xd6e0a23df3d426bf3b5f232ff4c69058;
    uint256 public issuerTableId;
    uint256 public docTableId;
    uint256 public requestsTableId;
    string private constant _ISSUERS_PREFIX = "issuers";
    string private constant _DOCUMENTS_PREFIX = "documents";
    string private constant _REQUESTS_PREFIX = "requests";
    bool private _isImpersonationMode = true;

    constructor() SismoConnect(buildConfig(_appId, _isImpersonationMode)) {
      // Create a new issuers table to store issuer details
      issuerTableId = TablelandDeployments.get().create(
        address(this),
        SQLHelpers.toCreateFromSchema(
          "id integer primary key," // Notice the trailing comma
          "name text,"
          "website text,"
          "description text,"
          "image text,"
          "twitter text",
          _ISSUERS_PREFIX
        ));

      // Create a new documents table to store the cid and metadata of the documents
      docTableId = TablelandDeployments.get().create(
        address(this),
        SQLHelpers.toCreateFromSchema(
          "id integer primary key," // Notice the trailing comma
          "title text,"
          "receiver text,"
          "cid text,"
          "twitter text",
          _DOCUMENTS_PREFIX
        ));

      // Create a new requests table to store user requests for documents from issuers
      requestsTableId = TablelandDeployments.get().create(
        address(this),
        SQLHelpers.toCreateFromSchema(
          "id integer primary key," // Notice the trailing comma
          "encryptedEmail text,"
          "cipher text,"
          "userAddress text,"
          "issuerId text",
          _REQUESTS_PREFIX
        ));
    }

    // Create a new issuer for the dApp
    function createIssuer(
        bytes memory sismoConnectResponse,
        string memory name,
        string memory website,
        string memory description,
        string memory image
    ) public {
        SismoConnectVerifiedResult memory result = verify({
            responseBytes: sismoConnectResponse,
            // we want users to prove that they own a Twitter account
            // we are recreating the auth request made in the frontend to be sure that
            // the proofs provided in the response are valid with respect to this auth request
            auth: buildAuth({authType: AuthType.TWITTER})
        });

        uint256 twitterId = SismoConnectHelper.getUserId(
            result,
            AuthType.TWITTER
        );

        // Create a new issuer by inserting their details into the issuers table
        TablelandDeployments.get().mutate(
          address(this),
          issuerTableId,
          SQLHelpers.toInsert(
            _ISSUERS_PREFIX,
            issuerTableId,
            "name,website,description,image,twitter",
            string.concat(
              SQLHelpers.quote(name),
              ",",
              SQLHelpers.quote(website),
              ",",
              SQLHelpers.quote(description),
              ",",
              SQLHelpers.quote(image),
              ",",
              SQLHelpers.quote(Strings.toHexString(twitterId)) // Wrap strings in single quotes with the `quote` method
            )
          )
        );
    }

    // Create a new document for the dApp
    function uploadDocument(
        bytes memory sismoConnectResponse,
        string memory title,
        string memory cid,
        address receiver
    ) public {
        SismoConnectVerifiedResult memory result = verify({
            responseBytes: sismoConnectResponse,
            // we want users to prove that they own a Twitter account
            // we are recreating the auth request made in the frontend to be sure that
            // the proofs provided in the response are valid with respect to this auth request
            auth: buildAuth({authType: AuthType.TWITTER})
        });

        uint256 twitterId = SismoConnectHelper.getUserId(
            result,
            AuthType.TWITTER
        );

        // Create a new issuer by inserting their details into the issuers table
        TablelandDeployments.get().mutate(
          address(this),
          docTableId,
          SQLHelpers.toInsert(
            _DOCUMENTS_PREFIX,
            docTableId,
            "title,receiver,cid,twitter",
            string.concat(
              SQLHelpers.quote(title),
              ",",
              SQLHelpers.quote(Strings.toHexString(receiver)),
              ",",
              SQLHelpers.quote(cid),
              ",",
              SQLHelpers.quote(Strings.toHexString(twitterId)) // Wrap strings in single quotes with the `quote` method
            )
          )
        );
    }

    // Create a new request
    function requestDocument(
        string memory encryptedEmail,
        string memory cipher,
        string memory issuerId,
        address userAddress
    ) public {
        // Create a new issuer by inserting their details into the issuers table
        TablelandDeployments.get().mutate(
          address(this),
          requestsTableId,
          SQLHelpers.toInsert(
            _REQUESTS_PREFIX,
            requestsTableId,
            "encryptedEmail,cipher,userAddress,issuerId",
            string.concat(
              SQLHelpers.quote(encryptedEmail),
              ",",
              SQLHelpers.quote(cipher),
              ",",
              SQLHelpers.quote(Strings.toHexString(userAddress)),
              ",",
              SQLHelpers.quote(issuerId)
            )
          )
        );
    }
}
