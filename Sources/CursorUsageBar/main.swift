import AppKit
import Foundation
import SQLite3

/// Refresh policy aligned with ClaudeBar/CodexBar/SessionWatcher practice:
/// - 1 minute floor while recently interacting (menu opened)
/// - 5 minutes when idle (same default CursorBar uses for this API)
/// - always refresh immediately when the menu opens
private enum RefreshPolicy {
  static let active: TimeInterval = 60
  static let idle: TimeInterval = 300
  static let recentInteraction: TimeInterval = 5 * 60
}

@main
enum CursorUsageBarMain {
  static func main() {
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)
    _ = UsageBarController.shared
    app.run()
  }
}

final class UsageBarController: NSObject, NSMenuDelegate {
  static let shared = UsageBarController()

  private let statusItem: NSStatusItem
  private let menu = NSMenu()
  private var refreshTimer: Timer?
  private var lastSummary: UsageSummary?
  private var isRefreshing = false
  private var lastMenuOpenAt: Date?

  private let autoItem = NSMenuItem(title: "Auto: —", action: nil, keyEquivalent: "")
  private let apiItem = NSMenuItem(title: "API: —", action: nil, keyEquivalent: "")
  private let onDemandItem = NSMenuItem(title: "On-demand: —", action: nil, keyEquivalent: "")
  private let creditsItem = NSMenuItem(title: "Credits: —", action: nil, keyEquivalent: "")
  private let creditsExpireItem = NSMenuItem(title: "Credits expire: —", action: nil, keyEquivalent: "")
  private let planItem = NSMenuItem(title: "Plan: —", action: nil, keyEquivalent: "")
  private let cycleItem = NSMenuItem(title: "Cycle: —", action: nil, keyEquivalent: "")
  private let messageItem = NSMenuItem(title: "—", action: nil, keyEquivalent: "")
  private let errorItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")

  private override init() {
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    super.init()

    if let button = statusItem.button {
      button.imagePosition = .imageOnly
      button.title = ""
      applyStatusImage(StatusArtwork.ring(percent: nil), tooltip: "Cursor usage")
    }

    for item in [
      messageItem, autoItem, apiItem, onDemandItem, creditsItem, creditsExpireItem,
      planItem, cycleItem, errorItem,
    ] {
      item.isEnabled = false
    }
    errorItem.isHidden = true
    creditsItem.isHidden = true
    creditsExpireItem.isHidden = true

    menu.delegate = self
    menu.addItem(messageItem)
    menu.addItem(.separator())
    menu.addItem(autoItem)
    menu.addItem(apiItem)
    menu.addItem(onDemandItem)
    menu.addItem(creditsItem)
    menu.addItem(creditsExpireItem)
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
    let quit = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
    quit.target = self
    menu.addItem(quit)

    statusItem.menu = menu

    refreshNow()
    scheduleRefreshTimer()
  }

  func menuWillOpen(_ menu: NSMenu) {
    lastMenuOpenAt = Date()
    refreshNow()
    scheduleRefreshTimer()
  }

  private func currentRefreshInterval() -> TimeInterval {
    if let lastMenuOpenAt,
       Date().timeIntervalSince(lastMenuOpenAt) < RefreshPolicy.recentInteraction {
      return RefreshPolicy.active
    }
    return RefreshPolicy.idle
  }

  private func scheduleRefreshTimer() {
    refreshTimer?.invalidate()
    let interval = currentRefreshInterval()
    refreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
      guard let self else { return }
      self.refreshNow()
      self.scheduleRefreshTimer()
    }
  }

  @objc private func quitApp() {
    NSApp.terminate(nil)
  }

  @objc private func openDashboard() {
    if let url = URL(string: "https://cursor.com/dashboard/spending") {
      NSWorkspace.shared.open(url)
    }
  }

  @objc private func refreshNow() {
    if isRefreshing { return }
    isRefreshing = true
    DispatchQueue.global(qos: .utility).async {
      defer {
        DispatchQueue.main.async { self.isRefreshing = false }
      }
      do {
        let summary = try UsageFetcher.fetch()
        DispatchQueue.main.async {
          self.lastSummary = summary
          self.apply(summary)
          self.errorItem.isHidden = true
        }
      } catch {
        DispatchQueue.main.async {
          self.applyStatusImage(
            StatusArtwork.ring(percent: nil),
            tooltip: error.localizedDescription
          )
          self.errorItem.title = error.localizedDescription
          self.errorItem.isHidden = false
        }
      }
    }
  }

  private func applyStatusImage(_ image: NSImage, tooltip: String) {
    guard let button = statusItem.button else { return }
    button.title = ""
    button.imagePosition = .imageOnly
    button.imageScaling = .scaleProportionallyDown
    button.image = image
    button.toolTip = tooltip
  }

  private func apply(_ summary: UsageSummary) {
    let total = summary.totalPercent
    // Menu bar: solid pie only. Exact % lives in the menu / tooltip.
    applyStatusImage(StatusArtwork.ring(percent: total), tooltip: summary.totalMessage)

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

    if let credits = summary.credits, credits.hasGrants {
      creditsItem.isHidden = false
      creditsItem.title = String(
        format: "Credits: $%.2f / $%.2f remaining",
        Double(credits.remainingCents) / 100.0,
        Double(credits.totalCents) / 100.0
      )
      if let expireText = credits.expireText {
        creditsExpireItem.isHidden = false
        creditsExpireItem.title = "Credits expire: \(expireText)"
      } else {
        creditsExpireItem.isHidden = true
      }
    } else {
      creditsItem.isHidden = true
      creditsExpireItem.isHidden = true
    }

    planItem.title = "Plan: \(summary.membershipType)"
    cycleItem.title = "Resets: \(summary.cycleEndText)"
  }
}

enum StatusArtwork {
  /// Standard menu-bar glyph: 16×16pt template, like Amphetamine / system status icons.
  /// `squareLength` (~22pt) provides the shared side rhythm next to other items.
  static func ring(percent: Double?) -> NSImage {
    let size = NSSize(width: 16, height: 16)
    let image = NSImage(size: size, flipped: false) { rect in
      let inset: CGFloat = 2
      let bounds = rect.insetBy(dx: inset, dy: inset)
      let center = NSPoint(x: bounds.midX, y: bounds.midY)
      let radius = min(bounds.width, bounds.height) / 2

      // Template mask: faint unused area vs solid black used wedge (Amphetamine-style contrast).
      let track = NSBezierPath(ovalIn: bounds)
      NSColor.black.withAlphaComponent(0.12).setFill()
      track.fill()

      guard let percent else { return true }
      let clamped = min(max(percent, 0), 100) / 100
      if clamped <= 0 { return true }

      NSColor.black.setFill()
      if clamped >= 1 {
        track.fill()
        return true
      }

      let start: CGFloat = 90
      let end = start - (360 * CGFloat(clamped))
      let wedge = NSBezierPath()
      wedge.move(to: center)
      wedge.line(to: pointOnCircle(center: center, radius: radius, degrees: start))
      wedge.appendArc(
        withCenter: center,
        radius: radius,
        startAngle: start,
        endAngle: end,
        clockwise: true
      )
      wedge.close()
      wedge.fill()
      return true
    }
    image.isTemplate = true
    return image
  }

  private static func pointOnCircle(center: NSPoint, radius: CGFloat, degrees: CGFloat) -> NSPoint {
    let radians = degrees * .pi / 180
    return NSPoint(
      x: center.x + radius * cos(radians),
      y: center.y + radius * sin(radians)
    )
  }
}


struct CreditsInfo {
  var hasGrants: Bool
  var remainingCents: Int
  var totalCents: Int
  var expireText: String?
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
  var credits: CreditsInfo?
}

enum UsageFetcher {
  enum FetchError: LocalizedError {
    case noSession
    case sessionDB
    case badJWT
    case http(Int)
    case decode

    var errorDescription: String? {
      switch self {
      case .noSession:
        return "No Cursor session in local DB (sign in to Cursor IDE once)"
      case .sessionDB:
        return "Could not read Cursor session database"
      case .badJWT:
        return "Could not parse Cursor token"
      case .http(let code):
        if code == 401 || code == 403 {
          return "Session rejected (HTTP \(code)) — re-login to Cursor"
        }
        return "HTTP \(code)"
      case .decode:
        return "Unexpected usage response"
      }
    }
  }

  static func fetch() throws -> UsageSummary {
    let token = try readAccessToken()
    let sub = try jwtSubject(token)
    let cookieValue = "\(sub)%3A%3A\(token)"

    let json = try getJSON(
      url: "https://cursor.com/api/usage-summary",
      cookie: cookieValue
    )

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
      guard let cycleEnd,
            let date = ISO8601DateFormatter().date(from: cycleEnd) ?? parseFractionalISO(cycleEnd)
      else { return "—" }
      return formatDateWithDaysLeft(date)
    }()

    let credits = fetchCredits(token: token, cookie: cookieValue)

    return UsageSummary(
      membershipType: membership,
      autoPercent: auto,
      apiPercent: api,
      totalPercent: totalPercent,
      totalMessage: message,
      onDemandEnabled: (onDemand["enabled"] as? Bool) ?? false,
      onDemandUsed: (onDemand["used"] as? Int) ?? 0,
      onDemandLimit: onDemand["limit"] as? Int,
      cycleEndText: cycleText,
      credits: credits
    )
  }

  /// Spending-page Credits card: promo/prepaid grants applied to Cursor usage.
  /// Balance: `POST /api/dashboard/get-credit-grants-balance`
  /// Expiry: earliest `expiresAtMs` from `GetUsageLimitStatusAndActiveGrants`
  private static func fetchCredits(token: String, cookie: String) -> CreditsInfo? {
    let balanceJSON: [String: Any]
    do {
      balanceJSON = try postJSON(
        url: "https://cursor.com/api/dashboard/get-credit-grants-balance",
        cookie: cookie,
        body: Data("{}".utf8)
      )
    } catch {
      return nil
    }

    let hasGrants = (balanceJSON["hasCreditGrants"] as? Bool) ?? false
    let total = intValue(balanceJSON["totalCents"]) ?? 0
    // Prefer creditBalanceCents; fall back to total − used when the balance field is omitted.
    let remaining: Int = {
      if let balance = intValue(balanceJSON["creditBalanceCents"]) { return balance }
      if let used = intValue(balanceJSON["usedCents"]) { return max(total - used, 0) }
      return 0
    }()
    guard hasGrants, total > 0 || remaining > 0 else {
      return CreditsInfo(hasGrants: false, remainingCents: 0, totalCents: 0, expireText: nil)
    }

    let expireText = earliestGrantExpiryText(token: token)
    return CreditsInfo(
      hasGrants: true,
      remainingCents: remaining,
      totalCents: total,
      expireText: expireText
    )
  }

  private static func earliestGrantExpiryText(token: String) -> String? {
    let json: [String: Any]
    do {
      json = try postJSON(
        url: "https://api2.cursor.sh/aiserver.v1.DashboardService/GetUsageLimitStatusAndActiveGrants",
        bearer: token,
        body: Data("{}".utf8),
        connectRPC: true
      )
    } catch {
      return nil
    }

    let grants = json["activeGrants"] as? [[String: Any]] ?? []
    var earliest: Date?
    for grant in grants {
      guard let ms = intValue(grant["expiresAtMs"]) else { continue }
      let date = Date(timeIntervalSince1970: TimeInterval(ms) / 1000.0)
      if let current = earliest {
        if date < current { earliest = date }
      } else {
        earliest = date
      }
    }
    guard let earliest else { return nil }
    return formatDateWithDaysLeft(earliest)
  }

  private static func formatDateWithDaysLeft(_ date: Date) -> String {
    let fmt = DateFormatter()
    fmt.locale = Locale(identifier: "en_US_POSIX")
    fmt.dateStyle = .medium
    fmt.timeStyle = .none
    let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
    return "\(fmt.string(from: date)) (\(max(days, 0))d)"
  }

  private static func intValue(_ raw: Any?) -> Int? {
    switch raw {
    case let v as Int: return v
    case let v as NSNumber: return v.intValue
    case let v as String: return Int(v)
    default: return nil
    }
  }

  private static func getJSON(url: String, cookie: String) throws -> [String: Any] {
    var request = URLRequest(url: URL(string: url)!)
    request.httpMethod = "GET"
    request.setValue("WorkosCursorSessionToken=\(cookie)", forHTTPHeaderField: "Cookie")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
    request.timeoutInterval = 20
    return try performJSON(request)
  }

  private static func postJSON(
    url: String,
    cookie: String? = nil,
    bearer: String? = nil,
    body: Data,
    connectRPC: Bool = false
  ) throws -> [String: Any] {
    var request = URLRequest(url: URL(string: url)!)
    request.httpMethod = "POST"
    request.httpBody = body
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
    request.setValue("https://cursor.com", forHTTPHeaderField: "Origin")
    request.timeoutInterval = 20
    if let cookie {
      request.setValue("WorkosCursorSessionToken=\(cookie)", forHTTPHeaderField: "Cookie")
    }
    if let bearer {
      request.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")
    }
    if connectRPC {
      request.setValue("1", forHTTPHeaderField: "Connect-Protocol-Version")
    }
    return try performJSON(request)
  }

  private static func performJSON(_ request: URLRequest) throws -> [String: Any] {
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
    return json
  }

  private static func parseFractionalISO(_ raw: String) -> Date? {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.date(from: raw)
  }

  /// Same approach as CursorBar / MeterBar / ai-usagebar: read the IDE session DB.
  /// No Keychain prompt. Token lifetime is months — failures are almost always DB open.
  ///
  /// Cursor keeps `state.vscdb` in WAL mode. After checkpoint, `-wal`/`-shm` are often
  /// gone even with no IDE process. Plain `SQLITE_OPEN_READONLY` then fails prepare with
  /// SQLITE_CANTOPEN. `immutable=1` reads the main file without those sidecars.
  private static func readAccessToken() throws -> String {
    let path = NSHomeDirectory()
      + "/Library/Application Support/Cursor/User/globalStorage/state.vscdb"
    guard FileManager.default.fileExists(atPath: path) else {
      throw FetchError.noSession
    }
    let encoded = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? path
    let uri = "file:\(encoded)?mode=ro&immutable=1"
    var db: OpaquePointer?
    guard sqlite3_open_v2(uri, &db, SQLITE_OPEN_READONLY | SQLITE_OPEN_URI, nil) == SQLITE_OK,
          let db else {
      throw FetchError.sessionDB
    }
    defer { sqlite3_close(db) }

    let sql = "SELECT value FROM ItemTable WHERE key = 'cursorAuth/accessToken' LIMIT 1;"
    var stmt: OpaquePointer?
    guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let stmt else {
      throw FetchError.sessionDB
    }
    defer { sqlite3_finalize(stmt) }

    guard sqlite3_step(stmt) == SQLITE_ROW,
          let cString = sqlite3_column_text(stmt, 0) else {
      throw FetchError.noSession
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
