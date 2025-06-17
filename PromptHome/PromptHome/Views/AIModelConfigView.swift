//
//  AIModelConfigView.swift
//  PromptHome
//
//  Created by Rui on 2025/6/15.
//

import SwiftUI
import SwiftData

struct AIModelConfigView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var configs: [AIModelConfig]
    
    @State private var selectedProvider: ModelProvider = .ollama
    @State private var baseURL: String = ""
    @State private var apiKey: String = ""
    @State private var selectedModel: String = ""
    @State private var availableModels: [String] = []
    @State private var isLoadingModels = false
    @State private var testStatus: TestStatus = .idle
    @State private var testMessage: String = ""
    
    // Hover states
    @State private var isProviderPickerHovered = false
    @State private var isBaseURLFieldHovered = false
    @State private var isAPIKeyFieldHovered = false
    @State private var isRefreshButtonHovered = false
    @State private var isTestButtonHovered = false
    @State private var isSaveButtonHovered = false
    @State private var hoveredModelIndex: Int? = nil
    
    enum TestStatus {
        case idle
        case testing
        case success
        case failed
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(NSLocalizedString("model_provider", comment: ""))
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14, weight: .medium))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(.controlBackgroundColor))
            
            VStack(alignment: .leading, spacing: 20) {
                // 配置AI模型以启用AI润色功能
                Text(NSLocalizedString("configure_ai_model_description", comment: ""))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 20)
                
                // Provider Selection - Dropdown
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("model_provider_label", comment: ""))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Picker("", selection: $selectedProvider) {
                        ForEach(ModelProvider.allCases, id: \.self) { provider in
                            Text(provider.rawValue).tag(provider)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(.textBackgroundColor))
                            .stroke(isProviderPickerHovered ? Color.blue : Color(.separatorColor), lineWidth: isProviderPickerHovered ? 2 : 1)
                    )
                    .scaleEffect(isProviderPickerHovered ? 1.02 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isProviderPickerHovered)
                    .onHover { hovering in
                        isProviderPickerHovered = hovering
                    }
                    .onChange(of: selectedProvider) { _, newProvider in
                        loadConfigForProvider(newProvider)
                        updateFieldsForProvider(newProvider)
                    }
                }
                
                // Base URL
                VStack(alignment: .leading, spacing: 8) {
                    Text("Base URL")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    TextField(NSLocalizedString("enter_base_url", comment: ""), text: $baseURL)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(.textBackgroundColor))
                                .stroke(
                                    isBaseURLFieldHovered ? Color.blue :
                                    isValidURL(baseURL) ? Color(.separatorColor) : Color.red,
                                    lineWidth: isBaseURLFieldHovered ? 2 : 1
                                )
                        )
                        .scaleEffect(isBaseURLFieldHovered ? 1.02 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: isBaseURLFieldHovered)
                        .onHover { hovering in
                            isBaseURLFieldHovered = hovering
                        }
                        .onChange(of: baseURL) { _, newValue in
                            // Remove trailing whitespace and validate
                            baseURL = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                    
                    if !baseURL.isEmpty && !isValidURL(baseURL) {
                        Text(NSLocalizedString("invalid_url_format", comment: ""))
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                // API Key (only for providers that require it)
                if selectedProvider.requiresAPIKey {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("API Key")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                        
                        SecureField(NSLocalizedString("enter_api_key", comment: ""), text: $apiKey)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(.textBackgroundColor))
                                    .stroke(isAPIKeyFieldHovered ? Color.blue : Color(.separatorColor), lineWidth: isAPIKeyFieldHovered ? 2 : 1)
                            )
                            .scaleEffect(isAPIKeyFieldHovered ? 1.02 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: isAPIKeyFieldHovered)
                            .onHover { hovering in
                                isAPIKeyFieldHovered = hovering
                            }
                    }
                }
                
                // Model Selection
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(NSLocalizedString("select_model", comment: ""))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if selectedProvider == .ollama {
                            Button(action: refreshOllamaModels) {
                                HStack(spacing: 4) {
                                    if isLoadingModels {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "arrow.clockwise")
                                            .font(.system(size: 12))
                                    }
                                    Text(NSLocalizedString("refresh", comment: ""))
                                        .font(.system(size: 12))
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(isRefreshButtonHovered ? Color.blue.opacity(0.1) : Color.clear)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .foregroundColor(isRefreshButtonHovered ? .blue : .blue)
                            .scaleEffect(isRefreshButtonHovered ? 1.05 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: isRefreshButtonHovered)
                            .onHover { hovering in
                                isRefreshButtonHovered = hovering
                            }
                            .disabled(isLoadingModels)
                        }
                    }
                    
                    if availableModels.isEmpty && selectedProvider == .ollama {
                        VStack(spacing: 8) {
                            Text(NSLocalizedString("no_models_found", comment: ""))
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                            Text(NSLocalizedString("ensure_ollama_running", comment: ""))
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 20)
                    } else {
                        // ListBox for model selection
                        List(availableModels.indices, id: \.self) { index in
                            let model = availableModels[index]
                            Text(model)
                                .font(.system(size: 14))
                                .foregroundColor(.primary)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(
                                            selectedModel == model ? Color.blue.opacity(0.2) :
                                            hoveredModelIndex == index ? Color.gray.opacity(0.1) : Color.clear
                                        )
                                )
                                .onTapGesture {
                                    selectedModel = model
                                }
                                .onHover { hovering in
                                    hoveredModelIndex = hovering ? index : nil
                                }
                                .animation(.easeInOut(duration: 0.15), value: hoveredModelIndex)
                        }
                        .listStyle(PlainListStyle())
                        .frame(height: 120)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(.textBackgroundColor))
                                .stroke(Color(.separatorColor), lineWidth: 1)
                        )
                    }
                }
                
                // Test Connection
                VStack(spacing: 8) {
                    Button(action: {
                        Task {
                            await testConnection()
                        }
                    }) {
                        HStack {
                            if testStatus == .testing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: testStatus == .success ? "checkmark.circle.fill" : testStatus == .failed ? "xmark.circle.fill" : "network")
                                    .foregroundColor(testStatus == .success ? .green : testStatus == .failed ? .red : .blue)
                            }
                            Text(NSLocalizedString("test_connection", comment: ""))
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(testStatus == .testing ? .secondary : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(isTestButtonHovered ? Color(.controlBackgroundColor).opacity(0.8) : Color(.controlBackgroundColor))
                                .stroke(isTestButtonHovered ? Color.blue : Color(.separatorColor), lineWidth: isTestButtonHovered ? 2 : 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .scaleEffect(isTestButtonHovered ? 1.02 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isTestButtonHovered)
                    .onHover { hovering in
                        isTestButtonHovered = hovering
                    }
                    .disabled(testStatus == .testing || baseURL.isEmpty || (selectedProvider.requiresAPIKey && apiKey.isEmpty) || selectedModel.isEmpty)
                    
                    if !testMessage.isEmpty {
                        Text(testMessage)
                            .font(.caption)
                            .foregroundColor(testStatus == .success ? .green : testStatus == .failed ? .red : .secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                Spacer()
                
                // Save Button
                Button(action: {
                    saveConfiguration()
                    // Trigger a refresh of the active config to update AI polish button
                    NotificationCenter.default.post(name: NSNotification.Name("AIConfigUpdated"), object: nil)
                }) {
                    Text(NSLocalizedString("save", comment: ""))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isSaveButtonHovered ? Color.black.opacity(0.8) : Color.black)
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(isSaveButtonHovered ? 1.02 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isSaveButtonHovered)
                .onHover { hovering in
                    isSaveButtonHovered = hovering
                }
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 20)
        }
        .frame(width: 400, height: 650)
        .background(Color(.windowBackgroundColor))
        .onAppear {
            loadConfigForProvider(selectedProvider)
        }
    }
    
    private func loadConfigForProvider(_ provider: ModelProvider) {
        // Load existing config for this provider
        if let existingConfig = configs.first(where: { $0.provider == provider.rawValue }) {
            baseURL = existingConfig.baseURL
            apiKey = existingConfig.apiKey
            selectedModel = existingConfig.selectedModel
        } else {
            // Use default values
            baseURL = provider.defaultBaseURL
            apiKey = ""
            selectedModel = provider.defaultModels.first ?? ""
        }
        
        if provider == .ollama {
            // For Ollama, fetch models dynamically
            Task {
                await loadOllamaModels()
            }
        } else {
            availableModels = provider.defaultModels
        }
    }
    
    private func updateFieldsForProvider(_ provider: ModelProvider) {
        // Reset test status when provider changes
        testStatus = .idle
        testMessage = ""
        
        // Update Base URL to default if empty or if switching providers
        if baseURL.isEmpty || baseURL == selectedProvider.defaultBaseURL {
            baseURL = provider.defaultBaseURL
        }
        
        // Update available models based on provider
        if provider == .ollama {
            Task {
                await loadOllamaModels()
            }
        } else {
            availableModels = provider.defaultModels
            // Set default model if current selection is not available
            if !availableModels.contains(selectedModel) {
                selectedModel = availableModels.first ?? ""
            }
        }
        
        // Clear API key if switching to Ollama (doesn't require API key)
        if provider == .ollama {
            apiKey = ""
        }
    }
    
    private func loadOllamaModels() async {
        await MainActor.run {
            isLoadingModels = true
        }
        
        let models = await ModelProvider.fetchOllamaModels(baseURL: baseURL.isEmpty ? "http://localhost:11434" : baseURL)
        
        await MainActor.run {
            availableModels = models
            if selectedModel.isEmpty && !models.isEmpty {
                selectedModel = models.first ?? ""
            }
            isLoadingModels = false
        }
    }
    
    private func refreshOllamaModels() {
        Task {
            await loadOllamaModels()
        }
    }
    
    private func isValidURL(_ urlString: String) -> Bool {
        guard !urlString.isEmpty else { return true } // Empty is considered valid for default
        guard let url = URL(string: urlString.trimmingCharacters(in: .whitespacesAndNewlines)) else { return false }
        return url.scheme != nil && url.host != nil
    }
    
    private func testConnection() async {
        await MainActor.run {
            testStatus = .testing
            testMessage = NSLocalizedString("testing_connection", comment: "")
        }
        
        do {
            let success = try await performConnectionTest()
            await MainActor.run {
                if success {
                    testStatus = .success
                    testMessage = NSLocalizedString("connection_success", comment: "")
                } else {
                    testStatus = .failed
                    testMessage = NSLocalizedString("connection_failed", comment: "")
                }
            }
        } catch {
            await MainActor.run {
                testStatus = .failed
                testMessage = String(format: NSLocalizedString("test_failed_format", comment: ""), error.localizedDescription)
            }
        }
    }
    
    private func performConnectionTest() async throws -> Bool {
        let trimmedBaseURL = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if selectedProvider == .ollama {
            // Test Ollama connection
            guard let url = URL(string: "\(trimmedBaseURL)/api/tags") else {
                throw URLError(.badURL)
            }
            
            let (_, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return false
            }
            return true
        } else {
            // Test OpenAI/Deepseek connection
            guard let url = URL(string: "\(trimmedBaseURL)/models") else {
                throw URLError(.badURL)
            }
            
            var request = URLRequest(url: url)
            request.setValue("Bearer \(apiKey.trimmingCharacters(in: .whitespacesAndNewlines))", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return false
            }
            return true
        }
    }
    
    private func saveConfiguration() {
        // Validate URL before saving
        let trimmedBaseURL = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidURL(trimmedBaseURL) else {
            // Show error or return early
            return
        }
        
        // Find existing config or create new one
        if let existingConfig = configs.first(where: { $0.provider == selectedProvider.rawValue }) {
            existingConfig.updateConfig(
                baseURL: trimmedBaseURL,
                apiKey: apiKey.trimmingCharacters(in: .whitespacesAndNewlines),
                selectedModel: selectedModel,
                isActive: true
            )
        } else {
            let newConfig = AIModelConfig(
                provider: selectedProvider,
                baseURL: trimmedBaseURL,
                apiKey: apiKey.trimmingCharacters(in: .whitespacesAndNewlines),
                selectedModel: selectedModel
            )
            newConfig.isActive = true
            modelContext.insert(newConfig)
        }
        
        // Deactivate other configs
        for config in configs {
            if config.provider != selectedProvider.rawValue {
                config.isActive = false
            }
        }
        
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    AIModelConfigView()
        .modelContainer(for: [AIModelConfig.self], inMemory: true)
}
