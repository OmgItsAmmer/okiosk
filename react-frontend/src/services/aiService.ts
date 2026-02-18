import axios from 'axios';

import { API_BASE_URL as ROOT_URL } from '../config';
const API_BASE_URL = `${ROOT_URL}/api`;

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
