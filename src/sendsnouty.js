const { Web3 } = require("web3");

const args = process.argv.slice(2);
// args[0] -> eth rpc url
// args[1] -> deployer address
// args[2] -> deployed contract address
// args[3] -> action ("transfer" or "mint")
// args[4] -> to address (recipient)
// args[5] -> amount

const rpcUrl = args[0]; // ETH RPC URL ex -> "http://127.0.0.1:30371"
if (!rpcUrl) {
  console.error("Error: Please provide an ETH RPC URL as an argument.");
  process.exit(1);
}

const deployer = args[1];
if (!deployer) {
  console.error("Error: Please provide the deployer address as an argument.");
  process.exit(1);
}

const deployedTo = args[2];
if (!deployedTo) {
  console.error("Error: Please provide the deployed contract address as an argument.");
  process.exit(1);
}

const web3 = new Web3(rpcUrl);
const privateKey = "0x12d7de8621a77640c9241b2595ba78ce443d05e94090365ab3bb5e19df82c625";
const account = web3.eth.accounts.privateKeyToAccount(privateKey);
const fromAddress = account.address;

const action = args[3] || "transfer";
if (action !== "transfer" && action !== "mint") {
  console.error("Error: Action must be either 'transfer' or 'mint'.");
  process.exit(1);
}

// Recipient address
const toAddress = args[4]; 
if (!toAddress) {
  console.error("Error: Please provide a recipient address.");
  process.exit(1);
}

// Amount
const valueWei = web3.utils.toWei(args[5] || '1000', 'ether');

// This is the ABI for SnoutyCoin with transfer and mint functions
const snoutyCoinABI = [
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "to",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "value",
        "type": "uint256"
      }
    ],
    "name": "transfer",
    "outputs": [
      {
        "internalType": "bool",
        "name": "",
        "type": "bool"
      }
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "to",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "amount",
        "type": "uint256"
      }
    ],
    "name": "mint",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "constant": true,
    "inputs": [
      {
        "name": "_owner",
        "type": "address"
      }
    ],
    "name": "balanceOf",
    "outputs": [
      {
        "name": "balance",
        "type": "uint256"
      }
    ],
    "payable": false,
    "type": "function"
  },
];

// Create contract instance
const snoutyContract = new web3.eth.Contract(snoutyCoinABI, deployedTo);

let nonceHex;
let chainIdHex;

async function sendSnoutyCoin() {
  try {
    console.log("SnoutyCoin Transaction");
    console.log("----------------------");
    console.log("ETH RPC URL:", rpcUrl);
    console.log("Deployer Address:", deployer);
    console.log("SnoutyCoin Contract Address:", deployedTo);
    console.log("From Address:", fromAddress);
    console.log("Action:", action);
    console.log("To Address:", toAddress);
    console.log("Amount (Wei):", valueWei);
    
    nonceHex = await web3.eth.getTransactionCount(fromAddress, 'latest');
    chainIdHex = await web3.eth.getChainId();

    const gasPrice = await web3.eth.getGasPrice(); 
    const gasPriceHex = web3.utils.toHex(gasPrice);

    let senderBal = web3.utils.fromWei(await getTokenBalance(fromAddress), 'ether');
    let receiverBal = web3.utils.fromWei(await getTokenBalance(toAddress), 'ether');

    console.log("Sender Balance: "+ senderBal)
    console.log("Receiver Bal: " + receiverBal)
    
    // Create transaction data based on action
    let transactionData;
    if (action === "transfer") {
      transactionData = snoutyContract.methods.transfer(toAddress, valueWei).encodeABI();
      console.log("Preparing transfer transaction...");
    } else if (action === "mint") {
      transactionData = snoutyContract.methods.mint(toAddress, valueWei).encodeABI();
      console.log("Preparing mint transaction (requires owner privileges)...");
    }
    
    // Higher gas limit for token transfers
    const gasLimitHex = web3.utils.toHex(100000);

    const txParams = {
      nonce: web3.utils.toHex(nonceHex),
      gasPrice: gasPriceHex,
      gasLimit: gasLimitHex,
      to: deployedTo, // Send to the contract address
      value: '0x0',  // No ETH/native currency being sent
      data: transactionData, // The encoded function call
      chainId: web3.utils.toHex(chainIdHex),
    };

    const signedTx = await account.signTransaction(txParams);
    const rawTx = signedTx.rawTransaction;

    console.log('Raw Transaction:', rawTx);

    const receipt = await web3.eth.sendSignedTransaction(rawTx);
    console.log('Transaction Receipt:', receipt);

    senderBal = web3.utils.fromWei(await getTokenBalance(fromAddress), 'ether');
    receiverBal = web3.utils.fromWei(await getTokenBalance(toAddress), 'ether');

    console.log("After transfer Sender Balance: "+ senderBal)
    console.log("After transfer Receiver Bal: " + receiverBal)

    console.log(`SnoutyCoin ${action} successful!`);

  } catch (error) {
    console.error(`Error sending SnoutyCoin ${action} transaction:`, error);
  }
}

async function getTokenBalance(walletAddress) {
    return await snoutyContract.methods.balanceOf(walletAddress).call();
}

sendSnoutyCoin();