import { ShopToken } from "../typechain-types/";

async function withDecimals(stk: ShopToken, value: bigint): Promise<bigint> {
  return value * 10n ** await stk.decimals();
}

export {withDecimals};