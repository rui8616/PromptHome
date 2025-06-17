//
//  MCPServer.swift
//  PromptHome
//
//  Created by Rui on 2025/6/16.
//

import Foundation
import Network
import SwiftData
import OSLog

/// MCP Server implementation for PromptHome
class MCPServer: ObservableObject {
    private let logger = Logger(subsystem: "PromptHome", category: "MCPServer")
    private var listener: NWListener?
    private var connections: Set<MCPConnection> = []
    private let queue = DispatchQueue(label: "mcp.server.queue")
    
    @Published var isRunning = false
    @Published var port: UInt16 = 3001
    @Published var errorMessage: String?
    
    private var modelContext: ModelContext?
    
    init() {}
    
    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func start() {
        guard !isRunning else { return }
        
        do {
            let parameters = NWParameters.tcp
            parameters.allowLocalEndpointReuse = true
            parameters.includePeerToPeer = true
            
            // Force IPv4
            let ipOptions = parameters.defaultProtocolStack.internetProtocol as! NWProtocolIP.Options
            ipOptions.version = .v4
            
            listener = try NWListener(using: parameters, on: NWEndpoint.Port(rawValue: port)!)
            
            listener?.newConnectionHandler = { [weak self] connection in
                self?.handleNewConnection(connection)
            }
            
            listener?.stateUpdateHandler = { [weak self] state in
                DispatchQueue.main.async {
                    switch state {
                    case .ready:
                        self?.isRunning = true
                        self?.errorMessage = nil
                        self?.logger.info("MCP Server started on port \(self?.port ?? 0)")
                    case .failed(let error):
                        self?.isRunning = false
                        self?.errorMessage = "Failed to start server: \(error.localizedDescription)"
                        self?.logger.error("MCP Server failed: \(error.localizedDescription)")
                    case .cancelled:
                        self?.isRunning = false
                        self?.logger.info("MCP Server stopped")
                    default:
                        break
                    }
                }
            }
            
            listener?.start(queue: queue)
            
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to create listener: \(error.localizedDescription)"
                self.logger.error("Failed to create listener: \(error.localizedDescription)")
            }
        }
    }
    
    func stop() {
        listener?.cancel()
        connections.forEach { $0.close() }
        connections.removeAll()
        
        DispatchQueue.main.async {
            self.isRunning = false
        }
    }
    
    private func handleNewConnection(_ connection: NWConnection) {
        let mcpConnection = MCPConnection(connection: connection, server: self)
        connections.insert(mcpConnection)
        mcpConnection.start()
        
        logger.info("New MCP connection established")
    }
    
    func removeConnection(_ mcpConnection: MCPConnection) {
        connections.remove(mcpConnection)
        logger.info("MCP connection removed")
    }
    
    // MARK: - MCP Request Handlers
    
    func handleRequest(_ request: MCPRequest, from connection: MCPConnection) -> MCPResponse {
        logger.info("Handling MCP request: \(request.method)")
        
        switch request.method {
        case "initialize":
            return handleInitialize(request)
        case "prompts/list":
            return handlePromptsList(request)
        case "prompts/get":
            return handlePromptsGet(request)
        case "tools/list":
            return handleToolsList(request)
        case "tools/call":
            return handleToolsCall(request)
        default:
            return MCPResponse(
                id: request.id,
                error: MCPError.methodNotFound
            )
        }
    }
    
    private func handleInitialize(_ request: MCPRequest) -> MCPResponse {
        let serverInfo = ServerInfo(name: "PromptHome", version: "1.0.0")
        let capabilities = ServerCapabilities(
            prompts: PromptsCapability(listChanged: true),
            tools: ToolsCapability(listChanged: false)
        )
        
        let result = InitializeResult(
            capabilities: capabilities,
            serverInfo: serverInfo
        )
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(result)
            let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
            let jsonValue = convertToJSONValue(json)
            
            return MCPResponse(id: request.id, result: jsonValue)
        } catch {
            logger.error("Failed to encode initialize result: \(error.localizedDescription)")
            return MCPResponse(id: request.id, error: MCPError.internalError)
        }
    }
    
    private func handlePromptsList(_ request: MCPRequest) -> MCPResponse {
        guard let modelContext = modelContext else {
            return MCPResponse(id: request.id, error: MCPError.internalError)
        }
        
        do {
            let descriptor = FetchDescriptor<Prompt>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
            let prompts = try modelContext.fetch(descriptor)
            
            let mcpPrompts = prompts.map { prompt in
                MCPPrompt(
                    name: prompt.id.uuidString,
                    description: "\(prompt.title) - \(prompt.tags.joined(separator: ", "))"
                )
            }
            
            let result = PromptsListResult(prompts: mcpPrompts)
            
            let encoder = JSONEncoder()
            let data = try encoder.encode(result)
            let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
            let jsonValue = convertToJSONValue(json)
            
            return MCPResponse(id: request.id, result: jsonValue)
        } catch {
            logger.error("Failed to fetch prompts: \(error.localizedDescription)")
            return MCPResponse(id: request.id, error: MCPError.internalError)
        }
    }
    
    private func handlePromptsGet(_ request: MCPRequest) -> MCPResponse {
        guard let modelContext = modelContext,
              let params = request.params,
              let nameValue = params["name"],
              let promptId = nameValue.stringValue,
              let uuid = UUID(uuidString: promptId) else {
            return MCPResponse(id: request.id, error: MCPError.invalidParams)
        }
        
        do {
            let descriptor = FetchDescriptor<Prompt>(predicate: #Predicate { $0.id == uuid })
            let prompts = try modelContext.fetch(descriptor)
            
            guard let prompt = prompts.first else {
                return MCPResponse(id: request.id, error: MCPError(code: -32000, message: "Prompt not found"))
            }
            
            let message = PromptMessage(
                role: .user,
                content: .text(prompt.content)
            )
            
            let result = PromptsGetResult(
                description: "\(prompt.title) - \(prompt.tags.joined(separator: ", "))",
                messages: [message]
            )
            
            let encoder = JSONEncoder()
            let data = try encoder.encode(result)
            let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
            let jsonValue = convertToJSONValue(json)
            
            return MCPResponse(id: request.id, result: jsonValue)
        } catch {
            logger.error("Failed to fetch prompt: \(error.localizedDescription)")
            return MCPResponse(id: request.id, error: MCPError.internalError)
        }
    }
    
    private func handleToolsList(_ request: MCPRequest) -> MCPResponse {
        // 定义可用的工具
        let tools = [
            MCPTool(
                name: "get_prompts_list",
                description: "获取所有可用提示词的列表",
                inputSchema: .object([
                    "type": .string("object"),
                    "properties": .object([:]),
                    "required": .array([])
                ])
            ),
            MCPTool(
                name: "get_prompt_content",
                description: "根据提示词ID获取具体的提示词内容",
                inputSchema: .object([
                    "type": .string("object"),
                    "properties": .object([
                        "prompt_id": .object([
                            "type": .string("string"),
                            "description": .string("提示词的UUID")
                        ])
                    ]),
                    "required": .array([.string("prompt_id")])
                ])
            )
        ]
        
        let result = ToolsListResult(tools: tools)
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(result)
            let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
            let jsonValue = convertToJSONValue(json)
            
            return MCPResponse(id: request.id, result: jsonValue)
        } catch {
            logger.error("Failed to encode tools list result: \(error.localizedDescription)")
            return MCPResponse(id: request.id, error: MCPError.internalError)
        }
    }
    
    private func handleToolsCall(_ request: MCPRequest) -> MCPResponse {
        guard let params = request.params,
              let nameValue = params["name"],
              let toolName = nameValue.stringValue else {
            return MCPResponse(id: request.id, error: MCPError.invalidParams)
        }
        
        guard let modelContext = modelContext else {
            return MCPResponse(id: request.id, error: MCPError.internalError)
        }
        
        switch toolName {
        case "get_prompts_list":
            return handleGetPromptsList(request, modelContext: modelContext)
        case "get_prompt_content":
            return handleGetPromptContent(request, modelContext: modelContext)
        default:
            return MCPResponse(id: request.id, error: MCPError(code: -32000, message: "Unknown tool: \(toolName)"))
        }
    }
    
    private func handleGetPromptsList(_ request: MCPRequest, modelContext: ModelContext) -> MCPResponse {
        do {
            let descriptor = FetchDescriptor<Prompt>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
            let prompts = try modelContext.fetch(descriptor)
            
            let promptsInfo = prompts.map { prompt in
                return [
                    "id": prompt.id.uuidString,
                    "title": prompt.title,
                    "tags": prompt.tags.joined(separator: ", "),
                    "updatedAt": ISO8601DateFormatter().string(from: prompt.updatedAt)
                ]
            }
            
            let jsonString = try JSONSerialization.data(withJSONObject: promptsInfo, options: .prettyPrinted)
            let resultText = String(data: jsonString, encoding: .utf8) ?? "Failed to serialize prompts"
            
            let result = ToolsCallResult(content: [ToolContent.text(resultText)])
            
            let encoder = JSONEncoder()
            let data = try encoder.encode(result)
            let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
            let jsonValue = convertToJSONValue(json)
            
            return MCPResponse(id: request.id, result: jsonValue)
        } catch {
            logger.error("Failed to fetch prompts for tool: \(error.localizedDescription)")
            let errorResult = ToolsCallResult(content: [ToolContent.text("Error: \(error.localizedDescription)")], isError: true)
            
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(errorResult)
                let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
                let jsonValue = convertToJSONValue(json)
                return MCPResponse(id: request.id, result: jsonValue)
            } catch {
                return MCPResponse(id: request.id, error: MCPError.internalError)
            }
        }
    }
    
    private func handleGetPromptContent(_ request: MCPRequest, modelContext: ModelContext) -> MCPResponse {
        guard let params = request.params,
              let argumentsValue = params["arguments"],
              let arguments = argumentsValue.objectValue,
              let promptIdValue = arguments["prompt_id"],
              let promptIdString = promptIdValue.stringValue,
              let promptId = UUID(uuidString: promptIdString) else {
            let errorResult = ToolsCallResult(content: [ToolContent.text("Error: Invalid prompt_id parameter")], isError: true)
            
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(errorResult)
                let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
                let jsonValue = convertToJSONValue(json)
                return MCPResponse(id: request.id, result: jsonValue)
            } catch {
                return MCPResponse(id: request.id, error: MCPError.invalidParams)
            }
        }
        
        do {
            let descriptor = FetchDescriptor<Prompt>(predicate: #Predicate { $0.id == promptId })
            let prompts = try modelContext.fetch(descriptor)
            
            guard let prompt = prompts.first else {
                let errorResult = ToolsCallResult(content: [ToolContent.text("Error: Prompt not found with ID: \(promptIdString)")], isError: true)
                
                let encoder = JSONEncoder()
                let data = try encoder.encode(errorResult)
                let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
                let jsonValue = convertToJSONValue(json)
                return MCPResponse(id: request.id, result: jsonValue)
            }
            
            let promptInfo = [
                "id": prompt.id.uuidString,
                "title": prompt.title,
                "content": prompt.content,
                "tags": prompt.tags.joined(separator: ", "),
                "createdAt": ISO8601DateFormatter().string(from: prompt.createdAt),
                "updatedAt": ISO8601DateFormatter().string(from: prompt.updatedAt)
            ]
            
            let jsonString = try JSONSerialization.data(withJSONObject: promptInfo, options: .prettyPrinted)
            let resultText = String(data: jsonString, encoding: .utf8) ?? "Failed to serialize prompt"
            
            let result = ToolsCallResult(content: [ToolContent.text(resultText)])
            
            let encoder = JSONEncoder()
            let data = try encoder.encode(result)
            let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
            let jsonValue = convertToJSONValue(json)
            
            return MCPResponse(id: request.id, result: jsonValue)
        } catch {
            logger.error("Failed to fetch prompt content for tool: \(error.localizedDescription)")
            let errorResult = ToolsCallResult(content: [ToolContent.text("Error: \(error.localizedDescription)")], isError: true)
            
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(errorResult)
                let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
                let jsonValue = convertToJSONValue(json)
                return MCPResponse(id: request.id, result: jsonValue)
            } catch {
                return MCPResponse(id: request.id, error: MCPError.internalError)
            }
        }
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

// MARK: - MCP Connection

class MCPConnection: Hashable {
    private let connection: NWConnection
    private weak var server: MCPServer?
    private let logger = Logger(subsystem: "PromptHome", category: "MCPConnection")
    private let queue = DispatchQueue(label: "mcp.connection.queue")
    
    init(connection: NWConnection, server: MCPServer) {
        self.connection = connection
        self.server = server
    }
    
    func start() {
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.logger.info("Connection ready")
                self?.receiveData()
            case .failed(let error):
                self?.logger.error("Connection failed: \(error.localizedDescription)")
                self?.close()
            case .cancelled:
                self?.logger.info("Connection cancelled")
                self?.server?.removeConnection(self!)
            default:
                break
            }
        }
        
        connection.start(queue: queue)
    }
    
    func close() {
        connection.cancel()
    }
    
    private func receiveData() {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            if let error = error {
                self?.logger.error("Receive error: \(error.localizedDescription)")
                self?.close()
                return
            }
            
            if let data = data, !data.isEmpty {
                self?.processReceivedData(data)
            }
            
            if isComplete {
                self?.close()
            } else {
                self?.receiveData()
            }
        }
    }
    
    private func processReceivedData(_ data: Data) {
        guard let httpString = String(data: data, encoding: .utf8) else {
            logger.error("Failed to decode received data as UTF-8")
            return
        }
        
        logger.info("Received HTTP data: \(httpString.prefix(200))...")
        
        // Parse HTTP request
        let lines = httpString.components(separatedBy: "\r\n")
        guard let firstLine = lines.first,
              firstLine.hasPrefix("POST") else {
            let errorResponse = MCPResponse(id: RequestId.string("unknown"), error: MCPError.methodNotFound)
            sendMCPResponse(errorResponse)
            return
        }
        
        // Find header end
        var headerEndIndex = 0
        
        for (index, line) in lines.enumerated() {
            if line.isEmpty {
                headerEndIndex = index + 1
                break
            }
        }
        
        // Extract JSON body
        let bodyLines = Array(lines.dropFirst(headerEndIndex))
        let jsonBody = bodyLines.joined(separator: "\r\n")
        
        guard let jsonData = jsonBody.data(using: .utf8) else {
            let errorResponse = MCPResponse(id: RequestId.string("unknown"), error: MCPError.parseError)
            sendMCPResponse(errorResponse)
            return
        }
        
        processJSONRequest(jsonData)
    }
    
    private func processJSONRequest(_ data: Data) {
        do {
            let request = try JSONDecoder().decode(MCPRequest.self, from: data)
            logger.info("Decoded MCP request: \(request.method)")
            
            guard let server = server else {
                logger.error("Server instance is nil when processing request: \(request.method)")
                let errorData = JSONValue.object([
                    "request_method": .string(request.method),
                    "error_detail": .string("Server instance not available")
                ])
                sendErrorResponse(id: request.id, error: MCPError(code: -32603, message: "Internal error: Server not initialized", data: errorData))
                return
            }
            
            let response = server.handleRequest(request, from: self)
            
            // Log detailed response information
            if let error = response.error {
                logger.error("Request \(request.method) failed with error: code=\(error.code), message=\(error.message)")
                if let errorData = error.data {
                    logger.error("Error data: \(String(describing: errorData))")
                }
            } else {
                logger.info("Request \(request.method) completed successfully")
            }
            
            sendMCPResponse(response)
            
        } catch {
            logger.error("Failed to decode JSON request: \(error.localizedDescription)")
            logger.error("Raw JSON data: \(String(data: data, encoding: .utf8) ?? "<invalid UTF-8>")")
            
            let errorData = JSONValue.object([
                "decode_error": .string(error.localizedDescription),
                "raw_data_length": .number(Double(data.count)),
                "raw_data_preview": .string(String(data: data.prefix(100), encoding: .utf8) ?? "<invalid UTF-8>")
            ])
            
            let detailedError = MCPError(code: -32700, message: "Parse error: Failed to decode JSON request", data: errorData)
            let errorResponse = MCPResponse(id: RequestId.string("unknown"), error: detailedError)
            sendMCPResponse(errorResponse)
        }
    }
    
    private func sendMCPResponse(_ response: MCPResponse) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let jsonData = try encoder.encode(response)
            
            sendHTTPResponse(statusCode: 200, body: String(data: jsonData, encoding: .utf8) ?? "")
        } catch {
            logger.error("Failed to encode MCP response: \(error.localizedDescription)")
            sendHTTPResponse(statusCode: 500, body: "Internal Server Error")
        }
    }
    
    private func sendErrorResponse(id: RequestId, error: MCPError) {
        let response = MCPResponse(id: id, error: error)
        sendMCPResponse(response)
    }
    
    private func sendHTTPResponse(statusCode: Int, body: String) {
        let statusText = statusCode == 200 ? "OK" : "Error"
        let response = """
            HTTP/1.1 \(statusCode) \(statusText)\r
            Content-Type: application/json\r
            Content-Length: \(body.utf8.count)\r
            Access-Control-Allow-Origin: *\r
            Access-Control-Allow-Methods: POST, OPTIONS\r
            Access-Control-Allow-Headers: Content-Type\r
            \r
            \(body)
            """
        
        guard let data = response.data(using: .utf8) else {
            logger.error("Failed to encode HTTP response")
            return
        }
        
        connection.send(content: data, completion: .contentProcessed { [weak self] error in
            if let error = error {
                self?.logger.error("Failed to send response: \(error.localizedDescription)")
            } else {
                self?.logger.info("HTTP response sent successfully")
            }
        })
    }
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
    
    static func == (lhs: MCPConnection, rhs: MCPConnection) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}