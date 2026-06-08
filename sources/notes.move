/// Module: notes
/// CRUD Notes on Sui. Each Note is an owned object.
/// Create, read (getters), update (title & content), and delete.

module belajar_sui_move::notes {
    use std::string::{Self, String};
    use sui::clock::Clock;
    use sui::event;
    use sui::object::{Self, ID, UID};
    use sui::transfer;
    use sui::tx_context::TxContext;

    // ── Error codes ──────────────────────────────────────────────
    const ETitleTooLong: u64 = 1;
    const EContentTooLong: u64 = 2;

    // ── Limits ───────────────────────────────────────────────────
    const MAX_TITLE_LENGTH: u64 = 200;
    const MAX_CONTENT_LENGTH: u64 = 10_000;

    // ── Note object ──────────────────────────────────────────────
    public struct Note has key, store {
        id:         UID,
        title:      String,
        content:    String,
        created_at: u64,
        updated_at: u64,
    }

    // ── Events ───────────────────────────────────────────────────
    public struct NoteCreated has copy, drop {
        id:         ID,
        title:      String,
        owner:      address,
        created_at: u64,
    }

    public struct NoteUpdated has copy, drop {
        id:         ID,
        updated_at: u64,
    }

    public struct NoteDeleted has copy, drop {
        id: ID,
    }

    // ══════════════════════════════════════════════════════════════
    //  CREATE
    // ══════════════════════════════════════════════════════════════

    entry fun create_note(
        title: String,
        content: String,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        // Validasi panjang input
        assert!(title.length() as u64 <= MAX_TITLE_LENGTH, ETitleTooLong);
        assert!(content.length() as u64 <= MAX_CONTENT_LENGTH, EContentTooLong);

        let now = clock.timestamp_ms();

        let note = Note {
            id: object::new(ctx),
            title,
            content,
            created_at: now,
            updated_at: now,
        };

        event::emit(NoteCreated {
            id:         object::id(&note),
            title:      note.title,
            owner:      ctx.sender(),
            created_at: now,
        });

        transfer::public_transfer(note, ctx.sender());
    }

    // ══════════════════════════════════════════════════════════════
    //  UPDATE — content
    // ══════════════════════════════════════════════════════════════

    entry fun update_content(note: &mut Note, new_content: String, clock: &Clock) {
        assert!(new_content.length() as u64 <= MAX_CONTENT_LENGTH, EContentTooLong);

        note.content = new_content;
        note.updated_at = clock.timestamp_ms();

        event::emit(NoteUpdated {
            id:         object::id(note),
            updated_at: note.updated_at,
        });
    }

    // ══════════════════════════════════════════════════════════════
    //  UPDATE — title
    // ══════════════════════════════════════════════════════════════

    entry fun update_title(note: &mut Note, new_title: String, clock: &Clock) {
        assert!(new_title.length() as u64 <= MAX_TITLE_LENGTH, ETitleTooLong);

        note.title = new_title;
        note.updated_at = clock.timestamp_ms();

        event::emit(NoteUpdated {
            id:         object::id(note),
            updated_at: note.updated_at,
        });
    }

    // ══════════════════════════════════════════════════════════════
    //  DELETE
    // ══════════════════════════════════════════════════════════════

    entry fun delete_note(note: Note) {
        let id = object::id(&note);
        event::emit(NoteDeleted { id });

        let Note { id, title: _, content: _, created_at: _, updated_at: _ } = note;
        object::delete(id);
    }

    // ══════════════════════════════════════════════════════════════
    //  GETTERS (public — callable from frontend, tests, other modules)
    // ══════════════════════════════════════════════════════════════

    public fun title(note: &Note): &String {
        &note.title
    }

    public fun content(note: &Note): &String {
        &note.content
    }

    public fun created_at(note: &Note): u64 {
        note.created_at
    }

    public fun updated_at(note: &Note): u64 {
        note.updated_at
    }
}
