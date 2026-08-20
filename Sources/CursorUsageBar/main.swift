import AppKit
import Foundation
import SQLite3

@main
enum CursorUsageBarMain {
  static func main() {
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)
    _ = UsageBarController.shared
    app.run()
  }
}

final class UsageBarController: NSObject {
  static let shared = UsageBarController()

  private let statusItem: NSStatusItem
  private let menu = NSMenu()
  private var refreshTimer: Timer?
  private var lastSummary: UsageSummary?

  private let autoItem = NSMenuItem(title: "Auto: —", action: nil, keyEquivalent: "")
  private let apiItem = NSMenuItem(title: "API: —", action: nil, keyEquivalent: "")
  private let onDemandItem = NSMenuItem(title: "On-demand: —", action: nil, keyEquivalent: "")
  private let planItem = NSMenuItem(title: "Plan: —", action: nil, keyEquivalent: "")
  private let cycleItem = NSMenuItem(title: "Cycle: —", action: nil, keyEquivalent: "")
  private let messageItem = NSMenuItem(title: "—", action: nil, keyEquivalent: "")
  private let errorItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")

  private override init() {
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    super.init()

    if let button = statusItem.button {
      button.title = "C …"
      button.toolTip = "Cursor usage"
    }

    messageItem.isEnabled = false
    autoItem.isEnabled = false
    apiItem.isEnabled = false
    onDemandItem.isEnabled = false
    planItem.isEnabled = false
    cycleItem.isEnabled = false
    errorItem.isEnabled = false
    errorItem.isHidden = true

    menu.addItem(messageItem)
    menu.addItem(.separator())
    menu.addItem(autoItem)
    menu.addItem(apiItem)
    menu.addItem(onDemandItem)
    menu.addItem(.separator())
    menu.addItem(planItem)
    menu.addItem(cycleItem)
    menu.addItem(.separator())
    menu.addItem(errorItem)

    let refresh = NSMenuItem(title: "Refresh", action: #selector(refreshNow), keyEquivalent: "r")
    refresh.target = self
    menu.addItem(refresh)

    let dashboard = NSMenuItem(title: "Open Dashboard", action: #selector(openDashboard), keyEquivalent: "o")
    dashboard.target = self
    menu.addItem(dashboard)

    menu.addItem(.separator())
    let quit = NSMenuItem(title: "Quit CursorUsageBar", action: #selector(quitApp), keyEquivalent: "q")
    quit.target = self
    menu.addItem(quit)

    statusItem.menu = menu

    refreshNow()
    refreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
      self?.refreshNow()
    }
  }

  @objc private func quitApp() {
    NSApp.terminate(nil)
  }

  @objc private func openDashboard() {
    if let url = URL(string: "https://cursor.com/dashboard") {
      NSWorkspace.shared.open(url)
    }
  }

  @objc private func refreshNow() {
    DispatchQueue.global(qos: .utility).async {
      do {
        let summary = try UsageFetcher.fetch()
        DispatchQueue.main.async {
          self.lastSummary = summary
          self.apply(summary)
          self.errorItem.isHidden = true
        }
      } catch {
        DispatchQueue.main.async {
          self.statusItem.button?.title = "C ?"
          self.errorItem.title = "Error: \(error.localizedDescription)"
          self.errorItem.isHidden = false
        }
      }
    }
  }

  private func apply(_ summary: UsageSummary) {
    let total = summary.totalPercent
    statusItem.button?.title = String(format: "C %.0f%%", total)
    statusItem.button?.toolTip = summary.totalMessage

    messageItem.title = summary.totalMessage
    autoItem.title = String(format: "Auto / Composer: %.0f%%", summary.autoPercent)
    apiItem.title = String(format: "API / Other models: %.0f%%", summary.apiPercent)

    if summary.onDemandEnabled {
      if let limit = summary.onDemandLimit, limit > 0 {
        onDemandItem.title = String(
          format: "On-demand: $%.2f / $%.2f",
          Double(summary.onDemandUsed) / 100.0,
          Double(limit) / 100.0
        )
      } else {
        onDemandItem.title = String(
          format: "On-demand: $%.2f used",
          Double(summary.onDemandUsed) / 100.0
        )
      }
    } else {
      onDemandItem.title = "On-demand: off"
    }

    planItem.title = "Plan: \(summary.membershipType)"
    cycleItem.title = "Resets: \(summary.cycleEndText)"
  }
}

struct UsageSummary {
  var membershipType: String
  var autoPercent: Double
  var apiPercent: Double
  var totalPercent: Double
  var totalMessage: String
  var onDemandEnabled: Bool
  var onDemandUsed: Int
  var onDemandLimit: Int?
  var cycleEndText: String
}

enum UsageFetcher {
  enum FetchError: LocalizedError {
    case noToken
    case badJWT
    case http(Int)
    case decode

    var errorDescription: String? {
      switch self {
      case .noToken: return "Cursor access token not found (sign in to Cursor IDE)"
      case .badJWT: return "Could not parse Cursor token"
      case .http(let code): return "HTTP \(code)"
      case .decode: return "Unexpected usage response"
      }
    }
  }

  static func fetch() throws -> UsageSummary {
    let token = try readAccessToken()
    let sub = try jwtSubject(token)
    let cookieValue = "\(sub)%3A%3A\(token)"

    var request = URLRequest(url: URL(string: "https://cursor.com/api/usage-summary")!)
    request.setValue("WorkosCursorSessionToken=\(cookieValue)", forHTTPHeaderField: "Cookie")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
    request.timeoutInterval = 20

    let sema = DispatchSemaphore(value: 0)
    var dataBox: Data?
    var responseBox: URLResponse?
    var errorBox: Error?

    URLSession.shared.dataTask(with: request) { data, response, error in
      dataBox = data
      responseBox = response
      errorBox = error
      sema.signal()
    }.resume()
    _ = sema.wait(timeout: .now() + 25)

    if let errorBox { throw errorBox }
    guard let http = responseBox as? HTTPURLResponse else { throw FetchError.http(-1) }
    guard (200..<300).contains(http.statusCode), let dataBox else {
      throw FetchError.http(http.statusCode)
    }

    guard let json = try JSONSerialization.jsonObject(with: dataBox) as? [String: Any] else {
      throw FetchError.decode
    }

    let membership = (json["membershipType"] as? String) ?? "unknown"
    let individual = json["individualUsage"] as? [String: Any] ?? [:]
    let plan = individual["plan"] as? [String: Any] ?? [:]
    let onDemand = individual["onDemand"] as? [String: Any] ?? [:]

    let auto = (plan["autoPercentUsed"] as? Double)
      ?? (plan["autoPercentUsed"] as? NSNumber)?.doubleValue
      ?? 0
    let api = (plan["apiPercentUsed"] as? Double)
      ?? (plan["apiPercentUsed"] as? NSNumber)?.doubleValue
      ?? 0
    let totalOptional = (plan["totalPercentUsed"] as? Double)
      ?? (plan["totalPercentUsed"] as? NSNumber)?.doubleValue
    let totalPercent = totalOptional ?? max(auto, api)

    let message = (json["autoModelSelectedDisplayMessage"] as? String)
      ?? String(format: "You've used %.0f%% of your included total usage", totalPercent)

    let cycleEnd = json["billingCycleEnd"] as? String
    let cycleText: String = {
      guard let cycleEnd, let date = ISO8601DateFormatter().date(from: cycleEnd)
              ?? parseFractionalISO(cycleEnd) else { return "—" }
      let fmt = DateFormatter()
      fmt.locale = Locale(identifier: "en_US_POSIX")
      fmt.dateStyle = .medium
      fmt.timeStyle = .none
      let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
      return "\(fmt.string(from: date)) (\(max(days, 0))d)"
    }()

    return UsageSummary(
      membershipType: membership,
      autoPercent: auto,
      apiPercent: api,
      totalPercent: totalPercent,
      totalMessage: message,
      onDemandEnabled: (onDemand["enabled"] as? Bool) ?? false,
      onDemandUsed: (onDemand["used"] as? Int) ?? 0,
      onDemandLimit: onDemand["limit"] as? Int,
      cycleEndText: cycleText
    )
  }

  private static func parseFractionalISO(_ raw: String) -> Date? {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.date(from: raw)
  }

  private static func readAccessToken() throws -> String {
    let path = NSHomeDirectory() + "/Library/Application Support/Cursor/User/globalStorage/state.vscdb"
    var db: OpaquePointer?
    guard sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK, let db else {
      throw FetchError.noToken
    }
    defer { sqlite3_close(db) }

    let sql = "SELECT value FROM ItemTable WHERE key = 'cursorAuth/accessToken' LIMIT 1;"
    var stmt: OpaquePointer?
    guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let stmt else {
      throw FetchError.noToken
    }
    defer { sqlite3_finalize(stmt) }

    guard sqlite3_step(stmt) == SQLITE_ROW,
          let cString = sqlite3_column_text(stmt, 0) else {
      throw FetchError.noToken
    }
    return String(cString: cString)
  }

  private static func jwtSubject(_ token: String) throws -> String {
    let parts = token.split(separator: ".")
    guard parts.count >= 2 else { throw FetchError.badJWT }
    var base64 = String(parts[1])
      .replacingOccurrences(of: "-", with: "+")
      .replacingOccurrences(of: "_", with: "/")
    while base64.count % 4 != 0 { base64.append("=") }
    guard let data = Data(base64Encoded: base64),
          let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
          let sub = json["sub"] as? String else {
      throw FetchError.badJWT
    }
    return sub
  }
}
