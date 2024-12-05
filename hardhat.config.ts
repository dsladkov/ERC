import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "dotenv/config";

const LOCALHOST = process.env.LOCAL_TEST_NETWORK_RPC_URL;

const config: HardhatUserConfig = {
  solidity: "0.8.27",
  networks: {
    localhost: {
      url: LOCALHOST,
      chainId: 31337,
      //gas: "auto",
      timeout: 10000,
      //initialBaseFeePerGas: 0
    },
    hardhat: {
      chainId: 31337,
      initialBaseFeePerGas: 0,
    },
  }
};

export default config;
