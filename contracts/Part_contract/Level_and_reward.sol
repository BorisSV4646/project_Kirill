// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "./ERC721_suit_unlimited.sol";

/* 
       ?2. Чтобы можно было поставить рейтинг участнику, сделать систему рейтинга
       ?6. Продумать про вывод средств с контракта, кто и как может выводить
    */

contract Level_revard {
    address private immutable _contracttoken;

    struct Level {
        uint256 color;
        uint256 fashion;
        uint256 endurance;
        uint256 reloaded;
        uint256 level;
    }

    mapping(uint256 => mapping(uint256 => CounterMeet)) private meetCount;

    struct CounterMeet {
        uint256 meet;
    }

    mapping(uint256 => Level) public suitoption;

    event Responce(bytes responce);
    event NewLevel(address owner, uint256 tokenid);

    constructor(address contracttoken_) {
        _contracttoken = contracttoken_;
    }

    // как убрать в отрицательную сторону или просто сделать сотни
    function _cafReward(
        address owner,
        uint256 user_tokenid,
        address invited_people,
        uint256 invited_tokenid,
        uint256 who_invate
    ) internal returns (uint256) {
        Level memory user = suitoption[user_tokenid];
        Level memory invited = suitoption[invited_tokenid];
        uint meet_count = _showMeetCount(user_tokenid, invited_tokenid);
        uint256 ratio;
        if (user.level < invited.level) {
            ratio = 20;
        } else if (user.level == invited.level) {
            ratio = 10;
        } else if (user.level > invited.level) {
            ratio = 5;
        }

        if (who_invate == 1) {
            ratio += 5;
        } else {
            ratio += 0;
        }

        if (meet_count > 0 && meet_count <= 2) {
            ratio -= 5;
        } else if (meet_count > 2 && meet_count <= 5) {
            ratio -= 10;
        } else if (meet_count > 5 && meet_count <= 10) {
            ratio -= 20;
        }
    }

    function _cooldownTime(
        address owner,
        uint256 user_tokenid,
        uint256 invate_token
    ) internal returns (uint) {
        Level memory user = suitoption[user_tokenid];

        if (user.level == 1) {
            user.reloaded = 1 days;
        } else if (user.level == 2) {
            user.reloaded = 18 hours;
        } else if (user.level == 3) {
            user.reloaded = 12 hours;
        } else if (user.level == 4) {
            user.reloaded = 8 hours;
        } else if (user.level == 5) {
            user.reloaded = 6 hours;
        }

        return user.reloaded;
    }

    function _rewardToken(
        address owner,
        uint256 user_tokenid,
        address invited_people,
        uint256 invited_tokenid,
        uint256 who_invate,
        uint256 meet_count
    ) internal {
        uint256 ratio_owner = _cafReward(
            owner,
            user_tokenid,
            invited_people,
            invited_tokenid,
            who_invate
        );
        uint256 ratio_invited = _cafReward(
            invited_people,
            invited_tokenid,
            owner,
            user_tokenid,
            who_invate
        );
        uint256 amount_owner = 10 * ratio_owner;
        (bool success_owner, bytes memory responce_owner) = _contracttoken.call(
            abi.encodeWithSignature(
                "_mint(address,uint256)",
                owner,
                amount_owner
            )
        );
        require(success_owner, "Cant sent reward");

        emit Responce(success_owner);

        uint256 amount_invited = 10 * ratio_invited;
        (bool success_invited, bytes memory responce_invited) = _contracttoken
            .call(
                abi.encodeWithSignature(
                    "_mint(address,uint256)",
                    invited_people,
                    amount_invited
                )
            );
        require(success_invited, "Cant sent reward");

        emit Responce(success_invited);
    }

    function _setMeetCount(
        uint256 user_tokenid,
        uint256 invited_tokenid
    ) internal {
        CounterMeet storage counterMeetUser = meetCount[user_tokenid][
            invited_tokenid
        ];
        CounterMeet storage counterMeetInvite = meetCount[invited_tokenid][
            user_tokenid
        ];
        counterMeetUser.meet++;
        counterMeetInvite.meet++;

        require(
            counterMeetUser.meet == counterMeetInvite.meet,
            "Different meet"
        );
    }

    function _showMeetCount(
        uint256 user_tokenid,
        uint256 invited_tokenid
    ) internal returns (uint) {
        CounterMeet storage counterMeetUser = meetCount[user_tokenid][
            invited_tokenid
        ];
        CounterMeet storage counterMeetInvite = meetCount[invited_tokenid][
            user_tokenid
        ];

        require(
            counterMeetUser.meet == counterMeetInvite.meet,
            "Different meet"
        );

        return counterMeetUser.meet;
    }

    // if who_invate == 1 - You invite people, if == 0, people invite you
    function _ckeckMeet(
        uint256 user_tokenid,
        uint256 invited_tokenid,
        uint256 who_invate
    ) internal {
        Level storage user = suitoption[user_tokenid];
        Level storage invited = suitoption[invited_tokenid];

        if (who_invate == 1) {
            require(
                user.level == invited.level || user.level == invited.level - 1,
                "Not enouth level to meet"
            );
        } else if (who_invate == 0) {
            require(
                user.level == invited.level || user.level == invited.level + 1,
                "Not enouth level to meet"
            );
        }

        uint meet_count = meetCount[user_tokenid][invited_tokenid];
        if (meet_count == 1) {
            user.reloaded += 1 days;
            invited.reloaded += 1 days;
        } else if (meet_count == 2) {
            user.reloaded += 36 hours;
            invited.reloaded += 36 hours;
        } else if (meet_count == 3) {
            user.reloaded += 2 days;
            invited.reloaded += 2 days;
        } else if (meet_count == 4) {
            user.reloaded += 3 days;
            invited.reloaded += 3 days;
        } else if (meet_count > 4) {
            user.reloaded += 5 days;
            invited.reloaded += 5 days;
        }

        require(block.timestamp >= user.reloaded, "Too early for user");
        require(block.timestamp >= invited.reloaded, "Too early for invited");
    }

    // TODO: сделать просто добавление пользователю очка, за которое он может прокачать одну из трех характеристик
    // ?сделать изменение картинки (uri) токена в зависимости от уровня
    function addLevelAndRewardForMeet(
        address owner,
        uint256 tokenid,
        address invited_people,
        uint256 invited_tokenid,
        uint256 who_invate,
        uint256 meet_count
    ) external {
        Level storage user = suitoption[tokenid];
        Level storage invited = suitoption[invited_tokenid];

        user.reloaded = uint32(block.timestamp + _cooldownTime(owner, tokenid));

        invited.reloaded = uint32(
            block.timestamp + _cooldownTime(invited_people, invited_tokenid)
        );

        _ckeckMeet(tokenid, invited_tokenid, who_invate);

        user.color++;
        user.endurance++;
        user.fashion++;
        invited.color++;
        invited.endurance++;
        invited.fashion++;

        uint256 suntolevel = user.color + user.fashion + user.endurance;
        if (suntolevel >= 10 && suntolevel < 20) {
            user.level = 2;
        } else if (suntolevel >= 20 && suntolevel < 30) {
            user.level = 3;
        } else if (suntolevel >= 30 && suntolevel < 40) {
            user.level = 4;
        } else if (suntolevel >= 40 && suntolevel < 50) {
            user.level = 5;
        }

        uint256 suntolevel_invited = invited.color +
            invited.fashion +
            invited.endurance;
        if (suntolevel_invited >= 10 && suntolevel_invited < 20) {
            invited.level = 2;
        } else if (suntolevel_invited >= 20 && suntolevel_invited < 30) {
            invited.level = 3;
        } else if (suntolevel_invited >= 30 && suntolevel_invited < 40) {
            invited.level = 4;
        } else if (suntolevel_invited >= 40 && suntolevel_invited < 50) {
            invited.level = 5;
        }

        _rewardToken(owner, tokenid);

        _rewardToken(invited_people, invited_tokenid);

        emit NewLevel(owner, tokenid);

        emit NewLevel(invited_people, invited_tokenid);
    }

    function _priceForUpgrade(
        address owner,
        uint tokenid
    ) internal view returns (uint256) {
        Level memory user = suitoption[tokenid];
        uint memory amountToUpgrade;

        // Проверить корректность работы цикла
        for (uint i = 1; i < 50; i++) {
            if (user.color <= i) {
                amountToUpgrade += 100000000000000000; //0.001 ETH;
            }
        }
        // Проверить корректность работы цикла
        for (uint j = 1; j < 5; j++) {
            if (user.level <= j) {
                amountToUpgrade += 300000000000000000; //0.003 ETH;
            }
        }
    }

    function addLevelForApgrade(address owner, uint tokenid) external payable {
        Level storage user = suitoption[tokenid];
        uint price = _priceForUpgrade(owner, tokenid);
        require(msg.value >= price, "Not enough money");

        _payForApgrade(owner, price);

        user.color++;
        user.endurance++;
        user.fashion++;

        uint256 suntolevel = user.color + user.fashion + user.endurance;
        if (suntolevel >= 10 && suntolevel < 20) {
            user.level = 2;
        } else if (suntolevel >= 20 && suntolevel < 30) {
            user.level = 3;
        } else if (suntolevel >= 30 && suntolevel < 40) {
            user.level = 4;
        } else if (suntolevel >= 40 && suntolevel < 50) {
            user.level = 5;
        }

        emit NewLevel(owner, tokenid);
    }

    function _payForApgrade(address account, uint256 amount) internal {
        (bool success, bytes memory responce) = _contracttoken.call(
            abi.encodeWithSignature("_burn(address,uint256)", account, amount)
        );
        require(success, "Cant spend token");

        emit Responce(responce);
    }
}
