/// Module: balance_crud
/// Simple CRUD balance management on Sui.
/// Each Balance is an owned object — create, update (add/sub/set), and delete.

module belajar_sui_move::balance_crud {
    use sui::event;
    use sui::object::{Self, ID, UID};
    use sui::transfer;
    use sui::tx_context::TxContext;

    // ── Error codes ──────────────────────────────────────────────
    const EInsufficientBalance: u64 = 1;

    // ── Balance object ───────────────────────────────────────────
    public struct Balance has key, store {
        id:     UID,
        name:   vector<u8>,   // human-readable label
        amount: u64,          // current balance in smallest unit
    }

    // ── Events (indexable by frontend) ───────────────────────────
    public struct BalanceCreated has copy, drop {
        id:     ID,
        name:   vector<u8>,
        amount: u64,
        owner:  address,
    }

    public struct BalanceUpdated has copy, drop {
        id:         ID,
        old_amount: u64,
        new_amount: u64,
    }

    public struct BalanceDeleted has copy, drop {
        id: ID,
    }

    // ══════════════════════════════════════════════════════════════
    //  CREATE
    // ══════════════════════════════════════════════════════════════

    /// Mint a new Balance owned by the sender.
    entry fun create_balance(
        name: vector<u8>,
        initial_amount: u64,
        ctx: &mut TxContext,
    ) {
        let balance = Balance {
            id: object::new(ctx),
            name,
            amount: initial_amount,
        };

        event::emit(BalanceCreated {
            id:     object::id(&balance),
            name:   balance.name,
            amount: balance.amount,
            owner:  ctx.sender(),
        });

        transfer::public_transfer(balance, ctx.sender());
    }

    // ══════════════════════════════════════════════════════════════
    //  UPDATE — add
    // ══════════════════════════════════════════════════════════════

    /// Increase the balance by `amount`.
    entry fun add_amount(balance: &mut Balance, amount: u64) {
        let old = balance.amount;
        balance.amount = old + amount;

        event::emit(BalanceUpdated {
            id:         object::id(balance),
            old_amount: old,
            new_amount: balance.amount,
        });
    }

    // ══════════════════════════════════════════════════════════════
    //  UPDATE — subtract
    // ══════════════════════════════════════════════════════════════

    /// Decrease the balance by `amount`. Aborts if insufficient.
    entry fun subtract_amount(balance: &mut Balance, amount: u64) {
        assert!(balance.amount >= amount, EInsufficientBalance);
        let old = balance.amount;
        balance.amount = old - amount;

        event::emit(BalanceUpdated {
            id:         object::id(balance),
            old_amount: old,
            new_amount: balance.amount,
        });
    }

    // ══════════════════════════════════════════════════════════════
    //  UPDATE — set
    // ══════════════════════════════════════════════════════════════

    /// Overwrite the balance to an exact value.
    entry fun set_amount(balance: &mut Balance, new_amount: u64) {
        let old = balance.amount;
        balance.amount = new_amount;

        event::emit(BalanceUpdated {
            id:         object::id(balance),
            old_amount: old,
            new_amount: balance.amount,
        });
    }

    // ══════════════════════════════════════════════════════════════
    //  DELETE
    // ══════════════════════════════════════════════════════════════

    /// Burn the Balance object entirely.
    entry fun delete_balance(balance: Balance) {
        let id = object::id(&balance);
        event::emit(BalanceDeleted { id });

        let Balance { id, name: _, amount: _ } = balance;
        object::delete(id);
    }

    // ══════════════════════════════════════════════════════════════
    //  READ helpers (public for frontend / tests)
    // ══════════════════════════════════════════════════════════════

    public fun amount(balance: &Balance): u64 {
        balance.amount
    }

    public fun name(balance: &Balance): vector<u8> {
        balance.name
    }
}
