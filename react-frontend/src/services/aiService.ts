import axios from 'axios';

const API_BASE_URL = 'http://localhost:3000/api'; // Adjust based on your backend config

export interface AiCommandRequest {
    prompt: String;
    session_id?: string;
    customer_id?: number;
}

export interface AiCommandResponse {
    success: boolean;
    message: string;
    actions_executed: string[];
    error?: string;
}

export const sendAiCommand = async (request: AiCommandRequest): Promise<AiCommandResponse> => {
    try {
        const response = await axios.post<AiCommandResponse>(`${API_BASE_URL}/ai/command`, request);
        return response.data;
    } catch (error) {
        console.error('AI Command Error:', error);
        return {
            success: false,
            message: 'Sorry, I encountered an error. Please try again.',
            actions_executed: [],
            error: error instanceof Error ? error.message : String(error),
        };
    }
};
