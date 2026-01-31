export interface TranscribeResponse {
    text: string;
}

const API_BASE_URL = 'http://localhost:3000'; // Make sure this matches your backend port

/**
 * Transcribe audio blob to text using the backend API
 * @param audioBlob - The audio blob to transcribe (webm format)
 * @returns Promise resolving to the transcribed text
 */
export async function transcribeAudio(audioBlob: Blob): Promise<TranscribeResponse> {
    const formData = new FormData();
    // Append the blob with a filename and extension that matches the blob type
    // The backend uses extension to determine format
    const extension = audioBlob.type.includes('wav') ? 'wav' : 'webm';
    formData.append('audio', audioBlob, `recording.${extension}`);

    try {
        const response = await fetch(`${API_BASE_URL}/api/transcribe`, {
            method: 'POST',
            body: formData,
        });

        if (!response.ok) {
            const errorData = await response.json().catch(() => ({}));
            throw new Error(errorData.error || `Transcription failed with status ${response.status}`);
        }

        const data = await response.json();
        return data as TranscribeResponse;
    } catch (error) {
        console.error('Transcription error:', error);
        throw error;
    }
}
