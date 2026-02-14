import Vapor

struct GeminiRequest: Content {
    struct ContentPart: Content {
        struct Part: Content {
            let text: String
        }
        let parts: [Part]
    }
    struct SystemInstruction: Content {
        struct Part: Content {
            let text: String
        }
        let parts: [Part]
    }
    struct GenerationConfig: Content {
        let responseMimeType: String
    }
    
    let contents: [ContentPart]
    let systemInstruction: SystemInstruction?
    let generationConfig: GenerationConfig?
}

struct GeminiGeocodeResponse: Content {
    struct Candidate: Content {
        struct ContentPart: Content {
            let text: String
        }
        let content: ContentPart
    }
    let candidates: [Candidate]
}
