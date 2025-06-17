//
//  MCPClient.swift
//  PromptHome
//
//  Created by Rui on 2025/6/16.
//

import Foundation
import Network
import OSLog

/// MCP Client implementation for connecting to MCP servers
class MCPClient: ObservableObject, @unchecked Sendable {
    private let logger = Logger(subsystem: "PromptHome", category: "MCPClient")
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "mcp.client.queue")
    private var pendingRequests: [RequestId: (Result<MCPResponse, Error>) -> Void] = [:]
    private var requestIdCounter = 0
    
    @Published var isConnected = false
    @Published var errorMessage: String?
    
    private var serverCapabilities: ServerCapabilities?
    
    init() {}
    
    // MARK: - Connection Management
    
    func connect(to host: String, port: UInt16) async throws {
        disconnect()
        
        let endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(host), port: NWEndpoint.Port(rawValue: port)!)
        let parameters = NWParameters.tcp
        
        connection = NWConnection(to: endpoint, using: parameters)
        
        return try await withCheckedThrowingContinuation { continuation in
            var hasResumed = false
            
            connection?.stateUpdateHandler = { [weak self] state in
                DispatchQueue.main.async {
                    switch state {
                    case .ready:
                        self?.isConnected = true
                        self?.errorMessage = nil
                        self?.logger.info("Connected to MCP server at \(host):\(port)")
                        self?.performInitialize()
                        if !hasResumed {
                            hasResumed = true
                            continuation.resume()
                        }
                    case .failed(let error):
                        self?.isConnected = false
                        self?.errorMessage = "Connection failed: \(error.localizedDescription)"
                        self?.logger.error("Connection failed: \(error.localizedDescription)")
                        if !hasResumed {
                            hasResumed = true
                            continuation.resume(throwing: error)
                        }
                    case .cancelled:
                        self?.isConnected = false
                        self?.logger.info("Connection cancelled")
                        if !hasResumed {
                            hasResumed = true
                            continuation.resume(throwing: CancellationError())
                        }
                    default:
                        break
                    }
                }
            }
            
            connection?.start(queue: queue)
        }
    }
    
    func disconnect() {
        connection?.cancel()
        connection = nil
        pendingRequests.removeAll()
        
        DispatchQueue.main.async {
            self.isConnected = false
        }
    }
    
    // MARK: - MCP Protocol Methods
    
    private func performInitialize() {
        let clientInfo = ClientInfo(name: "PromptHome", version: "1.0.0")
        let capabilities = ClientCapabilities()
        let initRequest = InitializeRequest(capabilities: capabilities, clientInfo: clientInfo)
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(initRequest)
            let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
            let params = convertToJSONValue(json)
            
            sendRequest(method: "initialize", params: params) { [weak self] result in
                switch result {
                case .success(let response):
                    if let result = response.result {
                        self?.parseInitializeResult(result)
                    }
                    self?.logger.info("Initialize completed successfully")
                case .failure(let error):
                    self?.logger.error("Initialize failed: \(error.localizedDescription)")
                }
            }
        } catch {
            logger.error("Failed to encode initialize request: \(error.localizedDescription)")
        }
    }
    
    private func parseInitializeResult(_ result: [String: JSONValue]) {
        // Parse server capabilities from the result
        if let capabilitiesValue = result["capabilities"],
           case .object(let capabilitiesDict) = capabilitiesValue {
            
            var prompts: PromptsCapability?
            if let promptsValue = capabilitiesDict["prompts"],
               case .object(let promptsDict) = promptsValue {
                let listChanged = promptsDict["listChanged"]?.boolValue
                prompts = PromptsCapability(listChanged: listChanged)
            }
            
            serverCapabilities = ServerCapabilities(prompts: prompts)
        }
    }
    
    func listPrompts(completion: @escaping (Result<[MCPPrompt], Error>) -> Void) {
        guard isConnected else {
            completion(.failure(MCPClientError.notConnected))
            return
        }
        
        let params: [String: JSONValue] = [:]
        
        sendRequest(method: "prompts/list", params: params) { result in
            switch result {
            case .success(let response):
                if let error = response.error {
                    completion(.failure(error))
                } else if let result = response.result {
                    do {
                        let prompts = try self.parsePromptsListResult(result)
                        completion(.success(prompts))
                    } catch {
                        completion(.failure(error))
                    }
                } else {
                    completion(.failure(MCPClientError.invalidResponse))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getPrompt(name: String, arguments: [String: JSONValue]? = nil, completion: @escaping (Result<PromptsGetResult, Error>) -> Void) {
        guard isConnected else {
            completion(.failure(MCPClientError.notConnected))
            return
        }
        
        var params: [String: JSONValue] = ["name": .string(name)]
        if let arguments = arguments {
            params["arguments"] = .object(arguments)
        }
        
        sendRequest(method: "prompts/get", params: params) { result in
            switch result {
            case .success(let response):
                if let error = response.error {
                    completion(.failure(error))
                } else if let result = response.result {
                    do {
                        let promptResult = try self.parsePromptsGetResult(result)
                        completion(.success(promptResult))
                    } catch {
                        completion(.failure(error))
                    }
                } else {
                    completion(.failure(MCPClientError.invalidResponse))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Async Methods
    
    func listPrompts() async throws -> [MCPPrompt] {
        return try await withCheckedThrowingContinuation { continuation in
            listPrompts { result in
                continuation.resume(with: result)
            }
        }
    }
    
    func getPrompt(name: String, arguments: [String: JSONValue]? = nil) async throws -> PromptsGetResult {
        return try await withCheckedThrowingContinuation { continuation in
            getPrompt(name: name, arguments: arguments) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    // MARK: - Low-level Request Handling
    
    private func sendRequest(method: String, params: [String: JSONValue]?, completion: @escaping (Result<MCPResponse, Error>) -> Void) {
        guard let connection = connection else {
            completion(.failure(MCPClientError.notConnected))
            return
        }
        
        requestIdCounter += 1
        let requestId = RequestId.number(requestIdCounter)
        let request = MCPRequest(id: requestId, method: method, params: params)
        
        do {
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(request)
            
            // Create HTTP POST request
            let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
            let httpRequest = """
                POST / HTTP/1.1\r
                Host: localhost\r
                Content-Type: application/json\r
                Content-Length: \(jsonString.utf8.count)\r
                \r
                \(jsonString)
                """
            
            guard let requestData = httpRequest.data(using: .utf8) else {
                completion(.failure(MCPClientError.encodingError))
                return
            }
            
            // Store completion handler
            pendingRequests[requestId] = completion
            
            // Send request
            connection.send(content: requestData, completion: .contentProcessed { [weak self] error in
                if let error = error {
                    self?.pendingRequests.removeValue(forKey: requestId)
                    completion(.failure(error))
                } else {
                    self?.logger.info("Request sent: \(method)")
                    self?.receiveResponse()
                }
            })
            
        } catch {
            completion(.failure(error))
        }
    }
    
    private func receiveResponse() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            if let error = error {
                self?.logger.error("Receive error: \(error.localizedDescription)")
                return
            }
            
            if let data = data, !data.isEmpty {
                self?.processReceivedData(data)
            }
            
            if !isComplete {
                self?.receiveResponse()
            }
        }
    }
    
    private func processReceivedData(_ data: Data) {
        guard let httpString = String(data: data, encoding: .utf8) else {
            logger.error("Failed to decode received data as UTF-8")
            return
        }
        
        logger.info("Received HTTP response: \(httpString.prefix(200))...")
        
        // Parse HTTP response
        let lines = httpString.components(separatedBy: "\r\n")
        
        // Check HTTP status code
        guard let statusLine = lines.first else {
            logger.error("Invalid HTTP response: missing status line")
            return
        }
        
        let statusComponents = statusLine.components(separatedBy: " ")
        guard statusComponents.count >= 2,
              let statusCode = Int(statusComponents[1]) else {
            logger.error("Invalid HTTP response: malformed status line")
            return
        }
        
        // Find the start of JSON body
        var bodyStartIndex = 0
        for (index, line) in lines.enumerated() {
            if line.isEmpty {
                bodyStartIndex = index + 1
                break
            }
        }
        
        // Extract JSON body
        let bodyLines = Array(lines.dropFirst(bodyStartIndex))
        let jsonBody = bodyLines.joined(separator: "\r\n")
        
        guard let jsonData = jsonBody.data(using: .utf8) else {
            logger.error("Failed to extract JSON from HTTP response")
            return
        }
        
        // Handle HTTP error responses
        if statusCode != 200 {
            logger.error("HTTP error \(statusCode): \(jsonBody)")
            logger.error("Full HTTP response: \(httpString)")
            
            // Try to parse error response as JSON to get detailed error info
            if let jsonData = jsonBody.data(using: .utf8) {
                do {
                    let errorResponse = try JSONDecoder().decode(MCPResponse.self, from: jsonData)
                    if let error = errorResponse.error {
                        logger.error("Server error details: code=\(error.code), message=\(error.message)")
                        if let errorData = error.data {
                            logger.error("Server error data: \(String(describing: errorData))")
                        }
                        
                        // Call all pending completions with the specific server error
                        for (_, completion) in pendingRequests {
                            completion(.failure(MCPClientError.serverError(error)))
                        }
                    } else {
                        // Call all pending completions with generic error
                        for (_, completion) in pendingRequests {
                            completion(.failure(MCPClientError.invalidResponse))
                        }
                    }
                } catch {
                    logger.error("Failed to parse error response as JSON: \(error.localizedDescription)")
                    // Call all pending completions with generic error
                    for (_, completion) in pendingRequests {
                        completion(.failure(MCPClientError.invalidResponse))
                    }
                }
            } else {
                // Call all pending completions with generic error
                for (_, completion) in pendingRequests {
                    completion(.failure(MCPClientError.invalidResponse))
                }
            }
            
            pendingRequests.removeAll()
            return
        }
        
        do {
            let response = try JSONDecoder().decode(MCPResponse.self, from: jsonData)
            
            // Log response details
             if let error = response.error {
                 logger.error("MCP response contains error: code=\(error.code), message=\(error.message)")
                 if let errorData = error.data {
                     logger.error("MCP error data: \(String(describing: errorData))")
                 }
             } else {
                 logger.info("MCP response received successfully for request ID: \(String(describing: response.id))")
             }
             
             // Find and call the completion handler
             if let completion = pendingRequests.removeValue(forKey: response.id) {
                 completion(.success(response))
             } else {
                 logger.warning("No pending request found for response ID: \(String(describing: response.id))")
             }
            
        } catch {
            logger.error("Failed to decode JSON response: \(error.localizedDescription)")
            logger.error("Raw JSON data: \(jsonBody)")
            logger.error("JSON data length: \(jsonData.count) bytes")
            
            // Call all pending completions with error
            for (_, completion) in pendingRequests {
                completion(.failure(MCPClientError.decodingError))
            }
            pendingRequests.removeAll()
        }
    }
    
    // MARK: - Response Parsing
    
    private func parsePromptsListResult(_ result: [String: JSONValue]) throws -> [MCPPrompt] {
        guard let promptsValue = result["prompts"],
              case .array(let promptsArray) = promptsValue else {
            throw MCPClientError.invalidResponse
        }
        
        var prompts: [MCPPrompt] = []
        
        for promptValue in promptsArray {
            guard case .object(let promptDict) = promptValue,
                  let nameValue = promptDict["name"],
                  case .string(let name) = nameValue else {
                continue
            }
            
            let description = promptDict["description"]?.stringValue
            
            // Parse arguments if present
            var arguments: [PromptArgument]?
            if let argsValue = promptDict["arguments"],
               case .array(let argsArray) = argsValue {
                arguments = []
                for argValue in argsArray {
                    if case .object(let argDict) = argValue,
                       let argNameValue = argDict["name"],
                       case .string(let argName) = argNameValue {
                        let argDescription = argDict["description"]?.stringValue
                        let required = argDict["required"]?.boolValue
                        arguments?.append(PromptArgument(name: argName, description: argDescription, required: required))
                    }
                }
            }
            
            prompts.append(MCPPrompt(name: name, description: description, arguments: arguments))
        }
        
        return prompts
    }
    
    private func parsePromptsGetResult(_ result: [String: JSONValue]) throws -> PromptsGetResult {
        let description = result["description"]?.stringValue
        
        guard let messagesValue = result["messages"],
              case .array(let messagesArray) = messagesValue else {
            throw MCPClientError.invalidResponse
        }
        
        var messages: [PromptMessage] = []
        
        for messageValue in messagesArray {
            guard case .object(let messageDict) = messageValue,
                  let roleValue = messageDict["role"],
                  case .string(let roleString) = roleValue,
                  let role = MessageRole(rawValue: roleString),
                  let contentValue = messageDict["content"],
                  case .object(let contentDict) = contentValue,
                  let typeValue = contentDict["type"],
                  case .string(let type) = typeValue else {
                continue
            }
            
            let content: MessageContent
            switch type {
            case "text":
                guard let textValue = contentDict["text"],
                      case .string(let text) = textValue else {
                    continue
                }
                content = .text(text)
            default:
                continue // Skip unsupported content types
            }
            
            messages.append(PromptMessage(role: role, content: content))
        }
        
        return PromptsGetResult(description: description, messages: messages)
    }
    
    // MARK: - Helper Methods
    
    private func convertToJSONValue(_ value: Any) -> [String: JSONValue] {
        guard let dict = value as? [String: Any] else { return [:] }
        
        var result: [String: JSONValue] = [:]
        for (key, val) in dict {
            result[key] = convertAnyToJSONValue(val)
        }
        return result
    }
    
    private func convertAnyToJSONValue(_ value: Any) -> JSONValue {
        if value is NSNull {
            return .null
        } else if let bool = value as? Bool {
            return .bool(bool)
        } else if let number = value as? NSNumber {
            return .number(number.doubleValue)
        } else if let string = value as? String {
            return .string(string)
        } else if let array = value as? [Any] {
            return .array(array.map(convertAnyToJSONValue))
        } else if let dict = value as? [String: Any] {
            var result: [String: JSONValue] = [:]
            for (key, val) in dict {
                result[key] = convertAnyToJSONValue(val)
            }
            return .object(result)
        } else {
            return .null
        }
    }
}

// MARK: - Error Types

enum MCPClientError: Error, LocalizedError {
    case notConnected
    case invalidResponse
    case encodingError
    case decodingError
    case serverError(MCPError)
    
    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Not connected to MCP server"
        case .invalidResponse:
            return "Invalid response from MCP server"
        case .encodingError:
            return "Failed to encode request"
        case .decodingError:
            return "Failed to decode response"
        case .serverError(let mcpError):
            return "Server error: \(mcpError.message) (code: \(mcpError.code))"
        }
    }
}