# Belajar Sui Move - CRUD Notes

Smart contract CRUD (Create, Read, Update, Delete) untuk catatan (notes) di blockchain Sui. Dibangun dengan Move 2024 edition.

## Package Info

|              |                                                                     |
| ------------ | ------------------------------------------------------------------- |
| Package ID   | `0xc322e23b4f168acd1f769aa29fb8301902f085a4be57b3a64faed065ec5b5b4d` |
| Network      | Devnet                                                              |
| Module       | `notes`                                                             |
| Edition      | 2024                                                                |

## Struktur Module

### Struct Note

```
Note {
    id:         UID,
    title:      String,
    content:    String,
    created_at: u64,   // timestamp ms
    updated_at: u64,   // timestamp ms
}
```

### Entry Functions

| Function          | Parameter                                                 | Keterangan          |
| ----------------- | --------------------------------------------------------- | ------------------- |
| `create_note`     | `title: String, content: String, clock: &Clock`           | Buat catatan baru   |
| `update_content`  | `note: &mut Note, new_content: String, clock: &Clock`     | Ubah isi catatan    |
| `update_title`    | `note: &mut Note, new_title: String, clock: &Clock`       | Ubah judul catatan  |
| `delete_note`     | `note: Note`                                              | Hapus catatan       |

### Getter Functions (public)

- `title(note: &Note): &String`
- `content(note: &Note): &String`
- `created_at(note: &Note): u64`
- `updated_at(note: &Note): u64`

### Events

- `NoteCreated { id, title, owner, created_at }`
- `NoteUpdated { id, updated_at }`
- `NoteDeleted { id }`

### Validasi Input

- `title` maksimal 200 karakter
- `content` maksimal 10.000 karakter

## Prasyarat

- [Sui CLI](https://docs.sui.io/guides/developer/getting-started/sui-install) sudah terinstall
- Wallet address dengan saldo SUI (devnet bisa pakai faucet)

## Build & Test

```bash
# Kompilasi package
sui move build

# Jalankan semua unit test
sui move test

# Jalankan test spesifik
sui move test --filter test_create_note
```

## Deploy

```bash
# Pastikan environment aktif adalah devnet
sui client active-env

# Deploy package baru
sui client publish

# Upgrade package yang sudah ada
sui client upgrade --upgrade-capability <upgrade-cap-id>
```

Setelah publish, data deployment otomatis tercatat di `Published.toml`.

## Interaksi dengan Contract

### Create Note

```bash
sui client call \
  --package 0xc322e23b4f168acd1f769aa29fb8301902f085a4be57b3a64faed065ec5b5b4d \
  --module notes \
  --function create_note \
  --args "Judul Catatan" "Isi catatan di sini" 0x6 \
  --gas-budget 10000000
```

Parameter `0x6` adalah address system object `Clock` milik Sui, diperlukan untuk timestamp.

### Read All Notes

```bash
# Lihat semua object milik address
sui client objects

# Lihat detail satu note
sui client object <note_object_id>
```

### Update Content

```bash
sui client call \
  --package 0xc322e23b4f168acd1f769aa29fb8301902f085a4be57b3a64faed065ec5b5b4d \
  --module notes \
  --function update_content \
  --args <note_object_id> "Konten baru" 0x6 \
  --gas-budget 10000000
```

### Update Title

```bash
sui client call \
  --package 0xc322e23b4f168acd1f769aa29fb8301902f085a4be57b3a64faed065ec5b5b4d \
  --module notes \
  --function update_title \
  --args <note_object_id> "Judul baru" 0x6 \
  --gas-budget 10000000
```

### Delete Note

```bash
sui client call \
  --package 0xc322e23b4f168acd1f769aa29fb8301902f085a4be57b3a64faed065ec5b5b4d \
  --module notes \
  --function delete_note \
  --args <note_object_id> \
  --gas-budget 10000000
```

## Struktur Direktori

```
belajar_sui_move/
  Move.toml          # Package manifest
  Published.toml     # Metadata publish (auto-generated)
  sources/
    notes.move       # Module CRUD Notes
  tests/
    notes_tests.move # 8 unit test
```

## Link Explorer

- [Package di SuiScan Devnet](https://suiscan.xyz/devnet/object/0xc322e23b4f168acd1f769aa29fb8301902f085a4be57b3a64faed065ec5b5b4d)
