// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@sismo-core/sismo-connect-solidity/contracts/SismoConnectLib.sol";
import "@tableland/evm/contracts/utils/TablelandDeployments.sol";
import "@tableland/evm/contracts/utils/SQLHelpers.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Docissue is SismoConnect, ERC721Holder {
    bytes16 private _appId = 0xd6e0a23df3d426bf3b5f232ff4c69058;
    uint256 public issuerTableId;
    uint256 public docTableId;
    string private constant _TABLE_1_PREFIX = "issuers";
    string private constant _TABLE_2_PREFIX = "documents";
    // bool private _isImpersonationMode = true;

    constructor() SismoConnect(buildConfig(_appId)) {
      // Create a new issuers table to store issuer details
      issuerTableId = TablelandDeployments.get().create(
        address(this),
        SQLHelpers.toCreateFromSchema(
          "id integer primary key," // Notice the trailing comma

          "twitter text",
          _TABLE_1_PREFIX
        ));

      // Create a new documents table to store the cid and metadata of the documents
      docTableId = TablelandDeployments.get().create(
        address(this),
        SQLHelpers.toCreateFromSchema(
          "id integer primary key," // Notice the trailing comma
          "name text,"
          "cid text,",
          // "type int,",
          _TABLE_2_PREFIX
        ));
    }

    // Create a new issuer for the dApp
    function createIssuer(
        bytes memory sismoConnectResponse,
        string memory name,
        string memory website,
        string memory description
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
            _TABLE_1_PREFIX,
            issuerTableId,
            "id,name,website,description,twitter",
            string.concat(
              "1,",
              SQLHelpers.quote(name),
              ",",
              SQLHelpers.quote(website),
              ",",
              SQLHelpers.quote(description),
              ",",
              SQLHelpers.quote(Strings.toHexString(twitterId)) // Wrap strings in single quotes with the `quote` method
            )
          )
        );
    }

    // Create a new document for the dApp
    function uploadDocument(
        // bytes memory sismoConnectResponse,
        string memory title,
        string memory cid
        // int8 docType
    ) public {
        // SismoConnectVerifiedResult memory result = verify({
        //     responseBytes: sismoConnectResponse,
        //     // we want users to prove that they own a Twitter account
        //     // we are recreating the auth request made in the frontend to be sure that
        //     // the proofs provided in the response are valid with respect to this auth request
        //     auth: buildAuth({authType: AuthType.TWITTER})
        // });

        // uint256 twitterId = SismoConnectHelper.getUserId(
        //     result,
        //     AuthType.TWITTER
        // );

        // Create a new issuer by inserting their details into the issuers table
        TablelandDeployments.get().mutate(
          address(this),
          docTableId,
          SQLHelpers.toInsert(
            _TABLE_1_PREFIX,
            docTableId,
            "id,title,cid,docType",
            string.concat(
              "1,",
              SQLHelpers.quote(title),
              ",",
              SQLHelpers.quote(cid)
            //   ",",
              // docType,
              // ",",
            //   SQLHelpers.quote(Strings.toHexString(twitterId)) // Wrap strings in single quotes with the `quote` method
            )
          )
        );
    }
}
