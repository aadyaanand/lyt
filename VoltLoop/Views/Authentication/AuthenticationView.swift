import SwiftUI
import AuthenticationServices

struct AuthenticationView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var showingPasswordReset = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.primaryBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    // Logo and Title
                    VStack(spacing: 20) {
                        Image(systemName: "bolt.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.voltLoopBlue)
                            .voltLoopGlow(color: .voltLoopBlue, radius: 15)
                        
                        Text(isSignUp ? "Create Account" : "Welcome Back")
                            .font(.system(size: 32, weight: .bold, design: .default))
                            .foregroundColor(.primaryText)
                        
                        Text(isSignUp ? "Join the VoltLoop community" : "Sign in to continue")
                            .font(.system(size: 16, weight: .medium, design: .default))
                            .foregroundColor(.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Form
                    VStack(spacing: 20) {
                        if isSignUp {
                            CustomTextField(
                                text: $displayName,
                                placeholder: "Full Name",
                                icon: "person.fill"
                            )
                        }
                        
                        CustomTextField(
                            text: $email,
                            placeholder: "Email",
                            icon: "envelope.fill",
                            keyboardType: .emailAddress
                        )
                        
                        CustomSecureField(
                            text: $password,
                            placeholder: "Password",
                            icon: "lock.fill"
                        )
                        
                        if !isSignUp {
                            Button("Forgot Password?") {
                                showingPasswordReset = true
                            }
                            .font(.system(size: 14, weight: .medium, design: .default))
                            .foregroundColor(.voltLoopBlue)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Sign In/Up Button
                    Button(action: {
                        Task {
                            if isSignUp {
                                await authManager.signUpWithEmail(email: email, password: password, displayName: displayName)
                            } else {
                                await authManager.signInWithEmail(email: email, password: password)
                            }
                        }
                    }) {
                        HStack {
                            if authManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .voltLoopBlack))
                                    .scaleEffect(0.8)
                            } else {
                                Text(isSignUp ? "Create Account" : "Sign In")
                                    .font(.system(size: 16, weight: .semibold, design: .default))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                    .voltLoopButtonStyle(isPrimary: false)
                    .disabled(authManager.isLoading || email.isEmpty || password.isEmpty || (isSignUp && displayName.isEmpty))
                    .opacity(authManager.isLoading || email.isEmpty || password.isEmpty || (isSignUp && displayName.isEmpty) ? 0.6 : 1.0)
                    .padding(.horizontal, 20)
                    
                    // Divider
                    HStack {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.secondaryBorder)
                        
                        Text("or")
                            .font(.system(size: 14, weight: .medium, design: .default))
                            .foregroundColor(.secondaryText)
                            .padding(.horizontal, 20)
                        
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.secondaryBorder)
                    }
                    .padding(.horizontal, 20)
                    
                    // Social Sign-In Buttons
                    VStack(spacing: 12) {
                        // Google Sign-In
                        Button(action: {
                            Task {
                                await authManager.signInWithGoogle()
                            }
                        }) {
                            HStack {
                                Image(systemName: "globe")
                                    .font(.system(size: 18))
                                Text("Continue with Google")
                                    .font(.system(size: 16, weight: .medium, design: .default))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.secondaryBorder, lineWidth: 1)
                            )
                            .foregroundColor(.primaryText)
                            .cornerRadius(12)
                        }
                        .disabled(authManager.isLoading)
                        
                        // Apple Sign-In
                        SignInWithAppleButton(
                            onRequest: { _ in },
                            onCompletion: { _ in
                                Task {
                                    await authManager.signInWithApple()
                                }
                            }
                        )
                        .signInWithAppleButtonStyle(.white)
                        .frame(height: 50)
                        .disabled(authManager.isLoading)
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // Toggle Sign In/Up
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isSignUp.toggle()
                            email = ""
                            password = ""
                            displayName = ""
                            authManager.errorMessage = nil
                        }
                    }) {
                        Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                            .font(.system(size: 14, weight: .medium, design: .default))
                            .foregroundColor(.voltLoopBlue)
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
        }
        .alert("Error", isPresented: .constant(authManager.errorMessage != nil)) {
            Button("OK") {
                authManager.errorMessage = nil
            }
        } message: {
            Text(authManager.errorMessage ?? "")
        }
        .sheet(isPresented: $showingPasswordReset) {
            PasswordResetView()
        }
    }
}

struct CustomTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.secondaryText)
                .frame(width: 20)
            
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .font(.system(size: 16, weight: .medium, design: .default))
                .foregroundColor(.primaryText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondaryBorder, lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

struct CustomSecureField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    @State private var isSecure = true
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.secondaryText)
                .frame(width: 20)
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .font(.system(size: 16, weight: .medium, design: .default))
                    .foregroundColor(.primaryText)
            } else {
                TextField(placeholder, text: $text)
                    .font(.system(size: 16, weight: .medium, design: .default))
                    .foregroundColor(.primaryText)
            }
            
            Button(action: {
                isSecure.toggle()
            }) {
                Image(systemName: isSecure ? "eye.slash" : "eye")
                    .font(.system(size: 16))
                    .foregroundColor(.secondaryText)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondaryBorder, lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

struct PasswordResetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var email = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.primaryBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    VStack(spacing: 20) {
                        Image(systemName: "envelope.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.voltLoopBlue)
                            .voltLoopGlow(color: .voltLoopBlue, radius: 15)
                        
                        Text("Reset Password")
                            .font(.system(size: 28, weight: .bold, design: .default))
                            .foregroundColor(.primaryText)
                        
                        Text("Enter your email address and we'll send you a link to reset your password.")
                            .font(.system(size: 16, weight: .medium, design: .default))
                            .foregroundColor(.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    
                    CustomTextField(
                        text: $email,
                        placeholder: "Email",
                        icon: "envelope.fill",
                        keyboardType: .emailAddress
                    )
                    .padding(.horizontal, 20)
                    
                    Button(action: {
                        Task {
                            await authManager.resetPassword(email: email)
                            dismiss()
                        }
                    }) {
                        Text("Send Reset Link")
                            .font(.system(size: 16, weight: .semibold, design: .default))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .voltLoopButtonStyle(isPrimary: false)
                    .disabled(email.isEmpty)
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
            }
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.voltLoopBlue)
                }
            }
        }
    }
}

struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationView()
            .environmentObject(AuthenticationManager())
    }
} 