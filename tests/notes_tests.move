#[test_only]
module belajar_sui_move::notes_tests {
    use belajar_sui_move::notes::{Self, Note};
    use std::string::{Self, String};
    use sui::clock::Clock;
    use sui::test_scenario::{Self, Scenario};

    const ALICE: address = @0xA;
    const BOB: address = @0xB;

    // ── Helper: setup scenario with system objects ──────────────
    fun setup(sender: address): Scenario {
        let mut scenario = test_scenario::begin(sender);
        test_scenario::create_system_objects(&mut scenario);
        scenario
    }

    // ── Helper: create a Note and return it ─────────────────────
    fun create(
        scenario: &mut Scenario,
        sender: address,
        title: vector<u8>,
        content: vector<u8>,
    ): Note {
        test_scenario::next_tx(scenario, sender);
        {
            let clock = test_scenario::take_shared<Clock>(scenario);
            notes::create_note(
                string::utf8(title),
                string::utf8(content),
                &clock,
                test_scenario::ctx(scenario),
            );
            test_scenario::return_shared(clock);
        };
        test_scenario::next_tx(scenario, sender);
        test_scenario::take_from_sender<Note>(scenario)
    }

    // ── Helper: create a Note owned by ALICE (shorthand) ───────
    fun create_alice(scenario: &mut Scenario): Note {
        create(scenario, ALICE, b"catatan-1", b"isi catatan pertama")
    }

    // ── Helper: compare a &String with expected bytes ───────────
    fun str_eq(s: &String, expected: vector<u8>): bool {
        string::as_bytes(s) == &expected
    }

    // ══════════════════════════════════════════════════════════════
    //  CREATE tests
    // ══════════════════════════════════════════════════════════════

    #[test]
    fun test_create_note() {
        let mut scenario = setup(ALICE);
        {
            let note = create_alice(&mut scenario);
            assert!(str_eq(notes::title(&note), b"catatan-1"));
            assert!(str_eq(notes::content(&note), b"isi catatan pertama"));
            assert!(notes::created_at(&note) >= 0);
            assert!(notes::updated_at(&note) >= 0);
            test_scenario::return_to_sender(&scenario, note);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_create_multiple_notes() {
        let mut scenario = setup(ALICE);
        {
            let note1 = create(
                &mut scenario, ALICE,
                b"judul-A", b"isi-A",
            );
            let note2 = create(
                &mut scenario, ALICE,
                b"judul-B", b"isi-B",
            );
            assert!(str_eq(notes::title(&note1), b"judul-A"));
            assert!(str_eq(notes::title(&note2), b"judul-B"));
            test_scenario::return_to_sender(&scenario, note1);
            test_scenario::return_to_sender(&scenario, note2);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_create_note_for_different_owners() {
        let mut scenario = setup(ALICE);
        {
            let note_alice = create_alice(&mut scenario);
            let note_bob = create(
                &mut scenario, BOB,
                b"catatan-bob", b"isi dari bob",
            );
            assert!(str_eq(notes::title(&note_alice), b"catatan-1"));
            assert!(str_eq(notes::title(&note_bob), b"catatan-bob"));
            test_scenario::return_to_address(ALICE, note_alice);
            test_scenario::return_to_address(BOB, note_bob);
        };
        test_scenario::end(scenario);
    }

    // ══════════════════════════════════════════════════════════════
    //  UPDATE tests
    // ══════════════════════════════════════════════════════════════

    #[test]
    fun test_update_content() {
        let mut scenario = setup(ALICE);
        {
            let mut note = create_alice(&mut scenario);
            test_scenario::next_tx(&mut scenario, ALICE);
            {
                let clock = test_scenario::take_shared<Clock>(&scenario);
                notes::update_content(
                    &mut note,
                    string::utf8(b"konten baru!"),
                    &clock,
                );
                test_scenario::return_shared(clock);
            };
            assert!(str_eq(notes::content(&note), b"konten baru!"));
            assert!(notes::updated_at(&note) >= notes::created_at(&note));
            test_scenario::return_to_sender(&scenario, note);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_update_title() {
        let mut scenario = setup(ALICE);
        {
            let mut note = create_alice(&mut scenario);
            test_scenario::next_tx(&mut scenario, ALICE);
            {
                let clock = test_scenario::take_shared<Clock>(&scenario);
                notes::update_title(
                    &mut note,
                    string::utf8(b"judul-baru"),
                    &clock,
                );
                test_scenario::return_shared(clock);
            };
            assert!(str_eq(notes::title(&note), b"judul-baru"));
            // Content tidak berubah
            assert!(str_eq(notes::content(&note), b"isi catatan pertama"));
            test_scenario::return_to_sender(&scenario, note);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_update_multiple_times() {
        let mut scenario = setup(ALICE);
        {
            let mut note = create_alice(&mut scenario);
            // Update pertama
            test_scenario::next_tx(&mut scenario, ALICE);
            {
                let clock = test_scenario::take_shared<Clock>(&scenario);
                notes::update_content(
                    &mut note,
                    string::utf8(b"revisi-1"),
                    &clock,
                );
                test_scenario::return_shared(clock);
            };
            // Update kedua
            test_scenario::next_tx(&mut scenario, ALICE);
            {
                let clock = test_scenario::take_shared<Clock>(&scenario);
                notes::update_content(
                    &mut note,
                    string::utf8(b"revisi-2"),
                    &clock,
                );
                test_scenario::return_shared(clock);
            };
            assert!(str_eq(notes::content(&note), b"revisi-2"));
            test_scenario::return_to_sender(&scenario, note);
        };
        test_scenario::end(scenario);
    }

    // ══════════════════════════════════════════════════════════════
    //  DELETE tests
    // ══════════════════════════════════════════════════════════════

    #[test]
    fun test_delete_note() {
        let mut scenario = setup(ALICE);
        {
            let note = create_alice(&mut scenario);
            test_scenario::next_tx(&mut scenario, ALICE);
            notes::delete_note(note);
            // Note sudah dihapus, tidak ada yang perlu dikembalikan
        };
        test_scenario::end(scenario);
    }

    // ══════════════════════════════════════════════════════════════
    //  Full CRUD flow
    // ══════════════════════════════════════════════════════════════

    #[test]
    fun test_full_crud_flow() {
        let mut scenario = setup(ALICE);
        {
            // CREATE
            let mut note = create(
                &mut scenario, ALICE,
                b"belajar-sui", b"Move is fun!",
            );
            assert!(str_eq(notes::title(&note), b"belajar-sui"));
            assert!(str_eq(notes::content(&note), b"Move is fun!"));
            let created = notes::created_at(&note);

            // UPDATE content
            test_scenario::next_tx(&mut scenario, ALICE);
            {
                let clock = test_scenario::take_shared<Clock>(&scenario);
                notes::update_content(
                    &mut note,
                    string::utf8(b"Sui Move is awesome!"),
                    &clock,
                );
                test_scenario::return_shared(clock);
            };
            assert!(str_eq(notes::content(&note), b"Sui Move is awesome!"));

            // UPDATE title
            test_scenario::next_tx(&mut scenario, ALICE);
            {
                let clock = test_scenario::take_shared<Clock>(&scenario);
                notes::update_title(
                    &mut note,
                    string::utf8(b"belajar-sui-move"),
                    &clock,
                );
                test_scenario::return_shared(clock);
            };
            assert!(str_eq(notes::title(&note), b"belajar-sui-move"));
            assert!(notes::updated_at(&note) >= created);

            // DELETE
            test_scenario::next_tx(&mut scenario, ALICE);
            notes::delete_note(note);
        };
        test_scenario::end(scenario);
    }
}
