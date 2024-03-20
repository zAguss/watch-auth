import LocalAuthentication

private enum PAMError: CInt {
    case success = 0
    case authError = 9
    case ignore = 25
    case silentFlag = -2147483648 //  0x80000000
}

private let defaultReason = "perform an action that requires authentication"


public typealias vchar = UnsafePointer<UnsafeMutablePointer<CChar>>
public typealias pam_handle_t = UnsafeRawPointer?


@_cdecl("pam_sm_authenticate")
public func pam_sm_authenticate(pamh: pam_handle_t, flags: CInt, argc: CInt, argv: vchar) -> CInt {
    guard !isAskpassArgumentPresent(argv) else {
        return PAMError.ignore.rawValue
    }

    let arguments = parseArguments(argc: Int(argc), argv: argv)
    let reason = arguments["reason"] ?? defaultReason

    guard canEvaluateBiometrics() else {
        return PAMError.ignore.rawValue
    }

    return evaluateBiometrics(reason: reason, flags: flags)
}

private func isAskpassArgumentPresent(_ argv: vchar) -> Bool {
    let sudoArguments = ProcessInfo.processInfo.arguments
    return sudoArguments.contains("-A") || sudoArguments.contains("--askpass")
}

private func canEvaluateBiometrics() -> Bool {
    let context = LAContext()
    return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometricsOrWatch, error: nil)
}

private func evaluateBiometrics(reason: String, flags: CInt) -> CInt {
    let semaphore = DispatchSemaphore(value: 0)
    var result = PAMError.authError.rawValue

    let context = LAContext()
    context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometricsOrWatch, localizedReason: reason) { success, error in
        defer { semaphore.signal() }

        if let error = error {
            fputs((flags & PAMError.silentFlag.rawValue == 0) ? "\(error.localizedDescription)\n" : "", stderr)
            result = PAMError.ignore.rawValue
        } else {
            result = success ? PAMError.success.rawValue : PAMError.authError.rawValue
        }
    }

    semaphore.wait()
    return result
}


private func parseArguments(argc: Int, argv: vchar) -> [String: String] {
    var parsed = [String: String]()

    let arguments = UnsafeBufferPointer(start: argv, count: Int(argc))
        .compactMap { String(cString: $0) }
        .joined(separator: " ")

    let regex = try? NSRegularExpression(pattern: "[^\\s\"']+|\"([^\"]*)\"|'([^']*)'", options: .dotMatchesLineSeparators)

    let matches = regex?.matches(in: arguments, options: [], range: NSRange(location: 0, length: arguments.count))

    let nsArguments = arguments as NSString
    let groups = matches?
        .map { nsArguments.substring(with: $0.range) }
        .map { ($0 as String).trimmingCharacters(in: CharacterSet(charactersIn: "\"'")) }

    for argument in groups ?? [] {
        let pieces = argument.components(separatedBy: "=")
        if pieces.count == 2, let key = pieces.first, let value = pieces.last {
            parsed[key] = value
        }
    }

    return parsed
}

// Ignored PAM events

@_cdecl("pam_sm_chauthtok")
public func pam_sm_chauthtok(pamh: pam_handle_t, flags: CInt, argc: CInt, argv: vchar) -> CInt {
    return PAMError.ignore.rawValue
}

@_cdecl("pam_sm_setcred")
public func pam_sm_setcred(pamh: pam_handle_t, flags: CInt, argc: CInt, argv: vchar) -> CInt {
    return PAMError.ignore.rawValue
}

@_cdecl("pam_sm_acct_mgmt")
public func pam_sm_acct_mgmt(pamh: pam_handle_t, flags: CInt, argc: CInt, argv: vchar) -> CInt {
    return PAMError.ignore.rawValue
}
