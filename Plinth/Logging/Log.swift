import OSLog

nonisolated enum Log {
    private static let subsystem = "au.edu.vic.woodleigh.Plinth"

    static let app = Logger(subsystem: subsystem, category: "app")
    static let assessment = Logger(subsystem: subsystem, category: "assessment")
    static let browser = Logger(subsystem: subsystem, category: "browser")
    static let configuration = Logger(subsystem: subsystem, category: "configuration")
    static let power = Logger(subsystem: subsystem, category: "power")
}
