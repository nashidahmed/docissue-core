// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@sismo-core/sismo-connect-solidity/contracts/SismoConnectLib.sol";
import "@tableland/evm/contracts/utils/TablelandDeployments.sol";
import "@tableland/evm/contracts/utils/SQLHelpers.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Docissue is SismoConnect, ERC721Holder {
    event ResponseVerified(uint256 twitterId);

    bytes16 private _appId = 0xd6e0a23df3d426bf3b5f232ff4c69058;
    uint256 public tableId;
    string private constant _TABLE_PREFIX = "issuers";

    constructor() SismoConnect(buildConfig(_appId)) {
      tableId = TablelandDeployments.get().create(
        address(this),
        SQLHelpers.toCreateFromSchema(
          "id integer primary key," // Notice the trailing comma
          "twitter text",
          _TABLE_PREFIX
        ));
    }

    function createIssuer(
        bytes memory sismoConnectResponse
    ) public {
        SismoConnectVerifiedResult memory result = verify({
            responseBytes: sismoConnectResponse,
            // we want users to prove that they own a Sismo Vault
            // we are recreating the auth and claim requests made in the frontend to be sure that
            // the proofs provided in the response are valid with respect to this auth request
            auth: buildAuth({authType: AuthType.TWITTER})
        });

        uint256 twitterId = SismoConnectHelper.getUserId(
            result,
            AuthType.TWITTER
        );

        emit ResponseVerified(twitterId);
        TablelandDeployments.get().mutate(
          address(this),
          tableId,
          SQLHelpers.toInsert(
            _TABLE_PREFIX,
            tableId,
            "id,twitter",
            string.concat(
              "1"
              ",",
              SQLHelpers.quote(Strings.toString(twitterId)) // Wrap strings in single quotes with the `quote` method
            )
          )
        );
    }
}
