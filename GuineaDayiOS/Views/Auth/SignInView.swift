import SwiftUI

/// Shown when the user is not signed in.
/// Supports both Sign Up (new user) and Log In (returning user).
struct SignInView: View {
    @Environment(AuthService.self) private var auth

    @State private var email: String    = ""
    @State private var password: String = ""
    @State private var isSignUp: Bool   = true   // toggle between sign-up / login
    @State private var isLoading        = false
    @State private var errorMsg: String?

    var body: some View {
        ZStack {
            Color.wallGray.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 28) {
                    Spacer().frame(height: 40)

                    // Logo
                    VStack(spacing: 12) {
                        Image("hachi")
                            .resizable().scaledToFit()
                            .frame(width: 90, height: 90)
                            .padding(14)
                            .background(Color.chiikawaWhite)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.inkBrown, lineWidth: 3))
                            .shadow(color: Color.inkBrown.opacity(0.18), radius: 6, x: 0, y: 3)

                        Text("GuineaDay")
                            .font(.system(size: 30, weight: .black, design: .rounded))
                            .foregroundColor(Color.inkBrown)
                        Text("Your piggy companion app 🐾")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(Color.inkBrown.opacity(0.5))
                    }

                    // Tab toggle
                    HStack(spacing: 0) {
                        tabButton("Create Account", selected: isSignUp)  { isSignUp = true;  errorMsg = nil }
                        tabButton("Log In",          selected: !isSignUp) { isSignUp = false; errorMsg = nil }
                    }
                    .background(Color.chiikawaWhite)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.inkBrown, lineWidth: 2))
                    .padding(.horizontal, 32)

                    // Form
                    VStack(spacing: 14) {
                        inputField("Email", text: $email,    keyboard: .emailAddress)
                        inputField("Password", text: $password, secure: true)

                        if let err = errorMsg {
                            Text(err)
                                .font(.system(size: 12, design: .rounded))
                                .foregroundColor(Color.blushPink)
                                .multilineTextAlignment(.center)
                        }

                        // Primary button
                        Button { Task { await submit() } } label: {
                            Text(isLoading ? "Please wait…" : (isSignUp ? "Create Account 🐾" : "Log In →"))
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .foregroundColor(Color.inkBrown)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .chiikawaCard(color: Color.mintGreen, radius: 24)
                        }
                        .buttonStyle(.plain)
                        .disabled(isLoading || email.isEmpty || password.isEmpty)

                        // Forgot password (login mode only)
                        if !isSignUp {
                            Button("Forgot password?") { Task { await resetPassword() } }
                                .font(.system(size: 12, design: .rounded))
                                .foregroundColor(Color.inkBrown.opacity(0.45))
                        }
                    }
                    .padding(.horizontal, 32)

                    Spacer().frame(height: 40)
                }
            }
        }
    }

    // MARK: - Sub-views

    func tabButton(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(selected ? Color.inkBrown : Color.inkBrown.opacity(0.4))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(selected ? Color.usagiYellow : Color.clear)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    func inputField(_ label: String, text: Binding<String>,
                    keyboard: UIKeyboardType = .default,
                    secure: Bool = false) -> some View {
        Group {
            if secure {
                SecureField(label, text: text)
            } else {
                TextField(label, text: text)
                    .keyboardType(keyboard)
                    .autocapitalization(.none)
            }
        }
        .font(.system(size: 15, design: .rounded))
        .padding()
        .background(Color.chiikawaWhite)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.inkBrown, lineWidth: 2))
    }

    // MARK: - Actions

    func submit() async {
        isLoading = true; errorMsg = nil
        do {
            if isSignUp {
                try await auth.signUp(email: email, password: password)
            } else {
                try await auth.signIn(email: email, password: password)
            }
        } catch {
            errorMsg = error.localizedDescription
        }
        isLoading = false
    }

    func resetPassword() async {
        guard !email.isEmpty else { errorMsg = "Enter your email above first."; return }
        do {
            try await auth.resetPassword(email: email)
            errorMsg = "Reset email sent! Check your inbox."
        } catch {
            errorMsg = error.localizedDescription
        }
    }
}
