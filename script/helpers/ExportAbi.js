// This script helps export ABIs to a format easily usable by a frontend

const fs = require("fs");
const path = require("path");

// Configuration
const sourceDir = "../../out";
const targetDir = "../../frontend-abi";
const contracts = [
	"Glb3dNft.sol/Glb3dNft.json",
	"Glb3dMarketplace.sol/Glb3dMarketplace.json",
];

// Create target directory if it doesn't exist
if (!fs.existsSync(targetDir)) {
	fs.mkdirSync(targetDir, { recursive: true });
}

// Process each contract
contracts.forEach((contractPath) => {
	try {
		// Read the forge output JSON file
		const sourcePath = path.join(sourceDir, contractPath);
		const rawData = fs.readFileSync(sourcePath);
		const contractData = JSON.parse(rawData);

		// Extract ABI
		const abi = contractData.abi;

		// Get contract name from path
		const contractName = path.basename(contractPath, ".json");

		// Write ABI to a new file
		const targetPath = path.join(targetDir, `${contractName}.json`);
		fs.writeFileSync(targetPath, JSON.stringify({ abi }, null, 2));

		console.log(`Exported ABI for ${contractName} to ${targetPath}`);
	} catch (error) {
		console.error(`Error exporting ABI for ${contractPath}:`, error);
	}
});

console.log("ABI export complete!");
