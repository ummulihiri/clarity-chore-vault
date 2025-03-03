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
    // [Previous test content remains the same]
  }
});

Clarinet.test({
  name: "Test chore creation with invalid reward amount",
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
    
    // Try to add chore with excessive reward
    block = chain.mineBlock([
      Tx.contractCall('chore-vault', 'add-chore',
        [
          types.ascii("Clean room"),
          types.uint(1001), // Exceeds max-reward-amount
          types.principal(wallet1.address)
        ],
        deployer.address
      )
    ]);
    
    block.receipts[0].result.expectErr().expectUint(105);
  }
});

// [Previous test content remains the same]
