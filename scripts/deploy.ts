import hre, {ethers} from "hardhat";

async function main() {
  const [signer] = await ethers.getSigners();
  
  const ShopToken = await ethers.getContractFactory("ShopToken");
  const stk = await ShopToken.deploy(signer.address);
  await stk.waitForDeployment();

  const TokenExchange = await ethers.getContractFactory("TokenExchange");
  const exch = await TokenExchange.deploy(stk.target);
  await exch.waitForDeployment();

  console.log(`Token: ${stk.target}`);
  console.log(`Exchange: ${exch.target}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.log(error);
    process.exit(1);
  })