import {Shop} from "../typechain-types";
import {time, loadFixture, hre, ethers, expect, anyValue, SignerWithAddress} from "./setup";
import { withDecimals } from "./helpers";

describe("Shop", function() {
  async function deploy() {
    const [owner, buyer] = await ethers.getSigners();

    const ShopToken = await ethers.getContractFactory("ShopToken");
    const stk = await ShopToken.deploy(owner);
    await stk.waitForDeployment();

    const Shop = await ethers.getContractFactory("Shop");
    const shop = await Shop.deploy(stk.target);
    await shop.waitForDeployment();

    return {stk, shop, owner, buyer};
  }

  it("should allow to buy", async function() {
    const {stk, shop, owner, buyer} = await loadFixture(deploy);

    //give tokens to buyer

    const tokenValue = 2n;
    const txResponse = await stk.connect(owner).transfer(buyer, await withDecimals(stk, tokenValue));
    await txResponse.wait();

    const priceItem = 1000n;
    const itemQuantity = 5n;
    const itemName = "TestItem";
    const txAddItem = await shop.connect(owner).addItem(priceItem, itemQuantity, itemName);
    await txAddItem.wait()

    const uidItem = await shop.uniqueIds(0);
    const numOfItems = 2n;
    const address = "TestAddress"
    const totalPrice = priceItem * numOfItems;

    //do approve for shop address
    const txApproveForShop = await stk.connect(buyer).approve(shop.target, totalPrice);
    await txApproveForShop.wait();

    const txBuyItem = await shop.connect(buyer).buy(uidItem, numOfItems, address);
    await txBuyItem.wait();

    await expect(txBuyItem).to.changeTokenBalances(stk, [shop.target, buyer.address], [totalPrice , -totalPrice]);

    //check that buyer allowance for shop is not equal to 0 
    expect(await stk.allowance(buyer.address, shop.target)).to.be.eq(0);

    const boughtItem = await shop.buyers(buyer.address, 0);
    
    expect(boughtItem.uniqueId).eq(uidItem);
    expect(boughtItem.deliveryAddress).eq(address);
    expect(boughtItem.numOfPurchasedItems).eq(numOfItems);


    //check that itmes is qeual to initial quantity - boughtQuantity items
    const item = await shop.items(uidItem);

    expect(item.exists).to.be.true;
    expect(item.name).eq(itemName);
    expect(item.quantity).eq(itemQuantity - numOfItems);
  })
});