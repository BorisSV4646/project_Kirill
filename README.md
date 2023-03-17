# Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a script that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.js
```

1. You need deploy contract ERC20_ST.sol, after deploy ContractSuit.sol and change creater in ERC20_ST.sol to address contract ContractSuit.sol
2.

Функции контракта:

```
ERC20_ST:
```

Просмотр (без газа):

1. Тотал суплая.
2. Капы токена
3. Символа токена
4. Имени токена
5. Колличества нулей токена
6. Создателя токена
7. Баланса адреса (вставить адрес)
8. Размер разрешения на трату (адрес владельца, адрес кто тратит)

Функции (с газом):

1. Трансфер (кому, сколько)
2. Трансфер от (от кого, кому, сколько)
3. Установить нового создателя (адрес новый создателя)
4. Добавить одобрение
5. Убрать одобрение
6. Выдать одобрение
7. Создание токенов
