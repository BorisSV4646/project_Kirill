const fs = require("fs");
const path = require("path");

for (let i = 1; i <= 10; i++) {
  const filePath = path.join(__dirname, "JSON", "" + i);
  let json = {};
  json.name = "SuitNFT #" + i;
  json.description = "NFT collections from SuitNFT";
  json.image =
    "ipfs://bafybeieen27j3ghmr66b6zlkzqb25h4p5gaf4wggrn2uu2kfv7opnaofru/" +
    i +
    ".png";

  fs.writeFileSync(filePath, JSON.stringify(json));
}
