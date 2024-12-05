import { ShopToken } from "../typechain-types/";
import {time, loadFixture, hre, ethers, expect, anyValue, SignerWithAddress} from "./setup";
import { withDecimals } from "./helpers";

describe("TokenExchange", function() {
  async function deploy() {
    const [owner, buyer] = await ethers.getSigners();

    const ShopToken = await ethers.getContractFactory("ShopToken", owner);

    const stk = await ShopToken.deploy(owner.address);
    await stk.waitForDeployment();

    const TokenExchange = await ethers.getContractFactory("TokenExchange");

    const exch = await TokenExchange.deploy(stk.target)
    await exch.waitForDeployment();

    return {stk, exch, owner, buyer};
  }

  it("should allow to buy token", async function() {
    const {stk, exch, owner, buyer} = await loadFixture(deploy);

    const tokenInStock = 5n;
    const tokenWithDecimals = await withDecimals(stk, tokenInStock);

    const transferTx = await stk.transfer(exch.target, tokenWithDecimals);
    await transferTx.wait();

    expect(await  stk.balanceOf(exch.target)).eq(tokenWithDecimals);
    await expect(transferTx).to.changeTokenBalances(stk, [owner,exch], [-tokenWithDecimals, tokenWithDecimals]);


    const tokenToBuy = 1n;
    const value = ethers.parseEther(tokenToBuy.toString());

    //console.log(await  stk.balanceOf(exch.target));
    //console.log(await  stk.balanceOf(owner.address));
    
    const buyTx = await exch.connect(buyer).buy({value: value});

    await buyTx.wait();

    //console.log(buyTx);

    await expect(buyTx).to.changeEtherBalances([buyer,exch], [-value, value]);
    await expect(buyTx).to.changeTokenBalances(stk,[exch, buyer], [-value,value]);

  });

  it("should allow to sell token", async function() {
    const {stk, exch, owner, buyer} = await loadFixture(deploy);

    const ownedTokens = 2n;

    const tokenWithDecimals = await withDecimals(stk, ownedTokens);

    const transferTx = await stk.transfer(buyer.address,tokenWithDecimals);
    await transferTx.wait();

    console.log(`Buyer token balance: ${await stk.balanceOf(buyer.address)}`);

    const ethersTransfer = await ethers.parseEther(ownedTokens.toString());

    const topUpTx = await exch.topUp({value: ethers.parseEther("5")});

    await topUpTx.wait();

    console.log(`Exchange balance ETH: ${await ethers.provider.getBalance(exch.target)}`);

    const tokenToSell = 1n;
    const value = await ethers.parseEther(tokenToSell.toString());

    const approveTx = await stk.connect(buyer).approve(exch.target, value);
    await approveTx.wait();

    const sellTx = await exch.connect(buyer).sell(value);

    await sellTx.wait();
    await expect(sellTx).to.changeEtherBalances([exch, buyer], [-value, value]);
    await expect(sellTx).to.changeTokenBalances(stk, [exch, buyer], [value, -value]); 
  });

  it("should allow to execute topUp by owner only", async function() {
    const {stk, exch, owner, buyer} = await loadFixture(deploy);

    const value = await ethers.parseEther("1");
    const topUpTxByOwner = await exch.connect(owner).topUp({value: value});
    await topUpTxByOwner.wait()
    
    expect(topUpTxByOwner).changeEtherBalances([owner.address, exch.target], [-value, value]);

    const topUpTxByBuyer = exch.connect(buyer).topUp({value: value});
    //await topUpTxByBuyer.wait();

    await expect(topUpTxByBuyer).to.revertedWithCustomError(exch, "NotAnOwner").withArgs(buyer.address);

  });

  // async function withDecimals(stk: ShopToken, value: bigint): Promise<bigint> {
  //   return value * 10n ** await stk.decimals();
  // }
})