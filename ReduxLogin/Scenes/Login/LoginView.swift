//
//  LoginView.swift
//  ReduxLogin
//
//  Created by Baidetskyi Yurii on 20.07.2024.
//

import SwiftUI
import FirebaseMessaging

struct LoginView: View {
    @EnvironmentObject private var store: Store<AppState, AppAction>
    @EnvironmentObject private var notificationManager: NotificationManager
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            loginBody
        }
    }
}

// MARK: Views
private extension LoginView {
    var loginBody: some View {
        VStack(spacing: 10) {
            title
            
            emailLoginView
            
            VStack(spacing: 10) {
                appleLoginButton
                
                googleLoginButton
                
                facebookLoginButton
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .background(MovingShapesView())
        .alert(isPresented: Binding<Bool>(
            get: { store.state.loginError != nil },
            set: { _ in store.send(.clearLoginError) }
        )) {
            Alert(
                title: Text("Login Error"),
                message: Text(store.state.loginError ?? "Unknown error"),
                dismissButton: .default(Text("OK")) {
                    store.send(.clearLoginError)
                }
            )
        }
        .navigationDestination(isPresented: Binding<Bool>(
            get: { store.state.isLoggedIn },
            set: { _ in }
        )) {
            HomeView()
                .environmentObject(store)
                .environmentObject(notificationManager)
        }
        .task {
            await notificationManager.request()
        }
    }
    
    var title: some View {
        Text("Hi, use any of the available methods to authorize yourself! Test on real device!")
            .font(.largeTitle)
            .padding(.top, 100)
            .padding()
    }
    
    var emailLoginView: some View {
        VStack(spacing: 10) {
            // Email TextField
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .padding(.horizontal)
            
            // Password SecureField
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            // Error Message
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            
            HStack {
                Button {
                    store.send(.emailLogin(.signUp(email, password)))
                } label: {
                    Text("Sign Up")
                        .frame(height: 55)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                }
                .frame(height: 55)
                .padding()
                
                Button {
                    store.send(.emailLogin(.signIn(email, password)))
                } label: {
                    Text("Log in")
                        .frame(height: 55)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                }
                .frame(height: 55)
                .padding()
            }
        }
        
    }
    
    var appleLoginButton: some View {
        Button {
            store.send(.appleLogin(.signIn))
        } label: {
            SignInWithAppleButtonViewRepresentable(type: .default,
                                                   style: .black)
            .allowsHitTesting(false)
            
        }
        .frame(height: 55)
    }
    
    var googleLoginButton: some View {
        Button(action: {
            store.send(.googleLogin(.signIn))
        }) {
            HStack {
                Image(.googleLogo)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                
                Text("Sign in with Google")
                    .font(.system(size: 18, weight: .medium, design: .default))
                    .padding(.leading, 8)
            }
            .frame(height: 55)
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .foregroundColor(.gray)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray, lineWidth: 1)
            )
        }
    }
    
    var facebookLoginButton: some View {
        Button(action: {
            store.send(.facebookLogin(.signIn))
        }) {
            HStack {
                Image(.facebookLogo)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                
                Text("Sign in with Facebook")
                    .font(.system(size: 18, weight: .medium, design: .default))
                    .padding(.leading, 8)
            }
            .frame(height: 55)
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray, lineWidth: 1)
            )
        }
    }
}

#Preview {
    let store = Store(initialState: AppState(), reducer: Reducer.appReducer())
    let notificationManager = NotificationManager()
    
    return LoginView()
        .environmentObject(store)
        .environmentObject(notificationManager)
}
