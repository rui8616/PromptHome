//
//  MCPProtocol.swift
//  PromptHome
//
//  Created by Rui on 2025/6/16.
//

import Foundation

// MARK: - MCP Protocol Types

/// JSON-RPC 2.0 Request
struct MCPRequest: Codable {
    let jsonrpc: String
    let id: RequestId
    let method: String
    let params: [String: JSONValue]?
    
    init(id: RequestId, method: String, params: [String: JSONValue]? = nil) {
        self.jsonrpc = "2.0"
        self.id = id
        self.method = method
        self.params = params
    }
}

/// JSON-RPC 2.0 Response
struct MCPResponse: Codable {
    let jsonrpc: String
    let id: RequestId
    let result: [String: JSONValue]?
    let error: MCPError?
    
    init(id: RequestId, result: [String: JSONValue]? = nil, error: MCPError? = nil) {
        self.jsonrpc = "2.0"
        self.id = id
        self.result = result
        self.error = error
    }
}

/// JSON-RPC 2.0 Notification
struct MCPNotification: Codable {
    let jsonrpc: String
    let method: String
    let params: [String: JSONValue]?
    
    init(method: String, params: [String: JSONValue]? = nil) {
        self.jsonrpc = "2.0"
        self.method = method
        self.params = params
    }
}

/// Request ID type
enum RequestId: Codable, Hashable {
    case string(String)
    case number(Int)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let intValue = try? container.decode(Int.self) {
            self = .number(intValue)
        } else {
            throw DecodingError.typeMismatch(RequestId.self, DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "RequestId must be either string or number"
            ))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .number(let value):
            try container.encode(value)
        }
    }
}

/// MCP Error
struct MCPError: Codable, Error {
    let code: Int
    let message: String
    let data: JSONValue?
    
    init(code: Int, message: String, data: JSONValue? = nil) {
        self.code = code
        self.message = message
        self.data = data
    }
    
    // Standard JSON-RPC error codes
    static let parseError = MCPError(code: -32700, message: "Parse error")
    static let invalidRequest = MCPError(code: -32600, message: "Invalid Request")
    static let methodNotFound = MCPError(code: -32601, message: "Method not found")
    static let invalidParams = MCPError(code: -32602, message: "Invalid params")
    static let internalError = MCPError(code: -32603, message: "Internal error")
}

/// Flexible JSON value type
enum JSONValue: Codable, Hashable {
    case null
    case bool(Bool)
    case number(Double)
    case string(String)
    case array([JSONValue])
    case object([String: JSONValue])
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self = .null
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let number = try? container.decode(Double.self) {
            self = .number(number)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let array = try? container.decode([JSONValue].self) {
            self = .array(array)
        } else if let object = try? container.decode([String: JSONValue].self) {
            self = .object(object)
        } else {
            throw DecodingError.typeMismatch(JSONValue.self, DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Cannot decode JSONValue"
            ))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .null:
            try container.encodeNil()
        case .bool(let value):
            try container.encode(value)
        case .number(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        }
    }
    
    // Convenience accessors
    var stringValue: String? {
        if case .string(let value) = self { return value }
        return nil
    }
    
    var numberValue: Double? {
        if case .number(let value) = self { return value }
        return nil
    }
    
    var boolValue: Bool? {
        if case .bool(let value) = self { return value }
        return nil
    }
    
    var arrayValue: [JSONValue]? {
        if case .array(let value) = self { return value }
        return nil
    }
    
    var objectValue: [String: JSONValue]? {
        if case .object(let value) = self { return value }
        return nil
    }
}

// MARK: - MCP Capabilities

struct ServerCapabilities: Codable {
    let prompts: PromptsCapability?
    let resources: ResourcesCapability?
    let tools: ToolsCapability?
    let logging: LoggingCapability?
    
    init(prompts: PromptsCapability? = nil, resources: ResourcesCapability? = nil, tools: ToolsCapability? = nil, logging: LoggingCapability? = nil) {
        self.prompts = prompts
        self.resources = resources
        self.tools = tools
        self.logging = logging
    }
}

struct ClientCapabilities: Codable {
    let sampling: SamplingCapability?
    
    init(sampling: SamplingCapability? = nil) {
        self.sampling = sampling
    }
}

struct PromptsCapability: Codable {
    let listChanged: Bool?
    
    init(listChanged: Bool? = nil) {
        self.listChanged = listChanged
    }
}

struct ResourcesCapability: Codable {
    let subscribe: Bool?
    let listChanged: Bool?
    
    init(subscribe: Bool? = nil, listChanged: Bool? = nil) {
        self.subscribe = subscribe
        self.listChanged = listChanged
    }
}

struct ToolsCapability: Codable {
    let listChanged: Bool?
    
    init(listChanged: Bool? = nil) {
        self.listChanged = listChanged
    }
}

struct LoggingCapability: Codable {
    // Empty for now
}

struct SamplingCapability: Codable {
    // Empty for now
}

// MARK: - MCP Data Types

struct MCPPrompt: Codable {
    let name: String
    let description: String?
    let arguments: [PromptArgument]?
    
    init(name: String, description: String? = nil, arguments: [PromptArgument]? = nil) {
        self.name = name
        self.description = description
        self.arguments = arguments
    }
}

struct PromptArgument: Codable {
    let name: String
    let description: String?
    let required: Bool?
    
    init(name: String, description: String? = nil, required: Bool? = nil) {
        self.name = name
        self.description = description
        self.required = required
    }
}

struct PromptMessage: Codable {
    let role: MessageRole
    let content: MessageContent
    
    init(role: MessageRole, content: MessageContent) {
        self.role = role
        self.content = content
    }
}

enum MessageRole: String, Codable {
    case user
    case assistant
    case system
}

enum MessageContent: Codable {
    case text(String)
    case image(Data, String) // data, mimeType
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "text":
            let text = try container.decode(String.self, forKey: .text)
            self = .text(text)
        case "image":
            let data = try container.decode(Data.self, forKey: .data)
            let mimeType = try container.decode(String.self, forKey: .mimeType)
            self = .image(data, mimeType)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown content type")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .text(let text):
            try container.encode("text", forKey: .type)
            try container.encode(text, forKey: .text)
        case .image(let data, let mimeType):
            try container.encode("image", forKey: .type)
            try container.encode(data, forKey: .data)
            try container.encode(mimeType, forKey: .mimeType)
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case type, text, data, mimeType
    }
}

// MARK: - Initialize Request/Response

struct InitializeRequest: Codable {
    let protocolVersion: String
    let capabilities: ClientCapabilities
    let clientInfo: ClientInfo
    
    init(protocolVersion: String = "2024-11-05", capabilities: ClientCapabilities, clientInfo: ClientInfo) {
        self.protocolVersion = protocolVersion
        self.capabilities = capabilities
        self.clientInfo = clientInfo
    }
}

struct InitializeResult: Codable {
    let protocolVersion: String
    let capabilities: ServerCapabilities
    let serverInfo: ServerInfo
    
    init(protocolVersion: String = "2024-11-05", capabilities: ServerCapabilities, serverInfo: ServerInfo) {
        self.protocolVersion = protocolVersion
        self.capabilities = capabilities
        self.serverInfo = serverInfo
    }
}

struct ClientInfo: Codable {
    let name: String
    let version: String
    
    init(name: String, version: String) {
        self.name = name
        self.version = version
    }
}

struct ServerInfo: Codable {
    let name: String
    let version: String
    
    init(name: String, version: String) {
        self.name = name
        self.version = version
    }
}

// MARK: - Prompts List Request/Response

struct PromptsListRequest: Codable {
    let cursor: String?
    
    init(cursor: String? = nil) {
        self.cursor = cursor
    }
}

struct PromptsListResult: Codable {
    let prompts: [MCPPrompt]
    let nextCursor: String?
    
    init(prompts: [MCPPrompt], nextCursor: String? = nil) {
        self.prompts = prompts
        self.nextCursor = nextCursor
    }
}

// MARK: - Prompts Get Request/Response

struct PromptsGetRequest: Codable {
    let name: String
    let arguments: [String: JSONValue]?
    
    init(name: String, arguments: [String: JSONValue]? = nil) {
        self.name = name
        self.arguments = arguments
    }
}

struct PromptsGetResult: Codable {
    let description: String?
    let messages: [PromptMessage]
    
    init(description: String? = nil, messages: [PromptMessage]) {
        self.description = description
        self.messages = messages
    }
}

// MARK: - Tools

struct MCPTool: Codable {
    let name: String
    let description: String?
    let inputSchema: JSONValue?
    
    init(name: String, description: String? = nil, inputSchema: JSONValue? = nil) {
        self.name = name
        self.description = description
        self.inputSchema = inputSchema
    }
}

// MARK: - Tools List Request/Response

struct ToolsListRequest: Codable {
    let cursor: String?
    
    init(cursor: String? = nil) {
        self.cursor = cursor
    }
}

struct ToolsListResult: Codable {
    let tools: [MCPTool]
    let nextCursor: String?
    
    init(tools: [MCPTool], nextCursor: String? = nil) {
        self.tools = tools
        self.nextCursor = nextCursor
    }
}

// MARK: - Tools Call Request/Response

struct ToolsCallRequest: Codable {
    let name: String
    let arguments: [String: JSONValue]?
    
    init(name: String, arguments: [String: JSONValue]? = nil) {
        self.name = name
        self.arguments = arguments
    }
}

struct ToolsCallResult: Codable {
    let content: [ToolContent]
    let isError: Bool?
    
    init(content: [ToolContent], isError: Bool? = nil) {
        self.content = content
        self.isError = isError
    }
}

struct ToolContent: Codable {
    let type: String
    let text: String?
    let data: Data?
    let mimeType: String?
    
    init(type: String, text: String? = nil, data: Data? = nil, mimeType: String? = nil) {
        self.type = type
        self.text = text
        self.data = data
        self.mimeType = mimeType
    }
    
    static func text(_ text: String) -> ToolContent {
        return ToolContent(type: "text", text: text)
    }
    
    static func image(_ data: Data, mimeType: String) -> ToolContent {
        return ToolContent(type: "image", data: data, mimeType: mimeType)
    }
}