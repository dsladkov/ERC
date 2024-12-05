// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ShopToken} from "./ShopToken.sol";

    struct Item {
        uint256 price;
        uint256 quantity;
        string name;
        bool exists;
    }

    struct ItemsInStock {
        bytes32 uid;
        uint256 price;
        uint256 quantity;
        string name;
    }

    struct BoughtItem {
        bytes32 uniqueId;
        uint256 numOfPurchasedItems;
        string deliveryAddress;
    }

    contract Shop {

        mapping(bytes32 => Item) public items;
        bytes32[] public uniqueIds;

        mapping(address buyer => BoughtItem[]) public buyers;


        ShopToken public stk;

        address public owner;

        modifier onlyOwner() {
            require(msg.sender == owner, "Not an owner");
            _;
        }

        constructor(address _stk) {
            owner = msg.sender;
            stk = ShopToken(_stk);
        }

        function addItem(uint _price, uint _quantity, string calldata _name) external onlyOwner returns(bytes32 uid) {
            uid = keccak256(abi.encode(_price, _name));
            uniqueIds.push(uid);
            items[uid] = Item({price: _price, quantity: _quantity, name: _name, exists: true});
        }

        function buy(bytes32 _uid, uint _numOfItems, string calldata _address) external {
            Item storage itemToBuy = items[_uid];
            uint256 quantity = itemToBuy.quantity;
            bool exists = itemToBuy.exists;
            require(exists && quantity >= _numOfItems);

            uint256 totalPrice = _numOfItems * itemToBuy.price;

            stk.transferFrom(msg.sender, address(this), totalPrice);

            itemToBuy.quantity -= _numOfItems;

            buyers[msg.sender].push(BoughtItem({uniqueId: _uid, numOfPurchasedItems: _numOfItems, deliveryAddress: _address}));
        }

        // Pagination
        function avaiableItems(uint _page, uint _count) external view returns(ItemsInStock[] memory) {
            require(_page > 0 && _count > 0 );
            uint totalItems = uniqueIds.length;

            ItemsInStock[] memory stockItems = new ItemsInStock[](_count);

            uint counter;

            for(uint i = _count * _page - _count; i < _count * _page; ++i) {
                if(i >= totalItems) break ;

                bytes32 currentUid = uniqueIds[i];

                Item memory currentItem = items[currentUid];

                stockItems[counter] = ItemsInStock({
                    uid: currentUid,
                    price: currentItem.price,
                    quantity: currentItem.quantity,
                    name: currentItem.name
                });

                ++counter;
            }
            return stockItems;
        }
}