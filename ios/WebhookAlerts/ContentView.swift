import SwiftUI
import UIKit

private let ink = Color(red: 0.025, green: 0.055, blue: 0.10)
private let panel = Color(red: 0.045, green: 0.09, blue: 0.15)
private let cyan = Color(red: 0.0, green: 0.67, blue: 1.0)

struct ContentView: View {
    @State private var token = SessionStore.load()
    @State private var webhookToken = ""
    @State private var email = ""
    @State private var password = ""
    @State private var registering = false
    @State private var events: [WebhookEvent] = []
    @State private var errorMessage: String?
    @State private var loading = false
    @State private var showWebhook = false

    var body: some View {
        ZStack {
            ink.ignoresSafeArea()
            if token == nil {
                loginView
            } else {
                inboxView
            }
        }
        .preferredColorScheme(.dark)
        .task {
            if token != nil { await refresh() }
        }
    }

    private var loginView: some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: "point.3.connected.trianglepath.dotted")
                .font(.system(size: 54, weight: .medium))
                .foregroundStyle(cyan)
                .padding(22)
                .background(panel, in: RoundedRectangle(cornerRadius: 24))
            VStack(spacing: 6) {
                HStack(spacing: 0) {
                    Text("Webhook").foregroundColor(.white)
                    Text(" Alerts").foregroundColor(cyan)
                }
                .font(.largeTitle.bold())
                Text("Seus webhooks na palma da mão.")
                    .font(.subheadline).foregroundStyle(.gray)
            }
            VStack(spacing: 12) {
                TextField("E-mail", text: $email)
                    .keyboardType(.emailAddress).textInputAutocapitalization(.never)
                    .textContentType(.emailAddress).fieldStyle()
                SecureField("Senha (mínimo 8 caracteres)", text: $password)
                    .textContentType(registering ? .newPassword : .password).fieldStyle()
                Button {
                    Task { await authenticate() }
                } label: {
                    HStack {
                        if loading { ProgressView().tint(.white) }
                        Text(registering ? "Criar conta" : "Entrar").bold()
                    }
                    .frame(maxWidth: .infinity).padding()
                    .background(cyan, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
                }.disabled(loading)
                Button(registering ? "Já tenho uma conta" : "Criar uma conta") {
                    registering.toggle()
                }.foregroundStyle(cyan)
            }.padding(.top, 18)
            if let errorMessage { Text(errorMessage).foregroundStyle(.red).font(.footnote) }
            Spacer()
        }
        .padding(24)
    }

    private var inboxView: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notificações").font(.title2.bold())
                        Text("\(events.count) eventos recebidos")
                            .font(.caption).foregroundStyle(.gray)
                    }
                    Spacer()
                    Button { showWebhook = true } label: {
                        Image(systemName: "link").font(.title3).foregroundStyle(cyan)
                    }
                    Button { Task { await refresh() } } label: {
                        Image(systemName: "arrow.clockwise").font(.title3).foregroundStyle(cyan)
                    }
                }.padding()
                if events.isEmpty {
                    ContentUnavailableView("Nenhum evento ainda",
                        systemImage: "bell.badge",
                        description: Text("Envie um webhook para começar."))
                } else {
                    List(events) { event in
                        NavigationLink {
                            EventDetailView(event: event)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Image(systemName: "point.3.connected.trianglepath.dotted")
                                        .foregroundStyle(cyan)
                                    Text(event.source).font(.headline)
                                    Spacer()
                                    Circle().fill(event.read ? .clear : cyan).frame(width: 7, height: 7)
                                }
                                Text(event.payload).font(.caption).foregroundStyle(.gray)
                                    .lineLimit(2)
                                Text(event.receivedAt).font(.caption2).foregroundStyle(.secondary)
                            }.padding(.vertical, 5)
                        }
                        .listRowBackground(panel)
                    }.scrollContentBackground(.hidden)
                }
                Button {
                    Task {
                        do {
                            try await APIService.shared.sendTest(token: token!)
                            await refresh()
                        } catch { errorMessage = error.localizedDescription }
                    }
                } label: {
                    Label("Enviar evento de teste", systemImage: "paperplane.fill")
                        .frame(maxWidth: .infinity).padding()
                        .background(cyan, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white).bold()
                }.padding()
            }
            .background(ink)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sair") { SessionStore.clear(); token = nil; events = [] }
                        .foregroundStyle(cyan)
                }
            }
            .sheet(isPresented: $showWebhook) {
                WebhookURLView(token: webhookToken)
                    .presentationDetents([.medium])
            }
            .refreshable { await refresh() }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                await refresh()
            }
        }
    }

    private func authenticate() async {
        errorMessage = nil
        loading = true
        defer { loading = false }
        do {
            let response = try await APIService.shared.authenticate(
                email: email, password: password, register: registering)
            SessionStore.save(response.token)
            token = response.token
            webhookToken = response.user.webhookToken
            await refresh()
        } catch { errorMessage = error.localizedDescription }
    }

    @MainActor private func refresh() async {
        guard let token else { return }
        do {
            events = try await APIService.shared.events(token: token)
            if webhookToken.isEmpty {
                webhookToken = try await APIService.shared.webhookToken(token: token)
            }
            errorMessage = nil
        } catch { errorMessage = error.localizedDescription }
    }
}

private extension View {
    func fieldStyle() -> some View {
        padding(14)
            .background(panel, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.08)))
    }
}

struct WebhookURLView: View {
    let token: String
    @State private var copied = false
    private var url: String { "https://SEU-WORKER.workers.dev/hook/\(token)" }

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "link.circle.fill").font(.system(size: 44)).foregroundStyle(cyan)
            Text("Sua URL de webhook").font(.title2.bold())
            Text(url).font(.footnote).textSelection(.enabled)
                .padding().frame(maxWidth: .infinity).background(panel, in: RoundedRectangle(cornerRadius: 12))
            Button {
                UIPasteboard.general.string = url
                copied = true
            } label: {
                Label(copied ? "Copiado" : "Copiar URL", systemImage: "doc.on.doc")
                    .frame(maxWidth: .infinity).padding()
                    .background(cyan, in: RoundedRectangle(cornerRadius: 12)).foregroundStyle(.white)
            }
            Text("Envie uma requisição HTTP POST para este endereço.")
                .font(.caption).foregroundStyle(.secondary)
        }.padding(24).background(ink.ignoresSafeArea())
    }
}

struct EventDetailView: View {
    let event: WebhookEvent
    var body: some View {
        ZStack {
            ink.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(event.source).font(.title.bold())
                    Text(event.receivedAt).font(.caption).foregroundStyle(.secondary)
                    Text("Payload").font(.headline)
                    Text(event.payload).font(.system(.footnote, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding().background(panel, in: RoundedRectangle(cornerRadius: 12))
                    ShareLink(item: event.payload) {
                        Label("Compartilhar payload", systemImage: "square.and.arrow.up")
                    }.foregroundStyle(cyan)
                }.padding()
            }
        }
        .navigationTitle("Detalhe do evento")
        .navigationBarTitleDisplayMode(.inline)
    }
}
