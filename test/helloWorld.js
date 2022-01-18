const HelloWorld = artifacts.require("HelloWorld");
// We begin by importing the smart contract

contract("HelloWorld", () => {
    it("returns userName", async() => {
        const helloWorld = await HelloWorld.deployed();
        //we get an instance of the contract
        await helloWorld.setName("Romeu");
        // we pass a string as an argument to the setName function
        const result = await helloWorld.userName()
        //because the `name` variable uses a public modifier in the smart contract it automatically generates a getter for us so we can call it directly
        assert(result === "Romeu");
        // We can use the assert function because Truffle imports Chai. And we check is the name is set properly in this way 
    })
})