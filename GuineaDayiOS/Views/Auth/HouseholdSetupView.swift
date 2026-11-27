import SwiftUI

/// Shown after sign-in when the user has no household yet.
/// Lets them create a new household or join a partner's.
struct HouseholdSetupView: View {
    @Environment(AuthService.self)      private var auth
    @Environment(HouseholdService.self) private var household

    @State private var mode: Mode = .pick
    @State private var codeInput: String = ""
    @State private var generatedCode: String = ""
    @State private var isLoading = false
    @State private var errorMsg: String?

    enum Mode { case pick, create, join }

    var body: some View {
        ZStack {
            Color.wallGray.ignoresSafeArea()
            VStack(spacing: 28) {
                Spacer()

                VStack(spacing: 8) {
                    Text("🏠 Set Up Your Farm")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundColor(Color.inkBrown)
                    Text("Share your piggies with a partner!")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(Color.inkBrown.opacity(0.5))
                }

                if let err = errorMsg {
                    Text(err).font(.system(size: 13, design: .rounded))
                        .foregroundColor(Color.blushPink).multilineTextAlignment(.center)
                }

                switch mode {
                case .pick:   pickView
                case .create: createView
                case .join:   joinView
                }

                Spacer()
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Pick screen

    var pickView: some View {
        VStack(spacing: 16) {
            optionButton(icon: "🐾", label: "Create a new home") { mode = .create }
            optionButton(icon: "💌", label: "Join partner's home") { mode = .join }
        }
    }

    func optionButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(icon).font(.system(size: 22))
                Text(label)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Color.inkBrown)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(Color.inkBrown.opacity(0.4))
            }
            .padding(.horizontal, 20).padding(.vertical, 16)
            .background(Color.chiikawaWhite)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.inkBrown, lineWidth: 2))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Create screen

    var createView: some View {
        VStack(spacing: 20) {
            if generatedCode.isEmpty {
                Button {
                    Task { await createHousehold() }
                } label: {
                    Text(isLoading ? "Creating…" : "Create My Home 🐾")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(Color.inkBrown)
                        .padding(.horizontal, 32).padding(.vertical, 14)
                        .chiikawaCard(color: Color.mintGreen, radius: 24)
                }
                .buttonStyle(.plain).disabled(isLoading)
            } else {
                VStack(spacing: 12) {
                    Text("Share this code with your partner:")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(Color.inkBrown.opacity(0.6))
                    Text(generatedCode)
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundColor(Color.inkBrown)
                        .kerning(6)
                        .padding(.horizontal, 24).padding(.vertical, 14)
                        .background(Color.usagiYellow.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.inkBrown, lineWidth: 2))
                    Text("They enter this code to join your home.\nYou're all set — go add your piggies!")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(Color.inkBrown.opacity(0.5))
                        .multilineTextAlignment(.center)
                }
            }
            backButton
        }
    }

    // MARK: - Join screen

    var joinView: some View {
        VStack(spacing: 20) {
            TextField("Enter invite code", text: $codeInput)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .textCase(.uppercase)
                .padding()
                .background(Color.chiikawaWhite)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.inkBrown, lineWidth: 2))

            Button {
                Task { await joinHousehold() }
            } label: {
                Text(isLoading ? "Joining…" : "Join 💌")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(Color.inkBrown)
                    .padding(.horizontal, 32).padding(.vertical, 14)
                    .chiikawaCard(color: Color.blushPink, radius: 24)
            }
            .buttonStyle(.plain).disabled(isLoading || codeInput.count < 6)

            backButton
        }
    }

    var backButton: some View {
        Button("← Back") { mode = .pick; errorMsg = nil }
            .font(.system(size: 13, design: .rounded))
            .foregroundColor(Color.inkBrown.opacity(0.5))
    }

    // MARK: - Actions

    func createHousehold() async {
        guard let uid = auth.user?.uid else { return }
        isLoading = true; errorMsg = nil
        do {
            generatedCode = try await household.createHousehold(uid: uid)
        } catch {
            errorMsg = error.localizedDescription
        }
        isLoading = false
    }

    func joinHousehold() async {
        guard let uid = auth.user?.uid else { return }
        isLoading = true; errorMsg = nil
        do {
            try await household.joinHousehold(code: codeInput.uppercased(), uid: uid)
        } catch {
            errorMsg = error.localizedDescription
        }
        isLoading = false
    }
}
