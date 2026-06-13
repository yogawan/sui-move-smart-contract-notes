# Handover: Notes Smart Contract — Devnet

> **Tujuan:** Dokumen ini untuk tim FE sebagai acuan integrasi `notes` module ke React/NextJS.
> **Last deploy:** 2026-06-13
> **Network:** Devnet

---

## 1. Deployment Info

| Key | Value |
|---|---|
| **Network** | Devnet |
| **Chain ID** | `043d64c6` |
| **Package ID** | `0x1b1756cdbb760564aa96511b24fdf3c1d37ec0a4dc5ec50711406d684da848d5` |
| **Publisher Address** | `0x259460735f8a86936042ed8243326adb634c80a2eb45eb198cf43b4fb896bc65` |
| **UpgradeCap ID** | `0xf7a2369dd34befadb4c1cf2db1c66f08f4222fbdcfe201e1f86e491074cac2e8` |
| **Module Name** | `notes` |
| **Move Edition** | 2024 |
| **RPC (gRPC)** | `https://grpc.devnet.sui.io:443` |

---

## 2. Constants untuk Frontend

```ts
// src/constants.ts
export const NOTES_PACKAGE_ID =
  "0x1b1756cdbb760564aa96511b24fdf3c1d37ec0a4dc5ec50711406d684da848d5";

export const NOTES_MODULE = "notes";

export const NOTES_TYPES = {
  Note:        `${NOTES_PACKAGE_ID}::${NOTES_MODULE}::Note`,
  NoteCreated: `${NOTES_PACKAGE_ID}::${NOTES_MODULE}::NoteCreated`,
  NoteUpdated: `${NOTES_PACKAGE_ID}::${NOTES_MODULE}::NoteUpdated`,
  NoteDeleted: `${NOTES_PACKAGE_ID}::${NOTES_MODULE}::NoteDeleted`,
} as const;
```

---

## 3. Data Structures

### 3.1 Note Object (on-chain struct)

```move
public struct Note has key, store {
    id:         UID,      // object ID — unique, auto-generated
    title:      String,   // max 200 chars
    content:    String,   // max 10.000 chars
    created_at: u64,      // unix timestamp ms
    updated_at: u64,      // unix timestamp ms
}
```

### 3.2 TS Type Mapping

```ts
interface Note {
  id:         string;   // object ID hex
  title:      string;
  content:    string;
  created_at: bigint;   // or number — timestamp in milliseconds
  updated_at: bigint;
}

interface NoteFields {
  id:         { id: string };
  title:      string;
  content:    string;
  created_at: string;   // u64 comes as string from RPC
  updated_at: string;
}
```

---

## 4. Functions (Entry Points)

### 4.1 `create_note`

Bikin Note baru. Note akan ditransfer ke sender (pemanggil).

```
target: {PACKAGE_ID}::notes::create_note
```

| # | Parameter | Move Type | TS `tx` helper | Notes |
|---|---|---|---|---|
| 1 | `title` | `String` | `tx.pure.string(title)` | Max 200 karakter |
| 2 | `content` | `String` | `tx.pure.string(content)` | Max 10.000 karakter |
| 3 | `clock` | `&Clock` | `tx.object("0x6")` | Object tetap Sui Clock |
| 4 | `ctx` | `&mut TxContext` | — | Otomatis |

```ts
function createNote(tx: Transaction, title: string, content: string) {
  tx.moveCall({
    target: `${NOTES_PACKAGE_ID}::${NOTES_MODULE}::create_note`,
    arguments: [
      tx.pure.string(title),
      tx.pure.string(content),
      tx.object("0x6"), // Clock
    ],
  });
}
```

### 4.2 `update_title`

Update judul Note.

```
target: {PACKAGE_ID}::notes::update_title
```

| # | Parameter | Move Type | TS `tx` helper |
|---|---|---|---|
| 1 | `note` | `&mut Note` | `tx.object(noteObjectId)` |
| 2 | `new_title` | `String` | `tx.pure.string(newTitle)` |
| 3 | `clock` | `&Clock` | `tx.object("0x6")` |

```ts
function updateTitle(tx: Transaction, noteObjectId: string, newTitle: string) {
  tx.moveCall({
    target: `${NOTES_PACKAGE_ID}::${NOTES_MODULE}::update_title`,
    arguments: [
      tx.object(noteObjectId),
      tx.pure.string(newTitle),
      tx.object("0x6"),
    ],
  });
}
```

### 4.3 `update_content`

Update konten Note.

```
target: {PACKAGE_ID}::notes::update_content
```

| # | Parameter | Move Type | TS `tx` helper |
|---|---|---|---|
| 1 | `note` | `&mut Note` | `tx.object(noteObjectId)` |
| 2 | `new_content` | `String` | `tx.pure.string(newContent)` |
| 3 | `clock` | `&Clock` | `tx.object("0x6")` |

```ts
function updateContent(tx: Transaction, noteObjectId: string, newContent: string) {
  tx.moveCall({
    target: `${NOTES_PACKAGE_ID}::${NOTES_MODULE}::update_content`,
    arguments: [
      tx.object(noteObjectId),
      tx.pure.string(newContent),
      tx.object("0x6"),
    ],
  });
}
```

### 4.4 `delete_note`

Hapus Note. Objek Note dikonsumsi dan dihapus permanen.

```
target: {PACKAGE_ID}::notes::delete_note
```

| # | Parameter | Move Type | TS `tx` helper |
|---|---|---|---|
| 1 | `note` | `Note` | `tx.object(noteObjectId)` |

```ts
function deleteNote(tx: Transaction, noteObjectId: string) {
  tx.moveCall({
    target: `${NOTES_PACKAGE_ID}::${NOTES_MODULE}::delete_note`,
    arguments: [tx.object(noteObjectId)],
  });
}
```

---

## 5. Getters (Query Data)

Getters ini **public**, bukan `entry` — jadi gak bisa dipanggil via transaksi. Data dibaca dari object response RPC.

```move
public fun title(note: &Note): &String       // → note.fields.title
public fun content(note: &Note): &String     // → note.fields.content
public fun created_at(note: &Note): u64      // → note.fields.created_at
public fun updated_at(note: &Note): u64      // → note.fields.updated_at
```

**Cara bacanya dari frontend:** query object langsung, field-nya udah include di response.

```ts
// Query semua Note milik user
const notes = await client.core.listOwnedObjects({
  owner: userAddress,
  type: NOTES_TYPES.Note,
});

// Detail satu Note
const note = await client.core.getObject({
  id: noteObjectId,
  include: { bcs: false, content: true },
});
// data ada di note.content.fields.title, .content, .created_at, .updated_at
```

---

## 6. Events

Tiap aksi emit event untuk tracking/indexing.

### 6.1 `NoteCreated`
```
type: {PACKAGE_ID}::notes::NoteCreated
```
| Field | Type |
|---|---|
| `id` | `ID` (address) |
| `title` | `String` |
| `owner` | `address` |
| `created_at` | `u64` |

### 6.2 `NoteUpdated`
```
type: {PACKAGE_ID}::notes::NoteUpdated
```
| Field | Type |
|---|---|
| `id` | `ID` (address) |
| `updated_at` | `u64` |

### 6.3 `NoteDeleted`
```
type: {PACKAGE_ID}::notes::NoteDeleted
```
| Field | Type |
|---|---|
| `id` | `ID` (address) |

```ts
// Subscribe events via gRPC
for await (const event of client.subscriptionService.subscribeEvents({
  filter: { MoveEventModule: { package: NOTES_PACKAGE_ID, module: NOTES_MODULE } },
})) {
  console.log(event.type, event.parsedJson);
}
```

---

## 7. Error Codes

| Code | Constant | Trigger |
|---|---|---|
| `1` | `ETitleTooLong` | Title > 200 karakter |
| `2` | `EContentTooLong` | Content > 10.000 karakter |

---

## 8. Validasi Input

| Field | Batas | Type |
|---|---|---|
| `title` | Max **200** karakter | `String` |
| `content` | Max **10.000** karakter | `String` |

Validasi ada di on-chain — transaksi akan **abort** jika melebihi batas. Tetap disarankan validasi di frontend juga sebelum submit tx.

---

## 9. Full PTB Examples

### Create Note
```ts
import { Transaction } from "@mysten/sui/transactions";

const tx = new Transaction();
tx.moveCall({
  target: `${NOTES_PACKAGE_ID}::${NOTES_MODULE}::create_note`,
  arguments: [
    tx.pure.string("Judul Catatan"),
    tx.pure.string("Isi konten di sini..."),
    tx.object("0x6"),
  ],
});

const result = await dAppKit.signAndExecuteTransaction({ transaction: tx });
if (result.$kind !== "FailedTransaction") {
  console.log("Created! Digest:", result.Transaction.digest);
}
```

### Update Content
```ts
const tx = new Transaction();
tx.moveCall({
  target: `${NOTES_PACKAGE_ID}::${NOTES_MODULE}::update_content`,
  arguments: [
    tx.object("0xNOTE_OBJECT_ID"),  // Note object ID
    tx.pure.string("Konten baru..."),
    tx.object("0x6"),
  ],
});
```

### Delete Note
```ts
const tx = new Transaction();
tx.moveCall({
  target: `${NOTES_PACKAGE_ID}::${NOTES_MODULE}::delete_note`,
  arguments: [tx.object("0xNOTE_OBJECT_ID")],
});
```

---

## 10. Pengingat untuk Tim FE

| # | Notes |
|---|---|
| 1 | **Devnet di-wipe mingguan** — setelah reset, package harus di-deploy ulang dan `PACKAGE_ID` berubah. Pantau `#devnet-updates` di Discord Sui. |
| 2 | Object `Clock` (`0x6`) **wajib** dioper ke `create_note`, `update_title`, dan `update_content`. Jangan lupa. |
| 3 | Setelah `signAndExecuteTransaction`, **wajib** `waitForTransaction` dulu sebelum refetch query biar data gak stale. |
| 4 | Buat query owned objects, pakai `listOwnedObjects` dengan type filter `{PACKAGE_ID}::notes::Note`. |
| 5 | Semua timestamp dalam **milidetik** (bukan detik). |
| 6 | Gunakan `@mysten/dapp-kit-react` (bukan `@mysten/dapp-kit` polos, itu deprecated). |
| 7 | `Note` adalah **address-owned object** — bukan shared object. Jadi setiap user cuma bisa lihat Note miliknya sendiri. |

---

## 11. Links

| Resource | URL |
|---|---|
| Sui Devnet Explorer | https://suiscan.xyz/devnet |
| Package (Suiscan) | `https://suiscan.xyz/devnet/package/{PACKAGE_ID}` |
| Sui Docs | https://docs.sui.io |
| TypeScript SDK | https://sdk.mystenlabs.com |
| dApp Kit | https://sdk.mystenlabs.com/dapp-kit |
