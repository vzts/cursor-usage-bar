import Foundation
import SQLite3

/// Regression guard for the WAL-sidecar failure mode:
/// plain SQLITE_OPEN_READONLY can fail prepare with SQLITE_CANTOPEN when
/// state.vscdb is WAL and -wal/-shm are absent. The app must use immutable=1.
let path = NSHomeDirectory()
  + "/Library/Application Support/Cursor/User/globalStorage/state.vscdb"

guard FileManager.default.fileExists(atPath: path) else {
  fputs("skip: no Cursor state.vscdb (sign in to Cursor IDE once, then re-run)\n", stderr)
  exit(0)
}

let encoded = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? path
let uri = "file:\(encoded)?mode=ro&immutable=1"
var db: OpaquePointer?
guard sqlite3_open_v2(uri, &db, SQLITE_OPEN_READONLY | SQLITE_OPEN_URI, nil) == SQLITE_OK,
      let db else {
  fputs("fail: could not open state.vscdb with immutable=1\n", stderr)
  exit(1)
}
defer { sqlite3_close(db) }

var stmt: OpaquePointer?
let sql = "SELECT length(value) FROM ItemTable WHERE key = 'cursorAuth/accessToken' LIMIT 1;"
guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let stmt else {
  fputs(
    "fail: prepare failed (\(String(cString: sqlite3_errmsg(db)))) — WAL-safe open regressed\n",
    stderr
  )
  exit(1)
}
defer { sqlite3_finalize(stmt) }

guard sqlite3_step(stmt) == SQLITE_ROW else {
  fputs("fail: no cursorAuth/accessToken row (sign in to Cursor IDE once)\n", stderr)
  exit(1)
}

print("ok: session DB readable via immutable=1 (token length \(sqlite3_column_int(stmt, 0)))")
