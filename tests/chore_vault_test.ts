import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Test family creation - owner only",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    const wallet2 = accounts.get('wallet_2')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('chore-vault', 'create-family', 
        [[types.principal(wallet1.address), types.principal(wallet2.address)]], 
        deployer.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Test non-owner attempt
    block = chain.mineBlock([
      Tx.contractCall('chore-vault', 'create-family',
        [[types.principal(wallet1.address)]], 
        wallet1.address
      )
    ]);
    
    block.receipts[0].result.expectErr().expectUint(100);
  }
});

Clarinet.test({
  name: "Test chore creation and completion",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    // Create family first
    let block = chain.mineBlock([
      Tx.contractCall('chore-vault', 'create-family',
        [[types.principal(wallet1.address)]],
        deployer.address
      )
    ]);
    
    // Add chore
    block = chain.mineBlock([
      Tx.contractCall('chore-vault', 'add-chore',
        [
          types.ascii("Clean room"),
          types.uint(100),
          types.principal(wallet1.address)
        ],
        deployer.address
      )
    ]);
    
    block.receipts[0].result.expectOk().expectUint(1);
    
    // Complete chore
    block = chain.mineBlock([
      Tx.contractCall('chore-vault', 'complete-chore',
        [types.uint(1)],
        wallet1.address
      )
    ]);
    
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Check reward balance
    const response = chain.callReadOnlyFn(
      'chore-vault',
      'get-reward-balance',
      [types.principal(wallet1.address)],
      wallet1.address
    );
    
    response.result.expectOk().expectUint(100);
  }
});

Clarinet.test({
  name: "Test reward transfers",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    const wallet2 = accounts.get('wallet_2')!;
    
    // Setup and earn rewards
    let block = chain.mineBlock([
      Tx.contractCall('chore-vault', 'create-family',
        [[types.principal(wallet1.address), types.principal(wallet2.address)]],
        deployer.address
      ),
      Tx.contractCall('chore-vault', 'add-chore',
        [
          types.ascii("Clean room"),
          types.uint(100),
          types.principal(wallet1.address)
        ],
        deployer.address
      )
    ]);
    
    block = chain.mineBlock([
      Tx.contractCall('chore-vault', 'complete-chore',
        [types.uint(1)],
        wallet1.address
      )
    ]);
    
    // Transfer rewards
    block = chain.mineBlock([
      Tx.contractCall('chore-vault', 'transfer-rewards',
        [types.uint(50), types.principal(wallet2.address)],
        wallet1.address
      )
    ]);
    
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Check balances
    let response = chain.callReadOnlyFn(
      'chore-vault',
      'get-reward-balance',
      [types.principal(wallet1.address)],
      wallet1.address
    );
    response.result.expectOk().expectUint(50);
    
    response = chain.callReadOnlyFn(
      'chore-vault',
      'get-reward-balance',
      [types.principal(wallet2.address)],
      wallet2.address
    );
    response.result.expectOk().expectUint(50);
  }
});
