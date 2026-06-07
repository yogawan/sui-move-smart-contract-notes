claude --resume 1c1f2c9d-06d7-4131-8490-0cf325c18c67

# HOW TO TEST — CRUD Balance Smart Contract

## Pre-requisites

- Sui CLI udah terinstall dan `devnet` aktif (`sui client envs` — pastiin `devnet` ada `*`)
- Address punya gas SUI di devnet (cek: `sui client balance`)
- Package udah di-deploy ke devnet

## Deployment Info

```
Package ID : 0x20bb917802b7db1e5552c25067e5f6614dc9424dafb89788606c6a5fb98de02e
Module     : balance_crud
Network    : Devnet
```

## 1. Unit Test (tanpa deploy)

Test logika contract secara lokal tanpa network:

```bash
# Dari root project
cd /home/yogawan/Downloads/Workspace/learn-sui-move/belajar_sui_move

# Run semua test
sui move test

# Run test spesifik
sui move test --filter test_create_balance
sui move test --filter test_full_crud_flow

# Output verbose (lihat detail assertion)
sui move test --verbose
```

### Test yang ada (7 tests di `tests/balance_crud_tests.move`):

| Test                               | Apa yang di-test                    |
|------------------------------------|-------------------------------------|
| `test_create_balance`              | Mint Balance, cek name + amount     |
| `test_add_amount`                  | Tambah amount, cek hasil            |
| `test_subtract_amount`             | Kurangi amount, cek hasil           |
| `test_subtract_insufficient_fails` | Pastiin revert kalau gak cukup      |
| `test_set_amount`                  | Overwrite amount, cek hasil         |
| `test_delete_balance`              | Hapus Balance                       |
| `test_full_crud_flow`              | End-to-end: create → add → sub → set → delete |

---

## 2. Interactive Test via CLI (on-chain, devnet)

Ini kaya nge-curl REST API — lo interaksi langsung sama contract di devnet.

### 2.1 Buat Balance (CREATE)

```bash
sui client call \
  --package 0x20bb917802b7db1e5552c25067e5f6614dc9424dafb89788606c6a5fb98de02e \
  --module balance_crud \
  --function create_balance \
  --args '"nama-tabungan"' 10000 \
  --gas-budget 10000000
```

**Output yang dicatat:** di `Created Objects`, cari object dengan type `balance_crud::Balance`, copy **Object ID**-nya.

> Variabel: ganti `"nama-tabungan"` dengan nama apa aja, `10000` dengan jumlah awal.

### 2.2 Lihat Balance (READ)

```bash
# Lihat detail satu Balance
sui client object <BALANCE_OBJECT_ID>

# Lihat semua Balance milik address lo
sui client objects \
  0x259460735f8a86936042ed8243326adb634c80a2eb45eb198cf43b4fb896bc65 \
  --filter type:0x20bb917802b7db1e5552c25067e5f6614dc9424dafb89788606c6a5fb98de02e::balance_crud::Balance
```

### 2.3 Tambah Amount (UPDATE — add)

```bash
sui client call \
  --package 0x20bb917802b7db1e5552c25067e5f6614dc9424dafb89788606c6a5fb98de02e \
  --module balance_crud \
  --function add_amount \
  --args <BALANCE_OBJECT_ID> 5000 \
  --gas-budget 10000000
```

> Variabel: `<BALANCE_OBJECT_ID>` dari step 2.1, `5000` = jumlah yang ditambah.

### 2.4 Kurangi Amount (UPDATE — subtract)

```bash
sui client call \
  --package 0x20bb917802b7db1e5552c25067e5f6614dc9424dafb89788606c6a5fb98de02e \
  --module balance_crud \
  --function subtract_amount \
  --args <BALANCE_OBJECT_ID> 2000 \
  --gas-budget 10000000
```

> **Penting:** Kalau amount gak cukup (dikurangi melebihi balance), transaksi bakal **revert**.

### 2.5 Set Amount Langsung (UPDATE — set)

```bash
sui client call \
  --package 0x20bb917802b7db1e5552c25067e5f6614dc9424dafb89788606c6a5fb98de02e \
  --module balance_crud \
  --function set_amount \
  --args <BALANCE_OBJECT_ID> 77777 \
  --gas-budget 10000000
```

### 2.6 Hapus Balance (DELETE)

```bash
sui client call \
  --package 0x20bb917802b7db1e5552c25067e5f6614dc9424dafb89788606c6a5fb98de02e \
  --module balance_crud \
  --function delete_balance \
  --args <BALANCE_OBJECT_ID> \
  --gas-budget 10000000
```

> Object bakal di-burn dari state. Setelah ini gak bisa diakses lagi.

---

## 3. Test via SuiVision Explorer (GUI)

### 3.1 Buka SuiVision Devnet

```
https://devnet.suivision.xyz/
```

### 3.2 Inspect Package

Search bar → paste Package ID:

```
0x20bb917802b7db1e5552c25067e5f6614dc9424dafb89788606c6a5fb98de02e
```

Yang bisa diliat:
- **Package tab** — list module (`balance_crud`), bytecode, dependencies
- **Transactions** — history semua tx yang pake package ini

### 3.3 Inspect Balance Object

Search bar → paste Object ID Balance (hasil step 2.1):

Yang bisa diliat:
- **Fields** — `id`, `name`, `amount` (nilai live dari on-chain)
- **Owner** — address pemilik object
- **Type** — `belajar_sui_move::balance_crud::Balance`
- **History** — transaction yang pernah modifikasi object ini

### 3.4 Query Events

Di SuiVision, cari transaction digest dari step 2.1:

Yang bisa diliat:
- Event `BalanceCreated` dengan fields: `id`, `name`, `amount`, `owner`
- Event `BalanceUpdated` dari setiap add/subtract/set
- Event `BalanceDeleted` kalau lo delete

---

## 4. Full Test Script (copy-paste sekaligus)

Jalanin ini dari terminal buat test full flow:

```bash
PKG="0x20bb917802b7db1e5552c25067e5f6614dc9424dafb89788606c6a5fb98de02e"

echo "=== 1. CREATE ==="
RESULT=$(sui client call --package $PKG --module balance_crud --function create_balance --args '"test-full-flow"' 1000 --gas-budget 10000000 --json 2>&1)
echo "$RESULT" | head -20
BALANCE_ID=$(echo "$RESULT" | jq -r '.objectChanges[] | select(.objectType | endswith("::balance_crud::Balance")) | .objectId')
echo "Balance ID: $BALANCE_ID"
echo ""

echo "=== 2. READ ==="
sui client object $BALANCE_ID --json 2>&1 | jq '.data.content.fields'
echo ""

echo "=== 3. ADD 500 ==="
sui client call --package $PKG --module balance_crud --function add_amount --args $BALANCE_ID 500 --gas-budget 10000000 --json 2>&1 | jq '.effects.status'
echo ""

echo "=== 4. SUBTRACT 200 ==="
sui client call --package $PKG --module balance_crud --function subtract_amount --args $BALANCE_ID 200 --gas-budget 10000000 --json 2>&1 | jq '.effects.status'
echo ""

echo "=== 5. SET 9999 ==="
sui client call --package $PKG --module balance_crud --function set_amount --args $BALANCE_ID 9999 --gas-budget 10000000 --json 2>&1 | jq '.effects.status'
echo ""

echo "=== 6. FINAL READ (should be 9999) ==="
sui client object $BALANCE_ID --json 2>&1 | jq '.data.content.fields'
echo ""

echo "=== 7. DELETE ==="
sui client call --package $PKG --module balance_crud --function delete_balance --args $BALANCE_ID --gas-budget 10000000 --json 2>&1 | jq '.effects.status'
echo ""

echo "=== DONE ==="
```

> Butuh `jq` installed (`sudo dnf install jq`).

---

## Troubleshooting

| Error | Penyebab | Solusi |
|-------|----------|--------|
| `Cannot find gas coin` | Address gak punya SUI | `sui client faucet` (testnet) atau request faucet devnet |
| `EInsufficientBalance` | Amount dikurangi > balance | Cek dulu balance pake read, kurangi lebih kecil |
| `Object has already been deleted` | Object ID udah di-burn | Object gak bisa diakses setelah delete |
| `Package not found` | Package ID salah | Pastiin pake `0x20bb9178...` yang bener |
