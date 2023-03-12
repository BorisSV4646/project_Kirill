// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LevelRevard {
    address private immutable _contracttoken;

    struct Level {
        uint256 color;
        uint256 fashion;
        uint256 endurance;
        uint256 reloaded;
        uint256 level;
    }

    struct CounterMeet {
        uint256 meet;
    }

    mapping(uint256 => mapping(uint256 => CounterMeet)) private meetCount;

    mapping(uint256 => Level) public suitoption;

    event Responce(bool responce);
    event NewLevel(address owner, uint256 tokenid);

    constructor(address contracttoken_) {
        _contracttoken = contracttoken_;
    }

    // TODO: Вычислить математику мультипликатора - сколько прибавлять и отбавлять
    function _getCafReward(
        uint256 userTokenId,
        uint256 invitedTokenId,
        uint256 whoInvited
    ) internal view returns (uint256) {
        Level memory user = suitoption[userTokenId];
        Level memory invited = suitoption[invitedTokenId];
        uint meet_count = _showMeetCount(userTokenId, invitedTokenId);
        uint256 ratio;
        if (user.level < invited.level) {
            ratio = 20;
        } else if (user.level == invited.level) {
            ratio = 10;
        } else if (user.level > invited.level) {
            ratio = 5;
        }

        if (whoInvited == 1) {
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

        return ratio;
    }

    function _getCooldownTime(
        uint256 userTokenId
    ) internal view returns (uint256) {
        Level memory user = suitoption[userTokenId];

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
        uint256 userTokenId,
        address invitedPeople,
        uint256 invitedTokenId,
        uint256 whoInvited
    ) internal {
        uint256 ratioOwner = _getCafReward(
            userTokenId,
            invitedTokenId,
            whoInvited
        );
        uint256 ratioInvited = _getCafReward(
            invitedTokenId,
            userTokenId,
            whoInvited
        );
        uint256 amountOwner = 10 * ratioOwner;
        (bool successOwner, ) = _contracttoken.call(
            abi.encodeWithSignature(
                "_mint(address,uint256)",
                owner,
                amountOwner
            )
        );
        require(successOwner, "Cant sent reward");

        emit Responce(successOwner);

        uint256 amountInvited = 10 * ratioInvited;
        (bool successInvited, ) = _contracttoken.call(
            abi.encodeWithSignature(
                "_mint(address,uint256)",
                invitedPeople,
                amountInvited
            )
        );
        require(successInvited, "Cant sent reward");

        emit Responce(successInvited);
    }

    function _setMeetCount(
        uint256 userTokenId,
        uint256 invitedTokenId
    ) internal {
        CounterMeet storage counterMeetUser = meetCount[userTokenId][
            invitedTokenId
        ];
        CounterMeet storage counterMeetInvite = meetCount[invitedTokenId][
            userTokenId
        ];
        counterMeetUser.meet++;
        counterMeetInvite.meet++;

        require(
            counterMeetUser.meet == counterMeetInvite.meet,
            "Different meet"
        );
    }

    function _showMeetCount(
        uint256 userTokenId,
        uint256 invitedTokenId
    ) internal view returns (uint) {
        CounterMeet memory counterMeetUser = meetCount[userTokenId][
            invitedTokenId
        ];
        CounterMeet memory counterMeetInvite = meetCount[invitedTokenId][
            userTokenId
        ];

        require(
            counterMeetUser.meet == counterMeetInvite.meet,
            "Different meet"
        );

        return counterMeetUser.meet;
    }

    // if whoInvite == 1 - You invite people, if == 0, people invite you
    function _ckeckMeet(
        uint256 userTokenId,
        uint256 invitedTokenId,
        uint256 whoInvite
    ) internal {
        Level storage user = suitoption[userTokenId];
        Level storage invited = suitoption[invitedTokenId];

        if (whoInvite == 1) {
            require(
                user.level == invited.level || user.level == invited.level - 1,
                "Not enouth level to meet"
            );
        } else if (whoInvite == 0) {
            require(
                user.level == invited.level || user.level == invited.level + 1,
                "Not enouth level to meet"
            );
        }

        CounterMeet memory meet_counter = meetCount[userTokenId][
            invitedTokenId
        ];
        uint meet_count = meet_counter.meet;
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
    // TODO: сделать изменение картинки (uri) токена в зависимости от уровня
    function addLevelAndRewardForMeet(
        address owner,
        uint256 userTokenId,
        address invitedPeople,
        uint256 invitedTokenId,
        uint256 whoInvite
    ) external {
        Level storage user = suitoption[userTokenId];
        Level storage invited = suitoption[invitedTokenId];

        _ckeckMeet(userTokenId, invitedTokenId, whoInvite);

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

        _rewardToken(
            owner,
            userTokenId,
            invitedPeople,
            invitedTokenId,
            whoInvite
        );

        user.reloaded = uint32(block.timestamp + _getCooldownTime(userTokenId));

        invited.reloaded = uint32(
            block.timestamp + _getCooldownTime(invitedTokenId)
        );

        _setMeetCount(userTokenId, invitedTokenId);

        emit NewLevel(owner, userTokenId);

        emit NewLevel(invitedPeople, invitedTokenId);
    }

    function _priceForUpgrade(
        uint userTokenId
    ) internal view returns (uint256) {
        Level memory user = suitoption[userTokenId];
        uint amountToUpgrade;

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

        return amountToUpgrade;
    }

    function addLevelForApgrade(
        address owner,
        uint userTokenId
    ) external payable {
        Level storage user = suitoption[userTokenId];
        uint price = _priceForUpgrade(userTokenId);
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

        emit NewLevel(owner, userTokenId);
    }

    function _payForApgrade(address account, uint256 amount) internal {
        (bool success, ) = _contracttoken.call(
            abi.encodeWithSignature("_burn(address,uint256)", account, amount)
        );
        require(success, "Cant spend token");

        emit Responce(success);
    }
}
