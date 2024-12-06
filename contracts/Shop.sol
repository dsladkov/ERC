// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ShopToken} from "./ShopToken.sol";
import "./Errors.sol";

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

        bytes32 uid;
        mapping( bytes32  => Item item ) public items;
        bytes32[] public uniqueIds;

        mapping(address buyer => BoughtItem[]) public buyers;


        ShopToken public stk;

        address public owner;

        modifier onlyOwner() {
            require(msg.sender == owner, Errors.NotAnOwner(msg.sender));
            _;
        }

        constructor(address _stk) {
            owner = msg.sender;
            stk = ShopToken(_stk);
        }

        function addItem(uint _price, uint _quantity, string calldata _name) external onlyOwner returns(bytes32) {
            uid = keccak256(abi.encode(_price, _name));
            items[uid] = Item({price: _price, quantity: _quantity, name: _name, exists: true});
            uniqueIds.push(uid);
            return uid;
        }

        function buy(bytes32 _uid, uint _numOfItems, string calldata _address) external {
            Item storage itemToBuy = items[_uid];
            uint256 quantity = itemToBuy.quantity;
            bool exists = itemToBuy.exists;
            require(exists, Errors.ItemIsOutOfStock());
            require(quantity >= _numOfItems, Errors.InsufficientItemQuantity(quantity, _numOfItems));

            //buyer should set allowance for totalPrice in stk token before buyng item< otherwise transferFrom shouldn't be possible
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
                if(i >= totalItems) break;

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