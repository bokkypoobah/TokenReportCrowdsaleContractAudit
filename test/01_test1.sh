#!/bin/bash
# ----------------------------------------------------------------------------------------------
# Testing the smart contract
#
# Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2017. The MIT Licence.
# ----------------------------------------------------------------------------------------------

MODE=${1:-test}

GETHATTACHPOINT=`grep ^IPCFILE= settings.txt | sed "s/^.*=//"`
PASSWORD=`grep ^PASSWORD= settings.txt | sed "s/^.*=//"`

CONTRACTSDIR=`grep ^CONTRACTSDIR= settings.txt | sed "s/^.*=//"`

# --- Tokens ---
TOKENSOL=`grep ^TOKENSOL= settings.txt | sed "s/^.*=//"`
TOKENJS=`grep ^TOKENJS= settings.txt | sed "s/^.*=//"`

DEPLOYMENTDATA=`grep ^DEPLOYMENTDATA= settings.txt | sed "s/^.*=//"`

TEST1OUTPUT=`grep ^TEST1OUTPUT= settings.txt | sed "s/^.*=//"`
TEST1RESULTS=`grep ^TEST1RESULTS= settings.txt | sed "s/^.*=//"`

CURRENTTIME=`date +%s`
CURRENTTIMES=`date -r $CURRENTTIME -u`

if [ "$MODE" == "dev" ]; then
  # Start time now
  STARTTIME=`echo "$CURRENTTIME" | bc`
else
  # Start time 1m 10s in the future
  STARTTIME=`echo "$CURRENTTIME+75" | bc`
fi
STARTTIME_S=`date -r $STARTTIME -u`
ENDTIME=`echo "$CURRENTTIME+60*5" | bc`
ENDTIME_S=`date -r $ENDTIME -u`

printf "MODE              = '$MODE'\n" | tee $TEST1OUTPUT
printf "GETHATTACHPOINT   = '$GETHATTACHPOINT'\n" | tee -a $TEST1OUTPUT
printf "PASSWORD          = '$PASSWORD'\n" | tee -a $TEST1OUTPUT
printf "CONTRACTSDIR      = '$CONTRACTSDIR'\n" | tee -a $TEST1OUTPUT
printf "TOKENSOL          = '$TOKENSOL'\n" | tee -a $TEST1OUTPUT
printf "TOKENJS           = '$TOKENJS'\n" | tee -a $TEST1OUTPUT
printf "DEPLOYMENTDATA    = '$DEPLOYMENTDATA'\n" | tee -a $TEST1OUTPUT
printf "TEST1OUTPUT       = '$TEST1OUTPUT'\n" | tee -a $TEST1OUTPUT
printf "TEST1RESULTS      = '$TEST1RESULTS'\n" | tee -a $TEST1OUTPUT
printf "CURRENTTIME       = '$CURRENTTIME' '$CURRENTTIMES'\n" | tee -a $TEST1OUTPUT
printf "STARTTIME         = '$STARTTIME' '$STARTTIME_S'\n" | tee -a $TEST1OUTPUT
printf "ENDTIME           = '$ENDTIME' '$ENDTIME_S'\n" | tee -a $TEST1OUTPUT

# Make copy of SOL file and modify start and end times ---
`cp $CONTRACTSDIR/$TOKENSOL .`

# --- Modify dates ---
#`perl -pi -e "s/SOFTCAP_TIME \= 4 hours;/SOFTCAP_TIME \= 33 seconds;/" $SALESOL`
#`perl -pi -e "s/ENDDATE \= STARTDATE \+ 28 days;.*$/ENDDATE \= STARTDATE \+ 5 minutes;/" $DAOCASINOTOKENTEMPSOL`
#`perl -pi -e "s/CAP \= 84417 ether;.*$/CAP \= 100 ether;/" $DAOCASINOTOKENTEMPSOL`

DIFFS1=`diff $CONTRACTSDIR/$TOKENSOL $TOKENSOL`
echo "--- Differences $CONTRACTSDIR/$TOKENSOL $TOKENSOL ---" | tee -a $TEST1OUTPUT
echo "$DIFFS1" | tee -a $TEST1OUTPUT

solc_0.4.16 --version | tee -a $TEST1OUTPUT
echo "var tokenOutput=`solc_0.4.16 --optimize --combined-json abi,bin,interface $TOKENSOL`;" > $TOKENJS


geth --verbosity 3 attach $GETHATTACHPOINT << EOF | tee -a $TEST1OUTPUT
loadScript("$TOKENJS");
loadScript("functions.js");

var controllerAbi = JSON.parse(tokenOutput.contracts["$TOKENSOL:Controller"].abi);
var controllerBin = "0x" + tokenOutput.contracts["$TOKENSOL:Controller"].bin;
var ledgerAbi = JSON.parse(tokenOutput.contracts["$TOKENSOL:Ledger"].abi);
var ledgerBin = "0x" + tokenOutput.contracts["$TOKENSOL:Ledger"].bin;
var tokenAbi = JSON.parse(tokenOutput.contracts["$TOKENSOL:Token"].abi);
var tokenBin = "0x" + tokenOutput.contracts["$TOKENSOL:Token"].bin;

// console.log("DATA: controllerAbi=" + JSON.stringify(controllerAbi));
// console.log("DATA: controllerBin=" + controllerBin);
// console.log("DATA: ledgerAbi=" + JSON.stringify(ledgerAbi));
// console.log("DATA: ledgerBin=" + ledgerBin);
// console.log("DATA: tokenAbi=" + JSON.stringify(tokenAbi));
// console.log("DATA: tokenBin=" + tokenBin);

unlockAccounts("$PASSWORD");
printBalances();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var controllerMessage = "Deploy Controller Contract";
// -----------------------------------------------------------------------------
console.log("RESULT: " + controllerMessage);
var controllerContract = web3.eth.contract(controllerAbi);
// console.log(JSON.stringify(controllerContract));
var controllerTx = null;
var controllerAddress = null;

var controller = controllerContract.new({from: contractOwnerAccount, data: controllerBin, gas: 6000000},
  function(e, contract) {
    if (!e) {
      if (!contract.address) {
        controllerTx = contract.transactionHash;
      } else {
        controllerAddress = contract.address;
        addAccount(controllerAddress, "Controller Contract");
        addControllerContractAddressAndAbi(controllerAddress, controllerAbi);
        console.log("DATA: controllerAddress=" + controllerAddress);
      }
    }
  }
);

// -----------------------------------------------------------------------------
var ledgerMessage = "Deploy Ledger Contract";
// -----------------------------------------------------------------------------
console.log("RESULT: " + ledgerMessage);
var ledgerContract = web3.eth.contract(ledgerAbi);
// console.log(JSON.stringify(ledgerContract));
var ledgerTx = null;
var ledgerAddress = null;

var ledger = ledgerContract.new({from: contractOwnerAccount, data: ledgerBin, gas: 6000000},
  function(e, contract) {
    if (!e) {
      if (!contract.address) {
        ledgerTx = contract.transactionHash;
      } else {
        ledgerAddress = contract.address;
        addAccount(ledgerAddress, "Ledger Contract");
        addLedgerContractAddressAndAbi(ledgerAddress, ledgerAbi);
        console.log("DATA: ledgerAddress=" + ledgerAddress);
      }
    }
  }
);

// -----------------------------------------------------------------------------
var tokenMessage = "Deploy Token Contract";
// -----------------------------------------------------------------------------
console.log("RESULT: " + tokenMessage);
var tokenContract = web3.eth.contract(tokenAbi);
// console.log(JSON.stringify(tokenContract));
var tokenTx = null;
var tokenAddress = null;

var token = tokenContract.new({from: contractOwnerAccount, data: tokenBin, gas: 6000000},
  function(e, contract) {
    if (!e) {
      if (!contract.address) {
        tokenTx = contract.transactionHash;
      } else {
        tokenAddress = contract.address;
        addAccount(tokenAddress, "Token Contract");
        addTokenContractAddressAndAbi(tokenAddress, tokenAbi);
        console.log("DATA: tokenAddress=" + tokenAddress);
      }
    }
  }
);

while (txpool.status.pending > 0) {
}

printTxData("controllerAddress=" + controllerAddress, controllerTx);
printBalances();
failIfTxStatusError(controllerTx, controllerMessage);
printControllerContractDetails();
console.log("RESULT: ");

printTxData("ledgerAddress=" + ledgerAddress, ledgerTx);
printBalances();
failIfTxStatusError(ledgerTx, ledgerMessage);
printLedgerContractDetails();
console.log("RESULT: ");

printTxData("tokenAddress=" + tokenAddress, tokenTx);
printBalances();
failIfTxStatusError(tokenTx, tokenMessage);
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var stitchContractsMessage = "Stitch Controller, Ledger And Token Contracts";
// -----------------------------------------------------------------------------
console.log("RESULT: " + stitchContractsMessage);
var stitchContracts1Tx = controller.setToken(tokenAddress, {from: contractOwnerAccount, gas: 400000});
var stitchContracts2Tx = controller.setLedger(ledgerAddress, {from: contractOwnerAccount, gas: 400000});
var stitchContracts3Tx = token.setController(controllerAddress, {from: contractOwnerAccount, gas: 400000});
var stitchContracts4Tx = ledger.setController(controllerAddress, {from: contractOwnerAccount, gas: 400000});
while (txpool.status.pending > 0) {
}
// var stitchContracts5Tx = controller.setBurnAddress("0x1111111111111111111111111111111111111111", {from: contractOwnerAccount, gas: 400000});
// while (txpool.status.pending > 0) {
// }
printTxData("stitchContracts1Tx", stitchContracts1Tx);
printTxData("stitchContracts2Tx", stitchContracts2Tx);
printTxData("stitchContracts3Tx", stitchContracts3Tx);
printTxData("stitchContracts4Tx", stitchContracts4Tx);
// printTxData("stitchContracts5Tx", stitchContracts5Tx);
printBalances();
failIfTxStatusError(stitchContracts1Tx, stitchContractsMessage + " - controller.setToken(...)");
failIfTxStatusError(stitchContracts2Tx, stitchContractsMessage + " - controller.setLedger(...)");
failIfTxStatusError(stitchContracts3Tx, stitchContractsMessage + " - token.setController(...)");
failIfTxStatusError(stitchContracts4Tx, stitchContractsMessage + " - ledger.setController(...)");
// failIfTxStatusError(stitchContracts5Tx, stitchContractsMessage + " - controller.setBurnAddress(...)");
printControllerContractDetails();
printLedgerContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var mintMessage = "Mint Tokens";
var v1 = account3 + "000000000003f28cb71571c7";
var v2 = account4 + "000000000003f28cb71571c7";
// > new BigNumber("1111111111111111").toString(16)
// "3f28cb71571c7"
// -----------------------------------------------------------------------------
console.log("RESULT: " + mintMessage);
var mint1Tx = ledger.multiMint(0, [v1, v2], {from: contractOwnerAccount, gas: 400000});
while (txpool.status.pending > 0) {
}
printTxData("mint1Tx", mint1Tx);
printBalances();
failIfTxStatusError(mint1Tx, mintMessage + " - ac3 + ac4 11111111.11111111 tokens");
printControllerContractDetails();
printLedgerContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var mintingStoppedMessage = "Minting Stopped";
// -----------------------------------------------------------------------------
console.log("RESULT: " + mintingStoppedMessage);
var mintingStopped1Tx = ledger.stopMinting({from: contractOwnerAccount, gas: 400000});
while (txpool.status.pending > 0) {
}
printTxData("mintingStopped1Tx", mintingStopped1Tx);
printBalances();
failIfTxStatusError(mintingStopped1Tx, mintingStoppedMessage);
printControllerContractDetails();
printLedgerContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var transferMessage = "Transfer Tokens";
// -----------------------------------------------------------------------------
console.log("RESULT: " + transferMessage);
var transfer1Tx = token.transfer(account6, "100", {from: account3, gas: 100000});
var transfer2Tx = token.approve(account5,  "3000000", {from: account4, gas: 100000});
while (txpool.status.pending > 0) {
}
var transfer3Tx = token.transferFrom(account4, account7, "3000000", {from: account5, gas: 100000});
while (txpool.status.pending > 0) {
}
printTxData("transfer1Tx", transfer1Tx);
printTxData("transfer2Tx", transfer2Tx);
printTxData("transfer3Tx", transfer3Tx);
printBalances();
failIfTxStatusError(transfer1Tx, transferMessage + " - transfer 0.000001 tokens ac3 -> ac6. CHECK for movement");
failIfTxStatusError(transfer2Tx, transferMessage + " - approve 0.03 tokens ac4 -> ac5");
failIfTxStatusError(transfer3Tx, transferMessage + " - transferFrom 0.03 tokens ac4 -> ac7 by ac5. CHECK for movement");
printControllerContractDetails();
printLedgerContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var invalidTransferMessage = "Invalid Transfers";
// -----------------------------------------------------------------------------
console.log("RESULT: " + invalidTransferMessage);
var invalidTransfer1Tx = token.transfer(account7, "100", {from: account5, gas: 100000});
var invalidTransfer2Tx = token.approve(account8,  "3000000", {from: account6, gas: 100000});
while (txpool.status.pending > 0) {
}
var invalidTransfer3Tx = token.transferFrom(account6, account9, "3000000", {from: account8, gas: 100000});
while (txpool.status.pending > 0) {
}
printTxData("invalidTransfer1Tx", invalidTransfer1Tx);
printTxData("invalidTransfer2Tx", invalidTransfer2Tx);
printTxData("invalidTransfer3Tx", invalidTransfer3Tx);
printBalances();
failIfTxStatusError(invalidTransfer1Tx, invalidTransferMessage + " - invalidTransfer 0.000001 tokens ac3 -> ac6. CHECK for NO movement");
failIfTxStatusError(invalidTransfer2Tx, invalidTransferMessage + " - approve 0.03 tokens ac4 -> ac5");
failIfTxStatusError(invalidTransfer3Tx, invalidTransferMessage + " - invalidTransferFrom 0.03 tokens ac4 -> ac7 by ac5. CHECK for NO movement");
printControllerContractDetails();
printLedgerContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var zeroTransferMessage = "Zero Transfers";
// -----------------------------------------------------------------------------
console.log("RESULT: " + zeroTransferMessage);
var zeroTransfer1Tx = token.transfer(account7, "0", {from: account5, gas: 100000});
var zeroTransfer2Tx = token.approve(account8,  "0", {from: account6, gas: 100000});
while (txpool.status.pending > 0) {
}
var zeroTransfer3Tx = token.transferFrom(account6, account9, "0", {from: account8, gas: 100000});
while (txpool.status.pending > 0) {
}
printTxData("zeroTransfer1Tx", zeroTransfer1Tx);
printTxData("zeroTransfer2Tx", zeroTransfer2Tx);
printTxData("zeroTransfer3Tx", zeroTransfer3Tx);
printBalances();
failIfTxStatusError(zeroTransfer1Tx, zeroTransferMessage + " - transfer 0 tokens ac3 -> ac6. CHECK for NO movement");
failIfTxStatusError(zeroTransfer2Tx, zeroTransferMessage + " - approve 0 tokens ac4 -> ac5");
failIfTxStatusError(zeroTransfer3Tx, zeroTransferMessage + " - zeroTransferFrom 0 tokens ac4 -> ac7 by ac5. CHECK for NO movement");
printControllerContractDetails();
printLedgerContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


EOF
grep "DATA: " $TEST1OUTPUT | sed "s/DATA: //" > $DEPLOYMENTDATA
cat $DEPLOYMENTDATA
grep "RESULT: " $TEST1OUTPUT | sed "s/RESULT: //" > $TEST1RESULTS
cat $TEST1RESULTS
