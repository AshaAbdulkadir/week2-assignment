-- Library Management Database
-- MSAI-5523 | Week 2 Assignment

PRAGMA foreign_keys = ON;

-- ── Books ────────────────────────────────────────────────────────────────────

CREATE TABLE books (
    book_id             INTEGER PRIMARY KEY AUTOINCREMENT,
    isbn                TEXT    UNIQUE,
    title               TEXT    NOT NULL,
    authors             TEXT,
    publisher           TEXT,
    publication_year    INTEGER,
    genre               TEXT,
    language            TEXT    DEFAULT 'English',
    is_stocked          INTEGER NOT NULL DEFAULT 1  -- 0 = only via interlibrary loan
);

-- ── Physical copies held by this library ────────────────────────────────────

CREATE TABLE copies (
    copy_id         INTEGER PRIMARY KEY AUTOINCREMENT,
    book_id         INTEGER NOT NULL REFERENCES books(book_id),
    condition       TEXT    NOT NULL DEFAULT 'good'
                            CHECK(condition IN ('good', 'fair', 'poor')),
    status          TEXT    NOT NULL DEFAULT 'available'
                            CHECK(status IN ('available', 'on_loan', 'reserved', 'lost', 'withdrawn')),
    acquired_date   TEXT    NOT NULL  -- yyyy-MM-dd
);

-- ── Borrowers ────────────────────────────────────────────────────────────────

CREATE TABLE borrowers (
    borrower_id         INTEGER PRIMARY KEY AUTOINCREMENT,
    first_name          TEXT    NOT NULL,
    last_name           TEXT    NOT NULL,
    email               TEXT    NOT NULL UNIQUE,
    phone               TEXT,
    address             TEXT,
    membership_date     TEXT    NOT NULL,  -- yyyy-MM-dd
    status              TEXT    NOT NULL DEFAULT 'active'
                                CHECK(status IN ('active', 'suspended'))
);

-- ── Loans ────────────────────────────────────────────────────────────────────

CREATE TABLE loans (
    loan_id             INTEGER PRIMARY KEY AUTOINCREMENT,
    copy_id             INTEGER NOT NULL REFERENCES copies(copy_id),
    borrower_id         INTEGER NOT NULL REFERENCES borrowers(borrower_id),
    loan_date           TEXT    NOT NULL,   -- yyyy-MM-dd
    due_date            TEXT    NOT NULL,   -- yyyy-MM-dd
    return_date         TEXT,               -- yyyy-MM-dd, NULL while on loan
    daily_late_fee_rate REAL    NOT NULL DEFAULT 0.25,  -- USD per day, locked at loan time
    status              TEXT    NOT NULL DEFAULT 'active'
                                CHECK(status IN ('active', 'returned', 'overdue'))
);

-- ── Loan Extensions ──────────────────────────────────────────────────────────

CREATE TABLE loan_extensions (
    extension_id        INTEGER PRIMARY KEY AUTOINCREMENT,
    loan_id             INTEGER NOT NULL REFERENCES loans(loan_id),
    requested_date      TEXT    NOT NULL,   -- yyyy-MM-dd
    previous_due_date   TEXT    NOT NULL,   -- yyyy-MM-dd
    new_due_date        TEXT    NOT NULL,   -- yyyy-MM-dd
    extension_days      INTEGER NOT NULL
);

-- ── Reservations (hold queue when a book is out of stock) ───────────────────

CREATE TABLE reservations (
    reservation_id      INTEGER PRIMARY KEY AUTOINCREMENT,
    book_id             INTEGER NOT NULL REFERENCES books(book_id),
    borrower_id         INTEGER NOT NULL REFERENCES borrowers(borrower_id),
    reservation_date    TEXT    NOT NULL,   -- yyyy-MM-dd
    expiry_date         TEXT    NOT NULL,   -- reservation_date + 7 days
    status              TEXT    NOT NULL DEFAULT 'pending'
                                CHECK(status IN ('pending', 'fulfilled', 'expired', 'cancelled'))
);

-- ── Late Fees ────────────────────────────────────────────────────────────────

CREATE TABLE late_fees (
    fee_id          INTEGER PRIMARY KEY AUTOINCREMENT,
    loan_id         INTEGER NOT NULL REFERENCES loans(loan_id),
    borrower_id     INTEGER NOT NULL REFERENCES borrowers(borrower_id),
    days_overdue    INTEGER NOT NULL,
    daily_rate      REAL    NOT NULL,
    total_amount    REAL    NOT NULL,   -- days_overdue * daily_rate
    paid            INTEGER NOT NULL DEFAULT 0,  -- 0 = unpaid, 1 = paid
    paid_date       TEXT                         -- yyyy-MM-dd
);

-- ── Partner Libraries ────────────────────────────────────────────────────────

CREATE TABLE partner_libraries (
    library_id  INTEGER PRIMARY KEY AUTOINCREMENT,
    name        TEXT    NOT NULL,
    address     TEXT,
    city        TEXT,
    phone       TEXT,
    email       TEXT
);

-- ── Interlibrary Requests ────────────────────────────────────────────────────

CREATE TABLE interlibrary_requests (
    request_id              INTEGER PRIMARY KEY AUTOINCREMENT,
    book_id                 INTEGER NOT NULL REFERENCES books(book_id),
    partner_library_id      INTEGER NOT NULL REFERENCES partner_libraries(library_id),
    borrower_id             INTEGER NOT NULL REFERENCES borrowers(borrower_id),
    request_date            TEXT    NOT NULL,   -- yyyy-MM-dd
    scheduled_pickup_date   TEXT,               -- yyyy-MM-dd, set when ready
    pickup_status           TEXT    NOT NULL DEFAULT 'requested'
                                    CHECK(pickup_status IN (
                                        'requested', 'in_transit', 'ready_for_pickup',
                                        'picked_up', 'returned'
                                    )),
    due_date                TEXT,               -- yyyy-MM-dd, set when picked up
    return_date             TEXT                -- yyyy-MM-dd
);

-- ── Indexes ──────────────────────────────────────────────────────────────────

CREATE INDEX idx_copies_book        ON copies(book_id);
CREATE INDEX idx_copies_status      ON copies(status);
CREATE INDEX idx_loans_borrower     ON loans(borrower_id);
CREATE INDEX idx_loans_status       ON loans(status);
CREATE INDEX idx_loans_due          ON loans(due_date);
CREATE INDEX idx_reservations_book  ON reservations(book_id);
CREATE INDEX idx_reservations_status ON reservations(status);
CREATE INDEX idx_late_fees_borrower ON late_fees(borrower_id);
CREATE INDEX idx_late_fees_paid     ON late_fees(paid);
CREATE INDEX idx_ill_borrower       ON interlibrary_requests(borrower_id);
CREATE INDEX idx_ill_status         ON interlibrary_requests(pickup_status);
