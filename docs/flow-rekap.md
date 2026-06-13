# Rekap Flow: Dari `sui move new` Sampai Deploy ke Devnet

> **Projek:** `belajar_sui_move` — CRUD Notes Smart Contract  
> **Edisi Move:** 2024  
> **Network target:** Sui Devnet  

Dokumen ini merangkum seluruh alur kerja pengembangan smart contract Sui Move, dari nol sampai ter-deploy dan siap di-integrasikan ke frontend.

---

## Daftar Isi

1. [Inisialisasi Projek](#1-inisialisasi-projek)
2. [Konfigurasi Move.toml](#2-konfigurasi-movetoml)
3. [Menulis Smart Contract](#3-menulis-smart-contract)
4. [Menulis Unit Test](#4-menulis-unit-test)
5. [Build & Test Lokal](#5-build--test-lokal)
6. [Setup Sui Client & Wallet](#6-setup-sui-client--wallet)
7. [Deploy ke Devnet](#7-deploy-ke-devnet)
8. [Interaksi dengan Contract yang Sudah Deploy](#8-interaksi-dengan-contract-yang-sudah-deploy)
9. [Handover ke Tim Frontend](#9-handover-ke-tim-frontend)
10. [Upgrade Contract (Future)](#10-upgrade-contract-future)
11. [Cheatsheet Perintah Penting](#11-cheatsheet-perintah-penting)

---

## 1. Inisialisasi Projek

```bash
# Buat package Move baru
sui move new belajar_sui_move
```

**Yang terjadi:**
- Folder `belajar_sui_move/` dibuat
- `Move.toml` (package manifest) di-generate otomatis
- Folder `sources/` dan `tests/` kosong siap diisi

**Struktur awal:**
```
belajar_sui_move/
├── Move.toml
├── sources/
└── tests/
```

> **Syarat:** Sui CLI harus sudah terinstall. Kalau belum: `suiup install stable` (lihat [sui-install](https://docs.sui.io/guides/developer/getting-started/sui-install)).

---

## 2. Konfigurasi Move.toml

Edit `Move.toml` untuk set edisi Move, dependency, dan environment.

```toml
[package]
name = "belajar_sui_move"
edition = "2024"                    # ✅ WAJIB: pakai Move 2024 edition

[dependencies]
# Kosong — projek ini gak butuh dependency eksternal
# Kalau butuh MVR: tambahin di sini, contoh:
# Sui = { git = "https://github.com/mystenlabs/sui.git", subdir = "crates/sui-framework/packages/sui-framework", rev = "testnet-v1.40.0" }

[environments]
devnet = "043d64c6"                 # Chain ID devnet (bisa dicek via `sui client chain-id`)
```

**Kenapa `[environments]` penting:**  
Ini nanti dipakai sama `sui client publish` untuk auto-detect network dan nge-track deployment di `Published.toml`.

---

## 3. Menulis Smart Contract

### 3.1 Module Structure

File: `sources/notes.move`

Isi: module `belajar_sui_move::notes` — CRUD lengkap untuk object `Note`.

```move
module belajar_sui_move::notes {
    use std::string::{Self, String};
    use sui::clock::Clock;
    use sui::event;
    use sui::object::{Self, ID, UID};
    use sui::transfer;
    use sui::tx_context::TxContext;

    // ... isi module
}
```

### 3.2 Define Data Struct (Object)

```move
public struct Note has key, store {
    id:         UID,        // Unique ID — auto-generated tiap object
    title:      String,
    content:    String,
    created_at: u64,        // Timestamp ms dari Clock
    updated_at: u64,        // Timestamp ms dari Clock
}
```

> **`key` ability** → object bisa disimpan di global storage (dimiliki address).  
> **`store` ability** → object bisa dibungkus/dimasukkan ke struct lain.

### 3.3 Define Events

Gunakan `has copy, drop` untuk events — events gak disimpan di storage, cuma di-log.

```move
public struct NoteCreated has copy, drop { id: ID, title: String, owner: address, created_at: u64 }
public struct NoteUpdated has copy, drop { id: ID, updated_at: u64 }
public struct NoteDeleted has copy, drop { id: ID }
```

### 3.4 Define Error Codes & Limits

```move
const ETitleTooLong: u64 = 1;
const EContentTooLong: u64 = 2;
const MAX_TITLE_LENGTH: u64 = 200;
const MAX_CONTENT_LENGTH: u64 = 10_000;
```

### 3.5 Entry Functions (yang dipanggil via transaksi)

| Function | Visibility | Parameter | Keterangan |
|---|---|---|---|
| `create_note` | `entry` | `title, content, &Clock, &mut TxContext` | Buat Note → kirim ke sender |
| `update_title` | `entry` | `&mut Note, new_title, &Clock` | Ubah judul |
| `update_content` | `entry` | `&mut Note, new_content, &Clock` | Ubah isi |
| `delete_note` | `entry` | `Note` (by value) | Hapus permanen |

**Pola penting di tiap entry function:**

```move
entry fun create_note(title: String, content: String, clock: &Clock, ctx: &mut TxContext) {
    // 1. Validasi input
    assert!(title.length() as u64 <= MAX_TITLE_LENGTH, ETitleTooLong);
    assert!(content.length() as u64 <= MAX_CONTENT_LENGTH, EContentTooLong);

    // 2. Ambil timestamp dari Clock (system object)
    let now = clock.timestamp_ms();

    // 3. Buat object
    let note = Note { id: object::new(ctx), title, content, created_at: now, updated_at: now };

    // 4. Emit event
    event::emit(NoteCreated { id: object::id(&note), title: note.title, owner: ctx.sender(), created_at: now });

    // 5. Transfer ke sender
    transfer::public_transfer(note, ctx.sender());
}
```

### 3.6 Getter Functions (public — bukan entry)

```move
public fun title(note: &Note): &String { &note.title }
public fun content(note: &Note): &String { &note.content }
public fun created_at(note: &Note): u64 { note.created_at }
public fun updated_at(note: &Note): u64 { note.updated_at }
```

> Getter ini **public** (bukan `entry`). Gak bisa dipanggil via transaksi — data diakses dari response RPC (`getObject`) atau dipanggil dari module Move lain.

**Rule of thumb:**
- `entry` → dipanggil user via transaksi (CLI / wallet / dApp)
- `public` → dipanggil dari kode Move lain atau query off-chain

---

## 4. Menulis Unit Test

File: `tests/notes_tests.move`

### 4.1 Module Test

```move
#[test_only]
module belajar_sui_move::notes_tests {
    use belajar_sui_move::notes::{Self, Note};
    use sui::test_scenario::{Self, Scenario};
    // ...
}
```

> **`#[test_only]`** → module ini cuma di-compile saat `sui move test`, gak ikut ke production build.

### 4.2 Helper Functions

Supaya test gak repetitif, bikin helper:

```move
fun setup(sender: address): Scenario {
    let mut scenario = test_scenario::begin(sender);
    test_scenario::create_system_objects(&mut scenario);   // ← setup Clock, Random, dll
    scenario
}

fun create(scenario: &mut Scenario, sender: address, title: vector<u8>, content: vector<u8>): Note {
    test_scenario::next_tx(scenario, sender);              // ← mulai transaksi baru
    {
        let clock = test_scenario::take_shared<Clock>(scenario);  // ambil Clock dari storage
        notes::create_note(string::utf8(title), string::utf8(content), &clock, test_scenario::ctx(scenario));
        test_scenario::return_shared(clock);               // ← WAJIB: balikin Clock
    };
    test_scenario::next_tx(scenario, sender);              // ← transaksi baru untuk take object
    test_scenario::take_from_sender<Note>(scenario)        // ambil Note dari sender
}
```

### 4.3 Test Cases (total: 8 test)

| # | Test | Kategori |
|---|---|---|
| 1 | `test_create_note` | Create — verifikasi field |
| 2 | `test_create_multiple_notes` | Create — multiple notes |
| 3 | `test_create_note_for_different_owners` | Create — multi-user isolation |
| 4 | `test_update_content` | Update — ubah content |
| 5 | `test_update_title` | Update — ubah title, content tetap |
| 6 | `test_update_multiple_times` | Update — double-update |
| 7 | `test_delete_note` | Delete — objek dikonsumsi |
| 8 | `test_full_crud_flow` | Integration — Create → Update → Delete |

**Pola test:**
```move
#[test]
fun test_create_note() {
    let mut scenario = setup(ALICE);           // 1. Setup scenario
    {
        let note = create_alice(&mut scenario); // 2. Eksekusi fungsi
        assert!(str_eq(notes::title(&note), b"catatan-1"));  // 3. Assert hasil
        test_scenario::return_to_sender(&scenario, note);    // 4. Balikin object
    };
    test_scenario::end(scenario);              // 5. Cleanup
}
```

> **PENTING:** Setiap object yang di-take dari storage HARUS dikembalikan (`return_to_sender`/`return_to_address`) ATAU dihapus (`delete_note`). Kalau enggak, test akan error.

---

## 5. Build & Test Lokal

### 5.1 Build

```bash
cd belajar_sui_move
sui move build
```

**Output sukses:**
```
UPDATING GIT DEPENDENCY ...
INCLUDING DEPENDENCY Sui
INCLUDING DEPENDENCY MoveStdlib
BUILDING belajar_sui_move
```

Kalau ada error compile, baca output-nya — biasanya:
- Typo di nama fungsi/variabel
- Salah import module
- Struct kurang ability (`key`, `store`, dll)

### 5.2 Test

```bash
# Jalanin semua test
sui move test

# Test spesifik
sui move test --filter test_create_note

# Verbose mode (lebih detail)
sui move test --verbose
```

**Output sukses:**
```
Running Move unit tests
[ PASS    ] belajar_sui_move::notes_tests::test_create_note
[ PASS    ] belajar_sui_move::notes_tests::test_create_multiple_notes
...
Test result: OK. Total tests: 8; passed: 8; failed: 0
```

> **Iterasi tipikal:** Tulis kode → `sui move build` → `sui move test` → ulangi sampai semua hijau.

---

## 6. Setup Sui Client & Wallet

Sebelum deploy, pastikan Sui client sudah dikonfigurasi dan punya saldo.

### 6.1 Cek Environment Aktif

```bash
sui client active-env
# Output: devnet   ← pastikan devnet
```

### 6.2 Switch ke Devnet (kalau belum)

```bash
sui client new-env --alias devnet --rpc https://fullnode.devnet.sui.io:443
sui client switch --env devnet
```

### 6.3 Cek Address & Saldo

```bash
# Lihat semua address yang ada di keystore
sui client addresses

# Cek saldo address aktif
sui client gas
```

### 6.4 Request Faucet (Devnet/Testnet)

```bash
# Devnet faucet
sui client faucet

# Atau spesifik address
sui client faucet --address 0xYOUR_ADDRESS
```

> **Mainnet gak ada faucet** — harus beli SUI dari exchange atau transfer dari wallet lain.

### 6.5 Buat Address Baru (kalau perlu)

```bash
sui client new-address ed25519
```

---

## 7. Deploy ke Devnet

### 7.1 Publish (First Deploy)

```bash
sui client publish --gas-budget 100000000
```

> **`--gas-budget`** penting! Harus cukup buat bayar compute + storage on-chain. Kalau kurang, transaksi akan gagal. Nilai `100_000_000` (100M MIST ≈ 0.1 SUI) biasanya cukup untuk package kecil.

**Yang terjadi saat publish:**
1. Bytecode module di-upload ke Sui
2. Package ID di-generate (unik, immutable)
3. `UpgradeCap` object dikirim ke publisher (buat upgrade nanti)
4. Metadata otomatis dicatat di `Published.toml`

**Output sukses:**
```
Transaction Digest: Hz8V7d...
╭──────────────────────────────────────────────────────╮
│ Transaction Effects                                  │
├──────────────────────────────────────────────────────┤
│ Created Objects:                                     │
│  - Package ID: 0x1b57...                             │  ← INI DICATAT!
│  - UpgradeCap: 0xf7a2...                             │  ← INI JUGA DICATAT!
╰──────────────────────────────────────────────────────╯
```

### 7.2 Published.toml (Auto-Generated)

Setelah publish, `Published.toml` otomatis ke-update:

```toml
[published.devnet]
chain-id = "043d64c6"
published-at = "0x1b1756cdbb760564aa96511b24fdf3c1d37ec0a4dc5ec50711406d684da848d5"
original-id = "0x1b1756cdbb760564aa96511b24fdf3c1d37ec0a4dc5ec50711406d684da848d5"
version = 1
toolchain-version = "1.73.1"
build-config = { flavor = "sui", edition = "2024" }
upgrade-capability = "0xf7a2369dd34befadb4c1cf2db1c66f08f4222fbdcfe201e1f86e491074cac2e8"
```

> **File ini WAJIB di-commit ke git!** Dipakai buat tracking deployment history dan keperluan upgrade nanti.

### 7.3 Key Info Setelah Publish

| Item | Value | Kegunaan |
|---|---|---|
| **Package ID** | `0x1b17...848d5` | Alamat package di blockchain — dipakai frontend buat panggil fungsi |
| **UpgradeCap ID** | `0xf7a2...c2e8` | "Kunci" buat upgrade package nanti — SIMPAN AMAN |
| **Chain ID** | `043d64c6` | Identitas chain (devnet) |

---

## 8. Interaksi dengan Contract yang Sudah Deploy

### 8.1 Create Note

```bash
sui client call \
  --package 0x1b1756cdbb760564aa96511b24fdf3c1d37ec0a4dc5ec50711406d684da848d5 \
  --module notes \
  --function create_note \
  --args "Judul Catatan" "Isi konten di sini" 0x6 \
  --gas-budget 10000000
```

> **`0x6`** adalah object ID dari Sui Clock (system object), wajib dioper karena `create_note` pakai `clock.timestamp_ms()`.

### 8.2 Read / Lihat Note

```bash
# List semua object milik address kita
sui client objects

# Detail satu object
sui client object 0xNOTE_OBJECT_ID
```

### 8.3 Update Title / Content

```bash
# Update title
sui client call \
  --package 0x1b17... \
  --module notes \
  --function update_title \
  --args 0xNOTE_OBJECT_ID "Judul Baru" 0x6 \
  --gas-budget 10000000

# Update content
sui client call \
  --package 0x1b17... \
  --module notes \
  --function update_content \
  --args 0xNOTE_OBJECT_ID "Konten Baru" 0x6 \
  --gas-budget 10000000
```

### 8.4 Delete Note

```bash
sui client call \
  --package 0x1b17... \
  --module notes \
  --function delete_note \
  --args 0xNOTE_OBJECT_ID \
  --gas-budget 10000000
```

### 8.5 Dry Run (Test Tanpa On-Chain)

```bash
sui client call --dry-run \
  --package 0x1b17... \
  --module notes \
  --function create_note \
  --args "Test" "Test content" 0x6 \
  --gas-budget 10000000
```

> Dry run mensimulasikan transaksi tanpa benar-benar mengeksekusinya — berguna buat verifikasi apakah tx akan sukses atau gagal.

---

## 9. Handover ke Tim Frontend

Setelah contract ter-deploy dan terverifikasi, buat dokumen handover untuk tim FE. Isinya:

### 9.1 Info yang Harus Diserahin

| Item | Contoh |
|---|---|
| **Package ID** | `0x1b17...` |
| **Network** | Devnet (Chain ID: `043d64c6`) |
| **Module Name** | `notes` |
| **Struct & Field** | `Note { id, title, content, created_at, updated_at }` |
| **Entry Functions** | `create_note`, `update_title`, `update_content`, `delete_note` |
| **Events** | `NoteCreated`, `NoteUpdated`, `NoteDeleted` |
| **Error Codes** | `1` = title too long, `2` = content too long |
| **Validasi Input** | title max 200 chars, content max 10.000 chars |

### 9.2 Code Snippets untuk FE

Berikan contoh kode TypeScript untuk tiap operasi:

```ts
import { Transaction } from "@mysten/sui/transactions";

const PACKAGE_ID = "0x1b1756cdbb760564aa96511b24fdf3c1d37ec0a4dc5ec50711406d684da848d5";
const MODULE = "notes";

// Create
function createNote(tx: Transaction, title: string, content: string) {
  tx.moveCall({
    target: `${PACKAGE_ID}::${MODULE}::create_note`,
    arguments: [tx.pure.string(title), tx.pure.string(content), tx.object("0x6")],
  });
}

// Query (baca data — bukan transaksi)
const notes = await client.listOwnedObjects({
  owner: userAddress,
  type: `${PACKAGE_ID}::${MODULE}::Note`,
});
```

> **Contoh lengkap:** lihat [`docs/notes-contract-handover.md`](./notes-contract-handover.md)

### 9.3 Pengingat untuk FE

- **Devnet di-wipe mingguan** (setiap Rabu) — Package ID berubah setelah redeploy
- Object `Clock` (`0x6`) WAJIB dioper ke fungsi yang butuh timestamp
- Semua timestamp dalam **milidetik**, bukan detik
- Setelah `signAndExecuteTransaction`, wajib `waitForTransaction` sebelum refetch query
- `Note` adalah **address-owned object** — tiap user cuma bisa lihat Note miliknya sendiri

---

## 10. Upgrade Contract (Future)

Kalau ada perubahan di module, jangan publish ulang (bikin package baru). Gunakan **upgrade**:

### 10.1 Syarat Upgrade

- Punya `UpgradeCap` object (dari publish pertama)
- Package belum di-"make immutable"
- Edition dan dependency kompatibel

### 10.2 Perintah Upgrade

```bash
sui client upgrade \
  --upgrade-capability 0xf7a2369dd34befadb4c1cf2db1c66f08f4222fbdcfe201e1f86e491074cac2e8 \
  --gas-budget 100000000
```

**Yang terjadi:**
- Package ID **gak berubah** (tetap yang lama)
- Version di `Published.toml` naik (1 → 2)
- Frontend **gak perlu update Package ID**

### 10.3 Upgrade Policy

Default policy: **COMPATIBLE** — hanya boleh nambah (fungsi baru, struct baru, field baru), gak boleh ngubah/hapus yang sudah ada.

Untuk ganti policy, bisa set di `Move.toml`:
```toml
[package]
publish-at = "0x..."
upgrade-policy = "compatible"   # compatible | additive | dep_only
```

---

## 11. Cheatsheet Perintah Penting

```bash
# ── PROJECT ──────────────────────────────
sui move new <nama>         # Buat projek baru
sui move build              # Compile
sui move test               # Test semua
sui move test --filter <fn> # Test spesifik
sui move check              # Cek error tanpa build penuh

# ── CLIENT ───────────────────────────────
sui client active-env       # Cek network aktif
sui client switch --env devnet
sui client addresses        # List address
sui client gas              # Cek saldo
sui client faucet           # Minta token devnet/testnet
sui client objects          # List owned objects
sui client object <id>      # Detail satu object
sui client new-address ed25519

# ── DEPLOY ──────────────────────────────
sui client publish --gas-budget 100000000
sui client upgrade --upgrade-capability <id> --gas-budget 100000000

# ── INTERACT ────────────────────────────
sui client call \
  --package <pkg-id> \
  --module <module> \
  --function <fn> \
  --args <arg1> <arg2> ... \
  --gas-budget 10000000

sui client call --dry-run ...    # Simulasi tanpa on-chain
```

---

## Flow Visual

```
┌─────────────────────────────────────────────────────────────────┐
│  1. sui move new belajar_sui_move                               │
│         │                                                       │
│         ▼                                                       │
│  2. Edit Move.toml (edition, environments)                      │
│         │                                                       │
│         ▼                                                       │
│  3. Tulis sources/notes.move                                    │
│     - Struct Note                                               │
│     - Events (NoteCreated, NoteUpdated, NoteDeleted)            │
│     - Entry functions (create, update_title, update_content,    │
│                        delete)                                  │
│     - Getters (title, content, created_at, updated_at)          │
│     - Error codes & validasi                                    │
│         │                                                       │
│         ▼                                                       │
│  4. Tulis tests/notes_tests.move (8 test)                       │
│         │                                                       │
│         ▼                                                       │
│  5. sui move build  →  pastikan compile                         │
│     sui move test    →  pastikan semua hijau                    │
│         │                                                       │
│         ▼                                                       │
│  6. Setup client: switch devnet, faucet, cek saldo              │
│         │                                                       │
│         ▼                                                       │
│  7. sui client publish --gas-budget 100000000                   │
│     → Dapat Package ID + UpgradeCap ID                          │
│     → Published.toml terisi otomatis                            │
│         │                                                       │
│         ▼                                                       │
│  8. Test on-chain: sui client call create/update/delete         │
│         │                                                       │
│         ▼                                                       │
│  9. Buat handover doc → Tim FE integrasi                        │
│         │                                                       │
│         ▼                                                       │
│  10. (Future) sui client upgrade kalau ada perubahan            │
└─────────────────────────────────────────────────────────────────┘
```

---

> **Last updated:** 2026-06-13  
> **Current Package ID (devnet):** `0x1b1756cdbb760564aa96511b24fdf3c1d37ec0a4dc5ec50711406d684da848d5`
