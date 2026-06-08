# Planning & Progress — CRUD Balance Smart Contract

## Tujuan

Bikin smart contract CRUD Balance sederhana di Sui Move, test, build, lalu deploy ke **devnet**. Contract harus bisa diintegrasikan dengan FE Next.js.

---

## Hasil Deploy (Devnet) ✅

| Item              | Value                                                                                      |
|-------------------|--------------------------------------------------------------------------------------------|
| **Status**        | ✅ Sukses                                                                                   |
| **Package ID**    | `0x20bb917802b7db1e5552c25067e5f6614dc9424dafb89788606c6a5fb98de02e`                        |
| **Module**        | `balance_crud`                                                                             |
| **Network**       | Devnet (`f91cee94`)                                                                        |
| **Sender**        | `0x2594607...` (lucid-carnelian)                                                           |
| **Digest**        | `xax86m2xuCfhq9gwm1cdtwtFtyqcMEBfvCh83N8CkcY`                                              |
| **UpgradeCap ID** | `0x77c87964528aa0cfdc83fa904871bfea42ac08881a7a60f3ee5102fcdf1ba2cf`                         |
| **Gas Cost**      | ~0.0127 SUI                                                                                |

---

## Desain Contract

### Module: `balance_crud`

**Object `Balance`** — owned object (dimiliki user):

| Field  | Type        | Keterangan                |
|--------|-------------|---------------------------|
| `id`   | `UID`       | Object ID (Sui native)    |
| `name` | `vector<u8>`| Label/nama balance        |
| `amount`| `u64`      | Jumlah balance            |

**CRUD Operations:**

| Operasi | Function            | Keterangan                              |
|---------|---------------------|-----------------------------------------|
| CREATE  | `create_balance`    | Mint Balance baru, transfer ke sender   |
| UPDATE  | `add_amount`        | Tambah amount                           |
| UPDATE  | `subtract_amount`   | Kurangi amount (revert kalau gak cukup) |
| UPDATE  | `set_amount`        | Overwrite amount ke nilai tertentu      |
| DELETE  | `delete_balance`    | Burn/hapus Balance object               |
| READ    | `amount` + `name`   | Public getter functions                 |

**Events** (buat frontend indexing via `suiClient.queryEvents`):

- `BalanceCreated { id, name, amount, owner }`
- `BalanceUpdated { id, old_amount, new_amount }`
- `BalanceDeleted { id }`

---

## Progress

### ✅ Semua Selesai

1. **Contract** — `sources/balance_crud.move`
2. **Tests** — 7/7 tests PASS
3. **Build** — sukses
4. **Deploy ke Devnet** — sukses

### File yang Dimodifikasi

| File                            | Status    | Keterangan                              |
|---------------------------------|-----------|-----------------------------------------|
| `sources/balance_crud.move`     | New       | Smart contract utama (5 entry + 2 getter)|
| `tests/balance_crud_tests.move` | New       | 7 unit tests                            |
| `Move.toml`                     | Modified  | Tambah `[environments] devnet = "f91cee94"` |

---

## Next Steps (buat Next.js Integration)

1. Setup Next.js project dengan `@mysten/dapp-kit` + `@mysten/sui`
2. Wallet connection (Sui Wallet, Sui Extension)
3. Query Balance objects milik user: `suiClient.getOwnedObjects({ owner, filter: { StructType: \`${packageId}::balance_crud::Balance\` } })`
4. Subscribe events: `suiClient.queryEvents({ query: { MoveEventType: \`${packageId}::balance_crud::BalanceCreated\` } })`
5. Implement UI:
   - Form create balance (input name + initial amount)
   - List balance cards (show name, amount, object ID)
   - Tombol add / subtract / set amount
   - Tombol delete balance
6. Deploy FE ke Vercel / Walrus Sites

### Contoh transaction call dari Next.js:

```ts
import { Transaction } from '@mysten/sui/transactions';

const PACKAGE_ID = '0x20bb917802b7db1e5552c25067e5f6614dc9424dafb89788606c6a5fb98de02e';
const tx = new Transaction();

// Create balance
tx.moveCall({
  target: `${PACKAGE_ID}::balance_crud::create_balance`,
  arguments: [tx.pure.string('tabungan-eth'), tx.pure.u64(1000)],
});

// Add amount
tx.moveCall({
  target: `${PACKAGE_ID}::balance_crud::add_amount`,
  arguments: [tx.object(balanceObjectId), tx.pure.u64(500)],
});

// Delete balance
tx.moveCall({
  target: `${PACKAGE_ID}::balance_crud::delete_balance`,
  arguments: [tx.object(balanceObjectId)],
});
```

### Catatan Teknis Move 2024

- Struct perlu visibility `public`
- Variable immutable by default — butuh prefix `mut` buat mutable
- Test API: `take_from_sender<T>` / `return_to_sender` (bukan `take_owned` / `return_owned`)
- `object::id()` return `ID` langsung (bukan `&ID`)
- `[environments]` di `Move.toml` format: `env_name = "chain_id"` (testnet/mainnet built-in, devnet harus explicit)
