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

    event Responce(bool indexed responce);
    event AddReward(address indexed owner, uint256 indexed tokenid);
    event NewLevel(address indexed owner, uint256 indexed tokenid);
    event Upgrade(address indexed owner, uint256 indexed tokenid);

    constructor(address contracttoken_) {
        _contracttoken = contracttoken_;
    }

    // TODO: Вычислить математику мультипликатора - сколько прибавлять и отбавлять
    function _getCafReward(
        uint256 userTokenId,
        uint256 invitedTokenId,
        bool whoInvited
    ) internal view returns (uint256) {
        Level memory user = suitoption[userTokenId];
        Level memory invited = suitoption[invitedTokenId];
        uint meet_count = showMeetCount(userTokenId, invitedTokenId);
        uint256 ratio;
        if (user.level < invited.level) {
            ratio = 20;
        } else if (user.level == invited.level) {
            ratio = 10;
        } else if (user.level > invited.level) {
            ratio = 5;
        }

        if (whoInvited == true) {
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

        if (user.level == 2) {
            ratio += 7;
        } else if (user.level == 3) {
            ratio += 10;
        } else if (user.level == 4) {
            ratio += 13;
        } else if (user.level == 5) {
            ratio += 15;
        }

        return ratio;
    }

    function _getCooldownTime(
        uint256 userTokenId,
        uint256 invitedTokenId
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

        CounterMeet memory meet_counter = meetCount[userTokenId][
            invitedTokenId
        ];
        uint meet_count = meet_counter.meet;
        if (meet_count == 1) {
            user.reloaded += 1 days;
        } else if (meet_count == 2) {
            user.reloaded += 36 hours;
        } else if (meet_count == 3) {
            user.reloaded += 2 days;
        } else if (meet_count == 4) {
            user.reloaded += 3 days;
        } else if (meet_count > 4) {
            user.reloaded += 5 days;
        }

        return user.reloaded;
    }

    function _rewardToken(
        address owner,
        uint256 userTokenId,
        address invitedPeople,
        uint256 invitedTokenId,
        bool whoInvited
    ) internal {
        uint256 ratioOwner = _getCafReward(
            userTokenId,
            invitedTokenId,
            whoInvited
        );
        uint256 ratioInvited = _getCafReward(
            invitedTokenId,
            userTokenId,
            !whoInvited
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

    // !может любой посмотреть колличество встреч любого
    function showMeetCount(
        uint256 userTokenId,
        uint256 invitedTokenId
    ) public view returns (uint) {
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

    // if whoInvite == true - You invite people, if == false, people invite you
    function _ckeckMeet(
        uint256 userTokenId,
        uint256 invitedTokenId,
        bool whoInvite
    ) internal view {
        Level storage user = suitoption[userTokenId];
        Level storage invited = suitoption[invitedTokenId];

        if (whoInvite == true) {
            require(
                user.level == invited.level || user.level - 1 == invited.level,
                "Not enouth level to meet"
            );
        } else if (whoInvite == false) {
            require(
                user.level == invited.level || user.level == invited.level + 1,
                "Not enouth level to meet"
            );
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
        bool whoInvite
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

        user.reloaded = uint32(
            block.timestamp + _getCooldownTime(userTokenId, invitedTokenId)
        );

        invited.reloaded = uint32(
            block.timestamp + _getCooldownTime(invitedTokenId, userTokenId)
        );

        _setMeetCount(userTokenId, invitedTokenId);

        emit AddReward(owner, userTokenId);

        emit AddReward(invitedPeople, invitedTokenId);

        if (
            suntolevel == 12 ||
            suntolevel == 21 ||
            suntolevel == 30 ||
            suntolevel == 42
        ) {
            emit NewLevel(owner, userTokenId);
        }

        if (
            suntolevel_invited == 12 ||
            suntolevel_invited == 21 ||
            suntolevel_invited == 30 ||
            suntolevel_invited == 42
        ) {
            emit NewLevel(invitedPeople, invitedTokenId);
        }
    }

    function _priceForUpgrade(uint userTokenId) public view returns (uint256) {
        Level memory user = suitoption[userTokenId];
        uint amountToUpgrade;

        for (uint i = 1; i < 50; i++) {
            if (user.color == i) {
                amountToUpgrade += 100000000000000000 * i; //0.001 ETH;
            }
        }

        for (uint j = 2; j < 5; j++) {
            if (user.level == j) {
                amountToUpgrade += 300000000000000000 * (j - 1); //0.003 ETH;
            }
        }

        return amountToUpgrade;
    }

    function addLevelForApgrade(
        address owner,
        uint userTokenId
    ) external payable virtual {
        Level storage user = suitoption[userTokenId];
        uint price = _priceForUpgrade(userTokenId);
        require(msg.sender == owner, "Not an owner to update tokens");

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

        emit Upgrade(owner, userTokenId);
    }

    function _payForApgrade(address account, uint256 amount) internal {
        (bool success, ) = _contracttoken.call(
            abi.encodeWithSignature("_burn(address,uint256)", account, amount)
        );
        require(success, "Cant spend token");

        emit Responce(success);
    }
}
