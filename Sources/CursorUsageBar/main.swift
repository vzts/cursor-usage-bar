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

  private let messageItem = NSMenuItem(title: "—", action: nil, keyEquivalent: "")
  private let includedItem = NSMenuItem(title: "Included: —", action: nil, keyEquivalent: "")
  private let poolsItem = NSMenuItem(title: "Pools: —", action: nil, keyEquivalent: "")
  private let onDemandItem = NSMenuItem(title: "On-demand: —", action: nil, keyEquivalent: "")
  private let creditsItem = NSMenuItem(title: "Credits: —", action: nil, keyEquivalent: "")
  private let slowPoolItem = NSMenuItem(title: "Slow pool: —", action: nil, keyEquivalent: "")
  private let metaItem = NSMenuItem(title: "Plan: —", action: nil, keyEquivalent: "")
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
      messageItem, includedItem, poolsItem, onDemandItem, creditsItem, slowPoolItem, metaItem, errorItem,
    ] {
      item.isEnabled = false
    }
    errorItem.isHidden = true
    creditsItem.isHidden = true
    slowPoolItem.isHidden = true

    menu.delegate = self
    menu.addItem(messageItem)
    menu.addItem(.separator())
    menu.addItem(includedItem)
    menu.addItem(poolsItem)
    menu.addItem(onDemandItem)
    menu.addItem(creditsItem)
    menu.addItem(slowPoolItem)
    menu.addItem(.separator())
    menu.addItem(metaItem)
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
    applyStatusImage(StatusArtwork.ring(percent: summary.totalPercent), tooltip: summary.tooltip)

    messageItem.title = summary.headline
    includedItem.title = summary.includedLine
    poolsItem.title = String(
      format: "Auto %.0f%% · API %.0f%% · Total %.0f%%",
      summary.autoPercent,
      summary.apiPercent,
      summary.totalPercent
    )

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
      var line = String(
        format: "Credits: $%.2f / $%.2f",
        Double(credits.remainingCents) / 100.0,
        Double(credits.totalCents) / 100.0
      )
      if let expireText = credits.expireText {
        line += " · \(expireText)"
      }
      creditsItem.title = line
    } else {
      creditsItem.isHidden = true
    }

    if let slow = summary.slowPool, slow.isActive {
      slowPoolItem.isHidden = false
      var parts: [String] = [slow.autoOnly ? "Auto only" : "limited models"]
      if let delay = slow.delaySeconds {
        parts.append("~\(delay)s")
      }
      if let remaining = slow.remainingCents, let total = slow.totalCents, total > 0 {
        parts.append(String(format: "$%.2f / $%.2f", Double(remaining) / 100.0, Double(total) / 100.0))
      }
      if let expireText = slow.expireText {
        parts.append(expireText)
      }
      slowPoolItem.title = "Slow pool: " + parts.joined(separator: " · ")
    } else {
      slowPoolItem.isHidden = true
    }

    metaItem.title = "\(summary.membershipType) · resets \(summary.cycleEndText)"
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

struct SlowPoolInfo {
  var isActive: Bool
  var delaySeconds: Int?
  var autoOnly: Bool
  var remainingCents: Int?
  var totalCents: Int?
  var expireText: String?
}

struct UsageSummary {
  var membershipType: String
  var autoPercent: Double
  var apiPercent: Double
  var totalPercent: Double
  var headline: String
  var includedLine: String
  var tooltip: String
  var onDemandEnabled: Bool
  var onDemandUsed: Int
  var onDemandLimit: Int?
  var cycleEndText: String
  var credits: CreditsInfo?
  var slowPool: SlowPoolInfo?
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

  private static let usageLimitPolicyGrantType = "usage_limit_policy"
  private static let emptyBody = Data("{}".utf8)

  /// Two parallel calls:
  /// 1) `usage-summary` — included $, pool %, on-demand, plan/cycle
  /// 2) `GetUsageLimitStatusAndActiveGrants` — promo credits + slow-pool policy
  static func fetch() throws -> UsageSummary {
    let token = try readAccessToken()
    let sub = try jwtSubject(token)
    let cookieValue = "\(sub)%3A%3A\(token)"

    let pair = try fetchPrimaryAndExtras(token: token, cookie: cookieValue)
    let json = pair.summary
    let extras = pair.extras

    let membership = (json["membershipType"] as? String) ?? "unknown"
    let individual = json["individualUsage"] as? [String: Any] ?? [:]
    let plan = individual["plan"] as? [String: Any] ?? [:]
    let onDemand = individual["onDemand"] as? [String: Any] ?? [:]

    let auto = doubleValue(plan["autoPercentUsed"]) ?? 0
    let api = doubleValue(plan["apiPercentUsed"]) ?? 0
    let totalPercent = doubleValue(plan["totalPercentUsed"]) ?? max(auto, api)

    let includedUsed = intValue(plan["used"]) ?? 0
    let includedLimit = intValue(plan["limit"]) ?? 0
    let includedRemaining = intValue(plan["remaining"])
      ?? max(includedLimit - includedUsed, 0)
    let includedExhausted = includedLimit > 0 && includedRemaining <= 0

    let percentMessage = (json["autoModelSelectedDisplayMessage"] as? String)
      ?? String(format: "You've used %.0f%% of your included total usage", totalPercent)
    let headline = includedExhausted
      ? "Included limit reached"
      : percentMessage

    let includedLine: String = {
      guard includedLimit > 0 else {
        return String(format: "Included: — · display %.0f%%", totalPercent)
      }
      let base = String(
        format: "Included: $%.2f / $%.2f",
        Double(includedUsed) / 100.0,
        Double(includedLimit) / 100.0
      )
      if includedExhausted {
        return base + " · exhausted"
      }
      return base + String(format: " · $%.2f left", Double(includedRemaining) / 100.0)
    }()

    let cycleEnd = json["billingCycleEnd"] as? String
    let cycleText: String = {
      guard let cycleEnd,
            let date = ISO8601DateFormatter().date(from: cycleEnd) ?? parseFractionalISO(cycleEnd)
      else { return "—" }
      return formatDateWithDaysLeft(date)
    }()

    var tooltipParts: [String] = [
      String(format: "%.0f%%", totalPercent),
    ]
    if includedLimit > 0 {
      tooltipParts.append(
        String(
          format: "$%.2f/$%.2f",
          Double(includedUsed) / 100.0,
          Double(includedLimit) / 100.0
        )
      )
    }
    if let slow = extras.slowPool, slow.isActive {
      if let delay = slow.delaySeconds {
        tooltipParts.append("Slow pool ~\(delay)s")
      } else {
        tooltipParts.append("Slow pool")
      }
    }

    return UsageSummary(
      membershipType: membership,
      autoPercent: auto,
      apiPercent: api,
      totalPercent: totalPercent,
      headline: headline,
      includedLine: includedLine,
      tooltip: tooltipParts.joined(separator: " · "),
      onDemandEnabled: (onDemand["enabled"] as? Bool) ?? false,
      onDemandUsed: intValue(onDemand["used"]) ?? 0,
      onDemandLimit: intValue(onDemand["limit"]),
      cycleEndText: cycleText,
      credits: extras.credits,
      slowPool: extras.slowPool
    )
  }

  private struct Extras {
    var credits: CreditsInfo?
    var slowPool: SlowPoolInfo?
  }

  private static func fetchPrimaryAndExtras(
    token: String,
    cookie: String
  ) throws -> (summary: [String: Any], extras: Extras) {
    let group = DispatchGroup()
    let lock = NSLock()
    var summaryBox: Result<[String: Any], Error>?
    var extrasBox: Result<[String: Any], Error>?

    group.enter()
    DispatchQueue.global(qos: .utility).async {
      let result: Result<[String: Any], Error>
      do {
        result = .success(try getJSON(
          url: "https://cursor.com/api/usage-summary",
          cookie: cookie
        ))
      } catch {
        result = .failure(error)
      }
      lock.lock()
      summaryBox = result
      lock.unlock()
      group.leave()
    }

    group.enter()
    DispatchQueue.global(qos: .utility).async {
      let result: Result<[String: Any], Error>
      do {
        result = .success(try postJSON(
          url: "https://api2.cursor.sh/aiserver.v1.DashboardService/GetUsageLimitStatusAndActiveGrants",
          bearer: token,
          body: emptyBody,
          connectRPC: true
        ))
      } catch {
        result = .failure(error)
      }
      lock.lock()
      extrasBox = result
      lock.unlock()
      group.leave()
    }

    let waitResult = group.wait(timeout: .now() + 30)

    lock.lock()
    let summaryResult = summaryBox
    let extrasResult = extrasBox
    lock.unlock()

    guard let summaryResult else {
      // Timed out before usage-summary finished, or worker never reported.
      throw FetchError.http(waitResult == .timedOut ? -2 : -1)
    }
    let summary = try summaryResult.get()

    // Credits / slow-pool are best-effort: keep primary usage even if the RPC lags or fails.
    let extras: Extras
    if case .success(let grantsJSON)? = extrasResult {
      extras = parseExtras(grantsJSON)
    } else {
      extras = Extras(credits: nil, slowPool: nil)
    }
    return (summary, extras)
  }

  private static func parseExtras(_ json: [String: Any]) -> Extras {
    let grants = json["activeGrants"] as? [[String: Any]] ?? []
    let policy = json["usageLimitPolicyStatus"] as? [String: Any] ?? [:]

    let promoGrants = grants.filter { ($0["grantType"] as? String) != usageLimitPolicyGrantType }
    let promoRemaining = promoGrants.compactMap { intValue($0["remainingCents"]) }.reduce(0, +)
    let promoTotal = promoGrants.compactMap { intValue($0["totalCents"]) }.reduce(0, +)
    let credits: CreditsInfo? = (promoTotal > 0 || promoRemaining > 0)
      ? CreditsInfo(
        hasGrants: true,
        remainingCents: promoRemaining,
        totalCents: max(promoTotal, promoRemaining),
        expireText: earliestExpiryText(in: promoGrants)
      )
      : nil

    let policyGrants = grants.filter { ($0["grantType"] as? String) == usageLimitPolicyGrantType }
    let policyGrant = policyGrants.first
    let isSlowPool = (policy["isInSlowPool"] as? Bool)
      ?? ((policy["stage"] as? String) == "LIMIT_HIT_STAGE_SLOW_POOL")
    let hasPolicyGrant = !policyGrants.isEmpty
    let active = isSlowPool || hasPolicyGrant

    let delayMs = intValue(policy["slownessMs"]) ?? intValue(policyGrant?["slownessMs"])
    let delaySeconds: Int? = {
      guard let delayMs, delayMs > 0 else { return nil }
      return max(Int((Double(delayMs) / 1000.0).rounded()), 1)
    }()

    let allowedModels = (policy["allowedModelIds"] as? [String])
      ?? (policyGrant?["allowedModelIds"] as? [String])
    let autoOnly = allowedModels == nil
      || allowedModels == ["default"]
      || (allowedModels?.allSatisfy { $0 == "default" } ?? false)

    let remainingSum = policyGrants.compactMap { intValue($0["remainingCents"]) }.reduce(0, +)
    let totalSum = policyGrants.compactMap { intValue($0["totalCents"]) }.reduce(0, +)

    let slowPool: SlowPoolInfo? = active
      ? SlowPoolInfo(
        isActive: true,
        delaySeconds: delaySeconds,
        autoOnly: autoOnly,
        remainingCents: hasPolicyGrant ? remainingSum : nil,
        totalCents: hasPolicyGrant ? totalSum : nil,
        expireText: earliestExpiryText(in: policyGrants)
      )
      : nil

    return Extras(credits: credits, slowPool: slowPool)
  }

  private static func earliestExpiryText(in grants: [[String: Any]]) -> String? {
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

  private static func doubleValue(_ raw: Any?) -> Double? {
    switch raw {
    case let v as Double: return v
    case let v as NSNumber: return v.doubleValue
    case let v as String: return Double(v)
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
