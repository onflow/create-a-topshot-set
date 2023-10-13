// Pass the repo name
const recipe = "create-a-topshot-set";

//Generate paths of each code file to render
const contractPath = `${recipe}/cadence/contract.cdc`;
const transactionPath = `${recipe}/cadence/transaction.cdc`;

//Generate paths of each explanation file to render
const smartContractExplanationPath = `${recipe}/explanations/contract.txt`;
const transactionExplanationPath = `${recipe}/explanations/transaction.txt`;

export const createATopShotSet= {
  slug: recipe,
  title: "Create a TopShot Set",
  createdAt: Date(2022, 9, 9),
  author: "Flow Blockchain",
  playgroundLink:
    "https://play.onflow.org/63a7ce9f-3315-4c55-8392-2d626bb8387d?type=account&id=91c4010c-2407-4a3c-a0c1-cc4d3904d9f8&storage=none",
  excerpt:
    "Using the TopShot contract, this is how you would create a set so that you could add plays to them and mint moments from those plays.",
  smartContractCode: contractPath,
  smartContractExplanation: smartContractExplanationPath,
  transactionCode: transactionPath,
  transactionExplanation: transactionExplanationPath,
};

