pragma solidity ^0.4.0;
import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";

contract ETHUSDPriceTicker is usingOraclize {

    string public ETHUSD;

    event newOraclizeQuery(string description);
    event newKrakenPriceTicker(string price);


    function KrakenPriceTicker() {
        oraclize_setProof(proofType_TLSNotary | proofStorage_IPFS);
        update();
    }

    function __callback(bytes32 myid, string result, bytes proof) {
        if (msg.sender != oraclize_cbAddress()) throw;
        ETHUSD = result;
        newKrakenPriceTicker(ETHUSD);
        update();
    }

    function update() payable {
        if (oraclize.getPrice("URL") > this.balance) {
            newOraclizeQuery("Oraclize query was NOT sent, please add some ETH to cover for the query fee");
        } else {
            newOraclizeQuery("Oraclize query was sent, standing by for the answer..");
            oraclize_query(60, "URL", "json(https://api.kraken.com/0/public/Ticker?pair=ETHUSD).result.XETHZUSD.c.[0]");
        }
    }

}
