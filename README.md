# TokenSwap

## Concept
The `TokenSwap` contract facilitates token swaps between different ERC-20 tokens with adjustable exchange rates. Users can create pairs of tokens, set their exchange rates, and execute swaps based on these rates. The contract supports multiple token pairs and allows the owner to manage pair configurations.

## Usage
Install foundry, Clone the repository and run

```bash
forge build
```

### Test Script

Run the command to execute the test script

```bash
forge script InteractTokenSwap
```
<Details>
<summary>Here is a step-by-step overview of the test script results</summary>

### Step 1: Pairs Created
- Three pairs are created with the following exchange rates:
    - X:Y (1:1)
    - Y:Z (1:4)
    - X:Z (1:2)
- Console output:
  ```
  1. Pairs Created
  ==============================
  Tokens: X/Y Exchange rate: 1
  Tokens: Y/Z Exchange rate: 4
  Tokens: X/Z Exchange rate: 2
  ==============================
  ```

### Step 2: Y/Z exchange rate updated to 2
- The exchange rate for the Y/Z pair is updated to 2.
- Console output:
  ```
  2. Y/Z exchange rate updated to 2
  ```

### Step 3: Swap Operation (X/Y, 10 tokens)
- User0 swaps 10 tokens from X to Y.
- Initial balances:
    - InToken (X): 100
    - OutToken (Y): 100
- After swap:
    - InToken (X): 110
    - OutToken (Y): 90
- Console output:
  ```
  3. Swap Operation
  ==============================
  Swap 10 X/Y
  swap symbols: false
  InToken balance of user0:  100
  OutToken balance of user0:  100
  InToken balance of user0:  110
  OutToken balance of user0:  90
  ==============================
  ```

### Step 4: Swap Operation (Y/Z, 10 tokens)
- User0 swaps 10 tokens from Y to Z.
- Initial balances:
    - InToken (Y): 110
    - OutToken (Z): 100
- After swap:
    - InToken (Y): 115
    - OutToken (Z): 90
- Console output:
  ```
  3. Swap Operation
  ==============================
  Swap 10 Y/Z
  swap symbols: true
  InToken balance of user0:  110
  OutToken balance of user0:  100
  InToken balance of user0:  115
  OutToken balance of user0:  90
  ==============================
  ```

### Step 5: Swap Operation (X/Z, 10 tokens)
- User0 swaps 10 tokens from X to Z.
- Initial balances:
    - InToken (X): 90
    - OutToken (Z): 90
- After swap:
    - InToken (X): 95
    - OutToken (Z): 80
- Console output:
  ```
  3. Swap Operation
  ==============================
  Swap 10 X/Z
  swap symbols: true
  InToken balance of user0:  90
  OutToken balance of user0:  90
  InToken balance of user0:  95
  OutToken balance of user0:  80
  ==============================
  ```

### Step 6: User0 Token Balances
- Displaying the final token balances of User0.
- Console output:
  ```
  4. User0 Token Balances
  ==============================
  TokenX: 95
  TokenY: 115
  TokenZ: 80
  ==============================
  ```

This step-by-step overview reflects the process of creating token pairs, updating exchange rates, and executing token swaps, providing a clear understanding of the contract's functionality.
</Details>

### Tests

```bash
 forge test
```

## Design Choices

### Pair Structure
- The contract uses a `Pair` struct to represent token pairs. Each pair includes two token addresses and an exchange rate.
- Pairs are stored in a mapping using a unique symbol, such as "X/Y," as the key.

### Exchange Rate Management
- Exchange rates are adjustable by the contract owner through the `setExchangeRate` function.
- The owner can create new token pairs with specified exchange rates using the `createPair` function.

### Token Swapping
- Token swaps are executed through the `swapTokens` function, allowing users to swap a specified amount of tokens between a selected pair.
- The function supports swapping tokens with the option to swap token symbols within the pair.

### Security Considerations

#### SafeERC20 Usage
- The contract incorporates the `SafeERC20` library to ensure secure handling of ERC-20 tokens.
- This minimizes the risk of reentrancy attacks and other potential vulnerabilities when interacting with external tokens.

#### Ownership Control
- The `Ownable` contract is utilized to restrict certain functions to the contract owner, ensuring that critical operations are managed securely.

#### Parameter Validation
- The contract includes comprehensive parameter validation to prevent invalid configurations and ensure the correctness of swap operations.
- Checks are implemented to verify valid token addresses, non-zero exchange rates, and the existence of token pairs.

#### Function Modifiers
- Function modifiers, such as `onlyOwner`, are used to restrict access to critical functions, enhancing the security of ownership-related operations.

#### Reentrancy Mitigation
- The contract design follows best practices to minimize the risk of reentrancy attacks, such as ensuring external calls are made after internal state changes.